-- Resolve the actual encounter surface before broad location families. In
-- particular Route 111 is not all desert, and fishing is not a land battle.
local H={}
local function has(id,s)return id:find(s,1,true)~=nil end
local gyms={RUSTBORO_CITY='rock',DEWFORD_TOWN='fighting',MAUVILLE_CITY='electric',
 LAVARIDGE_TOWN='steam',PETALBURG_CITY='normal',FORTREE_CITY='sky',MOSSDEEP_CITY='psychic',SOOTOPOLIS_CITY='water'}
-- Emerald uses OCEAN_WATER for these inland rivers/lakes as well. Native
-- terrain 4 alone therefore cannot justify a coral reef or Kyogre event.
local freshwater={EM_ROUTE103=true,EM_ROUTE114=true,EM_ROUTE119=true,EM_ROUTE120=true}
function H.resolve(id,def,terrain)
 id=tostring(id or'');def=def or{};local mt=tonumber(def.mapType)
 local p={id=id,family='meadow',landmark=nil,reason='outdoor vegetation'}
 local function use(f,l,r)p.family=f;p.landmark=l;p.reason=r or'location';p.key=f..':'..(l or'');return p end
 if mt==5 or has(id,'UNDERWATER')then
  local landmark=has(id,'SEALED_CHAMBER')and'braille'or has(id,'ABANDONED_SHIP')and'wreck'
   or has(id,'SOOTOPOLIS')and'crater'or has(id,'SEAFLOOR_CAVERN')and'cavern'or has(id,'MARINE_CAVE')and'marine'or nil
  return use('underwater',landmark,'submerged map')
 end
 if has(id,'_GYM')then
  for city,kind in pairs(gyms)do if has(id,city)then return use('gym',kind,'Hoenn gym')end end
 end
 if has(id,'SIDNEYS_ROOM')then return use('league','dark')end
 if has(id,'PHOEBES_ROOM')then return use('league','ghost')end
 if has(id,'GLACIAS_ROOM')then return use('league','ice')end
 if has(id,'DRAKES_ROOM')then return use('league','dragon')end
 if has(id,'CHAMPIONS_ROOM')then return use('league','champion')end
 if has(id,'HALL_OF_FAME')then return use('league','hall')end
 if has(id,'SHOAL_CAVE')then
  if has(id,'ICE_ROOM')then return use('ice')end
  return use('watercave',has(id,'HIGH_TIDE')and'tide'or'salt')
 end
 if has(id,'MAGMA_HIDEOUT')then return use('lava','magma')end
 if has(id,'AQUA_HIDEOUT')then return use('industrial','aqua')end
 if has(id,'FIERY_PATH')or has(id,'TERRA_CAVE')then return use('lava',has(id,'TERRA_CAVE')and'ancient'or'path')end
 if has(id,'MT_CHIMNEY')and mt~=8 then return use('volcano')end
 if has(id,'JAGGED_PASS')then return use('mountain','ash')end
 if has(id,'METEOR_FALLS')then return use('watercave','meteor')end
 if has(id,'SEAFLOOR_CAVERN')or has(id,'MARINE_CAVE')then return use('watercave',has(id,'MARINE_CAVE')and'marine'or'seafloor')end
 if has(id,'CAVE_OF_ORIGIN')then return use('cave','origin')end
 if id=='EM_RUSTURF_TUNNEL'then return use('cave','rusturf','hand-dug Rusturf passage')end
 if has(id,'ARTISAN_CAVE')then return use('cave','artisan','Smeargle habitat')end
 if id=='EM_ALTERING_CAVE'then return use('cave','altering','isolated Altering Cave')end
 if has(id,'DESERT_RUINS')then return use('ruins','regirock')end
 if has(id,'ANCIENT_TOMB')then return use('ruins','registeel')end
 if has(id,'ISLAND_CAVE')then return use('ruins','regice')end
 if has(id,'SEALED_CHAMBER')then return use('ruins','braille')end
 if has(id,'MIRAGE_TOWER')then return use('ruins','sand')end
 if has(id,'SKY_PILLAR')then return use('ruins',(has(id,'TOP')or has(id,'OUTSIDE'))and'sky'or nil)end
 if has(id,'DESERT_UNDERPASS')or has(id,'FOSSIL_MANIACS_TUNNEL')then return use('cave','fossil')end
 if has(id,'NEW_MAUVILLE')then return use('industrial','electric')end
 if has(id,'MT_PYRE')then return use((has(id,'EXTERIOR')or has(id,'SUMMIT'))and'mountain'or'tower','memorial')end
 if has(id,'ABANDONED_SHIP')then return use('ship','wreck')end
 if has(id,'SS_TIDAL')or has(id,'INSIDE_OF_TRUCK')then return use('ship',has(id,'TRUCK')and'truck'or'liner')end
 if has(id,'NAVEL_ROCK')then return use('cave',has(id,'TOP')and'sky'or has(id,'BOTTOM')and'tide'or nil)end
 if has(id,'BIRTH_ISLAND')then return use('island','triangle')end
 if has(id,'FARAWAY_ISLAND')then return use('forest','ancient')end
 if has(id,'SOUTHERN_ISLAND')then return use('forest','island')end
 if has(id,'SECRET_BASE')then
  if has(id,'CAVE')then return use('cave','base')end
  return use('interior',has(id,'TREE')and'wood'or'garden')
 end
 if has(id,'BATTLE_PYRAMID')then return use('ruins','pyramid')end
 if has(id,'TRAINER_HILL')then return use('facility','hill')end
 if has(id,'BATTLE_TENT')then
  return use('facility',has(id,'VERDANTURF')and'tent_verdanturf'or has(id,'FALLARBOR')and'tent_fallarbor'or'tent_slateport')
 end
 if has(id,'BATTLE_COLOSSEUM')then return use('facility','link')end
 if has(id,'BATTLE_FRONTIER_BATTLE_')and mt==8 then
  for _,name in ipairs({'ARENA','DOME','FACTORY','PALACE','PIKE','TOWER','TENT'})do if has(id,name)then return use('facility',name:lower())end end
  return use('facility','tower')
 end
 if mt==8 or mt==9 then
  if has(id,'SPACE_CENTER')then return use('industrial','space')end
  if has(id,'DEVON_CORP')then return use('industrial','devon')end
  if has(id,'WEATHER_INSTITUTE')then return use('industrial','weather')end
  if has(id,'LAB')then return use('industrial','lab')end
  if has(id,'HARBOR')or has(id,'SHIPYARD')then return use('ship','harbor')end
  if has(id,'POKEMON_CENTER')then return use('interior','center')end
  if id:match('_MART$')or has(id,'DEPARTMENT_STORE')then return use('interior','shop')end
  if has(id,'CONTEST')then return use('facility','contest')end
  if has(id,'TRICK_HOUSE')then return use('interior','puzzle')end
  if has(id,'MUSEUM')then return use('interior','museum')end
  return use('interior','wood')
 end
 if mt==4 then return use('cave',has(id,'GRANITE')and'granite'or has(id,'VICTORY_ROAD')and'victory'or nil)end
 -- Native terrain IDs: grass 0, long grass 1, sand 2, underwater 3,
 -- water 4, pond 5, mountain 6, cave 7, building 8, plain 9.
 if terrain==3 then return use('underwater',nil,'native underwater terrain')end
 if terrain==4 or terrain==5 then
  if freshwater[id]or has(id,'SAFARI_ZONE')then return use('pond',nil,'inland river or lake encounter')end
  if id=='EM_PACIFIDLOG_TOWN'then return use('sea','pacifidlog','water beside floating town')end
  if id=='EM_SOOTOPOLIS_CITY'then return use('sea','sootopolis','water inside crater city')end
 end
 if terrain==4 then return use('sea',nil,'encounter on water')end
 if terrain==5 then return use('pond',nil,'encounter on pond')end
 -- ASHGRASS and ordinary ash on Route 113 resolve to native SAND (2),
 -- not GRASS (0). Preserve this biome before generic beach selection.
 if id=='EM_ROUTE113'then return use('ash')end
 if has(id,'SAFARI_ZONE')then return use('safari')end
 if id=='EM_ROUTE111'and terrain==2 then return use('desert',nil,'desert sand encounter')end
 if terrain==2 then return use('coast',nil,'sand encounter')end
 if has(id,'PETALBURG_WOODS')then return use('forest')end
 if id=='EM_ROUTE119'or id=='EM_ROUTE120' then return use('rainforest')end
 if id=='EM_BATTLE_FRONTIER_OUTSIDE_EAST'or id=='EM_BATTLE_FRONTIER_OUTSIDE_WEST'then return use('city','frontier')end
 if id=='EM_FORTREE_CITY'then return use('treecity')end
 if id=='EM_PACIFIDLOG_TOWN'then return use('floating')end
 if id=='EM_SOOTOPOLIS_CITY'then return use('crater')end
 if mt==1 or mt==2 then return use('city',id:gsub('^EM_',''):gsub('_CITY$',''):gsub('_TOWN$',''):lower(),'named Hoenn town')end
 if mt==6 then return use('sea')end
 local route=tonumber(id:match('^EM_ROUTE(%d+)$'))
 if route and(route>=105 and route<=109 or route==122 or route>=124)then return use('coast')end
 if terrain==6 or route==112 or route==114 then return use('mountain')end
 return use('meadow',terrain==1 and'long_grass'or nil)
end
-- A shore angler stands on land. Choose scenery from the hooked water while
-- keeping battle.terrain untouched for Nature Power and other native rules.
function H.resolveBattle(id,def,battle,worldState)
 battle=battle or{}
 local terrain=battle.terrain
 local c=battle.encounterContext
 if battle.wild and type(c)=='table'and c.source=='fishing'and c.mapId==id
  and(c.terrain==4 or c.terrain==5)then terrain=c.terrain end
 -- Shoal changes the layout of the low-tide map in place. Its map ID does
 -- not change; use the native tide flag for the two interchangeable rooms.
 if worldState and worldState.shoalHighTide==true and
  (id=='EM_SHOAL_CAVE_LOW_TIDE_ENTRANCE_ROOM'or id=='EM_SHOAL_CAVE_LOW_TIDE_INNER_ROOM')then
  local p=H.resolve(id:gsub('LOW_TIDE','HIGH_TIDE'),def,terrain)
  p.id=id;p.reason='native Shoal high-tide layout';return p
 end
 return H.resolve(id,def,terrain)
end
return H
