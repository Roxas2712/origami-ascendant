-- Native psychic-gym islands: leave every arrow, switch and teleporter live.
local V=...
local R={}
local cap={};for _,m in ipairs({0x205,0x206,0x207,0x20d,0x20e,0x20f,0x21d,0x21e,0x21f})do cap[m]=true end
local front={};for _,m in ipairs({0x215,0x216,0x217,0x228,0x229})do front[m]=true end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.mossdeepGym.enabled and(d.id or d.name)=='EM_MOSSDEEP_CITY_GYM'and d.pair=='building__mossdeep_gym'
  and L and L.width==26 and L.height==36 and L:midAt(6,35)==6 and L:midAt(23,7)==0x219 then return c.homeRooms.mossdeepGym end
end
function R.wallInside(m,s,t)
 if front[m]then return true end
 if not cap[m]then return false end
 if m==0x205 or m==0x21d then return s<8 end
 if m==0x207 or m==0x21f then return s>=8 end
 return true
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w;o.h=h;o.noContact=true;objects[#objects+1]=o end
 for y=0,35 do for x=0,25 do local m=L:midAt(x,y);local k=y*26+x+1
  if m==0x208 or cap[m]or front[m]then mask[k]={mid=0x208,void=true}
  elseif m==0x204 or m==0x20c or m==0x214 or m>=0x218 and m<=0x21c or m>=0x220 and m<=0x224 then mask[k]=0x20a end
  if cap[m]or front[m]then add('mossGymWall',x,y,16,16,{mid=m})
  elseif m==0x204 then add('mossGymStatue',x,y,16,32)
  elseif m==0x214 then add('mossGymPillar',x,y,16,16)end
 end end
 add('mossGymPodium',22,7,64,32)
 return objects,mask
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local foot=z+16
 if x+8>=352 and x+8<416 and foot>=112 and foot<144 then return cfg.mossdeepGym.podiumHeight*cfg.heightScale*math.min(1,(144-foot)/8)end
 return 0
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.mossdeepGym;local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function band(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function contact(w,zz)if contacts then contacts[#contacts+1]={x+w/2,z+zz,w*.42,1.4,c.contactStrength}end end
 local function cutFloor(s,t)
  local m,sx,sy=source(s,t);local r,g,b=B.pixel(ts,m,sx,sy)
  r=math.floor(r*255+.5);g=math.floor(g*255+.5);b=math.floor(b*255+.5)
  return not(r==189 and g==181 and b==197 or r==156 and g==156 and b==173 or r==222 and g==214 and b==222 or r==132 and g==132 and b==148)
 end
 if o.kind=='mossGymWall'then
  local function inside(s,t)return R.wallInside(o.mid,s,t)end
  if front[o.mid]then
   -- A single native orange texel fills this hidden continuation of the cap;
   -- one quad is sufficient, rather than 256 identical pixel quads.
   G.quad(out,{x,c.wallHeight,z},{x+16,c.wallHeight,z},{x+16,c.wallHeight,z+16},{x,c.wallHeight,z+16},G.uv(ts,0x20e,8,8,9,9,.5),1)
  else band(0,16,function(s,t)return{x+s,c.wallHeight,z+t}end,inside)end
  local function neighbor(s,t)return R.wallInside(L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16)end
  local function side(ax,az,bx,bz,fullFront)
   local uv=fullFront and G.uv(ts,o.mid,ax,0,bx,16,.49)or G.uv(ts,0x216,5,0,6,16,.49)
   G.quad(out,{x+ax,c.wallHeight,z+az},{x+bx,c.wallHeight,z+bz},{x+bx,0,z+bz},{x+ax,0,z+az},uv,fullFront and 1 or .9)
  end
  -- Actual wall contour, including the half-tile side walls around islands.
  for t=0,15 do for s=0,15 do if inside(s,t)then
   if not neighbor(s-1,t)then side(s,t,s,t+1)end
   if not neighbor(s+1,t)then side(s+1,t+1,s+1,t)end
   if not neighbor(s,t-1)then side(s+1,t,s,t)end
   if not neighbor(s,t+1)then side(s,t+1,s+1,t+1,front[o.mid]and t==15)end
  end end end
  if front[o.mid]then contact(16,16)end
 elseif o.kind=='mossGymStatue'then
  band(0,32,function(s,t)return{x+s,c.statueHeight*(32-t)/32,z+28}end,cutFloor);contact(16,28)
 elseif o.kind=='mossGymPillar'then
  band(0,12,function(s,t)return{x+s,c.pillarHeight,z+t+4}end)
  band(12,16,function(s,t)return{x+s,c.pillarHeight*(16-t)/4,z+16}end);contact(16,16)
 elseif o.kind=='mossGymPodium'then
  band(0,24,function(s,t)return{x+s,c.podiumHeight,z+t}end,cutFloor)
  band(24,32,function(s,t)return{x+s,c.podiumHeight*(32-t)/8,z+24}end,cutFloor);contact(64,24)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
