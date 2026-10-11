-- Celadon hotel's original carpet, furniture, partitions and decorative
-- staircase. No restaurant assumptions and no map/event mutation.
local V=...
local H={}
function H.plan(def)
 local c=V.require('DioramaConfig').interiors.hotelSurfaces
 if V.require('IndoorSurfaces').profile(def)~=c then return nil end
 local L=def.midLayout;local objects,mask,owners={},{},{}
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;mask[k]=donor or 0x29e;owners[k]=o end end
  return o
 end
 for x=0,16 do if x~=9 then add({kind='hotelWall',x=x,y=0,w=1,clear=x<2},x,0,1,3)end end
 add({kind='hotelPartition',x=9,y=0,w=1,front=96},9,0,1,6)
 add({kind='hotelStairs',x=0,y=1,w=2,front=40},0,1,2,3)
 local function fold(x,y,w,cap,split,last,h,d)
  return add({kind='hotelFold',x=x,y=y,w=w,cap=cap,split=split,last=last,height=h,depth=d,front=last},x,y,w,math.ceil(last/16))
 end
 -- End at source row 94: rows 94/95 already contain carpet, not fascia.
 -- The shallow top also leaves the native receptionist visible above it.
 fold(0,4,8,13,24,30,c.counterHeight,12)
 for _,y in ipairs({3,7})do
  fold(13,y,2,0,27,32,c.tableHeight,c.tableDepth)
  for _,x in ipairs({12,15})do for yy=y,y+1 do fold(x,yy,1,0,13,16,c.stoolHeight,12)end end
 end
 add({kind='standing',x=8,y=5,w=1,sy=1,pixelH=14,front=16,background={0x29e}},8,5,1,1)
 add({kind='hotelSofa',x=0,y=6,w=1,front=46},0,6,1,3)
 -- Same native potted-plant contour as the entrance family; palette
 -- equality with carpet must not punch holes through the pot.
 for _,x in ipairs({1,7,8,16})do add({kind='transitPlant',x=x,y=8,front=30},x,8,1,2)end
 for y=0,1 do for x=0,16 do mask[y*L.width+x+1]={mid=0,void=true}end end
 return {objects=objects,mask=mask,owners=owners}
end
function H.hotelWall(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local h=V.require('DioramaConfig').interiors.hotelSurfaces.wallHeight
 for sx=0,15 do
  local last=(o.x==8 and sx>=8 or o.x==10 and sx<6 or o.x==16 and sx>=8)and 38 or 30
  for sy=6,last-1 do
   local mid=L:midAt(o.x,math.floor(sy/16));local yy=sy%16
   if o.clear then mid=sy<16 and 0x286 or 0x28e end
   G.quad(out,{x+sx,h*(last-sy)/(last-6),z+32},{x+sx+1,h*(last-sy)/(last-6),z+32},
    {x+sx+1,h*(last-sy-1)/(last-6),z+32},{x+sx,h*(last-sy-1)/(last-6),z+32},G.uv(ts,mid,sx,yy,sx+1,yy+1,.5),1)
  end
 end
end
function H.hotelPartition(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local h=V.require('DioramaConfig').interiors.hotelSurfaces.wallHeight
 local top=G.uv(ts,0x284,8,4,9,5,.5);local side=G.uv(ts,0x28e,8,0,9,16,.5)
 api.prism(out,ts,0,x,z+32,16,64,0,h,top,side,side)
 api.patch(out,L,ts,o,0,64,16,32,{x,h,z+96.02},{x+16,h,z+96.02},{x+16,0,z+96.02},{x,0,z+96.02})
end
function H.hotelFold(api,out,L,ts,o,x,z)
 local source,inside=api.nativeMask(L,ts,o,o.w*16,o.last,{0x29e})
 local function strip(a,b,project)
  local vv=V.require('PaperSprite').build(ts,o.w*16,o.last,source,function(sx,sy)return sy>=a and sy<b and inside(sx,sy)end,0,o.last,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 strip(o.cap,o.split,function(sx,sy)return {x+sx,o.height,z+o.front-o.depth+(sy-o.cap)*o.depth/(o.split-o.cap)}end)
 strip(o.split,o.last,function(sx,sy)return {x+sx,o.height*(o.last-sy)/(o.last-o.split),z+o.front}end)
end
function H.hotelStairs(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').interiors.hotelSurfaces
 local tread=G.uv(ts,0x298,2,12,3,13,.5);local rail=G.uv(ts,0x290,1,14,2,15,.5)
 local dark=G.uv(ts,0x2a0,1,4,2,5,.5)
 for n=0,7 do
  local h=(8-n)*cfg.stairHeight/8
  api.prism(out,ts,0,x+n*4,z+16,4,24,0,h,tread,dark,dark)
  api.prism(out,ts,0,x+n*4,z+38,1,2,h,cfg.railHeight,rail,rail,dark)
 end
 G.quad(out,{x,cfg.stairHeight+cfg.railHeight,z+38},{x+32,cfg.stairHeight/8+cfg.railHeight,z+38},
  {x+32,cfg.stairHeight/8+cfg.railHeight,z+40},{x,cfg.stairHeight+cfg.railHeight,z+40},rail,1)
end
function H.hotelSofa(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').interiors.hotelSurfaces
 local edge=G.uv(ts,0x2b8,13,8,14,9,.5)
 api.prism(out,ts,0,x,z+3,4,41,0,c.sofaBackHeight,edge,edge,edge)
 api.patch(out,L,ts,o,0,3,4,41,{x,c.sofaBackHeight+.01,z+3},{x+4,c.sofaBackHeight+.01,z+3},
  {x+4,c.sofaBackHeight+.01,z+44},{x,c.sofaBackHeight+.01,z+44})
 api.prism(out,ts,0,x+4,z+8,10,36,0,c.sofaSeatHeight,edge,edge,edge)
 api.patch(out,L,ts,o,4,8,10,36,{x+4,c.sofaSeatHeight+.01,z+8},{x+14,c.sofaSeatHeight+.01,z+8},
  {x+14,c.sofaSeatHeight+.01,z+44},{x+4,c.sofaSeatHeight+.01,z+44})
end
return H
