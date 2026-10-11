-- Native FireRed tree silhouettes on flat paper cards.
local V=...
local Budget=V.require('BuildBudget')
local Trees={}
-- The group starts on the crown row; the artwork starts one row north.
-- Keep the standing trunk at its original ground foot (base minus16).
function Trees.baseOffset(forest)return (forest and 57 or 43)-16 end
local templates=setmetatable({},{__mode="k"})
-- Native forest foliage and its ground shadow share green palette entries.
-- The last three rows need a silhouette mask, not just a colour key: the
-- shadow spreads back out beside the trunk while the crown curves inward.
local forestCrownInset={[45]=8,[46]=12,[47]=18}
-- Standalone canopy: fold the flat 0x0E/0x0F crown tips into the upright
-- card. Explicit per-pair flags win; otherwise every non-excluded tileset
-- that actually contains both tip metatiles uses it.
local function standaloneFor(pair,midToSlot)
  local cfg=V.require('DioramaConfig').trees
  local v=cfg.standaloneCanopyPairs[pair]
  if v~=nil then return v end
  if not cfg.standaloneDefault or (cfg.standaloneExclude and cfg.standaloneExclude[pair]) then return false end
  return midToSlot~=nil and midToSlot[0xe]~=nil and midToSlot[0xf]~=nil
end
Trees.standaloneFor=standaloneFor
function Trees.groups(L,def,preserveRows)
  local emerald=V.data('Emerald').map(def)
  local forest=V.data("Shapes").forest(def)
  local list,mask={},{}
  local function k(x,y)return y*L.width+x+1 end
  local function tree(mid)return V.data("Shapes").tree(mid,def)end
  local width=forest and 3 or 2
  -- A few native crowns cross a map seam. The northern/western map owns
  -- the standing card; its neighbour consumes only its remaining native ink.
  -- Guard both the connection and the local artwork, so unrelated layouts
  -- never lose tiles or gain a duplicate tree at the edge.
  local function connection(map,dir,offset)
    for _,c in ipairs(def.connections or{})do
      if c.map==map and c.dir==dir and c.offset==offset then return true end
    end
    return false
  end
  local function joined(x,y,rows,owner)
    for dy,row in ipairs(rows)do for dx,mid in ipairs(row)do
      if L:midAt(x+dx-1,y+dy-1)~=mid then return end
    end end
    for dy,row in ipairs(rows)do for dx in ipairs(row)do mask[k(x+dx-1,y+dy-1)]=true end end
    if owner then list[#list+1]={x=owner[1],y=owner[2],forest=false,width=2}end
    return true
  end
  local id=def.id or def.name
  if not emerald and not forest and standaloneFor((def.renderPair or def.pair),L.midToSlot or{[0xe]=true,[0xf]=true})then
    if id=='FR_ROUTE_1' and (def.renderPair or def.pair)=='pallet_outdoor' and L.width==24 and L.height==40 then
      -- Native fence/tree composites share both tip and middle rows.
      -- The tree owns the foliage; retain the canonical rail behind it.
      if joined(10,37,{{0xe,0x2ab},{0x1e,0x2ba},{0x14,0x15}},{10,38})then
        for y=37,38 do mask[k(11,y)]={fence=0xf5}end
      end
      if joined(14,37,{{0x2aa,0xf},{0x2b2,0x1f},{0x14,0x15}},{14,38})then
        for y=37,38 do mask[k(14,y)]={fence=0xf4}end
      end
    elseif (def.renderPair or def.pair)=='viridian_outdoor' then
      if id=='FR_ROUTE_2' and L.width==24 and L.height==80 and connection('FR_VIRIDIAN_CITY','south',-12)then
        joined(12,78,{{0xe,0xf},{0x1e,0x1f}},{12,79})
      elseif id=='FR_VIRIDIAN_CITY' and L.width==48 and L.height==40 and connection('FR_ROUTE_2','north',12)then
        joined(24,0,{{0x16,0x15}})
      end
    elseif (def.renderPair or def.pair)=='general__rom_082d507c' then
      if id=='FR_SIX_ISLAND_GREEN_PATH' and L.width==72 and L.height==20 and connection('FR_SIX_ISLAND_WATER_PATH','east',0)then
        joined(71,14,{{0xe},{0x1e},{0x26}},{71,15})
      elseif id=='FR_SIX_ISLAND_WATER_PATH' and L.width==24 and L.height==100 and connection('FR_SIX_ISLAND_GREEN_PATH','west',0)then
        joined(0,14,{{0xf},{0x1f},{0x27}})
      end
    elseif id=='FR_ROUTE_14' and (def.renderPair or def.pair)=='general__rom_082d4b0c' and L.width==24 and L.height==60 then
      -- 2e8 combines this crown's bottom with the next crown's tip.
      joined(11,16,{{0xe,0xf},{0x1e,0x1f},{0x24,0x2e8}},{11,17})
    end
  end
  for y=0,L.height-2 do for x=0,L.width-width do
    Budget.tick()
    local mid=L:midAt(x,y)
    -- Coastal crowns mix their top with animated water and their middle
    -- with shoreline art. They still own a full standing tree, not tiny
    -- fallback trees beneath an unlifted green crown.
    local coastal=not emerald and not forest and tostring(def.id or def.name):match('^FR_')
      and tostring((def.renderPair or def.pair)):match('^general__') and y>0 and mid==0xfa and L:midAt(x+1,y)==0xfb
      and (L:midAt(x,y-1)==0x10a and L:midAt(x+1,y-1)==0x10b
        -- Six Island uses static aliases of the same native coastal tips.
        or (def.renderPair or def.pair)=='general__rom_082d507c' and L:midAt(x,y-1)==0x255 and L:midAt(x+1,y-1)==0x25d)
    local anchor=coastal or emerald and (mid==0x1d4 or mid==0x1d6)
      or not emerald and (forest and (L:midAt(x+1,y)==0x289 or L:midAt(x+1,y)==0x299)
      or not forest and (mid==0x1c or mid==0x1e))
    -- Forest crowns can share an outer metatile where two staggered trees
    -- overlap. The centre identifies ownership; rejecting shared side pixels
    -- left four miniature fallback trees in place of one complete crown.
    if not mask[k(x+(forest and 1 or 0),y)] and anchor then
      local whole=true
      for dy=0,1 do for dx=0,width-1 do
        if (mask[k(x+dx,y+dy)] and (not forest or dx==1))or not(coastal and dy==0)and not tree(L:midAt(x+dx,y+dy))then whole=false end
      end end
      if whole then
        list[#list+1]={x=x,y=y,forest=forest,width=width}
        for dy=0,1 do for dx=0,width-1 do mask[k(x+dx,y+dy)]=true end end
        if coastal then
          -- Retain the native water/shoreline donors behind the raised crown.
          -- Neither the map cells nor their collision values are rewritten.
          for dx=0,1 do
            mask[k(x+dx,y-1)]={mid=0x12b,water=true}
            mask[k(x+dx,y)]={mid=dx==0 and 0xfa or 0xfb,coastal=true}
          end
        elseif not forest and (emerald or standaloneFor((def.renderPair or def.pair),L.midToSlot or (L.tileset and L.tileset.midToSlot) or {[0xe]=true,[0xf]=true})) and y>0 then
          -- Consume the original flat crown tips along with the full card.
          for dx=0,width-1 do local m=L:midAt(x+dx,y-1);if emerald and (m==0x1ce or m==0x1cf)or not emerald and (m==0xe or m==0xf)then mask[k(x+dx,y-1)]=true end end
        end
        if forest then
          -- Native shadows/trunks and the tip overlap adjacent map rows.
          -- They belong to this whole tree, never another upright copy.
          if y>0 then for dx=0,width-1 do
            local m=L:midAt(x+dx,y-1)
            if m==0x281 or m==0x286 or m==0x287 then mask[k(x+dx,y-1)]=true end
          end end
          if y+2<L.height and L:midAt(x+1,y+2)==0x2a4 then
            for dx=0,width-1 do mask[k(x+dx,y+2)]=true end
          end
        end
      end
    end
  end end
  -- ROM forests repeat canopy courses every two rows. Standing full crowns
  -- at that same spacing overlap into tall strips in the tilted view. Keep
  -- every front edge; rowStride selects the density of enclosed courses. The
  -- source mask still replaces all canopy tiles with ground; collision and
  -- native tree objects are untouched.
  local at={};for _,t in ipairs(list)do at[t.y*L.width+t.x]=t end
  local depths={}
  local function depth(t)
    if depths[t]then return depths[t]end
    local nextTree=at[(t.y+2)*L.width+t.x]
    if not nextTree and forest then
      local joined=true
      for dx=0,width-1 do if not tree(L:midAt(t.x+dx,t.y+2))then joined=false end end
      if joined then nextTree=at[(t.y+3)*L.width+t.x]end
    end
    local n=nextTree and depth(nextTree)+1 or 0;depths[t]=n;return n
  end
  local cfg=V.require("DioramaConfig").trees
  local route=not preserveRows and cfg.routeRows and cfg.routeRows[def and (def.id or def.name)]
  local spaced={}
  for _,t in ipairs(list)do
    local course=depth(t)
    if course%math.max(1,route and route.stride or cfg.rowStride)==0 then
      -- Alternate whole crowns within the native forest footprint. The mask
      -- still consumes every source tile and collision remains untouched.
      if route then t.offsetX=(math.floor(course/route.stride)%2==0 and -1 or 1)*route.stagger/2 end
      spaced[#spaced+1]=t
    end
  end
  return spaced,mask
end
-- Preserve every exposed native shore pixel, filling only the old crown's
-- footprint with local ground. Some packed atlases omit the plain shore tile.
function Trees.coastalFloor(out,ts,x,z,mid,ground)
 local G=V.require('WorldGeometry');local pixel=V.require('BuildingMesh').pixel
 local function leaf(s,t)local r,g,b=pixel(ts,mid,s,t);return g>r*1.08 and b<g*.6 end
 for y=0,15 do local start=0
  while start<16 do
   local foliage=leaf(start,y);local finish=start+1
   while finish<16 and leaf(finish,y)==foliage do finish=finish+1 end
   G.quad(out,{x+start,0,z+y},{x+finish,0,z+y},{x+finish,0,z+y+1},{x+start,0,z+y+1},
     G.uv(ts,foliage and ground or mid,start,y,finish,y+1),1)
   start=finish
  end
 end
end
local function template(ts,forest)
  local emerald=V.data('Emerald').active()
  local key=forest and "forest" or "ordinary"
  local cached=templates[ts] or {};templates[ts]=cached
  if cached[key] then return cached[key] end
  local pixel=V.require("BuildingMesh").pixel
  local standalone=emerald or standaloneFor(V.require('TilesetSemantics').atlasPair(ts),ts.midToSlot)
  local warm=V.require('TilesetSemantics').atlasPair(ts)=="general__rom_082d5004"
  local upper=ts.midToSlot[0x289] and {0x288,0x289,0x28a} or {0x298,0x299,0x29a}
  local mids=emerald and {{0x1ce,0x1cf},{0x1d6,0x1d7},{0x1dc,0x1dd}}
    or forest and {{false,0x281,false},upper,{0x290,0x2a1,0x2a2},{0x2a3,0x2a4,0x2a5}}
    or (standalone and {{0xe,0xf},{0x1e,0x1f},{0x24,0x25}} or {{0x14,0x15},{0x1c,0x1d},{0x24,0x25}})
  local W,H=forest and 48 or 32,forest and 64 or 48
  local cfg=V.require('DioramaConfig').trees
  local style=(cfg.pairStyle and cfg.pairStyle[V.require('TilesetSemantics').atlasPair(ts)]) or (forest and cfg.forestStyle) or cfg.defaultStyle or cfg
  local hideTrunks=style.hideTrunks;if hideTrunks==nil then hideTrunks=cfg.hideTrunks end
  local nativeBase=forest and 57 or 43
  local base=hideTrunks and (forest and cfg.canopyBaseForest or cfg.canopyBaseOrdinary)or nativeBase
  local function source(x,y)return mids[math.floor(y/16)+1][math.floor(x/16)+1],x%16,y%16 end
  local function inside(x,y,mid,sx,sy)
    local r,g,b,a=pixel(ts,mid,sx,sy)
    local leaf=a>.5 and g>r*(warm and .82 or 1.08) and b<g*(warm and .72 or .60)
      and (not warm or r>g*.70)
    if y<16 and not standalone then leaf=leaf and r>.4 and g>.7 end
    -- The last two forest leaf rows join the native trunk at row 47.
    -- Only crop them for the legacy trunkless silhouette.
    leaf=leaf and y<(forest and (hideTrunks and cfg.canopyBaseForest or 48) or cfg.canopyBaseOrdinary)
    local inset=forest and forestCrownInset[y]
    if inset then leaf=leaf and x>=inset and x<W-inset end
    local trunk=y>=(forest and 43 or 34) and y<base and math.abs(x-W/2)<(forest and 7 or 5)
    return leaf or (not hideTrunks and trunk and a>.5 and g<.65 and r>=g*.85)
  end
  -- Anchor the retained silhouette to the ground: cropped crown or the actual
  -- forest trunk tip. Native shadow rows below the trunk are not geometry.
  if hideTrunks or forest then
    local lowest=0
    for y=0,base-1 do for x=0,W-1 do
      local mid,sx,sy=source(x,y)
      if mid and inside(x,y,mid,sx,sy)then lowest=math.max(lowest,y+1)end
    end end
    if lowest>0 then base=lowest end
  end
  local shadeStyle=(cfg.pairStyle and cfg.pairStyle[V.require('TilesetSemantics').atlasPair(ts)]) or (forest and cfg.forestStyle) or cfg.defaultStyle or cfg
  local crownShade=shadeStyle.crownShade or cfg.crownShade
  local trunkShade=shadeStyle.trunkShade or cfg.trunkShade
  cached[key]=V.require("PaperSprite").build(ts,W,H,source,inside,-W/2,base,1,function(x,y)
    local lower=math.max(0,math.min(1,(y-base*cfg.lowerShadeStart)/(base*(1-cfg.lowerShadeStart))))
    return crownShade*(1-lower)+trunkShade*lower
  end)
  -- Per-tileset proportions: the approved Pallet/Route 1 style stays tall;
  -- other towns keep native crown proportions so rows read as single trees.
  local function pick(k)if style[k]~=nil then return style[k]end return cfg[k]end
  local perspective=V.require('Camera').projection()=='perspective'
  local angle=perspective and math.rad(cfg.tiltDegrees)or 0
  local compensation=pick('preserveScreenHeight') and perspective and
    1/math.max(.25,math.cos(angle)-math.tan(V.require('Camera').elevation())*math.sin(angle))or 1
  for _,v in ipairs(cached[key])do
    v[1]=v[1]*pick('widthScale')
    local h=v[2]*pick('heightScale')*compensation*(hideTrunks and pick('preserveCrownHeight') and nativeBase/base or 1)
    v[2]=h*math.cos(angle)
    if perspective then v[3]=h*math.sin(angle)end
    if (v[9]or 0)>0 then v[9]=1+V.require('DioramaConfig').dynamicTexture.treeWeight end
  end
  return cached[key]
end
function Trees.release()templates=setmetatable({},{__mode="k"})end
Trees.template=template
function Trees.stamp(out,ts,x,z,small,forest)
  local scale=small and .5 or 1
  for _,v in ipairs(template(ts,forest))do
    out[#out+1]=V.require("WorldGeometry").place(v,x,z,scale)
  end
end
return Trees
