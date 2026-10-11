-- Native retail layouts: short/tall shelf islands and open glass sales counters.
local V=...
local R={}
function R.plan(def,p)
 local L=def.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.department
 local objects,mask={},{}
 local function add(o,x,y,w,h)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*18+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=p.floor end
  end end
  return o
 end
 local shadows=p.retail==5 and{0x2f3,0x2f4,0x2f5,0x2fa,0x2fc,0x2fd}or{0x202,0x204,0x206,0x208,0x20b,0x20f}
 local shaded={};for _,m in ipairs(shadows)do shaded[m]=true end
 for y=2,7 do for x=0,17 do if shaded[L:midAt(x,y)]then mask[y*18+x+1]=p.floor end end end
 local blank=p.retail==5 and{0x2e7,0x2ef}or{0x288,0x290}
 for x=0,11 do
  local o=add({kind='wall',wallHeight=c.wallHeight,wallBase=32,wallLast=32},x,0,1,2)
  if x>=1 and x<=3 or p.retail==3 and(x==6 or x==11)or p.retail==5 and(x==5 or x==11)then o.clean=blank end
 end
 for y=0,1 do for x=0,17 do mask[y*18+x+1]={mid=0,void=true}end end
 add({kind='card',cap=8,last=44,front=40,height=c.elevatorHeight,trim=8,opaque=true},1,0,3,3)
 for _,x in ipairs({12,15})do add({kind='storeStairs',front=32,down=L:midAt(x+1,1)==0x251},x,0,3,2)end
 local function shelf(x,y,h)
  -- Flood only floor-connected background. Keep opaque white bottle labels
  -- and the white sides inside the shelf's original dark outline.
  add({kind='fold',cap=0,split=6,last=h*16,front=h*16,height=h==3 and c.shelfHeight or c.shortShelfHeight,depth=c.shelfDepth,
   background={{mid=p.floor},{mid=0x201},{mid=0x206},{mid=0x208}}},x,y,2,h)
 end
 if p.retail==2 then
  shelf(2,4,3);shelf(14,4,3)
  add({kind='storeIsland',front=64,device=true},6,4,6,4)
  for _,y in ipairs({3,6})do add({kind='card',cap=0,last=31,front=32,height=c.plantHeight,background={{mid=p.floor}},positionMask=true},17,y,1,2)end
 elseif p.retail==3 then
  shelf(2,4,3);shelf(14,4,3)
  add({kind='storeReception',front=48},6,1,6,3)
 elseif p.retail==4 then
  shelf(1,5,2);shelf(13,5,2);shelf(15,5,2)
  add({kind='storeIsland',front=64,device=true},6,4,5,4)
 elseif p.retail==5 then
  shelf(2,4,3);shelf(6,5,2);shelf(10,5,2)
  add({kind='storeReception',front=48},5,1,7,3)
  add({kind='storeIsland',front=64,noRight=true},14,4,4,4)
 end
 return objects,mask
end
function R.build(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').emeraldInteriors.department;local h=c.counterHeight
 local function source(sx,sy)return L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16)),sx%16,sy%16 end
 local function draw(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(sx,sy)return sy>=a and sy<b and(not inside or inside(sx,sy))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local barEnd=o.noRight and o.w or o.w-16;local back=o.front-42
 draw(14,24,function(sx,sy)return{x+sx,h,z+back+sy-14}end,function(sx)return sx>=16 and sx<barEnd end)
 draw(24,32,function(sx,sy)return{x+sx,h*(32-sy)/8,z+back+10}end,function(sx)return sx>=16 and sx<barEnd end)
 local function returns(sx)return sx<16 or not o.noRight and sx>=o.w-16 end
 draw(14,56,function(sx,sy)return{x+sx,h,z+back+sy-14}end,returns,function(sx,sy)
  if o.device and sx<16 and sy>=37 and sy<54 then return source(sx,20)end
  return source(sx,sy)
 end)
 draw(56,64,function(sx,sy)return{x+sx,h*(64-sy)/8,z+o.front}end,returns)
 -- Side faces use the native return's rim, not black filler geometry.
 local mid,u,v=source(15,20);local edge=G.uv(ts,mid,u,v,u+1,v+1,.5)
 local sides={0,16};if not o.noRight then sides[#sides+1]=o.w-16;sides[#sides+1]=o.w end
 for _,sx in ipairs(sides)do G.quad(out,{x+sx,h,z+back},{x+sx,h,z+o.front},{x+sx,0,z+o.front},{x+sx,0,z+back},edge,.9)end
 if o.device then
  local spans={{4,6},{3,8},{2,10},{2,12},{2,14},{2,16},{2,16},{2,16},{2,16},{2,16},{3,16},{5,16},{5,16},{5,15},{5,14},{6,9}}
  draw(37,53,function(sx,sy)return{x+sx,h+(53-sy)*c.terminalHeight/16,z+o.front-12}end,function(sx,sy)local r=spans[sy-36];return r and sx>=r[1]and sx<r[2]end)
 end
end
return R
