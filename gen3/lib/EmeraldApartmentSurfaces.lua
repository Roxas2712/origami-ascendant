-- Measured Rustboro apartments. Native cells/events/warps are read-only.
local V=...
local A={}
-- Shared native plant silhouette, including the opaque pot. The three source
-- variants contain different wall/floor shadows outside this same contour.
local plantRows={
 [1]={7,9},[2]={6,10},[3]={3,13},[4]={2,14},[5]={2,14},[6]={1,15},
 [7]={0,16},[8]={0,16},[9]={1,15},[10]={0,16},[11]={0,16},[12]={1,15},
 [13]={2,14},[14]={2,14},[15]={3,13},[16]={5,11},[17]={6,10},[18]={6,10},
 [19]={4,12},[20]={3,13},[21]={2,14},[22]={2,14},[23]={2,14},[24]={2,14},
 [25]={2,14},[26]={2,14},[27]={2,14},[28]={2,14},[29]={2,14},[30]={3,13},[31]={4,12},
}
function A.plantInside(s,t)local r=plantRows[t];return r and s>=r[1]and s<r[2]or false end
local heights={EM_RUSTBORO_CITY_FLAT1_1F=8,EM_RUSTBORO_CITY_FLAT1_2F=8,
 EM_RUSTBORO_CITY_FLAT2_1F=10,EM_RUSTBORO_CITY_FLAT2_2F=10,EM_RUSTBORO_CITY_FLAT2_3F=10}
function A.profile(def)
 local cfg=V.require('DioramaConfig').emeraldInteriors
 local L=def.midLayout;local id=def.id or def.name
 if cfg.enabled and cfg.apartments.enabled and heights[id] and def.pair=='building__generic_building'
  and L and L.width==14 and L.height==heights[id] and L:midAt(1,2)==0x32b then
  return cfg.homeRooms.apartment
 end
end
function A.plan(def,p)
 local L=def.midLayout;local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.apartments
 local objects,mask=V.require('EmeraldTileHomeSurfaces').plan(def,p)
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.residentialHome=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=donor or(xx==0 or yy==2)and p.edgeFloor or p.floor end
  end end
  return o
 end
 local blocked={}
 for x=0,13 do
  local m=L:midAt(x,0)
  if m==0x329 then
   add({kind='apartmentStairs',down=L:midAt(x,1)==0x219,front=32,noContact=true},x-1,0,3,2)
   for xx=x-1,x+1 do blocked[xx]=true end
  elseif m==0x2d7 then
   add({kind='apartmentPartition',axis='z',front=128,noContact=true},x,0,1,8)
   blocked[x]=true
  end
 end
 for y=2,L.height-1 do for x=0,13 do
  local m=L:midAt(x,y)
  if m==0x29d then
   add({kind='apartmentPartition',axis='x',front=48,noContact=true},x,y,14-x,3)
  elseif m==0x368 then
   add({kind='fold',residentialTable=true,cap=0,split=25,last=32,height=cfg.tableHeight,depth=25,front=32,
    background={{mid=p.floor}},positionMask=true},x,y,2,2)
  elseif m==0x321 then
   add({kind='card',cap=2,last=28,front=28,height=c.tvHeight,
    background={{mid=0x23e}},positionMask=true},x,y,2,2,0x23e)
  end
 end end
 if L:midAt(0,1)==0x348 then
  add({kind='fold',cap=1,split=8,last=24,height=c.drawerHeight,depth=7,front=32,bounds={0,15}},0,1,1,2)
  for _,o in ipairs(objects)do if o.kind=='wall'and o.x==0 then o.clean={0x338,0x340}end end
 end
 local kept={}
 for _,o in ipairs(objects)do
  if not(o.kind=='wall'and blocked[o.x])then
   local mid=L:midAt(o.x,o.y)
   if o.kind=='card'and(mid==0x343 or mid==0x346 or mid==0x347)then o.kind='apartmentPlant'end
   if o.kind=='wall'then o.wallHeight=c.wallHeight;o.wallLast=32;o.wallBase=32 end
   if o.kind=='seat'and L:midAt(o.x+1,o.y)==0x337 then
    o.w=48
    for yy=o.y,o.y+1 do
     local k=yy*14+o.x+3;mask[k]=yy==2 and p.edgeFloor or p.floor
    end
    for _,w in ipairs(objects)do if w.kind=='wall'and w.x==o.x+2 then w.clean={0x338,0x340}end end
   end
   if o.kind=='fold'and L:midAt(o.x,o.y)==0x248 then o.cup=true end
   kept[#kept+1]=o
  end
 end
 return kept,mask
end
function A.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.apartments
 local G=V.require('WorldGeometry');local first=#out+1;local h=c.wallHeight
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(mid,u0,v0,u1,v1,a,b,d,e,shade)
  G.quad(out,a,b,d,e,G.uv(ts,mid,u0,v0,u1,v1,.5),shade or 1)
 end
 local function wallFace(a,b,front)
  for j,m in ipairs({0x338,0x340})do
   local top,bot=h*(3-j)/2,h*(2-j)/2
   if front then patch(m,0,0,16,16,{a[1],top,a[2]},{b[1],top,b[2]},{b[1],bot,b[2]},{a[1],bot,a[2]})
   else patch(m,0,0,16,16,{b[1],top,b[2]},{a[1],top,a[2]},{a[1],bot,a[2]},{b[1],bot,b[2]})end
  end
 end
 if o.kind=='apartmentPlant'then
  draw(0,32,function(s,t)return{x+s,cfg.homePlantHeight*(32-t)/32,z+32}end,A.plantInside)
 elseif o.kind=='apartmentPartition'then
  if o.axis=='z'then
   local a,b=x+2,x+14;local back,front=z+32,z+o.front
   -- Close the two native edge columns where this divider joins the rear
   -- wall; the narrow crown must not leave black slits on either side.
   for j,m in ipairs({0x338,0x340})do local top,bot=h*(3-j)/2,h*(2-j)/2
    for _,r in ipairs({{0,2},{14,16}})do
     patch(m,r[1],0,r[2],16,{x+r[1],top,back},{x+r[2],top,back},{x+r[2],bot,back},{x+r[1],bot,back})
    end
   end
   for zz=back,front-16,16 do
    patch(0x300,2,0,14,16,{a,h,zz},{b,h,zz},{b,h,zz+16},{a,h,zz+16})
    wallFace({a,zz},{a,zz+16},true);wallFace({b,zz},{b,zz+16},false)
   end
   for j,m in ipairs({0x2df,0x2e7})do local top,bot=h*(3-j)/2,h*(2-j)/2
    patch(m,2,0,14,16,{a,top,front},{b,top,front},{b,bot,front},{a,bot,front})
   end
   if contacts then for zz=back+4,front,8 do contacts[#contacts+1]={(a+b)/2,zz,9,4,cfg.contactStrength}end end
  else
   local front=z+48;local back=front-c.partitionDepth;local a,b=x+2,x+o.w
   for xx=a,b-1,16 do local right=math.min(b,xx+16)
    patch(0x31e,0,12,right-xx,16,{xx,h,back},{right,h,back},{right,h,front},{xx,h,front})
    wallFace({xx,front},{right,front},true);wallFace({xx,back},{right,back},false)
   end
   wallFace({a,back},{a,front},true)
   if contacts then for xx=a+4,b,8 do contacts[#contacts+1]={xx,front,7,3,cfg.contactStrength}end end
  end
 elseif o.kind=='apartmentStairs'then
  -- Preserve the native frame and dark stairwell as one connected wall.
  -- Only the lower treads protrude; the top lintel stays part of the wall.
  draw(0,32,function(s,t)return{x+s,h*(32-t)/32,z+32}end)
  if not o.down then
   local depth=c.stairDepth
   for j=0,2 do local row=20+j*4;local high=(3-j)*c.stepHeight
    draw(row,row+2,function(s,t)return{x+s,high,z+32+(j+(t-row)/2)*depth/3}end,function(s)return s>=16 and s<32 end)
    draw(row+2,row+4,function(s,t)return{x+s,high-(t-row-2)*c.stepHeight/2,z+32+(j+1)*depth/3}end,function(s)return s>=16 and s<32 end)
   end
  end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return A
