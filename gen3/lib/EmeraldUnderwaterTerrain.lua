-- Native underwater boundary art contains sea floor inside solid metatiles.
-- Keep that floor at sea-floor height and close only the authored rock hull.
local V=...;local T={cache=setmetatable({},{__mode='k'})}
local full={{0,0},{16,0},{16,16},{0,16}}
local mixed={}
for _,m in ipairs{0x20a,0x20b,0x20c,0x212,0x214,0x218,0x219,0x21a,0x21b,0x21c,0x220,0x221,0x222,0x223,0x238,0x239,0x260,0x261,0x27c,0x27d,0x27e,0x284,0x285,0x286,0x28d,0x28e}do mixed[m]=true end
local moundCorner={[0x27d]={0,0},[0x27e]={1,0},[0x285]={0,1},[0x286]={1,1}}
local function cfg()return V.require('DioramaConfig').underwater.terrain end
function T.active(d)return cfg().enabled and V.require('EmeraldUnderwater').active(d)and V.require('DioramaConfig').terrain.enabled end
function T.heightAt(d,x,y)
 local L=d.midLayout;local m=L:midAt(x,y)
 local a=moundCorner[m];if not a then return cfg().height end
 local bx,by=x-a[1],y-a[2]
 if L:midAt(bx,by)~=0x27d or L:midAt(bx+1,by)~=0x27e or L:midAt(bx,by+1)~=0x285 or L:midAt(bx+1,by+1)~=0x286 then return cfg().height end
 -- The same corner art also joins long reefs. Only an isolated 2x2 mound
 -- is a low boulder; never shorten an attached wall or change collision.
 for dy=-1,2 do for dx=-1,2 do if dx==-1 or dx==2 or dy==-1 or dy==2 then
  local c=L:cellAt(bx+dx,by+dy);if c and c.coll==7 then return cfg().height end
 end end end
 return cfg().rockHeight
end
local function cross(a,b,c)return(b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function T.polygon(ts,m)
 if not mixed[m]then return full end
 local cache=T.cache[ts];if not cache or cache.padding~=cfg().edgePadding then cache={padding=cfg().edgePadding};T.cache[ts]=cache end
 if cache[m]then return cache[m]end
 local pixel=V.require('BuildingMesh').pixel;local floor={}
 for y=0,15 do for x=0,15 do floor[rgb(pixel(ts,0x228,x,y))]=true end end
 local pts,seen={},{}
 local function add(x,y)
  x=math.max(0,math.min(16,x));y=math.max(0,math.min(16,y));local k=x..':'..y
  if not seen[k]then seen[k]=true;pts[#pts+1]={x,y}end
 end
 for y=0,15 do for x=0,15 do if not floor[rgb(pixel(ts,m,x,y))]then
  local p=cfg().edgePadding;add(x-p,y-p);add(x+1+p,y-p);add(x+1+p,y+1+p);add(x-p,y+1+p)
 end end end
 table.sort(pts,function(a,b)return a[1]==b[1]and a[2]<b[2]or a[1]<b[1]end)
 local lo,hi={},{}
 for _,p in ipairs(pts)do while #lo>=2 and cross(lo[#lo-1],lo[#lo],p)<=0 do lo[#lo]=nil end;lo[#lo+1]=p end
 for i=#pts,1,-1 do local p=pts[i];while #hi>=2 and cross(hi[#hi-1],hi[#hi],p)<=0 do hi[#hi]=nil end;hi[#hi+1]=p end
 local poly={};for i=1,#lo-1 do poly[#poly+1]=lo[i]end;for i=1,#hi-1 do poly[#poly+1]=hi[i]end
 assert(#poly>=3,'missing native submerged rock contour '..m);cache[m]=poly;return poly
end
local function contains(poly,x,y)
 for i,a in ipairs(poly)do if cross(a,poly[i%#poly+1],{x,y})<-.001 then return false end end;return true
end
function T.stamp(out,d,ts,x,y,ox,oz,cells)
 local G=V.require('WorldGeometry');local L=d.midLayout;local m=L:midAt(x,y);local h=T.heightAt(d,x,y);local p=T.polygon(ts,m);local xx,zz=(x+ox)*16,(y+oz)*16
 local function emit(a,b,c,e,uv,shade)local start=#out+1;G.quad(out,a,b,c,e,uv,shade);for i=start,#out do out[i][9]=-2 end end
 if p~=full then emit({xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,m,0,0,16,16,.5),1)end
 -- The dedicated native wall/inscription is vertical art, not a top face.
 local cap=(m==0x21e or m==0x270 or m==0x226)and 0x213 or m
 local slot=ts.midToSlot[cap];local tw,th=ts.image:getDimensions();local ax,ay=slot%ts.cols*16,math.floor(slot/ts.cols)*16
 local function vertex(q)return{xx+q[1],h,zz+q[2],(ax+math.max(.5,math.min(15.5,q[1])))/tw,(ay+math.max(.5,math.min(15.5,q[2])))/th,1,0,0,-2}end
 for i=2,#p-1 do for _,q in ipairs{p[1],p[i],p[i+1],p[1],p[i+1],p[i+1]}do out[#out+1]=vertex(q)end end
 local function occupied(wx,wz)
  local cx,cy=math.floor(wx/16),math.floor(wz/16)
  if cx<0 or cy<0 or cx>=L.width or cy>=L.height then return false end
  return cells[cy*L.width+cx+1]=='emUnderwaterWall'and contains(T.polygon(ts,L:midAt(cx,cy)),wx%16,wz%16)
 end
 for i,a in ipairs(p)do local b=p[i%#p+1];local dx,dz=b[1]-a[1],b[2]-a[2];local length=math.sqrt(dx*dx+dz*dz);local n=math.max(1,math.ceil(length));local t=0
  local function exposed(k)local f=(k+.5)/n;return not occupied(x*16+a[1]+dx*f+dz/length*.05,y*16+a[2]+dz*f-dx/length*.05)end
  while t<n do if exposed(t)then
   local lo=t;repeat t=t+1 until t==n or not exposed(t)
   local a0={xx+a[1]+dx*lo/n,zz+a[2]+dz*lo/n};local b0={xx+a[1]+dx*t/n,zz+a[2]+dz*t/n}
   -- Continue the native horizontal texture through short bevel segments;
   -- restarting every segment at column zero produced dark stitch lines.
   local u0,u1
   if math.abs(dx)>=math.abs(dz)then u0,u1=a0[1]-xx,b0[1]-xx else u0,u1=a0[2]-zz,b0[2]-zz end
   local uv=G.uv(ts,0x21e,0,0,16,16,.5);local origin=(ts.midToSlot[0x21e]%ts.cols)*16
   uv[1]=(origin+math.max(.5,math.min(15.5,u0)))/tw;uv[3]=(origin+math.max(.5,math.min(15.5,u1)))/tw
   if(m==0x270 or m==0x226)and a[2]==16 and b[2]==16 then uv=G.uv(ts,m,b0[1]-xx,0,a0[1]-xx,16,.5);uv[1],uv[3]=uv[3],uv[1]end
   emit({a0[1],h,a0[2]},{b0[1],h,b0[2]},{b0[1],0,b0[2]},{a0[1],0,a0[2]},uv,cfg().sideShade)
  else t=t+1 end end
 end
 return true
end
return T
