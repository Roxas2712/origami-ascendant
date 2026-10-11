-- Measured native Sevii house and its rear trainer room. The blocked door,
-- scripts and trainer event are retained; only surfaces/light are separated.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.sevenIslandRooms end
function R.profile(d)
 local L=d and d.midLayout
 if not cfg().enabled or not d or d.mapType~=8 or not L or L.width~=12 or L.height~=10 then return end
 if d.id=='FR_SEVEN_ISLAND_HOUSE_ROOM1'and (d.renderPair or d.pair)=='building__rom_082d4e24'and L:midAt(0,0)==0x13d and L:midAt(9,0)==0x13d then return 'home'end
 if d.id=='FR_SEVEN_ISLAND_HOUSE_ROOM2'and (d.renderPair or d.pair)=='house'and L:midAt(0,0)==0x108 and L:midAt(5,4)==0x124 then return 'rear'end
end
function R.plan(d)
 local L=d.midLayout;if L then R.rooms[L]=nil end;local family=R.profile(d);if not family then return end
 local c=cfg();local objects,mask={},{ };R.rooms[L]=objects
 local function add(kind,x,y,w,h,p)
  p=p or{};p.kind=kind;p.family=family;p.x=x;p.y=y;p.w=w;p.h=h;objects[#objects+1]=p
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*12+xx+1]={mid=8,void=true,separateSurface=true}end end
 end
 local width=family=='home'and 11 or 12
 add('sevenWall',0,0,width,2);add('sevenFloor',0,2,width,family=='home'and 6 or 7)
 if family=='home'then
  add('sevenExit',3,8,3,1)
  for _,x in ipairs{0,9}do add('sevenShelf',x,0,2,3,{cap=11,last=40,height=c.shelfHeight,shape='greenShelf'})end
  for x=3,5 do if L:midAt(x,1)==0x181 and L:midAt(x,2)==0x182 then add('sevenBoxes',x,1,1,2,{cap=0,last=24,height=c.boxHeight})end end
  add('sevenTable',5,4,2,2,{cap=1,last=32,height=c.tableHeight})
  for _,x in ipairs{4,7}do for y=4,5 do add('sevenChair',x,y,1,1,{cap=0,last=16,height=c.seatHeight})end end
  for _,y in ipairs{3,6}do add('sevenPlant',0,y,1,2,{cap=4,last=31,height=c.plantHeight,shape='palm'})end
 else
  for _,x in ipairs{0,11}do for _,y in ipairs{2,6}do add('sevenPlant',x,y,1,2,{cap=4,last=31,height=c.plantHeight,shape='broadPlant'})end end
 end
 return{objects=objects,mask=mask,owners={}}
end
function R.actorOffset(d,x,z,gid)
 if R.profile(d)=='home'and gid==35 and math.floor((x+8)/16)==4 and math.floor(z/16)==4 then return cfg().seatHeight,0 end
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local own=R.rooms[L];if not c.enabled or not own then return end
 local P,G=V.require('PaperSprite'),V.require('WorldGeometry');local hs=V.require('Billboard').heightScale()
 local function source(x,y)return L:midAt(math.floor(x/16),math.floor(y/16)),x%16,y%16 end
 local function inside(o,s,t)
  if s<0 or s>=o.w*16 or t<o.cap or t>=o.last then return false end
  if o.shape then return V.require('InteriorHouseVariants').sourceInside(o,s,t)end
  if o.kind=='sevenBoxes'then return s>=1 and s<16 end
  if o.kind=='sevenTable'then
   if t==1 then return s>=2 and s<30 end
   if t<28 then return s>=1 and s<31 end
   if t==28 then return s>=3 and s<8 or s>=24 and s<29 end
   if t<31 then return s>=3 and s<7 or s>=25 and s<29 end
   return s>=4 and s<6 or s>=26 and s<28
  end
  if o.kind=='sevenChair'then
   local flip=L:midAt(o.x,o.y)==0x167;local u=flip and 15-s or s
   if t==0 then return u>=3 and u<5 end
   if t<5 then return u>=2 and u<6 end
   if t==5 then return u>=2 and u<13 end
   if t<14 then return u>=2 and u<14 end
   return u>=2 and u<5 or u>=11 and u<14
  end
  return false
 end
 -- Remove the complete baked footprint, including native flat shadows.
 local clear={};for _,o in ipairs(own)do if o.cap then for t=0,o.h*16-1 do for s=0,o.w*16-1 do clear[(o.y*16+t)*192+o.x*16+s]=true end end end end
 local function draw(w,h,src,mask,project)
  local vv=P.build(ts,w,h,src,mask,0,h,1,nil,project,.5);for _,v in ipairs(vv)do out[#out+1]=v end
 end
 for _,o in ipairs(own)do local x,z=(o.x+ox)*16,(o.y+oz)*16;local first=#out+1
  local function src(s,t)return source(o.x*16+s,o.y*16+t)end
  local function band(a,b,project)
   draw(o.w*16,o.h*16,src,function(s,t)return t>=a and t<b and inside(o,s,t)end,project)
  end
  if o.kind=='sevenWall'then
   draw(o.w*16,32,function(s,t)
    if o.family=='home'then
     if s<32 or s>=144 then return source(40,t)end
     if s>=48 and s<96 and t>=16 and L:midAt(math.floor(s/16),1)==0x181 then
      -- The visible native door lintel provides its jamb/inside texels;
      -- boxes own the lower drawing and remain in front of this doorway.
      if s>=60 and s<84 then return source(s,15)end
      return source(40,t)
     end
    end
    return source(s,t)
   end,function()return true end,function(s,t)return{x+s,c.wallHeight*hs*(32-t)/32,z+32}end)
  elseif o.kind=='sevenFloor'then
   draw(o.w*16,o.h*16,function(s,t)local xx,yy=s,t+32;if clear[yy*192+xx]then return (xx<16 or yy<48)and 0x111 or 0x109,xx%16,yy%16 end;return source(xx,yy)end,function()return true end,function(s,t)return{x+s,0,z+t}end)
  elseif o.kind=='sevenExit'then
   draw(48,16,src,function()return true end,function(s,t)return{x+s,0,z+t}end)
  elseif o.kind=='sevenTable'then
   band(1,26,function(s,t)return{x+s,c.tableHeight,z+(t-1)*c.tableDepth/25}end)
   band(26,28,function(s,t)return{x+s,c.tableHeight-(t-26)*c.tableRim/2,z+c.tableDepth}end)
   band(28,32,function(s,t)return{x+s,(32-t)*(c.tableHeight-c.tableRim)/4,z+c.tableDepth}end)
  elseif o.kind=='sevenBoxes'then
   band(0,8,function(s,t)return{x+s,c.boxHeight,z+24-c.boxDepth+t*c.boxDepth/8}end)
   band(8,24,function(s,t)return{x+s,c.boxHeight*(24-t)/16,z+24}end)
   for _,sx in ipairs{1,15}do local m,u,v=src(sx,12);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local xx=x+(sx==15 and 16 or sx)
    G.quad(out,{xx,c.boxHeight,z+24-c.boxDepth},{xx,c.boxHeight,z+24},{xx,0,z+24},{xx,0,z+24-c.boxDepth},uv,c.sideShade)
   end
  elseif o.kind=='sevenChair'then
   band(0,16,function(s,t)return{x+s,(16-t)*c.chairHeight/16*hs,z+15}end)
  else
   band(o.cap,o.last,function(s,t)return{x+s,o.height*hs*(o.last-t)/(o.last-o.cap),z+o.last}end)
  end
  if o.cap then contacts[#contacts+1]={x+o.w*8,z+(o.kind=='sevenTable'and c.tableDepth or o.kind=='sevenChair'and 15 or o.last),o.w*6,c.contactRadius,c.contactStrength}end
  local kind=o.kind=='sevenWall'and 'wall'or(o.kind=='sevenFloor'or o.kind=='sevenExit')and 'card'or o.kind=='sevenPlant'and 'plant'or o.kind=='sevenTable'and 'table'or o.kind=='sevenChair'and 'chair'or o.kind
  V.require('RoomLightRig').capture(L,{kind=kind},out,first,#out)
 end
end
function R.lighting(d)
 local family=R.profile(d);if not family then return end;local c=cfg();local sources={}
 for _,a in ipairs(c.sources[family])do sources[#sources+1]={at={a[1]*16,c.lightHeight,a[2]*16},radius=a[4],power=a[3],color=c.lampColor,spread=c.spread}end
 return{fixed=true,ambient=c.ambient,sources=sources}
end
return R
