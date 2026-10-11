-- Route 117: original tile art, separated into wall, complete rugs and furniture.
local V=...
local D={}
function D.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.dayCare.enabled and(d.id or d.name)=='EM_ROUTE117_POKEMON_DAY_CARE'
 and d.pair=='building__pokemon_day_care'and L and L.width==12 and L.height==10
 and L:midAt(2,3)==0x221 and L:midAt(6,8)==0x240 then return c.homeRooms.dayCare end
end
function D.plan(d)
 local c=V.require('DioramaConfig').emeraldInteriors.dayCare;local objects,mask={},{}
 local function floor(x,y,w,h,m)for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*12+xx+1]=m or 0x201 end end end
 local function add(kind,x,y,w,h)local o={kind=kind,x=x,y=y,w=w*16,h=h*16,noContact=true};objects[#objects+1]=o;return o end
 for y=0,9 do for x=0,11 do if y<2 or y==9 then mask[y*12+x+1]={mid=1,void=true}end end end
 for x=0,11 do
  local o=add('wall',x,0,1,2);o.wallHeight=c.wallHeight;o.wallLast=32;o.wallBase=32
  if x==4 or x==5 or x==6 or x==10 then
   o.clean={0x209,0x211};o.nativeUpper=x~=10
   if x==5 or x==6 then o.keepBefore=29 elseif x==4 then o.keepBefore=24 end
  end
 end
 add('dayCounter',0,1,5,3);floor(0,2,5,2)
 add('dayPC',10,0,1,3);floor(10,2,1,1)
 for _,x in ipairs({5,6})do add('dayChair',x,1,1,2);floor(x,2,1,1)end
 for _,y in ipairs({5,7})do add('dayPlant',0,y,1,2);floor(0,y,1,2)end
 add('dayTable',10,5,2,2);floor(10,5,2,3,0x204)
 for _,p in ipairs({{2,4},{11,4},{9,6}})do add('dayStool',p[1],p[2],1,1);floor(p[1],p[2],1,1,p[1]>6 and 0x204 or 0x201)end
 -- The rug reaches right under every table/chair; preserve its checker phase.
 floor(7,4,5,4,0x204)
 add('dayFence',6,8,6,1);floor(6,8,6,1)
 add('daySideFence',6,7,1,1);floor(6,7,1,1)
 return objects,mask
end
function D.actorHeight(d,x,z)
 if not D.profile(d)then return end
 local px,pz=x+8,z+16;local cfg=V.require('DioramaConfig').emeraldInteriors
 for _,p in ipairs({{2,4},{11,4},{9,6}})do
  if px>=p[1]*16+2 and px<p[1]*16+14 and pz>=p[2]*16+6 and pz<=p[2]*16+16 then
   return cfg.dayCare.seatHeight*cfg.heightScale
  end
 end
end
function D.tableInside(s,t)
 if t<2 or t>=32 then return false end
 if t==2 then return s>=1 and s<31 end
 if t<25 then return true end
 if t<28 then return s>=1 and s<31 end
 if t==31 then return s>=2 and s<5 or s>=27 and s<30 end
 return s>=1 and s<6 or s>=26 and s<31
end
function D.stoolInside(s,t)
 if t<1 or t>=15 then return false end
 if t<13 then return s>=2 and s<14 end
 if t==14 then return s>=3 and s<5 or s>=10 and s<12 end
 return s>=2 and s<5 or s>=10 and s<13
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function D.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.dayCare;local G=V.require('WorldGeometry');local BM=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(m,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(xx,zz,rx,rz)if contacts then contacts[#contacts+1]={x+xx,z+zz,rx,rz,cfg.contactStrength}end end
 local bg={}
 for _,m in ipairs({0x201,0x206,0x207,0x21e})do for v=0,15 do for u=0,15 do bg[rgb(BM.pixel(ts,m,u,v))]=true end end end
 local function cut(s,t)return not bg[rgb(BM.pixel(ts,source(s,t)))]end
 if o.kind=='dayPlant'then
  draw(0,32,function(s,t)return{x+s,c.plantHeight*(32-t)/32,z+32}end,cut);contact(8,32,5,2)
 elseif o.kind=='dayPC'then
  draw(8,40,function(s,t)return{x+s,c.pcHeight*(40-t)/32,z+42}end,function(s,t)
   local inset=t==8 and 3 or(t==9 or t==39)and 2 or(t==10 or t==38)and 1 or 0
   return s>=inset and s<16-inset
  end);contact(8,42,5,2)
 elseif o.kind=='dayChair'then
  local function inside(s,t)return t>13 or s>=1 and s<15 end
  draw(13,24,function(s,t)return{x+s,c.chairBackHeight-(t-13)*(c.chairBackHeight-c.seatHeight)/11,z+24}end,inside)
  draw(24,29,function(s,t)return{x+s,c.seatHeight,z+24+(t-24)*7/5}end,inside)
  draw(29,32,function(s,t)return{x+s,c.seatHeight*(32-t)/3,z+31}end,inside);contact(8,31,6,2)
 elseif o.kind=='dayStool'then
  draw(1,10,function(s,t)return{x+s,c.seatHeight,z+6+(t-1)*10/9}end,D.stoolInside)
  draw(10,15,function(s,t)return{x+s,c.seatHeight*(15-t)/5,z+16}end,D.stoolInside)
  for _,s in ipairs({2,14})do patch(0x230,3,9,{x+s,c.seatHeight,z+6},{x+s,c.seatHeight,z+16},{x+s,c.seatHeight-2,z+16},{x+s,c.seatHeight-2,z+6},.96)end
  contact(8,16,5,2)
 elseif o.kind=='dayTable'then
  draw(2,24,function(s,t)return{x+s,c.tableHeight,z+8+(t-2)*18/22}end,D.tableInside)
  draw(24,32,function(s,t)return{x+s,c.tableHeight*(32-t)/8,z+26}end,D.tableInside)
  for _,s in ipairs({0,32})do patch(0x229,2,8,{x+s,c.tableHeight,z+8},{x+s,c.tableHeight,z+26},{x+s,c.tableHeight-2,z+26},{x+s,c.tableHeight-2,z+8},.96)end
  contact(4,26,3,2);contact(28,26,3,2)
 elseif o.kind=='dayCounter'then
  local function edge(s)return math.min(42,112-s)end
  local function depth(t)return z+16+(t-8)*24/34 end
  draw(8,42,function(s,t)return{x+s,c.counterHeight,depth(t)}end,function(s,t)return(s>=64 or t>=28)and t<edge(s)end)
  -- Extrude the rounded native top contour. Each one-pixel edge segment has
  -- its own connected face; sampling the floor-bearing corner diagonally
  -- created striped wedges. Use the original straight front-panel texture.
  for s=0,79 do
   G.quad(out,{x+s,c.counterHeight,depth(edge(s))},{x+s+1,c.counterHeight,depth(edge(s+1))},
    {x+s+1,0,depth(edge(s+1))},{x+s,0,depth(edge(s))},G.uv(ts,0x22e,s%16,10,s%16+1,15,.5),1)
  end
  -- Inner upright faces enclose the L without raising the clerk's floor.
  patch(0x22e,2,11,{x,c.counterHeight,depth(28)},{x+64,c.counterHeight,depth(28)},{x+64,0,depth(28)},{x,0,depth(28)},.96)
  patch(0x22e,2,11,{x+64,c.counterHeight,depth(8)},{x+64,c.counterHeight,depth(28)},{x+64,0,depth(28)},{x+64,0,depth(8)},.96)
  patch(0x22e,2,11,{x+80,c.counterHeight,depth(8)},{x+80,c.counterHeight,depth(32)},{x+80,0,depth(32)},{x+80,0,depth(8)},.96)
  for xx=4,72,8 do contact(xx,40,5,2)end
 elseif o.kind=='dayFence'then
  draw(1,16,function(s,t)return{x+s,c.fenceHeight*(16-t)/15,z+16}end,cut)
  for xx=4,o.w-4,8 do contact(xx,16,4,1.5)end
 elseif o.kind=='daySideFence'then
  -- Small native wooden posts and two rails along the side of the rug.
  -- No blue floor pixels are turned upright with the source side-boundary tile.
  local h=c.fenceHeight;local a=x+3;local b=x+6
  for _,zz in ipairs({z+2,z+18,z+32})do
   G.quad(out,{a,h,zz},{b,h,zz},{b,0,zz},{a,0,zz},G.uv(ts,0x241,2,1,7,15,.5),1)
   patch(0x241,4,4,{a,h,zz-2},{b,h,zz-2},{b,h,zz},{a,h,zz})
   patch(0x241,4,8,{a,h,zz-2},{a,h,zz},{a,0,zz},{a,0,zz-2},.95)
  end
  for _,y in ipairs({4,10})do
   patch(0x241,8,7,{a,y+2,z+2},{a,y+2,z+32},{a,y,z+32},{a,y,z+2})
   patch(0x241,8,7,{b,y+2,z+2},{b,y+2,z+32},{b,y,z+32},{b,y,z+2})
   patch(0x241,4,4,{a,y+2,z+2},{b,y+2,z+2},{b,y+2,z+32},{a,y+2,z+32})
  end
  for zz=4,28,8 do contact(4.5,zz,2,4)end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return D
