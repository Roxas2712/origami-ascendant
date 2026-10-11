-- Reuse captures in visually idle native phases. Native attack/intro/substitute animation
-- paths remain live; every visual pose and camera value invalidates the cache.
local V=...
local C={}
local function same(a,b)
 if type(a)~='table'then return a==b end
 if type(b)~='table'then return false end
 for k,v in pairs(a)do if not same(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
local function copy(a)
 if type(a)~='table'then return a end
 local b={};for k,v in pairs(a)do b[k]=copy(v)end;return b
end
function C.changed(owner,record,side,battler,pose,dpi,ui,anim)
 owner.battlerCaptures=owner.battlerCaptures or{}
 local rows=owner.battlerCaptures
 local battle=require('src.core.game3.battle')
 local idle=battle._phase=='command'or battle._phase=='actions'or battle._phase=='residuals'or battle._phase=='awarding'or battle._phase=='shift_prompt'or battle._phase=='ending'
 if not idle or anim._vm and anim._vm.active then rows[side]=nil;return true end
 local mon=battler and battler.mon or{}
 local scene=record.scene
 owner.captureScratch=owner.captureScratch or{}
 local visual=owner.captureScratch
 visual.pose=pose
 visual.species=battler and battler.species;visual.form=battler and battler.form
 visual.hp=mon.hp or battler and battler.hp;visual.transform=battler and battler.expTransform
 visual.personality,visual.shiny,visual.speciesMon=mon.personality,mon.shiny,mon.species
 visual.dpi,visual.angle,visual.scale,visual.vp=dpi,scene.elevationDegrees,scene.scale,scene.vp
 visual.foot,visual.ground,visual.fold=scene.feet[side],scene.ground[side],scene.actorFold and scene.actorFold[side]
 visual.bounce=ui.bounceOffset and ui.bounceOffset('mon',V.require('battle/BattleSlots').id(side))or 0
 visual.hidden=ui.targetHidden and ui.targetHidden(V.require('battle/BattleSlots').id(side))or false
 local old=rows[side]
 if old and old.record==record and old.battler==battler and same(old.visual,visual)then
  owner.captureHits=(owner.captureHits or 0)+1;return false
 end
 rows[side]={record=record,battler=battler,visual=copy(visual)}
 owner.captureMisses=(owner.captureMisses or 0)+1;return true
end
return C
