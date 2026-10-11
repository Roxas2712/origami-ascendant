-- Nine measured dojo rooms share native sliding doors and untouched floor mats.
local V=...
local R={}
R.rows={0,13,26,39,52,65,78,91,104}
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.petalburgGym.enabled and(d.id or d.name)=='EM_PETALBURG_CITY_GYM'
  and d.pair=='building__petalburg_gym'and L and L.width==10 and L.height==112
  and L:midAt(0,0)==0x202 and L:midAt(4,111)==6 then return c.homeRooms.petalburgGym end
end
-- Display only the occupied room; native rooms share one map with void gaps.
function R.clipBounds(d,z)
 if not R.profile(d)then return end
 local row=math.max(0,math.min(8,math.floor((z/16+2.5)/13)))*13
 return{-4,row*16,148,(row+8)*16+.5}
end
-- Door sheets use the same 32 source rows as the wall; its cap stays static.
function R.doorPose(d,anim)
 if not R.profile(d)or not anim or anim.y%13~=1 then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors
 return{height=cfg.petalburgGym.wallHeight*cfg.heightScale,top=6/32}
end
function R.statueInside(s,t)
 local inset=({6,4,2,1})[t+1]or 0
 return t>=0 and t<32 and s>=inset and s<16-inset
end
function R.podiumInside(s,t)
 local a,b=0,80
 if t==0 then a,b=3,77 elseif t==1 then a,b=2,78 elseif t==2 then a,b=1,79
 elseif t==29 then a,b=1,80 elseif t==30 then a,b=2,79 elseif t==31 then a,b=16,64 end
 return t>=0 and t<32 and s>=a and s<b
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local foot=z+16;local cx=x+8
 if cx>=32 and cx<112 and foot>=32 and foot<64 then
  return cfg.petalburgGym.podiumHeight*cfg.heightScale*math.min(1,(64-foot)/8)
 end
 return 0
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h)local o={kind=kind,x=x,y=y,w=w*16,h=h*16,noContact=true};objects[#objects+1]=o end
 for y=0,111 do for x=0,9 do local m=L:midAt(x,y);local k=y*10+x+1
  if x==9 or m==0x208 or y%13<2 then mask[k]={mid=0x208,void=true}
  elseif y>=106 then
   if m~=6 and m~=7 then mask[k]=0x22b end
  elseif m==0x209 or m==0x212 or m==0x213 or m==0x214 then mask[k]=0x201 end
 end end
 for _,y in ipairs(R.rows)do add('petalGymWall',0,y,9,2)end
 -- Remove the podium's baked floor and side shadows, preserve its own contour.
 for y=2,3 do for x=1,7 do mask[y*10+x+1]=0x201 end end
 add('petalGymPodium',2,2,5,2)
 add('petalGymStatue',1,109,1,2);add('petalGymStatue',7,109,1,2)
 return objects,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.petalburgGym;local first=#out+1;local G=V.require('WorldGeometry')
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function band(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function contact(a,b,zz)
  if contacts then for s=a+3,b-2,6 do contacts[#contacts+1]={x+s,z+zz,4,1.3,c.contactStrength}end end
 end
 if o.kind=='petalGymWall'then
  band(6,32,function(s,t)return{x+s,c.wallHeight*(32-t)/26,z+32}end)
  band(0,6,function(s,t)return{x+s,c.wallHeight,z+26+t}end)
  -- Short ends use the original pale corner-post texture, never black wedges.
  G.quad(out,{x,c.wallHeight,z+26},{x,c.wallHeight,z+32},{x,0,z+32},{x,0,z+26},G.uv(ts,0x20a,0,0,1,16,.5),1)
  G.quad(out,{x+144,c.wallHeight,z+32},{x+144,c.wallHeight,z+26},{x+144,0,z+26},{x+144,0,z+32},G.uv(ts,0x20c,15,0,16,16,.5),1)
  contact(0,144,32)
 elseif o.kind=='petalGymStatue'then
  band(0,32,function(s,t)return{x+s,c.statueHeight*(32-t)/32,z+28}end,R.statueInside);contact(0,16,28)
 elseif o.kind=='petalGymPodium'then
  band(0,24,function(s,t)return{x+s,c.podiumHeight,z+t}end,R.podiumInside)
  band(24,32,function(s,t)return{x+s,c.podiumHeight*(32-t)/8,z+24}end,R.podiumInside);contact(0,80,24)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
