-- Four native Celadon sales floors. Geometry roles are measured from the
-- department atlas; source cells, movement and scripts remain untouched.
local V=...
local R={}
local function cfg()return V.require('DioramaConfig').interiors.departmentSurfaces end
function R.plan(def)
 local f=tonumber((def.id or def.name or ''):match('DEPARTMENT_STORE_([2345])F$'))
 if not f or V.require('IndoorSurfaces').profile(def)~=cfg()then return nil end
 local L=def.midLayout;local objects,mask,owners,ramps={},{},{},{}
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;mask[k]=donor or 0x2c0;owners[k]=o end end
  return o
 end
 -- Baked floor shadows belong to the replaced furniture, not floating cards.
 local shadows={[0x2bd]=true,[0x2c3]=true,[0x2c4]=true,[0x2c5]=true}
 for y=5,14 do for x=0,12 do if shadows[L:midAt(x,y)]then mask[y*14+x+1]=0x2c0 end end end
 add({kind='deptRetailWall',front=32},0,0,13,2,{mid=0,void=true})
 for _,x in ipairs({1,9})do
  local down=f%2==0 and x==1 or f%2==1 and x==9
  local o=add({kind='deptStairs',front=43,left=f%2==1,down=down},x,1,3,3,down and {mid=0,void=true}or 0x281)
  ramps[#ramps+1]=o
 end
 for y=0,1 do for x=0,12 do mask[y*14+x+1]={mid=0,void=true}end end
 for _,x in ipairs({0,10})do
  add({kind='deptPartition',front=40,retail=true},x,3,3,3)
  for y=3,4 do for xx=x,x+2 do mask[y*14+xx+1]={mid=0,void=true}end end
 end
 local function fold(x,y,w,cap,split,last,h,d)
  return add({kind='deptRetailFold',cap=cap,split=split,last=last,front=last,height=h,depth=d},x,y,w,math.ceil(last/16))
 end
 local function island(x,y)
  add({kind='deptIsland',last=64,front=64},x,y,2,4)
 end
 local function glass(x,y,w,tall)
  fold(x,y,w,12,tall and 38 or 24,tall and 48 or 32,cfg().glassHeight,tall and 26 or 12)
 end
 local function counter(x,y,w,h,shape)
  return add({kind='deptSalesCounter',last=h*16,front=h*16,shape=shape},x,y,w,h)
 end
 -- Native back-wall showcases stand independently in front of the stripe.
 if f==3 then
  for _,x in ipairs({11,12})do add({kind='panel',cap=8,split=10,last=40,front=40,depth=8,height=cfg().terminalHeight,base=0,sideMid=0x2df,sideX=2,sideY=12},x,4,1,3)end
 else
  fold(10,4,3,6,13,32,cfg().wallShelfHeight,7)
 end
 if f==2 then
  counter(0,4,3,6,'leftL')
  for _,x in ipairs({7,10})do for _,y in ipairs({7,11})do island(x,y)end end
  glass(1,10,3);glass(1,12,3)
 elseif f==3 then
  for _,y in ipairs({7,10})do
   local o=counter(0,y,7,2,'bar');o.devices=true
   for _,x in ipairs({1,4})do fold(x,y+2,1,5,13,16,cfg().stoolHeight,8)end
  end
  counter(8,7,5,5,'ring')
  for _,x in ipairs({0,12})do add({kind='deptPlant',front=32},x,13,1,2)end
 elseif f==4 then
  island(1,6)
  for _,x in ipairs({5,9})do for _,y in ipairs({6,8})do glass(x,y,3)end end
  counter(0,11,8,4,'rightL')
  for _,x in ipairs({9,10})do add({kind='deptPlant',front=32},x,13,1,2)end
  add({kind='deptSofa',front=39,left=false},12,12,1,3)
 else
  counter(0,4,3,5,'leftL')
  island(1,10);island(4,10)
  for _,x in ipairs({7,10})do for _,y in ipairs({7,11})do glass(x,y,2,true)end end
  add({kind='deptPlant',front=32},0,13,1,2)
  -- This native pot's canopy is in the preceding otherwise empty tile.
  add({kind='deptPlant',front=32},12,13,1,2)
 end
 return {objects=objects,mask=mask,owners=owners,ramps=ramps}
end
local function append(out,vv)for _,v in ipairs(vv)do out[#out+1]=v end end
function R.deptRetailWall(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local h=cfg().wallHeight
 for dx=0,12 do for sy=0,31 do
  local m=L:midAt(dx,math.floor(sy/16))
  if sy>=16 and(dx>=1 and dx<=3 or dx>=9 and dx<=11)then m=0x28b end
  G.quad(out,{x+dx*16,h*(32-sy)/32,z+32},{x+(dx+1)*16,h*(32-sy)/32,z+32},
   {x+(dx+1)*16,h*(31-sy)/32,z+32},{x+dx*16,h*(31-sy)/32,z+32},G.uv(ts,m,0,sy%16,16,sy%16+1,.5),1)
 end end
end
local function strips(api,out,L,ts,o,fn)
 local source,inside=api.nativeMask(L,ts,o,o.w*16,o.last,{0x2c0,0x2c1,0x2c3,0x2c4,0x2c5,0x2bd})
 local function band(a,b,project,extra,src)
  append(out,V.require('PaperSprite').build(ts,o.w*16,o.last,src or source,function(sx,sy)return sy>=a and sy<b and inside(sx,sy)and(not extra or extra(sx,sy))end,0,o.last,1,nil,project,.5))
 end
 fn(band,source,inside)
end
function R.deptRetailFold(api,out,L,ts,o,x,z)
 strips(api,out,L,ts,o,function(band,source,inside)
  band(o.cap,o.split,function(sx,sy)return{x+sx,o.height,z+o.front-o.depth+(sy-o.cap)*o.depth/(o.split-o.cap)}end)
  band(o.split,o.last,function(sx,sy)return{x+sx,o.height*(o.last-sy)/(o.last-o.split),z+o.front}end)
  local G=V.require('WorldGeometry')
  for sy=o.cap,o.split-1 do
   local a,b
   for sx=0,o.w*16-1 do if inside(sx,sy)then a=a or sx;b=sx end end
   if a then for _,sx in ipairs({a,b+1})do
    local m,u,v=source(sx==a and a or b,sy)
    local z0=z+o.front-o.depth+(sy-o.cap)*o.depth/(o.split-o.cap)
    local z1=z0+o.depth/(o.split-o.cap)
    G.quad(out,{x+sx,o.height,z0},{x+sx,o.height,z1},{x+sx,0,z1},{x+sx,0,z0},G.uv(ts,m,u,v,u+1,v+1,.5),.9)
   end end
  end
 end)
end
function R.deptIsland(api,out,L,ts,o,x,z)
 -- Merchandise rows are stacked shelf levels in the native sprite, not
 -- two sloping roof planes. Stand the contour and close its thin shell.
 local c=cfg();local G=V.require('WorldGeometry');local h=c.islandHeight
 local source,mask=api.nativeMask(L,ts,o,32,64,{0x2c0,0x2c1,0x2c3,0x2c4,0x2c5,0x2bd})
 local function inside(sx,sy)return sy>=11 and sy<64 and mask(sx,sy)end
 append(out,V.require('PaperSprite').build(ts,32,64,source,inside,0,64,1,nil,
  function(sx,sy)return{x+sx,h*(64-sy)/53,z+64}end,.5))
 for sy=11,63 do for sx=0,31 do if inside(sx,sy)then
  local m,u,v=source(sx,sy);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
  local xx,yy=x+sx,h*(64-sy)/53;local yy1=yy-h/53;local front=z+64;local back=front-c.islandDepth
  if not inside(sx,sy-1)then G.quad(out,{xx,yy,back},{xx+1,yy,back},{xx+1,yy,front},{xx,yy,front},uv,1)end
  if not inside(sx-1,sy)then G.quad(out,{xx,yy,back},{xx,yy,front},{xx,yy1,front},{xx,yy1,back},uv,.9)end
  if not inside(sx+1,sy)then G.quad(out,{xx+1,yy,front},{xx+1,yy,back},{xx+1,yy1,back},{xx+1,yy1,front},uv,.9)end
 end end end
end
function R.deptSalesCounter(api,out,L,ts,o,x,z)
 local h=cfg().counterHeight;local w=o.w*16;local last=o.last
 strips(api,out,L,ts,o,function(band,source)
  local function topSource(sx,sy)
   if o.devices and sy<24 then return 0x2d4,sx%16,0 end
   if o.shape=='leftL'and sx>=32 and sy>=20 and sy<48 then return 0x2d4,8,0 end
   return source(sx,sy)
  end
  local function top(a,b,filter)
   band(a,b,function(sx,sy)return{x+sx,h,z+sy}end,filter,topSource)
  end
  local function front(a,b,filter)
   band(a,b,function(sx,sy)return{x+sx,h*(b-sy)/(b-a),z+a}end,filter,topSource)
  end
  if o.shape=='bar'then
   top(12,24);front(24,32)
  elseif o.shape=='leftL'then
   top(12,last-8,function(sx)return sx>=32 end)
   top(last-20,last-8,function(sx)return sx<32 end)
   front(last-8,last)
  elseif o.shape=='rightL'then
   top(12,24);front(24,32,function(sx)return sx<w-16 end)
   top(24,last-8,function(sx)return sx>=w-16 end)
   front(last-8,last,function(sx)return sx>=w-16 end)
  else
   top(12,24);front(24,32,function(sx)return sx>=16 and sx<w-16 end)
   top(24,last-20,function(sx)return sx<16 or sx>=w-16 end)
   top(last-20,last-8);front(last-8,last)
  end
  local G=V.require('WorldGeometry');local uv=G.uv(ts,0x2d4,8,10,9,11,.5)
  local sides={}
  if o.shape=='leftL'then sides={{32,12,last-20},{w,12,last-8}}
  elseif o.shape=='rightL'then sides={{w-16,24,last-8},{w,12,last-8}}
  elseif o.shape=='ring'then sides={{0,12,last-8},{16,24,last-20},{w-16,24,last-20},{w,12,last-8}}end
  for _,p in ipairs(sides)do
   G.quad(out,{x+p[1],h,z+p[2]},{x+p[1],h,z+p[3]},{x+p[1],0,z+p[3]},{x+p[1],0,z+p[2]},uv,.9)
  end
  if o.devices then
   -- Handheld demo stations stand on their white table, with original seats.
   for _,dx in ipairs({16,64})do
    local function src(sx,sy)return source(dx+sx,sy)end
    local function mask(sx,sy)
     if sy<8 or sy>=24 then return false end
     if sx>=16 then return sy>8 or sx>=18 and sx<30 end
     local lo=sy==8 and 16 or sy==9 and 3 or sy<19 and 2 or sy==19 and 1 or 0
     local hi=sy<22 and 14 or sy==22 and 9 or 8
     return sx>=lo and sx<hi
    end
    append(out,V.require('PaperSprite').build(ts,32,24,src,mask,0,24,1,nil,function(sx,sy)return{x+dx+sx,h+(24-sy)*cfg().deviceHeight/16,z+24.1}end,.5))
   end
  elseif o.shape=='leftL'then
   local src,mask=api.nativeMask(L,ts,{x=o.x,y=o.y,sourceX=32,sourceY=20},16,28,{},{{0x2d4,8,0}})
   append(out,V.require('PaperSprite').build(ts,16,28,src,mask,0,28,1,nil,function(sx,sy)return{x+32+sx,h+28-sy,z+45}end,.5))
  end
 end)
end
return R
