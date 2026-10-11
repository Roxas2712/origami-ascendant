-- One native geometry job, resumed once per rendered frame. Only complete
-- entries are published. Cancellation owns GPU objects created by that job.
local V=...
local Budget=V.require('BuildBudget')
local Q={slices=0,completed=0,maxSliceMs=0}
local retry={}
-- A live native script may change a room while its build is suspended.
-- Discard that incomplete scene and retry; it is not a renderer failure.
function Q.retry()error(retry,0)end
function Q.own(object)
 if Q.job and coroutine.running()==Q.job.co and object then
  Q.job.objects[#Q.job.objects+1]=object
 end
 return object
end
function Q.cancel()
 local job=Q.job;Q.job=nil
 local prefetch=V.loaded and V.loaded.GeometryPrefetch
 if job and prefetch and prefetch.cancelAwait then prefetch.cancelAwait(job.co)end
 if job then for _,object in ipairs(job.objects)do object:release()end end
end
function Q.get(key,frame,build)
 if Q.frame==frame then return nil end
 if Q.job and Q.job.key~=key then Q.cancel()end
 if not Q.job then Q.job={key=key,co=coroutine.create(build),objects={}}end
 if Q.frame==frame then return nil end
 Q.frame=frame
 local job=Q.job;local started=(V.clock or love.timer.getTime)()
 Budget.begin(job.co,.002)
 local ok,result=coroutine.resume(job.co)
 Budget.finish()
 Q.slices=Q.slices+1
 local ms=((V.clock or love.timer.getTime)()-started)*1000
 Q.maxSliceMs=math.max(Q.maxSliceMs,ms)
 Q.phaseMax=Q.phaseMax or{};local phase=Budget.phase();Q.phaseMax[phase]=math.max(Q.phaseMax[phase]or 0,ms)
 local log=V.loaded and V.loaded.PerformanceLog
 if log then log.record('native geometry slice '..phase,ms/1000)end
 if not ok then Q.cancel();if result==retry then return nil end;error(result,0)end
 if coroutine.status(job.co)=='dead'then
  Q.job=nil;Q.completed=Q.completed+1
  return result
 end
 return nil
end
return Q
