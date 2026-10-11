-- Native FR school / Celadon rooftop study. Wall drawings end at different
-- source rows; those floor margins never belong to an upright wall or shelf.
local V=...
local S={}
function S.plan(def)
 local cfg=V.require('DioramaConfig').interiors.schoolSurfaces
 if V.require('IndoorSurfaces').profile(def)~=cfg then return nil end
 local L=def.midLayout;local objects,mask,owners={},{},{}
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1;mask[k]=donor or (xx==0 and 0x29d or 0x29e);owners[k]=o
  end end
  return o
 end
 add({kind='schoolWall',x=0,y=0,w=10},0,0,10,3)
 for y=0,1 do for x=0,9 do mask[y*10+x+1]={mid=0,void=true} end end
 -- Complete native shelf: top, front and narrow edge. Its floor margin
 -- at row 43 is excluded, even though it shares the shelf's grey palette.
 add({kind='panel',x=8,y=1,w=2,cap=3,split=5,last=30,depth=8,front=32,
  height=25,base=0,sideMid=0x2a3,sideX=1,sideY=8},8,1,2,2)
 local function fold(x,y,w,cap,split,last,height,depth)
  return add({kind='schoolFold',x=x,y=y,w=w,cap=cap,split=split,last=last,
   height=height,depth=depth,front=last},x,y,w,math.ceil(last/16))
 end
 fold(4,3,2,13,25,32,cfg.deskHeight,cfg.deskDepth)
 for _,x in ipairs({4,5})do fold(x,5,1,8,14,20,cfg.stoolHeight,cfg.stoolDepth)end
 if L:midAt(7,3)==0x2ac then fold(7,3,1,4,16,24,cfg.deskHeight,cfg.stoolDepth+3)end
 for _,x in ipairs({0,9})do
  add({kind='plant',x=x,y=7,ground=0x29e,bg={0x29d}},x,6,1,2)
 end
 return {objects=objects,mask=mask,owners=owners}
end
function S.schoolWall(api,out,L,ts,o,x,z)
 local cfg=V.require('DioramaConfig').interiors.schoolSurfaces
 local G=V.require('WorldGeometry')
 for sx=0,159 do
  local last=(sx<8 or sx>=56 and sx<104)and 38 or 30
  for sy=7,last-1 do
   local mx,my=sx,sy
   -- Original plain wall under the far-right shelf, sampled from the
   -- neighbouring window's lower wall, never from its book/white front.
   if sx>=128 and sy>=19 then mx=50 end
   local mid=L:midAt(math.floor(mx/16),math.floor(my/16))
   local a=cfg.wallHeight*(last-sy)/(last-7)
   local b=cfg.wallHeight*(last-sy-1)/(last-7)
   G.quad(out,{x+sx,a,z+cfg.wallFoot},{x+sx+1,a,z+cfg.wallFoot},
    {x+sx+1,b,z+cfg.wallFoot},{x+sx,b,z+cfg.wallFoot},G.uv(ts,mid,mx%16,my%16,mx%16+1,my%16+1,.5),1)
  end
 end
end
function S.schoolFold(api,out,L,ts,o,x,z)
 local source,inside=api.nativeMask(L,ts,o,o.w*16,o.last,{0x29e})
 local function strip(a,b,project)
  local vv=V.require('PaperSprite').build(ts,o.w*16,o.last,source,function(sx,sy)
   return sy>=a and sy<b and inside(sx,sy)
  end,0,o.last,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 strip(o.cap,o.split,function(sx,sy)return {x+sx,o.height,z+o.front-o.depth+(sy-o.cap)*o.depth/(o.split-o.cap)}end)
 strip(o.split,o.last,function(sx,sy)return {x+sx,o.height*(o.last-sy)/(o.last-o.split),z+o.front}end)
end
return S
