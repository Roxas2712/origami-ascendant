local V=...
local Card={ID='oasc.gen3.color-script',VERSION='1.0.0',CAPABILITY='ascendant.color-script.gen3/v1'}
Card.option={key='gen3Card_colorScript',label='REGIONALE FARBSTIMMUNG',type='toggle',default=true,
 help='Dezente Ortsfarben mit weichen Uebergaengen; vorhandene Helligkeit und Abendlicht bleiben erhalten.'}
Card.regions={'pallet','viridian','moon','cerulean','lavender','celadon','fuchsia','cinnabar','seafoam','indigo'}
local fogs={neutral={1,1,1},pallet={1.025,1,.98},viridian={.96,1.035,.985},moon={.97,.96,1.08},
 cerulean={.95,1.025,1.04},lavender={1.07,.95,1.10},celadon={1.04,1,.965},
 fuchsia={1.025,1.04,.95},cinnabar={1.09,1,.94},seafoam={.94,1.025,1.08},indigo={.98,.985,1.05}}
local exact={FR_PALLET_TOWN='pallet',FR_ROUTE_1='pallet',FR_VIRIDIAN_CITY='viridian',FR_ROUTE_2='viridian',
 FR_VIRIDIAN_FOREST='viridian',FR_CERULEAN_CITY='cerulean',FR_LAVENDER_TOWN='lavender',FR_CELADON_CITY='celadon',
 FR_FUCHSIA_CITY='fuchsia',FR_CINNABAR_ISLAND='cinnabar',FR_INDIGO_PLATEAU_EXTERIOR='indigo'}
local prefixes={{'FR_MT_MOON','moon'},{'FR_SEAFOAM_ISLANDS','seafoam'},{'FR_SAFARI_ZONE','fuchsia'},
 {'FR_MT_EMBER','cinnabar'},{'FR_POKEMON_TOWER','lavender'}}
-- Hoenn uses the existing restrained palettes by habitat, not Kanto map IDs.
local hoenn={EM_LITTLEROOT_TOWN='pallet',EM_OLDALE_TOWN='pallet',EM_PETALBURG_CITY='viridian',
 EM_PETALBURG_WOODS='viridian',EM_RUSTBORO_CITY='celadon',EM_DEWFORD_TOWN='cerulean',
 EM_SLATEPORT_CITY='cerulean',EM_MAUVILLE_CITY='celadon',EM_VERDANTURF_TOWN='viridian',
 EM_FALLARBOR_TOWN='cinnabar',EM_LAVARIDGE_TOWN='cinnabar',EM_FORTREE_CITY='viridian',
 EM_LILYCOVE_CITY='cerulean',EM_MOSSDEEP_CITY='cerulean',EM_SOOTOPOLIS_CITY='cerulean',
 EM_PACIFIDLOG_TOWN='cerulean',EM_EVER_GRANDE_CITY='indigo',EM_MT_CHIMNEY='cinnabar'}
local hoennPrefixes={{'EM_GRANITE_CAVE','moon'},{'EM_METEOR_FALLS','moon'},{'EM_RUSTURF_TUNNEL','moon'},
 {'EM_MT_PYRE','lavender'},{'EM_SHOAL_CAVE','seafoam'},{'EM_MAGMA_HIDEOUT','cinnabar'},
 {'EM_FIERY_PATH','cinnabar'},{'EM_JAGGED_PASS','cinnabar'},{'EM_SAFARI_ZONE','fuchsia'},
 {'EM_UNDERWATER','cerulean'},{'EM_SEAFLOOR_CAVERN','cerulean'},{'EM_CAVE_OF_ORIGIN','moon'},
 {'EM_VICTORY_ROAD','indigo'},{'EM_SKY_PILLAR','indigo'}}
function Card.region(id,overrides)
 if overrides and overrides[id]then return fogs[overrides[id]]and overrides[id]or'neutral'end
 if hoenn[id]then return hoenn[id]end
 for _,p in ipairs(hoennPrefixes)do if id:sub(1,#p[1])==p[1]then return p[2]end end
 local route=tonumber(id:match('^EM_ROUTE(%d+)$'))
 if route then
  if route>=124 and route<=134 or route>=105 and route<=109 then return 'cerulean'end
  if route==113 then return 'cinnabar'end
  return route<=103 and 'pallet'or'viridian'
 end
 if exact[id]then return exact[id]end
 for _,p in ipairs(prefixes)do if id:sub(1,#p[1])==p[1]then return p[2]end end
 return 'neutral'
end
local function smooth(x)x=math.max(0,math.min(1,x));return x*x*(3-2*x)end
-- Two daypart images suffice: existing illumination carries dawn/golden/dusk.
-- Regional chroma is restrained at night without undoing the blue night rig.
function Card.night(time)
 local t=time%1200
 if t<560 then return 0 elseif t<680 then return smooth((t-560)/120)
 elseif t<1100 then return 1 else return 1-smooth((t-1100)/100)end
end
Card.mixShader=[[
uniform Image oasc_region_other;uniform float oasc_region_blend;
vec4 effect(vec4 color,Image image,vec2 uv,vec2 screen){
 return mix(Texel(image,uv),Texel(oasc_region_other,uv),oasc_region_blend);
}
]]
function Card.descriptor(V)
 local S,U,C,G=V.require('core/RenderSeams'),V.require('UniformState'),V.require('DioramaConfig'),V.require('GeometryConfig')
 local state={active=false,available=false,enabled=false,resources=0,updateMs=0,mixMs=0}
 local images,presets={},{};local shader,fromCanvas,targetCanvas,spareCanvas
 local override={mix=0,amount=0,preserveLegacy=true};local lastContext
 local region,lastClock,started,transition,fromIdentity
 local fog,fromFog={1,1,1},{1,1,1};local fogParams={color={0,0,0},light={0,0,0}}
 local targetNight,targetRegion
 local function resources()
  local n=0;for _,pair in pairs(images)do n=n+1;if pair.night~=pair.day then n=n+1 end end
  state.resources=n+(shader and 1 or 0)+(fromCanvas and 1 or 0)+(targetCanvas and 1 or 0)+(spareCanvas and 1 or 0)
 end
 local function clearContext()
  if lastContext and lastContext.lutOverride==override then lastContext.lutOverride=nil end
  lastContext=nil
 end
 local function release()
  clearContext()
  for _,pair in pairs(images)do pair.day:release();if pair.night~=pair.day then pair.night:release()end end;images={}
  if shader then U.invalidate(shader);shader:release();shader=nil end
  for _,canvas in ipairs{fromCanvas or false,targetCanvas or false,spareCanvas or false}do if canvas then canvas:release()end end
  fromCanvas,targetCanvas,spareCanvas=nil,nil,nil;override.a,override.b=nil,nil
  region,lastClock,transition,targetNight,targetRegion=nil,nil,nil,nil,nil
  state.resources=0;state.enabled=false
 end
 local function load()
  if images.neutral then return true end
  local ok,err=pcall(function()
   assert(love.graphics.getCanvasFormats().rgba16f,'16-bit LUT mixing is unavailable')
   local neutral=assert(V.mod:read('gen3/data/luts/neutral.png'))
   local function image(raw,name)
    local file=love.filesystem.newFileData(raw,name);local data=love.image.newImageData(file);file:release()
    local w,h=data:getDimensions();if w~=1024 or h~=32 then data:release();error('invalid regional LUT dimensions: '..name)end
    local texture=love.graphics.newImage(data,{mipmaps=false,linear=true});data:release()
    texture:setFilter('linear','linear');texture:setWrap('clamp','clamp');return texture
   end
   local identity=image(neutral,'neutral.png');images.neutral={day=identity,night=identity,identity=true}
   for _,name in ipairs(Card.regions)do
    local pair={};images[name]=pair
    local a=assert(V.mod:read('gen3/data/luts/regions/'..name..'-day.png'))
    local b=assert(V.mod:read('gen3/data/luts/regions/'..name..'-night.png'))
    pair.day=image(a,name..'-day.png');pair.night=image(b,name..'-night.png');pair.identity=a==neutral and b==neutral
   end
   shader=V.require('ShaderCompiler').newShader(Card.mixShader)
  end)
  if not ok then
   -- A partially loaded pair is also owned and must be cleaned up.
   for name,pair in pairs(images)do if not pair.day then images[name]=nil elseif not pair.night then pair.night=pair.day end end
   release();state.available=false;state.error=tostring(err);S.unregister(Card.ID)
   if V.mod.log then V.mod.log:info('Regional grading unavailable: '..state.error)end
   return false
  end
  state.available=true;resources();return true
 end
 local function target(old)
  if old then return old end
  local canvas=love.graphics.newCanvas(1024,32,{format='rgba16f',dpiscale=1});canvas:setFilter('linear','linear');return canvas
 end
 local function mix(a,b,u,canvas)
  local g=love.graphics;local before=love.timer.getTime()
  U.send(shader,'oasc_region_other',b);U.send(shader,'oasc_region_blend',u)
  g.push('all');g.origin();g.setScissor();g.setDepthMode();g.setColor(1,1,1,1);g.setBlendMode('replace','premultiplied');g.setCanvas(canvas);g.setShader(shader);g.draw(a);g.pop()
  state.mixMs=state.mixMs+(love.timer.getTime()-before)*1000
 end
 local function prepare(ctx)
  local begin=love.timer.getTime();local c=C.cards and C.cards.colorScript;local preset=C.settings.presets[V.mod.options:get('gen3Quality')or C.settings.defaultPreset]
  local policy=preset and preset.cards and preset.cards.colorScript
  clearContext();state.mixMs=0;state.updateMs=0
  state.enabled=state.active and c and c.enabled~=false and not(type(policy)=='table'and policy.enabled==false)and C.post.enabled
   and(ctx.outdoors==true or ctx.cave==true)and (tostring(ctx.id):match('^FR_')~=nil or tostring(ctx.id):match('^EM_')~=nil)
  if not state.enabled then region=nil;transition=false;return end
  if not load()then return end
  local id=Card.region(ctx.id,c.regions);local now=(V.clock or love.timer.getTime)();local night=Card.night(V.require('DayNight').time())
  if lastClock and now<lastClock then transition=false end;lastClock=now
  if region~=id then
   if region and override.a then
    -- Snapshot the displayed palette, including an interrupted crossfade.
    -- Ping-pong avoids sampling the render target when crossing twice quickly.
    spareCanvas=target(spareCanvas);mix(override.a,override.b,override.mix,spareCanvas)
    spareCanvas,fromCanvas=fromCanvas,spareCanvas
    fromIdentity=override.identity;for i=1,3 do fromFog[i]=fog[i]end
    started=now;transition=true
   else transition=false end
   region=id;targetNight,targetRegion=nil,nil
  end
  local pair=images[id];local u=transition and smooth((now-started)/1.5)or 1
  if u>=1 then transition=false end
  if transition then
   targetCanvas=target(targetCanvas)
   if targetNight~=night or targetRegion~=id then mix(pair.day,pair.night,night,targetCanvas);targetNight,targetRegion=night,id end
   override.a,override.b,override.mix=fromCanvas,targetCanvas,u
   override.identity=fromIdentity and pair.identity
  else override.a,override.b,override.mix=pair.day,pair.night,night;override.identity=pair.identity end
  local f=fogs[id];for i=1,3 do fog[i]=transition and(fromFog[i]+(f[i]-fromFog[i])*u)or f[i]end
  override.amount=math.max(0,math.min(1,tonumber(c.amount)or .7))
  state.region,state.night,state.transition,state.mix,state.identity=id,night,transition,u,override.identity
  lastContext=ctx;resources();state.updateMs=(love.timer.getTime()-begin)*1000
 end
 local function beforeFinish(canvas,ctx)
  if state.enabled and state.available and ctx==lastContext then ctx.lutOverride=override end
  return canvas
 end
 local function params(original,def)
  if not state.enabled or not state.available or override.identity or override.amount<=0 or not lastContext or (def.id or def.name)~=lastContext.id then return original end
  for key in pairs(fogParams)do if key~='color'and key~='light'then fogParams[key]=nil end end
  for key,value in pairs(original)do if key~='color'and key~='light'then fogParams[key]=value end end
  for _,key in ipairs{'color','light'}do
   local src,dst=original[key],fogParams[key];local oldY,newY=0,0
   for i=1,3 do local w=i==1 and .2126 or i==2 and .7152 or .0722;dst[i]=src[i]*(1+(fog[i]-1)*override.amount);oldY=oldY+src[i]*w;newY=newY+dst[i]*w end
   for i=1,3 do dst[i]=dst[i]*oldY/math.max(.000001,newY)end
  end
  return fogParams
 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);release();state.active=false;state.error=nil
  if C.cards then C.cards.colorScript=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name];if p and p.cards then p.cards.colorScript=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end end
  presets={};return true
 end
 local files={'gen3/lib/cards/ColorScriptCard.lua','gen3/cards/COLOR_SCRIPT.md'}
 for _,name in ipairs(Card.regions)do for _,part in ipairs{'day','night'}do files[#files+1]='gen3/data/luts/regions/'..name..'-'..part..'.png'end end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_color_script_test.lua','tests/gen3_color_script_play_test.lua','tests/gen3_color_script_crossing_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/COLOR_SCRIPT.md'},
  impact={runtimeOwners={'gen3.render.color-script'},saveWrites={},publicHooks={},files=files},
  lifecycle={install=function()return{installed=true}end,activate=function()
   if state.active then return state end
   C.cards=C.cards or{};C.cards.colorScript=C.cards.colorScript or{enabled=true,amount=.7,regions={}}
   G.registerPresentation(Card.ID,'colorScript',{'enabled','amount','regions'})
   for name,p in pairs(C.settings.presets)do presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.colorScript};p.cards=p.cards or{};if p.cards.colorScript==nil then p.cards.colorScript={enabled=name~='off'and name~='low'} end end
   state.active=true;state.error=nil
   if load()then S.register(Card.ID,'prepare',prepare);S.register(Card.ID,'beforeFinish',beforeFinish,90);S.register(Card.ID,'fogParams',params);S.register(Card.ID,'release',release)end
   return state,{isActive=function()return state.active end}
  end,deactivate=deactivate,abort=deactivate,health=function()
   local h=S.health(Card.ID);for k,v in pairs(state)do h[k]=v end;h.ok=h.ok and not state.error;h.gpuTimeAvailable=false;return h
  end}}
end
return Card
