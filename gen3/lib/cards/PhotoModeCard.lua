local Card={ID='oasc.gen3.photo-mode',VERSION='1.0.0',CAPABILITY='ascendant.photo-mode.gen3/v1'}
Card.option={key='gen3Card_photoMode',label='FOTOMODUS',type='toggle',default=true,
 help='F8 oder SELECT+L: pausierte Kamera, Lichtvorschau und PNG-Foto. Keine gespeicherten Aenderungen.'}
function Card.descriptor(V)
 local L=V.require('MenuLocale')
 local C,S=V.require('DioramaConfig'),V.require('core/RenderSeams')
 local Camera,Day,Weather,Mood=V.require('Camera'),V.require('DayNight'),V.require('Weather'),V.require('WeatherMood')
 local Map=require('src.core.game3.map');local Battle=require('src.core.game3.battle')
 local Stack=require('src.ui.game3.stack');local Fade=require('src.ui.game3.fade');local Warp=require('src.core.game3.warp')
 local state={active=false,open=false,ui=true,exports=0,cursor=1,resources=0};local unsubs,presets={},{}
 local saved,game,frame,font,style;local held,axes={},{}
 local view={zoomMul=1,offsetX=0,offsetZ=0};local focus={0,0,0};local lut={mix=0,amount=1}
 local choices={'original','clear','rain','storm','snow','fog'}
 local grades={'original','neutral','dawn','day','golden','dusk','night'}
 local rows={'Uhrzeit','Wetter','Fokusdistanz','Tiefenunschaerfe','Tilt-Shift','Vignette','Farblook','Exportgroesse'}
 local fields={'enabled','depthOfField','vignette','vignetteStrength'}
 local function resetInput()held={};axes={};if game and game.input then game.input:reset()end end
 local timeFn=function()return state.time end
 local clockFn=function()return state.frozen end
 local weatherFn=function(self,...)
  if state.weather==1 then return saved.weatherGet(self,...)end
  return choices[state.weather]
 end
 local function close()
  if saved then
   if Day.time==timeFn then Day.time=saved.timeFn end
   if V.clock==clockFn then V.clock=saved.clockFn end
   if Weather.setting.get==weatherFn then Weather.setting.get=saved.weatherGet end
   Weather.visual=saved.visual;Mood.state=saved.mood
   for _,k in ipairs(fields)do C.post[k]=saved.post[k]end
   for k in pairs(C.post.coc)do C.post.coc[k]=nil end
   for k,v in pairs(saved.coc)do C.post.coc[k]=v end
   Camera.override=saved.camera
  end
  resetInput();saved=nil;game=nil;state.open=false;Camera.photoModeOpen=false;state.pendingExport=false
 end
 local function available(g)
  return state.active and S.enabled and C.cards and C.cards.photoMode and C.cards.photoMode.enabled~=false
   and g and g.phase=='field'and not Battle.isActive()and not Stack.busy()and not Fade.isActive()and not Warp.isBusy()
   and V.mod.options:get('gen3Quality')~='off' and not V.require('GraphicsOverlay').open and not V.require('Renderer').buildPending
   and(frame or V.require('Renderer').lastFrame)
 end
 local function open(g)
  if not available(g)then return false end
  frame=frame or V.require('Renderer').lastFrame
  game=g;saved={timeFn=Day.time,clockFn=V.clock,weatherGet=Weather.setting.get,visual=Weather.visual,mood=Mood.state,camera=Camera.override,post={},coc={}}
  for _,k in ipairs(fields)do saved.post[k]=C.post[k]end
  for k,v in pairs(C.post.coc)do saved.coc[k]=v end
  state.time=Day.time();state.frozen=(V.clock or love.timer.getTime)()
  state.map=Map.current;state.weather=1;state.grade=1;state.focus=0;state.strength=C.post.depthOfField and 1 or 0
  state.tilt=C.post.coc.tiltAmount or 0;state.vignette=C.post.vignette and C.post.vignetteStrength or 0
  state.scale=math.min(4,C.cards.photoMode.maxScale or 4);state.ui=true;state.cursor=1;state.message=nil
  view.zoomMul,view.offsetX,view.offsetZ,view.elevationDegrees=1,0,0,math.deg(Camera.elevation())
  Weather.visual={};for k,v in pairs(saved.visual)do Weather.visual[k]=v end
  Day.time=timeFn;V.clock=clockFn;Weather.setting.get=weatherFn
  state.open=true;Camera.photoModeOpen=true;resetInput();return true
 end
 local function weatherPreview()
  if state.weather==1 then Mood.state=saved.mood;for k,v in pairs(saved.visual)do Weather.visual[k]=v end;return end
  local mode=choices[state.weather];Mood.state=nil
  Mood.update(0,{id=Map.current,def=Map.currentDef()},mode)
  Weather.visual.fog=mode=='fog'and 1 or 0;Weather.visual.heat=0
 end
 local function adjust(dir)
  local row=state.cursor
  if row==1 then state.time=(state.time+dir*Day.CYCLE/48)%Day.CYCLE
  elseif row==2 then state.weather=(state.weather-1+dir)%#choices+1;weatherPreview()
  elseif row==3 then state.focus=math.max(-256,math.min(512,state.focus+dir*8))
  elseif row==4 then state.strength=math.max(0,math.min(1,state.strength+dir*.1))
  elseif row==5 then state.tilt=math.max(0,math.min(1,state.tilt+dir*.1))
  elseif row==6 then state.vignette=math.max(0,math.min(1,state.vignette+dir*.05))
  elseif row==7 then state.grade=(state.grade-1+dir)%#grades+1
  elseif row==8 then state.scale=math.max(1,math.min(C.cards.photoMode.maxScale or 4,state.scale+dir))end
 end
 local function key(nextFn,g,event)
  local k=event.key;local down=event.phase=='pressed'
  if k==(C.cards and C.cards.photoMode and C.cards.photoMode.key or'f8')then
   if down and not held[k]then if state.open then close()else open(g)end end
   held[k]=down or nil;return
  end
  if not state.open or g~=game then return nextFn(g,event)end
  if down and not held[k]then
   if k=='escape'then close();return
   elseif k=='tab'then state.ui=not state.ui
   elseif k=='return'then state.pendingExport=true
   elseif k=='['then state.cursor=(state.cursor-2)%#rows+1
   elseif k==']'then state.cursor=state.cursor%#rows+1
   elseif k=='-'then adjust(-1)
   elseif k=='='or k=='+'then adjust(1)end
  end
  held[k]=down or nil
 end
 local function pad(nextFn,g,event)
  local b=event.button;local down=event.phase=='pressed'
  if event.phase=='axis'then
   if state.open and g==game then axes[event.axis]=math.abs(event.value or 0)>.15 and event.value or 0;return end
   return nextFn(g,event)
  end
  if b=='back'or b=='leftshoulder'then
   local other=b=='back'and'leftshoulder'or'back';local paired=held[other]
   if not paired and event.joystick then pcall(function()paired=event.joystick:isGamepadDown(other)end)end
   if down and paired then if state.open then close()else open(g)end;return end
   held[b]=down or nil
  end
  if not state.open or g~=game then return nextFn(g,event)end
  if down then
   if b=='b'then close()
   elseif b=='x'then state.pendingExport=true
   elseif b=='a'then state.ui=not state.ui
   elseif b=='dpup'then state.cursor=(state.cursor-2)%#rows+1
   elseif b=='dpdown'then state.cursor=state.cursor%#rows+1
   elseif b=='dpleft'then adjust(-1)
   elseif b=='dpright'then adjust(1)end
  end
 end
 local function update(nextFn,g,dt)
  if not state.open or g~=game then return nextFn(g,dt)end
  if Map.current~=state.map or Battle.isActive()or not S.enabled then close();return nextFn(g,dt)end
  dt=math.max(0,math.min(.1,dt or 0));g.input:reset()
  local dx=(held.right and 1 or 0)-(held.left and 1 or 0)+(axes.leftx or 0)
  local dz=(held.down and 1 or 0)-(held.up and 1 or 0)+(axes.lefty or 0)
  view.offsetX=math.max(-2048,math.min(2048,view.offsetX+dx*80*dt))
  view.offsetZ=math.max(-2048,math.min(2048,view.offsetZ+dz*80*dt))
  view.zoomMul=math.max(.5,math.min(3,view.zoomMul+((held.e and 1 or 0)-(held.q and 1 or 0)-(axes.righty or 0))*.8*dt))
  view.elevationDegrees=math.max(20,math.min(65,view.elevationDegrees+((held.r and 1 or 0)-(held.f and 1 or 0)+(axes.rightx or 0))*25*dt))
 end
 local function camera(previous,ctx)
  if not state.open or ctx.game~=game or ctx.presentation then return previous end
  C.post.enabled=true;C.post.depthOfField=state.strength>0 or state.tilt>0;C.post.coc.enabled=true
  C.post.coc.near=state.strength;C.post.coc.far=state.strength*.6;C.post.coc.tiltAmount=state.tilt
  C.post.vignette=state.vignette>0;C.post.vignetteStrength=state.vignette
  return view
 end
 local function focusPoint(previous,ctx)
  if not state.open then return previous end
  local length=0;for i=1,3 do focus[i]=ctx.target[i]-ctx.eye[i];length=length+focus[i]^2 end
  length=math.sqrt(length);if length<.001 then return previous end
  for i=1,3 do focus[i]=previous[i]+focus[i]/length*state.focus end;return focus
 end
 local function beforeFinish(canvas,ctx)
  if state.open and state.grade>1 then
   local G=V.require('ColorGrade')
   if G.prepare()then lut.a=G.images[grades[state.grade]];lut.b=lut.a;lut.identity=G.identity[grades[state.grade]];ctx.lutOverride=lut end
  end
  return canvas
 end
 local function afterFinish(canvas,ctx)
  if not ctx.presentation then frame=canvas end
  if ctx.lutOverride==lut then ctx.lutOverride=nil end
  return canvas
 end
 local function export(viewport)
  state.pendingExport=false;local started=love.timer.getTime();local data
  local w,h=viewport.width,viewport.height;local scale=state.scale
  local limit=love.graphics.getSystemLimits().texturesize
  if w*scale>limit or h*scale>limit then state.message=L.text('Export too large for this device','Export zu gross fuer dieses Geraet');return end
  love.graphics.push('all')
  local ok,err=pcall(function()
   local R=V.require('Renderer')
   local output=R.draw(game,w,h,'paper',C.settings.presets[V.mod.options:get('gen3Quality')or'high'].neighbors,math.floor(w*scale),math.floor(h*scale))
   assert(output and not R.buildPending,L.text('Map is still loading; try the photo again','Karte wird noch vorbereitet; Foto erneut ausloesen'))
   state.exportRenderMs=(love.timer.getTime()-started)*1000;local part=love.timer.getTime()
   data=output:newImageData()
   state.exportReadMs=(love.timer.getTime()-part)*1000
   assert(love.filesystem.createDirectory('screenshots'))
   local path='screenshots/'..tostring(state.map):gsub('[^%w_-]','_')..'-'..os.date('%Y%m%d-%H%M%S')..'-'..tostring(state.exports+1)..'.png'
   -- ImageData:encode(filename) bypasses the host's virtual filesystem. Encode
   -- in memory, then write through the same sandbox API as mkdir.
   part=love.timer.getTime();local encoded=V.require('cards/PhotoPng').encode(data);state.exportEncodeMs=(love.timer.getTime()-part)*1000
   part=love.timer.getTime();local written,why=love.filesystem.write(path,encoded)
   state.exportWriteMs=(love.timer.getTime()-part)*1000
   assert(written,why)
   state.exports=state.exports+1;state.lastPath=path;state.exportWidth,state.exportHeight=data:getDimensions()
  end)
  if data then data:release()end;love.graphics.pop()
  state.exportMs=(love.timer.getTime()-started)*1000
  state.message=ok and(L.text('Saved: ','Gesichert: ')..state.lastPath)or tostring(err)
 end
 local function panel(w,h)
  local g=love.graphics
  if not font then font=g.newFont(16);state.resources=1 end
  if not style then style=V.require('VascMenuStyle').new(V.mod,{edition='firered'}).colors end
  g.setFont(font);local width=math.min(390,w-24);local x,y=w-width-12,12
  g.setColor(style.glass);g.rectangle('fill',x,y,width,math.min(h-24,358),8,8)
  g.setColor(style.glassLine);g.rectangle('line',x,y,width,math.min(h-24,358),8,8)
  g.setColor(style.glassText);g.print(L.text('ORIGAMI · PHOTO MODE','ORIGAMI · FOTOMODUS'),x+12,y+10)
  local hour=state.time/Day.CYCLE*24
  local values={string.format('%02d:%02d',math.floor(hour),math.floor(hour%1*60)),choices[state.weather],tostring(state.focus),string.format('%.1f',state.strength),string.format('%.1f',state.tilt),string.format('%.2f',state.vignette),grades[state.grade],state.scale..'x'}
  for i,label in ipairs(rows)do
   g.setColor(i==state.cursor and style.glassGold or style.glassText)
   g.print((i==state.cursor and'> 'or'  ')..L.text(({'Time','Weather','Focus distance','Depth blur','Tilt-shift','Vignette','Colour grade','Export size'})[i],label)..': '..values[i],x+12,y+34+i*24)
  end
  g.setColor(style.glassMuted)
  g.printf(L.text('Arrows: camera · Q/E: zoom · R/F: tilt\n[ / ]: row · - / +: value\nEnter: photo · Tab: UI · F8/Esc: back','Pfeile: Kamera · Q/E: Zoom · R/F: Neigung\n[ / ]: Zeile · - / +: Wert\nEnter: Foto · Tab: UI · F8/Esc: zurueck'),x+12,y+260,width-24)
  if state.message then
   local _,lines=font:getWrap(state.message,w-48);local height=#lines*font:getHeight()+16
   g.setColor(style.glass);g.rectangle('fill',12,h-height-12,w-24,height,8,8)
   g.setColor(style.glassGold);g.printf(state.message,24,h-height-4,w-48)
  end
 end
 local function hud(nextFn,g,viewport)
  if not state.open or g~=game then return nextFn(g,viewport)end
  if state.pendingExport then export(viewport)end
  love.graphics.push('all');local ok,err=pcall(function()
   local graphics=love.graphics;graphics.origin();graphics.setScissor();graphics.setShader();graphics.setDepthMode();graphics.setColor(1,1,1,1)
   graphics.setBlendMode('replace','premultiplied');graphics.draw(frame,0,0,0,viewport.width/frame:getWidth(),viewport.height/frame:getHeight())
   graphics.setBlendMode('alpha');if state.ui then
    local scale=math.min(1,viewport.width/430,viewport.height/420);graphics.scale(scale)
    panel(viewport.width/scale,viewport.height/scale)
   end
  end);love.graphics.pop()
  if not ok then state.error=tostring(err);close();return nextFn(g,viewport)end
 end
 local function deactivate()
  close();for i=#unsubs,1,-1 do unsubs[i]();unsubs[i]=nil end;S.unregister(Card.ID)
  V.require('GeometryConfig').unregisterPresentation(Card.ID)
  if font then font:release();font=nil end;frame=nil;style=nil;state.resources=0;state.active=false
  if C.cards then C.cards.photoMode=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name];if p and p.cards then p.cards.photoMode=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end end
  presets={};return true
 end
 return{schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_photo_mode_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/PHOTO_MODE.md'},
  impact={runtimeOwners={'gen3.render.photo-mode'},saveWrites={},publicHooks={'input.key','input.gamepad','core.update','render.hud'},files={'gen3/lib/cards/PhotoModeCard.lua','gen3/lib/cards/PhotoPng.lua','gen3/cards/PHOTO_MODE.md'}},
  lifecycle={install=function()return{installed=V.mod.hooks and type(V.mod.hooks.wrap)=='function'}end,
   activate=function(_,installed)
    if not installed or not installed.installed then return false,'public input/update hooks unavailable'end
    if state.active then return state,{isOpen=function()return state.open end}end
    C.cards=C.cards or{};C.cards.photoMode=C.cards.photoMode or{enabled=true,key='f8',maxScale=4}
    V.require('GeometryConfig').registerPresentation(Card.ID,'photoMode',{'enabled','key','maxScale'})
    for name,p in pairs(C.settings.presets)do presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.photoMode};p.cards=p.cards or{};if p.cards.photoMode==nil then p.cards.photoMode={enabled=name~='off'} end end
    state.active=true;S.register(Card.ID,'camera',camera,100000);S.register(Card.ID,'focusPoint',focusPoint,100000)
    S.register(Card.ID,'beforeFinish',beforeFinish,100000);S.register(Card.ID,'afterFinish',afterFinish,100000)
    S.register(Card.ID,'release',function()close();frame=nil end)
    unsubs[#unsubs+1]=V.mod.hooks:wrap('input.key',key,1000);unsubs[#unsubs+1]=V.mod.hooks:wrap('input.gamepad',pad,1000)
    unsubs[#unsubs+1]=V.mod.hooks:wrap('core.update',update,1000);unsubs[#unsubs+1]=V.mod.hooks:wrap('render.hud',hud,1000)
    return state,{isOpen=function()return state.open end}
   end,deactivate=deactivate,abort=deactivate,health=function()
    local h={ok=not state.error};for k,v in pairs(state)do h[k]=v end
    h.zoom,h.panX,h.panZ,h.elevation=view.zoomMul,view.offsetX,view.offsetZ,view.elevationDegrees
    return h
   end}}
end
return Card
