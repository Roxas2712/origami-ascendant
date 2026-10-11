-- Fixed ceiling pools over native room floors. Large rooms keep the same
-- spacing as small ones; only the nearby emitters enter the shader budget.
local V=...
local R={cache=setmetatable({},{__mode='k'}),MAX=16,SPACING=6}
-- Lighting concept per room type. Every style has a day and a night look:
-- by day the room is lit from outside (brighter ambient, soft ceiling pools),
-- at night ambient drops and the lamps carry the room with warmer pools.
local styles=V.require('DioramaConfig').interiors.lighting
R.styles=styles
function R.style(def)
 local measured=V.require('EmeraldRoomSurfaces').profile(def)
 if measured and measured.lightingStyle then return assert(styles[measured.lightingStyle],'unknown room light style')end
 return styles[V.require('InteriorSchema').describe(def).lighting]
end
function R.plan(def)
 local L=def.midLayout
 if R.cache[L]then return R.cache[L]end
 local profile=V.require('EmeraldRoomSurfaces').profile(def)or V.require('IndoorSurfaces').profile(def)
 if profile and profile.lamps then
  local pools={}
  for _,p in ipairs(profile.lamps)do
   pools[#pools+1]={x=p.x*16,y=p.height,z=p.z*16,radius=-p.radius,color=p.color,powerScale=p.powerScale}
  end
  R.cache[L]=pools;return pools
 end
 local pools={};local spacing=R.style(def).spacing or R.SPACING
 for z0=0,L.height-1,spacing do for x0=0,L.width-1,spacing do
  local x1,z1=math.min(L.width-1,x0+spacing-1),math.min(L.height-1,z0+spacing-1)
  local cx,cz=(x0+x1)/2,(z0+z1)/2
  local best,score=nil,math.huge
  for z=z0,z1 do for x=x0,x1 do
   local c=L:cellAt(x,z)
   if c and c.coll==0 and c.mid~=0 and c.mid~=8 then
    local d=(x-cx)^2+(z-cz)^2
    if d<score then best={x=x*16+8,y=V.require('DioramaConfig').interiors.ceilingHeight,z=z*16+8,radius=-(R.style(def).radius or V.require('DioramaConfig').interiors.ceilingRadius)};score=d end
   end
  end end
  if best then pools[#pools+1]=best end
 end end
 R.cache[L]=pools
 return pools
end
function R.prepare(def,px,pz)
 local amb,lights,state=V.require("RoomLightRig").prepare(def,px,pz)
 if amb then return amb,lights,state end
 local style=R.style(def);local sorted={}
 local night=math.max(0,math.min(1,V.require('DayNight').windowLight()))
 for _,p in ipairs(R.plan(def))do
  sorted[#sorted+1]={p=p,d=(p.x-px)^2+(p.z-pz)^2}
 end
 table.sort(sorted,function(a,b)
  if a.d~=b.d then return a.d<b.d end
  if a.p.z~=b.p.z then return a.p.z<b.p.z end
  return a.p.x<b.p.x
 end)
 local lights={}
 local power=style.power+(style.nightPower-style.power)*night
 local col={};for i=1,3 do col[i]=style.color[i]*(1-night*.15*(i-1)) end
 local budget=V.require('DioramaConfig').interiors.lightBudget-(style.accent and 1 or 0)
 for i=1,math.min(budget,#sorted)do
  local p=sorted[i].p
  lights[#lights+1]={x=p.x,y=p.y,z=p.z,radius=p.radius,power=power*(p.powerScale or 1),color=p.color or col}
 end
 local measured=V.require('EmeraldRoomSurfaces').profile(def)
 if measured and measured.accent and not measured.noAccent then
  local a=measured.accent
  lights[#lights+1]={x=a.x*16,y=20,z=a.z*16,radius=-a.radius,power=a.power,color=a.color}
 elseif not measured and style.accent and def.midLayout and not V.require('IndoorSurfaces').profile(def) then
  -- An accent belongs to the actual healing device, never the centre of a
  -- room or the link-service desks upstairs. No source, no pink light.
  local L=def.midLayout
  if def.pair=='network' then
   for z=0,L.height-1 do for x=0,L.width-2 do
    if L:midAt(x,z)==0x2aa and L:midAt(x+1,z)==0x2ab and #lights<V.require('DioramaConfig').interiors.lightBudget then
     lights[#lights+1]={x=(x+1)*16,y=20,z=(z+1)*16,radius=-style.accent.radius,power=style.accent.power,color=style.accent.color}
    end
   end end
  end
 end
 local amb={};for i=1,3 do amb[i]=style.ambient[i]+(style.night[i]-style.ambient[i])*night end
 return amb,lights
end
function R.release()R.cache=setmetatable({},{__mode='k'})end
return R
