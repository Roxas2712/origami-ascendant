-- Authored cutaway shells for the three native wreck corridors. Cabin voids
-- are not white ceilings or floor; doors, water and damaged carpet stay native.
local V=...;local C={}
local rooms={
 EM_ABANDONED_SHIP_CORRIDORS_1F={w=18,h=12,anchor={0,11,0x29b},rear={{0,6},{8,17}},
  floors={{0,2,7,10},{8,2,10,10}},blocks={{2,3,3,7},{10,3,6,7}},down={{5,2},{16,2}},
  lights={{24,38,35,1},{72,38,35,1},{146,38,35,1},{200,38,35,1},{264,38,35,1},{64,55,171},{220,55,171}}},
 EM_ABANDONED_SHIP_CORRIDORS_B1F={w=14,h=10,anchor={5,5,0x206},shellY=1,
  floors={{0,0,13,10}},blocks={{2,0,6,5,backless=true},{10,0,3,5,backless=true},{4,7,9,3,frontless=true}},
  up={{0,0},{8,0}},lights={{22,55,65},{151,55,65},{94,55,103},{21,55,139}}},
 EM_ABANDONED_SHIP_HIDDEN_FLOOR_CORRIDORS={w=14,h=12,anchor={5,10,0x202},rear={{0,12}},
  floors={{0,2,13,9}},blocks={{2,3,9,6}},
  lights={{24,38,35,1},{88,38,35,1},{152,38,35,1},{200,55,143},{95,55,164}}},
}
function C.profile(d)
 local a=V.require('DioramaConfig').emeraldInteriors;local L=d and d.midLayout;local r=d and rooms[d.id or d.name]
 if a.enabled and a.wreck.enabled and a.wreck.corridors.enabled and r and tonumber(d.mapType)==4
  and d.pair=='general__inside_ship'and L and L.width==r.w and L.height==r.h
  and L:midAt(r.anchor[1],r.anchor[2])==r.anchor[3]and L:midAt(3,r.shellY or 4)==0x231 then return a.wreck.corridorProfile,r end
end
function C.plan(d)
 local _,r=C.profile(d);local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.wreck
 local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 local function void(x,y)mask[y*L.width+x+1]={mid=0x201,void=true}end
 local function floor(x,y)
  local m=L:midAt(x,y);mask[y*L.width+x+1]=0x202
  if m<0x200 or m==0x29b or m==0x29c or m==0x2ac or m==0x2ad then mask[y*L.width+x+1]=nil end
 end
 for y=0,L.height-1 do for x=0,L.width-1 do void(x,y)end end
 for _,a in ipairs(r.floors)do for y=a[2],a[2]+a[4]-1 do for x=a[1],a[1]+a[3]-1 do floor(x,y)end end end
 for _,a in ipairs(r.rear or{})do for x=a[1],a[2]do add('wall',x,0,1,2,{wallHeight=c.wallHeight,wallLast=32,wallBase=32})end end
 for _,b in ipairs(r.blocks)do local x,y,w,h=unpack(b)
  local doors={};for col=1,w-1,3 do doors[col]=true end
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   void(xx,yy)
   if (not b.backless and yy==y)or (not b.frontless and yy==y+h-1 and doors[xx-x])then floor(xx,yy)end
  end end
  add('wreckHallBlock',x,y,w,h,{backless=b.backless,frontless=b.frontless,doors=doors})
  if not b.frontless then add('wreckHallFront',x,y+h-2,w,2,{doors=doors})end
 end
 for _,a in ipairs(r.down or{})do
  add('wreckHallDown',a[1],a[2],2,1,{floor=0x202,noRear=true,edgeLine=true,stairDrop=c.corridors.stairDrop,railHeight=c.corridors.railHeight})
  for x=a[1],a[1]+1 do void(x,a[2])end
 end
 for _,a in ipairs(r.up or{})do
  add('tidalStairs',a[1],a[2],2,3)
  for x=a[1],a[1]+1 do add('wall',x,a[2],1,2,{wallHeight=c.wallHeight,wallLast=32,wallBase=32,clean={0x221,0x229}})end
 end
 return objects,mask
end
function C.build(out,L,ts,o,x,z,contacts)
 local a=V.require('DioramaConfig').emeraldInteriors;local c=a.wreck.corridors;local G=V.require('WorldGeometry');local first=#out+1
 local function draw(w,h,src,inside,project)
  local vv=V.require('PaperSprite').build(ts,w,h,src,inside,0,h,1,nil,project,.5);for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function wood(s,t)return t<16 and 0x222 or 0x22a,s%16,t%16 end
 local function patch(ax,az,bx,bz,h)
  G.quad(out,{x+ax,h,z+az},{x+bx,h,z+az},{x+bx,h,z+bz},{x+ax,h,z+bz},G.uv(ts,0x231,8,8,9,9,.5),1)
 end
 local function face(ax,az,bx,bz,h)
  local len=math.sqrt((bx-ax)^2+(bz-az)^2)
  draw(len,32,wood,function()return true end,function(s,t)return{x+ax+(bx-ax)*s/len,h*(32-t)/32,z+az+(bz-az)*s/len}end)
 end
 if o.kind=='wreckHallDown'then
  local stair={};for k,v in pairs(o)do stair[k]=v end;stair.kind='tidalCorridorDown'
  V.require('EmeraldShipCorridor').build(out,L,ts,stair,x,z,contacts)
  V.require('RoomRecessClip').shaft(out,{x+8,z,x+32,z+16},o.stairDrop*a.heightScale,
   G.uv(ts,0x20e,8,9,9,10,.5),G.HANGING_FACADE)
  return
 elseif o.kind=='wreckHallFront'then
  draw(o.w,32,source,function(_,t)return t>=4 end,function(s,t)return{x+s,c.wallHeight*(32-t)/28,z+32}end)
  draw(o.w,4,source,function()return true end,function(s,t)return{x+s,c.wallHeight,z+28+t}end)
  if contacts then for s=4,o.w-3,8 do contacts[#contacts+1]={x+s,z+32,5,2,c.contactStrength}end end
 else
  local back=o.backless and 0 or c.cutawayInset;local front=o.h;local h=c.wallHeight;local thick=c.wallThickness
  for _,edge in ipairs{0,o.w-thick}do
   face(edge,back,edge,front,h);face(edge+thick,front,edge+thick,back,h)
   patch(edge,back,edge+thick,front,h);face(edge,back,edge+thick,back,h)
   if o.frontless then face(edge+thick,front,edge,front,h)end
  end
  if not o.backless then for col=0,o.w/16-1 do if not o.doors[col]then
   local left,right=col*16,(col+1)*16;local low=c.cutawayHeight
   local rear,front=c.cutawayInset,c.cutawayInset+c.wallThickness
   face(left,front,right,front,low);face(right,rear,left,rear,low);patch(left,rear,right,front,low)
   face(left,rear,left,front,low);face(right,front,right,rear,low)
  end end end
 end
 for i=first,#out do out[i][2]=out[i][2]*a.heightScale end
end
function C.capture(list,o,x,z)
 if o.kind=='wreckHallDown'then return true end
 if o.kind~='wreckHallFront'and o.kind~='wreckHallBlock'then return false end
 local a=V.require('DioramaConfig').emeraldInteriors;local c=a.wreck.corridors
 local function box(l,r,b,f,h)list[#list+1]={lo={x+l,0,z+b},hi={x+r,h*a.heightScale,z+f},wall=true}end
 if o.kind=='wreckHallFront'then
  for col=0,o.w/16-1 do if not o.doors[col]then box(col*16,(col+1)*16,31.75,32.25,c.wallHeight)end end
 else
  local back=o.backless and 0 or c.cutawayInset
  box(0,c.wallThickness,back,o.h,c.wallHeight);box(o.w-c.wallThickness,o.w,back,o.h,c.wallHeight)
  if not o.backless then for col=0,o.w/16-1 do if not o.doors[col]then box(col*16,(col+1)*16,c.cutawayInset,c.cutawayInset+c.wallThickness,c.cutawayHeight)end end end
 end
 return true
end
function C.recesses(d)
 local _,r=C.profile(d);local bounds={};if not r then return bounds end
 for _,s in ipairs(r.down or{})do bounds[#bounds+1]={s[1]*16+8,s[2]*16,s[1]*16+32,s[2]*16+16}end
 return bounds
end
function C.lighting(d)
 local _,r=C.profile(d);if not r then return end
 local c=V.require('DioramaConfig').emeraldInteriors.wreck.corridors;local sources={}
 for _,s in ipairs(r.lights)do sources[#sources+1]={at={s[1],s[2],s[3]},color=c.color,radius=c.radius,
  power=s[4]and c.windowPower or c.fillPower,nightPower=s[4]and c.windowNightPower or c.fillNightPower,spread={12,8}}end
 return{ambient=c.ambient,night=c.night,sources=sources,localSelection=true}
end
return C
