-- Measured ice-gym surfaces. Puzzle cells, ladder warps and actors stay native.
local V=...
local R={}
local upperWalls={};for _,m in ipairs({0x239,0x23a,0x23b,0x23c,0x240,0x241,0x242,0x243,0x244,0x245,0x248,0x249,0x24a,0x24c,0x24d,0x24e,0x250,0x252,0x254,0x255,0x256,0x258,0x259,0x25b,0x25c,0x260,0x261,0x262})do upperWalls[m]=true end
local lowerWalls={};for _,m in ipairs({0x209,0x219,0x21d,0x21e,0x225,0x226,0x227,0x22d,0x22f,0x235,0x237,0x23d,0x25d,0x25e})do lowerWalls[m]=true end
local upperVoid={[1]=true,[0x208]=true,[0x210]=true,[0x218]=true,[0x220]=true}
R.floorColors={}
for _,c in ipairs({{173,214,222},{132,165,197},{99,132,156},{206,239,239},{222,222,239},{189,189,206}})do R.floorColors[c[1]*65536+c[2]*256+c[3]]=true end
local function upper(d)return(d.id or d.name)=='EM_SOOTOPOLIS_CITY_GYM_1F'end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout;local id=d.id or d.name
 if c.enabled and c.sootopolisGym.enabled and(id=='EM_SOOTOPOLIS_CITY_GYM_1F'or id=='EM_SOOTOPOLIS_CITY_GYM_B1F')
  and d.pair=='building__sootopolis_gym'and L and L.width==18 and L.height==26
  and L:midAt(0,0)==(upper(d)and 0x210 or 0x201)and L:midAt(8,24)==(upper(d)and 0x23e or 0x211)then
  return c.homeRooms[upper(d)and'sootopolisUpper'or'sootopolisLower']
 end
end
-- Four connected terrace levels. Stairs and their unsolved icy ramps share
-- endpoints, so changing the native metatile never opens a geometry crack.
function R.height(y)
 local h=V.require('DioramaConfig').emeraldInteriors.sootopolisGym.stepHeight
 local n=0
 for _,a in ipairs({{4,6},{10,12},{15,17},{20,22}})do n=n+math.max(0,math.min(1,(a[2]-y)/(a[2]-a[1])))end
 return h*n
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local h=upper(d)and R.height((z+16)/16)or 0
 if upper(d)and x+8>=96 and x+8<176 and z+16>=32 and z+16<64 then h=h+cfg.sootopolisGym.podiumHeight*math.min(1,(64-z-16)/8)end
 return h*cfg.heightScale
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local u=upper(d);local objects,mask,claimed={},{},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind='sootGym'..kind;o.x=x;o.y=y;o.w=w;o.h=h;o.upper=u;o.noContact=true;objects[#objects+1]=o end
 local function claim(x,y,w,h)for yy=y,y+h-1 do for xx=x,x+w-1 do claimed[yy*18+xx+1]=true end end end
 if u then
  for y=0,23 do for x=0,15 do if L:midAt(x,y)==0x268 then add('Waterfall',x,y,32,48);claim(x,y,2,3)end end end
  add('Podium',6,2,80,32);claim(6,2,5,2)
 end
 for y=0,25 do for x=0,17 do local m=L:midAt(x,y);local k=y*18+x+1
  mask[k]={mid=1,void=true}
  if not claimed[k]and not(u and upperVoid[m]or not u and(m==1 or m==0x201 or m==0x22e))then
   if(u and upperWalls[m]or not u and lowerWalls[m])then add('Wall',x,y,16,16,{mid=m})
   else
    local donor=m
    if u and(m==0x217 or m==0x21f or m==0x24f or m==0x257 or m==0x25f)then donor=0x23e end
    if u and(m==0x203 or m==0x216)then donor=m==0x216 and 0x215 or 0x20d;add('Rock',x,y,16,16,{mid=m,donor=donor})end
    add('Floor',x,y,16,16,{mid=donor})
    if u and m==0x217 then add('Statue',x,y,16,32)end
   end
  end
 end end
 return objects,mask
end
-- Camera-facing rock boundaries are cut away at floor level so native
-- trainers beside them are not buried behind an invented full-height cap.
function R.wallHeight(L,o)
 local c=V.require('DioramaConfig').emeraldInteriors.sootopolisGym
 if o.upper then return c.wallHeight end
 return L:midAt(o.x,o.y-1)==0x211 and c.frontWallHeight or c.rockWallHeight
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.sootopolisGym;local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local first=#out+1
 local function height(t)return o.upper and R.height(o.y+t/16)or 0 end
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function band(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function cutFloor(s,t)
  local m,sx,sy=source(s,t);local r,g,b=B.pixel(ts,m,sx,sy)
  local key=math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)
  return not R.floorColors[key]
 end
 local function contact(w,t)if contacts then contacts[#contacts+1]={x+w/2,z+t,w*.42,1.2,c.contactStrength}end end
 local function side(ax,az,bx,bz,hiA,hiB,loA,loB,m,s)
  G.quad(out,{x+ax,hiA,z+az},{x+bx,hiB,z+bz},{x+bx,loB,z+bz},{x+ax,loA,z+az},G.uv(ts,m,0,0,16,16,.5),.9)
 end
 if o.kind=='sootGymFloor'then
  if o.upper and o.mid==0x207 then
   for a=0,8,8 do
    band(a,a+4,function(s,t)return{x+s,height(a),z+t}end)
    band(a+4,a+8,function(s,t)return{x+s,height(a)+(height(a+8)-height(a))*(t-a-4)/4,z+a+4}end)
    band(a+4,a+8,function(s,t)return{x+s,height(a+8),z+t}end,nil,function(s,t)return 0x207,s,0 end)
   end
  else band(0,16,function(s,t)return{x+s,height(t),z+t}end,nil,function(s,t)return o.mid,s,t end)end
 elseif o.kind=='sootGymWall'then
  local h=R.wallHeight(L,o);local walls=o.upper and upperWalls or lowerWalls
  band(0,16,function(s,t)return{x+s,height(t)+h,z+t}end)
  local function edge(dx,dy,ax,az,bx,bz)
   local neighbor=walls[L:midAt(o.x+dx,o.y+dy)]
   local low=neighbor and R.wallHeight(L,{upper=o.upper,x=o.x+dx,y=o.y+dy})or 0
   if not neighbor or low<h then
    side(ax,az,bx,bz,height(az)+h,height(bz)+h,height(az)+low,height(bz)+low,o.upper and 0x252 or 0x22d,o.upper and 8 or 7)
   end
  end
  edge(-1,0,0,0,0,16);edge(1,0,16,16,16,0);edge(0,-1,16,0,0,0)
  edge(0,1,0,16,16,16)
 elseif o.kind=='sootGymRock'then
  -- Subtract only identical native ice pixels, not a guessed colour key.
  local function inside(s,t)
   local r,g,b=B.pixel(ts,o.mid,s,t);local rr,gg,bb=B.pixel(ts,o.donor,s,t)
   return r~=rr or g~=gg or b~=bb
  end
  band(0,16,function(s,t)return{x+s,height(14)+c.rockHeight*(16-t)/16,z+14}end,inside)
  contact(16,14)
 elseif o.kind=='sootGymStatue'then
  band(0,32,function(s,t)return{x+s,height(28)+c.statueHeight*(32-t)/32,z+28}end,cutFloor)
  contact(16,28)
 elseif o.kind=='sootGymPodium'then
  band(0,32,function(s,t)return{x+s,height(t),z+t}end,nil,function(s,t)return 0x23e,s%16,t%16 end)
  band(0,24,function(s,t)return{x+s,height(t)+c.podiumHeight,z+t}end,cutFloor)
  band(24,32,function(s,t)return{x+s,height(t)+c.podiumHeight*(32-t)/8,z+24}end,cutFloor)
  contact(80,24)
 elseif o.kind=='sootGymWaterfall'then
  local base=height(48)
  -- Continuous wall backing below the waterfall: no black shaft is exposed
  -- where its original three source rows used to lie flat.
  local h=base+c.wallHeight
  G.quad(out,{x,h,z},{x+32,h,z},{x+32,h,z+48},{x,h,z+48},G.uv(ts,0x24a,8,9,9,10,.5),1)
  side(0,0,0,48,h,h,base,base,0x252)
  side(32,48,32,0,h,h,base,base,0x252)
  -- The waterfall's frame is part of its upright cutout, never a stretched lid.
  band(0,48,function(s,t)return{x+s,base+c.waterfallHeight*(48-t)/48,z+48}end)
  G.quad(out,{x,base+c.waterfallHeight,z+44},{x+32,base+c.waterfallHeight,z+44},{x+32,base+c.waterfallHeight,z+48},{x,base+c.waterfallHeight,z+48},G.uv(ts,0x24a,8,0,9,4,.5),1)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
