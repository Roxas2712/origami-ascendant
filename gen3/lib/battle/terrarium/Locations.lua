-- Native Gen3 IDs -> the existing authored Kanto designs. Prefix removal alone
-- is insufficient: FR/LG gym, ship, lab and League names differ from Gen1.
local L={}
local exact={
 FR_PEWTER_CITY_GYM='PEWTER_GYM',FR_CERULEAN_CITY_GYM='CERULEAN_GYM',
 FR_VERMILION_CITY_GYM='VERMILION_GYM',FR_CELADON_CITY_GYM='CELADON_GYM',
 FR_FUCHSIA_CITY_GYM='FUCHSIA_GYM',FR_SAFFRON_CITY_GYM='SAFFRON_GYM',
 FR_CINNABAR_ISLAND_GYM='CINNABAR_GYM',FR_VIRIDIAN_CITY_GYM='VIRIDIAN_GYM',
 FR_SAFFRON_CITY_DOJO='FIGHTING_DOJO',FR_SSANNE_DECK='SS_ANNE_BOW',
 FR_PALLET_TOWN_PROFESSOR_OAKS_LAB='OAKS_LAB',
 FR_DIGLETTS_CAVE_B1F='DIGLETTS_CAVE',
}
function L.id(id)
 if type(id)~='string' or not id:match('^FR_')then return nil end
 return exact[id] or id:gsub('^FR_POKEMON_LEAGUE_',''):gsub('^FR_','')
end
function L.family(id,def,terrain)
 if id:find('FOREST') or id:find('PATTERN_BUSH')then return 'forest' end
 if id:find('SEAFOAM') or id:find('ICEFALL')then return 'ice'end
 if id:find('POKEMON_TOWER')then return 'tower'end
 if id:find('POWER_PLANT') or id:find('SILPH_CO') or id:find('ROCKET')then return 'industrial'end
 if id:find('SSANNE')then return 'ship'end
 if id:find('SAFARI')then return 'safari'end
 if tonumber(def.mapType)==4 or terrain==7 then return 'cave'end
 if terrain==2 or terrain==3 or terrain==4 or terrain==5 then return 'coast'end
 if id:find('GYM') or id:find('POKEMON_LEAGUE')then return 'gym'end
 if tonumber(def.mapType)==8 then return 'interior'end
 if tonumber(def.mapType)==1 then return 'city'end
 return 'grass'
end
function L.silphOccupied()
 local store=require('src.core.game3.scripting.space').getStore()
 return store and type(store.flags)=='table'
  and not require('src.core.game3.scripting.flags').getFlag(store,nil,0x53) or false
end
return L
