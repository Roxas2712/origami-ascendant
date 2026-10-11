-- Native type-9 Secret Base shells. Decoration and event state belong to the engine.
local V=...;local R={cache=setmetatable({},{__mode='k'}),underlays=setmetatable({},{__mode='k'})}
function R.kind(d)
 if not d or tonumber(d.mapType)~=9 then return end
 local p=V.data('Emerald').secretBaseRooms[d.id or d.name];local L=d.midLayout
 if p and d.pair==p.pair and L and L.width==p.width and L.height==p.height then return p.theme end
end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors
 if c.enabled and c.secretBases.enabled and R.kind(d)then return c.homeRooms.secretBase end
end
local function wall(m)return m>=0x201 and m<=0x213 and m~=0x204 and m~=0x208 and m~=0x20a and m~=0x20c and m~=0x20e and m~=0x20f end
local function stone(m)return m==0x20e or m==0x20f or m==0x214 end
local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.relief(L,ts)
 local old=R.cache[L];if old and old.ts==ts then return old end
 local pixel=V.require('BuildingMesh').pixel;local palette={};local under=R.underlays[L]or{}
 for t=0,15 do for s=0,15 do palette[key(pixel(ts,0x20a,s,t))]=true end end
 local w,h=L.width*16,L.height*16;local eligible,ground,rock,dist,void,q={},{},{},{},{},{}
 local function index(x,y)return y*w+x+1 end
 -- Flood only floor-connected native colours. Brown/yellow rock caps share
 -- floor colours, but their enclosing outlines must keep those caps solid.
 for y=0,h-1 do for x=0,w-1 do local i=index(x,y);local tx,ty=math.floor(x/16),math.floor(y/16);local m=under[ty*L.width+tx+1]or L:midAt(tx,ty)
  void[i]=m==0x208
  eligible[i]=wall(m)and palette[key(pixel(ts,m,x%16,y%16))]or false
  if not wall(m)and not void[i]then ground[i]=true;q[#q+1]=i end
 end end
 local at=1
 while q[at]do local i=q[at];at=at+1;local x,y=(i-1)%w,math.floor((i-1)/w)
  for _,d in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do local xx,yy=x+d[1],y+d[2]
   if xx>=0 and xx<w and yy>=0 and yy<h then local j=index(xx,yy)
    if eligible[j]and not ground[j]then ground[j]=true;q[#q+1]=j end
   end
  end
 end
 q={};for i=1,w*h do rock[i]=not ground[i]and not void[i];if ground[i]then dist[i]=0;q[#q+1]=i end end
 at=1
 while q[at]do local i=q[at];at=at+1;local x,y=(i-1)%w,math.floor((i-1)/w)
  for _,d in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do local xx,yy=x+d[1],y+d[2]
   if xx>=0 and xx<w and yy>=0 and yy<h then local j=index(xx,yy)
    if not void[j]and dist[j]==nil then dist[j]=dist[i]+1;q[#q+1]=j end
   end
  end
 end
 local function isVoid(x,y)return x<0 or y<0 or x>=w or y>=h or void[index(x,y)]end
 local function height(x,y)
  local c=V.require('DioramaConfig').emeraldInteriors.secretBases;local d=math.huge
  for yy=y-1,y do for xx=x-1,x do if not isVoid(xx,yy)then d=math.min(d,dist[index(xx,yy)]or math.huge)end end end
  return math.min(c.wallHeight,d*c.wallSlope)
 end
 local shape={}
 for z=0,L.height-1 do for x=0,L.width-1 do local m=under[z*L.width+x+1]or L:midAt(x,z);shape[#shape+1]=(wall(m)or stone(m)or m==0x208)and m or 0 end end
 local field={geometryKey=table.concat(shape,','),ts=ts,width=w,heightPixels=h,rock=function(x,y)return not isVoid(x,y)and rock[index(x,y)]end,height=height,isVoid=isVoid}
 R.cache[L]=field;return field
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;R.cache[L]=nil;local objects,under=V.require('EmeraldSecretDecor').plan(d);R.underlays[L]=under;local mask={};for i,m in pairs(under)do mask[i]=m end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=under[y*L.width+x+1]or L:midAt(x,y)
  if m==0x208 then mask[y*L.width+x+1]={mid=m,void=true}
  elseif wall(m)then objects[#objects+1]={kind='secretRelief',x=x,y=y,w=16,h=16,mid=m,noContact=true};mask[y*L.width+x+1]={mid=m,void=true}
  elseif stone(m)then objects[#objects+1]={kind='secretStone',x=x,y=y,w=16,h=16,mid=m,noContact=true};mask[y*L.width+x+1]=0x20a end
 end end
 return objects,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.secretBases;local G=V.require('WorldGeometry')
 if o.kind=='secretDecor'then return V.require('EmeraldSecretDecor').build(out,L,ts,o,x,z,contacts)end
 if o.kind=='secretStone'then
  local src,inside=V.require('EmeraldCableRooms').cutout(L,ts,o.x*16,o.y*16,16,16,{0x20a})
  local vv=V.require('PaperSprite').build(ts,16,16,src,inside,0,16,1,nil,function(s,t)return{x+s,c.stoneHeight*(16-t)/16*cfg.heightScale*V.require('Billboard').heightScale(),z+16}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
  if contacts then contacts[#contacts+1]={x+8,z+15,5,2,c.contactStrength}end;return
 end
 local field=R.relief(L,ts);local ox,oz=o.x*16,o.y*16
 local function pos(s,t)return{x+s,field.height(ox+s,oz+t)*cfg.heightScale,z+t}end
 for t=0,15 do local s=0;while s<16 do
  local start=s;local rock=field.rock(ox+s,oz+t)
  local function y(s,t)return rock and field.height(ox+s,oz+t)*cfg.heightScale or 0 end
  local slope=y(s+1,t)-y(s,t);local lower=y(s+1,t+1)-y(s,t+1);s=s+1
  if math.abs(slope-lower)<.00001 then
   while s<16 and field.rock(ox+s,oz+t)==rock and math.abs(y(s+1,t)-y(s,t)-slope)<.00001 and math.abs(y(s+1,t+1)-y(s,t+1)-slope)<.00001 do s=s+1 end
  end
  local function point(xx,tt)return{x+xx,y(xx,tt),z+tt}end
  G.quad(out,point(start,t),point(s,t),point(s,t+1),point(start,t+1),G.uv(ts,o.mid,start,t,s,t+1,.5),1)
  if rock then for u=start,s-1 do for _,e in ipairs{{0,0,0,1,-1,0},{1,1,1,0,1,0},{1,0,0,0,0,-1},{0,1,1,1,0,1}}do
   if field.isVoid(ox+u+e[5],oz+t+e[6])then local a,b=pos(u+e[1],t+e[2]),pos(u+e[3],t+e[4])
    if a[2]>0 or b[2]>0 then G.quad(out,a,b,{b[1],0,b[3]},{a[1],0,a[3]},G.uv(ts,0x210,u,0,u+1,16,.5),c.sideShade)end
   end
  end end end
 end end
end
function R.lighting(d)
 if not R.profile(d)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.secretBases;local L=d.midLayout;local theme=R.kind(d)
 local p={fixed=true,ambient=(theme=='TREE'or theme=='SHRUB')and c.foliageAmbient or c.rockAmbient,localSelection=true,sources={}}
 -- Broad, low-energy bounced light: fixed in room space, never a player lamp.
 for y=2,L.height-2,5 do for x=2,L.width-2,5 do
  local bx,by,score
  for yy=math.max(1,y-2),math.min(L.height-2,y+2)do for xx=math.max(1,x-2),math.min(L.width-2,x+2)do
   if L.cells[yy*L.width+xx+1].mid==0x20a then local dd=(xx-x)^2+(yy-y)^2;if not score or dd<score then bx,by,score=xx,yy,dd end end
  end end
  if bx then p.sources[#p.sources+1]={at={bx*16+8,c.lightHeight,by*16+8},radius=c.lightRadius,power=c.lightPower,color=c.lightColor,spread={24,20},cone=-.1}end
 end end
 return p
end
function R.light(d,state)
 if R.profile(d)then local c=V.require('DioramaConfig').emeraldInteriors.secretBases;state.sun=c.keyPower;state.direction={unpack(c.keyDirection)}end
end
return R
