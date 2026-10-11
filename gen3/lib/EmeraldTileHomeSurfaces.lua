-- Native Rustboro tile-floor layouts. Artwork and event coordinates are read-only.
local V=...
local H={}
function H.plan(def,p)
 local L=def.midLayout;local c=V.require('DioramaConfig').emeraldInteriors
 local objects,mask={},{}
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.residentialHome=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then
    mask[k]=o.kind=='wall'and{mid=p.void,void=true}or donor or(yy==2 or xx==0)and p.edgeFloor or p.floor
   end
  end end
  return o
 end
 local function clear(x,w)
  for _,o in ipairs(objects)do if o.kind=='wall'and o.x>=x and o.x<x+w then o.clean={0x338,0x340}end end
 end
 local function fold(x,y,w,h,cap,split,last,height,depth,front,bounds,donor)
  return add({kind='fold',cap=cap,split=split,last=last,height=height,depth=depth,front=front,bounds=bounds},x,y,w,h,donor)
 end
 local width=L.width;while L:midAt(width-1,0)==p.void do width=width-1 end
 for x=0,width-1 do add({kind='wall'},x,0,1,2)end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if m==0x379 then
   fold(x,y,2,3,10,16,40,c.homeCabinetHeight,9,48,{0,32});clear(x,2)
  elseif m==0x366 then
   fold(x,y,2,3,12,20,40,c.homeCabinetHeight,9,48,{1,31});clear(x,2)
  elseif m==0x34a then
   fold(x,y,2,2,1,4,24,22,5,32,{0,32});clear(x,2)
  elseif m==0x349 then
   fold(x,y,1,2,1,8,24,c.homeCabinetHeight,7,32,{1,15});clear(x,1)
  elseif m==0x331 then
   add({kind='card',cap=13,last=40,front=48,height=30,background={{mid=0x338},{mid=0x340},{mid=p.edgeFloor}},positionMask=true},x,y,1,3);clear(x,1)
  elseif m==0x343 or m==0x346 or m==0x347 then
   add({kind='card',cap=0,last=32,front=32,height=c.homePlantHeight,background={{mid=p.floor},{mid=p.edgeFloor},{mid=0x340}},positionMask=true},x,y,1,2)
   if y<2 then clear(x,1)end
  elseif m==0x378 then
   fold(x,y,1,3,10,18,40,36,8,48,{1,15});clear(x,1)
  elseif m==0x356 then
   local o=fold(x,y,2,2,5,16,24,c.homeKitchenHeight,16,32,{1,31});o.faucet=true;o.detailWallMid=0x340;clear(x,2)
  elseif m==0x354 then
   add({kind='seat',cap=8,backEnd=17,seatEnd=27,last=32,backHeight=c.sofaBackHeight,seatHeight=c.sofaSeatHeight,depth=c.sofaSeatDepth,front=16+c.sofaSeatDepth+c.wallClearance,background={{mid=p.floor},{mid=p.edgeFloor},{mid=0x340}}},x,y,2,2);clear(x,2)
  elseif m==0x36a or m==0x37e or m==0x248 then
   local donor=m==0x248 and 0x23e or p.floor
   local o=fold(x,y,m==0x37e and 3 or 2,2,0,25,32,c.tableHeight,25,32,nil,donor)
   o.background={{mid=donor}};o.positionMask=true;o.residentialTable=true
  elseif m==0x344 or m==0x345 or m==0x2e1 or m==0x2e2 then
   local donor=(m==0x2e1 or m==0x2e2)and 0x23e or p.floor
   add({kind='card',cap=0,last=16,front=16,height=c.chairHeight,background={{mid=donor}},positionMask=true},x,y,1,1,donor)
  end
 end end
 return objects,mask
end
return H
