-- Spatial lighting for the two measured rock/dark gyms. Native darkness is
-- applied later by EmeraldGymVisibility; this module never changes flash state.
local V=...;local G={}
function G.profile(d)
 if not(d and d.mapType==8)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.rockGymLighting
 if not c.enabled then return end
 if (d.id or d.name)=='EM_RUSTBORO_CITY_GYM'and V.require('EmeraldRustboroGym').profile(d)then return c.rustboro end
 if (d.id or d.name)=='EM_DEWFORD_TOWN_GYM'and V.require('EmeraldDewfordGym').profile(d)then return c.dewford end
end
function G.capture(list,o,x,z)
 local rock=o.kind:match('^rustGym');local dark=o.kind:match('^dewGym')
 if not(rock or dark)then return false end
 local all=V.require('DioramaConfig').emeraldInteriors
 local c=all[rock and 'rustboroGym'or 'dewfordGym']
 local function box(a,b,u,v,low,high,merge)
  local q={lo={x+a,low*all.heightScale,z+u},hi={x+b,high*all.heightScale,z+v},wall=false,gymVolume=merge}
  -- Merge only full shared edges, never the bounding rectangle of an L shape.
  if merge then
   local again=true
   while again do again=false
    for i=#list,1,-1 do local old=list[i]
     if old.gymVolume and old.lo[2]==q.lo[2]and old.hi[2]==q.hi[2]then
      local axis
      if old.lo[3]==q.lo[3]and old.hi[3]==q.hi[3]and(old.hi[1]==q.lo[1]or q.hi[1]==old.lo[1])then axis=1
      elseif old.lo[1]==q.lo[1]and old.hi[1]==q.hi[1]and(old.hi[3]==q.lo[3]or q.hi[3]==old.lo[3])then axis=3 end
      if axis then q.lo[axis]=math.min(q.lo[axis],old.lo[axis]);q.hi[axis]=math.max(q.hi[axis],old.hi[axis]);table.remove(list,i);again=true end
     end
    end
   end
  end
  list[#list+1]=q
 end
 local function contour(w,h,height,inside)
  for t=0,h-1 do local s=0
   while s<w do
    if inside(s,t)then local first=s;repeat s=s+1 until s==w or not inside(s,t);box(first,s,t,t+1,0,height,true)
    else s=s+1 end
   end
  end
 end
 if o.kind=='rustGymRock'then
  contour(16,16,c.rockHeight,function(s,t)return V.require('EmeraldRustboroGym').topInside(o.mid,s,t)end)
 elseif o.kind=='dewGymCap'or o.kind=='dewGymFront'then
  local height=o.x*16<112 and o.y*16<48 and c.backWallHeight or c.wallHeight
  if o.kind=='dewGymFront'then box(0,16,0,32,0,height,true)
  else contour(16,16,height,function(s,t)return V.require('EmeraldDewfordGym').covered(o.mid,s,t)end)end
 elseif o.kind=='rustGymWall'then
  box(14,162,31.75,32.25,0,c.wallHeight)
 elseif o.kind=='rustGymStatue'or o.kind=='dewGymStatue'then
  -- Narrow opaque stone core, not the donor floor or transparent shoulders.
  box(5,11,27.75,28.25,0,c.statueHeight-3)
 elseif o.kind=='dewGymPillar'then box(0,16,31.75,32.25,0,c.pillarHeight)
 elseif o.kind=='rustGymPodium'then
  contour(80,26,c.podiumHeight,V.require('EmeraldRustboroGym').podiumInside)
 elseif o.kind=='dewGymPodium'then
  contour(64,24,c.podiumHeight,V.require('EmeraldDewfordGym').podiumInside)
  for j=0,3 do local h=c.podiumHeight*(4-j)/4
   box(3,17,24+j*2,26+j*2,0,h);box(47,61,24+j*2,26+j*2,0,h)
  end
 end
 return true
end
return G
