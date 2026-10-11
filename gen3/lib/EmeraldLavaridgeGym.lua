-- Two measured ash-gym floors. All traps, trainers and warps remain native.
local V=...
local R={}
local contours=V.data('EmeraldLavaridgeContours')
local top={[0x206]=true,[0x214]=true,[0x216]=true,[0x22b]=true}
local border={[0x204]=true,[0x20b]=true,[0x20c]=true,[0x228]=true,[0x229]=true,[0x230]=true,[0x231]=true}
local holes={[0x212]=true,[0x213]=true,[0x21d]=true,[0x227]=true,[0x238]=true,[0x239]=true,[0x23a]=true,[0x23b]=true,[0x23c]=true}
-- Rectangles end on the native one-way ledge row; heights count low steps.
local terraces={
 [1]={{11,15,9,13,1},{5,6,9,15,1}},
 [2]={{0,3,6,12,1},{5,6,6,11,1},{10,12,6,10,2},{10,12,11,15,1},{14,16,6,10,1}},
}
local function level(d)return(d.id or d.name)=='EM_LAVARIDGE_TOWN_GYM_1F'and 1 or 2 end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout;local id=d.id or d.name
 if c.enabled and c.lavaridgeGym.enabled and(id=='EM_LAVARIDGE_TOWN_GYM_1F'or id=='EM_LAVARIDGE_TOWN_GYM_B1F')
  and d.pair=='building__lavaridge_gym'and L and L.width==18 and L.height==20
  and L:midAt(0,0)==(level(d)==1 and 0x206 or 0x22b)and L:midAt(1,3)==0x208 then
  return c.homeRooms[level(d)==1 and 'lavaridgeUpper'or'lavaridgeLower']
 end
end
function R.covered(mid,s,t)
 local rows=contours[mid];if not rows or s<0 or s>=16 or t<0 or t>=16 then return false end
 return math.floor(tonumber(rows:sub(t*4+1,t*4+4),16)/2^s)%2==1
end
function R.height(n,x,y)
 local h=V.require('DioramaConfig').emeraldInteriors.lavaridgeGym.stepHeight
 for _,a in ipairs(terraces[n])do if x>=a[1]and x<=a[2]and y>=a[3]and y<=a[4]then return h*a[5]end end
 return 0
end
function R.wallTop(n,L,x,y)
 local c=V.require('DioramaConfig').emeraldInteriors.lavaridgeGym;local m=L:midAt(x,y)
 if top[m]then return(y==0 and c.backWallHeight or c.partitionHeight)+R.height(n,x,y+2)end
 if m==0x20e or m==0x21e or m==0x233 then return R.wallTop(n,L,x,y-1)end
 if border[m]then
  if y<2 then return c.backWallHeight end
  local h=math.max(R.height(n,x-1,y),R.height(n,x+1,y))
  for _,dy in ipairs({0,-1})do for _,dx in ipairs({-1,1})do if top[L:midAt(x+dx,y+dy)]then h=math.max(h,R.height(n,x+dx,y+dy+2))end end end
  return c.partitionHeight+h
 end
 return 0
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.lavaridgeGym
 local cx,cy=math.floor((x+8)/16),math.floor((z+15.999)/16);local n=level(d)
 local h=R.height(n,cx,cy);local m=d.midLayout:midAt(cx,cy)
 if m==0x225 or m==0x226 then h=h-c.stepHeight*math.max(0,math.min(1,(z+16-cy*16)/16))end
 if n==1 and x+8>=176 and x+8<256 and z+16>=152 and z+16<176 then h=h+c.podiumHeight*math.min(1,(176-z-16)/6)end
 return h*cfg.heightScale
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local n=level(d);local objects,mask,claimed={},{},{}
 local function add(kind,x,y,w,h,extra)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.level=n;o.noContact=true;objects[#objects+1]=o
 end
 local function blank(x,y)mask[y*18+x+1]={mid=1,void=true}end
 for y=0,18 do for x=0,16 do if top[L:midAt(x,y)]then
  add('lavaGymWall',x,y,1,2,{base=R.height(n,x,y+2)});blank(x,y);blank(x,y+1)
  claimed[y*18+x+1]=true;claimed[(y+1)*18+x+1]=true
 end end end
 for y=0,19 do for x=0,17 do local m=L:midAt(x,y);local k=y*18+x+1;local h=R.height(n,x,y)
  if m==1 then blank(x,y)
  elseif not claimed[k]then
   blank(x,y)
   if border[m]then add('lavaGymBorder',x,y,1,1,{mid=m})
   elseif m==0x225 or m==0x226 then add('lavaGymStep',x,y,1,1,{base=h})
   elseif holes[m]then add('lavaGymHole',x,y,1,1,{base=h,mid=m})
   else
    add('lavaGymFloor',x,y,1,1,{base=h,mid=(m==6 or m==7)and m or 0x208})
    if(m==0x215 or m==0x217)and L:midAt(x,y+1)==0x21f then add('lavaGymStatue',x,y,1,2,{base=h})end
   end
  end
 end end
 if n==1 then add('lavaGymPodium',11,9,5,2,{base=R.height(n,13,9)})end
 return objects,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.lavaridgeGym;local G=V.require('WorldGeometry');local first=#out+1;local base=o.base or 0
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function inside(s,t)local m,sx,sy=source(s,t);return R.covered(m,sx,sy)end
 local function band(a,b,project,cut,src,shade)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not cut or cut(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do if shade then v[6]=shade end;out[#out+1]=v end
 end
 local function side(ax,az,bx,bz,hi,lo,m)
  G.quad(out,{x+ax,hi,z+az},{x+bx,hi,z+bz},{x+bx,lo,z+bz},{x+ax,lo,z+az},G.uv(ts,m or 0x225,8,10,9,14,.5),lo+base<0 and G.HANGING_FACADE or 1)
 end
 local function floor(mid,h,cut)
  band(0,16,function(s,t)return{x+s,h,z+t}end,cut,function(s,t)return mid,s,t end)
 end
 if o.kind=='lavaGymFloor'then
  floor(o.mid,0)
 elseif o.kind=='lavaGymHole'then
  floor(o.mid,0,function(s,t)return not inside(s,t)end)
  floor(o.mid,-c.holeDepth,inside)
  for t=0,15 do for s=0,15 do if inside(s,t)then
   if not R.covered(o.mid,s-1,t)then side(s,t,s,t+1,0,-c.holeDepth)end
   if not R.covered(o.mid,s+1,t)then side(s+1,t+1,s+1,t,0,-c.holeDepth)end
   if not R.covered(o.mid,s,t-1)then side(s+1,t,s,t,0,-c.holeDepth)end
   if not R.covered(o.mid,s,t+1)then side(s,t+1,s+1,t+1,0,-c.holeDepth)end
  end end end
 elseif o.kind=='lavaGymStep'then
  band(0,8,function(s,t)return{x+s,0,z+t}end)
  band(8,16,function(s,t)return{x+s,-c.stepHeight*(t-8)/8,z+8}end)
  floor(0x208,-c.stepHeight,function(s,t)return t>=8 end)
  if contacts then contacts[#contacts+1]={x+8,z+9,7,1.2,c.contactStrength}end
 elseif o.kind=='lavaGymStatue'then
  band(0,32,function(s,t)return{x+s,c.statueHeight*(32-t)/32,z+28}end,inside)
  if contacts then contacts[#contacts+1]={x+8,z+28,7,1.5,c.contactStrength}end
 elseif o.kind=='lavaGymPodium'then
  band(0,26,function(s,t)return{x+s,c.podiumHeight,z+t}end,inside)
  band(26,32,function(s,t)return{x+s,c.podiumHeight*(32-t)/6,z+26}end,inside)
  for t=0,25 do for s=0,79 do if inside(s,t)then
   if s==0 or not inside(s-1,t)then side(s,t,s,t+1,c.podiumHeight,0,0x221)end
   if s==79 or not inside(s+1,t)then side(s+1,t+1,s+1,t,c.podiumHeight,0,0x223)end
  end end end
 elseif o.kind=='lavaGymWall'then
  local h=o.y==0 and c.backWallHeight or c.partitionHeight
  band(4,32,function(s,t)return{x+s,h*(32-t)/28,z+32}end)
  band(0,32,function(s,t)return{x+s,h,z+t}end,nil,function(s,t)return o.level==1 and 0x206 or 0x22b,s%16,3 end)
  -- Tiles share top planes; only expose the ends of each connected wall run.
  if not top[L:midAt(o.x-1,o.y)]then side(0,0,0,32,h,0,o.level==1 and 0x20e or 0x233)end
  if not top[L:midAt(o.x+1,o.y)]then side(16,32,16,0,h,0,o.level==1 and 0x20e or 0x233)end
 elseif o.kind=='lavaGymBorder'then
  local h=R.wallTop(o.level,L,o.x,o.y)
  floor(o.mid,h)
  local face=o.level==1 and 0x20e or 0x233
  local function edge(dx,dy,ax,az,bx,bz)local lo=R.wallTop(o.level,L,o.x+dx,o.y+dy);if lo<h then side(ax,az,bx,bz,h,lo,face)end end
  edge(-1,0,0,0,0,16);edge(1,0,16,16,16,0);edge(0,-1,16,0,0,0);edge(0,1,0,16,16,16)
 end
 for i=first,#out do out[i][2]=(out[i][2]+base)*cfg.heightScale;if out[i][2]<0 then out[i][6]=G.HANGING_FACADE end end
end
return R
