-- Hash source dependencies off the render thread using the existing compute
-- permission. Unsupported hosts simply keep the native geometry build path.
local V=...
local M={}
local thread,results,done,index,reason
local decoder,deadline
function M.poll(seconds)
 if done then
  if thread and not thread:isRunning()then thread,results=nil,nil end
  return index,reason
 end
 if not thread then
  local raw=V.mod:read('gen3/render-cache/index.data')
  if not raw then done=true;return nil end
  local ok,err=pcall(function()
   assert(#raw<=128*1024*1024,'geometry index size')
   local codec=assert(V.mod:read('gen3/lib/RenderCacheCodec.lua'))
   local validator=assert(V.mod:read('gen3/lib/GeometryIndex.lua'))
   local worker=assert(V.mod:read('gen3/lib/GeometryValidationWorker.lua'))
   local source='local codec=(function()\n'..codec..'\nend)()\nlocal validator=(function(...)\n'..validator..'\nend)({require=function(n)assert(n=="RenderCacheCodec");return codec end})\n'..worker
   results=love.thread.newChannel();thread=love.thread.newThread(source)
   thread:start(results,V.mod.path,raw)
  end)
  if not ok then thread,results=nil,nil;done=true;reason=tostring(err);return nil,reason end
 end
 local result=not decoder and results:pop()
 if result then
  if not result.ok then done=true;reason=result.error;return nil,reason end
  decoder=coroutine.create(function()
   return V.require('RenderCacheCodec').decode(result.raw,function()
    if love.timer.getTime()>=deadline then coroutine.yield()end
   end)
  end)
 end
 if decoder then
  deadline=love.timer.getTime()+math.max(.0005,math.min(.004,tonumber(seconds)or .0005))
  local ok,value=coroutine.resume(decoder)
  if not ok then done=true;reason=tostring(value);decoder=nil;return nil,reason end
  if coroutine.status(decoder)=='dead'then done=true;index=value;decoder=nil;return index end
 end
 local err=thread:getError()
 if err then done=true;reason=err;thread,results=nil,nil;return nil,reason end
 return nil,'validation pending'
end
-- Tests/reloads may reset only after the finite worker has finished. Never
-- block the render thread waiting for filesystem work or leak duplicate jobs.
function M.reset()
 if thread and thread:isRunning()then return false end
 thread,results,done,index,reason,decoder=nil,nil,nil,nil,nil,nil
 return true
end
return M
