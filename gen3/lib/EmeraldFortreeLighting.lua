-- Fixed room lights and native-angle shadows for the bamboo gym.
local V=...;local F={}
function F.appendMoving(d,boxes)
 if not V.require('DioramaConfig').emeraldInteriors.fortreeLighting.gateShadows then return end
 for _,b in ipairs(V.require('EmeraldRotatingGates').shadowBoxes(d))do boxes[#boxes+1]=b end
end
function F.profile(d)
 if not(d and d.mapType==8 and(d.id or d.name)=='EM_FORTREE_CITY_GYM')then return end
 local c=V.require('DioramaConfig').emeraldInteriors.fortreeLighting
 if not c.enabled or not V.require('EmeraldFortreeGym').profile(d)then return end
 local p={};for k,v in pairs(c.room)do p[k]=v end;p.movingShadows=F.appendMoving;return p
end
function F.capture(list,o,x,z)
 if not o.kind:match('^fortGym')then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.fortreeGym
 local box,contour=V.require('RoomShadowContours').writer(list,x,z,all.heightScale)
 if o.kind=='fortGymPole'then box(3,13,15,24,0,c.poleHeight,true)
 elseif o.kind=='fortGymPost'then box(1,7,4,8,0,c.postHeight,true)
 elseif o.kind=='fortGymWall'then box(1,15,o.h-5,o.h,0,c.wallHeight*o.h/32,true)
 elseif o.kind=='fortGymStatue'then box(5,11,27.75,28.25,0,c.statueHeight-3)
 elseif o.kind=='fortGymPodium'then contour(80,24,0,c.podiumHeight,V.require('EmeraldPetalburgGym').podiumInside)end
 return true
end
return F
