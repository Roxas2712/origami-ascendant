-- Measured Battle Palace surfaces. The native game owns paths and challenges.
local V=...
local R={}
local defs={LOBBY={26,12,12,11,0x204,'building__battle_palace'},CORRIDOR={18,14,8,13,0x204,'general__battle_palace'},BATTLE_ROOM={16,10,7,5,0x26b,'general__battle_palace'}}
function R.kind(d)local k=d and(d.id or d.name or''):match('^EM_BATTLE_FRONTIER_BATTLE_PALACE_(.+)$');return defs[k],k end
function R.profile(d)
 local p,k=R.kind(d);if not p then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.battlePalace.enabled and d.pair==p[6]and L and L.width==p[1]and L.height==p[2]and L:midAt(p[3],p[4])==p[5]then return c.homeRooms[k=='LOBBY'and'palaceLobby'or k=='CORRIDOR'and'palaceCorridor'or'palaceBattle']end
end
function R.doorPose(d,a)
 if not a or not R.profile(d)then return end
 local _,k=R.kind(d);local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battlePalace
 local h=k=='LOBBY'and a.y==4 and c.lobbyWallHeight*32/80 or k=='CORRIDOR'and a.y==3 and c.corridorWallHeight*32/64
 if h then return{height=h*cfg.heightScale,base=0,top=0}end
end
function R.scriptDoor(d,a)
 if not a or a.mapId~=nil or a.tile~='battle_palace_lobby'or not R.doorPose(d,a)then return end
 if type(a.x)=='number'and a.x>=0 and a.x<d.midLayout.width and d.midLayout:midAt(a.x,a.y)==0x219 then return a end
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local _,k=R.kind(d);local cfg=V.require('DioramaConfig').emeraldInteriors
 if k=='BATTLE_ROOM'and x+8>=64 and x+8<=176 and z+16>=48 and z+16<=124 then return cfg.battlePalace.stageHeight*cfg.heightScale end
end
function R.plan(d)
 if not R.profile(d)then return end
 local _,k=R.kind(d);local L=d.midLayout;local cfg=V.require('DioramaConfig').emeraldInteriors.battlePalace;local objects,mask={},{}
 local function clear(x,y,m)mask[y*L.width+x+1]=m or{mid=k=='LOBBY'and 1 or 0x23,void=true}end
 local function add(kind,x,y,w,h,e)local o=e or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do clear(xx,yy)end end;return o
 end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y);if m==(k=='LOBBY'and 1 or 0x23)then clear(x,y)end end end
 if k=='LOBBY'then
  add('palaceWall',0,0,25,5,{height=cfg.lobbyWallHeight,clean=true})
  add('palaceCounter',2,5,7,4);add('palaceCounter',16,5,7,4)
  add('palaceMonitor',9,3,3,3)
  add('palacePC',13,2,3,4)
 elseif k=='CORRIDOR'then
  add('palaceWall',0,0,17,4,{height=cfg.corridorWallHeight})
  for y=4,13 do for x=0,16 do local m=L:midAt(x,y)
   if m==4 or m==0xd then add('palacePlant',x,y,1,1,{mid=m})
   elseif m==0x239 or m==0x23c or m==0x235 or m==0x233 or m==0x23d or m==0x23b then add('palaceRail',x,y,1,1,{mid=m})end
  end end
 else
  add('palaceWall',0,0,15,3,{height=cfg.battleWallHeight})
  add('palaceStage',4,3,7,5)
 end
 return objects,mask
end
local counterRows={
 '..####################....................................................................####################..',
 '.######################..................................................................######################.',
 '########################................................................................########################',
 '########################................................................................########################',
 '########################................................................................########################',
 '########################................................................................########################',
 '########################................................................................########################',
 '########################................................................................########################',
 '########################................................................................########################',
 '########################................................................................########################',
 '########################................................................................########################',
 '########################................................................................########################',
 '########################................................................................########################',
 '########################................................................................########################',
 '########################.................................................................######################.',
 '########################..................................................................####################..',
 '..####################....####################....................####################....####################..',
 '.######################..######################..................######################..######################.',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '################################################................################################################',
 '................################################################################################################',
 '................################################################################################################',
 '................################################################################################################',
 '................################################################################################################',
 '................################################################################################################',
 '...................##########...........################################...........##########..............#####',
 '...................##########...........################################...........##########..............#####',
 '..................#####..#####..........################################..........#####..#####............#####.',
}
function R.counterInside(s,t)return counterRows[t+1]and counterRows[t+1]:sub(s+1,s+1)=='#'end
function R.pcInside(s,t)
 if t>=56 then return false end
 local inset=t==0 and 11 or t==1 and 10 or t==2 and 9 or t==3 and 8 or t<13 and 7 or t==13 and 8 or t==14 and 9 or t<17 and 10 or 8
 return s>=inset and s<48-inset
end
function R.deviceInside(s,t)
 if t<28 or t>=56 then return false end
 local inset=t==28 and 4 or t==29 and 2 or t<32 and 1 or t<46 and 0 or t==46 and 1 or t<49 and 4 or t<54 and 6 or 5
 return s>=inset and s<16-inset
end
R.plantRows={
 [4]={
 '................',
 '.............#..',
 '......#####.....',
 '.....########...',
 '#.#############.',
 '.###############',
 '.###############',
 '.###############',
 '.###############',
 '.###############',
 '..#############.',
 '..#############.',
 '.##############.',
 '###############.',
 '.#####...######.',
 '..##........###.',
 },
 [13]={
 '............##..',
 '..####....#####.',
 '..###.#..#####..',
 '...#..###..###..',
 '.##############.',
 '###.############',
 '##...#####..###.',
 '.#..#######.##..',
 '.##############.',
 '################',
 '###.########..#.',
 '.##..######....#',
 '.#.####..#######',
 '.#####.#..######',
 '..######.######.',
 '.......####.....',
 },
}
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battlePalace;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project,src,shade)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,shade and function()return shade end,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(m,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,c.contactStrength}end end end
 if o.kind=='palaceWall'then
  draw(0,o.h,nil,function(s,t)return{x+s,o.height*(o.h-t)/o.h,z+o.h}end,function(s,t)
   local m,u,v=source(s,t);local xx=math.floor(s/16)
   if o.clean and(xx>=9 and xx<=11 and t>=48 or xx>=13 and xx<=15 and t>=32)then m=t>=64 and 0x20e or 0x209 end
   return m,u,v
  end)
 elseif o.kind=='palaceCounter'then
  -- Restore just furniture pixels on the ground; keep the original patterned
  -- rug and floor at every other source texel, including between table legs.
  draw(0,64,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)
   if R.counterInside(s,t)or s<16 and R.deviceInside(s,t)then return 0x201,s%16,t%16 end
   return source(s,t)
  end)
  draw(0,32,R.counterInside,function(s,t)return{x+s,c.counterHeight,z+t+8}end,function(s,t)
   if s<16 and t>=28 then return 0x220,8,8 end;return source(s,t)
  end)
  draw(32,40,R.counterInside,function(s,t)return{x+s,c.counterHeight*(40-t)/8,z+40}end)
  draw(28,56,function(s,t)return s<16 and R.deviceInside(s,t)end,function(s,t)return{x+s,c.deviceHeight*(56-t)/28,z+56}end)
  contact(0,48,40);contact(64,104,40);contact(0,16,56)
 elseif o.kind=='palaceMonitor'then
  draw(32,48,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)return 0x201,s%16,t%16 end)
  draw(16,40,function(s,t)local q=t-15;local a=q==1 and 20 or q==2 and 10 or q<=18 and 9 or q==19 and 10 or q<=21 and 18 or q==22 and 19 or 20;return s>=a and s<48-a end,function(s,t)return{x+s,c.monitorHeight*(40-t)/24,z+40}end);contact(16,32,40)
 elseif o.kind=='palacePC'then
  draw(48,64,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)return 0x201,s%16,t%16 end)
  draw(0,56,R.pcInside,function(s,t)return{x+s,c.pcHeight*(56-t)/56,z+56}end);contact(8,40,56)
 elseif o.kind=='palacePlant'then
  local rows=R.plantRows[o.mid]
  local function inside(s,t)return rows[t+1]:sub(s+1,s+1)=='#'end
  draw(0,16,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)if inside(s,t)then return o.mid,0,0 end;return source(s,t)end)
  draw(0,16,inside,function(s,t)return{x+s,c.plantHeight*(16-t)/16,z+16}end);contact(2,14,16)
 elseif o.kind=='palaceRail'then
  local m=o.mid
  local function inside(s,t)return(m==0x239 and t>=8)or(m==0x23c and t<8)or(m==0x235 and s<8)or(m==0x233 and s>=8)or(m==0x23d and(t<8 or s<8))or(m==0x23b and(t<8 or s>=8))end
  draw(0,16,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)if inside(s,t)then return 0x201,s,t end;return source(s,t)end)
  draw(0,16,inside,function(s,t)return{x+s,c.railHeight,z+t}end)
  for t=0,15 do for s=0,15 do if inside(s,t)then
   local function edge(a,b)patch(m,s,t,{x+a[1],c.railHeight,z+a[2]},{x+b[1],c.railHeight,z+b[2]},{x+b[1],0,z+b[2]},{x+a[1],0,z+a[2]},.88)end
   if s==0 or not inside(s-1,t)then edge({s,t},{s,t+1})end
   if s==15 or not inside(s+1,t)then edge({s+1,t+1},{s+1,t})end
   if t==0 or not inside(s,t-1)then edge({s+1,t},{s,t})end
   if t==15 or not inside(s,t+1)then edge({s,t+1},{s+1,t+1})end
  end end end
 elseif o.kind=='palaceStage'then
  draw(0,76,nil,function(s,t)return{x+s,c.stageHeight,z+t}end)
  draw(76,80,nil,function(s,t)return{x+s,c.stageHeight*(80-t)/4,z+76}end);contact(0,o.w,76)
  for _,ss in ipairs({0,o.w})do patch(0x278,1,14,{x+ss,c.stageHeight,z},{x+ss,c.stageHeight,z+76},{x+ss,0,z+76},{x+ss,0,z},.9)end
  draw(76,80,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)return 0x170,s%16,t%16 end,G.WATER)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
