-- Cerulean's burgled house: preserve native damage, footprints and debris.
-- Only visual surfaces are separated; the exit through the breach stays native.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.trashedHouse end
function R.profile(d)
 local L=d and d.midLayout
 return cfg().enabled and d and d.id=='FR_CERULEAN_CITY_HOUSE2'and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4fa4'and L and L.width==10 and L.height==10 and L:midAt(0,0)==0xd8 and L:midAt(4,0)==0x283 and cfg()or nil
end
function R.plan(d,objects,mask)
 local L=d.midLayout;if L then R.rooms[L]=nil end;if not R.profile(d)then return end
 local c=cfg();local own={};R.rooms[L]=own
 local function add(kind,x,y,w,h,p)
  p=p or{};p.kind=kind;p.x=x;p.y=y;p.w=w;p.h=h;own[#own+1]=p;objects[#objects+1]=p
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*10+xx+1]={mid=8,void=true,separateSurface=true}end end
 end
 add('trashedWall',0,0,10,2)
 add('trashedFloor',0,2,10,6)
 add('trashedSink',0,0,2,3,{cap=19,last=39,height=c.sinkHeight})
 add('trashedCabinet',2,0,2,3,{cap=12,last=39,height=c.shelfHeight})
 add('trashedDrawer',7,0,1,3,{cap=18,last=40,height=c.drawerHeight})
 add('trashedShelf',8,0,2,3,{cap=11,last=40,height=c.shelfHeight})
 add('trashedTable',3,4,2,2,{cap=0,last=31,height=c.tableHeight})
 for _,p in ipairs{{2,4,false},{5,5,false},{2,5,true},{5,4,true}}do
  add('trashedChair',p[1],p[2],1,1,{cap=0,last=16,height=p[3]and c.fallenHeight or c.seatHeight,fallen=p[3]})
 end
 add('trashedPlant',0,6,1,2,{cap=4,last=31,height=c.plantHeight})
 add('trashedFallenPlant',8,6,2,2,{cap=0,last=32,height=c.fallenHeight})
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local own=R.rooms[L];if not c.enabled or not own then return end
 local P,B=V.require('PaperSprite'),V.require('BuildingMesh');local hs=V.require('Billboard').heightScale()
 local function source(x,y)return L:midAt(math.floor(x/16),math.floor(y/16)),x%16,y%16 end
 local function color(x,y)return rgb(B.pixel(ts,source(x,y)))end
 local wood={};for y=0,15 do for x=0,15 do wood[rgb(B.pixel(ts,0x109,x,y))]=true end end
 local carpet=color(50,60);local shadow=rgb(123/255,123/255,123/255)
 local function inside(o,s,t)
  if s<0 or s>=o.w*16 or t<o.cap or t>=o.last then return false end
  local k=o.kind
  if k=='trashedCabinet'then return s>=1 and s<24
  elseif k=='trashedDrawer'then return s>=1 and s<15
  elseif k=='trashedShelf'then return s>=1 and s<31 and(t~=11 or s<4 or s>=28)
  elseif k=='trashedSink'then return t~=19 or s>=1 and s<31
  elseif k=='trashedPlant'then return V.require('InteriorHouseVariants').sourceInside({w=1,y=6,cap=4,last=31,shape='palm'},s,t)
  end
  local v=color(o.x*16+s,o.y*16+t)
  if k=='trashedFallenPlant'then return not wood[v]and v~=shadow end
  return v~=carpet and v~=shadow
 end
 local function draw(w,h,src,mask,project)
  local vv=P.build(ts,w,h,src,mask,0,h,1,nil,project,.5);for _,v in ipairs(vv)do out[#out+1]=v end
 end
 -- Per-pixel floor ownership avoids rectangular donors over the original
 -- rug border, muddy footprints, fallen books and the damaged cabinet foot.
 local cleared={}
 for _,o in ipairs(own)do if o.cap then for t=o.cap,o.last-1 do for s=0,o.w*16-1 do
  local x,y=o.x*16+s,o.y*16+t
  local rug=o.kind=='trashedTable'or o.kind=='trashedChair'
  if y>=32 and(inside(o,s,t)or rug and color(x,y)==shadow)then cleared[y*160+x]=rug and true or 'wood' end
 end end end end
 for _,o in ipairs(own)do
  local x,z=(o.x+ox)*16,(o.y+oz)*16;local first=#out+1
  local function src(s,t)return source(o.x*16+s,o.y*16+t)end
  if o.kind=='trashedWall'then
   draw(160,32,function(s,t)
    if s<56 or s>=112 then return source(94,t)end
    return source(s,t)
   end,function()return true end,function(s,t)return{x+s,c.wallHeight*hs*(32-t)/32,z+32}end)
  elseif o.kind=='trashedFloor'then
   draw(160,96,function(s,t)
    local y=t+32;local donor=cleared[y*160+s]
    if donor==true then return source(50,60)elseif donor=='wood'then return 0x109,s%16,y%16 end
    return source(s,y)
   end,function()return true end,function(s,t)return{x+s,0,z+t}end)
  else
   local function band(a,b,project,extra)
    draw(o.w*16,o.h*16,src,function(s,t)return t>=a and t<b and inside(o,s,t)and(not extra or extra(s,t))end,project)
   end
   if o.kind=='trashedTable'then
    band(0,24,function(s,t)return{x+s,o.height,z+t}end)
    band(24,26,function(s,t)return{x+s,o.height-c.tableRim*(t-24)/2,z+24}end)
    band(26,31,function(s,t)return{x+s,(o.height-c.tableRim)*(31-t)/5,z+24}end)
   elseif o.kind=='trashedSink'then
    band(19,31,function(s,t)return{x+s,o.height,z+t+8}end)
    band(31,39,function(s,t)return{x+s,o.height*(39-t)/8,z+39}end)
    draw(32,24,src,function(s,t)return s>=9 and s<=12 and t>=16 end,function(s,t)return{x+s,o.height+(24-t)*hs,z+33}end)
   elseif o.kind=='trashedFallenPlant'or o.fallen then
    band(o.cap,o.last,function(s,t)return{x+s,o.height,z+t}end)
   elseif o.kind=='trashedChair'then
    local right=o.x==5
    band(0,12,function(s,t)return{x+s,o.height+(12-t)*hs,z+12}end,function(s)return right and s>=12 or not right and s<4 end)
    band(5,12,function(s,t)return{x+s,o.height,z+t}end,function(s)return right and s<12 or not right and s>=4 end)
    band(12,16,function(s,t)return{x+s,o.height*(16-t)/4,z+12}end)
   else
    band(o.cap,o.last,function(s,t)return{x+s,o.height*hs*(o.last-t)/(o.last-o.cap),z+o.last}end)
   end
   local foot=o.kind=='trashedTable'and 24 or o.kind=='trashedChair'and not o.fallen and 12 or o.last
   contacts[#contacts+1]={x+o.w*8,z+foot,o.w*6,c.contactRadius,c.contactStrength}
  end
  local kind=o.kind=='trashedWall'and 'wall'or o.kind=='trashedFloor'and 'card'or o.kind=='trashedTable'and 'table'or(o.kind=='trashedChair'or o.kind:find('Plant'))and 'plant'or o.kind
  V.require('RoomLightRig').capture(L,{kind=kind},out,first,#out)
 end
end
function R.lighting(d)
 local c=R.profile(d);if not c then return end;local sources={}
 for _,a in ipairs(c.sources)do
  sources[#sources+1]={at={a[1]*16,c.lightHeight,a[2]*16},radius=a[4],power=a[3],nightPower=a[5]and a[3]*c.windowNightScale or a[3],color=a[5]and c.windowColor or c.lampColor,spread=c.spread}
 end
 return{ambient=c.ambient,night=c.nightAmbient,sources=sources}
end
return R
