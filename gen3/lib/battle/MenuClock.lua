-- Settings own buttons, not the native battle clock. Run at native 60 Hz;
-- no synthetic command or dialog confirmation is sent beneath the overlay.
local V=...
local Battle=require('src.core.game3.battle')
local Message=require('src.ui.game3.message')
local C={accum=0,steps=0,opens=0,rows={}}
local function edge(label)
 C.rows[#C.rows+1]=string.format('%s: native_steps=%d phase=%s',label,C.steps,tostring(Battle._phase))
 if #C.rows>16 then table.remove(C.rows,1)end
end
function C.update(game,dt,adapter)
 if not C.active then C.active=true;C.opens=C.opens+1;edge('settings opened')end
 C.accum=C.accum+math.max(0,math.min(dt or 0,.1))
 while C.accum>=1/60 do
  C.accum=C.accum-1/60
  if not Battle.isActive()then C.accum=0;break end
  if not adapter:tick(game,1/60)then
   Battle.update(1/60,game)
   Message.tick()
   C.steps=C.steps+1
  end
 end
end
function C.reset()
 if C.active then edge('settings closed')end
 C.active=false;C.accum=0
end
function C.text()
 local Ui=require('src.core.game3.battle.ui')
 local Anim=require('src.core.game3.battle.anim')
 local Intro=require('src.core.game3.battle.intro_seq')
 local lines={string.format('Battle/settings clock: open=%s opens=%d native_steps=%d active=%s phase=%s ui=%s dialog_pending=%s anim_busy=%s intro_step=%s waiting_msg=%s',
  tostring(C.active==true),C.opens,C.steps,tostring(Battle.isActive()),tostring(Battle._phase),tostring(Ui._mode),tostring(Ui.dialogPending()),tostring(Anim.busy()),tostring(Intro._i),tostring(Intro._waitingMsg))}
 local renderer=V and V.loaded and V.loaded.Renderer
 local handoff=V and V.loaded and V.loaded.FieldHandoff
 if renderer then lines[#lines+1]=string.format('Field handoff during battle: build_pending=%s started=%s',tostring(renderer.buildPending~=nil and renderer.buildPending~=false),tostring(handoff and handoff.started))end
 for _,row in ipairs(C.rows)do lines[#lines+1]=row end
 return table.concat(lines,'\n')
end
return C
