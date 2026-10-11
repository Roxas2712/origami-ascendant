-- Complete the two map-edge towers from their native atlas artwork. Lavender's
-- crown and two storeys belong to Route 10 in the ROM, not to a second building.
local V=...
local T={}
function T.kind(b)
 if b.mapId=='FR_LAVENDER_TOWN'and b.x0==15 and b.y0==0 then return 'lavender'end
 if b.mapId=='FR_SEVEN_ISLAND_TRAINER_TOWER'and b.x0==54 and b.y0==0 then return 'trainer'end
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local rocks={[0xdec5a5]=true,[0x7b4a4a]=true,[0xbd948c]=true,[0x5a3a42]=true,[0x946b6b]=true,[0xefd6c5]=true}
local crown={
 {1,1,0x2a5,0x2a6,0x2a7,1,1},
 {0x2a9,0x2aa,0x2ab,0x2ac,0x2ad,0x2ae,0x2af},
 {0x2b1,0x2b2,0x2b3,0x2b4,0x2b5,0x2b6,0x2b7},
 {0x2b9,0x2ba,0x2bb,0x2bc,0x2bd,0x2be,0x2bf},
 {0x2c1,0x2c2,0x2c3,0x2c4,0x2c5,0x2c6,0x2c7},
 {0x2c9,0x2ca,0x2cb,0x2cc,0x2cd,0x2ce,0x2cf},
 {0x2b0,0x2d2,0x2d3,0x2d3,0x2d3,0x2d6,0x2b8},
 {0x2c0,0x2d2,0x2d3,0x2d3,0x2d3,0x2d6,0x2c8}}
function T.crownSource(x,y)return crown[math.floor(y/16)+1][math.floor(x/16)+1],x%16,y%16 end
local function palette(ts,mid)
 local p={};for y=0,15 do for x=0,15 do p[rgb(V.require('BuildingMesh').pixel(ts,mid,x,y))]=true end end;return p
end
local function isCrown(ts,x,y,grass)
 local r,g,b,a=V.require('BuildingMesh').pixel(ts,T.crownSource(x,y));local c=rgb(r,g,b)
 return a>.5 and not grass[c]and not rocks[c]
end
-- Remove only the crown's original ground pixels on Route 10. Keep its
-- flanking rocks/grass, native collision and connection metadata untouched.
function T.floor(out,d,ts,x,y,ox,oz)
 if d.id~='FR_ROUTE_10'or x<15 or x>21 or y<72 or y>79 then return false end
 local G=V.require('WorldGeometry');local grass=palette(ts,1)
 local vv=V.require('PaperSprite').build(ts,16,16,function(s,t)
  if isCrown(ts,(x-15)*16+s,(y-72)*16+t,grass)then return 1,s,t end
  return d.midLayout:midAt(x,y),s,t
 end,function()return true end,0,0,1,nil,function(s,t)return{(x+ox)*16+s,0,(y+oz)*16+t}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end;return true
end
function T.build(out,b,L,ts,ox,oz)
 local kind=assert(T.kind(b));local lavender=kind=='lavender'
 local BM=V.require('BuildingMesh');local G=V.require('WorldGeometry');local S=V.require('PaperSprite');local LL=V.require('LocalLights')
 local sp,pr=BM.sprite(b,L,ts,true);local scale=1.18*V.require('Billboard').heightScale()
 local extra=lavender and 32 or 16;local left=lavender and 8 or 20;local right=lavender and 104 or 124
 local frontLeft=lavender and 24 or 36;local frontRight=lavender and 88 or 108;local depth=lavender and 72 or 48
 local xx,zz=(b.x0+ox)*16,(b.y1+1+oz)*16
 local function source(x,y)return L:midAt(b.x0+math.floor(x/16),math.floor(y/16)),x%16,y%16 end
 local function height(y)
  local h=(sp.H-y)*scale
  if lavender then h=h+math.min(sp.H-y,40)*(.80-1.18)*V.require('Billboard').heightScale()end
  return h
 end
 local function front(x,y)
  local z=-math.max(0,frontLeft-x,x-frontRight)
  -- Pedestal/entry stay at the native warp plane; upper chamfers gain depth.
  local blend=math.min(1,math.max(0,(sp.H-y-16)/24))
  return{x,height(y),z*blend,0,lavender and y or 0,-1}
 end
 local function append(vv)for _,v in ipairs(vv)do out[#out+1]=G.place(v,xx,zz)end end
 local grass=palette(ts,1)
 local function upperSource(x,y)
  if lavender then return T.crownSource(x,y+96)end
  return 0x2a0+math.floor((x-16)/16),(x-16)%16,y%16
 end
 local function upperInside(x,y)
  if lavender then return isCrown(ts,x,y+96,grass)end
  return x>=16 and x<128
 end
 local whole={W=sp.W,H=sp.H+extra,inside={},faceDepth={},darkGlass={},ax={},ay={}}
 for y=0,whole.H-1 do for x=0,whole.W-1 do
  local i=y*whole.W+x;local old=(y-extra)*sp.W+x
  if y>=extra then
   whole.inside[i],whole.faceDepth[i],whole.darkGlass[i]=sp.inside[old],sp.faceDepth[old],sp.darkGlass[old]
   whole.ax[i],whole.ay[i]=sp.ax[old],sp.ay[old]
  elseif upperInside(x,y)then
   local r,g,bl,alpha,ax,ay=BM.pixel(ts,upperSource(x,y))
   whole.inside[i]=alpha>.5;whole.ax[i],whole.ay[i]=ax,ay
   if not lavender and bl>r*1.25 and bl>g*1.02 and g>r*1.1 and g>.4 then whole.faceDepth[i]=2 end
  end
 end end
 local lights,fullGlass=LL.windows(whole,{roofRows=0,depthPx=depth});local glass,ghost={},{}
 for i in pairs(fullGlass)do if i>=extra*sp.W then glass[i-extra*sp.W]=true end end
 if lavender then
  for y=0,45 do for x=0,sp.W-1 do local i=y*sp.W+x
   if sp.inside[i]and V.require('GhostWindows').sidePane(x,y,BM.pixel(ts,source(x,y)))then ghost[i]=true end
  end end
 end
 LL.registerGlass(ts,whole,fullGlass)
 LL.registerGlass(ts,sp,glass,ghost)
 append(S.build(ts,sp.W,sp.H,source,function(x,y)return sp.inside[y*sp.W+x]end,0,sp.H,1,function()return 3 end,front,.5,
  function(x,y)return glass[y*sp.W+x]and(not lavender or y>=48 and y<=64)and 1 or -1 end))
 append(S.build(ts,sp.W,extra,function(x,y)if not lavender and x<16 then return 1,x%16,y%16 end;return upperSource(x,y)end,
  upperInside,0,extra,1,function()return 3 end,function(x,y)return front(x,y-extra)end,.5,function(x,y)return not lavender and fullGlass[y*sp.W+x]and 1 or -1 end))
 local roofHeight=height(-extra)
 -- Close the volume behind the original chamfered facade. Use native wall
 -- texels, never the surrounding sea/cliff strips, and never emit side light.
 for _,side in ipairs{{left,frontLeft,-1},{right,frontRight,1}}do
  append(S.build(ts,1,sp.H+extra,function(s,y)return source(side[3]<0 and frontLeft or frontRight-1,math.min(sp.H-1,math.max(0,y-extra)))end,
   function()return true end,0,0,1,function()return 3.25 end,
   function(s,y)return{side[1],height(y-extra),-16-s*(depth-16),0,0,-1}end,.5,function()return -1 end))
 end
 append(S.build(ts,frontRight-frontLeft,sp.H+extra,function(x,y)return source(frontLeft+x,math.min(sp.H-1,math.max(0,y-extra)))end,
  function()return true end,0,0,1,function()return 3.3 end,
  function(x,y)return{left+x*(right-left)/(frontRight-frontLeft),height(y-extra),-depth,0,0,-1}end,.5,function()return -1 end))
 -- A continuous opaque deck closes the shell beneath the native roof trim.
 local deck={};local ring={{frontLeft,0},{frontRight,0},{right,-16},{right,-depth},{left,-depth},{left,-16}}
 local uv=lavender and G.uv(ts,0x2cb,8,10,9,11,.5)or G.uv(ts,0x28b,8,8,9,9,.5)
 for i=1,#ring do local a,c=ring[i],ring[i%#ring+1];local p={(left+right)/2,roofHeight-.05,-depth/2,0,0,-1}
  G.quad(deck,p,{a[1],roofHeight-.05,a[2],0,0,-1},{c[1],roofHeight-.05,c[2],0,0,-1},p,uv,G.BUILDING_ROOF)
 end;append(deck)
 if lavender then
  -- The original rounded crown becomes a raised roof. Its centre gains a
  -- modest physical dome; the white finial remains an upright paper detail.
  local function finial(x,y)
   if x<48 or x>=64 or y>=32 then return false end
   local r,g,bl=BM.pixel(ts,T.crownSource(x,y));return r>.72 and g>.80 and bl>.72
  end
  local function roofSource(x,y)
   if finial(x,y)then return T.crownSource(40,y)end
   return T.crownSource(x,y)
  end
  append(S.build(ts,112,96,roofSource,function(x,y)return y>=16 and isCrown(ts,x,y,grass)end,0,0,1,
   function()return G.BUILDING_ROOF end,function(x,y)
    local q=math.max(0,1-((x-56)/48)^2-((y-56)/40)^2)
    return{x,roofHeight+q*12,(y-96)*depth/80,0,0,-1}
   end,.5,function()return -1 end))
  append(S.build(ts,112,32,T.crownSource,function(x,y)return finial(x,y)end,0,0,1,
   function()return 3 end,function(x,y)return{x,roofHeight+12+(28-y)*.8,-depth*.5,0,0,-1}end,.5,function()return -1 end))
 else
  -- Purple native Trainer Tower roof, including its trim; blue ocean texels
  -- outside the end brackets are deliberately excluded from the roof mask.
  local function roofSource(x,y)return(y<16 and 0x288 or 0x290)+math.floor(x/16),x%16,y%16 end
  append(S.build(ts,112,32,roofSource,function(x,y)
   if x>=16 and x<96 then return true end
   local r,g,bl=BM.pixel(ts,roofSource(x,y));return r>g*1.1 or math.abs(r-g)<.035 and math.abs(g-bl)<.035
  end,0,0,1,function()return G.BUILDING_ROOF end,
   function(x,y)return{x+16,roofHeight+3,(y-32)*depth/32,0,0,-1}end,.5,function()return -1 end))
  local uv=G.uv(ts,0x295,0,13,16,15,.5)
  local vv={};G.quad(vv,{left,roofHeight+3,0,0,0,-1},{right,roofHeight+3,0,0,0,-1},{right,roofHeight,0,0,0,-1},{left,roofHeight,0,0,0,-1},uv,3);append(vv)
 end
 if sp.background then append(S.build(ts,sp.W,sp.H,source,function(x,y)return sp.background[y*sp.W+x]end,0,0,1,function()return 1 end,
  function(x,y)return{x,.03,y-sp.H}end,.5))end
 local result={}
 if not lavender then for _,l in ipairs(lights)do local p=front(l.x,sp.H-l.y)
  result[#result+1]={x=xx+p[1],y=p[2],z=zz+p[3]+.2,radius=math.min(112,72+p[2]*.6),power=l.power*.35*.22,facadeBounce=V.require('DioramaConfig').lighting.houseBounce}
 end end
 return result
end
return T
