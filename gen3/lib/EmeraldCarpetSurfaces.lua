-- Four native Xeneroville/Sootopolis home layouts, with complete woven floor.
local V=...
local C={}
function C.plan(def,p)
 local L=def.midLayout;local cfg=V.require('DioramaConfig').emeraldInteriors
 local objects,mask={},{}
 local function add(o,x,y,w,h)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.residentialHome=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then
    mask[k]=o.kind=='wall'and{mid=p.void,void=true}or(yy==2 or xx==0)and p.edgeFloor or p.floor
   end
  end end
  return o
 end
 local function clear(x,w)
  for _,o in ipairs(objects)do if o.kind=='wall'and o.x>=x and o.x<x+w then o.clean={0x3f0,0x3f8}end end
 end
 local function fold(x,y,w,h,cap,split,last,height,depth,front,bounds)
  return add({kind='fold',cap=cap,split=split,last=last,height=height,depth=depth,front=front,bounds=bounds},x,y,w,h)
 end
 for x=0,L.width-1 do add({kind='wall'},x,0,1,2)end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if m==0x2c8 then
   fold(x,y,2,3,10,16,40,cfg.homeCabinetHeight,9,48,{0,32});clear(x,2)
  elseif m==0x2cd then
   fold(x,y,1,2,1,8,24,cfg.homeCabinetHeight,7,32,{1,15});clear(x,1)
  elseif m==0x230 then
   add({kind='card',cap=13,last=40,front=48,height=30,background={{mid=0x3f0},{mid=0x3f8},{mid=p.edgeFloor}},positionMask=true},x,y,1,3);clear(x,1)
  elseif m==0x294 then
   add({kind='card',cap=0,last=32,front=32,height=cfg.homePlantHeight,background={{mid=p.floor},{mid=p.edgeFloor},{mid=0x3f8}},positionMask=true},x,y,1,2);clear(x,1)
  elseif m==0x2bd then
   fold(x,y,1,2,2,9,29,36,8,32,{1,15});clear(x,1)
  elseif m==0x2bb then
   fold(x,y,2,2,5,16,24,cfg.homeKitchenHeight,16,32,{1,31}).faucet=true;clear(x,2)
  elseif m==0x292 then
   add({kind='seat',cap=8,backEnd=17,seatEnd=27,last=32,backHeight=cfg.sofaBackHeight,seatHeight=cfg.sofaSeatHeight,depth=cfg.sofaSeatDepth,front=16+cfg.sofaSeatDepth+cfg.wallClearance,background={{mid=p.floor},{mid=p.edgeFloor},{mid=0x3f8}}},x,y,2,2);clear(x,2)
  elseif m==0x3f3 or m==0x3dd then
   local o=fold(x,y,2,2,0,25,32,cfg.tableHeight,25,32);o.background={{mid=p.floor}};o.residentialTable=true
  elseif m==0x2dd or m==0x2de then
   add({kind='card',cap=0,last=16,front=16,height=cfg.chairHeight,background={{mid=p.floor}},positionMask=true},x,y,1,1)
  end
 end end
 return objects,mask
end
return C
