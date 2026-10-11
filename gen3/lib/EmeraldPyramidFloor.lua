-- Read the engine-composed Pyramid layout. Never generate rooms or choose RNG.
local V=...
local P={}
local walls={}
for _,m in ipairs({0x260,0x261,0x262,0x265,0x268,0x26a,0x26b,0x270,0x271,0x272,0x273,0x274})do walls[m]=true end
function P.isWall(m)return walls[m]==true end
function P.kind(d)
 local id=d and(d.id or d.name)or''
 if id=='EM_BATTLE_FRONTIER_BATTLE_PYRAMID_FLOOR'then return'floor'end
 local n=tonumber(id:match('^EM_BATTLE_PYRAMID_SQUARE(%d%d)$'))
 if n and n>=1 and n<=16 then return'square'end
end
function P.profile(d)
 local k=P.kind(d);if not k then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout;local side=k=='floor'and 32 or 8
 if not(c.enabled and c.pyramidFloor.enabled and d.pair=='building__battle_pyramid'and L and L.width==side and L.height==side)then return end
 return c.homeRooms.pyramidFloor
end
function P.plan(d)
 if not P.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if P.isWall(m)then
   objects[#objects+1]={kind='pyramidWall',x=x,y=y,w=16,h=16,mid=m,noContact=true}
   mask[y*L.width+x+1]={mid=0x28d,void=true}
  end
 end end
 return objects,mask
end
function P.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.pyramidFloor
 local h=c.wallHeight*cfg.heightScale;local G=V.require('WorldGeometry')
 local function blocked(dx,dy)
  local xx,yy=o.x+dx,o.y+dy
  return xx>=0 and yy>=0 and xx<L.width and yy<L.height and P.isWall(L:midAt(xx,yy))
 end
 G.quad(out,{x,h,z},{x+16,h,z},{x+16,h,z+16},{x,h,z+16},G.uv(ts,o.mid,0,0,16,16,.5),1)
 local function side(ax,az,bx,bz)
  -- Native grey stone texels under the gold lip, lit by the same room shader.
  G.quad(out,{x+ax,h,z+az},{x+bx,h,z+bz},{x+bx,0,z+bz},{x+ax,0,z+az},G.uv(ts,0x261,3,2,13,16,.5),c.sideShade)
  if contacts then
   local vertical=ax==bx
   contacts[#contacts+1]={x+(ax+bx)/2,z+(az+bz)/2,vertical and 1.5 or 7,vertical and 7 or 1.5,c.contactStrength}
  end
 end
 if not blocked(0,-1)then side(16,0,0,0)end
 if not blocked(1,0)then side(16,16,16,0)end
 if not blocked(0,1)then side(0,16,16,16)end
 if not blocked(-1,0)then side(0,0,0,16)end
end
return P
