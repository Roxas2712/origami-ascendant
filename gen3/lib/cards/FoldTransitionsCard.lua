local Card={ID='oasc.gen3.fold-transitions',VERSION='1.0.0',CAPABILITY='ascendant.fold-transitions.gen3/v1'}
Card.option={key='gen3Card_foldTransitions',label='FALT-UEBERGAENGE',type='toggle',default=true,
 help='Alte Karte zusammenfalten, neue Karte entfalten. Kaempfe bleiben unveraendert.'}
function Card.descriptor(V)
 local C,S,G=V.require('DioramaConfig'),V.require('core/RenderSeams'),V.require('GeometryConfig')
 local Fold=V.require('cards/FoldMesh')
 local state={active=false,phase='idle',resources=0,warps=0,completed=0,drawMs=0,maxDrawMs=0}
 local unsubs,presets={},{};local source,sourceMap,sourceGame,snapshot,mesh,rows,paperShader
 local Warp,Fade,Map,Battle,Transition
 local function clock()return(V.clock or love.timer.getTime)()end
 local function reset()
  if V.loaded and V.loaded.FieldHandoff then V.loaded.FieldHandoff.foldVisible=false end
  if snapshot then snapshot:release();snapshot=nil end
  if mesh then mesh:release();mesh=nil end
  if paperShader then paperShader:release();paperShader=nil end
  rows=nil;state.phase='idle';state.resources=0;state.fromMap,state.toMap,state.started,state.armed,state.closedAt=nil,nil,nil,nil,nil
 end
 local function allowed()
  local c=C.cards and C.cards.foldTransitions
  local p=C.settings.presets[V.mod.options:get('gen3Quality')or C.settings.defaultPreset]
  local policy=p and p.cards and p.cards.foldTransitions
  local preview=package.loaded['src.ui.game3.map_preview_screen']
  local stack=package.loaded['src.ui.game3.stack']
  return state.active and not state.error and S.enabled and c and c.enabled~=false
   and not(preview and preview.isActive())and not(stack and stack.fullscreen())
   and not(type(policy)=='table'and policy.enabled==false)and not Battle.isActive()and not Transition.isActive()
 end
 local function copy(canvas)
  local started=love.timer.getTime()
  local g=love.graphics;local w,h=canvas:getDimensions()
  if snapshot then snapshot:release();snapshot=nil end
  snapshot=g.newCanvas(w,h,{dpiscale=1});snapshot:setFilter('nearest','nearest')
  if not mesh then rows=Fold.rows();mesh=g.newMesh(rows,'triangles','stream')end
  state.resources=paperShader and 3 or 2
  g.push('all')
  local ok,err=pcall(function()
   g.setCanvas(snapshot);g.origin();g.setScissor();g.setShader();g.setDepthMode();g.setColorMask(true,true,true,true)
   g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1);g.draw(canvas)
  end)
  g.pop();if not ok then error(err,0)end
  mesh:setTexture(snapshot)
  state.captureMs=(love.timer.getTime()-started)*1000
  state.maxCaptureMs=math.max(state.maxCaptureMs or 0,state.captureMs)
 end
 local function fail(err)
  reset();state.error=tostring(err)
  if V.mod.log then V.mod.log:warn('Fold transitions disabled: %s',state.error)end
 end
 local function finished(canvas,ctx)
  if not ctx.game or ctx.presentation or not allowed()then
   if state.phase~='idle'then reset()end
   source,sourceMap,sourceGame=nil,nil,nil;return canvas
  end
  source,sourceMap,sourceGame=canvas,ctx.id,ctx.game
  if state.phase=='armed'then
   if ctx.id~=state.fromMap or clock()-state.armed>15 then reset()
   elseif Fade.isActive()and Fade._dir>0 then
    local ok,err=pcall(copy,canvas)
    if not ok then fail(err)else state.phase='closing';state.started=clock()end
   end
  end
  return canvas
 end
 local function destination(nextFn,map,x,y,ctx)
  local m,nx,ny=nextFn(map,x,y,ctx)
  if allowed()and source and ctx and ctx.lastMap==sourceMap and type(m)=='string'
   and(sourceMap:match('^FR_')or sourceMap:match('^SEVII_')or sourceMap:match('^EM_'))then
   local c=C.cards.foldTransitions;local kind=ctx.warp and ctx.warp.kind
   local door=kind=='door'or kind=='exit_door'
   if(door and c.doors~=false)or(not door and c.maps~=false)then
    reset();state.fromMap,state.toMap=ctx.lastMap,m
    state.phase='armed';state.armed=clock();state.warps=state.warps+1;state.shape=Fold.choose(ctx.lastMap,m,state.warps)
   end
  end
  return m,nx,ny
 end
 local function draw(game,viewport)
  if state.phase=='idle'or state.phase=='armed'then return end
  if game~=sourceGame or not allowed()then reset();return end
  local now=clock();local duration=math.max(.05,math.min(1,C.cards.foldTransitions.duration or .55))
  local age=math.max(0,now-state.started)/duration
  if state.phase=='closing'and age>=1 then
   -- Start the hold only once the fully folded model has been drawn. A fast
   -- map load or a stalled frame must never skip the recognizable end pose.
   if not state.closedAt then state.closedAt=now end
   if now-state.closedAt>=.40 and sourceMap==state.toMap and Map.current==state.toMap and not V.require('Renderer').buildPending then
    copy(source);state.phase='opening';state.started=now;age=0
   elseif now-state.started>15 then reset();return end
  elseif state.phase=='opening'and age>=1 then state.completed=state.completed+1;reset();return end
  local amount=state.phase=='closing'and math.min(1,age)or 1-math.min(1,age)
  -- OASC field rendering fills the host surface. gameWidth/gameHeight describe
  -- the native 240x160 UI fit and would leave an unfurled strip on tall windows.
  local w,h=viewport.width,viewport.height
  state.foldAmount=amount
  Fold.update(rows,w,h,amount,state.shape);mesh:setVertices(rows)
  if V.loaded then V.require('FieldHandoff').foldVisible=true end
  local g=love.graphics;g.origin();g.setShader();g.setDepthMode();g.setMeshCullMode('none')
  g.setScissor(0,0,w,h);g.setBlendMode('alpha','alphamultiply')
  g.setColor(0,0,0,1);g.rectangle('fill',0,0,w,h)
  if not paperShader then paperShader=g.newShader([[uniform float foldAmount;
   vec4 effect(vec4 color,Image sheet,vec2 uv,vec2 screen){vec4 p=Texel(sheet,uv);
    return vec4(mix(p.rgb,vec3(.92,.94,.98),foldAmount*.85),mix(p.a,1.0,foldAmount))*color;}]])end
  state.resources=3
  paperShader:send('foldAmount',amount);g.setShader(paperShader)
  g.setColor(1,1,1,1);g.draw(mesh);g.setShader();Fold.details(w,h,amount,state.shape)
 end
 local function hud(nextFn,game,viewport)
  nextFn(game,viewport)
  if state.phase=='idle'or state.phase=='armed'then return end
  local started=love.timer.getTime();love.graphics.push('all')
  local ok,err=pcall(draw,game,viewport);love.graphics.pop()
  state.drawMs=(love.timer.getTime()-started)*1000;state.maxDrawMs=math.max(state.maxDrawMs,state.drawMs)
  local log=V.loaded and V.loaded.PerformanceLog;if log then log.record('card '..Card.ID,state.drawMs/1000)end
  if not ok then fail(err)end
 end
 local function input(nextFn,game,dt)
  -- Native tasks/door callbacks keep running. Only player input waits for the
  -- visible sheet to finish; no save, warp, fade or battle state is modified.
  if game==sourceGame and(state.phase=='closing'or state.phase=='opening')and allowed()then game.input:reset()end
  return nextFn(game,dt)
 end
 local function deactivate()
  for i=#unsubs,1,-1 do unsubs[i]();unsubs[i]=nil end
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);reset();source,sourceMap,sourceGame=nil,nil,nil
  state.active=false;state.error=nil
  if C.cards then C.cards.foldTransitions=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name]
   if p and p.cards then p.cards.foldTransitions=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end
  end
  presets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_fold_transitions_test.lua','tests/gen3_fold_transitions_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/FOLD_TRANSITIONS.md'},
  impact={runtimeOwners={'gen3.render.fold-transitions'},saveWrites={},publicHooks={'warp.destination','render.hud','core.update'},files={'gen3/lib/cards/FoldTransitionsCard.lua','gen3/lib/cards/FoldMesh.lua','gen3/cards/FOLD_TRANSITIONS.md'}},
  lifecycle={install=function()
   local ok=pcall(function()
    Warp=require('src.core.game3.warp');Fade=require('src.ui.game3.fade');Map=require('src.core.game3.map')
    Battle=require('src.core.game3.battle');Transition=require('src.core.game3.battle_transition')
    assert(V.mod.hooks and type(V.mod.hooks.wrap)=='function'and type(Warp.request)=='function'
     and type(Fade.isActive)=='function'and type(Battle.isActive)=='function'and type(Transition.isActive)=='function')
   end)
   state.available=ok
   return{installed=ok,reason=not ok and'Gen3 warp/render hook adapter unavailable'or nil}
  end,activate=function(_,installed)
   if not state.available then return false,installed and installed.reason or'warp hooks unavailable'end
   if state.active then return state end
   C.cards=C.cards or{};C.cards.foldTransitions=C.cards.foldTransitions or{enabled=true,duration=.55,doors=true,maps=true}
   G.registerPresentation(Card.ID,'foldTransitions',{'enabled','duration','doors','maps'})
   for name,p in pairs(C.settings.presets)do presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.foldTransitions};p.cards=p.cards or{};if p.cards.foldTransitions==nil then p.cards.foldTransitions={enabled=name~='off'and name~='low'} end end
   state.active=true;S.register(Card.ID,'afterFinish',finished,10000)
   S.register(Card.ID,'release',function()reset();source,sourceMap,sourceGame=nil,nil,nil end)
   unsubs[#unsubs+1]=V.mod.hooks:wrap('warp.destination',destination)
   unsubs[#unsubs+1]=V.mod.hooks:wrap('render.hud',hud,-100)
   unsubs[#unsubs+1]=V.mod.hooks:wrap('core.update',input,100)
   return state,{isActive=function()return state.active end}
  end,deactivate=deactivate,abort=deactivate,health=function()
   local h=S.health(Card.ID);for k,v in pairs(state)do h[k]=v end;h.ok=h.ok and not state.error;return h
  end}}
end
return Card
