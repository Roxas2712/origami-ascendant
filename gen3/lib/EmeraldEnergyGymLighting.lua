-- Electrical spill follows native barrier metatiles; ash-gym pools use fixed
-- room sources. No puzzle scripts, collision, warp or visibility writes.
local V=...;local E={beams=setmetatable({},{__mode='k'})}
function E.profile(d)
 if not(d and d.mapType==8)then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.energyGymLighting
 if not c.enabled then return end
 local id=d.id or d.name
 if id=='EM_MAUVILLE_CITY_GYM'and V.require('EmeraldMauvilleGym').profile(d)then
  local L=d.midLayout;local stamp=V.require('WorldGeometry').layoutStamp(L);local cached=E.beams[L]
  if not cached or cached.stamp~=stamp then
   cached={stamp=stamp,objects={}}
   for _,o in ipairs(V.require('EmeraldMauvilleGym').plan(d))do
    if o.kind=='mauvGymBeamH'or o.kind=='mauvGymBeamV'then cached.objects[#cached.objects+1]=o end
   end
   E.beams[L]=cached
  end
  local p={};for k,v in pairs(c.mauville)do p[k]=v end;p.sources={}
  for _,s in ipairs(c.mauville.sources)do p.sources[#p.sources+1]=s end
  if c.beam.enabled then for _,o in ipairs(cached.objects)do
   local h=o.kind=='mauvGymBeamH'and cfg.mauvilleGym.poleHeight*(o.base-16)/32 or cfg.mauvilleGym.beamHeight
   local z=o.y*16+(o.kind=='mauvGymBeamH'and o.base-4 or 16)
   p.sources[#p.sources+1]={at={o.x*16+8,h*cfg.heightScale,z},radius=c.beam.radius,power=c.beam.power,
    color=c.beam.color,spread=c.beam.spread,beam=true}
  end end
  return p
 elseif(id=='EM_LAVARIDGE_TOWN_GYM_1F'or id=='EM_LAVARIDGE_TOWN_GYM_B1F')and V.require('EmeraldLavaridgeGym').profile(d)then
  return c[id:match('_1F$')and 'upper'or 'lower']
 end
end
function E.capture(list,o,x,z,L)
 if not(o.kind:match('^mauvGym')or o.kind:match('^lavaGym'))then return false end
 local all=V.require('DioramaConfig').emeraldInteriors
 local c=all[o.kind:match('^mauv')and 'mauvilleGym'or 'lavaridgeGym']
 local box,contour=V.require('RoomShadowContours').writer(list,x,z,all.heightScale)
 if o.kind=='mauvGymWall'or o.kind=='mauvGymBorder'then
  local M=V.require('EmeraldMauvilleGym')
  local height=o.kind=='mauvGymBorder'and c.borderHeight or o.y==0 and c.backWallHeight or c.partitionHeight
  contour(o.w,o.h,0,height,function(s,t)return M.covered(L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16)end)
 elseif o.kind=='mauvGymPole'then box(5,11,o.h-4.25,o.h-3.75,0,c.poleHeight*o.h/32-3)
 elseif o.kind=='mauvGymStatue'then box(5,11,27.75,28.25,0,c.statueHeight-3)
 elseif o.kind=='mauvGymPodium'then contour(64,26,0,c.podiumHeight,V.require('EmeraldMauvilleGym').podiumInside)
 elseif o.kind=='lavaGymWall'then
  box(0,16,0,32,0,(o.base or 0)+(o.y==0 and c.backWallHeight or c.partitionHeight),true)
 elseif o.kind=='lavaGymBorder'then box(0,16,0,16,0,V.require('EmeraldLavaridgeGym').wallTop(o.level,L,o.x,o.y),true)
 elseif o.kind=='lavaGymFloor'then box(0,16,0,16,0,o.base or 0,true)
 elseif o.kind=='lavaGymHole'then
  local R=V.require('EmeraldLavaridgeGym');local h=o.base or 0
  contour(16,16,0,h,function(s,t)return not R.covered(o.mid,s,t)end)
  contour(16,16,0,h-c.holeDepth,function(s,t)return R.covered(o.mid,s,t)end)
 elseif o.kind=='lavaGymStep'then
  box(0,16,0,8,0,o.base or 0,true);box(0,16,8,16,0,(o.base or 0)-c.stepHeight,true)
 elseif o.kind=='lavaGymStatue'then box(5,11,27.75,28.25,o.base or 0,(o.base or 0)+c.statueHeight-3)
 elseif o.kind=='lavaGymPodium'then
  local R=V.require('EmeraldLavaridgeGym');local h=o.base or 0
  contour(80,26,h,h+c.podiumHeight,function(s,t)return R.covered(L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16)end)
 end
 -- Animated energy is emissive, never an opaque rectangular shadow caster.
 return true
end
return E
