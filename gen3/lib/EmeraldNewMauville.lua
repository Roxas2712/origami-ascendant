-- Measured industrial entrance. Native map/event/door state stays authoritative.
local V=...;local N={heights=setmetatable({},{__mode='k'})}
local floor={};for m=0x3ce,0x3d6 do floor[m]=true end;floor[0x3c7]=true
local floorColors={[0x845a5a]=true,[0x9c7373]=true,[0xbd948c]=true}
function N.profile(d)
 local hall=V.require('EmeraldPowerHall').profile(d);if hall then return hall end
 local a=V.require('DioramaConfig').emeraldInteriors;local L=d and d.midLayout
 if a.enabled and a.newMauville.enabled and d and(d.id or d.name)=='EM_NEW_MAUVILLE_ENTRANCE'
  and d.pair=='general__facility'and tonumber(d.mapType)==4 and L and L.width==10 and L.height==10
  and(L:midAt(3,0)==0x314 or L:midAt(3,0)==0x2c3)
  and(L:midAt(4,0)==0x315 or L:midAt(4,0)==0x2c4)
  and(L:midAt(5,0)==0x316 or L:midAt(5,0)==0x2c5)
  and L:midAt(4,6)==0x3c7 then return a.newMauville.entranceProfile end
end
function N.lighting(d)local hall=V.require('EmeraldPowerHall').lighting(d);if hall then return hall end;if N.profile(d)then return V.require('DioramaConfig').emeraldInteriors.newMauville.entranceLight end end
function N.isFloor(m)return floor[m]==true end
function N.plan(d)
 if V.require('EmeraldPowerHall').profile(d)then return V.require('EmeraldPowerHall').plan(d)end
 if not N.profile(d)then return end
 local L=d.midLayout;local list,mask={},{};N.heights[L]=nil
 for y=0,9 do for x=0,9 do
  local k=y*10+x+1;local m=L:midAt(x,y)
  if x>=3 and x<=5 and y<=2 then mask[k]={mid=0x3d0,void=true}
  elseif not floor[m]then
   mask[k]={mid=m,void=true};list[#list+1]={kind='newMauvilleRock',x=x,y=y,w=16,h=16,mid=m,noContact=true}
  end
 end end
 list[#list+1]={kind='newMauvilleGate',x=3,y=0,w=48,h=48,noContact=true}
 return list,mask
end
-- Distance from actual native floor cells. Rock texture stays on its own
-- continuous surface; no rectangular black side quads are inserted in gaps.
function N.height(L,x,z)
 local c=V.require('DioramaConfig').emeraldInteriors.newMauville;local d=math.huge
 local tag=c.rockHeight..':'..c.rockSlope..':'..c.frontRimHeight
 local cache=N.heights[L];if not cache or cache.tag~=tag then cache={tag=tag};N.heights[L]=cache end
 local key=z*161+x;local old=cache[key];if old then return old end
 for yy=1,7 do for xx=2,7 do
  if floor[L:midAt(xx,yy)]or(xx>=3 and xx<=5 and yy<=2)then
   local dx=math.max(xx*16-x,0,x-(xx+1)*16);local dz=math.max(yy*16-z,0,z-(yy+1)*16)
   d=math.min(d,math.max(dx,dz))
  end
 end end
 local cap=z>=112 and c.frontRimHeight or c.rockHeight
 local h=math.min(cap,d*c.rockSlope);cache[key]=h;return h
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function N.gateInside(ts,m,u,v,t)
 if t>=35 then return false end
 if t<31 then return true end
 return not floorColors[rgb(V.require('BuildingMesh').pixel(ts,m,u,v))]
end
function N.build(out,L,ts,o,x,z,contacts)
 if o.kind:match('^newMauvilleHall')then return V.require('EmeraldPowerHall').build(out,L,ts,o,x,z,contacts)end
 local a=V.require('DioramaConfig').emeraldInteriors;local c=a.newMauville;local G=V.require('WorldGeometry')
 if o.kind=='newMauvilleRock'then
  local function height(s,t)return N.height(L,o.x*16+s,o.y*16+t)*a.heightScale end
  local function point(s,t)return{x+s,height(s,t),z+t}end
  for t=0,15 do local s=0;while s<16 do
   local start=s;local slope=height(s+1,t)-height(s,t);local low=height(s+1,t+1)-height(s,t+1);s=s+1
   if math.abs(slope-low)<.0001 then
    while s<16 and math.abs(height(s+1,t)-height(s,t)-slope)<.0001 and math.abs(height(s+1,t+1)-height(s,t+1)-slope)<.0001 do s=s+1 end
   end
   G.quad(out,point(start,t),point(s,t),point(s,t+1),point(start,t+1),G.uv(ts,o.mid,start,t,s,t+1,.02),1)
  end end
  return
 end
 -- A single 48px native gate drawing, including both pillar feet. The three
 -- floor cells below it are reconstructed from the native floor, not tinted.
 for yy=0,2 do for xx=0,2 do
  G.quad(out,{x+xx*16,0,z+yy*16},{x+(xx+1)*16,0,z+yy*16},{x+(xx+1)*16,0,z+(yy+1)*16},{x+xx*16,0,z+(yy+1)*16},G.uv(ts,0x3d0),1)
 end end
 -- The gate stands in a rock tunnel. Cover the space behind its lintel with
 -- the native rock cap, rather than leaving an exposed black roof opening.
 for zz=0,35-c.gateDepth-1,16 do for xx=0,32,16 do
  local depth=math.min(16,35-c.gateDepth-zz);local h=c.rockHeight*a.heightScale
  G.quad(out,{x+xx,h,z+zz},{x+xx+16,h,z+zz},{x+xx+16,h,z+zz+depth},{x+xx,h,z+zz+depth},G.uv(ts,0x71,0,0,16,depth,.02),1)
 end end
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),math.floor(t/16)),s%16,t%16 end
 local vv=V.require('PaperSprite').build(ts,48,48,source,function(s,t,m,u,v)return N.gateInside(ts,m,u,v,t)end,0,35,1,nil,
  function(s,t)return{x+s,c.gateHeight*(35-t)/35*a.heightScale,z+35}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
 -- The top rim has native steel thickness, not an extra dark silhouette.
 G.quad(out,{x,c.gateHeight*a.heightScale,z+35-c.gateDepth},{x+48,c.gateHeight*a.heightScale,z+35-c.gateDepth},{x+48,c.gateHeight*a.heightScale,z+35},{x,c.gateHeight*a.heightScale,z+35},G.uv(ts,0x315,0,0,16,3,.5),1)
 if contacts then for s=4,44,8 do contacts[#contacts+1]={x+s,z+35,5,2,c.contactStrength}end end
end
function N.capture(list,o,x,z)
 if V.require('EmeraldPowerHall').capture(list,o,x,z)then return true end
 if o.kind=='newMauvilleRock'then return true end
 if o.kind~='newMauvilleGate'then return false end
 local a=V.require('DioramaConfig').emeraldInteriors;local c=a.newMauville
 -- Open lintel and jambs: the dark aperture is not an opaque room blocker.
 for _,b in ipairs{{0,8,0,c.gateHeight},{40,48,0,c.gateHeight},{8,40,c.gateHeight*23/35,c.gateHeight}}do
  list[#list+1]={lo={x+b[1],b[3]*a.heightScale,z+34},hi={x+b[2],b[4]*a.heightScale,z+35},wall=true}
 end
 return true
end
return N
