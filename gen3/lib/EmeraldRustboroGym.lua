-- Native rock-gym surfaces. This module owns presentation only, never puzzles/events.
local V=...
local R={}
local upper={ [0x218]=true,[0x219]=true,[0x21a]=true,[0x21b]=true,
 [0x22c]=true,[0x22d]=true,[0x22e]=true,[0x230]=true,[0x232]=true,
 [0x233]=true,[0x234]=true,[0x235]=true }
local front={ [0x228]=true,[0x229]=true,[0x22a]=true,[0x22b]=true }
local full={ [0x21d]=true,[0x220]=true,[0x221]=true,[0x222]=true,
 [0x223]=true,[0x224]=true,[0x225]=true,[0x231]=true }
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.rustboroGym.enabled and (d.id or d.name)=='EM_RUSTBORO_CITY_GYM'
  and d.pair=='building__rustboro_gym' and L and L.width==12 and L.height==20
  and L:midAt(5,0)==0x21f and L:midAt(2,17)==0x21e then return c.homeRooms.rustboroGym end
end
function R.topInside(m,s,t)
 if full[m]then return true end
 if front[m]then return t<8 end
 if upper[m]then return t>=9 or t==8 and (s>=1 and s<7 or s>=9 and s<15)end
 return false
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o end
 for y=0,19 do for x=0,11 do local m=L:midAt(x,y);local k=y*12+x+1
  if m==1 or y<2 then mask[k]={mid=1,void=true}
  elseif m~=6 and m~=7 then mask[k]=0x201 end
  if upper[m]or full[m]or front[m]then add('rustGymRock',x,y,1,1,{mid=m})end
 end end
 add('rustGymWall',0,0,11,2)
 add('rustGymPodium',3,2,5,2)
 add('rustGymStatue',2,17,1,2);add('rustGymStatue',8,17,1,2)
 return objects,mask
end
local podiumBounds={}
for t=0,31 do local a=({[11]=1,[12]=1,[19]=1,[20]=1,[25]=1,[26]=2,[27]=3,[28]=3,[29]=4,[30]=5,[31]=7})[t]or 0;podiumBounds[t]={a,80-a}end
function R.podiumInside(s,t)local b=podiumBounds[t];return b and s>=b[1]and s<b[2]end
function R.statueInside(s,t)
 local a=({6,4,2,1})[t+1]or 0;return t>=0 and t<32 and s>=a and s<16-a
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors
 local foot=z+16
 if x+8>=48 and x+8<128 and foot>=32 and foot<64 then
  return cfg.rustboroGym.podiumHeight*cfg.heightScale*math.min(1,(64-foot)/6)
 end
 return 0
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.rustboroGym;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function band(a,b,project,inside)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and (not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function contact(a,b,zz)if contacts then for s=a+3,b-2,6 do contacts[#contacts+1]={x+s,z+zz,4,1.5,c.contactStrength}end end end
 if o.kind=='rustGymRock'then
  local function inside(s,t)return R.topInside(o.mid,s,t)end
  band(0,16,function(s,t)return{x+s,c.rockHeight,z+t}end,inside)
  if front[o.mid]then band(8,16,function(s,t)return{x+s,c.rockHeight*(16-t)/8,z+8}end);contact(0,16,8)end
  local function neighbor(s,t)
   local m=L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16));return R.topInside(m,s%16,t%16)
  end
  -- Close only exposed boundaries; adjacent top tiles share one continuous volume.
  local function side(ax,az,bx,bz)
   G.quad(out,{x+ax,c.rockHeight,z+az},{x+bx,c.rockHeight,z+bz},{x+bx,0,z+bz},{x+ax,0,z+az},G.uv(ts,0x229,5,8,6,16,.5),.97)
  end
  for t=0,15 do for s=0,15 do if inside(s,t)then
   if not neighbor(s-1,t)then side(s,t,s,t+1)end
   if not neighbor(s+1,t)then side(s+1,t+1,s+1,t)end
   if not neighbor(s,t-1)then side(s+1,t,s,t)end
   if not neighbor(s,t+1)and not(front[o.mid]and t==7)then side(s,t+1,s+1,t+1)end
  end end end
 elseif o.kind=='rustGymWall'then
  band(6,32,function(s,t)return{x+s,c.wallHeight*(32-t)/26,z+32}end,function(s,t)return t>=22 or s>=14 and s<162 end)
 elseif o.kind=='rustGymStatue'then
  band(0,32,function(s,t)return{x+s,c.statueHeight*(32-t)/32,z+28}end,R.statueInside);contact(0,16,28)
 elseif o.kind=='rustGymPodium'then
  band(0,26,function(s,t)return{x+s,c.podiumHeight,z+t}end,R.podiumInside)
  band(26,32,function(s,t)return{x+s,c.podiumHeight*(32-t)/6,z+26}end,R.podiumInside);contact(6,74,26)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
