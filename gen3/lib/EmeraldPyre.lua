-- Measured memorial hall surfaces. Original holes, events and collision stay native.
local V=...
local P={}
local sizes={{22,20},{14,14},{14,14},{14,14},{14,14},{14,14}}
local checks={{10,0x2b3},{1,0x2c3},{1,0x2b3},{9,0x2b3},{1,0x2b3},{1,0x2c3}}
local terraces={[4]={row=4,x=9,w=3},[5]={row=4,x=2,w=1},[6]={row=6,x=10,w=1}}
function P.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 local n=tonumber((d.id or d.name or''):match('^EM_MT_PYRE_(%d)F$'));local size=n and sizes[n]
 if c.enabled and c.pyre.enabled and size and d.pair=='general__facility'and L
  and L.width==size[1]and L.height==size[2]and L:midAt(checks[n][1],0)==checks[n][2]then return c.homeRooms['pyre'..n]end
end
local wallTop={[0x2ef]=true,[0x2e4]=true,[0x31f]=true,[0x2ea]=true,[0x30f]=true}
function P.plan(d)
 local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.pyre;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 local function blank(x,y)mask[y*L.width+x+1]={mid=0x201,void=true}end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x201 then blank(x,y)
  elseif wallTop[m]then
   add('wall',x,y,1,2,{wallHeight=c.wallHeight,wallBase=32,wallLast=32});blank(x,y);blank(x,y+1)
  elseif m==0x2b3 or m==0x2c3 then
   add('pyreStairs',x,y,3,3,{down=m==0x2c3})
   for dx=0,2 do blank(x+dx,y);blank(x+dx,y+1);mask[(y+2)*L.width+x+dx+1]=0x2e6 end
  elseif m==0x2ee or m==0x326 or m==0x2ed or m==0x3d7 then
   add('pyreGrave',x,y,1,1);mask[y*L.width+x+1]=0x2e6

  elseif m==0x2e7 or m==0x2e8 or m==0x2e9 then mask[y*L.width+x+1]=0x2e6 end
 end end
 local n=tonumber((d.id or d.name):match('_(%d)F$'));local terrace=terraces[n]
 if terrace then
  -- Raised floor and its occupants share the same visual height. The ROM's
  -- elevation values continue to govern walking and falling unchanged.
  for _,o in ipairs(objects)do if o.y<terrace.row then
   o.base=c.terraceHeight;if o.kind=='wall'then o.kind='pyreRaisedWall'end
  elseif o.y==terrace.row then
   if o.kind=='wall'then o.wallHeight=c.terraceHeight
   elseif o.kind=='pyreStairs'then o.frameHeight=c.terraceHeight end
  end end
  for y=0,terrace.row-1 do for x=0,L.width-1 do local k=y*L.width+x+1;local m=mask[k]
   if not(type(m)=='table'and m.void)then
    add('pyreFloor',x,y,1,1,{floor=type(m)=='number'and m or L:midAt(x,y),base=c.terraceHeight});blank(x,y)
   end
  end end
  -- The front wall occupies two source rows. A native floor cap behind its
  -- upper edge closes the volume instead of leaving a slit above the facade.
  for x=0,12 do if x<terrace.x or x>=terrace.x+terrace.w then
   add('pyreFloor',x,terrace.row,1,2,{floor=0x2e6,base=c.terraceHeight})
  end end
  add('pyreFlight',terrace.x,terrace.row,terrace.w,2)
  for y=terrace.row,terrace.row+1 do for x=terrace.x,terrace.x+terrace.w-1 do blank(x,y)end end
 end
 return objects,mask
end
function P.actorHeight(d,x,z)
 if not P.profile(d)then return end
 local n=tonumber((d.id or d.name):match('_(%d)F$'));local t=terraces[n];if not t then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local top=t.row*16;local foot=z+16;local h=cfg.pyre.terraceHeight
 if foot<=top then return h*cfg.heightScale end
 if foot<top+32 and x+8>=t.x*16 and x+8<=(t.x+t.w)*16 then
  return h*(top+32-foot)/32*cfg.heightScale
 end
 return 0
end
-- Grave contour excludes the painted ground and the eastward cast shadow.
local bounds={{5,11},{4,12},{3,13},{2,13},{2,13},{2,13},{2,14},{1,13},{1,13},{1,13},{1,13},{1,13},{1,14},{1,14},{1,14}}
function P.graveInside(s,t)local r=bounds[t+1];return r and s>=r[1]and s<r[2]or false end
function P.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.pyre;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function band(a,b,project,inside)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(m,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 if o.kind=='pyreFloor'then
  for yy=0,o.h-1,16 do G.quad(out,{x,0,z+yy},{x+o.w,0,z+yy},{x+o.w,0,z+yy+16},{x,0,z+yy+16},G.uv(ts,o.floor,0,0,16,16,.5))end
 elseif o.kind=='pyreRaisedWall'then
  band(0,32,function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
 elseif o.kind=='pyreFlight'then
  for j=0,7 do local a=j*4;local h=c.terraceHeight*(8-j)/8
   band(a,a+2,function(s,t)return{x+s,h,z+a+(t-a)*2}end)
   band(a+2,a+4,function(s,t)return{x+s,h-(t-a-2)*c.terraceHeight/16,z+a+4}end)
   for _,sx in ipairs({0,o.w})do patch(0x2de,8,a%16,{x+sx,h,z+a},{x+sx,h,z+a+4},{x+sx,0,z+a+4},{x+sx,0,z+a},.96)end
  end
 elseif o.kind=='pyreGrave'then
  band(0,12,function(s,t)return{x+s,c.baseHeight+(12-t)*(c.graveHeight-c.baseHeight)/12,z+12}end,P.graveInside)
  band(12,15,function(s,t)return{x+s,c.baseHeight*(15-t)/3,z+12+(t-12)}end,P.graveInside)
  if contacts and not o.base then contacts[#contacts+1]={x+7.5,z+14,6,2,c.contactStrength}end

 elseif o.kind=='pyreStairs'then
  -- The entire doorway frame is upright. Treads are separate surfaces in
  -- front of it, not the stretched tilted rectangular patch of the old path.
  band(0,32,function(s,t)return{x+s,(o.frameHeight or c.wallHeight)*(32-t)/32,z+32}end,function(s,t)return t<16 or s<8 or s>=40 or o.down end)
  if not o.down then
   for step=0,2 do
    local sy=16+step*5;local front=37+step*5;local h=(3-step)*c.stepHeight
    band(sy,sy+3,function(s,t)return{x+s,h,z+front-5+(t-sy)*5/3}end,function(s)return s>=8 and s<40 end)
    band(sy+3,sy+5,function(s,t)return{x+s,h-(t-sy-3)*c.stepHeight/2,z+front}end,function(s)return s>=8 and s<40 end)
    for _,s in ipairs({8,40})do patch(0x2bc,0,3,{x+s,h,z+front-5},{x+s,h,z+front},{x+s,0,z+front},{x+s,0,z+front-5},.96)end
   end
  end
 end
 for i=first,#out do out[i][2]=(out[i][2]+(o.base or 0))*cfg.heightScale end
end
function P.light(d,result,px,pz)
 if not P.profile(d)then return false end
 local c=V.require('DioramaConfig').emeraldInteriors.pyre
 result.sun=0;result.cave=false;result.flash=false
 result.shafts={};result.sprites={}
 local ambient,lights,rig=V.require('RoomLightRig').prepare(d,px,pz)
 if ambient then result.ambient=ambient;result.lights=lights;result.roomRig=rig
 else
  result.ambient={unpack(c.ambient)};result.lights={};result.roomRig=nil
  for _,p in ipairs(V.require('RoomLighting').plan(d))do
   result.lights[#result.lights+1]={x=p.x,y=p.y,z=p.z,radius=p.radius,power=c.lightPower,color=c.lightColor}
  end
 end
 return true
end
return P
