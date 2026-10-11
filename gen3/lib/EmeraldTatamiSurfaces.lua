-- Measured native tatami furniture. Explicit map ownership lives in Emerald.lua.
local V=...
local T={}
function T.plan(def,p)
 local L=def.midLayout;local c=V.require('DioramaConfig').emeraldInteriors
 local objects,mask={},{}
 local function donor(x,y)return (y==2 or x==0)and 0x221 or 0x229 end
 local function add(o,x,y,w,h)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.tatamiHome=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=o.kind=='wall'and{mid=0x201,void=true}or donor(xx,yy)end
  end end
  return o
 end
 local function clear(x,w)
  for _,o in ipairs(objects)do if o.kind=='wall'and o.x>=x and o.x<x+w then o.clean={0x215,0x21d}end end
 end
 local function fold(x,y,w,h,cap,split,last,height,depth,front,bounds)
  return add({kind='fold',cap=cap,split=split,last=last,height=height,depth=depth,front=front,bounds=bounds},x,y,w,h)
 end
 for x=0,L.width-1 do add({kind='wall'},x,0,1,2)end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local mid=L:midAt(x,y)
  if mid==0x2be then
   fold(x,y,2,3,12,20,40,c.homeCabinetHeight,9,48,{1,31});clear(x,2)
  elseif mid==0x2b1 then
   fold(x,y,2,3,11,18,40,c.homeCabinetHeight,8,48,{2,23});clear(x,2)
  elseif mid==0x2a6 or mid==0x316 then
   fold(x,y,2,3,10,16,40,c.homeCabinetHeight,9,48,{0,32});if y<2 then clear(x,2)end
  elseif mid==0x216 then
   add({kind='card',cap=13,last=40,front=48,height=30,background={{mid=0x215},{mid=0x21d},{mid=0x221}},positionMask=true},x,y,1,3);clear(x,1)
  elseif mid==0x2a0 or mid==0x2a1 then
   fold(x,y,1,2,1,8,24,c.homeCabinetHeight,7,32,{1,15});clear(x,1)
  elseif mid==0x2e3 or mid==0x2e4 then
   add({kind='card',cap=0,last=38,front=48,height=c.tatamiPillarHeight,opaque=true,bounds=mid==0x2e3 and{0,7}or{9,16}},x,y,1,3);clear(x,1)
  elseif mid==0x24e then
   local o=fold(x,y,2,2,0,25,32,c.tatamiTableHeight,25,32)
   o.tatamiTable=true;o.background={{mid=0x229},{mid=0x221}};o.tatamiGlass=L:midAt(x+1,y)==0x24f
  elseif mid==0x244 or mid==0x259 then
   fold(x,y,1,1,2,12,15,c.tatamiCushionHeight,12,15,{2,14})
  elseif mid==0x2b3 or mid==0x2b4 then
   add({kind='card',cap=0,last=16,front=16,height=c.tatamiBasketHeight,background={{mid=0x229},{mid=0x221}},positionMask=true},x,y,1,1)
  end
 end end
 if def.id=='EM_ROUTE114_FOSSIL_MANIACS_HOUSE' then
  -- The native cave doorway is kept complete, including the broken plaster.
  add({kind='card',cap=0,last=48,front=48,height=40,background={{mid=0x215},{mid=0x21d},{mid=0x221}},positionMask=true},3,0,3,3);clear(3,3)
  fold(5,2,2,3,3,11,33,c.homeCabinetHeight,9,40,{1,31})
 end
 return objects,mask
end
return T
