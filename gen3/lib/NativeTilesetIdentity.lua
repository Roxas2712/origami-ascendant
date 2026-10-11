-- Old FRLG imports sometimes merged tilesets sharing a tile sheet even
-- though their metatile/attribute tables differ. Rebuild the render atlas
-- from the already extracted, authoritative map-tree blobs in memory.
-- Never rewrite cached maps, collision cells, events or player files.
-- Old imports also need the authoritative, per-map behavior lookup.
local V=...
local R={descriptors={},atlases={},views=setmetatable({},{__mode='k'}),failures={}}
R.attributeTables={}
local root='data/generated/gba/map_tree/'
local function bytes(s)local t={};for i=1,#s do t[i]=s:byte(i)end;return t end
function R.bundle(cache,primary,secondary)
 local T=require('src.import.gba.tileset')
 local function one(id)
  assert(type(id)=='string' and id:match('^ts_%x+$'),'invalid tileset identity')
  local p=root..'tilesets/'..id..'/'
  local function read(name,unit)
   local s=assert(cache:read(p..name),'missing native tileset source '..p..name)
   assert(#s>=unit and #s%unit==0,'truncated native tileset source '..p..name)
   return s
  end
  local raw=read('tiles.4bpp',32);local mt=read('metatiles.bin',16);local attr=read('attributes.bin',4)
  local pal=read('palettes.bin',32);assert(#pal>=512,'incomplete native palette')
  local pals={}
  for n=0,15 do pals[n]={};for k=0,15 do local i=n*32+k*2+1;pals[n][k]=pal:byte(i)+pal:byte(i+1)*256 end end
  return {tiles={count=#raw/32,raw=bytes(raw)},mt={count=#mt/16,data=bytes(mt)},
   attr={count=#attr/4,data=bytes(attr)},pals=pals}
 end
 local a,b=one(primary),one(secondary)
 return {primaryTiles=a.tiles,secondaryTiles=b.tiles,primaryMt=a.mt,secondaryMt=b.mt,
  primaryAttr=a.attr,secondaryAttr=b.attr,mapPals=T.mergeMapPalettes(a.pals,b.pals)}
end
function R.describe(def,cache)
 if not def or not V.require('DioramaConfig').interiors.nativeTilesetRepair then return nil end
 local id=def.id or def.name;local old=def.pair and def.pair:match('__rom_(%x+)$')
 if not id or not old then return nil end
 local key=id..'/'..def.pair
 if R.descriptors[key]~=nil then return R.descriptors[key] or nil end
 local slot=require('src.import.gba.map_catalog').slotKeyFor(id)
 local raw=slot and cache:read(root..'maps/'..slot..'/header.json')
 -- Only these ASCII identifiers are needed from the generated header.
 -- Avoid depending on the engine's network-protocol JSON module.
 local primary=raw and raw:match('"primaryTileset"%s*:%s*"(ts_%x+)"')
 local secondary=raw and raw:match('"secondaryTileset"%s*:%s*"(ts_%x+)"')
 local descriptor
 if primary and secondary and secondary~='ts_'..old then
  descriptor={primary=primary,secondary=secondary,
   oldPair=def.pair,pair=def.pair:gsub('__rom_%x+$','__rom_'..secondary:sub(4))}
 end
 -- Old imports omitted script-only machine, electrical-gate and quiz-door frames.
 -- Repair only these visual atlases from the extracted native source blobs.
 -- The engine remains authoritative for collision and metatile behavior.
 local variants
 local semanticPair=V.require("TilesetSemantics").pair(def,cache)
 if id=='FR_ROUTE_25_SEA_COTTAGE'and semanticPair=='building__rom_082d4eb4'and V.require('DioramaConfig').interiors.seaCottage.nativeVariants then
  variants={0x2b5,0x2ba}
 elseif id=='FR_CINNABAR_ISLAND_GYM'and semanticPair=='building__rom_082d4d7c'and V.require('DioramaConfig').interiors.fireredFireGym.nativeVariants then
  variants={0x2c6,0x2d1}
 elseif id=='FR_VERMILION_CITY_GYM'and semanticPair=='building__rom_082d4d34'and V.require('DioramaConfig').interiors.fireredElectricGym.nativeVariants then
  variants={0x293,0x2c7}
 end
 if not descriptor and primary and secondary and variants then
  local pack=require('src.import.gba.native_pack');local missing=false
  for _,file in ipairs{'mids.idx','mids_over.idx'}do
   local blob=cache:read('data/generated/gba/native/'..def.pair..'/'..file)
   local idx=blob and pack.decodeIdx(blob);local present={}
   for _,mid in ipairs(idx and idx.midIds or{})do present[mid]=true end
   for mid=variants[1],variants[2]do if not present[mid]then missing=true end end
  end
  if missing then descriptor={primary=primary,secondary=secondary,oldPair=def.pair,pair=def.pair,visualOnly=true}end
 end
 R.descriptors[key]=descriptor or false
 return descriptor
end
function R.build(cache,d)
 local P=require('src.import.gba.native_pack');local T=require('src.import.gba.tileset')
 local bundle=R.bundle(cache,d.primary,d.secondary)
 -- All source metatiles, including script-set variants absent from the map.
 local mids={};for n=0,bundle.primaryMt.count-1 do mids[#mids+1]=n end
 for n=0,bundle.secondaryMt.count-1 do mids[#mids+1]=T.NUM_PRIMARY_METATILES+n end
 local under,over=P.buildLayeredIdx(bundle,mids);local rgb=P.palsToRgb8(bundle.mapPals)
 local function image(idx,transparent)
  local blob,w,h=P.bakeRgba(idx,rgb,{transparentZero=transparent})
  local data=love.image.newImageData(w,h,'rgba8',blob);local im=love.graphics.newImage(data)
  im:setFilter('nearest','nearest');return im,data
 end
 local im,data=image(under,false);local oi,od=image(over,true);local slots={}
 for i,mid in ipairs(mids)do slots[mid]=i-1 end
 return {pair=d.pair,image=im,imageData=data,overImage=oi,overImageData=od,layered=true,
  cols=under.atlasCols,rows=under.atlasRows,midCount=#mids,midToSlot=slots,quads={},overQuads={}}
end
local semanticViews=setmetatable({},{__mode="k"})
local function semanticView(def,cache)
 local pair=V.require("TilesetSemantics").pair(def,cache)
 if pair==def.pair or def.renderPair==pair then return def end
 local view=semanticViews[def]
 if not view then view=setmetatable({renderPair=pair},{__index=def});semanticViews[def]=view end
 return view
end
function R.resolve(def)
 local cache=require('src.core.game3.dataset').cache();local d=R.describe(def,cache)
 if not d then return semanticView(def,cache) end
 local ts=R.atlases[d.pair]
 if not ts then
  if R.failures[d.pair]then return def end
  local ok,value=pcall(R.build,cache,d)
  if not ok then
   R.failures[d.pair]=tostring(value)
   if V.mod and V.mod.log then V.mod.log:warn('Native tileset identity repair failed: %s',tostring(value))end
   return def
  end
  ts=value;R.atlases[d.pair]=ts
 end
 require('src.core.game3.tileset_native')._pairs[d.pair]=ts
 local view=R.views[def]
 if not view then view=setmetatable({pair=d.pair},{__index=def});R.views[def]=view end
 return semanticView(view,cache),ts
end
-- Metatile semantics are separate from the map's collision/elevation grid.
-- Read the already extracted ROM attributes without building a GPU atlas.
function R.behavior(def,cx,cy)
 if V.require('DioramaConfig').interiors.nativeBehaviorRepair==false then return nil end
 local L=def and def.midLayout
 if not L or cx<0 or cy<0 or cx>=L.width or cy>=L.height then return nil end
 local cache=require('src.core.game3.dataset').cache();local d=R.describe(def,cache)
 if not d or d.visualOnly then return nil end
 local mid=L:midAt(cx,cy);if not mid or mid<0 then return nil end
 local count=require('src.import.gba.tileset').NUM_PRIMARY_METATILES
 local id=mid<count and d.primary or d.secondary;local index=mid<count and mid or mid-count
 local a=R.attributeTables[id]
 if a==nil then
  a=cache:read(root..'tilesets/'..id..'/attributes.bin')
  if not a or #a<4 or #a%4~=0 then a=false end
  R.attributeTables[id]=a
 end
 if not a or index*4+4>#a then return nil end
 local offset=index*4+1
 -- FRLG behavior occupies the low nine bits; layer/encounter flags are not behavior.
 return (a:byte(offset)+a:byte(offset+1)*256)%512
end
function R.warp(def,cx,cy)
 local b=R.behavior(def,cx,cy)
 if b==nil or not require('src.core.game3.collision').isWarpMetatileBehavior(b)then return nil end
 for _,w in ipairs(def.warps or {})do if tonumber(w.x)==cx and tonumber(w.y)==cy then return w end end
end
function R.install()
 if R.installed then return end;R.installed=true
 local C=require('src.core.game3.collision');local behavior,warp=C.behavior,C.warpAt
 C.behavior=function(x,y)
  local b=R.behavior(C._mapDef,x,y)
  if b~=nil then return b end
  return behavior(x,y)
 end
 C.warpAt=function(x,y)
  -- The old translated collision byte may be ordinary floor (0), so the
  -- engine's legacy warp index omitted this original header event.
  if R.behavior(C._mapDef,x,y)~=nil then return R.warp(C._mapDef,x,y)end
  return warp(x,y)
 end
 local N=require('src.core.game3.tileset_native');local get,ready=N.get,N.ready
 N.get=function(pair)if R.override and pair==R.override.oldPair then return R.override.ts end;return get(pair)end
 N.ready=function(pair)if R.override and pair==R.override.oldPair then return true end;return ready(pair)end
end
function R.nativeDraw(game,draw,...)
 local def=require('src.core.game3.map').currentDef();local view,ts=R.resolve(def)
 if not ts then return draw(game,...)end
 local old=R.override;R.override={oldPair=def.pair,ts=ts}
 local result={pcall(draw,game,...)};R.override=old
 if not result[1]then error(result[2],0)end
 return unpack(result,2)
end
return R
