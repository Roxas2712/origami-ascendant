-- Ice terraces use their native elevation, including sloping wall volumes.
local V=...;local S={}
function S.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors.sootopolisLighting
 if c.enabled and d and d.mapType==8 and V.require('EmeraldSootopolisGym').profile(d)then
  return c[(d.id or d.name)=='EM_SOOTOPOLIS_CITY_GYM_1F'and'upper'or'lower']
 end
end
function S.capture(list,o,x,z,vertices,first,last,L)
 if not o.kind:match('^sootGym')then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.sootopolisGym;local scale=all.heightScale
 local R=V.require('EmeraldSootopolisGym')
 local function h(t)return o.upper and R.height(o.y+t/16)or 0 end
 local box=V.require('RoomShadowContours').writer(list,x,z,scale)
 if o.kind=='sootGymWall'then
  local base,far=h(0),h(16);local height=R.wallHeight(L,o)
  box(0,16,0,16,base,base+height,base==far)
  if base~=far then
   local b=list[#list];b.slope={z,(far-base)*scale/16}
   -- Merge only full horizontal edges on the same slope; never a corner.
   local again=true
   while again do again=false
    for i=#list-1,1,-1 do local a=list[i]
     if a.slope and a.slope[1]==b.slope[1]and a.slope[2]==b.slope[2]
      and a.lo[2]==b.lo[2]and a.hi[2]==b.hi[2]and a.lo[3]==b.lo[3]and a.hi[3]==b.hi[3]
      and(a.hi[1]==b.lo[1]or b.hi[1]==a.lo[1])then
      b.lo[1]=math.min(a.lo[1],b.lo[1]);b.hi[1]=math.max(a.hi[1],b.hi[1]);table.remove(list,i);again=true
     end
    end
   end
  end
 elseif o.kind=='sootGymRock'then box(5,11,13.75,14.25,h(14),h(14)+c.rockHeight-3)
 elseif o.kind=='sootGymStatue'then box(5,11,27.75,28.25,h(28),h(28)+c.statueHeight-3)
 elseif o.kind=='sootGymWaterfall'then
  -- Only the solid backing; the falling water is not an opaque 42px block.
  box(0,32,0,48,h(48),h(48)+c.wallHeight,true)
 elseif o.kind=='sootGymPodium'then
  local base=h(0)*scale;local top=base+c.podiumHeight*scale
  local world=V.require('RoomShadowContours').writer(list,0,0,1)
  for i=first,last,6 do
   local a,b,u,v=math.huge,-math.huge,math.huge,-math.huge;local flat=true
   for j=i,math.min(i+5,last)do local p=vertices[j]
    if math.abs(p[2]-top)>.001 then flat=false end
    a=math.min(a,p[1]);b=math.max(b,p[1]);u=math.min(u,p[3]);v=math.max(v,p[3])
   end
   if flat and b>a and v>u then world(a,b,u,v,base,top,true)end
  end
 end
 -- Elevated floor/ice/stair quads never become enclosing shadow rectangles.
 return true
end
return S
