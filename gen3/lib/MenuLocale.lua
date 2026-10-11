-- Follow the Universal mod's published boot language, never the OS locale or
-- an uncommitted language option. Without that active provider, use English.
local V=...
local L={}
function L.language()
 local mod=V.mod
 if type(mod.find)~='function'then return 'en'end
 local ok,h=pcall(mod.find,'translation-german-universal')
 if not ok or type(h)~='table'then ok,h=pcall(mod.find,mod,'translation-german-universal')end
 return ok and type(h)=='table'and type(h.exports)=='table'and h.exports.bootLanguage=='de'and 'de'or'en'
end
function L.text(en,de)return L.language()=='de'and de or en end
local settings={
 gen3FieldCamera={'FIELD CAMERA','NORMAL: standard view. 3RD/FIRST: experimental field cameras. Right-drag or [ / ] turns; touch arrows turn. Movement in both views is camera-relative. Look is limited to roofs/treetops. Battles keep their own camera.'},
 gen3LiveDisplay={'FPS HUD','Show or hide the HUD. Your individual display choices are retained.'},
 gen3LiveFps={'FPS / FRAME TIME','Actual frame rate and average time per frame.'},
 gen3LiveClock={'CLOCK','Local device time, independent of the in-game day.'},
 gen3LiveCpu={'CPU TIME','Process time per frame; not CPU utilisation or GPU time.'},
 gen3LiveGpu={'GRAPHICS MEMORY','Texture and canvas memory in MiB; not GPU utilisation or total VRAM.'},
 gen3Quality={'QUALITY','CRISP: gentle daytime focus; HIGH at night and in caves (recommended). OFF: original view. LOW/MEDIUM/HIGH/ULTRA set effect quality. Individual changes produce a custom preset.'},
 gen3Supersampling={'SUPERSAMPLING','Only useful without Retina/4K. Render above screen resolution on ULTRA. Higher graphics cost; disabled by default.'},
 gen3BattleView={'BATTLE VIEW','MAP: fight on the current map. ORIGINAL: native battle view. TERRARIUM: paper stage. F6 / 5 switches views.'},
 gen3OrigamiSpawn={'ORIGAMI ENTRANCE','Trainers and Pokemon unfold when they appear. OFF uses the earlier fold-up animation.'},
 gen3TerrariumIntro={'BATTLE INTRO','NORMAL: 1.7 seconds, alongside battle text. FAST: 0.9 seconds. CINEMATIC: full entrance. Applies to the next battle.'},
 gen3TerrariumAutoZoom={'AUTOMATIC TERRARIUM ZOOM','Frame the battle once after the stage opens and Pokemon appear. Manual or saved zoom takes priority.'},
 gen3TerrariumZoom={'TERRARIUM ZOOM','Saved camera distance for terrarium battles. Mouse wheel or trackpad adjusts zoom during battle.'},
 gen3TerrariumIdleSound={'IDLE SOUND','A soft sound accompanies the idle wobble, using the sound-effect volume.'},
 gen3BattleTilt={'BATTLE ANGLE','Independent camera angle for map battles.'},
 gen3OvTilt={'CAMERA ANGLE','50 degrees is the reference camera angle.'},
 gen3OvTerrain={'TERRAIN HEIGHT','Height of terrain edges, cliffs and trees.'},
 gen3OvPost={'POST-PROCESSING','FULL: bloom, tilt-shift and vignette. BLOOM: glow only. OFF: no post-processing.'},
 gen3OvBloom={'BLOOM STRENGTH','Strength of the glow around bright areas.'},
 gen3OvTiltShift={'TILT-SHIFT','Miniature-style depth blur near the top and bottom of the image.'},
 gen3OvShadows={'SHADOWS','Strength of cast shadows.'},
 gen3OvClouds={'CLOUD SHADOWS','Moving cloud shadows during the day.'},
 gen3OvAtmosphere={'ATMOSPHERE','Forest light shafts and haze, and fog in Pokemon Tower.'},
 gen3OvTexture={'WIND ANIMATION','Wind movement in grass and trees.'},
 gen3PlayerSilhouette={'PLAYER SILHOUETTE','Show a subtle silhouette where buildings or trees hide the player.'},
 gen3Lights={'WINDOWS AND LAMPS','Window light, indoor lamps and stained-glass badge light in gyms.'},
 gen3Scenery={'WATER AND FIREFLIES','Water sparkles and fireflies.'},
 gen3Vignette={'VIGNETTE','Subtle darkening around the image edges.'},
 gen3Dof={'DEPTH OF FIELD','Optional background blur. Keeps the focus area sharp.'},
 gen3Daytime={'TIME OF DAY','DAY CYCLE follows saved playtime. At 1x, a day lasts 20 minutes of play. Other choices fix the time.'},
 gen3ClockSpeed={'DAY CYCLE SPEED','Change the speed of the day cycle without jumping to another time.'},
 weather={'WEATHER','AUTO follows regional weather. GAME follows native weather scripts. Other choices override outdoor weather.'},
 rainStrength={'RAIN STRENGTH','Set the density of rain, or let the weather choose it automatically.'},
 gen3FoliageSeason={'SEASONAL FOLIAGE','AUTO follows the weather cycle. Choose spring, summer, autumn or original foliage colours.'},
 gen3CloudLight={'CLOUD LIGHT','Moving sunlight patches and cloud cover. ORIGINAL restores the earlier daylight.'},
 gen3WindowLife={'WINDOW VARIATION','Warm lamp colours and gradual window dimming by game hour. ORIGINAL restores the earlier light.'},
 gen3Fireflies={'FIREFLIES','Choose where fireflies can appear, or disable them.'},
 gen3Voxel={'ORIGAMI WORLD','OFF shows the original flat map.'},
 gen3Perspective={'PERSPECTIVE','ON: perspective camera. OFF: orthographic projection.'},
 gen3Upright={'UPRIGHT OBJECTS / 3D','Upright trees, buildings, props and terrain. Does not change collision.'},
 gen3Neighbors={'CONNECTED MAPS','Display neighbouring maps across their native connections.'},
 gen3Finish={'PAPER FINISH','Enable the final paper-world image treatment.'},
 gen3Bloom={'BLOOM','Soft glow around bright surfaces.'},
 gen3Shadows={'CAST SHADOWS','Shadows cast by the world and its objects.'},
 gen3GeometryAA={'GEOMETRY ANTIALIASING','Smooth geometry edges while preserving sharp pixel sprites.'},
 gen3GodRays={'SUN SHAFTS','Light shafts through gaps in scenery.'},
 gen3Card_renderSeams={'EXTRA EFFECTS','Master switch for the additional visual effects and their resources.'},
 gen3Card_grassDisplacement={'GRASS MOVEMENT','Grass bends as characters walk through it, then springs back.'},
 gen3Card_paperCut={'PAPER EDGES','Fine cut-paper edges and short, sharp contact shadows.'},
 gen3Card_paperSurface={'PAPER TEXTURE','Fine paper fibres and lit creases in low sunlight.'},
 gen3Card_particles={'AMBIENT PARTICLES','Pollen, falling leaves, dust, embers and chimney steam. Up to 300 particles.'},
 gen3Card_waterTouch={'WATER RIPPLES','Surfing ripples, rain rings and animated shore foam.'},
 gen3Card_skyLife={'BIRDS AND SKY','Occasional birds. Shooting stars appear on clear nights in visible rooftop skies.'},
 gen3Card_lampIgnition={'LAMP IGNITION','Windows light up gradually at dusk with a smooth fade, independent of camera distance.'},
 gen3Card_foldTransitions={'FOLD TRANSITIONS','The old map folds away and the new map unfolds. Battle transitions are unchanged.'},
 gen3Card_cameraDrama={'CAMERA MOVEMENT','Smooth following, dialogue zoom and a brief city entrance.'},
 gen3Card_colorScript={'REGIONAL COLOURS','Subtle regional colours with smooth transitions and the existing evening light.'},
 gen3Card_horizon={'DISTANT SCENERY','Layered paper scenery beyond the outer map edge.'},
 gen3Card_stormDrama={'STORM EFFECTS','Directional lightning, drifting fog banks and occasional subtle lens drops.'},
 gen3Card_geometryFxaa={'GEOMETRY ANTIALIASING','Smooth angled building edges. Sprites stay sharp. Automatically bypassed at 1.5x rendering or above.'},
 gen3Card_atlasMipmaps={'DISTANT GROUND FILTER','Steadier distant ground tiles below a 45-degree camera angle. Nearby pixels and sprites stay sharp.'},
 gen3Card_paperUi={'PAPER MENUS (UNAVAILABLE)','This engine has no supported window-drawing hook. Native menus remain in use.'},
 gen3Card_photoMode={'PHOTO MODE','F8 or SELECT+L: pause, adjust camera and lighting, and save a PNG. Restores settings on exit.'},
}
L.settings=settings
function L.setting(key,label,help)
 local row=settings[key]
 if L.language()=='en'and row then return row[1],row[2]end
 return label,help
end
local pairsList={
 {'CRISP (EMPFOHLEN)','CRISP (RECOMMENDED)'},{'GROSS','FULL'},{'KLEIN','COMPACT'},
 {'AN','ON'},{'AUS','OFF'},{'NIEDRIG','LOW'},{'MITTEL','MEDIUM'},{'HOCH','HIGH'},
 {'KARTE','MAP'},{'VOLL','FULL'},{'FLACH','FLAT'},{'SPIEL','GAME'},{'KLAR','CLEAR'},
 {'REGEN','RAIN'},{'SCHNEE','SNOW'},{'NEBEL','FOG'},{'STURM','STORM'},{'HITZE','HEAT'},
 {'ASCHE','ASH'},{'SANDSTURM','SANDSTORM'},{'LEICHT','LIGHT'},{'STARK','STRONG'},
 {'TAG','DAY'},{'NACHT','NIGHT'},{'FESTER TAG','FIXED DAY'},{'FESTE NACHT','FIXED NIGHT'},
 {'ABENDSONNE','GOLDEN HOUR'},{'MORGEN','DAWN'},{'DAEMMERUNG','DUSK'},
 {'DEZENT','SUBTLE'},{'TAGESLAUF','DAY CYCLE'},{'FRUEHLING','SPRING'},{'SOMMER','SUMMER'},
 {'HERBST','AUTUMN'},{'BELEBT','LIVING'},{'BEDECKT','OVERCAST'},{'AUFLOCKERND','BREAKS'},
 {'LAMPENVARIANZ','VARIED'},{'LEBENDIG','LIVING'},{'SCHNELL','FAST'},{'FILMISCH','CINEMATIC'},
 {'3. PERSON (TEST)','3RD PERSON (TEST)'},{'ICH-PERSPEKTIVE (TEST)','FIRST PERSON (TEST)'},{'UEBERALL','EVERYWHERE'},{'DRAUSSEN','OUTDOORS'},
}
function L.choice(value)
 if L.language()=='de'then return value end
 for _,p in ipairs(pairsList)do if value==p[1]then return p[2]end end
 return value:gsub(' GRAD',' DEG'):gsub(' EIGEN$',' CUSTOM')
end
local phrases={
 ['FPS + HUD']='HUD AND PERFORMANCE', ['KAEMPFE']='BATTLES', ['QUALITAET']='QUALITY',
 ['GRAFIK']='GRAPHICS', ['LICHT + WELT']='LIGHT AND WORLD', ['ZEIT + WETTER']='TIME AND WEATHER', ['ERWEITERT']='ADVANCED',
 ['RENDER-CARDS']='VISUAL EFFECTS', ['FEHLER / LOGS SENDEN']='ERRORS / SEND LOGS',
 ['ALLE EINSTELLUNGEN']='ALL SETTINGS', ['KAMERA ZURUECKSETZEN']='RESET CAMERA',
 ['Fehlerbericht, Geraetediagnose und manueller Versand an den Entwickler.']='Error reports, device diagnostics and manual sending to the developer.',
 ['Einzeln abschaltbare Erweiterungen mit vollstaendigem Rueckbau.']='Enable or disable individual visual effects.',
 ['Stellt den Mausrad-Zoom auf den Standard zurueck.']='Restore the default camera zoom.',
 ['Origami Ascendant und Engine-Urheber.']='Origami Ascendant and engine credits.',
 ['Eigenstaendige Mod fuer Feuerrot.']='Standalone FireRed mod.',
 ['Live-Anzeige: echte Bildrate, Framezeit und optionale Messwerte.']='Actual frame rate, frame time and optional diagnostics.',
 ['Ein Preset setzt alle Effekte. Einzelwerte lassen sich danach anpassen. AUS nutzt den originalen FireRed-Renderer.']='Presets set effect quality. Adjust individual values afterwards. OFF uses the original FireRed renderer.',
 ['Dieselben Regler wie im F7-Menue (Controller: R halten + SELECT). Wirkt sofort und wird gespeichert.']='The same controls as F7 (controller: hold R + SELECT). Changes apply immediately and are saved.',
 ['Lichter, Wasser, Gluehwuermchen und Randeffekte.']='Lighting, water, fireflies and screen-edge effects.',
 ['TAGESLAUF folgt der gespeicherten Spielzeit. Tempo 1x: ein Tag in 20 Spielminuten. Hoehlen und Raeume bleiben konstant.']='DAY CYCLE follows saved playtime. At 1x, a day lasts 20 minutes. Caves and interiors keep their lighting.',
 ['Grundschalter der Darstellung. Normalerweise nicht noetig.']='Core rendering switches. Usually no adjustment is needed.',
 ['Karte ist Standard. Original und Terrarium als alternative Kampfansichten.']='Map is the default. Original and Terrarium are alternative battle views.',
 ['Karte ist Standard. Original als alternative Kampfansicht; Terrarien noch nicht verfuegbar.']='Map is the default. Original is an alternative; terrariums are unavailable.',
}
function L.phrase(text)
 if L.language()=='de'then return text=='RENDER-CARDS'and 'VISUELLE EFFEKTE'or text end
 return phrases[text]or text
end
-- Localise the native mod-options schema as well as OASC's own panels.
-- Copy entries and choices: preset definitions and setting values stay untouched.
function L.schema(schema)
 for i,entry in ipairs(schema)do
  local row={};for key,val in pairs(entry)do row[key]=val end
  row.label,row.description=L.setting(row.key,row.label,row.description)
  if row.help then local _,help=L.setting(row.key,nil,row.help);row.help=help end
  if row.choices then
   row.choices={}
   for j,choice in ipairs(entry.choices)do
    local copy={};for key,val in pairs(choice)do copy[key]=val end
    copy[1]=L.choice(copy[1]);row.choices[j]=copy
   end
  end
  schema[i]=row
 end
 return schema
end
return L
