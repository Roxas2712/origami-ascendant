-- The four windowless underground entrance halls retain their native art.
local V=...;local T={}
local directions={NORTH=true,SOUTH=true,EAST=true,WEST=true}
function T.profile(d)
 if not(d and directions[(d.id or d.name or''):match('^FR_UNDERGROUND_PATH_(%u+)_ENTRANCE$')])then return end
 local c=V.require('DioramaConfig').interiors.transitSurfaces
 if not(c.lighting.enabled and V.require('InteriorTransit').profile(d))then return end
 local L=d.midLayout
 for _,a in ipairs({{0,0,0x287},{12,0,0x287},{6,1,0x28f},{2,2,0x2eb},{9,2,0x2eb},{2,7,0x284},{9,7,0x284},{7,4,0x2b4}})do
  if L:midAt(a[1],a[2])~=a[3]then return end
 end
 return c.lighting
end
function T.capture(list,o,x,z)
 if o.kind=='transitCounter'then
  local c=V.require('DioramaConfig').interiors
  local function box(a,b,back,front)
   list[#list+1]={lo={x+a,0,z+back},hi={x+b,c.transitSurfaces.counterHeight*c.heightScale,z+front},wall=false}
  end
  -- Three joined pieces preserve the open centre of the C, including its
  -- mirrored right-hand counterpart; no full-footprint shadow rectangle.
  box(1,31,13,23);box(1,31,61,71)
  box(o.right and 17 or 1,o.right and 31 or 15,23,61)
  return true
 end
 if o.kind=='transitStairs'then
  local c=V.require('DioramaConfig').interiors;local h=c.transitSurfaces.railHeight*c.heightScale
  for _,b in ipairs({{0,10,4,44},{4,10,34,14},{4,40,34,44}})do
   list[#list+1]={lo={x+b[1],0,z+b[2]},hi={x+b[3],h,z+b[4]},wall=false}
  end
  return true
 end
 return o.kind=='transitPlant'
end
return T
