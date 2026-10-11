-- Measured Battle Dome surfaces. Original tiles, warps and tournament scripts
-- remain authoritative; cutout masks contain only native foreground pixels.
local V=...
local R={}
local defs={LOBBY={24,18,5,3,0x201},CORRIDOR={48,8,23,6,0x23d},PRE_BATTLE_ROOM={10,8,5,0,0x202},BATTLE_ROOM={20,10,9,5,0x318}}
function R.kind(d)local k=d and(d.id or d.name or''):match('^EM_BATTLE_FRONTIER_BATTLE_DOME_(.+)$');return defs[k],k end
function R.profile(d)
 local p,k=R.kind(d);if not p then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.battleDome.enabled and d.pair=='building__battle_dome'and L and L.width==p[1]and L.height==p[2]and L:midAt(p[3],p[4])==p[5]then
  return c.homeRooms[k=='LOBBY'and'domeLobby'or k=='CORRIDOR'and'domeCorridor'or k=='PRE_BATTLE_ROOM'and'domeWaiting'or'domeBattle']
 end
end
function R.doorPose(d,a)
 if not R.profile(d)or not a then return end
 local _,k=R.kind(d);local c=V.require('DioramaConfig').emeraldInteriors;local h=k=='LOBBY'and a.y==4 and c.battleDome.lobbyWallHeight*32/80 or k=='CORRIDOR'and a.y==3 and c.battleDome.corridorWallHeight*32/64 or k=='PRE_BATTLE_ROOM'and a.y==1 and c.battleDome.waitingWallHeight
 if h then return{height=h*c.heightScale,base=0,top=0}end
end
-- The native script adapter can omit mapId on an otherwise valid door frame.
-- Recover presentation only when its native tile and measured map cell agree.
function R.scriptDoor(d,a)
 if not a or a.mapId~=nil or not R.profile(d)or not R.doorPose(d,a)then return end
 local _,k=R.kind(d);local spec=k=='LOBBY'and{0x209,'battle_dome_lobby'}or k=='CORRIDOR'and{0x25e,'battle_dome_corridor'}or k=='PRE_BATTLE_ROOM'and{0x20a,'battle_dome_pre_battle_room'}
 local L=d.midLayout
 if spec and a.tile==spec[2]and type(a.x)=='number'and a.x>=0 and a.x<L.width and L:midAt(a.x,a.y)==spec[1]then return a end
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local _,k=R.kind(d);local c=V.require('DioramaConfig').emeraldInteriors;local px,pz=x+8,z+16
 if k=='BATTLE_ROOM'then
  if pz<=44 then return (16+(44-pz)/44*(c.battleDome.standHeight-16))*c.heightScale,20 end
  if px>=64 and px<80 or px>=208 and px<224 then
   if pz>=80 and pz<90 then return c.battleDome.stageHeight*math.min(1,math.floor((pz-80)/3)/3)*c.heightScale end
   if pz>=122 and pz<136 then return c.battleDome.stageHeight*math.max(0,1-math.floor((pz-122)/4)/3)*c.heightScale end
  end
  if px>=96 and px<=192 and pz>=72 and pz<=138 or px>=48 and px<=240 and pz>=90 and pz<=122 then return c.battleDome.stageHeight*c.heightScale end
 elseif k=='PRE_BATTLE_ROOM'then
  if px>=49 and px<=63 and pz>=68 and pz<=78 or px>=129 and px<=143 and(pz>=52 and pz<=78 or pz>=84 and pz<=94)then return c.battleDome.seatHeight*c.heightScale end
 end
end
function R.plan(d)
 if not R.profile(d)then return end
 local _,k=R.kind(d);local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.battleDome;local objects,mask={},{}
 local function floor(x,y)if k=='PRE_BATTLE_ROOM'then return(x+y)%2==0 and 0x346 or 0x345 end;return(x+y)%2==0 and 0x340 or 0x341 end
 local function add(kind,x,y,w,h,e)local o=e or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]=floor(xx,yy)end end;return o end
 local function wall(x,y,w,h,height,clean)local o=add('domeWall',x,y,w,h,{height=height,clean=clean});for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=1,void=true}end end;return o end
 for y=0,L.height-1 do for x=0,L.width-1 do if L:midAt(x,y)==1 then mask[y*L.width+x+1]={mid=1,void=true}end end end
 if k=='CORRIDOR'then wall(0,0,48,4,c.corridorWallHeight)
 elseif k=='BATTLE_ROOM'then
  wall(0,0,20,4,c.standHeight).stands=true
  add('domeStage',2,4,15,6);for y=4,9 do for x=2,16 do mask[y*L.width+x+1]={mid=1,void=true}end end
 elseif k=='PRE_BATTLE_ROOM'then
  wall(2,0,7,2,c.waitingWallHeight,true)
  for _,p in ipairs({{7,1},{8,1},{2,6},{3,6}})do add('domePlant',p[1],p[2],1,2)end
  add('domeTable',6,3,2,3)
  add('domeChair',3,4,1,1,{mask='chair'})
  add('domeChair',8,3,1,2,{mask='chairPair',last=22})
  add('domeChair',8,5,1,1,{mask='chairPair',maskOffset=32,last=15})
  add('domeBoard',2,3,1,3,{mask='board'})
 else
  wall(0,0,23,5,c.lobbyWallHeight)
  add('domeCounter',2,7,3,4,{mask='left'})
  add('domeCounter',18,7,3,4,{mask='right'})
  add('domeShortCounter',6,9,3,2)
  add('domeShortCounter',14,9,3,2)
  for _,p in ipairs({{4,9},{18,9},{7,9}})do add('domeDevice',p[1],p[2],1,2,{mask='device'})end
  add('domeMonitor',14,9,3,2,{mask='monitor'})
  add('domePC',11,8,1,3,{mask='pc'})
  for y=5,16 do for x=0,22 do local m=L:midAt(x,y)
   if m>=0x2db and m<=0x2e0 then add('domeRope',x,y,1,1,{mask=string.format('rope%x',m)})
   elseif m==0x384 or m==0x386 or m==0x38b or m==0x327 then add('domePlant',x,y,1,2)
   elseif m==0x354 then mask[y*L.width+x+1]=floor(x,y)end
  end end
 end
 return objects,mask
end
local masks={
rope2db={
 '...##...........','..####.##.......',
 '..########......','...########.....',
 '..####.#####....','..####..########',
 '..####....######','..####......####',
 '..####..........','..####..........',
 '..####..........','..####..........',
 '.######.........','########........',
 '.######.........','..####..........'},
rope2dc={
 '...........##...','.......##.####..',
 '......########..','.....#####.##...',
 '....#####.####..','########..####..',
 '######....####..','####......####..',
 '..........####..','..........####..',
 '..........####..','..........####..',
 '.........######.','........########',
 '.........######.','..........####..'},
rope2dd={
 '...##...........','..####.##.......',
 '..########......','...########.....',
 '..####.#####....','..####..########',
 '..####....######','..####......####',
 '..####..........','..####..........',
 '..####..........','..####..........',
 '.######.........','########........',
 '.######.........','..####..........'},
rope2de={
 '...........##...','.......##.####..',
 '......########..','.....#####.##...',
 '....#####.####..','########..####..',
 '######....####..','####......####..',
 '..........####..','..........####..',
 '..........####..','..........####..',
 '.........######.','........########',
 '.........######.','..........####..'},
rope2df={
 '...##...........','..####.##.......',
 '..########......','...########.....',
 '..####.#####....','..####..########',
 '..####....######','..####......####',
 '..####..........','..####..........',
 '..####..........','..####..........',
 '.######.........','########........',
 '.######.........','..####..........'},
rope2e0={
 '...##...........','..####.##.......',
 '..########......','...########.....',
 '..####.#####....','..####..########',
 '..####....######','..####......####',
 '..####..........','..####..........',
 '..####..........','..####..........',
 '.######.........','########........',
 '.######.........','..####..........'},
left={
 '..........############..........................','.........##############.........................',
 '........################........................','........################........................',
 '........################........................','........################........................',
 '........################........................','........################........................',
 '.......#################........................','.......#################........................',
 '......##################........................','......##################........................',
 '.....###################........................','.....###################........................',
 '....####################........................','....####################........................',
 '...#####################........................','...#####################........................',
 '..######################........................','..######################........................',
 '.#######################........................','.#######################........................',
 '########################........................','########################........................',
 '########################........................','########################........................',
 '#######################.........................','#######################.........................',
 '#######################.........................','########################........................',
 '########################........................','########################........................',
 '########################........................','########################........................',
 '########################........................','########################........................',
 '########################........................','########################........................',
 '########################........................','########################........................',
 '########################........................','########################........................',
 '########################........................','########################........................',
 '########################........................','########################........................',
 '########################........................','########################........................',
 '################################################','################################################',
 '################################################','################################################',
 '################################################','################################################',
 '################################################','################################################',
 '################################################','################################################',
 '################################################','################################################',
 '################################################','################################################',
 '.###############################################','..##############################################'},
right={
 '..........................############..........','.........................##############.........',
 '........................################........','........................################........',
 '........................################........','........................################........',
 '........................################........','........................################........',
 '........................#################.......','........................#################.......',
 '........................##################......','........................##################......',
 '........................###################.....','........................###################.....',
 '........................####################....','........................####################....',
 '........................#####################...','........................#####################...',
 '........................######################..','........................######################..',
 '........................#######################.','........................#######################.',
 '........................########################','........................########################',
 '........................########################','........................########################',
 '.........................#######################','.........................#######################',
 '.........................#######################','........................########################',
 '........................########################','........................########################',
 '........................########################','........................########################',
 '........................########################','........................########################',
 '........................########################','........................########################',
 '........................########################','........................########################',
 '........................########################','........................########################',
 '........................########################','........................########################',
 '........................########################','........................########################',
 '........................########################','........................########################',
 '################################################','################################################',
 '################################################','################################################',
 '################################################','################################################',
 '################################################','################################################',
 '################################################','################################################',
 '################################################','################################################',
 '################################################','################################################',
 '###############################################.','##############################################..'},
monitor={
 '................................................','....................########....................',
 '..........############################..........','.........##############################.........',
 '.........##############################.........','.........##############################.........',
 '.........##############################.........','.........##############################.........',
 '.........##############################.........','.........##############################.........',
 '.........##############################.........','.........##############################.........',
 '.........##############################.........','.........##############################.........',
 '.........##############################.........','.........##############################.........',
 '.........##############################.........','.........##############################.........',
 '.........##############################.........','..........############################..........',
 '..................############..................','..................############..................',
 '...................##########...................','....................########....................',
 '................................................','................................................',
 '................................................','................................................',
 '................................................','................................................',
 '................................................','................................................'},
pc={
 '................','................',
 '................','................',
 '................','................',
 '................','................',
 '...##########...','..############..',
 '.##############.','################',
 '################','################',
 '################','################',
 '################','################',
 '################','################',
 '################','################',
 '################','################',
 '################','################',
 '################','################',
 '################','################',
 '################','################',
 '################','################',
 '################','################',
 '################','################',
 '.##############.','..############..',
 '................','................',
 '................','................',
 '................','................',
 '................','................'},
table={
 '..........####################..','.........######################.',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '........########################','........########################',
 '.........######################.','..........####################..',
 '..........####............####..','..........####............####..'},
chair={
 '............##..','...........####.',
 '...........####.','...........####.',
 '..#############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '..#############.','..############..',
 '..##........##..','................'},
chairPair={
 '............##..','...........####.',
 '...........####.','...........####.',
 '..#############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '..#############.','..############..',
 '..##........##..','................',
 '............##..','...........####.',
 '...........####.','...........####.',
 '..#############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '.##############.','.##############.',
 '..#############.','..############..',
 '..##........##..','................'},
board={
 '############....','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','#############...',
 '#############...','############....',
 '########........','########........',
 '########........','#######.........',
 '................','................',
 '................','................',
 '................','................',
 '................','................'},
}
function R.inside(name,s,t)local rows=masks[name];return rows and rows[t+1]and rows[t+1]:sub(s+1,s+1)=='#'or false end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battleDome;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(m,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,c.contactStrength}end end end
 local function mask(s,t)return R.inside(o.mask,s,t+(o.maskOffset or 0))end
 if o.kind=='domeWall'then
  draw(0,o.h,nil,function(s,t)if o.stands then return{x+s,t<44 and 16+(44-t)/44*(o.height-16)or 16*(64-t)/20,z+(t<44 and t+20 or 64)}end;return{x+s,o.height*(o.h-t)/o.h,z+o.h}end,function(s,t)local m,u,v=source(s,t);if o.clean and m==0x308 then m=0x358 end;return m,u,v end)
 elseif o.kind=='domePlant'then
  draw(3,31,V.require('EmeraldFrontierReception').plantInside,function(s,t)return{x+s,c.plantHeight*(31-t)/28,z+31}end);contact(2,14,31)
 elseif o.kind=='domeRope'then
  draw(0,16,mask,function(s,t)return{x+s,c.ropeHeight*(16-t)/16,z+16}end);contact(0,16,16)
 elseif o.kind=='domeCounter'or o.kind=='domeShortCounter'then
  local short=o.kind=='domeShortCounter';local split=short and 24 or 56;local last=short and 32 or 64
  local function inside(s,t)if short then return t>=8 end;return mask(s,t)end
  local function clean(s,t)
   if short then return math.floor(s/16)==0 and 0x3a8 or math.floor(s/16)==1 and 0x3a9 or 0x3aa,s%16,t<16 and 2 or t-16
   elseif t>=48 and(o.mask=='left'and s>=32 or o.mask=='right'and s<16)then return o.mask=='left'and 0x3aa or 0x3a8,s%16,t-48 end
   return source(s,t)
  end
  draw(0,split,inside,function(s,t)return{x+s,c.counterHeight,z+t+8}end,clean)
  draw(split,last,inside,function(s,t)return{x+s,c.counterHeight*(last-t)/(last-split),z+last}end,clean)
  -- Close only measured contour borders; openings stay open.
  for t=0,split-1 do for s=0,o.w-1 do if inside(s,t)then
   local function edge(a,b)patch(0x3a9,8,13,{x+a[1],c.counterHeight,z+a[2]+8},{x+b[1],c.counterHeight,z+b[2]+8},{x+b[1],0,z+b[2]+8},{x+a[1],0,z+a[2]+8},.97)end
   if s==0 or not inside(s-1,t)then edge({s,t},{s,t+1})end
   if s==o.w-1 or not inside(s+1,t)then edge({s+1,t+1},{s+1,t})end
   if t==0 or not inside(s,t-1)then edge({s+1,t},{s,t})end
  end end end;contact(0,o.w,last)
 elseif o.kind=='domeDevice'or o.kind=='domeMonitor'or o.kind=='domePC'then
  local pc=o.kind=='domePC';local mon=o.kind=='domeMonitor';local a=pc and 8 or mon and 1 or 4;local b=pc and 40 or 24
  local h=pc and c.pcHeight or c.deviceHeight;local base=pc and 0 or c.counterHeight
  local function inside(s,t)if not pc and not mon then local inset=t==4 and 3 or t<7 and 1 or t==23 and 2 or 0;return s>=inset and s<16-inset end;return mask(s,t)end
  draw(a,b,inside,function(s,t)return{x+s,base+h*(b-t)/(b-a),z+(pc and 40 or 28)}end);if pc then contact(0,16,40)end
 elseif o.kind=='domeTable'then
  draw(0,42,function(s,t)return R.inside('table',s,t)end,function(s,t)return{x+s,c.tableHeight,z+t}end)
  draw(42,48,function(s,t)return R.inside('table',s,t)end,function(s,t)return{x+s,c.tableHeight*(48-t)/6,z+42}end)
  -- The native tabletop begins at column 8, not at the sprite's left edge.
  -- Close its measured outline with a short apron; keep the leg space open.
  for t=0,41 do for s=0,31 do if R.inside('table',s,t)then
   for _,edge in ipairs({{-1,s},{1,s+1}})do if not R.inside('table',s+edge[1],t)then
    local xx=x+edge[2];patch(0x36f,8,10,{xx,c.tableHeight,z+t},{xx,c.tableHeight,z+t+1},{xx,c.tableHeight-c.lighting.slabThickness,z+t+1},{xx,c.tableHeight-c.lighting.slabThickness,z+t},.97)
   end end
  end end end;contact(8,32,42)
 elseif o.kind=='domeChair'then
  local last=o.last or o.h-1
  draw(0,last-3,function(s,t)return mask(s,t)and s>=11 end,function(s,t)return{x+11,c.seatHeight+(s-11)*(c.backHeight-c.seatHeight)/4,z+t}end)
  draw(0,last-3,function(s,t)return mask(s,t)and s<11 end,function(s,t)return{x+s,c.seatHeight,z+t}end)
  draw(last-3,last,mask,function(s,t)return{x+s,c.seatHeight*(last-t)/3,z+last-3}end)
  for t=0,last-3 do if mask(13,t)then patch(0x364,13,5,{x+11,c.backHeight,z+t},{x+14,c.backHeight,z+t},{x+14,c.backHeight,z+t+1},{x+11,c.backHeight,z+t+1});patch(0x364,13,5,{x+14,c.backHeight,z+t},{x+14,c.backHeight,z+t+1},{x+14,0,z+t+1},{x+14,0,z+t},.97)end end
  contact(0,16,last-3)
 elseif o.kind=='domeBoard'then
  draw(0,40,function(s,t)return mask(s,t)and s>=4 end,function(s,t)return{x+s,c.tableHeight,z+t}end)
  draw(0,40,function(s,t)return mask(s,t)and s<4 end,function(s,t)return{x+4,c.pcHeight-(s/4)*(c.pcHeight-c.tableHeight),z+t}end)
  for t=0,39 do if mask(2,t)then patch(0x35b,2,5,{x,c.pcHeight,z+t},{x+4,c.pcHeight,z+t},{x+4,c.pcHeight,z+t+1},{x,c.pcHeight,z+t+1})end end
  patch(0x36b,2,5,{x,c.pcHeight,z+40},{x+4,c.pcHeight,z+40},{x+4,0,z+40},{x,0,z+40},.97)
  -- Close the console's actual tapered plinth, never an imagined rectangular
  -- end cap beyond the last opaque native row (row 39).
  for t=0,39 do for s=4,15 do if mask(s,t)then
   if not mask(s,t+1)then patch(0x36b,2,5,{x+s,c.tableHeight,z+t+1},{x+s+1,c.tableHeight,z+t+1},{x+s+1,0,z+t+1},{x+s,0,z+t+1},.97)end
   if not mask(s+1,t)then patch(0x36b,2,5,{x+s+1,c.tableHeight,z+t},{x+s+1,c.tableHeight,z+t+1},{x+s+1,0,z+t+1},{x+s+1,0,z+t},.97)end
  end end end;contact(0,8,40)
 elseif o.kind=='domeStage'then
  -- Local coordinates retain the painted arena floor. Only the native raised
  -- playing surfaces and steps receive height; brown/green ground stays flat.
  local function kind(s,t)
   if s>=64 and s<160 and t>=8 and t<72 then return'top'end
   if s>=64 and s<160 and t>=72 and t<74 then return'front'end
   if(s>=16 and s<64 or s>=160 and s<208)and t>=26 and t<56 then return'side'end
   if(s>=16 and s<64 or s>=160 and s<208)and t>=56 and t<58 then return'sidefront'end
   if(s>=32 and s<48 or s>=176 and s<192)and t>=16 and t<26 then return'up'end
   if(s>=32 and s<48 or s>=176 and s<192)and t>=58 and t<72 then return'down'end
   return'ground'
  end
  -- The two source rows folded into each front face still need ground below
  -- their original footprint. Continue the adjacent native floor/shadow there.
  draw(0,96,function(s,t)local k=kind(s,t);return k=='front'or k=='sidefront'end,function(s,t)return{x+s,0,z+t}end,function(s,t)return source(s,kind(s,t)=='front'and 74 or 58)end)
  for _,k in ipairs({'top','front','side','sidefront','up','down','ground'})do
   draw(0,96,function(s,t)return kind(s,t)==k end,function(s,t)
    local h=0;local zz=t
    if k=='top'or k=='side'then h=c.stageHeight
    elseif k=='front'then h=c.stageHeight*(74-t)/2;zz=72
    elseif k=='sidefront'then h=c.stageHeight*(58-t)/2;zz=56
    elseif k=='up'then h=c.stageHeight*math.min(1,math.floor((t-16)/3)/3)
    elseif k=='down'then h=c.stageHeight*math.max(0,1-math.floor((t-58)/4)/3)end
    return{x+s,h,z+zz}
   end)
  end
  for _,ss in ipairs({64,160})do patch(0x2ee,1,10,{x+ss,c.stageHeight,z+8},{x+ss,c.stageHeight,z+72},{x+ss,0,z+72},{x+ss,0,z+8},.97)end
  for _,ss in ipairs({16,208})do patch(0x2ee,1,10,{x+ss,c.stageHeight,z+26},{x+ss,c.stageHeight,z+56},{x+ss,0,z+56},{x+ss,0,z+26},.97)end
  patch(0x2ee,1,10,{x+64,c.stageHeight,z+8},{x+160,c.stageHeight,z+8},{x+160,0,z+8},{x+64,0,z+8},.97)
  for _,a in ipairs({{16,64},{160,208}})do patch(0x2ee,1,10,{x+a[1],c.stageHeight,z+26},{x+a[2],c.stageHeight,z+26},{x+a[2],0,z+26},{x+a[1],0,z+26},.97)end
  contact(64,160,74)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
