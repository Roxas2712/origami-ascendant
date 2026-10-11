-- Measured One Island network center. Native art, independent surfaces.
local V=...;local C={}
function C.profile(d)
 local p=V.require('DioramaConfig').interiors.celioCenter;local L=d and d.midLayout
 if p.enabled and d and (d.id or d.name)=='SEVII_ONE_ISLAND_POKECENTER'
  and d.mapType==8 and d.pair=='network' and L and L.width==20 and L.height==12
  and L:midAt(12,1)==0x348 and L:midAt(14,4)==0x358
  and L:midAt(3,1)==0x2aa and L:midAt(2,8)==0x29c then return p end
end
function C.lighting(d)local p=C.profile(d);return p and p.light end
function C.actorHeight(d,x,z)
 if not C.profile(d)then return end
 local px,pz=x+8,z+16
 if px>=0 and px<32 and pz>=64 and pz<=112 then
  local c=V.require('DioramaConfig').interiors
  return (112-pz)*c.centerFurniture.escalatorRise/48*c.heightScale
 end
end
function C.plan(d)
 local p=C.profile(d);if not p then return end
 local L=d.midLayout;local objects,mask,owners={},{},{}
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=donor or 0x281 end
   owners[k]=o
  end end
  return o
 end
 for x=1,17 do
  add({kind='wall',x=x,y=0,clear=x==3 or x==4 or x==7 or x==8 or x==9 or x>=12,
   wallSource={0x284,0x28c}},x,0,1,2,{mid=0,void=true})
 end
 add({kind='wallCorner',x=0,y=0},0,0,1,3,{mid=0,void=true})
 add({kind='wallCorner',x=18,y=0,right=true,wallSource={0x2a6,0x2ae,0x2b6}},18,0,1,3,{mid=0,void=true})
 add({kind='panel',x=3,y=1,w=2,last=28,front=28,base=0,contour=true,
  background={0x281,0x284,0x28c,0x2b7}},3,1,2,2)
 add({kind='panel',x=7,y=1,w=2,cap=0,split=10,last=25,depth=12,front=30,base=11,
  sideMid=0x2ad,sideX=2,sideY=9},7,1,2,2)
 add({kind='counter',x=2,y=2,w=7},2,2,7,2)
 add({kind='panel',x=9,y=0,w=1,cap=12,split=18,last=39,depth=9,front=43,base=0,
  sideMid=0x62,sideX=1,sideY=6},9,0,1,3)
 add({kind='celioMachine',x=12,y=1,w=6,front=p.machineFront,
  contactWidth=76,contactOffset=10},12,1,6,6)
 add({kind='celioCable',x=18,y=2,w=1,front=48,noContact=true},18,2,1,3)
 add({kind='escalator',x=0,y=4,w=2},0,4,2,3)
 add({kind='roundtable',x=2,y=8,w=2},2,8,2,2)
 for y=7,9 do for x=0,18 do local m=L:midAt(x,y)
  if m==0x2f5 or m==0x2fd then add({kind='stool',x=x,y=y},x,y,1,1)end
 end end
 for _,r in ipairs({{0,9,1},{18,9,1},{8,10,3}})do
  add({kind='celioFloorEdge',x=r[1],y=r[2],w=r[3],noContact=true},r[1],r[2],r[3],1,{mid=0,void=true})
 end
 for i,cell in ipairs(L.cells)do if cell.mid==0 or cell.mid==8 then mask[i]={mid=0,void=true}end end
 return {objects=objects,mask=mask,owners=owners}
end
-- Exact native silhouette, including the metal plinth. Palette rejection
-- would erase its grey pixels because those are also used in the room floor.
function C.machineInside(x,y)
 if y<0 or y>=80 then return false end
 local edge=y==0 and 9 or y<7 and 8 or y<12 and math.max(0,22-2*y)
  or y<64 and 0 or y<71 and 1 or y-69
 return x>=edge and x<96-edge
end
function C.machinePoint(x,y)
 local p=V.require('DioramaConfig').interiors.celioCenter
 if y<=49 then return {x,p.machineHeight,p.machineFront-p.machineDepth+y*p.machineDepth/49}end
 return {x,(80-y)*p.machineHeight/31,p.machineFront}
end
function C.machine(N,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local p=V.require('DioramaConfig').interiors.celioCenter
 local function source(sx,sy)return L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16)),sx%16,sy%16 end
 local function point(sx,sy)local v=C.machinePoint(sx,sy);return {x+v[1],v[2],z+v[3]}end
 local verts=V.require('PaperSprite').build(ts,96,80,source,C.machineInside,0,80,1,nil,point,.5)
 for _,v in ipairs(verts)do out[#out+1]=v end
 -- Close the actual cap outline, not its rectangular bounding quad.
 local function side(ax,ay,bx,by,mid,u,v)
  local a,b=point(ax,ay),point(bx,by)
  G.quad(out,a,b,{b[1],0,b[3]},{a[1],0,a[3]},G.uv(ts,mid,u,v,u+1,v+1,.5),p.sideShade)
 end
 for sy=0,48 do for sx=0,95 do if C.machineInside(sx,sy)then
  local m,u,v=source(sx,sy)
  if not C.machineInside(sx-1,sy)then side(sx,sy,sx,sy+1,m,u,v)end
  if not C.machineInside(sx+1,sy)then side(sx+1,sy+1,sx+1,sy,m,u,v)end
  if not C.machineInside(sx,sy-1)then side(sx+1,sy,sx,sy,m,u,v)end
 end end end
end
function C.cable(N,out,L,ts,o,x,z)
 local p=V.require('DioramaConfig').interiors.celioCenter
 local G=V.require('WorldGeometry')
 local source,inside=N.nativeMask(L,ts,o,16,48,{0x281,0x282},{})
 local verts=V.require('PaperSprite').build(ts,16,48,source,inside,0,48,1,nil,
  function(sx,sy)return{x+sx,p.cableHeight,z+sy}end,.5)
 for _,v in ipairs(verts)do out[#out+1]=v end
 for sy=0,47 do for sx=0,15 do if inside(sx,sy)then
  local mid,u,v=source(sx,sy);local uv=G.uv(ts,mid,u,v,u+1,v+1,.5)
  local a,b,h=x+sx,z+sy,p.cableHeight
  if sx==0 or not inside(sx-1,sy)then G.quad(out,{a,h,b},{a,h,b+1},{a,0,b+1},{a,0,b},uv,p.sideShade)end
  if sx==15 or not inside(sx+1,sy)then G.quad(out,{a+1,h,b+1},{a+1,h,b},{a+1,0,b},{a+1,0,b+1},uv,p.sideShade)end
  if sy==0 or not inside(sx,sy-1)then G.quad(out,{a+1,h,b},{a,h,b},{a,0,b},{a+1,0,b},uv,p.sideShade)end
  if sy==47 or not inside(sx,sy+1)then G.quad(out,{a,h,b+1},{a+1,h,b+1},{a+1,0,b+1},{a,0,b+1},uv,p.sideShade)end
 end end end
end
-- Capture only the opaque horizontal faces of these closed native volumes.
-- Their projected bounds include empty corners and cable cutouts; an AABB
-- would incorrectly let those empty regions obstruct the ceiling lights.
function C.capture(list,o,vertices,first,last)
 if not V.require('DioramaConfig').interiors.celioCenter.shadowContours then return false end
 if o.kind~='celioMachine'and o.kind~='celioCable'then return false end
 local box=V.require('RoomShadowContours').writer(list,0,0,1)
 for i=first,last,6 do
  local h=vertices[i][2];local flat=h>.05
  local a,b,u,v=math.huge,-math.huge,math.huge,-math.huge
  for j=i,i+5 do local q=vertices[j]
   if math.abs(q[2]-h)>.00001 then flat=false end
   a=math.min(a,q[1]);b=math.max(b,q[1]);u=math.min(u,q[3]);v=math.max(v,q[3])
  end
  if flat and b>a and v>u then
   -- A cable segment tucked entirely inside the already captured wall adds
   -- no occlusion. Omit it rather than spending the finite shader budget twice.
   local enclosed=false
   if o.kind=='celioCable'then for _,q in ipairs(list)do
    if q.wall and not q.frame and q.lo[1]<=a and q.hi[1]>=b
     and q.lo[3]<=u and q.hi[3]>=v and q.lo[2]<=0 and q.hi[2]>=h then enclosed=true;break end
   end end
   if not enclosed then box(a,b,u,v,0,h,true)end
  end
 end
 return true
end
function C.floorEdge(N,out,L,ts,o,x,z)
 local BM=V.require('BuildingMesh')
 local function source(sx,sy)return L:midAt(o.x+math.floor(sx/16),o.y),sx%16,sy end
 local verts=V.require('PaperSprite').build(ts,o.w*16,16,source,function(sx,sy,m,u,v)
  local r,g,b,a=BM.pixel(ts,m,u,v);return a>.5 and(r>0 or g>0 or b>0)
 end,0,16,1,nil,function(sx,sy)return{x+sx,0,z+sy}end,.5)
 for _,v in ipairs(verts)do out[#out+1]=v end
end
return C
