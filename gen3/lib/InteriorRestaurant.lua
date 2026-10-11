-- Celadon restaurant: source-measured native tops, faces and small details.
-- Kitchen and dining floor donors remain separate; no native cells change.
local V=...
local R={}
function R.plan(def)
 local c=V.require('DioramaConfig').interiors.restaurantSurfaces
 if V.require('IndoorSurfaces').profile(def)~=c then return nil end
 local L=def.midLayout;local objects,mask,owners={},{},{}
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;mask[k]=donor or 0x2d4;owners[k]=o end end
  return o
 end
 for x=0,14 do add({kind='restaurantWall',x=x,y=0,w=1,clear=x>=10 and x<=13},x,0,1,3,x>=11 and 0x2cf or 0x2d4)end
 for _,y in ipairs({3,7})do
  add({kind='restaurantFold',x=1,y=y,w=2,cap=0,split=25,last=32,front=32,height=c.tableHeight,depth=c.tableDepth,
   cup=y==3,background={0x2d4}},1,y,2,2)
 end
 for _,y in ipairs({2,6})do for _,x in ipairs({1,2})do add({kind='restaurantChair',x=x,y=y,w=1,front=16},x,y,1,1)end end
 for y=2,6 do add({kind='standing',x=9,y=y,w=1,sy=0,pixelH=16,front=16,background={0x2d4}},9,y,1,1)end
 for _,y in ipairs({3,4,7,8})do add({kind='standing',x=3,y=y,w=1,sy=0,pixelH=16,front=16,background={0x2d4}},3,y,1,1)end
 local counter={kind='restaurantCounter',x=10,y=1,w=5,front=119};add(counter,10,1,1,8)
 for y=7,8 do for x=11,14 do local k=y*L.width+x+1;mask[k]=0x2d4;owners[k]=counter end end
 add({kind='restaurantFold',x=11,y=1,w=2,cap=11,split=25,last=32,front=32,height=c.sinkHeight,depth=14,faucet=true,
  background={0x2cf}},11,1,2,2,0x2cf)
 add({kind='restaurantFold',x=13,y=1,w=2,cap=4,split=6,last=32,front=32,height=c.cabinetHeight,depth=10,
  left=1,right=25},13,1,2,2,0x2cf)
 for y=0,1 do for x=0,14 do mask[y*L.width+x+1]={mid=0,void=true}end end
 return {objects=objects,mask=mask,owners=owners}
end
function R.restaurantWall(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local h=V.require('DioramaConfig').interiors.restaurantSurfaces.wallHeight
 for sx=0,15 do
  local last=(o.x==0 and sx<6 or o.x==14 and sx>=10)and 38 or 31
  for sy=6,last-1 do
   local mid=L:midAt(o.x,math.floor(sy/16));local yy=sy%16
   if o.clear and sy>=24 then mid=0x2bd;yy=sy%16 end
   G.quad(out,{x+sx,h*(last-sy)/(last-6),z+32},{x+sx+1,h*(last-sy)/(last-6),z+32},
    {x+sx+1,h*(last-sy-1)/(last-6),z+32},{x+sx,h*(last-sy-1)/(last-6),z+32},G.uv(ts,mid,sx,yy,sx+1,yy+1,.5),1)
  end
 end
end
local function append(out,vv)for _,v in ipairs(vv)do out[#out+1]=v end end
function R.restaurantFold(api,out,L,ts,o,x,z)
 local W=o.w*16;local source,visible=api.nativeMask(L,ts,o,W,o.last,o.background or {})
 local function inside(sx,sy)return sx>=(o.left or 0)and sx<(o.right or W)and visible(sx,sy)end
 local details={}
 if o.cup then details[1]={x=4,y=3,w=10,h=11,offset=-17,blank={0x2ba,8,12},
  spans={{8,12},{7,13},{6,14},{5,14},{4,14},{4,14},{4,14},{5,14},{6,14},{7,14},{8,13}}}end
 if o.faucet then details[1]={x=8,y=8,w=7,h=10,offset=-9,blank={0x2ca,2,12}}end
 local function detailInside(d,sx,sy)
  if sx<d.x or sx>=d.x+d.w or sy<d.y or sy>=d.y+d.h then return false end
  local span=d.spans and d.spans[sy-d.y+1]
  return not span or sx>=span[1] and sx<span[2]
 end
 local function topSource(sx,sy)
  for _,d in ipairs(details)do if detailInside(d,sx,sy) then return d.blank[1],d.blank[2],d.blank[3]end end
  return source(sx,sy)
 end
 local function strip(a,b,project,src)
  append(out,V.require('PaperSprite').build(ts,W,o.last,src or source,function(sx,sy)return sy>=a and sy<b and inside(sx,sy)end,0,o.last,1,nil,project,.5))
 end
 strip(o.cap,o.split,function(sx,sy)return {x+sx,o.height,z+o.front-o.depth+(sy-o.cap)*o.depth/(o.split-o.cap)}end,topSource)
 strip(o.split,o.last,function(sx,sy)return {x+sx,o.height*(o.last-sy)/(o.last-o.split),z+o.front}end)
 for _,d in ipairs(details)do
  local src,mask=api.nativeMask(L,ts,{x=o.x,y=o.y,sourceX=d.x,sourceY=d.y},d.w,d.h,{},{{d.blank[1],d.blank[2],d.blank[3]}})
  local function cut(sx,sy)return d.spans and detailInside(d,sx+d.x,sy+d.y) or not d.spans and mask(sx,sy)end
  append(out,V.require('PaperSprite').build(ts,d.w,d.h,src,cut,0,d.h,1,nil,
   function(sx,sy)return {x+d.x+sx,o.height+d.h-sy,z+o.front+d.offset}end,.5))
 end
end
function R.restaurantCounter(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local h=V.require('DioramaConfig').interiors.restaurantSurfaces.counterHeight
 local blue=G.uv(ts,0x2e0,8,8,9,9,.5);local edge=G.uv(ts,0x2e2,1,7,2,16,.5)
 api.prism(out,ts,0,x,z+8,16,111,0,h,blue,edge,edge)
 api.prism(out,ts,0,x+16,z+108,64,11,0,h,blue,edge,edge)
 local function source(sx,sy)return L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16)),sx%16,sy%16 end
 append(out,V.require('PaperSprite').build(ts,80,128,source,function(sx,sy)
  return sy>=8 and sy<119 and (sx<16 or sy>=108)
 end,0,128,1,nil,function(sx,sy)return {x+sx,h+.02,z+sy}end,.5))
 api.patch(out,L,ts,o,0,119,80,9,{x,h,z+119.02},{x+80,h,z+119.02},{x+80,0,z+119.02},{x,0,z+119.02})
end
function R.restaurantChair(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.restaurantSurfaces
 local source,mask=api.nativeMask(L,ts,o,16,16,{0x2d4})
 local function strip(a,b,project)
  append(out,V.require('PaperSprite').build(ts,16,16,source,function(sx,sy)return sy>=a and sy<b and mask(sx,sy)end,0,16,1,nil,project,.5))
 end
 strip(0,7,function(sx,sy)return {x+sx,c.chairSeatHeight+(7-sy)*(c.chairBackHeight-c.chairSeatHeight)/7,z+5}end)
 strip(7,13,function(sx,sy)return {x+sx,c.chairSeatHeight,z+5+(sy-7)*10/6}end)
 strip(13,16,function(sx,sy)return {x+sx,c.chairSeatHeight*(16-sy)/3,z+15}end)
end
return R
