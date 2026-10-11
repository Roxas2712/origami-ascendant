-- Native FireRed game corners: continuous walls and separately folded objects.
local V=...;local C={}
local specs={
 FR_CELADON_CITY_GAME_CORNER={width=18,height=16,wall=18,floor=0x291,anchor={5,5,0x2a8},mode='casino'},
 FR_CELADON_CITY_GAME_CORNER_PRIZE_ROOM={width=10,height=10,wall=9,floor=0x291,anchor={4,2,0x29c},mode='prize'},
 FR_TWO_ISLAND_JOYFUL_GAME_CORNER={width=12,height=10,wall=12,floor=0x2e0,anchor={8,5,0x30d},mode='joyful'},
}
local function config()return V.require('DioramaConfig').interiors.casinoSurfaces end
function C.profile(d)
 local c=config();local L=d and d.midLayout;local p=d and specs[d.id or d.name]
 if c.enabled and p and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4cec' and L
  and L.width==p.width and L.height==p.height and L:midAt(unpack(p.anchor,1,2))==p.anchor[3]
  and L:midAt(0,0)==(p.mode=='joyful'and 0x2fd or 0x281)then return c.rooms[p.mode],p end
end
function C.lighting(d)local p=C.profile(d);return p and p.light end
function C.stairsOpen(d)
 local _,scope=C.profile(d);if not scope or scope.mode~='casino'then return false end
 local L=d.midLayout
 for i,m in ipairs{0x29d,0x29e,0x29f}do if L:midAt(14+i,2)~=m then return false end end
 return L:midAt(16,3)==0x2a6 and L:midAt(17,3)==0x2a7
end
function C.recesses(d)return C.stairsOpen(d)and{{240,34,288,48}}or{}end
function C.actorHeight(d,px,pz)
 if not C.stairsOpen(d)then return end
 local x,z=px+8,pz+16
 if x>=240 and x<288 and z>=34 and z<=48 then
  return -math.floor((x-240)/6)*config().stairHeight/8*V.require('DioramaConfig').interiors.heightScale
 end
end
function C.plan(d)
 local p,s=C.profile(d);if not p then return end
 local L=d.midLayout;local objects,mask,owners={},{},{}
 local function add(kind,x,y,w,h,extra)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w;o.h=h;o.mode=s.mode;o.floor=s.floor
  o.front=o.front or h*16;o.noContact=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;mask[k]=s.floor;owners[k]=o end end
  return o
 end
 add('casinoWall',0,0,s.wall,2)
 local function cabinet(x,y)add('casinoCabinet',x,y,2,3,{last=40})end
 local function plant(x,y)add('casinoPlant',x,y,1,2)end
 if s.mode=='joyful'then
  add('casinoCounter',2,1,7,3)
  add('casinoPC',10,0,1,3,{last=47})
  plant(11,1);plant(0,7);plant(11,7)
  add('casinoTable',8,5,2,2)
  add('casinoSofa',11,5,1,2)
 else
  local x=s.mode=='prize'and 0 or 1
  add('casinoCounter',x,1,9,3)
  cabinet(x+1,0);cabinet(x+6,0)
  if s.mode=='prize'then cabinet(0,5);cabinet(7,5)
  else
   plant(0,1);plant(0,12)
   add('casinoStairs',15,2,3,2,{open=C.stairsOpen(d)})
   add('casinoPartition',14,3,4,2)
   if C.stairsOpen(d)then for x=15,17 do mask[2*L.width+x+1]={mid=8,void=true}end end
   add('casinoBin',17,12,1,2)
   for _,b in ipairs{{0,1,'right'},{5,2},{11,2},{17,1,'left'}}do
    add('casinoBank',b[1],5,b[2],6,{half=b[3]})
   end
   for _,x0 in ipairs{1,4,7,10,13,16}do for y=6,10 do
    add('casinoSeat',x0,y,1,1,{right=x0==1 or x0==7 or x0==13})
   end end
  end
 end
 -- Void is never a black floor plate. Original door rugs remain ground art.
 for i,cell in ipairs(L.cells)do if cell.mid==0 or cell.mid==8 then mask[i]={mid=8,void=true}end end
 for y=0,1 do for x=0,s.wall-1 do mask[y*L.width+x+1]={mid=8,void=true}end end
 for y=0,L.height-1 do for x=0,L.width-1 do if L:midAt(x,y)==0x1a then
  add('casinoExit',x,y,3,1);for xx=x,x+2 do mask[y*L.width+xx+1]={mid=8,void=true}end
 end end end
 return{objects=objects,mask=mask,owners=owners}
end
-- Only the native main casino's partition; other casino rooms are excluded.
function C.sections(d,px,pz)
 local _,scope=C.profile(d);if not scope or scope.mode~='casino'then return {}end
 local c=config();local a=c.cutaway;local scale=V.require('DioramaConfig').interiors.heightScale
 local function smooth(lo,hi,x)local t=math.max(0,math.min(1,(x-lo)/(hi-lo)));return t*t*(3-2*t)end
 local front=3*16+13;local x0,x1=14*16,18*16
 local amount=(1-smooth(0,a.sideMargin,math.max(x0-px,px-x1,0)))
  *smooth(-a.behindMargin,0,front-pz)*(1-smooth(a.nearDistance,a.farDistance,front-pz))
 if not a.enabled or V.require('Camera').projection()~='perspective'then amount=0 end
 return {{x0,x1,front,(c.partitionHeight+(a.height-c.partitionHeight)*amount)*scale}}
end
function C.build(api,out,L,ts,o,x,z)
 local c=config();local G=V.require('WorldGeometry');local BM=V.require('BuildingMesh')
 local w,h=o.w*16,o.h*16
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(inside,project,src,hh,shade)
  local vv=V.require('PaperSprite').build(ts,w,hh or h,src or source,inside,0,hh or h,1,shade,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function all()return true end
 local floor=o.mode=='joyful'and{0x2e0}or{0x291,0x290}
 local function masked(extra)
  local bg={};for _,m in ipairs(floor)do bg[#bg+1]=m end
  return api.nativeMask(L,ts,o,w,h,bg,extra and(o.mode=='joyful'and{{0x2e7,8,2},{0x2e7,8,12}}or{{0x289,8,2},{0x289,8,12}})or{})
 end
 local function plane(s,t)return{x+s,0,z+t}end
 local function floorBackground(inside)
  draw(function(s,t)return z+t>=30 and not inside(s,t)end,function(s,t)return{x+s,.02,z+t}end)
 end
 local function edge(s,t)local m,u,v=source(s,t);return G.uv(ts,m,u,v,u+1,v+1,.5)end
 if o.kind=='casinoWall'then
  local function wallSource(s,t)
   local col=math.floor(s/16);local clear
   if o.mode=='joyful'then clear=col>=10 or ((col==2 or col==8)and t>=20)
   else local x0=o.mode=='prize'and 0 or 1;clear=col==x0+1 or col==x0+2 or col==x0+6 or col==x0+7 or (col==0 and o.mode=='casino')
    if (col==x0 or col==x0+8)and t>=24 then clear=true end
   end
   if clear then
    if o.mode=='joyful'then return t<16 and 0x2e6 or 0x2e7,s%16,t%16 end
    return t<16 and 0x281 or 0x289,s%16,t%16
   end
   return source(s,t)
  end
  draw(all,function(s,t)return{x+s,c.wallHeight*(30-t)/30,z+30}end,wallSource,30)
  draw(function(s,t)return t>=30 end,plane,function(s,t)return o.floor,s%16,t%16 end)
 elseif o.kind=='casinoExit'then
  draw(function(s,t)local r,g,b,a=BM.pixel(ts,source(s,t));return a>.5 and r+g+b>0 end,plane)
 elseif o.kind=='casinoCounter'then
  local src,inside=masked();local joy=o.mode=='joyful';local split=joy and 42 or 39;local last=joy and 48 or 48
  local function keep(s,t)return t>= (joy and 4 or 8) and (s<16 or s>=w-16 or t>= (joy and 28 or 28))and inside(s,t)end
  floorBackground(inside)
  draw(function(s,t)return keep(s,t)and t<split end,function(s,t)return{x+s,c.counterHeight,z+t}end,src)
  draw(function(s,t)return keep(s,t)and t>=split end,function(s,t)return{x+s,c.counterHeight*(last-t)/(last-split),z+split}end,src)
  local uv=edge(3,32)
  for _,sx in ipairs{0,16,w-16,w}do G.quad(out,{x+sx,c.counterHeight,z+10},{x+sx,c.counterHeight,z+split},{x+sx,0,z+split},{x+sx,0,z+10},uv,c.sideShade)end
 elseif o.kind=='casinoCabinet'or o.kind=='casinoPC'then
  local pc=o.kind=='casinoPC';local src,inside=masked(true)
  if pc then inside=function(s,t)local inset=t<11 and 11-t or t>=45 and 1 or 0;return t>=7 and t<47 and s>=inset and s<16-inset end end
  local first=pc and 7 or (o.y==0 and 8 or 0);local last=pc and 47 or 40;local split=pc and 13 or first+3
  if not pc then
   -- Only the sky-blue wall field is background above the cabinet. Its
   -- white/grey frame and blue glass are native cabinet colours too.
   local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
   local bg={};for yy=8,15 do for xx=0,15 do bg[rgb(BM.pixel(ts,0x281,xx,yy))]=true end end
   for yy=0,12 do for xx=0,15 do bg[rgb(BM.pixel(ts,0x289,xx,yy))]=true end end
   for yy=0,15 do for xx=0,15 do bg[rgb(BM.pixel(ts,o.floor,xx,yy))]=true end end
   local tops={}
   for sx=0,w-1 do for sy=first,last-1 do
    if not bg[rgb(BM.pixel(ts,source(sx,sy)))]then tops[sx]=sy;break end
   end end
   inside=function(s,t)return tops[s]and t>=tops[s]and t<last end
  end
  local function keep(s,t)return t>=first and t<last and inside(s,t)end
  floorBackground(inside)
  draw(function(s,t)return keep(s,t)and t<split end,function(s,t)return{x+s,c.cabinetHeight,z+last-c.cabinetDepth+(t-first)*c.cabinetDepth/(split-first)}end,src)
  draw(function(s,t)return keep(s,t)and t>=split end,function(s,t)return{x+s,c.cabinetHeight*(last-t)/(last-split),z+last}end,src)
  for _,sx in ipairs{0,w}do G.quad(out,{x+sx,c.cabinetHeight,z+last-c.cabinetDepth},{x+sx,c.cabinetHeight,z+last},{x+sx,0,z+last},{x+sx,0,z+last-c.cabinetDepth},edge(sx==0 and 1 or w-2,last-8),c.sideShade)end
 elseif o.kind=='casinoPlant'then
  local src,inside=masked(true);floorBackground(inside)
  draw(inside,function(s,t)return{x+s,(32-t)*c.plantHeight/32,z+31}end,src)
 elseif o.kind=='casinoSeat'then
  local src,inside=masked();floorBackground(inside)
  local cut=o.right and 12 or 4
  local function project(s,t,H)
   if t<12 then return{x+s,H,z+t}end
   return{x+s,H*(16-t)/4,z+12}
  end
  draw(function(s,t)return inside(s,t)and s<cut end,function(s,t)return project(s,t,o.right and c.seatHeight or c.seatBackHeight)end,src)
  draw(function(s,t)return inside(s,t)and s>=cut end,function(s,t)return project(s,t,o.right and c.seatBackHeight or c.seatHeight)end,src)
  G.quad(out,{x+cut,c.seatBackHeight,z+2},{x+cut,c.seatBackHeight,z+12},{x+cut,c.seatHeight,z+12},{x+cut,c.seatHeight,z+2},edge(cut,6),1)
 elseif o.kind=='casinoBank'then
  local src,inside=masked();floorBackground(inside)
  -- Source side panels face into the aisles; the central orange crown is a top.
  local function full(s)return s+(o.half=='right'and 16 or 0)end
  local function pos(s,t)
   local a=full(s);local height=c.bankHeight
   local xx=s
   if a<7 then height=height*a/7;xx=7-(o.half=='right'and 16 or 0)
   elseif a>25 then height=height*(32-a)/7;xx=25-(o.half=='right'and 16 or 0)end
   local zz=t
   if t>=88 then height=height*(96-t)/8;zz=88 end
   return{x+xx,height,z+zz}
  end
  for _,bounds in ipairs{{0,7},{7,25},{25,32}}do
   draw(function(s,t)return inside(s,t)and full(s)>=bounds[1]and full(s)<bounds[2]end,pos,src)
  end
  -- Close the north crown contour with its native edge colour.
  for sy=0,15 do for sx=0,w-1 do
   if inside(sx,sy)and full(sx)>=7 and full(sx)<25 and(sy==0 or not inside(sx,sy-1))then
    local a,b=pos(sx,sy),pos(sx+1,sy)
    G.quad(out,a,b,{b[1],0,b[3]},{a[1],0,a[3]},edge(sx,sy),c.sideShade)
   end
  end end
 elseif o.kind=='casinoPartition'then
  local src,inside=masked();floorBackground(inside)
  local front=z+13;local back=z+3;local anchor=x+w/2
  -- Reuse the opaque gate cutaway tags: the crown keeps its depth while
  -- front, back and end faces meet the lowered cap without transparency.
  draw(function(s,t)return t>=3 and inside(s,t)end,function(s,t)
   if t<13 then return{x+s,c.partitionHeight,z+t,anchor,front,0}end
   return{x+s,c.partitionHeight*(32-t)/19,front,anchor,front,0}
  end,src,nil,function(_,t)return t<13 and 14 or 13 end)
  draw(function(s,t)return t>=13 and inside(s,t)end,function(s,t)
   return{x+s,c.partitionHeight*(32-t)/19,back,anchor,front,0}
  end,src,nil,function()return 13 end)
  for _,sx in ipairs{0,w}do for t=13,31 do
   local hi,lo=c.partitionHeight*(32-t)/19,c.partitionHeight*(31-t)/19
   G.quad(out,{x+sx,hi,back,anchor,front,0},{x+sx,hi,front,anchor,front,0},
    {x+sx,lo,front,anchor,front,0},{x+sx,lo,back,anchor,front,0},edge(sx==0 and 0 or w-1,t),13)
  end end
 elseif o.kind=='casinoStairs'then
  if not o.open then draw(function(_,t)return t<16 end,plane);return end
  -- The native downward flight enters on its left. Replace only its measured
  -- floor opening; source palette colours retain the purple treads and nosings.
  local back,front=z+2,z+16;local depth=c.stairHeight
  draw(function(_,t)return t<2 end,plane,function(s,t)return 0x292,s%16,t%16 end)
  local targets={{206,173,239},{148,132,173},{82,74,107}};local uv,best={},{}
  for t=0,18 do for s=0,w-1 do local m,u,v=source(s,t);local r,g,b,a=BM.pixel(ts,m,u,v)
   if a>.5 then for i,col in ipairs(targets)do local delta=(r*255-col[1])^2+(g*255-col[2])^2+(b*255-col[3])^2
    if not best[i]or delta<best[i]then best[i]=delta;uv[i]=G.uv(ts,m,u,v,u+1,v+1,.5)end
   end end
  end end
  for i=0,7 do
   local h0=-i*depth/8;local a,b=x+i*6,x+(i+1)*6
   G.quad(out,{a,h0,back},{b,h0,back},{b,h0,front},{a,h0,front},uv[1])
   if i<7 then local h1=-(i+1)*depth/8
    G.quad(out,{b,h0,back},{b,h0,front},{b,h1,front},{b,h1,back},uv[2],c.stairRiserShade)
   end
   G.quad(out,{b-1,h0+.02,back},{b,h0+.02,back},{b,h0+.02,front},{b-1,h0+.02,front},uv[3])
  end
  V.require('RoomRecessClip').shaft(out,{x,back,x+w,front},depth,uv[2],c.sideShade)
  G.quad(out,{x,-depth,back},{x+w,-depth,back},{x+w,-depth,front},{x,-depth,front},uv[3])
 elseif o.kind=='casinoTable'then
  local src,inside=masked();floorBackground(inside)
  draw(inside,function(s,t)
   if t<28 then return{x+s,c.tableHeight,z+t}end
   return{x+s,c.tableHeight*(32-t)/4,z+28}
  end,src)
  for _,sx in ipairs{3,27}do for _,sz in ipairs{5,25}do api.prism(out,ts,0,x+sx,z+sz,2,2,0,c.tableHeight,edge(3,28),edge(3,28),edge(3,28))end end
 elseif o.kind=='casinoSofa'then
  local src,inside=masked();floorBackground(inside)
  local function project(s,t,H)if t<29 then return{x+s,H,z+t}end;return{x+s,H*(32-t)/3,z+29}end
  draw(function(s,t)return inside(s,t)and s<12 end,function(s,t)return project(s,t,c.seatHeight)end,src)
  draw(function(s,t)return inside(s,t)and s>=12 end,function(s,t)return project(s,t,c.seatBackHeight)end,src)
 elseif o.kind=='casinoBin'then
  local src,inside=masked();floorBackground(inside)
  draw(inside,function(s,t)
   if t<8 then return{x+s,c.binHeight,z+16+t}end
   return{x+s,c.binHeight*(32-t)/24,z+24}
  end,src)
 end
end
return C
