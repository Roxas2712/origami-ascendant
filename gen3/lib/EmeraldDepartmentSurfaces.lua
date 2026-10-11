-- Measured Lilycove reception. Source pixels and original event geometry stay native.
local V=...
local D={}
function D.plan(def,p)
 if p.roof then return V.require("EmeraldDepartmentRoof").plan(def,p)end
 if p.cabin then
  local c=V.require('DioramaConfig').emeraldInteriors.department
  local objects,mask={},{}
  -- The upper eight source rows are void. Keep the complete metal frame,
  -- ceiling lamps and handrail together on the rear wall; never on the floor.
  for x=0,4 do
   objects[#objects+1]={kind='wall',x=x,y=0,w=16,h=48,wallCap=8,wallLast=48,wallBase=48,wallHeight=c.cabinWallHeight}
  end
  for y=0,5 do for x=0,5 do
   if y<3 or x==5 then mask[y*6+x+1]={mid=1,void=true}end
  end end
  return objects,mask
 end
 if p.retail then return V.require("EmeraldDepartmentRetail").plan(def,p)end
 local L=def.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.department
 local objects,mask={},{}
 local function add(o,x,y,w,h)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=p.floor end
  end end
  return o
 end
 -- The original floor tiles already include rectangular object shadows.
 -- Their geometry is replaced by short contact shadows, not a second layer.
 local shadows={[0x270]=true,[0x271]=true,[0x278]=true,[0x279]=true,[0x280]=true}
 for y=2,7 do for x=0,17 do if shadows[L:midAt(x,y)]then mask[y*18+x+1]=p.floor end end end
 for x=0,14 do
  local o=add({kind='wall',wallHeight=c.wallHeight,wallBase=32,wallLast=32},x,0,1,2)
  if x>=1 and x<=3 or x==6 or x==11 then o.clean={0x288,0x290}end
 end
 for y=0,1 do for x=0,17 do mask[y*18+x+1]={mid=0,void=true}end end
 add({kind='card',cap=8,last=44,front=40,height=c.elevatorHeight,trim=8,opaque=true},1,0,3,3)
 add({kind='storeStairs',front=32},15,0,3,2)
 add({kind='storeReception',front=48},6,1,6,3)
 for _,y in ipairs({4,6})do
  add({kind='card',cap=10,last=31,front=32,height=c.planterHeight,background={{mid=p.floor}},positionMask=true},0,y,2,2)
 end
 for _,y in ipairs({3,5})do
  add({kind='fold',cap=0,split=9,last=16,front=16,height=c.stoolHeight,depth=12,background={{mid=p.floor}},positionMask=true},16,y,1,1)
 end
 for _,x in ipairs({14,16,17})do
  add({kind='card',cap=0,last=31,front=32,height=c.plantHeight,background={{mid=p.floor}},positionMask=true},x,6,1,2)
 end
 return objects,mask
end
function D.build(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.department;local first=#out+1
 local function source(sx,sy)return L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16)),sx%16,sy%16 end
 local function draw(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(sx,sy)return sy>=a and sy<b and(not inside or inside(sx,sy))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 if o.kind=='storeIsland'then
  V.require('EmeraldDepartmentRetail').build(out,L,ts,o,x,z)
 elseif o.kind=='storeReception'then
  local h=c.counterHeight;local right=o.w-16;local spans={{4,6},{3,8},{2,10},{2,12},{2,14},{2,16},{2,16},{2,16},{2,16},{2,16},{3,16},{5,16},{5,16},{5,15},{5,14},{6,9}}
  -- The side-view terminal keeps its white case and exact outline, including
  -- its tiny base. Rebuild the original green countertop underneath it.
  draw(8,38,function(sx,sy)return{x+sx,h,z+o.front-30+sy-8}end,function(sx,sy)return sx<16 or sx>=right or sy>=28 end,function(sx,sy)
   if sx<16 and sy>=21 then return source(sx,12)end
   if sx>=right and sy<24 then return source(right+sx%16,26)end
   return source(sx,sy)
  end)
  draw(38,48,function(sx,sy)return{x+sx,h*(48-sy)/10,z+o.front}end)
  draw(21,37,function(sx,sy)return{x+sx,h+(37-sy)*c.terminalHeight/16,z+o.front-12}end,function(sx,sy)
   local r=spans[sy-20];return r and sx>=r[1]and sx<r[2]
  end)
  -- Upright information terminal on the opposite return, from the native tile.
  local info={{11,15},{10,15},{9,15},{2,15},{2,15},{2,15},{2,15},{2,15},{2,16},{2,16},{2,14},{2,13},{2,12},{2,11},{2,10}}
  draw(9,24,function(sx,sy)return{x+sx,h+(24-sy)*c.infoHeight/15,z+o.front-23}end,function(sx,sy)
   local r=info[sy-8];return r and sx>=right+r[1]and sx<right+r[2]
  end)
 elseif o.kind=='storeStairs'then
  local h=c.wallHeight;local rise=c.stairStepHeight;local back=z+32-c.stairDepth;local roof=c.stairRecessHeight;local bottom=o.down and -2*rise or 3*rise
  draw(0,32,function(sx,sy)return{x+sx,h*(32-sy)/32,z+32}end,function(sx)return sx<16 or sx>=32 end)
  draw(0,14,function(sx,sy)return{x+sx,h*(32-sy)/32,z+32}end,function(sx)return sx>=16 and sx<32 end)
  local shade=G.uv(ts,0x309,7,14,8,15,.5)
  G.quad(out,{x+16,roof,back},{x+32,roof,back},{x+32,bottom,back},{x+16,bottom,back},shade,1)
  G.quad(out,{x+16,roof,back},{x+32,roof,back},{x+32,h*18/32,z+32},{x+16,h*18/32,z+32},shade,1)
  for _,sx in ipairs({16,32})do G.quad(out,{x+sx,roof,back},{x+sx,h*18/32,z+32},{x+sx,0,z+32},{x+sx,bottom,back},shade,.85)end
  for j=0,2 do
   local a=14+j*6;local high=o.down and (j-2)*rise or (3-j)*rise;local topRows=o.down and j==2 and 6 or 4
   draw(a,a+topRows,function(sx,sy)return{x+sx,high,back+(j+(sy-a)/topRows)*c.stairDepth/3}end,function(sx)return sx>=16 and sx<32 end)
   if not o.down or j<2 then draw(a+4,a+6,function(sx,sy)return{x+sx,high+(o.down and 1 or -1)*(sy-a-4)*rise/2,back+(j+1)*c.stairDepth/3}end,function(sx)return sx>=16 and sx<32 end)end
  end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return D
