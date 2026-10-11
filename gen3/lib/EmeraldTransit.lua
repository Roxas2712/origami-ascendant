-- Measured transport interiors; rendering only, native cells/events stay intact.
local V=...
local T={}
local cycle={EM_ROUTE110_SEASIDE_CYCLING_ROAD_NORTH_ENTRANCE=true,EM_ROUTE110_SEASIDE_CYCLING_ROAD_SOUTH_ENTRANCE=true}
function T.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.transit.enabled and cycle[d.id or d.name]and d.pair=='building__shop'
  and L and L.width==16 and L.height==6 and L:midAt(5,2)==0x2a8 and L:midAt(6,4)==0x259 then return c.homeRooms.transitCycle end
end
function T.plan(d)
 local c=V.require('DioramaConfig').emeraldInteriors.transit;local L=d.midLayout;local objects,mask={},{}
 local function add(o,x,y,w,h)o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for y=0,5 do for x=0,15 do if y<2 or x==15 then mask[y*16+x+1]={mid=1,void=true}end end end
 for x=0,14 do
  local o=add({kind='wall',wallHeight=c.wallHeight,wallLast=32,wallBase=32},x,0,1,2)
  if x==5 or x==10 then o.clean={0x288,0x290}end
 end
 add({kind='transitCounter'},5,1,6,3)
 for y=2,3 do for x=5,10 do mask[y*16+x+1]=y==2 and 0x270 or 0x268 end end
 for _,x in ipairs({6,8})do
  add({kind='transitPlanter'},x,4,2,2)
  for y=4,5 do for xx=x,x+1 do mask[y*16+xx+1]=0x268 end end
 end
 for _,x in ipairs({0,14})do
  add({kind='transitPlant'},x,4,1,2)
  for y=4,5 do mask[y*16+x+1]=0x268 end
 end
 return objects,mask
end
function T.counterInside(s,t)return s>=0 and s<96 and t>=8 and t<40 and(s<16 or s>=80 or t>=28)end
function T.planterInside(s,t)
 if t<10 or t>=32 then return false end
 if t==10 then return s<31 end
 if t<29 then return s<31 end
 if t==29 then return s>=1 and s<30 end
 return s>=2 and s<29
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local leaves={[0x5a9442]=true,[0x94de73]=true,[0x63c563]=true}
function T.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.transit;local G=V.require('WorldGeometry');local BM=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(s,t,a,b,d,e,shade)
  local m,u,v=source(s,t);G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)
 end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,cfg.contactStrength}end end end
 if o.kind=='transitCounter'then
  local function zz(t)return z+16+(t-8)*24/32 end
  draw(8,40,function(s,t)return{x+s,c.counterHeight,zz(t)}end,T.counterInside)
  draw(40,48,function(s,t)return{x+s,c.counterHeight*(48-t)/8,zz(40)}end,function(s,t)return t<47 or s>0 and s<95 end)
  -- Real short side panels. No background strips or black gap-fill geometry.
  for _,edge in ipairs({{0,8,40},{96,8,40},{16,8,28},{80,8,28}})do
   local s,a,b=unpack(edge)
   patch(3,42,{x+s,c.counterHeight,zz(a)},{x+s,c.counterHeight,zz(b)},{x+s,0,zz(b)},{x+s,0,zz(a)},.96)
  end
  patch(3,42,{x+16,c.counterHeight,zz(28)},{x+80,c.counterHeight,zz(28)},{x+80,0,zz(28)},{x+16,0,zz(28)},.96)
  contact(0,96,40)
 elseif o.kind=='transitPlanter'then
  local function leaf(s,t)return leaves[rgb(BM.pixel(ts,source(s,t)))]end
  local function top(s,t)
   -- Reconstruct the complete rectangular soil bed, not a leaf-shaped hole.
   if s>=3 and s<28 and t>=12 and t<21 then return source(3,18)end
   return source(s,t)
  end
  draw(10,23,function(s,t)return{x+s,c.planterHeight,z+17+(t-10)}end,T.planterInside,top)
  draw(23,32,function(s,t)return{x+s,c.planterHeight*(32-t)/9,z+30}end,T.planterInside)
  -- The original foliage stands above the box rather than lying on its top.
  draw(11,20,function(s,t)return{x+s,c.planterHeight+(20-t),z+23}end,leaf)
  for _,s in ipairs({0,31})do patch(2,24,{x+s,c.planterHeight,z+17},{x+s,c.planterHeight,z+30},{x+s,0,z+30},{x+s,0,z+17},.95)end
  contact(1,30,30)
 elseif o.kind=='transitPlant'then
  local bg={}
  for v=0,15 do for u=0,15 do bg[rgb(BM.pixel(ts,0x268,u,v))]=true end end
  draw(3,31,function(s,t)return{x+s,c.plantHeight*(31-t)/28,z+31}end,function(s,t)return not bg[rgb(BM.pixel(ts,source(s,t)))]end)
  contact(3,13,31)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return T
