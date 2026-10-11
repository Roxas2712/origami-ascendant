-- Fixed field magnification. The battle and photo cameras retain ownership of
-- their own zoom. No scene/cache key, target resolution or player state changes.
local Card={ID='oasc.gen3.field-zoom',VERSION='1.0.0',CAPABILITY='ascendant.field-zoom.gen3/v1'}
local levels={.75,1,1.25,1.5,2}
Card.option={key='gen3Card_fieldZoom',label='FIELD ZOOM',type='toggle',default=true,
 help='Fixed, saved field zoom. C cycles levels; +/- or wheel steps. Controller: hold L + D-pad up/down. Touch: pinch on the world.'}
Card.options={
 {key='gen3FieldZoom',label='FIELD ZOOM',type='choice',default=1,choices={{'0.75x',.75},{'1x',1},{'1.25x',1.25},{'1.5x',1.5},{'2x',2}},
  help='C: next level. +/- or wheel: closer/further. Controller: L + D-pad up/down. Touch: pinch on the world. Indoor limit does not change the saved outdoor level.'},
 {key='gen3FieldZoomHud',label='ZOOM NOTIFICATION',type='toggle',default=true,help='Briefly show the zoom level when it changes.'},
}
function Card.descriptor(V)
 local C,Camera,S=V.require('DioramaConfig'),V.require('Camera'),V.require('core/RenderSeams')
 local Menu,HUD=V.require('Menu'),V.require('PerformanceOverlay')
 local Game=require('src.core.Game3');local Battle=require('src.core.game3.battle')
 local Transition=require('src.core.game3.battle_transition');local Stack=require('src.ui.game3.stack')
 local Fade=require('src.ui.game3.fade');local Warp=require('src.core.game3.warp')
 local state={active=false,current=1,desired=1,elapsed=.25,saved=1,draws={}}
 local held,consumed,unsubs,presets={},{},{},{}
 local font,style,oldMatrix,oldFit,oldWheel,matrix,fit,wheel,oldReset,oldMetrics
 local oldTouch,wrappers,touches={},{},{};local pinchDistance,pinchMap
 local function cfg()return C.cards and C.cards.fieldZoom end
 local function setting()return Menu.settings.gen3FieldZoom end
 local function clock()return love.timer.getTime()end
 local function owns(g)return g and g.mods and g.mods.exports and g.mods.exports[V.mod.id]==V.mod.exports end
 local function photoOpen()return Camera.photoModeOpen==true end
 local function field(g)
  return state.active and S.enabled and cfg()and cfg().enabled~=false and owns(g)and g.phase=='field'
   and not Battle.isActive()and not Transition.isActive()and V.mod.options:get('gen3Quality')~='off'
 end
 local function allowed(g)
  return field(g)and not Stack.busy()and not Fade.isActive()and not Warp.isBusy()
   and not V.require('GraphicsOverlay').open and not V.require('Renderer').buildPending
   and not V.require('FieldHandoff').started and not V.require('FieldHandoff').foldVisible and not photoOpen()
 end
 local function notify()state.untilTime=clock()+.8 end
 local function savedLevel()
  local value=setting()and setting():get()or V.mod.options:get('gen3FieldZoom')or 1
  for _,level in ipairs(cfg().levels)do if value==level then return level end end
  return cfg().levels[2]
 end
 local function choose(g,dir,wrap)
  local values=cfg().levels;local index=2
  for i,v in ipairs(values)do if v==savedLevel()then index=i;break end end
  index=wrap and(index%#values+1)or math.max(1,math.min(#values,index+dir))
  setting():setValue(values[index],g,true);notify()
 end
 local function key(nextFn,g,event)
  local k=event.key
  if event.phase=='released'and consumed[k]then held[k]=nil;consumed[k]=nil;return end
  local delta=(k=='+'or k=='='or k=='kp+'or k=='kpadd')and 1 or(k=='-'or k=='kp-'or k=='kpsubtract')and -1
  if (k==cfg().key or delta)and allowed(g)and not(g.input and g.input.keyBindings and g.input.keyBindings[k])then
   if event.phase=='pressed'and not held[k]then choose(g,delta or 1,k==cfg().key)end
   held[k]=event.phase=='pressed'or nil;consumed[k]=held[k];return
  end
  return nextFn(g,event)
 end
 local function pad(nextFn,g,event)
  local b=event.button
  if event.phase=='released'and consumed[b]then consumed[b]=nil;return end
  if b=='leftshoulder'or b=='back'then held[b]=event.phase=='pressed'or nil end
  local shoulder=held.leftshoulder;local select=held.back
  if event.joystick and event.joystick.isGamepadDown then
   shoulder=shoulder or event.joystick:isGamepadDown('leftshoulder');select=select or event.joystick:isGamepadDown('back')
  end
  if (b=='dpup'or b=='dpdown')and shoulder and not select and allowed(g)then
   if event.phase=='pressed'and not consumed[b]then choose(g,b=='dpup'and 1 or -1,false);consumed[b]=true end
   return
  end
  return nextFn(g,event)
 end
 local function camera(previous,ctx)
  state.renderField=field(ctx.game)and not ctx.presentation
  if not state.renderField then Camera.zoom=Camera.defaultZoom;return previous end
  if photoOpen()then return previous end
  state.room=not V.data('Shapes').outdoors(ctx.def)or tonumber(ctx.def.mapType)==4
  local saved=savedLevel();local desired=state.room and math.max(1,math.min(cfg().indoorMax,saved))or saved
  state.saved=saved
  if desired~=state.desired then state.desired=desired;state.elapsed=0;Camera.connection=nil;notify()end
  if state.lastRoom~=state.room then state.lastRoom=state.room;notify()end
  Camera.zoom=Camera.defaultZoom/state.current
  return previous
 end
 local function metrics()
  if not state.renderField then return nil end
  local R=V.require('Renderer');local s=R.stats or{};local g=love.graphics.getStats()
  local row={visible=R.visibleEntries and #R.visibleEntries or 0,drawcalls=g.drawcalls or 0,vertices=s.vertices or 0}
  state.draws[tostring(state.desired)]=row;state.visible=row.visible;return row
 end
 local function update(nextFn,g,dt)
  -- main.lua installs the legacy wheel handler after Cards activate. Capture
  -- that final handler on the first update, then restore exactly it on disable.
  if Game.wheelmoved~=wheel then oldWheel=Game.wheelmoved;Game.wheelmoved=wheel end
  for name,fn in pairs(wrappers)do if Game[name]~=fn then oldTouch[name]=Game[name];Game[name]=fn end end
  if Battle.isActive()or Transition.isActive()then Camera.zoom=Camera.defaultZoom;state.renderField=false end
  local id=require('src.core.game3.map').current
  if pinchMap~=id or not allowed(g)then touches={};pinchDistance=nil;pinchMap=id end
  if allowed(g)then
   state.elapsed=math.min(.25,state.elapsed+math.max(0,dt or 0))
   state.current=state.elapsed>=.25 and state.desired or state.current+(state.desired-state.current)*(1-math.exp(-math.max(0,dt or 0)/.08))
  end
  return nextFn(g,dt)
 end
 local function hud(nextFn,g,viewport)
  local result=nextFn(g,viewport)
  if not field(g)or Stack.busy()or photoOpen()or not state.untilTime or clock()>state.untilTime or V.mod.options:get('gen3FieldZoomHud')==false then return result end
  font=font or love.graphics.newFont(16);style=style or V.require('VascMenuStyle').new(V.mod,{edition='firered'}).colors
  local text=string.format('ZOOM %.2fx%s',state.rounded or state.desired,state.room and ' (ROOM)'or'')
  local g=love.graphics;g.push('all');g.origin();g.setShader();g.setScissor();g.setDepthMode();g.setFont(font)
  local w=font:getWidth(text)+24;local h=font:getHeight()+16;local x=math.max(8,(viewport.width-w)*.5);local y=math.max(8,viewport.height-h-12)
  g.setColor(style.glass);g.rectangle('fill',x,y,w,h,6,6);g.setColor(style.glassLine);g.rectangle('line',x,y,w,h,6,6)
  g.setColor(style.glassText);g.print(text,x+12,y+8);g.pop();return result
 end
 local function stop()
  for i=#unsubs,1,-1 do unsubs[i]();unsubs[i]=nil end;S.unregister(Card.ID)
  if Camera.matrix==matrix then Camera.matrix=oldMatrix end
  if Camera.fitGroundBounds==fit then Camera.fitGroundBounds=oldFit end
  if Game.wheelmoved==wheel then Game.wheelmoved=oldWheel end
  for name,fn in pairs(wrappers)do if Game[name]==fn then Game[name]=oldTouch[name]end end
  wrappers={};oldTouch={};touches={};pinchDistance=nil
  if Menu.resetCamera==state.reset then Menu.resetCamera=oldReset end
  if HUD.sceneMetrics==metrics then HUD.sceneMetrics=oldMetrics end
  Menu.unregisterSection(Card.ID)
  if font then font:release();font=nil end
  Camera.zoom=Camera.defaultZoom;Camera.connection=nil;state.active=false;state.renderField=false
  held={};consumed={};state.untilTime=nil
  if C.cards then C.cards.fieldZoom=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name];if p and p.cards then p.cards.fieldZoom=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end end
  presets={};V.require('GeometryConfig').unregisterPresentation(Card.ID);return true
 end
 local function start(_,installed)
  if not installed or not installed.installed then return false,'public hooks unavailable'end
  if state.active then return state,{level=function()return state.saved end}end
  C.cards=C.cards or{};C.cards.fieldZoom=C.cards.fieldZoom or{enabled=true,levels=levels,key='c',indoorMax=1.25}
  V.require('GeometryConfig').registerPresentation(Card.ID,'fieldZoom',{'enabled','levels','key','indoorMax'})
  for name,p in pairs(C.settings.presets)do presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.fieldZoom};p.cards=p.cards or{};p.cards.fieldZoom=p.cards.fieldZoom or{enabled=name~='off'}end
  state.active=true;state.desired=savedLevel();state.current=state.desired;state.elapsed=.25
  oldMatrix,oldFit=Camera.matrix,Camera.fitGroundBounds
  fit=function(vp,target,bounds,limit)
   if not state.renderField or Battle.isActive()or Transition.isActive()or Camera.override or Camera.experimental()then return oldFit(vp,target,bounds,limit)end
   -- Preserve magnification. Clamp translation only where the coverage fits;
   -- Horizon/WorldBorder supply the remaining extent on small outdoor maps.
   local inv=Camera.groundInverse(vp);local lx,lz,hx,hz=math.huge,math.huge,-math.huge,-math.huge
   for _,x in ipairs{-1,1}do for _,z in ipairs{-1,1}do local w=inv[7]*x+inv[8]*z+inv[9]
    local px,pz=(inv[1]*x+inv[2]*z+inv[3])/w,(inv[4]*x+inv[5]*z+inv[6])/w
    lx,lz,hx,hz=math.min(lx,px),math.min(lz,pz),math.max(hx,px),math.max(hz,pz)
   end end
   local function shift(lo,hi,a,b)
    if hi-lo>b-a then return 0 end
    return math.max(a-lo,math.min(b-hi,0))
   end
   return 1,shift(lx,hx,bounds[1]*16+34,bounds[3]*16-34),shift(lz,hz,bounds[2]*16+34,bounds[4]*16-34)
  end
  matrix=function(mode,px,py,facing,w,h,obstructed,indoors,targetHeight)
   local vp,eye,target=oldMatrix(mode,px,py,facing,w,h,obstructed,indoors,targetHeight)
   if not state.renderField or Battle.isActive()or Transition.isActive()or Camera.override or Camera.experimental()or state.elapsed<.25 or Camera.connection then return vp,eye,target end
   local R=V.require('Renderer');local width=R.canvas and R.canvas:getWidth()or w
   local footY=targetHeight or 0
   local function tile(m)
    local a=Camera.project(m,px+8,footY,py+8);local b=Camera.project(m,px+24,footY,py+8)
    return a and b and math.abs(b-a)*width or 0
   end
   local originalZoom=Camera.zoom;local pixels=tile(vp);local rounded=math.floor(pixels+.5)
   if rounded>0 and pixels>0 then
    local zoom=originalZoom
    if Camera.projection()=='orthographic'then zoom=zoom*pixels/rounded
    else
     local divisor=vp[13]*(px+8)+vp[14]*footY+vp[15]*(py+8)+vp[16]
     zoom=zoom+divisor*(pixels/rounded-1)/(C.camera.distance*(Camera.envScale or 1))
    end
    local nominal=Camera.defaultZoom/originalZoom;local actual=Camera.defaultZoom/zoom
    state.roundingLimited=math.abs(actual/nominal-1)>.02
    if not state.roundingLimited then
     Camera.zoom=zoom;vp,eye,target=oldMatrix(mode,px,py,facing,w,h,obstructed,indoors,targetHeight)
    end
   end
   state.rounded=Camera.defaultZoom/Camera.zoom;state.tilePixels=tile(vp);state.targetWidth=width
   return vp,eye,target
  end
  Camera.matrix,Camera.fitGroundBounds=matrix,fit
  wheel=function(g,dx,dy,...)
   if allowed(g)then
    if dy and dy~=0 and(not state.lastWheel or clock()-state.lastWheel>=.15)then state.lastWheel=clock();choose(g,dy>0 and 1 or -1,false)end
    return
   end
   -- Menus, handoffs and photo mode must not fall through to legacy field zoom.
   if owns(g)and g.phase=='field'and not Battle.isActive()and not Transition.isActive()then return end
   if oldWheel then return oldWheel(g,dx,dy,...)end
  end
  local function distance()
   local a,b,count;count=0
   for _,point in pairs(touches)do count=count+1;if not a then a=point else b=point end end
   if count==2 then return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)end
  end
  wrappers.touchpressed=function(g,id,x,y,...)
   -- Existing menu/splash/virtual-pad handlers get first refusal. Only touches
   -- that began on free world space may become a pinch; never steal held A/Dpad.
   local ctl=g.touchControls
   local onControl=ctl and ctl.active and ctl.enabled~=false and ctl.hitTest and ctl:hitTest(x,y)
   local result;if oldTouch.touchpressed then result=oldTouch.touchpressed(g,id,x,y,...)end
   if not result and not onControl and allowed(g)and not(ctl and ctl.touches and ctl.touches[id])then
    touches[id]={x=x,y=y};pinchDistance=distance();pinchMap=require('src.core.game3.map').current
   end
   return result
  end
  wrappers.touchmoved=function(g,id,x,y,...)
   if touches[id]then
    touches[id].x,touches[id].y=x,y
    local d=distance()
    if allowed(g)and d and pinchDistance and pinchDistance>=24 then
     local ratio=d/pinchDistance
     if (ratio>=1.20 or ratio<=1/1.20)and(not state.lastPinch or clock()-state.lastPinch>=.15)then
      choose(g,ratio>1 and 1 or -1,false);state.lastPinch=clock();pinchDistance=d;state.pinches=(state.pinches or 0)+1
     end
    elseif not allowed(g)then touches={};pinchDistance=nil end
   end
   if oldTouch.touchmoved then return oldTouch.touchmoved(g,id,x,y,...)end
  end
  wrappers.touchreleased=function(g,id,...)
   touches[id]=nil;pinchDistance=distance()
   if oldTouch.touchreleased then return oldTouch.touchreleased(g,id,...)end
  end
  state.reset=function(g)setting():setValue(1,g,true);notify()end
  oldReset=Menu.resetCamera;Menu.resetCamera=state.reset
  oldMetrics=HUD.sceneMetrics;HUD.sceneMetrics=metrics
  Menu.registerSection(Card.ID,{id='camera',label='CAMERA',available=function()return not Battle.isActive()and not Transition.isActive()end,help=Card.option.help,keys={'gen3FieldZoom','gen3FieldZoomHud'},quick='camera'})
  S.register(Card.ID,'camera',camera,90000)
  unsubs[#unsubs+1]=V.mod.hooks:wrap('input.key',key,900)
  unsubs[#unsubs+1]=V.mod.hooks:wrap('input.gamepad',pad,900)
  unsubs[#unsubs+1]=V.mod.hooks:wrap('core.update',update,900)
  unsubs[#unsubs+1]=V.mod.hooks:wrap('render.hud',hud,900)
  return state,{level=function()return state.saved end}
 end
 return{schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
 tests={'tests/gen3_field_zoom_play_test.lua'},docs={'gen3/cards/FIELD_ZOOM.md'},
 impact={runtimeOwners={'gen3.render.field-zoom'},saveWrites={},publicHooks={'input.key','input.gamepad','core.update','render.hud'},files={'gen3/lib/cards/FieldZoomCard.lua','gen3/cards/FIELD_ZOOM.md'}},
 lifecycle={install=function()return{installed=V.mod.hooks and type(V.mod.hooks.wrap)=='function'}end,activate=start,deactivate=stop,abort=stop,
 health=function()metrics();local h={ok=not S.errors[Card.ID],error=S.errors[Card.ID]};for k,v in pairs(state)do if type(v)~='function'then h[k]=v end end;return h end}}
end
return Card
