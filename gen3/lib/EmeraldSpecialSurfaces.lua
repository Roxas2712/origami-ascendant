-- Individually measured public/special rooms. Never infer these from a shared atlas.
local V=...
local S={}
function S.plan(def,p)
 local L=def.midLayout;local c=V.require('DioramaConfig').emeraldInteriors
 local objects,mask={},{}
 local function floor(x,y)
  if p.style=='scott' then return (x+y)%2==0 and 0x3c8 or 0x3c9 end
  if p.style=='seashore' then return y==2 and 0x21a or L:midAt(2,y) end
  return x==0 and p.edgeFloor or p.floor
 end
 local function add(o,x,y,w,h,donor)
  if p.style=='lanette'then o.specialHomeLighting='lanette'end
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=o.kind=='wall'and{mid=p.void,void=true}or donor or floor(xx,yy)end
  end end
  return o
 end
 local function fold(x,y,w,h,cap,split,last,height,depth,front,bounds)
  return add({kind='fold',cap=cap,split=split,last=last,height=height,depth=depth,front=front,bounds=bounds},x,y,w,h)
 end
 local function clear(x,w,top,bottom)
  for _,o in ipairs(objects)do if o.kind=='wall'and o.x>=x and o.x<x+w then o.clean={top,bottom}end end
 end
 if p.style=='school' then
  for x=0,L.width-1 do add({kind='wall',wallCap=8,wallLast=48,wallHeight=c.schoolWallHeight,wallBase=48},x,0,1,3)end
  for y=3,L.height-1 do for x=0,L.width-1 do
   local m=L:midAt(x,y)
   if m==0x21c then
    fold(x,y,2,2,10,23,32,c.tableHeight,14,32,{1,31})
    for xx=x,x+1 do mask[y*L.width+xx+1]=0x221 end
   elseif m==0x20c or m==0x20d or m==0x20e then
    local o=fold(x,y,1,2,0,11,16,c.schoolDeskHeight,11,16,{1,15});o.schoolDesk=true
    add({kind='card',cap=13,last=27,front=32,height=c.chairHeight,bounds={3,14},background={{mid=p.floor}},positionMask=true},x,y,1,2)
   end
  end end
 elseif p.style=='lanette' then
  for x=0,10 do add({kind='wall'},x,0,1,2)end
  for y=0,L.height-1 do for x=0,10 do
   local m=L:midAt(x,y)
   if m==0x210 then
    fold(x,y,2,3,10,19,40,c.homeCabinetHeight,9,40,{0,32});clear(x,2,0x208,0x20a)
   elseif m==0x22c then
    local o=fold(x,y-1,2,3,5,27,46,c.homeCabinetHeight,22,48,{1,31});o.shelfBox=true
   elseif m==0x212 then
    local o=fold(x,y+1,2,2,5,16,24,c.tableHeight,17,24);o.desk=true;o.lab=true;o.pc=true;clear(x,2,0x208,0x20a)
   elseif m==0x24c then
    local o=fold(x,y,2,2,5,16,24,c.tableHeight,17,24);o.desk=true;o.lab=true;o.book=true;o.labBall=true;clear(x,2,0x208,0x20a)
   elseif m==0x250 or m==0x251 then
    local o=fold(x,y,1,2,20,24,32,c.tableHeight,14,32,{1,15});o.bench=true;o.pcHeight=20
   elseif m==0x230 then
    local o=fold(x,y,1,3,20,40,48,c.tableHeight,28,48,{1,15});o.bench=true;o.pcHeight=20;o.deviceOffset=-26;o.benchCup=true
   elseif m==0x232 then
    add({kind='card',cap=0,last=16,front=16,height=16,background={{mid=p.floor}},positionMask=true},x,y,1,1)
   elseif m==0x228 or m==0x24a then
    fold(x,y,1,1,0,5,16,c.boxHeight,6,16,{1,15})
   elseif m==0x229 then
    fold(x,y,1,2,8,14,32,c.boxHeight,8,32,{1,15})
   elseif m==0x23a then
    fold(x,y,1,3,8,14,40,c.boxHeight*2,8,40,{1,15})
   end
  end end
 elseif p.style=='seashore' then
  for x=0,14 do
   local endPost=x==0 or x==14
   add({kind='wall',wallLast=endPost and 48 or 32,wallHeight=endPost and 40 or 32,wallFloor=nil},x,0,1,endPost and 3 or 2)
  end
  for _,x in ipairs({1,12})do
   fold(x,1,2,2,0,7,31,c.homeCabinetHeight,7,32,{1,31})
   clear(x,2,0x202,0x20a)
  end
  local drink=fold(7,1,1,2,19,26,32,c.tableHeight,9,32,{1,15});drink.drink=true;clear(7,1,0x202,0x20a)
  add({kind='card',cap=0,last=16,front=16,height=c.chairHeight,background={{mid=0x21a}},positionMask=true},6,2,1,1,0x21a)
  for y=3,L.height-1 do for x=0,14 do
   local m=L:midAt(x,y)
   if m==0x218 or m==0x220 then
    local w=1;while x+w<=14 and L:midAt(x+w,y)==0x210 do w=w+1 end
    if L:midAt(x+w,y)==0x219 or L:midAt(x+w,y)==0x221 then w=w+1 end
    local o=fold(x,y,w,1,0,12,16,c.seashoreBenchHeight,12,16);o.background={{mid=floor(x,y)}};o.positionMask=true
   end
  end end
 else
  for x=0,L.width-1 do add({kind='wall'},x,0,1,2)end
  add({kind='seat',cap=0,backEnd=7,seatEnd=13,last=16,backHeight=c.chairHeight,seatHeight=5,depth=7,front=16,background={{mid=0x3c8},{mid=0x3c9}},positionMask=true},5,3,1,1)
  add({kind='card',cap=0,last=32,front=32,height=c.homePlantHeight,background={{mid=0x3c8},{mid=0x3c9}},positionMask=true},5,4,1,2)
 end
 return objects,mask
end
return S
