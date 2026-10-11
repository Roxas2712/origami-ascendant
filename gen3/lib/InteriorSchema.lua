-- Shared room classification. Geometry may only use a measured source
-- template; unknown families keep their original cutouts, never guessed boxes.
local V=...
local S={}
local rules={
 {'GYM$','gym'},{'DOJO$','gym'},{'POKEMON_CENTER','center'},{'MART$','mart'},{'DEPARTMENT_STORE','mart'},
 {'LAB','lab'},{'SILPH','lab'},{'POKEMON_LAB','lab'},{'MUSEUM','museum'},{'GAME_CORNER','casino'},
 {'POKECENTER','center'},{'SSANNE','ship'},{'ROCKET_HIDEOUT','hideout'},{'ROCKET_WAREHOUSE','hideout'},{'POKEMON_LEAGUE','league'},{'TRAINER_TOWER','mart'},
 {'HOTEL','cozy'},{'RESTAURANT','cozy'},{'FAN_CLUB','cozy'},{'DAY_CARE','cozy'},{'SCHOOL','cozy'},{'COTTAGE','cozy'},{'SPA$','cozy'},{'BIKE_SHOP','mart'},
 {'HOUSE','home'},{'CONDOMINIUMS','home'},{'MANSION','home'},
}

function S.describe(def)
 local id=def.id or def.name or '';local pair=(def.renderPair or def.pair) or ''
 local kind='public'
 for _,r in ipairs(rules)do if id:match(r[1])then kind=r[2];break end end
 if id=='FR_CELADON_CITY_GYM'then kind='garden'
 elseif kind=='public' and (pair=='house' or pair=='player_house')then kind='home'end
 local outdoor=V.data('Shapes').outdoors(def)
 local mode='native-cutout';local template
 local rooms=V.require('DioramaConfig').interiors.rooms
 local community=V.require('InteriorCommunity').profile(def)
 if community then mode='measured-surfaces';template=community
 elseif pair=='oak_lab' and V.require('DioramaConfig').interiors.labSurfaces.rooms[id] then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.labSurfaces.rooms[id]
 elseif pair=='building__rom_082d4f5c' and def.midLayout and def.midLayout.width==10 and def.midLayout.height==10
  and def.midLayout:midAt(4,3)==0x291 and def.midLayout:midAt(8,1)==0x29b then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.schoolSurfaces
 elseif id:match('^FR_UNDERGROUND_PATH_%u+_ENTRANCE$') and pair=='house' and def.midLayout
  and def.midLayout.width==14 and def.midLayout.height==10 and def.midLayout:midAt(5,3)==0x2aa then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.transitSurfaces;kind='public'
 elseif V.require('InteriorElevator').profile(def)then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.elevatorSurfaces
 elseif V.require('DioramaConfig').interiors.departmentSurfaces.enabled and id:match('^FR_CELADON_CITY_DEPARTMENT_STORE_[1-5]F$') and pair=='building__rom_082d4e6c' and def.midLayout
  and def.midLayout.width==14 and def.midLayout.height==16 and def.midLayout:midAt(6,2)==(id:match('1F$')and 0x295 or 0x28e+tonumber(id:match('_(%d)F$'))) then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.departmentSurfaces
 elseif id=='FR_CERULEAN_CITY_BIKE_SHOP' and pair=='building__rom_082d4c5c' and def.midLayout
  and def.midLayout.width==12 and def.midLayout.height==10 and def.midLayout:midAt(8,2)==0x290 then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.bikeShopSurfaces
 elseif pair=='building__rom_082d4f74' and def.midLayout and def.midLayout.width==12
  and V.require('DioramaConfig').interiors.clubSurfaces.rooms[id]
  and def.midLayout.height==(id=='FR_VERMILION_CITY_POKEMON_FAN_CLUB'and 12 or 10)
  and def.midLayout:midAt(0,0)==(id=='FR_VERMILION_CITY_POKEMON_FAN_CLUB'and 0x281 or 0x284)then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.clubSurfaces.rooms[id]
 elseif id=='FR_CELADON_CITY_HOTEL' and pair=='building__rom_082d4f44' and def.midLayout
  and def.midLayout.width==18 and def.midLayout.height==12 and def.midLayout:midAt(9,4)==0x294 then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.hotelSurfaces
 elseif id=='FR_CELADON_CITY_RESTAURANT' and pair=='building__rom_082d4f44' and def.midLayout
  and def.midLayout.width==16 and def.midLayout.height==12 and def.midLayout:midAt(10,7)==0x2d9 then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.restaurantSurfaces
 elseif pair=='building__rom_082d4c2c' and def.midLayout
  and V.require('DioramaConfig').interiors.museumSurfaces.rooms[id]
  and def.midLayout.width==(id:match('1F$')and 28 or 20) then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.museumSurfaces.rooms[id]
 elseif V.require('DioramaConfig').interiors.condoSurfaces.enabled~=false and pair=='building__rom_082d4f8c' and id:match('^FR_CELADON_CITY_CONDOMINIUMS_[123]F$')
  and def.midLayout and def.midLayout.width==16 and def.midLayout.height==20 and def.midLayout:midAt(7,0)==0x28c then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.condoSurfaces
 elseif V.require('InteriorShipCorridors').profile(def)then
  mode='measured-surfaces';template=V.require('InteriorShipCorridors').profile(def)
 elseif V.require('InteriorShipPublic').profile(def)then
  mode='measured-surfaces';template=V.require('InteriorShipPublic').profile(def)
 elseif V.require('InteriorShipCabins').profile(def)then
  mode='measured-surfaces';template=V.require('InteriorShipCabins').profile(def)
 elseif V.require('InteriorHouseVariants').profile(def)then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.houseVariants
 elseif V.require('InteriorIndigoReception').profile(def)then
  mode='measured-surfaces';template=V.require('InteriorIndigoReception').profile(def)
 elseif V.require('InteriorCasino').profile(def)then
  mode='measured-surfaces';template=V.require('InteriorCasino').profile(def)
 elseif V.require('InteriorCelio').profile(def)then
  mode='measured-surfaces';template=V.require('InteriorCelio').profile(def)
 elseif rooms[id]then mode='measured-surfaces';template=rooms[id]
 elseif pair=='network' and def.midLayout and def.midLayout.width==16 and def.midLayout.height==10
  and def.midLayout:midAt(4,2)==0x2b1 then
  mode='measured-surfaces';template=rooms.FR_VIRIDIAN_CITY_POKEMON_CENTER_1F
 elseif pair=='network' and def.midLayout and def.midLayout.width==16 and def.midLayout.height==10
  and def.midLayout:midAt(8,1)==0x2fe and def.midLayout:midAt(12,1)==0x2fe then
  mode='measured-surfaces';template=V.require('DioramaConfig').interiors.centerUpstairs
 elseif pair=='building__rom_082d4bcc' and def.midLayout and def.midLayout.width==12 and def.midLayout.height==10 then
  mode='measured-surfaces';template=rooms.FR_VIRIDIAN_CITY_MART
 elseif (pair=='player_house' or pair=='house') and def.midLayout then
  for _,cell in ipairs(def.midLayout.cells)do
   if cell.mid==0x4c or cell.mid==0x128 or cell.mid==0xc8 then
    mode='measured-surfaces';template=V.require('DioramaConfig').interiors.homeSurfaces;break
   end
  end
 end
 if outdoor then mode='outdoor';template=nil end
 return {id=id,family=pair,lighting=kind,mode=mode,profile=template,
  floor='native-ground-and-rugs',actors=mode=='measured-surfaces' and 'native-feet' or 'cutout-aligned-feet',materials='native-atlas-nearest',
  lights=template and 'authored-fixed-anchors' or 'walkable-ceiling-grid',
  special=id:match('POKEMON_TOWER') and 'haunted' or id:match('GYM$') and 'badge-light' or nil}
end
return S
