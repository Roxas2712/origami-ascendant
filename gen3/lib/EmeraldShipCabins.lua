-- Eight native S.S. Tidal cabins share one map; retain every original fixture.
local V=...
local C={}
local starts={1,10,19,28}
function C.profile(d)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if cfg.enabled and cfg.ship.enabled and(d.id or d.name)=='EM_SS_TIDAL_ROOMS'
  and d.pair=='general__inside_ship'and L and L.width==36 and L.height==18
  and L:midAt(0,0)==0x236 and L:midAt(4,16)==0x264 then return cfg.homeRooms.shipCabins end
end
function C.plan(d)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.ship;local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for y=0,17 do for x=0,35 do mask[y*36+x+1]={mid=0x201,void=true}end end
 for _,row in ipairs({0,9})do for _,left in ipairs(starts)do
  for x=left,left+6 do
   add('wall',x,row,1,2,{wallHeight=c.wallHeight,wallLast=32,wallBase=32})
   for y=row+2,row+7 do local m=L:midAt(x,y);if m==0x264 or m==0x265 then mask[y*36+x+1]=nil else mask[y*36+x+1]=0x238 end end
  end
  add('tidalCabinSide',left,row+2,1,6,{left=true})
  add('tidalCabinSide',left+7,row+2,1,6)
 end end
 local function clearWall(x,y,w)
  for _,o in ipairs(objects)do if o.kind=='wall'and o.y==y-1 and o.x>=x and o.x<x+w then
   o.clean={0x227,0x22f};o.keepBefore=24
  end end
 end
 for y=1,16 do for x=1,34 do local m=L:midAt(x,y)
  if m==0x248 or m==0x275 or m==0x269 then
   add('tidalCabinBed',x,y,2,3,{reverse=m~=0x248});clearWall(x,y,2)
  elseif m==0x256 then
   local w=2;while L:midAt(x+w-1,y)==0x270 do w=w+1 end
   add('tidalCabinTable',x,y,w,2)
  elseif m==0x260 or m==0x261 then add('tidalCabinChair',x,y,1,1,{reverse=m==0x261})
  elseif m==0x299 then add('tidalCabinDesk',x,y,2,2)
  elseif m==0x262 or m==0x277 then add('tidalCabinBin',x,y,1,1)end
 end end
 return objects,mask
end
function C.actorHeight(d,x,z)
 if not C.profile(d)then return end
 local tx,ty=math.floor((x+8)/16),math.floor((z+15.99)/16);local m=d.midLayout:midAt(tx,ty)
 if m==0x260 or m==0x261 then local c=V.require('DioramaConfig').emeraldInteriors;return c.ship.seatHeight*c.heightScale end
end
function C.tableInside(s,t,w)
 if t<0 or t>=32 then return false end
 if t<3 then return s>=3-t and s<w-3+t end
 if t>=28 then return s>=2 and s<7 or s>=w-7 and s<w-2 end
 if t>=25 then return s>=1 and s<w-1 end
 return true
end
function C.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.ship;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function band(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(m,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for sx=a+4,b-3,8 do contacts[#contacts+1]={x+sx,z+zz,5,2,cfg.contactStrength}end end end
 if o.kind=='tidalCabinSide'then
  local a=o.left and -4 or 0;local b=a+4;local h=c.cabinSideHeight
  for yy=0,o.h-1 do
   local m,u,v=0x227,8,8
   patch(m,u,v,{x+a,h,z+yy},{x+a,h,z+yy+1},{x+a,0,z+yy+1},{x+a,0,z+yy})
   patch(m,u,v,{x+b,h,z+yy},{x+b,h,z+yy+1},{x+b,0,z+yy+1},{x+b,0,z+yy})
   patch(0x227,8,2,{x+a,h,z+yy},{x+b,h,z+yy},{x+b,h,z+yy+1},{x+a,h,z+yy+1})
  end
  patch(0x227,8,8,{x+a,h,z+o.h},{x+b,h,z+o.h},{x+b,0,z+o.h},{x+a,0,z+o.h})
 elseif o.kind=='tidalCabinBed'then
  local function q(s)return o.reverse and 31-s or s end
  local shelf=c.bedsideHeight;local bed=c.bedHeight;local back=24;local front=42
  -- Original L-shaped bedside unit: its cream checkerboard is part of the
  -- furniture, not a color-key background. Keep it, apart from the wood wall.
  band(10,20,function(s,t)return{x+s,shelf,z+12+t-10}end,nil,function(s,t)
   local qs=q(s);if qs>=12 and qs<24 and t<16 then return source(o.reverse and 29 or 2,t)end
   return source(s,t)
  end)
  band(20,41,function(s,t)return{x+s,shelf,z+22+t-20}end,function(s)return q(s)<8 end)
  band(41,48,function(s,t)return{x+s,shelf*(48-t)/7,z+43}end,function(s)return q(s)<8 end)
  local outer=o.reverse and 32 or 0;local m,u,v=source(o.reverse and 30 or 1,43)
  patch(m,u,v,{x+outer,shelf,z+12},{x+outer,shelf,z+43},{x+outer,0,z+43},{x+outer,0,z+12})
  -- Small original bedside clock, isolated from the countertop behind it.
  band(8,15,function(s,t)return{x+s,shelf+(15-t)*c.bedClockHeight/7,z+22}end,function(s,t)local qq=q(s);return qq>=12 and qq<24 end)
  band(20,25,function(s,t)return{x+s,bed+(25-t)*(c.bedHeadHeight-bed)/5,z+back}end,function(s)return q(s)>=8 and q(s)<31 end)
  band(25,43,function(s,t)return{x+s,bed,z+back+(t-25)*(front-back)/18}end,function(s)return q(s)>=8 and q(s)<31 end)
  band(43,46,function(s,t)return{x+s,2+(46-t)*(bed-2)/3,z+front}end,function(s)return q(s)>=8 and q(s)<31 end)
  band(46,48,function(s,t)return{x+s,48-t,z+front}end,function(s,t)local qq=q(s);return t==46 and(qq>=9 and qq<13 or qq>=26 and qq<30)or t==47 and(qq>=10 and qq<12 or qq>=27 and qq<29)end)
  for _,qs in ipairs({8,31})do local s=o.reverse and 31-qs or qs;local mm,uu,vv=source(o.reverse and 3 or 28,39)
   patch(mm,uu,vv,{x+s,bed,z+back},{x+s,bed,z+front},{x+s,0,z+front},{x+s,0,z+back},.96)
  end
  contact(0,32,43)
 elseif o.kind=='tidalCabinTable'then
  band(0,24,function(s,t)return{x+s,c.tableHeight,z+t}end,function(s,t)return C.tableInside(s,t,o.w)end)
  band(24,32,function(s,t)return{x+s,c.tableHeight*(32-t)/8,z+24}end,function(s,t)return C.tableInside(s,t,o.w)end)
  for _,s in ipairs({1,o.w-1})do local m,u,v=source(s,25);patch(m,u,v,{x+s,c.tableHeight,z+3},{x+s,c.tableHeight,z+24},{x+s,0,z+24},{x+s,0,z+3},.96)end
  contact(0,o.w,24)
 elseif o.kind=='tidalCabinChair'then
  local function q(s)return o.reverse and 15-s or s end
  band(0,13,function(s,t)return{x+s,c.chairHeight*(13-t)/13,z+14}end,function(s,t)local qq=q(s);return qq>=2 and qq<6 and(t>0 or qq>=3 and qq<5)end)
  band(4,10,function(s,t)return{x+s,c.seatHeight,z+8+t-4}end,function(s)return q(s)>=6 and q(s)<14 end)
  band(10,13,function(s,t)return{x+s,2+(13-t)*(c.seatHeight-2)/3,z+14}end,function(s)return q(s)>=6 and q(s)<14 end)
  band(13,16,function(s,t)return{x+s,2*(16-t)/3,z+14}end,function(s)local qq=q(s);return qq>=2 and qq<6 or qq>=10 and qq<14 end)
  contact(2,14,14)
 elseif o.kind=='tidalCabinDesk'then
  band(2,12,function(s,t)return{x+s,c.tableHeight,z+4+t-2}end,function(s,t)return t>2 or s>=1 and s<31 end)
  band(12,24,function(s,t)return{x+s,c.tableHeight*(24-t)/12,z+14}end,function(s,t)return t<15 or s>=1 and s<5 or s>=27 and s<31 end)
  -- The native chair below the desk is its own surface, not a floor rectangle.
  band(18,23,function(s,t)return{x+s,c.seatHeight,z+21+t-18}end,function(s)return s>=10 and s<23 end)
  band(23,29,function(s,t)return{x+s,c.chairHeight*(29-t)/6,z+28}end,function(s)return s>=10 and s<23 end)
  band(29,32,function(s,t)return{x+s,3*(32-t)/3,z+28}end,function(s)return s>=10 and s<14 or s>=19 and s<23 end)
  contact(0,32,14);contact(10,24,28)
 elseif o.kind=='tidalCabinBin'then
  band(0,15,function(s,t)return{x+s,c.binHeight*(15-t)/15,z+15}end,V.require('EmeraldShipInteriors').binInside);contact(3,13,15)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return C
