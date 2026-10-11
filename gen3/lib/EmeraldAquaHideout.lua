-- Measured Aqua entry surfaces. Native map, collision and scripts stay owned
-- by the engine. B2 has its own measured plan in EmeraldAquaBasement.
local V=...
local R={}
local rock={};for _,m in ipairs({0x73,0x74,0x75,0x7b,0x7c,0x7d,0x89})do rock[m]=true end
local rails={};for _,m in ipairs({0x25d,0x269,0x25e,0x260,0x2a4,0x268,0x2ac,0x265,0x266,0x279,0x2aa,0x2ad,0x295,0x296})do rails[m]=true end
function R.kind(d)return d and(d.id or d.name)=='EM_AQUA_HIDEOUT_1F'end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d and d.midLayout
 if R.kind(d)and c.enabled and c.aquaHideout.enabled and d.pair=='general__facility'and L and L.width==28 and L.height==30 and L:midAt(22,1)==0x2cc and L:midAt(13,28)==0x2c9 then return c.homeRooms.aquaEntry end
end
-- Canonical native 32x48 pump contour; wall-mounted versions start 8px lower.
local heads={ [1]='.............######.............',[2]='...........##########...........',[3]='..........############..........',[4]='.........##############.........',[5]='.........##############.........',[6]='........################........',[7]='........################........',[8]='........################........',[9]='....###.################........',[10]='...#####################........',[11]='..######################........',[12]='..######################..#####.',[13]='.###############################'}
function R.machineInside(s,t)
 if s<0 or s>=32 or t<1 or t>=48 then return false end
 return t>=14 or heads[t]:sub(s+1,s+1)=='#'
end
function R.isRock(m)return rock[m]==true end
function R.isRail(m)return rails[m]==true end
-- The four measured native floor colours are absent from the metal rail.
local floorColors={[0xdedec5]=true,[0x6b7b42]=true,[0x849473]=true,[0xadb594]=true}
local waterColors={[0x425abd]=true,[0x3a529c]=true,[0x526bd6]=true,[0x6b84d6]=true,[0x8ca5de]=true}
function R.railInside(ts,m,u,v,water)
 local r,g,b=V.require('BuildingMesh').pixel(ts,m,u,v)
 local rgb=math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)
 return not floorColors[rgb]and not(water and waterColors[rgb])
end
local pipeMids={[0x21f]=true,[0x227]=true,[0x22f]=true,[0x237]=true,[0x2b1]=true}
function R.pipeInside(m,u,v)
 if not pipeMids[m]then return false end
 if m==0x237 then return true end
 if m==0x2b1 then return false end
 if m==0x21f and v==0 then return u%8~=0 and u%8~=7 end
 return true
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,e)
  local o=e or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=0x228,void=true}end end
  return o
 end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if m==0x201 then mask[y*L.width+x+1]={mid=m,void=true}
  elseif R.isRock(m)then add('aquaRock',x,y,1,1,{mid=m})
  elseif R.isRail(m)then add('aquaRail',x,y,1,1,{mid=m})end
 end end
 add('aquaWall',6,0,21,3,{wallMachines=true})
 add('aquaCorner',5,0,1,5)
 add('aquaWall',1,2,4,3)
 -- Native outside border is a low cutaway rim, not a screen-filling wall.
 add('aquaRim',1,5,1,24);add('aquaRim',26,3,1,26)
 for _,p in ipairs({{6,0},{13,0}})do add('aquaMachine',p[1],p[2],2,4,{start=8,base=56,wall=true})end
 for _,p in ipairs({{2,15},{24,18},{2,22},{24,23}})do add('aquaMachine',p[1],p[2],2,3,{start=0,base=48})end
 for _,p in ipairs({{2,4,1,5},{3,4,1,5},{4,4,1,4},{25,0,1,4},{25,8,1,6}})do add('aquaPipe',p[1],p[2],p[3],p[4])end
 return objects,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.aquaHideout;local G=V.require('WorldGeometry');local first=#out+1
 local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project,source)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source or src,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function donor(m,a,b)draw(a,b,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)return m,s%16,t%16 end)end
 local function contact(w,zz)if contacts then for xx=4,w-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,c.contactStrength}end end end
 if o.kind=='aquaWall'then
  local function clean(s,t)
   local m,u,v=src(s,t)
   if o.wallMachines and (s<32 or s>=112 and s<144)then m=t<16 and 0x219 or t<32 and 0x221 or 0x229 end
   -- Orange pipe head is separate from its wall background.
   if m==0x21f then m=0x221 end
   return m,u,v
  end
  draw(0,40,nil,function(s,t)return{x+s,c.wallHeight*(40-t)/40,z+40}end,clean)
  draw(40,48,nil,function(s,t)return{x+s,0,z+t}end,clean)
 elseif o.kind=='aquaCorner'then
  -- The two rear walls are offset by two tiles. A connected return wall
  -- bridges them; the native column must not be left lying on the floor.
  local h=c.wallHeight
  G.quad(out,{x,h,z+40},{x+16,h,z+40},{x+16,h,z+72},{x,h,z+72},G.uv(ts,0x219,0,2,16,4,.5),1)
  for t=0,39 do
   local m=t<16 and 0x219 or t<32 and 0x221 or 0x229
   local a=h*(40-t)/40;local b=h*(39-t)/40
   G.quad(out,{x+16,a,z+40},{x+16,a,z+72},{x+16,b,z+72},{x+16,b,z+40},G.uv(ts,m,0,t%16,16,t%16+1,.5),c.sideShade)
   G.quad(out,{x,a,z+72},{x+16,a,z+72},{x+16,b,z+72},{x,b,z+72},G.uv(ts,m,0,t%16,16,t%16+1,.5),1)
  end
  donor(0x228,72,80)
 elseif o.kind=='aquaMachine'then
  if not o.wall then donor(0x228,0,o.h)else donor(0x228,40,o.h)end
  draw(o.start+1,o.base,function(s,t)return R.machineInside(s,t-o.start)end,function(s,t)return{x+s,c.machineHeight*(o.base-t)/47,z+o.base}end)
  contact(o.w,o.base)
 elseif o.kind=='aquaRock'or o.kind=='aquaRim'then
  local h=o.kind=='aquaRock'and c.rockHeight or c.rimHeight
  draw(0,o.h,nil,function(s,t)return{x+s,h,z+t}end)
  local function side(a,b,m,u,v)
   G.quad(out,{x+a[1],h,z+a[2]},{x+b[1],h,z+b[2]},{x+b[1],0,z+b[2]},{x+a[1],0,z+a[2]},G.uv(ts,m,0,8,16,16,.5),c.sideShade)
  end
  for _,edge in ipairs({{{0,0},{o.w,0},0,-1},{{o.w,0},{o.w,o.h},1,0},{{o.w,o.h},{0,o.h},0,1},{{0,o.h},{0,0},-1,0}})do
   local nx,ny=o.x+edge[3],o.y+edge[4]
   local adjacent=o.kind=='aquaRock'and nx>=0 and nx<L.width and ny>=0 and ny<L.height and R.isRock(L:midAt(nx,ny))
   if not adjacent then side(edge[1],edge[2],o.kind=='aquaRock'and 0x75 or 0x20a,8,8)end
  end
 elseif o.kind=='aquaPipe'or o.kind=='aquaRail'then
  -- Original pipe runs sit just above the floor; every masked edge closes
  -- down to it. No floor colours or adjacent wall texels enter this mesh.
  local rail=o.kind=='aquaRail';local height=rail and c.railHeight or c.pipeHeight
  if not rail then donor(0x228,o.y==0 and 40 or 0,o.h)end
  local function inside(s,t)
   if s<0 or t<0 or s>=o.w or t>=o.h then return false end
   local m,u,v=src(s,t);return rail and R.railInside(ts,m,u,v,o.water)or not rail and R.pipeInside(m,u,v)
  end
  if rail then draw(0,o.h,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)
   local m,u,v=src(s,t);return inside(s,t)and 0x228 or m,u,v
  end)end
  draw(0,o.h,inside,function(s,t)return{x+s,height,z+t}end)
  for t=0,o.h-1 do for s=0,o.w-1 do if inside(s,t)then
   local function edge(a,b)
    local m,u,v=src(s,t)
    G.quad(out,{x+a[1],height,z+a[2]},{x+b[1],height,z+b[2]},
     {x+b[1],0,z+b[2]},{x+a[1],0,z+a[2]},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)
   end
   if not inside(s-1,t)then edge({s,t},{s,t+1})end
   if not inside(s+1,t)then edge({s+1,t+1},{s+1,t})end
   if not inside(s,t-1)then edge({s+1,t},{s,t})end
   if not inside(s,t+1)then edge({s,t+1},{s+1,t+1})end
  end end end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
