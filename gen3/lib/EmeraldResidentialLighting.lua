-- Exact-layout lighting for wood bedroom, Rustboro and Sootopolis homes.
local V=...;local H={cache=setmetatable({},{__mode='k'})}
local rooms
local function stamp(t)
 local keys={};for k in pairs(t)do keys[#keys+1]=k end;table.sort(keys)
 local a={};for _,k in ipairs(keys)do local v=t[k];a[#a+1]=k..'='..(type(v)=='table'and stamp(v)or tostring(v))end;return table.concat(a,';')
end
function H.profile(d)
 if not(d and d.pair=='building__generic_building'and(d.id or''):match('^EM_'))then return end
 rooms=rooms or V.data('EmeraldResidentialLayouts');local room=rooms[d.id];if not room then return end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.residentialLighting;local L=d.midLayout
 if not(all.enabled and c.enabled and d.mapType==8 and L and L.width==room.width and L.height==room.height)then return end
 local i=0;for m in room.rows:gmatch('%x+')do if L:midAt(i%L.width,math.floor(i/L.width))~=tonumber(m,16)then return end;i=i+1 end
 for _,a in ipairs(room.anchors)do if L:midAt(a[2],a[3])~=a[4]then return end end
 local signature=d.id..stamp(c);local hit=H.cache[L];if hit and hit.signature==signature then return hit.profile end
 local sources,regions={},{};local windows=0
 for _,a in ipairs(room.anchors)do if a[1]=='window'then windows=windows+1 end end
 for _,a in ipairs(room.anchors)do
  local kind=a[1];local role=c[kind];local window=kind=='window'
  sources[#sources+1]={at={(a[2]+a[5]/2)*16,role.height,a[3]*16+role.forward},radius=role.radius,power=role.power/(window and math.sqrt(windows)or 1),nightPower=role.nightPower,color=window and c.windowColor or c.ceilingColor,nightColor=window and c.windowNightColor or c.ceilingColor,spread=role.spread,direction=window and{0,-.45,1}or{0,-1,0},cone=window and .1 or -.1}
  if window then regions[#regions+1]={at={a[2],a[3]},rect={0,0,16,32},palette=c.glassPalette}end
 end
 local p={ambient=c.ambient,night=c.nightAmbient,sources=sources}
 if #regions>0 then p.emission={enabled=true,day=c.emissionDay,night=c.emissionNight,bloom=c.emissionBloom,regions=regions}end
 H.cache[L]={signature=signature,profile=p};return p
end
function H.capture(list,o,x,z)
 if not o.residentialHome then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.residentialLighting;local scale=all.heightScale
 local function box(a,b,back,front,low,high,wall)list[#list+1]={lo={x+a,low*scale,z+back},hi={x+b,high*scale,z+front},wall=wall or false}end
 if o.kind=='apartmentPartition'then
  local a=all.apartments
  if o.axis=='z'then box(2,14,32,o.front,0,a.wallHeight,true)
  else box(2,o.w,48-a.partitionDepth,48,0,a.wallHeight,true)end
 elseif o.kind=='partition'then box(1,1+o.width,o.start,o.front,0,o.height,true)
 elseif o.kind~='fold'then return false
 elseif o.faucet then
  box(1,o.w-1,o.front-o.depth,o.front,0,o.height)
  box(6,13,o.front-14-.25,o.front-14+.25,o.height,o.height+9)
 elseif o.residentialTable then
  box(0,o.w,o.front-o.depth,o.front,o.height-c.tableThickness,o.height)
  if o.cup then box(17,27,o.front-12-.25,o.front-12+.25,o.height,o.height+9)end
 else return false end
 return true
end
return H
