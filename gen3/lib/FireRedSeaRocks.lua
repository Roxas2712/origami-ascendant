-- Native sea-rock quarters: water/foam stay flat, only stone is lifted.
local V=...
local R={}
local families={
 [0x110]={0x110,0x111,0x118,0x119},
 [0x1cb]={0x1cb,0x1cc,0x1d3,0x1d4},
 [0x212]={0x212,0x213,0x21a,0x21b},
 -- Render-template keys, not map metatile IDs. Five Island also combines
 -- the two native rock families vertically; keep every original quarter UV.
 [0x10110]={0x110,0x111,0x21a,0x21b},
 [0x10212]={0x212,0x213,0x118,0x119},
 -- Whole native stones beside a cliff/pier or sandy shore. Preserve the
 -- right-hand shore artwork; it is not part of the raised stone silhouette.
 [0x20110]={0x110,0x113,0x118,0x11b},
 [0x20212]={0x212,0x113,0x21a,0x11b},
 [0x30110]={0x110,0x201,0x118,0x209},
 [0x40110]={0x110,0x111,0x2b6,0x2b7},
 [0x50110]={0x110,0x111,0x281,0x282},
}
-- Intersection of original stone pixels over all eight native water frames.
-- Measured identically in Water Labyrinth, Vermilion and Cinnabar atlases.
local stable={
 [0x110]={
 [8]={16,18},
 [9]={13,19},
 [10]={12,19},
 [11]={11,22},
 [12]={10,22},
 [13]={9,22},
 [14]={8,21},
 [15]={8,8,11,21},
 [16]={10,22},
 [17]={10,22},
 [18]={9,23},
 [19]={10,21},
 [20]={19,20},
 },
 [0x1cb]={
 [8]={16,19},
 [9]={14,20},
 [10]={13,21},
 [11]={11,21},
 [12]={9,22},
 [13]={8,23},
 [14]={8,23},
 [15]={8,23},
 [16]={8,23},
 [17]={8,23},
 [18]={8,23},
 [19]={8,23},
 [20]={9,22},
 [21]={9,22},
 [22]={10,21},
 [23]={12,19},
 },
}
stable[0x212]=stable[0x110]
stable[0x10110]=stable[0x110];stable[0x10212]=stable[0x110]
stable[0x20110]=stable[0x110];stable[0x20212]=stable[0x110];stable[0x30110]=stable[0x110]
stable[0x40110]=stable[0x110]
-- The gym roof covers the lower stone from native row 17 onward. Never
-- lift that roof ink as a rock face, even when its grey trim shares colours.
stable[0x50110]={}
for y,runs in pairs(stable[0x110])do if y<17 then stable[0x50110][y]=runs end end
local roofFamilies={[0x40110]=true,[0x50110]=true}
-- Exact native footprints: these two roofs include water/rock in their
-- source rectangles. Other buildings and script-replaced artwork stay alone.
function R.roof(b,L)
 local y=math.max(0,b.y0-1)
 local kind,row
 if b.mapId=='FR_VERMILION_CITY'and (b.renderPair or b.pair)=='general__rom_082d4b24'
  and L.width==48 and L.height==40 and b.x0==8 and b.x1==12 and b.y0==3 and b.y1==6 then
  kind=0x40110;row={0x2b6,0x2b7,0x2a1,0x2a1,0x2a2}
  for x,m in ipairs{0x110,0x111,0x12b,0x12b,0x12b}do if L:midAt(b.x0+x-1,y)~=m then return end end
  y=y+1
 elseif b.mapId=='FR_CINNABAR_ISLAND'and (b.renderPair or b.pair)=='general__rom_082d4b6c'
  and L.width==24 and L.height==20 and b.x0==17 and b.x1==22 and b.y0==1 and b.y1==4 then
  kind=0x50110;row={0x281,0x282,0x283,0x283,0x283,0x284}
 else return end
 for x,m in ipairs(row)do if L:midAt(b.x0+x-1,y)~=m then return end end
 return kind
end
local yellowRoofEdge={26,25,24,24,24,24,25,26}
function R.roofBackdrop(kind,x,y)
 if kind==0x40110 then
  -- Scalloped yellow roof: preserve its one-pixel grey outline.
  return y<yellowRoofEdge[x%8+1]
 elseif kind==0x50110 then
  return y<math.max(1,4-x,x-91)
 end
 return false
end
-- First dry pixel in each 32px row, measured against all eight native water
-- frames. Use the widest land extent: an advancing wave must never give the
-- sand or cliff pixels the water displacement/reflection material.
local shoreEdge={29,28,28,28,28,28,28,28,28,28,28,28,28,28,28,29,
 29,28,28,28,28,28,28,28,28,28,28,28,28,28,28,29}
local sandEdge={26,26,27,27,27,27,27,26,26,26,27,27,27,27,27,26,
 26,26,27,27,27,27,27,26,26,26,27,27,27,27,27,26}
local dryEdges={[0x20110]=shoreEdge,[0x20212]=shoreEdge,[0x30110]=sandEdge}
local legacy={SEVII_ONE_ISLAND=true,SEVII_ONE_ISLAND_KINDLE_ROAD=true,SEVII_ONE_ISLAND_TREASURE_BEACH=true}
function R.applies(d)
 return d and (tostring(d.id or d.name):match('^FR_')or legacy[d.id or d.name])
  and tostring((d.renderPair or d.pair)):match('^general__')and V.data('Shapes').outdoors(d)and V.require('DioramaConfig').seaRocks.enabled
end
function R.plan(d)
 local mask={};if not R.applies(d)then return mask end
 local L=d.midLayout
 -- Four native stones straddle connected maps. The north/west map owns
 -- one complete mesh; the other map consumes only its original quarters.
 -- Like cross-map crowns, this keeps one continuous object in either view.
 local function joined(map,dir,offset,x,y,rows,passive)
  local connected=false
  for _,c in ipairs(d.connections or{})do
   if c.map==map and c.dir==dir and c.offset==offset then connected=true;break end
  end
  if not connected then return end
  for dy,row in ipairs(rows)do for dx,mid in ipairs(row)do
   local xx,yy=x+dx-1,y+dy-1
   if xx<0 or yy<0 or xx>=L.width or yy>=L.height then return end
   local c=L:cellAt(xx,yy)
   if c.mid~=mid or(c.coll~=7 and not V.data('Shapes').water(c))then return end
  end end
  local p={x=x,y=y,mid=0x110,seam=true,columns=#rows[1],rows=#rows,passive=passive or nil}
  for dy,row in ipairs(rows)do for dx in ipairs(row)do mask[(y+dy-1)*L.width+x+dx]=p end end
 end
 local id=d.id or d.name
 if (d.renderPair or d.pair)=='general__rom_082d5064'then
  if id=='FR_FIVE_ISLAND_MEADOW'and L.width==24 and L.height==40 then
   joined('FR_FIVE_ISLAND_MEMORIAL_PILLAR','east',20,23,22,{{0x110},{0x118}})
   joined('FR_FIVE_ISLAND_MEMORIAL_PILLAR','east',20,23,33,{{0x110},{0x118}})
  elseif id=='FR_FIVE_ISLAND_MEMORIAL_PILLAR'and L.width==24 and L.height==60 then
   joined('FR_FIVE_ISLAND_MEADOW','west',-20,0,2,{{0x111},{0x119}},true)
   joined('FR_FIVE_ISLAND_MEADOW','west',-20,0,13,{{0x111},{0x119}},true)
  elseif id=='FR_FIVE_ISLAND_RESORT_GORGEOUS'and L.width==72 and L.height==20 then
   joined('FR_FIVE_ISLAND_WATER_LABYRINTH','south',-48,3,19,{{0x110,0x111}})
  elseif id=='FR_FIVE_ISLAND_WATER_LABYRINTH'and L.width==72 and L.height==20 then
   joined('FR_FIVE_ISLAND_RESORT_GORGEOUS','north',48,51,0,{{0x118,0x119}},true)
  end
 elseif (d.renderPair or d.pair)=='general__rom_082d507c'then
  if id=='FR_SIX_ISLAND_OUTCAST_ISLAND'and L.width==24 and L.height==80 then
   joined('FR_SIX_ISLAND_GREEN_PATH','south',0,12,79,{{0x110,0x111}})
  elseif id=='FR_SIX_ISLAND_GREEN_PATH'and L.width==72 and L.height==20 then
   joined('FR_SIX_ISLAND_OUTCAST_ISLAND','north',0,12,0,{{0x118,0x119}},true)
  end
 end
 -- Only the northern water cells belong to the rock floor. The building
 -- owns the remaining pixels, with an exact water/roof boundary below.
 if id=='FR_VERMILION_CITY'and R.roof({mapId=id,pair=(d.renderPair or d.pair),x0=8,x1=12,y0=3,y1=6},L)then
  local p={x=8,y=2,mid=0x40110};mask[2*L.width+9]=p;mask[2*L.width+10]=p
 elseif id=='FR_ROUTE_21_SOUTH'and (d.renderPair or d.pair)=='general__rom_082d4b6c'and L.width==24 and L.height==50 then
  joined('FR_CINNABAR_ISLAND','south',0,17,49,{{0x110,0x111}})
  local p=mask[49*L.width+18];if p then p.mid=0x50110 end
 end
 for y=0,L.height-2 do for x=0,L.width-2 do
  local mid=L:midAt(x,y)
  if (d.renderPair or d.pair)=='general__rom_082d5064'then
   if mid==0x110 and L:midAt(x,y+1)==0x21a then mid=0x10110
   elseif mid==0x212 and L:midAt(x,y+1)==0x118 then mid=0x10212 end
  end
  if mid==0x110 and L:midAt(x+1,y)==0x113 then mid=0x20110
  elseif mid==0x212 and (d.renderPair or d.pair)=='general__rom_082d5064'and L:midAt(x+1,y)==0x113 then mid=0x20212
  elseif mid==0x110 and (d.renderPair or d.pair)=='general__rom_082d507c'and L:midAt(x+1,y)==0x201 then mid=0x30110 end
  local f=families[mid]
  if f and (mid~=0x212 or (d.renderPair or d.pair)=='general__rom_082d5064')then
   local match=true
   for j,m in ipairs(f)do local c=L:cellAt(x+(j-1)%2,y+math.floor((j-1)/2))
    -- Native sea rocks are solid (7), while some imported fixtures retain
    -- surfable water behavior (41). Artwork owns the render grouping only;
    -- neither collision value is rewritten or used to make rocks traversable.
    if c.mid~=m or(c.coll~=7 and not V.data('Shapes').water(c))then match=false;break end
   end
   if match then local p={x=x,y=y,mid=mid}
    for j=0,3 do mask[(y+math.floor(j/2))*L.width+x+j%2+1]=p end
   end
  end
 end end
 return mask
end
local cache=setmetatable({},{__mode='k'})
function R.source(mid,x,y)return families[mid][math.floor(y/16)*2+math.floor(x/16)+1],x%16,y%16 end
function R.mask(ts,mid)
 local byMid=cache[ts];if not byMid then byMid={};cache[ts]=byMid end
 if byMid[mid]then return byMid[mid]end
 local q={};for k=1,1024 do q[k]=false end
 for y,runs in pairs(stable[mid])do for i=1,#runs,2 do for x=runs[i],runs[i+1]do q[y*32+x+1]=true end end end
 byMid[mid]=q;return q
end
local function inside(q,x,y)return x>=0 and y>=0 and x<32 and y<32 and q[y*32+x+1]end
function R.template(ts,mid)
 local q=R.mask(ts,mid);local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').seaRocks
 if mid==0x1cb then
  local out=V.require('PaperSprite').build(ts,32,32,function(x,y)return R.source(mid,x,y)end,
   function(x,y)return inside(q,x,y)end,0,24,cfg.uprightScale,nil,nil,.5)
  for _,v in ipairs(out)do v[3]=v[3]+24;v[8]=v[8]+24 end
  return out
 end
 local out={};local h=cfg.slabHeight
 local function face(a,b,c,d,x,y,w,hh,shade)
  local m,sx,sy=R.source(mid,x,y);G.quad(out,a,b,c,d,G.uv(ts,m,sx,sy,sx+w,sy+hh,.5),shade)
 end
 for y=0,31 do local x=0
  while x<32 do
   if inside(q,x,y)then local start=x
    repeat x=x+1 until x==32 or x%16==0 or not inside(q,x,y)
    face({start,h,y},{x,h,y},{x,h,y+1},{start,h,y+1},start,y,x-start,1,1)
   else x=x+1 end
  end
 end
 -- Tiny native contours need no faces between neighboring stone pixels.
 for y=0,31 do for x=0,31 do if inside(q,x,y)then
  if not inside(q,x,y+1)then face({x,h,y+1},{x+1,h,y+1},{x+1,0,y+1},{x,0,y+1},x,y,1,1,cfg.sideShade)end
  if not inside(q,x,y-1)then face({x+1,h,y},{x,h,y},{x,0,y},{x+1,0,y},x,y,1,1,cfg.sideShade)end
  if not inside(q,x-1,y)then face({x,h,y},{x,h,y+1},{x,0,y+1},{x,0,y},x,y,1,1,cfg.sideShade)end
  if not inside(q,x+1,y)then face({x+1,h,y+1},{x+1,h,y},{x+1,0,y},{x+1,0,y+1},x,y,1,1,cfg.sideShade)end
 end end end
 return out
end
function R.floor(ts,mid)
 local q=R.mask(ts,mid);if q.floor then return q.floor end
 local G=V.require('WorldGeometry');local out={}
 local edge=dryEdges[mid]
 local function material(x,y)return edge and x>=edge[y+1]and 1 or G.WATER end
 -- Merge equal stone/material rectangles inside each metatile. Foam keeps
 -- its original animated UV; dry shoreline ink never gets water shading.
 for tile=0,roofFamilies[mid]and 1 or 3 do local used={};local ox,oz=tile%2*16,math.floor(tile/2)*16
  for y=0,15 do for x=0,15 do if not used[y*16+x+1]then
   local stone=inside(q,x+ox,y+oz);local shade=material(x+ox,y+oz);local w,h=1,1
   while x+w<16 and not used[y*16+x+w+1]and inside(q,x+w+ox,y+oz)==stone and material(x+w+ox,y+oz)==shade do w=w+1 end
   while y+h<16 do local row=true
    for dx=0,w-1 do if used[(y+h)*16+x+dx+1]or inside(q,x+dx+ox,y+h+oz)~=stone or material(x+dx+ox,y+h+oz)~=shade then row=false;break end end
    if not row then break end;h=h+1
   end
   for dy=0,h-1 do for dx=0,w-1 do used[(y+dy)*16+x+dx+1]=true end end
   local donor=stone and 0x1d9 or families[mid][tile+1]
   G.quad(out,{x+ox,0,y+oz},{x+w+ox,0,y+oz},{x+w+ox,0,y+h+oz},{x+ox,0,y+h+oz},G.uv(ts,donor,x,y,x+w,y+h,.5),shade)
  end end end
 end
 q.floor=out;return out
end
function R.buildingFloor(out,b,L,ts,x,y,ox,oz,kind)
 local G=V.require('WorldGeometry');local bx=(x-b.x0)*16
 local by=(y-math.max(0,b.y0-1))*16;local q=R.mask(ts,kind)
 if by>=(kind==0x40110 and 26 or 4)then
  local xx,zz=(x+ox)*16,(y+oz)*16
  G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,b.ground or 1),1)
  return
 end
 local function donor(px,py)
  if not R.roofBackdrop(kind,bx+px,by+py)then return b.ground or 1,1 end
  local ry=by+py+(kind==0x50110 and 16 or 0)
  if bx+px<32 and ry<32 and q[ry*32+bx+px+1]then return 0x1d9,G.WATER end
  return L:midAt(x,y),G.WATER
 end
 for py=0,15 do local px=0
  while px<16 do
   local m,shade=donor(px,py);local start=px;px=px+1
   while px<16 do local mm,ss=donor(px,py);if mm~=m or ss~=shade then break end;px=px+1 end
   local xx,zz=(x+ox)*16,(y+oz)*16
   G.quad(out,{xx+start,0,zz+py},{xx+px,0,zz+py},{xx+px,0,zz+py+1},{xx+start,0,zz+py+1},G.uv(ts,m,start,py,px,py+1,.5),shade)
  end
 end
end
function R.place(out,ts,p,ox,oz,instances,contacts)
 local G=V.require('WorldGeometry');local x,z=(p.x+ox)*16,(p.y+oz)*16
 for _,v in ipairs(R.floor(ts,p.mid))do out[#out+1]=G.place(v,x,z,1)end
 if instances then local key='seaRock:'..p.mid;local group=instances.props[key]
  if not group then group={mid=p.mid,kind='seaRock',ground=0x1d9,placements={}};instances.props[key]=group end
  group.placements[#group.placements+1]={x,z,1}
 else V.require('Props').stamp(out,ts,p.mid,'seaRock',x,z,0x1d9)end
 local c=V.require('DioramaConfig').contact;contacts[#contacts+1]={x+16,z+21,7,3,c.strength*.6}
end
return R
