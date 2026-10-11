-- Measured S.S. Anne work rooms. Source art stays native; only surfaces move.
local V=...
local S={}
function S.profile(d)
 local c=V.require('DioramaConfig').interiors.shipPublic;local L=d.midLayout
 if not c.enabled or (d.renderPair or d.pair)~='general__rom_082d4d94'or not L then return end
 local p=c.rooms[d.id or d.name];if not p or L.width~=p.width or L.height~=p.height or L:midAt(p.checkX,p.checkY)~=p.checkMid then return end
 return p
end
function S.plan(d)
 local p=S.profile(d);if not p or not V.require('IndoorSurfaces').profile(d)then return end
 local c=V.require('DioramaConfig').interiors.shipPublic;local L=d.midLayout
 local objects,mask,owners,ramps={},{},{},{}
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w;o.last=h*16;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;owners[k]=o;mask[k]=donor or(p.kitchen and 0x299 or 0x298)end end
  return o
 end
 local function cut(x,y,w,h)for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=0x288,void=true}end end end
 for y=0,L.height-1 do for x=0,L.width-1 do
  if x==0 or x>=L.width-(p.kitchen and 1 or 2)or y==L.height-1 or L:midAt(x,y)==0x288 then cut(x,y,1,1)end
 end end
 for x=1,L.width-(p.kitchen and 2 or 3)do
  add({kind='shipPublicWall',base=.01,kitchen=p.kitchen,clear=not p.kitchen and(x==2 or x==7),front=p.kitchen and 32 or 40},x,0,1,p.kitchen and 2 or 3)
  cut(x,0,1,p.kitchen and 2 or 3)
 end
 if p.kitchen then
  for _,x in ipairs({3,7,11})do
   add({kind='shipPublicBench',cap=13,split=88,front=96,height=c.benchHeight,depth=75,sink=x~=7},x,3,2,6)
  end
  add({kind='shipPublicBench',cap=14,split=42,front=48,height=c.benchHeight,depth=28,wide=true},1,10,14,3)
  for _,y in ipairs({4,6,8})do add({kind='shipPublicBin',cap=1,front=16},14,y,1,1)end
 else
  add({kind='shipPublicTable',cap=5,split=24,front=32,height=c.tableHeight,depth=19},1,3,3,2)
  add({kind='shipPublicCabinet',cap=3,front=32},7,1,1,2)
  add({kind='shipPublicChair',rear=true,cap=10,front=32},2,1,1,2)
  add({kind='shipPublicBucket',cap=1,front=16},5,3,1,1)
  for _,y in ipairs({6,7})do add({kind='shipPublicChair',cap=0,front=16},7,y,1,1)end
  local stair=add({kind='shipPublicStairs',base=.01,front=48},1,6,3,3);ramps[#ramps+1]=stair;cut(1,6,3,3)
  -- Objects share wall rows. Keep that region void; the wall builder supplies
  -- only the eight native floor rows in front of the captain's back wall.
  cut(1,0,7,3)
 end
 return {objects=objects,mask=mask,owners=owners,ramps=ramps}
end
function S.actorHeight(d,x,z)
 local p=S.profile(d);if not p or not V.require('IndoorSurfaces').profile(d)then return end
 local cx,cy=math.floor((x+8)/16),math.floor((z+15.99)/16)
 if p.kitchen and cx==1 and cy==10 and d.midLayout:midAt(1,10)==0x2dc then
  local c=V.require('DioramaConfig').interiors
  return c.shipPublic.benchHeight*c.heightScale,c.shipPublic.itemInset
 end
end
function S.recesses(d)
 local p=S.profile(d)
 return p and not p.kitchen and {{16,112,48,136}}or{}
end
function S.stairHeight(o,x,z)
 local a,b=x-o.x*16,z-o.y*16
 if a<0 or a>=35 or b<16 or b>40 then return end
 local h=V.require('DioramaConfig').interiors.shipPublic.stairHeight
 return -h+math.min(8,math.floor(a/4)+1)*h/8
end
local function append(out,vv)for _,v in ipairs(vv)do out[#out+1]=v end end
function S.build(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.shipPublic;local G=V.require('WorldGeometry')
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function strip(a,b,project,inside,src)
  append(out,V.require('PaperSprite').build(ts,o.w*16,o.last,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.last,1,nil,project,.5))
 end
 if o.kind=='shipPublicWall'then
  local foot=o.front
  local function wallSource(s,t)
   if o.clear and t>=16 then return t<32 and 0x2fb or 0x2fc,s,t%16 end
   return source(s,t)
  end
  strip(6,foot,function(s,t)return{x+s,c.wallHeight*(foot-t)/(foot-6),z+foot}end,nil,wallSource)
  if not o.kitchen then
   local src=function(s,t)return 0x298,s,t%16 end
   strip(40,48,function(s,t)return{x+s,0,z+t}end,nil,src)
  end
 elseif o.kind=='shipPublicCabinet'then
  strip(3,32,function(s,t)return{x+s,c.cabinetHeight*(32-t)/29,z+32}end)
 elseif o.kind=='shipPublicChair'then
  -- Yellow upholstery shares the wall-rail palette. Use the measured
  -- silhouette, never a background colour key that would erase the seat.
  local last=o.rear and 29 or 16
  local function inside(s,t)
   if o.rear then
    if t==10 then return s>=3 and s<13 end
    if t<19 then return s>=2 and s<14 end
    if t==19 or t==27 then return s>=1 and s<15 end
    if t==28 then return s==2 or s==13 end
    return true
   end
   if t==0 then return s>=12 and s<15 end
   if t<4 then return s>=11 end
   if t==4 then return s>=5 end
   if t<10 then return s>=4 end
   if t<15 then return s>=4 and s<15 end
   return s>=5 and s<7 or s>=12 and s<15
  end
  strip(o.cap,last,function(s,t)return{x+s,(o.rear and c.rearChairHeight or c.chairHeight)*(last-t)/(last-o.cap),z+o.front}end,inside)
 elseif o.kind=='shipPublicBucket'or o.kind=='shipPublicBin'then
  local src,inside=api.nativeMask(L,ts,o,16,16,{0x298,0x299})
  strip(o.cap,16,function(s,t)return{x+s,c.binHeight*(16-t)/(16-o.cap),z+16}end,inside,src)
 elseif o.kind=='shipPublicTable'or o.kind=='shipPublicBench'then
  local table=o.kind=='shipPublicTable'
  local function inside(s,t)
   if o.wide then return true end
   if table then
    if t<26 then return t~=5 or s>0 and s<47 end
    if t<28 then return s>=1 and s<47 end
    if t<31 then return s>=1 and s<5 or s>=43 and s<47 end
    return s>=2 and s<4 or s>=44 and s<46
   end
   if t<88 then return s>=1 and s<31 and(t~=13 or s>=2 and s<30)end
   if t<92 then return s>=1 and s<31 end
   return s>=2 and s<5 or s>=27 and s<30
  end
  -- The basin remains horizontal; only its six-pixel faucet stands upright.
  local function faucet(s,t)return o.sink and s>=14 and s<21 and t>=72 and t<79 end
  local function topSource(s,t)if faucet(s,t)then return 0x2da,10,5 end;return source(s,t)end
  local function floor(s,t)return{x+s,o.height,z+o.front-o.depth+(t-o.cap)*o.depth/(o.split-o.cap)}end
  strip(o.cap,o.split,floor,inside,topSource)
  strip(o.split,o.last,function(s,t)return{x+s,o.height*(o.last-t)/(o.last-o.split),z+o.front}end,inside)
  for _,sx in ipairs(o.wide and{0,o.w*16}or table and{1,47}or{1,31})do
   local m,u,v=source(math.min(sx,o.w*16-1),o.split)
   G.quad(out,{x+sx,o.height,z+o.front-o.depth},{x+sx,o.height,z+o.front},{x+sx,0,z+o.front},{x+sx,0,z+o.front-o.depth},G.uv(ts,m,u,v,u+1,v+1,.5),.92)
  end
  if o.sink then
   strip(72,79,function(s,t)return{x+s,o.height+79-t,z+o.front-o.depth+(79-o.cap)*o.depth/(o.split-o.cap)}end,faucet)
  end
 elseif o.kind=='shipPublicStairs'then
  -- Native flight descends to the left. Keep the surrounding floor intact.
  strip(0,48,function(s,t)return{x+s,0,z+t}end,function(s,t)return s>=32 or t<8 end,function(s,t)return 0x298,s%16,t%16 end)
  local tread=G.uv(ts,0x2ac,9,6,10,7,.5);local riser=G.uv(ts,0x2ab,4,9,5,10,.5)
  for i=0,7 do
   local h=-c.stairHeight+(i+1)*c.stairHeight/8
   api.prism(out,ts,0,x+i*4,z+16,4,24,-c.stairHeight,h+c.stairHeight,tread,riser,riser)
   G.quad(out,{x+i*4,h+.02,z+16},{x+i*4+1,h+.02,z+16},{x+i*4+1,h+.02,z+40},{x+i*4,h+.02,z+40},riser,1)
  end
  V.require('RoomRecessClip').shaft(out,{x,z+16,x+32,z+40},c.stairHeight,riser,c.shaftShade)
  for _,range in ipairs({{8,16},{40,48}})do
   strip(range[1],range[2],function(s,t)
    local h=-c.stairHeight+math.min(32,s)*c.stairHeight/32
    return{x+s,h+range[2]-t,z+(range[1]==8 and 16 or 40)}
   end,function(s)return s<35 end)
  end
 end
end
return S
