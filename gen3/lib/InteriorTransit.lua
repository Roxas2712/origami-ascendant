-- Four native underground-path entrances: recessed stairs, independent
-- C-shaped benches, and floor texture restored around each exact footprint.
local V=...
local T={}
function T.profile(def)
 if not(def and def.mapType==8 and def.midLayout and def.pair=='house')then return end
 local direction=(def.id or def.name or''):match('^FR_UNDERGROUND_PATH_(%u+)_ENTRANCE$')
 if direction~='NORTH'and direction~='SOUTH'and direction~='EAST'and direction~='WEST'then return end
 if V.require('IndoorSurfaces').profile(def)==V.require('DioramaConfig').interiors.transitSurfaces then return V.require('DioramaConfig').interiors.transitSurfaces end
end
function T.plan(def)
 if not T.profile(def)then return nil end
 local L=def.midLayout;local objects,mask,owners={},{},{}
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1;mask[k]=donor or 0x281;owners[k]=o
  end end
 end
 for x=0,12 do add({kind='wall',x=x,y=0,clear=x==0 or x==12,wallSource={0x287,0x28f}},x,0,1,2,{mid=0,void=true})end
 for _,x in ipairs({2,9})do add({kind='transitCounter',x=x,y=2,w=2,right=x==9,front=72},x,2,3,6)end
 add({kind='transitStairs',x=5,y=3,w=3,front=44},5,3,3,3,{mid=0,void=true})
 for _,p in ipairs({{0,2},{12,2},{0,8},{12,8}})do
  add({kind='transitPlant',x=p[1],y=p[2]-1,front=30},p[1],p[2]-1,1,2)
 end
 for y=0,1 do for x=0,12 do mask[y*L.width+x+1]={mid=0,void=true}end end
 return {objects=objects,mask=mask,owners=owners}
end
function T.recesses(def)
 return T.profile(def)and{{80,58,114,92}}or{}
end
local function pixelUV(G,L,ts,o,sx,sy)
 return G.uv(ts,L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16)),sx%16,sy%16,sx%16+1,sy%16+1,.5)
end
function T.transitCounter(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local h=V.require('DioramaConfig').interiors.transitSurfaces.counterHeight
 local function source(sx,sy)return L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16)),sx%16,sy%16 end
 -- Source rows 13..71 are the cream top; 23..31 and 71..79 contain
 -- the short grey fronts. Their floor shadows are deliberately not raised.
 local function topInside(sx,sy)
  local u=o.right and 31-sx or sx
  return u>=1 and u<31 and sy>=13 and sy<71 and (u<15 or sy<23 or sy>=61)
 end
 local function put(a,b,inside,project)
  local vv=V.require('PaperSprite').build(ts,32,80,source,function(sx,sy)return sy>=a and sy<b and inside(sx,sy)end,0,80,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 put(13,71,topInside,function(sx,sy)return {x+sx,h,z+sy}end)
 for _,band in ipairs({{23,31},{71,79}})do
  put(band[1],band[2],function(sx)
   local u=o.right and 31-sx or sx;return u>=1 and u<31 and (band[1]==71 or u>=15)
  end,function(sx,sy)return {x+sx,h*(band[2]-sy)/8,z+band[1]}end)
 end
 -- Close the thin inner/outer faces using native edge texels. No opaque
 -- bounding box across the walkable centre of either C-shaped bench.
 local outer=o.right and 31 or 1;local inner=o.right and 17 or 15
 local side=pixelUV(G,L,ts,o,o.right and 30 or 1,73)
 for _,r in ipairs({{outer,13,71},{inner,23,61}})do
  G.quad(out,{x+r[1],h,z+r[2]},{x+r[1],h,z+r[3]},{x+r[1],0,z+r[3]},{x+r[1],0,z+r[2]},side,1)
 end
 o.contactFront=71;o.contactWidth=32
end
function T.transitStairs(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').interiors.transitSurfaces
 local depth=cfg.stairDepth
 -- Only the native shaft footprint is absent. Rebuild the surrounding
 -- partial tiles at their original pixel pitch instead of cutting 3x3 tiles.
 for sy=0,47 do for sx=0,47 do if sx>=34 or sy<10 or sy>=44 then
  G.quad(out,{x+sx,0,z+sy},{x+sx+1,0,z+sy},{x+sx+1,0,z+sy+1},{x+sx,0,z+sy+1},
   G.uv(ts,0x281,sx%16,sy%16,sx%16+1,sy%16+1,.5),1)
 end end end
 local dark=pixelUV(G,L,ts,o,5,20);local rim=pixelUV(G,L,ts,o,1,11)
 local railSide=pixelUV(G,L,ts,o,5,45)
 G.quad(out,{x,-depth,z+10},{x+34,-depth,z+10},{x+34,-depth,z+44},{x,-depth,z+44},dark,1)
 for n=0,6 do
  local top=-depth+(n+1)*depth/7
  local tread=pixelUV(G,L,ts,o,6+n*4,31-n*2)
  api.prism(out,ts,0,x+4+n*4,z+14,4,26,-depth,top+depth,tread,dark,dark)
  -- Native dark separator between each pair of differently coloured treads.
  local edge=x+4+n*4
  G.quad(out,{edge,top+.02,z+14},{edge+cfg.treadEdge,top+.02,z+14},
   {edge+cfg.treadEdge,top+.02,z+40},{edge,top+.02,z+40},dark,1)
 end
 -- Three sides enclose the opening, with the right side open at ground
 -- level exactly where the native stair warp accepts the player.
 for _,r in ipairs({{0,10,4,34},{4,10,30,4},{4,40,30,4}})do
  api.prism(out,ts,0,x+r[1],z+r[2],r[3],r[4],-depth,depth+cfg.railHeight,rim,railSide,railSide)
 end
 o.contactFront=44;o.contactWidth=34
end
function T.transitPlant(api,out,L,ts,o,x,z)
 -- The grey trunk and white pot share colours with the wall trim. Their
 -- measured native contour must survive even where palette flood-fill fails.
 local spans={[4]={7,9},[5]={6,10},[6]={2,14},[7]={2,14},[8]={2,14},[9]={2,14},[10]={1,15},
  [11]={0,16},[12]={0,16},[13]={0,16},[14]={0,16},[15]={0,16},[16]={1,15},[17]={1,15},
  [18]={4,12},[19]={5,11},[20]={4,12},[21]={3,13},[22]={3,13},[23]={3,13},[24]={3,13},[25]={3,13},
  [26]={4,12},[27]={4,12},[28]={4,12},[29]={4,12},[30]={5,11}}
 local source=function(sx,sy)sy=sy+(o.sourceY or 0);return L:midAt(o.x,o.y+math.floor(sy/16)),sx,sy%16 end
 local vv=V.require('PaperSprite').build(ts,16,32,source,function(sx,sy)
  local r=spans[sy];return r and sx>=r[1] and sx<r[2]
 end,0,32,1,nil,function(sx,sy)return {x+sx,31-sy,z+30}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
end
return T
