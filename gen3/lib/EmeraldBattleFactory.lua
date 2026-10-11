-- Battle Factory: native pipe walls, separate machines and rack silhouettes.
-- This module changes presentation only; rental and battle scripts stay native.
local V=...
local R={}
local defs={LOBBY={20,12,9,11,0x209},PRE_BATTLE_ROOM={18,14,8,13,0x209},BATTLE_ROOM={14,12,6,6,0x2a1}}
function R.kind(d)local k=d and(d.id or d.name or''):match('^EM_BATTLE_FRONTIER_BATTLE_FACTORY_(.+)$');return defs[k],k end
function R.profile(d)
 local p,k=R.kind(d);if not p then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.battleFactory.enabled and d.pair=='building__battle_factory'and L and L.width==p[1]and L.height==p[2]and L:midAt(p[3],p[4])==p[5]then return c.homeRooms[k=='LOBBY'and'factoryLobby'or k=='PRE_BATTLE_ROOM'and'factoryPreparation'or'factoryBattle']end
end
function R.doorPose(d,a)
 if not R.profile(d)or not a then return end
 local _,k=R.kind(d);local c=V.require('DioramaConfig').emeraldInteriors
 local h=k=='LOBBY'and a.y==4 and c.battleFactory.lobbyWallHeight*32/80 or k=='PRE_BATTLE_ROOM'and a.y==5 and c.battleFactory.pipeWallHeight*32/96
 if h then return{height=h*c.heightScale,base=0,top=0}end
end
function R.scriptDoor(d,a)
 if not a or a.mapId~=nil or a.tile~='battle_tower_elevator'or not R.doorPose(d,a)then return end
 local L=d.midLayout
 if type(a.x)=='number'and a.x>=0 and a.x<L.width and L:midAt(a.x,a.y)==0x20e then return a end
end
function R.plan(d)
 if not R.profile(d)then return end
 local _,k=R.kind(d);local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.battleFactory;local objects,mask={},{}
 local function floor(x,y)return(x+y)%2==0 and 0x201 or 0x202 end
 local function add(kind,x,y,w,h,e)local o=e or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local i=yy*L.width+xx+1;if not(type(mask[i])=='table'and mask[i].void)then mask[i]=floor(xx,yy)end end end;return o
 end
 local function wall(w,h,height)
  local o=add('factoryWall',0,0,w,h,{height=height,lobby=k=='LOBBY'})
  for y=0,h-1 do for x=0,w-1 do mask[y*L.width+x+1]={mid=1,void=true}end end;return o
 end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==1 then mask[y*L.width+x+1]={mid=1,void=true}
  elseif k~='BATTLE_ROOM'and(m==0x333 or m==0x334 or m==0x335 or m==0x337)then mask[y*L.width+x+1]=floor(x,y)end
 end end
 if k=='LOBBY'then
  wall(19,5,c.lobbyWallHeight)
  add('factoryCounter',2,4,6,4,{gap=32});add('factoryCounter',11,4,6,4,{gap=48})
  add('factoryDevice',2,6,1,2);add('factoryDevice',11,6,1,2)
  add('factoryPC',0,4,1,3)
  add('factoryMonitor',8,4,3,2)
  for _,p in ipairs({{1,4},{17,4},{18,4},{8,6},{10,6}})do add('factoryPlant',p[1],p[2],1,2)end
  add('factorySeat',18,9,1,3)
  add('factoryBin',15,10,1,2);add('factoryBin',17,10,1,2)
 elseif k=='PRE_BATTLE_ROOM'then
  wall(17,6,c.pipeWallHeight)
  add('factoryMachineA',1,4,3,3,{start=8,last=40})
  add('factoryMachineB',13,4,3,3,{start=8,last=39})
  add('factoryMachineRow',0,7,5,2)
  add('factoryMachineA',14,7,3,2,{start=0,last=32})
  for _,p in ipairs({{3,10,3},{5,10,2},{9,8,4},{11,9,4}})do add('factoryRack',p[1],p[2],2,p[3])end
  for _,xx in ipairs({0,15})do add('factoryTable',xx,10,2,2)end
  for _,xx in ipairs({2,14})do add('factoryBin',xx,10,1,2)end
 else
  add('factoryBattleShell',0,0,13,12)
  for y=0,11 do for x=0,12 do mask[y*L.width+x+1]={mid=1,void=true}end end
 end
 return objects,mask
end
function R.machineBInside(s,t)
 if t<8 or t>=39 then return false end
 if t<11 then return s>=24 and s<37 end
 if t<13 then return s>=3 and s<11 or s>=24 and s<37 or t==12 and s==14 end
 if t<17 then return s>=3 and s<11 or s>=12 and s<15 or s>=23 and s<37 end
 return s<39
end
-- Footer tiles contain floor from row 8 onward; the gap between the two
-- feet is floor already at rows 6/7. Keep it off the upright shelf mesh.
function R.rackInside(s,t,h)
 local footer=t-(h-16)
 return footer<6 or footer<8 and(s<5 or s>=27)
end
function R.battleFloorInside(s,t)
 local inset=math.min(24,math.max(0,t-151))
 return s>=inset and s<208-inset
end
function R.counterInside(s,t,w,gap)
 if t<8 or t>=64 or s<0 or s>=w then return false end
 return s<16 or s>=w-16 or t>=44 and not(s>=gap and s<gap+16)
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battleFactory;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(m,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,c.contactStrength}end end end
 if o.kind=='factoryWall'then
  draw(0,o.h,nil,function(s,t)return{x+s,o.height*(o.h-t)/o.h,z+o.h}end,function(s,t)
   local m,u,v=source(s,t);local xx=math.floor(s/16)
   if o.lobby and t>=64 then
    if xx==2 or xx==16 then m=0x214
    elseif xx==0 or xx==1 or xx>=7 and xx<=11 or xx>=17 then m=0x215 end
   elseif not o.lobby and(xx>=1 and xx<=3 or xx>=13 and xx<=15)then
    if t>=72 and t<80 then m=0x21b
    elseif t>=80 then m=0x215 end
   end
   return m,u,v
  end)
 elseif o.kind=='factoryPlant'then
  draw(3,31,V.require('EmeraldFrontierReception').plantInside,function(s,t)return{x+s,c.plantHeight*(31-t)/28,z+31}end);contact(2,14,31)
 elseif o.kind=='factoryCounter'then
  local function inside(s,t)return R.counterInside(s,t,o.w,o.gap)end
  local function clean(s,t)local m,u,v=source(s,t);if m==0x218 then m=0x210 elseif m==0x220 then m=0x221 end;return m,u,v end
  draw(8,56,inside,function(s,t)return{x+s,c.counterHeight,z+t+8}end,clean)
  draw(56,64,inside,function(s,t)return{x+s,c.counterHeight*(64-t)/8,z+64}end,clean)
  for t=8,55 do for s=0,o.w-1 do if inside(s,t)then
   local function edge(a,b)patch(0x212,8,12,{x+a[1],c.counterHeight,z+a[2]+8},{x+b[1],c.counterHeight,z+b[2]+8},{x+b[1],0,z+b[2]+8},{x+a[1],0,z+a[2]+8},.97)end
   if not inside(s-1,t)then edge({s,t},{s,t+1})end
   if not inside(s+1,t)then edge({s+1,t+1},{s+1,t})end
   if not inside(s,t-1)then edge({s+1,t},{s,t})end
  end end end
  contact(0,o.gap,64);contact(o.gap+16,o.w,64)
 elseif o.kind=='factoryDevice'then
  local function inside(s,t)local a=t==4 and 3 or t<7 and 1 or t==23 and 2 or 0;return s>=a and s<16-a end
  draw(4,24,inside,function(s,t)return{x+s,c.counterHeight+c.deviceHeight*(24-t)/20,z+28}end)
 elseif o.kind=='factoryPC'then
  draw(8,40,function(s,t)local a=t==8 and 3 or t==9 and 2 or t==10 and 1 or t==39 and 1 or 0;return s>=a and s<16-a end,function(s,t)return{x+s,c.pcHeight*(40-t)/32,z+40}end);contact(0,16,40)
 elseif o.kind=='factoryMonitor'then
  draw(1,24,function(s,t)local a=t==1 and 20 or t==2 and 10 or t<=18 and 9 or t==19 and 10 or t<=21 and 18 or t==22 and 19 or 20;return s>=a and s<48-a end,function(s,t)return{x+s,c.monitorHeight*(24-t)/23,z+24}end);contact(16,32,24)
 elseif o.kind=='factoryMachineA'or o.kind=='factoryMachineB'or o.kind=='factoryMachineRow'then
  local a=o.start or 0;local last=o.last or 32
  local function inside(s,t)
   if o.kind=='factoryMachineB'then return R.machineBInside(s,t)end
   if o.kind=='factoryMachineRow'then return s<39 and R.machineBInside(s,t+8)or s>=40 and s<72 end
   return true
  end
  draw(a,last,inside,function(s,t)return{x+s,c.machineHeight*(last-t)/(last-a),z+last}end)
  contact(0,o.kind=='factoryMachineRow'and 72 or o.kind=='factoryMachineB'and 39 or o.w,last)
 elseif o.kind=='factoryRack'then
  local last=o.h-8;local split=4
  draw(0,split,nil,function(s,t)return{x+s,(last-split)*c.rackHeightScale,z+last-c.rackDepth+t*c.rackDepth/split}end)
  draw(split,last,function(s,t)return R.rackInside(s,t,o.h)end,function(s,t)return{x+s,(last-t)*c.rackHeightScale,z+last}end)
  for _,ss in ipairs({0,o.w})do patch(0x216,0,8,{x+ss,(last-split)*c.rackHeightScale,z+last-c.rackDepth},{x+ss,(last-split)*c.rackHeightScale,z+last},{x+ss,0,z+last},{x+ss,0,z+last-c.rackDepth},.97)end;contact(0,o.w,last)
 elseif o.kind=='factoryTable'then
  draw(0,18,nil,function(s,t)return{x+s,c.tableHeight,z+t}end)
  draw(18,32,function(s,t)return t<23 or s<4 or s>=o.w-4 end,function(s,t)return{x+s,c.tableHeight*(32-t)/14,z+18}end)
  for _,ss in ipairs({0,o.w})do patch(0x258,2,7,{x+ss,c.tableHeight,z},{x+ss,c.tableHeight,z+18},{x+ss,0,z+18},{x+ss,0,z},.97)end;contact(0,o.w,18)
 elseif o.kind=='factoryBin'then
  local function inside(s,t)local a=t<4 and 8 or t==4 and 6 or t==5 and 4 or t==6 and 3 or t==7 and 2 or t<28 and 1 or t==28 and 2 or t==29 and 3 or 5;return s>=a and s<16-a end
  draw(4,31,inside,function(s,t)return{x+s,c.binHeight*(31-t)/27,z+31}end);contact(1,15,31)
 elseif o.kind=='factorySeat'then
  local mask=V.require('EmeraldTowerPublic').benchInside
  draw(0,44,function(s,t)return mask(s,t)and s>=11 end,function(s,t)return{x+11,c.seatHeight+(s-11)*(c.backHeight-c.seatHeight)/4,z+t}end)
  draw(4,44,function(s,t)return mask(s,t)and s<11 end,function(s,t)return{x+s,c.seatHeight,z+t}end)
  draw(44,47,mask,function(s,t)return{x+s,c.seatHeight*(47-t)/3,z+44}end)
  for t=1,43 do patch(0x238,13,5,{x+11,c.backHeight,z+t},{x+14,c.backHeight,z+t},{x+14,c.backHeight,z+t+1},{x+11,c.backHeight,z+t+1});patch(0x238,13,5,{x+14,c.backHeight,z+t},{x+14,c.backHeight,z+t+1},{x+14,0,z+t+1},{x+14,0,z+t},.97)end;contact(0,16,44)
 elseif o.kind=='factoryBattleShell'then
  local function base(s)return s<16 and 56-s or s>=192 and s-192+40 or 40 end
  local function wallPoint(s,t)return{x+s,c.battleWallHeight*math.max(0,base(s)-t)/base(s),z+base(s)}end
  draw(0,40,function(s)return s>=16 and s<192 end,wallPoint)
  -- The diagonal corners have a non-affine UV projection. Whole scanline
  -- runs triangulate differently on adjacent rows and overlap into a comb.
  -- Equal one-texel facets share every edge and preserve the native stripes.
  for _,start in ipairs({0,192})do for s=start,start+15 do for t=0,base(s)-1 do
   local m,u,v=source(s,t)
   patch(m,u,v,wallPoint(s,t),wallPoint(s+1,t),wallPoint(s+1,t+1),wallPoint(s,t+1))
  end end end
  -- One native texel of overlap closes the stair-stepped diagonal cut edge.
  draw(32,192,function(s,t)return t>=base(s)-1 and R.battleFloorInside(s,t)end,function(s,t)return{x+s,0,z+t}end)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
