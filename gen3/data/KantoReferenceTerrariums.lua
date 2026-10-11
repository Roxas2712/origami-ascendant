-- Deliberate stage compositions based on the native FR/LG map references.
-- Each row names real local architecture/furniture rather than an elemental logo.
local R={};local s
local function scene(key,floor,environment,motion)
 s={floor=floor,environment=environment or 'room',motion=motion or 'paper',cards={}}
 R[key]=s;return s
end
local function a(kit,part,w,x,z,h,y,extra)
 s.cards[#s.cards+1]={kit=kit,part=part,width=w,x=x,z=z,height=h,y=y or -1.35,extra=extra}
end
local function pair(kit,part,w,x,z,h,extra)
 a(kit,part,w,-x,z,h,nil,extra);a(kit,part,w,x,z+.04,h,nil,extra)
end
local function flat(kit,part,w,x,z,length)
 a(kit,part,w,x,z,length*30,-1.1,{restPitch=-math.pi/2})
end
local function row(kit,part,count,width,z,h,spacing)
 for i=1,count do a(kit,part,width,(i-(count+1)/2)*(spacing or width*.95),z,h)end
end
local function wall(kit,part,h)
 if kit=='league' and (part==5 or part==6 or part==10) then
  a(kit,part,2.50,0,-2.61,h or 64)
  a(kit,part,1.55,-2,-2.54,h or 64,nil,{cropU={0,.27}})
  a(kit,part,1.55,2,-2.54,h or 64,nil,{cropU={.73,1}})
  return
 end
 for i,x in ipairs({-1.8,0,1.8})do a(kit,part,1.92,x,-2.61+(i%2)*.08,h or 64)end
end
local function trees()
 pair('nature',1,1.25,2.65,-1.73,69,{sway=true})
 pair('nature',1,.76,2.91,.40,34,{sway=true})
end
local function cliff(part)
 a('terrain',part,2.25,-1.64,-2.54,69);a('terrain',part,2.28,1.62,-2.35,62)
 pair('terrain',part,1.03,2.67,-1.12,39)
 pair('terrain',part,.80,2.70,1.70,15)
end
local function rocks(part)
 pair('terrain',part,.44,2.76,.82,12)
 a('terrain',part,.38,-1.5,2.72,9)
end
local function bench(kit,part)
 pair(kit,part,1.5,1.76,-1.74,30)
end

-- Towns: real low Kanto buildings, identifiable skyline and local terrain.
local townSpecs={
 pallet={1,{'corrections',1,3.05,0,-2.60,55},{'towns',1,1.42,-1.96,-1.34,47},{'towns',1,1.42,1.96,-1.46,47}},
 viridian={1,{'towns',8,2.55,.64,-2.59,69},{'towns',4,1.52,-1.84,-1.60,48},{'towns',6,1.28,2.02,-1.50,40}},
 pewter={2,{'landmarks',1,3.35,-.43,-2.55,65},{'towns',8,1.65,1.83,-1.70,53},{'towns',2,1.18,-2.22,-1.21,39}},
 cerulean={1,{'towns',8,2.50,-.75,-2.57,64},{'towns',3,1.44,1.95,-1.55,46},{'towns',5,1.41,-2.01,-1.31,43}},
 vermilion={7,{'towns',8,2.06,-1.29,-2.54,64},{'services',1,2.30,1.45,-2.26,57},{'towns',3,1.08,-2.46,-1.40,38}},
 lavender={1,{'corrections',2,1.87,1.05,-2.60,112},{'towns',2,1.77,-1.62,-1.91,53},{'towns',6,1.08,2.48,-1.20,36}},
 celadon={2,{'corrections',5,2.15,-1.17,-2.51,105},{'corrections',6,1.87,1.39,-2.31,91},{'towns',5,1.21,-2.44,-1.35,38}},
 saffron={2,{'corrections',7,2.12,0,-2.67,117},{'towns',2,1.51,-2.03,-1.89,51},{'towns',3,1.51,2.03,-1.74,51}},
 fuchsia={1,{'corrections',8,2.47,.68,-2.58,66},{'towns',8,1.79,-1.70,-1.89,56},{'towns',3,1.23,2.28,-1.31,41}},
 cinnabar={7,{'corrections',3,2.05,-1.16,-2.51,79},{'corrections',4,2.41,1.42,-2.24,61},{'towns',8,1.26,-2.36,-1.35,41}},
 one={7,{'corrections',9,2.95,0,-2.56,77},{'towns',2,1.32,-2.09,-1.76,43},{'towns',2,1.32,2.12,-1.53,43}},
 two={7,{'towns',2,2.23,-.70,-2.60,66},{'towns',3,1.60,1.96,-1.84,49},{'landmarks',8,1.44,-2.03,-1.33,39}},
 three={1,{'towns',2,1.54,-1.11,-2.61,59},{'towns',2,1.54,1.17,-2.40,59},{'towns',5,1.40,-2.31,-1.31,42}},
 four={7,{'landmarks',12,2.67,-.52,-2.58,71},{'towns',2,1.41,-2.06,-1.73,44},{'towns',5,1.39,2.19,-1.49,43}},
 five={7,{'towns',5,2.12,-.82,-2.55,67},{'towns',2,1.78,1.63,-2.10,51},{'towns',2,1.10,-2.36,-1.36,38}},
 six={7,{'towns',5,1.97,1.08,-2.46,62},{'towns',2,1.75,-1.32,-2.15,52},{'towns',6,1.24,2.28,-1.24,40}},
 seven={7,{'towns',5,2.13,-.77,-2.47,68},{'towns',2,1.55,1.77,-1.93,49},{'towns',6,.91,-2.08,-1.33,34}},
}
for name,t in pairs(townSpecs)do
 scene('town_'..name,t[1],'outdoor','leaf');s.topFloor=t[1]==7 and 1 or t[1]
 for i=2,#t do local p=t[i];a(p[1],p[2],p[3],p[4],p[5],p[6])end
 trees();pair('nature',10,.66,2.48,1.68,13)
 if t[1]==7 then
  pair('nature',5,.91,2.27,1.49,17);s.water=true
  pair('nature',4,1.43,2.32,-.64,25)
 else pair('nature',11,.92,2.28,1.84,17)end
 if name=='pewter'then rocks(7)
 elseif name=='cerulean'then flat('nature',7,1.11,-2.57,.03,1.14);flat('nature',7,.81,2.58,.76,.8)
 elseif name=='fuchsia'then pair('nature',11,1.02,2.40,-.77,27);flat('nature',7,.97,2.41,1.67,1.1)
 elseif name=='vermilion'then a('services',2,.68,1.58,-2.25,29,65);pair('services',3,1.15,2.43,-.57,22)
 elseif name=='one'then pair('nature',4,1.22,2.62,-1.12,41)
 elseif name=='four'then a('terrain',4,.90,2.48,-2.11,62)
 elseif name=='three'then a('towns',2,1.14,2.25,-.98,37)
 elseif name=='two'then a('services',11,.36,-.72,-1.73,19)
 end
end

-- Gyms retain their characteristic puzzles and floor plans in the perimeter.
scene('pewter_gym',3,'room','pebble');s.topFloor=8;wall('finishing',2,62)
for _,p in ipairs({{-1.97,-1.78},{-.97,-2.06},{.95,-2.03},{1.98,-1.78}})do a('terrain',6,.61,p[1],p[2],26)end
pair('terrain',6,.65,2.58,.78,22);rocks(6)
scene('cerulean_gym',7,'room','water');s.water=true;s.topFloor=11
wall('services',4,63);pair('gyms',2,2.06,1.36,-1.72,29);pair('gyms',2,.83,2.67,.87,18)
scene('vermilion_gym',11,'room','electric');wall('rooms',5,70)
for _,z in ipairs({-1.93,-1.23})do for _,x in ipairs({-1.81,-.61,.61,1.81})do a('gyms',3,.43,x,z,23)end end
a('gyms',4,2.2,0,-2.30,34);pair('gyms',3,.43,2.66,1.26,23)
scene('celadon_gym',1,'room','leaf');wall('gyms',5,81)
pair('nature',1,.99,2.09,-1.89,64,{sway=true});pair('gyms',6,1.01,2.53,.90,25);pair('gyms',6,1.00,.74,-1.63,26)
scene('fuchsia_gym',11,'room','paper');s.floorKit='finishing';s.floorPart=11;wall('finishing',2,63)
-- Koga's maze walls are invisible in the original room; no painted walls here.
scene('saffron_gym',5,'room','psychic');wall('corrections',11,61)
pair('corrections',11,1.68,1.56,-1.64,28)
for _,p in ipairs({{-2.45,1.81},{2.47,1.82},{-1.30,-1.62},{1.30,-1.62}})do flat('gyms',8,.69,p[1],p[2],.66)end
scene('cinnabar_gym',11,'room','scan');wall('gyms',10,67)
pair('gyms',9,1.10,1.84,-1.83,62);a('gyms',9,1.10,0,-2.44,62)
pair('gyms',10,1.25,2.17,.88,26)
scene('viridian_gym',6,'room','scan');wall('gyms',10,64)
pair('gyms',10,1.50,1.66,-1.83,29);pair('gyms',10,1.14,2.42,.87,23)
for _,x in ipairs({-2.49,2.49})do for _,z in ipairs({-.70,1.70})do flat('gyms',11,.48,x,z,.48)end end
scene('dojo',3,'room','paper');wall('finishing',2,67)
flat('gyms',12,1.40,-1.47,-1.36,.85);flat('gyms',12,1.40,1.47,-1.36,.85)
pair('finishing',8,.42,2.60,1.74,28)

-- League rooms share the native orange paneling, with each room's own pillars.
for _,t in ipairs({{'lorelei',6,1,'ice'},{'bruno',11,2,'pebble'},{'agatha',5,3,'ghost'},{'lance',6,4,'paper'}})do
 scene(t[1],t[2],'room',t[4]);wall('league',5,70)
 pair('league',t[3],.73,1.70,-1.85,t[3]==4 and 53 or 79)
 pair('league',t[3],.60,2.67,.93,t[3]==4 and 32 or 48)
 pair('league',t[3],.53,2.35,-.52,t[3]==4 and 39 or 59)
 pair('league',8,.30,2.60,1.78,17)
end
scene('champion',6,'room','spark');wall('league',6,83)
a('league',7,2.35,0,-1.64,31);pair('league',8,.43,2.15,-1.77,31);pair('league',8,.38,2.54,1.41,24)
scene('hall',6,'room','scan');wall('league',10,76)
a('league',9,1.47,0,-1.74,61);pair('league',8,.49,2.10,-1.65,47);pair('league',8,.38,2.51,1.41,29)

-- Offices, warehouses, memorial rooms and domestic spaces.
scene('rocket',4,'room','scan');wall('rooms',5,69);bench('rooms',2)
pair('rooms',3,.95,2.58,.77,37);for _,x in ipairs({-2.55,2.55})do flat('gyms',11,.56,x,1.77,.55)end
scene('warehouse',4,'room','scan');wall('rooms',5,69);bench('rooms',3)
pair('rooms',3,.97,2.57,.89,43);pair('rooms',2,.71,2.14,1.84,23)
scene('silph',4,'room','scan');wall('finishing',1,77);bench('rooms',1)
pair('gyms',10,1.14,2.54,.87,26);pair('rooms',2,.68,2.34,1.85,26)
flat('gyms',8,.70,-1.91,-.94,.67);flat('gyms',8,.70,1.91,-.94,.67)
scene('power',4,'room','electric');wall('rooms',5,84)
pair('rooms',4,1.60,1.36,-1.73,67);pair('rooms',4,.78,2.62,.84,33);pair('rooms',2,.74,2.23,1.86,26)
scene('tower',5,'room','ghost');wall('finishing',3,74)
for _,z in ipairs({-1.60,-2.18})do for _,x in ipairs({-1.75,-.59,.59,1.75})do a('rooms',8,.46,x,z,30)end end
pair('rooms',8,.41,2.59,1.59,23)
scene('mansion',11,'room','paper');wall('rooms',6,83)
pair('rooms',7,.59,1.64,-1.75,45);pair('rooms',6,.83,2.61,.66,35);rocks(7)
scene('lab',4,'room','scan');wall('finishing',1,72);bench('rooms',12)
pair('rooms',2,.65,2.53,1.16,34);a('rooms',12,1.25,0,-2.26,42)
scene('museum',4,'room','paper');wall('finishing',4,77)
a('services',10,2.18,-.75,-2.00,73);a('services',9,1.27,1.87,-1.71,40)
pair('services',9,.88,2.48,1.15,26)
scene('center',11,'room','scan');wall('finishing',1,70)
a('rooms',9,3.80,0,-1.76,38);a('rooms',10,1.33,-1.19,-2.18,59);a('rooms',12,.88,1.47,-2.07,42)
pair('rooms',2,.59,2.55,1.17,27)
scene('shop',11,'room','paper');s.floorKit='corrections';s.floorPart=12;wall('finishing',1,66);bench('rooms',11)
pair('rooms',3,.71,2.63,.91,39)
scene('game_corner',11,'room','scan');wall('finishing',1,70)
for _,x in ipairs({-2.09,-1.23,-.38,.49,1.35,2.17})do a('services',11,.55,x,-1.94,46)end
pair('services',11,.49,2.60,1.02,37)
scene('house',3,'room','paper');wall('finishing',4,71)
a('finishing',5,1.70,-1.52,-1.77,39);a('rooms',3,1.05,1.75,-1.79,45)
pair('finishing',7,.54,2.60,1.53,24)
scene('gate',11,'room','paper');wall('finishing',1,70)
a('services',12,1.15,0,-2.35,69);a('rooms',1,1.31,-1.89,-1.67,33);a('league',7,1.13,1.95,-1.64,29)
pair('gyms',10,.78,2.54,1.38,26)
scene('underground',4,'room','paper');wall('finishing',1,62)
pair('finishing',1,1.31,2.41,-1.18,49);pair('finishing',1,.81,2.87,.73,32);a('league',7,1.03,0,-1.63,30)
scene('link',1,'room','scan');wall('league',5,60);pair('services',12,1.09,1.67,-1.86,56);pair('rooms',1,.92,2.52,1.12,25)
scene('league_reception',11,'room','scan');wall('finishing',1,73)
a('rooms',9,2.42,-.98,-1.87,39);a('rooms',10,1.00,-1.21,-2.29,59);a('league',7,1.09,1.89,-1.62,31)
pair('league',8,.35,2.55,1.31,26)

-- Steamship and port: no sailboat, captain's castle or outside facade indoors.
scene('ship_deck',7,'outdoor','water');s.water=true;s.topFloor=3
a('services',1,3.57,0,-2.53,66);a('services',2,.83,.40,-2.51,39,59)
pair('services',3,1.45,2.21,-1.11,26);pair('services',3,.86,2.55,1.47,18)
scene('ship_cabin',3,'room','paper');wall('services',4,73)
pair('services',5,1.46,1.60,-1.55,37);pair('services',12,.57,2.59,.66,47)
scene('captain',3,'room','paper');wall('finishing',4,76)
a('services',6,2.66,0,-1.72,56);a('rooms',2,.77,2.25,-1.76,41);a('services',5,1.10,-2.19,-1.46,30)
scene('ship_kitchen',3,'room','mist');wall('rooms',5,67)
a('services',8,1.41,0,-2.24,67);bench('services',7);pair('services',7,.86,2.57,1.27,24)
scene('harbor',7,'outdoor','water');s.water=true;s.topFloor=3
a('landmarks',9,3.54,0,-2.57,75);pair('nature',5,1.38,2.13,-1.20,29);pair('nature',6,.85,2.61,1.38,21)
scene('ferry_terminal',7,'room','water');s.water=true;s.topFloor=4;wall('finishing',4,67)
pair('nature',6,1.45,1.70,-1.67,27);a('services',12,1.02,0,-2.22,65);pair('nature',6,.89,2.52,1.12,23)
scene('trainer_tower',4,'outdoor','paper')
a('corrections',10,4.77,0,-2.49,61);a('league',7,1.09,-1.71,-1.63,27);pair('nature',6,1.04,2.39,-1.18,27);pair('nature',6,.85,2.59,1.50,23)

-- Caves and special areas retain their original terrain families and objects.
for _,t in ipairs({{'moon',8,1,'pebble'},{'diglett',8,1,'pebble'},
 {'rock_tunnel',8,2,'pebble'},{'cerulean_cave',7,3,'water'},
 {'victory',9,1,'pebble'},{'seafoam',7,4,'water'},{'icefall',7,4,'water'},
 {'ember',8,1,'pebble'},{'ruby',12,1,'spark'},{'lost',9,1,'pebble'},
 {'altering',8,2,'pebble'},{'dotted',4,2,'drop'},{'sapphire',4,2,'spark'},
 {'tanoby',4,2,'paper'},{'tanoby_key',8,1,'pebble'},
 {'dunsparce',9,1,'pebble'}})do
 scene(t[1],t[2],t[1]=='ember'and'outdoor'or'cave',t[4]);cliff(t[3]);rocks(t[3]==1 and 6 or 7)
 if t[2]==7 then s.water=true;s.topFloor=t[3]==4 and 10 or 8 end
 if t[1]=='moon'then a('terrain',11,1.49,0,-1.82,43)
 elseif t[1]=='diglett'or t[1]=='dunsparce'then a('terrain',5,2.59,0,-2.42,57)
 elseif t[1]=='cerulean_cave'then pair('terrain',3,.91,1.64,-1.43,29)
 elseif t[1]=='icefall'then a('terrain',12,1.41,0,-1.70,63,nil,{flowing=true})
 elseif t[1]=='seafoam'then pair('terrain',7,.76,1.79,-1.45,28)
 elseif t[1]=='ruby'then a('terrain',9,.86,0,-1.83,36);a('terrain',10,.60,-1.58,-1.38,28)
 elseif t[1]=='sapphire'then a('terrain',8,.92,0,-1.86,39);a('terrain',10,.61,1.73,-1.47,29)
 elseif t[1]=='dotted'then a('terrain',10,1.24,0,-1.86,49)
 elseif t[1]=='tanoby'then
  wall('nature',9,55);for _,x in ipairs({-1.67,-.55,.55,1.67})do a('terrain',10,.36,x,-1.65,21)end
 elseif t[1]=='tanoby_key'or t[1]=='victory'then
  for _,x in ipairs({-1.71,-.57,.57,1.71})do a('terrain',6,.64,x,-1.68,29)end
 elseif t[1]=='ember'then a('terrain',1,2.05,0,-2.81,94)
 else a('terrain',5,1.85,0,-2.46,55)end
end
scene('canyon',1,'outdoor','pebble');cliff(1);pair('nature',3,.81,2.45,.83,24)
scene('memorial',7,'outdoor','leaf');s.water=true;s.topFloor=1
a('landmarks',10,1.24,0,-1.95,59);pair('nature',1,.92,2.10,-2.11,69,{sway=true});pair('nature',4,1.35,2.28,.79,27)
scene('ruin_valley',1,'outdoor','leaf');trees();pair('nature',4,1.69,1.76,-2.00,62)
a('terrain',5,1.30,0,-2.29,46);flat('nature',7,1.44,0,-1.34,.69);pair('nature',3,.85,2.42,1.54,21)
scene('tanoby_exterior',7,'outdoor','water');s.water=true;s.topFloor=8
for _,x in ipairs({-1.87,0,1.87})do a('landmarks',11,1.41,x,-2.35+math.abs(x)*.14,57)end
pair('nature',9,.85,2.52,1.20,25)
scene('berry',1,'outdoor','leaf');trees();row('nature',1,3,1.25,-2.52,93,1.63)
pair('nature',2,.99,2.36,.93,27);pair('nature',2,.74,1.47,-1.40,23);flat('nature',7,1.08,2.35,1.75,.94)
scene('pattern',1,'outdoor','leaf');trees();row('nature',1,4,1.13,-2.49,86,1.44)
for _,x in ipairs({-2.18,-1.01,1.01,2.18})do a('nature',3,.65,x,-1.65,31)end;pair('nature',3,.72,2.56,1.47,21)
scene('spa',7,'cave','mist');s.water=true;s.topFloor=8;cliff(1)
pair('terrain',12,1.05,1.45,-1.81,39,nil,{flowing=true});a('terrain',12,.77,0,-2.26,54,nil,{flowing=true})
scene('navel_exterior',7,'outdoor','water');s.water=true;s.topFloor=8
cliff(2);a('terrain',5,2.06,0,-2.04,68);pair('terrain',7,.71,2.47,1.24,22)
scene('navel_passage',4,'cave','pebble');cliff(2)
a('league',7,1.62,0,-1.73,34);pair('terrain',7,.61,2.37,.91,19)
scene('trainer_tower_exterior',7,'outdoor','leaf');s.water=true;s.topFloor=1;trees()
a('landmarks',7,2.40,0,-2.63,119);pair('nature',6,1.16,2.49,1.48,22)
scene('cycling_road',2,'outdoor','leaf');trees()
pair('services',3,1.64,1.59,-1.97,26);pair('services',3,.88,2.59,1.68,20)
for _,z in ipairs({-1.87,1.80})do flat('gyms',11,.65,0,z,.65)end
scene('rocky_route',8,'outdoor','pebble');cliff(1)
pair('nature',3,.89,2.28,.83,27);pair('nature',1,.83,2.40,-1.74,48)
scene('pier_route',7,'outdoor','water');s.water=true;s.topFloor=3
pair('nature',5,1.68,1.33,-1.96,34);pair('nature',6,1.12,2.48,.94,22)
pair('nature',1,.71,2.28,-2.49,55)
scene('kindle_road',7,'outdoor','water');s.water=true;s.topFloor=8
a('terrain',1,2.53,1.35,-2.52,87);a('nature',4,2.20,-1.56,-2.15,57)
pair('terrain',6,.58,2.64,1.08,17);pair('nature',3,.75,2.08,1.87,18)
-- Small independent foreground cuts keep the stage layered at close zoom.
for key,recipe in pairs(R)do
 s=recipe
 if key:match('^town_') or key=='berry' or key=='pattern' or key=='ruin_valley' then
  pair('finishing',6,.74,1.71,2.57,15,{sway=true})
  pair('nature',3,.48,2.51,1.93,16,{sway=true})
  pair('nature',10,.64,2.84,-.12,16)
  flat('finishing',12,1.40,0,2.70,.64)
 elseif s.environment=='cave' or key=='canyon' or key=='ember' then
  pair('terrain',7,.57,1.79,2.43,14)
  pair('terrain',6,.31,2.88,.28,11)
 elseif key:match('_gym$') then
  pair('finishing',8,.41,1.66,2.44,26)
 elseif key=='center' or key=='shop' or key=='lab' or key=='museum' or key=='ferry_terminal' or key=='house' then
  pair('finishing',7,.49,1.79,2.40,25,{sway=true})
 end
end
return R
