-- Measured six-floor memorial lighting; preserves the native cool atmosphere.
local V=...;local P={}
function P.profile(d)
 if not(d and d.mapType==8 and V.require('EmeraldPyre').profile(d))then return end
 local c=V.require('DioramaConfig').emeraldInteriors.pyreLighting
 if c.enabled then return c.floors[tonumber((d.id or d.name):match('_(%d)F$'))]end
end
function P.capture(list,o,x,z)
 if not o.kind:match('^pyre')then return false end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.pyre
 local t=cfg.pyreLighting.blockerThickness/2;local base=o.base or 0
 local function box(a,b,u,v,low,high,wall)
  local lo,hi={x+a,(base+low)*cfg.heightScale,z+u},{x+b,(base+high)*cfg.heightScale,z+v}
  if wall then for _,old in ipairs(list)do
   if old.wall and old.lo[2]==lo[2]and old.hi[2]==hi[2]and old.lo[3]==lo[3]and old.hi[3]==hi[3]
    and lo[1]<=old.hi[1]and hi[1]>=old.lo[1]then
    old.lo[1]=math.min(old.lo[1],lo[1]);old.hi[1]=math.max(old.hi[1],hi[1]);return
   end
  end end
  list[#list+1]={lo=lo,hi=hi,wall=wall or false}
 end
 if o.kind=='pyreGrave'then
  -- Only the opaque inner stone, never the donor floor/cast-shadow pixels.
  -- The irregular outer silhouette retains its alpha-masked contact shadow.
  box(4,12,12-t,12+t,0,c.graveHeight-2)
 elseif o.kind=='pyreRaisedWall'then box(0,o.w,32-t,32+t,0,c.wallHeight,true)
 elseif o.kind=='pyreStairs'then
  local h=o.frameHeight or c.wallHeight
  if o.down then box(0,48,32-t,32+t,0,h,true)
  else
   box(0,48,32-t,32+t,h/2,h,true)
   box(0,8,32-t,32+t,0,h/2,true);box(40,48,32-t,32+t,0,h/2,true)
   for j=0,2 do box(8,40,32+j*5,37+j*5,0,(3-j)*c.stepHeight)end
  end
 elseif o.kind=='pyreFlight'then
  for j=0,7 do box(0,o.w,j*4,(j+1)*4,0,c.terraceHeight*(8-j)/8)end
 end
 -- Raised floor caps are surfaces, not floating tile-sized shadow volumes.
 return true
end
return P
