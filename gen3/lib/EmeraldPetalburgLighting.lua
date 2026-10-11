-- Nine isolated native dojo rooms: local ceiling fixtures, no light in the void.
local V=...;local P={}
function P.profile(d)
 local cfg=V.require('DioramaConfig').emeraldInteriors.petalburgLighting
 if not(cfg.enabled and d and d.mapType==8 and V.require('EmeraldPetalburgGym').profile(d))then return end
 local p={localSelection=true,ambient=cfg.ambient,night=cfg.night,sources={}}
 for _,row in ipairs(V.require('EmeraldPetalburgGym').rows)do
  for _,source in ipairs(cfg.sources)do
   local s={};for k,v in pairs(source)do s[k]=v end
   s.at={source.at[1],source.at[2],source.at[3]+row*16};p.sources[#p.sources+1]=s
  end
 end
 return p
end
function P.capture(list,o,x,z,L)
 if not o.kind:match('^petalGym')then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.petalburgGym
 local box,contour=V.require('RoomShadowContours').writer(list,x,z,all.heightScale)
 if o.kind=='petalGymWall'then
  -- The 6-pixel cornice is above the door opening. Open native doors must
  -- not inherit a solid wall blocker when the native layout cache rebuilds.
  box(0,144,26,32,c.wallHeight,c.wallHeight+.25,true)
  for col=0,8 do
   if L:midAt(o.x+col,o.y)~=0x21c then box(col*16,(col+1)*16,31.5,32,0,c.wallHeight,true)end
  end
 elseif o.kind=='petalGymStatue'then box(5,11,27.75,28.25,0,c.statueHeight-3)
 elseif o.kind=='petalGymPodium'then contour(80,24,0,c.podiumHeight,V.require('EmeraldPetalburgGym').podiumInside)end
 return true
end
return P
