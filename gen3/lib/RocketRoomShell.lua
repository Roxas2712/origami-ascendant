-- Measured Rocket shell over the native map. Furniture remains independently
-- owned; collision, arrow fields, doors and warp state are never rewritten.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local sizes={FR_ROCKET_HIDEOUT_B1F={28,34},FR_ROCKET_HIDEOUT_B2F={32,22},FR_ROCKET_HIDEOUT_B3F={22,28},FR_ROCKET_HIDEOUT_B4F={24,26},FR_FIVE_ISLAND_ROCKET_WAREHOUSE={30,28}}
local top={[0x289]=true,[0x28a]=true,[0x28b]=true,[0x2ff]=true,[0x26c]=true,[0x2c5]=true,[0x2ad]=true,[0x2af]=true,[0x2a2]=true,[0x2a3]=true,[0x2a4]=true}
local borders={[0x288]=true,[0x290]=true,[0x28c]=true,[0x294]=true,[0x298]=true,[0x299]=true,[0x29a]=true,[0x29c]=true,[0x2b3]=true,[0x2b4]=true,[0x26d]=true,[0x2de]=true,[0x2df]=true,[0x2e6]=true,[0x2e7]=true,[0x2e1]=true}
local barriers={[0x28d]=true,[0x28e]=true,[0x295]=true,[0x296]=true,[0x297]=true,[0x29d]=true,[0x29e]=true,[0x29f]=true,[0x2a5]=true,[0x2a7]=true,[0x2ae]=true,[0x2e5]=true}
local variants={
 {tiles={0x252,0x253,0x254,0x25a,0x25b,0x25c,0x262,0x263,0x264},left=true},
 {tiles={0x255,0x256,0x257,0x25d,0x25e,0x25f,0x265,0x266,0x267},left=false,down=true},
 {tiles={0x2cb,0x2cc,0x2cd,0x2d3,0x2d4,0x2d5,0x2db,0x2dc,0x2dd},left=false},
 {tiles={0x26e,0x2c9,0x2ca,0x2d0,0x2d1,0x2d2,0x2d8,0x2d9,0x2da},left=true,down=true},
 {tiles={0x250,0x251,0x268,0x258,0x259,0x270,0x260,0x261,0x278},left=false},
}
local function cfg()return V.require('DioramaConfig').interiors.rocketShell end
function R.profile(d)
 local id=d and(d.id or d.name);local s=sizes[id];local L=d and d.midLayout
 local warehouse=id=='FR_FIVE_ISLAND_ROCKET_WAREHOUSE'
 return (not warehouse or V.require('DioramaConfig').interiors.rocketWarehouse.enabled) and cfg().enabled and s and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4ecc'and L and L.width==s[1]and L.height==s[2] and L:midAt(1,id=='FR_ROCKET_HIDEOUT_B1F'and 6 or 0)==((id=='FR_ROCKET_HIDEOUT_B3F'or warehouse)and 0x2ad or 0x289)
end
function R.plan(d,objects,mask)
 local L=d.midLayout;if L then R.rooms[L]=nil end
 if not R.profile(d)then return end
 local owned={};R.rooms[L]=owned
 local function add(o,x,y,w,h,void)
  o.x=x;o.y=y;o.w=w;o.h=h;objects[#objects+1]=o;owned[#owned+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=0x281,void=void,separateSurface=true}end end
  return o
 end
 -- All nine complete native stair drawings; partial patterns are not erased.
 for y=0,L.height-3 do for x=0,L.width-3 do for _,v in ipairs(variants)do
  if L:midAt(x,y)==v.tiles[1]then
   local ok=true;for i,m in ipairs(v.tiles)do if L:midAt(x+(i-1)%3,y+math.floor((i-1)/3))~=m then ok=false;break end end
   if ok then add({kind='rocketStairs',left=v.left,down=v.down},x,y,3,3,true)end
  end
 end end end
 -- Equipment which overlaps the rear course must retain its own full source.
 for y=0,L.height-3 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if m==0x2ad and x+2<L.width and L:midAt(x+1,y)==0x2af and L:midAt(x,y+1)==0x2b5 then
   add({kind='rocketMachine',generator=true},x,y,3,3)
  elseif m==0x2ff and L:midAt(x,y+1)==0x307 and L:midAt(x,y+2)==0x30f then
   add({kind='rocketMachine',pc=true},x,y,1,3)
  elseif (m==0x305 or m==0x306)and L:midAt(x,y+1)==m+8 then
   add({kind='rocketMachine',small=true},x,y,1,2)
  elseif (m==0x300 and L:midAt(x,y+1)==0x308)or((m==0x301 or m==0x302)and L:midAt(x,y+1)==0x309)then
   add({kind='rocketPlant',wall=m==0x302},x,y,1,2)
  end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y);local k=y*L.width+x+1
  if m==0 or m==8 then mask[k]={mid=8,void=true,separateSurface=true}
  elseif borders[m]or d.id=='FR_FIVE_ISLAND_ROCKET_WAREHOUSE'and(m==0x2e0 or m==0x3ed or m==0x3ee)then add({kind='rocketBorder'},x,y,1,1,true)
  elseif barriers[m]and not(type(mask[k])=='table'and mask[k].separateSurface)then add({kind='rocketBarrier'},x,y,1,1)
  end
  if y<L.height-1 and top[m]then
   local bottom=L:midAt(x,y+1);local clear=not(m==0x289 and bottom==0x291 or m==0x28a and bottom==0x292 or m==0x28b and bottom==0x293 or m>=0x2a2 and m<=0x2a4 and bottom==m+8)
   -- Keep original grille/intercom artwork, replace only the background behind
   -- a separate machine or stair. A complete wall is always the same height.
   add({kind='rocketWall',top=clear and 0x289 or m,bottom=clear and 0x291 or bottom},x,y,1,2,true)
  end
 end end
 -- Restore source ownership for stair/machine cells below the wall course.
 for _,o in ipairs(owned)do if o.kind=='rocketStairs'or o.kind=='rocketMachine'or o.kind=='rocketPlant'then
  for yy=o.y,o.y+o.h-1 do for xx=o.x,o.x+o.w-1 do
   mask[yy*L.width+xx+1]={mid=0x281,void=o.kind=='rocketStairs'or o.kind=='rocketMachine'and yy<o.y+2 and not o.small or o.kind=='rocketPlant'and o.wall and yy==o.y,separateSurface=true}
  end end
 end end
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.height(o,px,pz)
 local x,z=px-o.x*16,pz-o.y*16
 if x<0 or x>=48 or z<16 or z>48 then return end
 local n=math.min(7,math.floor(x/6));local step=o.left and 8-n or n+1
 return step*cfg().stairHeight/8*(o.down and -1 or 1)
end
function R.actorOffset(d,px,pz,gid)
 if not R.profile(d)then return end
 for _,o in ipairs(R.rooms[d.midLayout]or{})do if o.kind=='rocketStairs'then
  local h=R.height(o,px+8,pz+16);if h then return h,0 end
 elseif gid==92 and o.kind=='rocketBorder'and math.floor((px+8)/16)==o.x and math.floor((pz+15.99)/16)==o.y then
  -- Pickups use the centre of the narrow native edge tile, rather than
  -- the humanoid foot at its far edge (which is already outside the room).
  return cfg().edgeHeight,-cfg().pickupInset
 end end
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 if not R.rooms[L]then return end
 local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local c=cfg()
 local floor={};for _,m in ipairs{0x281,0x282,0x283,0x285,0x286,0x287}do
  for sy=0,15 do for sx=0,15 do floor[rgb(B.pixel(ts,m,sx,sy))]=true end end
 end
 local function q(a,b,d,e,uv,shade)G.quad(out,a,b,d,e,uv,shade or 1)end
 for _,o in ipairs(R.rooms[L])do
  local x,z=(o.x+ox)*16,(o.y+oz)*16
  local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local function draw(W,H,src,inside,project)
   local vv=V.require('PaperSprite').build(ts,W,H,src,inside,0,H,1,nil,project,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
  end
  if o.kind=='rocketWall'then
   draw(16,32,function(s,t)return t<16 and o.top or o.bottom,s,t%16 end,function()return true end,
    function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
   local uv=G.uv(ts,o.top,1,0,2,1,.5)
   q({x,c.wallHeight,z+32-c.wallDepth},{x+16,c.wallHeight,z+32-c.wallDepth},{x+16,c.wallHeight,z+32},{x,c.wallHeight,z+32},uv)
   for _,sx in ipairs{0,16}do q({x+sx,c.wallHeight,z+32-c.wallDepth},{x+sx,c.wallHeight,z+32},{x+sx,0,z+32},{x+sx,0,z+32-c.wallDepth},uv,c.sideShade)end
  elseif o.kind=='rocketBorder'or o.kind=='rocketBarrier'then
   local m=L:midAt(o.x,o.y);local H=o.kind=='rocketBorder'and c.edgeHeight or c.dividerHeight
   -- A return corner shares half a column with the rear wall. Separate
   -- that half from the low side trim, rather than laying wall pixels flat.
   local upper=m==0x2de or m==0x2df
   local lower=m==0x2e6 or m==0x2e7
   local left=m==0x2de or m==0x2e6
   local joined=upper and o.y+1<L.height and L:midAt(o.x,o.y+1)==m+8
    or lower and o.y>0 and L:midAt(o.x,o.y-1)==m-8
   local function wallHalf(s)return joined and(left and s<8 or not left and s>=8)end
   if upper and joined then
    draw(16,32,function(s,t)return t<16 and 0x289 or 0x291,s,t%16 end,
     function(s)return wallHalf(s)end,function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
   end
   local function inside(s,t)
    if s<0 or s>=16 or t<0 or t>=16 or wallHalf(s)then return false end
    local r,g,b,a=B.pixel(ts,m,s,t);return a>.5 and r+g+b>.01 and not floor[rgb(r,g,b)]
   end
   draw(16,16,source,inside,function(s,t)return{x+s,H,z+t}end)
   if o.kind=='rocketBorder'then draw(16,16,source,function(s,t)local r,g,b=B.pixel(ts,m,s,t);return not wallHalf(s)and floor[rgb(r,g,b)]end,function(s,t)return{x+s,0,z+t}end)end
   for t=0,15 do for s=0,15 do if inside(s,t)then
    local uv=G.uv(ts,m,s,t,s+1,t+1,.5);local a,b=x+s,z+t
    if not inside(s-1,t)then q({a,H,b},{a,H,b+1},{a,0,b+1},{a,0,b},uv,c.sideShade)end
    if not inside(s+1,t)then q({a+1,H,b+1},{a+1,H,b},{a+1,0,b},{a+1,0,b+1},uv,c.sideShade)end
    if not inside(s,t-1)then q({a+1,H,b},{a,H,b},{a,0,b},{a+1,0,b},uv,c.sideShade)end
    if not inside(s,t+1)then q({a,H,b+1},{a+1,H,b+1},{a+1,0,b+1},{a,0,b+1},uv,c.sideShade)end
   end end end
  elseif o.kind=='rocketMachine'then
   local W,H=o.w*16,o.h*16;local last=o.small and 32 or 48;local front=last
   -- Remove only background connected to the perimeter. A matching wall
   -- colour enclosed by the housing is still part of the original machine.
   local candidate,empty,queue={},{},{}
   for t=0,H-1 do for s=0,W-1 do
    local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v)
    local donor=o.small and(t<16 and 0x291 or 0x282)or(t<16 and 0x289 or t<32 and 0x291 or 0x282)
    candidate[t*W+s]=a<.5 or rgb(r,g,b)==rgb(B.pixel(ts,donor,u,v))or(t>=(o.small and 16 or 32)and floor[rgb(r,g,b)])
   end end
   local function seed(s,t)local k=t*W+s;if candidate[k]and not empty[k]then empty[k]=true;queue[#queue+1]=k end end
   for s=0,W-1 do seed(s,0);seed(s,H-1)end;for t=0,H-1 do seed(0,t);seed(W-1,t)end
   local n=1;while queue[n]do local k=queue[n];n=n+1;local s,t=k%W,math.floor(k/W)
    if s>0 then seed(s-1,t)end;if s<W-1 then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t<H-1 then seed(s,t+1)end
   end
   local function inside(s,t)return s>=0 and s<W and t>=0 and t<last and not empty[t*W+s]end
   front=0;for t=0,H-1 do for s=0,W-1 do if inside(s,t)then front=math.max(front,t+1)end end end
   draw(W,H,source,inside,function(s,t)return{x+s,(front-t)*c.machineScale,z+front}end)
   for t=0,last-1 do for s=0,W-1 do if inside(s,t)then
    local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local a,b=x+s,z+front;local h0,h1=(front-t)*c.machineScale,(front-t-1)*c.machineScale
    if not inside(s-1,t)then q({a,h0,b-c.machineDepth},{a,h0,b},{a,h1,b},{a,h1,b-c.machineDepth},uv,c.sideShade)end
    if not inside(s+1,t)then q({a+1,h0,b},{a+1,h0,b-c.machineDepth},{a+1,h1,b-c.machineDepth},{a+1,h1,b},uv,c.sideShade)end
    if not inside(s,t-1)then q({a,h0,b-c.machineDepth},{a+1,h0,b-c.machineDepth},{a+1,h0,b},{a,h0,b},uv)end
    if not inside(s,t+1)then q({a,h1,b},{a+1,h1,b},{a+1,h1,b-c.machineDepth},{a,h1,b-c.machineDepth},uv,c.sideShade)end
   end end end
   contacts[#contacts+1]={x+W/2,z+front,W/2-1,c.contactRadius,c.contactStrength}
  elseif o.kind=='rocketPlant'then
   local bg={};for _,m in ipairs{0x281,0x282,o.wall and 0x291 or 0x282}do
    for sy=0,15 do for sx=0,15 do bg[rgb(B.pixel(ts,m,sx,sy))]=true end end
   end
   local candidate,empty,queue={},{},{}
   for t=0,31 do for s=0,15 do local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v);candidate[t*16+s]=a<.5 or bg[rgb(r,g,b)] end end
   local function seed(s,t)local k=t*16+s;if candidate[k]and not empty[k]then empty[k]=true;queue[#queue+1]=k end end
   for s=0,15 do seed(s,0);seed(s,31)end;for t=0,31 do seed(0,t);seed(15,t)end
   local n=1;while queue[n]do local k=queue[n];n=n+1;local s,t=k%16,math.floor(k/16)
    if s>0 then seed(s-1,t)end;if s<15 then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t<31 then seed(s,t+1)end
   end
   draw(16,32,source,function(s,t)return not empty[t*16+s]end,function(s,t)return{x+s,(32-t)*c.plantHeight/32*V.require('Billboard').heightScale(),z+32}end)
   contacts[#contacts+1]={x+8,z+31,6,c.contactRadius,c.contactStrength}
  elseif o.kind=='rocketStairs'then
   -- Choose colours from this actual stair drawing, not an arbitrary atlas
   -- pixel. Dark one-pixel nosings keep each tread readable from the front.
   local targets={{239,239,255},{173,165,206},{82,74,107},{222,214,239},{148,140,173}}
   local uv,best={},{}
   for t=0,47 do for s=0,47 do local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v)
    if a>.5 then for i,col in ipairs(targets)do local delta=(r*255-col[1])^2+(g*255-col[2])^2+(b*255-col[3])^2
     if not best[i]or delta<best[i]then best[i]=delta;uv[i]=G.uv(ts,m,u,v,u+1,v+1,.5)end
    end end
   end end
   for t=0,15 do q({x,0,z+t},{x+48,0,z+t},{x+48,0,z+t+1},{x,0,z+t+1},G.uv(ts,0x281,0,t,16,t+1,.5))end
   for i=0,7 do
    local step=o.left and 8-i or i+1;local H=step*c.stairHeight/8*(o.down and -1 or 1)
    local a,b=x+i*6,x+(i+1)*6;local back,front=z+16,z+48
    q({a,H,back},{b,H,back},{b,H,front},{a,H,front},uv[1])
    if i<7 then local nextStep=o.left and 7-i or i+2;local h2=nextStep*c.stairHeight/8*(o.down and -1 or 1)
     q({b,H,back},{b,H,front},{b,h2,front},{b,h2,back},uv[2],c.riserShade)
    end
    q({a,H,front},{b,H,front},{b,0,front},{a,0,front},uv[5],c.sideShade)
    q({b,H,back},{a,H,back},{a,0,back},{b,0,back},uv[5],c.sideShade)
    local edge=o.left and b or a;local inset=o.left and -1 or 1
    q({edge,H+.02,back},{edge+inset,H+.02,back},{edge+inset,H+.02,front},{edge,H+.02,front},uv[3])
    for _,zz in ipairs{back,front-1}do
     local ha=(o.left and 1-i/8 or i/8)*c.stairHeight*(o.down and -1 or 1)+c.railHeight
     local hb=(o.left and 1-(i+1)/8 or (i+1)/8)*c.stairHeight*(o.down and -1 or 1)+c.railHeight
     q({a,ha,zz},{b,hb,zz},{b,hb,zz+1},{a,ha,zz+1},uv[4])
     q({a,ha,zz+1},{b,hb,zz+1},{b,hb-1,zz+1},{a,ha-1,zz+1},uv[4])
     q({a,ha,zz},{a+1,ha,zz},{a+1,H,zz},{a,H,zz},uv[3])
    end
   end
   if not o.down then local sx=o.left and x or x+48;q({sx,c.stairHeight,z+16},{sx,c.stairHeight,z+48},{sx,0,z+48},{sx,0,z+16},uv[5],c.sideShade)end
  end
 end
end
return R
