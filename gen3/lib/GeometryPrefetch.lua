-- One read/decode at a time; at most four retained payloads / 32 MiB decoded
-- bytes. A consumed record is never reused: restore mutates flower statistics.
local V=...
local P={enabled=true,hits=0,completed=0,failed=0,readyBytes=0,dispatched=0}
local wanted,order,ready,consumed={},{},{},{}
local thread,requests,results,active,unavailable,retiring,decodeJob
local quitInstalled
local awaited
local function digest(s)return type(s)=='string'and #s==64 and s:match('^[0-9a-f]+$')end
local function start()
 if thread then return true end
 if unavailable then return false end
 if retiring then
  if retiring:isRunning()then return false end
  retiring=nil
 end
 local ok,err=pcall(function()
  local t=love.thread;assert(t and t.newThread,'threads unavailable')
  local root=V.mod.path
  assert(type(root)=='string'and root~=''and not root:find('..',1,true)and not root:match('^[/\\]'),'invalid mod root')
  local codec=assert(V.mod:read('gen3/lib/RenderCacheCodec.lua'))
  local envelope=assert(V.mod:read('gen3/lib/GeometryPayload.lua'))
  local worker=assert(V.mod:read('gen3/lib/GeometryCacheWorker.lua'))
  local chunks=assert(V.mod:read('gen3/lib/GeometryChunks.lua'))
  local source='local codec=(function()\n'..codec..'\nend)()\nlocal payload=(function(...)\n'..envelope..'\nend)({require=function(n)assert(n=="RenderCacheCodec");return codec end})\nlocal chunks=(function(...)\n'..chunks..'\nend)({require=function(n)assert(n=="RenderCacheCodec");return codec end})\n'..worker
  requests=t.newChannel();results=t.newChannel();thread=t.newThread(source)
  thread:start(requests,results,root)
  if not quitInstalled then
   quitInstalled=true;local previous=love.quit
   love.quit=function(...)
    local cancel=previous and previous(...)
    if not cancel then V.require('GeometryGpuWarm').release();P.release()end
    return cancel
   end
  end
 end)
 if not ok then
  thread=nil;unavailable=tostring(err)
  if V.mod.log then V.mod.log:info('Geometry prefetch unavailable; synchronous fallback: '..unavailable)end
 end
 return ok
end
function P.want(items)
 local nextWanted,nextOrder={},{}
 -- A native load has priority over speculative neighbors until it completes
 -- or its owning build is cancelled. Lookahead cannot remove this digest.
 if awaited then nextWanted[awaited.item.digest]=awaited.item;nextOrder[1]=awaited.item.digest end
 local mobile=V.require('MobileRenderBudget').active()
 for _,item in ipairs(items)do
  if #nextOrder>=(mobile and 1 or 4)then break end
  if digest(item.digest)and digest(item.filename)and not nextWanted[item.digest]then
   local request={digest=item.digest,filename=item.filename,priority=item.priority,maxBytes=item.maxBytes}
   if mobile then request.maxBytes=math.min(request.maxBytes or 8*1024*1024,8*1024*1024)end
   nextWanted[item.digest]=request;nextOrder[#nextOrder+1]=item.digest
  end
 end
 for key,row in pairs(ready)do if not nextWanted[key]then P.readyBytes=P.readyBytes-row.size;ready[key]=nil end end
 for key in pairs(consumed)do if not nextWanted[key]then consumed[key]=nil end end
 wanted,order=nextWanted,nextOrder
end
function P.pump(allowDecode)
 if not P.enabled then P.release();return end
 local mobile=V.require('MobileRenderBudget').active()
 local top=order[1]and wanted[order[1]]
 local walking=allowDecode==false
 if walking and not(top and top.priority)then return end
 if not thread and (#order==0 or not start())then return end
 if decodeJob and not wanted[decodeJob.digest]then decodeJob=nil end
 local result=not decodeJob and results:pop()
 if result then
  active=nil
  if wanted[result.digest]and not consumed[result.digest]then
   local maxBytes=mobile and not awaited and 8*1024*1024 or 32*1024*1024
   if result.ok and type(result.transfer)=='string'and #result.transfer<=128*1024*1024 and result.size<=maxBytes-P.readyBytes then
    decodeJob={digest=result.digest,size=result.size}
    local job=decodeJob
    job.co=coroutine.create(function()
     return V.require('RenderCacheCodec').decode(result.transfer,function()
      if love.timer.getTime()>=job.deadline then coroutine.yield()end
     end)
    end)
   else consumed[result.digest]=true;if not result.ok then P.failed=P.failed+1 end end
  end
 end
 if decodeJob then
  local job=decodeJob;job.deadline=love.timer.getTime()+(awaited and job.digest==awaited.item.digest and .004 or walking and .0005 or .001)
  local ok,record=coroutine.resume(job.co)
  if not ok then
   consumed[job.digest]=true;P.failed=P.failed+1;decodeJob=nil
  elseif coroutine.status(job.co)=='dead'then
   ready[job.digest]={record=record,size=job.size};P.readyBytes=P.readyBytes+job.size;P.completed=P.completed+1;decodeJob=nil
  end
 end
 -- No wait on the render thread, even if a worker failed or a map is already
 -- needed. The caller can still use the verified synchronous path immediately.
 if thread:getError()then unavailable=thread:getError();P.release();return end
 if not active then for _,key in ipairs(order)do
  if (not walking or key==order[1])and not ready[key]and not consumed[key]and not(decodeJob and decodeJob.digest==key)then
   active=key;requests:push(wanted[key]);P.dispatched=P.dispatched+1;break
  end
 end end
end
function P.peek(key)
 local row=ready[key];if row then return key,row.record end
end
function P.nextReady(excluded)
 for _,key in ipairs(order)do if ready[key]and not(excluded and excluded[key])then return key,ready[key].record end end
end
function P.take(key)
 local row=ready[key]
 if row then ready[key]=nil;P.readyBytes=P.readyBytes-row.size;P.hits=P.hits+1 end
 if wanted[key]then consumed[key]=true end
 return row and row.record
end
-- A cold native queue miss can use the same finite read-only worker as
-- lookahead. Yield frames while it decodes instead of decompressing on the
-- render thread. Synchronous tools and unavailable workers keep C.load's
-- verified fallback. A cancelled native job never publishes its record.
function P.await(item)
 if not P.enabled or not V.require('BuildBudget').ownsCurrent()
  or not digest(item.digest)or not digest(item.filename)then return end
 awaited={item=item,owner=coroutine.running()}
 P.want({item});consumed[item.digest]=nil
 local started=love.timer.getTime()
 while P.enabled and love.timer.getTime()-started<2 do
  P.pump()
  if ready[item.digest]then awaited=nil;return P.take(item.digest)end
  if unavailable or consumed[item.digest]then awaited=nil;return end
  coroutine.yield('cache CPU handoff')
 end
 awaited=nil
end
function P.cancelAwait(owner)
 if awaited and awaited.owner==owner then awaited=nil end
end
function P.release()
 if requests then requests:push(false);retiring=thread end
 thread,requests,results,active=nil,nil,nil,nil
 wanted,order,ready,consumed={},{},{},{};decodeJob=nil;awaited=nil;P.readyBytes=0
end
function P.stats()
 local count=0;for _ in pairs(ready)do count=count+1 end
 return {ready=count,bytes=P.readyBytes,pending=active~=nil or decodeJob~=nil,decoding=decodeJob~=nil,dispatched=P.dispatched,available=not unavailable,hits=P.hits,completed=P.completed,failed=P.failed}
end
return P
