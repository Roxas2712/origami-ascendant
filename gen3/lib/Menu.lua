-- FireRed adapter for the existing VASC ORAS settings presentation. The
-- native Gen3 stack retains modal ownership; no Gen1 game stack is installed.
local V=...
local Stack=require("src.ui.game3.stack")
local Menu={serial=0,settings={},specs={}}
local L=V.require('MenuLocale')
local Style=V.require("VascMenuStyle")
-- ASCENDANT menu (VASC presentation), content matched to Origami Ascendant.
-- GRAFIK carries exactly the rows of the F7 panel, so both views share one
-- set of options and always show the same values.
local groups={
 {id='hud',label='FPS + HUD',help='Live-Anzeige: echte Bildrate, Framezeit und optionale Messwerte.',keys={'gen3LiveDisplay','gen3LiveFps','gen3LiveClock','gen3LiveCpu','gen3LiveGpu'}},
 {id='battle',label='KAEMPFE',help='Karte ist Standard. '..(V.require('battle/BattleViews').terrariumAvailable()and 'Original und Terrarium als alternative Kampfansichten.'or 'Original als alternative Kampfansicht; Terrarien noch nicht verfuegbar.'),keys={'gen3BattleView','gen3BattleTilt','gen3OrigamiSpawn','gen3TerrariumAutoZoom','gen3TerrariumZoom','gen3TerrariumIdleSound','gen3TerrariumIntro'}},
 {id='quality',label='QUALITAET',help='Ein Preset setzt alle Effekte. Einzelwerte lassen sich danach anpassen. AUS nutzt den originalen FireRed-Renderer.',keys={'gen3Quality','gen3Supersampling'}},
 {id='graphics',label='GRAFIK',help='Dieselben Regler wie im F7-Menue (Controller: R halten + SELECT). Wirkt sofort und wird gespeichert.',keys={'gen3OvTilt','gen3OvTerrain','gen3OvPost','gen3OvBloom','gen3OvTiltShift','gen3OvShadows','gen3OvClouds','gen3OvAtmosphere','gen3OvTexture'}},
 {id='light',label='LICHT + WELT',help='Lichter, Wasser, Gluehwuermchen und Randeffekte.',keys={'gen3PlayerSilhouette','gen3Lights','gen3CloudLight','gen3WindowLife','gen3Scenery','gen3Fireflies','gen3Vignette','gen3Dof'}},
 {id='weather',label='ZEIT + WETTER',help='TAGESLAUF folgt der gespeicherten Spielzeit. Tempo 1x: ein Tag in 20 Spielminuten. Hoehlen und Raeume bleiben konstant.',keys={'gen3Daytime','gen3ClockSpeed','weather','rainStrength','gen3FoliageSeason'}},
 {id='expert',label='ERWEITERT',help='Grundschalter der Darstellung. Normalerweise nicht noetig.',keys={'gen3Voxel','gen3Perspective','gen3Upright','gen3Neighbors'}},
}
-- Cards own optional menu sections and can remove them without importing their
-- definitions here. Quick sections append to an existing category on phones.
local extraSections={}
function Menu.registerSection(owner,section)extraSections[owner]=section end
function Menu.unregisterSection(owner)extraSections[owner]=nil end
local function sections()
 local result={};for _,g in ipairs(groups)do result[#result+1]=g end
 local owners={};for owner in pairs(extraSections)do owners[#owners+1]=owner end;table.sort(owners)
 for _,owner in ipairs(owners)do result[#result+1]=extraSections[owner]end
 return result
end
local function available(key)
 for _,section in pairs(extraSections)do if section.available then for _,k in ipairs(section.keys)do if k==key and not section.available()then return false end end end end
 local s=Menu.settings[key]
 return (not s or not s.available or s.available())and V.require('GraphicsOverlay').available(key)
end
local labels={gen3Quality='QUALITAET',gen3Perspective='PERSPEKTIVE',gen3Upright='AUFRECHTE OBJEKTE / 3D',gen3Dof='TIEFENSCHAERFE',gen3Bloom='BLOOM',gen3Vignette='VIGNETTE',gen3Shadows='SCHLAGSCHATTEN',gen3Scenery='WASSER + GLUEHWUERMCHEN',gen3ClockSpeed='ZEITTEMPO',gen3Finish='PAPIER-FINISH',gen3Voxel='ORIGAMI-WELT',gen3Lights='FENSTER- + LAMPENLICHT',gen3Neighbors='VERBUNDENE KARTEN',weather='WETTER',gen3Fireflies='GLUEHWUERMCHEN',rainStrength='REGENSTAERKE',gen3Daytime='TAGESZEIT',
 gen3BattleTilt='KAMPFWINKEL',gen3OvTilt='NEIGUNG',gen3OvTerrain='GELAENDE-HOEHE',gen3OvPost='NACHBEARBEITUNG',gen3OvBloom='BLOOM-STAERKE',gen3OvTiltShift='TILT-SHIFT',gen3OvShadows='SCHATTEN',gen3OvClouds='WOLKENSCHATTEN',gen3OvAtmosphere='ATMOSPHAERE',gen3OvTexture='DYNAMISCHE TEXTUREN'}
labels.gen3Supersampling='SUPERSAMPLING'
local helps={gen3Quality='AUS: Original. NIEDRIG: ohne Unschaerfe/Schatten. MITTEL: einfache Schatten. CRISP: sanfter Hintergrund am Tag, HOCH nachts und in Hoehlen (empfohlen). HOCH: weiche Schatten. ULTRA: volle Effektdichte. EIGEN: angepasst.',
 gen3Supersampling='Nur ohne Retina/4K sinnvoll. AN: ULTRA rendert groesser als die Bildschirmauflösung. Mehr Kantenglaettung, aber hoehere Grafiklast. AUS: Bildschirmaufloesung, alle gewaehlten Lichteffekte bleiben aktiv.',
 gen3Perspective='AN: Perspektive. AUS: orthografische Vergleichsansicht.',gen3Upright='Baeume, Haeuser, Props und Terrain aufrecht oder flach. Keine Aenderung der Kollision.',
 gen3Scenery='Schaltet Wasserfunkeln und Gluehwuermchen zusammen.',gen3ClockSpeed='Tempo des Tageslaufs; ein Tempowechsel springt nicht auf eine andere Tageszeit.',
 gen3Daytime='TAGESLAUF: laufende Spielzeituhr. Sonst feste Zeit: MORGEN, TAG, ABENDSONNE, DAEMMERUNG, NACHT.',
 gen3Lights='Fenster, Tueren, Lampen in Innenraeumen und Orden-Licht in Arenen.',gen3Dof='Optionale Hintergrundunschaerfe. Standard AUS; Vordergrund bleibt scharf.',
 gen3BattleTilt='Eigener Blickwinkel fuer Kartenkaempfe. Unabhaengig von der Aussenkamera.',gen3OvTilt='Kamerawinkel. 50 GRAD entspricht den HD-2D-Vorlagen.',gen3OvTerrain='Hoehe von Kanten, Klippen und Baeumen.',gen3OvPost='VOLL: Bloom, Tilt-Shift, Vignette. BLOOM: nur Leuchten. AUS: keine Nachbearbeitung.',
 gen3OvTiltShift='Miniatur-Unschaerfe am oberen und unteren Bildrand.',gen3OvClouds='Ziehende Wolkenschatten bei Tag.',
 gen3OvAtmosphere='Wald-Lichtstrahlen und Dunst, Nebel im Pokemon-Turm.',gen3OvTexture='Wind in Gras und Baeumen.',gen3Voxel='AUS zeigt die flache Originalkarte.'}
labels.gen3FoliageSeason='JAHRESZEITEN';labels.gen3CloudLight='WOLKENLICHT';labels.gen3WindowLife='FENSTERLEBEN'
helps.gen3OvBloom='Staerke des Leuchtens um helle Flaechen.'
helps.gen3OvShadows='Schatten unter Objekten und in der Spielwelt.'
helps.gen3Vignette='Dezente Abdunklung am Bildrand.'
helps.gen3Fireflies='Gluehwuermchen ueberall, nur draussen oder ausgeschaltet.'
helps.rainStrength='Regendichte automatisch oder als feste Staerke.'
helps.weather='AUTO folgt regionalem Wetter. SPIEL folgt nativen Wetterskripten. Andere Werte ueberschreiben das Wetter draussen.'
helps.gen3Neighbors='Zeigt angrenzende Karten ueber ihre nativen Verbindungen.'
local translated={ON="AN",OFF="AUS",FULL="VOLL",FLAT="FLACH",GAME="SPIEL",CLEAR="KLAR",RAIN="REGEN",SNOW="SCHNEE",FOG="NEBEL",STORM="STURM",HEAT="HITZE",ASH="ASCHE",SAND="SANDSTURM",LIGHT="LEICHT",NORMAL="NORMAL",HEAVY="STARK",DAY="TAG",NIGHT="NACHT",["FIXED DAY"]="FESTER TAG",["FIXED NIGHT"]="FESTE NACHT",LOW="NIEDRIG",MEDIUM="MITTEL",HIGH="HOCH",ULTRA="ULTRA",GOLDEN="ABENDSONNE",DAWN="MORGEN",DUSK="DAEMMERUNG",
 EVERYWHERE="UEBERALL",OUTDOORS="DRAUSSEN",STRONG="STARK",SUBTLE="DEZENT",TALL="HOCH",CYCLE="TAGESLAUF",MORNING="MORGEN",EVENING="ABENDSONNE",NATIVE="TAGESLAUF"}
labels.gen3LiveDisplay='FPS-HUD';labels.gen3LiveFps='FPS + FRAMEZEIT';labels.gen3LiveClock='UHR'
labels.gen3LiveCpu='CPU-ZEIT';labels.gen3LiveGpu='GRAFIKSPEICHER'
helps.gen3LiveDisplay='Kleine Live-Anzeige rechts oben. AUS beendet die Messung; deine Einzelauswahl bleibt gespeichert.'
helps.gen3LiveFps='Echte dargestellte Frames und mittlere Framezeit ueber eine halbe Sekunde. Unabhaengig vom Spieltempo.'
helps.gen3LiveClock='Lokale Uhrzeit des Computers, unabhaengig vom Tageslauf im Spiel.'
helps.gen3LiveCpu='CPU-Prozesszeit pro Frame, inklusive Threads. Keine CPU-Auslastung und keine GPU-Zeit.'
helps.gen3LiveGpu='Speicher fuer LOVE-Texturen und Render-Canvas in MiB. Keine GPU-Auslastung und kein Gesamt-VRAM.'
labels.gen3BattleView='KAMPFANSICHT'
labels.gen3OrigamiSpawn='ORIGAMI-AUFTRITT';helps.gen3OrigamiSpawn='AN: Papierfalten oeffnen sich beim Erscheinen von Trainern und Pokemon. AUS: bisheriges Aufklappen. Standard AN.'
labels.gen3TerrariumIntro='KAMPFINTRO';helps.gen3TerrariumIntro='NORMAL: 1,7 Sekunden zum Entfalten. SCHNELL: 0,9 Sekunden. Text laeuft parallel. FILMISCH: ausfuehrlicher Aufbau. Gilt ab dem naechsten Kampf.'
labels.gen3TerrariumAutoZoom='AUTOMATISCHER TERRARIUM-ZOOM'
helps.gen3TerrariumAutoZoom='Richtet den Kampf einmal nach Aufbau und Pokemon-Auftritt aus. Mausrad oder gespeicherter Zoom haben Vorrang.'
labels.gen3TerrariumZoom='TERRARIUM-ZOOM';labels.gen3TerrariumIdleSound='WACKELKLANG'
helps.gen3TerrariumZoom='Standardnaehe speichern. Im Kampf mit Mausrad / Trackpad bis 250% nah ans Geschehen zoomen.'
helps.gen3TerrariumIdleSound='Bong-bong im Takt der Ruheanimation. Nutzt die eingestellte Effektlautstaerke.'
helps.gen3BattleView='KARTE: Standard auf der aktuellen Map. ORIGINAL: native Darstellung. F6 / 5 wechselt jederzeit.'..(V.require('battle/BattleViews').terrariumAvailable()and ' TERRARIUM: Papierbuehne im Pokeball.'or ' Emerald: Terrarien noch nicht verfuegbar.')
local function battleFailure()
 local battle=V.mod.exports.gen3 and V.mod.exports.gen3.battle
 if not battle then return end
 local health=battle.health()
 if health.ok then return end
 local reason=tostring(health.reason or '')
 -- A failed renderer (including mobile GLSL compilation) is not evidence
 -- that the host lacks the battle presentation API.
 local engine=reason:find('OASC presentation: unsupported engine',1,true)
  or reason:find('OASC presentation: missing native',1,true)
  or reason:find('OASC battle presentation engine patch v2 required',1,true)
 local label=engine and L.text('ORIGINAL (INCOMPATIBLE ENGINE)','ORIGINAL (ENGINE INKOMPATIBEL)') or L.text('ORIGINAL (RENDERER UNAVAILABLE)','ORIGINAL (DARSTELLUNG NICHT VERFUEGBAR)')
 local help=reason~='' and (L.text('Battle presentation unavailable: ','Kampfdarstellung nicht verfuegbar: ')..reason)
  or L.text('Battle presentation is not active.','Kampfdarstellung derzeit nicht aktiv.')
 return label,help..L.text(' See ERRORS / SEND LOGS for details.',' Details unter FEHLER / LOGS SENDEN.')
end
local function battleHelp(key)
 if key=='gen3BattleView' then local _,help=battleFailure();if help then return help end end
 local _,help=L.setting(key,nil,helps[key] or (Menu.specs[key]or{}).help or (Menu.specs[key]or{}).description);return help
end
local function value(setting)
 local v=setting:get()
 if setting.key=="gen3BattleView" and v~="native" then
  local label=battleFailure();if label then return label end
 end
 for i,x in ipairs(setting.values)do if x==v then local l=setting.labels[i];if setting.key=='gen3Daytime' and l:upper()=='ON' then l='CYCLE' end;return L.choice(((translated[l:upper()] or l:upper()):gsub(' DEG',' GRAD'))..(setting.key=='gen3Quality'and V.require('EffectSettings').custom()and ' EIGEN'or '')) end end
 return tostring(v)
end
function Menu.install(schema,shared,onChanged)
 if not Menu.touchInstalled then
  Menu.touchInstalled=true
  local Game=require('src.core.Game3');local press,release=Game.touchpressed,Game.touchreleased
  local held={}
  Game.touchpressed=function(game,id,x,y,...)
   if V.require('EffectSettings').game==game and Menu.pointer(game,x,y)then held[id]=true;return end
   if press then return press(game,id,x,y,...)end
  end
  Game.touchreleased=function(game,id,...)
   if held[id]then held[id]=nil;return end
   if release then return release(game,id,...)end
  end
 end
 Menu.onChanged=onChanged
 for _,s in ipairs(schema)do
  Menu.specs[s.key]=s
  local values,names={},{}
  if s.type=="toggle" then values={true,false};names={"ON","OFF"}
  else for _,c in ipairs(s.choices or {})do names[#names+1]=c[1];values[#values+1]=c[2] end end
  if #values>0 then Menu.settings[s.key]=shared[s.key] or V.require("ModSetting").new(s.key,s.label,values,names,s.default) end
 end
 V.mod.events:on("mod.options_changed",function(payload)
  if type(payload)~="table" or payload.mod and payload.mod~=V.mod.id then return end
  local setting=Menu.settings[payload.key]
  if setting then setting:sync(payload.value) end
  if Menu.onChanged then Menu.onChanged(payload.key,payload.value,V.require("EffectSettings").game)end
 end)
 for _,r in ipairs(V.require('GraphicsOverlay').rows)do if r.s then Menu.settings[r.s.key]=r.s end end
 Menu.sideSetting=V.require('ModSetting').new('gen3MenuSide','MENUE',{false,true},{'GROSS','KLEIN'},false)
 Menu.settings.gen3StatementOnStartup=V.require('CommunityStatement').setting
 Menu.schema=schema
 Menu.ui=Style.new(V.mod,{edition=require('src.core.GameVersion').get(),skin="oras_fullscreen",language=L.language})
end
local function push(game,screen)
 Menu.serial=Menu.serial+1
 local id="origami_gen3_"..Menu.serial
 screen.__gen3Menu=true
 screen.battleSettings=require("src.core.game3.battle").isActive()
 local module={screen=screen,draw=function()end,handleInput=function(input)
  screen.game.input=input;screen:update(1/60)
 end}
 Stack.push(id,module)
 return screen
end
local function context(game)
 local proxy=setmetatable({},{__index=game})
 proxy.stack={push=function(_,s)return push(game,s)end,pop=function()Stack.pop()end,
  top=function()local t=Stack.top();return t and t.mod and t.mod.screen end}
 return proxy
end
function Menu.openScreen(game,screen)
 screen.game=context(game);return push(game,screen)
end
function Menu.change(screen,game,dir)
 local item=screen.items[screen.index]
 if item.disabled or not item.savedPreference and not available(item.key)then return end
 if item.setting then
  item.setting:cycle(game,dir)
  if Menu.onChanged then Menu.onChanged(item.key,item.setting:get(),game)end
  item.right=value(item.setting)
 elseif dir<0 then Stack.pop()
 elseif item.choose then item.choose()end
end
local function make(game,title,items)
 title=L.phrase(title)
 for _,item in ipairs(items)do
  item.label,item.help=L.setting(item.key,item.label,item.help)
  if item.disabled then item.right=L.text('UNAVAILABLE','NICHT VERFUEGBAR')end
  item.label=L.phrase(item.label);item.help=L.phrase(item.help)
  if item.key=='gen3BattleView'then item.help=battleHelp(item.key)end
 end
 local screen={game=context(game),title=title,items=items,index=1,scroll=0,rows=8,footer=L.text("A: SELECT   LEFT/RIGHT: VALUE   SELECT: COMPACT   B: BACK","A: WAHL   LINKS/RECHTS: WERT   SELECT: KLEIN   B: ZURUECK")}
 function screen:update(dt)
  local input=self.game.input
  if input:wasPressed("b") then Stack.pop();return end
  if input:wasPressed("select") and not self.quick then Menu.sideSetting:cycle(game,1) end
  if self.quickHome then
   local step=input:wasPressed('down')and 2 or input:wasPressed('up')and -2 or input:wasPressed('right')and 1 or input:wasPressed('left')and -1
   if step then self.index=(self.index-1+step)%#self.items+1
   elseif input:wasPressed('a')then Menu.change(self,game,1)end
  elseif input:wasPressed("down") then self.index=self.index%#self.items+1
  elseif input:wasPressed("up") then self.index=(self.index-2)%#self.items+1
  elseif input:wasPressed("a") or input:wasPressed("right") or input:wasPressed("left") then
   Menu.change(self,game,input:wasPressed("left") and -1 or 1)
  end
  for _,item in ipairs(self.items)do if item.setting then item.right=item.disabled and L.text('UNAVAILABLE','NICHT VERFUEGBAR')or value(item.setting);if item.key=='gen3BattleView'then item.help=battleHelp(item.key)end end end
  self.scroll=math.max(0,math.min(self.scroll,math.max(0,#self.items-self.rows)))
  if self.index<=self.scroll then self.scroll=self.index-1 end
  if self.index>self.scroll+self.rows then self.scroll=self.index-self.rows end
 end
 Menu.ui.decorateFocusHelp(screen,function(item)return item and item.help or "" end,8)
 return push(game,screen)
end
function Menu.open(game,section)
 require("src.ui.game3.start_menu").close()
 if section=='cards'then
  local items={}
  for _,s in ipairs(Menu.schema)do if s.key:match('^gen3Card_')then
   local setting=Menu.settings[s.key]
   items[#items+1]={label=s.label,right=value(setting),key=s.key,setting=setting,help=s.help,disabled=s.available==false}
  end end
  return make(game,'RENDER-CARDS',items)
 end
 if section then
  for _,group in ipairs(sections())do if group.id==section then
   local items={}
   for _,key in ipairs(group.keys)do
    local s=Menu.settings[key]
    if s and available(key)and (V.require('battle/BattleViews').terrariumAvailable()or(key~='gen3TerrariumZoom'and key~='gen3TerrariumIdleSound'and key~='gen3TerrariumAutoZoom'))then items[#items+1]={label=labels[key]or(Menu.specs[key]or{}).label or key,right=value(s),key=key,setting=s,help=battleHelp(key)} end
   end
   return make(game,group.label,items)
  end end
 end
 local items={}
 items[#items+1]={label='FEHLER / LOGS SENDEN',help='Fehlerbericht, Geraetediagnose und manueller Versand an den Entwickler.',choose=function()V.require('SupportDiagnostics').open(game)end}
 for _,g in ipairs(sections())do local group=g;items[#items+1]={label=g.label,help=g.help,choose=function()Menu.open(game,group.id)end} end
 items[#items+1]={label="RENDER-CARDS",help="Einzeln abschaltbare Erweiterungen mit vollstaendigem Rueckbau.",choose=function()Menu.open(game,"cards")end}
 items[#items+1]={label="KAMERA ZURUECKSETZEN",help="Stellt den Mausrad-Zoom auf den Standard zurueck.",choose=function()
  local C=V.require("Camera");if Menu.resetCamera then Menu.resetCamera(game)else C.zoom=C.defaultZoom end
 end}
 items[#items+1]={label="CREDITS",help="Origami Ascendant und Engine-Urheber.",choose=function()
  make(game,"CREDITS",{
   {label="Origami Ascendant",help="Eigenstaendige Mod fuer Feuerrot."},
   {label="Pokemon Gen 1 Recompilation Project",help="Based on the Pokemon Gen 1 Recompilation Project by BOIS CLUB GAMES, LLC (https://github.com/bryanthaboi/gen1recomp)"},
  })
 end}
 items[#items+1]={label='Community statement',help='Read the startup pages and choose whether to show them at startup.',choose=function()V.require('CommunityStatement').open(game)end}
 local statement=Menu.settings.gen3StatementOnStartup
 items[#items+1]={label='Community statement at startup',key='gen3StatementOnStartup',setting=statement,right=value(statement),savedPreference=true,help='Restore or hide the statement at startup.'}
 return make(game,"ORIGAMI ASCENDANT",items)
end
local function quickItems(keys,group)
 local items={}
 for _,key in ipairs(keys)do
  local setting=Menu.settings[key]
  -- Edition-specific settings may be absent from the installed schema.
  if setting and not(key=='gen3OvTilt'and V.require('GraphicsOverlay').indoorLocked())and (key=='gen3OvTilt'or key=='gen3BattleTilt'or available(key))and (V.require('battle/BattleViews').terrariumAvailable()or(key~='gen3TerrariumZoom'and key~='gen3TerrariumIdleSound'and key~='gen3TerrariumAutoZoom'))then
   local help=battleHelp(key)
   items[#items+1]={label=labels[key]or(Menu.specs[key]or{}).label or key,right=value(setting),key=key,setting=setting,help=help,group=group,savedPreference=key=='gen3OvTilt'or key=='gen3BattleTilt'}
  end
 end
 return items
end
local quickGroups={
 {id='camera',label={'Camera / quality','Kamera / Qualität'},help={'Angle, terrain, quality','Winkel, Gelände, Qualität'},keys={'gen3OvTilt','gen3Quality','gen3Supersampling','gen3OvTerrain'}},
 {id='battle',label={'Battles','Kämpfe'},help={'View, entrance, zoom','Ansicht, Auftritt, Zoom'},keys={'gen3BattleView','gen3BattleTilt','gen3OrigamiSpawn','gen3TerrariumAutoZoom','gen3TerrariumZoom','gen3TerrariumIdleSound','gen3TerrariumIntro'}},
 {id='light',label={'Light / effects','Licht / Effekte'},help={'Lamps, shadows, atmosphere','Licht, Schatten, Atmosphäre'},keys={'gen3Lights','gen3OvShadows','gen3OvPost','gen3OvTiltShift','gen3OvAtmosphere'}},
 {id='weather',label={'Time / weather','Zeit / Wetter'},help={'Time, weather, seasons','Uhrzeit, Wetter, Jahreszeit'},keys={'gen3Daytime','weather','rainStrength','gen3FoliageSeason'}},
 {id='hud',label={'FPS / diagnostics','FPS / Diagnose'},help={'FPS, clock, memory','FPS, Uhr, Speicher'},keys={'gen3LiveDisplay','gen3LiveFps','gen3LiveClock','gen3LiveCpu','gen3LiveGpu'}},
}
function Menu.openQuick(game,section)
 local items,title={},L.text('Categories','Kategorien')
 local support=L.text('Support / all settings','Support / alle Einstellungen')
 if section=='support'then
  title=support
  items[#items+1]={label=L.text('ERRORS / SEND LOGS','FEHLER / LOGS SENDEN'),group=title,help=L.text('Error report, device diagnostics and manual sending.','Fehlerbericht, Gerätediagnose und manueller Versand.'),choose=function()V.require('SupportDiagnostics').open(game)end}
  items[#items+1]={label=L.text('ALL SETTINGS','ALLE EINSTELLUNGEN'),group=title,choose=function()Menu.open(game)end}
  items[#items+1]={label='Community statement',group=title,help='Read the startup pages and choose whether to show them at startup.',choose=function()V.require('CommunityStatement').open(game)end}
 elseif section then
  for _,group in ipairs(quickGroups)do if group.id==section then title=L.text(unpack(group.label));local keys={};for _,key in ipairs(group.keys)do keys[#keys+1]=key end
   for _,extra in ipairs(sections())do if extra.quick==section then for _,key in ipairs(extra.keys)do keys[#keys+1]=key end end end
   items=quickItems(keys,title);break end end
 else
  for _,group in ipairs(quickGroups)do local id=group.id
   items[#items+1]={key='category_'..id,label=L.text(unpack(group.label)),help=L.text(unpack(group.help)),choose=function()Menu.openQuick(game,id)end}
  end
  items[#items+1]={key='category_support',label=L.text('Support / more','Support / mehr'),help=L.text('Logs and more settings','Logs und weitere Optionen'),choose=function()Menu.openQuick(game,'support')end}
 end
 assert(#items>0,'unknown quick-menu category: '..tostring(section))
 local screen=make(game,'ORIGAMI ASCENDANT',items);screen.quick=true;screen.quickHome=not section;screen.quickTitle=title
 if game.input and game.input.reset then game.input:reset()end
 return screen
end
function Menu.openBattle(game)
 return Menu.openQuick(game)
end
local heldShortcuts={}
function Menu.shortcut(game,event)
 local current=Menu.active()
 if current and current.quick then
  if event.key=='escape' then
   if event.phase=='pressed'then Stack.pop();game.input:reset()end;return true
  elseif event.key=='return' or event.key=='space' then
   if event.phase=='pressed'then Menu.change(current,game,1)end;return true
  elseif event.key=='pageup' or event.key=='pagedown' then
   if event.phase=='pressed'then
    local page=V.require('QuickMenuView').layout(current)
    current.index=(event.key=='pageup'and page.prevIndex or page.nextIndex)or current.index
   end
   return true
  end
 end
 if event.key=='v' then
  if event.phase=='released'then heldShortcuts.v=nil;return true end
  if heldShortcuts.v then return true end
  heldShortcuts.v=true
  if event.phase=='pressed'and not current and not Stack.busy()and game.phase=='field'
   and not require('src.core.game3.battle').isActive()
   and not require('src.core.game3.battle_transition').isActive()
   and not V.require('GraphicsOverlay').open
   and V.mod.options:get('gen3Voxel')~=false then
   local overlay=V.require('GraphicsOverlay');overlay.cycleFieldAngle(game)
   V.require('MenuHint').showAngle(game,overlay.effectiveAngle())
  end
  return true
 end
 if event.key~='f3' and event.key~='o' then return false end
 if event.phase=='released' then heldShortcuts[event.key]=nil;return true end
 if heldShortcuts[event.key]then return true end
 heldShortcuts[event.key]=true
 local screen=Menu.active()
 if event.phase=='pressed' then
  if screen then
   repeat Stack.pop()until not Menu.active()
   if game.input and game.input.reset then game.input:reset()end
  elseif not Stack.busy()and require('src.core.game3.battle').isActive()
    and not require('src.core.game3.battle_transition').isActive()then
   Menu.openBattle(game)
  elseif not Stack.busy() and game.phase=='field'
    and not require('src.core.game3.battle').isActive()
    and not require('src.core.game3.battle_transition').isActive() then
   V.require('GraphicsOverlay').open=false;Menu.openQuick(game)
  end
 end
 return true
end
function Menu.active()
 local t=Stack.top();return t and t.mod and t.mod.screen and t.mod.screen.__gen3Menu and t.mod.screen
end
-- Full-screen VASC menu by default; SELECT switches to a slim side panel
-- (right edge, no help card) so the diorama stays visible while tuning.
local function drawSide(screen)
 local F=V.require('MenuFont')
 local W,H=love.graphics.getDimensions()
 local scale=math.max(1,math.floor(math.min(W/440,H/300)+.5))
 local pw,rowH,visible=210,15,math.min(#screen.items,10)
 local theme=V.require("EditionAccent").ui();local accent=theme.accent
 local first=math.max(1,math.min(screen.index-visible+1,#screen.items-visible+1))
 local ph=21+visible*rowH+16
 love.graphics.push('all');love.graphics.origin();love.graphics.setShader();love.graphics.setDepthMode()
 love.graphics.translate(math.floor(W-pw*scale-10*scale),math.floor(H*.08))
 love.graphics.scale(scale)
 love.graphics.setColor(theme.glass);love.graphics.rectangle('fill',0,0,pw,ph)
 love.graphics.setColor(accent);love.graphics.setLineWidth(1/scale);love.graphics.rectangle('line',.5,.5,pw-1,ph-1)
 love.graphics.setColor(theme.soft);love.graphics.rectangle('fill',1,1,pw-2,15)
 love.graphics.setColor(1,1,1,1);F.draw(screen.title or '',6,4)
 if first+visible-1<#screen.items then love.graphics.setColor(theme.focus);F.draw('v',pw-10,4) end
 for i=first,math.min(#screen.items,first+visible-1)do
  local it=screen.items[i];local y=21+(i-first)*rowH
  if i==screen.index then love.graphics.setColor(theme.selected);love.graphics.rectangle('fill',2,y-4,pw-4,rowH);love.graphics.setColor(theme.focus)
  else love.graphics.setColor(theme.text) end
  F.draw(it.label or '',6,y)
  local v=it.right or ''
  if v~='' then
   if i==screen.index and it.setting then v='<'..v..'>' end
   local w=0;for _,sp in ipairs(F.split(v))do w=w+F.advanceOf(sp.code)end
   F.draw(v,pw-6-w,y)
  end
 end
 love.graphics.setColor(theme.muted);F.draw(screen.quick and L.text('F3: CLOSE   <>: VALUE   B: BACK','F3: ZU   <>: WERT   B: ZURUECK') or L.text('SELECT: FULL   B: BACK','SELECT: GROSS   B: ZURUECK'),6,ph-12)
 love.graphics.pop()
end
function Menu.pointer(game,x,y)
 local screen=Menu.active()
 if not screen then return V.require('MenuHint').pointer(game,x,y)end
 if screen and screen.__oascErrors then return screen:pointer{phase='pressed',x=x,y=y}end
 if not(screen and screen.quick)then return false end
 local view=V.require('QuickMenuView');local t=view.layout(screen)
 local function hit(r)return x>=r[1]and x<r[1]+r[3]and y>=r[2]and y<r[2]+r[4]end
 if hit(t.close)then repeat Stack.pop()until not Menu.active();game.input:reset()
 elseif t.back and hit(t.back)then Stack.pop();game.input:reset()
 elseif t.prev and hit(t.prev)then screen.index=t.prevIndex
 elseif t.next and hit(t.next)then screen.index=t.nextIndex
 else for _,entry in ipairs(t.rows)do if hit(entry.rect)then screen.index=entry.index;Menu.change(screen,game,1);break end end end
 return true
end
function Menu.draw()
 local screen=Menu.active()
 if not screen then return V.require('MenuHint').draw(V.require('EffectSettings').game)end
 if screen.__oascErrors then return screen:drawPhysical()end
 if screen.quick then return V.require('QuickMenuView').draw(screen)end
 if Menu.sideSetting and Menu.sideSetting:get()==true then return drawSide(screen) end
 screen:drawWidescreen(love.graphics.getDimensions())
end
return Menu
