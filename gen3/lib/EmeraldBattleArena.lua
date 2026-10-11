-- Battle Arena: native wood dais, stone floor, freestanding furnishings and
-- U-shaped corridor. Presentation only; native challenge scripts own movement.
local V=...
local R={}
local defs={LOBBY={16,14,7,3,0x2a2},CORRIDOR={18,14,8,13,0x294},BATTLE_ROOM={16,12,7,5,0x233}}
function R.kind(d)local k=d and(d.id or d.name or''):match('^EM_BATTLE_FRONTIER_BATTLE_ARENA_(.+)$');return defs[k],k end
function R.profile(d)
 local p,k=R.kind(d);if not p then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.battleArena.enabled and d.pair=='building__battle_arena'and L and L.width==p[1]and L.height==p[2]and L:midAt(p[3],p[4])==p[5]then return c.homeRooms[k=='LOBBY'and'arenaLobby'or k=='CORRIDOR'and'arenaCorridor'or'arenaBattle']end
end
function R.doorPose(d,a)
 local _,k=R.kind(d);if not R.profile(d)or not a or a.y~=2 or k~='LOBBY'then return end
 local c=V.require('DioramaConfig').emeraldInteriors
 return{height=c.battleArena.wallHeight*32/48*c.heightScale,base=c.battleArena.daisHeight*c.heightScale,top=0}
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local _,k=R.kind(d);local c=V.require('DioramaConfig').emeraldInteriors;local h=c.battleArena.daisHeight;local px,pz=x+8,z+16
 if k=='LOBBY'then
  if pz<=96 or px>=64 and px<176 and pz<=128 then return h*c.heightScale end
  if px>=104 and px<=136 and pz>=128 and pz<=152 then return h*math.max(0,(152-pz)/24)*c.heightScale end
 elseif k=='BATTLE_ROOM'then
  if px>=64 and px<=192 and pz>=64 and pz<=144 or(px<64 or px>192)and pz>=88 and pz<=122 then return h*c.heightScale end
 end
end
function R.plan(d)
 if not R.profile(d)then return end
 local _,k=R.kind(d);local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.battleArena;local objects,mask={},{}
 local function clear(x,y,m)mask[y*L.width+x+1]=m or{mid=1,void=true}end
 local function add(kind,x,y,w,h,e)local o=e or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y);if m==1 then clear(x,y)elseif m==0x20a or m==0x20b then clear(x,y,0x202)end end end
 local function wall(x,y,w,h,base)
  add('arenaWall',x,y,w,h,{base=base or 0});for yy=y,y+h-1 do for xx=x,x+w-1 do clear(xx,yy)end end
 end
 local function plant(x,y,source,base,donor)
  add('arenaPlant',x,y,1,1,{sourceMid=source,base=base or 0});clear(x,y,donor or 0x201)
 end
 local function bench(x,y,w,h,extra)
  local o=add('arenaBench',x,y,w,h,extra);for yy=y,y+h-1 do for xx=x,x+w-1 do clear(xx,yy,0x202)end end;return o
 end
 if k=='CORRIDOR'then
  wall(0,0,6,3);wall(12,0,6,3);wall(3,8,12,4)
  plant(0,3,0x2a5,0,0x26e);plant(17,3,0x2a6,0,0x26f)
  plant(0,13,0x2a5,0,0x26e);plant(17,13,0x2a6,0,0x26f)
 else
  wall(0,0,16,3,k=='LOBBY'and c.daisHeight or 0)
  if k=='BATTLE_ROOM'then
   add('arenaMat',4,4,8,6);for y=4,9 do for x=4,11 do clear(x,y,0x202)end end
   for _,xx in ipairs({0,12})do add('arenaSideDais',xx,5,4,4);for y=5,8 do for x=xx,xx+3 do clear(x,y,0x202)end end end
  else
   -- Original wooden stage includes its narrow vertical front trim; keep the
   -- donor out of the native layout and move only the presentation surface.
   for y=3,7 do for x=0,15 do
    if y<=5 or x>=4 and x<=10 then
     add('arenaDais',x,y,1,1,{clean=L:midAt(x,y)==0x2a2 and 0x201 or nil});clear(x,y,0x202)
    end
   end end
   for _,a in ipairs({{0,6,4},{11,6,5},{4,8,2},{9,8,2}})do
    add('arenaRiser',a[1],a[2],a[3],1);for xx=a[1],a[1]+a[3]-1 do clear(xx,a[2],0x202)end
   end
   add('arenaRamp',6,8,3,2);for y=8,9 do for x=6,8 do clear(x,y)end end
   plant(7,3,0x2a2,c.daisHeight,0x202)
   bench(0,6,3,2,{monitor=true});add('arenaMonitor',0,6,3,2,{base=c.benchHeight})
   bench(5,8,1,2,{device=true});add('arenaDevice',5,8,1,2,{base=c.benchHeight})
   bench(0,10,1,2,{flowers={[0]=true}});plant(0,10,0x289,c.benchHeight,0x202)
   bench(12,6,1,2,{flowers={[0]=true}});plant(12,6,0x289,c.benchHeight,0x202)
   bench(14,6,1,2,{flowers={[0]=true}});plant(14,6,0x285,c.benchHeight,0x202)
   bench(15,6,1,7,{flowers={[4]=true,[5]=true}});plant(15,10,0x286,c.benchHeight,0x202);plant(15,11,0x28e,c.benchHeight,0x202)
   add('arenaPC',13,5,1,3);for y=5,7 do clear(13,y,0x202)end
  end
 end
 return objects,mask
end
local leaves={
 '......##........','.....#####.#....','....########....','.#.##########...','.#############..','################','################','################','###.######...###','###..######..###'}
function R.plantInside(s,t,m)
 if m==0x2a2 then if t<10 then return leaves[t+1]:sub(s+1,s+1)=='#'end;return t<13 or t<15 and s>=1 and s<15 or t==15 and(s>=2 and s<7 or s>=9 and s<14)end
 if t<6 then
  local red={'................','...##..#.#.##...','..###.#####.#...','....##..###.....','...#.##.####.#..','.###..####..##..'}
  local green={'....#...........','...#####........','..#####...####..','.######.########','..######.######.','...########.....'}
  local rows=(m==0x2a6 or m==0x285 or m==0x286)and green or red;return rows[t+1]:sub(s+1,s+1)=='#'
 end
 if t>=6 then return t<12 and s>=1 and s<15 or t<15 and s>=2 and s<14 or t==15 and(s>=3 and s<7 or s>=9 and s<13)end
 return s>=1 and s<15
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battleArena;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,proj,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,proj,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(m,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,c.contactStrength}end end end
 if o.kind=='arenaWall'then
  local h=o.h==64 and c.corridorWallHeight or c.wallHeight
  draw(0,o.h,nil,function(s,t)return{x+s,(o.base or 0)+h*(o.h-t)/o.h,z+o.h}end)
 elseif o.kind=='arenaDais'then
  draw(0,16,nil,function(s,t)return{x+s,c.daisHeight,z+t}end,function(s,t)return o.clean or L:midAt(o.x,o.y),s,t end)
  if o.x==4 and o.y>=6 or o.x==10 and o.y>=6 then
   local ss=o.x==4 and 0 or 16;patch(0x227,8,6,{x+ss,c.daisHeight,z},{x+ss,c.daisHeight,z+16},{x+ss,0,z+16},{x+ss,0,z},.97)
  end
 elseif o.kind=='arenaRamp'then
  draw(0,32,function(s)return s>=8 and s<40 end,function(s,t)return{x+s,c.daisHeight*math.max(0,(24-t)/24),z+t}end)
  draw(0,32,function(s)return s<8 or s>=40 end,function(s,t)return{x+s,0,z+t}end)
 elseif o.kind=='arenaRiser'then
  draw(0,10,nil,function(s,t)return{x+s,c.daisHeight*(10-t)/10,z}end,function(s,t)
   local m=L:midAt(o.x+math.floor(s/16),o.y);if m~=0x21d and m~=0x21e and m~=0x227 then m=0x227 end;return m,s%16,t
  end)
 elseif o.kind=='arenaMat'then
  local front=80
  draw(0,front,nil,function(s,t)return{x+s,c.daisHeight,z+t}end)
  for _,ss in ipairs({0,o.w})do patch(0x21d,8,1,{x+ss,c.daisHeight,z},{x+ss,c.daisHeight,z+front},{x+ss,0,z+front},{x+ss,0,z},.95)end
  draw(front,front+10,nil,function(s,t)return{x+s,c.daisHeight*(front+10-t)/10,z+front}end);contact(0,o.w,front)
 elseif o.kind=='arenaSideDais'then
  draw(8,42,nil,function(s,t)return{x+s,c.daisHeight,z+t}end)
  draw(42,48,nil,function(s,t)return{x+s,c.daisHeight*(48-t)/6,z+42}end);contact(0,o.w,42)
 elseif o.kind=='arenaPlant'then
  local m=o.sourceMid
  draw(0,16,function(s,t)
   if not R.plantInside(s,t,m)then return false end
   return true
  end,function(s,t)return{x+s,(o.base or 0)+c.plantHeight*(16-t)/16,z+16}end,function(s,t)return m,s,t end)
  if(o.base or 0)==0 then contact(2,14,16)end
 elseif o.kind=='arenaBench'then
  local last=o.h-1;local split=last-8
  local function src(s,t)
   local m,u,v=source(s,t);local row=math.floor(t/16)
   if o.monitor then m=row==0 and 0x287 or 0x297
   elseif o.device then m=row==0 and 0x287 or 0x297
   elseif o.flowers and o.flowers[row]then m=row==math.floor((o.h-1)/16)and 0x297 or 0x287 end
   return m,u,v
  end
  local function inside(s,t)return t<last-3 or s<4 or s>=o.w-4 end
  draw(0,split,nil,function(s,t)return{x+s,c.benchHeight,z+t+4}end,src)
  draw(split,last,inside,function(s,t)return{x+s,c.benchHeight*(last-t)/(last-split),z+split+4}end,src)
  for _,ss in ipairs({0,o.w})do patch(0x287,ss==0 and 0 or 15,4,{x+ss,c.benchHeight,z+4},{x+ss,c.benchHeight,z+split+4},{x+ss,0,z+split+4},{x+ss,0,z+4},.98)end
  contact(0,o.w,split+4)
 elseif o.kind=='arenaMonitor'or o.kind=='arenaDevice'or o.kind=='arenaPC'then
  local monitor=o.kind=='arenaMonitor';local pc=o.kind=='arenaPC';local a=monitor and 1 or pc and 8 or 4;local last=monitor and 24 or pc and 40 or 21
  local h=monitor and c.monitorHeight or pc and c.pcHeight or c.deviceHeight
  local function inside(s,t)if monitor then local inset=t==1 and 20 or t==2 and 10 or t<=18 and 9 or t==19 and 10 or t<=21 and 18 or t==22 and 19 or 20;return s>=inset and s<48-inset end;return s>=1 and s<15 end
  draw(a,last,inside,function(s,t)return{x+s,(o.base or 0)+h*(last-t)/(last-a),z+last}end)
  if pc then contact(1,15,last)end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
