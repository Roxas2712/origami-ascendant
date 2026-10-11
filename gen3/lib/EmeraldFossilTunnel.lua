-- Source-contoured rock relief for the Fossil Maniac's tunnel (native type 8).
-- No map/collision/event data or source textures are rewritten.
local V=...;local R={cache=setmetatable({},{__mode='k'})}
local rocks={};for _,m in ipairs{0x268,0x269,0x26a,0x270,0x272,0x278,0x27a,0x2b7,0x2b8,0x2c5,0x2c6,0x347,0x34f}do rocks[m]=true end
local stones={[0x2af]=true,[0x2bf]=true,[0x2c7]=true}
function R.kind(d)return d and(d.id or d.name)=='EM_ROUTE114_FOSSIL_MANIACS_TUNNEL'end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d and d.midLayout
 if R.kind(d)and c.enabled and c.fossilTunnel.enabled and d.mapType==8 and d.pair=='general__fallarbor'
  and L and L.width==14 and L.height==26 and L:midAt(6,25)==0x2b1 and L:midAt(5,3)==0x303 then return c.homeRooms.fossilTunnel end
end
function R.lighting(d)if R.profile(d)then return V.require('DioramaConfig').emeraldInteriors.fossilTunnel.light end end
function R.light(d,state)
 if not R.profile(d)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.fossilTunnel
 state.sun=c.keyPower;state.direction={unpack(c.keyDirection)}
end
local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.relief(L,ts)
 local cached=R.cache[L];if cached and cached.ts==ts then return cached end
 local pixel=V.require('BuildingMesh').pixel;local palette={}
 for _,m in ipairs{0x269,0x270,0x272}do for t=0,15 do for s=0,15 do palette[key(pixel(ts,m,s,t))]=true end end end
 local w,h=L.width*16,L.height*16;local stone,void,dist,q={},{},{},{}
 local function index(x,y)return y*w+x+1 end
 for y=0,h-1 do for x=0,w-1 do
  local m=L:midAt(math.floor(x/16),math.floor(y/16));local i=index(x,y)
  stone[i]=rocks[m]and(m==0x347 or m==0x34f or palette[key(pixel(ts,m,x%16,y%16))])or false;void[i]=m==0x277
  if not stone[i]and not void[i]then dist[i]=0;q[#q+1]=i end
 end end
 -- Distance is measured from actual floor pixels, never from the outside void.
 -- This leaves broad rock masses high and every path pixel exactly at zero.
 local at=1
 while q[at]do local i=q[at];at=at+1;local x,y=(i-1)%w,math.floor((i-1)/w)
  for _,d in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do local xx,yy=x+d[1],y+d[2]
   if xx>=0 and xx<w and yy>=0 and yy<h then local j=index(xx,yy)
    if stone[j]and dist[j]==nil then dist[j]=dist[i]+1;q[#q+1]=j end
   end
  end
 end
 local function isRock(x,y)return x>=0 and x<w and y>=0 and y<h and stone[index(x,y)]end
 local function height(x,y)
  local c=V.require('DioramaConfig').emeraldInteriors.fossilTunnel;local d=math.huge
  for yy=y-1,y do for xx=x-1,x do if xx>=0 and xx<w and yy>=0 and yy<h then
   local i=index(xx,yy);if not void[i]then d=math.min(d,dist[i]or math.huge)end
  end end end
  return math.min(c.wallHeight,d*c.wallSlope)
 end
 cached={ts=ts,rock=isRock,height=height,width=w,heightPixels=h,isVoid=function(x,y)return x<0 or x>=w or y<0 or y>=h or void[index(x,y)]end};R.cache[L]=cached;return cached
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;R.cache[L]=nil;local list,mask={},{}
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y);local i=y*L.width+x+1
  if m==0x277 then mask[i]={mid=m,void=true}
  elseif rocks[m]then list[#list+1]={kind='fossilRock',x=x,y=y,w=16,h=16,mid=m,noContact=true};mask[i]={mid=0x279,void=true}
  elseif stones[m]then list[#list+1]={kind='fossilStone',x=x,y=y,w=16,h=16,mid=m,noContact=true};mask[i]=0x279 end
 end end
 return list,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.fossilTunnel;local G=V.require('WorldGeometry')
 if o.kind=='fossilStone'then
  local src,inside=V.require('EmeraldCableRooms').cutout(L,ts,o.x*16,o.y*16,16,16,{0x279,0x2fd})
  local h=o.mid==0x2c7 and c.pebblesHeight or c.stoneHeight
  local vv=V.require('PaperSprite').build(ts,16,16,src,inside,0,16,1,nil,function(s,t)return{x+s,h*(16-t)/16*cfg.heightScale*V.require('Billboard').heightScale(),z+16}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
  if contacts then contacts[#contacts+1]={x+8,z+15,5,2,c.contactStrength}end
  return
 end
 local field=R.relief(L,ts);local ox,oz=o.x*16,o.y*16
 local function pos(s,t)return{x+s,field.height(ox+s,oz+t)*cfg.heightScale,z+t}end
 for t=0,15 do local s=0;while s<16 do
  local start=s;local rock=field.rock(ox+s,oz+t)
  local function y(s,t)return rock and field.height(ox+s,oz+t)*cfg.heightScale or 0 end
  local slope=y(s+1,t)-y(s,t);local lower=y(s+1,t+1)-y(s,t+1)
  s=s+1
  -- Merge only coplanar runs inside one native tile. Corners and changes of
  -- slope stay split, so source-contour fidelity does not cost six vertices
  -- for every flat texel of a broad rock cap.
  if math.abs(slope-lower)<.00001 then
   while s<16 and field.rock(ox+s,oz+t)==rock
    and math.abs(y(s+1,t)-y(s,t)-slope)<.00001
    and math.abs(y(s+1,t+1)-y(s,t+1)-slope)<.00001 do s=s+1 end
  end
  local function point(xx,tt)return{x+xx,y(xx,tt),z+tt}end
  G.quad(out,point(start,t),point(s,t),point(s,t+1),point(start,t+1),G.uv(ts,o.mid,start,t,s,t+1,.5),1)
  if rock then for u=start,s-1 do
   for _,e in ipairs{{0,0,0,1,-1,0},{1,1,1,0,1,0},{1,0,0,0,0,-1},{0,1,1,1,0,1}}do
    if field.isVoid(ox+u+e[5],oz+t+e[6])then
     local a,b=pos(u+e[1],t+e[2]),pos(u+e[3],t+e[4])
     if a[2]>0 or b[2]>0 then G.quad(out,a,b,{b[1],0,b[3]},{a[1],0,a[3]},G.uv(ts,o.mid,u,t,u+1,t+1,.5),c.sideShade)end
    end
   end
  end end
 end end
end
return R
