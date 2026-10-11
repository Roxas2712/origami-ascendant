-- Native harbor halls: high windows, quay lighting and solid crate shadows.
local V=...;local H={}
function H.profile(d)
 if not(d and d.mapType==8)then return end
 local p=V.require('EmeraldStations').profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors.harborLighting
 if not(p and p.harbor and c.enabled)then return end
 local L=d.midLayout
 if L:midAt(17,11)~=0x260 or L:midAt(18,10)~=0x3de then return end
 return c
end
function H.capture(list,o,x,z)
 if o.kind=='stationCrate'then
  local hs=V.require('DioramaConfig').emeraldInteriors.heightScale
  list[#list+1]={lo={x,0,z+o.last-o.split},hi={x+32,o.height*hs,z+o.last},wall=false}
  return true
 end
 -- Open railings and rounded bollards retain native masked contacts. A
 -- bounding cuboid here would shade the entire water basin/boarding gap.
 return o.kind=='stationHarborRails'or o.kind=='stationStorageRail'or o.kind=='stationBollard'
end
return H
