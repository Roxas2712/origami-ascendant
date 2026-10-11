-- Measured Celadon roof deck. All sampling stays in the native live atlas.
local V=...
local R={}
function R.profile(def)
 local c=V.require('DioramaConfig').interiors.departmentRoof;local L=def and def.midLayout
 if c.enabled and (def.id or def.name)=='FR_CELADON_CITY_DEPARTMENT_STORE_ROOF' and (def.renderPair or def.pair)=='building__rom_082d4e6c'
  and L and L.width==20 and L.height==14 and L:midAt(10,2)==0x325 and L:midAt(4,5)==0x34b then return c end
end
function R.plan(def)
 if not R.profile(def)then return end
 local L=def.midLayout;local objects,mask,owners={},{},{}
 for y=0,13 do for x=0,19 do mask[y*20+x+1]={mid=0,void=true}end end
 local function add(kind,x,y,w,h)
  local o={kind=kind,x=x,y=y,w=w,h=h};objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do owners[yy*20+xx+1]=o end end
  return o
 end
 add('deck',0,0,19,14);add('hut',13,0,5,8)
 for x=10,12 do add('vending',x,2,1,2)end
 add('table',3,4,4,4);add('bin',9,3,1,1)
 return {objects=objects,mask=mask,owners=owners}
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local G=V.require('WorldGeometry');local c=V.require('DioramaConfig').interiors.departmentRoof
 local pixel=V.require('BuildingMesh').pixel
 local function src(s,y)return L:midAt(math.floor(s/16),math.floor(y/16)),s%16,y%16 end
 local function draw(w,h,source,inside,project,shade)
  local v=V.require('PaperSprite').build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,a in ipairs(v)do a[1]=a[1]+ox*16;a[3]=a[3]+oz*16;out[#out+1]=a end
 end
 local function area(x,y,w,h,project,inside,shade)
  draw(w,h,function(s,t)return src(x+s,y+t)end,inside,function(s,t)return project(x+s,y+t)end,shade)
 end
 local function flat(x,y,w,h,height)area(x,y,w,h,function(s,t)return{s,height or 0,t}end)end
 for _,o in ipairs(objects)do
  if o.kind=='deck'then
   -- Floor/coping is retained at its native cell; artwork belonging to
   -- furniture or the hanging facade is sampled by its own surface below.
   area(16,32,272,112,function(s,t)return{s,0,t}end,function(s,t)
    local x,y=s+16,t+32
    return y>=48 and not(x>=144 and x<160 and y<64)and not(x>=48 and x<112 and y>=64 and y<128)and not(x>=160 and x<208 and y<64)and not(x>=208 and y<64 or x>=240 and y<128)
   end)
   draw(192,16,function(s,t)return 0x2bb,s%16,t%16 end,nil,function(s,t)return{16+s,0,32+t}end)
   draw(16,16,function(s,t)return 0x2bb,s,t end,nil,function(s,t)return{144+s,0,48+t}end)
   -- Native floor beneath the machines, without their baked shadow band.
   draw(48,16,function(s,t)return 0x2b8,s%16,t%16 end,nil,function(s,t)return{160+s,0,48+t}end)
   local function rail(x0,z0,length,side)
    draw(length,16,function(s,y)return src(16+s%16,24+y)end,function(s,y)
     local r,g,b=pixel(ts,src(16+s%16,24+y));return not(b>.9 and r<.7 and g>.7)end,
     function(s,y)return{x0+(side and 0 or s),c.railHeight*(16-y)/16,z0+(side and s or 0)}end)
   end
   rail(8,32,200,false);rail(8,144,280,false);rail(8,32,112,true);rail(288,32,112,true)
   for _,edge in ipairs({8,288})do
    draw(4,112,function(s,t)return src(16+t%16,25+s%2)end,nil,function(s,t)return{edge-2+s,c.railHeight,32+t}end)
   end
   local storeys=V.require('DioramaConfig').rooftopVista.enabled~=false and 5 or 1
   for floor=0,storeys-1 do
    local start=floor==0 and 144 or 160;local rows=224-start
    local offset=floor==0 and 0 or 80+(floor-1)*64
    area(0,start,304,rows,function(s,t)return{s,-(t-start+offset)*c.facadeHeight/80,144}end,function(s,t)
     local r,g,b=pixel(ts,src(s,start+t));return (s>=8 and s<296)or not(b>.9 and r<.7 and g>.7)end,G.HANGING_FACADE)
    -- Close the sides down to the same level; native facade strips supply
    -- the masonry, so neither a floating deck nor an open underside remains.
    if storeys>1 then for _,edge in ipairs{0,304}do
     draw(112,rows,function(s,t)return src(16+s%16,start+t)end,nil,
      function(s,t)return{edge,-(t+offset)*c.facadeHeight/80,32+s}end,G.HANGING_FACADE)
    end end
   end
   -- Solid native coping directly under the rail, including both corners.
   for _,x in ipairs({0,288})do draw(16,112,function(s,t)return 0x2bb,s%16,t%16 end,nil,function(s,t)return{x+s,0,32+t}end)end
  elseif o.kind=='vending'then
   local x=o.x*16
   area(x,32,16,8,function(s,t)return{s,c.vendingHeight,64-c.vendingDepth+(t-32)*c.vendingDepth/8}end)
   area(x,40,16,24,function(s,t)return{s,c.vendingHeight*(64-t)/24,64}end)
   for _,edge in ipairs({x,x+16})do
    draw(c.vendingDepth,24,function(_,t)return src(edge==x and x or x+15,40+t)end,nil,
     function(s,t)return{edge,c.vendingHeight*(24-t)/24,64-c.vendingDepth+s}end)
   end
   contacts[#contacts+1]={x+8+ox*16,64+oz*16,8,3,.3}
  elseif o.kind=='hut'then
   -- L-shaped stair enclosure: roof, signed front, long side and end cap.
   area(208,8,80,24,function(s,t)return{s,c.hutHeight,16+(t-8)*48/24}end)
   area(208,32,48,32,function(s,t)return{s,c.hutHeight*(64-t)/32,64}end)
   area(256,32,32,80,function(s,t)return{s,c.hutHeight,64+(t-32)*64/80}end)
   area(256,112,32,16,function(s,t)return{s,c.hutHeight*(128-t)/16,128}end)
   draw(112,32,function(_,t)return src(208,32+t)end,nil,function(s,t)return{288,c.hutHeight*(32-t)/32,16+s}end)
   -- Interior wall beside the landing keeps a doorway above the native stairs.
   draw(64,32,function(_,t)return src(255,32+t)end,function(s,t)return s<16 or s>=48 or t<8 end,
    function(s,t)return{256,c.hutHeight*(32-t)/32,64+s}end)
   draw(48,32,function(_,t)return src(208,32+t)end,nil,function(s,t)return{208,c.hutHeight*(32-t)/32,16+s}end)
   -- Native pink landing remains horizontal; the orange tread drawing rises.
   flat(240,64,16,64)
   for n=0,3 do
    local z=80+n*8;local h=(4-n)*c.stairHeight/4
    area(248,z,8,8,function(s,t)return{s,h,z+(t-z)}end)
    area(248,z+6,8,2,function(s,t)return{s,h-(t-z-6)*c.stairHeight/8,z+8}end)
   end
  elseif o.kind=='bin'then
   area(152,50,7,13,function(s,t)return{s,c.binHeight*(63-t)/13,64}end,function(s,t)return t<10 or s<6 end)
   contacts[#contacts+1]={155+ox*16,64+oz*16,4,2,.25}
  elseif o.kind=='table'then
   -- Preserve the rug border and reconstruct only the covered pink interior
   -- from its own native texel. No wood/floor replacement through the carpet.
   draw(64,64,function(s,t)
    if s>=4 and s<60 and t>=12 and t<60 then return src(56,112)end
    return src(48+s,64+t)
   end,nil,function(s,t)return{48+s,0,64+t}end)
   local function tableInk(s,t)
    local r,g,b=pixel(ts,src(s,t));return not(r>.5 and b>r*.9 and g<r*.85)
   end
   area(64,80,32,28,function(s,t)return{s,c.tableHeight,84+(t-80)*24/28}end,function(s,t)return tableInk(64+s,80+t)end)
   area(64,108,32,8,function(s,t)return{s,c.tableHeight*(116-t)/8,108}end,function(s,t)return tableInk(64+s,108+t)end)
   for _,x in ipairs({52,100})do for _,y in ipairs({86,102})do
    area(x,y,10,10,function(s,t)return{s,c.seatHeight*(y+10-t)/10,y+10}end,function(s,t)return tableInk(x+s,y+t)end)
    area(x,y,10,6,function(s,t)return{s,c.seatHeight,y+4+(t-y)}end,function(s,t)return tableInk(x+s,y+t)end)
   end end
   contacts[#contacts+1]={80+ox*16,109+oz*16,17,4,.25}
  end
 end
end
function R.light(def,result)
 local c=R.profile(def);if not c then return end
 local p=c.vendingLightPower*V.require('DayNight').windowLight()
 if p<=0 then return end
 for x=10,12 do result.lights[#result.lights+1]={x=x*16+8,y=c.vendingLightHeight,z=68,radius=-c.vendingLightRadius,power=p,color=c.vendingLightColor}end
end
return R
