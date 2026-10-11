-- Native Pacifidlog huts and floating timber. Only render geometry changes;
-- the original water/bridge behaviours, collisions, elevations and warps stay intact.
local V=...
local P={}
local function cfg()return V.require('DioramaConfig').pacifidlogArchitecture end
function P.applies(d)
 return d and(d.id or d.name)=='EM_PACIFIDLOG_TOWN'and d.pair=='general__pacifidlog'
  and cfg().enabled and V.require('DioramaConfig').billboards.enabled
  and V.require('Camera').projection()=='perspective'
end
local deckMids={[0x208]=true,[0x20c]=true,[0x210]=true,[0x214]=true,[0x218]=true,[0x219]=true,[0x21a]=true,[0x21b]=true,[0x21c]=true,
 [0x220]=true,[0x221]=true,[0x224]=true,[0x228]=true,[0x229]=true,[0x22a]=true,[0x22c]=true}
-- Native step callbacks animate all twelve floating/half/sunk states.
local bridges={[0x250]=1,[0x251]=1,[0x258]=1,[0x260]=1,
 [0x252]=.5,[0x253]=.5,[0x259]=.5,[0x261]=.5,[0x254]=0,[0x255]=0,[0x25a]=0,[0x262]=0}
function P.bridgeHeight(m)local f=bridges[m];return f and f*cfg().deckHeight end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local water={[0x526bd6]=true,[0x6b84d6]=true,[0x29428c]=true,[0x3a529c]=true,[0xadc5e6]=true,[0x8ca5de]=true,[0xdee6ef]=true}
function P.timber(ts,m,x,y)
 local r,g,b,a=V.require('BuildingMesh').pixel(ts,m,x,y)
 return a>.5 and not water[rgb(r,g,b)]
end
-- Measured inclusive silhouette extents of the native 80x64 hut. These
-- isolate its cap/eaves/bamboo walls from the gold deck and blue sea.
local silhouette={false,{38,41},{36,43},{35,44},{35,44},{34,45},{33,46},{33,46},{34,45},{34,45},{35,44},{36,43},
 {35,44},{35,44},{34,45},{32,47},{30,49},{28,51},{26,53},{25,54},{23,56},{22,57},{20,59},{19,60},
 {18,61},{17,62},{17,62},{17,62},{16,63},{16,63},{16,63},{16,63},{16,63},{16,63},
 {17,62},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},
 {18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},{18,61},
 {19,60},{20,59},{21,58},{22,57},{23,56}}
function P.hutPixel(x,y)local r=silhouette[y+1];return r and x>=r[1]and x<=r[2]or false end
function P.plan(d)
 local p={mask={},huts={},decks={},bridges={},signs={}}
 if not P.applies(d)then return p end
 local L=d.midLayout
 for _,w in ipairs(d.warps or{})do if L:midAt(w.x,w.y)==0x21a then
  local h={x=w.x-2,y=w.y-3,doorX=w.x,doorY=w.y};p.huts[#p.huts+1]=h
  for y=0,3 do for x=0,4 do if y>0 or x==2 then p.mask[(h.y+y)*L.width+h.x+x+1]=0x170 end end end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y);local k=y*L.width+x+1
  if m==3 then p.signs[#p.signs+1]={x=x,y=y,mid=m};p.mask[k]=0x170
  elseif deckMids[m]then p.decks[#p.decks+1]={x=x,y=y,mid=m};p.mask[k]=0x170
  elseif bridges[m]then p.bridges[#p.bridges+1]={x=x,y=y,mid=m};p.mask[k]=0x170 end
 end end
 return p
end
function P.mask(d,mask)for k,v in pairs(P.plan(d).mask)do mask[k]=v end end
function P.build(out,d,ts,ox,oz)
 if not P.applies(d)then return end
 local c=cfg();local p=P.plan(d);local L=d.midLayout;local G=V.require('WorldGeometry');local S=V.require('PaperSprite')
 local xx,zz=(ox or 0)*16,(oz or 0)*16
 local function append(v)for _,a in ipairs(v)do out[#out+1]=a end end
 local function art(o,source,inside,transform,shade)
  append(S.build(ts,16,16,source,inside,0,16,1,shade and function()return shade end or nil,
   function(x,y)local a,b,z=transform(x,y);return{xx+o.x*16+a,b,zz+o.y*16+z}end,.5))
 end
 local function owner(x,y)
  for _,h in ipairs(p.huts)do local sx,sy=x-h.x*16,y-h.y*16
   if sx>=0 and sx<80 and sy>=28 and sy<64 and (P.hutPixel(sx,sy)or sx>=18 and sx<=64 and sy>=34)then return h,sx,sy end
  end
 end
 -- Reconstruct only the obscured timber from the identical native plank tile.
 -- Foam and water are kept at sea level, never stretched up with the deck.
 local cells={};for _,o in ipairs(p.decks)do cells[o.y*L.width+o.x+1]=o end
 for _,h in ipairs(p.huts)do for y=1,3 do for x=0,4 do local wx,wy=h.x+x,h.y+y;cells[wy*L.width+wx+1]={x=wx,y=wy,mid=L:midAt(wx,wy)}end end end
 for _,o in pairs(cells)do
  local function source(x,y)if owner(o.x*16+x,o.y*16+y)then return 0x221,x,y end;return o.mid,x,y end
  local function inside(x,y,m,s,t)
   local h,_,sy=owner(o.x*16+x,o.y*16+y)
   if h then return sy>=28 end
   for _,hut in ipairs(p.huts)do local hx,hy=o.x*16+x-hut.x*16,o.y*16+y-hut.y*16;if P.hutPixel(hx,hy)then return false end end
   return P.timber(ts,m,s,t)
  end
  art(o,source,inside,function(x,y)return x,c.deckHeight,y end)
  art(o,function(x,y)return o.mid,x,y end,function(x,y,m,s,t)return not P.timber(ts,m,s,t)end,function(x,y)return x,.01,y end,G.WATER)
  -- Short physical rim below the native bottom deck edge, not a black skirt.
  if o.mid==0x228 or o.mid==0x229 or o.mid==0x22a or o.mid==0x22c then
   art(o,function(x,y)return o.mid,x,y end,function(x,y,m,s,t)return y>=8 and y<12 and P.timber(ts,m,s,t)end,
    function(x,y)return x,c.deckHeight-(y-8)*c.rimDepth/4,12 end,c.rimShade)
  end
 end
 for _,o in ipairs(p.bridges)do
  art(o,function(x,y)return o.mid,x,y end,function(x,y,m,s,t)return P.timber(ts,m,s,t)end,function(x,y)return x,P.bridgeHeight(o.mid),y end)
  art(o,function(x,y)return o.mid,x,y end,function(x,y,m,s,t)return not P.timber(ts,m,s,t)end,function(x,y)return x,.01,y end,G.WATER)
 end
 for _,o in ipairs(p.signs)do
  G.quad(out,{xx+o.x*16,c.deckHeight,zz+o.y*16},{xx+(o.x+1)*16,c.deckHeight,zz+o.y*16},{xx+(o.x+1)*16,c.deckHeight,zz+(o.y+1)*16},{xx+o.x*16,c.deckHeight,zz+(o.y+1)*16},G.uv(ts,0x221),1)
  local vv={};V.require('Props').stamp(vv,ts,3,'sign',xx+o.x*16,zz+o.y*16,0x221)
  for _,v in ipairs(vv)do v[2]=v[2]+c.deckHeight;out[#out+1]=v end
 end
 for _,h in ipairs(p.huts)do
  local scale=c.wallScale*V.require('Billboard').heightScale();local seam=44;local wall=(64-seam)*scale
  local roofDepth=seam*c.roofScale/math.max(.25,math.sin(V.require('Camera').elevation()))
  local function source(x,y)return L:midAt(h.x+math.floor(x/16),h.y+math.floor(y/16)),x%16,y%16 end
  local function point(x,y,roof)
   local a=(seam-y)/seam;return{xx+h.x*16+x,c.deckHeight+(roof and wall+a*c.roofRise or(64-y)*scale),zz+(h.doorY+1)*16-(roof and a*roofDepth or 0)}
  end
  append(S.build(ts,80,44,source,P.hutPixel,0,64,1,function()return G.BUILDING_ROOF end,function(x,y)return point(x,y,true)end,.5))
  append(S.build(ts,80,64,source,function(x,y)return y>=44 and P.hutPixel(x,y)end,0,64,1,nil,function(x,y)return point(x,y,false)end,.5))
 end
end
function P.actorHeight(d,x,z)
 if not P.applies(d)then return end
 local L=d.midLayout;local m=L:midAt(math.floor((x+8)/16),math.floor((z+.001)/16))
 if bridges[m]then return P.bridgeHeight(m)end
 if deckMids[m]or m==3 or m==0x61 or m==0x248 or m==0x24b then return cfg().deckHeight end
 return 0
end
function P.buildingBase(b)return b.mapId=='EM_PACIFIDLOG_TOWN'and P.applies({id=b.mapId,pair=b.pair})and cfg().deckHeight or 0 end
function P.doorPose(d,a)
 if not P.applies(d)or not a then return end
 local m=d.midLayout:midAt(a.x,a.y)
 if m==0x21a or m==0x61 then return{height=32*(m==0x21a and cfg().wallScale or 1.18)*V.require('Billboard').heightScale(),base=cfg().deckHeight,top=0}end
end
return P
