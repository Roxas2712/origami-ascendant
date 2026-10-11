-- Folded native furniture surfaces. No generated voxel model or replacement art.
local V=...
local I={}
function I.profile(def)
 local c=V.require('DioramaConfig').interiors
 return c and c.enabled and V.require('InteriorSchema').describe(def).profile or nil
end
local function prism(out,ts,mid,x,z,w,d,y,h,topUV,frontUV,sideUV)
 local G=V.require("WorldGeometry");local q=G.quad
 local uv=sideUV or G.uv(ts,mid,1,1,2,2)
 q(out,{x,y+h,z},{x+w,y+h,z},{x+w,y+h,z+d},{x,y+h,z+d},topUV or uv,1)
 q(out,{x,y+h,z+d},{x+w,y+h,z+d},{x+w,y,z+d},{x,y,z+d},frontUV or uv,1)
 q(out,{x+w,y+h,z},{x,y+h,z},{x,y,z},{x+w,y,z},uv,.7)
 q(out,{x,y+h,z},{x,y+h,z+d},{x,y,z+d},{x,y,z},uv,.78)
 q(out,{x+w,y+h,z+d},{x+w,y+h,z},{x+w,y,z},{x+w,y,z+d},uv,.9)
end

local function patch(out,L,ts,o,sx,sy,w,h,a,b,c,d,shade)
 local G=V.require("WorldGeometry")
 local function point(u,v)
  local p={}
  for k=1,3 do p[k]=(1-v)*((1-u)*a[k]+u*b[k])+v*((1-u)*d[k]+u*c[k]) end
  return p
 end
 local yy=sy
 while yy<sy+h do
  local yh=math.min(sy+h,(math.floor(yy/16)+1)*16)-yy
  local xx=sx
  while xx<sx+w do
   local xw=math.min(sx+w,(math.floor(xx/16)+1)*16)-xx
   local mid=L:midAt(o.x+math.floor(xx/16),o.y+math.floor(yy/16))
   local u0,v0,u1,v1=(xx-sx)/w,(yy-sy)/h,(xx+xw-sx)/w,(yy+yh-sy)/h
   G.quad(out,point(u0,v0),point(u1,v0),point(u1,v1),point(u0,v1),
    G.uv(ts,mid,xx%16,yy%16,xx%16+xw,yy%16+yh,.5),shade or 1)
   xx=xx+xw
  end
  yy=yy+yh
 end
end
-- Source-space cutout: only flood background from the perimeter. Shared
-- furniture colours inside an enclosed object remain opaque.
local function nativeMask(L,ts,o,w,h,background,pixels)
 local BM=V.require('BuildingMesh')
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local bg={}
 for _,mid in ipairs(background or {})do for y=0,15 do for x=0,15 do bg[rgb(BM.pixel(ts,mid,x,y))]=true end end end
 for _,p in ipairs(pixels or {})do bg[rgb(BM.pixel(ts,p[1],p[2],p[3]))]=true end
 local function source(x,y)
  local sx,sy=x+(o.sourceX or 0),y+(o.sourceY or 0)
  return L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16)),sx%16,sy%16
 end
 local clear,empty,queue={},{},{}
 for y=0,h-1 do for x=0,w-1 do local m,u,v=source(x,y);local r,g,b,a=BM.pixel(ts,m,u,v);clear[y*w+x]=a<.5 or bg[rgb(r,g,b)]end end
 local function seed(x,y)local k=y*w+x;if clear[k] and not empty[k]then empty[k]=true;queue[#queue+1]=k end end
 for x=0,w-1 do seed(x,0);seed(x,h-1)end
 for y=0,h-1 do seed(0,y);seed(w-1,y)end
 local n=1;while queue[n]do local k=queue[n];n=n+1;local x,y=k%w,math.floor(k/w)
  if x>0 then seed(x-1,y)end;if x<w-1 then seed(x+1,y)end
  if y>0 then seed(x,y-1)end;if y<h-1 then seed(x,y+1)end
 end
 return source,function(x,y)return x>=0 and x<w and y>=0 and y<h and not empty[y*w+x]end
end
local function contouredPanel(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local w,h=o.w*16,o.last
 local source,inside=nativeMask(L,ts,o,w,h,o.background,o.backgroundPixels)
 local front=z+(o.front or h);local depth=V.require('DioramaConfig').interiors.centerFurniture.machineDepth
 local base=o.base or 0
 local verts=V.require('PaperSprite').build(ts,w,h,source,inside,0,h,1,nil,
  function(sx,sy)return {x+sx,base+h-sy,front}end,.5)
 for _,v in ipairs(verts)do out[#out+1]=v end
 -- Thin native-coloured shell follows the actual silhouette, not its box.
 for sy=0,h-1 do for sx=0,w-1 do if inside(sx,sy)then
  local m,u,v=source(sx,sy);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
  local xx,yy=x+sx,base+h-sy
  if not inside(sx,sy-1)then G.quad(out,{xx,yy,front-depth},{xx+1,yy,front-depth},{xx+1,yy,front},{xx,yy,front},uv,1)end
  if not inside(sx-1,sy)then G.quad(out,{xx,yy,front-depth},{xx,yy,front},{xx,yy-1,front},{xx,yy-1,front-depth},uv,.9)end
  if not inside(sx+1,sy)then G.quad(out,{xx+1,yy,front},{xx+1,yy,front-depth},{xx+1,yy-1,front-depth},{xx+1,yy-1,front},uv,.9)end
 end end end
end
local function panel(out,L,ts,o,x,z)
 if o.contour then return contouredPanel(out,L,ts,o,x,z)end
 local G=V.require("WorldGeometry")
 local height=o.height or o.last-o.split
 local front=z+(o.front or o.last-4);local back=front-o.depth
 local side=G.uv(ts,o.sideMid,o.sideX,o.sideY,o.sideX+1,o.sideY+1)
 local top=o.base+height
 prism(out,ts,o.sideMid,x,back,o.w*16,o.depth,o.base,height,side,side,side)
 patch(out,L,ts,o,0,o.cap,o.w*16,o.split-o.cap,{x,top+.02,back},{x+o.w*16,top+.02,back},
  {x+o.w*16,top+.02,front},{x,top+.02,front})
 patch(out,L,ts,o,0,o.split,o.w*16,o.last-o.split,{x,top,front+.02},{x+o.w*16,top,front+.02},
  {x+o.w*16,o.base,front+.02},{x,o.base,front+.02})
end
local function desk(out,L,ts,o,x,z)
 local G=V.require("WorldGeometry")
 local side=G.uv(ts,o.home and 0x30 or 0x285,o.home and 5 or 1,o.home and 10 or 2,o.home and 6 or 2,o.home and 11 or 3)
 for _,dx in ipairs({1,o.w*16-3})do for _,dz in ipairs({17,28})do
  prism(out,ts,0,x+dx,z+dz,2,2,0,12,side,side,side)
 end end
 prism(out,ts,0,x,z+16,o.w*16,16,12,2,side,side,side)
 for dx=0,o.w-1 do
  local mid=o.home and 0x86 or dx==0 and 0x85 or 0x86
  G.quad(out,{x+dx*16,14.02,z+16},{x+(dx+1)*16,14.02,z+16},
   {x+(dx+1)*16,14.02,z+32},{x+dx*16,14.02,z+32},G.uv(ts,mid,0,8,16,16),1)
 end
 if o.home then
  -- Blue computer stool, cut from the original lower desk tile.
  local m=L:midAt(o.x,o.y+1);local edge=G.uv(ts,m,4,13,5,14,.5)
  prism(out,ts,m,x+3,z+34,10,8,4,2,G.uv(ts,m,3,5,13,13,.5),edge,edge)
  for _,dx in ipairs({4,11})do prism(out,ts,m,x+dx,z+40,1,2,0,4,G.uv(ts,m,4,14,5,15,.5),edge,edge)end
 end

end
local function counter(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local BM=V.require('BuildingMesh')
 local red=G.uv(ts,L:midAt(o.x,o.y),7,2,8,3,.5)
 local edge=G.uv(ts,0x2b9,7,8,8,9,.5)
 prism(out,ts,0,x,z+16,o.w*16,16,0,11,red,edge,edge)
 patch(out,L,ts,o,0,21,o.w*16,2,{x,11.02,z+16},{x+o.w*16,11.02,z+16},
  {x+o.w*16,11.02,z+32},{x,11.02,z+32})
 patch(out,L,ts,o,0,23,o.w*16,9,{x,11,z+32.02},{x+o.w*16,11,z+32.02},
  {x+o.w*16,2,z+32.02},{x,2,z+32.02})
 for _,dx in ipairs({0,o.w-1})do
  prism(out,ts,0,x+dx*16,z-8,16,24,0,11,red,edge,edge)
  local function source(sx,sy)return L:midAt(o.x+dx,o.y+math.floor(sy/16)),sx,sy%16 end
  local verts=V.require('PaperSprite').build(ts,16,21,source,function(sx,sy)
   if sx<3 or sx>13 or sy<6 then return false end
   local m,u,v=source(sx,sy);local r,g,b=BM.pixel(ts,m,u,v)
   return not(r>.95 and g>.49 and g<.55 and b<.49)
  end,0,21,1,nil,function(sx,sy)return {x+dx*16+sx,11+(21-sy)*1.18,z+17}end,.5)
  for _,v in ipairs(verts)do out[#out+1]=v end
 end
 -- The native white service pad stays flat on the counter.
 patch(out,L,ts,o,48,15,16,6,{x+48,11.03,z+19},{x+64,11.03,z+19},
  {x+64,11.03,z+27},{x+48,11.03,z+27})
end
local function stool(out,L,ts,o,x,z)
 local G=V.require("WorldGeometry");local m=L:midAt(o.x,o.y)
 local frame=G.uv(ts,m,1,11,2,12)
 for _,dx in ipairs({2,12})do for _,dz in ipairs({2,12})do prism(out,ts,m,x+dx,z+dz,2,2,0,6,frame,frame,frame)end end
 prism(out,ts,m,x+2,z+2,12,12,6,2,G.uv(ts,m,2,1,14,12),frame,frame)
end

local function bed(out,L,ts,o,x,z)
 local G=V.require("WorldGeometry")
 local wood=G.uv(ts,0x294,8,14,9,15)
 local cloth=G.uv(ts,0x28c,8,10,9,11)
 -- The bed is one horizontal mattress with an upright head and foot board.
 -- Its native 3x3 drawing contains floor margins, which remain floor.
 prism(out,ts,0x294,x+13,z+18,22,29,4,4,cloth,cloth,wood)
 patch(out,L,ts,o,13,22,22,20,{x+13,8.02,z+23},{x+35,8.02,z+23},{x+35,8.02,z+47},{x+13,8.02,z+47})
 prism(out,ts,0x294,x+14,z+19,20,7,8,2,cloth,cloth,cloth)
 patch(out,L,ts,o,14,18,20,6,{x+14,10.02,z+19},{x+34,10.02,z+19},{x+34,10.02,z+26},{x+14,10.02,z+26})
 prism(out,ts,0x294,x+12,z+16,24,2,0,16,wood,wood,wood)
 patch(out,L,ts,o,12,13,24,8,{x+12,16,z+18.02},{x+36,16,z+18.02},{x+36,8,z+18.02},{x+12,8,z+18.02})
 prism(out,ts,0x294,x+13,z+45,22,2,0,8,wood,wood,wood)
 patch(out,L,ts,o,13,40,22,7,{x+13,8,z+47.02},{x+35,8,z+47.02},{x+35,1,z+47.02},{x+13,1,z+47.02})
end
local function console(out,L,ts,o,x,z)
 local G=V.require("WorldGeometry")
 local side=G.uv(ts,0x35,0,7,1,8)
 -- Upper grey band is the TV's depth; the highlighted lower band is the
 -- screen. The separate white NES lies below it, with its controller on
 -- the original rug. It must not become another vertical screen.
 prism(out,ts,0x35,x,z+22,16,10,0,17,side,side,side)
 patch(out,L,ts,o,0,14,16,9,{x,17.02,z+22},{x+16,17.02,z+22},{x+16,17.02,z+32},{x,17.02,z+32})
 patch(out,L,ts,o,0,23,16,17,{x,17,z+32.02},{x+16,17,z+32.02},{x+16,0,z+32.02},{x,0,z+32.02})
 prism(out,ts,0x35,x+2,z+36,12,11,0,3,side,side,side)
 patch(out,L,ts,o,2,41,12,7,{x+2,3.02,z+36},{x+14,3.02,z+36},{x+14,3.02,z+47},{x+2,3.02,z+47})
end

local function wall(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry')
 for row=0,1 do
  local mid=L:midAt(o.x,o.y+row)
  if o.clear then
   mid=o.wallSource and o.wallSource[row+1] or o.network and (row==0 and 0x284 or 0x2a9)
    or o.mart and (row==0 and 0x285 or 0x28f) or (row==0 and 0x20 or 0x28)
  end
  local h=32-row*16
  G.quad(out,{x,h,z+32},{x+16,h,z+32},{x+16,h-16,z+32},{x,h-16,z+32},G.uv(ts,mid,0,0,16,16,.5),1)
 end
end
local function gondola(out,L,ts,o,x,z)
 -- Long double-sided shop island: preserve its native plan on a low top,
 -- rather than compressing all its merchandise into a vertical end panel.
 local G=V.require('WorldGeometry');local m=L:midAt(o.x,o.y+3)
 local side=G.uv(ts,m,8,12,9,13)
 prism(out,ts,m,x+1,z+3,o.w*16-2,57,0,6,side,side,side)
 patch(out,L,ts,o,0,0,o.w*16,60,{x,6.02,z},{x+o.w*16,6.02,z},
  {x+o.w*16,6.02,z+60},{x,6.02,z+60})
 patch(out,L,ts,o,0,60,o.w*16,4,{x,6,z+60.02},{x+o.w*16,6,z+60.02},
  {x+o.w*16,2,z+60.02},{x,2,z+60.02})
end
local function stairs(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry')
 local dark=G.uv(ts,5,6,3,7,4);local white=G.uv(ts,5,1,1,2,2)
 local rail=G.uv(ts,0xd,4,5,5,6)
 G.quad(out,{x,-16,z},{x+32,-16,z},{x+32,-16,z+26},{x,-16,z+26},dark,1)
 G.quad(out,{x,0,z},{x+32,0,z},{x+32,-16,z},{x,-16,z},dark,1)
 for n=0,6 do
  local col,row=5+n*4,14-n*2
  local mid=L:midAt(o.x+math.floor(col/16),o.y)
  local top=G.uv(ts,mid,col%16,row,col%16+3,row+1,.5)
  local edge=G.uv(ts,6,12,3,13,4,.5)
  prism(out,ts,6,x+4+n*4,z+3,4,22,-16,4+n*2,top,top,edge)
 end
 -- Original white handrail and grey posts; no solid wall replacing them.
 prism(out,ts,5,x,z,3,27,6,2,white,rail,rail)
 prism(out,ts,5,x,z+25,32,3,6,2,white,rail,rail)
 for _,dx in ipairs({2,10,18,26})do prism(out,ts,5,x+dx,z+25,2,2,0,6,rail,rail,rail)end
 for _,dz in ipairs({2,13})do prism(out,ts,5,x+1,z+dz,2,2,0,6,rail,rail,rail)end
end
local function plant(out,L,ts,o,x,z)
 local home=V.require('HomePlants');if home.matches(L,o)then return home.build(out,L,ts,o,x,z)end
 local BM=V.require('BuildingMesh');local H=(o.rows or 2)*16
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local bg={};local mids={o.ground};for _,m in ipairs(o.bg or {})do mids[#mids+1]=m end
 for _,m in ipairs(mids)do for yy=0,15 do for xx=0,15 do bg[rgb(BM.pixel(ts,m,xx,yy))]=true end end end
 local function source(sx,sy)return L:midAt(o.x,o.y-H/16+1+math.floor(sy/16)),sx,sy%16 end
 local clear,empty,queue={},{},{}
 for sy=0,H-1 do for sx=0,15 do
  local m,u,v=source(sx,sy);local r,g,b,a=BM.pixel(ts,m,u,v)
  clear[sy*16+sx]=a<.5 or bg[rgb(r,g,b)] or sy>=H-(o.trim or 0)
 end end
 local function seed(sx,sy)local k=sy*16+sx;if clear[k] and not empty[k]then empty[k]=true;queue[#queue+1]=k end end
 for sy=0,H-1 do seed(0,sy);seed(15,sy)end
 for sx=0,15 do seed(sx,0);seed(sx,H-1)end
 local n=1;while queue[n]do
  local k=queue[n];n=n+1;local sx,sy=k%16,math.floor(k/16)
  if sx>0 then seed(sx-1,sy)end;if sx<15 then seed(sx+1,sy)end
  if sy>0 then seed(sx,sy-1)end;if sy<H-1 then seed(sx,sy+1)end
 end
 local function inside(sx,sy)
  -- Pot shares the wall/floor palette; its enclosed centre is still art.
  local pot=false
  if o.rows==3 then
   local widths={[27]=2,[28]=4,[29]=5,[30]=5,[31]=5,[32]=5,[33]=5,[34]=5,[35]=5,[36]=5,[37]=4,[38]=3,[39]=3}
   local half=widths[sy];pot=half and sx>=8-half and sx<8+half
  end
  if o.labPot and sy>=17 and sy<31 then
   local half=sy<27 and 5 or sy<29 and 4 or 3
   pot=sx>=8-half and sx<8+half
  end
  return pot or not empty[sy*16+sx]
 end
 local base=H-(o.trim or 0)
 local verts=V.require('PaperSprite').build(ts,16,H,source,inside,0,base,1,nil,
  function(sx,sy)return {x+sx,(base-sy)*1.18,z+16-(o.trim or 0)}end,.5)
 for _,v in ipairs(verts)do out[#out+1]=v end
end
local function roundtable(out,L,ts,o,x,z)
 -- Center glass table: keep the entire native rounded rim/reflection;
 -- fold only its lower apron down. No colour-key through the glass.
 if o.ground then return end -- Other families use their native cutout below.
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').interiors.centerFurniture
 local source,inside=nativeMask(L,ts,o,32,32,{0x281,0x2b7,0x2c6})
 local h,d=cfg.tableHeight,cfg.tableDepth
 local function put(y0,y1,project)
  local verts=V.require('PaperSprite').build(ts,32,32,source,function(sx,sy)return sy>=y0 and sy<y1 and inside(sx,sy)end,0,32,1,nil,project,.5)
  for _,v in ipairs(verts)do out[#out+1]=v end
 end
 put(0,26,function(sx,sy)return {x+sx,h,z+sy*d/26}end)
 put(26,29,function(sx,sy)return {x+sx,h-(sy-26)*cfg.tableRimHeight/3,z+d}end)
 -- Original dark posts under the apron: no invented solid slab.
 put(29,32,function(sx,sy)return {x+sx,(32-sy)*(h-cfg.tableRimHeight)/3,z+d}end)
end
local function escalator(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').interiors.centerFurniture
 -- Only remove floor-connected background. Global palette rejection can
 -- punch holes in shared-colour highlights inside the original machinery.
 local source,inside=nativeMask(L,ts,o,32,48,{0x281,0x2b7,0x2c6})
 local function height(y)return math.max(0,(48-y)*cfg.escalatorRise/48)end
 -- Preserve the complete native tread/handrail drawing on the inclined top.
 -- Close its actual pixel contour to the floor, not its rectangular quad.
 for sy=0,47 do for sx=0,31 do if inside(sx,sy)then
  local m,u,v=source(sx,sy);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
  local a,b=x+sx,z+sy;local h0,h1=height(sy),height(sy+1)
  G.quad(out,{a,h0,b},{a+1,h0,b},{a+1,h1,b+1},{a,h1,b+1},uv,1)
  if not inside(sx-1,sy)then G.quad(out,{a,h0,b},{a,h1,b+1},{a,0,b+1},{a,0,b},uv,cfg.escalatorSideShade)end
  if not inside(sx+1,sy)then G.quad(out,{a+1,h1,b+1},{a+1,h0,b},{a+1,0,b},{a+1,0,b+1},uv,cfg.escalatorSideShade)end
  if not inside(sx,sy-1)then G.quad(out,{a+1,h0,b},{a,h0,b},{a,0,b},{a+1,0,b},uv,cfg.escalatorSideShade)end
  if not inside(sx,sy+1)then G.quad(out,{a,h1,b+1},{a+1,h1,b+1},{a+1,0,b+1},{a,0,b+1},uv,cfg.escalatorSideShade)end
 end end end
end
local function standing(out,L,ts,o,x,z)
 local start=o.sy or 0;local h=o.pixelH or (o.h or 2)*16
 local source,inside=nativeMask(L,ts,o,(o.w or 1)*16,start+h,o.background,o.backgroundPixels)
 local verts=V.require('PaperSprite').build(ts,(o.w or 1)*16,start+h,source,
  function(sx,sy)return sy>=start and sx>=(o.left or 0) and sx<(o.right or (o.w or 1)*16) and inside(sx,sy)end,0,start+h,1,nil,
  function(sx,sy)return {x+sx,(o.base or 0)+start+h-sy,z+(o.front or start+h)}end,.5)
 for _,v in ipairs(verts)do out[#out+1]=v end
end
local function wallCorner(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry')
 -- Undo the diagonal already painted into the native corner before
 -- placing it on a real diagonal wall. Otherwise it appears twice.
 for sx=0,15 do for sy=0,31 do
  local offset=o.right and sx or 15-sx
  local row=math.floor((sy+offset)/16)
  local m=o.wallSource and o.wallSource[row+1]or L:midAt(o.x,o.y+row)
  local z0=z+32+(o.right and sx or 16-sx)
  local z1=z0+(o.right and 1 or -1)
  G.quad(out,{x+sx,32-sy,z0},{x+sx+1,32-sy,z1},
   {x+sx+1,31-sy,z1},{x+sx,31-sy,z0},G.uv(ts,m,sx,(sy+offset)%16,sx+1,(sy+offset)%16+1,.5),1)
 end end
 -- Retain the floor's pixel pitch right up to the diagonal return. A
 -- triangle textured with an entire tile would stretch its square motif.
 for sx=0,15 do for sy=32,47 do
  if sy>=32+(o.right and sx or 15-sx)then
   G.quad(out,{x+sx,0,z+sy},{x+sx+1,0,z+sy},{x+sx+1,0,z+sy+1},{x+sx,0,z+sy+1},
    G.uv(ts,0x281,sx,sy%16,sx+1,sy%16+1,.5),1)
  end
 end end
end
local builders={wall=wall,wallCorner=wallCorner,panel=panel,standing=standing,desk=desk,bed=bed,console=console,counter=counter,stool=stool,gondola=gondola,roundtable=roundtable,stairs=stairs,plant=plant,escalator=escalator}
local native={prism=prism,patch=patch,nativeMask=nativeMask}
for _,kind in ipairs{'casinoWall','casinoExit','casinoCounter','casinoCabinet','casinoPC','casinoPlant','casinoSeat','casinoBank','casinoStairs','casinoPartition','casinoTable','casinoSofa','casinoBin'}do builders[kind]=function(...)return V.require('InteriorCasino').build(native,...)end end
builders.celioMachine=function(...)return V.require('InteriorCelio').machine(native,...)end
builders.celioCable=function(...)return V.require('InteriorCelio').cable(native,...)end
builders.celioFloorEdge=function(...)return V.require('InteriorCelio').floorEdge(native,...)end
builders.indigoWallJoin=function(...)return V.require('InteriorIndigoReception').wallJoin(native,...)end
builders.indigoSideCounter=function(...)return V.require('InteriorIndigoReception').sideCounter(native,...)end
for _,kind in ipairs({'schoolWall','schoolFold'})do
 builders[kind]=function(...)return V.require('InteriorSchool')[kind](native,...)end
end
for _,kind in ipairs({'transitCounter','transitStairs','transitPlant'})do
 builders[kind]=function(...)return V.require('InteriorTransit')[kind](native,...)end
end
for _,kind in ipairs({'hotelWall','hotelPartition','hotelFold','hotelStairs','hotelSofa'})do
 builders[kind]=function(...)return V.require('InteriorHotel')[kind](native,...)end
end
for _,kind in ipairs({'museumWall','museumPartition','museumStairs','museumPlant','museumFold'})do
 builders[kind]=function(out,L,ts,o,x,z)return V.require('InteriorMuseum')[kind](native,out,L,ts,o,x,z)end
end
for _,kind in ipairs({'restaurantWall','restaurantCounter','restaurantFold','restaurantChair'})do
 builders[kind]=function(...)return V.require('InteriorRestaurant')[kind](native,...)end
end
for _,kind in ipairs({'condoWall','condoPartition','condoFold','condoSofa','condoSideSofa','condoStairs'})do
 builders[kind]=function(...)return V.require('InteriorCondo')[kind](native,...)end
end
for _,kind in ipairs({'clubWall','clubFold','clubSeat','clubPen','clubPC'})do
 builders[kind]=function(...)return V.require('InteriorClub')[kind](native,...)end
end
for _,kind in ipairs({'bikeWall','bikeCutout','bikeFold'})do
 builders[kind]=function(...)return V.require('InteriorBikeShop')[kind](native,...)end
end
for _,kind in ipairs({'deptWall','deptPartition','deptStairs','deptRing','deptPlant','deptSofa'})do
 builders[kind]=function(...)return V.require('InteriorDepartment')[kind](native,...)end
end
for _,kind in ipairs({'deptRetailWall','deptRetailFold','deptIsland','deptSalesCounter'})do
 builders[kind]=function(...)return V.require('InteriorDepartmentRetail')[kind](native,...)end
end
for _,kind in ipairs({'houseVariantWall','houseVariantFold','houseVariantPlant','houseVariantBin','houseVariantChair'})do
 builders[kind]=function(...)return V.require('InteriorHouseVariants')[kind](native,...)end
end
for _,kind in ipairs({'shipCabinWall','shipCabinBed','shipCabinDesk','shipCabinPlant','shipCabinChair','shipCabinTable','shipCabinRug'})do
 builders[kind]=function(...)return V.require('InteriorShipCabins').build(native,...)end
end
for _,kind in ipairs{'communityWall','communityCounter','communityCabinet','communityChair'}do
 builders[kind]=function(...)return V.require('InteriorCommunity').build(native,...)end
end
builders.elevatorWall=function(...)return V.require('InteriorElevator').wall(native,...)end
builders.elevatorDoorway=function(...)return V.require('InteriorElevator').doorway(native,...)end
for _,kind in ipairs({'shipCorridorWall','shipCorridorFloor','shipCorridorStairs','shipCorridorExit'})do
 builders[kind]=function(...)return V.require('InteriorShipCorridors').build(native,...)end
end
for _,kind in ipairs({'shipPublicWall','shipPublicTable','shipPublicBench','shipPublicCabinet','shipPublicChair','shipPublicBucket','shipPublicBin','shipPublicStairs'})do
 builders[kind]=function(...)return V.require('InteriorShipPublic').build(native,...)end
end
builders.labFold=function(...)return V.require('LabSurfaces').fold(native,...)end
for _,kind in ipairs({'table','chair','seat','glass','stairsUp'})do
 builders[kind]=function(...)return V.require('HomeSurfaces')[kind](native,...)end
end
function I.build(out,objects,L,ts,ox,oz,mask,owners,fallback,contacts)
 local c=V.require('DioramaConfig').interiors
 for _,o in ipairs(objects)do
  local x,z=(o.x+ox)*16,(o.y+oz)*16
  local build=builders[o.kind]
  if o.kind=="roundtable" and o.ground then build=nil end
  if build then
   local first=#out+1
   build(out,L,ts,o,x,z)
   for n=first,#out do out[n][2]=out[n][2]*c.heightScale end
   V.require("RoomLightRig").capture(L,o,out,first,#out,x,z)
   if not o.noContact and o.kind~='communityWall' and o.kind~='indigoWallJoin' and o.kind~='shipCabinWall' and o.kind~='wall' and o.kind~='wallCorner' and o.kind~='schoolWall' and o.kind~='hotelWall' and o.kind~='restaurantWall' and o.kind~='museumWall' and o.kind~='condoWall' and o.kind~='clubWall' and o.kind~='bikeWall' and o.kind~='houseVariantWall' and o.kind~='elevatorWall' and o.kind~='elevatorDoorway' and o.kind~='deptRetailWall' and o.kind~='deptWall' and o.kind~='deptPartition' and (o.base or 0)==0 then
    local w=o.contactWidth or (o.w or (o.kind=='bed' and 3) or 1)*16
    local fronts={stool=14,plant=16-(o.trim or 0),bed=46,roundtable=c.centerFurniture.tableDepth,escalator=46}
    local front=z+(o.contactFront or o.front or o.last or fronts[o.kind] or 30)
    local origin=x+(o.contactOffset or 0)
    for xx=origin+4,origin+w-2,8 do contacts[#contacts+1]={xx,front,7,c.contactRadius,c.contactStrength}end
   end
  else
   local own={}
   for k,v in pairs(mask)do if owners[k]==o then own[k]=v end end
   -- Unmeasured art remains an independent native cutout, never a guessed box.
   fallback(own)
  end
 end
end
return I
