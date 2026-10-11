-- Native Lavender rescue home: wall, enclosure, furniture and floor are distinct.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.volunteerHouse end
function R.profile(d)
 local L=d and d.midLayout
 if cfg().enabled and d and d.id=='FR_LAVENDER_TOWN_VOLUNTEER_POKEMON_HOUSE'and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4f74'and L and L.width==12 and L.height==10 and L:midAt(0,0)==0x284 and L:midAt(3,0)==0x323 then return cfg()end
end
function R.plan(d,objects,mask)
 local L=d.midLayout;if L then R.rooms[L]=nil end;if not R.profile(d)then return end
 local c=cfg();local own={};R.rooms[L]=own
 local function add(k,x,y,w,h,p)
  p=p or{};p.kind=k;p.x=x;p.y=y;p.w=w;p.h=h;objects[#objects+1]=p;own[#own+1]=p
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*12+xx+1]={mid=8,void=true,separateSurface=true}end end
 end
 add('volunteerWall',0,0,12,2)
 add('volunteerFloor',0,2,12,6)
 add('volunteerSink',1,0,2,3,{cap=19,last=39,height=c.sinkHeight})
 add('volunteerShelf',3,0,2,3,{cap=11,last=40,height=c.shelfHeight})
 add('volunteerPC',5,0,1,3,{cap=12,last=40,height=c.pcHeight})
 add('volunteerTable',5,4,2,2,{cap=0,last=32,height=c.tableHeight})
 for _,x in ipairs{4,7}do for y=4,5 do add('volunteerStool',x,y,1,1,{cap=3,last=16,height=c.stoolHeight})end end
 for _,x in ipairs{0,11}do
  add('volunteerPlanter',x,4,1,2,{cap=1,last=31,height=c.planterHeight})
  add('volunteerPlant',x,6,1,2,{cap=4,last=32,height=c.plantHeight})
 end
 add('volunteerPen',8,1,4,3)
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local own=R.rooms[L];if not c.enabled or not own then return end
 local P,G,B=V.require('PaperSprite'),V.require('WorldGeometry'),V.require('BuildingMesh');local hs=V.require('Billboard').heightScale()
 local function source(x,y)return L:midAt(math.floor(x/16),math.floor(y/16)),x%16,y%16 end
 local bg={};for y=0,15 do for x=0,15 do bg[rgb(B.pixel(ts,0x287,x,y))]=true end end
 local function inside(o,s,t)
  if s<0 or s>=o.w*16 or t<o.cap or t>=o.last then return false end
  if o.kind=='volunteerShelf'then return s>=1 and s<31 and(t~=11 or s<4 or s>=28)
  elseif o.kind=='volunteerPC'then local inset=t<16 and 16-t or t>=38 and 1 or 0;return s>=inset and s<16-inset
  elseif o.kind=='volunteerSink'then return t~=19 or s>=1 and s<31
  elseif o.kind=='volunteerPlant'then
   -- Right-hand source has clean floor around the identical leaf/pot art;
   -- use it as the matte for both plants, excluding the left wall shadow.
   return not bg[rgb(B.pixel(ts,source(176+s,96+t)))]
  end
  return not bg[rgb(B.pixel(ts,source(o.x*16+s,o.y*16+t)))]
 end
 local function draw(w,h,src,mask,project)
  local vv=P.build(ts,w,h,src,mask,0,h,1,nil,project,.5);for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local clear={}
 for _,o in ipairs(own)do if o.cap then for t=o.cap,o.last-1 do for s=0,o.w*16-1 do
  if inside(o,s,t)then clear[(o.y*16+t)*192+o.x*16+s]=true end
 end end end end
 for _,o in ipairs(own)do local x,z=(o.x+ox)*16,(o.y+oz)*16;local first=#out+1
  local function src(s,t)return source(o.x*16+s,o.y*16+t)end
  if o.kind=='volunteerWall'then
   draw(192,30,function(s,t)
    if s>=16 and s<96 or s>=136 and s<148 then return source(152,t)end
    return source(s,t)
   end,function()return true end,function(s,t)return{x+s,c.wallHeight*hs*(30-t)/30,z+32}end)
  elseif o.kind=='volunteerFloor'then
   draw(192,96,function(s,t)
    local y=t+32
    -- Pen turf is an independent floor. Its original low rim is drawn below.
    if s>=136 and y<64 then
     return (s>=144 and y<56)and 0x2ee or 0x287,s%16,y%16
    end
    if clear[y*192+s]or y<40 and s<7 then return 0x287,s%16,y%16 end
    return source(s,y)
   end,function()return true end,function(s,t)return{x+s,0,z+t}end)
  elseif o.kind=='volunteerPen'then
   local h=c.penRailHeight;local top=G.uv(ts,0x2f6,11,9,12,10,.5);local side=G.uv(ts,0x2f6,13,12,14,13,.5)
   local function prism(xx,zz,w,d)
    G.quad(out,{xx,h,zz},{xx+w,h,zz},{xx+w,h,zz+d},{xx,h,zz+d},top,1)
    G.quad(out,{xx,h,zz+d},{xx+w,h,zz+d},{xx+w,0,zz+d},{xx,0,zz+d},side,1)
    G.quad(out,{xx,h,zz},{xx,h,zz+d},{xx,0,zz+d},{xx,0,zz},side,c.sideShade)
    G.quad(out,{xx+w,h,zz+d},{xx+w,h,zz},{xx+w,0,zz},{xx+w,0,zz+d},side,c.sideShade)
   end
   prism(x+10,z+16,3,26);prism(x+10,z+40,8,4)
   prism(x+46,z+40,18,4)
   draw(18,8,function(s,t)return source(174+s,52+t)end,function()return true end,
    function(s,t)return{x+46+s,h*(8-t)/8,z+44.02}end)
  else
   local function band(a,b,project,extra)
    draw(o.w*16,o.h*16,src,function(s,t)return t>=a and t<b and inside(o,s,t)and(not extra or extra(s,t))end,project)
   end
   local foot=o.last
   if o.kind=='volunteerSink'then
    band(19,31,function(s,t)return{x+s,o.height,z+t+8}end)
    band(31,39,function(s,t)return{x+s,o.height*(39-t)/8,z+39}end)
    draw(32,24,src,function(s,t)return s>=9 and s<=12 and t>=16 end,function(s,t)return{x+s,o.height+(24-t)*hs,z+33}end)
   elseif o.kind=='volunteerTable'or o.kind=='volunteerStool'or o.kind=='volunteerPlanter'then
    local split=o.kind=='volunteerTable'and 27 or o.kind=='volunteerStool'and 13 or 26
    foot=split
    band(o.cap,split,function(s,t)return{x+s,o.height,z+t}end)
    band(split,o.last,function(s,t)return{x+s,o.height*(o.last-t)/(o.last-split),z+split}end)
   else
    band(o.cap,o.last,function(s,t)return{x+s,o.height*hs*(o.last-t)/(o.last-o.cap),z+o.last}end)
   end
   contacts[#contacts+1]={x+o.w*8,z+foot,o.w*6,c.contactRadius,c.contactStrength}
  end
  local k=o.kind=='volunteerWall'and 'wall'or o.kind=='volunteerFloor'and 'card'or o.kind=='volunteerTable'and 'table'or(o.kind:find('Plant')or o.kind=='volunteerStool')and 'plant'or o.kind
  V.require('RoomLightRig').capture(L,{kind=k},out,first,#out)
 end
end
function R.lighting(d)
 local c=R.profile(d);if not c then return end;local sources={}
 for _,a in ipairs(c.sources)do sources[#sources+1]={at={a[1]*16,c.lightHeight,a[2]*16},radius=a[4],power=a[3],nightPower=a[5]and a[3]*c.windowNightScale or a[3],color=a[5]and c.windowColor or c.lampColor,spread=c.spread}end
 return{ambient=c.ambient,night=c.nightAmbient,sources=sources}
end
return R
