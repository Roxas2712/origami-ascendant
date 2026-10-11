-- Measured native harbor/cable-station surfaces, independent of travel scripts.
local V=...
local S={}
local rooms={EM_SLATEPORT_CITY_HARBOR='stationHarbor',EM_LILYCOVE_CITY_HARBOR='stationHarbor',EM_ROUTE112_CABLE_CAR_STATION='stationCable',EM_MT_CHIMNEY_CABLE_CAR_STATION='stationCable'}
function S.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout;local name=rooms[d.id or d.name]
 if not(c.enabled and c.stations.enabled and name and L and d.pair=='general__facility')then return end
 local p=c.homeRooms[name]
 if L.width==p.width and L.height==p.height and L:midAt(p.check[1],p.check[2])==p.check[3]then return p end
end
function S.plan(d,p)
 local c=V.require('DioramaConfig').emeraldInteriors.stations;local L=d.midLayout;local objects,mask={},{}
 local function add(o,x,y,w,h)o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 local function claim(x,y,w,h,donor)for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;if not(type(mask[k])=='table'and mask[k].void)then mask[k]=donor end end end end
 local wallRows=p.harbor and 4 or 2;local width=p.harbor and 24 or 13
 for y=0,L.height-1 do for x=0,L.width-1 do if L:midAt(x,y)==0x201 or y<wallRows then mask[y*L.width+x+1]={mid=0x201,void=true}end end end
 for x=0,width-1 do add({kind='wall',wallHeight=p.harbor and c.harborWallHeight or c.wallHeight,wallLast=wallRows*16,wallBase=wallRows*16},x,0,1,wallRows)end
 if p.harbor then
  add({kind='stationHarborRails'},3,4,21,7)
  claim(3,4,21,1,0x202);claim(3,5,1,5,0x202)
  for x=3,23 do if x~=7 and x~=8 then claim(x,10,1,1,0x202)end end
  for x=0,16 do for y=11,14 do if L:midAt(x,y)==0x204 then mask[y*L.width+x+1]=0x202 end end end
  for _,x in ipairs({9,12,15})do add({kind='stationBollard'},x,11,1,1);claim(x,11,1,1,0x202)end
  for _,b in ipairs({{18,10,3,32,46,c.crateHeight*2},{20,11,2,16,31,c.crateHeight},{22,12,3,32,46,c.crateHeight*2}})do
   add({kind='stationCrate',split=b[4],last=b[5],height=b[6]},b[1],b[2],2,b[3]);claim(b[1],b[2],2,b[3],0x22a)
  end
  -- Long side of the fenced storage bay, not a black stripe on the floor.
  add({kind='stationStorageRail'},17,11,1,4);claim(17,11,1,4,0x202)
 else
  for _,x in ipairs({0,7})do
   add({kind='stationPit',right=x==7},x,4,6,4)
   claim(x,4,6,4,{mid=0x201,void=true})
  end
  add({kind='stationSign'},2,4,2,1)
  for _,y in ipairs({7,9})do add({kind='stationBench'},0,y,1,3);claim(0,y,1,3,0x2f0)end
  add({kind='stationMachine'},12,7,1,2);claim(12,7,1,2,0x2f0)
  add({kind='stationBin'},12,9,1,1);claim(12,9,1,1,0x2f0)
 end
 return objects,mask
end
function S.railInside(s,t)return t<3 or t>=8 or s%8>=2 and s%8<=5 end
local bollard={{5,11},{4,12},{3,13},{2,14},{3,13},{3,13},{3,13},{3,13},{4,12},{3,13},{3,13},{4,12},{5,11},{6,10}}
function S.bollardInside(s,t)local r=bollard[t];return r and s>=r[1]and s<r[2]end
function S.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.stations;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(w,h,src,inside,project)
  local vv=V.require('PaperSprite').build(ts,w,h,src or source,inside,0,h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function band(a,b,project,inside,src)draw(o.w,o.h,src,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,project)end
 local function patch(mid,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,mid,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,cfg.contactStrength}end end end
 -- Sample the actual horizontal railing artwork for all orientations. Only
 -- posts and crossbars survive; the painted floor between them is discarded.
 local function rail(ax,az,bx,bz,src)
  local length=math.sqrt((bx-ax)^2+(bz-az)^2)
  draw(length,12,src,S.railInside,function(s,t)return{x+ax+(bx-ax)*s/length,c.railHeight*(12-t)/12,z+az+(bz-az)*s/length}end)
 end
 if o.kind=='stationHarborRails'then
  local function metal(s,t)return L:midAt(4,10),s%16,t end
  rail(16,16,336,16,metal);rail(16,16,16,112,metal)
  rail(16,112,64,112,metal);rail(96,112,336,112,metal)
  contact(16,64,112);contact(96,336,112)
 elseif o.kind=='stationStorageRail'then
  rail(8,0,8,64,function(s,t)return L:midAt(4,10),s%16,t end)
 elseif o.kind=='stationBollard'then
  band(1,10,function(s,t)return{x+s,c.bollardHeight,z+5+(t-1)*7/9}end,S.bollardInside)
  band(10,15,function(s,t)return{x+s,c.bollardHeight*(15-t)/5,z+12}end,S.bollardInside);contact(4,12,12)
 elseif o.kind=='stationCrate'then
  local front=o.last;local depth=o.split
  band(0,o.split,function(s,t)return{x+s,o.height,z+front-depth+t}end)
  band(o.split,o.last,function(s,t)return{x+s,o.height*(o.last-t)/(o.last-o.split),z+front}end)
  local m,u,v=source(4,o.split+2)
  for _,s in ipairs({0,32})do patch(m,u,v,{x+s,o.height,z+front-depth},{x+s,o.height,z+front},{x+s,0,z+front},{x+s,0,z+front-depth},.95)end
  contact(0,32,front)
 elseif o.kind=='stationPit'then
  -- Yellow boarding/safety strips remain on the walking level, both ends.
  band(0,8,function(s,t)return{x+s,0,z+t}end,nil,function(s,t)return L:midAt(1,4),s%16,t end)
  band(56,64,function(s,t)return{x+s,0,z+t}end,nil,function(s,t)return L:midAt(1,7),s%16,t%16 end)
  local mid=L:midAt(1,5);local a,b=0,96;local h=-c.pitDepth
  patch(mid,8,8,{x+a,h,z+8},{x+b,h,z+8},{x+b,h,z+56},{x+a,h,z+56},G.HANGING_FACADE)
  patch(mid,8,8,{x+a,0,z+8},{x+b,0,z+8},{x+b,h,z+8},{x+a,h,z+8},G.HANGING_FACADE)
  patch(mid,8,8,{x+b,0,z+56},{x+a,0,z+56},{x+a,h,z+56},{x+b,h,z+56},G.HANGING_FACADE)
  local edge=o.right and 0 or 96
  patch(mid,8,8,{x+edge,0,z+8},{x+edge,0,z+56},{x+edge,h,z+56},{x+edge,h,z+8},G.HANGING_FACADE)
  local function metal(s,t)return L:midAt(1,math.floor((72+t)/16)),s%16,(72+t)%16 end
  rail(0,8,96,8,metal);rail(0,56,96,56,metal);rail(edge,8,edge,56,metal)
  contact(0,96,56)
 elseif o.kind=='stationSign'then
  band(2,16,function(s,t)return{x+s,c.railHeight+c.signHeight*(16-t)/14,z+8}end,function(s,t)return s>=1 and s<31 end)
 elseif o.kind=='stationBench'then
  -- A bench along the wall: seat horizontal, backrest on its left side.
  band(14,35,function(s,t)return{x+s,c.benchSeatHeight,z+t}end,function(s)return s>=4 and s<14 end)
  band(14,35,function(s,t)return{x+4,c.benchBackHeight-(s-1)*(c.benchBackHeight-c.benchSeatHeight)/3,z+t}end,function(s)return s>=1 and s<4 end)
  band(35,40,function(s,t)return{x+s,c.benchSeatHeight*(40-t)/5,z+35}end,function(s,t)return s>=2 and s<14 end)
  local m,u,v=source(4,34)
  patch(m,u,v,{x+14,c.benchSeatHeight,z+14},{x+14,c.benchSeatHeight,z+35},{x+14,0,z+35},{x+14,0,z+14},.96);contact(2,14,35)
 elseif o.kind=='stationMachine'then
  band(1,5,function(s,t)return{x+s,c.machineHeight,z+32-c.machineDepth+(t-1)*c.machineDepth/4}end)
  band(5,32,function(s,t)return{x+s,c.machineHeight*(32-t)/27,z+32}end)
  local m,u,v=source(0,15)
  for _,s in ipairs({0,16})do patch(m,u,v,{x+s,c.machineHeight,z+32-c.machineDepth},{x+s,c.machineHeight,z+32},{x+s,0,z+32},{x+s,0,z+32-c.machineDepth},.95)end
  contact(0,16,32)
 elseif o.kind=='stationBin'then
  local spans={{5,11},{3,13},{2,14},{2,14},{1,15},{1,15},{1,15},{1,15},{1,15},{1,15},{2,14},{2,14},{3,13},{4,12},{5,11}}
  band(0,15,function(s,t)return{x+s,c.binHeight*(15-t)/15,z+15}end,function(s,t)local r=spans[t+1];return r and s>=r[1]and s<r[2]end);contact(3,13,15)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return S
