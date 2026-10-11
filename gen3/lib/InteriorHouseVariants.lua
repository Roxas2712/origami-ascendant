-- Measured native wooden-house layouts. Puzzle rooms are excluded.
local V=...
local H={}
local nativePalmInside
function H.profile(def)
 local c=V.require('DioramaConfig').interiors.houseVariants;local L=def.midLayout
 if not c.enabled or not L or L.width~=12 or L.height~=10 then return end
 if def.id=='FR_THREE_ISLAND_HOUSE1' and c.islandKitchen.enabled and (def.pair=='oak_lab' or def.pair=='house') then
  local anchors={{0,0,0x13d},{1,0,0x13e},{2,1,0x326},{2,2,0x32e},{4,0,0x118},{5,0,0x160},{8,0,0x138},{9,0,0x139},{10,0,0x10f},{0,4,0x156},{0,5,0x15e},{0,6,0x156},{0,7,0x15e},{5,4,0x165},{6,4,0x166},{5,5,0x16d},{6,5,0x16e},{3,4,0x109}}
  for _,a in ipairs(anchors)do if L:midAt(a[1],a[2])~=a[3]then return end end
  return c
 end
 if def.pair~='house' then return end
 local first=L:midAt(0,0)
 if (first==0xc2 and L:midAt(8,3)==0x165 or first==0x122 and L:midAt(5,4)==0x165 or first==0x10e and L:midAt(5,4)==0x165)
  and L:midAt(3,4)==0x109 then return c end
end
-- Native item event on the Sevault dining table. Only its visual elevation
-- changes; the event stays at the original cell and keeps its original script.
function H.actorHeight(def,x,z)
 local c=H.profile(def)
 if not c or not V.require('IndoorSurfaces').profile(def)then return end
 local id=def.id or def.name
 local item=c.tableItems[id]
 if item and math.floor((x+8)/16)==item.x and math.floor((z+15.99)/16)==item.y
  and def.midLayout:midAt(item.x,item.y)==item.mid then
  return c.tableHeight*V.require('DioramaConfig').interiors.heightScale
 end
end
function H.plan(def)
 local c=H.profile(def);if not c or not V.require('IndoorSurfaces').profile(def)then return end
 local L=def.midLayout;local living=L:midAt(0,0)==0xc2;local kitchen=L:midAt(0,0)==0x122
 local island=def.id=='FR_THREE_ISLAND_HOUSE1'
 local objects,mask,owners={},{},{}
 local function add(o,x,y,w,h)
  o.x=x;o.y=y;o.w=w;o.living=living;o.island=island;o.houseVariant=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*12+xx+1;mask[k]=0x109;owners[k]=o end end
  return o
 end
 local wall=add({kind='houseVariantWall',front=c.wallFoot,clear={}},0,0,11,3)
 for y=0,1 do for x=0,10 do mask[y*12+x+1]={mid=0,void=true}end end
 local function fold(x,y,w,cap,split,last,height,depth)
  return add({kind='houseVariantFold',cap=cap,split=split,last=last,front=last,height=height,depth=depth},x,y,w,math.ceil(last/16))
 end
 local function back(x,w,cap,split,last,height,depth,shape)
  local o=fold(x,0,w,cap,split,last,height,depth);o.shape=shape
  for xx=x,x+w-1 do wall.clear[xx]=true end
  return o
 end
 local function plant(x,y,wallPlant,w)
  local broad=(w or 1)==2
  local o=add({kind='houseVariantPlant',cap=wallPlant and 12 or 4,last=wallPlant and (broad and 39 or 40)or(broad and 31 or 32),front=wallPlant and 40 or 32,shape=broad and 'broadPlant' or 'nativePalm'},x,y,w or 1,wallPlant and 3 or 2)
  if wallPlant then for xx=x,x+(w or 1)-1 do wall.clear[xx]=true end end
 end
 if island then
  back(0,2,11,13,40,c.shelfHeight,7,'islandShelf')
  back(2,1,20,20,39,c.islandKitchen.clockCabinetHeight,0,'islandClock')
  local sink=back(8,2,19,31,40,c.sinkHeight,14,'sink');sink.faucet=true;sink.front=c.islandKitchen.sinkFront
  back(10,1,13,15,40,c.fridgeHeight,8,'fridge')
  for _,y in ipairs({4,6})do
   local o=add({kind='plant',rows=2,ground=0x109},0,y,1,2);o.y=y+1
  end
 elseif living then
  for x=0,2 do plant(x,0,true)end
  back(6,1,18,20,39,c.drawerHeight,5,'drawer')
  for _,x in ipairs({7,9})do back(x,2,11,13,39,c.shelfHeight,7,'greenShelf')end
  for _,y in ipairs({4,6})do plant(0,y,false,2)end
 else
  local x=kitchen and 1 or 0
  back(x,1,14,16,39,c.shelfHeight,6,'blueShelf')
  back(x+1,2,12,14,39,c.shelfHeight,8,'cabinet')
  add({kind='houseVariantBin',cap=25,last=39,front=39,shape='bin'},x+2,0,1,3)
  if kitchen then
   plant(0,0,true)
   local sink=back(8,2,19,31,40,c.sinkHeight,14,'sink');sink.faucet=true;sink.front=c.kitchenSinkFront
   back(10,1,13,15,39,c.fridgeHeight,8,'fridge')
   for _,y in ipairs({3,6})do plant(0,y)end
  else for _,y in ipairs({4,6})do plant(0,y)end end
 end
 for y=3,7 do for x=0,10 do
  local m=L:midAt(x,y)
  if m==0x111 and not mask[y*12+x+1]then mask[y*12+x+1]=0x109 end
  if m==0x165 and L:midAt(x+1,y)==0x166 then fold(x,y,2,0,24,31,c.tableHeight,c.tableDepth)
  elseif m==0x16f or m==0x167 then
   add({kind='houseVariantChair',last=16,front=15,right=m==0x167},x,y,1,1)
  end
 end end
 -- Rear source floor margins survive as floor, not repeated wall shadows.
 for y=0,1 do for x=0,10 do mask[y*12+x+1]={mid=0,void=true}end end
 return {objects=objects,mask=mask,owners=owners}
end
function H.houseVariantWall(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').interiors.houseVariants
 for sx=0,175 do for sy=0,31 do
  local mx=sx
  local clear=o.clear[math.floor(sx/16)]
  if clear==true or type(clear)=='number'and sy>=clear then mx=o.living and 79 or (L:midAt(0,0)==0x122 and 95 or 63)end
  local m=L:midAt(math.floor(mx/16),math.floor(sy/16))
  G.quad(out,{x+sx,c.wallHeight*(32-sy)/32,z+c.wallFoot},{x+sx+1,c.wallHeight*(32-sy)/32,z+c.wallFoot},
   {x+sx+1,c.wallHeight*(31-sy)/32,z+c.wallFoot},{x+sx,c.wallHeight*(31-sy)/32,z+c.wallFoot},G.uv(ts,m,mx%16,sy%16,mx%16+1,sy%16+1,.5),1)
 end end
end
-- Native silhouettes measured in source pixels. Cabinet faces may use the
-- wall's palette internally; background rows and neighbouring bin pixels do
-- not belong to them. Plants use their actual leaf/pot contour, not a tile box.
local palmRows={
 [4]={7,9},[5]={6,10},[6]={2,14},[7]={2,14},[8]={2,14},[9]={2,14},
 [10]={1,15},[11]={0,16},[12]={0,16},[13]={2,14},[14]={2,14},
 [15]={1,15},[16]={1,15},[17]={1,15},[18]={4,12},[19]={5,11},
 [20]={4,12},[21]={3,13},[22]={3,13},[23]={3,13},[24]={3,13},
 [25]={3,13},[26]={4,12},[27]={4,12},[28]={4,12},[29]={5,11},[30]={6,10},
}
local broadRows={0x0,0x0,0x0,0x0,0xc00,0xe00,0xf06,0xf1e,0x7fbc,0x7ffc,0x3ff8,0xffff,0x7fff,0x3ffe,0x1ffe,0x1ffe,0x3ffc,0x7ff8,0xfffe,0x7fff,0x1fff,0xff0,0x1ff8,0x1ff8,0x1ff8,0x1ff8,0xff0,0xff0,0xff0,0x7e0,0x3c0,0x0}
function H.sourceInside(o,s,t)
 if s<0 or s>=o.w*16 or t<o.cap or t>=o.last then return false end
 local k=o.shape
 if k=='nativePalm'then
  nativePalmInside=nativePalmInside or V.require('HomePlants').mask()
  return nativePalmInside(s,t-(o.y==0 and 8 or 0))
 elseif k=='palm'then
  local r=palmRows[t-(o.y==0 and 8 or 0)]
  return r and s>=r[1]and s<r[2]or false
 elseif k=='broadPlant'then
  local mask=broadRows[t+1]or 0
  return math.floor(mask/2^(s%16))%2==1
 elseif k=='cabinet'then return s>=1 and s<24
 elseif k=='blueShelf'then
  local lo=t==14 and 2 or t==15 and 1 or 0;return s>=lo and s<16-lo
 elseif k=='fridge'then return s>=(t==13 and 2 or 1)and s<(t==13 and 15 or 16)
 elseif k=='islandClock'then
  if t==20 then return s>=5 and s<=7 end
  if t<=22 then return s>=1 and s<15 end
  return true
 elseif k=='islandShelf'or k=='greenShelf'then
  if t==11 then return s==1 or s==30 end
  if t==12 then return s>=1 and s<=4 or s>=28 and s<=30 end
  return s>=1 and s<31
 elseif k=='drawer'then return t~=18 or s<4 or s>=12
 elseif k=='sink'then return t~=19 or s>=1 and s<31
 elseif k=='bin'then
  local lo,hi=8,15
  if t==25 then lo,hi=10,13 elseif t==26 then lo,hi=9,14
  elseif t==37 then lo,hi=9,14 elseif t==38 then lo,hi=10,13 end
  return s>=lo and s<hi
 end
 return false
end
local function strips(api,out,L,ts,o,fn)
 local source,inside
 if o.shape then
  source=function(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  inside=function(s,t)return H.sourceInside(o,s,t)end
 else
  source,inside=api.nativeMask(L,ts,o,o.w*16,o.last,{0x109,0x111})
 end
 local function band(a,b,project,extra,override)
  local v=V.require('PaperSprite').build(ts,o.w*16,o.last,override or source,function(s,t)return t>=a and t<b and (extra and extra(s,t)or not extra and inside(s,t))end,0,o.last,1,nil,project,.5)
  for _,p in ipairs(v)do out[#out+1]=p end
 end
 fn(band,source,inside)
end
function H.houseVariantFold(api,out,L,ts,o,x,z)
 strips(api,out,L,ts,o,function(band,source,inside)
  local topSource
  if o.faucet then topSource=function(s,t)
   if s>=9 and s<=12 and t<24 then return source(8,24)end
   return source(s,t)
  end end
  band(o.cap,o.split,function(s,t)return{x+s,o.height,z+o.front-o.depth+(t-o.cap)*o.depth/(o.split-o.cap)}end,nil,topSource)
  band(o.split,o.last,function(s,t)return{x+s,o.height*(o.last-t)/(o.last-o.split),z+o.front}end)
  local G=V.require('WorldGeometry')
  for t=o.cap,o.split-1 do
   local a,b;for s=0,o.w*16-1 do if inside(s,t)then a=a or s;b=s end end
   if a then for _,s in ipairs({a,b+1})do
    local m,u,v=source(s==a and a or b,t);local za=z+o.front-o.depth+(t-o.cap)*o.depth/(o.split-o.cap);local zb=za+o.depth/(o.split-o.cap)
    G.quad(out,{x+s,o.height,za},{x+s,o.height,zb},{x+s,0,zb},{x+s,0,za},G.uv(ts,m,u,v,u+1,v+1,.5),.92)
   end end
  end
  if o.faucet then band(16,24,function(s,t)return{x+s,o.height+(24-t),z+o.front-o.depth+4}end,function(s)return s>=9 and s<=12 end)end
 end)
end
function H.houseVariantPlant(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.houseVariants
 strips(api,out,L,ts,o,function(band)
  band(o.cap,o.last,function(s,t)return{x+s,c.plantHeight*(o.last-t)/(o.last-o.cap),z+o.front}end)
 end)
end
function H.houseVariantBin(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.houseVariants
 strips(api,out,L,ts,o,function(band)band(o.cap,o.last,function(s,t)return{x+s,c.binHeight*(o.last-t)/(o.last-o.cap),z+o.front}end)end)
end
function H.houseVariantChair(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.houseVariants
 strips(api,out,L,ts,o,function(band)
  band(0,16,function(s,t)return{x+s,c.chairHeight*(16-t)/16,z+15}end)
 end)
end
-- The faucet is taller than its counter, but is not a full-width light blocker.
-- Dining-table light passes through the open space below the slab.
function H.capture(list,o,x,z)
 if not o.houseVariant then return false end
 if o.kind=='houseVariantChair' then return true end
 if o.kind~='houseVariantFold' then return false end
 local cfg=V.require('DioramaConfig').interiors;local hs=cfg.heightScale
 local function box(a,b,back,front,low,high)
  list[#list+1]={lo={x+a,low*hs,z+back},hi={x+b,high*hs,z+front},wall=false}
 end
 if o.faucet then
  box(0,32,o.front-o.depth,o.front,0,o.height)
  box(9,13,o.front-o.depth+3.75,o.front-o.depth+4.25,o.height,o.height+8)
 elseif o.y>0 then
  box(0,o.w*16,o.front-o.depth,o.front,o.height-cfg.houseVariants.islandKitchen.tableThickness,o.height)
 else return false end
 return true
end
return H
