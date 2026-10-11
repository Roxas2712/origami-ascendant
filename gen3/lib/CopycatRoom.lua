-- Native Copycat bedroom. Preserve rug borders, console cable and event dolls.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.copycatRoom end
function R.profile(d)
 local L=d and d.midLayout
 if cfg().enabled and d and d.id=='FR_SAFFRON_CITY_COPYCATS_HOUSE_2F'and d.mapType==8 and d.pair=='player_house'and L and L.width==12 and L.height==10 and L:midAt(1,0)==0x100 and L:midAt(3,5)==0x281 then return cfg()end
end
function R.plan(d)
 local L=d.midLayout;if L then R.rooms[L]=nil end;if not R.profile(d)then return end
 local c=cfg();local own,mask={},{ };R.rooms[L]=own
 local function add(k,x,y,w,h,p)
  p=p or{};p.kind=k;p.x=x;p.y=y;p.w=w;p.h=h;own[#own+1]=p
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*12+xx+1]={mid=8,void=true,separateSurface=true}end end
 end
 add('copycatWall',1,0,11,2);add('copycatFloor',1,2,11,7)
 add('copycatDesk',1,0,2,3,{cap=11,last=48,height=c.deskHeight})
 add('copycatShelf',3,0,1,3,{cap=14,last=39,height=c.shelfHeight})
 add('copycatDrawer',4,0,1,3,{cap=18,last=39,height=c.drawerHeight})
 add('copycatTV',3,3,1,3,{cap=13,last=40,height=c.tvHeight})
 add('copycatConsole',3,5,1,2,{cap=8,last=27,height=c.consoleHeight})
 for _,y in ipairs{5,7}do add('copycatPlant',11,y,1,2,{cap=4,last=32,height=c.plantHeight})end
 add('copycatStairs',8,1,3,3)
 return{objects=own,mask=mask,owners={}}
end
function R.actorOffset(d,x,z)
 if not R.profile(d)then return end
 local xx,zz=x+8,z+16
 if xx>=132 and xx<160 and zz>=34 and zz<=56 then return -cfg().stairDepth*(6-math.min(6,math.floor((xx-132)/4)))/6,0 end
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local own=R.rooms[L];if not c.enabled or not own then return end
 local P,G,B=V.require('PaperSprite'),V.require('WorldGeometry'),V.require('BuildingMesh');local hs=V.require('Billboard').heightScale()
 local function source(x,y)return L:midAt(math.floor(x/16),math.floor(y/16)),x%16,y%16 end
 local function colour(x,y)return rgb(B.pixel(ts,source(x,y)))end
 local bg={};for _,m in ipairs{0xa9,0xb1}do for y=0,15 do for x=0,15 do bg[rgb(B.pixel(ts,m,x,y))]=true end end end
 local carpet=colour(72,90)
 local plant={};for t=0,31 do for s=0,15 do plant[t*16+s]=bg[colour(176+s,80+t)]end end
 -- Perimeter flood preserves enclosed pot texels sharing floor colours.
 local empty,q={},{};local function seed(s,t)local k=t*16+s;if plant[k]and not empty[k]then empty[k]=true;q[#q+1]=k end end
 for s=0,15 do seed(s,0);seed(s,31)end;for t=0,31 do seed(0,t);seed(15,t)end
 local n=1;while q[n]do local k=q[n];n=n+1;local s,t=k%16,math.floor(k/16);if s>0 then seed(s-1,t)end;if s<15 then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t<31 then seed(s,t+1)end end
 local function inside(o,s,t)
  if s<0 or s>=o.w*16 or t<o.cap or t>=o.last then return false end
  if o.kind=='copycatPlant'then return not empty[t*16+s]
  elseif o.kind=='copycatShelf'then local a=t==14 and 2 or t==15 and 1 or 0;return s>=a and s<16-a
  elseif o.kind=='copycatDrawer'then return t~=18 or s<4 or s>=12
  elseif o.kind=='copycatTV'then local a=t<16 and 16-t or t>=38 and 1 or 0;return s>=a and s<16-a
  elseif o.kind=='copycatConsole'then return colour(48+s,80+t)~=carpet
  elseif o.kind=='copycatDesk'then
   if t<31 then return s<16 and s>=(t<14 and 14-t or 0)and s<16-(t<14 and 14-t or 0)or s>=16 and t>=21 end
   return not bg[colour(16+s,t)]
  end
 end
 local function draw(w,h,src,mask,project)
  local vv=P.build(ts,w,h,src,mask,0,h,1,nil,project,.5);for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local clear={};for _,o in ipairs(own)do if o.cap then for t=o.cap,o.last-1 do for s=0,o.w*16-1 do if inside(o,s,t)then clear[(o.y*16+t)*192+o.x*16+s]=true end end end end end
 for _,o in ipairs(own)do local x,z=(o.x+ox)*16,(o.y+oz)*16;local first=#out+1
  local function src(s,t)return source(o.x*16+s,o.y*16+t)end
  if o.kind=='copycatWall'then
   draw(176,32,function(s,t)local xx=s+16;if xx<80 or xx>=128 and xx<132 then xx=136 end;return source(xx,t)end,function()return true end,function(s,t)return{x+s,c.wallHeight*hs*(32-t)/32,z+32}end)
  elseif o.kind=='copycatFloor'then
   draw(176,112,function(s,t)
    local xx,yy=s+16,t+32
    if xx>=128 and xx<160 and yy<64 then return 0xa9,xx%16,yy%16 end
    if clear[yy*192+xx]then
     -- Adjacent original rug rows include its top border beneath the TV.
     if xx>=48 and xx<64 and yy>=48 then return source(64+xx%16,yy)end
     return xx<32 and 0xb1 or 0xa9,xx%16,yy%16
    end
    return source(xx,yy)
   end,function(s,t)local xx,yy=s+16,t+32;return not(xx>=132 and xx<160 and yy>=34 and yy<56)end,function(s,t)return{x+s,0,z+t}end)
  elseif o.kind=='copycatStairs'then
   local function uv(xx,yy)local m,u,v=source(xx,yy);return G.uv(ts,m,u,v,u+1,v+1,.5)end
   local top,edge,dark,white,post=uv(158,36),uv(146,42),uv(134,34),uv(129,53),uv(137,60)
   local X,Z=ox*16,oz*16
   local function quad(a,b,d,e,u,shade)for _,v in ipairs{a,b,d,e}do v[1]=v[1]+X;v[3]=v[3]+Z end;G.quad(out,a,b,d,e,u,shade or 1)end
   for step=0,6 do
    local a,b=132+step*4,136+step*4;local h=-c.stairDepth*(6-step)/6
    quad({a,h,34},{b,h,34},{b,h,56},{a,h,56},top)
    if step<6 then local nh=h+c.stairDepth/6;quad({b,nh,34},{b,nh,56},{b,h,56},{b,h,34},edge,c.riserShade)end
    for _,zz in ipairs{34,56}do quad({a,0,zz},{b,0,zz},{b,h,zz},{a,h,zz},dark,c.sideShade)end
   end
   quad({132,0,34},{132,0,56},{132,-c.stairDepth,56},{132,-c.stairDepth,34},dark)
   local function rail(xx,zz,w,d)
    quad({xx,c.railHeight,zz},{xx+w,c.railHeight,zz},{xx+w,c.railHeight,zz+d},{xx,c.railHeight,zz+d},white)
    quad({xx,c.railHeight,zz+d},{xx+w,c.railHeight,zz+d},{xx+w,c.railHeight-2,zz+d},{xx,c.railHeight-2,zz+d},post)
    for px=xx,xx+w-1,8 do quad({px,c.railHeight,zz+d},{px+1,c.railHeight,zz+d},{px+1,0,zz+d},{px,0,zz+d},post)end
   end
   rail(128,32,3,26);rail(128,56,32,3)
   quad({128,c.railHeight,32},{128,c.railHeight,58},{128,c.railHeight-2,58},{128,c.railHeight-2,32},post)
  else
   local function band(a,b,project,extra)
    draw(o.w*16,o.h*16,src,function(s,t)return t>=a and t<b and inside(o,s,t)and(not extra or extra(s,t))end,project)
   end
   if o.kind=='copycatDesk'then
    draw(32,11,function(s,t)return source(32+s%16,21+t)end,function()return true end,function(s,t)return{x+s,o.height,z+32+t}end)
    band(31,39,function(s,t)return{x+s,o.height*(39-t)/8,z+43}end)
    band(11,31,function(s,t)return{x+s,o.height+(31-t)*hs,z+34}end,function(s)return s<16 end)
    band(39,45,function(s,t)return{x+s,c.stoolHeight,z+t+5}end,function(s)return s<16 end)
    band(45,48,function(s,t)return{x+s,c.stoolHeight*(48-t)/3,z+50}end,function(s)return s<16 end)
   elseif o.kind=='copycatConsole'then
    -- Console body rises slightly; its original controller and cable stay flat.
    band(8,27,function(s,t)local body=s>=3 and s<14 and t<22;return{x+s,body and o.height or c.cableLift,z+t}end)
   else
    band(o.cap,o.last,function(s,t)return{x+s,o.height*hs*(o.last-t)/(o.last-o.cap),z+o.last}end)
   end
   contacts[#contacts+1]={x+o.w*8,z+o.last,o.w*6,c.contactRadius,c.contactStrength}
  end
  local k=o.kind=='copycatWall'and 'wall'or(o.kind=='copycatFloor'or o.kind=='copycatStairs')and 'card'or o.kind=='copycatPlant'and 'plant'or o.kind
  V.require('RoomLightRig').capture(L,{kind=k},out,first,#out)
 end
end
function R.lighting(d)
 local c=R.profile(d);local L=d and d.midLayout
 local ground=V.require('DioramaConfig').interiors.copycatGround
 if ground.enabled and d and d.id=='FR_SAFFRON_CITY_COPYCATS_HOUSE_1F'and d.mapType==8 and d.pair=='player_house'and L and L.width==14 and L.height==10 and L:midAt(1,0)==0xaf and L:midAt(6,4)==0xc8 then c=ground end
 if not c then return end;local sources={}
 for _,a in ipairs(c.sources)do sources[#sources+1]={at={a[1]*16,c.lightHeight,a[2]*16},radius=a[4],power=a[3],nightPower=a[5]and a[3]*c.windowNightScale or a[3],color=a[5]and c.windowColor or c.lampColor,spread=c.spread}end
 return{ambient=c.ambient,night=c.nightAmbient,sources=sources}
end
return R
