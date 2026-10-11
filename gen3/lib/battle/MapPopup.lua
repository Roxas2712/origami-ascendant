-- Presentation-only map intro. Native visibility/ball release determines order;
-- gameplay and native completion callbacks retain ownership of each handoff.
local V=...;local P={DURATION=.65}
local sides={'playerTrainer','enemyTrainer','enemy','player'}
function P.update(record,dt,phase,stage,poses)
 local s=record.scene
 if s.paperPopup or s.edition=='emerald'or s.kind=='terrarium'then return end
 s.mapPopup=s.mapPopup or{ages={}}
 s.mapPopup.mons=s.mapPopup.mons or{};s.mapPopup.reentry=s.mapPopup.reentry or{}
 s.actorFall=s.actorFall or{}
 s.actorFold=s.actorFold or{};s.actorVisible=s.actorVisible or{}
 s.actorLean=s.actorLean or{};s.ground=s.ground or{}
 -- Wild encounters introduce the player trainer and opponent as one pair.
 -- Their presentation clock must not inherit the native sprite slide offsets.
 local wild=record.battle and record.battle.wild
 if wild and phase=='intro'and stage.slideDone then
  s.mapPopup.wildAge=(s.mapPopup.wildAge or 0)+math.max(0,math.min(dt or 0,.1))
 end
 for _,side in ipairs(sides)do if s.feet[side]then
  local p=side:find('Trainer')and(stage.trainer or{})[side=='playerTrainer'and'player'or'enemy']or poses[side]
  local paired=wild and(side=='enemy'or side=='playerTrainer')
  local origami=V and V.require('battle/OrigamiSpawn').enabled()
  -- Match the normal hinge pace; folding adds no extra intro delay.
  local duration=P.DURATION
  local age=s.mapPopup.ages[side]
  local b=record.battle and record.battle[side];local mon=b and b.mon
  if mon and s.mapPopup.mons[side]and s.mapPopup.mons[side]~=mon then
   age=nil;s.mapPopup.reentry[side]=true
  end
  if mon then s.mapPopup.mons[side]=mon end
  if origami and s.mapPopup.reentry[side]then
   if p and p.visible~=false and not p.invisible then age=(age or 0)+math.max(0,math.min(dt or 0,.1))end
   if age and age>=duration then s.mapPopup.reentry[side]=nil end
  elseif phase~='intro'then
   -- Let a released Pokemon finish opening while the first command is shown.
   -- Actual moves always receive a fully opened actor.
   if origami and phase=='command'and age then age=age+math.max(0,math.min(dt or 0,.1))else age=duration end
  elseif paired then age=s.mapPopup.wildAge
  elseif stage.slideDone and (age or p and p.visible~=false and not p.invisible)then
   age=(age or(side=='playerTrainer'and -.08 or 0))+math.max(0,math.min(dt or 0,.1))
  end
  s.mapPopup.ages[side]=age
  local progress=math.max(0,math.min(1,(age or 0)/duration))
  s.actorFold[side]=progress;s.actorVisible[side]=progress>0;s.actorFall[side]=nil
  local f=record.faints and record.faints[side]
  if f and mon~=f.mon then record.faints[side]=nil;f=nil end
  if origami and f then
   s.actorFold[side]=1-math.max(0,math.min(1,f.progress or 0))
   s.actorVisible[side]=not f.complete;s.actorFall[side]=true
  end
  s.actorLean[side]=0;s.ground[side]=s.ground[side]or 0
 end end
end
return P
