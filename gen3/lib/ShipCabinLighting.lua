-- Two native cabin layouts: actual portholes, table light and bedside fill.
local V=...;local S={}
function S.profile(d)
 if not(d and d.mapType==8)then return end
 local p=V.require('InteriorShipCabins').profile(d)
 local c=V.require('DioramaConfig').interiors.shipCabins.lighting
 if not(p and c.enabled)then return end
 local L=d.midLayout
 if p.green then
  if L:midAt(3,1)~=0x33a or L:midAt(3,5)~=0x328 then return end
 else
  if L:midAt(1,1)~=0x33b or L:midAt(4,1)~=0x33b or L:midAt(3,2)~=0x308 then return end
 end
 return p.green and c.green or c.gold
end
function S.capture(list,o,x,z)
 if not o.kind:match('^shipCabin')or o.kind=='shipCabinWall'then return false end
 local all=V.require('DioramaConfig').interiors;local c=all.shipCabins;local scale=all.heightScale
 local function box(a,b,back,front,low,high)
  list[#list+1]={lo={x+a,low*scale,z+back},hi={x+b,high*scale,z+front},wall=false}
 end
 local thickness=c.lighting.slabThickness
 if o.kind=='shipCabinBed'then
  box(15,33,32-c.bedDepth,32,c.bedHeight-thickness,c.bedHeight)
  box(16,32,32-c.bedDepth-.25,32-c.bedDepth+.25,c.bedHeight,c.headHeight)
 elseif o.kind=='shipCabinDesk'then box(9,31,o.front-c.deskDepth,o.front,c.tableHeight-thickness,c.tableHeight)
 elseif o.kind=='shipCabinTable'then box(1,47,o.front-c.tableDepth,o.front,c.tableHeight-thickness,c.tableHeight)end
 -- Plants/chairs retain alpha silhouettes and contacts, rugs remain flat.
 return true
end
return S
