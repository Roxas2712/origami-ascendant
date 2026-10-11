-- Measured Pewter museum surfaces. Exhibits retain their native artwork;
-- geometry and floor masks never change maps, events or stair warps.
local V=...
local M={}
function M.plan(def)
 local c=V.require('DioramaConfig').interiors.museumSurfaces
 local profile=c.rooms[def.id or def.name]
 if not profile or V.require('IndoorSurfaces').profile(def)~=profile then return nil end
 local L=def.midLayout;local upstairs=(def.id or def.name):match('2F$')
 local objects,mask,owners={},{},{}
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;mask[k]=donor or 0x281;owners[k]=o end end
  return o
 end
 local function fold(x,y,w,cap,split,last,height,depth)
  return add({kind='museumFold',x=x,y=y,w=w,cap=cap,split=split,last=last,front=last,
   height=height,depth=depth,background={0x281,0x282}},x,y,w,math.ceil(last/16))
 end
 local width=upstairs and 19 or 28
 for x=0,width-1 do
  add({kind='museumWall',x=x,y=0,w=1,column=L:midAt(x,0)==0x2bd,
   clear=L:midAt(x,0)==0x2a5 or L:midAt(x,0)==0x2cd or L:midAt(x,0)==0x2ce or x==15 and not upstairs},x,0,1,3,0x282)
 end
 if upstairs then
  fold(2,4,4,8,42,56,c.caseHeight,c.largeCaseDepth)
  -- Space shuttle stays a whole upright exhibit, independently of its low plinth.
  add({kind='standing',x=14,y=4,w=3,sy=0,pixelH=28,front=32,base=0,background={0x281}},14,4,3,3)

  add({kind='museumPartition',x=8,y=5,w=1,front=64,length=48},8,5,1,5)
  add({kind='museumStairs',x=9,y=7,w=3,front=44,down=true},9,7,3,3,{mid=0,void=true})
 else
  for _,y in ipairs({3,6})do fold(3,y,4,8,26,40,c.caseHeight,c.caseDepth)end
  for _,x in ipairs({17,19,24,26})do fold(x,0,2,11,13,40,c.shelfHeight,10)end
  add({kind='museumPartition',x=15,y=1,w=3,front=136,bent=true},15,1,3,9)
  add({kind='museumPartition',x=11,y=5,w=1,front=64,length=48},11,5,1,5)
  add({kind='museumStairs',x=9,y=7,w=2,front=40},9,7,2,3)
  for _,p in ipairs({{16,3},{16,5},{26,4},{26,7}})do fold(p[1],p[2],1,0,13,16,c.displayHeight,12)end
  for _,y in ipairs({3,6})do
   fold(27,y,1,20,32,48,c.deskHeight,16)
   add({kind='standing',x=27,y=y,w=1,sy=0,pixelH=20,front=29,base=c.deskHeight,background={0x281}},27,y,1,3)
  end
  fold(22,3,1,6,14,32,c.deskHeight,12).front=16
 end
 -- Remove the source's baked rectangular shadows beside moved exhibits.
 if upstairs then for y=5,7 do mask[y*L.width+7]=0x281 end
 else for _,y in ipairs({4,5,7,8})do mask[y*L.width+8]=0x281 end end
 local plants=upstairs and {{0,0,8},{18,0,8},{0,8,0},{1,8,0},{17,8,0},{18,8,0}}
  or {{0,0,8},{0,8,0},{16,8,0},{24,8,0},{25,8,0}}
 for _,p in ipairs(plants)do add({kind='museumPlant',x=p[1],y=p[2],sourceY=p[3],front=30+p[3]},p[1],p[2],1,p[3]>0 and 3 or 2, p[1]==0 and 0x282 or 0x281)end
 for y=0,1 do for x=0,width-1 do mask[y*L.width+x+1]={mid=0,void=true}end end
 return {objects=objects,mask=mask,owners=owners}
end
function M.museumWall(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').interiors.museumSurfaces
 local last=o.column and 38 or 30;local h=o.column and c.columnHeight or c.wallHeight;local front=32
 for sy=0,last-1 do
  local mid=L:midAt(o.x,math.floor(sy/16))
  if o.clear then mid=sy<16 and 0x287 or 0x28f end
  G.quad(out,{x,h*(last-sy)/last,z+front},{x+16,h*(last-sy)/last,z+front},
   {x+16,h*(last-sy-1)/last,z+front},{x,h*(last-sy-1)/last,z+front},G.uv(ts,mid,0,sy%16,16,sy%16+1,.5),1)
 end
end
function M.museumFold(api,out,L,ts,o,x,z)
 V.require('InteriorRestaurant').restaurantFold(api,out,L,ts,o,x,z)
 if o.w==4 then
  local G=V.require('WorldGeometry');local frame=G.uv(ts,0x28b,1,8,2,9,.5)
  for _,sx in ipairs({1,63})do
   G.quad(out,{x+sx,o.height,z+o.front-o.depth},{x+sx,o.height,z+o.front},
    {x+sx,0,z+o.front},{x+sx,0,z+o.front-o.depth},frame,1)
  end
 end
end
function M.museumPlant(api,out,L,ts,o,x,z)
 -- The source has the same leaf/pot contour, offset eight pixels at the wall.
 return V.require('InteriorTransit').transitPlant(api,out,L,ts,o,x,z+(o.sourceY or 0))
end
function M.museumPartition(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').interiors.museumSurfaces
 local top=G.uv(ts,0x293,8,8,9,9,.5);local side=G.uv(ts,0x28f,0,0,16,14,.5)
 if o.bent then
  for _,p in ipairs({{0,12,16,96},{16,92,16,16},{32,92,16,44}})do
   api.prism(out,ts,0,x+p[1],z+p[2],p[3],p[4],0,c.counterHeight,top,G.uv(ts,0x2ac,1,6,2,14,.5),G.uv(ts,0x2ac,1,6,2,14,.5))
  end
 else
  api.prism(out,ts,0,x,z,16,o.length,0,c.wallHeight,top,side,side)
  api.patch(out,L,ts,o,0,48,16,32,{x,c.wallHeight,z+o.length+.02},{x+16,c.wallHeight,z+o.length+.02},
   {x+16,0,z+o.length+.02},{x,0,z+o.length+.02})
 end
end
function M.museumStairs(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').interiors.museumSurfaces
 local gold=G.uv(ts,0x293,8,8,9,9,.5);local dark=G.uv(ts,0x2ba,1,8,2,9,.5)
 local rail=G.uv(ts,0x2b3,8,11,9,12,.5)
 local tread=G.uv(ts,0x2b3,8,11,9,12,.5)
 local nose=G.uv(ts,0x2b3,8,9,9,10,.5)
 local function nosing(sx,h,a,b)
  G.quad(out,{x+sx,h+.02,z+a},{x+sx+1,h+.02,z+a},{x+sx+1,h+.02,z+b},{x+sx,h+.02,z+b},nose,1)
 end
 if o.down then
  -- The room is cut away at its native floor boundary. Opaque void at
  -- floor level hides the underside of the recessed flight beyond that
  -- boundary, while the opening inside the room remains fully visible.
  local edge=L.height*16
  G.quad(out,{x-16,0,edge},{x+64,0,edge},{x+64,0,edge+128},{x-16,0,edge+128},G.uv(ts,0x281,8,8,9,9,.5),G.ROOM_VOID)
  for sy=0,47 do for sx=0,47 do if sx>=34 or sy<10 or sy>=44 then
   G.quad(out,{x+sx,0,z+sy},{x+sx+1,0,z+sy},{x+sx+1,0,z+sy+1},{x+sx,0,z+sy+1},G.uv(ts,0x281,sx%16,sy%16,sx%16+1,sy%16+1,.5),1)
  end end end
  for n=0,7 do
   api.prism(out,ts,0,x+n*4,z+14,4,26,-c.stairHeight,(n+1)*c.stairHeight/8,tread,gold,gold)
   nosing(n*4,-c.stairHeight+(n+1)*c.stairHeight/8,14,40)
  end
  for _,p in ipairs({{0,10,4,34},{4,10,30,4},{4,40,30,4}})do api.prism(out,ts,0,x+p[1],z+p[2],p[3],p[4],0,c.railHeight,rail,dark,dark)end
 else
  for n=0,7 do
   local h=(n+1)*c.stairHeight/8
   api.prism(out,ts,0,x+n*4,z+10,4,28,0,h,tread,gold,gold)
   nosing(n*4,h,10,38)
   for _,dz in ipairs({10,36})do api.prism(out,ts,0,x+n*4,z+dz,1,2,h,c.railHeight,rail,rail,dark)end
  end
  for _,dz in ipairs({10,36})do G.quad(out,{x,c.stairHeight/8+c.railHeight,z+dz},{x+32,c.stairHeight+c.railHeight,z+dz},
   {x+32,c.stairHeight+c.railHeight,z+dz+2},{x,c.stairHeight/8+c.railHeight,z+dz+2},rail,1)end
 end
end
return M
