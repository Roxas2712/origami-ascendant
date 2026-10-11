-- FireRed Trainer Tower upper floors. Preserve native challenge layouts,
-- sign variants, NPCs and warp scripts; only split their rendered surfaces.
local V=...;local T={rooms=setmetatable({},{__mode='k'})}
local up={0x300,0x301,0x302,0x303,0x304,0x305,0x306,0x307,0x309}
local down={0x30a,0x30b,0x30c,0x30d,0x30e,0x30f,0x310,0x311,0x312}
local function cfg()return V.require('DioramaConfig').interiors.trainerTower end
local function same(L,x,y,tiles)
 for i,m in ipairs(tiles)do if L:midAt(x+(i-1)%3,y+math.floor((i-1)/3))~=m then return false end end
 return true
end
function T.profile(d)
 local f=d and tonumber((d.id or d.name or''):match('^FR_TRAINER_TOWER_(%d)F$'));local L=d and d.midLayout
 return cfg().enabled and f and f>=1 and f<=8 and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d5094'
  and L and L.width==18 and L.height==18 and L:midAt(2,4)==0x2e9 and L:midAt(14,4)==0x2e9
  and same(L,2,5,down)and same(L,13,5,up)
end
function T.lighting(d)if T.profile(d)then return cfg().light end end
function T.plan(d,objects,mask)
 local L=d.midLayout;if L then T.rooms[L]=nil end
 if not T.profile(d)then return end
 local owned={};T.rooms[L]=owned
 local function add(kind,x,y,w,h,extra)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w;o.h=h;owned[#owned+1]=o;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=0x2ee,separateSurface=true}end end
  return o
 end
 for k,c in ipairs(L.cells)do
  if c.mid==8 or c.mid==0 then mask[k]={mid=8,void=true,separateSurface=true}end
 end
 for _,x in ipairs{2,3,4,5,13,14,15,16}do
  local sign=x==13 or x==16
  add('towerWall',x,4,1,2,{top=sign and L:midAt(x,4)or 0x2e9,bottom=sign and L:midAt(x,5)or 0x2f1})
  for y=4,5 do mask[y*L.width+x+1]={mid=8,void=true,separateSurface=true}end
 end
 for _,x in ipairs{6,7,11,12}do
  add('towerWall',x,7,1,2,{top=0x2e9,bottom=0x2f1})
  for y=7,8 do mask[y*L.width+x+1]={mid=8,void=true,separateSurface=true}end
 end
 -- Keep the floor-specific numeral/indicator from the live source atlas.
 add('towerDisplay',8,7,3,3)
 for y=7,8 do for x=8,10 do mask[y*L.width+x+1]={mid=8,void=true,separateSurface=true}end end
 for _,x in ipairs{6,12}do
  add('towerJamb',x,6,1,3,{left=x==12})
  for y=4,8 do mask[y*L.width+x+1]={mid=8,void=true,separateSurface=true}end
 end
 add('towerFlight',2,5,3,3,{left=false,down=true})
 add('towerFlight',13,5,3,3,{left=true,down=false})
 for y=5,7 do for _,x0 in ipairs{2,13}do for x=x0,x0+2 do
  mask[y*L.width+x+1]={mid=8,void=true,separateSurface=true}
 end end end
 -- Three overlapping native pillar sprites occupy four cells. Extract each
 -- cap and restore its hidden foot from the terminal drawing in that run.
 for y=0,L.height-4 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if (m==0x38a or m==0x382)and(L:midAt(x,y+1)==0x388 or L:midAt(x,y+1)==0x389)
   and L:midAt(x,y+2)==0x388 and L:midAt(x,y+3)==0x380 then
   for i=0,2 do add('towerPillar',x,y+i,1,2,{baseRow=y+3})end
   -- The upper centre cell belongs to both the display and a pillar cap.
   if m==0x382 then mask[y*L.width+x+1]={mid=0x2ee,separateSurface=true}end
  end
 end end
 -- Remove only baked floor shadows immediately bordering the measured wall
 -- and flights. No remapping of behaviour, collision or elevation is done.
 local shadows={[0x2f6]=true,[0x2f7]=true,[0x2fe]=true,[0x2ff]=true,[0x2ef]=true}
 for k,c in ipairs(L.cells)do if shadows[c.mid]then mask[k]={mid=0x2ee,separateSurface=true}end end
end
function T.actorOffset(d,px,pz)
 if not T.profile(d)then return end
 for _,o in ipairs(T.rooms[d.midLayout]or{})do if o.kind=='towerFlight'then
  local x,z=px+8-o.x*16,pz+16-o.y*16
  if x>=0 and x<48 and z>=16 and z<=48 then
   local n=math.min(7,math.floor(x/6));return(o.left and 8-n or n+1)*cfg().height/8*(o.down and -1 or 1),0
  end
 end end
end
function T.build(out,objects,L,ts,ox,oz,contacts)
 if not T.rooms[L]then return end
 local c=cfg();local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local P=V.require('PaperSprite')
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local bg={};for y=0,15 do for x=0,15 do bg[rgb(B.pixel(ts,0x2ee,x,y))]=true end end
 local function q(a,b,d,e,uv,s)G.quad(out,a,b,d,e,uv,s or 1)end
 for _,o in ipairs(T.rooms[L])do
  local first=#out+1;local x,z=(o.x+ox)*16,(o.y+oz)*16
  local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local function draw(w,h,source,inside,project)
   local vv=P.build(ts,w,h,source,inside,0,h,1,nil,project,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
  end
  if o.kind=='towerFlight'then
   V.require('SilphStairs').build(out,{{kind='silphStairs',x=o.x,y=o.y,left=o.left,down=o.down,stairConfig=c}},L,ts,ox,oz)
  elseif o.kind=='towerWall'then
   draw(16,32,function(s,t)return t<16 and o.top or o.bottom,s,t%16 end,function()return true end,
    function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
   local uv=G.uv(ts,0x2e9,4,0,5,1,.5)
   q({x,c.wallHeight,z+32-c.wallDepth},{x+16,c.wallHeight,z+32-c.wallDepth},{x+16,c.wallHeight,z+32},{x,c.wallHeight,z+32},uv)
  elseif o.kind=='towerJamb'then
   local a,b=o.left and x+8 or x,o.left and x+16 or x+8
   local uv=G.uv(ts,0x2e9,4,0,5,1,.5)
   q({a,c.wallHeight,z},{b,c.wallHeight,z},{b,c.wallHeight,z+48},{a,c.wallHeight,z+48},uv)
   local xx=o.left and b or a
   draw(48,32,function(s,t)return t<16 and 0x2e9 or 0x2f1,s%16,t%16 end,function()return true end,
    function(s,t)return{xx,c.wallHeight*(32-t)/32,z+s}end)
  elseif o.kind=='towerDisplay'then
   draw(48,48,src,function(s,t)return t<44 and not bg[rgb(B.pixel(ts,src(s,t)))]end,
    function(s,t)return{x+s,44-t,z+40}end)
  elseif o.kind=='towerPillar'then
   local function source(s,t)
    if t<3 then return 0x38a,s,13+t end
    return L:midAt(o.x,o.baseRow),s,t-3
   end
   local function inside(s,t)return s>=0 and s<15 and t>=0 and t<19 and not bg[rgb(B.pixel(ts,source(s,t)))]end
   local front=z+26
   draw(16,19,source,function(s,t)return t<9 and inside(s,t)end,function(s,t)return{x+s,c.pillarHeight,z+17+t}end)
   draw(16,19,source,function(s,t)return t>=9 and inside(s,t)end,function(s,t)return{x+s,c.pillarHeight*(19-t)/10,front}end)
   for t=0,8 do for s=0,14 do if inside(s,t)then
    local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
    local a,b=x+s,z+17+t
    if not inside(s-1,t)then q({a,c.pillarHeight,b},{a,c.pillarHeight,b+1},{a,0,b+1},{a,0,b},uv,c.sideShade)end
    if not inside(s+1,t)then q({a+1,c.pillarHeight,b+1},{a+1,c.pillarHeight,b},{a+1,0,b},{a+1,0,b+1},uv,c.sideShade)end
    if t==0 or not inside(s,t-1)then q({a+1,c.pillarHeight,b},{a,c.pillarHeight,b},{a,0,b},{a+1,0,b},uv,c.sideShade)end
   end end end
   contacts[#contacts+1]={x+8,front,6,c.contactRadius,c.contactStrength}
  end
  V.require('RoomLightRig').capture(L,o,out,first,#out)
 end
end
return T
