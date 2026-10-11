-- Lilycove's open roof deck: native pixels, independent of gameplay height.
local V=...
local R={}
function R.plan(def,p)
 local L=def.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.department.roof
 local objects,mask={},{}
 -- Every tile has explicit ownership. The source facade below the terrace
 -- hangs down from its edge instead of becoming additional walkable-looking floor.
 for y=0,11 do for x=0,17 do
  mask[y*18+x+1]=(y==0 or y>=7 or x==0 or x>=16 and y<2 or x==17 and y>=3 or x==15 and y>=1 and y<3)and{mid=0x21f,void=true}or p.floor
 end end
 local function add(o,x,y,w,h)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o;return o
 end
 add({kind='roofBoundary',noContact=true},0,0,18,12)
 add({kind='roofHut',front=48,noContact=true},12,1,3,3)
 for _,x in ipairs({9,10})do
  add({kind='fold',cap=0,split=8,last=32,front=32,height=c.vendingHeight,depth=c.vendingDepth},x,0,1,2)
 end
 for _,y in ipairs({2,4})do
  add({kind='fold',cap=8,split=23,last=30,front=32,height=c.planterHeight,depth=13,background={{mid=p.floor},{mid=0x24d}}},1,y,2,2)
 end
 for _,x in ipairs({5,9})do
  add({kind='seat',cap=3,backEnd=8,seatEnd=11,last=15,front=15,backHeight=c.benchBackHeight,seatHeight=c.benchSeatHeight,depth=c.benchDepth,background={{mid=p.floor}}},x,5,2,1)
 end
 for _,y in ipairs({4,5})do add({kind='roofChair',front=15,height=c.benchBackHeight},16,y,1,1)end
 return objects,mask
end
function R.build(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.department.roof;local first=#out+1
 local function source(sx,sy)return L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16)),sx%16,sy%16 end
 local function draw(w,h,src,inside,project,shade)
  local vv=V.require('PaperSprite').build(ts,w,h,src,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 if o.kind=='roofBoundary'then
  -- Preserve the rail's native cap and posts; the spaces between posts
  -- are actual holes, not pale background rectangles from the flat drawing.
  local function rail(x0,z0,length,side)
   draw(length,16,function(s,y)return y<8 and 0x281 or 0x253,s%16,(y+8)%16 end,
    function(s,y)return y<3 or y>=12 or s%8>=2 and s%8<=5 end,
    function(s,y)return{x+x0+(side and 0 or s),c.railHeight*(16-y)/16,z+z0+(side and s or 0)}end)
  end
  rail(12,24,232,false);rail(244,48,32,false);rail(12,112,264,false)
  rail(12,24,88,true);rail(244,24,24,true);rail(276,48,64,true)
  -- Source cornice and three windows form one connected front facade.
  draw(288,76,function(s,y)return source(s,y+116)end,nil,
   function(s,y)return{x+s,-y*c.facadeHeight/76,z+112}end,G.HANGING_FACADE)
  for _,edge in ipairs({{12,16,24,112},{272,276,48,112},{240,244,24,48}})do
   local x0,x1,z0,z1=unpack(edge)
   draw(x1-x0,z1-z0,function(s,y)return 0x24a,(x0+s)%16,(z0+y)%16 end,nil,
    function(s,y)return{x+x0+s,0,z+z0+y}end)
  end
  -- Narrow original coping strips outside the side rails remain horizontal.
  for _,edge in ipairs({{0,12,24,112},{276,288,48,112},{244,256,24,48}})do
   local x0,x1,z0,z1=unpack(edge)
   draw(x1-x0,z1-z0,function(s,y)return source(x0+s,z0+y)end,nil,
    function(s,y)return{x+x0+s,0,z+z0+y}end)
  end
 elseif o.kind=='roofHut'then
  draw(48,48,source,nil,function(s,y)
   if y<=20 then return{x+s,c.hutHeight,z+48-c.hutDepth+y*c.hutDepth/20}end
   return{x+s,c.hutHeight*(48-y)/28,z+48}
  end)
  for _,edge in ipairs({0,48})do
   draw(c.hutDepth,28,function(_,y)return source(edge==0 and 0 or 47,y+20)end,nil,
    function(s,y)return{x+edge,c.hutHeight*(28-y)/28,z+48-c.hutDepth+s}end)
  end
 elseif o.kind=='roofChair'then
  -- Native right-facing chair: upright back at the right edge, seat on
  -- the ground-facing horizontal plane, two short legs below it.
  local pixel=V.require('BuildingMesh').pixel
  local function ink(s,y)local r,g,b=pixel(ts,source(s,y));return b>g*1.12 end
  draw(16,16,source,function(s,y)return s>=11 and y<11 and ink(s,y)end,
   function(s,y)return{x+13,c.benchSeatHeight+(11-y)*(c.benchBackHeight-c.benchSeatHeight)/11,z+4+(s-11)*c.benchDepth/5}end)
  draw(16,16,source,function(s,y)return s<11 and y>=4 and y<12 and ink(s,y)end,
   function(s,y)return{x+s,c.benchSeatHeight,z+4+(y-4)*c.benchDepth/8}end)
  draw(16,16,source,function(s,y)return y>=12 and ink(s,y)end,
   function(s,y)return{x+s,c.benchSeatHeight*(16-y)/4,z+4+c.benchDepth}end)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
function R.light(def,result)
 local p=V.require('EmeraldRoomSurfaces').profile(def)
 if not(p and p.roof)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.department.roof
 local power=c.vendingLightPower*V.require('DayNight').windowLight()
 if power<=0 then return end
 for _,x in ipairs({9.5,10.5})do
  result.lights[#result.lights+1]={x=x*16,y=c.vendingLightHeight,z=35,radius=-c.vendingLightRadius,power=power,color=c.vendingLightColor}
 end
end
return R
