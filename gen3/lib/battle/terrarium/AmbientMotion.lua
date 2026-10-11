-- Ambient paper details own no battle state and never consume game RNG.
-- Distinctive events advance only during a quiet command menu. Pausing freezes
-- their exact pose; view changes and new battles reset the schedule.
local A={}
local plans={
 ['facility:link']={kind='linkSignal',delay=12,duration=3.8,interval=29},
 ['interior:center']={kind='healLights',delay=18,duration=4.2,interval=37},
 ['interior:shop']={kind='receipt',delay=23,duration=4,interval=43},
 ['ship:harbor']={kind='paperDock',delay=17,duration=5.6,interval=33},
 ['ship:truck']={kind='cargoDust',delay=17,duration=3.4,interval=31},
 ['underwater:']={kind='paperFish',delay=16,duration=5.6,interval=33},
 ['underwater:braille']={kind='paperFish',delay=21,duration=5.6,interval=41},
 ['underwater:cavern']={kind='paperBubbles',delay=18,duration=5.6,interval=37},
 ['underwater:crater']={kind='paperFish',delay=16,duration=5.6,interval=33},
 ['underwater:marine']={kind='kyogre',delay=26,duration=5,interval=53},
 ['industrial:devon']={kind='devonVentCycle',delay=18,duration=4.4,interval=37},
 ['industrial:lab']={kind='labGlobeStudy',delay=22,duration=4,interval=41},
 ['league:hall']={kind='hallRegistration',delay=19,duration=4.8,interval=39},
 ['city:dewford']={kind='shoreCrab',delay=14,duration=4.8,interval=29},
 ['city:lavaridge']={kind='springSteam',delay=10,duration=5,interval=24},
 ['city:mossdeep']={kind='dishScan',delay=11,duration=5,interval=27},
 ['city:frontier']={kind='tournamentBreeze',delay=10,duration=4.5,interval=26},
 ['city:ever_grande']={kind='flowerDrift',delay=12,duration=5,interval=29},
 ['city:petalburg']={kind='gardenLeaves',delay=11,duration=4.8,interval=25},
 ['city:littleroot']={kind='paperPinwheel',delay=10,duration=4.5,interval=24},
 ['city:oldale']={kind='paperSign',delay=12,duration=4.5,interval=27},
 ['city:verdanturf']={kind='gardenButterflies',delay=13,duration=5,interval=29},
 ['city:fallarbor']={kind='paperAsh',delay=12,duration=5,interval=27},

 ['cave:base']={kind='paperBase',delay=19,duration=5.4,interval=37},
 ['interior:wood']={kind='paperBase',delay=21,duration=5.4,interval=39},
 ['interior:garden']={kind='paperBase',delay=16,duration=5.4,interval=33},
 ['cave:sky']={kind='paperNavelSky',delay=17,duration=5.6,interval=35},
 ['cave:tide']={kind='paperNavelTide',delay=18,duration=5.6,interval=37},
 ['underwater:wreck']={kind='paperBubbles',delay=17,duration=5.6,interval=35},
 ['city:mauville']={kind='streetSignal',delay=11,duration=4.5,interval=27},
 ['city:lilycove']={kind='shoreCrab',delay=16,duration=4.8,interval=31},
 ['city:slateport']={kind='harborBreeze',delay=9,duration=4.5,interval=23},
 ['interior:museum']={kind='shipBell',delay=14,duration=4.5,interval=31},
 ['facility:tent_slateport']={kind='paperStreamers',delay=13,duration=5,interval=29},
 ['facility:tent_verdanturf']={kind='paperFan',delay=11,duration=4.5,interval=27},
 ['facility:tent_fallarbor']={kind='trophyGlint',delay=12,duration=4.5,interval=28},
 ['ship:wreck']={kind='paperShip',delay=13,duration=5.6,interval=29},
 ['ship:liner']={kind='paperShip',delay=20,duration=5.6,interval=39},
 ['facility:hill']={kind='hillBanners',delay=19,duration=4,interval=41},
 ['interior:puzzle']={kind='motes',delay=17,duration=4,interval=35},
 ['tower:memorial']={kind='motes',delay=19,duration=4,interval=37},
 ruins={kind='skyWind',delay=17,duration=4.6,interval=33},
 ['ruins:sand']={kind='sandGust',delay=13,duration=4.5,interval=29},
 ['ruins:braille']={kind='caveDrips',delay=16,duration=3.8,interval=33},
 ['cave:victory']={kind='pebbles',delay=13,duration=3.1,interval=29},
 ['cave:fossil']={kind='sandGust',delay=17,duration=4.5,interval=35},
 safari={kind='leaves',delay=15,duration=4.5,interval=31},
 mountain={kind='skyWind',delay=14,duration=4.6,interval=29},
 ['mountain:ash']={kind='ashGust',delay=13,duration=4.5,interval=29},
 ['mountain:memorial']={kind='skyWind',delay=18,duration=4.6,interval=37},
 ['forest:ancient']={kind='leaves',delay=16,duration=4.5,interval=33},
 ['forest:island']={kind='petals',delay=16,duration=4.5,interval=33},
 ['watercave:meteor']={kind='caveDrips',delay=12,duration=3.8,interval=28},
 ['watercave:seafloor']={kind='seaSpray',delay=14,duration=4.2,interval=29},
 ['watercave:marine']={kind='pondBubbles',delay=16,duration=4.2,interval=33},
 ['lava:ancient']={kind='emberBurst',delay=17,duration=4.1,interval=33},
 ['cave:granite']={kind='pebbles',delay=13,duration=3.1,interval=29},
 ['cave:rusturf']={kind='pebbles',delay=11,duration=3.4,interval=29},
 ['cave:artisan']={kind='paperPaint',delay=22,duration=4.5,interval=41},
 ['cave:altering']={kind='paperBat',delay=18,duration=4.8,interval=37},
 ['cave:origin']={kind='caveDrips',delay=19,duration=3.8,interval=37},
 ['industrial:space']={kind='rocketTest',delay=18,duration=3.4,interval=37},
 ['industrial:weather']={kind='weatherGust',delay=13,duration=4.2,interval=29},
 ['industrial:electric']={kind='sparks',delay=14,duration=2.4,interval=31},
 ['ruins:regirock']={kind='sandGust',delay=12,duration=4.5,interval=27},
 ['ruins:regice']={kind='regiceFrost',delay=12,duration=3.8,interval=27},
 ['ruins:registeel']={kind='bell',delay=17,duration=4.2,interval=37},
 ['facility:arena']={kind='judgingBanners',delay=13,duration=4.5,interval=28},
 ['facility:dome']={kind='tournamentRibbons',delay=10,duration=4.8,interval=24},
 ['facility:factory']={kind='ventPuff',delay=12,duration=4.4,interval=27},
 ['facility:palace']={kind='treeChime',delay=14,duration=4.2,interval=31},
 ['facility:pike']={kind='lanternSequence',delay=16,duration=4,interval=32},
 ['facility:tower']={kind='paperDoor',delay=12,duration=4.5,interval=28},
 ['ruins:pyramid']={kind='pebbles',delay=11,duration=3.1,interval=26},
 ['lava:path']={kind='ventPuff',delay=12,duration=4.4,interval=28},
 ['lava:magma']={kind='emberBurst',delay=14,duration=4.1,interval=31},
 volcano={kind='emberBurst',delay=11,duration=4.1,interval=27},
 ['watercave:tide']={kind='caveDrips',delay=9,duration=3.8,interval=22},
 ['watercave:salt']={kind='saltFall',delay=13,duration=4.1,interval=29},
 ice={kind='frostShower',delay=12,duration=4.4,interval=28},
 treecity={kind='treeChime',delay=12,duration=4.2,interval=27},
 floating={kind='harborRipples',delay=11,duration=5.4,interval=25},
 crater={kind='fountain',delay=12,duration=4.2,interval=26},
 ['sea:pacifidlog']={kind='harborRipples',delay=11,duration=5.4,interval=25},
 ['sea:sootopolis']={kind='fountain',delay=12,duration=4.2,interval=26},
 desert={kind='sandGust',delay=13,duration=4.5,interval=26},
 pond={kind='paperPond',delay=11,duration=5.4,interval=24},
 meadow={kind='petals',delay=9,duration=4.5,interval=22},
 coast={kind='paperCoast',delay=10,duration=5.6,interval=23},
 ash={kind='ashGust',delay=12,duration=4.5,interval=26},
 cave={kind='pebbles',delay=8,duration=3.1,interval=21},
 forest={kind='leaves',delay=7,duration=4.5,interval=17},
 rainforest={kind='leaves',delay=7,duration=4.5,interval=17},
 city={kind='chimney',delay=6,duration=5,interval=15},
 ['city:rustboro']={kind='paperChimney',delay=13,duration=4.6,interval=29},
 sea={kind='kyogre',delay=26,duration=5,interval=53},
 underwater={kind='kyogre',delay=26,duration=5,interval=53},
 ['gym:rock']={kind='pebbles',delay=10,duration=3.1,interval=25},
 ['gym:electric']={kind='sparks',delay=8,duration=2.4,interval=17},
 ['gym:steam']={kind='steamPuff',delay=9,duration=4,interval=19},
 ['gym:psychic']={kind='paperOrrery',delay=12,duration=4.8,interval=29},
 ['gym:fighting']={kind='dojoTarget',delay=8,duration=4,interval=18},
 ['gym:normal']={kind='normalDoor',delay=10,duration=4.5,interval=25},
 ['gym:sky']={kind='paperGust',delay=7,duration=4.5,interval=17},
 ['gym:water']={kind='paperIcicles',delay=13,duration=4.6,interval=31},
 ['league:dark']={kind='motes',delay=9,duration=4,interval=22},
 ['league:ghost']={kind='haunt',delay=18,duration=4.6,interval=37},
 ['league:ice']={kind='iceGlints',delay=9,duration=4,interval=23},
 ['league:dragon']={kind='bell',delay=13,duration=4.2,interval=31},
 ['league:champion']={kind='fountain',delay=11,duration=3.6,interval=24},
 ['ruins:sky']={kind='skyWind',delay=14,duration=4.6,interval=29},
 ['industrial:aqua']={kind='signals',delay=6,duration=4,interval=13},
 ['island:triangle']={kind='stars',delay=7,duration=5,interval=18},
}
local frontierKeys={frontierFactorySteam='facility:factory',frontierPyramidPebble='ruins:pyramid',frontierArenaBanner='facility:arena',frontierDomeRibbon='facility:dome',frontierPikeLamp='facility:pike',frontierTowerDoor='facility:tower'}
local function plan(scene)
 local h=scene.habitat or{}
 return scene.ambientPlan or plans[h.key]or plans[h.family]
end
function A.reset(scene)scene.ambient={quiet=0,age=0,cycle=0,active=false}end
-- Textured props share the quiet-event clock with particles. A battle action
-- freezes the exact pose; rendering has no timer or RNG side effects.
function A.cardPose(scene,kind,def)
 local a=scene.ambient;local p=plan(scene)
 if not a or not a.active or not p then return nil end
 if kind=='kantoSteam'then
  if not def or def.kantoKey~=scene.artKey then return nil end
  local u=(a.age-((def.eventIndex or 1)-1)*.45)/3.2
  if u<=0 or u>=1 then return nil end
  return{x=math.sin(u*4+(def.eventIndex or 1))*.9,y=u*8,spin=math.sin(u*3)*.07,
   scale=math.sin(u*math.pi)^2}
 end
 if kind=='kantoProp'then
  if not def or def.kantoKey~=scene.artKey then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  local e=math.sin(u*math.pi)^2;local i=def.eventIndex or 1;local m=def.kantoMotion
  local pose={x=0,y=0,spin=0};local phase=a.age*2.6+i*.8
  if m=='wheel'then pose.spin=2*math.pi*u*u*(3-2*u)
  elseif m=='banner'then pose.pitch=math.sin(phase)*e*.32
  elseif m=='pebble'and def.mount~='lid'then
   pose.spin=-e*3;pose.x=e*9;pose.y=math.abs(math.sin(pose.spin))*def.width*12
  elseif m=='ghost'then pose.x=math.sin(phase*.55)*e*8;pose.y=e*8;pose.spin=math.sin(phase)*e*.10
  elseif m=='leaf'or m=='paper'then pose.x=math.sin(phase*.6)*e*9;pose.y=e*5;pose.spin=math.sin(phase)*e*.3
  elseif m=='water'then pose.x=math.sin(phase)*e*4;pose.y=math.sin(phase+.5)*e*1.5
  elseif m=='mist'or m=='ember'then pose.y=e*8;pose.x=math.sin(phase)*e*3
  elseif m=='ice'or m=='spark'or m=='psychic'then pose.spin=math.sin(phase*.5)*e*.45;pose.y=e*4
  elseif m=='electric'or m=='scan'then pose.y=math.sin(phase*2)*e*1.5;pose.scale=1+math.sin(phase*3)*e*.09
  elseif m=='drop'then pose.y=-e*math.min(def.y+1,12)
  else pose.spin=math.sin(phase)*e*.13 end
  return pose
 end
 if kind=='paperDetail'then
  if not def or scene.artKey~=def.detailKey then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  local e=math.sin(u*math.pi)^2;local i=def.eventIndex or 1;local motion=def.detailMotion
  local pose={x=0,y=0,spin=0}
  if motion=='gear'or motion=='rotor'then
   -- Complete revolutions return to precisely the original printed pose.
   pose.spin=math.pi*2*(motion=='rotor'and 2 or 1)*(i%2==0 and -1 or 1)*u*u*(3-2*u)
  elseif motion=='banner'then pose.pitch=math.sin(a.age*3.9-i*.6)*e*.40
  elseif motion=='cloud'then pose.x=math.sin(u*math.pi*2)*e*13;pose.y=e*3
  elseif motion=='mist'then pose.x=(i%2==0 and -1 or 1)*e*15;pose.y=math.sin(u*math.pi*2)*e*3
  elseif motion=='bird'then pose.x=math.sin(u*math.pi*2+i)*e*14;pose.y=e*9;pose.spin=math.sin(u*8+i)*e*.16
  elseif motion=='star'then
   u=(a.age-(i-1)*.45)/3.2;if u<0 or u>1 then return nil end
   pose.y=math.sin(u*math.pi)*5;pose.spin=u*math.pi*2;pose.scale=math.sin(u*math.pi)^2
  elseif motion=='pebble'then
   u=(a.age-(i-1)*.28)/2.1;if u<0 or u>1 then return nil end
   pose.spin=-u*5.2;pose.x=u*17
   pose.y=math.abs(math.sin(pose.spin))*def.width*15+math.abs(math.cos(pose.spin))*2.6-2.6+.5+math.abs(math.sin(u*12))*(1-u)*1.1
   pose.scale=math.min(1,u*12,(1-u)*12)
  elseif motion=='drop'then
   u=(a.age-(i-1)*.55)/1.65;if u<0 or u>1 then return nil end
   pose.y=-(def.y+1.5)*u*u;pose.scale=math.min(1,u*12,(1-u)*14)
  end
  return pose
 end
 if kind=='shipCloth'or kind=='dockHook'or kind=='dockGull'then
  if not def or not scene.habitat or scene.habitat.key~=def.shipHabitat then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  local e=math.sin(u*math.pi)^2;local i=def.eventIndex or 1
  if kind=='shipCloth'then
   local wreck=def.shipHabitat=='ship:wreck'
   return{x=0,y=0,spin=0,pitch=math.sin(a.age*(wreck and 3.8 or 2.8)-i*.51)*e*(wreck and .48 or .32)}
  elseif kind=='dockHook'then
   return{x=0,y=0,spin=math.sin(a.age*2.7)*e*.16}
  end
  -- The renderer separates the three source silhouettes; x/y provide each
  -- bird's own phase without changing the atlas's original arrangement.
  local phase=def.x*1.8+def.y*.09
  return{x=math.sin(u*math.pi*2+phase)*e*11,y=(2+math.sin(a.age*2+phase)*4)*e,spin=math.sin(a.age*2.8+phase)*e*.12}
 end
 if kind=='navelCloud'or kind=='navelFeather'or kind=='navelDrop'then
  if not def or not scene.habitat or scene.habitat.key~=def.navelHabitat then return nil end
  local i=def.eventIndex or 1;local u=a.age/p.duration
  if u<0 or u>1 then return nil end
  if kind=='navelCloud'then
   local e=math.sin(math.pi*u)^2
   return{x=(i==1 and 1 or -1)*math.sin(u*math.pi*2)*e*10,y=e*(i==1 and 3 or 5),spin=math.sin(u*7+i)*e*.055}
  elseif kind=='navelFeather'then
   u=(a.age-(i-1)*.6)/4.8;if u<0 or u>1 then return nil end
   return{x=(i==1 and 1 or -1)*(u*22+math.sin(u*math.pi*3)*3),y=math.sin(u*math.pi)*5-u*6,
    spin=math.sin(u*math.pi*4+i)*.32,turn=math.sin(u*math.pi*3)*.42,
    scale=math.min(1,u*10,(1-u)*10)}
  end
  u=(a.age-(i-1)*.55)/1.55;if u<0 or u>1 then return nil end
  return{x=0,y=-(def.y-def.landingY)*u*u,spin=0,scale=math.min(1,u*10,(1-u)*18)}
 end
 if kind=='shoreCrab'or kind=='coastBird'or kind=='harborBird'or kind=='pondButterfly'then
  if not def or not scene.habitat or (scene.habitat.key~=def.shoreHabitat and not(kind=='harborBird'and scene.habitat.key=='sea:pacifidlog'and def.shoreHabitat=='floating:'))then return nil end
  local i=def.eventIndex or 1
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  if kind=='coastBird'or kind=='harborBird'then
   local envelope=math.sin(u*math.pi)^2
   return{x=math.sin(u*math.pi*2+(i-1)*math.pi)*envelope*11,y=envelope*(i==1 and 9 or 5),spin=math.sin(u*6+i)*envelope*.13}
  elseif kind=='shoreCrab'then
   -- Out from the driftwood, pause in the open, then retreat to the same spot.
   local travel=math.min(1,u/.33,(1-u)/.33);travel=travel*travel*(3-2*travel)
   local walking=u<.33 or u>.67
   return{x=travel*15,y=walking and math.abs(math.sin(a.age*17))*travel*.45 or 0,
    spin=walking and math.sin(a.age*9)*travel*.025 or 0,scale=math.min(1,u*12,(1-u)*12)}
  end
  u=(a.age-(i-1)*.55)/4.5;if u<0 or u>1 then return nil end
  local lift=math.sin(u*math.pi)^2
  return{x=(i==1 and 1 or -1)*(lift*12+math.sin(u*math.pi*2)*3),y=lift*17,
   spin=math.sin(u*8+i)*lift*.16,turn=math.sin(a.age*17+i)*.9,
   scale=math.min(1,u*10,(1-u)*10)}
 end
 if kind=='basePaperFringe'then
  if not def or not scene.habitat or scene.habitat.key~=def.baseHabitat or p.kind~='paperBase'then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  local i=def.eventIndex or 1;local garden=def.baseHabitat=='interior:garden'
  local swing=math.sin(a.age*(garden and 4.2 or 3.2)-i*.58)*math.sin(u*math.pi)^2
  return{x=0,y=0,spin=0,pitch=swing*(garden and .40 or .46)}
 end
 if kind=='underseaFish'or kind=='underseaBubble'then
  if not def or not scene.habitat or scene.habitat.key~=def.underseaHabitat then return nil end
  local i=def.eventIndex or 1
  if kind=='underseaBubble'then
   local u=(a.age-(i-1)*.42)/3.3
   if u<0 or u>1 then return nil end
   return{x=math.sin(u*5+i)*2.2*u,y=u*49,spin=math.sin(u*5+i)*.12,
    scale=math.min(1,u*8,(1-u)*7)}
  end
  local u=(a.age-((i-1)%5)*.10)/5
  if u<0 or u>1 then return nil end
  local function ease(v)return v*v*(3-2*v)end
  local x,turn=0,0
  if u<.4 then x=ease(u/.4)
  elseif u<.6 then x=1;turn=math.pi*ease((u-.4)/.2)
  elseif u<.9 then x=1-ease((u-.6)/.3);turn=math.pi
  else turn=math.pi+math.pi*ease((u-.9)/.1)end
  return{x=x*22*(def.swimDirection or -1),y=math.sin(u*math.pi)^2*3,
   spin=math.sin(u*math.pi)^2*math.sin(u*9+i)*.06,turn=turn}
 end
 if kind=='psychicPendant'or kind=='psychicMedallion'or kind=='waterIcicle'or kind=='waterPaperDrop'then
  local key=kind:sub(1,7)=='psychic'and'gym:psychic'or'gym:water'
  if not def or def.gymHabitat~=key or not scene.habitat or scene.habitat.key~=key then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  local i=def.eventIndex or 1
  if kind=='waterPaperDrop'then
   u=(a.age-.35-(i-1)*.62)/1.75
   if u<0 or u>1 then return nil end
   return{x=0,y=-(def.y-def.landingY)*u*u,spin=math.sin(u*7+i)*.055,
    scale=math.min(1,u*10,(1-u)*12)}
  end
  local envelope=math.sin(u*math.pi)^2
  local amplitude=kind=='psychicMedallion'and .20 or kind=='psychicPendant'and .32 or .14
  return{x=0,y=0,spin=math.sin(a.age*(kind=='waterIcicle'and 5 or 3.4)+(i-1)*.55)*envelope*amplitude}
 end
 if kind=='devonFanRotor'or kind=='labGlobeDisc'or kind=='hallRecordStar'then
  local key=kind=='devonFanRotor'and'industrial:devon'or kind=='labGlobeDisc'and'industrial:lab'or'league:hall'
  if not def or def.researchHabitat~=key or not scene.habitat or scene.habitat.key~=key then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  if kind~='hallRecordStar'then
   -- Whole turns end on the initial printed position, with a gentle start/stop.
   return{x=0,y=0,spin=math.pi*2*(kind=='devonFanRotor'and 3 or 1)*u*u*(3-2*u)}
  end
  u=(a.age-((def.eventIndex or 1)-1)*.42)/2.4
  if u<0 or u>1 then return nil end
  return{x=0,y=0,spin=math.sin(u*math.pi)*.2,scale=math.min(1,u*8,(1-u)*6)}
 end
 if kind=='spaceModelLift'or kind=='spaceModelSteam'or kind=='weatherGustRotor'or kind=='weatherWindowLeaf'then
  local key=scene.habitat and scene.habitat.key
  if not def or key~=(kind:sub(1,5)=='space'and 'industrial:space'or 'industrial:weather')then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  if kind=='spaceModelLift'then
   return{x=0,y=16*math.sin(u*math.pi)^2,spin=0}
  elseif kind=='weatherGustRotor'then
   -- Two extra turns accelerate/decelerate smoothly, preserving the idle
   -- rotor's phase at both endpoints instead of snapping back after a gust.
   return{x=0,y=0,spin=4*math.pi*u*u*(3-2*u)}
  end
  local i=def.eventIndex or 1
  u=(a.age-(i-1)*.36)/(kind=='spaceModelSteam'and 2.6 or 3.2)
  if u<0 or u>1 then return nil end
  local scale=math.min(1,u*10,(1-u)*9)
  if kind=='spaceModelSteam'then
   return{x=math.sin(u*5+i)*5*u,y=9*math.sin(u*math.pi),spin=math.sin(u*4+i)*.08,scale=scale}
  end
  return{x=46*u,y=-24*u+math.sin(u*7+i)*2,spin=u*4+i*.6,turn=math.sin(u*8+i)*.45,scale=scale}
 end
 if kind=='leaguePendant'or kind=='leagueBell'or kind=='leagueMedallion'or kind=='leagueSnowflake'then
  local key=scene.habitat and scene.habitat.key
  if not def or def.leagueHabitat~=key or not((kind=='leaguePendant'and(key=='league:ghost'or key=='league:champion'))or
   (kind=='leagueBell'and key=='league:dragon')or(kind=='leagueMedallion'and key=='league:dark')or
   (kind=='leagueSnowflake'and key=='league:ice'))then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  local envelope=math.sin(u*math.pi)^2;local i=def.eventIndex or 1
  if kind=='leagueSnowflake'then return{x=0,y=0,spin=math.pi*2*u*u*(3-2*u)}end
  local rate=kind=='leagueBell'and 7 or kind=='leagueMedallion'and 3.4 or key=='league:ghost'and 4.8 or 3.8
  local amplitude=kind=='leagueBell'and .34 or kind=='leagueMedallion'and .17 or key=='league:ghost'and .25 or .20
  local spin=math.sin(a.age*rate-(i-1)*.8)*envelope*amplitude;local hx=def.hingeX or 0
  return{x=hx*(1-math.cos(spin)),y=-hx*math.sin(spin),spin=spin}
 end
 if kind=='hillBanner'then
  if not def or not scene.habitat or scene.habitat.key~='facility:hill'then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  return{x=0,y=0,spin=math.sin(a.age*4.3-(def.eventIndex-1)*.7)*math.sin(u*math.pi)^2*.16}
 end
 if frontierKeys[kind]then
  if not def or not scene.habitat or scene.habitat.key~=frontierKeys[kind]then return nil end
  local i=def.eventIndex or 1
  if kind=='frontierFactorySteam'then
   local u=(a.age-(i-1)*.45)/3.3
   if u<0 or u>1 then return nil end
   return{x=math.sin(u*5+i)*2*u,y=u*20,spin=math.sin(u*4+i)*.09,scale=math.min(1,u*9,(1-u)*7)}
  elseif kind=='frontierPyramidPebble'then
   local u=(a.age-(i-1)*.18)/2.6
   if u<0 or u>1 then return nil end
   local spin=-u*5.2
   -- Lift by the rotating cutout's extent so its lower edge stays above sand.
   local support=math.abs(math.sin(spin))*def.width*15+math.abs(math.cos(spin))*2.4
   return{x=u*12,y=support-2.4+.4+math.abs(math.sin(u*13+i))*.45,spin=spin,
    scale=math.min(1,u*14,(1-u)*14)}
  elseif kind=='frontierDomeRibbon'then
   local u=(a.age-(i-1)*.18)/3.2
   if u<0 or u>1 then return nil end
   return{x=math.sin(u*8+i)*3,y=-u*36,spin=math.sin(u*9+i)*.6,turn=math.sin(u*7+i)*.45,scale=math.min(1,u*10,(1-u)*8)}
  elseif kind=='frontierPikeLamp'then
   local u=(a.age-(i-1)*.7)/1.2
   if u<0 or u>1 then return nil end
   return{x=0,y=0,spin=u*.5,scale=math.sin(u*math.pi)^2}
  end
  local u=a.age/p.duration
  if u<0 or u>1 then return nil end
  local envelope=math.sin(u*math.pi)^2
  if kind=='frontierTowerDoor'then
   local side=i==1 and -1 or 1;local turn=side*1.08*envelope;local hinge=side*def.width*15
   return{x=hinge*(1-math.cos(turn)),y=0,z=hinge*math.sin(turn),spin=0,turn=turn}
  end
  return{x=0,y=0,spin=math.sin(a.age*4+(i-1)*.65)*envelope*.18}
 end
 if def and def.natureEvent and kind=='nature_'..def.natureEvent..def.eventIndex then
  if not scene.habitat or scene.habitat.key~=def.natureHabitat then return nil end
  local i=def.eventIndex;local u=(a.age-(i-1)*.32)/3.5
  if u<0 or u>1 then return nil end
  local motion=def.natureEvent;local scale=math.min(1,u*10,(1-u)*8)
  if motion=='grassButterfly'then
   return {x=(i==1 and -1 or 1)*math.sin(u*math.pi)*3,y=math.sin(u*math.pi)*13,
    spin=math.sin(u*7+i)*.14,turn=math.sin(a.age*16+i)*.8,scale=scale}
  elseif motion=='routeAsh'then
   return {x=u*4+math.sin(u*7+i),y=math.sin(u*math.pi)*6,spin=u*1.8+i*.3,scale=scale}
  elseif motion=='meadowPetal'then
   return {x=u*5+math.sin(u*6+i),y=math.sin(u*math.pi)*7-u*10,
    spin=math.sin(u*7+i)*.6,turn=math.sin(u*8+i)*.45,scale=scale}
  end
  local side=motion=='islandPetal'and 1 or -1
  return {x=side*(u*3+math.sin(u*8+i)*1.5),y=-u*u*(motion=='ancientFrond'and 42 or 35),
   spin=math.sin(u*8+i)*.55,turn=math.sin(u*6+i)*.4,scale=scale}
 end
 if kind=='museumBell'or kind=='verdanturfFan'or kind=='fallarborTrophySpark'then
  local key=kind=='museumBell'and'interior:museum'or kind=='verdanturfFan'and'facility:tent_verdanturf'or'facility:tent_fallarbor'
  if not def or not scene.habitat or scene.habitat.key~=key then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  local envelope=math.sin(u*math.pi)^2
  if kind=='fallarborTrophySpark'then
   return {x=0,y=0,spin=u*.4,scale=envelope*(.60+.40*math.sin(u*math.pi*3)^2)}
  end
  local spin=math.sin(a.age*(kind=='museumBell'and 6 or 8))*envelope*(kind=='museumBell'and .18 or .22)
  local h=def.hingeX or 0
  return {x=h*(1-math.cos(spin)),y=-h*math.sin(spin),spin=spin}
 end
 local ribbon=tonumber(kind:match('^slateportRibbon([12])$'))
 if ribbon then
  if not scene.habitat or scene.habitat.key~='facility:tent_slateport'then return nil end
  local u=(a.age-(ribbon-1)*.5)/3.8;if u<0 or u>1 then return nil end
  return {x=math.sin(u*7+ribbon)*3,y=-u*30,spin=math.sin(u*6+ribbon)*.30,
   scale=math.min(1,u*10,(1-u)*8)}
 end
 local spark=tonumber(kind:match('^mauvilleSpark([12])$'))
 local petal=tonumber(kind:match('^everGrandePetal([123])$'))
 if spark or petal then
  local key=spark and 'city:mauville'or 'city:ever_grande'
  if not scene.habitat or scene.habitat.key~=key then return nil end
  local i=spark or petal;local u=(a.age-(i-1)*.4)/(spark and 3.7 or 3.8)
  if u<0 or u>1 then return nil end
  if spark then
   return {x=0,y=0,spin=math.sin(u*9)*.15,
    scale=math.min(1,u*10,(1-u)*10)*(.55+.45*math.sin(u*math.pi*4)^2)}
  end
  return {x=u*6+math.sin(u*8+i)*2,y=-u*u*29,spin=math.sin(u*7+i)*.65,
   turn=math.sin(u*9+i)*.55,scale=math.min(1,u*10,(1-u)*8)}
 end
 if kind=='frontierPennant'then
  if not def or not scene.habitat or scene.habitat.key~='city:frontier'then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  return {x=0,y=0,spin=math.sin(a.age*4+(def.floatPhase or 0))*math.sin(u*math.pi)^2*.14}
 end
 local steam=tonumber(kind:match('^lavaridgeSteam([123])$'))
 local ash=tonumber(kind:match('^fallarborAsh([123])$'))
 if steam or ash then
  local key=steam and 'city:lavaridge'or 'city:fallarbor'
  if not scene.habitat or scene.habitat.key~=key then return nil end
  local i=steam or ash;local u=(a.age-(i-1)*.45)/3.7
  if u<0 or u>1 then return nil end
  return {x=steam and math.sin(u*5+i)*2 or u*5+math.sin(u*8+i),
   y=steam and u*23 or math.sin(u*math.pi)*7,spin=math.sin(u*6+i)*(steam and .08 or .55),
   scale=math.min(1,u*8,(1-u)*5)}
 end
 if kind=='littlerootRotor'or kind=='oldaleSign'then
  local key=kind=='littlerootRotor'and'city:littleroot'or'city:oldale'
  if not def or not scene.habitat or scene.habitat.key~=key then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  if kind=='littlerootRotor'then
   local spin=math.pi*4*(u-math.sin(u*math.pi*2)/(math.pi*2))
   local h=def.hingeX or 0
   return {x=h*(1-math.cos(spin)),y=-h*math.sin(spin),spin=spin}
  end
  local turn=math.sin(a.age*4)*math.sin(u*math.pi)^2*.4;local half=def.width*15
  return {x=half*(math.cos(turn)-1),y=0,z=-half*math.sin(turn),spin=0,turn=turn}
 end
 local butterfly=tonumber(kind:match('^verdanturfButterfly([12])$'))
 if butterfly then
  if not scene.habitat or scene.habitat.key~='city:verdanturf'then return nil end
  local u=(a.age-(butterfly-1)*.45)/4.3;if u<0 or u>1 then return nil end
  local lift=math.sin(u*math.pi)
  return {x=math.sin(u*math.pi*2)*(butterfly==1 and 5 or -5),y=lift*12,
   spin=math.sin(u*7)*.14,turn=math.sin(a.age*18+butterfly)*.85,
   scale=math.min(1,u*9,(1-u)*9)}
 end
 local leaf=tonumber(kind:match('^petalburgLeaf([123])$'))
 if leaf then
  if not scene.habitat or scene.habitat.key~='city:petalburg'then return nil end
  local u=(a.age-(leaf-1)*.35)/3.8;if u<0 or u>1 then return nil end
  return {x=u*7+math.sin(u*9+leaf)*2,y=-u*u*30,spin=math.sin(u*8+leaf)*.6,
   scale=math.min(1,u*12,(1-u)*9)}
 end
 if kind=='dewfordCrab'or kind=='lilycoveCrab'then
  local key=kind=='dewfordCrab'and'city:dewford'or'city:lilycove'
  if not scene.habitat or scene.habitat.key~=key then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  -- The flat crab walks out from its shore decoration, pauses and retreats.
  local walk=math.sin(math.pi*u)^2
  return {x=(kind=='dewfordCrab'and 1 or -1)*walk*12,y=math.abs(math.sin(a.age*16))*walk*.55,
   spin=math.sin(a.age*8)*walk*.035,scale=math.min(1,u*10,(1-u)*10)}
 end
 if kind=='mossdeepDish'or kind=='slateportHook'or kind=='slateportPennant'then
  local key=kind=='mossdeepDish'and'city:mossdeep'or'city:slateport'
  if not def or not scene.habitat or scene.habitat.key~=key then return nil end
  local u=a.age/p.duration;if u<0 or u>1 then return nil end
  local envelope=math.sin(u*math.pi)^2
  if kind=='mossdeepDish'then
   local turn=math.sin(u*math.pi*2)*.65*envelope
   local hinge=def.hingeX or 0
   return {x=hinge*(1-math.cos(turn)),y=0,z=hinge*math.sin(turn),spin=0,turn=turn}
  end
  local phase=kind=='slateportHook'and 0 or(def.floatPhase or 0)
  return {x=0,y=0,spin=math.sin(a.age*4+phase)*envelope*(kind=='slateportHook'and .22 or .12)}
 end
 if kind=='dojoTarget'or kind=='normalDoor'or kind=='skyFeather'then
  local key=kind=='dojoTarget'and'gym:fighting'or kind=='normalDoor'and'gym:normal'or'gym:sky'
  if not scene.habitat or scene.habitat.key~=key then return nil end
  local u=a.age/p.duration
  if u<0 or u>1 then return nil end
  local envelope=math.sin(u*math.pi)^2
  if kind=='normalDoor'then
   if not def then return nil end
   local turn=-.95*envelope;local half=def.width*15
   -- Translate the leaf while rotating it so its left edge stays fixed.
   return {x=half*(math.cos(turn)-1),y=0,z=-half*math.sin(turn),spin=0,turn=turn}
  end
  local phase=def and def.floatPhase or 0
  return {x=0,y=0,spin=kind=='dojoTarget'and math.sin(a.age*7)*envelope*.16 or math.sin(a.age*5+phase)*envelope*.24}
 end
 local smoke=tonumber(kind:match('^rustboroSmoke([123])$'))
 if smoke then
  if not scene.habitat or scene.habitat.key~='city:rustboro'then return nil end
  local u=(a.age-(smoke-1)*.55)/3.2
  if u<0 or u>1 then return nil end
  return {x=u*7,y=u*22,spin=math.sin(u*math.pi)*.1,scale=math.min(1,u*8,(1-u)*7)*(.5+u*.5)}
 end
 if kind=='artisanTail'then
  if not scene.habitat or scene.habitat.key~='cave:artisan'then return nil end
  local u=a.age/p.duration
  if u<0 or u>1 then return nil end
  return {x=0,y=math.sin(u*math.pi)^2*10,spin=0,scale=1}
 end
 local paint=tonumber(kind:match('^artisanPaint([123])$'))
 if paint then
  if not scene.habitat or scene.habitat.key~='cave:artisan'then return nil end
  local u=(a.age-1.35-(paint-1)*.15)/1.6
  if u<0 or u>1 then return nil end
  return {x=u*(paint-2)*2,y=-13*u*u,spin=(paint-2)*u*.25,scale=math.min(1,u*8,(1-u)*8)}
 end
 local bat=tonumber(kind:match('^alteringBat([01])$'))
 if bat then
  if not scene.habitat or scene.habitat.key~='cave:altering'then return nil end
  local u=a.age/p.duration
  if u<0 or u>1 or math.floor(a.age*8)%2~=bat then return nil end
  return {x=u*90,y=math.sin(u*math.pi)*8,spin=0,scale=math.min(1,u*9,(1-u)*9)}
 end
 if kind=='aquaPeriscope'then
  if not scene.habitat or scene.habitat.key~='industrial:aqua'then return nil end
  local u=a.age/p.duration
  if u<0 or u>1 then return nil end
  return {x=0,y=math.sin(u*math.pi)^2*20,spin=0,scale=1}
 end
 if kind=='shoalCrab'then
  if not scene.habitat or scene.habitat.key~='watercave:salt'then return nil end
  local u=a.age/3.7
  if u<0 or u>1 then return nil end
  return {x=u*18,y=math.abs(math.sin(u*math.pi*15))*.35,spin=math.sin(u*math.pi*15)*.045,
   scale=math.min(1,u*8,(1-u)*8)}
 end
 local shoal,bit=kind:match('^shoal(%a+)([123])$');bit=tonumber(bit)
 if bit then
  local keys={Drop='watercave:tide',Salt='watercave:salt',Frost='ice:'}
  if not keys[shoal]or not scene.habitat or scene.habitat.key~=keys[shoal]then return nil end
  local u=(a.age-(bit-1)*.28)/(shoal=='Drop'and 2.5 or 3.1)
  if u<0 or u>1 then return nil end
  local distance=shoal=='Drop'and({42,54,42})[bit]or shoal=='Salt'and 31 or 66
  return {x=shoal=='Drop'and 0 or math.sin(u*5+bit)*3,y=-distance*(shoal=='Drop'and u*u or u),
   spin=shoal=='Drop'and 0 or u*math.pi*(shoal=='Frost'and .8 or 2),
   scale=math.min(1,u*10,(1-u)*9)}
 end
 local volcanic,particle=kind:match('^(%a+)Volcanic([123])$');particle=tonumber(particle)
 if particle then
  local keys={path='lava:path',magma='lava:magma',volcano='volcano:'}
  if not keys[volcanic]or not scene.habitat or scene.habitat.key~=keys[volcanic]then return nil end
  local steam=volcanic=='path'
  local u=(a.age-(particle-1)*.32)/(steam and 3.1 or 2.7)
  if u<0 or u>1 then return nil end
  return {x=math.sin(u*4+particle)*u*(steam and 3 or 5),y=u*(steam and 23 or 27),
   spin=steam and math.sin(u*math.pi)*.12 or u*math.pi*2,
   scale=math.min(1,u*9,(1-u)*8)*(steam and(.65+u*.35)or 1)}
 end
 if kind=='safariButterfly'then
  if not scene.habitat or scene.habitat.family~='safari'then return nil end
  local u=a.age/p.duration
  if u<0 or u>1 then return nil end
  return {x=math.sin(u*math.pi)*19,y=math.sin(u*math.pi)*15+math.sin(u*math.pi*4)*2,
   spin=math.sin(u*math.pi*3)*.19,turn=math.sin(a.age*12)*.60,scale=math.min(1,u*8,(1-u)*8)}
 end
 if kind=='rusturfDust'or kind=='roxanneDust'then
  if not scene.habitat or scene.habitat.key~=(kind=='roxanneDust'and'gym:rock'or'cave:rusturf')then return nil end
  local u=(a.age-1)/2.2
  if u<0 or u>1 then return nil end
  return {x=u*4,y=u*5,spin=u*.15,scale=math.sin(u*math.pi)*.8}
 end
 local cave,pebble=kind:match('^(%a+)Pebble([123])$');pebble=tonumber(pebble)
 if pebble then
  if(cave~='granite'and cave~='victory'and cave~='rusturf'and cave~='roxanne')or not scene.habitat or scene.habitat.key~=(cave=='roxanne'and'gym:rock'or'cave:'..cave)then return nil end
  local u=(a.age-(pebble-1)*.23)/2.1
  if u<0 or u>1 then return nil end
  return {x=(1-(1-u)^2)*13,y=math.abs(math.sin(u*math.pi*3))*(1-u)*2.8,
   spin=-u*math.pi*6,scale=math.min(1,u*10,(1-u)*8)}
 end
 local bubble=tonumber(kind:match('^marineBubble([123])$'))
 if bubble then
  if not scene.habitat or scene.habitat.key~='watercave:marine'then return nil end
  local u=(a.age-(bubble-1)*.33)/2.7
  if u<0 or u>1 then return nil end
  return {x=math.sin(u*math.pi*2+bubble)*1.7,y=u*16,spin=math.sin(u*math.pi)*.08,
   scale=math.min(1,u*9,(1-u)*9)*(.65+u*.35)}
 end
 local ember=tonumber(kind:match('^terraEmber([123])$'))
 if ember then
  if not scene.habitat or scene.habitat.key~='lava:ancient'then return nil end
  local u=(a.age-(ember-1)*.28)/2.7
  if u<0 or u>1 then return nil end
  return {x=u*9+math.sin(u*math.pi*2+ember)*1.5,y=u*24,spin=u*math.pi*2,
   scale=math.min(1,u*8,(1-u)*8)}
 end
 local spray=tonumber(kind:match('^seafloorSpray([123])$'))
 if spray then
  if not scene.habitat or scene.habitat.key~='watercave:seafloor'then return nil end
  local u=(a.age-(spray-1)*.18)/2.3
  if u<0 or u>1 then return nil end
  return {x=(spray-2)*u*4,y=math.sin(u*math.pi)*10,
   spin=(spray-2)*u*.35,scale=math.min(1,u*10,(1-u)*10)}
 end
 local dropCave,caveDrop=kind:match('^(%a+)Drop([123])$');caveDrop=tonumber(caveDrop)
 if caveDrop and(dropCave=='meteor'or dropCave=='origin')then
  local key=dropCave=='meteor'and'watercave:meteor'or'cave:origin'
  if not scene.habitat or scene.habitat.key~=key then return nil end
  local u=(a.age-(caveDrop-1)*.32)/2.4
  if u<0 or u>1 then return nil end
  local travel=(dropCave=='meteor'and{59,47,54}or{46,64,45})[caveDrop]
  return {x=math.sin(u*math.pi)*.7,y=-travel*u*u,
   scale=math.min(1,u*12,(1-u)*14),spin=math.sin(u*math.pi*2)*.025}
 end
 local drop=tonumber(kind:match('^rainDrop([123])$'))
 if drop then
  if not scene.habitat or scene.habitat.family~='rainforest'then return nil end
  local u=(a.age-(drop-1)*.40)/2.5
  if u<0 or u>1 then return nil end
  return {x=math.sin(u*math.pi)*1.8,y=-53*u*u,spin=math.sin(u*math.pi*2)*.035}
 end
 if kind~='tumbleweed'or p.kind~='sandGust'then return nil end
 local u=math.max(0,math.min(1,a.age/p.duration))
 return {x=-58+u*116,y=math.abs(math.sin(u*math.pi*5))*1.7,spin=-u*math.pi*5}
end
function A.update(scene,dt,quiet)
 if not scene.ambient then A.reset(scene)end
 local p=plan(scene)
 if not p or not quiet then return end
 local a=scene.ambient;dt=math.max(0,math.min(dt or 0,.1))
 if a.active then
  a.age=a.age+dt
  if a.age>=p.duration then a.active=false;a.quiet=0;a.cycle=a.cycle+1 end
 else
  a.quiet=a.quiet+dt
  if a.quiet>=(a.cycle==0 and p.delay or p.interval)then a.active=true;a.age=0 end
 end
end
function A.samples(scene)
 local a=scene.ambient;local p=plan(scene)
 if not a or not p or not a.active then return{}end
 local out={}
 if p.kind=='paperShip'or p.kind=='paperDock'then return out end
 if p.kind=='paperNavelSky'then return out end
 if p.kind=='paperNavelTide'then
  for i,source in ipairs({{-1.42,2.55},{1.43,2.55},{-1.50,2.59},{1.50,2.59}})do
   local u=(a.age-1.55-(i-1)*.55)/2.25
   if u>=0 and u<=1 then
    out[#out+1]={kind='waterRipple',x=source[1]*30,y=-2.05,z=source[2]*30,
     size=.8+u*5.2,spin=0,alpha=math.sin(u*math.pi)^2*.85,eventIndex=i}
   end
  end
  return out
 end
 if p.kind=='paperCoast'then return out end
 if p.kind=='harborRipples'or p.kind=='paperPond'then
  local harbor=p.kind=='harborRipples'
  for side=1,2 do for ring=1,3 do
   local u=(a.age-(side-1)*.8-(ring-1)*.56)/3.2
   if u>=0 and u<=1 then
    out[#out+1]={kind='waterRipple',x=(side==1 and -1 or 1)*(harbor and 54 or 56),
     y=-2.05,z=harbor and 74 or 62,size=(harbor and 1.5 or 2)+u*6.5,
     spin=0,alpha=math.sin(u*math.pi)^2*.76,eventIndex=(side-1)*3+ring}
   end
  end end
  return out
 end
 if p.kind=='paperFish'or p.kind=='paperBubbles'or p.kind=='paperBase'then return out end
 local h=scene.habitat or{}
 if h.key=='gym:psychic'or h.key=='gym:water'then return out end
 if h.key=='industrial:devon'or h.key=='industrial:lab'or h.key=='league:hall'then return out end
 if h.key=='industrial:space'or h.key=='industrial:weather'then return out end
 if h.key=='league:dark'or h.key=='league:ghost'or h.key=='league:ice'or h.key=='league:dragon'or h.key=='league:champion'then return out end
 if h.key=='facility:factory'or h.key=='ruins:pyramid'or h.key=='facility:arena'or h.key=='facility:dome'or h.key=='facility:pike'or h.key=='facility:tower'then return out end
 -- These reviewed stages use their own textured paper event cards.
 if h.key=='forest:'or h.key=='meadow:'or h.key=='meadow:long_grass'or h.key=='forest:ancient'or h.key=='forest:island'or h.key=='ash:'then return out end
 if p.kind=='healLights'then
  for i=1,6 do local u=(a.age-(i-1)*.22)/2.6
   if u>=0 and u<=1 then out[#out+1]={kind='healLight',x=-24+(i-1)*10,y=31.5,z=-69.5,size=1.2+math.sin(u*math.pi)*.4,spin=0,alpha=math.sin(u*math.pi)*.86}end
  end
 elseif p.kind=='receipt'then
  local u=a.age/p.duration
  out[1]={kind='receipt',x=-17+math.sin(u*6)*3,y=56+u*15,z=-62,size=1.4,spin=math.sin(u*7)*.2,alpha=math.sin(u*math.pi)*.8}
 elseif p.kind=='dockRipple'then
  for i=1,4 do local u=(a.age-(i-1)*.25)/3
   if u>=0 and u<=1 then out[#out+1]={kind='bubble',x=-20+i*9+u*4,y=1+math.sin(u*math.pi)*1.5,z=83,size=.5+u*.5,spin=0,alpha=math.sin(u*math.pi)*.5}end
  end
 elseif p.kind=='cargoDust'then
  for i=1,5 do local u=(a.age-(i-1)*.12)/2.6
   if u>=0 and u<=1 then out[#out+1]={kind='dust',x=-67+i*1.3+u*5,y=12+u*9,z=42,size=.36,spin=u*2,alpha=math.sin(u*math.pi)*.55}end
  end
 elseif p.kind=='starTrace'then
  local u=a.age/p.duration
  out[1]={kind='star',x=34+u*31,y=106-u*23,z=-66,size=.75,spin=u,alpha=math.sin(u*math.pi)^2*.7}
 elseif p.kind=='emberBurst'then
  if scene.habitat and(scene.habitat.key=='lava:ancient'or scene.habitat.key=='lava:magma'or scene.habitat.key=='volcano:')then return out end
  for i=1,7 do local u=(a.age-(i-1)*.12)/3.0
   if u>=0 and u<=1 then out[#out+1]={kind='ember',x=-37+u*20+i*3,y=26+u*29,z=-38,size=.42+(i%3)*.12,spin=u*6,alpha=math.sin(u*math.pi)*.8}end
  end
 elseif p.kind=='ventPuff'then
  if scene.habitat and scene.habitat.key=='lava:path'then return out end
  local devon=scene.habitat and scene.habitat.key=='industrial:devon'
  for i=1,3 do local u=(a.age-(i-1)*.35)/3.1
   if u>=0 and u<=1 then out[#out+1]={kind='steam',x=(devon and -25.5 or 19)+math.sin(u*4)*3,y=(devon and 103 or 62)+u*18,z=devon and -82 or -57,size=1.4+u*2.6,spin=u*.4,alpha=math.sin(u*math.pi)*.32}end
  end
 elseif p.kind=='regiceFrost'then
  -- Shed paper frost in front of the upper ice walls. Generic cave drips
  -- fell behind the tall side cards and were completely depth-occluded.
  for i,source in ipairs({{-46,127,-62},{-7,135,-78},{43,129,-59}})do
   local u=(a.age-(i-1)*.28)/2.8
   if u>=0 and u<=1 then out[#out+1]={kind='star',x=source[1]+math.sin(u*5+i)*2,
    y=source[2]-u*u*37,z=source[3],size=2.2+(i%2)*.35,spin=u*2+i,
    alpha=math.sin(u*math.pi)*.82}end
  end
 elseif p.kind=='caveDrips'then
  if scene.habitat and(scene.habitat.key=='watercave:meteor'or scene.habitat.key=='cave:origin'or scene.habitat.key=='watercave:tide')then return out end
  for i=1,4 do local u=(a.age-(i-1)*.24)/2.6
   if u>=0 and u<=1 then out[#out+1]={kind='bubble',x=-46+i*7,y=62-u*u*59,z=-42,size=.38,spin=0,alpha=math.sin(u*math.pi)*.8}end
  end
 elseif p.kind=='saltFall'or p.kind=='frostShower'then
  if scene.habitat and(scene.habitat.key=='watercave:salt'or scene.habitat.key=='ice:')then return out end
  for i=1,7 do local u=(a.age-(i-1)*.14)/3.1
   if u>=0 and u<=1 then out[#out+1]={kind=p.kind=='saltFall'and'salt'or'star',x=-39+i*9+math.sin(u*5+i)*3,y=67-u*51,z=-35,size=.37+(i%2)*.17,spin=u*4,alpha=math.sin(u*math.pi)*.72}end
  end
 elseif p.kind=='petals'then
  for i=1,5 do local u=(a.age-(i-1)*.24)/3.4
   if u>=0 and u<=1 then out[#out+1]={kind='leaf',x=-49+u*57,y=13+math.sin(u*5+i)*3,z=-18+u*9,
    size=.48,spin=u*8+i,alpha=math.sin(u*math.pi)*.7}end
  end
 elseif p.kind=='seaSpray'then
  if scene.habitat and scene.habitat.key=='watercave:seafloor'then return out end
  for i=1,6 do local u=(a.age-(i-1)*.12)/2.8
   if u>=0 and u<=1 then out[#out+1]={kind='bubble',x=-33+i*6+u*9,y=11+math.sin(u*math.pi)*10,z=-40,
    size=.35+u*.25,spin=0,alpha=math.sin(u*math.pi)*.7}end
  end
 elseif p.kind=='pondBubbles'then
  if scene.habitat and scene.habitat.key=='watercave:marine'then return out end
  local marine=scene.habitat and(scene.habitat.key=='watercave:marine'or scene.habitat.family=='underwater')
  for i=1,4 do local u=(a.age-(i-1)*.4)/2.6
   if u>=0 and u<=1 then out[#out+1]={kind='bubble',x=(marine and -13+i*5 or -44)+math.sin(u*4)*1.8,y=1+u*7,z=marine and 86 or -8+i*3,
    size=.45+u*.4,spin=0,alpha=math.sin(u*math.pi)*.6}end
  end
 elseif p.kind=='ashGust'or p.kind=='sandGust'then
  for i=1,9 do local u=(a.age-(i-1)*.12)/3.3
   if u>=0 and u<=1 then out[#out+1]={kind='dust',x=-54+u*91,y=31+i*2-u*14,z=-34+i,
    size=.40,spin=u*5,alpha=math.sin(u*math.pi)*.6}end
  end
 elseif p.kind=='pebbles'then
  -- These caves use authored paper pebble cards instead of generic geometry.
  if scene.habitat and(scene.habitat.key=='cave:granite'or scene.habitat.key=='cave:victory'or scene.habitat.key=='cave:rusturf'or scene.habitat.key=='gym:rock')then return out end
  for i=1,3 do
   local u=(a.age-(i-1)*.23)/2.1
   if u>=0 and u<=1 then
    local travel=1-(1-u)^2
    local pyramid=scene.habitat and scene.habitat.key=='ruins:pyramid'
    local granite=scene.habitat and(scene.habitat.key=='cave:granite'or scene.habitat.key=='cave:victory')
    out[#out+1]={kind='pebble',x=granite and(-59+travel*13+i*1.3)or pyramid and(-69+travel*3+i*.7)or(-52+travel*15+i*2),z=granite and(24+travel*9-i)or pyramid and(24+travel*28-i)or(-23+travel*17-i),
     y=(granite and 8 or -1.75)+math.abs(math.sin(u*math.pi*3))*(1-u)*2.8,
     size=.7+i*.16,spin=u*math.pi*6,alpha=math.min(1,u*10,(1-u)*8)}
   end
  end
 elseif p.kind=='linkSignal'then
  -- A quiet connection pulse crosses between the two paper terminals.
  for i=1,5 do local u=(a.age-(i-1)*.17)/2.6
   if u>=0 and u<=1 then out[#out+1]={kind='star',x=-57+114*u,y=70+math.sin(u*math.pi)*23,z=-55,
    size=4.0,spin=u*math.pi,alpha=math.sin(u*math.pi)*.85}end
  end
 elseif p.kind=='recordLights'then
  -- Six recording lights appear in succession above the archival console.
  for i=1,6 do local u=(a.age-(i-1)*.18)/2.7
   if u>=0 and u<=1 then out[#out+1]={kind='star',x=-30+(i-1)*12,y=79+math.sin(u*math.pi)*5,z=-72,size=.8,spin=u*.4,alpha=math.sin(u*math.pi)*.8}end
  end
 elseif p.kind=='leaves'or p.kind=='treeChime'then
  for i=1,3 do local u=(a.age-(i-1)*.35)/3.5
   if u>=0 and u<=1 then out[#out+1]={kind='leaf',x=-45+u*31+i*4,y=23*(1-u)+2,z=-26+u*15,
    size=.9,spin=math.sin(u*math.pi*3+i)*.7,alpha=math.min(1,u*8,(1-u)*8)}end
  end
 elseif p.kind=='chimney'and scene.ambientOrigin then
  local o=scene.ambientOrigin
  for i=1,3 do local u=(a.age-(i-1)*.7)/3.2
   if u>=0 and u<=1 then out[#out+1]={kind='smoke',x=o[1]+u*5,y=o[2]+u*14,z=o[3],size=1.4+u*2.5,spin=.2,alpha=math.sin(u*math.pi)*.17}end
  end
 elseif p.kind=='kyogre'then
  local u=a.age/p.duration
  local marine=scene.habitat and scene.habitat.key=='underwater:marine'
  out[1]={kind='kyogre',x=-66+u*132,y=marine and -6 or -38,z=marine and 83 or -28+math.sin(u*math.pi)*8,
   size=18,spin=-math.pi/2+.10*math.sin(u*math.pi*2),alpha=math.sin(u*math.pi)^2*(marine and .22 or .15)}
 elseif p.kind=='skyWind'then
  for i=1,3 do local u=(a.age-(i-1)*.35)/3.5
   if u>=0 and u<=1 then out[#out+1]={kind='wisp',x=-54+u*108,y=83+i*4+math.sin(u*5)*3,z=-46,size=1.8,spin=math.pi/2+.12*math.sin(u*5),alpha=math.sin(u*math.pi)^2*.4}end
  end
 elseif p.kind=='fountain'then
  for i=1,6 do local u=(a.age-(i-1)*.16)/2.2
   if u>=0 and u<=1 then out[#out+1]={kind='bubble',x=(i%2==0 and -1 or 1)*(31+u*7),y=18+math.sin(u*math.pi)*9,z=-43+u*8,size=.45+u*.35,spin=0,alpha=math.sin(u*math.pi)*.65}end
  end
 elseif p.kind=='confetti'then
  for i=1,12 do local u=(a.age-(i-1)*.07)/3.5
   if u>=0 and u<=1 then out[#out+1]={kind=i%2==0 and'star'or'leaf',x=-52+i*8+math.sin(u*6+i)*3,y=100-u*44,z=-56,size=.68,spin=u*7+i,alpha=math.sin(u*math.pi)*.65}end
  end
 elseif p.kind=='motes'then
  for i=1,5 do local u=(a.age+(i-1)*.4)/5
   if u<1 then out[#out+1]={kind='dust',x=-44+i*2+math.sin(u*5+i),y=37+u*12,z=-29,
    size=.3,spin=u,alpha=math.sin(u*math.pi)*.5}end
  end
 elseif p.kind=='iceGlints'then
  for i,o in ipairs({{-47,17,-28},{44,21,-28},{0,26,-42}})do
   local u=(a.age-(i-1)*.35)/2.8
   if u>0 and u<1 then out[#out+1]={kind='star',x=o[1],y=o[2],z=o[3],size=.8+math.sin(u*math.pi)*.5,spin=0,alpha=math.sin(u*math.pi)^2*.6}end
  end
 elseif p.kind=='sparks'then
  for i,x in ipairs({-55.5,55.5})do
   local u=(a.age-(i-1)*.6)/1.4
   if u>0 and u<1 then out[#out+1]={kind='spark',x=x,y=37,z=-37.8,
    size=7.1,spin=math.sin(u*17)*.07,alpha=math.sin(u*math.pi)^2*(.6+.4*math.sin(u*71)^2)}end
  end
 elseif p.kind=='steamPuff'then
  for i,x in ipairs({-41.4,41.4})do local u=(a.age-(i-1)*.5)/3.2
   if u>0 and u<1 then out[#out+1]={kind='steam',x=x+math.sin(u*3)*2,y=17+u*20,z=-35,
    size=2.5+u*3,spin=math.sin(u*4)*.12,alpha=math.sin(u*math.pi)*.38}end
  end
 elseif p.kind=='orbit'then
  for i=1,3 do local u=a.age/p.duration;local angle=u*math.pi*2+(i-1)*math.pi*2/3
   out[#out+1]={kind='star',x=48.6+math.cos(angle)*10,y=24+math.sin(angle)*7,z=-36,
    size=2.1+.4*math.sin(angle)^2,spin=angle,alpha=math.sin(u*math.pi)^2*.86}
  end
 elseif p.kind=='stars'then
  for i,o in ipairs({{-20,64,-82},{22,74,-82},{0,84,-82}})do
   local u=(a.age-(i-1)*.45)/3.3
   if u>0 and u<1 then out[#out+1]={kind='star',x=o[1],y=o[2],z=o[3],size=.7+math.sin(u*math.pi)*.6,spin=0,alpha=math.sin(u*math.pi)^2*.45}end
  end
 end
 return out
end
-- Continuous environment motion uses the water clock. Larger surprise events
-- above still pause during combat; these small background loops remain alive.
function A.continuous(scene)
 local h=scene.habitat or{};local time=scene.waterTime or 0;local out={}
 if h.key=='cave:granite'or h.key=='cave:victory'or h.key=='cave:fossil'or h.key=='ruins:'or h.key=='ruins:sand'then
  local front=h.key~='cave:granite'
  for i=1,7 do local u=(time/8+i*.139)%1
   out[#out+1]={kind='dust',x=-21+i*6+math.sin(time*.4+i),y=(front and 100 or 116)-u*(front and 60 or 92),z=front and -42 or -79,size=front and .55 or .40,spin=u,alpha=math.sin(u*math.pi)*.45}
  end
 elseif h.key=='ruins:pyramid'or h.key=='ruins:regirock'or h.key=='ruins:registeel'then
  for i=1,7 do local u=(time/7+i*.139)%1
   out[#out+1]={kind='dust',x=-46+i*13,y=90-u*83,z=-49,size=.46,spin=u*3,alpha=math.sin(u*math.pi)*.45}
  end
 elseif h.family=='lava'or h.family=='volcano'then
  for i=1,5 do local u=(time/6+i*.197)%1
   out[#out+1]={kind='ember',x=-39+i*15+math.sin(u*5+i)*3,y=19+u*35,z=-37,
    size=.26+i*.04,spin=u*5,alpha=math.sin(u*math.pi)*.65}
  end
 elseif h.key=='watercave:salt'then
  for i=1,7 do local u=(time/6+i*.139)%1
   out[#out+1]={kind='salt',x=-45+i*8,y=64-u*55,z=-35,size=.52,spin=u*2,alpha=math.sin(u*math.pi)*.52}
  end
 elseif h.family=='ice'then
  for i=1,4 do local u=(time/8+i*.243)%1
   out[#out+1]={kind='star',x=-46+i*20+math.sin(u*4)*2,y=59-u*40,z=-34,size=.28,spin=u,alpha=math.sin(u*math.pi)*.5}
  end
 elseif h.family=='desert'then
  for i=1,6 do local u=(time/5+i*.16)%1
   out[#out+1]={kind='dust',x=-58+u*100,y=3+i*1.2,z=-43+i*3,size=.3,spin=u*5,alpha=math.sin(u*math.pi)*.35}
  end
 elseif h.family=='ash'then
  for i=1,12 do local u=(time/7+i*.083)%1
   out[#out+1]={kind='dust',x=-49+i*8+math.sin(time*.4+i)*3,y=88-u*83,z=-46+i*.8,
    size=.24+(i%3)*.07,spin=u*2,alpha=math.sin(u*math.pi)*.48}
  end
 elseif h.key=='gym:steam'then
  for i,o in ipairs({{-41.4,17,-35},{41.4,17,-35},{0,11,86}})do
   for j=1,2 do local u=(time/4+j*.5+i*.21)%1
    out[#out+1]={kind='steam',x=o[1]+math.sin(u*3+i)*2,y=o[2]+u*15,z=o[3],
     size=1.4+u*2.4,spin=math.sin(u*4)*.10,alpha=math.sin(u*math.pi)*.24}
   end
  end
 elseif h.family=='city'and scene.ambientOrigin then
  local o=scene.ambientOrigin
  for i=1,2 do local u=(time/5+i*.5)%1
   out[#out+1]={kind='smoke',x=o[1]+math.sin(u*2.2)*3,y=o[2]+u*14,z=o[3],
    size=1.5+u*2.5,spin=u*.3,alpha=math.sin(u*math.pi)*.19}
  end
 elseif h.key=='cave:'then
  -- Dust sheds from the visible foreground ledge, outside the actor disk.
  -- The old generic position was behind the illustrated cave wall.
  for i=1,7 do local u=(time/5+i*.139)%1
   out[#out+1]={kind='dust',x=-54+i*2+math.sin(time*.4+i),y=14-u*15,z=64+i*1.2,
    size=.65,spin=u*2,alpha=math.sin(u*math.pi)*.56}
  end
 elseif h.family=='cave'then
  for i=1,5 do local u=(time/4+i*.193)%1
   out[#out+1]={kind='dust',x=-43+i*3+math.sin(time*.7+i),y=33-u*29,z=-29,
    size=.25+i*.025,spin=0,alpha=math.sin(u*math.pi)*.42}
  end
 end
 return out
end
function A.pulse(scene)
 local p=plan(scene);local a=scene.ambient
 if not p or not a or not a.active then return 0 end
 if p.kind=='haunt'or p.kind=='skyWind'then return math.sin(a.age/p.duration*math.pi)^2 end
 if p.kind=='bell'or p.kind=='treeChime'or p.kind=='cargoDust'or p.kind=='receipt'then return math.sin(a.age*5)*math.sin(a.age/p.duration*math.pi)^2 end
 if p.kind=='signals'then return math.sin(a.age/p.duration*math.pi)^2*.22 end
 if p.kind=='orbit'then return math.sin(a.age/p.duration*math.pi)^2*.45 end
 return 0
end
return A
