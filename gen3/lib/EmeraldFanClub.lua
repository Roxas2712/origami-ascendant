-- Slateport fan club: native carpet, separate glass, upholstery and plants.
local V=...
local F={}
function F.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.fanClub.enabled and(d.id or d.name)=='EM_SLATEPORT_CITY_POKEMON_FAN_CLUB'
  and d.pair=='building__pokemon_fan_club'and L and L.width==14 and L.height==12
  and L:midAt(5,4)==0x250 and L:midAt(5,6)==0x260 then return c.homeRooms.fanClub end
end
function F.plan(d)
 local c=V.require('DioramaConfig').emeraldInteriors.fanClub;local L=d.midLayout;local objects,mask={},{}
 for y=0,11 do for x=0,13 do local m=L:midAt(x,y);local k=y*14+x+1
  if m==1 or y<2 then mask[k]={mid=1,void=true}
  elseif m~=6 and m~=7 then
   if x>=2 and x<=11 and y>=4 and y<=8 then
    mask[k]=(y==4 and 0x228 or y==8 and 0x238 or 0x230)+(x==2 and 0 or x==11 and 2 or 1)
   else mask[k]=x==0 and 0x204 or(x%2==0 and 0x202 or 0x201)end
  end
 end end
 local function add(o,x,y,w,h)o.noContact=o.kind~='wall';o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o;return o end
 for x=0,13 do
  local o=add({kind='wall',wallHeight=c.wallHeight,wallLast=40,wallBase=40},x,0,1,3)
  if x<=1 or x==3 or x==10 or x>=12 then o.clean={0x211,0x21d,0x221};o.nativeUpper=true end
 end
 add({kind='fanShelf',cap=11,split=18,last=32,height=c.lowShelfHeight,front=32},0,1,2,2)
 add({kind='fanShelf',cap=2,split=10,last=31,height=c.tallShelfHeight,front=32,tall=true},12,1,2,2)
 for _,p in ipairs({{3,1},{10,1},{0,9},{13,9}})do add({kind='fanPlant',front=31},p[1],p[2],1,2)end
 add({kind='fanSofa',front=32},5,4,4,2)
 add({kind='fanChair',front=32},3,6,1,2)
 add({kind='fanChair',front=32,right=true},10,6,1,2)
 add({kind='fanTable',front=34},5,6,4,3)
 return objects,mask
end
function F.actorHeight(d,x,z)
 if not F.profile(d)then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local px,pz=x+8,z+16
 if px>=5*16+7 and px<9*16-7 and pz>=5*16 and pz<=6*16 then return c.fanClub.seatHeight*c.heightScale end
 -- Native side chairs are walkable too. Raise only feet over their cushions.
 if pz>=8*16-c.fanClub.sideChairDepth and pz<=8*16
  and(px>=3*16+4 and px<4*16 or px>=10*16 and px<10*16+12)then
  return c.fanClub.seatHeight*c.heightScale
 end
end
function F.tableInside(s,t)
 if t<2 or t>=35 then return false end
 if t==2 then return s>=3 and s<61 end
 if t==3 then return s>=2 and s<62 end
 if t==34 then return s>=2 and s<7 or s>=57 and s<62 end
 if t>=32 then return s>=1 and s<8 or s>=56 and s<63 end
 return s>=1 and s<63
end
function F.shelfInside(o,s,t)
 if t<o.cap or t>=o.last then return false end
 if o.tall then
  s=s%16
  if t==2 then return s>=1 and s<15 end
  if t>=29 then return s<3 or s>=13 end
  return true
 end
 if t==11 then return s>=3 and s<29 end
 if t==30 then return s>=2 and s<6 or s>=26 and s<30 end
 if t==31 then return s>=3 and s<5 or s>=27 and s<29 end
 return s>=2 and s<30
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function F.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.fanClub;local G=V.require('WorldGeometry');local BM=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(s,t,a,b,d,e,shade)
  local m,u,v=source(s,t);G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)
 end
 local function contact(a,b,zz)if contacts then for xx=a+3,b-2,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,cfg.contactStrength}end end end
 if o.kind=='fanPlant'then
  -- Reuse the matching floor plant's exact native outline for wall plants too.
  -- This excludes wall stripes while retaining every leaf and the opaque pot.
  local bg={};for _,m in ipairs({0x201,0x202,0x204})do for v=0,15 do for u=0,15 do bg[rgb(BM.pixel(ts,m,u,v))]=true end end end
  draw(3,31,function(s,t)return{x+s,c.plantHeight*(31-t)/28,z+31}end,function(s,t)
   return not bg[rgb(BM.pixel(ts,L:midAt(0,9+math.floor(t/16)),s,t%16))]
  end)
  contact(3,13,31)
 elseif o.kind=='fanShelf'then
  local inside=function(s,t)return F.shelfInside(o,s,t)end
  draw(o.cap,o.split,function(s,t)return{x+s,o.height,z+o.front-c.shelfDepth+(t-o.cap)*c.shelfDepth/(o.split-o.cap)}end,inside)
  draw(o.split,o.last,function(s,t)return{x+s,o.height*(o.last-t)/(o.last-o.split),z+o.front}end,inside)
  local a,b=o.tall and 0 or 2,o.tall and 32 or 30
  for _,s in ipairs({a,b})do patch(o.tall and 1 or 3,o.split,{x+s,o.height,z+o.front-c.shelfDepth},{x+s,o.height,z+o.front},{x+s,0,z+o.front},{x+s,0,z+o.front-c.shelfDepth},.95)end
  contact(a,b,o.front)
 elseif o.kind=='fanSofa'then
  local function inside(s,t)
   if t==9 then return s>=4 and s<60 elseif t==10 then return s>=2 and s<62
   elseif t==11 or t==12 then return s>=1 and s<63 elseif t==31 then return s>0 and s<63 and s~=6 and s~=57 end
   return true
  end
  draw(9,21,function(s,t)return{x+s,c.backHeight-(t-9)*(c.backHeight-c.seatHeight)/12,z+32-c.seatDepth}end,inside)
  draw(21,27,function(s,t)return{x+s,c.seatHeight,z+32-c.seatDepth+(t-21)*c.seatDepth/6}end,inside)
  draw(27,32,function(s,t)return{x+s,c.seatHeight*(32-t)/5,z+32}end,inside)
  for _,s in ipairs({0,64})do patch(1,26,{x+s,c.seatHeight,z+32-c.seatDepth},{x+s,c.seatHeight,z+32},{x+s,0,z+32},{x+s,0,z+32-c.seatDepth},.95)end
  contact(0,64,32)
 elseif o.kind=='fanTable'then
  draw(2,26,function(s,t)return{x+s,c.tableHeight,z+o.front-c.tableDepth+(t-2)*c.tableDepth/24}end,F.tableInside)
  draw(26,35,function(s,t)return{x+s,c.tableHeight*(35-t)/9,z+o.front}end,F.tableInside)
  for _,s in ipairs({2,61})do patch(3,28,{x+s,c.tableHeight,z+o.front-c.tableDepth},{x+s,c.tableHeight,z+o.front},{x+s,c.tableHeight-2,z+o.front},{x+s,c.tableHeight-2,z+o.front-c.tableDepth},.95)end
  contact(2,62,o.front)
 elseif o.kind=='fanChair'then
  -- Both side chairs use their original mirrored pixels, with the backrest
  -- standing along the side of a horizontal seat instead of lying on the rug.
  local function sx(s)return o.right and 15-s or s end
  local function src(s,t)return source(sx(s),t)end
  local function point(s,h,d)return{x+(o.right and 16-s or s),h,z+d}end
  local rear=32-c.sideChairDepth
  draw(2,22,function(s,t)return point(4,c.backHeight-s*(c.backHeight-c.seatHeight)/7,rear+(t-2)*c.sideChairDepth/20)end,function(s)return s<=7 end,src)
  draw(11,22,function(s,t)return point(4+(s-7)*12/8,c.seatHeight,rear+4+(t-11)*(c.sideChairDepth-8)/11)end,function(s)return s>=7 and s<15 end,src)
  draw(4,8,function(s,t)return point(4+(s-7)*12/8,c.armHeight,rear+t-4)end,function(s,t)return s>=7 and s<15 and(t>4 or s<14)end,src)
  draw(8,11,function(s,t)return point(4+(s-7)*12/8,c.armHeight-(t-8)*(c.armHeight-c.seatHeight)/3,rear+4)end,function(s)return s>=7 and s<15 end,src)
  draw(23,26,function(s,t)return point(4+(s-7)*12/8,c.armHeight,28+(t-23)*4/3)end,function(s)return s>=7 and s<15 end,src)
  draw(26,32,function(s,t)return point(4+(s-7)*12/8,c.armHeight*(32-t)/6,32)end,function(s)return s>=7 and s<15 end,src)
  draw(22,32,function(s,t)return point(s*4/7,c.backHeight*(32-t)/10,32)end,function(s)return s<7 end,src)
  local function panel(s,t,a,b,d,e,shade)
   local m,u,v=src(s,t);G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)
  end
  panel(3,26,point(0,c.backHeight,rear),point(0,c.backHeight,32),point(0,0,32),point(0,0,rear),.95)
  panel(3,1,point(0,c.backHeight,rear),point(4,c.backHeight,rear),point(4,c.backHeight,32),point(0,c.backHeight,32))
  for _,xx in ipairs({0,3})do
   panel(0,14,point(xx,c.backHeight+.01,rear),point(xx+1,c.backHeight+.01,rear),point(xx+1,c.backHeight+.01,32),point(xx,c.backHeight+.01,32))
  end
  panel(3,26,point(0,c.backHeight,rear),point(4,c.backHeight,rear),point(4,0,rear),point(0,0,rear),.95)
  contact(0,16,32)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return F
