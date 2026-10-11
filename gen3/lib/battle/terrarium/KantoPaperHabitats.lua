-- FR and LG share native FR_ map identities. Resolve physical surfaces before
-- outdoor landmarks, but keep authored interiors (e.g. Misty's pool) intact.
local H={}
local function has(id,s)return id:find(s,1,true)~=nil end
local gyms={PEWTER='pewter',CERULEAN='cerulean',VERMILION='vermilion',CELADON='celadon',FUCHSIA='fuchsia',SAFFRON='saffron',CINNABAR='cinnabar',VIRIDIAN='viridian'}
local cities={PALLET_TOWN='pallet',VIRIDIAN_CITY='viridian',PEWTER_CITY='pewter',CERULEAN_CITY='cerulean',VERMILION_CITY='vermilion',LAVENDER_TOWN='lavender',CELADON_CITY='celadon',SAFFRON_CITY='saffron',FUCHSIA_CITY='fuchsia',CINNABAR_ISLAND='cinnabar',INDIGO_PLATEAU_EXTERIOR='indigo',ONE_ISLAND='one',TWO_ISLAND='two',THREE_ISLAND='three',FOUR_ISLAND='four',FIVE_ISLAND='five',SIX_ISLAND='six',SEVEN_ISLAND='seven'}
function H.resolve(id,def,terrain)
 if type(id)~='string'or not(id:match('^FR_')or id:match('^SEVII_'))then return nil end
 local originalId=id;id=id:gsub('^SEVII_','FR_')
 def=def or{};local mt=tonumber(def.mapType)
 if not mt then return nil end
 local function use(f,l)return{id=originalId,family=f,landmark=l,key=f..':'..(l or''),reason='shared Kanto paper habitat'}end
 local function k(name)return{id=originalId,family='kanto',landmark=name,key='kanto:'..name,reason='Kanto location paper assembly'}end
 for city,name in pairs(gyms)do if has(id,city..'_')and id:match('_GYM$')then return k(name..'_gym')end end
 local rooms={LORELEIS_ROOM='lorelei',BRUNOS_ROOM='bruno',AGATHAS_ROOM='agatha',LANCES_ROOM='lance',CHAMPIONS_ROOM='champion',HALL_OF_FAME='hall'}
 for part,key in pairs(rooms)do if has(id,'POKEMON_LEAGUE_'..part)then return k(key)end end
 if has(id,'BATTLE_COLOSSEUM')or has(id,'UNION_ROOM')or has(id,'TRADE_CENTER')or has(id,'RECORD_CORNER')then return k('link')end
 if has(id,'DOJO')then return k('dojo')end
 if has(id,'ROCKET_WAREHOUSE')then return k('warehouse')end
 if has(id,'ROCKET_HIDEOUT')then return k('rocket')end
 if has(id,'SILPH_CO')then return k('silph')end
 if has(id,'POKEMON_TOWER')then return k('tower')end
 if has(id,'POKEMON_MANSION')then return k('mansion')end
 if has(id,'POWER_PLANT')then return k('power')end
 if has(id,'TRAINER_TOWER')and mt~=3 then return k('trainer_tower')end
 if has(id,'SSANNE')then
  if has(id,'DECK')or has(id,'EXTERIOR')then return k('ship_deck')end
  if has(id,'KITCHEN')then return k('ship_kitchen')end
  if has(id,'CAPTAIN')then return k('captain')end
  return k('ship_cabin')
 end
 if has(id,'SEAFOAM')then return k('seafoam')end
 if has(id,'ICEFALL')then return k('icefall')end
 if has(id,'DOTTED_HOLE')then return k(has(id,'SAPPHIRE')and'sapphire'or'dotted')end
 if has(id,'TANOBY_KEY')then return k('tanoby_key')end
 if has(id,'TANOBY')and has(id,'CHAMBER')then return k('tanoby')end
 if has(id,'CERULEAN_CAVE')then return k('cerulean_cave')end
 if has(id,'MT_MOON')then return k('moon')end
 if has(id,'ROCK_TUNNEL')then return k('rock_tunnel')end
 if has(id,'DIGLETTS_CAVE')then return k('diglett')end
 if has(id,'VICTORY_ROAD')then return k('victory')end
 if has(id,'LOST_CAVE')then return k('lost')end
 if has(id,'ALTERING_CAVE')then return k('altering')end
 if has(id,'DUNSPARCE_TUNNEL')then return k('dunsparce')end
 if has(id,'RUBY_PATH')then return k('ruby')end
 if has(id,'UNDERGROUND_PATH')then return k('underground')end
 if has(id,'EMBER_SPA')then return k('spa')end
 if has(id,'INDIGO_PLATEAU_POKEMON_CENTER')then return k('league_reception')end
 if has(id,'HARBOR')and(mt==8 or mt==9)then return k('ferry_terminal')end
 -- Services and houses take priority over their town-name prefix.
 if mt==8 or mt==9 then
  if has(id,'POKEMON_CENTER')or has(id,'POKECENTER')then return k('center')end
  if has(id,'LAB')or has(id,'SEA_COTTAGE')then return k('lab')end
  if has(id,'MUSEUM')then return k('museum')end
  if has(id,'MART')or has(id,'SHOP')or has(id,'DEPARTMENT_STORE')then return k('shop')end
  if has(id,'GAME_CORNER')then return k('game_corner')end
  if has(id,'ENTRANCE')or has(id,'BUILDING')then return k('gate')end
  return k('house')
 end
 if terrain==5 then return use('pond')end
 if terrain==4 then return use('sea')end
 if has(id,'BIRTH_ISLAND')and has(id,'EXTERIOR')then return use('island','triangle')end
 if has(id,'NAVEL_ROCK')then
  if id=='FR_NAVEL_ROCK_SUMMIT'then return use('cave','sky')end
  if id=='FR_NAVEL_ROCK_BASE'then return use('cave','tide')end
  if has(id,'EXTERIOR')then return k('navel_exterior')end
  return k('navel_passage')
 end
 if id=='FR_SEVEN_ISLAND_TRAINER_TOWER'then return k('trainer_tower_exterior')end
 if id:match('^FR_ROUTE_1[678]$')then return k('cycling_road')end
 if id=='FR_ROUTE_3'or id=='FR_ROUTE_4'or id=='FR_ROUTE_9'or id=='FR_ROUTE_10'or id=='FR_ROUTE_23'then return k('rocky_route')end
 if id=='FR_ROUTE_12'or id=='FR_ROUTE_13'or has(id,'BOND_BRIDGE')then return k('pier_route')end
 if id=='FR_ONE_ISLAND_KINDLE_ROAD'then return k('kindle_road')end
 if has(id,'HARBOR')or has(id,'THREE_ISLAND_PORT')then return k('harbor')end
 if has(id,'MT_EMBER')then return k('ember')end
 if has(id,'MEMORIAL_PILLAR')then return k('memorial')end
 if has(id,'TANOBY_RUINS')then return k('tanoby_exterior')end
 if has(id,'RUIN_VALLEY')then return k('ruin_valley')end
 if has(id,'SEVAULT_CANYON')then return k('canyon')end
 if has(id,'BERRY_FOREST')then return k('berry')end
 if has(id,'PATTERN_BUSH')then return k('pattern')end
 if has(id,'FOREST')then return use('forest')end
 if has(id,'SAFARI_ZONE')then return use('safari')end
 local town=cities[id:sub(4)];if town then return k('town_'..town)end
 if mt==4 or terrain==7 then return use('cave')end
 if terrain==2 or has(id,'BEACH')then return use('coast')end
 if terrain==6 or has(id,'CAPE_BRINK')then return use('mountain')end
 if mt==6 then return use('sea')end
 if mt==1 or mt==2 then return k('town_three')end
 if mt==3 then return use('meadow',terrain==1 and'long_grass'or nil)end
 return k('house')
end
function H.resolveBattle(id,def,battle)
 battle=battle or{};local terrain=battle.terrain;local c=battle.encounterContext
 if battle.wild and type(c)=='table'and c.source=='fishing'and c.mapId==id and(c.terrain==4 or c.terrain==5)then terrain=c.terrain end
 return H.resolve(id,def,terrain)
end
return H
