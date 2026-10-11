-- Wild-battle paper staging follows the native, localized message queue.
-- Reading time is unbounded; only the short folds gate the intro sequencer.
local D={}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
local function phase(d,name)d.phase=name;d.age=0 end
function D.new(fast,style,safari)return{phase='waitingWild',age=0,enemy=0,playerTrainer=0,player=0,fast=fast,balanced=style=='balanced',safari=safari}end
function D.message(d,kind)
 if kind=='wild'and d.phase=='waitingWild'then phase(d,'enemy')
 elseif kind=='go'and d.phase=='awaitGo'then phase(d,'go')end
end
function D.update(d,dt)
 d.age=d.age+dt
 if d.phase=='enemy'then d.enemy=ease(d.age/(d.balanced and .55 or d.fast and .35 or .7))
 elseif d.phase=='trainer'then d.playerTrainer=ease(d.age/(d.balanced and .35 or d.fast and .2 or .65))
 elseif d.phase=='throw'then
  if d.fast then
   -- Match native player_throw: release frame 32, land frame 57, emerge 12f.
   if d.age<32/60 then d.throwTime=6.25+.4*d.age/(32/60)
   elseif d.age<57/60 then d.throwTime=6.65+.8*(d.age-32/60)/(25/60)
   else d.throwTime=7.45+.8*(d.age-57/60)/.2 end
   d.player=ease((d.age-57/60)/.2)
  else d.throwTime=6.25+d.age;d.player=ease((d.age-1.2)/.8)end
  if d.age>=(d.fast and 1.2 or 2.2)then phase(d,'ready');d.throwTime=nil;d.player=1 end
 end
end
function D.beforeNative(d,waitingMessage,dialogPending)
 if d.phase=='enemy'and waitingMessage and not dialogPending then
  if d.enemy<1 then return true end
  phase(d,'trainer');return true
 elseif d.phase=='trainer'then
  if d.playerTrainer<1 then return true end
  phase(d,d.safari and'ready'or'awaitGo')
 elseif d.phase=='go'and waitingMessage and not dialogPending then
  phase(d,'throw');d.throwTime=6.25
  return false,d.fast and 'releaseGo'or nil
 elseif d.phase=='throw'then return true end
 return false
end
function D.finish(d)d.enemy=1;d.playerTrainer=1;d.player=d.safari and 0 or 1;d.throwTime=nil;phase(d,'ready')end
return D
