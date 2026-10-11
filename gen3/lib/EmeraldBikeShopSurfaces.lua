-- Rydel's native workshop: nine separate bicycles, display strips, low
-- counters and rear work desks. Map cells, collisions and events are read-only.
local V=...
local B={}
function B.plan(def,p)
 local L=def.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.bikeShop
 local objects,mask={},{}
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=donor or p.floor end
  end end
  return o
 end
 for x=0,11 do
  local o=add({kind='wall',wallCap=4,wallLast=32,wallHeight=32,wallBase=32},x,0,1,2,{mid=p.void,void=true})
  if x<2 or x==2 then o.clean={0x22b,0x233}end
  if x==7 or x==8 or x==10 or x==11 then o.clean={0x22b,0x233};o.keepBefore=(x==8 or x==11)and 18 or 20 end
 end
 add({kind='fold',cap=11,split=14,last=40,front=40,height=28,depth=7,bounds={0,31}},0,0,2,3)
 -- Remove bike drawings from the ground, then restore their original
 -- patterned display flooring at native pixel pitch, independently of bikes.
 add({kind='bikeDisplay',right=false,noContact=true},0,2,2,7)
 add({kind='bikeDisplay',right=true,noContact=true},10,5,2,4)
 for y=2,7 do add({kind='bikeStock',cap=9,last=24,front=24,height=c.bikeHeight,left=0,right=24},0,y,2,2)end
 for y=5,7 do add({kind='bikeStock',cap=1,last=16,front=16,height=c.bikeHeight,left=8,right=32},10,y,2,1)end
 add({kind='bikeCounter',front=44},2,1,3,4)
 add({kind='bikeRegister',cap=8,last=22,front=22,base=c.counterHeight,noContact=true},2,1,1,2)
 add({kind='fold',cap=14,split=26,last=28,front=32,height=c.gateHeight,depth=12},5,2,1,2)
 for _,x in ipairs({7,10})do add({kind='bikeDesk',cap=4,split=16,last=24,front=32,height=c.deskHeight,depth=16},x,1,2,2)end
 add({kind='bikePartition',stem=true,front=40},6,3,2,3)
 -- Stem continues behind the left partition to the back wall.
 for y=2,2 do mask[y*L.width+7]=p.floor end
 add({kind='bikePartition',stem=false,front=40},10,3,2,3)
 return objects,mask
end
local function source(L,o,sx,sy)
 return L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16)),sx%16,sy%16
end
function B.build(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.bikeShop
 local first=#out+1
 local function uv(sx,sy)local m,u,v=source(L,o,sx,sy);return G.uv(ts,m,u,v,u+1,v+1,.5)end
 local function patch(sx,sy,w,h,a,b,d,e)
  for yy=0,h-1 do for xx=0,w-1 do
   local function p(u,v)local r={};for k=1,3 do r[k]=(1-v)*((1-u)*a[k]+u*b[k])+v*((1-u)*e[k]+u*d[k])end;return r end
   G.quad(out,p(xx/w,yy/h),p((xx+1)/w,yy/h),p((xx+1)/w,(yy+1)/h),p(xx/w,(yy+1)/h),uv(sx+xx,sy+yy),1)
  end end
 end
 local function prism(xx,zz,w,d,h,tex)
  G.quad(out,{xx,h,zz},{xx+w,h,zz},{xx+w,h,zz+d},{xx,h,zz+d},tex,1)
  G.quad(out,{xx,h,zz+d},{xx+w,h,zz+d},{xx+w,0,zz+d},{xx,0,zz+d},tex,.85)
  G.quad(out,{xx,0,zz},{xx,h,zz},{xx,h,zz+d},{xx,0,zz+d},tex,.85)
  G.quad(out,{xx+w,h,zz},{xx+w,0,zz},{xx+w,0,zz+d},{xx+w,h,zz+d},tex,.9)
 end
 local function draw(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or function(sx,sy)return source(L,o,sx,sy)end,
   function(sx,sy)return sy>=a and sy<b and(not inside or inside(sx,sy))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 if o.kind=='bikeDisplay'then
  for sy=0,o.h-1 do for sx=0,31 do
   local inside=o.right and sx>=8 or not o.right and sx<24
   local mid=o.right and(sx<16 and 0x255 or 0x256)or(sx<16 and 0x20e or 0x20f)
   local tex=inside and G.uv(ts,mid,sx%16,8+sy%8,sx%16+1,9+sy%8,.5)or G.uv(ts,0x23f,sx%16,sy%16,sx%16+1,sy%16+1,.5)
   G.quad(out,{x+sx,.01,z+sy},{x+sx+1,.01,z+sy},{x+sx+1,.01,z+sy+1},{x+sx,.01,z+sy+1},tex,1)
  end end
  local rx=o.right and 5 or 25;local start=o.right and 8 or 16
  prism(x+rx,z+start,2,o.h-start,c.railHeight,G.uv(ts,0x222,10,4,11,5,.5))
 elseif o.kind=='bikeStock'then
  local BM=V.require('BuildingMesh');local bg={}
  local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
  for sy=0,15 do for sx=0,15 do bg[rgb(BM.pixel(ts,0x23f,sx,sy))]=true end end
  draw(o.cap,o.last,function(sx,sy)return{x+sx,(o.last-sy)*o.height/(o.last-o.cap),z+o.front}end,function(sx,sy)
   if sx<o.left or sx>=o.right then return false end
   local m,u,v=source(L,o,sx,sy);local r,g,b,a=BM.pixel(ts,m,u,v);return a>.5 and not bg[rgb(r,g,b)]
  end)
 elseif o.kind=='bikeCounter'then
  draw(22,44,function(sx,sy)return{x+sx,c.counterHeight,z+sy}end,function(sx,sy)return sx<16 or sy>=30 end)
  draw(44,56,function(sx,sy)return{x+sx,c.counterHeight*(56-sy)/12,z+44}end)
  local side=G.uv(ts,0x224,2,4,3,5,.5)
  G.quad(out,{x+16,c.counterHeight,z+22},{x+16,c.counterHeight,z+30},{x+16,0,z+30},{x+16,0,z+22},side,.9)
  G.quad(out,{x+48,c.counterHeight,z+30},{x+48,c.counterHeight,z+44},{x+48,0,z+44},{x+48,0,z+30},side,.9)
 elseif o.kind=='bikeRegister'then
  draw(o.cap,o.last,function(sx,sy)return{x+sx,o.base+o.last-sy,z+o.front}end)
 elseif o.kind=='bikeDesk'then
  local function device(sx,sy)return sx>=21 and sx<31 and sy>=2 and sy<18 end
  draw(4,16,function(sx,sy)return{x+sx,c.deskHeight,z+o.front-o.depth+(sy-4)*o.depth/12}end,nil,function(sx,sy)
   if device(sx,sy)then return source(L,o,19,10)end;return source(L,o,sx,sy)
  end)
  draw(16,24,function(sx,sy)return{x+sx,c.deskHeight*(24-sy)/8,z+32}end,function(sx,sy)return sx<3 or sx>=29 or sy<19 end,function(sx,sy)
   if device(sx,sy)then return source(L,o,19,sy)end;return source(L,o,sx,sy)
  end)
  draw(2,18,function(sx,sy)return{x+sx,c.deskHeight+18-sy,z+26}end,device)
 elseif o.kind=='bikePartition'then
  local h=c.partitionHeight;local edge=G.uv(ts,0x240,8,1,9,2,.5)
  if o.stem then prism(x+1,32,5,z+40-32,h,edge)end
  prism(x,z+35,32,5,h,edge)
  patch(0,12,32,28,{x,h,z+40.02},{x+32,h,z+40.02},{x+32,0,z+40.02},{x,0,z+40.02})
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return B
