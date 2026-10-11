-- Native Tanoby masonry: rear wall/pilasters and a closed low stone labyrinth.
-- The layout, passage widths, encounter cells and exit events remain native.
local V=...;local R={masks=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.tanoby end
local maze={}
for _,range in ipairs{{0x2a0,0x2a3},{0x2a5,0x2ab},{0x2ad,0x2ae},{0x2b0,0x2b3},{0x2b8,0x2ba},{0x2c2,0x2c3},{0x2c8,0x2ca},{0x2d0,0x2db}}do for m=range[1],range[2]do maze[m]=true end end
local fronts={[0x2ad]=true,[0x2ae]=true,[0x2b3]=true,[0x2b8]=true,[0x2b9]=true,[0x2ba]=true,[0x2d2]=true,[0x2d3]=true,[0x2d4]=true,[0x2d5]=true,[0x2d6]=true}
local function pillar(m)return m and(m>=0x289 and m<=0x28d or m==0x2ce or m==0x2cf)end
function R.profile(d)
 local L=d and d.midLayout
 return cfg().enabled and d and (d.id or''):match('^FR_SEVEN_ISLAND_TANOBY_RUINS_%u+_CHAMBER$')
  and tonumber(d.mapType)==4 and (d.renderPair or d.pair)=='building__rom_082d5034'and L and L.width==24 and L.height==18 and true or nil
end
function R.plan(d)
 if not R.profile(d)then return end
 local objects={{kind='tanobyRoom'}};local mask={}
 for i=1,d.midLayout.width*d.midLayout.height do mask[i]={mid=8,void=true,separateSurface=true}end
 return{objects=objects,mask=mask,owners={}}
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.pixelMask(ts,mid,x,y)
 if not maze[mid]then return false end
 local cache=R.masks[ts]
 if not cache then
  cache={floor={}};R.masks[ts]=cache
  for _,m in ipairs{0x288,0x290}do for sy=0,15 do for sx=0,15 do cache.floor[rgb(V.require('BuildingMesh').pixel(ts,m,sx,sy))]=true end end end
 end
 return not cache.floor[rgb(V.require('BuildingMesh').pixel(ts,mid,x,y))]
end
function R.build(out,d,ts,ox,oz,contacts)
 if not R.profile(d)then return end
 local L=d.midLayout;local C=cfg();local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local P=V.require('PaperSprite')
 local W,H=L.width*16,L.height*16;local xx,zz=ox*16,oz*16
 local function source(x,y)return L:midAt(math.floor(x/16),math.floor(y/16)),x%16,y%16 end
 local function occupied(x,y)
  if x<0 or y<48 or x>=W or y>=H then return false end
  local m,u,v=source(x,y);return R.pixelMask(ts,m,u,v)
 end
 local function draw(w,h,src,inside,transform,shade)
  local a=P.build(ts,w,h,src,inside,0,h,1,shade and function()return shade end,transform,.5)
  for _,v in ipairs(a)do out[#out+1]=v end
 end
 -- Native floor perimeter/exit stays intact. Baked object/shadow rectangles
 -- are replaced with the adjacent native floor, never a new texture.
 for y=2,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if m~=8 then
   if maze[m]or m>=0x2bb and m<=0x2bf then m=0x288 end
   if y==2 and pillar(L:midAt(x,1))then m=0x290 end
   G.quad(out,{xx+x*16,0,zz+y*16},{xx+x*16+16,0,zz+y*16},{xx+x*16+16,0,zz+y*16+16},{xx+x*16,0,zz+y*16+16},G.uv(ts,m),1)
  end
 end end
 -- Rear brick band stands behind, rather than sharing the pilaster plane.
 local wallMid=L:midAt(2,0);local first=#out+1
 local function wallSource(s,t)
  if pillar(L:midAt(math.floor(s/16),1))then return t<16 and wallMid or 0x287,s%16,t%16 end
  return source(s,t)
 end
 local function wallInside(s,t)
  if s<16 or s>=352 then return false end
  local m,u,v=wallSource(s,t);local r,g,b=B.pixel(ts,m,u,v);local c=rgb(r,g,b)
  return c~=0xf7f7de and c~=0xe6dea5
 end
 -- Close the exact source contour. A single rectangular cap would bridge
 -- the native stepped cornice and leave open ends at the pilasters.
 local function solid(w,h,src,inside,origin,front,depth,height)
  local function has(s,t)return s>=0 and t>=0 and s<w and t<h and inside(s,t)end
  local function point(s,t,z)return{xx+origin+s,height*(h-t)/h,zz+z}end
  draw(w,h,src,inside,function(s,t)return point(s,t,front)end)
  draw(w,h,src,inside,function(s,t)return point(s,t,front-depth)end,C.sideShade)
  for t=0,h-1 do for s=0,w-1 do if has(s,t)then
   local mid,u,v=src(s,t);local uv=G.uv(ts,mid,u,v,u+1,v+1,.5)
   if not has(s,t-1)then G.quad(out,point(s,t,front-depth),point(s+1,t,front-depth),point(s+1,t,front),point(s,t,front),uv,1)end
   if not has(s,t+1)then G.quad(out,point(s,t+1,front),point(s+1,t+1,front),point(s+1,t+1,front-depth),point(s,t+1,front-depth),uv,C.sideShade)end
   if not has(s-1,t)then G.quad(out,point(s,t,front),point(s,t+1,front),point(s,t+1,front-depth),point(s,t,front-depth),uv,C.sideShade)end
   if not has(s+1,t)then G.quad(out,point(s+1,t,front-depth),point(s+1,t+1,front-depth),point(s+1,t+1,front),point(s+1,t,front),uv,C.sideShade)end
  end end end
 end
 solid(W,32,wallSource,wallInside,0,32,C.wallDepth,C.wallHeight)
 V.require('RoomLightRig').capture(L,{kind='wall'},out,first,#out)
 for x=0,L.width-1 do if pillar(L:midAt(x,1))then
  first=#out+1
  local function src(s,t)return source(x*16+s,t)end
  solid(16,40,src,function(s,t)
   local m,u,v=src(s,t);local color=rgb(B.pixel(ts,m,u,v))
   return color~=0xf7f7de and color~=0xe6dea5
  end,x*16,40,8,C.pillarHeight)
  V.require('RoomLightRig').capture(L,{kind='wall'},out,first,#out)
 end end
 -- Occupancy is measured from native object pixels, not collision rectangles.
 -- Front-face glyphs are not duplicated on caps; cracks on real caps remain.
 for cy=3,L.height-1 do for cx=0,L.width-1 do local m=L:midAt(cx,cy)
  if maze[m]then
   first=#out+1
   -- Row runs preserve native UVs while avoiding one quad per cap pixel.
   for sy=0,15 do local sx=0
    while sx<16 do
     if occupied(cx*16+sx,cy*16+sy)then
      local begin=sx;repeat sx=sx+1 until sx==16 or not occupied(cx*16+sx,cy*16+sy)
      local uv=fronts[m]and G.uv(ts,0x2a8,7,7,8,8,.5)or G.uv(ts,m,begin,sy,sx,sy+1,.5)
      local x,z=xx+cx*16,zz+cy*16+sy
      G.quad(out,{x+begin,C.mazeHeight,z},{x+sx,C.mazeHeight,z},{x+sx,C.mazeHeight,z+1},{x+begin,C.mazeHeight,z+1},uv,1)
     else sx=sx+1 end
    end
   end
   for sy=0,15 do for sx=0,15 do local x,z=cx*16+sx,cy*16+sy
    if occupied(x,z)then
     local plain=G.uv(ts,0x2b9,0,0,1,1,.5)
     if not occupied(x,z+1)then
      local front=fronts[m]and G.uv(ts,m,sx,0,sx+1,16,.5)or plain
      G.quad(out,{xx+x,C.mazeHeight,zz+z+1},{xx+x+1,C.mazeHeight,zz+z+1},{xx+x+1,0,zz+z+1},{xx+x,0,zz+z+1},front,C.sideShade)
     end
     if not occupied(x,z-1)then G.quad(out,{xx+x+1,C.mazeHeight,zz+z},{xx+x,C.mazeHeight,zz+z},{xx+x,0,zz+z},{xx+x+1,0,zz+z},plain,C.sideShade)end
     for _,side in ipairs{{-1,0},{1,1}}do if not occupied(x+side[1],z)then
      local at=xx+x+side[2];local tex=fronts[m]and G.uv(ts,m,sy,0,sy+1,16,.5)or plain
      G.quad(out,{at,C.mazeHeight,zz+z},{at,C.mazeHeight,zz+z+1},{at,0,zz+z+1},{at,0,zz+z},tex,C.sideShade)
     end end
    end
   end end
   V.require('RoomLightRig').capture(L,{kind='wall'},out,first,#out)
   for i=first,#out do out[i][9]=-2 end -- existing opaque, closed player section
  end
 end end
end
-- The camera section also opens its local-light blockers. Keeping the old
-- full-height box would paint a dark rectangle on the newly exposed cap.
function R.sectionShadows(d,boxes,px,pz)
 if not(px and pz)then return end
 local cut=V.require('CaveCutaway').bounds(d,px,pz);if not cut then return end
 local changed={}
 local function add(b,x0,z0,x1,z1,h)
  if x1>x0 and z1>z0 and h>b.lo[2]then changed[#changed+1]={lo={x0,b.lo[2],z0},hi={x1,h,z1},wall=b.wall}end
 end
 for _,b in ipairs(boxes)do
  local a,c=b.lo,b.hi;local x0,z0=math.max(a[1],cut[1]),math.max(a[3],cut[2]);local x1,z1=math.min(c[1],cut[3]),math.min(c[3],cut[4])
  if c[2]<=cut[5]or x0>=x1 or z0>=z1 or a[3]<48 then changed[#changed+1]=b
  else
   add(b,a[1],a[3],x0,c[3],c[2]);add(b,x1,a[3],c[1],c[3],c[2])
   add(b,x0,a[3],x1,z0,c[2]);add(b,x0,z1,x1,c[3],c[2]);add(b,x0,z0,x1,z1,cut[5])
  end
 end
 for i=#boxes,1,-1 do boxes[i]=nil end;for _,b in ipairs(changed)do boxes[#boxes+1]=b end
end
function R.lighting(d)
 if not R.profile(d)then return end
 local C=cfg();local sources={}
 for _,p in ipairs(C.sources)do sources[#sources+1]={at={p[1]*16,C.lightHeight,p[2]*16},radius=C.lightRadius,power=C.lightPower,color=C.lightColor,spread=C.lightSpread}end
 return{fixed=true,localSelection=true,movingShadows=R.sectionShadows,ambient=C.ambient,sources=sources}
end
return R
