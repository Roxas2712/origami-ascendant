-- Measured Elite Four chambers and connecting stair halls. Native doors,
-- trainer scripts, cell collision and metatile overrides stay authoritative.
local V=...
local R={}
local rooms={SIDNEYS_ROOM={floor=0x22c,style='leagueWarm'},PHOEBES_ROOM={floor=0x25c,style='leagueGhost'},GLACIAS_ROOM={floor=0x28c,style='leagueIce'},DRAKES_ROOM={floor=0x2bc,style='leagueDragon'}}
function R.kind(d)
 local id=d.id or d.name or'';local key=id:match('^EM_EVER_GRANDE_CITY_(.+)$')
 if rooms[key]then return 'room',rooms[key]end
 if key and key:match('^HALL[1-5]$')then return 'hall',key end
end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local k,v=R.kind(d);local L=d.midLayout
 if not(c.enabled and c.leagueRooms.enabled and k and L and d.pair=='building__elite_four')then return end
 if k=='room'then
  if L.width~=14 or L.height~=14 or L:midAt(2,4)~=v.floor then return end
  return c.homeRooms[v.style]
 end
 if L.width~=12 or L.height~=(v=='HALL4'and 34 or 14)or L:midAt(3,5)~=0x2d8 then return end
 return c.homeRooms[v=='HALL4'and'leagueLongHall'or'leagueHall']
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 if R.kind(d)~='hall'then return 0 end
 local cfg=V.require('DioramaConfig').emeraldInteriors
 local bottom=(d.midLayout.height-1)*16
 return cfg.leagueRooms.hallRise*cfg.heightScale*math.max(0,math.min(1,(bottom-z-16)/(bottom-80)))
end
function R.doorPose(d,anim)
 if not R.profile(d)or not anim or anim.y~=2 then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.leagueRooms
 return{height=32*c.wallHeight/42*cfg.heightScale,base=(R.kind(d)=='hall'and c.hallRise or 0)*cfg.heightScale,top=0}
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local k,v=R.kind(d);local objects,mask={},{}
 local function clear(x,y,w,h,mid)
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]=mid or{mid=1,void=true}end end
 end
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind='league'..kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o end
 for y=0,L.height-1 do for x=0,L.width-1 do if L:midAt(x,y)==1 then clear(x,y,1,1)end end end
 if k=='room'then
  for x=0,12 do add('Wall',x,0,1,3);clear(x,0,1,3)end
  for _,x in ipairs({0,11})do add('Alcove',x,4,2,6,{right=x==11,floor=v.floor});clear(x,4,2,6,v.floor)end
  clear(0,10,13,1,v.floor) -- native foreground wall cap moves with the cutaway wall
  for x=0,12 do if x<5 or x>7 then add('Cutaway',x,11,1,3);clear(x,11,1,3,v.floor)else clear(x,11,1,1,v.floor)end end
  if L:midAt(6,12)==0x206 then add('EntryGate',6,12,1,2);clear(6,12,1,2,v.floor)end
 else
  for x=0,10 do add('Wall',x,0,1,3,{raised=true});clear(x,0,1,3)end
  add('Landing',0,3,11,2);clear(0,3,11,2)
  add('Stairs',3,5,5,L.height-6);clear(0,5,11,L.height-5)
 end
 return objects,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.leagueRooms;local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside,src)
  local v=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,q in ipairs(v)do out[#out+1]=q end
 end
 local function quad(a,b,h,uv,shade)
  G.quad(out,{a[1],h,a[2]},{b[1],h,b[2]},{b[1],0,b[2]},{a[1],0,a[2]},uv,shade or 1)
 end
 local function contact(a,b,zz)if contacts then for s=a+4,b-1,8 do contacts[#contacts+1]={x+s,z+zz,5,1.4,c.contactStrength}end end end
 if o.kind=='leagueWall'then
  local base=o.raised and c.hallRise or 0
  draw(0,6,function(s,t)return{x+s,base+c.wallHeight,z+42+t}end)
  draw(6,48,function(s,t)return{x+s,base+c.wallHeight*(48-t)/42,z+48}end)
  contact(0,o.w,48)
 elseif o.kind=='leagueCutaway'then
  draw(0,16,function(s,t)return{x+s,c.cutawayHeight,z+32+t}end)
  draw(16,48,function(s,t)return{x+s,c.cutawayHeight*(48-t)/32,z+48}end)
 elseif o.kind=='leagueEntryGate'then
  draw(0,32,function(s,t)return{x+s,c.cutawayHeight*(32-t)/32,z+32}end)
 elseif o.kind=='leagueLanding'then
  draw(0,32,function(s,t)return{x+s,c.hallRise,z+t}end)
  quad({x,z},{x,z+32},c.hallRise,G.uv(ts,0x2d0,0,0,1,16,.5),.9)
  quad({x+o.w,z+32},{x+o.w,z},c.hallRise,G.uv(ts,0x2d0,15,0,16,16,.5),.9)
  -- Native grey fascia closes the landing outside the stair opening.
  draw(0,32,function(s,t)return{x+s,c.hallRise*(32-t)/32,z+32}end,function(s)return s<48 or s>=128 end,function(s,t)return L:midAt(math.floor(s/16),5+math.floor(t/16)),s%16,t%16 end)
 elseif o.kind=='leagueStairs'then
  local count=o.h/8;local rise=c.hallRise/count
  -- Six source rows on each tread, two on each riser. No floor quads beneath.
  for a=0,o.h-1,8 do local h=c.hallRise-a/8*rise;local low=h-rise
   draw(a,a+6,function(s,t)return{x+s,h,z+t}end,function(s)return s>=16 and s<64 end)
   draw(a+6,a+8,function(s,t)return{x+s,h-(t-a-6)/2*rise,z+a+6}end,function(s)return s>=16 and s<64 end)
   draw(a+6,a+8,function(s,t)return{x+s,low,z+t}end,function(s)return s>=16 and s<64 end,function(s,t)return source(s,a)end)
  end
  -- Original orange rails: follow the stair slope and retain their end caps.
  local function height(t)return c.hallRise*(1-t/o.h)end
  draw(0,o.h,function(s,t)return{x+s,height(t)+c.railHeight,z+t}end,function(s,t)return (s>=4 and s<16 or s>=64 and s<76)and(t>=2 or s>=6 and s<74)end)
  for _,s in ipairs({4,16,64,76})do
   G.quad(out,{x+s,c.hallRise+c.railHeight,z},{x+s,c.railHeight,z+o.h},{x+s,0,z+o.h},{x+s,c.hallRise,z},G.uv(ts,s<32 and 0x2e0 or 0x2e3,6,0,7,16,.5),.94)
  end
 elseif o.kind=='leagueAlcove'then
  -- These are native inset arena decorations, not furniture. Preserve their
  -- full motifs; lift only the rounded stone rim, leaving the inset at floor.
  local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
  local floor={};for t=0,15 do for s=0,15 do floor[rgb(B.pixel(ts,o.floor,s,t))]=true end end
  local function inside(s,t)local m,u,v=source(s,t);return not floor[rgb(B.pixel(ts,m,u,v))]end
  local function rim(s,t)local u=o.right and 31-s or s;return t<22 or t>=80 or u>=22 end
  draw(0,o.h,function(s,t)return{x+s,c.alcoveRim,z+t}end,function(s,t)return inside(s,t)and rim(s,t)end)
  draw(0,o.h,function(s,t)return{x+s,.1,z+t}end,function(s,t)return inside(s,t)and not rim(s,t)end)
  -- Pixel-matched contour sides connect the rim and its lower inset.
  for t=0,o.h-1 do for s=0,o.w-1 do if inside(s,t)and rim(s,t)then
   local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
   local function edge(ss,tt,a,b)if ss<0 or ss>=o.w or tt<0 or tt>=o.h or not(inside(ss,tt)and rim(ss,tt))then quad(a,b,c.alcoveRim,uv,.94)end end
   edge(s-1,t,{x+s,z+t},{x+s,z+t+1});edge(s+1,t,{x+s+1,z+t+1},{x+s+1,z+t})
   edge(s,t-1,{x+s+1,z+t},{x+s,z+t});edge(s,t+1,{x+s,z+t+1},{x+s+1,z+t+1})
  end end end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
