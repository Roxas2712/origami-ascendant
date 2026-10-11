-- Fit the native intro's presentation steps to the popup. Native messages,
-- cries, shiny checks, send-out callbacks and battle state retain ownership.
local F={}
function F.prepare(intro,battle)
 if intro._st~=battle or not intro._steps or intro._i~=1 or intro._waiting then return false end
 local steps={}
 for i,step in ipairs(intro._steps)do
  local data={};for k,v in pairs(step.data or{})do data[k]=v end
  if step.kind=='bgslide'then
   data.frames=1;data.slideFrames=1;data.unlockAt=0
   data.playerFrom=0;data.enemyFrom=0;data.enemyMonFrom=0
  elseif step.kind=='undarken'then data.frames=1
  elseif step.kind=='healthbox'or step.kind=='partybar'then data.frames=6 end
  steps[i]={kind=step.kind,data=data}
 end
 intro._steps=steps
 return true
end
function F.releaseSendOut(intro,text)
 local step=intro._steps and intro._steps[intro._i]
 if not intro._waitingMsg or not step or step.kind~='msg'or step.data.text~=text then return false end
 -- Called after the native Go line has finished. Advance its sequencer once
 -- so the popup throw and the native throw begin on the same frame.
 intro._waitingMsg=false;intro._waiting=false;intro._i=intro._i+1
 return true
end
return F
