local V = ...
local Budget=V.require('BuildBudget')
local Shapes = V.data("Shapes")
-- VertexShade: 2/3 are facade glass; 10–14 belong to Silph/gate cutaway
-- surfaces. Lava must not share their deformation or pixel-snap dispatch.
local Geometry = {WATER=4,BUILDING_ROOF=6,ROOM_VOID=7,HANGING_FACADE=8,ELECTRIC_BEAM=9,ELECTRIC_BEAM_FR=9.2,MAGMA_LAVA=15}
local neighborX,neighborY={-1,1,0,0},{0,0,-1,1}
local function decorativeSea(def,mid)
  return (def.id or def.name)=='FR_SIX_ISLAND'
    and (def.renderPair or def.pair)=='general__rom_082d507c' and mid==0x276
end
local function waterMaterial(def,cell)
  -- The solid decorative sea uses the adjoining border's animated donor,
  -- lighting and reflections, while native movement remains blocked.
  return Shapes.water(cell) or decorativeSea(def,cell.mid)
end
Geometry.FORMAT={{"VertexPosition","float",3},{"VertexTexCoord","float",2},{"VertexShade","float",1},{"BillboardAnchor","float",3}}

local function quad(out,a,b,c,d,uv,shade)
  Budget.tick()
  -- Keep six independent vertices, without eight temporary tables per quad.
  -- Large native facades emit thousands of these during a map transition.
  local n=#out;shade=shade or 1
  out[n+1]={a[1],a[2],a[3],uv[1],uv[2],shade,a[4]or 0,a[5]or 0,a[6]or 0}
  out[n+2]={b[1],b[2],b[3],uv[3],uv[2],shade,b[4]or 0,b[5]or 0,b[6]or 0}
  out[n+3]={c[1],c[2],c[3],uv[3],uv[4],shade,c[4]or 0,c[5]or 0,c[6]or 0}
  out[n+4]={a[1],a[2],a[3],uv[1],uv[2],shade,a[4]or 0,a[5]or 0,a[6]or 0}
  out[n+5]={c[1],c[2],c[3],uv[3],uv[4],shade,c[4]or 0,c[5]or 0,c[6]or 0}
  out[n+6]={d[1],d[2],d[3],uv[1],uv[4],shade,d[4]or 0,d[5]or 0,d[6]or 0}
end
Geometry.quad=quad
function Geometry.place(v,x,z,scale)
 scale=scale or 1
 return {v[1]*scale+x,v[2]*scale,v[3]*scale+z,v[4],v[5],v[6],
   (v[7]or 0)*scale+x,(v[8]or 0)*scale+z,v[9]or 0}
end
function Geometry.uv(ts,mid,x0,y0,x1,y1,inset)
  -- In play, script-placed metatiles (setmetatile) may be absent from the
  -- packed atlas; the engine's own renderer falls back to metatile 0, so do we.
  local slot=ts.midToSlot[mid] or (Geometry.lenient and ts.midToSlot[0])
  if not slot then error(string.format("Missing native metatile %03x in %s",mid,tostring(ts.pair))) end
  local x,y=slot%ts.cols*16,math.floor(slot/ts.cols)*16
  local w,h=ts.image:getDimensions()
  inset=inset or .02
  return {(x+(x0 or 0)+inset)/w,(y+(y0 or 0)+inset)/h,
    (x+(x1 or 16)-inset)/w,(y+(y1 or 16)-inset)/h}
end
local function top(out,x,z,w,d,y,uv,shade)
  quad(out,{x,y,z},{x+w,y,z},{x+w,y,z+d},{x,y,z+d},uv,shade)
end
-- A building is a bounded connected body of secondary solid metatiles with
-- a real exterior door. Primary forest/cliff tiles cannot join the component.
-- Door coordinates remain exactly where the game's warp event expects them.
function Geometry.buildings(def)
  local L=def.midLayout
  local found,mask={},{}
  if (def.id or def.name)=='EM_SKY_PILLAR_OUTSIDE'and V.require('EmeraldSkyPillar').profile(def)then return found,mask end
  if not L or not Shapes.outdoors(def) or V.require("FireRedDepartmentRoof").profile(def) or V.require("TrainerTowerRoof").profile(def) then return found,mask end
  local function key(x,y)return y*L.width+x+1 end
  local specs={}
  for _,b in ipairs(V.data('LandmarkBounds')[def.id or def.name]or{})do specs[#specs+1]=b end
  for _,b in ipairs(V.require('EmeraldSootopolisHouses').buildings(def))do specs[#specs+1]=b end
  for _,b in ipairs(V.require('EmeraldSpaceCenterExterior').buildings(def))do specs[#specs+1]=b end
  for _,b in ipairs(V.require('EmeraldSlateportExterior').buildings(def))do specs[#specs+1]=b end
  for _,b in ipairs(V.require('EmeraldTownLandmarks').buildings(def))do specs[#specs+1]=b end
  for _,b in ipairs(V.require('EmeraldTallLandmarks').buildings(def))do specs[#specs+1]=b end
  for _,b in ipairs(V.require('EmeraldLilycoveMuseum').buildings(def))do specs[#specs+1]=b end
  for _,spec in ipairs(specs)do
   if spec.x0>=0 and (spec.y0>0 or spec.y0==0 and tostring(def.id or def.name):match('^FR_')) and spec.x1<L.width and spec.y1<L.height then
    local b={pair=(def.renderPair or def.pair)}
    for k,v in pairs(spec)do b[k]=v end
    b.ground=b.ground or L:midAt(b.doorX,math.min(L.height-1,b.doorY+1))
    found[#found+1]=b
    for cy=b.y0,b.y1 do for cx=b.x0,b.x1 do mask[key(cx,cy)]=b end end
    if b.y0>0 then for cx=b.x0,b.x1 do mask[key(cx,b.y0-1)]=b end end
   end
  end
  local family,leftBound,rightBound
  local function body(x,y)
    if x<0 or y<0 or x>=L.width or y>=L.height then return false end
    local c=L:cellAt(x,y)
    return not mask[key(x,y)] and Shapes.architecture(def,c.mid) and Shapes.solid(c)
      and not Shapes.tree(c.mid,def) and not Shapes.prop(def,c)
      and (not family or Shapes.architectureFamily(def,c.mid)==family)
      and (not leftBound or x>=leftBound and x<=rightBound)
  end
  for _,warp in ipairs(def.warps or {}) do
    local x,y=warp.x,warp.y
    family,leftBound,rightBound=nil,nil,nil
    if x and y and y>=2 and not mask[key(x,y)] and body(x,y-1) then
      family=Shapes.architectureFamily(def,L:midAt(x,y-1))
      -- Adjacent buildings may touch in the ROM image. A flood over every
      -- architectural tile used to fuse their facades into one giant roof.
      local lo,hi=x,x
      local cerulean=(def.renderPair or def.pair)=="general__rom_082d4af4" and family=="secondary"
      while lo>0 and body(lo-1,y-1) and not (cerulean and L:midAt(lo,y-1)==0x2b0)do lo=lo-1 end
      while hi<L.width-1 and body(hi+1,y-1) and not (cerulean and L:midAt(hi,y-1)==0x2b2)do hi=hi+1 end
      -- Shared native Hoenn roofs give exact footprints. Adjacent red houses
      -- touch, while some gyms replace the right facade cell with a local
      -- sign tile; a single horizontal body scan cannot bound either safely.
      if family=='hoenn_primary_house'and L:midAt(x-1,y-2)==0x10 and L:midAt(x+2,y-2)==0x12 then lo,hi=x-1,x+2
      elseif family=='hoenn_gym'and L:midAt(x-3,y-3)==0x1b2 and L:midAt(x+2,y-3)==0x1b4 then lo,hi=x-3,x+2 end
      leftBound,rightBound=lo,hi
      -- Parallel coordinate arrays retain traversal order and the 1024-entry
      -- guard without allocating a coordinate/direction table per neighbor.
      local queueX,queueY,seen={x},{y-1},{}
      local b={pair=(def.renderPair or def.pair),x0=x,x1=x,y0=y-1,y1=y,doorX=x,doorY=y}
      local i=1
      while queueX[i] and i<1024 do
        local px,py=queueX[i],queueY[i];i=i+1
        local k=key(px,py)
        if not seen[k] and body(px,py) then
          seen[k]=true
          b.x0=math.min(b.x0,px);b.x1=math.max(b.x1,px)
          b.y0=math.min(b.y0,py);b.y1=math.max(b.y1,py)
          for d=1,4 do local n=#queueX+1;queueX[n],queueY[n]=px+neighborX[d],py+neighborY[d] end
        end
      end
      local w,h=b.x1-b.x0+1,b.y1-b.y0+1
      if i<1024 and w>=3 and w<=28 and h>=3 and h<=24 and b.y1==y then
        b.ground=L:midAt(x,math.min(L.height-1,y+1))
        found[#found+1]=b
        for cy=b.y0,b.y1 do for cx=b.x0,b.x1 do mask[key(cx,cy)]=b end end
        -- Native roof trim occupies the walkable row just behind the body.
        -- Remove that flat duplicate; the roof now carries its upper trim.
        for cx=b.x0,b.x1 do
          if b.y0>0 and Shapes.architecture(def,L:midAt(cx,b.y0-1)) then mask[key(cx,b.y0-1)]=b end
        end
      end
    end
  end
  -- Decorative city houses have no warp. Lift dense architectural bodies
  -- too, while rejecting thin fence runs and keeping routes/rock fields out.
  local city=({FR_PALLET_TOWN=true,FR_VIRIDIAN_CITY=true,FR_PEWTER_CITY=true,
    FR_CERULEAN_CITY=true,FR_VERMILION_CITY=true,FR_LAVENDER_TOWN=true,
    FR_CELADON_CITY=true,FR_FUCHSIA_CITY=true,FR_SAFFRON_CITY=true,
    FR_CINNABAR_ISLAND=true,FR_INDIGO_PLATEAU_EXTERIOR=true})[def.id or def.name]
  if city then
    local seen={}
    local function eligible(x,y)
      if x<0 or y<0 or x>=L.width or y>=L.height or mask[key(x,y)]then return false end
      local c=L:cellAt(x,y)
      return Shapes.solid(c) and Shapes.architecture(def,c.mid)
        and not Shapes.tree(c.mid,def) and not Shapes.prop(def,c)
    end
    for y=0,L.height-1 do Budget.check();for x=0,L.width-1 do
      if not seen[key(x,y)] and eligible(x,y)then
        local pointsX,pointsY={x},{y};seen[key(x,y)]=true
        local i,x0,x1,y0,y1=1,x,x,y,y
        while pointsX[i]do
          local px,py=pointsX[i],pointsY[i];i=i+1
          x0,x1,y0,y1=math.min(x0,px),math.max(x1,px),math.min(y0,py),math.max(y1,py)
          for d=1,4 do
            local xx,yy=px+neighborX[d],py+neighborY[d];local k=key(xx,yy)
            if not seen[k] and eligible(xx,yy)then seen[k]=true;local n=#pointsX+1;pointsX[n],pointsY[n]=xx,yy end
          end
        end
        local w,h=x1-x0+1,y1-y0+1
        if w>=3 and w<=28 and h>=2 and h<=18 and #pointsX/(w*h)>=.72 then
          local ground=L:midAt(math.floor((x0+x1)/2),math.min(L.height-1,y1+1))
          local c=L:cellAt(math.floor((x0+x1)/2),math.min(L.height-1,y1+1))
          if Shapes.solid(c)then
            for _,px in ipairs(pointsX)do
              local below=L:cellAt(px,math.min(L.height-1,y1+1))
              if not Shapes.solid(below)then ground=below.mid;break end
            end
          end
          local b={pair=(def.renderPair or def.pair),x0=x0,x1=x1,y0=y0,y1=y1,ground=ground,renderOnly=true}
          found[#found+1]=b
          for yy=y0,y1 do for xx=x0,x1 do mask[key(xx,yy)]=b end end
          for xx=x0,x1 do if y0>0 and Shapes.architecture(def,L:midAt(xx,y0-1))then mask[key(xx,y0-1)]=b end end
        end
      end
    end end
  end
  for _,b in ipairs(found)do b.mapId=def.id or def.name
    if b.mapId=="EM_FORTREE_CITY"and b.ground==0xc7 and V.require("DioramaConfig").fortreeArchitecture.enabled then b.fortreeArchitecture=V.require("DioramaConfig").fortreeArchitecture end end
  -- Rectangular building bounds can contain native trees, shrubs and signs
  -- (museum frontage, roof backdrops). Return those cells to their own pass.
  local fireRed=tostring(def.id or def.name):match('^FR_')
  for _,b in ipairs(found)do
   -- Include the extra source row even when it was never in the body mask.
   -- Otherwise a real tree renders normally AND as a duplicate on the roof.
   for y=math.max(0,b.y0-1),b.y1 do for x=b.x0,b.x1 do
    local k=key(x,y);local cell=L:cellAt(x,y)
    local nativeProp=fireRed and (Shapes.tree(cell.mid,def) or Shapes.prop(def,cell))
    if nativeProp or V.require('FireRedStandingProps').profile(def,cell.mid)then
     b.detachedProps=b.detachedProps or {};b.detachedProps[k]=true
     if mask[k]==b then mask[k]=nil end
    end
   end end
  end
  return found,mask
end


-- Atlases contain only native metatiles used by a tileset pair. A grass
-- donor from Pallet is absent on Cinnabar and in Berry Forest. Recover a
-- real walkable ground donor from this map instead of sampling atlas slot 0.
function Geometry.ground(def,ts)
  if V.require("EmeraldAshRoute").applies(def) and ts.midToSlot[0x218]then return 0x218 end
  if ts.midToSlot[1] then return 1 end
  if tonumber(def.mapType)==4 and Shapes.prop(def,{mid=0x282,coll=7})=="rock" and ts.midToSlot[0x281]then return 0x281 end
  local counts,best,n={},nil,0
  local L=def.midLayout
  for y=0,L.height-1 do Budget.check();for x=0,L.width-1 do
    local c=L:cellAt(x,y)
    if c.mid~=0 and c.coll==0 and ts.midToSlot[c.mid]
      and not Shapes.tree(c.mid,def) and not Shapes.prop(def,c) then
      counts[c.mid]=(counts[c.mid] or 0)+1
      if counts[c.mid]>n then best,n=c.mid,counts[c.mid] end
    end
  end end
  return best or L:midAt(0,0)
end

-- Native layout revisions invalidate the paper geometry and rain cover.
local layoutStamps=setmetatable({},{__mode='k'})
function Geometry.layoutStamp(L)
 local overrides=L.overrides or {};local previous=layoutStamps[L]
 if previous then
  local count,unchanged=0,true
  for k,c in pairs(overrides)do
   count=count+1;local saved=previous.cells[k]
   if not saved or saved[1]~=(c.mid or -1)or saved[2]~=(c.coll or -1)or saved[3]~=(c.elev or -1)then unchanged=false;break end
  end
  -- Compare values, not just table identity: native scripts can replace cells
  -- or mutate them in place. Unchanged repeated height queries avoid sorting
  -- and allocating the same signature hundreds of times in a single frame.
  if unchanged and count==previous.count then return previous.stamp end
 end
 local keys={};for k in pairs(overrides)do keys[#keys+1]=k end
 table.sort(keys)
 local values,cells={},{}
 for _,k in ipairs(keys)do
  local c=overrides[k];cells[k]={c.mid or -1,c.coll or -1,c.elev or -1}
  values[#values+1]=table.concat({k,c.mid or -1,c.coll or -1,c.elev or -1},":")
 end
 local stamp=table.concat(values,";")
 layoutStamps[L]={cells=cells,count=#keys,stamp=stamp}
 return stamp
end

function Geometry.heightfield(vertices,scale)
 scale=scale or 1
 local field={}
 for i=1,#vertices,6 do
  Budget.tick()
  local a=vertices[i];local x0,x1,z0,z1,h=a[1],a[1],a[3],a[3],a[2]
  for j=i+1,i+5 do local v=vertices[j]
   local x,y,z=v[1],v[2],v[3]
   if x<x0 then x0=x end;if x>x1 then x1=x end
   if z<z0 then z0=z end;if z>z1 then z1=z end
   if y>h then h=y end
  end
  if(a[9]or 0)>0 then
   local radius=math.max(math.abs(x0-a[7]),math.abs(x1-a[7]))
   x0,x1,z0,z1=a[7]-radius,a[7]+radius,math.min(z0,a[8]-radius),math.max(z1,a[8]+radius)
  end
  x0,x1,z0,z1,h=x0*scale,x1*scale,z0*scale,z1*scale,h*scale
  if h>1 then
   local cx0,cx1=math.floor(x0/8),math.max(math.floor(x0/8),math.ceil(x1/8)-1)
   local cz0,cz1=math.floor(z0/8),math.max(math.floor(z0/8),math.ceil(z1/8)-1)
   for z=cz0,cz1 do
    Budget.tick()
    local row=field[z] or {};field[z]=row
    for x=cx0,cx1 do if not row[x]or row[x]<h then row[x]=h end end
   end
  end
 end
 return field
end
function Geometry.mergeHeightfield(field,source,x,z)
 -- A native trunk foot can lie between eight-pixel obstruction cells.
 -- Cover every destination cell touched by the translated source cell;
 -- exact grid-aligned placements retain their original single-cell coverage.
 local x0,x1=math.floor(x/8),math.ceil(x/8)
 local z0,z1=math.floor(z/8),math.ceil(z/8)
 for sz,row in pairs(source)do for dz=z0,z1 do
  Budget.tick()
  local target=field[sz+dz]or{};field[sz+dz]=target
  for sx,h in pairs(row)do for dx=x0,x1 do
   target[sx+dx]=math.max(target[sx+dx]or 0,h)
  end end
 end end
end
function Geometry.blocked(field,x,y,z)
 local row=field[math.floor(z/8)]
 return row and y<(row[math.floor(x/8)] or 0)+1 or false
end

function Geometry.build(def,ts,ox,oz,treeInstances,preserveRows)
  ox,oz=ox or 0,oz or 0
  local L=assert(def.midLayout)
  local deck,deckStats=V.require('EmeraldWreckDeck').build(def,ts,ox,oz)
  if deck then return deck,deckStats end
  local sky,skyStats=V.require('EmeraldSkyPillar').build(def,ts,ox,oz)
  if sky then return sky,skyStats end
  local outdoor=Shapes.outdoors(def)
  if not V.require('DioramaConfig').billboards.enabled then
   local out={}
   for y=0,L.height-1 do Budget.check();for x=0,L.width-1 do
    local c=L:cellAt(x,y);top(out,(x+ox)*16,(y+oz)*16,16,16,0,Geometry.uv(ts,decorativeSea(def,c.mid)and 0x12b or c.mid),waterMaterial(def,c)and Geometry.WATER or 1)
   end end
   return out,{contacts={},lights={},buildings=0,trees=0,cells=L.width*L.height,vertices=#out,terrainCells=0}
  end
  local buildings,mask=Geometry.buildings(def)
  local qualityProps=V.require('FireRedQualityProps').plan(def)
  local trees,treeMask={},{}
  if outdoor then trees,treeMask=V.require("Trees").groups(L,def,preserveRows) end
  local furniture,furnitureMask=V.require("Furniture").plan(def)
  V.require('EmeraldSkyPillar').exteriorMask(def,furnitureMask)
  local pacifidlogMask={};V.require('EmeraldPacifidlog').mask(def,pacifidlogMask)
  local fortreeMask={};V.require('EmeraldFortreeArchitecture').mask(def,fortreeMask)
  local eventIslands=V.require('EmeraldEventExteriors').plan(def)
  local underwater=V.require('EmeraldUnderwater').plan(def)
  local ground=Geometry.ground(def,ts)
  local mapView=(V.require('DioramaConfig').mapViews or {})[def.id or def.name]
  if not outdoor then
    local counts,best={},0
    for _,donor in pairs(furnitureMask)do
      local m=type(donor)=="table" and donor.mid or donor
      if m~=0 and ts.midToSlot[m] then counts[m]=(counts[m]or 0)+1;if counts[m]>best then best=counts[m];ground=m end end
    end
  end
  local terrain=V.require("Terrain").plan(def,mask)
  local originObjects=V.require('EmeraldOriginObjects').plan(def)
  local caveObjects=V.require('EmeraldCaveObjects').plan(def)
  local stalagmites=V.require('EmeraldCaveStalagmites').plan(def)
  local rainforest=V.require('EmeraldRainforest').plan(def)
  local ash=V.require('EmeraldAshRoute').plan(def)
  local fallarbor=V.require('EmeraldFallarborTrees').plan(def)
  local compact=V.require('EmeraldCompactForest').plan(def)
  local mossdeep=V.require('EmeraldMossdeepTrees').plan(def)
  local safari=V.require('FireRedSafari').plan(def)
  local sea=V.require('FireRedSeaRocks');local seaRocks=sea.plan(def)
  local coastalRoofs={};for _,b in pairs(mask)do if coastalRoofs[b]==nil then coastalRoofs[b]=sea.roof(b,L)or false end end
  local fountain=V.require('FireRedCeladonFountain').active(def)
  local market=V.require('EmeraldSlateportMarket').plan(def)
  local crater=V.require('EmeraldSootopolisCrater').plan(def,mask)
  local out={}
  local contacts={}
  local contact=V.require("DioramaConfig").contact
  -- Outdoor/cave continuation is a bounded, camera-sized WorldBorder mesh.
  local function treeAt(x,z,small,forest)
    local scale=small and .5 or 1
    contacts[#contacts+1]={x,z,contact.treeRadius[1]*scale,contact.treeRadius[2]*scale,contact.treeStrength}
    if treeInstances then treeInstances.trees[#treeInstances.trees+1]={x,z,small and .5 or 1}
    else V.require("Trees").stamp(out,ts,x,z,small,forest) end
  end
  for y=0,L.height-1 do Budget.check();for x=0,L.width-1 do
    local c=L:cellAt(x,y);local mid=c.mid
    local prop=Shapes.prop(def,c)
    local xx,zz=(x+ox)*16,(y+oz)*16
    local uv=Geometry.uv(ts,decorativeSea(def,mid)and 0x12b or Shapes.surfaceMid(def,mid))
    if qualityProps.mask[y*L.width+x+1]then
      V.require('FireRedQualityProps').floor(out,def,ts,x,y,ox,oz,qualityProps.mask[y*L.width+x+1])
    elseif fountain and x>=12 and x<=14 and y>=18 and y<=21 then
      if x==12 and y==18 then V.require('FireRedCeladonFountain').place(out,ts,ox,oz,contacts)end
    elseif V.require('FireRedTowerExterior').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('EmeraldUnderwater').floor(out,def,ts,x,y,ox,oz,underwater)then
    elseif V.require('EmeraldEventExteriors').floor(out,def,ts,x,y,ox,oz,eventIslands,contacts)then
    elseif crater[y*L.width+x+1]then
      V.require('EmeraldSootopolisCrater').floor(out,def,ts,x,y,ox,oz,crater[y*L.width+x+1])
    elseif market.mask[y*L.width+x+1]then
      V.require('EmeraldSlateportMarket').floor(out,def,ts,x,y,ox,oz,market.mask[y*L.width+x+1])
    elseif pacifidlogMask[y*L.width+x+1]then
      top(out,xx,zz,16,16,0,Geometry.uv(ts,pacifidlogMask[y*L.width+x+1]),Geometry.WATER)
    elseif furnitureMask[y*L.width+x+1]or fortreeMask[y*L.width+x+1]then
      local floor=furnitureMask[y*L.width+x+1]or fortreeMask[y*L.width+x+1]
      if floor==0 then floor=ground end
      local tex=type(floor)=="table" and Geometry.uv(ts,floor.mid,floor.x0,floor.y0,floor.x1,floor.y1) or Geometry.uv(ts,floor)
      if not (type(floor)=="table" and floor.void) then
        local repeats=type(floor)=='table'and floor.repeatY or 1
        for row=0,repeats-1 do top(out,xx,zz+row*16/repeats,16,16/repeats,0,tex)end
      end
    elseif mask[y*L.width+x+1] then
      local b=mask[y*L.width+x+1]
      if coastalRoofs[b]then sea.buildingFloor(out,b,L,ts,x,y,ox,oz,coastalRoofs[b])
      elseif b.slateportMuseum then V.require('EmeraldSlateportExterior').museumFloor(out,b,L,ts,x,y,ox,oz)
      elseif b.lilycoveMuseum then V.require('EmeraldLilycoveMuseum').floor(out,b,L,ts,x,y,ox,oz)
      elseif b.nativeSilhouette then V.require('EmeraldSootopolisHouses').floor(out,b,L,ts,x,y,ox,oz)
      else top(out,xx,zz,16,16,0,Geometry.uv(ts,mapView and mapView.buildingGround or b.ground or 1))end
    elseif fallarbor[y*L.width+x+1]then
      top(out,xx,zz,16,16,0,Geometry.uv(ts,0x279))
      V.require('EmeraldFallarborTrees').place(out,ts,fallarbor[y*L.width+x+1],ox,oz,treeInstances,contacts)
    elseif ash[y*L.width+x+1]then
      top(out,xx,zz,16,16,0,Geometry.uv(ts,ground))
      V.require('EmeraldAshRoute').place(out,ts,ash[y*L.width+x+1],ox,oz,treeInstances,contacts)
    elseif safari[y*L.width+x+1]then
      top(out,xx,zz,16,16,0,Geometry.uv(ts,ground))
      local p=safari[y*L.width+x+1]
      if type(p)=='table'then V.require('FireRedSafari').place(out,ts,p,ox,oz,treeInstances,contacts)end
    elseif mossdeep.mask[y*L.width+x+1]then
      V.require('EmeraldMossdeepTrees').floor(out,def,ts,x,y,ox,oz,mossdeep.mask[y*L.width+x+1])
    elseif compact[y*L.width+x+1]then
      local p=compact[y*L.width+x+1];local role=V.require('EmeraldCompactForest').role(def,mid)
      top(out,xx,zz,16,16,0,Geometry.uv(ts,role[3]))
      if p.x==x and p.y==y then V.require('EmeraldCompactForest').place(out,ts,p,ox,oz,treeInstances,contacts)end
    elseif rainforest[y*L.width+x+1] then
      top(out,xx,zz,16,16,0,Geometry.uv(ts,ground))
      local crown=rainforest[y*L.width+x+1]
      if crown.x==x and crown.y==y then V.require('EmeraldRainforest').place(out,ts,crown,ox,oz,treeInstances,contacts)end
    elseif treeMask[y*L.width+x+1] then
      local floor=treeMask[y*L.width+x+1]
      if type(floor)=='table'and floor.fence then
        if not V.require('FireRedStandingProps').build(out,def,ts,x,y,ox,oz,contacts,{mid=floor.fence,ground=ground})then
          V.require('Trees').coastalFloor(out,ts,xx,zz,mid,ground)
        end
      elseif type(floor)=='table'and floor.coastal then V.require('Trees').coastalFloor(out,ts,xx,zz,floor.mid,ground)
      else top(out,xx,zz,16,16,0,Geometry.uv(ts,type(floor)=='table'and floor.mid or ground),
        type(floor)=='table'and floor.water and Geometry.WATER or 1)end
    elseif outdoor and Shapes.tree(mid,def) then
      top(out,xx,zz,16,16,0,Geometry.uv(ts,ground))
      treeAt(xx+8,zz+8,true,Shapes.forest(def))
    elseif seaRocks[y*L.width+x+1]then
      local p=seaRocks[y*L.width+x+1]
      if p.x==x and p.y==y and not p.passive then V.require('FireRedSeaRocks').place(out,ts,p,ox,oz,treeInstances,contacts)end
    elseif V.require('EmeraldNavelSanctums').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('EmeraldNavelPassages').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('EmeraldMirageTower').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('EmeraldSeafloorCurrents').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('EmeraldMagmaHideout').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('EmeraldRusturf').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('EmeraldFieryPath').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('EmeraldCaveTerraces').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('FireRedTerracedCaves').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('TanobyKey').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('FireRedDiglettCave').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('FireRedLostCave').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('FireRedRuinCaves').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('EmeraldCaveStalagmites').floor(out,def,ts,x,y,ox,oz,stalagmites)then
    elseif V.require('EmeraldCaveObjects').floor(out,def,ts,x,y,ox,oz,caveObjects)then
    elseif V.require('EmeraldOriginObjects').floor(out,def,ts,x,y,ox,oz,originObjects)then
    elseif V.require('EmeraldMeteorEdges').rocks(out,def,ts,x,y,ox,oz,contacts)then
    elseif V.require('EmeraldMeteorColumns').floor(out,def,ts,x,y,ox,oz)then
    elseif V.require('EmeraldFlowers').build(out,def,ts,x,y,ox,oz,contacts)then
    elseif terrain[y*L.width+x+1] then
      if outdoor and terrain[y*L.width+x+1]~='emeraldCoast'then
        -- Continue the ledge's own native ground material underneath the raised
        -- lip. The lower source half contains the rock face, not floor artwork.
        local floorUV=terrain[y*L.width+x+1]=='ledge'and Geometry.uv(ts,mid,0,0,16,8,.5)or Geometry.uv(ts,ground)
        top(out,xx,zz,16,16,0,floorUV)
      end
      V.require("Terrain").stamp(out,def,ts,x,y,ox,oz,terrain)
      if terrain[y*L.width+x+1]=='ledge' and terrain[(y+1)*L.width+x+1]~='ledge' then
        local tc=V.require('DioramaConfig').terrain
        contacts[#contacts+1]={xx+8,zz+16,10,tc.ledgeContactRadius,tc.ledgeContactStrength}
      end
    elseif V.require('Props').mailboxHeadFloor(out,def,ts,x,y,ox,oz,ground)then
    elseif V.require('FireRedStandingProps').build(out,def,ts,x,y,ox,oz,contacts)then
    elseif V.require('EmeraldSlateportProps').build(out,def,ts,x,y,ox,oz,contacts)then
    elseif V.require('EmeraldMauvilleBikes').build(out,def,ts,x,y,ox,oz,contacts)then
    elseif V.require('EmeraldCityLamps').build(out,def,ts,x,y,ox,oz,contacts)then
      -- Whole native lamps share the existing silhouette/sun-shadow pass.
    elseif V.require('EmeraldCityFences').build(out,def,ts,x,y,ox,oz,contacts)then
      -- Exact native city rails keep their own pavement/grass background.
    elseif prop=='fountain'then
      -- A script-edited, incomplete fountain keeps its exact native floor.
      top(out,xx,zz,16,16,0,uv)
    elseif prop then
      if prop=="fence" or prop=="mailbox" or prop=="sign" or prop=="post" or prop=="rock" then
        contacts[#contacts+1]={xx+8,zz+14,prop=="mailbox" and 4 or 8,contact.propRadius,contact.strength}
      end
      top(out,xx,zz,16,16,0,Geometry.uv(ts,ground))
      if prop=="ledge" then top(out,xx,zz,16,16,.01,uv)
      elseif treeInstances then
        local key=mid..":"..prop..":"..ground
        local group=treeInstances.props[key]
        if not group then group={mid=mid,kind=prop,ground=ground,placements={}};treeInstances.props[key]=group end
        group.placements[#group.placements+1]={xx,zz,1}
      else V.require("Props").stamp(out,ts,mid,prop,xx,zz,ground) end
    else
      top(out,xx,zz,16,16,0,uv,waterMaterial(def,c) and Geometry.WATER or 1)
    end
  end end
  V.require('FireRedTerracedCaves').objects(out,def,ts,ox,oz,contacts)
  V.require('TanobyKey').objects(out,def,ts,ox,oz,contacts)
  V.require('FireRedDiglettCave').objects(out,def,ts,ox,oz,contacts)
  V.require('FireRedLostCave').objects(out,def,ts,ox,oz,contacts)
  V.require('FireRedRuinCaves').objects(out,def,ts,ox,oz,contacts)
  V.require("Furniture").build(out,furniture,L,ts,ox,oz,furnitureMask,contacts)
  for _,tree in ipairs(trees)do treeAt((tree.x+ox)*16+tree.width*8+(tree.offsetX or 0),(tree.y+oz)*16+V.require("Trees").baseOffset(tree.forest),false,tree.forest) end
  V.require('EmeraldMagmaHideout').objects(out,def,ts,ox,oz,contacts)
  V.require('EmeraldRusturf').objects(out,def,ts,ox,oz,contacts)
  V.require('EmeraldMeteorColumns').build(out,def,ts,ox,oz,contacts)
  V.require('EmeraldOriginObjects').build(out,def,ts,ox,oz,contacts,originObjects)
  V.require('EmeraldNavelSanctums').objects(out,def,ts,ox,oz,contacts)
  V.require('EmeraldNavelPassages').objects(out,def,ts,ox,oz,contacts)
  V.require('EmeraldMirageTower').objects(out,def,ts,ox,oz,contacts)
  V.require('EmeraldSeafloorCurrents').objects(out,def,ts,ox,oz,contacts)
  if V.require('EmeraldCaveTerraces').active(def)then
    V.require('EmeraldCaveTerraces').objects(out,def,ts,ox,oz,contacts)
  else
    V.require('EmeraldCaveObjects').build(out,def,ts,ox,oz,contacts,caveObjects)
    V.require('EmeraldCaveStalagmites').build(out,def,ts,ox,oz,contacts,stalagmites)
  end
  V.require('EmeraldEventExteriors').objects(out,def,ts,ox,oz,eventIslands,contacts)
  V.require('EmeraldUnderwater').objects(out,def,ts,ox,oz,underwater,contacts)
  V.require('EmeraldSlateportProps').walls(out,def,ts,ox,oz)
  V.require('EmeraldSlateportMarket').build(out,def,ts,ox,oz,contacts,market)
  V.require('EmeraldSootopolisCrater').build(out,def,ts,ox,oz,crater,contacts)
  V.require('EmeraldSkyPillar').exteriorBuild(out,def,ts,ox,oz)
  V.require('EmeraldFortreeArchitecture').build(out,def,ts,ox,oz)
  V.require('EmeraldPacifidlog').build(out,def,ts,ox,oz)
  V.require('EmeraldMossdeepTrees').build(out,def,ts,ox,oz,treeInstances,contacts)
  V.require('FireRedQualityProps').build(out,def,ts,ox,oz,contacts,qualityProps)
  local lights={}
  for _,b in ipairs(buildings)do
    local x0,x1=(b.x0+ox)*16,(b.x1+1+ox)*16
    -- Overlapping short ellipses make a continuous contact line with soft ends.
    for x=x0+3,x1-2,6 do contacts[#contacts+1]={x,((b.facadeBaseY or b.y1+1)+oz)*16,7,contact.buildingRadius,contact.strength}end
    for _,l in ipairs(V.require("BuildingMesh").build(out,b,L,ts,ox,oz))do lights[#lights+1]=l end
  end
  V.require('RooftopVista').extendCondo(out,def,ts,ox,oz)
  return out,{contacts=contacts,lights=lights,buildings=#buildings,trees=#trees,cells=L.width*L.height,vertices=#out,terrainCells=(function()local n=0;for _ in pairs(terrain)do n=n+1 end;return n end)()}
end
return Geometry
