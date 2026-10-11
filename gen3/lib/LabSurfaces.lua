local V=...
local M={}
function M.fold(api,out,L,ts,o,x,z)
 local W,H=o.w*16,o.last
 local cfg=V.require('DioramaConfig').interiors.labSurfaces
 local source=api.nativeMask(L,ts,o,W,H,{})
 local function inside(sx,sy)return sx>=(o.left or 0) and sx<W-(o.rightTrim or 0)
  and (not o.reception or sy<24 or sy>=60 or sx>=18) end
 local h=o.height*(cfg.heightScale or 1);local front=o.front or H;local depth=o.depth
 local function draw(first,last,project,src,predicate)
  local vv=V.require('PaperSprite').build(ts,W,H,src or source,function(sx,sy)
   return sy>=first and sy<last and (predicate or inside)(sx,sy)
  end,0,H,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local cap,split=o.cap,o.split
 local details={};local topSource=source
 local function device(sx,sy,w,hh,frontOffset,blank)
  details[#details+1]={sx=sx,sy=sy,w=w,h=hh,z=frontOffset,blank=blank}
 end
 if o.computer then device(0,-2,24,19,-7,{0x85,0,5,16,8});details[#details].shape='computer' end
 if o.workstation then device(6,3,36,21,-6,{0x2e1,0,8,16,8});details[#details].shape='workstation' end
 if o.bench then
  device(0,0,16,22,-depth+16,{0x8f,1,7,8,8});details[#details].shape='bench'
  device(16,24,16,22,-7,{0x8f,1,7,8,8});details[#details].shape='bench'
 end
 if o.looseDevice then device(32,32,16,16,-15,{0x2e1,0,8,16,8}) end
 if #details>0 then
  topSource=function(sx,sy)
   for _,d in ipairs(details)do if sx>=d.sx and sx<d.sx+d.w and sy>=d.sy and sy<d.sy+d.h then
    local b=d.blank;return b[1],b[2]+sx%b[4],b[3]+sy%b[5]
   end end
   return source(sx,sy)
  end
 end
 draw(cap,split,function(sx,sy)return {x+sx,h,z+front-depth+(sy-cap)*depth/(split-cap)}end,topSource)
 draw(split,H,function(sx,sy)return {x+sx,h*(H-sy)/(H-split),z+front}end)
 for _,d in ipairs(details)do
  local pixels={}
  local b=d.blank
  for yy=b[3],b[3]+b[5]-1 do for xx=b[2],b[2]+b[4]-1 do pixels[#pixels+1]={b[1],xx,yy}end end
  local src,visible=api.nativeMask(L,ts,{x=o.x,y=o.y,sourceX=d.sx,sourceY=d.sy},d.w,d.h,{},pixels)
  if d.shape=='computer' then visible=function(sx,sy)return sx<15 and sy>=3 or sx>=17 or sy>=7 and sx>=15 end
  elseif d.shape=='workstation' then visible=function(sx,sy)return sx>=2 and sx<18 and sy>=6 or sx>=18 and sx<34 and sy>=3 end
  elseif d.shape=='bench' then visible=function(sx,sy)return sy>=1 and sy<21 and sx>=(sy<5 and 2 or 1) and sx<15 end end
  local vv=V.require('PaperSprite').build(ts,d.w,d.h,src,visible,0,d.h,1,nil,
   function(sx,sy)return {x+d.sx+sx,h+(d.h-sy)*cfg.deviceScale,z+front+d.z}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 o.contactFront=front;o.contactWidth=W
end
return M
