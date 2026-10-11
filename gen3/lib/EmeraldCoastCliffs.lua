-- Exact native coastal rock family; water/sand/grass remain on the ground.
local V=...
local F={}
local pairsByMap={EM_BIRTH_ISLAND_EXTERIOR='general__dewford',EM_NAVEL_ROCK_EXTERIOR='general__dewford',EM_FARAWAY_ISLAND_ENTRANCE='general__rustboro',EM_MOSSDEEP_CITY='general__mossdeep',EM_DEWFORD_TOWN='general__dewford',EM_ROUTE106='general__dewford',EM_ROUTE107='general__dewford',EM_EVER_GRANDE_CITY='general__ever_grande',EM_SOOTOPOLIS_CITY='general__sootopolis'}
-- Inland routes and Safari areas use the same reviewed native primary rock
-- palette. Keep the scope tied to the exact map/tileset pair: Fallarbor and
-- volcanic variants have different artwork and are handled elsewhere.
for _,id in ipairs{'EM_ROUTE121','EM_ROUTE122',
 'EM_SAFARI_ZONE_NORTH','EM_SAFARI_ZONE_NORTHEAST','EM_SAFARI_ZONE_NORTHWEST',
 'EM_SAFARI_ZONE_SOUTH','EM_SAFARI_ZONE_SOUTHEAST','EM_SAFARI_ZONE_SOUTHWEST'}do
 pairsByMap[id]='general__lilycove'
end
pairsByMap.EM_ROUTE103='general__petalburg'
pairsByMap.EM_ROUTE116='general__rustboro'
pairsByMap.EM_ROUTE105='general__dewford'
pairsByMap.EM_ROUTE120='general__fortree'
pairsByMap.EM_ROUTE125='general__mossdeep'
local coast={[0x157]=true,[0x15e]=true,[0x15f]=true,[0x166]=true,[0x167]=true,[0x16e]=true,[0x16f]=true}
local colors={[0xdeb5a5]=true,[0xbd948c]=true,[0xefd6ce]=true,[0x9c7373]=true,[0x845a5a]=true,[0x634252]=true}
function F.applies(d)return d and pairsByMap[d.id or d.name]==d.pair and V.require('DioramaConfig').emeraldCoastCliffs.enabled
 and((d.id or d.name)~='EM_SOOTOPOLIS_CITY'or V.require('DioramaConfig').sootopolisCrater.enabled)end
-- These four native corner cells are collision-zero pockets wholly enclosed
-- by solid rock, not walkable paths. Raise only their art, never the cells.
local everGrandeCaps={{15,33},{17,34},{22,35},{25,36}}
function F.isolatedCap(d,c)
 if not d or d.id~='EM_EVER_GRANDE_CITY' or d.pair~='general__ever_grande' or not c or c.mid~=0xbe or c.coll~=0 then return false end
 local L=d.midLayout;if not L then return false end
 for _,p in ipairs(everGrandeCaps)do if L:cellAt(p[1],p[2])==c then
  for _,n in ipairs({{-1,0},{1,0},{0,-1},{0,1}})do if L:cellAt(p[1]+n[1],p[2]+n[2]).coll~=7 then return false end end
  return true
 end end
 return false
end
function F.kind(d,c)
 if F.applies(d)and c and V.require('EmeraldEventExteriors').coast(d,c)then return 'emeraldCoast'end
 if F.applies(d)and c and(c.coll==7 or F.isolatedCap(d,c))and(c.mid>=0x68 and c.mid<=0x97 or coast[c.mid]or(d.id=='EM_EVER_GRANDE_CITY'and(c.mid==0xa9 or c.mid==0xbe or c.mid==0xbf)))then return 'emeraldCoast' end
end
local cache=setmetatable({},{__mode='k'})
local function shape(ts,m)
 local atlas=cache[ts];if not atlas then atlas={};cache[ts]=atlas end
 if atlas[m]then return atlas[m]end
 local item={mask={},rects={},edges={}};atlas[m]=item
 for y=0,15 do for x=0,15 do
  local r,g,b,a=V.require('BuildingMesh').pixel(ts,m,x,y)
  local rgb=math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)
  item.mask[y*16+x+1]=a>.5 and colors[rgb]or false
 end end
 -- Exact native UV rectangles, not hundreds of quads for a solid tile.
 local seen={}
 for y=0,15 do for x=0,15 do local k=y*16+x+1;if not seen[k]then
  local rock=item.mask[k];local x1=x+1
  while x1<16 and not seen[y*16+x1+1]and item.mask[y*16+x1+1]==rock do x1=x1+1 end
  local y1=y+1
  while y1<16 do local same=true;for xx=x,x1-1 do local q=y1*16+xx+1;if seen[q]or item.mask[q]~=rock then same=false;break end end;if not same then break end;y1=y1+1 end
  for yy=y,y1-1 do for xx=x,x1-1 do seen[yy*16+xx+1]=true end end
  item.rects[#item.rects+1]={x,y,x1,y1,rock}
 end end end
 for _,dir in ipairs({{0,1},{0,-1},{1,0},{-1,0}})do for row=0,15 do
  local runs={};local col=0
  local function candidate(c)
   local sx,sy=dir[1]==0 and c or row,dir[1]==0 and row or c
   if not item.mask[sy*16+sx+1]then return false end
   local nx,ny=sx+dir[1],sy+dir[2]
   if nx<0 or ny<0 or nx>15 or ny>15 then return true,true end
   return not item.mask[ny*16+nx+1],false
  end
  while col<16 do local yes,external=candidate(col)
   if yes then local first=col;repeat col=col+1 until col==16 or not candidate(col)
    item.edges[#item.edges+1]={dir[1],dir[2],row,first,col,external}
   else col=col+1 end
  end
 end end
 return item
end
function F.rock(ts,m,x,y)return shape(ts,m).mask[y*16+x+1]end
function F.rects(ts,m)return shape(ts,m).rects end
function F.height()return V.require('DioramaConfig').emeraldCoastCliffs.height end
function F.stamp(out,d,ts,x,y,ox,oz,cells)
 local G=V.require('WorldGeometry');local L=d.midLayout;local cfg=V.require('DioramaConfig').emeraldCoastCliffs
 local m=L:midAt(x,y);local xx,zz=(x+ox)*16,(y+oz)*16;local h=cfg.height
 local function occupied(px,py)
  local tx,ty=math.floor(px/16),math.floor(py/16)
  if tx<0 or ty<0 or tx>=L.width or ty>=L.height or cells[ty*L.width+tx+1]~='emeraldCoast'then return false end
  return F.rock(ts,L:midAt(tx,ty),px%16,py%16)
 end
 -- Partition the original tile into contiguous native UV rectangles.
 -- All non-rock pixels, including native surf and sand, stay at height zero.
 for _,r in ipairs(F.rects(ts,m))do
  local elevation=r[5]and h or 0
  G.quad(out,{xx+r[1],elevation,zz+r[2]},{xx+r[3],elevation,zz+r[2]},{xx+r[3],elevation,zz+r[4]},{xx+r[1],elevation,zz+r[4]},G.uv(ts,m,r[1],r[2],r[3],r[4],0),1)
 end
 -- Cached source contours avoid rescanning 1024 neighbours per solid tile.
 for _,run in ipairs(shape(ts,m).edges)do
  local dx,dz,row,first,last,external=unpack(run);local col=first
  local function exposed(c)
   if not external then return true end
   local sx,sy=dx==0 and c or row,dx==0 and row or c
   return not occupied(x*16+sx+dx,y*16+sy+dz)
  end
  while col<last do if exposed(col)then local begin=col;repeat col=col+1 until col==last or not exposed(col)
   local a,b,c,e
   if dx==0 then local z=zz+row+(dz>0 and 1 or 0);a={xx+begin,h,z};b={xx+col,h,z};c={xx+col,0,z};e={xx+begin,0,z}
   else local qx=xx+row+(dx>0 and 1 or 0);a={qx,h,zz+begin};b={qx,h,zz+col};c={qx,0,zz+col};e={qx,0,zz+begin}end
   G.quad(out,a,b,c,e,G.uv(ts,0x79,begin,.5,col,14.5,0),cfg.sideShade)
  else col=col+1 end end
 end
end
return F
