-- Rocket furniture: original worktops, separate devices, seats and cupboards.
-- The native map and event positions remain authoritative.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.rocketFurniture end
function R.profile(d)return cfg().enabled and V.require('RocketRoomShell').profile(d)end
function R.plan(d,objects,mask)
 local L=d.midLayout;if L then R.rooms[L]=nil end
 if not R.profile(d)then return end
 local owned={};R.rooms[L]=owned
 local function add(kind,x,y,w,h)
  local o={kind=kind,x=x,y=y,w=w*16,h=h*16};objects[#objects+1]=o;owned[#owned+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1
   local old=mask[k];mask[k]={mid=0x281,void=type(old)=='table'and old.void,separateSurface=true}
  end end
  -- Only remove the original shadows touching this complete drawing.
  for yy=y,y+h do if x+w<L.width and yy<L.height then
   local m=L:midAt(x+w,yy)
   if m==0x283 or m==0x284 then mask[yy*L.width+x+w+1]={mid=0x281,separateSurface=true}end
  end end
  return o
 end
 local function matches(x,y,rows)
  if x+#rows[1]>L.width or y+#rows>L.height then return false end
  for dy,row in ipairs(rows)do for dx,m in ipairs(row)do if L:midAt(x+dx-1,y+dy-1)~=m then return false end end end
  return true
 end
 if d.id=='FR_FIVE_ISLAND_ROCKET_WAREHOUSE'then
  local narrow={
   {kind='rocketDrawingDesk',x=16,y=3,rows={{0x313,0x315},{0x31b,0x31d},{0x32b,0x32d}}},
   {kind='rocketWorkDesk',x=25,y=2,rows={{0x3e3,0x3e5},{0x2bb,0x2c4},{0x2c3,0x2c4},{0x2c0,0x2c2}}},
   {kind='rocketWorkDesk',x=26,y=9,rows={{0x3e3,0x3e5},{0x2bb,0x2ba},{0x3f4,0x2ba},{0x2c0,0x2c2}}},
   {kind='rocketSofa',x=24,y=8,rows={{0x3f5,0x3f6},{0x328,0x32a}}},
  }
  for _,n in ipairs(narrow)do if matches(n.x,n.y,n.rows)then add(n.kind,n.x,n.y,2,#n.rows)end end
 end
 local leftWork={[0x2b8]=true,[0x2bb]=true,[0x2c3]=true,[0x32e]=true}
 local middleWork={[0x2b9]=true,[0x326]=true,[0x32f]=true}
 local rightWork={[0x2ba]=true,[0x2c4]=true,[0x327]=true}
 local leftDrawing={[0x323]=true,[0x31e]=true,[0x31b]=true}
 local middleDrawing={[0x324]=true,[0x31f]=true,[0x316]=true}
 local rightDrawing={[0x325]=true,[0x31d]=true,[0x317]=true}
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if (m==0x2b0 or m==0x313)and x+2<L.width and L:midAt(x+1,y)==m+1 and L:midAt(x+2,y)==m+2 then
   local drawing=m==0x313;local sets=drawing and{leftDrawing,middleDrawing,rightDrawing}or{leftWork,middleWork,rightWork}
   for h=2,8 do
    local yy=y+h-1;if yy>=L.height then break end
    local a,b,c=L:midAt(x,yy),L:midAt(x+1,yy),L:midAt(x+2,yy)
    local bottom=drawing and(a==0x32b or a==0x3e8)and b==0x32c and c==0x32d
      or not drawing and(a==0x2c0 or a==0x2bc)and b==0x2c1 and c==0x2c2
    if bottom then add(drawing and'rocketDrawingDesk'or'rocketWorkDesk',x,y,3,h);break end
    if not(sets[1][a]and sets[2][b]and sets[3][c])then break end
   end
  elseif m==0x320 and matches(x,y,{{0x320,0x321,0x322},{0x328,0x329,0x32a}})then
   add('rocketSofa',x,y,3,2)
  elseif m==0x310 and matches(x,y,{{0x310,0x311},{0x310,0x311},{0x318,0x319}})and(y==0 or L:midAt(x,y-1)~=0x310)then
   add('rocketCupboard',x,y,2,3)
  elseif m==0x2e3 or m==0x2e4 or m==0x99 and d.id~='FR_FIVE_ISLAND_ROCKET_WAREHOUSE' then add('rocketStool',x,y,1,1)end
 end end
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local function flood(w,h,clear)
 local empty,queue={},{}
 local function seed(x,y)local k=y*w+x;if clear[k]and not empty[k]then empty[k]=true;queue[#queue+1]=k end end
 for x=0,w-1 do seed(x,0);seed(x,h-1)end;for y=0,h-1 do seed(0,y);seed(w-1,y)end
 local n=1;while queue[n]do local k=queue[n];n=n+1;local x,y=k%w,math.floor(k/w)
  if x>0 then seed(x-1,y)end;if x<w-1 then seed(x+1,y)end;if y>0 then seed(x,y-1)end;if y<h-1 then seed(x,y+1)end
 end
 return function(x,y)return x>=0 and y>=0 and x<w and y<h and not empty[y*w+x]end
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 if not cfg().enabled or not R.rooms[L]then return end
 local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local P=V.require('PaperSprite');local c=cfg()
 local bg={};for _,m in ipairs{0x281,0x282,0x283,0x284}do for y=0,15 do for x=0,15 do bg[rgb(B.pixel(ts,m,x,y))]=true end end end
 for _,o in ipairs(R.rooms[L])do
  local x,z=(o.x+ox)*16,(o.y+oz)*16
  local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local clear={};for t=0,o.h-1 do for s=0,o.w-1 do local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v)
   clear[t*o.w+s]=a<.5 or bg[rgb(r,g,b)]or(o.kind=='rocketCupboard'and t<16 and rgb(r,g,b)==rgb(B.pixel(ts,0x291,u,v)))
  end end
  local inside=flood(o.w,o.h,clear)
  local function band(a,b,project,src)
   local vv=P.build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and inside(s,t)end,0,o.h,1,nil,project,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
  end
  local function contact(front)for s=5,o.w-3,8 do contacts[#contacts+1]={x+s,z+front,5,c.contactRadius,c.contactStrength}end end
  local function q(a,b,d,e,uv,shade)G.quad(out,a,b,d,e,uv,shade or 1)end
  if o.kind=='rocketWorkDesk'or o.kind=='rocketDrawingDesk'then
   local front=o.h-16;local top=o.kind=='rocketDrawingDesk'and 3 or 12
   local donors={[0x2bb]=0x2b8,[0x2c3]=0x2b8,[0x2c4]=0x2ba,[0x3f4]=0x2b8}
   local function plain(s,t)local m,u,v=source(s,t);return donors[m]or m,u,v end
   band(top,front,function(s,t)return{x+s,c.deskHeight,z+t}end,plain)
   band(front,o.h-8,function(s,t)return{x+s,c.deskHeight*(o.h-8-t)/8,z+front}end)
   -- Close only the outer top contour; paper plans remain flat on the top.
   for t=top,front-1 do for s=0,o.w-1 do if inside(s,t)then
    local m,u,v=plain(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local a,b=x+s,z+t
    if not inside(s-1,t)then q({a,c.deskHeight,b},{a,c.deskHeight,b+1},{a,0,b+1},{a,0,b},uv,c.sideShade)end
    if not inside(s+1,t)then q({a+1,c.deskHeight,b+1},{a+1,c.deskHeight,b},{a+1,0,b},{a+1,0,b+1},uv,c.sideShade)end
    if t==top or not inside(s,t-1)then q({a+1,c.deskHeight,b},{a,c.deskHeight,b},{a,0,b},{a+1,0,b},uv,c.sideShade)end
   end end end
   if o.kind=='rocketWorkDesk'then
    for dy=1,o.h/16-2 do for dx=0,o.w/16-1 do
     local m=L:midAt(o.x+dx,o.y+dy)
     if m==0x2bb or m==0x2c4 then
      local h=m==0x2bb and 32 or 16;local donor=m==0x2bb and 0x2b8 or 0x2ba
      local function src(s,t)return source(dx*16+s,dy*16+t)end
      local diff={};for t=0,h-1 do for s=0,15 do local sm,u,v=src(s,t);local r,g,b,a=B.pixel(ts,sm,u,v);diff[t*16+s]=a<.5 or rgb(r,g,b)==rgb(B.pixel(ts,donor,u,v))end end
      local cut=flood(16,h,diff);local base=m==0x2bb and 29 or 16
      local scale=c.deviceScale*V.require('Billboard').heightScale()
      local vv=P.build(ts,16,h,src,function(s,t)return t<base and cut(s,t)end,0,h,1,nil,
       function(s,t)return{x+dx*16+s,c.deskHeight+(base-t)*scale,z+dy*16+base}end,.5)
      for _,v in ipairs(vv)do out[#out+1]=v end
     end
    end end
   end
   contact(front)
  elseif o.kind=='rocketStool'then
   band(0,9,function(s,t)return{x+s,c.seatHeight,z+5+t}end)
   band(9,16,function(s,t)return{x+s,c.seatHeight*(16-t)/7,z+14}end);contact(14)
  elseif o.kind=='rocketSofa'then
   band(9,20,function(s,t)return{x+s,c.seatHeight+(20-t)*(c.sofaHeight-c.seatHeight)/11,z+20}end)
   band(20,27,function(s,t)return{x+s,c.seatHeight,z+t}end)
   band(27,32,function(s,t)return{x+s,c.seatHeight*(32-t)/5,z+27}end);contact(27)
  elseif o.kind=='rocketCupboard'then
   local base=0;for t=0,o.h-1 do for s=0,o.w-1 do if inside(s,t)then base=math.max(base,t+1)end end end
   local scale=c.cupboardHeight/base*V.require('Billboard').heightScale()
   band(0,base,function(s,t)return{x+s,(base-t)*scale,z+base}end)
   for t=0,base-1 do for s=0,o.w-1 do if inside(s,t)then
    local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local a,b=x+s,z+base;local h0,h1=(base-t)*scale,(base-t-1)*scale
    if not inside(s-1,t)then q({a,h0,b-c.cupboardDepth},{a,h0,b},{a,h1,b},{a,h1,b-c.cupboardDepth},uv,c.sideShade)end
    if not inside(s+1,t)then q({a+1,h0,b},{a+1,h0,b-c.cupboardDepth},{a+1,h1,b-c.cupboardDepth},{a+1,h1,b},uv,c.sideShade)end
    if not inside(s,t-1)then q({a,h0,b-c.cupboardDepth},{a+1,h0,b-c.cupboardDepth},{a+1,h0,b},{a,h0,b},uv)end
   end end end
   contact(base)
  end
 end
end
function R.actorOffset(d,px,pz,gid)
 if not R.profile(d)then return end
 for _,o in ipairs(R.rooms[d.midLayout]or{})do
  local x,z=px+8-o.x*16,pz+16-o.y*16
  if gid==92 and(o.kind=='rocketWorkDesk'or o.kind=='rocketDrawingDesk')and x>=4 and x<o.w-4 and z>0 and z<=o.h then
   local top=o.kind=='rocketDrawingDesk'and 3 or 12;local front=o.h-16
   return cfg().deskHeight,math.max(top+2,math.min(front-2,z-cfg().pickupInset))-z
  end
  if o.kind=='rocketSofa'and x>=4 and x<o.w-4 and z>=16 and z<=32 then return cfg().seatHeight,27-z end
 end
end
return R
