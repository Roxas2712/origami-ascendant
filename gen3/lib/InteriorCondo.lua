-- Source-measured Celadon condominium interiors. The extracted f8c atlas
-- is authoritative; the original maps, events and stairs remain untouched.
local V=...
local C={}
function C.plan(def)
 local c=V.require('DioramaConfig').interiors.condoSurfaces
 if V.require('IndoorSurfaces').profile(def)~=c then return nil end
 local L=def.midLayout;local floor=tonumber((def.id or def.name):match('_(%d)F$'))
 local objects,mask,owners,ramps={},{},{},{}
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;mask[k]=donor or 0x281;owners[k]=o end end
  return o
 end
 for _,row in ipairs({{0,0,7},{9,0,6},{0,5,7},{0,15,9}})do
  for x=row[1],row[1]+row[3]-1 do
   local y=row[2]
   local clear=(y==0 and (L:midAt(x,1)==0x300 or L:midAt(x,1)==0x301 or L:midAt(x,1)==0x305 or L:midAt(x,1)==0x2a4 or L:midAt(x,1)==0x2ae or L:midAt(x,1)==0x2af))
    or y==5 and (floor==1 and (x==0 or x==2 or x==4)or floor==2 and x~=4 or floor==3 and x<4)
    or y==15 and (x==0 or floor~=1 and x>=4 and x<=6 or floor==1 and x>=2 and x<=3)
   add({kind='condoWall',x=x,y=y,w=1,clear=clear,front=32},x,y,1,2)
   for yy=y,y+1 do mask[yy*L.width+x+1]={mid=0,void=true}end
  end
 end
 -- The native black strips are the cutaway behind the room walls.
 for _,y in ipairs({4,14})do for x=0,(y==4 and 7 or 8)do mask[y*L.width+x+1]={mid=0,void=true}end end
 add({kind='condoPartition',x=7,y=0,w=2,front=208},7,0,2,13,{mid=0,void=true})
 local function stairs(x,down,left)
  local stair=add({kind='condoStairs',x=x,y=1,w=3,front=48,down=down,left=left},x,1,3,3,down and {mid=0,void=true} or 0x281)
  ramps[#ramps+1]=stair
  -- Mask only the actual aperture; stair builder restores its perimeter.
 end
 if floor==1 then stairs(4,false,false);stairs(12,false,false)
 elseif floor==2 then stairs(0,false,true);stairs(4,true,true);stairs(9,false,true);stairs(12,true,true)
 else stairs(0,true,false);stairs(4,false,false);stairs(9,true,false);stairs(12,false,false)end
 local function fold(x,y,w,cap,split,last,h,d)
  return add({kind='condoFold',x=x,y=y,w=w,cap=cap,split=split,last=last,front=last,height=h,depth=d,background={0x281,0x282}},x,y,w,math.ceil(last/16))
 end
 if floor<3 then
  local y=floor==1 and 9 or 8
  local o=fold(1,y,4,10,54,64,c.tableHeight,c.tableDepth);o.cups=floor==1 and {18,34}or{34}
  for yy=y+1,y+4 do mask[yy*L.width+6]=0x281 end -- baked shadow, not furniture
  if floor==1 then for _,x in ipairs({1,4})do fold(x,13,1,0,8,16,c.stoolHeight,9)end end
 else
  for _,p in ipairs({{0,8},{4,8},{0,11}})do local o=fold(p[1],p[2],3,12,38,46,c.deskHeight,c.deskDepth);o.computer=true end
  fold(3,12,1,0,13,16,c.stoolHeight,12)
  fold(3,13,1,0,13,16,c.stoolHeight,12)
 end
 if floor>=2 then
  for _,p in ipairs(floor==2 and {{1,6,4},{4,16,3}}or{{4,16,3}})do add({kind='condoSofa',x=p[1],y=p[2],w=p[3],front=32},p[1],p[2],p[3],2)end
  if floor==2 then add({kind='condoSideSofa',x=6,y=9,w=1,front=48},6,9,1,3)end
  for _,p in ipairs(floor==2 and {{5,5}}or{{0,5},{2,5}})do
   add({kind='panel',x=p[1],y=p[2],w=2,cap=9,split=11,last=38,front=40,depth=8,height=c.shelfHeight,
    base=0,sideMid=0x2f5,sideX=1,sideY=8},p[1],p[2],2,3)
  end
 else
  add({kind='panel',x=2,y=15,w=2,cap=12,split=14,last=40,front=40,depth=5,height=c.shelfHeight,
   base=0,sideMid=0x2c2,sideX=1,sideY=8},2,15,2,3)
 end
 -- Native potted plants: opaque leaves/pots on the floor, not wall texture.
 local plants={{0,16},{9,5},{14,5},{9,8},{14,8},{9,11},{14,11},{14,14}}
 if floor==1 then for _,x in ipairs({0,2,4})do plants[#plants+1]={x,6}end
 else plants[#plants+1]={0,6};plants[#plants+1]={14,17}end
 for _,p in ipairs(plants)do add({kind='transitPlant',x=p[1],y=p[2],front=30},p[1],p[2],1,2)end
 -- Shelves/plants share source rows with the wall. Their restoration masks
 -- must not put a strip of floor behind that upright wall.
 for _,row in ipairs({{0,0,7},{9,0,6},{0,5,7},{0,15,9}})do
  for y=row[2],row[2]+1 do for x=row[1],row[1]+row[3]-1 do mask[y*L.width+x+1]={mid=0,void=true}end end
 end
 return {objects=objects,mask=mask,owners=owners,ramps=ramps}
end
function C.condoWall(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').interiors.condoSurfaces
 -- Exclude the floor margin. Plain wall donors remove source plants/sofas
 -- only where those are reconstructed independently in front of the wall.
 for sy=0,30 do
  local mid=L:midAt(o.x,o.y+math.floor(sy/16))
  if o.clear then mid=sy<16 and 0x289 or 0x291 end
  G.quad(out,{x,c.wallHeight*(31-sy)/31,z+32},{x+16,c.wallHeight*(31-sy)/31,z+32},
   {x+16,c.wallHeight*(30-sy)/31,z+32},{x,c.wallHeight*(30-sy)/31,z+32},G.uv(ts,mid,0,sy%16,16,sy%16+1,.5),1)
 end
end
function C.condoPartition(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local h=V.require('DioramaConfig').interiors.condoSurfaces.wallHeight
 local top=G.uv(ts,0x28c,2,2,3,3,.5);local side=G.uv(ts,0x291,0,0,1,16,.5)
 local rim=V.require('DioramaConfig').interiors.condoSurfaces.partitionRim
 for _,sx in ipairs({0,32-rim})do api.prism(out,ts,0,x+sx,z+32,rim,160,0,h,top,side,side)end
 api.prism(out,ts,0,x,z+192,32,16,0,h,top,side,side)
 api.patch(out,L,ts,o,0,176,32,32,{x,h,z+208.02},{x+32,h,z+208.02},{x+32,0,z+208.02},{x,0,z+208.02})
end
local function append(out,vv)for _,v in ipairs(vv)do out[#out+1]=v end end
function C.condoFold(api,out,L,ts,o,x,z)
 local W=o.w*16;local source,inside=api.nativeMask(L,ts,o,W,o.last,o.background)
 local details={}
 for _,sx in ipairs(o.cups or{})do details[#details+1]={x=sx,y=16,w=12,h=12,blank={0x2d6,8,8},front=o.front-o.depth+16}end
 if o.computer then details[1]={x=8,y=0,w=24,h=22,blank={0x29d,2,0},striped=true,front=o.front-o.depth+10}end
 local function covers(d,sx,sy)return sx>=d.x and sx<d.x+d.w and sy>=d.y and sy<d.y+d.h end
 local function topSource(sx,sy)
  for _,d in ipairs(details)do if covers(d,sx,sy)then return d.blank[1],d.blank[2],d.striped and sy%16 or d.blank[3]end end
  return source(sx,sy)
 end
 local function strip(a,b,project,src)
  append(out,V.require('PaperSprite').build(ts,W,o.last,src or source,function(sx,sy)return sy>=a and sy<b and inside(sx,sy)end,0,o.last,1,nil,project,.5))
 end
 strip(o.cap,o.split,function(sx,sy)return {x+sx,o.height,z+o.front-o.depth+(sy-o.cap)*o.depth/(o.split-o.cap)}end,topSource)
 strip(o.split,o.last,function(sx,sy)return {x+sx,o.height*(o.last-sy)/(o.last-o.split),z+o.front}end)
 for _,d in ipairs(details)do
  local src,mask=api.nativeMask(L,ts,{x=o.x,y=o.y,sourceX=d.x,sourceY=d.y},d.w,d.h,{0x281,0x282},{{d.blank[1],d.blank[2],d.blank[3]}})
  append(out,V.require('PaperSprite').build(ts,d.w,d.h,src,mask,0,d.h,1,nil,function(sx,sy)return {x+d.x+sx,o.height+d.h-sy,z+d.front}end,.5))
 end
end
function C.condoSofa(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.condoSurfaces
 local source,inside=api.nativeMask(L,ts,o,o.w*16,32,{0x281,0x282})
 local function strip(a,b,project)
  append(out,V.require('PaperSprite').build(ts,o.w*16,32,source,function(sx,sy)return sy>=a and sy<b and inside(sx,sy)end,0,32,1,nil,project,.5))
 end
 strip(0,16,function(sx,sy)return {x+sx,c.sofaSeatHeight+(16-sy)*(c.sofaBackHeight-c.sofaSeatHeight)/16,z+12}end)
 strip(16,26,function(sx,sy)return {x+sx,c.sofaSeatHeight,z+12+(sy-16)*1.6}end)
 strip(26,32,function(sx,sy)return {x+sx,c.sofaSeatHeight*(32-sy)/6,z+28}end)
end
function C.condoSideSofa(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.condoSurfaces;local G=V.require('WorldGeometry')
 local edge=G.uv(ts,0x2cb,10,8,11,9,.5)
 api.prism(out,ts,0,x+12,z+2,4,44,0,c.sofaBackHeight,edge,edge,edge)
 api.patch(out,L,ts,o,12,2,4,44,{x+12,c.sofaBackHeight,z+2},{x+16,c.sofaBackHeight,z+2},{x+16,c.sofaBackHeight,z+46},{x+12,c.sofaBackHeight,z+46})
 api.prism(out,ts,0,x+2,z+5,10,38,0,c.sofaSeatHeight,edge,edge,edge)
 api.patch(out,L,ts,o,2,5,10,38,{x+2,c.sofaSeatHeight+.01,z+5},{x+12,c.sofaSeatHeight+.01,z+5},{x+12,c.sofaSeatHeight+.01,z+43},{x+2,c.sofaSeatHeight+.01,z+43})
end
function C.stairHeight(o,px,pz)
 local dx,dz=px-o.x*16,pz-o.y*16
 if dx<3 or dx>=47 or dz<18 or dz>44 then return nil end
 local n=math.min(7,math.floor((dx-3)/5.5))
 local step=o.left and 8-n or n+1
 local height=V.require('DioramaConfig').interiors.condoSurfaces.stairHeight
 return step*height/8-(o.down and height or 0)
end
function C.condoStairs(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').interiors.condoSurfaces
 local tread=G.uv(ts,0x2b6,9,8,10,9,.5);local rail=G.uv(ts,0x2be,8,0,9,1,.5)
 local riser=G.uv(ts,0x2bf,8,12,9,13,.5);local dark=G.uv(ts,0x2ac,8,7,9,8,.5)
 local a,b=18,44
 if o.down then
  -- Hide the underground flight through the non-playable cutaway behind
  -- the next room's wall. This depth surface never crosses a walkable cell.
  if o.x<7 then G.quad(out,{0,0,64},{112,0,64},{112,0,112},{0,0,112},G.uv(ts,0x281,8,8,9,9,.5),G.ROOM_VOID)end
  -- Only the shaft is open; retain complete floor around its footprint.
  for sy=0,47 do for sx=0,47 do if sx<3 or sx>=47 or sy<a or sy>=b then
   G.quad(out,{x+sx,0,z+sy},{x+sx+1,0,z+sy},{x+sx+1,0,z+sy+1},{x+sx,0,z+sy+1},G.uv(ts,0x281,sx%16,sy%16,sx%16+1,sy%16+1,.5),1)
  end end end
 end
 for n=0,7 do
  local step=o.left and 8-n or n+1
  local h=step*c.stairHeight/8-(o.down and c.stairHeight or 0)
  local base=o.down and -c.stairHeight or 0;local sx=3+n*5.5
  api.prism(out,ts,0,x+sx,z+a,5.5,b-a,base,h-base,tread,riser,dark)
  local edge=sx+(o.left and 4.8 or 0)
  G.quad(out,{x+edge,h+.02,z+a},{x+edge+.7,h+.02,z+a},{x+edge+.7,h+.02,z+b},{x+edge,h+.02,z+b},riser,1)
  for _,dz in ipairs({a,b-2})do api.prism(out,ts,0,x+sx,z+dz,1,2,h,c.railHeight,rail,rail,dark)end
 end
 if o.down then
  for _,p in ipairs({{0,a-3,3,b-a+6},{3,a-3,44,3},{3,b,44,3}})do api.prism(out,ts,0,x+p[1],z+p[2],p[3],p[4],0,c.railHeight,rail,dark,dark)end
 else
  for _,dz in ipairs({a,b-2})do
   local ha=o.left and c.stairHeight or c.stairHeight/8;local hb=o.left and c.stairHeight/8 or c.stairHeight
   G.quad(out,{x+3,ha+c.railHeight,z+dz},{x+47,hb+c.railHeight,z+dz},{x+47,hb+c.railHeight,z+dz+2},{x+3,ha+c.railHeight,z+dz+2},rail,1)
  end
 end
end
return C
