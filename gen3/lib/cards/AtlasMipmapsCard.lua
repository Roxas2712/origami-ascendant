local V=...
local Card={ID='oasc.gen3.atlas-mipmaps',VERSION='1.0.0',CAPABILITY='ascendant.atlas-mipmaps.gen3/v1'}
Card.option={key='gen3Card_atlasMipmaps',label='BODEN-FERNFILTER',type='toggle',default=true,
 help='Ruhigere ferne Bodenfliesen bei Kameraneigung unter 45 Grad. Nahe Pixel und Figuren bleiben scharf.'}
Card.defines='#pragma language glsl3\n'
Card.uniforms=[[
uniform vec2 oasc_mip_size;
uniform float oasc_mip_enabled;
uniform float oasc_mip_bias;
varying float oasc_mip_floor;
#ifdef PIXEL
vec4 oasc_mip_nearest(Image tex,vec2 uv){
 if(oasc_mip_enabled<.5)return texture(tex,uv);
 return textureLod(tex,(floor(uv*oasc_mip_size)+.5)/oasc_mip_size,0.0);
}
#endif
]]
Card.vertex='oasc_mip_floor=(1.0-step(1.01,abs(VertexShade)))*(1.0-step(.5,BillboardAnchor.z));'
Card.pre=[[
 // Derivatives and explicit mip sampling precede every material discard.
 vec2 oasc_mip_pixels=uv*oasc_mip_size;
 float oasc_mip_rho=max(length(dFdx(oasc_mip_pixels)),length(dFdy(oasc_mip_pixels)));
 float oasc_mip_lod=clamp(log2(max(oasc_mip_rho,.0001))+oasc_mip_bias,0.0,4.0);
 // Clamp the footprint of BOTH trilinear levels to this 16-pixel cell.
 // Level four is one texel per cell; higher levels would mix adjacent tiles.
 vec2 oasc_mip_margin=vec2(exp2(ceil(oasc_mip_lod))*.5);
 vec2 oasc_mip_cell=floor(oasc_mip_pixels/16.0)*16.0;
 vec2 oasc_mip_uv=clamp(oasc_mip_pixels,oasc_mip_cell+oasc_mip_margin,oasc_mip_cell+16.0-oasc_mip_margin)/oasc_mip_size;
 vec4 oasc_mip_pixel=vec4(0.0);
 vec3 oasc_mip_cross=cross(dFdx(worldPosition),dFdy(worldPosition));
 float oasc_mip_horizontal=abs(oasc_mip_cross.y)/max(length(oasc_mip_cross),.00001);
 float oasc_mip_amount=oasc_mip_enabled*oasc_mip_floor*step(.995,oasc_mip_horizontal)*smoothstep(1.0,2.0,oasc_mip_rho);
 // Most visible cutouts/near tiles never use the distant-floor sample.
 // Derivatives stay outside this branch, before every material discard.
 if(oasc_mip_amount>0.0)oasc_mip_pixel=textureLod(tex,oasc_mip_uv,oasc_mip_lod);
]]
Card.albedo='pixel=mix(pixel,oasc_mip_pixel,oasc_mip_amount);'
Card.probe='#pragma language glsl3\nuniform Image oasc_mip_probe;\nvec4 effect(vec4 c,Image t,vec2 uv,vec2 p){return textureLod(oasc_mip_probe,uv,1.0);}'
function Card.wrap(source)
 -- Only functions sampling the current draw's primary texture are redirected.
 -- Other samplers (lights, shadows, fiber, alpha masks) retain their filtering.
 return(source:gsub('Texel%s*%(%s*tex%s*,','oasc_mip_nearest(tex,'))
end
function Card.descriptor(V)
 local S,U,C,G=V.require('core/RenderSeams'),V.require('UniformState'),V.require('DioramaConfig'),V.require('GeometryConfig')
 local Atlas=V.require('AtlasComposite');local state={active=false,available=false,enabled=false,resources=0,bytes=0,builds=0,hits=0,mipMs=0,maxMipMs=0}
 local cache={};local presets={};local tick=0;local size={1,1};local maxBytes=32*1024*1024
 local function drop(key)
  local row=cache[key];if row then row.canvas:release();state.bytes=state.bytes-row.bytes;state.resources=state.resources-1;cache[key]=nil end
 end
 local function release()
  for key in pairs(cache)do drop(key)end
  state.resources=0;state.bytes=0
 end
 local warm
 local function prepare(ctx)
  tick=tick+1
  local c=C.cards and C.cards.atlasMipmaps;local p=C.settings.presets[V.mod.options:get('gen3Quality')or C.settings.defaultPreset]
  local policy=p and p.cards and p.cards.atlasMipmaps
  state.enabled=state.available and c and c.enabled~=false and not(policy and policy.enabled==false)
   and V.require('Camera').elevation()<math.rad(45) and not state.error
  -- Repacking/generating mip levels changes render targets. Finish it before
  -- any depth-attached scene pass, not in the middle of a mirrored draw.
  if state.enabled and ctx.drawList then
   for _,entry in ipairs(ctx.drawList)do
    local native=Atlas.cache[entry.atlas]
    if native then warm(native.canvas,native)end
   end
  end
 end
 local function bind(shader)
  if U.has(shader,'oasc_mip_enabled')then U.send(shader,'oasc_mip_enabled',0);U.send(shader,'oasc_mip_size',size);U.send(shader,'oasc_mip_bias',-.5)end
 end
 local function repack(row,image)
  love.graphics.setCanvas(row.canvas);love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode()
  love.graphics.setColorMask(true,true,true,true);love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('replace','premultiplied');love.graphics.setShader()
  love.graphics.draw(image)
  love.graphics.setCanvas()
  local start=love.timer.getTime();row.canvas:generateMipmaps();state.mipMs=(love.timer.getTime()-start)*1000;state.maxMipMs=math.max(state.maxMipMs,state.mipMs)
 end
 warm=function(image,native)
  local w,h=image:getDimensions();local row=cache[image]
  local bytes=w*h*4*4/3
  if w%16~=0 or h%16~=0 or bytes>maxBytes then return end
  if row and(row.w~=w or row.h~=h)then drop(image);row=nil end
  if not row then
   local count=0;for _ in pairs(cache)do count=count+1 end
   while count>=4 or state.bytes+bytes>maxBytes do
    local oldest,age;for key,item in pairs(cache)do if not age or item.tick<age then oldest,age=key,item.tick end end
    if not oldest then break end;drop(oldest);count=count-1
   end
   local ok,canvas=pcall(love.graphics.newCanvas,w,h,{format='rgba8',dpiscale=1,mipmaps='manual'})
   if not ok then state.error=tostring(canvas);release();return end
   canvas:setFilter('linear','linear');canvas:setMipmapFilter('linear',0)
   row={canvas=canvas,w=w,h=h,bytes=bytes};cache[image]=row;state.bytes=state.bytes+bytes;state.resources=state.resources+1
  end
  row.tick=tick
  if row.version~=native.version then
   love.graphics.push('all');local ok,err=pcall(repack,row,image);love.graphics.pop()
   if not ok then state.error=tostring(err);release();return end
   row.version=native.version;state.builds=state.builds+1
  else state.hits=state.hits+1 end
  return row
 end
 local function texture(image,ctx)
  local shader,source=ctx.shader,ctx.source
  if not U.has(shader,'oasc_mip_enabled')then return image end
  U.send(shader,'oasc_mip_enabled',0)
  if not state.enabled or not source or not source.midToSlot then return image end
  local native=Atlas.cache[source]
  if not native or native.canvas~=image then return image end
  local row=cache[image]
  if ctx.frame and ctx.frame.drawList then
   -- Never mutate the framebuffer during a scene pass. If a new source
   -- appeared after prepare, use its exact native pixels for this one frame.
   if not row or row.version~=native.version then return image end
   row.tick=tick;state.hits=state.hits+1
  else row=warm(image,native)end
  if not row then return image end
  size[1],size[2]=row.w,row.h
  U.send(shader,'oasc_mip_size',size)
  U.send(shader,'oasc_mip_bias',math.max(-2,math.min(0,tonumber(C.cards.atlasMipmaps.bias)or -.5)))
  U.send(shader,'oasc_mip_enabled',1)
  return row.canvas
 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);release();state.active=false;state.enabled=false;state.error=nil
  if C.cards then C.cards.atlasMipmaps=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name];if p and p.cards then p.cards.atlasMipmaps=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end end
  presets={};return true
 end
 return{schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_atlas_mipmaps_test.lua','tests/gen3_atlas_mipmaps_gpu_test.lua','tests/gen3_atlas_mipmaps_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/ATLAS_MIPMAPS.md'},
  impact={runtimeOwners={'gen3.render.atlas-mipmaps'},saveWrites={},publicHooks={},files={'gen3/lib/cards/AtlasMipmapsCard.lua','gen3/cards/ATLAS_MIPMAPS.md'}},
  lifecycle={install=function()return{installed=true}end,activate=function()
   if state.active then return state end
   C.cards=C.cards or{};C.cards.atlasMipmaps=C.cards.atlasMipmaps or{enabled=true,bias=-.5}
   G.registerPresentation(Card.ID,'atlasMipmaps',{'enabled','bias'})
   for name,p in pairs(C.settings.presets)do presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.atlasMipmaps};p.cards=p.cards or{};if p.cards.atlasMipmaps==nil then p.cards.atlasMipmaps={enabled=name~='off'and name~='low'} end end
   state.active=true;state.error=nil;state.reason=nil
   local ok,probe=pcall(V.require('ShaderCompiler').newShader,Card.probe);state.available=ok
   if ok then probe:release()
    local ready,canvas=pcall(love.graphics.newCanvas,16,16,{dpiscale=1,mipmaps='manual'})
    state.available=ready;if ready then canvas:release()else state.reason=tostring(canvas)end
   else state.reason=tostring(probe)end
   if state.available then
    S.register(Card.ID,'main.defines',Card.defines);S.register(Card.ID,'main.uniforms',Card.uniforms)
    S.register(Card.ID,'main.vertex.post',Card.vertex,0,{x=0,y=0,z=0})
    S.register(Card.ID,'main.fragment.pre',Card.pre);S.register(Card.ID,'main.fragment.albedo',Card.albedo)
    S.register(Card.ID,'shaderSource',Card.wrap);S.register(Card.ID,'prepare',prepare);S.register(Card.ID,'bind',bind)
    S.register(Card.ID,'textureSource',texture);S.register(Card.ID,'release',release)
   elseif V.mod.log then V.mod.log:info('Floor mipmaps unavailable; retaining nearest native atlas: '..tostring(state.reason))end
   return state,{isActive=function()return state.active end}
  end,deactivate=deactivate,abort=deactivate,health=function()
   local h=S.health(Card.ID);for k,v in pairs(state)do h[k]=v end;h.ok=h.ok and not state.error;h.gpuTimeAvailable=false;return h
  end}}
end
return Card
