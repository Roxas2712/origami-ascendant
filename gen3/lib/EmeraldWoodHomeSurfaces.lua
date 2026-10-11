-- Larger/bedroom native wood-floor variants, kept separate from the two simple homes.
local V=...
local H={}
function H.plan(def,p)
 local L=def.midLayout;local c=V.require('DioramaConfig').emeraldInteriors
 local objects,mask={},{}
 local wallY=0;while L:midAt(0,wallY)==1 do wallY=wallY+1 end
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.residentialHome=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then
    mask[k]=o.kind=='wall'and{mid=p.void,void=true}or donor or(yy==wallY+2 and 0x224)or(xx==0 and p.edgeFloor)or p.floor
   end
  end end
  return o
 end
 local function clear(x,w)
  for _,o in ipairs(objects)do if o.kind=='wall'and o.x>=x and o.x<x+w then o.clean={0x205,0x20d}end end
 end
 local function fold(x,y,w,h,cap,split,last,height,depth,front,bounds,donor)
  return add({kind='fold',cap=cap,split=split,last=last,height=height,depth=depth,front=front,bounds=bounds},x,y,w,h,donor)
 end
 local width=L.width;while L:midAt(width-1,wallY)==1 do width=width-1 end
 for x=0,width-1 do add({kind='wall'},x,wallY,1,2)end
 for y=wallY,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if m==0x286 then
   fold(x,y,2,3,12,20,40,c.homeCabinetHeight,9,48,{1,31});clear(x,2)
  elseif m==0x26e then
   fold(x,y,2,3,10,16,40,c.homeCabinetHeight,9,48,{0,32});clear(x,2)
  elseif m==0x268 or m==0x269 then
   fold(x,y,1,2,1,8,24,c.homeCabinetHeight,7,32,{1,15});clear(x,1)
  elseif m==0x279 then
   fold(x,y,2,3,11,18,40,c.homeCabinetHeight,8,48,{2,23});clear(x,2)
  elseif m==0x278 then
   fold(x,y,1,3,10,18,40,36,8,48,{1,15});clear(x,1)
  elseif m==0x26c then
   fold(x,y,2,2,5,16,24,c.homeKitchenHeight,16,32,{1,31}).faucet=true;clear(x,2)
  elseif m==0x35b then
   local o=fold(x,y,1,2,3,13,31,c.glassCaseHeight,c.glassCaseDepth,32)
   o.background={{mid=p.floor}};o.positionMask=true
  elseif m==0x25a then
   add({kind='seat',cap=0,backEnd=10,seatEnd=27,last=32,backHeight=c.homeBedBackHeight,seatHeight=c.bedHeight,depth=c.homeBedDepth,front=32,background={{mid=p.floor},{mid=p.edgeFloor}},positionMask=true},x,y,2,2)
  elseif m==0x2ca then
   add({kind='seat',cap=15,backEnd=24,seatEnd=40,last=45,backHeight=c.homeBedBackHeight,seatHeight=c.bedHeight,depth=c.homeBedDepth,front=48,bounds={13,35},background={{mid=p.floor},{mid=0x224}},positionMask=true},x,y,3,3)
  elseif m==0x248 or m==0x24c or m==0x2e8 then
   local w=2;if m==0x2e8 then while L:midAt(x+w-1,y)==0x2e9 do w=w+1 end end
   local donor=m==0x248 and 0x23e or p.floor
   local o=fold(x,y,w,2,0,25,32,c.tableHeight,25,32,nil,donor)
   o.background={{mid=donor}};o.positionMask=true;o.residentialTable=true;o.cup=m==0x248 and L:midAt(x+1,y)==0x249
  elseif m==0x22b or m==0x22c or m==0x2e1 or m==0x2e2 or m==0x234 or m==0x23c then
   local donor=(m==0x2e1 or m==0x2e2)and 0x23e or p.floor
   add({kind='card',cap=0,last=16,front=16,height=c.chairHeight,background={{mid=donor}},positionMask=true},x,y,1,1,donor)
  elseif m==0x290 or m==0x291 or m==0x222 then
   add({kind='card',cap=0,last=32,front=32,height=c.homePlantHeight,background={{mid=p.floor},{mid=0x224},{mid=0x20d}},positionMask=true},x,y,1,2)
   if y<wallY+2 then clear(x,1)end
  elseif m==0x2f8 then
   add({kind='partition',height=c.partitionHeight,width=c.partitionWidth,start=32,front=96},x,y,1,6);clear(x,1)
  end
 end end
 return objects,mask
end
function H.buildPartition(out,ts,o,x,z,contacts)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').emeraldInteriors
 local x0,x1=x+1,x+1+o.width;local back,front=z+o.start,z+o.front;local h=o.height*c.heightScale
 -- Original white wall strip on top and sides, native lower trim on the end.
 local white=G.uv(ts,0x300,2,1,12,15,.5)
 G.quad(out,{x0,h,back},{x1,h,back},{x1,h,front},{x0,h,front},white,1)
 G.quad(out,{x0,0,back},{x0,h,back},{x0,h,front},{x0,0,front},white,1)
 G.quad(out,{x1,0,front},{x1,h,front},{x1,h,back},{x1,0,back},white,1)
 for i,mid in ipairs({0x308,0x310})do
  local top=h*(3-i)/2;local bottom=h*(2-i)/2
  G.quad(out,{x0,top,front},{x1,top,front},{x1,bottom,front},{x0,bottom,front},G.uv(ts,mid,1,0,13,16,.5),1)
 end
 if contacts then for zz=back+3,front,6 do contacts[#contacts+1]={(x0+x1)/2,zz,o.width/2+2,4,c.contactStrength}end end
end
return H
