-- FireRed's primary outdoor tileset is shared by its town/route pairs.
-- IDs are native 16px metatiles, never Gen1/Gen2 32px block IDs.
local Shapes = {}
local specialSigns={
 general__rom_082d4b3c={[0x327]=true,[0x355]=true},
 general__rom_082d4b54={[0x28f]=true,[0x296]=true,[0x339]=true},
 general__rom_082d4b9c={[0x30c]=true,[0x32f]=true,[0x33c]=true},
}
local saffronRails={}
for _,mid in ipairs{0x30d,0x318,0x319,0x31a,0x31c,0x31d,0x31e,0x320,0x322,0x323,0x325,0x326,0x328,0x329,0x32a,0x32d,0x32e,0x344,0x345,0x346,0x347}do saffronRails[mid]=true end
local function emerald(def)return def and tostring(def.id or def.name or ''):match('^EM_')~=nil end
local function emeraldTree(mid)
 return mid==0x1ce or mid==0x1cf or mid>=0x1d4 and mid<=0x1d7
  or mid>=0x1dc and mid<=0x1df or mid>=0x1e4 and mid<=0x1e7
end
-- These native headers use INDOOR/UNDERGROUND for event and encounter rules,
-- despite showing an exposed deck, rooftop or summit. Share the exception
-- between lighting, camera, geometry and weather so they cannot disagree.
local exposed={
 EM_BIRTH_ISLAND_EXTERIOR=true,EM_NAVEL_ROCK_EXTERIOR=true,EM_FARAWAY_ISLAND_ENTRANCE=true,EM_FARAWAY_ISLAND_INTERIOR=true,
 EM_ABANDONED_SHIP_DECK=true,EM_SKY_PILLAR_TOP=true,
 EM_LILYCOVE_CITY_DEPARTMENT_STORE_ROOFTOP=true,
 FR_SSANNE_EXTERIOR=true,FR_SSANNE_DECK=true,
 FR_CELADON_CITY_DEPARTMENT_STORE_ROOF=true,FR_CELADON_CITY_CONDOMINIUMS_ROOF=true,
 FR_TRAINER_TOWER_ROOF=true,FR_MT_EMBER_SUMMIT=true,FR_NAVEL_ROCK_SUMMIT=true,
}
function Shapes.outdoors(def)
  if exposed[def.id or def.name] then return true end
  -- Tilesets are shared across locations (including caves). The ROM's map
  -- header is authoritative; names only support older/incomplete adapters.
  local mapType=tonumber(def.mapType)
  if mapType==1 or mapType==2 or mapType==3 or mapType==6 then return true end
  if mapType==4 or mapType==5 or mapType==8 or mapType==9 then return false end
  if def.environment=="INDOOR" or def.kind=="indoor" then return false end
  local pair = tostring((def.renderPair or def.pair) or (def.midLayout and def.midLayout.pair) or "")
  return pair:match("outdoor") ~= nil or pair:match("^general") ~= nil
end
function Shapes.roomTileset(def)
  local p=(def.renderPair or def.pair) or ""
  return p=="house" or p=="player_house" or p=="network" or p=="oak_lab" or p:match("^building")~=nil
end
function Shapes.forest(def)
  return def and ((def.renderPair or def.pair)=="general__rom_082d4dc4" or (def.renderPair or def.pair)=="general__rom_082d5004")
end
function Shapes.tree(mid,def)
  if def and def.id=='FR_ROUTE_25'and (def.renderPair or def.pair)=='general__rom_082d4af4'and mid==0x2fa then return true end
  if emerald(def) then return emeraldTree(mid) end
  if Shapes.forest(def) then
    return mid==0x281 or mid==0x286 or mid==0x287 or mid>=0x288 and mid<=0x28a
      or mid>=0x28e and mid<=0x292 or mid==0x296 or mid>=0x298 and mid<=0x29a
      or mid>=0x29e and mid<=0x2a5
  end
  return mid >= 0x14 and mid <= 0x17 or mid >= 0x1c and mid <= 0x1f
    or mid >= 0x24 and mid <= 0x27
end
function Shapes.water(cell)
  return cell.coll == 0x29
end
function Shapes.solid(cell)
  return cell and (cell.coll == 7 or cell.coll == 255)
end
function Shapes.surfaceMid(def,mid)
  -- Mt. Moon's lower floors use black filler both around and inside the
  -- map. The wider Paper camera exposes it; use the native rock cap art.
  if tonumber(def.mapType)==4 and (def.renderPair or def.pair)=="general__rom_082d4bfc" and mid==0x2f2 then return 0x291 end
  -- Diglett B1F is 85 native cells wide, stored in an even-width layout.
  -- Its zero/solid padding column must continue the surrounding rock cap.
  if tonumber(def.mapType)==4 and (def.renderPair or def.pair)=="general__rom_082d4e0c" and mid==0 then return 0x291 end
  return mid
end
function Shapes.borderMid(def,x,z)
  return Shapes.surfaceMid(def,def.midLayout:midAt(x,z))
end
function Shapes.prop(def,cell)
  local mid=cell.mid
  if emerald(def) then
    if not Shapes.outdoors(def)then return nil end
    if def.id=='EM_FARAWAY_ISLAND_INTERIOR'then
      if mid==0x208 then return 'grass'end
      if mid==0xe0 then return 'rock'end
    end
    if (def.renderPair or def.pair)=='general__fortree' and (mid==0xc6 or mid==0xc7 or mid==0x16 or mid==0x17)then return 'shrub' end
    if mid==3 then return 'sign' end
    if mid==4 or mid==5 then return 'flower' end
    if mid==0xd or mid==0x15 then return 'grass' end
    return nil
  end
  if not Shapes.outdoors(def) then
    if tonumber(def.mapType)==4 and ({general__rom_082d4e0c=true,general__rom_082d4bfc=true,
      general__rom_082d4df4=true,general__rom_082d4e54=true})[(def.renderPair or def.pair)]
      and (mid==0x282 or mid==0x283)then return "rock" end
    return nil
  end
  if (def.renderPair or def.pair)=="viridian_outdoor" and (mid==0x285 or mid==0x286 or mid==0x287 or mid==0x28d) then return "shrub" end
  if (def.id or def.name)=='FR_CELADON_CITY'and (def.renderPair or def.pair)=='general__rom_082d4b3c'and mid>=0x2cd and mid<=0x2d8 then return 'fountain'end
  if mid==5 then return "shrub" end
  if mid==4 then return "flower" end
  if cell.coll==0x18 or cell.coll==0x14 or mid==0xd then return "grass" end
  if mid==0x168 or mid==0x169 then return "sign" end
  if (specialSigns[(def.renderPair or def.pair)]or{})[mid]then return 'sign'end
  if (def.renderPair or def.pair)=='general__rom_082d4b3c'and(mid==0x353 or mid==0x354)then return 'fence'end
  if (def.renderPair or def.pair)=='general__rom_082d4b9c'and saffronRails[mid]then return 'fence'end
  if mid==0xee or mid==0xef or mid==0xf6 or mid==0xf7 then return 'fence'end
  if mid==2 or mid==3 then return "sign" end
  if (def.renderPair or def.pair)=="pallet_outdoor" and mid==0x2ad then return "mailbox" end
  if mid==0xe6 or mid==0xe8 or mid==0xe9 or mid==0xf0 or mid==0xf2 or mid==0xf3 then return "post" end
  if mid==0xea or mid==0xf1 or mid==0xf9
    or mid==0xe7 or mid==0xec or mid==0xed or mid==0xf4 or mid==0xf5
    or mid==0xfc or mid==0xfd or (def.renderPair or def.pair)=="pallet_outdoor" and (mid==0x284 or mid==0x287) then return "fence" end
  if cell.coll>=0xa0 and cell.coll<=0xa7 or mid==0x87 or mid==0x97
    or mid==0xb0 or mid==0xb1 or mid==0xc0 or mid==0xc1 then return "ledge" end
end
-- Measured shared Hoenn architecture; intervening IDs are grass, flowers or
-- compact crowns and must never join the building flood fill.
local hoennHouse={[0x08]=true,[0x09]=true,[0x0a]=true,[0x0b]=true,[0x10]=true,[0x11]=true,[0x12]=true,[0x13]=true,[0x18]=true,[0x19]=true,[0x1a]=true,[0x20]=true,[0x21]=true,[0x22]=true}
local hoennGym={[0x1aa]=true,[0x1ab]=true,[0x1ac]=true,[0x1b2]=true,[0x1b3]=true,[0x1b4]=true,[0x1b8]=true,[0x1b9]=true,[0x1ba]=true,[0x1bb]=true,[0x1bc]=true,[0x1c0]=true,[0x1c1]=true,[0x1c2]=true,[0x1c3]=true,[0x1c4]=true,[0x1c5]=true,[0x1c8]=true,[0x1c9]=true,[0x1ca]=true,[0x1cb]=true,[0x1cc]=true,[0x1cd]=true}
function Shapes.architectureFamily(def,mid)
  if emerald(def) then
    if (def.renderPair or def.pair)=='general__dewford'and(mid>=0x21a and mid<=0x21c or mid>=0x222 and mid<=0x224 or mid>=0x22b and mid<=0x22f or mid>=0x233 and mid<=0x237 or mid>=0x23b and mid<=0x23f)then return 'hoenn_gym' end
    if (def.renderPair or def.pair)=='general__sootopolis'and(mid>=0x282 and mid<=0x284 or mid>=0x28a and mid<=0x28c or mid==0x250)then return 'hoenn_gym' end
    if hoennHouse[mid]then return 'hoenn_primary_house' end
    if hoennGym[mid]then return 'hoenn_gym' end
    if (def.renderPair or def.pair)=='general__fortree' and (mid>=0x224 and mid<=0x226 or mid>=0x22b and mid<=0x22f or mid>=0x233 and mid<=0x237)then return 'hoenn_treehouse' end
    if (def.renderPair or def.pair)=='general__fortree' and (mid>=0x1b3 and mid<=0x1bf or mid>=0x1c0 and mid<=0x1c2)then return 'hoenn_gym' end
    if (def.renderPair or def.pair)=='general__petalburg' and mid>=0x208 and mid<=0x24b then return 'hoenn_house' end
    if (def.renderPair or def.pair)=='general__petalburg' and (mid>=0x26c and mid<=0x26e or mid>=0x274 and mid<=0x276
      or mid>=0x27c and mid<=0x27f or mid==0x284 or mid==0x286 or mid==0x287 or mid==0x28f)then return 'hoenn_house' end
    if mid>=0x28 and mid<=0x43 then return 'hoenn_mart' end
    if mid>=0x48 and mid<=0x63 then return 'hoenn_center' end
    return nil
  end
  if mid>=0x200 then return "secondary" end
  if mid>=0x140 and mid<=0x15f then return "gym" end
  if mid>=0x28 and mid<=0x47 then return "mart" end
  if mid>=0x48 and mid<=0x67 or mid>=0x17b and mid<=0x19f then return "center" end
end
function Shapes.architecture(def,mid)
  if (def.renderPair or def.pair)=="viridian_outdoor" and (mid==0x285 or mid==0x286 or mid==0x287 or mid==0x28d) then return false end
  return Shapes.architectureFamily(def,mid)~=nil
end
return Shapes
