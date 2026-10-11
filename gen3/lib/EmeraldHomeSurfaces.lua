-- Native BPEE wood-floor homes. Measured furniture, no floor inference from
-- collision: the original rug is restored under each lifted table/chair.
local V=...
local H={}
function H.plan(def,p)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=def.midLayout
 local objects,mask={},{}
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.woodHome=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1
   -- Rear furniture overlaps the native shaded plank row. Reconstruct that
   -- same row below it, rather than inserting a bright rectangle in the band.
   -- Explicit rugs and wall voids still own their original source regions.
   if not(type(mask[k])=='table'and mask[k].void)then
    mask[k]=donor or(yy==2 and 0x224)or(xx==0 and p.edgeFloor or p.floor)
   end
  end end
  return o
 end
 local function fold(x,y,w,h,cap,split,last,height,depth,front,donor)
  local o=add({kind='fold',cap=cap,split=split,last=last,height=height,depth=depth,front=front,background={{mid=donor or p.floor}}},x,y,w,h,donor)
  if y<=1 then o.background=nil;o.bounds={1,w*16-1}end
  return o
 end
 local function clear(x,w)
  for _,o in ipairs(objects)do if o.kind=='wall'and o.x>=x and o.x<x+w then o.clean={0x205,0x20d}end end
 end
 local width=p.family=='rugHome'and 10 or 11
 for x=0,width-1 do add({kind='wall'},x,0,1,2,{mid=1,void=true})end
 -- The TV sideboard uses its native lid and opaque case; tall storage is
 -- folded separately so the windows/wall trim do not become furniture.
 fold(0,0,2,3,12,20,40,c.homeCabinetHeight,9,48);clear(0,2)
 if p.family=='rugHome' then
  fold(2,0,2,3,11,18,40,c.homeCabinetHeight,8,48).bounds={2,23};clear(2,2)
 else
  add({kind='card',cap=13,last=40,front=48,height=30,background={{mid=0x205},{mid=0x20d},{mid=0x224},{mid=p.floor}},positionMask=true},2,0,1,3);clear(2,1)
  fold(7,1,1,2,1,8,24,c.homeCabinetHeight,7,32);clear(7,1)
  fold(8,1,2,2,5,16,24,c.homeKitchenHeight,16,32).faucet=true;clear(8,2)
  fold(10,0,1,3,10,18,40,36,8,48);clear(10,1)
 end
 local rug=p.family=='rugHome'and 0x23e or nil
 local tx=p.family=='rugHome'and 2 or 5
 local table=fold(tx,4,2,2,0,25,32,c.tableHeight,25,32,rug);table.cup=not not rug
 for _,x in ipairs(rug and{4}or{4,7})do for y=4,5 do
  add({kind='card',cap=0,last=16,front=16,height=c.chairHeight,background={{mid=rug or p.floor}}},x,y,1,1,rug)
 end end
 for y=1,L.height-1 do for x=0,L.width-1 do
  local mid=L:midAt(x,y)
  if mid==0x290 or mid==0x291 or mid==0x222 then
   add({kind='card',cap=0,last=32,front=32,height=c.homePlantHeight,
    background={{mid=p.floor},{mid=0x224},{mid=0x20d}},positionMask=true},x,y,1,2)
   if y==1 then clear(x,1)end
  end
 end end
 return objects,mask
end
return H
