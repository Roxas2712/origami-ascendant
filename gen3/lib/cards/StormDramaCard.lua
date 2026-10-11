local V=...
local Card={ID='oasc.gen3.storm-drama',VERSION='1.0.0',CAPABILITY='ascendant.storm-drama.gen3/v1'}
Card.option={key='gen3Card_stormDrama',label='GEWITTERSTIMMUNG',type='toggle',default=true,
 help='Gerichtetes Blitzlicht, wandernde Nebelbaenke und gelegentliche dezente Regentropfen.'}
Card.fogUniforms=[[
uniform vec4 oasc_storm_fog; // seconds, visible storm weight, wind x/z
uniform float oasc_storm_banksOnly;
]]
Card.fogDensity=[[
 if(oasc_storm_fog.y>0.0){
  vec2 q=p.xz-oasc_storm_fog.zw*oasc_storm_fog.x*2.0;
  float bands=0.0;
  for(int b=0;b<3;b++){
   float k=float(b);
   float bend=noise(vec2(q.x*.012+k*17.0,oasc_storm_fog.x*.025))-.5;
   float across=mod(q.y+q.x*.32+k*61.0+bend*32.0,190.0)-95.0;
   bands+=exp(-across*across/(180.0+k*65.0));
  }
  d*=mix(1.0+bands*.55*oasc_storm_fog.y,bands*oasc_storm_fog.y,oasc_storm_banksOnly);
 }
]]
Card.lens=[[
uniform Image oasc_storm_normal;
uniform vec2 oasc_storm_pixels;
uniform vec4 oasc_storm_drops[8]; // pixel x/y, radius, envelope
uniform float oasc_storm_lens;
vec4 effect(vec4 color,Image scene,vec2 uv,vec2 screen){
 vec4 original=Texel(scene,uv);vec2 offset=vec2(0.0);float coverage=0.0;
 for(int i=0;i<8;i++){
  vec4 drop=oasc_storm_drops[i];vec2 q=(uv*oasc_storm_pixels-drop.xy)/max(1.0,drop.z);
  if(drop.w>0.0 && abs(q.x)<1.0 && abs(q.y)<1.0){
   vec4 lens=Texel(oasc_storm_normal,q*.5+.5);
   float a=lens.a*drop.w;offset+=(lens.rg*2.0-1.0)*a;coverage=max(coverage,a);
  }
 }
 if(coverage<=0.0)return original;
 float span=length(offset);offset/=max(1.0,span);
 offset*=min(3.0,max(0.0,oasc_storm_lens*3.0));
 vec2 edge=.5/oasc_storm_pixels;
 vec3 refracted=Texel(scene,clamp(uv+offset/oasc_storm_pixels,edge,1.0-edge)).rgb*.7
  +Texel(scene,clamp(uv-offset*.35/oasc_storm_pixels,edge,1.0-edge)).rgb*.3;
 return vec4(mix(original.rgb,refracted,coverage*.65),original.a);
}
]]
local function hash(n)return((n*97+1729)*631%65521)/65521 end
local function smooth(x)x=math.max(0,math.min(1,x));return x*x*(3-2*x)end
-- One 2–4 second burst in 20 seconds: <=20% temporal coverage at any FPS.
function Card.dropWindow(time,seed)
 local cycle=math.floor(time/20);local duration=2+2*hash(cycle+seed)
 local age=time-cycle*20-4
 if age<0 or age>=duration then return 0,age,duration,cycle end
 return smooth(age/.3)*smooth((duration-age)/.45),age,duration,cycle
end
function Card.descriptor(V)
 local S,U,C,G=V.require('core/RenderSeams'),V.require('UniformState'),V.require('DioramaConfig'),V.require('GeometryConfig')
 local NewFog=V.require('cards/StormFogPass')
 local state={active=false,enabled=false,available=false,resources=0,flash=0,lensWeight=0,updateMs=0,applyMs=0}
 local presets={};local copied,solar,direction,shear,color={},{},{0,1,0},{0,0},{.80,.89,1.08}
 local fog={0,0,1,-.52};local cloud,events={0,0,0,0},{0,0,0,0};local pixels={1,1};local drops={}
 for i=1,8 do drops[i]={0,0,1,0}end
 local normal,shader,output;local mapId,seed
 local fogPass;local fogContext={stormBanks=true};local fogConfig={density=.16,height=18,color={.35,.43,.52},light={.58,.66,.75},pocket={0,0},clearCore=1,ribbonMix=0}
 local function resources()
  local n=(normal and 1 or 0)+(shader and 1 or 0)+(output and 1 or 0)
  if fogPass then n=n+(fogPass.layer and 1 or 0)+(fogPass.shader and 1 or 0)+(fogPass.compose and 1 or 0)+(fogPass.outputs and #fogPass.outputs or 0)end
  state.resources=n
 end
 local function release()
  if normal then normal:release();normal=nil end
  if shader then U.invalidate(shader);shader:release();shader=nil end
  if output then output:release();output=nil end
  if fogPass then fogPass.release();fogPass=nil end
  state.resources=0;state.enabled=false;state.flash=0;state.lensWeight=0;fog[2]=0
 end
 local function lighting(atmosphere,ctx)
  local started=love.timer.getTime();local c=C.cards and C.cards.stormDrama
  local preset=C.settings.presets[V.mod.options:get('gen3Quality')or C.settings.defaultPreset]
  local policy=preset and preset.cards and preset.cards.stormDrama
  local front=ctx.weatherMood
  local amount=front and(front.precipMode=='storm'and front.amount or 0)or(ctx.weatherMode=='storm'and 1 or 0)
  state.enabled=state.available and c and c.enabled~=false and not(type(policy)=='table'and policy.enabled==false)
   and ctx.outdoors==true and not ctx.cave and C.weather.enabled~=false and amount>0
  state.updateMs=0;state.flash=0;state.lensWeight=0;fog[1],fog[2]=ctx.time or 0,0
  if not state.enabled then return atmosphere end
  if mapId~=ctx.id then mapId=ctx.id;seed=0;for i=1,#tostring(mapId)do seed=(seed*31+tostring(mapId):byte(i))%65521 end end
  fog[2]=c.fogBands~=false and amount or 0
  local envelope,age,duration,cycle=Card.dropWindow(ctx.time or 0,seed)
  state.lensAmount=math.max(0,math.min(1,tonumber(c.lensDrops)or 0))
  state.lensWeight=envelope*amount*state.lensAmount
  state.dropAge,state.dropCycle,state.dropDuration=age,cycle,duration
  local event=ctx.skyEvents
  if c.lightningLight~=false and event and event[1]>.6 and atmosphere.solar then
   state.flash=event[1]
   for k in pairs(copied)do copied[k]=nil end;for k,v in pairs(atmosphere)do copied[k]=v end
   for k in pairs(solar)do solar[k]=nil end;for k,v in pairs(atmosphere.solar)do solar[k]=v end
   local horizontal=math.sqrt(event[3]^2+event[4]^2);local sx,sz=event[3]/math.max(.0001,horizontal),event[4]/math.max(.0001,horizontal)
   direction[1],direction[2],direction[3]=sx*math.cos(math.rad(70)),math.sin(math.rad(70)),sz*math.cos(math.rad(70))
   -- PaperShadows divides by billboard height; cancel it so the cast vector
   -- matches this physical light direction for every height profile.
   local height=V.require('Billboard').heightScale()
   shear[1],shear[2]=-direction[1]/direction[2]*height,-direction[3]/direction[2]*height
   solar.direction,solar.shear,solar.sunColor=direction,shear,color
   solar.weight,solar.buildingWeight,solar.buildingShadows=1,1,true
   solar.shadowSoftness,solar.shadowStrength,solar.sun=.65,.65,.9*event[1]
   copied.solar,copied.direction,copied.sun=solar,direction,solar.sun
   atmosphere=copied
  end
  state.updateMs=(love.timer.getTime()-started)*1000
  return atmosphere
 end
 local function bind(main,ctx)
  if state.flash<=0 then return end
  -- All main/instance/actor bindings see the same atmosphere. Remove the
  -- old additive flash and cloud attenuation during the directional pulse.
  for i=1,4 do cloud[i]=ctx.cloudLight and ctx.cloudLight[i]or 0;events[i]=ctx.skyEvents[i]end
  cloud[1]=0;events[1]=0
  U.send(main,'cloudLight',cloud);U.send(main,'skyEvents',events);U.send(main,'daylightDirect',1)
 end
 local function bindFog(fogShader,context)
  if fogShader:hasUniform('oasc_storm_fog')then
   U.send(fogShader,'oasc_storm_fog',fog)
   U.send(fogShader,'oasc_storm_banksOnly',context and context.stormBanks and 1 or 0)
  end
 end
 local function banks(source,ctx)
  state.fogMs=0
  if not state.enabled or fog[2]<=0 or not ctx.depth or not C.post.enabled or C.weather.fog and C.weather.fog.volumetric==false then return source end
  local start=love.timer.getTime()
  fogPass=fogPass or NewFog()
  fogContext.depth,fogContext.depthScale,fogContext.eye=ctx.depth,ctx.depthScale or 1,ctx.eye
  fogContext.outdoors,fogContext.solar=ctx.outdoors,ctx.atmosphere.solar
  local out=fogPass.apply(source,ctx.vp,ctx.playerX-8,ctx.playerZ-16,ctx.time,fogConfig,fogContext)
  resources();state.fogMs=(love.timer.getTime()-start)*1000;return out
 end
 local function lens(source,ctx)
  state.applyMs=0
  if not state.enabled or state.lensWeight<=0 or not C.post.enabled then return source end
  local start=love.timer.getTime();local g=love.graphics;local w,h=source:getDimensions()
  if not shader then
   shader=V.require('ShaderCompiler').newShader(Card.lens)
   local file=love.filesystem.newFileData(assert(V.mod:read('gen3/data/weather/drop-normal.png')),'drop-normal.png')
   local data=love.image.newImageData(file);file:release();normal=g.newImage(data,{linear=true});data:release();normal:setFilter('linear','linear');normal:setWrap('clamp','clamp')
  end
  if not output or output:getWidth()~=w or output:getHeight()~=h or output:getFormat()~=source:getFormat()then
   if output then output:release()end
   output=g.newCanvas(w,h,{format=source:getFormat(),dpiscale=1});output:setFilter('nearest','nearest')
  end
  pixels[1],pixels[2]=w,h
  for i=1,8 do
   local d=drops[i];local n=seed+state.dropCycle*173+i*31
   d[1]=w*((i-1)%4+.25+hash(n)*.5)/4
   d[2]=h*(.10+math.floor((i-1)/4)*.42+hash(n+4)*.16)+state.dropAge*h*(.010+hash(n+7)*.009)
   d[3]=math.min(w,h)*(.018+hash(n+9)*.013);d[4]=state.lensWeight
  end
  U.send(shader,'oasc_storm_normal',normal);U.send(shader,'oasc_storm_pixels',pixels);U.send(shader,'oasc_storm_drops',unpack(drops));U.send(shader,'oasc_storm_lens',state.lensAmount)
  g.push('all');g.setCanvas(output);g.origin();g.setScissor();g.setDepthMode();g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1);g.setShader(shader);g.draw(source);g.pop()
  resources();state.applyMs=(love.timer.getTime()-start)*1000;return output
 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);release();state.active=false;state.error=nil
  if C.cards then C.cards.stormDrama=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name];if p and p.cards then p.cards.stormDrama=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end end
  presets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_storm_drama_test.lua','tests/gen3_storm_fog_uniform_test.lua','tests/gen3_storm_drama_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/STORM_DRAMA.md'},
  impact={runtimeOwners={'gen3.render.storm-drama'},saveWrites={},publicHooks={},files={'gen3/lib/cards/StormDramaCard.lua','gen3/lib/cards/StormFogPass.lua','gen3/data/weather/drop-normal.png','gen3/cards/STORM_DRAMA.md'}},
  lifecycle={install=function()return {installed=true}end,activate=function()
   if state.active then return state end
   C.cards=C.cards or{};C.cards.stormDrama=C.cards.stormDrama or{enabled=true,lightningLight=true,lensDrops=.6,fogBands=true}
   G.registerPresentation(Card.ID,'stormDrama',{'enabled','lightningLight','lensDrops','fogBands'})
   for name,p in pairs(C.settings.presets)do presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.stormDrama};p.cards=p.cards or{};if p.cards.stormDrama==nil then p.cards.stormDrama={enabled=name~='off'} end end
   state.active=true;state.error=nil
   S.register(Card.ID,'lighting',lighting);S.register(Card.ID,'bind',bind)
   S.register(Card.ID,'fog.uniforms',Card.fogUniforms);S.register(Card.ID,'fog.density',Card.fogDensity);S.register(Card.ID,'bindFog',bindFog)
   S.register(Card.ID,'beforeFinish',banks,30);S.register(Card.ID,'afterFinish',lens,40);S.register(Card.ID,'release',release)
   local ok,err=pcall(function()
    local probe=V.require('ShaderCompiler').newShader(Card.lens);probe:release()
    probe=V.require('ShaderCompiler').newShader(NewFog().buildIntegrateSource());probe:release()
   end)
   state.available=ok
   if not ok then S.unregister(Card.ID);state.error=tostring(err);if V.mod.log then V.mod.log:info('Storm drama unavailable: '..state.error)end end
   return state,{isActive=function()return state.active end}
  end,deactivate=deactivate,abort=deactivate,health=function()
   local h=S.health(Card.ID);for k,v in pairs(state)do h[k]=v end;h.ok=h.ok and not state.error;h.gpuTimeAvailable=false;return h
  end}}
end
return Card
