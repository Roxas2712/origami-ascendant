-- Measured Silph furniture, using the original atlas and unchanged map cells.
local V=...;local S={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.silphFurniture end
local supported={silphDrawingDesk=true,silphWorkDesk=true,silphSofa=true,silphStool=true,silphExecutiveTable=true,silphGlassTable=true,silphBlueBench=true,silphLoungeSeat=true,silphBeds=true}
function S.profile(def)
 return cfg().enabled and def.mapType==8 and (def.renderPair or def.pair)=='building__rom_082d4ecc'
  and (def.id or def.name or ''):match('^FR_SILPH_CO_%d+F$') and def.midLayout
end
function S.plan(def,objects,mask)
 local L=def.midLayout;if L then S.rooms[L]=nil end
 if not S.profile(def)then return end
 local owned={};S.rooms[L]=owned
 local function add(kind,x,y,w,h)
  local o={kind=kind,x=x,y=y,w=w*16,h=h*16};objects[#objects+1]=o;owned[#owned+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=0x334,separateSurface=true}end end
  -- Only the baked shadows touching this measured drawing are replaced.
  for yy=y,y+h do if x+w<L.width and yy<L.height then
   local m=L:midAt(x+w,yy)
   if m==0x336 or m==0x357 then mask[yy*L.width+x+w+1]={mid=0x334,separateSurface=true}end
  end end
  return o
 end
 local function rectangle(x,y,top,center,last,maxH)
  local w=2;while x+w-1<L.width and L:midAt(x+w-1,y)==top[2]do w=w+1 end
  if x+w>L.width or L:midAt(x+w-1,y)~=top[3]then return end
  local h=2
  while y+h-1<L.height and h<=maxH do
   local yy=y+h-1
   if L:midAt(x,yy)==last[1]then
    for dx=1,w-2 do if L:midAt(x+dx,yy)~=last[2]then return end end
    if L:midAt(x+w-1,yy)~=last[3]then return end
    return w,h
   end
   for dx=0,w-1 do
    local allowed=center[dx==0 and 1 or dx==w-1 and 3 or 2]
    if not allowed[L:midAt(x+dx,yy)]then return end
   end
   h=h+1
  end
 end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if type(mask[y*L.width+x+1])=="table"and mask[y*L.width+x+1].silphCounter then
   -- Claimed by a complete non-rectangular work surface.
  elseif m==0x36d then
   local w,h=rectangle(x,y,{0x36d,0x36e,0x36f},
    {{[0x323]=true,[0x391]=true},{[0x324]=true,[0x31c]=true,[0x388]=true},{[0x325]=true,[0x31d]=true,[0x389]=true}},
    {0x375,0x376,0x377},8)
   if w then add('silphDrawingDesk',x,y,w,h)end
  elseif m==0x378 then
   local w,h=rectangle(x,y,{0x378,0x379,0x37a},
    {{[0x2b8]=true,[0x2bb]=true,[0x2c3]=true},{[0x2b9]=true},{[0x2ba]=true,[0x2c4]=true}},
    {0x380,0x381,0x382},12)
   if w then
    local complete=true
    for dy=1,h-2 do local left=L:midAt(x,y+dy)
     if left==0x2bb and L:midAt(x,y+dy+1)~=0x2c3 then complete=false end
     if left==0x2c3 and L:midAt(x,y+dy-1)~=0x2bb then complete=false end
    end
    if complete then add('silphWorkDesk',x,y,w,h)end
   end
  elseif cfg().beds.enabled and m==0x399 and x+4<L.width and y+1<L.height then
   -- Both native beds share a five-tile drawing; the middle tile contains
   -- the edge of each. Never cut it into two incomplete two-tile sprites.
   local rows={{0x399,0x39a,0x39b,0x39c,0x3ba},{0x3a1,0x3a2,0x3a3,0x3a4,0x3bb}}
   local ok=true;for dy,row in ipairs(rows)do for dx,id in ipairs(row)do if L:midAt(x+dx-1,y+dy-1)~=id then ok=false end end end
   if ok then add('silphBeds',x,y,5,2)end
  elseif cfg().lounge.enabled and (m==0x345 or m==0x34a)then add('silphLoungeSeat',x,y,1,1)
  elseif cfg().lounge.enabled and (m==0x343 or m==0x362)and x+1<L.width and y+1<L.height then
   local glass=m==0x343
   local r,b,br=glass and 0x344 or 0x363,glass and 0x34b or 0x36a,glass and 0x34c or 0x36b
   if L:midAt(x+1,y)==r and L:midAt(x,y+1)==b and L:midAt(x+1,y+1)==br then
    add(glass and 'silphGlassTable'or'silphBlueBench',x,y,2,2)
    -- Replace only the complete native baked-shadow strip of this object.
    if y+2<L.height and x+2<L.width and L:midAt(x,y+2)==0x33d and L:midAt(x+1,y+2)==0x33b and L:midAt(x+2,y+2)==0x33c then
     for dx=0,2 do mask[(y+2)*L.width+x+dx+1]={mid=0x334,separateSurface=true}end
    end
   elseif not glass and x+2==L.width and L:midAt(x,y+1)==0x36a and L:midAt(x+1,y)==8 and L:midAt(x+1,y+1)==8 then
    -- Native 7F ends with one seat half against the map's void border.
    -- Keep the authored half; never synthesize its missing neighbour.
    add('silphBlueBench',x,y,1,2)
   end
  elseif m==0x386 or m==0x312 then add('silphStool',x,y,1,1)
  elseif m==0x39d and x+2<L.width and y+1<L.height then
   if L:midAt(x+1,y)==0x39e and L:midAt(x+2,y)==0x39f and L:midAt(x,y+1)==0x328
    and L:midAt(x+1,y+1)==0x329 and L:midAt(x+2,y+1)==0x32a then add('silphSofa',x,y,3,2)end
  elseif m==0x3a5 and x+4<L.width and y+3<L.height then
   local rows={{0x3a5,0x3a6,0x3a6,0x3a6,0x3a7},{0x3ad,0x3b6,0x3ae,0x3b6,0x3af},
    {0x3b5,0x3b6,0x3a8,0x3b6,0x3b7},{0x3bd,0x3be,0x3be,0x3be,0x3bf}}
   local ok=true;for dy,row in ipairs(rows)do for dx,mid in ipairs(row)do if L:midAt(x+dx-1,y+dy-1)~=mid then ok=false end end end
   if ok then add('silphExecutiveTable',x,y,5,4)end
  end
 end end
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local function flood(w,h,clear)
 local empty,queue={},{}
 local function seed(x,y)local k=y*w+x;if clear[k]and not empty[k]then empty[k]=true;queue[#queue+1]=k end end
 for x=0,w-1 do seed(x,0);seed(x,h-1)end;for y=0,h-1 do seed(0,y);seed(w-1,y)end
 local i=1;while queue[i]do local k=queue[i];i=i+1;local x,y=k%w,math.floor(k/w)
  if x>0 then seed(x-1,y)end;if x<w-1 then seed(x+1,y)end
  if y>0 then seed(x,y-1)end;if y<h-1 then seed(x,y+1)end
 end
 return function(x,y)return x>=0 and y>=0 and x<w and y<h and not empty[y*w+x]end
end
function S.build(out,objects,L,ts,ox,oz,contacts)
 local relevant=false
 for _,o in ipairs(objects)do if supported[o.kind]then relevant=true;break end end
 if not cfg().enabled or not relevant then return end
 local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local c=cfg()
 local bg={};for _,m in ipairs({0x334,0x335,0x336})do for y=0,15 do for x=0,15 do bg[rgb(B.pixel(ts,m,x,y))]=true end end end
 for _,o in ipairs(objects)do if supported[o.kind]then
  local x,z=(o.x+ox)*16,(o.y+oz)*16
  local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local clear={};for t=0,o.h-1 do for s=0,o.w-1 do local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v);clear[t*o.w+s]=a<.5 or bg[rgb(r,g,b)]end end
  local inside=flood(o.w,o.h,clear)
  local function band(a,b,project,filter,src)
   local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and inside(s,t)and(not filter or filter(s,t))end,0,o.h,1,nil,project,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
  end
  local function contact(front)
   for sx=5,o.w-3,8 do contacts[#contacts+1]={x+sx,z+front,5,c.contactRadius,c.contactStrength}end
  end
  if o.kind=='silphDrawingDesk'or o.kind=='silphWorkDesk'then
   local front=o.h-16;local top=o.kind=='silphDrawingDesk'and 3 or 12
   local function tabletop(s,t)
    local m,u,v=source(s,t)
    if m==0x2c4 then m=0x2ba elseif m==0x2bb or m==0x2c3 then m=0x2b8 elseif m==0x391 then m=0x323 end
    return m,u,v
   end
   band(top,front,function(s,t)return{x+s,c.deskHeight,z+t}end,nil,tabletop)
   band(front,o.h-8,function(s,t)return{x+s,c.deskHeight*(o.h-8-t)/8,z+front}end)
   -- Devices get their own upright source mask. Compare each pixel with
   -- its exact uncovered table donor, flood only from the perimeter.
   do for dy=1,o.h/16-2 do for dx=0,o.w/16-1 do
    local m=L:midAt(o.x+dx,o.y+dy)
    if m==0x2c4 or m==0x2bb or m==0x391 then
     local h=m==0x2bb and 32 or 16;local donor=m==0x2bb and 0x2b8 or m==0x391 and 0x323 or 0x2ba
     local function src(s,t)return L:midAt(o.x+dx,o.y+dy+math.floor(t/16)),s,t%16 end
     local empty={};for t=0,h-1 do for s=0,15 do
      local sm,u,v=src(s,t);local r,g,b,a=B.pixel(ts,sm,u,v)
      empty[t*16+s]=a<.5 or rgb(r,g,b)==rgb(B.pixel(ts,donor,u,v))
     end end
     local cut=flood(16,h,empty);local bottom=m==0x2bb and 29 or 16
     local vv=V.require('PaperSprite').build(ts,16,h,src,function(s,t)return t<bottom and cut(s,t)end,0,h,1,nil,
      function(s,t)return{x+dx*16+s,c.deskHeight+(bottom-t)*c.deviceScale,z+dy*16+bottom}end,.5)
     for _,v in ipairs(vv)do out[#out+1]=v end
    end
   end end end
   contact(front)
  elseif o.kind=='silphBeds'then
   local b=c.beds
   band(0,4,function(s,t)return{x+s,b.height+(4-t)*b.headScale,z+4}end)
   band(4,27,function(s,t)return{x+s,b.height,z+t}end)
   band(27,32,function(s,t)return{x+s,b.height*(32-t)/5,z+27}end)
   -- Close only each mattress's pixel contour, leaving the aisle intact.
   for t=4,26 do for s=0,o.w-1 do if inside(s,t)then
    local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
    if not inside(s-1,t)then G.quad(out,{x+s,b.height,z+t},{x+s,b.height,z+t+1},{x+s,0,z+t+1},{x+s,0,z+t},uv,b.sideShade)end
    if not inside(s+1,t)then G.quad(out,{x+s+1,b.height,z+t+1},{x+s+1,b.height,z+t},{x+s+1,0,z+t},{x+s+1,0,z+t+1},uv,b.sideShade)end
   end end end
   for _,cx in ipairs({25,57})do contacts[#contacts+1]={x+cx,z+27,10,c.contactRadius,c.contactStrength}end
  elseif o.kind=='silphGlassTable'then
   local l=c.lounge
   band(0,26,function(s,t)return{x+s,l.tableHeight,z+t*l.tableDepth/26}end)
   band(26,29,function(s,t)return{x+s,l.tableHeight-(t-26)*l.tableRimHeight/3,z+l.tableDepth}end)
   band(29,32,function(s,t)return{x+s,(32-t)*(l.tableHeight-l.tableRimHeight)/3,z+l.tableDepth}end)
   contact(l.tableDepth)
  elseif o.kind=='silphLoungeSeat'then
   local l=c.lounge
   band(0,12,function(s,t)return{x+s,l.seatHeight,z+t}end)
   band(12,16,function(s,t)return{x+s,l.seatHeight*(16-t)/4,z+12}end);contact(12)
  elseif o.kind=='silphBlueBench'then
   local l=c.lounge;local scale=l.backScale*V.require('Billboard').heightScale()
   -- The two central back strips stand; the flanking cushions lie flat.
   band(0,25,function(s,t)return{x+s,l.seatHeight+(25-t)*scale,z+25}end,function(s)return s>=11 and s<21 end)
   band(0,25,function(s,t)return{x+s,l.seatHeight,z+t}end,function(s)return s<11 or s>=21 end)
   band(25,32,function(s,t)return{x+s,l.seatHeight*(32-t)/7,z+25}end);contact(25)
  elseif o.kind=='silphStool'then
   band(0,9,function(s,t)return{x+s,c.seatHeight,z+5+t}end)
   band(9,16,function(s,t)return{x+s,c.seatHeight*(16-t)/7,z+14}end);contact(14)
  elseif o.kind=='silphSofa'then
   band(9,20,function(s,t)return{x+s,c.seatHeight+(20-t)*(c.sofaHeight-c.seatHeight)/11,z+20}end)
   band(20,27,function(s,t)return{x+s,c.seatHeight,z+t}end)
   band(27,32,function(s,t)return{x+s,c.seatHeight*(32-t)/5,z+27}end);contact(27)
  elseif o.kind=='silphExecutiveTable'then
   local gold={[rgb(247/255,239/255,148/255)]=true,[rgb(222/255,206/255,107/255)]=true,
    [rgb(197/255,181/255,74/255)]=true,[rgb(132/255,115/255,16/255)]=true}
   local edge,last={},{}
   for s=0,79 do for t=0,63 do local m,u,v=source(s,t)
    if gold[rgb(B.pixel(ts,m,u,v))]then edge[s]=t+1 end
    if inside(s,t)then last[s]=t+1 end
   end end
   local function slab(s,t)
    if s>=32 and s<48 and t>=16 and t<37 then return 0x3b6,s%16,t%16 end
    return source(s,t)
   end
   band(0,64,function(s,t)return{x+s,c.executiveHeight,z+t}end,function(s,t)return edge[s]and t<edge[s]end,slab)
   -- The octagonal front is piecewise constant per native pixel column.
   -- A merged horizontal run cannot use the neighbouring column's contour
   -- at its right vertex: that produced stretched wedges at the corners.
   for s=0,79 do local f,b=edge[s],last[s]
    if f and b and b>f then for t=f,b-1 do if inside(s,t)then
     local m,u,v=source(s,t);local h0=c.executiveHeight*(b-t)/(b-f);local h1=c.executiveHeight*(b-t-1)/(b-f)
     G.quad(out,{x+s,h0,z+f},{x+s+1,h0,z+f},{x+s+1,h1,z+f},{x+s,h1,z+f},G.uv(ts,m,u,v,u+1,v+1,.5),1)
    end end end
   end
   band(16,37,function(s,t)return{x+s,c.executiveHeight+(37-t)*c.deviceScale,z+37}end,
    function(s,t)return s>=32 and s<48 and not gold[rgb(B.pixel(ts,source(s,t)))]end)
   contact(54)
  end
 end end
end
function S.actorOffset(def,px,pz,gid)
 if not def or not S.profile(def)then return end
 for _,o in ipairs(S.rooms[def.midLayout]or{})do
  local x,z=px-o.x*16,pz-o.y*16
  -- Native pickup balls placed on a desk belong on its horizontal top.
  -- Move the visual foot to its own tile centre; never move the event,
  -- an NPC/player, or an item on the floor immediately in front of it.
  if gid==92 and (o.kind=='silphDrawingDesk'or o.kind=='silphWorkDesk')then
   local inset=cfg().pickupInset;local top=o.kind=='silphDrawingDesk'and 3 or 12
   if x>=4 and x<o.w-4 and z-inset>=top and z-inset<o.h-16 then
    return cfg().deskHeight,-inset
   end
  end
  if cfg().lounge.enabled and o.kind=='silphLoungeSeat'and x>=0 and x<16 and z>0 and z<=16 then return cfg().lounge.seatHeight,-cfg().lounge.actorInset end
  if o.kind=='silphSofa'and x>=4 and x<o.w-4 and z>=0 and z<=27 then return cfg().seatHeight,math.max(0,27-z)end
 end
end
return S
