local Card={ID='oasc.gen3.camera-drama',VERSION='1.0.0',CAPABILITY='ascendant.camera-drama.gen3/v1'}
Card.option={key='gen3Card_cameraDrama',label='KAMERA-BEWEGUNG',type='toggle',default=true,
 help='Sanftes Nachfuehren, Dialog-Zoom und kurzer Stadt-Auftritt.'}
local function smooth(t)return 1-(1-math.max(0,math.min(1,t)))^3 end
local function spring(x,v,target,dt)
 local delta=x-target;local j=v+8*delta;local e=math.exp(-8*dt)
 local n=target+(delta+j*dt)*e
 if (x-target)*(n-target)<0 then return target,0 end
 return n,(v-8*j*dt)*e
end
function Card.descriptor(V)
 local C,S,G,Camera=V.require('DioramaConfig'),V.require('core/RenderSeams'),V.require('GeometryConfig'),V.require('Camera')
 local Message=require('src.ui.game3.message');local Stack=require('src.ui.game3.stack')
 local Battle=require('src.core.game3.battle');local Objects=require('src.core.game3.objects')
 local state={active=false};local presets={}
 local override={zoomMul=1,offsetX=0,offsetZ=0,shakeX=0,shakeZ=0}
 local function reset()
  if Camera.override==override then Camera.override=nil end
  state.map,state.time,state.x,state.z=nil,nil,nil,nil
  state.vx,state.vz,state.zoom,state.zoomFrom,state.zoomTarget,state.zoomAge=0,0,1,1,1,.4
  state.cityAge,state.dialog,state.enabled=1,false,false
  override.zoomMul,override.offsetX,override.offsetZ=1,0,0
 end
 local function prepare(previous,ctx)
  local c=C.cards and C.cards.cameraDrama
  local quality=V.mod.options:get('gen3Quality')or C.settings.defaultPreset
  local p=C.settings.presets[quality];local policy=p and p.cards and p.cards.cameraDrama
  if not c or c.enabled==false or policy and policy.enabled==false or ctx.presentation or Battle.isActive()
   or not(ctx.id:match('^FR_')or ctx.id:match('^EM_')or ctx.id:match('^SEVII_'))then reset();return previous end
  local player=ctx.player
  if Camera.nativeFocus(player,Objects)~=player then reset();return previous end
  local now=(V.clock or love.timer.getTime)();local dt=state.time and math.max(0,math.min(.1,now-state.time))or 0
  local changed=state.map~=ctx.id
  if changed then
   reset();state.map=ctx.id;state.x,state.z=player.px,player.py
   local kind=tonumber(ctx.def.mapType)
   state.cityAge=c.cityPullout~=false and(kind==1 or kind==2)and 0 or 1
   dt=0
  end
  state.time=now;state.enabled=true
  -- Gen3 field text is not a Stack layer. Read its actual printer state;
  -- an unrelated bag/start-menu layer must never trigger a dialog zoom.
  local dialog=Message.isOpen()and not Stack.fullscreen()
  local wanted=dialog and math.max(1,math.min(1.5,c.dialogZoom or 1.12))or 1
  if wanted~=state.zoomTarget then state.zoomFrom=state.zoom;state.zoomTarget=wanted;state.zoomAge=0 end
  state.zoomAge=math.min(.4,state.zoomAge+dt)
  state.zoom=state.zoomFrom+(wanted-state.zoomFrom)*smooth(state.zoomAge/.4)
  state.cityAge=math.min(.8,state.cityAge+dt)
  local zoom=state.zoom*(.92+.08*smooth(state.cityAge/.8))
  -- Pixel aspect is handled by the billboard projection. Quantizing the
  -- continuous camera tween to 1/8 made a dialog/city entrance jump.
  if C.billboards.preservePixelAspect then zoom=math.floor(zoom*64+.5)/64 end
  override.zoomMul=zoom
  local dx,dz=player.px-state.x,player.py-state.z;state.x,state.z=player.px,player.py
  local distance=math.sqrt(dx*dx+dz*dz);local tx,tz=0,0
  if distance>32 then override.offsetX,override.offsetZ,state.vx,state.vz=0,0,0,0
  elseif distance>.001 and not dialog and not Stack.busy()then
   local lead=math.max(0,math.min(16,c.lead or 6));tx,tz=dx/distance*lead,dz/distance*lead
  end
  override.offsetX,state.vx=spring(override.offsetX,state.vx,tx,dt)
  override.offsetZ,state.vz=spring(override.offsetZ,state.vz,tz,dt)
  state.dialog=not not dialog
  return override
 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);reset();state.active=false
  if C.cards then C.cards.cameraDrama=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name]
   if p and p.cards then p.cards.cameraDrama=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end
  end
  presets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_camera_drama_test.lua','tests/gen3_camera_drama_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/CAMERA_DRAMA.md'},
  impact={runtimeOwners={'gen3.render.camera-drama'},saveWrites={},publicHooks={},files={'gen3/lib/cards/CameraDramaCard.lua','gen3/cards/CAMERA_DRAMA.md'}},
  lifecycle={install=function()return{installed=true}end,activate=function()
   if state.active then return state end
   C.cards=C.cards or{};C.cards.cameraDrama=C.cards.cameraDrama or{enabled=true,dialogZoom=1.12,lead=6,cityPullout=true,shake=false}
   G.registerPresentation(Card.ID,'cameraDrama',{'enabled','dialogZoom','lead','cityPullout','shake'})
   for name,p in pairs(C.settings.presets)do presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.cameraDrama};p.cards=p.cards or{};p.cards.cameraDrama=p.cards.cameraDrama or{enabled=name~='off'and name~='low'}end
   reset();state.active=true;S.register(Card.ID,'camera',prepare);S.register(Card.ID,'release',reset)
   return state,{isActive=function()return state.active end}
  end,deactivate=deactivate,abort=deactivate,health=function()
   local h=S.health(Card.ID);for k,v in pairs(state)do h[k]=v end
   h.zoomMul,h.offsetX,h.offsetZ=override.zoomMul,override.offsetX,override.offsetZ
   h.shakeAvailable=false;return h
  end}}
end
return Card
