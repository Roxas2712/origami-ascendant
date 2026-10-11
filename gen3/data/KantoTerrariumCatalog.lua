-- Kanto identities, composed from reusable paper materials and location props.
-- A shared material is never labelled as an individually illustrated map.
local C={}
local function add(key,label,base,kit,prop,motion,mode)
 C[key]={label=label,base=base,kit=kit,prop=prop,motion=motion,mode=mode or 'landmark'}
end
add('pewter_gym','Marmoria – Rocko','gym:rock',1,1,'pebble','gym')
add('cerulean_gym','Azuria – Misty','gym:water',1,2,'water','gym')
add('vermilion_gym','Orania – Major Bob','gym:electric',1,3,'electric','gym')
add('celadon_gym','Prismania – Erika','forest:ancient',1,4,'leaf','garden')
add('fuchsia_gym','Fuchsania – Koga','gym:fighting',1,5,'banner','gym')
add('saffron_gym','Saffronia – Sabrina','gym:psychic',1,6,'psychic','gym')
add('cinnabar_gym','Zinnober – Pyro','gym:steam',1,7,'ember','gym')
add('viridian_gym','Vertania – Giovanni','gym:rock',1,8,'pebble','gym')
add('dojo','Saffronia – Kampf-Dojo','gym:fighting',3,10,'banner','gym')
add('lorelei','Liga – Lorelei','league:ice',3,9,'ice','league')
add('bruno','Liga – Bruno','gym:rock',3,10,'banner','league')
add('agatha','Liga – Agatha','league:ghost',3,11,'ghost','league')
add('lance','Liga – Siegfried','league:dragon',3,12,'banner','league')
add('champion','Liga – Rivale','league:champion',nil,nil,'spark','league')
add('hall','Ruhmeshalle','league:hall',nil,nil,'spark')
add('rocket','Rocket-Versteck','industrial:devon',1,9,'electric','industrial')
add('warehouse','Rocket-Lager','industrial:devon',1,9,'electric','warehouse')
add('silph','Silph & Co.','industrial:devon',1,10,'scan','industrial')
add('power','Kraftwerk','industrial:electric',1,3,'electric','industrial')
add('tower','Pokémon-Turm','tower:memorial',1,11,'ghost','memorial')
add('mansion','Pokémon-Villa','interior:puzzle',1,12,'paper','ruined')
add('moon','Mondberg','cave:fossil',3,1,'spark')
add('diglett','Digda-Höhle','cave:rusturf',nil,nil,'pebble')
add('rock_tunnel','Felstunnel','cave',3,2,'pebble')
add('cerulean_cave','Azuria-Höhle','cave:altering',3,2,'psychic')
add('victory','Siegesstraße','cave:victory',nil,nil,'pebble')
add('seafoam','Seeschauminseln','ice',nil,nil,'ice')
add('icefall','Eisfallhöhle','ice',nil,nil,'water')
add('ember','Glutberg','volcano',3,6,'ember')
add('ruby','Rubinpfad','lava:ancient',3,6,'ember')
add('lost','Verlorene Höhle','cave:altering',1,11,'ghost')
add('altering','Wandelhöhle','cave:altering',nil,nil,'pebble')
add('dotted','Punktloch','ruins:braille',3,3,'drop')
add('sapphire','Saphir-Kammer','ruins:braille',3,3,'spark')
add('tanoby','Tanoby-Kammer','ruins:braille',3,4,'psychic')
add('tanoby_key','Tanoby-Schlüssel','cave:victory',3,4,'pebble')
add('canyon','Sevault-Schlucht','mountain',3,4,'pebble')
add('memorial','Gedenksäule','mountain:memorial',3,5,'leaf')
add('ruin_valley','Ruinental','forest:ancient',3,4,'leaf')
add('berry','Beerenforst','forest:ancient',nil,nil,'leaf')
add('pattern','Musterbuschwald','forest:island',nil,nil,'leaf')
add('dunsparce','Dummisel-Tunnel','cave:rusturf',nil,nil,'pebble')
add('trainer_tower','Trainerturm','facility:hill',3,10,'banner')
add('spa','Gluttherme','pond',6,8,'mist','spa')
add('ship_deck','M.S. Anne – Deck','ship:harbor',6,3,'banner','deck')
add('ship_cabin','M.S. Anne – Kabine','ship:liner',6,2,'banner','cabin')
add('ship_kitchen','M.S. Anne – Kombüse','ship:liner',6,1,'mist','galley')
add('captain','M.S. Anne – Kapitän','ship:liner',3,7,'wheel')
add('harbor','Kanto/Sevii – Hafen','ship:harbor',2,5,'banner')
add('lab','Labor','industrial:lab',1,10,'scan')
add('museum','Marmoria – Museum','interior:museum',3,1,'spark')
add('game_corner','Spielhalle','industrial:devon',6,4,'electric','casino')
add('house','Wohnhaus','interior:wood',nil,nil,'paper')
add('gate','Durchgangshaus','industrial:devon',6,7,'banner','gate')
add('underground','Unterführung','industrial:devon',6,7,'mist','tunnel')
add('center','Pokémon-Center','interior:center',nil,nil,'spark')
add('shop','Laden','interior:shop',nil,nil,'paper')
add('link','Verbindungskampf','facility:link',nil,nil,'electric')
local towns={
 {'pallet','Alabastia',1}, {'viridian','Vertania City',2}, {'pewter','Marmoria City',3},
 {'cerulean','Azuria City',4}, {'vermilion','Orania City',5}, {'lavender','Lavandia',6},
 {'celadon','Prismania City',7}, {'saffron','Saffronia City',8}, {'fuchsia','Fuchsania City',9},
 {'cinnabar','Zinnoberinsel',10}, {'indigo','Indigo-Plateau',3},
 {'one','Eiland Eins',11}, {'two','Eiland Zwei',12}, {'three','Eiland Drei',11},
 {'four','Eiland Vier',11}, {'five','Eiland Fünf',12}, {'six','Eiland Sechs',11}, {'seven','Eiland Sieben',12},
}
for i,t in ipairs(towns)do
 add('town_'..t[1],t[2],(i==5 or i==10 or i>11)and 'coast' or 'meadow',2,t[3],i==6 and 'ghost' or i==10 and 'ember' or 'leaf','town')
 -- Lua's and/or precedence deliberately kept out of art selection.
 C['town_'..t[1]].base=(i==5 or i==10 or i>11)and 'coast'or'meadow'
 C['town_'..t[1]].townVariant=i
end
-- A unique forecourt, not the museum facade previously reused from Marmoria.
C.town_indigo={label='Indigo-Plateau',base='meadow',motion='leaf',mode='indigo'}
add('tanoby_exterior','Tanoby-Ruinen – Außeninseln','coast',nil,nil,'water','reference')
add('ferry_terminal','Sevii – Fährterminal','interior:wood',nil,nil,'paper','reference')
add('league_reception','Indigo – Liga-Empfang','interior:center',nil,nil,'scan','reference')
add('navel_exterior','Nabelfels – Außeninsel','coast',nil,nil,'water','reference')
add('navel_passage','Nabelfels – Treppenwege','cave',nil,nil,'pebble','reference')
add('trainer_tower_exterior','Trainerturm – Außenbereich','meadow',nil,nil,'leaf','reference')
add('cycling_road','Kanto – Radweg','meadow',nil,nil,'leaf','reference')
add('rocky_route','Kanto – Felsrouten','mountain',nil,nil,'pebble','reference')
add('pier_route','Kanto – Stegrouten','coast',nil,nil,'water','reference')
add('kindle_road','Eiland Eins – Glühweg','coast',nil,nil,'water','reference')
return C
