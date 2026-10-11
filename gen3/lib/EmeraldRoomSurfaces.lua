-- Edition-specific source measurements. Native map cells remain untouched.
local V=...
local E={}
local Budget=V.require('BuildBudget')
-- Provider initialization may load many independent room modules. Yield only
-- inside the geometry queue; direct tools and runtime lookups stay synchronous.
local function provider(name)
 local module=V.require(name);Budget.check();return module
end
function E.profile(def)
 local cfg=provider('DioramaConfig').emeraldInteriors
 if not cfg.enabled then return end
 if provider('EmeraldNewMauville').profile(def)then return provider('EmeraldNewMauville').profile(def)end
 if provider('EmeraldWreckRooms').profile(def)then return provider('EmeraldWreckRooms').profile(def)end
 if provider("EmeraldSecretBases").kind(def)then return provider("EmeraldSecretBases").profile(def)end
 if provider("EmeraldCableRooms").hasId(def)then return provider("EmeraldCableRooms").profile(def)end
 if provider("EmeraldFossilTunnel").kind(def)then return provider("EmeraldFossilTunnel").profile(def)end
 local id=def.id or def.name
 if id=="EM_TRAINER_HILL_ROOF"then return provider("EmeraldTrainerHillRoof").profile(def)end
 if id=="EM_TRAINER_HILL_ENTRANCE"then return provider("EmeraldTrainerHillEntrance").profile(def)end
 if id and(id:match("^EM_TRAINER_HILL_[1-4]F$")or id=="EM_TRAINER_HILL_ELEVATOR")then return provider("EmeraldTrainerHill").profile(def)end
 if id=="EM_INSIDE_OF_TRUCK"then return provider("EmeraldTruck").profile(def)end
 if id=="EM_SOOTOPOLIS_CITY_MYSTERY_EVENTS_HOUSE_1F"or id=="EM_SOOTOPOLIS_CITY_MYSTERY_EVENTS_HOUSE_B1F"then return provider("EmeraldMysteryHouse").profile(def)end
 if id=="EM_ROUTE110_TRICK_HOUSE_PUZZLE5"then return provider("EmeraldTrickQuiz").profile(def)end
 if id=="EM_ROUTE110_TRICK_HOUSE_PUZZLE8"then return provider("EmeraldTrickSlide").profile(def)end
 if id=="EM_ROUTE110_TRICK_HOUSE_PUZZLE3"then return provider("EmeraldTrickDoors").profile(def)end
 if id=="EM_ROUTE110_TRICK_HOUSE_PUZZLE2"or id=="EM_ROUTE110_TRICK_HOUSE_PUZZLE4"or id=="EM_ROUTE110_TRICK_HOUSE_PUZZLE6"or id=="EM_ROUTE110_TRICK_HOUSE_PUZZLE7"then return provider("EmeraldTrickSteps").profile(def)end
 if id=="EM_ROUTE110_TRICK_HOUSE_PUZZLE1"then return provider("EmeraldTrickMaze").profile(def)end
 if id=="EM_ROUTE110_TRICK_HOUSE_CORRIDOR"then return provider("EmeraldTrickCorridor").profile(def)end
 if id=="EM_ROUTE110_TRICK_HOUSE_ENTRANCE"or id=="EM_ROUTE110_TRICK_HOUSE_END"then return provider("EmeraldTrickHouse").profile(def)end
 if provider("EmeraldAquaOperations").kind(def)then return provider("EmeraldAquaOperations").profile(def)end
 if provider("EmeraldAquaBasement").kind(def)then return provider("EmeraldAquaBasement").profile(def)end
 if provider("EmeraldAquaHideout").kind(def)then return provider("EmeraldAquaHideout").profile(def)end
 if provider("EmeraldPyramidTop").kind(def)then return provider("EmeraldPyramidTop").profile(def)end
 if provider("EmeraldPyramidLobby").kind(def)then return provider("EmeraldPyramidLobby").profile(def)end
 if provider("EmeraldPyramidFloor").kind(def)then return provider("EmeraldPyramidFloor").profile(def)end
 if provider("EmeraldBattlePike").kind(def)then return provider("EmeraldBattlePike").profile(def)end
 if provider("EmeraldBattlePalace").kind(def)then return provider("EmeraldBattlePalace").profile(def)end
 if provider("EmeraldBattleFactory").kind(def)then return provider("EmeraldBattleFactory").profile(def)end
 if provider("EmeraldBattleDome").kind(def)then return provider("EmeraldBattleDome").profile(def)end
 if provider("EmeraldBattleArena").kind(def)then return provider("EmeraldBattleArena").profile(def)end
 if provider("EmeraldTowerChallengeRooms").kind(def)then return provider("EmeraldTowerChallengeRooms").profile(def)end
 if provider("EmeraldTowerPublic").kind(def)then return provider("EmeraldTowerPublic").profile(def)end
 if id=="EM_BATTLE_FRONTIER_RANKING_HALL"then return provider("EmeraldFrontierRanking").profile(def)end
 if id=="EM_BATTLE_FRONTIER_RECEPTION_GATE"then return provider("EmeraldFrontierReception").profile(def)end
 if id=="EM_BATTLE_FRONTIER_EXCHANGE_SERVICE_CORNER"then return provider("EmeraldFrontierExchange").profile(def)end
 if id and id:match("^EM_BATTLE_FRONTIER_LOUNGE[1-9]$")then return provider("EmeraldFrontierLounges").profile(def)end
 if id=="EM_EVER_GRANDE_CITY_CHAMPIONS_ROOM"then return provider("EmeraldChampionRoom").profile(def)end
 if id=="EM_EVER_GRANDE_CITY_HALL_OF_FAME"then return provider("EmeraldHallOfFame").profile(def)end
 if id=="EM_EVER_GRANDE_CITY_POKEMON_LEAGUE_1F"or id=="EM_EVER_GRANDE_CITY_POKEMON_LEAGUE_2F"then return provider("EmeraldLeagueReception").profile(def)end
 if provider('EmeraldLeagueRooms').kind(def)then return provider('EmeraldLeagueRooms').profile(def)end
 if id=='EM_MAUVILLE_CITY_BIKE_SHOP'and(def.pair~='general__bike_shop'or not def.midLayout or def.midLayout.width~=12 or def.midLayout.height~=10 or def.midLayout:midAt(2,3)~=0x21b)then return end
 if id=='EM_LILYCOVE_CITY_DEPARTMENT_STORE_1F'and(def.pair~='building__shop'or not def.midLayout or def.midLayout.width~=18 or def.midLayout.height~=8 or def.midLayout:midAt(8,7)~=0x216)then return end
 if id=='EM_LILYCOVE_CITY_DEPARTMENT_STORE_ELEVATOR'and(def.pair~='building__battle_frontier'or not def.midLayout or def.midLayout.width~=6 or def.midLayout.height~=6 or def.midLayout:midAt(0,0)~=0x328 or def.midLayout:midAt(2,5)~=0x257)then return end
 if id=='EM_LILYCOVE_CITY_DEPARTMENT_STORE_ROOFTOP'and(def.pair~='building__shop'or not def.midLayout or def.midLayout.width~=18 or def.midLayout.height~=12 or def.midLayout:midAt(9,0)~=0x26f or def.midLayout:midAt(13,3)~=0x25f)then return end
 local retail=({EM_LILYCOVE_CITY_DEPARTMENT_STORE_2F=0x2a7,EM_LILYCOVE_CITY_DEPARTMENT_STORE_3F=0x2af,EM_LILYCOVE_CITY_DEPARTMENT_STORE_4F=0x2b7,EM_LILYCOVE_CITY_DEPARTMENT_STORE_5F=0x2bf})[id]
 if retail and(def.pair~='building__shop'or not def.midLayout or def.midLayout.width~=18 or def.midLayout.height~=8 or def.midLayout:midAt(2,2)~=retail)then return end
 if id=='EM_LILYCOVE_CITY_CONTEST_LOBBY'or id=='EM_LILYCOVE_CITY_CONTEST_HALL'or(id or''):match('^EM_CONTEST_HALL')then return provider('EmeraldContestRooms').profile(def)end
 if id=='EM_SOOTOPOLIS_CITY_GYM_1F'or id=='EM_SOOTOPOLIS_CITY_GYM_B1F'then return provider('EmeraldSootopolisGym').profile(def)end
 if id=='EM_MOSSDEEP_CITY_GYM'then return provider('EmeraldMossdeepGym').profile(def)end
 if id=='EM_FORTREE_CITY_GYM'then return provider('EmeraldFortreeGym').profile(def)end
 if id=='EM_PETALBURG_CITY_GYM'then return provider('EmeraldPetalburgGym').profile(def)end
 if id=='EM_LAVARIDGE_TOWN_GYM_1F'or id=='EM_LAVARIDGE_TOWN_GYM_B1F'then return provider('EmeraldLavaridgeGym').profile(def)end
 if id=='EM_MAUVILLE_CITY_GYM'then return provider('EmeraldMauvilleGym').profile(def)end
 if id=='EM_DEWFORD_TOWN_GYM'then return provider('EmeraldDewfordGym').profile(def)end
 if id=='EM_RUSTBORO_CITY_GYM'then return provider('EmeraldRustboroGym').profile(def)end
 if (id or''):match('^EM_MT_PYRE_[1-6]F$')then return provider('EmeraldPyre').profile(def)end
 if id=='EM_SS_TIDAL_ROOMS'then return provider('EmeraldShipCabins').profile(def)end
 if id=='EM_SS_TIDAL_CORRIDOR'then return provider('EmeraldShipCorridor').profile(def)end
 if id=='EM_SS_TIDAL_LOWER_DECK'then return provider('EmeraldShipInteriors').profile(def)end
 if (id or''):match('^EM_RUSTBORO_CITY_DEVON_CORP_')then return provider('EmeraldDevon').profile(def)end
 if (id or''):match('^EM_ROUTE119_WEATHER_INSTITUTE_')then return provider('EmeraldWeatherInstitute').profile(def)end
 if (id or''):match('^EM_MOSSDEEP_CITY_SPACE_CENTER_')then return provider('EmeraldSpaceCenter').profile(def)end
 if id=='EM_LAVARIDGE_TOWN_HERB_SHOP'then return provider('EmeraldHerbShop').profile(def)end
 if id=='EM_ROUTE121_SAFARI_ZONE_ENTRANCE'then return provider('EmeraldSafariEntrance').profile(def)end
 if id=='EM_ROUTE117_POKEMON_DAY_CARE'then return provider('EmeraldDayCare').profile(def)end
 if (id or''):match('^EM_SLATEPORT_CITY_STERNS_SHIPYARD_')then return provider('EmeraldShipyard').profile(def)end
 local edition=V.data('Emerald')
 if (edition.homeRooms[id]or''):match('^station')then return provider('EmeraldStations').profile(def)end
 if edition.homeRooms[id]=='transitCycle'then return provider('EmeraldTransit').profile(def)end
 if (edition.homeRooms[id]or''):match('^tent')then return provider('EmeraldBattleTents').profile(def)end
 if edition.homeRooms[id]=='mauvilleCorner'then return provider('EmeraldMauvilleCorner').profile(def)end
 if(edition.homeRooms[id]or''):match('^moss')then return provider('EmeraldMossdeepClub').profile(def)end
 if edition.homeRooms[id]=="fanClub"then return provider("EmeraldFanClub").profile(def)end
 if (edition.homeRooms[id]or''):match('^art')then return provider('EmeraldArtMuseum').profile(def)end
 if (edition.homeRooms[id]or''):match('^ocean')then return provider('EmeraldOceanMuseum').profile(def)end
 if edition.homeRooms[id]=='flowerShop'then return provider('EmeraldFlowerShop').profile(def)end
 if (edition.homeRooms[id]or''):match('^workshop')then return provider('EmeraldWorkshopSurfaces').profile(def)end
 if (edition.homeRooms[id]or''):match('^guest')then return provider('EmeraldGuestSurfaces').profile(def)end
 if edition.homeRooms[id]=='apartment'then return provider('EmeraldApartmentSurfaces').profile(def)end
 return cfg.rooms[id] or cfg.publicRooms[edition.publicRooms[id]] or cfg.homeRooms[edition.homeRooms[id]]
end
function E.plan(def)
 local profile=E.profile(def);if not profile then return end
 if profile.family=='wreckUnderwater'then return V.require('EmeraldWreckUnderwater').plan(def)end
 if profile.family=='wreckCorridor'then return V.require('EmeraldWreckCorridors').plan(def)end
 if profile.family=='wreckCabins'then return V.require('EmeraldWreckCabins').plan(def)end
 if profile.family=='newMauville'then return V.require('EmeraldNewMauville').plan(def)end
 if profile.family=='wreckOffice'then return V.require('EmeraldWreckRooms').plan(def)end
 if profile.family=='secretBase'then return V.require('EmeraldSecretBases').plan(def)end
 if profile.family=='trickDoors'then return V.require('EmeraldTrickDoors').plan(def)end
 if profile.family=='fossilTunnel'then return V.require('EmeraldFossilTunnel').plan(def)end
 if profile.family=='cableRoom'then return V.require('EmeraldCableRooms').plan(def)end
 if profile.family=='hillRoof'then return V.require('EmeraldTrainerHillRoof').plan(def)end
 if profile.family=='hillEntrance'then return V.require('EmeraldTrainerHillEntrance').plan(def)end
 if profile.family=='trainerHill'then return V.require('EmeraldTrainerHill').plan(def)end
 if profile.family=='truck'then return V.require('EmeraldTruck').plan(def)end
 if profile.family=='mysteryHouse'then return V.require('EmeraldMysteryHouse').plan(def)end
 if profile.family=='trickQuiz'then return V.require('EmeraldTrickQuiz').plan(def)end
 if profile.family=='trickSlide'then return V.require('EmeraldTrickSlide').plan(def)end
 if profile.family=='trickSteps'then return V.require('EmeraldTrickSteps').plan(def)end
 if profile.family=='trickMaze'then return V.require('EmeraldTrickMaze').plan(def)end
 if profile.family=='trickCorridor'then return V.require('EmeraldTrickCorridor').plan(def)end
 if profile.family=='trickHome'then return V.require('EmeraldTrickHouse').plan(def)end
 if profile.family=='aquaOperations'then return V.require('EmeraldAquaOperations').plan(def)end
 if profile.family=='aquaBasement'then return V.require('EmeraldAquaBasement').plan(def)end
 if profile.family=='aquaEntry'then return V.require('EmeraldAquaHideout').plan(def)end
 if profile.family=='pyramidTop'then return V.require('EmeraldPyramidTop').plan(def)end
 if profile.family=='pyramidLobby'then return V.require('EmeraldPyramidLobby').plan(def)end
 if profile.family=='pyramidFloor'then return V.require('EmeraldPyramidFloor').plan(def)end
 if profile.family=='battlePike'then return V.require('EmeraldBattlePike').plan(def)end
 if profile.family=='battlePalace'then return V.require('EmeraldBattlePalace').plan(def)end
 if profile.family=='battleFactory'then return V.require('EmeraldBattleFactory').plan(def)end
 if profile.family=='battleDome'then return V.require('EmeraldBattleDome').plan(def)end
 if profile.family=='battleArena'then return V.require('EmeraldBattleArena').plan(def)end
 if profile.family=='towerChallenge'then return V.require('EmeraldTowerChallengeRooms').plan(def)end
 if profile.family=='towerPublic'then return V.require('EmeraldTowerPublic').plan(def)end
 if profile.family=='frontierRanking'then return V.require('EmeraldFrontierRanking').plan(def)end
 if profile.family=='frontierReception'then return V.require('EmeraldFrontierReception').plan(def)end
 if profile.family=='frontierExchange'then return V.require('EmeraldFrontierExchange').plan(def)end
 if profile.family=='frontierLounge'then return V.require('EmeraldFrontierLounges').plan(def)end
 if profile.family=='championRoom'then return V.require('EmeraldChampionRoom').plan(def)end
 if profile.family=='hallOfFame'then return V.require('EmeraldHallOfFame').plan(def)end
 if profile.family=='leagueReception'then return V.require('EmeraldLeagueReception').plan(def)end
 if profile.family=='league'then return V.require('EmeraldLeagueRooms').plan(def)end
 if profile.family=='contest'then return V.require('EmeraldContestRooms').plan(def)end
 if profile.family=='sootopolisGym'then return V.require('EmeraldSootopolisGym').plan(def)end
 if profile.family=='mossdeepGym'then return V.require('EmeraldMossdeepGym').plan(def)end
 if profile.family=='fortreeGym'then return V.require('EmeraldFortreeGym').plan(def)end
 if profile.family=='petalburgGym'then return V.require('EmeraldPetalburgGym').plan(def)end
 if profile.family=='lavaridgeGym'then return V.require('EmeraldLavaridgeGym').plan(def)end
 if profile.family=='mauvilleGym'then return V.require('EmeraldMauvilleGym').plan(def)end
 if profile.family=='dewfordGym'then return V.require('EmeraldDewfordGym').plan(def)end
 if profile.family=='rustboroGym'then return V.require('EmeraldRustboroGym').plan(def)end
 if profile.family=='pyre'then return V.require('EmeraldPyre').plan(def)end
 if profile.family=='shipCabins'then return V.require('EmeraldShipCabins').plan(def)end
 if profile.family=='shipCorridor'then return V.require('EmeraldShipCorridor').plan(def)end
 if profile.family=='ship'then return V.require('EmeraldShipInteriors').plan(def)end
 if profile.family=='devon'then return V.require('EmeraldDevon').plan(def,profile)end
 if profile.family=='weatherInstitute'then return V.require('EmeraldWeatherInstitute').plan(def,profile)end
 if profile.family=='spaceCenter'then return V.require('EmeraldSpaceCenter').plan(def,profile)end
 if profile.family=='herbShop'then return V.require('EmeraldHerbShop').plan(def)end
 if profile.family=='safariEntrance'then return V.require('EmeraldSafariEntrance').plan(def)end
 if profile.family=='dayCare'then return V.require('EmeraldDayCare').plan(def)end
 if profile.family=='shipyard'then return V.require('EmeraldShipyard').plan(def,profile)end
 if profile.family=='station'then return V.require('EmeraldStations').plan(def,profile)end
 if profile.family=='transit'then return V.require('EmeraldTransit').plan(def,profile)end
 if profile.family=='battleTent'then return V.require('EmeraldBattleTents').plan(def,profile)end
 if profile.family=='mauvilleCorner'then return V.require('EmeraldMauvilleCorner').plan(def)end
 if profile.family=='mossdeepClub'then return V.require('EmeraldMossdeepClub').plan(def,profile)end
 if profile.family=='fanClub'then return V.require('EmeraldFanClub').plan(def)end
 if profile.family=='artMuseum'then return V.require('EmeraldArtMuseum').plan(def,profile)end
 if profile.family=='oceanMuseum'then return V.require('EmeraldOceanMuseum').plan(def,profile)end
 if profile.family=='flowerShop'then return V.require('EmeraldFlowerShop').plan(def,profile)end
 if profile.family=='workshop'then return V.require('EmeraldWorkshopSurfaces').plan(def,profile)end
 if profile.family=='guest'then return V.require('EmeraldGuestSurfaces').plan(def,profile)end
 if profile.family=='apartment'then return V.require('EmeraldApartmentSurfaces').plan(def,profile)end
 if profile.family=='department'then return V.require('EmeraldDepartmentSurfaces').plan(def,profile)end
 if profile.family=='bikeShop'then return V.require('EmeraldBikeShopSurfaces').plan(def,profile)end
 if profile.family=='specialHome' then return V.require('EmeraldSpecialSurfaces').plan(def,profile)end
 if profile.family=='timberHome' then return V.require('EmeraldTimberSurfaces').plan(def,profile)end
 if profile.family=='woodHome' then return V.require('EmeraldWoodHomeSurfaces').plan(def,profile)end
 if profile.family=='tileHome' then return V.require('EmeraldTileHomeSurfaces').plan(def,profile)end
 if profile.family=='carpetHome' then return V.require('EmeraldCarpetSurfaces').plan(def,profile)end
 if profile.family=='tatamiHome' then return V.require('EmeraldTatamiSurfaces').plan(def,profile)end
 if profile.family=='rugHome' or profile.family=='kitchenHome' then return V.require('EmeraldHomeSurfaces').plan(def,profile)end
 if profile.family=='center' or profile.family=='link' or profile.family=='mart' then return V.require('EmeraldPublicSurfaces').plan(def,profile)end
 local L=def.midLayout;local cfg=V.require('DioramaConfig').emeraldInteriors
 local objects,mask={},{ };local floor=profile.floor
 local function claim(x,y,w,h,donor)
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   if xx>=0 and yy>=0 and xx<L.width and yy<L.height then
    local k=yy*L.width+xx+1
    if not(type(mask[k])=='table' and mask[k].void)then
     mask[k]=donor or (xx==0 and profile.edgeFloor) or floor
    end
   end
  end end
 end
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o;claim(x,y,w,h,donor);return o
 end
 local function fold(x,y,w,h,cap,split,last,height,depth,front)
  return add({kind='fold',cap=cap,split=split,last=last,height=height,depth=depth,front=front or last},x,y,w,h)
 end
 local function card(x,y,w,h,cap,last,bg,front)
  return add({kind='card',cap=cap,last=last,background=bg,front=front or last},x,y,w,h)
 end
 local function wall(x,y,donor)
  local o=add({kind='wall',clean=donor},x,y,1,2,{mid=profile.void,void=true});return o
 end
 local function clear(x,w,donors)
  for _,o in ipairs(objects)do if o.kind=='wall' and o.x>=x and o.x<x+w then o.clean=donors end end
 end
 local may=(def.id or def.name):match('MAYS')~=nil
 if profile.family=='downstairs' then
  local start=may and 4 or 0;local stair=may and 0 or 7
  for x=start,start+6 do wall(x,0)end
  for x=stair,stair+3 do wall(x,1)end
  local fridge,sink,cabinet=may and 10 or 0,may and 8 or 1,may and 6 or 3
  fold(fridge,1,1,2,2,8,31,25,8,31)
  fold(sink,1,2,2,8,22,31,11,15,31)
  fold(cabinet,1,2,2,3,10,31,25,10,31)
  clear(start,7,{0x26e,0x226})
  -- Restore the native windows above furniture; only the furniture's own
  -- columns are cleared, the upper window row remains native where visible.
  for _,o in ipairs(objects)do if o.kind=='wall' and o.y==0 then o.nativeUpper=true end end
  local tv=may and 7 or 2;local console=may and 6 or 4
  fold(tv,4,2,2,1,6,23,18,8,24)
  fold(console,3,1,3,5,12,45,30,9,45)
  local tableX=may and 6 or 3;local rug=may and 0x2c0 or 0x219
  local donor={mid=rug,x0=0,y0=0,x1=1,y1=1}
  local t=fold(tableX,6,2,2,0,25,32,cfg.tableHeight,25,32)
  claim(tableX,6,2,2,donor)
  for _,xx in ipairs({tableX-1,tableX+2})do for yy=6,7 do
   local o=card(xx,yy,1,1,0,16,{donor},16);o.height=cfg.chairHeight
   claim(xx,yy,1,1,donor)
  end end
  for y=1,L.height-1 do for x=0,L.width-1 do
   local mid=L:midAt(x,y)
   if mid==0x268 then fold(x,y,1,1,0,8,15,cfg.boxHeight,10,15)
   elseif mid==0x270 then fold(x,y,1,2,0,10,22,cfg.boxHeight,10,22)end
  end end
 elseif profile.family=='bedroom' then
  for x=0,8 do wall(x,0)end
  local pc,bed,tv,game=may and 7 or 0,may and 6 or 0,4,may and 5 or 3
  local d=fold(pc,1,2,2,5,16,24,cfg.tableHeight,16,24);d.desk=true;d.pcRight=may
  card(may and 8 or 0,0,1,2,6,28,{},40).base=cfg.tableHeight
  clear(pc,2,{0x254,0x255})
  fold(tv,0,1,3,14,20,40,25,8,40);clear(tv,1,{0x254,0x255})
  card(game,1,1,2,7,24,{{mid=0x278}},24)
  local b=add({kind='bed'},bed,3,3,3);b.may=may
 else
  for x=0,12 do wall(x,0)end
  fold(0,0,2,3,10,19,40,25,9,40);clear(0,2,{0x208,0x20a})
  for _,x in ipairs({3,6,8})do
   local o=fold(x,1,2,2,5,16,24,cfg.tableHeight,17,24);o.desk=true;o.lab=true
   if x==3 then o.pc=true elseif x==6 then o.book=true else o.notes=true end
   clear(x,2,{0x208,0x20a})
   for _,w in ipairs(objects)do if w.kind=='wall' and w.x>=x and w.x<x+2 and L:midAt(w.x,0)==0x209 then w.nativeUpper=true end end
  end
  for _,x in ipairs({0,2})do fold(x,5,2,3,6,20,43,25,12,43)end
  card(10,6,2,3,0,32,{{mid=0x202}},32).height=cfg.machineHeight
  card(12,6,1,2,14,32,{{mid=0x202}},32)
  for _,pos in ipairs({{1,9},{11,9}})do
   local o=fold(pos[1],pos[2],1,3,12,39,47,cfg.tableHeight,28,47);o.bench=true
  end
  for y=1,L.height-1 do for x=0,L.width-1 do
   local mid=L:midAt(x,y)
   if mid==0x244 or mid==0x22e then
    card(x,y-1,1,2,0,32,{{mid=0x202},{mid=0x23e}},32)
   elseif mid==0x241 or mid==0x239 or mid==0x249 then
    card(x,y,1,1,0,16,{{mid=0x202}},16).height=cfg.chairHeight
   elseif mid==0x228 or mid==0x229 or mid==0x23a then
    fold(x,y,1,2,0,10,28,cfg.boxHeight,11,28)
   elseif mid==0x29a or mid==0x232 or mid==0x248 or mid==0x24f then
    fold(x,y,1,1,0,5,16,11,7,16)
   end
  end end
 end
 return objects,mask
end
local function source(L,o,x,y)
 local sx,sy=o.x*16+x,o.y*16+y
 return L:midAt(math.floor(sx/16),math.floor(sy/16)),sx%16,sy%16
end
local function cutout(L,ts,o)
 local pixel=V.require('BuildingMesh').pixel
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local bg={}
 for _,d in ipairs(o.background or {})do
  if d.x0 then bg[rgb(pixel(ts,d.mid,d.x0,d.y0))]=true
  else for y=0,15 do for x=0,15 do bg[rgb(pixel(ts,d.mid,x,y))]=true end end end
 end
 local clear,empty,q={},{},{}
 for y=0,o.h-1 do for x=0,o.w-1 do local m,u,v=source(L,o,x,y);local r,g,b,a=pixel(ts,m,u,v)
  local matches=bg[rgb(r,g,b)]
  if o.positionMask then
   matches=false;for _,d in ipairs(o.background or {})do if rgb(r,g,b)==rgb(pixel(ts,d.mid,x%16,y%16))then matches=true end end
  end
  clear[y*o.w+x]=a<.5 or matches
 end end
 local function seed(x,y)local k=y*o.w+x;if clear[k] and not empty[k]then empty[k]=true;q[#q+1]=k end end
 for x=0,o.w-1 do seed(x,0);seed(x,o.h-1)end;for y=0,o.h-1 do seed(0,y);seed(o.w-1,y)end
 local n=1;while q[n]do local k=q[n];n=n+1;local x,y=k%o.w,math.floor(k/o.w)
  if x>0 then seed(x-1,y)end;if x<o.w-1 then seed(x+1,y)end;if y>0 then seed(x,y-1)end;if y<o.h-1 then seed(x,y+1)end
 end
 return function(x,y)return not empty[y*o.w+x]end
end
function E.build(out,objects,L,ts,ox,oz,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors
 for _,o in ipairs(objects)do
  local rigFirst=#out+1
  local x,z=(o.x+ox)*16,(o.y+oz)*16
  local function draw(y0,y1,project,inside,src)
   local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or function(sx,sy)return source(L,o,sx,sy)end,
    function(sx,sy)return sy>=y0 and sy<y1 and (not inside or inside(sx,sy))end,0,o.h,1,nil,project,.5)
   for _,v in ipairs(vv)do v[2]=v[2]*cfg.heightScale;out[#out+1]=v end
  end
  if o.kind:match('^newMauville')then
   V.require('EmeraldNewMauville').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^wreck')then
   V.require('EmeraldWreckRooms').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^secret')then
   V.require('EmeraldSecretBases').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^fossil')then
   V.require('EmeraldFossilTunnel').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^cable')then
   V.require('EmeraldCableRooms').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^hillRoof')then
   V.require('EmeraldTrainerHillRoof').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^hillEntry')then
   V.require('EmeraldTrainerHillEntrance').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^hill')then
   V.require('EmeraldTrainerHill').build(out,L,ts,o,x,z,contacts)
  elseif o.kind=='truckFloor'or o.kind=='truckCargo'then
   V.require('EmeraldTruck').build(out,L,ts,o,x,z,contacts)
  elseif o.kind=='mysteryPlant'or o.kind=='mysteryCase'then
   V.require('EmeraldMysteryHouse').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^trickDoor')then
   V.require('EmeraldTrickDoors').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^trickStep')then
   V.require('EmeraldTrickSteps').build(out,L,ts,o,x,z,contacts)
  elseif o.kind=='trickQuizRecess'then
   V.require('EmeraldTrickQuiz').build(out,L,ts,o,x,z)
  elseif o.kind=='trickSlidePot'then
   V.require('EmeraldTrickSlide').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^trickMaze')then
   V.require('EmeraldTrickMaze').build(out,L,ts,o,x,z,contacts)
  elseif o.kind=='trickPlant'then
   V.require('EmeraldTrickHouse').build(out,L,ts,o,x,z)
  elseif o.kind:match('^a1')then
   V.require('EmeraldAquaOperations').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^a2')then
   V.require('EmeraldAquaBasement').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^aqua')then
   V.require('EmeraldAquaHideout').build(out,L,ts,o,x,z,contacts)
  elseif o.kind=='pyramidTopStone'then
   V.require('EmeraldPyramidTop').build(out,L,ts,o,x,z)
  elseif o.kind:match('^pyl')then
   V.require('EmeraldPyramidLobby').build(out,L,ts,o,x,z,contacts)
  elseif o.kind=='pyramidWall'then
   V.require('EmeraldPyramidFloor').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^pike')then
   V.require('EmeraldBattlePike').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^palace')then
   V.require('EmeraldBattlePalace').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^factory')then
   V.require('EmeraldBattleFactory').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^dome')then
   V.require('EmeraldBattleDome').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^arena')then
   V.require('EmeraldBattleArena').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^challenge')then
   V.require('EmeraldTowerChallengeRooms').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^tower')then
   V.require('EmeraldTowerPublic').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^rank')then
   V.require('EmeraldFrontierRanking').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^gate')then
   V.require('EmeraldFrontierReception').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^exchange')then
   V.require('EmeraldFrontierExchange').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^frontLounge')then
   V.require('EmeraldFrontierLounges').build(out,L,ts,o,x,z,contacts)
  elseif o.kind=='championRoom'then
   V.require('EmeraldChampionRoom').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^fame')then
   V.require('EmeraldHallOfFame').build(out,L,ts,o,x,z,contacts)
  elseif o.kind=='receptionTable'or o.kind=='receptionMonitor'then
   V.require('EmeraldLeagueReception').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^league')then
   V.require('EmeraldLeagueRooms').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^contest')then
   V.require('EmeraldContestRooms').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^sootGym')then
   V.require('EmeraldSootopolisGym').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^mossGym')then
   V.require('EmeraldMossdeepGym').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^fortGym')then
   V.require('EmeraldFortreeGym').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^petalGym')then
   V.require('EmeraldPetalburgGym').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^lavaGym')then
   V.require('EmeraldLavaridgeGym').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^mauvGym')then
   V.require('EmeraldMauvilleGym').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^dewGym')then
   V.require('EmeraldDewfordGym').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^rustGym')then
   V.require('EmeraldRustboroGym').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^pyre')then
   V.require('EmeraldPyre').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^tidalCabin')then
   V.require('EmeraldShipCabins').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^tidalCorridor')then
   V.require('EmeraldShipCorridor').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^tidal')then
   V.require('EmeraldShipInteriors').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^devon')then
   V.require('EmeraldDevon').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^weather')then
   V.require('EmeraldWeatherInstitute').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^space')then
   V.require('EmeraldSpaceCenter').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^herb')then
   V.require('EmeraldHerbShop').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^yard')then
   V.require('EmeraldShipyard').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^day')then
   V.require('EmeraldDayCare').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^safari')then
   V.require('EmeraldSafariEntrance').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^station')then
   V.require('EmeraldStations').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^transit')then
   V.require('EmeraldTransit').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^tent')then
   V.require('EmeraldBattleTents').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^mau')then
   V.require('EmeraldMauvilleCorner').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^moss')then
   V.require('EmeraldMossdeepClub').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^fan')then
   V.require('EmeraldFanClub').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^art')then
   V.require('EmeraldArtMuseum').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^ocean')then
   V.require('EmeraldOceanMuseum').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^flower')then
   V.require('EmeraldFlowerShop').build(out,L,ts,o,x,z)
  elseif o.kind=='workshopCounter'then
   V.require('EmeraldWorkshopSurfaces').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^guest')then
   V.require('EmeraldGuestSurfaces').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^apartment')then
   V.require('EmeraldApartmentSurfaces').build(out,L,ts,o,x,z,contacts)
  elseif o.kind:match('^roof')then
   V.require('EmeraldDepartmentRoof').build(out,L,ts,o,x,z)
  elseif o.kind:match('^store')then
   V.require('EmeraldDepartmentSurfaces').build(out,L,ts,o,x,z)
  elseif o.kind:match('^bike')then
   V.require('EmeraldBikeShopSurfaces').build(out,L,ts,o,x,z)
  elseif o.kind=='corner' or o.kind=='escalator' then
   V.require('EmeraldPublicSurfaces').build(out,L,ts,o,x,z)
  elseif o.kind=='wall' then
   draw(o.wallCap or 0,o.wallLast or 32,function(sx,sy)local h=o.wallHeight or 32;local start=o.wallCap or 0;local height=o.wallBase and h*(o.wallLast-sy)/(o.wallLast-start)or math.max(0,h-sy);return{x+sx,height,z+math.max(o.wallBase or h,sy)}end,nil,function(sx,sy)
    local row=math.floor(sy/16)
    if o.wallFloor and sy>=o.wallHeight then return o.wallFloor,sx,sy%16 end
    return o.clean and not(o.nativeUpper and row==0) and not(o.keepBefore and sy<o.keepBefore)and o.clean[row+1] or L:midAt(o.x,o.y+row),sx,sy%16
   end)
  elseif o.kind=='fold' then
   local h=o.height;local front=o.front
   local foldMask=o.bounds and function(sx)return sx>=o.bounds[1]and sx<o.bounds[2]end or o.background and cutout(L,ts,o)
   local parts={}
   local function part(sx,sy,w,hh,offset,blank,shape)
    parts[#parts+1]={sx=sx,sy=sy,w=w,h=hh,offset=offset,blank=blank,shape=shape}
   end
   -- Keep native opaque whites in computer cases. A floor-palette mask would
   -- remove them together with the pale checkerboard of the desktop.
   if o.tatamiGlass then part(16,8,6,8,-12,{0x24e,6,8,1,1},'homeGlass')end
   if o.faucet then part(6,0,7,9,-14,{0x26c,4,0,1,16},'homeTap')end
   if o.shelfBox then part(8,2,16,18,-9,{0x22c,2,2,8,8},'shelfBox')end
   if o.labBall then part(2,0,8,8,-10,{0x24c,10,9,1,1},'labBall')end
   if o.benchCup then part(5,28,10,8,-10,{0x238,0,8,16,4},'benchCup')end
   if o.drink then part(1,2,13,18,-8,{0x21f,0,8,1,1},'drink')end
   if o.cup then part(17,8,10,9,-12,{0x248,8,8,1,1},'homeCup')end
   if o.pc then part(0,-8,24,21,-10,{0x21b,8,7,8,8},'labPC')end
   if o.bench then part(0,0,16,o.pcHeight or 22,o.deviceOffset or -16,{0x20b,1,6,8,8},'benchPC')end
   if o.book then part(21,1,9,13,-9,{0x21b,8,7,8,8},'book')end
   if o.notes then part(18,-1,11,15,-9,{0x21b,8,7,8,8},'book')end
   if o.desk and not o.lab then
    part(o.pcRight and 2 or 18,5,12,11,-8,{0x25b,1,0,8,4},'homeBooks')
   end
   local function topSource(sx,sy)
    if o.repeatTop then return source(L,o,sx,o.repeatTop)end
    if o.removeBalls and (sx>=2 and sx<14 or sx>=82 and sx<94)then return source(L,o,16+sx%16,sy)end
    for _,d in ipairs(parts)do
     if sx>=d.sx and sx<d.sx+d.w and sy>=d.sy and sy<d.sy+d.h then
      local b=d.blank;return b[1],b[2]+sx%b[4],b[3]+sy%b[5]
     end
    end
    return source(L,o,sx,sy)
   end
   if o.schoolDesk then local previous=foldMask;foldMask=function(sx,sy)return(not previous or previous(sx,sy))and(sy<13 or sx<4 or sx>=12)end end
   draw(o.cap,o.split,function(sx,sy)return{x+sx,h,z+front-o.depth+(sy-o.cap)*o.depth/(o.split-o.cap)}end,foldMask,topSource)
   draw(o.split,o.last,function(sx,sy)return{x+sx,h*(o.last-sy)/(o.last-o.split),z+front}end,foldMask)
   for _,d in ipairs(parts)do
    local function inside(sx,sy)
     if d.shape=='benchCup' then local spans={{2,6},{1,7},{0,9},{0,10},{0,10},{0,10},{1,9},{2,6}};local row=spans[sy+1];return row and sx>=row[1]and sx<row[2]end
     if d.shape=='labBall' then return sy>=2 and sy<7 and sx>=1 and sx<7 or sy<2 and sx>=2 and sx<6 end
     if d.shape=='shelfBox' then return sx>=1 and sx<15 and sy>=1 end
     if d.shape=='drink' then return sy>=6 and sx>=2 and sx<11 or sy>=2 and sy<6 and sx>=4 and sx<9 or sy<2 and sx>=5 and sx<8 end
     if d.shape=='homeGlass' then
      local pixel=V.require('BuildingMesh').pixel;local r,g,b=pixel(ts,source(L,o,d.sx+sx,d.sy+sy));local br,bg,bb=pixel(ts,0x24e,6,8)
      return r~=br or g~=bg or b~=bb
     end
     if d.shape=='homeTap' then
      local pixel=V.require('BuildingMesh').pixel;local r,g,b=pixel(ts,source(L,o,d.sx+sx,d.sy+sy));local br,bg,bb=pixel(ts,o.detailWallMid or 0x20d,0,0)
      return r~=br or g~=bg or b~=bb
     end
     if d.shape=='homeCup' then return sy>=2 and sy<8 and sx>=1 and sx<8 or sy>=3 and sy<6 and sx==8 or sy==1 and sx>=3 and sx<6 end
     if d.shape=='labPC' then return sx>=2 and sx<9 and sy>=3 or sx>=10 and sx<23 and sy>=2 or sy>=11 and sx>=1 and sx<10 end
     if d.shape=='benchPC' then return sy>=1 and sy<21 and sx>=(sy<5 and 2 or 1) and sx<15 end
     return true
    end
    local function device(band,project)
     local vv=V.require('PaperSprite').build(ts,d.w,d.h,
      function(sx,sy)return source(L,o,d.sx+sx,d.sy+sy)end,function(sx,sy)return inside(sx,sy)and(not band or band(sy))end,0,d.h,1,nil,project,.5)
     for _,v in ipairs(vv)do v[2]=v[2]*cfg.heightScale;out[#out+1]=v end
    end
    if d.shape=='shelfBox' then
     device(function(sy)return sy<5 end,function(sx,sy)return{x+d.sx+sx,h+cfg.boxHeight,z+front+d.offset-8+(sy-1)*2}end)
     device(function(sy)return sy>=5 end,function(sx,sy)return{x+d.sx+sx,h+cfg.boxHeight*(18-sy)/13,z+front+d.offset}end)
    else
     device(nil,function(sx,sy)return{x+d.sx+sx,h+(d.h-sy)*cfg.deviceScale,math.max(z+front+d.offset,o.y<=1 and (oz*16+32+cfg.wallClearance)or -math.huge)}end)
    end
   end
  elseif o.kind=='card' then
   local visible=o.opaque and function()return true end or cutout(L,ts,o);local height=o.height or(o.last-o.cap)
   draw(o.cap,o.last,function(sx,sy)return{x+sx,(o.base or 0)+(o.last-sy)*height/(o.last-o.cap),z+o.front}end,function(sx,sy)return visible(sx,sy) and (not o.bounds or sx>=o.bounds[1]and sx<o.bounds[2]) and (not o.trim or sx>=o.trim and sx<o.w-o.trim)end)
  elseif o.kind=='treeTrunk' then
   V.require('EmeraldTimberSurfaces').buildTrunk(out,L,ts,o,x,z)
  elseif o.kind=='partition' then
   V.require('EmeraldWoodHomeSurfaces').buildPartition(out,ts,o,x,z,contacts)
  elseif o.kind=='seat' then
   local mask=cutout(L,ts,o);local visible=function(sx,sy)return mask(sx,sy)and(not o.bounds or sx>=o.bounds[1]and sx<o.bounds[2])end
   draw(o.cap,o.backEnd,function(sx,sy)return{x+sx,o.backHeight-(sy-o.cap)*(o.backHeight-o.seatHeight)/(o.backEnd-o.cap),z+o.front-o.depth}end,visible)
   draw(o.backEnd,o.seatEnd,function(sx,sy)return{x+sx,o.seatHeight,z+o.front-o.depth+(sy-o.backEnd)*o.depth/(o.seatEnd-o.backEnd)}end,visible)
   draw(o.seatEnd,o.last,function(sx,sy)return{x+sx,o.seatHeight*(o.last-sy)/(o.last-o.seatEnd),z+o.front}end,visible)
  elseif o.kind=='bed' then
   local h=cfg.bedHeight
   local function band(a,b,transform)draw(a,b,transform,function(sx)return sx>=13 and sx<35 end)end
   band(13,22,function(sx,sy)return{x+sx,15-(sy-13),z+21}end)
   band(22,40,function(sx,sy)return{x+sx,h,z+21+(sy-22)*24/18}end)
   band(40,46,function(sx,sy)return{x+sx,h*(46-sy)/6,z+45}end)
  end
  V.require('RoomLightRig').capture(L,o,out,rigFirst,#out,x,z)
  if o.kind~='wall'and not o.noContact and contacts then
   for xx=x+4,x+o.w-2,8 do contacts[#contacts+1]={xx,z+(o.front or 45),7,2,cfg.contactStrength}end
  end
 end
end
return E
