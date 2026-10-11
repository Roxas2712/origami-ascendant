-- Native electric gym: read live metatiles; never own the switch state.
local V=...
local M={}
local contours=V.data('EmeraldMauvilleContours')
local poleTop={[0x210]=true,[0x211]=true,[0x236]=true,[0x237]=true,[0x250]=true,[0x251]=true}
local poleBottom={[0x218]=true,[0x219]=true,[0x240]=true,[0x241]=true,[0x242]=true,[0x243]=true,[0x246]=true,[0x247]=true,[0x24e]=true}
local beamTop={[0x220]=true,[0x221]=true,[0x222]=true,[0x223]=true}
function M.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.mauvilleGym.enabled and(d.id or d.name)=='EM_MAUVILLE_CITY_GYM'
  and d.pair=='building__mauville_gym'and L and L.width==10 and L.height==22
  and L:midAt(4,0)==0x24a and L:midAt(3,17)==0x216 then return c.homeRooms.mauvilleGym end
end
function M.covered(mid,s,t,floor)
 local rows=(floor and contours.floor or contours)[mid];if not rows or s<0 or s>=16 or t<0 or t>=16 then return false end
 return math.floor(tonumber(rows:sub(t*4+1,t*4+4),16)/2^s)%2==1
end
function M.plan(d)
 if not M.profile(d)then return end
 local L=d.midLayout;local objects,mask,claimed,poles={},{},{},{}
 local function add(kind,x,y,w,h,extra)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o
 end
 local function wall(x,y,w)
  add('mauvGymWall',x,y,w,2)
  for yy=y,y+1 do for xx=x,x+w-1 do claimed[yy*10+xx+1]=true end end
 end
 wall(2,0,6);wall(0,7,3);wall(7,6,3);wall(7,13,3)
 for y=0,20 do for x=0,9 do if poleTop[L:midAt(x,y)]then
  local bottom=y+1
  while (L:midAt(x,bottom)==0x246 or L:midAt(x,bottom)==0x247)and bottom<21 do bottom=bottom+1 end
  if poleBottom[L:midAt(x,bottom)]then
   poles[#poles+1]={x=x,y=y,bottom=bottom};add('mauvGymPole',x,y,1,bottom-y+1)
  end
 end end end
 for y=0,21 do for x=0,9 do
  local k=y*10+x+1;local m=L:midAt(x,y)
  if m==1 or claimed[k]then mask[k]={mid=1,void=true}
  elseif m~=6 and m~=7 and m~=0x205 and m~=0x206 then mask[k]=0x20a end
  if beamTop[m]then
   local bottom=y+1
   for _,p in ipairs(poles)do if math.abs(p.x-x)<=2 and p.y<=y and p.bottom>=y+1 then bottom=math.max(bottom,p.bottom)end end
   add('mauvGymBeamH',x,y,1,2,{base=(bottom-y+1)*16})
  end
  if m==0x240 or m==0x241 then add('mauvGymBeamV',x,y,1,2)end
  if m==0x216 and L:midAt(x,y+1)==0x21e then add('mauvGymStatue',x,y,1,2)end
  if contours[m]and not claimed[k]and not poleTop[m]and not poleBottom[m]and m~=0x216 and m~=0x21e then
   mask[k]={mid=1,void=true};add('mauvGymBorder',x,y,1,1,{mid=m})
  end
 end end
 add('mauvGymPodium',3,2,4,2)
 return objects,mask
end
function M.actorHeight(d,x,z)
 if not M.profile(d)then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local foot=z+16
 if x+8>=48 and x+8<112 and foot>=32 and foot<64 then return cfg.mauvilleGym.podiumHeight*cfg.heightScale*math.min(1,(64-foot)/6)end
 return 0
end
function M.podiumInside(s,t)
 local a=({5,4,3,2})[t+1]or(t==30 and 2 or t==31 and 3 or 1)
 local b=({59,60,61,63})[t+1]or(t>=29 and 92-t or 64)
 return t>=0 and t<32 and s>=a and s<b
end
function M.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.mauvilleGym;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)
  local mid=L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16))
  if o.kind=='mauvGymPole'then mid=({[0x240]=0x242,[0x241]=0x243})[mid]or mid end
  return mid,s%16,t%16
 end
 local function inside(s,t)local m,sx,sy=source(s,t);return M.covered(m,sx,sy)end
 local function band(a,b,project,cut,material)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and(not cut or cut(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do if material then v[6]=material end;out[#out+1]=v end
 end
 local function contact(width,depth)if contacts then contacts[#contacts+1]={x+width/2,z+depth,width*.45,1.5,c.contactStrength}end end
 if o.kind=='mauvGymPole'or o.kind=='mauvGymStatue'then
  local h=o.kind=='mauvGymPole'and c.poleHeight*o.h/32 or c.statueHeight
  band(0,o.h,function(s,t)return{x+s,h*(o.h-t)/o.h,z+o.h-4}end,inside);contact(16,o.h-4)
 elseif o.kind=='mauvGymBeamH'then
  band(0,32,function(s,t)return{x+s,c.poleHeight*(o.base-t)/32,z+o.base-4}end,nil,G.ELECTRIC_BEAM)
 elseif o.kind=='mauvGymBeamV'then
  band(0,32,function(s,t)return{x+8,c.beamHeight+(8-s)*.25,z+t}end,nil,G.ELECTRIC_BEAM)
 elseif o.kind=='mauvGymWall'then
  local h=o.y==0 and c.backWallHeight or c.partitionHeight
  band(4,32,function(s,t)return{x+s,h*(32-t)/28,z+32}end,inside)
  local vv=V.require('PaperSprite').build(ts,o.w,32,function(s,t)return 0x213,s%16,t%4 end,inside,0,32,1,nil,function(s,t)return{x+s,h,z+t}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
  local function side(ax,az,bx,bz)
   G.quad(out,{x+ax,h,z+az},{x+bx,h,z+bz},{x+bx,0,z+bz},{x+ax,0,z+az},G.uv(ts,0x20e,8,0,9,16,.5))
  end
  for t=0,31 do for s=0,o.w-1 do if inside(s,t)then
   if s==0 or not inside(s-1,t)then side(s,t,s,t+1)end
   if s==o.w-1 or not inside(s+1,t)then side(s+1,t+1,s+1,t)end
  end end end
  contact(o.w,32)
 elseif o.kind=='mauvGymBorder'then
  -- Only the native floor side of the cutaway border belongs to the room.
  local vv=V.require('PaperSprite').build(ts,16,16,function(s,t)return 0x20a,s,t end,function(s,t)
   return M.covered(o.mid,s,t,true)
  end,0,16,1,nil,function(s,t)return{x+s,0,z+t}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
  band(0,16,function(s,t)return{x+s,c.borderHeight,z+t}end,inside)
  local function side(ax,az,bx,bz)
   G.quad(out,{x+ax,c.borderHeight,z+az},{x+bx,c.borderHeight,z+bz},{x+bx,0,z+bz},{x+ax,0,z+az},G.uv(ts,0x20e,8,0,9,16,.5))
  end
  for t=0,15 do for s=0,15 do if inside(s,t)then
   local function occupied(s,t)return M.covered(L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16)end
   if not occupied(s-1,t)then side(s,t,s,t+1)end
   if not occupied(s+1,t)then side(s+1,t+1,s+1,t)end
   if not occupied(s,t-1)then side(s+1,t,s,t)end
   if not occupied(s,t+1)then side(s,t+1,s+1,t+1)end
  end end end
 elseif o.kind=='mauvGymPodium'then
  band(0,26,function(s,t)return{x+s,c.podiumHeight,z+t}end,M.podiumInside)
  band(26,32,function(s,t)return{x+s,c.podiumHeight*(32-t)/6,z+26}end,M.podiumInside);contact(64,26)
  -- Close the rim with the original grey platform material, not a black skirt.
  local function side(ax,az,bx,bz)
   G.quad(out,{x+ax,c.podiumHeight,z+az},{x+bx,c.podiumHeight,z+bz},{x+bx,0,z+bz},{x+ax,0,z+az},G.uv(ts,0x224,8,8,9,9,.5))
  end
  for t=0,25 do for s=0,63 do if M.podiumInside(s,t)then
   if not M.podiumInside(s-1,t)then side(s,t,s,t+1)end
   if not M.podiumInside(s+1,t)then side(s+1,t+1,s+1,t)end
   if not M.podiumInside(s,t-1)then side(s+1,t,s,t)end
  end end end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return M
