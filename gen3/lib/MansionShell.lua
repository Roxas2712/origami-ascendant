-- Measured Mansion wall courses and complete native flights. Gameplay owns
-- switches, collision and warps; this module only separates their artwork.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local sizes={FR_POKEMON_MANSION_1F=36,FR_POKEMON_MANSION_2F=38,FR_POKEMON_MANSION_3F=36,FR_POKEMON_MANSION_B1F=36}
local function cfg()return V.require('DioramaConfig').interiors.mansionShell end
local wallTop={[0x2a1]=true,[0x2a2]=true,[0x2a3]=true,[0x2f3]=true,[0x2f4]=true}
local trim={};for _,m in ipairs{0x29b,0x29c,0x29d,0x29f,0x2a0,0x2a4,0x2a8,0x2ac,0x2a5,0x2ad,0x2b0,0x2b4,0x2db,0x2dc,0x2e3,0x2e4,0x2eb,0x2ec,0x2ed,0x2ee,0x2ef,0x2f5,0x2f6,0x2f7,0x2fb,0x2fc,0x303,0x304,0x30c,0x32d,0x335,0x351,0x352,0x353,0x357}do trim[m]=true end
local stairs={
 {left=false,tiles={0x2d5,0x2d6,0x2d7,0x2dd,0x2de,0x2df,0x2e5,0x2e6,0x2e7}},
 {left=false,tiles={0x2d5,0x2d6,0x2d7,0x32f,0x2de,0x2df,0x337,0x2e6,0x2e7}},
 {left=false,tiles={0x2d5,0x2d6,0x2d7,0x363,0x2de,0x2df,0x36b,0x2e6,0x2e7}},
 {left=false,down=true,tiles={0x2d0,0x2d1,0x2d2,0x2d8,0x2d9,0x2da,0x2e0,0x2e1,0x2e2}},
}
function R.profile(d)
 local L=d and d.midLayout;local h=d and sizes[d.id or d.name]
 return cfg().enabled and h and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4f2c'and L and L.width==38 and L.height==h and L:midAt(2,0)==0x2a2
end
function R.lighting(d)
 if not R.profile(d)then return end
 local c,L=cfg(),d.midLayout;local sources={};local basement=d.id=='FR_POKEMON_MANSION_B1F'
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x378 and L:midAt(x+1,y)==0x379 then
   sources[#sources+1]={at={x*16+16,c.windowHeight,y*16+44},radius=c.windowRadius,power=c.windowPower,nightPower=c.windowNightPower,color=c.windowColor,nightColor=c.windowNightColor,spread={14,10}}
  elseif(m==0x31d or m==0x31e or m==0x31f)and(x==0 or(L:midAt(x-1,y)~=0x31d and L:midAt(x-1,y)~=0x31e and L:midAt(x-1,y)~=0x31f))then
   sources[#sources+1]={at={x*16+16,c.deviceLightHeight,y*16+40},radius=c.deviceRadius,power=c.devicePower,color=c.deviceColor,spread={10,8}}
  end
 end end
 return{fixed=basement,ambient=basement and c.basementAmbient or c.ambient,night=c.nightAmbient,localSelection=true,sources=sources}
end
function R.plan(d,objects,mask)
 local L=d.midLayout;if L then R.rooms[L]=nil end;if not R.profile(d)then return end
 local owned={};R.rooms[L]=owned;local basement=d.id=='FR_POKEMON_MANSION_B1F';local floor=basement and 0x286 or 0x284
 local function add(kind,x,y,w,h,extra)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w;o.h=h;objects[#objects+1]=o;owned[#owned+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=floor,void=true,separateSurface=true}end end;return o
 end
 for y=0,L.height-3 do for x=0,L.width-3 do for _,v in ipairs(stairs)do if L:midAt(x,y)==v.tiles[1]then
  local ok=true;for i,m in ipairs(v.tiles)do if L:midAt(x+(i-1)%3,y+math.floor((i-1)/3))~=m then ok=false;break end end
  if ok then add('mansionStairs',x,y,3,3,{left=v.left,down=v.down,floor=floor,stairConfig={height=cfg().stairHeight,railHeight=cfg().railHeight,riserShade=cfg().riserShade,sideShade=cfg().sideShade}})end
 end end end end
 for y=0,L.height-3 do for x=0,L.width-1 do
  local m=L:midAt(x,y);local next=L:midAt(x,y+1)
  if wallTop[m]and(next==0x2a9 or next==0x2aa or next==0x2ab or next==0x2fb or next==0x2fc or next==0x317 or next==0x378 or next==0x379)then
   local k=(y+2)*L.width+x+1;local overlap=type(mask[k])=='table'and mask[k].separateSurface
   add('mansionWall',x,y,1,3,{repair=overlap,floor=floor})
  end
 end end
 -- Gates remain live native art: opening a statue switch changes their mids,
 -- so the next geometry rebuild must see and render the new state.
 for y=0,L.height-2 do for x=0,L.width-1 do
  local a,b=L:midAt(x,y),L:midAt(x,y+1)
  if(a==0x2f8 and(b==0x300 or b==0x354))or(a==0x2f9 and(b==0x301 or b==0x355))or(a==0x2fa and(b==0x302 or b==0x356))then add('mansionGate',x,y,1,2,{floor=floor})end
 end end
 -- North/south gates have five source rows. A floor-aligned silver strip
 -- is their top-down drawing, not their physical pose in the diorama.
 for y=0,L.height-5 do for x=0,L.width-1 do
  if L:midAt(x,y)==0x350 and L:midAt(x,y+1)==0x358 then
   local a,b,e=L:midAt(x,y+2),L:midAt(x,y+3),L:midAt(x,y+4)
   if(a==0x362 and b==0x36a and e==0x372)or(a==0x360 and b==0x368 and e==0x370)then
    add('mansionSideGate',x,y,1,5,{floor=floor,plant=b==0x368})
    if b==0x368 then add('mansionPlant',x,y+3,1,2,{sourceMids={0x30b,0x313}})end
   end
  end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y);local k=y*L.width+x+1
  if m==0 or m==8 then mask[k]={mid=8,void=true,separateSurface=true}
  elseif trim[m]and not(type(mask[k])=='table'and mask[k].separateSurface)then add('mansionTrim',x,y,1,1)end
 end end
 -- Full plants/devices straddle wall and floor; never fold their top into a wall.
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y);local b=y+1<L.height and L:midAt(x,y+1)
  local plant=(m==0x324 and b==0x323)or(m==0x30b and b==0x313)or(m==0x359 and b==0x361)
  local statue=((m==0x314 or m==0x34d or m==0x34e)and b==0x31c)or((m==0x316 or m==0x34f)and b==0x32c)
  local device=(m==0x31d and(b==0x325 or b==0x36c))or(m==0x31e and(b==0x326 or b==0x36d))or(m==0x31f and(b==0x327 or b==0x36e))
  if plant or device or statue then
   local old=mask[y*L.width+x+1];local wall=type(old)=='table'and old.void and old.separateSurface
   local o=add(plant and'mansionPlant'or statue and'mansionStatue'or'mansionDevice',x,y,1,2,{wall=wall})
   for yy=y,y+1 do mask[yy*L.width+x+1]={mid=floor,void=yy==y and wall,separateSurface=true}end
  end
 end end
 -- The complete stair footprint wins over the wall course it overlaps.
 for _,o in ipairs(owned)do if o.kind=='mansionStairs'then
  for y=o.y,o.y+2 do for x=o.x,o.x+2 do mask[y*L.width+x+1]={mid=floor,void=true,separateSurface=true}end end
 end end
end
function R.actorOffset(d,x,z)
 if not R.profile(d)then return end
 for _,o in ipairs(R.rooms[d.midLayout]or{})do if o.kind=='mansionStairs'then
  local px,pz=x+8-o.x*16,z+16-o.y*16
  if px>=0 and px<48 and pz>=16 and pz<=48 then
   return(math.min(7,math.floor(px/6))+1)*cfg().stairHeight/8*(o.down and -1 or 1),0
  end
 end end
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local own=R.rooms[L];if not own then return end
 local c=cfg();local hs=V.require('Billboard').heightScale();local G,B,P=V.require('WorldGeometry'),V.require('BuildingMesh'),V.require('PaperSprite');local bg={}
 for _,m in ipairs{0x284,0x285,0x286,0x287,0x28c,0x28d,0x28e,0x28f,0x295,0x297}do if ts.midToSlot[m]then for y=0,15 do for x=0,15 do bg[rgb(B.pixel(ts,m,x,y))]=true end end end end
 local function draw(w,h,src,inside,project)
  local vv=P.build(ts,w,h,src,inside or function()return true end,0,h,1,nil,project,.5);for _,v in ipairs(vv)do out[#out+1]=v end
 end
 for _,o in ipairs(own)do local x,z=(o.x+ox)*16,(o.y+oz)*16;local first=#out+1
  local function source(s,t)
   local m=o.sourceMids and o.sourceMids[math.floor(t/16)+1]or L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16))
   -- Older imports omit the script-only pressed statue head. Preserve the
   -- original sculpture instead of sampling void; modern imports use exact art.
   if o.kind=='mansionStatue'and not ts.midToSlot[m]then if m==0x34d or m==0x34e then m=0x314 elseif m==0x34f then m=0x316 end end
   return m,s%16,t%16
  end
  if o.kind=='mansionWall'then
   local function wall(s,t)
    local m,u,v=source(s,t+16)
    if t<16 and m==0x317 then m=0x2aa end
    if t>=16 and(o.repair or m==0x324 or m==0x31d or m==0x31e or m==0x31f or m==0x2d3 or m==0x374)then m=0x2b2 end
    return m,u,v
   end
   draw(16,48,function(s,t)return o.floor,s,t%16 end,nil,function(s,t)return{x+s,0,z+t}end)
   draw(16,32,wall,nil,function(s,t)return{x+s,c.wallHeight*hs*(32-t)/32,z+48}end)
   -- Native cap is a shallow top, not a second raised wall rectangle.
   draw(16,16,source,nil,function(s,t)return{x+s,c.wallHeight*hs,z+48-c.wallDepth+c.wallDepth*t/16}end)
   for _,side in ipairs{0,16}do local uv=G.uv(ts,0x2aa,8,8,9,9,.5)
    G.quad(out,{x+side,c.wallHeight*hs,z+48-c.wallDepth},{x+side,c.wallHeight*hs,z+48},{x+side,0,z+48},{x+side,0,z+48-c.wallDepth},uv,c.sideShade)
   end
  elseif o.kind=='mansionGate'then
   draw(16,32,function(s,t)return o.floor,s,t%16 end,nil,function(s,t)return{x+s,0,z+t}end)
   draw(16,32,source,function(s,t)local m,u,v=source(s,t);return t<24 or not bg[rgb(B.pixel(ts,m,u,v))]end,function(s,t)return{x+s,c.gateHeight*hs*(32-t)/32,z+32}end)
  elseif o.kind=='mansionSideGate'then
   draw(16,80,function(s,t)return o.floor,s,t%16 end,nil,function(s,t)return{x+s,0,z+t}end)
   local light=G.uv(ts,0x350,8,8,9,9,.5);local dark=G.uv(ts,0x350,0,8,1,9,.5)
   local height=c.gateHeight*hs;local a,b=z+8,z+72
   local function bar(x0,x1,y0,y1,z0,z1)
    G.quad(out,{x0,y1,z0},{x1,y1,z0},{x1,y1,z1},{x0,y1,z1},light)
    G.quad(out,{x0,y1,z1},{x1,y1,z1},{x1,y0,z1},{x0,y0,z1},dark)
    G.quad(out,{x0,y1,z0},{x0,y1,z1},{x0,y0,z1},{x0,y0,z0},dark)
    G.quad(out,{x1,y1,z1},{x1,y1,z0},{x1,y0,z0},{x1,y0,z1},dark)
   end
   for zz=a,b,8 do bar(x+7,x+9,0,height,zz,zz+1)end
   for _,yy in ipairs{1,height*.5,height-1}do bar(x+7,x+9,yy,yy+1,a,b+1)end
  elseif o.kind=='mansionTrim'then
   local function inside(s,t)
    if s<0 or t<0 or s>=16 or t>=16 then return false end
    local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v);return a>.5 and r+g+b>.01 and not bg[rgb(r,g,b)]
   end
   draw(16,16,source,function(s,t)local m,u,v=source(s,t);return bg[rgb(B.pixel(ts,m,u,v))]end,function(s,t)return{x+s,0,z+t}end)
   draw(16,16,source,inside,function(s,t)return{x+s,c.edgeHeight,z+t}end)
   for t=0,15 do for s=0,15 do if inside(s,t)then local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
    for _,e in ipairs{{-1,0,s,t,s,t+1},{1,0,s+1,t+1,s+1,t},{0,-1,s+1,t,s,t},{0,1,s,t+1,s+1,t+1}}do if not inside(s+e[1],t+e[2])then
     G.quad(out,{x+e[3],c.edgeHeight,z+e[4]},{x+e[5],c.edgeHeight,z+e[6]},{x+e[5],0,z+e[6]},{x+e[3],0,z+e[4]},uv,c.sideShade)
    end end
   end end end
  elseif o.kind=='mansionStairs'then
   -- Use the Mansion's beige tread / pink handrail texels, never a palette
   -- search borrowed from a different building's white-metal stairs.
   local function uv(m,u,v)return G.uv(ts,m,u,v,u+1,v+1,.5)end
   local tread=uv(0x2d6,2,15);local riser=uv(0x2e6,15,12)
   local post=uv(0x2de,7,4);local rim=uv(0x2d6,2,15);local rail=uv(0x2e6,3,0);local dark=uv(0x2e6,0,0)
   local function q(a,b,d,e,tex,shade)G.quad(out,a,b,d,e,tex,shade or 1)end
   local sign=o.down and -1 or 1
   for step=0,7 do
    local a,b=x+step*6,x+(step+1)*6;local h=(step+1)*c.stairHeight/8*sign
    local prev=step*c.stairHeight/8*sign;local back,front=z+16,z+48
    q({a,h,back},{b,h,back},{b,h,front},{a,h,front},tread)
    q({a,math.max(h,prev),back},{a,math.max(h,prev),front},{a,math.min(h,prev),front},{a,math.min(h,prev),back},riser,c.riserShade)
    q({a,h+.02,back},{a+1,h+.02,back},{a+1,h+.02,front},{a,h+.02,front},rim)
    -- Closed stair stringer; the balusters above it remain genuinely open.
    q({a,h,front},{b,h,front},{b,0,front},{a,0,front},riser,c.sideShade)
    q({b,h,back},{a,h,back},{a,0,back},{b,0,back},riser,c.sideShade)
    for _,zz in ipairs{back,front-1}do
     local ha=prev+c.railHeight;local hb=h+c.railHeight
     q({a,ha,zz},{b,hb,zz},{b,hb,zz+1},{a,ha,zz+1},rail)
     q({a,ha,zz+1},{b,hb,zz+1},{b,hb-1,zz+1},{a,ha-1,zz+1},dark)
     q({b-2,hb,zz+1},{b-1,hb,zz+1},{b-1,h,zz+1},{b-2,h,zz+1},post)
     q({b-1,hb,zz+1},{b,hb,zz+1},{b,h,zz+1},{b-1,h,zz+1},dark)
    end
   end
   local high=c.stairHeight*sign
   q({x+48,high,z+16},{x+48,high,z+48},{x+48,0,z+48},{x+48,0,z+16},riser,c.sideShade)
   -- The unused back row remains native floor; the actual recessed flight is open.
   local m=o.floor
   draw(48,16,function(s,t)return m,s%16,t end,nil,function(s,t)return{x+s,0,z+t}end)
  elseif o.kind=='mansionPlant'or o.kind=='mansionDevice'or o.kind=='mansionStatue'then
   local clear,empty,q={},{},{}
   for t=0,31 do for s=0,15 do local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v)
    clear[t*16+s]=a<.5 or bg[rgb(r,g,b)]or(o.wall and t<16 and rgb(r,g,b)==rgb(B.pixel(ts,0x2b2,s,t)))
   end end
   local function seed(s,t)local k=t*16+s;if clear[k]and not empty[k]then empty[k]=true;q[#q+1]=k end end
   for s=0,15 do seed(s,0);seed(s,31)end;for t=0,31 do seed(0,t);seed(15,t)end
   local i=1;while q[i]do local k=q[i];i=i+1;local s,t=k%16,math.floor(k/16);if s>0 then seed(s-1,t)end;if s<15 then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t<31 then seed(s,t+1)end end
   local h=(o.kind=='mansionPlant'and c.plantHeight or o.kind=='mansionStatue'and c.statueHeight or c.deviceHeight)*V.require('Billboard').heightScale()
   draw(16,32,source,function(s,t)return not empty[t*16+s]end,function(s,t)return{x+s,h*(32-t)/32,z+32}end)
   contacts[#contacts+1]={x+8,z+31,6,c.contactRadius,c.contactStrength}
  end
  V.require('RoomLightRig').capture(L,o,out,first,#out)
 end
end
return R
