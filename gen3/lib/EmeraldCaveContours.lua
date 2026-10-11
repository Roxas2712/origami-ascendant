-- Convex outer corners and side boundaries of native brown, ice and pale rock.
-- The darkest authored outline separates rock from floor. Interior seeds keep
-- the bright plateau inside the contour, even though it shares floor colors.
local V=...
local E={cache=setmetatable({},{__mode='k'})}
local seeds={
 [0x208]={{16,16}},[0x20a]={{0,16}},
 [0x210]={{16,0},{16,16}},[0x212]={{0,0},{0,16}},
 [0x218]={{16,0}},[0x21a]={{0,0}},
}
local ice={[0x378]=0x208,[0x37a]=0x20a,[0x380]=0x210,[0x382]=0x212,[0x388]=0x218,[0x38a]=0x21a}
-- Origin's pale cliff faces use a separate native outline palette. The
-- exposed floor around these six silhouettes must not become a square cap.
local pale={
 [0x31c]={{16,0},{16,16}},[0x31d]={{0,0},{0,16}},
 [0x322]={{16,0},{16,16}},[0x320]={{0,0},{0,16}},
 [0x328]={{0,0},{16,0}},[0x32a]={{0,0},{16,0}},
}
local full={{0,0},{16,0},{16,16},{0,16}}
local function cross(a,b,c)return(b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])end
function E.applies(d)
 return d and d.pair=='general__cave'and tonumber(d.mapType)==4 and V.data('Emerald').map(d)
  and V.require('DioramaConfig').terrain.caveContours.enabled
end
function E.polygon(ts,mid,outline,padding)
 local seed=pale[mid]or seeds[ice[mid]or mid];if not seed then return full end
 local pad=padding or V.require('DioramaConfig').terrain.caveContours.edgePadding
 local cached=E.cache[ts];if not cached or cached.pad~=pad then cached={pad=pad};E.cache[ts]=cached end
 local key=tostring(mid)..':'..tostring(outline or '')
 if cached[key]then return cached[key]end
 local points,seen={},{}
 local function add(x,y)
  x,y=math.max(0,math.min(16,x)),math.max(0,math.min(16,y));local k=x..':'..y
  if not seen[k]then seen[k]=true;points[#points+1]={x,y}end
 end
 for _,p in ipairs(seed)do add(p[1],p[2])end
 local pixel=V.require('BuildingMesh').pixel;local color=outline or(pale[mid]and 0x5a423a or ice[mid]and 0x0073de or 0x522931)
 for y=0,15 do for x=0,15 do local r,g,b=pixel(ts,mid,x,y)
  if math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)==color then
   add(x-pad,y-pad);add(x+1+pad,y-pad);add(x+1+pad,y+1+pad);add(x-pad,y+1+pad)
  end
 end end
 table.sort(points,function(a,b)return a[1]==b[1]and a[2]<b[2]or a[1]<b[1]end)
 local lower,upper={},{}
 for _,p in ipairs(points)do while #lower>=2 and cross(lower[#lower-1],lower[#lower],p)<=0 do lower[#lower]=nil end;lower[#lower+1]=p end
 for i=#points,1,-1 do local p=points[i];while #upper>=2 and cross(upper[#upper-1],upper[#upper],p)<=0 do upper[#upper]=nil end;upper[#upper+1]=p end
 local hull={};for i=1,#lower-1 do hull[#hull+1]=lower[i]end;for i=1,#upper-1 do hull[#hull+1]=upper[i]end
 assert(#hull>=3,'empty native cave wall contour');cached[key]=hull;return hull
end
function E.contains(poly,x,y)
 for i,a in ipairs(poly)do if cross(a,poly[i%#poly+1],{x,y})<-.001 then return false end end
 return #poly>=3
end
-- Rectangular terrain neighbours used to hide their whole shared side even
-- when this contour leaves part of it exposed. Fill only that uncovered run.
function E.closeJoins(out,d,ts,x,y,ox,oz,cells)
 if not E.applies(d)or not V.require('DioramaConfig').terrain.caveContours.closeJoins then return end
 local L=d.midLayout;local cfg=V.require('DioramaConfig').terrain
 local G=V.require('WorldGeometry');local h=cfg.caveWallHeight
 local xx,zz=(x+ox)*16,(y+oz)*16
 local mid=V.require('EmeraldCaveObjects').donor(d,x,y)or L:midAt(x,y)
 local materials=V.require('EmeraldCaveMaterials')
 for _,edge in ipairs{{0,1,0,16,16,16},{-1,0,0,0,0,16},{1,0,16,16,16,0},{0,-1,16,0,0,0}}do
  local nx,ny=x+edge[1],y+edge[2]
  if nx>=0 and ny>=0 and nx<L.width and ny<L.height and cells[ny*L.width+nx+1]=='wall'then
   local poly=E.polygon(ts,L:midAt(nx,ny))
   if poly~=full then
   local donor=materials.side(d,mid)or materials.side(d,L:midAt(nx,ny))or 0x219
   local function exposed(i)
    local t=(i+.5)/16
    return not E.contains(poly,edge[3]+(edge[5]-edge[3])*t-edge[1]*16+edge[1]*.01,
     edge[4]+(edge[6]-edge[4])*t-edge[2]*16+edge[2]*.01)
   end
   local i=0
   while i<16 do
    if exposed(i)then
     local start=i;repeat i=i+1 until i==16 or not exposed(i)
     local ax=xx+edge[3]+(edge[5]-edge[3])*start/16
     local az=zz+edge[4]+(edge[6]-edge[4])*start/16
     local bx=xx+edge[3]+(edge[5]-edge[3])*i/16
     local bz=zz+edge[4]+(edge[6]-edge[4])*i/16
     local first=#out+1
     G.quad(out,{ax,h,az},{bx,h,bz},{bx,0,bz},{ax,0,az},G.uv(ts,donor,start,0,i,16,.5),cfg.sideShade)
     for j=first,#out do out[j][9]=-2 end
    else i=i+1 end
   end
   end
  end
 end
end
function E.inscription(d,x,y)
 if not E.applies(d)or not V.require('DioramaConfig').terrain.caveInscriptions.enabled then return end
 local L=d.midLayout;local mid=L:midAt(x,y)
 if mid~=0x235 and mid~=0x237 then return end
 -- Rear wall inscriptions continue their native rock top. Free-standing
 -- tablets continue the pale plateau above them, without duplicate glyphs.
 return{front=mid,cap=L:midAt(x,y-1)==0x229 and 0x229 or 0x201}
end
function E.stamp(out,d,ts,x,y,ox,oz,cells)
 if not E.applies(d)then return false end
 local L=d.midLayout;local M=V.require('EmeraldCaveMaterials')
 local mid=V.require('EmeraldCaveObjects').donor(d,x,y)or L:midAt(x,y)
 local family=M.family(mid)
 if family~=0x219 and family~=0x389 and mid~=0x237 and not pale[mid]then return false end
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').terrain
 local h=cfg.caveWallHeight;local xx,zz=(x+ox)*16,(y+oz)*16;local poly=E.polygon(ts,mid)
 local function emit(a,b,c,e,uv,shade)
  local first=#out+1;G.quad(out,a,b,c,e,uv,shade);for i=first,#out do out[i][9]=-2 end
 end
 if poly~=full then emit({xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,mid,0,0,16,16,.5),1)end
 local slot=ts.midToSlot[mid];local tw,th=ts.image:getDimensions();local ax,ay=slot%ts.cols*16,math.floor(slot/ts.cols)*16
 local function vertex(p)return{xx+p[1],h,zz+p[2],(ax+math.max(.5,math.min(15.5,p[1])))/tw,(ay+math.max(.5,math.min(15.5,p[2])))/th,cfg.topShade,0,0,-2}end
 local inscription=E.inscription(d,x,y)
 if poly==full then emit({xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,inscription and inscription.cap or mid,0,0,16,16,.5),cfg.topShade)
 else for i=2,#poly-1 do for _,p in ipairs({poly[1],poly[i],poly[i+1],poly[1],poly[i+1],poly[i+1]})do out[#out+1]=vertex(p)end end end
 local function occupied(wx,wz)
  local cx,cy=math.floor(wx/16),math.floor(wz/16)
  if cx<0 or cy<0 or cx>=L.width or cy>=L.height or cells[cy*L.width+cx+1]~='wall'then return false end
  return E.contains(E.polygon(ts,L:midAt(cx,cy)),wx%16,wz%16)
 end
 local donor=M.side(d,mid)
 for i,a in ipairs(poly)do local b=poly[i%#poly+1];local dx,dz=b[1]-a[1],b[2]-a[2]
  local length=math.sqrt(dx*dx+dz*dz);local steps=math.max(1,math.ceil(length));local t=0
  local function exposed(n)
   local f=(n+.5)/steps
   return not occupied(x*16+a[1]+dx*f+dz/length*.05,y*16+a[2]+dz*f-dx/length*.05)
  end
  while t<steps do
   if exposed(t)then
    local lo=t;repeat t=t+1 until t==steps or not exposed(t)
    local p={xx+a[1]+dx*lo/steps,zz+a[2]+dz*lo/steps};local q={xx+a[1]+dx*t/steps,zz+a[2]+dz*t/steps}
    local uv
    if inscription and a[2]==16 and b[2]==16 then
     -- Polygon edges run right-to-left here. Reverse U, not the lettering;
     -- clipped face runs must retain their original horizontal pixel range.
     uv=G.uv(ts,mid,q[1]-xx,0,p[1]-xx,16,.5);uv[1],uv[3]=uv[3],uv[1]
    else uv=G.uv(ts,donor or mid,0,donor and 0 or 8,math.max(1,math.min(16,length*(t-lo)/steps)),16,.5)end
    emit({p[1],h,p[2]},{q[1],h,q[2]},{q[1],0,q[2]},{p[1],0,p[2]},uv,cfg.sideShade)
   else t=t+1 end
  end
 end
 return true
end
return E
