-- Shared brown/ice cave objects. Open descent holes stay on the floor;
-- ascent ladders are lifted only where a real native warp validates the art.
local V=...
local O={}
local brown={0xffe69c,0xcead7b,0x522931,0x734a3a}
local ice={0xffffff,0xb5deff,0x0073de,0x3a94f7}
function O.applies(d)
 return d and d.pair=='general__cave' and tonumber(d.mapType)==4 and V.data('Emerald').map(d)
  and V.require('DioramaConfig').caveObjects.enabled
  and V.require('DioramaConfig').billboards.enabled and V.require('DioramaConfig').terrain.enabled
  and V.require('Camera').projection()=='perspective'
end
-- 2d5 is the same native contour as 202 in the Regi rock palette.
local function rock(m)return m==0x202 or m==0x203 or m==0x2d5 or m==0x37d or m==0x37e end
function O.isRock(d,m)return O.applies(d)and rock(m)end
local function ascent(L,w)
 local m,up=L:midAt(w.x,w.y),L:midAt(w.x,w.y-1)
 if up==0x20f and(m==0x216 or m==0x217)then return{upper=up,lower=m,wall=0x219,floor=m==0x216 and 0x201 or 0x211,h=2,colors=brown,bounds={3,12,2,29}}
 elseif up==0x377 and m==0x37f then return{upper=up,lower=m,wall=0x389,floor=0x385,h=2,colors=ice,bounds={3,12,2,29}}
 elseif m==0x23d or m==0x23e then return{lower=m,floor=m==0x23d and 0x201 or 0x211,h=1,colors=brown,bounds={2,13,0,15}}end
end
function O.donor(d,x,y)
 if not O.applies(d)then return end
 local L=d.midLayout;local mid=L:midAt(x,y);if mid~=0x20f and mid~=0x377 then return end
 for _,w in ipairs(d.warps or{})do if w.x==x and w.y==y+1 then local a=ascent(L,w);return a and a.wall end end
end
function O.plan(d)
 local p={objects={},mask={}};if not O.applies(d)then return p end
 local L=d.midLayout;local height=V.require('DioramaConfig').terrain.caveWallHeight
 for y=0,L.height-1 do for x=0,L.width-1 do local mid=L:midAt(x,y)
  if rock(mid)then
   local frozen=mid==0x37d or mid==0x37e
   local ground=false;local floors={};local best,floor=0,frozen and 0x385 or 0x201
   for _,v in ipairs({{-1,0},{1,0},{0,-1},{0,1}})do local c=L:cellAt(x+v[1],y+v[2])
    if c then
     if c.coll~=7 and c.coll~=255 then ground=true end
     if not frozen and(c.mid==0x201 or c.mid==0x211)then floors[c.mid]=(floors[c.mid]or 0)+1;if floors[c.mid]>best then best=floors[c.mid];floor=c.mid end end
    end
   end
   local o={kind='rock',x=x,y=y,mid=mid,floor=floor,wall=frozen and 0x389 or 0x219,base=ground and 0 or height}
   p.objects[#p.objects+1]=o;p.mask[y*L.width+x+1]=o
  end
 end end
 for _,w in ipairs(d.warps or{})do local o=ascent(L,w)
  if o then o.kind='ladder';o.x=w.x;o.y=w.y-o.h+1;o.base=0;p.objects[#p.objects+1]=o
   for y=o.y,w.y do p.mask[y*L.width+w.x+1]=o end
  end
 end
 return p
end
function O.floor(out,d,ts,x,y,ox,oz,p)
 local o=p.mask[y*d.midLayout.width+x+1]
 if not o or o.kind=='ladder'and o.h==2 and y==o.y then return false end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16;local h=o.base
 G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,o.floor),1)
 if h>0 then
  local first=#out-5;local L=d.midLayout;local T=V.require('Terrain')
  local function neighbour(dx,dy)
   local nx,ny=x+dx,y+dy
   if nx<0 or ny<0 or nx>=L.width or ny>=L.height then return 0 end
   local other=p.mask[ny*L.width+nx+1]
   if other and other.kind=='rock'then return other.base end
   local kind=T.kind(d,L:cellAt(nx,ny));return kind and kind~='caveLedge'and T.height(kind)or 0
  end
  local function side(a,b,low)
   if low<h then G.quad(out,{a[1],h,a[2]},{b[1],h,b[2]},{b[1],low,b[2]},{a[1],low,a[2]},
    G.uv(ts,o.wall,0,0,16,16,.5),V.require('DioramaConfig').terrain.sideShade)end
  end
  side({xx,zz+16},{xx+16,zz+16},neighbour(0,1))
  side({xx+16,zz},{xx,zz},neighbour(0,-1))
  side({xx,zz},{xx,zz+16},neighbour(-1,0))
  side({xx+16,zz+16},{xx+16,zz},neighbour(1,0))
  for i=first,#out do out[i][9]=-2 end
 end
 return true
end
function O.cutout(ts,o)
 local A=V.require('CaveObjectArt')
 local source=function(x,y)return o.h==2 and y<16 and o.upper or o.lower,x,y%16 end
 local inside=function(x,y)return A.ladderPixel(ts,x,y,source,o.colors,o.bounds)end
 local lo,hi=math.huge,-1
 for y=0,o.h*16-1 do for x=0,15 do if inside(x,y)then lo=math.min(lo,y);hi=math.max(hi,y+1)end end end
 return source,inside,lo,hi
end
function O.build(out,d,ts,ox,oz,contacts,p)
 local C=V.require('DioramaConfig').caveObjects;local G=V.require('WorldGeometry');local A=V.require('CaveObjectArt')
 for _,o in ipairs(p.objects)do local xx,zz=(o.x+ox)*16,(o.y+oz)*16;local vertices
  if o.kind=='rock'then
   vertices=V.require('PaperSprite').build(ts,16,16,function(x,y)return o.mid,x,y end,
    function(x,y)return A.rockPixel(o.mid,x,y)end,0,16,C.rockHeightScale,function()return 1 end,nil,.5)
   zz=zz+16
   for _,v in ipairs(vertices)do v[2]=v[2]+o.base;if o.base>0 then v[9]=-2 end end
   if o.base==0 then contacts[#contacts+1]={xx+8,zz,C.rockContactWidth,C.contactDepth,C.contactStrength}end
  else
   local h=V.require('DioramaConfig').terrain.caveWallHeight
   local source,inside,lo,hi=O.cutout(ts,o);assert(hi>lo,'empty native ladder cutout')
   local depth=o.h==2 and 16 or C.shortLadderDepth
   vertices=V.require('PaperSprite').build(ts,16,o.h*16,source,inside,0,hi,1,function()return 5 end,
    function(x,y)local t=(y-lo)/(hi-lo);return{x,h*(1-t),-depth+C.ladderFrontOffset+(depth-C.ladderFrontOffset)*t}end,.5)
   for _,v in ipairs(vertices)do v[9]=-2 end
   zz=zz+o.h*16;contacts[#contacts+1]={xx+8,zz,4,C.contactDepth,C.contactStrength}
  end
  for _,v in ipairs(vertices)do out[#out+1]=G.place(v,xx,zz)end
 end
end
return O
