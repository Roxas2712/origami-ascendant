-- Native Emerald link rooms. Only presentation; multiplayer/warp state is untouched.
local V=...;local R={}
local rooms={
 EM_BATTLE_COLOSSEUM_2P={w=14,h=10,left=8,right=216,top=8,anchor=0x268,style='colosseum'},
 EM_BATTLE_COLOSSEUM_4P={w=14,h=10,left=8,right=216,top=8,anchor=0x268,style='colosseum'},
 EM_RECORD_CORNER={w=20,h=10,left=56,right=264,top=0,anchor=0x201,style='record'},
 EM_TRADE_CENTER={w=12,h=10,left=8,right=184,top=8,anchor=0x230,style='trade'},
 EM_UNION_ROOM={w=16,h=12,left=0,right=240,top=0,anchor=0x201,style='union'},
 EM_UNION_ROOM_PLAZA={w=25,h=25,left=0,right=400,top=0,anchor=0x201,style='plaza'}}
function R.hasId(d)return d and rooms[d.id or d.name]~=nil end
function R.kind(d)
 local p=d and rooms[d.id or d.name];local L=d and d.midLayout
 if p and L and L.width==p.w and L.height==p.h and d.mapType==8
  and d.pair==((p.style=='union'or p.style=='plaza')and'building__union_room'or'building__cable_club')and L:midAt(0,0)==p.anchor then return p end
end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors
 if c.enabled and c.cableRooms.enabled and R.kind(d)then return c.homeRooms.cableRoom end
end
function R.lighting(d)
 if not R.profile(d)then return end
 return V.require('DioramaConfig').emeraldInteriors.cableRooms.lights[R.kind(d).style]
end
local function offset(p,s)return math.max(0,(p.left+15-s)/2,(s-(p.right-16))/2)end
function R.plan(d)
 if not R.profile(d)then return end
 local p=R.kind(d);local obj,mask={},{}
 for i=1,p.w*p.h do mask[i]={mid=(p.style=='union'or p.style=='plaza')and 1 or 0x201,void=true}end
 local function add(kind,x,y,w,h,data)
  local o=data or{};o.kind=kind;o.x=x/16;o.y=y/16;o.w=w;o.h=h;o.room=p;o.noContact=true;obj[#obj+1]=o
 end
 add('cableFloor',0,0,p.w*16,p.h*16)
 add('cableWall',0,0,p.w*16,48)
 if p.style=='trade'then
  add('cableTrade',76,64,40,40)
  add('cableChair',64,80,16,24,{right=false});add('cableChair',112,80,16,24,{right=true})
 elseif p.style=='record'then
  add('cableConsole',128,64,64,48)
  add('cableScreen',174,86,18,17)
  for _,x in ipairs({112,192})do for _,y in ipairs({48,80})do add('cableTerminal',x,y,16,32)end end
 end
 return obj,mask
end
-- Flood only perimeter-connected background. Shared pale furniture pixels stay opaque.
function R.cutout(L,ts,x,y,w,h,mids,pixels)
 local pixel=V.require('BuildingMesh').pixel
 local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local bg={}
 for _,m in ipairs(mids or{})do for t=0,15 do for s=0,15 do bg[key(pixel(ts,m,s,t))]=true end end end
 local function src(s,t)return L:midAt(math.floor((x+s)/16),math.floor((y+t)/16)),(x+s)%16,(y+t)%16 end
 for _,p in ipairs(pixels or{})do bg[key(pixel(ts,src(p[1],p[2])))]=true end
 local clear,empty,q={},{},{}
 for t=0,h-1 do for s=0,w-1 do local r,g,b,a=pixel(ts,src(s,t));clear[t*w+s]=a<.5 or bg[key(r,g,b)]end end
 local function seed(s,t)local k=t*w+s;if clear[k]and not empty[k]then empty[k]=true;q[#q+1]=k end end
 for s=0,w-1 do seed(s,0);seed(s,h-1)end;for t=0,h-1 do seed(0,t);seed(w-1,t)end
 local i=1;while q[i]do local k=q[i];i=i+1;local s,t=k%w,math.floor(k/w)
  if s>0 then seed(s-1,t)end;if s<w-1 then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t<h-1 then seed(s,t+1)end
 end
 return src,function(s,t)return s>=0 and s<w and t>=0 and t<h and not empty[t*w+s]end
end
local screenLeft={11,9,7,5,3,2,2,0,0,0,0,0,0,0,1,3,4}
function R.screen(s,t)return t>=0 and t<17 and s>=screenLeft[t+1]and s<14 end
function R.consoleTop(s,t)
 if t<3 or t>=40 then return false end
 local inset=t==3 and 3 or t==4 and 2 or t==5 and 1 or 0
 return s>=inset and s<64-inset and not(s>=10 and s<54 and t>=14 and t<30)
end
function R.capture(boxes,o,x,z)
 if o.kind~='cableConsole'then return false end
 local cfg=V.require('DioramaConfig').emeraldInteriors
 local c=o.presentation and o.presentation.config or cfg.cableRooms;local scale=o.presentation and o.presentation.heightScale or cfg.heightScale
 for _,a in ipairs({{0,3,64,11},{0,14,10,26},{54,14,10,26},{10,30,44,10}})do
  boxes[#boxes+1]={lo={x+a[1],0,z+a[2]},hi={x+a[1]+a[3],c.consoleHeight*scale,z+a[2]+a[4]},wall=false}
 end
 return true
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=o.presentation and o.presentation.config or cfg.cableRooms;local scale=o.presentation and o.presentation.heightScale or cfg.heightScale;local shift=o.presentation and o.presentation.paletteShift or 0;local p=o.room;local G=V.require('WorldGeometry')
 local function source(s,t)return L:midAt(math.floor((o.x*16+s)/16),math.floor((o.y*16+t)/16)),(o.x*16+s)%16,(o.y*16+t)%16 end
 local function draw(w,h,src,inside,point,shade)
  local vv=V.require('PaperSprite').build(ts,w,h,src,inside or function()return true end,0,h,1,shade and function()return shade end or nil,point,.5)
  for _,v in ipairs(vv)do v[2]=v[2]*scale;out[#out+1]=v end
 end
 if o.kind=='cableFloor'then
  local masks={}
  if p.style=='trade'then
   for _,a in ipairs({{76,64,40,40},{64,80,16,24},{112,80,16,24}})do
    local _,inside=R.cutout(L,ts,a[1],a[2],a[3],a[4],nil,{{76-a[1],64-a[2]},{95-a[1],64-a[2]}})
    masks[#masks+1]={a=a,inside=inside}
   end
  end
  draw(o.w,o.h,function(s,t)
   if p.style=='record'and s>=112 and s<208 and t>=48 and t<128 then return 0x2c4+shift,s%16,t%16 end
   for _,m in ipairs(masks)do if m.inside(s-m.a[1],t-m.a[2])then
    if s==95 or s==96 then return source(95,120)elseif t==95 or t==96 then return source(32,95)end
    return 0x208+shift,s%16,t%16
   end end
   return source(s,t)
  end,function(s,t)
   if s<p.left or s>=p.right or t<p.top+32+math.floor(offset(p,s))then return false end
   local m,u,v=source(s,t);if m==(o.presentation and o.presentation.voidMid or ((p.style=='union'or p.style=='plaza')and 1 or 0x201))then return false end
   local r,g,b,a=V.require('BuildingMesh').pixel(ts,m,u,v);return a>.5 and r+g+b>0
  end,function(s,t)return{x+s,0,z+t}end)
 elseif o.kind=='cableWall'then
  for s=p.left,p.right-1 do
   local off=math.floor(offset(p,s));local off0=offset(p,s);local off1=offset(p,s+1)
   draw(1,32,function(_,t)return source(s,p.top+off+t)end,nil,
    function(u,t)return{x+s+u,c.wallHeight*(32-t)/32,z+p.top+32+off0+(off1-off0)*u}end)
  end
 elseif o.kind=='cableTrade'then
  local src,inside=R.cutout(L,ts,76,64,40,40,nil,{{0,0},{19,0}})
  draw(40,40,src,function(s,t)return t>=3 and t<10 and inside(s,t)end,function(s,t)return{x+s,c.machineHeight,z+40-c.machineDepth+(t-3)*c.machineDepth/7}end)
  draw(40,40,src,function(s,t)return t>=10 and inside(s,t)end,function(s,t)return{x+s,c.machineHeight*(40-t)/30,z+40}end)
 elseif o.kind=='cableChair'then
  local src,inside=R.cutout(L,ts,o.x*16,o.y*16,16,24,nil,{{76-o.x*16,64-o.y*16},{95-o.x*16,64-o.y*16}})
  local back=o.right and 12 or 4
  local function backInside(s,t)return s>=0 and s<16 and t>=3 and t<16 and inside(s,t)and(o.right and s>=12 or not o.right and s<4)end
  local function backPoint(s,t,depth)return{x+back+(o.right and depth or -depth),c.seatHeight+(16-t)*(c.chairHeight-c.seatHeight)/13,z+12+(o.right and s-12 or 4-s)*c.seatDepth/4}end
  draw(16,24,src,backInside,function(s,t)return backPoint(s,t,0)end)
  -- Closed native silhouette, not an edge-on infinitely thin chair back.
  -- Extruding along X retains the original open floor around the seat.
  local thickness=c.chairBackThickness or 0
  if thickness>0 then
   draw(16,24,src,backInside,function(s,t)return backPoint(s,t,thickness)end,c.sideShade)
   local function point(s,t,depth)local a=backPoint(s,t,depth);a[2]=a[2]*scale;return a end
   for t=3,15 do for s=0,15 do if backInside(s,t)then
    local m,u,v=src(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
    if not backInside(s-1,t)then G.quad(out,point(s,t,0),point(s,t,thickness),point(s,t+1,thickness),point(s,t+1,0),uv,c.sideShade)end
    if not backInside(s+1,t)then G.quad(out,point(s+1,t,thickness),point(s+1,t,0),point(s+1,t+1,0),point(s+1,t+1,thickness),uv,c.sideShade)end
    if not backInside(s,t-1)then G.quad(out,point(s,t,thickness),point(s,t,0),point(s+1,t,0),point(s+1,t,thickness),uv)end
    if not backInside(s,t+1)then G.quad(out,point(s,t+1,0),point(s,t+1,thickness),point(s+1,t+1,thickness),point(s+1,t+1,0),uv,c.sideShade)end
   end end end
  end
  draw(16,24,src,function(s,t)return t>=7 and t<16 and inside(s,t)and(o.right and s<12 or not o.right and s>=4)end,
   function(s,t)return{x+s,c.seatHeight,z+12+(t-7)*c.seatDepth/9}end)
  draw(16,24,src,function(s,t)return t>=16 and t<22 and inside(s,t)end,
   function(s,t)return{x+s,c.seatHeight*(22-t)/6,z+12+c.seatDepth}end)
 elseif o.kind=='cableTerminal'then
  local src,inside=R.cutout(L,ts,o.x*16,o.y*16,16,32,{0x2c4+shift,0x2c6+shift})
  draw(16,32,src,function(s,t)return t>=5 and t<9 and inside(s,t)end,
   function(s,t)return{x+s,c.terminalHeight,z+32-c.terminalDepth+(t-5)*c.terminalDepth/4}end)
  draw(16,32,src,function(s,t)return t>=9 and inside(s,t)end,
   function(s,t)return{x+s,c.terminalHeight*(32-t)/23,z+32}end)
 elseif o.kind=='cableConsole'then
  draw(64,48,function(s,t)if R.screen(s-46,t-22)then return source(2,10)end;return source(s,t)end,R.consoleTop,
   function(s,t)return{x+s,c.consoleHeight,z+t}end)
  draw(64,48,source,function(s,t)return t>=40 and(s>=(t>=44 and t-43 or 0))and s<64-(t>=44 and t-43 or 0)end,
   function(s,t)return{x+s,c.consoleHeight*(48-t)/8,z+40}end)
  -- Inner rear face stays vertical; native floor remains visible in the opening.
  draw(64,48,source,function(s,t)return s>=10 and s<54 and t>=14 and t<22 end,
   function(s,t)return{x+s,c.consoleHeight*(22-t)/8,z+14}end)
  for _,edge in ipairs({{10,14,30},{54,14,30},{0,6,40},{64,6,40}})do
   local xx,lo,hi=unpack(edge)
   draw(hi-lo,8,function(_,t)return source(xx==64 and 63 or math.max(0,xx-1),40+t)end,nil,
    function(s,t)return{x+xx,c.consoleHeight*(8-t)/8,z+lo+s}end,c.sideShade)
  end
 elseif o.kind=='cableScreen'then
  draw(18,17,source,R.screen,function(s,t)return{x+s,c.consoleHeight+c.screenHeight*(17-t)/17,z+17}end)
 end
 if contacts and o.kind~='cableFloor'and o.kind~='cableWall'and o.kind~='cableScreen'then contacts[#contacts+1]={x+o.w/2,z+o.h,o.w*.4,2,c.contactStrength}end
end
return R
