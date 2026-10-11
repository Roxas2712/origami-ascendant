-- Measured native Celadon reception. No changes to map or event data.
local V=...
local D={}
local function cfg()return V.require('DioramaConfig').interiors.departmentSurfaces end
function D.plan(def)
 if V.require('IndoorSurfaces').profile(def)~=cfg()then return nil end
 if not(def.id or def.name):match('_1F$')then return V.require('InteriorDepartmentRetail').plan(def)end
 local L=def.midLayout;local objects,mask,owners,ramps={},{},{},{}
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;mask[k]=donor or 0x2c0;owners[k]=o end end
  return o
 end
 add({kind='deptWall',x=1,y=0,w=10,front=32},1,0,10,2,{mid=0,void=true})
 local stair=add({kind='deptStairs',x=2,y=1,w=3,front=43},2,1,3,3,0x281);ramps[1]=stair
 for y=0,1 do for x=1,10 do mask[y*L.width+x+1]={mid=0,void=true}end end
 for _,p in ipairs({{0,4},{10,3}})do
  add({kind='deptPartition',x=p[1],y=3,w=p[2],front=40},p[1],3,p[2],3)
  for y=3,4 do for x=p[1],p[1]+p[2]-1 do mask[y*L.width+x+1]={mid=0,void=true}end end
 end
 for _,x in ipairs({11,12})do add({kind='panel',x=x,y=4,w=1,cap=8,split=12,last=40,front=40,depth=9,height=cfg().phoneHeight,base=0,sideMid=0x2f7,sideX=2,sideY=12},x,4,1,3)end
 add({kind='deptRing',x=3,y=7,w=7,front=72},3,7,7,5,0x2da)
 for _,p in ipairs({{0,6},{0,12},{12,12}})do add({kind='deptPlant',x=p[1],y=p[2],w=1,front=32},p[1],p[2],1,2)end
 for _,x in ipairs({0,12})do add({kind='deptSofa',x=x,y=9,w=1,front=39,left=x==0},x,9,1,3)end
 return {objects=objects,mask=mask,owners=owners,ramps=ramps}
end
local function append(out,vv)for _,v in ipairs(vv)do out[#out+1]=v end end
function D.deptWall(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local h=cfg().wallHeight
 for sx=0,159,16 do for sy=0,31 do
  local m=L:midAt(o.x+math.floor(sx/16),math.floor(sy/16));local u,v=sx%16,sy%16
  if sx>=16 and sx<64 and sy>=16 then m=0x28b end
  G.quad(out,{x+sx,h*(32-sy)/32,z+32},{x+sx+16,h*(32-sy)/32,z+32},
   {x+sx+16,h*(31-sy)/32,z+32},{x+sx,h*(31-sy)/32,z+32},G.uv(ts,m,u,v,u+16,v+1,.5),1)
 end end
end
function D.deptPartition(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local h=cfg().partitionHeight
 for sy=4,39 do for dx=0,o.w-1 do
  local m=L:midAt(o.x+dx,o.y+math.floor(sy/16))
  -- Plain stripe behind the independently modelled phones.
  if o.x==10 and(dx>0 or o.retail)then m=sy<16 and 0x2a8 or sy<32 and 0x2ae or 0x2b6 end
  G.quad(out,{x+dx*16,h*(40-sy)/36,z+40},{x+(dx+1)*16,h*(40-sy)/36,z+40},
   {x+(dx+1)*16,h*(39-sy)/36,z+40},{x+dx*16,h*(39-sy)/36,z+40},G.uv(ts,m,0,sy%16,16,sy%16+1,.5),1)
 end end
end
function D.stairHeight(o,px,pz)
 local sx,sz=px-o.x*16,pz-o.y*16
 if sx<0 or sx>=48 or sz<16 or sz>43 then return nil end
 local n=math.min(7,math.floor(sx/6));local step=o.left==false and n+1 or 8-n
 return step*cfg().stairHeight/8-(o.down and cfg().stairHeight or 0)
end
function D.deptStairs(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local c=cfg()
 local tread=G.uv(ts,0x360,6,15,7,16,.5);local edge=G.uv(ts,0x360,2,4,3,5,.5);local rail=G.uv(ts,0x368,3,6,4,7,.5)
 if o.down then
  for sy=0,47 do for sx=0,47 do if sy<16 or sy>=43 then
   G.quad(out,{x+sx,0,z+sy},{x+sx+1,0,z+sy},{x+sx+1,0,z+sy+1},{x+sx,0,z+sy+1},G.uv(ts,0x281,sx%16,sy%16,sx%16+1,sy%16+1,.5),1)
  end end end
 end
 local base=o.down and -c.stairHeight or 0
 for i=0,7 do
  local h=(o.left==false and i+1 or 8-i)*c.stairHeight/8+base
  api.prism(out,ts,0,x+i*6,z+16,6,27,base,h-base,tread,edge,edge)
  G.quad(out,{x+i*6,h+.02,z+16},{x+i*6+1,h+.02,z+16},{x+i*6+1,h+.02,z+43},{x+i*6,h+.02,z+43},edge,1)
  for _,a in ipairs({16,41})do api.prism(out,ts,0,x+i*6,z+a,1,2,h,c.railHeight,rail,rail,edge)end
 end
 local ha=(o.left==false and c.stairHeight/8 or c.stairHeight)+base+c.railHeight
 local hb=(o.left==false and c.stairHeight or c.stairHeight/8)+base+c.railHeight
 for _,a in ipairs({16,41})do G.quad(out,{x,ha,z+a},{x+48,hb,z+a},{x+48,hb,z+a+2},{x,ha,z+a+2},rail,1)end
end
function D.deptRing(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local H=cfg().counterHeight
 -- The clean lower half of the carpet donor contains its native 8px
 -- repeat; its upper half is a baked shadow and must not tile into stripes.
 for sy=0,79,8 do for sx=0,111,8 do
  G.quad(out,{x+sx,.02,z+sy},{x+sx+8,.02,z+sy},{x+sx+8,.02,z+sy+8},{x+sx,.02,z+sy+8},
   G.uv(ts,0x2da,sx%16,8,sx%16+8,16,.5),1)
 end end
 api.patch(out,L,ts,o,0,0,112,11,{x,.03,z},{x+112,.03,z},{x+112,.03,z+11},{x,.03,z+11})
 local src,inside=api.nativeMask(L,ts,o,112,80,{0x2da,0x2d9})
 local function sign(sx,sy)return sx>=96 and sy>=56 and sy<74 end
 local function topSource(sx,sy)if sign(sx,sy)then return 0x2d4,8,0 end;return src(sx,sy)end
 local function band(a,b,filter,project,source)
  append(out,V.require('PaperSprite').build(ts,112,80,source or src,function(sx,sy)return sy>=a and sy<b and filter(sx,sy)and inside(sx,sy)end,0,80,1,nil,project,.5))
 end
 local function yes()return true end
 band(11,24,yes,function(sx,sy)return{x+sx,H,z+sy}end)
 band(24,32,function(sx)return sx>=16 and sx<96 end,function(sx,sy)return{x+sx,H*(32-sy)/8,z+24}end)
 band(24,59,function(sx)return sx<16 or sx>=96 end,function(sx,sy)return{x+sx,H,z+sy}end,topSource)
 band(59,72,yes,function(sx,sy)return{x+sx,H,z+sy}end,topSource)
 band(72,80,yes,function(sx,sy)return{x+sx,H*(80-sy)/8,z+72}end,topSource)
 local uv=G.uv(ts,0x2d4,8,10,9,11,.5)
 for _,sx in ipairs({1,15,96,110})do G.quad(out,{x+sx,H,z+24},{x+sx,H,z+59},{x+sx,0,z+59},{x+sx,0,z+24},uv,.9)end
 local source,mask=api.nativeMask(L,ts,{x=o.x,y=o.y,sourceX=96,sourceY=56},16,18,{},{{0x2d4,8,0},{0x2d4,8,8}})
 append(out,V.require('PaperSprite').build(ts,16,18,source,mask,0,18,1,nil,function(sx,sy)return{x+96+sx,H+18-sy,z+69}end,.5))
end
function D.deptPlant(api,out,L,ts,o,x,z)
 local src,inside=api.nativeMask(L,ts,o,16,32,{0x2c0,0x2c1})
 append(out,V.require('PaperSprite').build(ts,16,32,src,inside,0,32,1,nil,function(sx,sy)return{x+sx,(32-sy)*cfg().plantHeight/32,z+32}end,.5))
end
function D.deptSofa(api,out,L,ts,o,x,z)
 local src,inside=api.nativeMask(L,ts,o,16,40,{0x2c0,0x2c1});local c=cfg()
 append(out,V.require('PaperSprite').build(ts,16,40,src,inside,0,40,1,nil,function(sx,sy)
  local back=o.left and sx<4 or not o.left and sx>=12;local h=back and c.sofaBackHeight or c.sofaSeatHeight
  if sy>=36 then return{x+sx,h*(40-sy)/4,z+36}end
  return{x+sx,h,z+sy}
 end,.5))
 local G=V.require('WorldGeometry');local side=G.uv(ts,o.left and 0x31e or 0x31a,1,8,2,9,.5);local sx=o.left and 4 or 12
 G.quad(out,{x+sx,c.sofaBackHeight,z+2},{x+sx,c.sofaBackHeight,z+36},{x+sx,c.sofaSeatHeight,z+36},{x+sx,c.sofaSeatHeight,z+2},side,1)
end
return D
