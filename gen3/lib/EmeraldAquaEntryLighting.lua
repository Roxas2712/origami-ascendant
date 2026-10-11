-- Fixed industrial lighting. Shadow geometry follows the native raised surfaces,
-- never the donor floor, pool rectangles or collision grid.
local V=...;local R={}
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors.aquaEntryLighting
 if c.enabled and d and d.mapType==8 and V.require('EmeraldAquaHideout').profile(d)then return c.light end
end
function R.capture(list,o,x,z,vertices,first,last)
 if not o.kind:match('^aqua')then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.aquaHideout
 local depth=all.aquaEntryLighting.shadowThickness
 local box=V.require('RoomShadowContours').writer(list,x,z,all.heightScale)
 if o.kind=='aquaWall'then
  box(0,o.w,40-depth/2,40+depth/2,0,c.wallHeight,true)
 elseif o.kind=='aquaCorner'then
  box(0,16,40,72,0,c.wallHeight,true)
 elseif o.kind=='aquaRock'or o.kind=='aquaRim'then
  box(0,o.w,0,o.h,0,o.kind=='aquaRock'and c.rockHeight or c.rimHeight,true)
 elseif o.kind=='aquaMachine'then
  local native=V.require('EmeraldAquaHideout');local start=#list+1
  for t=1,47 do local s=0
   while s<32 do
    if native.machineInside(s,t)then
     local a=s;repeat s=s+1 until s==32 or not native.machineInside(s,t)
     box(a,s,o.base-depth/2,o.base+depth/2,c.machineHeight*(47-t)/47,c.machineHeight*(48-t)/47,true)
    else s=s+1 end
   end
  end
  -- Merge vertical runs only when their complete footprint matches. A pump's
  -- broad body becomes one volume, while crown notches remain open.
  for i=#list,start,-1 do local b=list[i]
   for j=start,i-1 do local a=list[j]
    if a.lo[1]==b.lo[1]and a.hi[1]==b.hi[1]and a.lo[3]==b.lo[3]and a.hi[3]==b.hi[3]
     and(a.hi[2]==b.lo[2]or b.hi[2]==a.lo[2])then
     a.lo[2]=math.min(a.lo[2],b.lo[2]);a.hi[2]=math.max(a.hi[2],b.hi[2]);table.remove(list,i);break
    end
   end
  end
 elseif o.kind=='aquaPipe'or o.kind=='aquaRail'then
  local h=(o.kind=='aquaPipe'and c.pipeHeight or c.railHeight)*all.heightScale
  local worldBox=V.require('RoomShadowContours').writer(list,0,0,1)
  for i=first,last,6 do
   local a,b,u,v=math.huge,-math.huge,math.huge,-math.huge;local top=true
   for j=i,i+5 do local p=vertices[j];top=top and math.abs(p[2]-h)<.001
    a=math.min(a,p[1]);b=math.max(b,p[1]);u=math.min(u,p[3]);v=math.max(v,p[3])
   end
   if top and b>a and v>u then worldBox(a,b,u,v,0,h,true)end
  end
 else return false end
 return true
end
return R
