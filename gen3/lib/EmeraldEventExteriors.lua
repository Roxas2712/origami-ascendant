-- Event headers are indoor for script semantics; their native art is outdoors.
-- This adapter owns only measured objects, never cells, warps or encounters.
local V=...;local E={}
local maps={EM_BIRTH_ISLAND_EXTERIOR={'general__dewford',30,30},EM_NAVEL_ROCK_EXTERIOR={'general__dewford',22,24},
 EM_FARAWAY_ISLAND_ENTRANCE={'general__rustboro',34,46},EM_FARAWAY_ISLAND_INTERIOR={'general__fortree',30,26}}
function E.profile(d)
 local p=d and maps[d.id];local L=d and d.midLayout;local C=V.require('DioramaConfig')
 return p and C.eventIslands.enabled and C.billboards.enabled and d.mapType==8 and d.pair==p[1]and L and L.width==p[2]and L.height==p[3]and C.eventIslands or nil
end
function E.coast(d,c)
 if not E.profile(d)then return false end
 local m=c.mid
 -- Native diagonal shore corners include ocean pixels. The coast adapter
 -- raises only the exact rock palette, leaving water at sea level.
 if m==0x378 or m==0x37a or m>=0x172 and m<=0x19a then return true end
 -- The small central summit and four corner pockets are unreachable art,
 -- despite collision-zero cells. Faraway's walkable cliff trails stay flat.
 return d.id=='EM_NAVEL_ROCK_EXTERIOR'and(m==0x71 or m==0x81 or m==0xbf or m==0x17c)
end
function E.plan(d)
 local p={mask={},objects={}};if not E.profile(d)then return p end
 local L=d.midLayout
 local function object(x,y,w,h,kind)
  local o={x=x,y=y,w=w,h=h,kind=kind};p.objects[#p.objects+1]=o
  for dy=0,h-1 do for dx=0,w-1 do p.mask[(y+dy)*L.width+x+dx+1]=o end end
 end
 if d.id=='EM_BIRTH_ISLAND_EXTERIOR'then
  object(14,3,3,3,'tree');object(7,14,4,3,'tree');object(20,14,4,3,'tree')
 end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if d.pair=='general__dewford'and m==0x352 then object(x-1,y,7,5,'harbor')end
  if (m==0xe2 or m==0xe1)and d.id~='EM_BIRTH_ISLAND_EXTERIOR'then object(x,y,1,1,'rock')end
  if d.id=='EM_NAVEL_ROCK_EXTERIOR'and m==0x9f then object(x,y,1,2,'portal')end
 end end
 return p
end
local function leaf(ts,m,x,y)
 local r,g,b,a=V.require('BuildingMesh').pixel(ts,m,x,y)
 return a>.5 and g>r*1.06 and b<g*.63
end
local function treeInk(ts,m,x,y)
 local r,g,b,a=V.require('BuildingMesh').pixel(ts,m,x,y)
 return leaf(ts,m,x,y)or(a>.5 and r> b*1.25 and g>b*1.25 and g<r*1.3)
end
function E.floor(out,d,ts,x,y,ox,oz,p,contacts)
 local o=p.mask[y*d.midLayout.width+x+1];if not o then return false end
 local G=V.require('WorldGeometry');local cfg=E.profile(d);local m=d.midLayout:midAt(x,y);local xx,zz=(x+ox)*16,(y+oz)*16
 local function ground(mid,water)G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,mid),water and G.WATER or 1)end
 if o.kind=='tree'then
  -- Remove canopy, stump and its baked ochre shadow only. Original ocean
  -- texels around the northern crown remain ocean, not a grass rectangle.
  local donor=o.y==3 and y==3 and 0x170 or 1
  local v=V.require('PaperSprite').build(ts,16,16,function(s,t)return treeInk(ts,m,s,t)and donor or m,s,t end,function()return true end,0,0,1,nil,function(s,t)return{xx+s,0,zz+t}end,.5)
  for _,q in ipairs(v)do out[#out+1]=q end
 elseif o.kind=='harbor'then ground(0x170,true)
 elseif o.kind=='rock'then
  ground(d.id=='EM_NAVEL_ROCK_EXTERIOR'and 0x121 or 0x71)
  local donor=d.id=='EM_NAVEL_ROCK_EXTERIOR'and 0x121 or 0x71
  local bg={};local pixel=V.require('BuildingMesh').pixel
  local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
  for t=0,15 do for s=0,15 do bg[key(pixel(ts,donor,s,t))]=true end end
  local v=V.require('PaperSprite').build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return not bg[key(pixel(ts,m,s,t))]end,0,15,cfg.rockHeight/15,nil,nil,.5)
  for _,q in ipairs(v)do out[#out+1]=G.place(q,xx,zz+14)end
  contacts[#contacts+1]={xx+8,zz+14,6,cfg.contactDepth,cfg.contactStrength}
 elseif o.kind=='portal'then
  if y==o.y then
   local h=V.require('EmeraldCoastCliffs').height()
   -- Carry the native arch cap to the facade foot row: no open strip
   -- between the raised summit and the doorway plane.
   G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+32},{xx,h,zz+32},G.uv(ts,0x9f),1)
  else
   G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,0xa7,8,8,8,8,0),1)
  end
 end
 return true
end
function E.objects(out,d,ts,ox,oz,p,contacts)
 local cfg=E.profile(d);if not cfg then return end
 local G=V.require('WorldGeometry');local L=d.midLayout;local S=V.require('PaperSprite')
 for _,o in ipairs(p.objects)do local xx,zz=(o.x+ox)*16,(o.y+oz)*16;local W,H=o.w*16,o.h*16
  local function art(h,inside,point)
   local v=S.build(ts,W,h,function(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end,inside or function()return true end,0,h,1,nil,function(s,t)local q=point(s,t);return{xx+q[1],q[2],zz+q[3]}end,.5)
   for _,q in ipairs(v)do out[#out+1]=q end
  end
  if o.kind=='tree'then
   local base=32;local tilt=math.rad(V.require('DioramaConfig').trees.tiltDegrees)
   art(base,function(s,t,m,u,v)return leaf(ts,m,u,v)end,function(s,t)local h=(base-t)*cfg.treeHeight;return{s,h*math.cos(tilt),32+h*math.sin(tilt)}end)
   contacts[#contacts+1]={xx+W/2,zz+32,W*.28,cfg.treeContactDepth,cfg.treeContactStrength}
  elseif o.kind=='harbor'then
   -- Three roof rows above the eave, then native facade rows. Keep native
   -- side posts with their own facade; no emissive roof or invented window.
   art(H,function(s,t,m,u,v)
    local r,g,b,a=V.require('BuildingMesh').pixel(ts,m,u,v)
    return a>.5 and not(b>r*1.25 and b>g*1.15)
   end,function(s,t)
    if t<=48 then return{s,cfg.harborWallHeight+cfg.harborRoofRise*(1-t/48),t}end
    return{s,cfg.harborWallHeight*(1-(t-48)/32),48}
   end)
   for _,x in ipairs{16,W-16}do G.quad(out,{xx+x,0,zz+16},{xx+x,cfg.harborWallHeight+cfg.harborRoofRise,zz+16},{xx+x,cfg.harborWallHeight,zz+48},{xx+x,0,zz+48},G.uv(ts,0x375),cfg.sideShade)end
  elseif o.kind=='portal'then
   G.quad(out,{xx,cfg.portalHeight,zz+32},{xx+W,cfg.portalHeight,zz+32},{xx+W,0,zz+32},{xx,0,zz+32},G.uv(ts,0xa7),1)
  end
 end
end
return E
