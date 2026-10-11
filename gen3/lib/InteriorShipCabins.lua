-- Two measured S.S. Anne cabin templates, shared by eighteen native rooms.
local V=...
local C={}
function C.profile(d)
 local c=V.require('DioramaConfig').interiors.shipCabins;local L=d.midLayout;local id=d.id or d.name or ''
 if not c.enabled or (d.renderPair or d.pair)~='general__rom_082d4d94'or not L or L.width~=6 then return end
 local floor,n=id:match('^FR_SSANNE_(%w+)_ROOM(%d+)$');n=tonumber(n)
 if floor=='1F'and n and n>=1 and n<=7 and L.height==8 and L:midAt(0,5)==0x338 and L:midAt(2,0)==0x3bf then return c.green end
 if(floor=='2F'and n and n>=1 and n<=6 or floor=='B1F'and n and n>=1 and n<=5)and L.height==10 and L:midAt(0,2)==0x342 and L:midAt(4,7)==0x33e then return c.gold end
end
function C.plan(d)
 local p=C.profile(d);if not p or not V.require('IndoorSurfaces').profile(d)then return end
 local objects,mask,owners={},{},{};local L=d.midLayout;local green=p.green
 local function add(o,x,y,w,h)
  o.x=x;o.y=y;o.w=w;o.last=h*16;o.green=green;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*6+xx+1;owners[k]=o end end
  return o
 end
 for y=0,L.height-1 do for x=0,5 do local m=L:midAt(x,y);local k=y*6+x+1
  if y<2 or m==0x288 then mask[k]={mid=0x288,void=true}
  elseif not(m>=0x33d and m<=0x33f or m>=0x2ca and m<=0x2cc)then
   mask[k]=green and(y==2 and(x==0 and 0x31d or 0x31e)or x==0 and 0x31f or 0x31c)or(x==0 and 0x327 or 0x324)
  end
 end end
 for x=0,5 do add({kind='shipCabinWall',plant=green and x==5,front=32},x,0,1,2)end
 add({kind='shipCabinBed',front=32,contactFront=32,contactWidth=20,contactOffset=14},3,green and 5 or 2,3,2)
 if green then
  add({kind='shipCabinDesk',front=42,contactWidth=20,contactOffset=8},0,5,2,3)
  add({kind='shipCabinPlant',front=32,contactWidth=8,contactOffset=4},5,1,1,2)
  add({kind='shipCabinChair',right=true,front=16,contactWidth=8,contactOffset=6},2,6,1,1)
 else
  for y=7,8 do for x=3,5 do mask[y*6+x+1]=y==8 and{mid=0x288,void=true}or 0x324 end end
  add({kind='shipCabinRug',base=.03},3,7,3,2)
  add({kind='shipCabinTable',front=26,contactWidth=44,contactOffset=2},0,2,3,2)
  add({kind='shipCabinPlant',front=32,contactWidth=8,contactOffset=4},0,6,1,2)
  add({kind='shipCabinChair',front=16,contactWidth=8,contactOffset=2},1,4,1,1)
 end
 return {objects=objects,mask=mask,owners=owners}
end
function C.actorHeight(d,x,z)
 local p=C.profile(d);if not p or not V.require('IndoorSurfaces').profile(d)then return end
 local cx,cy=math.floor((x+8)/16),math.floor((z+15.99)/16)
 local c=V.require('DioramaConfig').interiors
 -- The native item event stands on the table, not on the floor beneath it.
 -- Only presentation height changes; its cell, script and pickup flag do not.
 if (d.id or d.name)=='FR_SSANNE_B1F_ROOM5'and cx==2 and cy==2 and d.midLayout:midAt(cx,cy)==0x344 then
  return c.shipCabins.tableHeight*c.heightScale
 end
 if cx==(p.green and 2 or 1)and cy==(p.green and 6 or 4)then
  return c.shipCabins.seatHeight*c.heightScale
 end
end
local plantRows={ [4]={7,9},[5]={6,10},[6]={2,14},[7]={2,14},[8]={2,14},[9]={2,14},[10]={1,15},[11]={0,16},[12]={0,16},[13]={2,14},[14]={2,14},[15]={1,15},[16]={1,15},[17]={1,15},[18]={4,12},[19]={5,11},[20]={4,12},[21]={3,13},[22]={3,13},[23]={3,13},[24]={3,13},[25]={3,13},[26]={3,13},[27]={3,13},[28]={3,13},[29]={3,13},[30]={4,12}}
function C.inside(o,s,t)
 if o.kind=='shipCabinPlant'then local r=plantRows[t];return r and s>=r[1]and s<r[2]or false end
 if o.kind=='shipCabinBed'then
  if t<3 or t>=32 then return false end
  if t==30 then return s>=15 and s<19 or s>=29 and s<33 end
  if t==31 then return s>=16 and s<18 or s>=30 and s<32 end
  local a=t==3 and 19 or t==4 and 17 or t==5 and 16 or t<11 and 15 or 14
  return s>=a and s<48-a
 end
 if o.kind=='shipCabinTable'or o.kind=='shipCabinDesk'then
  local desk=o.kind=='shipCabinDesk';local endTop=desk and 40 or 24;local lo,hi=desk and 8 or 0,desk and 32 or 48
  if t<5 or t>=endTop+8 then return false end
  if t==5 then return s>=lo+1 and s<hi-1 end
  if t<=endTop+1 then return s>=lo and s<hi end
  if t<=endTop+3 then return s>=lo+1 and s<hi-1 end
  if t<endTop+7 then return s>=lo+1 and s<lo+5 or s>=hi-5 and s<hi-1 end
  return s>=lo+2 and s<lo+4 or s>=hi-4 and s<hi-2
 end
 if o.kind=='shipCabinChair'then
  if o.right then s=15-s end
  if t<0 or t>=16 then return false end
  if t==0 then return s>=1 and s<4 end
  if t<4 then return s>=0 and s<5 end
  if t==4 then return s>=0 and s<11 end
  if t<10 then return s>=0 and s<12 end
  if t<15 then return s>=1 and s<12 end
  return s>=1 and s<4 or s>=9 and s<11
 end
 return true
end
function C.build(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.shipCabins;local G=V.require('WorldGeometry')
 local function source(s,t)
  if o.kind=='shipCabinWall'and o.plant then return t<16 and 0x28c or 0x291,s,t%16 end
  return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16
 end
 local function draw(a,b,project,filter)
  local vv=V.require('PaperSprite').build(ts,o.w*16,o.last,source,function(s,t)return t>=a and t<b and C.inside(o,s,t)and(not filter or filter(s,t))end,0,o.last,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function side(s,t,a,b,shade)local m,u,v=source(s,t);G.quad(out,{x+a[1],a[2],z+a[3]},{x+b[1],b[2],z+b[3]},{x+b[1],0,z+b[3]},{x+a[1],0,z+a[3]},G.uv(ts,m,u,v,u+1,v+1,.5),shade or .95)end
 if o.kind=='shipCabinWall'then
  draw(0,32,function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
 elseif o.kind=='shipCabinPlant'then
  draw(4,31,function(s,t)return{x+s,c.plantHeight*(31-t)/27,z+32}end)
 elseif o.kind=='shipCabinBed'then
  local start=32-c.bedDepth
  draw(3,9,function(s,t)return{x+s,c.bedHeight+(9-t)*(c.headHeight-c.bedHeight)/6,z+start}end)
  draw(9,26,function(s,t)return{x+s,c.bedHeight,z+start+(t-9)*c.bedDepth/17}end)
  draw(26,32,function(s,t)return{x+s,c.bedHeight*(32-t)/6,z+32}end)
  for _,s in ipairs({15,33})do side(s,25,{s,c.bedHeight,start},{s,c.bedHeight,32})end
 elseif o.kind=='shipCabinTable'or o.kind=='shipCabinDesk'then
  local desk=o.kind=='shipCabinDesk';local split=desk and 40 or 24;local depth=desk and c.deskDepth or c.tableDepth;local front=o.front
  draw(5,split,function(s,t)return{x+s,c.tableHeight,z+front-depth+(t-5)*depth/(split-5)}end)
  draw(split,split+8,function(s,t)return{x+s,c.tableHeight*(split+8-t)/8,z+front}end)
  for _,s in ipairs(desk and{9,31}or{1,47})do side(s,split,{s,c.tableHeight,front-depth},{s,c.tableHeight,front})end
 elseif o.kind=='shipCabinChair'then
  -- Preserve the native side-view chair silhouette as one upright cutout.
  draw(0,16,function(s,t)return{x+s,c.chairHeight*(16-t)/16,z+16}end)
 elseif o.kind=='shipCabinRug'then
  draw(4,20,function(s,t)return{x+s,c.rugHeight,z+t}end,function(s)return s>=11 and s<37 end)
 end
end
return C
