-- One immutable vertex blob in flight. Adjacency tables exist only in the
-- worker state; Channels never copy that graph into the renderer's Lua heap.
local V=...
local W={}
local thread,requests,results,retiring,unavailable
local serial=0
local quitInstalled=false
local function failed(reason)
 unavailable=tostring(reason);W.lastError=unavailable
 W.release()
 if V.mod.log then V.mod.log:info('Paper surface worker unavailable; cooperative fallback: '..unavailable)end
end
local function start()
 if thread then return true end
 if unavailable then return false end
 if retiring then if retiring:isRunning()then return false end;retiring=nil end
 local ok,err=pcall(function()
  local source=assert(V.mod:read('gen3/lib/cards/PaperSurfaceGeometry.lua'))
  requests=love.thread.newChannel();results=love.thread.newChannel()
  thread=love.thread.newThread('local G=(function()\n'..source..'\nend)()\n'..[[
   local input,output=...
   require('love.data');require('love.thread')
   while true do
    local request=input:demand();if request==false then break end
    local raw=request.bytes
    local ok,data,stats=pcall(function()
     local d,s=G.build(G.fromPacked(raw));return G.packRows(d),s
    end)
    output:push({id=request.id,ok=ok,data=ok and data or nil,stats=ok and stats or nil,error=not ok and tostring(data)or nil})
    request=nil;raw=nil;data=nil;stats=nil
    -- Reclaim the graph here, where an atomic GC phase cannot stall input.
    collectgarbage('collect')
   end
  ]])
  thread:start(requests,results)
  if not quitInstalled then
   quitInstalled=true;local previous=love.quit
   love.quit=function(...)
    local cancelled=previous and previous(...)
    if not cancelled then W.release()end
    return cancelled
   end
  end
 end)
 if not ok then failed(err)end
 return ok
end
function W.build(raw)
 if not start()then return nil,nil,false end
 local owner=thread
 -- An abandoned coroutine may leave one job in flight. Bound queued input
 -- and discard its result by token before a replacement can publish anything.
 while thread==owner and requests and requests:getCount()>=1 do
  local err=thread and thread:getError()
  if err then failed(err);return nil,nil,false end
  if not thread then return nil,nil,false end
  coroutine.yield()
 end
 if thread~=owner or not requests then return nil,nil,false end
 serial=serial+1;local id=serial;requests:push({id=id,bytes=raw});raw=nil
 while true do
  if thread~=owner or not results then return nil,nil,false end
  local result=results:pop()
  if result and result.id==id then
   if not result.ok then failed(result.error);return nil,nil,false end
   return result.data,result.stats,true
  end
  local err=thread:getError()
  if err then failed(err);return nil,nil,false end
  if not thread:isRunning()then failed('worker stopped before result');return nil,nil,false end
  coroutine.yield()
 end
end
function W.release()
 if requests then requests:push(false);retiring=thread end
 thread,requests,results=nil,nil,nil
end
return W
