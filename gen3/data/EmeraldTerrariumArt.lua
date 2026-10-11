-- Illustrated assets only; a family asset is not a bespoke landmark claim.
local function city(kind,water)
 local timber=kind~='crater';local floor=(kind=='floating'or water)and'floating-water-floor.png'or'crater-floor.png'
 if kind=='floating'then floor='floating-water-floor.png'end
 if kind=='treecity'then floor='floor.jpg'end
 return {landscape=kind..'-landscape.png',floor=floor,layout='EmeraldCityTerrariums',layoutKey=water and kind=='crater'and'crater_water'or kind,
  floorRect=kind=='treecity'and{30,30,738,738}or{0,0,1253,1253},floorFlow=kind=='floating'or water,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture=timber and'city-timber-floor.png'or'crater-floor.png',rect={80,80,1174,1174}},
  anchors={player={-35,8.0,27},enemy={35,8.0,4},
   playerTrainer={-71.1,kind=='treecity'and 11.5 or kind=='floating'and 10.3 or 8.5,17},
   enemyTrainer={71.1,kind=='treecity'and 11.5 or kind=='floating'and 10.3 or 8.5,-2}},paperCaps=false}
end
local function cavern(key,kind,wet)
 local volcanic=kind=='volcanic';local floor=volcanic and(key=='path'and'cave-floor.png'or'volcanic-floor.png')or wet and'pond-water-floor.png'or kind..'-floor.png'
 return {landscape=kind..'-structure.png',floor=floor,floorRect={24,24,1228,1228},
  layout=volcanic and'EmeraldVolcanicTerrariums'or'EmeraldShoalTerrariums',layoutKey=key,water=false,floorFlow=wet,
  floorLava=volcanic and key~='path',floorFrost=kind=='frost',
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,
   texture=volcanic and'basalt-floor.png'or kind..'-floor.png',
   rect={90,90,1164,1164}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end
local function secludedCave(kind)
 local floor=kind=='artisan'and'cave-floor.png'or'story-coldstone-floor.png'
 return {landscape=kind..'-layered-v1.png',floor=floor,floorRect={24,24,1228,1228},
  layout='EmeraldSecludedCaves',layoutKey=kind,water=false,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture=floor,rect=kind=='artisan'and{280,280,974,974}or{90,90,1164,1164},sideTint=kind=='artisan'and{.69,.64,.52,1}or{.37,.43,.47,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end
local function frontier(kind)
 local floor=kind=='palace'and'city-timber-floor.png'or'frontier-'..kind..'-floor.png'
 local trim={arena={.78,.66,.43,1},dome={.66,.63,.78,1},factory={.74,.78,.75,1},palace={.74,.61,.40,1},pike={.77,.74,.64,1},tower={.85,.83,.75,1},pyramid={.79,.66,.44,1}}
 return {landscape='frontier-'..kind..'-kit.png',floor=floor,floorRect={24,24,1228,1228},
  layout='EmeraldFrontierTerrariums',layoutKey=kind,water=false,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture=floor,sideTint=trim[kind],rect={90,90,1164,1164}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end
local function story(kind)
 local floors={space='frontier-factory-floor.png',weather='city-timber-floor.png',electric='story-electric-floor.png',regirock='frontier-pyramid-floor.png',regice='story-coldstone-floor.png',registeel='basalt-floor.png'}
 local floor=floors[kind]
 return {landscape='story-'..kind..'-kit.png',floor=floor,floorRect={24,24,1228,1228},
  layout='EmeraldStoryTerrariums',layoutKey=kind,water=false,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture=floor,sideTint=kind=='regirock'and{.78,.62,.43,1}or{.70,.72,.70,1},rect={90,90,1164,1164}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end
local function rustboro(kind)
 local city=kind=='city'
 return {landscape=(city and'rustboro'or'rock-gym')..'-layered-v3.png',floor='city-floor.png',floorRect={24,24,1228,1228},
  layout=city and'EmeraldRustboroLayered'or'EmeraldRockGymLayered',water=false,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture='city-floor.png',rect={260,260,994,994},sideTint={.76,.67,.52,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end
local function deepcave(kind)
 local wet=kind=='marine'or kind=='seafloor';local lava=kind=='terra'
 local dry=kind=='meteor'and'deepcave-ochre-floor.png'or kind=='granite'and'cave-floor.png'or(kind=='origin'or wet)and'story-coldstone-floor.png'or'basalt-floor.png'
 local floor=wet and'deepcave-water-floor.png'or lava and'volcanic-floor.png'or dry
 return {landscape='deepcave-'..kind..'-kit.png',floor=floor,floorRect={24,24,1228,1228},
  layout=kind=='origin'and'EmeraldOriginTerrarium'or kind=='granite'and'EmeraldGraniteTerrarium'or kind=='meteor'and'EmeraldMeteorTerrarium'or kind=='seafloor'and'EmeraldSeafloorTerrarium'or(kind=='marine'or kind=='terra')and'EmeraldAncientCaveTerrariums'or'EmeraldDeepCaveTerrariums',layoutKey=kind,water=false,floorFlow=wet,floorLava=lava,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture=dry,rect={90,90,1164,1164},sideTint=kind=='meteor'and{.80,.67,.40,1}or{.54,.55,.54,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end
local function wildplace(kind)
 local stone=kind=='mountain'or kind=='ash';local floor=stone and'cave-floor.png'or'floor.jpg'
 local dark=kind=='rainforest'or kind=='ancient'or kind=='memorial'
 if dark then floor='wildplace-floor.png'end
 local rect=(stone or dark)and{24,24,1228,1228}or{30,30,738,738}
 return {landscape='wildplace-'..kind..'-kit.png',floor=floor,floorRect=rect,
  layout=kind=='rainforest'and'EmeraldRainforestTerrarium'or kind=='mountain'and'EmeraldMountainTerrarium'or kind=='safari'and'EmeraldSafariTerrarium'or'EmeraldWildPlaceTerrariums',layoutKey=kind,water=false,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture=floor,rect=(stone or dark)and{90,90,1164,1164}or{154,154,614,614}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end
local function ruin(kind)
 local sand=kind=='mirage'or kind=='pillar'or kind=='fossil'
 local floor=sand and'deepcave-ochre-floor.png'or kind=='victory'and'cave-floor.png'or'story-coldstone-floor.png'
 return {landscape='ruin-'..kind..'-kit.png',floor=floor,floorRect={24,24,1228,1228},
  layout=kind=='victory'and'EmeraldVictoryTerrarium'or'EmeraldRuinTerrariums',layoutKey=kind,water=false,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture=floor,rect={90,90,1164,1164},sideTint=sand and{.80,.67,.45,1}or{.58,.60,.62,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end
local function room(kind)
 local dry=kind=='hill'and'frontier-arena-floor.png'or'city-timber-floor.png'
 local wet=kind=='wreck';local floor=wet and'deepcave-water-floor.png'or dry
 return {landscape='room-'..kind..'-kit.png',floor=floor,floorRect={24,24,1228,1228},
  layout='EmeraldRoomTerrariums',layoutKey=kind,water=false,floorFlow=wet,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={paperDock=kind=='liner'or kind=='wreck',x=0,z=15,radius=61,height=7.5,texture=dry,rect={90,90,1164,1164},sideTint={.69,.53,.35,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end
local function townTent(kind)
 local floors={mauville='city-floor.png',lilycove='frontier-pike-floor.png',slateport='city-floor.png',museum='frontier-tower-floor.png',tent_slateport='city-timber-floor.png',tent_verdanturf='frontier-arena-floor.png',tent_fallarbor='basalt-floor.png'}
 local floor=floors[kind]or(kind=='lavaridge'and'basalt-floor.png'or kind=='fallarbor'and'story-coldstone-floor.png'or kind=='frontier'and'frontier-tower-floor.png'or kind=='dewford'and'deepcave-ochre-floor.png'or'city-floor.png')
 return {landscape='town-'..kind..'-kit.png',floor=floor,floorRect={24,24,1228,1228},
  layout='EmeraldTownTentTerrariums',layoutKey=kind,water=false,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture=floor,rect={90,90,1164,1164},sideTint={.73,.68,.55,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end
local function baseEvent(kind)
 local floors={base_cave='deepcave-ochre-floor.png',base_wood='city-timber-floor.png',base_garden='wildplace-floor.png',navel_sky='story-coldstone-floor.png',navel_tide='deepcave-water-floor.png',submerged_wreck='deepcave-water-floor.png'}
 local floor=floors[kind];local wet=kind=='navel_tide'or kind=='submerged_wreck'
 local dry=wet and'story-coldstone-floor.png'or floor
 return {landscape='baseevent-'..kind..'-kit.png',floor=floor,floorRect={24,24,1228,1228},
  layout='EmeraldBaseEventTerrariums',layoutKey=kind,water=false,floorFlow=wet,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,paperStack=kind=='submerged_wreck',rockArt=kind=='submerged_wreck'and{texture='undersea-cavern-kit.png',rect={354,779,817,990}}or nil,texture=dry,rect={90,90,1164,1164},sideTint=wet and{.59,.66,.70,1}or{.73,.68,.55,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end
local function research(kind)
 local floor=kind=='lab'and'city-timber-floor.png'or kind=='hall'and'frontier-tower-floor.png'or'frontier-factory-floor.png'
 return {landscape='research-'..kind..'-kit.png',floor=floor,floorRect={24,24,1228,1228},
  layout='EmeraldResearchTerrariums',layoutKey=kind,water=false,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture=floor,rect={90,90,1164,1164},sideTint={.70,.66,.54,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end

local underseaRockFaces={reef={355,721,778,993},braille={393,791,792,978},
 cavern={354,779,817,990},crater={375,751,780,981},marine={349,753,781,998}}
local function undersea(kind)
 return {landscape='undersea-'..kind..'-kit.png',floor='deepcave-water-floor.png',floorRect={24,24,1228,1228},
  layout='EmeraldUnderseaTerrariums',layoutKey=kind,basin=true,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,bottom=-43,edge=4,strata=12,paperStack=true,rockArt={texture='undersea-'..kind..'-kit.png',rect=underseaRockFaces[kind]},texture='undersea-sand-floor.png',rect={24,24,1228,1228},sideTint={.47,.66,.69,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end

local function service(kind)
 local floor=kind=='center'and'frontier-tower-floor.png'or kind=='shop'and'city-timber-floor.png'or kind=='harbor'and'deepcave-water-floor.png'or'city-timber-floor.png'
 local dry=kind=='harbor'and'city-timber-floor.png'or floor
 return {landscape='service-'..kind..'-kit.png',floor=floor,floorRect={24,24,1228,1228},
  layout='EmeraldServiceTerrariums',layoutKey=kind,basin=kind=='harbor',dockPiers=kind=='harbor',
  camera={eye={0,208,447},target={0,52,-12}},
  platform={paperDock=kind=='harbor',x=0,z=15,radius=61,height=7.5,bottom=kind=='harbor'and -43 or nil,texture=dry,rect={90,90,1164,1164},sideTint={.75,.69,.57,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false}
end

return {
 ['cave:artisan']=secludedCave('artisan'),['cave:altering']=secludedCave('altering'),
 ['cave:rusturf']={landscape='rusturf-layered-v1.png',floor='deepcave-ochre-floor.png',floorRect={24,24,1228,1228},
  layout='EmeraldRusturfTerrarium',layoutKey='rusturf',water=false,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture='deepcave-ochre-floor.png',rect={90,90,1164,1164},sideTint={.63,.55,.43,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false},
 ['facility:link']={landscape='link-colosseum-kit.png',floor='frontier-tower-floor.png',floorRect={24,24,1228,1228},layout='EmeraldLinkTerrarium',layoutKey='link',water=false,
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture='frontier-tower-floor.png',rect={90,90,1164,1164},sideTint={.70,.77,.68,1}},
  anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,11,17},enemyTrainer={71.1,11,-2}},paperCaps=false},
 ['interior:center']=service('center'),['interior:shop']=service('shop'),['ship:harbor']=service('harbor'),['ship:truck']=service('truck'),
 ['underwater:']=undersea('reef'),['underwater:braille']=undersea('braille'),['underwater:cavern']=undersea('cavern'),['underwater:crater']=undersea('crater'),['underwater:marine']=undersea('marine'),
 ['industrial:devon']=research('devon'),['industrial:lab']=research('lab'),['league:hall']=research('hall'),
 ['city:dewford']=townTent('dewford'),['city:lavaridge']=townTent('lavaridge'),['city:mossdeep']=townTent('mossdeep'),['city:frontier']=townTent('frontier'),['city:ever_grande']=townTent('ever_grande'),['city:petalburg']=townTent('petalburg'),['city:littleroot']=townTent('littleroot'),['city:oldale']=townTent('oldale'),['city:verdanturf']=townTent('verdanturf'),['city:fallarbor']=townTent('fallarbor'),
 ['cave:base']=baseEvent('base_cave'),['interior:wood']=baseEvent('base_wood'),['interior:garden']=baseEvent('base_garden'),
 ['cave:sky']=baseEvent('navel_sky'),['cave:tide']=baseEvent('navel_tide'),['underwater:wreck']=baseEvent('submerged_wreck'),
 ['city:mauville']=townTent('mauville'),['city:lilycove']=townTent('lilycove'),['city:slateport']=townTent('slateport'),['interior:museum']=townTent('museum'),
 ['facility:tent_slateport']=townTent('tent_slateport'),['facility:tent_verdanturf']=townTent('tent_verdanturf'),['facility:tent_fallarbor']=townTent('tent_fallarbor'),
 ['ship:wreck']=room('wreck'),['ship:liner']=room('liner'),['facility:hill']=room('hill'),['interior:puzzle']=room('puzzle'),
 ['tower:memorial']=ruin('memorial'),ruins=ruin('pillar'),['ruins:sand']=ruin('mirage'),
 ['ruins:braille']=ruin('sealed'),['cave:victory']=ruin('victory'),['cave:fossil']=ruin('fossil'),
 rainforest=wildplace('rainforest'),safari=wildplace('safari'),mountain=wildplace('mountain'),['mountain:ash']=wildplace('ash'),
 ['mountain:memorial']=wildplace('memorial'),['forest:ancient']=wildplace('ancient'),['forest:island']=wildplace('island'),
 ['watercave:meteor']=deepcave('meteor'),['watercave:seafloor']=deepcave('seafloor'),['watercave:marine']=deepcave('marine'),
 ['lava:ancient']=deepcave('terra'),['cave:granite']=deepcave('granite'),['cave:origin']=deepcave('origin'),
 ['industrial:space']=story('space'),['industrial:weather']=story('weather'),['industrial:electric']=story('electric'),['ruins:regirock']=story('regirock'),['ruins:regice']=story('regice'),['ruins:registeel']=story('registeel'),
 ['facility:arena']=frontier('arena'),['facility:dome']=frontier('dome'),['facility:factory']=frontier('factory'),['facility:palace']=frontier('palace'),['facility:pike']=frontier('pike'),['facility:tower']=frontier('tower'),['ruins:pyramid']=frontier('pyramid'),
 ['lava:path']=cavern('path','volcanic'),['lava:magma']=cavern('magma','volcanic'),volcano=cavern('volcano','volcanic'),
 ['watercave:tide']=cavern('tide','tidal',true),['watercave:salt']=cavern('salt','tidal'),ice=cavern('ice','frost'),
 treecity=city('treecity'),floating=city('floating'),crater=city('crater'),
 ['sea:pacifidlog']=city('floating',true),['sea:sootopolis']=city('crater',true),
 forest={landscape='green-structure-v3.png',floor='floor.jpg',floorRect={30,30,738,738},layout='EmeraldGreenTerrarium',
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=15,radius=61,height=7.5,texture='floor.jpg',rect={154,154,614,614}},
  anchors={player={-35,8.0,27},enemy={35,8.0,4},playerTrainer={-71.1,11.0,17},enemyTrainer={71.1,11.0,-2}},
  paperCaps=false},
 desert={landscape='desert-layered-v2.png',floor='route-desert-kit.png',floorRect={38,806,422,1184},layout='EmeraldDryRouteTerrariums',layoutKey='desert',trainerGround=9.8},
 pond={landscape='pond-botanical-v2.png',floor='pond-water-floor.png',floorRect={0,0,1253,1253},layout='EmeraldPondTerrarium',layoutKey='pond',trainerGround=8.4,battlerGround=8.0,floorFlow=true},
 meadow={landscape='meadow-landscape-v2.png',floor='meadow-floor-v2.png',floorRect={0,0,1253,1253},layout='EmeraldMeadowTerrarium',layoutKey='meadow',trainerGround=12.0},
 ['meadow:long_grass']={landscape='meadow-landscape-v2.png',floor='meadow-floor-v2.png',floorRect={0,0,1253,1253},layout='EmeraldMeadowTerrarium',layoutKey='long_grass',trainerGround=12.0},
 coast={landscape='coast-botanical-v2.png',floor='route-coast-kit.png',floorRect={46,839,400,1184},layout='EmeraldCoastTerrarium',layoutKey='coast',trainerGround=9.7},
 ash={landscape='ash-layered-v2.png',floor='route-ash-kit.png',floorRect={52,842,414,1200},layout='EmeraldDryRouteTerrariums',layoutKey='ash',trainerGround=11.3},
 sea={landscape='sea-landscape.png',floor='sea-floor.png',layout='EmeraldSeaTerrarium',sea=true},
 underwater={landscape='sea-landscape.png',floor='sea-floor.png',layout='EmeraldSeaTerrarium',sea=true},
 ['city:rustboro']=rustboro('city'),
 cave={landscape='cave-paper-v2.png',floor='cave-floor.png',layout='EmeraldCaveTerrarium',water=false},
 ['gym:rock']=rustboro('gym'),
 ['gym:electric']={landscape='gym-electric-atlas.png',floor='gym-electric-atlas.png',floorRect={26,558,630,1183},layout='EmeraldGymAtlasLayouts',layoutKey='electric',trainerGround=11.2},
 ['gym:steam']={landscape='gym-steam-atlas.png',floor='gym-steam-atlas.png',floorRect={35,548,612,1155},layout='EmeraldGymAtlasLayouts',layoutKey='steam',trainerGround=11.8},
 ['gym:psychic']={landscape='gym-psychic-atlas.png',floor='gym-psychic-atlas.png',floorRect={56,577,622,1144},layout='EmeraldGymAtlasLayouts',layoutKey='psychic',trainerGround=11.5},
 ['gym:fighting']={landscape='gym-fighting-atlas.png',floor='gym-fighting-atlas.png',floorRect={1039,68,1445,449},layout='EmeraldGymAtlasLayouts',layoutKey='fighting',trainerGround=7.2},
 ['gym:normal']={landscape='gym-normal-atlas.png',floor='gym-normal-atlas.png',floorRect={1004,31,1500,494},layout='EmeraldGymAtlasLayouts',layoutKey='normal',trainerGround=8.6},
 ['gym:sky']={landscape='gym-sky-atlas.png',floor='gym-sky-atlas.png',floorRect={1004,63,1482,491},layout='EmeraldGymAtlasLayouts',layoutKey='sky',trainerGround=8.9},
 ['gym:water']={landscape='gym-water-atlas.png',floor='gym-water-atlas.png',floorRect={1006,57,1436,447},layout='EmeraldGymAtlasLayouts',layoutKey='water',trainerGround=11.7},
 ['industrial:aqua']={landscape='aqua-paper.png',floor='aqua-floor-paper.png',floorRect={0,0,1253,1253},layout='EmeraldAquaTerrarium',
  camera={eye={0,208,447},target={0,52,-12}},
  platform={x=0,z=0,radius=70,height=2,texture='aqua-floor-paper.png',rect={191.65,191.65,1061.35,1061.35},sideTint={.52,.59,.64,1}},
  anchors={player={-35,2.5,27},enemy={35,2.5,4}},paperCaps=false},
 ['league:dark']={landscape='league-dark-kit.png',floor='league-dark-kit.png',floorRect={42,823,395,1173},layout='EmeraldLeagueTerrariums',layoutKey='dark',trainerGround=12.1,anchors={player={-35,-1.74,27},enemy={35,-1.74,4}},battleFootprint={x=0,z=15,radius=70}},
 ['league:ghost']={landscape='league-ghost-kit.png',floor='league-ghost-kit.png',floorRect={39,833,397,1187},layout='EmeraldLeagueTerrariums',layoutKey='ghost',trainerGround=15.1,anchors={player={-35,-1.74,27},enemy={35,-1.74,4}},battleFootprint={x=0,z=15,radius=70}},
 ['league:ice']={landscape='league-ice-kit.png',floor='league-ice-kit.png',floorRect={48,846,388,1177},layout='EmeraldLeagueTerrariums',layoutKey='ice',trainerGround=10.6,anchors={player={-35,-1.74,27},enemy={35,-1.74,4}},battleFootprint={x=0,z=15,radius=70}},
 ['league:dragon']={landscape='league-dragon-kit.png',floor='league-dragon-kit.png',floorRect={42,825,390,1173},layout='EmeraldLeagueTerrariums',layoutKey='dragon',trainerGround=10.1,anchors={player={-35,-1.74,27},enemy={35,-1.74,4}},battleFootprint={x=0,z=15,radius=70}},
 ['league:champion']={landscape='league-champion-kit.png',floor='league-champion-kit.png',floorRect={42,836,403,1182},layout='EmeraldLeagueTerrariums',layoutKey='champion',trainerGround=11.0,anchors={player={-35,-1.74,27},enemy={35,-1.74,4}},battleFootprint={x=0,z=15,radius=70}},
 ['island:triangle']={landscape='birth-island-paper.png',floor='floor.jpg',layout='EmeraldBirthIslandTerrarium'},
 ['ruins:sky']={landscape='sky-pillar-kit.png',floor='sky-pillar-floor.png',floorRect={0,0,1254,1254},layout='EmeraldSkyPillarTerrarium',trainerGround=11.0},
}
