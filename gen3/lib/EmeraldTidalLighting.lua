-- S.S. Tidal: real portholes, cabin ceiling lights and open stairwells.
local V=...;local T={}
function T.profile(d)
 if not(d and d.mapType==8)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.tidalLighting
 if not c.enabled then return end
 if V.require('EmeraldShipCabins').profile(d)then return c.cabins end
 if V.require('EmeraldShipCorridor').profile(d)then return c.corridor end
 if V.require('EmeraldShipInteriors').profile(d)then return c.cargo end
end
function T.capture(list,o,x,z)
 if not o.kind:match('^tidal')then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.ship
 local scale=all.heightScale;local r=all.tidalLighting
 local function box(a,b,back,front,low,high,wall)
  list[#list+1]={lo={x+a,low*scale,z+back},hi={x+b,high*scale,z+front},wall=wall or false}
 end
 local thin=r.blockerThickness/2
 if o.kind=='tidalCrate'then
  local front=o.h-1;box(0,o.w,front-(o.h-16),front,0,c.crateHeight)
 elseif o.kind=='tidalCabinSide'then
  local a=o.left and -4 or 0;box(a,a+4,0,o.h,0,c.cabinSideHeight,true)
 elseif o.kind=='tidalCabinBed'then
  -- L-shaped bedside unit and bed remain separate, including mirrored beds.
  local function mirror(a,b)return o.reverse and 31-b or a,o.reverse and 31-a or b end
  box(0,32,12,22,0,c.bedsideHeight)
  local a,b=mirror(0,8);box(a,b,22,43,0,c.bedsideHeight)
  a,b=mirror(8,31);box(a,b,24,42,c.bedHeight-r.slabThickness,c.bedHeight)
  box(a,b,24-thin,24+thin,c.bedHeight,c.bedHeadHeight)
 elseif o.kind=='tidalCabinTable'then
  box(1,o.w-1,3,24,c.tableHeight-r.slabThickness,c.tableHeight)
 elseif o.kind=='tidalCabinDesk'then
  box(1,31,4,14,c.tableHeight-r.slabThickness,c.tableHeight)
 elseif o.kind=='tidalCorridorFront'then
  box(0,o.w,32-thin,32+thin,0,c.cabinWallHeight,true)
 elseif o.kind=='tidalCorridorBlock'then
  box(0,4,12,112,0,c.cabinWallHeight,true)
  box(o.w-4,o.w,12,112,0,c.cabinWallHeight,true)
  for col=0,11 do if col~=1 and col~=4 and col~=7 and col~=10 then
   box(col*16,(col+1)*16,12,16,0,c.cabinCutawayHeight,true)
  end end
 end
 -- Chairs, round bins and stair rails keep masked contacts. Never enclose
 -- the downward flights or the open cabin-block cutaway in a shadow cube.
 return true
end
return T
