-- Gen3 renderer with separately reviewed FireRed and Emerald surface roles.
local mod=...
local V={mod=mod,path=mod.path,loaded={}}
-- Injectable monotonic clock; native time in play, fixed time in render tests.
V.clock=function()return love.timer.getTime()end
local function load(rel,...)
  local source=assert(mod:read("gen3/"..rel),"Missing Gen3 module: "..rel)
  return assert((loadstring or _G.load)(source,"@OrigamiAscendant/gen3/"..rel))(...)
end
function V.require(name)
  if not V.loaded[name] then V.loaded[name]=load("lib/"..name..".lua",V) end
  return V.loaded[name]
end
function V.data(name)
  local key="data/"..name
  if not V.loaded[key] then V.loaded[key]=load(key..".lua") end
  return V.loaded[key]
end
V.require('SupportDiagnostics').install()
local TransitionTrace=V.require('TransitionTrace');TransitionTrace.install()
local optionSchema=load("options.lua",V)
local CardIndex=V.require('cards/index')
CardIndex.options(optionSchema)
V.require('MenuLocale').schema(optionSchema)
mod.options:define(optionSchema)
local Effects=V.require("EffectSettings")
Effects.apply()
local NativeIdentity=V.require("NativeTilesetIdentity")
NativeIdentity.install()
if V.data('Emerald').active() then V.require('EmeraldPlaces').install() end
V.require('EmeraldDecorationRestore').install()
local Renderer=V.require("Renderer")
Renderer.cooperative=true
local Camera=V.require("Camera")
local FieldView=require("src.core.game3.field_view")
local Tilt=require("src.render.Tilt")
local Battle=require("src.core.game3.battle")
local Transition=require("src.core.game3.battle_transition")
local Stack=require("src.ui.game3.stack")
local EngineRenderer=require("src.render.Renderer")
local exports=mod.exports
exports.active=true
exports.generation=3
exports.runtime="gen3"
exports.version=mod._origamiPackageVersion
exports.rendererInstalled=true
exports.lib=V
local forcedMode
local broken=false
local function mode()
  if forcedMode then return forcedMode end
  if mod.options:get("gen3Voxel")==false then return "off" end
  return "paper" -- Ignore legacy saved camera selections.
end
local function owns(game)
  return game and game.mods and game.mods.exports
    and game.mods.exports[mod.id]==exports
end
V.require('GameSharkGate').install(mod,owns)
local function eligible(game)
  if V.data('Emerald').active() then
    local map=require('src.core.game3.map').current
    if not V.data('Emerald').isSupported(map,require('src.core.game3.map').currentDef())then return false end
  end
  return owns(game) and not broken and mode()~="off" and game and game.phase=="field"
    and not Battle.isActive()
end
local previous=FieldView.draw
-- There is no active render_pipelines registry in Gen3 yet. Own exactly the
-- field pass; the engine still draws its HUD, menus, fades and battle scenes.
local function drawDestination(game,w,h,pw,ph)
  TransitionTrace.step('before mobile scene retirement')
  V.require('MobileRenderBudget').enter(Renderer,require('src.core.game3.map').current)
  TransitionTrace.step('before OASC destination draw')
  return Renderer.draw(game,w or 240,h or 160,mode(),mod.options:get('gen3Neighbors')~=false,pw,ph)
end
FieldView.draw=function(game,w,h,opts)
  if not eligible(game) or (opts and opts.actorsOnly) then
    if owns(game) then return NativeIdentity.nativeDraw(game,previous,w,h,opts)end
    return previous(game,w,h,opts)
  end
  local rects=EngineRenderer.frameRects and EngineRenderer:frameRects()
  local override=EngineRenderer.worldCanvas==V.require('Presentation').boundCanvas() and rects
  local transitioning=Transition.isActive and Transition.isActive()
  local paperEntry=transitioning and V.require('battle/BattleViews').preference()~='native'and V.require('DioramaConfig').battle.enabled
  local direct=(override or paperEntry)and rects
  local pw=direct and math.floor(rects.vuw*rects.dpiX+.5) or (w or 240)
  local ph=direct and math.floor(rects.vuh*rects.dpiY+.5) or (h or 160)
  local displayWidth,displayHeight=pw,ph
  local scale=V.require('RenderResolution').scale()
  pw,ph=math.max(240,math.floor(pw*scale+.5)),math.max(160,math.floor(ph*scale+.5))
  pw,ph=V.require('RenderResolution').dimensions(pw,ph)
  if transitioning
    and V.require('FieldBattleTransition').reuse(displayWidth,displayHeight,w or 240,h or 160)then return end
  if paperEntry and Renderer.preparedMap==require('src.core.game3.map').current and Renderer.lastFrame then
    V.require('FieldHandoff').ready()
    V.require('FieldBattleTransition').capture(Renderer.lastFrame,displayWidth,displayHeight,w or 240,h or 160,true)
    return
  end
  love.graphics.push("all")
  local ok,canvas=pcall(drawDestination,game,w,h,pw,ph)
  love.graphics.pop()
  if ok and Renderer.buildPending then
    canvas=V.require('FieldHandoff').pending(Renderer,pw,ph)
    if not canvas then
      local result=NativeIdentity.nativeDraw(game,previous,w,h,opts)
      -- A cold field can still be meshing when an encounter starts. Feed its
      -- stationary native fallback through the same view-aware black fade.
      if override and Transition.isActive and Transition.isActive()then
        V.require('FieldBattleTransition').capture(V.require('Presentation').boundCanvas(),displayWidth,displayHeight,w or 240,h or 160,false)
      end
      return result
    end
  elseif ok then V.require('FieldHandoff').ready();TransitionTrace.ready()end
  if ok and canvas then
    if transitioning and(override or paperEntry)then
      V.require('FieldBattleTransition').capture(canvas,displayWidth,displayHeight,w or 240,h or 160,not Renderer.buildPending)
    elseif override then
      EngineRenderer:setWorldOverride(V.require('Presentation').fit(canvas,displayWidth,displayHeight))
    else
      -- Transitions still consume the native world target. An active override
      -- is presented directly and must not also blit into that discarded target.
      love.graphics.push("all")
      love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setColor(1,1,1,1)
      love.graphics.setBlendMode("alpha","premultiplied")
      love.graphics.draw(canvas,0,0,0,(w or 240)/pw,(h or 160)/ph)
      love.graphics.pop()
    end
    return
  end
  if not ok then
    TransitionTrace.step('OASC draw failed',tostring(canvas))
    broken=true;exports.rendererError=tostring(canvas);exports.rendererInstalled=false
    pcall(Renderer.release)
    mod.log:warn("Gen3 paper renderer disabled; native view restored: %s",tostring(canvas))
  end
  return previous(game,w,h,opts)
end
local ModSetting=V.require("ModSetting")
local enabledSetting=ModSetting.new("gen3Voxel","PAPER WORLD",{true,false},{"ON","OFF"})
local function setMode(value,game)
  if not Camera.valid(value) then return false end
  if game then
    enabledSetting:setValue(value~="off",game,true)
    forcedMode=nil
  else forcedMode=value end
  if value~="off" then Tilt.setLevel(0) end
  return true
end
local function cycle(game)setMode(mode()=="off" and "paper" or "off",game)end
local function setProjection(value)
  if value~="perspective"and value~="orthographic"then return false end
  local setting=V.require('Menu').settings.gen3Perspective
  if setting and Effects.game then setting:setValue(value=='perspective',Effects.game,true)end
  V.require('DioramaConfig').camera.projection=value
  return true
end
exports.gen3={setProjection=setProjection,setMode=setMode,getMode=mode,stats=function()return Renderer.stats end,
  invalidate=Renderer.invalidate}
local cards=V.require('core/AscendantCardRegistry').new()
local battleAdapter=V.require('battle/Gen3BattleAdapter').new({owns=owns,mode=mode,
  supportsMap=function()
    local emerald=V.data('Emerald')
    local map=require('src.core.game3.map')
    return not emerald.active() or emerald.isSupported(map.current,map.currentDef())
  end})
CardIndex.register(cards,{battle=battleAdapter})
Effects.cardsChanged=function()return CardIndex.apply(cards)end
local activation=CardIndex.apply(cards)
for _,failure in ipairs(activation.errors or{})do
  if failure.id=='oasc.gen3.overworld-battle'then battleAdapter.error=tostring(failure.error)end
  mod.log:warn('Card %s unavailable: %s',failure.id,tostring(failure.error))
end
exports.gen3.battle=battleAdapter.public
exports.cards=V.require('core/AscendantCardHost').new({cardSchema='ascendant.card/v1',
  health=function()return cards:healthAll()end})
local battleViewHeld={}
local function toggleBattleView(game)
  local view=battleAdapter:toggle(game)
  if view then V.require('Menu').settings.gen3BattleView:setValue(view,game,true)end
end
mod.hooks:wrap("input.key",function(nextFn,game,event)
  if owns(game) and Battle.isActive() and (event.key=="f6" or event.key=="5")then
    if event.phase=="released" then battleViewHeld[event.key]=nil
    elseif event.phase=="pressed" and not battleViewHeld[event.key]then
      battleViewHeld[event.key]=true;toggleBattleView(game)
    end
    return
  end
  if event.phase=="released"then battleViewHeld[event.key]=nil end
  if owns(game) and V.require("Menu").shortcut(game,event)then return end
  if game.phase=="field" and not Stack.busy() and not Battle.isActive() then
    -- F7 opens the live graphics overlay (reference-style HD-2D panel).
    if V.require("GraphicsOverlay").key(game,event)then return end
    if event.key=="5" or event.key=="f6" then if event.phase=="pressed" then cycle(game) end;return end
    if mode()~="off" and event.key=="3" then return end
  end
  return nextFn(game,event)
end)
-- Controller / Steam Deck: SELECT+R opens the F7 graphics overlay; while it
-- is open the d-pad moves/changes rows, A steps forward, B or SELECT+R closes.
mod.hooks:wrap("input.gamepad",function(nextFn,game,event)
  local O=V.require("GraphicsOverlay")
  if game.phase=="field" and not Stack.busy() and not Battle.isActive() and event.phase=="pressed" then
    local b=event.button
    local selectHeld=game.input and game.input.isDown and game.input:isDown("select")
    if not selectHeld and event.joystick and event.joystick.isGamepadDown then
      local ok,down=pcall(function()return event.joystick:isGamepadDown("back")end);selectHeld=ok and down==true
    end
    local rHeld=false
    if event.joystick and event.joystick.isGamepadDown then
      local ok,down=pcall(function()return event.joystick:isGamepadDown("rightshoulder")end);rHeld=ok and down==true
    end
    -- Either order works; holding R first keeps SELECT from firing a registered item.
    if (b=="rightshoulder" and selectHeld) or (b=="back" and rHeld) then O.toggle(true);return end
    if O.open then
      local gb=b
      pcall(function()gb=require("src.core.GamepadMap").mapGamepadButton(b)or b end)
      local key=({dpup="up",dpdown="down",dpleft="left",dpright="right",a="return",b="escape",start="escape"})[gb] or ({dpup="up",dpdown="down",dpleft="left",dpright="right"})[b]
      if key then O.key(game,{key=key,phase="pressed"}) end
      return
    end
  end
  return nextFn(game,event)
end)
-- FLASH as in the reference clips: usable in caves (the game3 party menu
-- never passes the cave context) and outdoors at night, where it lights a
-- pool around the player until the map changes. Badge and move are still
-- required; the native handler does all checks and sets the native flag.
if not V.data('Emerald').active() then
  local FM=require("src.core.game3.field_moves")
  local native=FM.flashFromMenu
  local function wrapped(ctx)
    local cfg=V.require("DioramaConfig").flash or {}
    local def=require("src.core.game3.map").currentDef()
    local mt=def and tonumber(def.mapType)
    if cfg.enabled~=false and def then
      if mt==4 then ctx.isCave=true
      elseif V.require("HauntedFog").active(def) then
        -- Pokémon Tower: FLASH lights the dark floor and drives the ghost fog back.
        ctx.isCave=true
        local res=native(ctx)
        if res and res.ok then V.require("Atmosphere").flashMap=def.id or def.name end
        return res
      elseif cfg.outdoorNight and FM.isOutdoors(mt) and V.require("DayNight").windowLight()>(cfg.nightThreshold or .3) then
        ctx.isCave=true
        local res=native(ctx)
        if res and res.ok then V.require("Atmosphere").flashMap=def.id or def.name end
        return res
      end
    end
    return native(ctx)
  end
  FM.flashFromMenu=wrapped
  if FM.MENU_HANDLERS and FM.MOVES then FM.MENU_HANDLERS[FM.MOVES.FLASH]=wrapped end
end
local Game=require("src.core.Game3")
local previousMousePress,previousMouseRelease=Game.mousepressed,Game.mousereleased
local quickMouseHeld=false
Game.mousepressed=function(game,x,y,button,istouch,...)
 if owns(game) and button==1 and not istouch and V.require('Menu').pointer(game,x,y)then quickMouseHeld=true;return end
 if previousMousePress then return previousMousePress(game,x,y,button,istouch,...)end
end
Game.mousereleased=function(game,x,y,button,istouch,...)
 if owns(game) and button==1 and quickMouseHeld then quickMouseHeld=false;return end
 if previousMouseRelease then return previousMouseRelease(game,x,y,button,istouch,...)end
end
local previousWheel=Game.wheelmoved
Game.wheelmoved=function(game,dx,dy,...)
  local r=battleAdapter.active
  if owns(game) and r and r.game==game and r.scene and r.provider.wheel then
    r.provider.wheel(r.scene,dy or 0);return
  end
  if eligible(game) and not Stack.busy() then
    Camera.zoom=math.max(.65,math.min(2.4,Camera.zoom*math.exp(-(dy or 0)*.12)))
    return
  end
  if previousWheel then return previousWheel(game,dx,dy,...) end
end
local previousUpdate=Game.update
Game.update=function(game,dt,...)
  if not owns(game) then return previousUpdate(game,dt,...) end
  Renderer.frameDt=dt
  local battleMenu=V.require('Menu').active()
  if Battle.isActive()and battleMenu and battleMenu.battleSettings then
    -- Consume settings input before advancing combat: animations/typewriter
    -- continue, but zoom or sound changes never select an attack underneath.
    if game.input.step then game.input:step()end
    battleMenu:update(dt);game.input:reset()
    V.require('battle/MenuClock').update(game,dt,battleAdapter)
    require('src.core.game3.audio').update(dt)
    return
  end
  V.require('battle/MenuClock').reset()
  if battleAdapter:tick(game,dt) then
    game.input:reset()
    require('src.core.game3.audio').update(dt)
    return
  end
  if not Battle.isActive()and Renderer.buildPending and V.require('FieldHandoff').started and game.phase=='field'then game.input:reset()end
  local result=previousUpdate(game,dt,...)
  battleAdapter:update(game)
  Effects.game=game
  Effects.apply()
  V.require("GraphicsOverlay").apply()
  local day=V.require("DayNight")
  day.update(dt,game)
  local weather=V.require("Weather")
  weather.setClock(day.gameSeconds(game))
  local id,def=V.require("WorldAdapter").current(game)
  weather.updateVisual(dt,id and {id=id,def=def}or nil)
  V.require('SurfaceSteps').update(game,dt,id,def)
  return result
end
for _,event in ipairs({'save.loaded','save.created'})do mod.events:on(event,function()V.require('DayNight').restore();V.require('Weather').restore();V.require('SurfaceSteps').reset()end)end
mod.events:on('save.writing',function()V.require('DayNight').store();V.require('Weather').store()end)
local Menu=V.require("Menu")
Menu.install(optionSchema,{
  gen3Voxel=enabledSetting,
  gen3LiveDisplay=V.require("PerformanceOverlay").enabled,gen3LiveFps=V.require("PerformanceOverlay").fps,
  gen3LiveClock=V.require("PerformanceOverlay").clock,gen3LiveCpu=V.require("PerformanceOverlay").cpu,gen3LiveGpu=V.require("PerformanceOverlay").gpu,
  gen3Daytime=V.require("DayNight").setting,weather=V.require("Weather").setting,rainStrength=V.require("RainStrength").setting,
},function(key,value,game)
  if key=="gen3Voxel" then setMode(value and "paper" or "off",game) end
  if key=="gen3Quality"then forcedMode=nil end
  if key=='gen3BattleView' and game then battleAdapter:select(game,value)end
  if key=='gen3TerrariumZoom'or key=='gen3TerrariumIdleSound'then
    local r=battleAdapter.active
    if r and r.scene and r.scene.edition=='emerald'then r.provider.preference(r.scene);r.provider.leave(r.scene);r.provider.camera(r.scene)end
  end
  Effects.changed(key,value,game)
  if key:match("^gen3Card_")then CardIndex.apply(cards)end
end)
exports.gen3.menu=Menu
V.require('CenterEscalatorTraversal').install()
V.require('CameraContinuity').install()
V.require('PerformanceLog').install()
V.require('BattleAssetWarm').install()
V.require('BattleSoundWarm').install()
-- All preparation here runs during mod loading, before interactive field
-- frames. Full cache identity checks are retained, never replaced by version.
V.require('GeometryCache').validateIndex()
local roomsPrepared,roomPrepareError=pcall(function()V.require('RoomProviderWarmup').prepare()end)
if not roomsPrepared then mod.log:warn('OASC room provider preparation deferred: %s',tostring(roomPrepareError))end
local prepared,prepareError=pcall(function()
 Renderer.roomProgram=false;Renderer.prepareShaders()
 Renderer.roomProgram=true;Renderer.prepareShaders()
 local cfg=V.require('DioramaConfig')
 V.require('PaperShadows').prepareShaders(cfg.shadows.enabled and (cfg.settings.shadowSoftness or 1)>0)
 if cfg.contact.enabled then V.require('ContactShadows').prepareShader(true)end
 if cfg.weather.enabled then V.require('WorldRain').prepareShader()end
 V.require('CaveShafts').prepareShader()
 if cfg.forest.enabled then V.require('CloudShafts').prepareShader()end
 V.require('VolumeFog').prepareShaders()
 V.require('battle/terrarium/Scene').prepareShader()
 V.require('battle/terrarium/EmeraldScene').prepareShader()
end)
if not prepared then
 broken=true;exports.rendererError=tostring(prepareError);exports.rendererInstalled=false
 V.require('SupportDiagnostics').record('shader-error',tostring(prepareError))
 cards:deactivateAll(nil,'shader preparation failed');pcall(Renderer.release)
 mod.log:warn('OASC shader preparation failed; open FEHLER / LOGS SENDEN: %s',tostring(prepareError))
end
V.require('FoleyBank').prepare()
local previousDraw=Game.draw
Game.draw=function(game,...)
  previousDraw(game,...)
  if owns(game) then V.require('PerformanceLog').present() end
  if owns(game) then love.graphics.push("all");Menu.draw();V.require("GraphicsOverlay").draw();V.require("PerformanceOverlay").present();love.graphics.pop() end
end
local previousReset=Game.reset
Game.reset=function(game,...)
  if owns(game) then V.require('GameSharkGate').reset(game);cards:deactivateAll(nil,'game reset');V.require("PerformanceOverlay").reset();Renderer.release();V.require('FoleyBank').release();exports.active=false end
  return previousReset(game,...)
end
mod.hooks:wrap("ui.start_menu.items",function(nextFn,game,items)
  items=nextFn(game,items) or items
  local at=#items+1
  for i,item in ipairs(items)do if item.id=='mods' then at=i;break end end
  if at==#items+1 then for i,item in ipairs(items)do if item.id=='exit' then at=i;break end end end
  table.insert(items,at,{id="origami_gen3",label="ASCENDANT",onSelect=function()Menu.open(game)end})
  return items
end)
-- The native seven-tile window is too narrow for ASCENDANT. Keep its right
-- edge and original skin, widening only a menu that contains our entry.
local StartMenu=require('src.ui.game3.start_menu')
local previousTemplate=StartMenu.contentTemplate
StartMenu.contentTemplate=function(...)
  local tpl=previousTemplate(...)
  if not owns(StartMenu._game) then return tpl end
  local found=false
  for _,item in ipairs(StartMenu.ENTRIES or {})do if item.id=='origami_gen3' then found=true;break end end
  if not found then return tpl end
  local Font=require('src.ui.game3.frlg_font');local Window=require('src.ui.game3.window')
  local width=tpl.width
  for _,item in ipairs(StartMenu.ENTRIES)do
    width=math.max(width,math.ceil((Window.CURSOR_WIDTH+Font.measure(item.label or '')+4)/8))
  end
  local copy={};for k,v in pairs(tpl)do copy[k]=v end
  copy.left=math.max(0,tpl.left+tpl.width-width);copy.width=width
  copy.tilemapLeft=copy.left;copy.w=copy.width
  return copy
end
for _,event in ipairs({"world.block_replaced","map.reloaded","world.object_toggled"})do
  mod.events:on(event,function()Renderer.invalidate()end)
end
if mode()~="off" then Tilt.setLevel(0) end
mod.log:info("Gen3 paper renderer ready (%s)",require('src.core.GameVersion').get())
return exports.gen3
