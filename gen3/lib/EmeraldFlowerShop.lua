-- Native Pretty Petal layout: independent plant displays, counter and walls.
local V=...
local F={}
local ids={EM_ROUTE104_PRETTY_PETAL_FLOWER_SHOP=true,EM_ROUTE104_PROTOTYPE_PRETTY_PETAL_FLOWER_SHOP=true}
function F.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.flowerShop.enabled and ids[d.id or d.name]and d.pair=='building__pretty_petal_flower_shop'
  and L and L.width==16 and L.height==10 and L:midAt(0,0)==0x210 and L:midAt(5,6)==0x22e then return c.homeRooms.flowerShop end
end
function F.plan(d,p)
 local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.flowerShop
 local objects,mask={},{}
 -- Remove baked furniture and its painted floor shadows; retain native exits.
 for y=0,9 do for x=0,15 do local m=L:midAt(x,y)
  if m~=1 and m~=6 and m~=7 then mask[y*16+x+1]=y<2 and{mid=1,void=true}or(y==2 and 0x202 or 0x201)end
 end end
 local function add(o,x,y,w,h)o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o;return o end
 for x=0,14 do
  if x~=5 then
   local o=add({kind='wall',wallHeight=c.wallHeight,wallLast=32,wallBase=32,nativeUpper=true},x,0,1,2)
   if x~=0 and x~=1 and x~=4 and x~=14 then o.clean={0x213,0x21b}end
  end
 end
 add({kind='card',cap=0,last=40,front=32,height=c.wallHeight,opaque=true},5,0,1,3)
 -- Vases are separate from their wall: closed pale interiors stay opaque.
 for _,x in ipairs({2,6,9})do add({kind='card',cap=x==9 and 0 or 2,last=23,front=24,height=c.vaseHeight,
  background={{mid=0x213},{mid=0x21b},{mid=0x202}},positionMask=true},x,1,1,2)end
 add({kind='flowerShelf',cap=3,last=32,front=32,height=c.shelfHeight},7,1,2,2)
 for _,x in ipairs({10,12})do add({kind='flowerRearDisplay',cap=3,last=32,front=32,height=c.rearDisplayHeight},x,1,2,2)end
 add({kind='flowerCounter',front=55,noContact=true},0,2,2,4)
 add({kind='flowerRegister',front=12,noContact=true},1,2,1,1)
 for _,x in ipairs({0,6,10})do add({kind='flowerStool',front=14},x,3,1,1)end
 for y=3,8 do for x=0,14 do local m=L:midAt(x,y)
  if m==0x225 then add({kind='flowerTallDisplay',cap=0,last=48,front=48,height=c.tallDisplayHeight},x,y,1,3)
  elseif m==0x22e and L:midAt(x,y-1)~=0x22e then
   local rows=1;while L:midAt(x,y+rows)==0x22e do rows=rows+1 end
   if L:midAt(x,y+rows)==0x236 then rows=rows+1 end
   add({kind='flowerBox',front=rows*16,height=rows*16-2},x,y,1,rows)
  elseif m==0x236 and L:midAt(x,y-1)~=0x22e then add({kind='flowerBox',front=16,height=14},x,y,1,1)end
 end end
 return objects,mask
end
function F.inside(kind,x,y,w,h)
 if kind=='flowerShelf'then
  if y<3 or y>=32 then return false end
  if y>=28 then return x>=1 and x<4 or x>=28 and x<31 end
  return x>=1 and x<31
 elseif kind=='flowerRearDisplay'then
  if y<3 or y>=32 then return false end
  if y>=27 then return x>=1 and x<4 or x>=28 and x<31 end
  return true
 elseif kind=='flowerTallDisplay'then
  if y>=43 then return x>=1 and x<4 or x>=12 and x<15 end
  return true
 elseif kind=='flowerStool'then
  if y>=14 then return false end
  local ranges={{6,10},{4,12},{3,13},{2,14},{2,14},{2,14},{2,14},{2,14},{2,14},{3,13},{3,13},{2,6},{2,5},{3,5}}
  local r=ranges[y+1];return r and(x>=r[1]and x<r[2]or y>=11 and x>=16-r[2]and x<16-r[1])or false
 end
 return true
end
function F.build(out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').emeraldInteriors.flowerShop
 local scale=V.require('DioramaConfig').emeraldInteriors.heightScale
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do v[2]=v[2]*scale;out[#out+1]=v end
 end
 if o.kind=='flowerCounter'then
  draw(3,55,function(s,t)return{x+s,c.counterHeight,z+t}end,function(s,t)return s>=16 or t>=42 end,function(s,t)
   if s>=16 and t<15 then return source(20,18)end;return source(s,t)
  end)
  draw(55,64,function(s,t)return{x+s,c.counterHeight*(64-t)/9,z+55}end,function(s,t)return s>=16 or t<57 end)
 elseif o.kind=='flowerRegister'then
  draw(1,14,function(s,t)return{x+s,c.counterHeight+14-t,z+12}end,function(s,t)return s>=2 and s<16 end)
 elseif o.kind=='flowerStool'then
  draw(0,9,function(s,t)return{x+s,c.stoolHeight,z+4+t*10/9}end,function(s,t)return F.inside(o.kind,s,t)end)
  draw(9,14,function(s,t)return{x+s,c.stoolHeight*(14-t)/5,z+14}end,function(s,t)return F.inside(o.kind,s,t)end)
 else
  local cap,last=o.cap or 0,o.last or o.h
  local BM=V.require('BuildingMesh')
  local function same(a,b,c,d,e,f)return a==d and b==e and c==f end
  local function inside(s,t)
   if not F.inside(o.kind,s,t,o.w,o.h)then return false end
   -- Only open space above the rear pots/tall canopy is removed by color.
   -- All pots, white petals, platforms and enclosed shelf faces stay intact.
   if o.kind=='flowerRearDisplay'and t<8 then
    local r,g,b=BM.pixel(ts,source(s,t));return not same(r,g,b,BM.pixel(ts,0x21b,s%16,t%16))
   elseif o.kind=='flowerTallDisplay'and t<7 then
    local r,g,b=BM.pixel(ts,source(s,t));return not same(r,g,b,BM.pixel(ts,0x201,s%16,t%16))
   end
   return true
  end
  draw(cap,last,function(s,t)return{x+s,(last-t)*o.height/(last-cap),z+o.front}end,inside)
 end
end
return F
