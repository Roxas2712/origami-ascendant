-- Native Fortree treehouses and Pacifidlog raft homes, explicitly owned layouts.
local V=...
local T={}
function T.plan(def,p)
 local L=def.midLayout;local c=V.require('DioramaConfig').emeraldInteriors
 local objects,mask={},{};local tree=p.style=='tree'
 local upper,lower=tree and 0x3c9 or 0x391,tree and 0x3d1 or 0x399
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.timberHome=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then
    mask[k]=(o.kind=='wall'or o.kind=='corner')and{mid=p.void,void=true}or donor or(xx==0 and p.edgeFloor)or p.floor
   end
  end end
  return o
 end
 local function clear(x,w)
  for _,o in ipairs(objects)do if o.kind=='wall'and o.x>=x and o.x<x+w then o.clean={upper,lower}end end
 end
 local function fold(x,y,w,h,cap,split,last,height,depth,front,bounds,donor)
  return add({kind='fold',cap=cap,split=split,last=last,height=height,depth=depth,front=front,bounds=bounds},x,y,w,h,donor)
 end
 for x=1,L.width-2 do add({kind='wall'},x,0,1,2)end
 for _,x in ipairs({0,L.width-1})do add({kind='corner',right=x>0,floor=p.floor,wallHeight=32,diagonal=16},x,0,1,3)end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if tree then
   if m==0x3be and y==0 then
    add({kind='treeTrunk',height=c.treehouseTrunkHeight,depth=c.treehouseTrunkDepth,front=62},x,y,2,4);clear(x,2)
    for yy=2,3 do mask[yy*L.width+x]=p.floor;mask[yy*L.width+x+3]=p.floor end
   elseif m==0x3e0 then
    fold(x,y,1,2,1,8,24,c.homeCabinetHeight,7,32,{1,15});clear(x,1)
   elseif m==0x3e3 then
    fold(x,y,2,2,3,10,30,c.homeCabinetHeight,8,32,{1,23});clear(x,2)
   elseif m==0x3cb then
    add({kind='card',cap=13,last=40,front=48,height=30,background={{mid=upper},{mid=lower},{mid=p.floor}},positionMask=true},x,y,1,3);clear(x,1)
   end
  else
   if m==0x3a8 or m==0x3a9 then
    fold(x,y,1,2,1,8,24,c.homeCabinetHeight,7,32,{1,15});clear(x,1)
   elseif m==0x3b4 then
    fold(x,y,2,3,11,18,40,c.homeCabinetHeight,8,48,{2,23});clear(x,2)
   elseif m==0x3ba then
    fold(x,y,2,3,12,20,40,c.homeCabinetHeight,9,48,{1,31});clear(x,2)
   elseif m==0x397 then
    fold(x,y,1,3,10,18,40,36,8,48,{1,15});clear(x,1)
   elseif m==0x3b8 then
    local o=fold(x,y,2,2,5,16,24,c.homeKitchenHeight,16,32,{1,31});o.faucet=true;o.detailWallMid=lower;clear(x,2)
   elseif m==0x393 then
    add({kind='card',cap=13,last=40,front=48,height=30,background={{mid=upper},{mid=lower},{mid=p.floor}},positionMask=true},x,y,1,3);clear(x,1)
   elseif m==0x3aa then
    local o=fold(x,y,2,2,0,25,32,c.tableHeight,25,32,nil,0x39d);o.background={{mid=0x39d}};o.positionMask=true;o.timberTable=true
   elseif m==0x3ae or m==0x3af then
    add({kind='card',cap=0,last=16,front=16,height=c.chairHeight,background={{mid=0x39d}},positionMask=true},x,y,1,1,0x39d)
   elseif m==0x3b7 then
    add({kind='card',cap=0,last=16,front=16,height=c.raftBasketHeight,background={{mid=p.floor},{mid=p.edgeFloor}},positionMask=true},x,y,1,1)
   end
  end
 end end
 return objects,mask
end
function T.buildTrunk(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local h=o.height*V.require('DioramaConfig').emeraldInteriors.heightScale
 local function arc(sx)return o.depth*.5*math.sqrt(math.max(0,1-((sx-16)/14)^2))end
 local center=z+o.front-o.depth*.5
 -- A curved surface must not use PaperSprite's 16px-wide planar run merging.
 -- One source-pixel-wide strip preserves the round cross section at both ends.
 for sx=2,29 do
  local front0,front1=center+arc(sx),center+arc(sx+1)
  for _,sy in ipairs({0,16,32,48})do
   local last=math.min(58,sy+16);local mid=L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16))
   G.quad(out,{x+sx,h*(58-sy)/58,front0},{x+sx+1,h*(58-sy)/58,front1},
    {x+sx+1,h*(58-last)/58,front1},{x+sx,h*(58-last)/58,front0},G.uv(ts,mid,sx%16,sy%16,sx%16+1,sy%16+last-sy,.5),1)
  end
  local mid=L:midAt(o.x+math.floor(sx/16),o.y)
  G.quad(out,{x+sx,h,center-arc(sx)},{x+sx+1,h,center-arc(sx+1)},
   {x+sx+1,h,front1},{x+sx,h,front0},G.uv(ts,mid,sx%16,0,sx%16+1,16,.5),1)
 end
end
return T
