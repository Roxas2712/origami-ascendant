-- Upload verified destination geometry over several frames. Partial scenes are
-- private; only GeometryCache's exact native/layout key can claim a result.
local V=...
local Budget=V.require('BuildBudget')
local Queue=V.require('NativeBuildQueue')
local W={hits=0,completed=0,failed=0,forced=0}
local ready,skipped,job={}, {}, nil
local wanted={}
local bytes=0
local MAX_BYTES=64*1024*1024
local function dispose(objects)
 for i=#objects,1,-1 do objects[i]:release();objects[i]=nil end
end
local function discard(row)
 dispose(row.created);bytes=bytes-row.bytes
end
local function estimate(record)
 local n=#record.mesh+#(record.stats.contacts or{})*144
 for _,b in ipairs(record.instances)do n=n+#b.placements+(b.dynamic and 0 or #b.mesh)end
 return n
end
local function finish(row)
 local c=row.scene;local r=c.pendingRecord
 -- The GPU and decoded scene now own this data. Keep only metadata needed by
 -- activation (live flowers, furniture registrations and glass masks).
 r.mesh,r.heights,r.caveCaps=nil,nil,nil
 for _,b in ipairs(r.instances)do b.mesh,b.placements=nil,nil end
 row.thread=nil;ready[row.key]=row;job=nil;W.completed=W.completed+1
end
local function resume(row,deadline)
 row.deadline=deadline
 local ok,result=coroutine.resume(row.thread)
 if not ok then
  discard(row);job=nil;skipped[row.key]=true;W.failed=W.failed+1
  if V.mod.log then V.mod.log:info('Geometry GPU preparation failed; synchronous fallback: '..tostring(result))end
  return
 end
 if coroutine.status(row.thread)=='dead'then row.scene=result;finish(row)end
end
function W.update(targets,backgroundAllowed)
 local cfg=V.require('DioramaConfig').renderCache
 if cfg.prefetch==false or cfg.gpuWarm==false or V.require('MobileRenderBudget').active()then W.release();return end
 for key in pairs(wanted)do wanted[key]=nil end
 for i,item in ipairs(targets or{})do if i<=4 then wanted[item.digest]=true end end
 for key,row in pairs(ready)do if not wanted[key]then discard(row);ready[key]=nil end end
 for key in pairs(skipped)do if not wanted[key]then skipped[key]=nil end end
 if job and not wanted[job.key]then discard(job);job=nil end
 -- Ordinary speculative uploads pause during walking. Only the nearest
 -- lookahead destination gets a half-millisecond submission slice.
 local walking=backgroundAllowed==false
 local top=targets and targets[1]
 if walking and not(top and top.priority)then return end
 if walking and job and job.key~=top.digest then return end
 local budget=walking and .5 or tonumber(cfg.gpuBudgetMs)or 2
 if budget~=budget then budget=2 end
 local deadline=(V.clock or love.timer.getTime)()+math.max(.1,math.min(4,budget))/1000
 if not job then
  local P=V.require('GeometryPrefetch')
  local key,record
  if walking then key,record=P.peek(top.digest);if skipped[key]then key,record=nil,nil end
  else key,record=P.nextReady(skipped)end
  if key and wanted[key]and not ready[key]then
   local ok,size=pcall(estimate,record)
   if not ok or size>MAX_BYTES-bytes then skipped[key]=true;return end
   record=P.take(key)
   local row={key=key,bytes=size,created={}}
   bytes=bytes+size;job=row
   row.thread=coroutine.create(function()
    return V.require('GeometryCache').restore(record,nil,nil,0,0,{created=row.created,checkpoint=function()
     if (V.clock or love.timer.getTime)()>=row.deadline then coroutine.yield()end
    end})
   end)
  end
 end
 -- At most one scene's restore is resumed per call. Mesh uploads are atomic:
 -- this is a CPU submission budget between operations, not a GPU-time cap.
 if job then resume(job,deadline)end
end
function W.take(key)
 if job and job.key==key then
  W.forced=W.forced+1
  if Budget.ownsCurrent()then
   local row=job
   -- Taking an unfinished warm-up must not turn its remaining work into one
   -- blocking frame. The native queue also cancels an abandoned handoff.
   Queue.own({release=function()
    if job==row then discard(row);job=nil
    elseif ready[key]==row then discard(row);ready[key]=nil end
   end})
   while job==row do
    resume(row,(V.clock or love.timer.getTime)()+.002)
    if job==row then coroutine.yield('cache GPU handoff')end
   end
  else resume(job,math.huge)end
 end
 local row=ready[key]
 if row then
  ready[key]=nil;bytes=bytes-row.bytes;W.hits=W.hits+1
  return row.scene
 end
end
function W.release()
 if job then discard(job);job=nil end
 for key,row in pairs(ready)do discard(row);ready[key]=nil end
 skipped={}
end
function W.stats()
 local n=0;for _ in pairs(ready)do n=n+1 end
 return {ready=n,bytes=bytes,pending=job~=nil,hits=W.hits,completed=W.completed,failed=W.failed,forced=W.forced}
end
return W
