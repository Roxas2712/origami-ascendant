-- Measured Cerulean bicycle shop. Each bicycle is its own upright native
-- contour; loose floor tools and the exit remain in the original ground.
local V=...
local B={}
function B.plan(def)
 local c=V.require('DioramaConfig').interiors.bikeShopSurfaces
 if V.require('IndoorSurfaces').profile(def)~=c then return nil end
 local objects,mask,owners={},{},{};local L=def.midLayout
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;mask[k]=donor or 0x29e;owners[k]=o end end
  return o
 end
 add({kind='bikeWall',x=0,y=0,w=11},0,0,11,3)
 for _,x in ipairs({1,3})do
  add({kind='panel',x=x,y=1,w=2,cap=3,split=7,last=32,front=32,height=25,depth=6,base=0,sideMid=0x2a8,sideX=1,sideY=8},x,1,2,2)
 end
 for _,p in ipairs({{1,3},{3,3},{0,4},{3,4},{1,5},{3,5},{1,7},{1,8}})do
  add({kind='bikeCutout',x=p[1],y=p[2],w=2,last=16,front=15,height=c.bikeHeight,bicycle=true,clipLeft=p[1]==0 and 8 or 0},p[1],p[2],2,1)
 end
 add({kind='plant',x=5,y=3,ground=0x29e,bg={0x28e,0x296},labPot=true},5,2,1,2)
 -- Low glass cabinet, upright register on its rear edge, checked worktop.
 add({kind='bikeFold',x=8,y=2,w=1,cap=19,split=42,last=48,front=48,height=c.counterHeight,depth=23},8,2,1,3)
 objects[#objects+1]={kind='bikeCutout',x=8,y=2,w=1,sy=3,last=19,front=25,height=16,base=c.counterHeight}
 add({kind='bikeFold',x=9,y=3,w=2,cap=13,split=26,last=32,front=32,height=c.counterHeight,depth=13},9,3,2,2)
 add({kind='bikeFold',x=10,y=5,w=1,cap=0,split=12,last=16,front=16,height=c.boxHeight,depth=12},10,5,1,1)
 for _,p in ipairs({{8,6},{9,8}})do
  add({kind='bikeCutout',x=p[1],y=p[2],w=1,last=16,front=15,height=15},p[1],p[2],1,1)
 end
 for y=0,1 do for x=0,10 do mask[y*L.width+x+1]={mid=0,void=true}end end
 return {objects=objects,mask=mask,owners=owners}
end
function B.bikeWall(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').interiors.bikeShopSurfaces
 for sx=0,175 do
  local last=(sx<7 or sx>=169)and 47 or 40
  for sy=6,last-1 do
   local xx=sx
   -- Plain neighbouring wall behind the shelves, plant and register.
   if sx>=16 and sx<80 and sy>=19 or sx>=80 and sx<96 and sy>=37 or sx>=128 and sx<144 and sy>=35 then xx=152 end
   local mid=L:midAt(math.floor(xx/16),math.floor(sy/16))
   G.quad(out,{x+sx,c.wallHeight*(last-sy)/(last-6),z+c.wallFoot},{x+sx+1,c.wallHeight*(last-sy)/(last-6),z+c.wallFoot},
    {x+sx+1,c.wallHeight*(last-sy-1)/(last-6),z+c.wallFoot},{x+sx,c.wallHeight*(last-sy-1)/(last-6),z+c.wallFoot},G.uv(ts,mid,xx%16,sy%16,xx%16+1,sy%16+1,.5),1)
  end
 end
end
local function source(L,o,sx,sy)
 return L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16)),sx%16,sy%16
end
function B.bikeCutout(api,out,L,ts,o,x,z)
 local BM=V.require('BuildingMesh')
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local bg={};for sy=0,15 do for sx=0,15 do bg[rgb(BM.pixel(ts,0x29e,sx,sy))]=true end end
 local start=o.sy or 0
 local vv=V.require('PaperSprite').build(ts,o.w*16,o.last,function(sx,sy)return source(L,o,sx,sy)end,function(sx,sy)
  if sy<start or sx<(o.clipLeft or 0)then return false end
  local m,u,v=source(L,o,sx,sy);local r,g,b,a=BM.pixel(ts,m,u,v)
  -- Only this atlas's three floor colours. Bike rims/spokes are distinct
  -- white/grey; clear the holes between wheels and frame as well.
  return a>.5 and not bg[rgb(r,g,b)]
 end,0,o.last,1,nil,function(sx,sy)return {x+sx,(o.base or 0)+(o.last-sy)*o.height/(o.last-start),z+o.front}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
end
function B.bikeFold(api,out,L,ts,o,x,z)
 local src,inside=api.nativeMask(L,ts,o,o.w*16,o.last,{0x29e})
 local function strip(a,b,project)
  local vv=V.require('PaperSprite').build(ts,o.w*16,o.last,src,function(sx,sy)return sy>=a and sy<b and inside(sx,sy)end,0,o.last,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 strip(o.cap,o.split,function(sx,sy)return {x+sx,o.height,z+o.front-o.depth+(sy-o.cap)*o.depth/(o.split-o.cap)}end)
 strip(o.split,o.last,function(sx,sy)return {x+sx,o.height*(o.last-sy)/(o.last-o.split),z+o.front}end)
end
return B
