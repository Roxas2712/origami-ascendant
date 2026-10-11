-- Mixed native cave edge tiles contain both rock and floor/water. Only the
-- measured rock contour is raised; the old full-cell caps made square teeth.
local V=...
local E={cache=setmetatable({},{__mode='k'})}
local mixed={}
for _,m in ipairs({0x208,0x20a,0x210,0x212,0x213,0x214,0x215,0x216,
 0x218,0x21a,0x21b,0x21d,0x220,0x222,0x223,0x225,0x228,0x22a,
 0x22b,0x230,0x231,0x232,0x234,0x235,0x237,0x238,0x239,0x23a,
 0x23b,0x240,0x241,0x242,0x243,0x288,0x289,0x28d,0x28e,0x290,0x295,0x297,0x29d,0x29e})do mixed[m]=true end
local rock={['132,115,140']=true,['49,41,82']=true,['107,90,115']=true,['74,66,107']=true}
local function cross(a,b,c)return(b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])end
function E.polygon(ts,mid)
 local cached=E.cache[ts]or{};E.cache[ts]=cached;if cached[mid]then return cached[mid]end
 if not mixed[mid]then return{{0,0},{16,0},{16,16},{0,16}}end
 local pixel=V.require('BuildingMesh').pixel;local points,seen={},{}
 for y=0,15 do for x=0,15 do local r,g,b=pixel(ts,mid,x,y)
  if rock[string.format('%d,%d,%d',math.floor(r*255+.5),math.floor(g*255+.5),math.floor(b*255+.5))]then
   for _,q in ipairs({{x-1,y-1},{x+2,y-1},{x+2,y+2},{x-1,y+2}})do
    local px,py=math.max(0,math.min(16,q[1])),math.max(0,math.min(16,q[2]));local key=py*17+px
    if not seen[key]then seen[key]=true;points[#points+1]={px,py}end
   end
  end
 end end
 table.sort(points,function(a,b)return a[1]==b[1]and a[2]<b[2]or a[1]<b[1]end)
 local lower,upper={},{}
 for _,p in ipairs(points)do while #lower>=2 and cross(lower[#lower-1],lower[#lower],p)<=0 do lower[#lower]=nil end;lower[#lower+1]=p end
 for i=#points,1,-1 do local p=points[i];while #upper>=2 and cross(upper[#upper-1],upper[#upper],p)<=0 do upper[#upper]=nil end;upper[#upper+1]=p end
 local hull={};for i=1,#lower-1 do hull[#hull+1]=lower[i]end;for i=1,#upper-1 do hull[#hull+1]=upper[i]end
 cached[mid]=hull;return hull
end
function E.contains(poly,x,y)
 if #poly<3 then return false end
 for i,a in ipairs(poly)do if cross(a,poly[i%#poly+1],{x,y})<-.001 then return false end end
 return true
end
function E.applies(d)
 return V.require('DioramaConfig').meteorEdges.enabled and d.pair=='general__meteor_falls'
  and tostring(d.id or''):match('^EM_METEOR_FALLS_')
end
function E.isRock(mid)return mid==0x20e or mid==0x20f or mid==0x217 or mid==0x21f or mid==0x28c end
local rockMasks=setmetatable({},{__mode='k'})
function E.rocks(out,d,ts,x,y,ox,oz,contacts)
 if not E.applies(d)then return false end
 local mid=d.midLayout:midAt(x,y);if not E.isRock(mid)then return false end
 local cached=rockMasks[ts]or{};rockMasks[ts]=cached;local outside=cached[mid]
 if not outside then
  local pixel=V.require('BuildingMesh').pixel;local palette={}
  local function key(r,g,b)return string.format('%.4f,%.4f,%.4f',r,g,b)end
  for sy=0,15 do for sx=0,15 do palette[key(pixel(ts,0x229,sx,sy))]=true end end
  local queue={};outside={}
  local function add(sx,sy)
   if sx<0 or sx>15 or sy<0 or sy>15 or outside[sy*16+sx]then return end
   if palette[key(pixel(ts,mid,sx,sy))]then outside[sy*16+sx]=true;queue[#queue+1]={sx,sy}end
  end
  for i=0,15 do add(i,0);add(i,15);add(0,i);add(15,i)end
  local i=1;while i<=#queue do local p=queue[i];i=i+1;add(p[1]-1,p[2]);add(p[1]+1,p[2]);add(p[1],p[2]-1);add(p[1],p[2]+1)end
  cached[mid]=outside
 end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16;local cfg=V.require('DioramaConfig').meteorEdges
 G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,0x229),1)
 local sprite=V.require('PaperSprite').build(ts,16,16,function(sx,sy)return mid,sx,sy end,
  function(sx,sy)return not outside[sy*16+sx]end,0,16,cfg.rockHeightScale,function()return 5 end,nil,.5)
 for _,v in ipairs(sprite)do v[3]=v[3]+16;v[8]=v[8]+16;out[#out+1]=G.place(v,xx,zz)end
 contacts[#contacts+1]={xx+8,zz+15,6,cfg.rockContactDepth,cfg.rockContactStrength}
 return true
end
function E.stamp(out,d,ts,x,y,ox,oz,cells)
 if not E.applies(d)then return false end
 local L=d.midLayout;local mid=V.require('EmeraldMeteorColumns').donor(d,x,y)or L:midAt(x,y)
 local G=V.require('WorldGeometry');local h=V.require('DioramaConfig').terrain.caveWallHeight
 local cfg=V.require('DioramaConfig').meteorEdges;local xx,zz=(x+ox)*16,(y+oz)*16
 local poly=E.polygon(ts,mid)
 local function emit(a,b,c,e,uv,shade)
  local start=#out+1;G.quad(out,a,b,c,e,uv,shade);for i=start,#out do out[i][9]=-2 end
 end
 -- Native floor/water remains below the contour; no missing corner quads.
 emit({xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,mid),1)
 -- A small convex native contour gives clean diagonal sides, rather than
 -- one-pixel vertical teeth. Texture coordinates remain in the source cell.
 local slot=ts.midToSlot[mid];local tw,th=ts.image:getDimensions();local ax,ay=slot%ts.cols*16,math.floor(slot/ts.cols)*16
 local function vertex(p)return{xx+p[1],h,zz+p[2],(ax+math.max(.02,math.min(15.98,p[1])))/tw,(ay+math.max(.02,math.min(15.98,p[2])))/th,1,0,0,-2}end
 -- WorldGeometry heightfield consumes six-vertex faces; retain that format
 -- with a degenerate second triangle for each fan segment.
 for i=2,#poly-1 do for _,p in ipairs({poly[1],poly[i],poly[i+1],poly[1],poly[i+1],poly[i+1]})do out[#out+1]=vertex(p)end end
 local function occupied(wx,wz)
  local cx,cy=math.floor(wx/16),math.floor(wz/16)
  if cx<0 or cy<0 or cx>=L.width or cy>=L.height or cells[cy*L.width+cx+1]~='wall'then return false end
  local m=V.require('EmeraldMeteorColumns').donor(d,cx,cy)or L:midAt(cx,cy)
  return E.contains(E.polygon(ts,m),wx%16,wz%16)
 end
 for i,a in ipairs(poly)do local b=poly[i%#poly+1];local dx,dz=b[1]-a[1],b[2]-a[2]
  local length=math.sqrt(dx*dx+dz*dz);local steps=math.max(1,math.ceil(length));local t=0
  local function exposed(n)
   local f=(n+.5)/steps;local mx,mz=a[1]+dx*f,a[2]+dz*f
   local nx,nz=dz/length,-dx/length
   return not occupied(x*16+mx+nx*.05,y*16+mz+nz*.05)
  end
  while t<steps do
   if exposed(t)then
    local lo=t;repeat t=t+1 until t==steps or not exposed(t)
    local p={xx+a[1]+dx*lo/steps,zz+a[2]+dz*lo/steps};local q={xx+a[1]+dx*t/steps,zz+a[2]+dz*t/steps}
    emit({p[1],h,p[2]},{q[1],h,q[2]},{q[1],0,q[2]},{p[1],0,p[2]},G.uv(ts,0x244,0,0,math.max(1,math.min(16,length*(t-lo)/steps)),16,.5),cfg.sideShade)
   else t=t+1 end
  end
 end
 return true
end
return E
