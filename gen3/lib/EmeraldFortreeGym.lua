-- Measured bamboo maze. Native cells, gate pivots and trainer events are read only.
local V=...
local R={}
local caps={}
for _,m in ipairs({0x208,0x20a,0x20b,0x218,0x228,0x235,0x239,0x23c,0x23d})do caps[m]=0 end
for _,m in ipairs({0x209,0x20e,0x212,0x219,0x21a,0x220,0x222,0x223,0x224,0x225,0x229,0x22a,0x22b,0x22c,0x23b})do caps[m]=8 end
local small={[0x229]=8,[0x233]=8,[0x234]=7,[0x238]=7,[0x23a]=8,[0x23b]=8}
local wall={};for _,m in ipairs({0x20e,0x20f,0x213,0x214,0x215,0x216,0x217,0x226,0x22a,0x236,0x237,0x23c,0x23d,0x23e,0x23f,0x246,0x247,0x24f})do wall[m]=true end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.fortreeGym.enabled and(d.id or d.name)=='EM_FORTREE_CITY_GYM'and d.pair=='building__fortree_gym'
  and L and L.width==20 and L.height==26 and L:midAt(0,0)==0x20f and L:midAt(15,24)==6 then return c.homeRooms.fortreeGym end
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w;o.h=h;o.noContact=true;objects[#objects+1]=o end
 for y=0,25 do for x=0,19 do
  local m=L:midAt(x,y);local k=y*20+x+1
  if m==1 then mask[k]={mid=1,void=true}elseif m~=6 and m~=7 then mask[k]=0x202 end
  if caps[m]then add('fortGymPole',x,y+caps[m]/16,16,32)end
  if small[m]then for _,sx in ipairs({0,8})do for _,sy in ipairs({0,small[m]})do add('fortGymPost',x+sx/16,y+sy/16,8,8)end end end
  if m==0x227 then add('fortGymStatue',x,y,16,32)end
 end end
 for x=0,19 do
  local bottom=0;for y=0,2 do if wall[L:midAt(x,y)]then bottom=y+1 end end
  if bottom>0 then add('fortGymWall',x,0,16,bottom*16)end
 end
 add('fortGymPodium',13,2,80,32)
 return objects,mask
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local foot=z+16
 if x+8>=208 and x+8<288 and foot>=32 and foot<64 then return c.fortreeGym.podiumHeight*c.heightScale*math.min(1,(64-foot)/8)end
 return 0
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.fortreeGym;local first=#out+1;local G=V.require('WorldGeometry');local B=V.require('BuildingMesh')
 local function poleSource(s,t)return t<16 and 0x20b or 0x211,s,t%16 end
 local function source(s,t)
  if o.kind=='fortGymPole'then return poleSource(s,t)
  elseif o.kind=='fortGymPost'then return 0x234,s,t
  else return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 end
 local function notFloor(m,s,t)
  local r,g,b=B.pixel(ts,m,s,t);r=math.floor(r*255+.5);g=math.floor(g*255+.5);b=math.floor(b*255+.5)
  return not(r==222 and g==222 and b==140 or r==181 and g==189 and b==90)
 end
 local function inside(s,t)
  local m,sx,sy=source(s,t)
  if o.kind=='fortGymWall'then
   if not wall[m]then return false end
   if caps[m]and sy>=caps[m]then local pm,px,py=poleSource(sx,sy-caps[m]);if notFloor(pm,px,py)then return false end end
  end
  return notFloor(m,sx,sy)
 end
 local function band(a,b,project,cut)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and(cut or inside)(s,t)end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function contact(w,zz)if contacts then contacts[#contacts+1]={x+w/2,z+zz,w*.42,1.5,c.contactStrength}end end
 if o.kind=='fortGymPole'then
  -- The canopy starts in the walkable row behind its blocked foot cell.
  -- Anchor at source +24, not +14: otherwise poles cover the NPC's cell.
  band(0,14,function(s,t)return{x+s,c.poleHeight,z+10+t}end)
  band(14,32,function(s,t)return{x+s,c.poleHeight*(32-t)/18,z+24}end)
  -- Native stem columns close both sides; same green art, no black wedges.
  for _,a in ipairs({{1,1},{15,14}})do
   G.quad(out,{x+a[1],c.poleHeight,z+15},{x+a[1],c.poleHeight,z+24},{x+a[1],0,z+24},{x+a[1],0,z+15},G.uv(ts,0x211,a[2],0,a[2]+1,12,.49),.88)
  end
  contact(16,24)
 elseif o.kind=='fortGymPost'then
  band(0,4,function(s,t)return{x+s,c.postHeight,z+4+t}end)
  band(4,8,function(s,t)return{x+s,c.postHeight*(8-t)/4,z+8}end);contact(8,8)
 elseif o.kind=='fortGymWall'then
  local h=c.wallHeight*o.h/32
  band(0,6,function(s,t)return{x+s,h,z+o.h-6+t}end)
  band(6,o.h,function(s,t)return{x+s,h*(o.h-t)/(o.h-6),z+o.h}end);contact(16,o.h)
 elseif o.kind=='fortGymStatue'then
  band(0,32,function(s,t)return{x+s,c.statueHeight*(32-t)/32,z+28}end);contact(16,28)
 elseif o.kind=='fortGymPodium'then
  local cut=V.require('EmeraldPetalburgGym').podiumInside
  band(0,24,function(s,t)return{x+s,c.podiumHeight,z+t}end,cut)
  band(24,32,function(s,t)return{x+s,c.podiumHeight*(32-t)/8,z+24}end,cut);contact(80,24)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
