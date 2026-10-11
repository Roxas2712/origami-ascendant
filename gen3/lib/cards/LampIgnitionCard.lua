local Card={ID='oasc.gen3.lamp-ignition',VERSION='1.0.0',CAPABILITY='ascendant.lamp-ignition.gen3/v1'}
Card.option={key='gen3Card_lampIgnition',label='LAMPENSTART',type='toggle',default=true,
 help='Fenster gehen zur Daemmerung zeitversetzt sanft heller an. Unabhaengig von der Kamera.'}
-- One cycle second is one displayed night minute. Dusk starts at dial 600
-- (18:00); spread 90 finishes at 19:30. Never start an arrival-local timer.
function Card.seed(code)
 if type(code)~='number'then return nil end
 local base=code>=.625 and code<.75 and .625 or code>=.125 and code<.25 and .125
 return base and math.floor((code-base)*131072+.5)or nil
end
function Card.factor(seed,dial,spread,flicker)
 if seed==nil then return 1 end
 dial=dial%1200;if dial<300 then return 1 end
 local elapsed=dial-600-((seed*73+19)%997)/997*spread
 if elapsed<0 then return 0 end
 local u=math.min(1,elapsed/math.max(.001,flicker*.25))
 return u*u*(3-2*u)
end
Card.uniforms=[[
uniform vec4 oasc_ignition_params; // dusk elapsed, spread, fade duration / .25, enabled
float oasc_ignition_factor(float seed){
 if(oasc_ignition_params.w<.5 || seed<0.0)return 1.0;
 float elapsed=oasc_ignition_params.x-mod(seed*73.0+19.0,997.0)/997.0*oasc_ignition_params.y;
 if(elapsed<0.0)return 0.0;
 return smoothstep(0.0,max(.001,oasc_ignition_params.z*.25),elapsed);
}
float oasc_ignition_pane(float code){
 bool textured=code>=.625 && code<.75;bool flatPane=code>=.125 && code<.25;
 if(!(textured || flatPane))return 1.0;
 return oasc_ignition_factor(floor((code-(textured?.625:.125))*131072.0+.5));
}
]]
Card.static='color.a*=oasc_ignition_factor(abs(params.w-.5)-1.5);params.w=step(.5,params.w);'
Card.window='lamp.a*=oasc_ignition_pane(windowVariationCode);'
function Card.descriptor(V)
 local S,U,C,G=V.require('core/RenderSeams'),V.require('UniformState'),V.require('DioramaConfig'),V.require('GeometryConfig')
 local state={active=false,resources=0,sources=0,uploads=0};local presets={};local cache={};local serial=0
 local params={0,90,12,0};local Grid=V.require('StaticLightGrid');local previousFilter,filter
 local function invalidate()
  for _,grid in pairs(Grid.cache)do grid.bucket=nil end
 end
 local function release()
  for grid,e in pairs(cache)do e.data:release();cache[grid]=nil end
  state.resources=0;state.sources=0
 end
 filter=function(data,lights,grid)
  if previousFilter then data=previousFilter(data,lights,grid)or data end
  serial=serial+1;local e=cache[grid]
  if not e then
   e={data=love.image.newImageData(data:getWidth(),data:getHeight(),'rgba32f'),seeds={},tagged=0}
   for i,l in ipairs(lights)do
    local seed=not l.spatial and Card.seed(l.variationCode)or nil
    e.seeds[i]=seed or -1;if seed~=nil then e.tagged=e.tagged+1 end
   end
   cache[grid]=e;state.resources=state.resources+1
   if state.resources>4 then
    local oldest,age
    for key,row in pairs(cache)do if key~=grid and(not age or row.used<age)then oldest,age=key,row.used end end
    cache[oldest].data:release();cache[oldest]=nil;state.resources=state.resources-1
   end
  end
  -- Preserve the native >.5 point predicate even if a shader consumer fails.
  -- Tagged facade flags become -(seed+1); tagged point flags become seed+2.
  -- The owned copy needs no added sampler, draw or GPU upload.
  e.data:paste(data,0,0,0,0,data:getWidth(),data:getHeight())
  for i,seed in ipairs(e.seeds)do
   local r,g,b,point=data:getPixel(2,i-1);e.data:setPixel(2,i-1,r,g,b,seed<0 and point or point>.5 and seed+2 or -seed-1)
  end
  e.used=serial;state.sources=e.tagged;state.uploads=state.uploads+1
  return e.data
 end
 local function prepare(ctx)
  local c=C.cards and C.cards.lampIgnition
  local preset=(C.settings.presets[V.mod.options:get('gen3Quality')or C.settings.defaultPreset]or{}).cards
  params[4]=ctx.outdoors and c and c.enabled~=false and not(preset and type(preset.lampIgnition)=='table'and preset.lampIgnition.enabled==false)and 1 or 0
  local dial=V.require('DayNight').time()%1200
  params[1]=dial<300 and 1200 or dial-600
  params[2]=math.min(180,math.max(0,tonumber(c and c.spread)or 90))
  params[3]=math.min(12,math.max(0,math.floor(tonumber(c and c.flicker)or 12)))
 end
 local function bind(shader,ctx)
  local e=ctx.lights and cache[ctx.lights.staticGrid];state.sources=e and e.tagged or 0
  U.send(shader,'oasc_ignition_params',params)

 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID)
  if Grid.dataFilter==filter then Grid.dataFilter=previousFilter end
  previousFilter=nil;invalidate();release();state.active=false
  if C.cards then C.cards.lampIgnition=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name]
   if p and p.cards then p.cards.lampIgnition=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end
  end
  presets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',
  requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_lamp_ignition_test.lua','tests/gen3_lamp_ignition_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/LAMP_IGNITION.md'},
  impact={runtimeOwners={'gen3.render.lamp-ignition'},saveWrites={},publicHooks={},
   files={'gen3/lib/cards/LampIgnitionCard.lua','gen3/cards/LAMP_IGNITION.md'}},
  lifecycle={install=function()return {installed=true}end,
   activate=function()
    if state.active then return state end
    G.registerPresentation(Card.ID,'lampIgnition',{'enabled','spread','flicker'})
    C.cards=C.cards or{};C.cards.lampIgnition=C.cards.lampIgnition or{enabled=true,spread=90,flicker=12}
    for name,p in pairs(C.settings.presets)do
     presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.lampIgnition}
     p.cards=p.cards or{};if p.cards.lampIgnition==nil then p.cards.lampIgnition={enabled=name~='off'} end
    end
    previousFilter=Grid.dataFilter;Grid.dataFilter=filter;invalidate()
    S.register(Card.ID,'main.uniforms',Card.uniforms)
    S.register(Card.ID,'main.light.static',Card.static);S.register(Card.ID,'main.light.window',Card.window)
    S.register(Card.ID,'prepare',prepare);S.register(Card.ID,'bind',bind);S.register(Card.ID,'release',release)
    state.active=true;return state,{isActive=function()return state.active end}
   end,deactivate=deactivate,abort=deactivate,
   health=function()local h=S.health(Card.ID);h.active=state.active;h.resources=state.resources;h.sources=state.sources
    h.catalogueUploads=state.uploads;h.gpuTimeAvailable=false;return h end}}
end
return Card
