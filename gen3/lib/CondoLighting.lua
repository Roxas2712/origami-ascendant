-- Celadon condominium: independent stairwells, office/lounge and corridor.
local V=...;local C={cache=setmetatable({},{__mode='k'})}
local function stamp(t)
 local keys={};for k in pairs(t)do keys[#keys+1]=k end;table.sort(keys)
 local out={};for _,k in ipairs(keys)do local v=t[k];out[#out+1]=k..'='..(type(v)=='table'and stamp(v)or tostring(v))end
 return table.concat(out,';')
end
function C.profile(d)
 if not(d and d.mapType==8 and d.midLayout and (d.renderPair or d.pair)=='building__rom_082d4f8c'
  and(d.id or d.name or''):match('^FR_CELADON_CITY_CONDOMINIUMS_[123]F$'))then return end
 local all=V.require('DioramaConfig').interiors.condoSurfaces;local c=all.lighting
 if not(c.enabled and V.require('IndoorSurfaces').profile(d)==all)then return end
 local floor=tonumber((d.id or d.name):match('_(%d)F$'));local L=d.midLayout
 local windows=floor==1 and {4,12}or floor==2 and {2,4,11,13}or{2,4,10,12}
 for _,x in ipairs(windows)do if L:midAt(x,0)~=0x2f8 or L:midAt(x,1)~=0x2f9 then return end end
 if L:midAt(7,11)~=0x2fa or L:midAt(7,12)~=0x2fb then return end
 local key=floor..stamp(c);local hit=C.cache[L];if hit and hit.key==key then return hit.profile end
 local sources,regions={},{}
 for _,at in ipairs(c.ceiling.positions)do
  local r=c.ceiling
  sources[#sources+1]={at={at[1],r.height,at[2]},radius=r.radius,power=r.power,nightPower=r.nightPower,
   color=floor==3 and at[1]<112 and at[2]>80 and c.officeColor or c.ceilingColor,spread=r.spread}
 end
 for _,x in ipairs(windows)do
  local r=c.window
  sources[#sources+1]={at={x*16+8,r.height,32+r.forward},radius=r.radius,power=r.power,nightPower=r.nightPower,
   color=c.windowColor,spread=r.spread,direction={0,-.25,1},cone=r.cone}
  regions[#regions+1]={at={x,0},rect={3,12,10,8},palette=c.glassPalette}
 end
 local p={ambient=c.ambient,night=c.nightAmbient,sources=sources,localSelection=true,
  emission={enabled=true,day=c.emissionDay,night=c.emissionNight,bloom=c.emissionBloom,regions=regions}}
 C.cache[L]={key=key,profile=p};return p
end
function C.capture(list,o,x,z)
 if not o.kind:match('^condo')then return false end
 if o.kind=='condoWall'then return false end
 local all=V.require('DioramaConfig').interiors;local c=all.condoSurfaces
 local function box(a,b,back,front,low,high,wall)
  list[#list+1]={lo={x+a,low*all.heightScale,z+back},hi={x+b,high*all.heightScale,z+front},wall=wall or false}
 end
 if o.kind=='condoPartition'then
  local r=c.partitionRim
  box(0,r,32,192,0,c.wallHeight,true);box(32-r,32,32,192,0,c.wallHeight,true)
  box(0,32,192,208,0,c.wallHeight,true)
 elseif o.kind=='condoFold'and o.height>c.stoolHeight then
  local low=o.height-c.lighting.slabThickness;local back=o.front-o.depth
  if o.cups then
   -- Octagonal tabletop, with open space under it and clipped outer corners.
   box(1,15,back+6,o.front-6,low,o.height)
   box(15,49,back,o.front,low,o.height)
   box(49,63,back+6,o.front-6,low,o.height)
  else box(1,o.w*16-1,back,o.front,low,o.height)end
  if o.computer then box(8,32,back+9.75,back+10.25,o.height,o.height+22)end
 elseif o.kind=='condoSofa'then
  box(1,o.w*16-1,12,28,0,c.sofaSeatHeight)
  box(1,o.w*16-1,11.75,12.25,c.sofaSeatHeight,c.sofaBackHeight)
 elseif o.kind=='condoSideSofa'then
  box(12,16,2,46,0,c.sofaBackHeight);box(2,12,5,43,0,c.sofaSeatHeight)
 end
 -- Thin stair rails and stools retain contact shading, never a full shadow box.
 return true
end
return C
