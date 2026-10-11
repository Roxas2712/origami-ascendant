local V=...
local Card={ID='oasc.gen3.water-touch',VERSION='1.0.0',CAPABILITY='ascendant.water-touch.gen3/v1'}
Card.option={key='gen3Card_waterTouch',label='WASSERKONTAKT',type='toggle',default=true,
 help='Ringwellen beim Surfen, Regenringe und bewegter Ufersaum. Trockenes ruhiges Wasser bleibt unveraendert.'}
Card.uniforms=[[
uniform vec4 oasc_water_params; // seconds, enabled, rain, foam
uniform vec4 oasc_water_ripple[12]; // world x/z, birth seconds, signed amplitude
uniform vec2 oasc_water_size;
varying vec2 oasc_water_cell;
varying vec2 oasc_water_code;
#ifdef VERTEX
uniform Image oasc_water_shore;
uniform vec2 oasc_water_atlas;
#endif
]]
Card.vertex=[[
// Native water quads use the metatile's UV orientation. An inward epsilon
// assigns all six tile vertices to the same tile, including shared borders.
vec2 oasc_water_corner=fract(VertexTexCoord.xy*oasc_water_atlas/16.0);
vec2 oasc_water_grid=floor((vertex_position.xz+(vec2(.5)-oasc_water_corner)*.02)/16.0);
oasc_water_cell=oasc_water_grid*16.0;
oasc_water_code=vec2(0.0);
if(VertexShade>=3.5 && VertexShade<4.5 && oasc_water_params.y>.5 &&
 all(greaterThanEqual(oasc_water_grid,vec2(0.0))) && all(lessThan(oasc_water_grid,oasc_water_size))){
 oasc_water_code=vec2(floor(Texel(oasc_water_shore,(oasc_water_grid+.5)/oasc_water_size).r*255.0+.5),1.0);
}
]]
Card.functions=[[
float oasc_water_bit(float code,float weight){return mod(floor(code/weight),2.0);}
float oasc_water_bank(vec2 p,float code){
 code=floor(code+.5); // recover integer bits after perspective interpolation
 float d=32.0;
 if(oasc_water_bit(code,1.0)>.5)d=min(d,p.x);
 if(oasc_water_bit(code,2.0)>.5)d=min(d,16.0-p.x);
 if(oasc_water_bit(code,4.0)>.5)d=min(d,p.y);
 if(oasc_water_bit(code,8.0)>.5)d=min(d,16.0-p.y);
 if(oasc_water_bit(code,16.0)>.5)d=min(d,length(p));
 if(oasc_water_bit(code,32.0)>.5)d=min(d,length(p-vec2(16.0,0.0)));
 if(oasc_water_bit(code,64.0)>.5)d=min(d,length(p-vec2(0.0,16.0)));
 if(oasc_water_bit(code,128.0)>.5)d=min(d,length(p-vec2(16.0)));
 return d;
}
]]
Card.fragment=[[
if(waterFace>.5 && oasc_water_params.y>.5){
 float oasc_water_energy=0.0,oasc_water_motion=0.0;
 for(int oasc_water_i=0;oasc_water_i<12;oasc_water_i++){
  vec4 p=oasc_water_ripple[oasc_water_i];float t=oasc_water_params.x-p.z;
  float life=p.w<0.0?.6:1.6;
  if(p.w!=0.0 && t>=0.0 && t<life){
   float r=length(worldPosition.xz-p.xy);
   float front=exp(-pow((r-t*14.0)/2.0,2.0));
   float fade=(1.0-t/life)*(1.0-t/life);
   oasc_water_energy+=front*sin(r*.9-t*6.0)*fade*abs(p.w);
   oasc_water_motion=max(oasc_water_motion,fade*exp(-r*.05)*abs(p.w));
  }
 }
 // Modulate existing illumination rather than emitting white light at night.
 lit*=1.0+oasc_water_energy*.16;
 if(oasc_water_code.y>.5){
  float bank=1.0-smoothstep(0.0,6.0,oasc_water_bank(clamp(worldPosition.xz-oasc_water_cell,0.0,16.0),oasc_water_code.x));
  float noise=.5+.5*sin(worldPosition.x*.37+oasc_water_params.x*1.7)*sin(worldPosition.z*.41-oasc_water_params.x*.9);
  float foam=bank*noise*oasc_water_params.w*max(oasc_water_params.z,oasc_water_motion);
  lit=mix(lit,lit*1.35+vec3(dot(lit,vec3(.2126,.7152,.0722)))*.25,foam*.5);
 }
}
]]
function Card.descriptor(V)
 local S,U,C,G=V.require('core/RenderSeams'),V.require('UniformState'),V.require('DioramaConfig'),V.require('GeometryConfig')
 local Maps=V.require('cards/WaterTouchMap');local player=require('src.core.game3.player')
 local state={active=false,enabled=false,resources=0,ringCount=0,updateMs=0,buildMs=0,maxBuildMs=0};local presets={}
 local params={0,0,0,.5};local size={1,1};local atlas={1,1};local rings={}
 local weatherMap={}
 for i=1,12 do rings[i]={0,0,0,0}end
 local row,blank,previousX,previousZ,lastTime,surfCursor,rainCursor
 local function resetMotion()
  for _,r in ipairs(rings)do r[4]=0 end
  state.ringCount=0;state.rainEmitted=0
  previousX,previousZ,lastTime=nil,nil,nil;surfCursor,rainCursor=0,4
 end
 local function release()
  if row and row.texture then row.texture:release()end
  if blank then blank:release();blank=nil end
  row=nil;resetMotion();state.resources=0;state.enabled=false;params[2]=0
 end
 local function emit(slot,x,z,time,amplitude)
  local r=rings[slot];r[1],r[2],r[3],r[4]=x,z,time,amplitude
 end
 local function build(layout,mesh)
  if row and row.texture then row.texture:release()end
  row={layout=layout,mesh=mesh,revision=layout._revision,width=layout.width,height=layout.height}
  row.work=coroutine.create(function()
   local decorative=Maps.decorative(layout,mesh,coroutine.yield)
   local w,h,bytes,water=Maps.build(layout,coroutine.yield,decorative)
   local data=love.image.newImageData(w,h,'r8',bytes)
   local texture=love.graphics.newImage(data,{linear=true});data:release()
   texture:setFilter('nearest','nearest');texture:setWrap('clamp','clamp')
   row.texture,row.water,row.w,row.h,row.decorative=texture,water,w,h,decorative;size[1],size[2]=w,h
   row.decorativeCount=0;for _ in pairs(decorative)do row.decorativeCount=row.decorativeCount+1 end
  end)
  resetMotion();state.resources=blank and 1 or 0
 end
 local function prepare(ctx)
  local start=love.timer.getTime();local config=C.cards and C.cards.waterTouch
  local preset=C.settings.presets[V.mod.options:get('gen3Quality')or C.settings.defaultPreset]
  local policy=preset and preset.cards and preset.cards.waterTouch
  local layout=ctx.def and ctx.def.midLayout
  state.enabled=config and config.enabled~=false and not(type(policy)=='table'and policy.enabled==false)and layout~=nil and not state.error
  params[2]=0
  if not state.enabled then resetMotion();return end
  -- The renderer has already resolved/restored the actual current-map mesh.
  -- Rebuild on replacement as well as native layout edits, without modifying
  -- geometry caches, collision, atlas pixels or the renderer itself.
  local renderer=V.require('Renderer');local mesh
  for _,entry in pairs(renderer.cache or{})do
   local origin=entry.foliageOrigin
   if entry.def==ctx.def and entry.used==renderer.tick and origin and origin[1]==0 and origin[2]==0 then
    if entry.stats and entry.stats.waterReflectionBounds then mesh=entry.mesh end;break
   end
  end
  if not row or row.layout~=layout or row.mesh~=mesh or row.revision~=layout._revision or row.width~=layout.width or row.height~=layout.height then build(layout,mesh)end
  if row.work then
   repeat
    local ok,err=coroutine.resume(row.work);if not ok then error(err,0)end
    if coroutine.status(row.work)=='dead'then row.work=nil;state.resources=1+(blank and 1 or 0);break end
   until love.timer.getTime()-start>.00035
   state.buildMs=(love.timer.getTime()-start)*1000;state.maxBuildMs=math.max(state.maxBuildMs,state.buildMs)
  end
  local t=ctx.time or 0
  if lastTime and(t<lastTime or t-lastTime>2)then resetMotion()end
  weatherMap.id,weatherMap.def=ctx.id,ctx.def
  local mood=V.require('WeatherMood')
  local front=mood.sample(weatherMap)
  local rain=ctx.outdoors and(not C.weather or C.weather.enabled~=false)and mood.rainAmount(ctx.weatherMode,front)or 0
  params[1],params[2],params[3],params[4]=t,1,rain,math.max(0,math.min(1,tonumber(config.foam)or .5))
  local x,z=ctx.playerX or 0,(ctx.playerZ or 8)-8
  local cx,cz=math.floor(x/16),math.floor(z/16)
  if config.ripples~=false and not ctx.presentation and player.surfing and Maps.water(layout,cx,cz)and previousX and(cx~=previousX or cz~=previousZ)then
   surfCursor=surfCursor%4+1;emit(surfCursor,x,z,t,1)
  end
  previousX,previousZ=cx,cz
  -- Two fresh impacts per moving frame, four in a storm. Repeated draws at
  -- the same frozen time must not emit again (photo mode / rollback captures).
  -- The bounded rain pool replaces its oldest impacts before their .6 s
  -- maximum lifetime; surf slots remain independent so rain cannot erase wakes.
  state.rainEmitted=0
  if config.rainRings~=false and params[3]>0 and row.water and #row.water>0 and t~=lastTime then
   local tick=math.floor(t*60000)
   local count=(front and front.precipMode or ctx.weatherMode)=='storm'and 4 or 2
   for i=1,count do
    local seed=(tick*97+i*631)%65521;local cell=row.water[seed%#row.water+1]
    local point=row.decorative and row.decorative[cell]
    rainCursor=4+(rainCursor-3)%8
    emit(rainCursor,point and point.x or(cell%row.w)*16+2+(seed%13),point and point.z or math.floor(cell/row.w)*16+2+(math.floor(seed/17)%13),t,-.8*rain)
   end
   state.rainEmitted=count
  end
  lastTime=t;state.ringCount=0
  for _,r in ipairs(rings)do if r[4]~=0 and t-r[3]>=(r[4]<0 and .6 or 1.6)then r[4]=0 end;if r[4]~=0 then state.ringCount=state.ringCount+1 end end
  state.updateMs=(love.timer.getTime()-start)*1000
 end
 local function bind(shader)
  if not U.has(shader,'oasc_water_params')then return end
  if not blank then local d=love.image.newImageData(1,1,'r8');blank=love.graphics.newImage(d,{linear=true});d:release();state.resources=state.resources+1 end
  U.send(shader,'oasc_water_params',params);U.send(shader,'oasc_water_size',size)
  U.send(shader,'oasc_water_ripple',unpack(rings));U.send(shader,'oasc_water_shore',row and row.texture or blank)
  U.send(shader,'oasc_water_atlas',atlas)
 end
 local function texture(shader,source)
  if U.has(shader,'oasc_water_atlas')then atlas[1],atlas[2]=source:getPixelDimensions();U.send(shader,'oasc_water_atlas',atlas)end
 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);release();state.active=false;state.error=nil
  if C.cards then C.cards.waterTouch=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name];if p and p.cards then p.cards.waterTouch=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end end
  presets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_water_touch_test.lua','tests/gen3_water_touch_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/WATER_TOUCH.md'},
  impact={runtimeOwners={'gen3.render.water-touch'},saveWrites={},publicHooks={},files={'gen3/lib/cards/WaterTouchCard.lua','gen3/lib/cards/WaterTouchMap.lua','gen3/cards/WATER_TOUCH.md'}},
  lifecycle={install=function()return {installed=true}end,activate=function()
   if state.active then return state end
   C.cards=C.cards or{};C.cards.waterTouch=C.cards.waterTouch or{enabled=true,ripples=true,rainRings=true,foam=.5}
   G.registerPresentation(Card.ID,'waterTouch',{'enabled','ripples','rainRings','foam'})
   for name,p in pairs(C.settings.presets)do presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.waterTouch};p.cards=p.cards or{};if p.cards.waterTouch==nil then p.cards.waterTouch={enabled=name~='off'} end end
   resetMotion();state.active=true;state.error=nil
   S.register(Card.ID,'main.uniforms',Card.uniforms);S.register(Card.ID,'main.functions',Card.functions)
   S.register(Card.ID,'main.vertex.post',Card.vertex,0,{x=0,y=0,z=0})
   S.register(Card.ID,'main.fragment.lit',Card.fragment)
   S.register(Card.ID,'prepare',prepare);S.register(Card.ID,'bind',bind);S.register(Card.ID,'bindTexture',texture);S.register(Card.ID,'release',release)
   -- Probe the complete current texture budget before Renderer can compile
   -- it. Failure removes only this owner, not the other active shader Cards.
   local ok,err=pcall(function()
    local source=V.require('Renderer').buildShaderSource()
    local shader=V.require('ActorLighting').compile(source);shader:release()
    shader=V.require('ShaderCompiler').newShader(V.require('SurfaceDerivatives').prepare('#define WORLD_INSTANCES\n'..source));shader:release()
   end)
   state.available=ok
   if not ok then S.unregister(Card.ID);state.error=tostring(err);state.enabled=false
    if V.mod.log then V.mod.log:info('Water contact unavailable; retaining existing water: '..state.error)end
   end
   return state,{isActive=function()return state.active end}
  end,deactivate=deactivate,abort=deactivate,health=function()
   local h=S.health(Card.ID);for k,v in pairs(state)do h[k]=v end;h.ok=h.ok and not state.error;h.pending=row and row.work~=nil or false;h.waterTiles=row and row.water and #row.water or 0
   h.decorativeWaterTiles=row and row.decorativeCount or 0
   h.gpuTimeAvailable=false;return h
  end}}
end
return Card
