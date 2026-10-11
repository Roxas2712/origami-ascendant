-- Statement -> Ascendant intro -> native boot/map load, exactly once.
local V=...
local S={}
local function owns(game,exports)return game.mods and game.mods.exports and game.mods.exports.ORIGAMI_ASCENDANT==exports end
function S.install(exports)
 if S.installed then return end;S.installed=true
 local Game=require('src.core.Game3');local boot,update,draw,reset=Game._handleBootAction,Game.update,Game.draw,Game.reset
 local Notice=V.require('CommunityStatement')
 local function intro(game,action,args)
  local prefix='gen3/integrated/ascendant_startup/'
  local ok,scene=pcall(function()
   local Scene=assert((loadstring or load)(assert(V.mod:read(prefix..'IntroScene.lua'))))()
   return Scene.new(function(path)return V.mod:read(prefix..path)end)
  end)
  if not ok then V.mod.log:warn('Ascendant intro unavailable: %s',scene);return boot(game,action,unpack(args))end
  S.active={game=game,action=action,args=args,scene=scene,time=0}
 end
 Game.reset=function(game,...)
  if Notice.active and Notice.active.game==game then Notice.close()end
  if S.active and S.active.game==game then S.active.scene:release();V.require('StartupThanks').release(S.active.thanks);S.active=nil end
  V.require('FieldHandoff').release()
  V.require('HauntedWisps').resetContacts()
  return reset(game,...)
 end
 Game._handleBootAction=function(game,action,...)
  if not owns(game,exports)or V.mod.options:get('gen3Voxel')==false or not action
   or(action.action~='continue'and action.action~='new_game')then return boot(game,action,...)end
  if S.active or Notice.active then return end
  -- Stop the boot menu tune before any presentation. Native field audio is
  -- started only by boot below, after the whole intro has finished.
  require('src.core.game3.audio').stopAll()
  V.require('HauntedWisps').resetContacts()
  local args={...}
  if Notice.setting:get()then Notice.open(game,function()intro(game,action,args)end)
  else intro(game,action,args)end
 end
 Game.update=function(game,dt,...)
  if Notice.active and Notice.active.game==game then if game.input then game.input:reset()end;return end
  local a=S.active
  if not a or a.game~=game then return update(game,dt,...)end
  if game.input then game.input:reset()end
  if a.loadRequested and not a.adopted then
   -- Use the already visible thanks scene for authentication/index decoding,
   -- before native boot creates the first room. No artificial extra delay.
   V.require('GeometryCache').validateIndex(.004)
   if not a.sceneReleased then
    a.scene:release();a.sceneReleased=true;a.thanks=V.require('StartupThanks').new();a.thanksLast=nil
   end
   if a.thanks.age<V.require('StartupThanks').duration then return end
   V.require('StartupThanks').release(a.thanks);a.thanks=nil;a.adopted=true
   -- The intro is over. Its 54 MiB of atlases must not overlap native import,
   -- shader compilation and the first field's render targets on mobile.
   boot(game,a.action,unpack(a.args))
  end
  if a.adopted then
   require('src.core.game3.audio').update(dt)
   V.require('EffectSettings').game=game;V.require('EffectSettings').apply();V.require('GraphicsOverlay').apply()
   if game.phase=='field'then
    local id,def=V.require('WorldAdapter').current(game)
    if id then V.require('GeometryCacheLookahead').update(game,id,def,V.require('FieldWork').update(game,false))end
   end
  end
 end
 Game.draw=function(game,...)
  if Notice.active and Notice.active.game==game then return Notice.draw()end
  local a=S.active
  if not a or a.game~=game then
   local result=draw(game,...)
   if owns(game,exports)and V.mod.options:get('gen3Voxel')~=false then
    V.require('HauntedWisps').drawScreen(game)
    V.require('FieldHandoff').overlay(game)
   end
   return result
  end
  local now=love.timer.getTime()
  if a.thanks then
   if a.thanksLast then a.thanks.age=a.thanks.age+math.min(.1,math.max(0,now-a.thanksLast))end;a.thanksLast=now
   return V.require('StartupThanks').draw(a.thanks,love.graphics.getWidth(),love.graphics.getHeight())
  end
  if a.lastDraw and not a.loadRequested then a.time=a.time+math.min(.1,math.max(0,now-a.lastDraw))end;a.lastDraw=now
  if not a.drawn then
   local opts=game.options or{};local volume=require('src.core.game3.audio')._sfxVolume or 1
   a.scene:play(opts.splashMute and 0 or volume);a.drawn=true
  end
  if a.skip or a.time>=a.scene.duration then a.loadRequested=true end
  if a.adopted then
   draw(game,...)
   a.prepared=game.phase~='field'or(not V.require('Renderer').buildPending and V.require('Renderer').lastFrame~=nil)or exports.rendererError~=nil
   if a.prepared then if not a.sceneReleased then a.scene:release()end;S.active=nil;return end
   V.require('FieldHandoff').overlay(game,true);return
  end
  local t=a.loadRequested and a.scene.duration-.6 or a.time
  a.scene:draw(t,love.graphics.getWidth(),love.graphics.getHeight(),a.time)
  if a.loadRequested then
   local L=V.require('MenuLocale');a.scene:drawStatus(L.text('Preparing world and graphics','Welt und Grafik werden vorbereitet'),0,1)
  end
 end
 local function modal(game)return Notice.active and Notice.active.game==game end
 local function presenting(game)return S.active and S.active.game==game end
 V.mod.hooks:wrap('input.key',function(nextFn,game,event)
  if modal(game)then return Notice.key(event.key,event.phase,event.isrepeat)end
  if presenting(game)then
   if event.phase=='pressed'and S.active.time>.2 and(event.key=='return'or event.key=='space'or event.key=='escape'or event.key=='z'or event.key=='x')then S.active.skip=true end
   return
  end
  return nextFn(game,event)
 end)
 V.mod.hooks:wrap('input.gamepad',function(nextFn,game,event)
  local key=require('src.core.GamepadMap').mapGamepadButton(event.button)or event.button
  if modal(game)then return Notice.key(({dpup='up',dpdown='down',dpleft='left',dpright='right'})[key]or key,event.phase)end
  if presenting(game)then
   if event.phase=='pressed'and S.active.time>.2 and(key=='a'or key=='b'or key=='start')then S.active.skip=true end;return
  end
  return nextFn(game,event)
 end)
 local methods={mousepressed='pressed',mousereleased='released',mousemoved='moved',touchpressed='pressed',touchreleased='released',touchmoved='moved'}
 local held={}
 for name,phase in pairs(methods)do
  local original=Game[name];local touch=name:match('^touch')
  Game[name]=function(game,...)
   local args={...};local id=touch and args[1]or'mouse';local x,y=touch and args[2]or args[1],touch and args[3]or args[2]
   if modal(game)then
    if phase=='pressed'then held[id]=true end
    Notice.pointer(phase,id,x,y)
    if phase=='released'then held[id]=nil end;return
   end
   if held[id]then if phase=='released'then held[id]=nil end;return end
   if presenting(game)then
    if phase=='released'and S.active.time>.2 then S.active.skip=true end;return
   end
   if original then return original(game,...)end
  end
 end
 local wheel=Game.wheelmoved
 Game.wheelmoved=function(game,dx,dy,...)
  if modal(game)then Notice.scroll(-(dy or 0)*64);return end
  if presenting(game)then return end
  if wheel then return wheel(game,dx,dy,...)end
 end
end
return S
