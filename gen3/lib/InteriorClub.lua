-- Original Fan Club / day-care art: rugs remain on the floor, furniture
-- has separate native tops and fronts. No source map or event edits.
local V=...
local C={}
function C.plan(def)
 local c=V.require('DioramaConfig').interiors.clubSurfaces
 local profile=c.rooms[def.id or def.name]
 if not profile or V.require('IndoorSurfaces').profile(def)~=profile then return nil end
 local club=(def.id or def.name)=='FR_VERMILION_CITY_POKEMON_FAN_CLUB'
 local L=def.midLayout;local objects,mask,owners={},{},{}
 local floor=club and 0x288 or 0x287
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;mask[k]=donor or floor;owners[k]=o end end
  return o
 end
 add({kind='clubWall',x=0,y=0,w=12,club=club},0,0,12,2,{mid=0,void=true})
 local function fold(x,y,w,cap,split,last,h,d,bg)
  add({kind='clubFold',x=x,y=y,w=w,cap=cap,split=split,last=last,height=h,depth=d,front=last,background={bg or floor}},x,y,w,math.ceil(last/16),bg)
 end
 if club then
  for _,x in ipairs({4,6})do
   add({kind='panel',x=x,y=0,w=2,cap=11,split=13,last=40,height=27,depth=6,front=40,base=0,sideMid=0x2a8,sideX=1,sideY=3},x,0,2,3)
  end
  fold(5,5,2,0,27,32,c.tableHeight,c.tableDepth,0x2a3)
  add({kind='clubSeat',x=5,y=3,w=2,last=32,front=32},5,3,2,2,0x2a3)
  for x=5,6 do mask[3*12+x+1]=0x29b end -- preserve rug's upper border beneath the chair
  for _,x in ipairs({4,7})do add({kind='clubSeat',x=x,y=5,w=1,last=32,front=32,side=true,right=x==7},x,5,1,2,0x2a3)end
  for _,x in ipairs({0,11})do
   for _,y in ipairs({3,9})do add({kind='plant',x=x,y=y+1,ground=floor,trim=0},x,y,1,2)end
   for _,y in ipairs({5,7})do fold(x,y,1,1,26,31,c.planterHeight,25)end
  end
 else
  fold(7,4,2,0,27,32,c.tableHeight,c.tableDepth,0x2a3)
  for _,x in ipairs({6,9})do for y=4,5 do fold(x,y,1,3,13,16,c.stoolHeight,10,0x2a3)end end
  for _,p in ipairs({{0,4},{0,6},{11,6}})do fold(p[1],p[2],1,1,26,31,c.planterHeight,25)end
  add({kind='clubPC',x=10,y=0,w=1,last=40,front=40},10,0,1,3)
  -- The enclosure's green floor is independent of its two low rails.
  local pen=add({kind='clubPen',x=0,y=1,w=5,front=46},4,1,1,3)
  for x=0,3 do local k=3*L.width+x+1;mask[k]=0x2ee;owners[k]=pen end
 end
 -- No raised wall-floor strips. Keep original rug borders and exits.
 for y=0,1 do for x=0,11 do mask[y*12+x+1]={mid=0,void=true}end end
 mask[2*12+1]=club and floor or 0x2ee;mask[2*12+12]=floor
 return {objects=objects,mask=mask,owners=owners}
end
function C.clubWall(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local h=V.require('DioramaConfig').interiors.clubSurfaces.wallHeight
 for sx=0,191 do
  local last=(sx<7 or sx>=185)and 38 or 30
  for sy=1,last-1 do
   local xx=sx
   if o.club and sx>=64 and sx<128 and sy>=11 then xx=52 end
   if not o.club and (sx>=160 and sx<176 and sy>=8 or sx>=64 and sx<80 and sy>=26)then xx=88 end
   local mid=L:midAt(math.floor(xx/16),math.floor(sy/16))
   G.quad(out,{x+sx,h*(last-sy)/(last-1),z+32},{x+sx+1,h*(last-sy)/(last-1),z+32},
    {x+sx+1,h*(last-sy-1)/(last-1),z+32},{x+sx,h*(last-sy-1)/(last-1),z+32},G.uv(ts,mid,xx%16,sy%16,xx%16+1,sy%16+1,.5),1)
  end
 end
end
local function strip(api,out,L,ts,o,a,b,project,cut)
 local source,inside=api.nativeMask(L,ts,o,o.w*16,o.last,o.background or {0x2a3})
 local vv=V.require('PaperSprite').build(ts,o.w*16,o.last,source,function(sx,sy)return sy>=a and sy<b and inside(sx,sy)and(not cut or cut(sx,sy))end,0,o.last,1,nil,project,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
end
function C.clubFold(api,out,L,ts,o,x,z)
 strip(api,out,L,ts,o,o.cap,o.split,function(sx,sy)return {x+sx,o.height,z+o.front-o.depth+(sy-o.cap)*o.depth/(o.split-o.cap)}end)
 strip(api,out,L,ts,o,o.split,o.last,function(sx,sy)return {x+sx,o.height*(o.last-sy)/(o.last-o.split),z+o.front}end)
end
function C.clubSeat(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.clubSurfaces
 if not o.side then
  strip(api,out,L,ts,o,9,20,function(sx,sy)return {x+sx,c.seatHeight+(20-sy)*(c.backHeight-c.seatHeight)/11,z+19}end)
  strip(api,out,L,ts,o,20,28,function(sx,sy)return {x+sx,c.seatHeight,z+19+(sy-20)*10/8}end)
  strip(api,out,L,ts,o,28,32,function(sx,sy)return {x+sx,c.seatHeight*(32-sy)/4,z+29}end)
 else
  local cut=o.right and 11 or 5
  local function back(sx)return o.right and sx>=cut or not o.right and sx<cut end
  strip(api,out,L,ts,o,1,30,function(sx,sy)return {x+sx,c.backHeight,z+sy}end,back)
  strip(api,out,L,ts,o,1,30,function(sx,sy)return {x+sx,c.seatHeight,z+sy}end,function(sx)return not back(sx)end)
  local G=V.require('WorldGeometry');local u=o.right and 12 or 2
  local uv=G.uv(ts,L:midAt(o.x,o.y+1),u,8,u+1,9,.5)
  G.quad(out,{x+cut,c.backHeight,z+1},{x+cut,c.backHeight,z+30},{x+cut,c.seatHeight,z+30},{x+cut,c.seatHeight,z+1},uv,1)
  for _,b in ipairs({false,true})do
   local h=b and c.backHeight or c.seatHeight
   strip(api,out,L,ts,o,30,32,function(sx,sy)return {x+sx,h*(32-sy)/2,z+30}end,function(sx)return back(sx)==b end)
  end
 end
end
function C.clubPC(api,out,L,ts,o,x,z)
 local function source(sx,sy)return L:midAt(o.x,math.floor(sy/16)),sx,sy%16 end
 local vv=V.require('PaperSprite').build(ts,16,40,source,function(sx,sy)
  if sy<8 then return false end
  local inset=sy<12 and 12-sy or sy>=38 and 1 or 0
  return sx>=inset and sx<16-inset
 end,0,40,1,nil,function(sx,sy)return {x+sx,40-sy,z+40}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
end
function C.clubPen(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').interiors.clubSurfaces
 -- Restore native green/yellow floor around the thin rail, not a solid block.
 for sy=16,47 do for sx=0,79 do
  local mid=sx<64 and 0x2ee or 0x287
  G.quad(out,{x+sx,0,z+sy},{x+sx+1,0,z+sy},{x+sx+1,0,z+sy+1},{x+sx,0,z+sy+1},G.uv(ts,mid,sx%16,sy%16,sx%16+1,sy%16+1,.5),1)
 end end
 local top=G.uv(ts,0x302,3,12,4,13,.5);local side=G.uv(ts,0x304,2,8,3,9,.5)
 api.prism(out,ts,0,x+66,z+16,3,26,0,c.penRailHeight,top,side,side)
 api.prism(out,ts,0,x+61,z+40,8,5,0,c.penRailHeight,top,side,side)
 api.patch(out,L,ts,o,0,36,18,8,{x,c.penRailHeight,z+44},{x+18,c.penRailHeight,z+44},{x+18,0,z+44},{x,0,z+44})
 api.prism(out,ts,0,x,z+40,18,4,0,c.penRailHeight,top,side,side)
end
return C
