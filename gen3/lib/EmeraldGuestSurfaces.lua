-- Native community halls and tatami guest rooms; layout and events are read-only.
local V=...
local S={seats=setmetatable({},{__mode="k"})}
-- Native sofa whites share their palette with plaster. Keep the closed seat
-- intact; only the measured exterior and the floor between its feet are cut.
function S.sofaInside(x,y)
 if y<8 or y>=31 then return false end
 if y==8 then return x>=3 and x<29 end
 if y==9 then return x>=2 and x<30 end
 if y==10 or y==28 or y==29 then return x>=1 and x<31 end
 if y==30 then return x>=2 and x<7 or x>=24 and x<30 end
 return x>=0 and x<32
end
local layouts={
 EM_DEWFORD_TOWN_HALL={18,10,0x205},
 EM_LILYCOVE_CITY_POKEMON_TRAINER_FAN_CLUB={12,14,0x26e},
 EM_LILYCOVE_CITY_COVE_LILY_MOTEL_1F={12,10,0x2e3},
 EM_LILYCOVE_CITY_COVE_LILY_MOTEL_2F={12,10,0x2e3},
 EM_ROUTE111_OLD_LADYS_REST_STOP={10,8,0x2e3},
}
function S.profile(def)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local id=def.id or def.name
 local spec=layouts[id];local L=def.midLayout
 if cfg.enabled and cfg.guestRooms.enabled and spec and def.pair=='building__generic_building'
  and L and L.width==spec[1]and L.height==spec[2]and L:midAt(0,0)==spec[3]then
  return cfg.homeRooms[V.data('Emerald').homeRooms[id]]
 end
end
function S.plan(def,p)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.guestRooms
 local L=def.midLayout;local wood=p.style=='wood'
 local objects,mask=V.require(wood and 'EmeraldWoodHomeSurfaces'or'EmeraldTatamiSurfaces').plan(def,p)
 local width=L.width;while L:midAt(width-1,0)==p.void do width=width-1 end
 local blocked={};local wallMids=wood and{0x205,0x20d}or{0x215,0x21d}
 local function floor(x,y)return y==2 and(wood and 0x224 or p.edgeFloor)or x==0 and p.edgeFloor or p.floor end
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=donor or floor(xx,yy)end
  end end
  return o
 end
 local function clear(x,w)
  for _,o in ipairs(objects)do if o.kind=='wall'and o.x>=x and o.x<x+w then o.clean=wallMids end end
 end
 for y=0,L.height-1 do for x=0,width-1 do
  local mid=L:midAt(x,y)
  if wood and mid==0x283 then
   add({kind='guestSofa',cap=8,backEnd=17,seatEnd=25,last=31,front=36,
    backHeight=cfg.sofaBackHeight,seatHeight=cfg.sofaSeatHeight,depth=cfg.sofaSeatDepth,
    background={{mid=p.floor},{mid=0x224},{mid=0x20d},{mid=0x303}},positionMask=true},x,y,2,2)
   if y<2 then clear(x,2)end
  elseif wood and mid==0x27b then
   add({kind='fold',cap=0,split=25,last=32,front=32,height=cfg.tableHeight,depth=25,
    background={{mid=p.floor},{mid=0x224}},positionMask=true},x,y,2,2)
  elseif wood and(mid==0x2fa or mid==0x309)then
   local w=1;while x+w<width and L:midAt(x+w,y)==0x2fb do w=w+1 end
   if x+w<width and L:midAt(x+w,y)==0x2fc then w=w+1 end
   add({kind='guestPartition',front=48,wallMids=wallMids,noContact=true},x,y,w,3)
  elseif not wood and mid==0x261 then
   add({kind='guestStairs',down=L:midAt(x,y+1)==0x219,front=32,noContact=true},x-1,y,3,2)
   for xx=x-1,x+1 do blocked[xx]=true end
  elseif not wood and mid==0x2b0 then
   add({kind='fold',cap=10,split=18,last=40,front=48,height=36,depth=8,bounds={1,15}},x,y,1,3);clear(x,1)
  elseif not wood and mid==0x320 then
   local o=add({kind='guestFront',front=16,noContact=true},0,y,width,2)
   o.doors={}
   for xx=0,width-1 do
    local m=L:midAt(xx,y+1);local door=m==0x210 or m==0x211
    o.doors[xx]=door
    mask[y*L.width+xx+1]=p.floor
    if door then mask[(y+1)*L.width+xx+1]=nil else mask[(y+1)*L.width+xx+1]={mid=p.void,void=true}end
   end
  end
 end end
 local kept={}
 for _,o in ipairs(objects)do
  if o.kind=='partition'then
   o.kind='guestDivider';o.front=112;o.h=112;o.noContact=true;blocked[o.x]=true
   for yy=0,6 do local k=yy*L.width+o.x+1;if yy>=2 then mask[k]=floor(o.x,yy)end end
  end
 end
 for _,o in ipairs(objects)do
  if o.kind~='wall'or(o.x<width and not blocked[o.x])then
   if o.kind=='wall'then o.wallHeight=c.wallHeight;o.wallBase=32;o.wallLast=32 end
   kept[#kept+1]=o
  end
 end
 local seats={};for _,o in ipairs(kept)do if o.kind=='guestSofa'then seats[#seats+1]=o end end;S.seats[L]=seats
 return kept,mask
end
function S.actorHeight(def,x,z)
 if not S.profile(def)then return end
 local L=def.midLayout
 if not S.seats[L]then S.plan(def,S.profile(def))end
 local px,pz=x+8,z+16
 for _,o in ipairs(S.seats[L])do
  if px>=o.x*16+2 and px<o.x*16+o.w-2 and pz>=o.y*16+o.front-o.depth and pz<=o.y*16+o.front then
   return o.seatHeight*V.require('DioramaConfig').emeraldInteriors.heightScale
  end
 end
end
function S.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.guestRooms
 local G=V.require('WorldGeometry');local first=#out+1;local h=c.wallHeight
 local function patch(mid,u0,v0,u1,v1,a,b,d,e)
  G.quad(out,a,b,d,e,G.uv(ts,mid,u0,v0,u1,v1,.5),1)
 end
 local function face(a,b,mids)
  for j,m in ipairs(mids)do local top,bot=h*(3-j)/2,h*(2-j)/2
   patch(m,0,0,16,16,{a[1],top,a[2]},{b[1],top,b[2]},{b[1],bot,b[2]},{a[1],bot,a[2]})
  end
 end
 local function draw(a,b,project,inside)
  local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 if o.kind=='guestSofa'then
  draw(o.cap,o.backEnd,function(s,t)return{x+s,o.backHeight-(t-o.cap)*(o.backHeight-o.seatHeight)/(o.backEnd-o.cap),z+o.front-o.depth}end,S.sofaInside)
  draw(o.backEnd,o.seatEnd,function(s,t)return{x+s,o.seatHeight,z+o.front-o.depth+(t-o.backEnd)*o.depth/(o.seatEnd-o.backEnd)}end,S.sofaInside)
  draw(o.seatEnd,o.last,function(s,t)return{x+s,o.seatHeight*(o.last-t)/(o.last-o.seatEnd),z+o.front}end,S.sofaInside)
 elseif o.kind=='guestStairs'then
  draw(0,32,function(s,t)return{x+s,h*(32-t)/32,z+32}end)
  if not o.down then for j=0,2 do local row=20+j*4;local high=(3-j)*c.stepHeight
   draw(row,row+2,function(s,t)return{x+s,high,z+32+(j+(t-row)/2)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
   draw(row+2,row+4,function(s,t)return{x+s,high-(t-row-2)*c.stepHeight/2,z+32+(j+1)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
  end end
 elseif o.kind=='guestDivider'then
  local a,b=x+1,x+13;local back,front=z+32,z+o.front
  patch(0x300,1,0,13,16,{a,h,back},{b,h,back},{b,h,front},{a,h,front})
  face({a,back},{a,front},{0x303,0x20d});face({b,front},{b,back},{0x303,0x20d})
  face({a,front},{b,front},{0x308,0x310})
  for j,m in ipairs({0x205,0x20d})do local top,bot=h*(3-j)/2,h*(2-j)/2
   for _,r in ipairs({{0,1},{13,16}})do patch(m,r[1],0,r[2],16,{x+r[1],top,back},{x+r[2],top,back},{x+r[2],bot,back},{x+r[1],bot,back})end
  end
  if contacts then for zz=back+4,front,8 do contacts[#contacts+1]={(a+b)/2,zz,8,3,cfg.contactStrength}end end
 elseif o.kind=='guestPartition'then
  local front=z+o.front;local back=front-c.partitionDepth
  for sx=0,o.w-1,16 do local right=math.min(o.w,sx+16)
   patch(0x300,3,1,11,15,{x+sx,h,back},{x+right,h,back},{x+right,h,front},{x+sx,h,front})
   face({x+sx,front},{x+right,front},{0x303,0x20d});face({x+right,back},{x+sx,back},{0x303,0x20d})
  end
  face({x,back},{x,front},{0x303,0x20d});face({x+o.w,front},{x+o.w,back},{0x303,0x20d})
  if contacts then for xx=x+4,x+o.w,8 do contacts[#contacts+1]={xx,front,7,2,cfg.contactStrength}end end
 elseif o.kind=='guestFront'then
  local h=c.frontWallHeight;local front=z+16;local back=front-c.partitionDepth
  for sx=0,o.w-16,16 do if not o.doors[sx/16]then
   patch(0x318,0,0,16,8,{x+sx,h,back},{x+sx+16,h,back},{x+sx+16,h,front},{x+sx,h,front})
   patch(0x318,0,8,16,16,{x+sx,h,front},{x+sx+16,h,front},{x+sx+16,0,front},{x+sx,0,front})
  end end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return S
