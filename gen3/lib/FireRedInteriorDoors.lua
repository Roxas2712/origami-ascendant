-- Native animated lift doors on their authored room walls. This supplies only
-- presentation coordinates; native door tasks, collision and warps own state.
local V=...;local D={}
function D.doorPose(def,anim)
 if not(def and def.mapType==8 and def.midLayout and anim)then return end
 local lift=false
 for _,w in ipairs(def.warps or{})do
  local target=w.destMap or w.toMap or w.target
  if w.x==anim.x and w.y==anim.y and type(target)=='string'and target:match('^FR_.*_ELEVATOR$')then lift=true;break end
 end
 if not lift or require("src.core.game3.collision").behaviorOn(def,anim.x,anim.y)~=0x69 then return end
 local c=V.require('DioramaConfig').interiors
 local height
 if V.require('IndoorSurfaces').profile(def)==c.departmentSurfaces then
  height=c.departmentSurfaces.wallHeight*c.heightScale
 elseif V.require('RocketRoomShell').profile(def)then
  height=c.rocketShell.wallHeight
 elseif V.require('SilphWallPlants').profile(def)then
  height=c.silphWallPlants.wallHeight*V.require('Billboard').heightScale()
 elseif V.require('TrainerTowerLobby').profile(def)then
  height=c.trainerTowerLobby.wallHeight
 end
 if height then return{height=height,base=0,top=0}end
end
return D
