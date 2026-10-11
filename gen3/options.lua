local V=...
local options={
  {key='gen3TerrariumAutoZoom',type='toggle',label='TERRARIUM AUTO ZOOM',default=true,description='Frame the spawned Pokemon once after the stage opens. Manual zoom keeps your chosen view.'},
  {key='gen3PerformanceLog',type='toggle',label='PERFORMANCE LOG',default=false,description='Write local diagnostic timing logs for bug reports. No save data is included.'},
  {key='gen3StatementOnStartup',type='toggle',label='Community statement at startup',default=true,
   description='Show the personal community statement before the Ascendant intro. Reopen it through Community statement in OASC settings.'},
  {key='gen3OvTilt',type='choice',label='FIELD ANGLE',default=50,
   choices={{'24 DEG',24},{'36 DEG',36},{'50 DEG',50}},
   description='Field camera: flat 24, balanced 36 or standard 50 degrees. Battles keep their own saved angle.'},
  {key='gen3BattleTilt',type='choice',label='BATTLE ANGLE',default=24,
   choices={{'24 DEG',24},{'36 DEG',36},{'50 DEG',50}},
   description='Independent camera angle for map battles. The field camera keeps its own saved angle.'},
  {key='gen3Supersampling',type='toggle',label='SUPERSAMPLING',default=false,
   description='Optionales Rendern ueber Bildschirmaufloesung bei ULTRA; nur ohne Retina/4K sinnvoll. Kostet deutlich mehr Grafikleistung. Standard AUS; Licht, Wetter und native Texturen bleiben erhalten.'},
  {key='gen3FoliageSeason',type='choice',label='JAHRESZEITEN',default='auto',
   choices={{'AUTO','auto'},{'FRUEHLING','spring'},{'SOMMER','summer'},{'HERBST','autumn'},{'ORIGINAL','original'}},
   description='AUTO folgt dem Wetterzyklus: einzelne rosa Fruehlingsbaeume und warme Herbstfarben. Schnee legt sich auch auf Baeume und Gras. ORIGINAL deaktiviert diese Pflanzenfarben.'},
  {key='gen3PlayerSilhouette',type='toggle',label='SPIELER-SILHOUETTE',default=true,
   description='Dezente dunkle Silhouette nur fuer verdeckte Teile der Spielfigur hinter Haeusern und Baeumen.'},
  {key='gen3CloudLight',type='choice',label='WOLKENLICHT',default='living',
   choices={{'ORIGINAL','original'},{'BELEBT','living'},{'BEDECKT','overcast'},{'AUFLOCKERND','breaks'}},
   description='Feuerrot: warme Sonnenflecken, diffuse Wolkendecke und weiche Schatten. ORIGINAL stellt das bisherige Tageslicht wieder her.'},
  {key='gen3WindowLife',type='choice',label='FENSTERLEBEN',default='living',
   choices={{'ORIGINAL','original'},{'LAMPENVARIANZ','varied'},{'LEBENDIG','living'}},
   description='Feuerrot: warme Lampentoene pro Haus, sanftes Dimmen einzelner Fenster nach Spielstunde. ORIGINAL stellt das bisherige Licht wieder her.'},
  {key='gen3TerrariumIntro',type='choice',label='KAMPFINTRO',default='balanced',choices={{'NORMAL','balanced'},{'SCHNELL','fast'},{'FILMISCH','cinematic'}},
   description='Normal: 1,7 Sekunden Entfalten mit parallelem Kampftext. Schnell: 0,9 Sekunden. Filmisch: voller Aufbau.'},
  {key='gen3TerrariumZoom',type='choice',label='TERRARIUM-ZOOM',default=1,
   choices={{'75%',.75},{'100%',1},{'125%',1.25},{'150%',1.5},{'175%',1.75},{'200%',2},{'250%',2.5}},
   description='Emerald: gespeicherte Kameranaehe. Mausrad / Trackpad zoomt im Kampf frei von 65 bis 250 Prozent.'},
  {key='gen3TerrariumIdleSound',type='toggle',label='WACKELKLANG',default=true,
   description='Emerald: VASC-Bong passend zum Wackeln nach neun Sekunden Ruhe.'},
  {key='gen3OrigamiSpawn',type='toggle',label='ORIGAMI-AUFTRITT',default=true,
   description='Trainer und Pokemon entfalten sich beim Erscheinen aus gefaltetem Papier. AUS nutzt das bisherige Aufklappen.'},
  {key='gen3BattleView',type='choice',label='KAMPFANSICHT',default=V.require('battle/BattleViews').preference(),
   choices=V.require('battle/BattleViews').choices(),description='Karte ist Standard. F6 / 5 wechselt die laufende Kampfansicht.'},
  {key="gen3Voxel", type="toggle", label="PAPER WORLD", default=true,
   description="HD-2D perspective with upright native-art billboards. Settings change live; F3 opens quick settings, V cycles outdoor camera angles, F6 toggles native rendering; mouse wheel zooms."},
  {key="gen3Lights",type="toggle",label="DYNAMIC LIGHTS",default=true,
   description="Windows, room lamps, cave shafts and fireflies illuminate the ground, scenery and characters."},
  {key="gen3Fireflies",type="choice",label="FIREFLIES",default="all",choices={{"EVERYWHERE","all"},{"OUTDOORS","outdoors"},{"OFF","off"}}},
  {key="rainStrength",type="choice",label="RAIN STRENGTH",default="auto",choices={{"AUTO","auto"},{"LIGHT","light"},{"NORMAL","normal"},{"HEAVY","heavy"}}},
  {key="gen3Finish",type="toggle",label="PAPER FINISH",default=true,description="Top-edge depth of field, restrained bloom, vignette and warm grading. Each effect also has a DioramaConfig flag."},
  {key="gen3Neighbors",type="toggle",label="CONNECTED MAPS",default=true,
   description="Render adjacent FireRed maps across their native connections."},
  {key="gen3Daytime",type="choice",label="DAY / NIGHT",default="native",choices={{"ON","native"},{"FIXED DAY","day"},{"FIXED NIGHT","night"},{"DAWN","dawn"},{"GOLDEN","golden"},{"DUSK","dusk"}},
   description="GAME follows saved FireRed playtime: one Origami Ascendant day in 20 minutes. Loading or changing game speed keeps sun and moon lighting synchronized."},
  {key="weather",type="choice",label="WEATHER",default="auto",choices={{"AUTO","auto"},{"GAME","native"},{"CLEAR","clear"},{"RAIN","rain"},{"SNOW","snow"},{"FOG","fog"},{"STORM","storm"},{"HEAT","heat"},{"ASH","ash"},{"SAND","sand"}},
   description="AUTO follows game weather and Origami Ascendant regional fronts. GAME uses only native weather scripts. Outdoors only; music stays with FireRed."},
}

for _,entry in ipairs(V.require("DioramaConfig").settings.definitions)do options[#options+1]=entry end
for _,entry in ipairs(V.require('PerformanceOverlay').entries())do
 local setting=entry[1];local spec=setting:schema(entry[2])
 spec.default=setting.values[setting.defaultIndex or 1];options[#options+1]=spec
end
local config=V.require('DioramaConfig')
local profile=V.mod.options:get('gen3Quality')or config.settings.defaultPreset
local preset=config.settings.presets[profile]or config.settings.presets[config.settings.defaultPreset]
local fields={gen3Dof='dof',gen3Bloom='bloom',gen3Vignette='vignette',gen3Shadows='shadows',gen3Scenery='scenery',gen3Upright='upright',gen3Perspective='perspective',gen3GodRays='godRays'}
for _,entry in ipairs(options)do local field=fields[entry.key]
 if field then local v=preset[field];entry.default=field=='bloom'and (v==true or v=='night')or v end
end
return options
