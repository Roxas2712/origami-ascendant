local V=...
local Card={ID='oasc.gen3.geometry-fxaa',VERSION='1.0.0',CAPABILITY='ascendant.geometry-fxaa.gen3/v1'}
Card.option={key='gen3Card_geometryFxaa',label='GEOMETRIE-KANTENGLAETTUNG',type='toggle',default=true,
 help='Glaettet schraege Gebaeudekanten. Figuren bleiben scharf. Bei Ultra/1.5x automatisch aus.'}
-- Adapted FXAA 3.11 console path; attribution in GEOMETRY_FXAA_LICENSE.txt.
Card.filter=[[
uniform Image oasc_fxaa_mask; // scene luminance, geometry eligibility, unused, coverage
uniform vec2 oasc_fxaa_texel;
uniform vec3 oasc_fxaa_tuning;
uniform float oasc_fxaa_subpix;
// Detect contrast in scene luminance. Compressing it before the relative
// threshold hides low-contrast roof edges; HDR color itself stays untouched.
float oasc_fxaa_luma(vec3 c){return max(0.0,dot(c,vec3(.299,.587,.114)));}
vec4 oasc_fxaa_data(Image scene,vec2 uv){
 vec4 m=Texel(oasc_fxaa_mask,uv);
 // Vistas rendered by another shader have no packed luminance. Read their
 // actual color at the boundary instead of treating the sky as black.
 if(m.b<.99999)m.r=oasc_fxaa_luma(Texel(scene,uv).rgb);
 return m;
}
vec4 effect(vec4 color,Image scene,vec2 uv,vec2 screen){
 vec4 original=Texel(scene,uv);vec2 halfPixel=oasc_fxaa_texel*.5;
 vec4 m=oasc_fxaa_data(scene,uv);
 if(m.g<.99999)return original;
 vec4 nw=oasc_fxaa_data(scene,uv-halfPixel),sw=oasc_fxaa_data(scene,uv+vec2(-halfPixel.x,halfPixel.y));
 vec4 ne=oasc_fxaa_data(scene,uv+vec2(halfPixel.x,-halfPixel.y)),se=oasc_fxaa_data(scene,uv+halfPixel);
 // The four corner samples also protect the entire short-tap footprint.
 if(min(min(nw.g,sw.g),min(ne.g,se.g))<.99999)return original;
 float lumaMin=min(min(nw.r,sw.r),min(ne.r,se.r));
 float lumaMax=max(max(nw.r,sw.r),max(ne.r,se.r));
 if(max(lumaMax,m.r)-min(lumaMin,m.r)<max(oasc_fxaa_tuning.z,lumaMax*oasc_fxaa_tuning.y))return original;
 ne.r+=1.0/384.0;
 float swNe=sw.r-ne.r,seNw=se.r-nw.r;
 vec2 dir=vec2(swNe+seNw,swNe-seNw);dir/=max(length(dir),.00001);
 vec3 shortSum=Texel(scene,uv-dir*halfPixel).rgb+Texel(scene,uv+dir*halfPixel).rgb;
 float span=max(.00001,min(abs(dir.x),abs(dir.y))*oasc_fxaa_tuning.x);
 vec2 longStep=clamp(dir/span,vec2(-2.0),vec2(2.0))*oasc_fxaa_texel*2.0;
 // Checking only the color taps misses translucent sprite boundaries.
 // The same linear footprint in the mask rejects even partial coverage.
 vec4 maskA=Texel(oasc_fxaa_mask,uv-longStep),maskB=Texel(oasc_fxaa_mask,uv+longStep);
 if(min(maskA.g,maskB.g)<.99999)return vec4(mix(original.rgb,shortSum*.5,oasc_fxaa_subpix),original.a);
 vec3 wide=(Texel(scene,uv-longStep).rgb+Texel(scene,uv+longStep).rgb+shortSum)*.25;
 float wideLuma=oasc_fxaa_luma(wide);
 return vec4(mix(original.rgb,(wideLuma<lumaMin || wideLuma>lumaMax)?shortSum*.5:wide,oasc_fxaa_subpix),original.a);
}

]]
-- Integrate the screen-pixel footprint only at roof texture texel borders.
-- Texel interiors retain nearest sampling. Four explicit nearest taps avoid
-- changing the source atlas filter (shared with sprites and other Cards).
Card.coverageUniforms=[[
uniform vec2 oasc_fxaa_atlasSize;
uniform float oasc_fxaa_roofCoverage;
varying float oasc_fxaa_roof;
]]
Card.coverageVertex='oasc_fxaa_roof=1.0-step(.01,abs(VertexShade-6.0));'
Card.coveragePre=[[
 vec2 oasc_fxaa_pixel=uv*oasc_fxaa_atlasSize;
 vec2 oasc_fxaa_width=max(fwidth(oasc_fxaa_pixel),vec2(.0001));
]]
Card.coverageFunction=[[
vec4 oasc_fxaa_coverage(Image tex,vec2 p,vec2 width){
 vec2 centre=floor(p+.5);
 vec2 q=centre+clamp((p-centre)/width,vec2(-.5),vec2(.5))-.5;
 vec2 base=floor(q),weight=fract(q),cell=floor(p/16.0)*16.0;
 // Never import another metatile's pixels. Keep alpha cutout boundaries native.
 vec2 lo=clamp(base+.5,cell+.5,cell+15.5)/oasc_fxaa_atlasSize;
 vec2 hi=clamp(base+1.5,cell+.5,cell+15.5)/oasc_fxaa_atlasSize;
 vec4 a=Texel(tex,lo),b=Texel(tex,vec2(hi.x,lo.y)),c=Texel(tex,vec2(lo.x,hi.y)),d=Texel(tex,hi);
 if(min(min(a.a,b.a),min(c.a,d.a))<.99999)return Texel(tex,p/oasc_fxaa_atlasSize);
 return mix(mix(a,b,weight.x),mix(c,d,weight.x),weight.y);
}
]]
Card.coverageAlbedo=[[
 if(oasc_fxaa_roofCoverage>.5 && oasc_fxaa_roof>.5)
  pixel=oasc_fxaa_coverage(tex,oasc_fxaa_pixel,oasc_fxaa_width);
]]
Card.output=[[
#ifdef PIXEL
uniform Image MainTex;
uniform float oasc_fxaa_maskEnabled;
void effect(){
 vec4 c=oasc_fxaa_sceneColor(VaryingColor,MainTex,VaryingTexCoord.xy,love_PixelCoord);
 love_Canvases[0]=c;
 float l=max(0.0,dot(c.rgb,vec3(.299,.587,.114)));
 float eligible=1.0-clamp(max(max(spriteFace,actorFace),max(fenceFace,signFace)),0.0,1.0);
 // Native floor motifs are pixel art too. Filtering their grout/corner pixels
 // makes a repeated pale grid; retain exact ground texels and only smooth
 // elevated geometry. The mask also protects taps crossing the floor edge.
 eligible*=step(.05,abs(worldPosition.y));
 love_Canvases[1]=vec4(l,eligible*oasc_fxaa_maskEnabled,1.0,c.a);
}
#endif
]]
function Card.wrap(source)
 local renamed,n=source:gsub('vec4%s+effect%s*%(', 'vec4 oasc_fxaa_sceneColor(')
 assert(n==1,'scene fragment entry must be unique')
 return renamed..Card.output
end
function Card.descriptor(V)
 local S,U,C,G=V.require('core/RenderSeams'),V.require('UniformState'),V.require('DioramaConfig'),V.require('GeometryConfig')
 local state={active=false,available=false,drawing=false,applyMs=0,resources=0}
 local presets={};local mask,output,shader;local targets={};local texel={1,1};local tuning={8,.125,.05};local width,height,format;local atlasSize={1,1}
 local function releaseTargets()
  if mask then mask:release();mask=nil end;if output then output:release();output=nil end
  for k in pairs(targets)do targets[k]=nil end;width,height,format=nil,nil,nil;state.drawing=false;state.resources=shader and 1 or 0
 end
 local function release()
  releaseTargets();if shader then U.invalidate(shader);shader:release();shader=nil end;state.resources=0
 end
 local function prepareShader()
  if shader then return true end
  local ok,result=pcall(function()return V.require('ShaderCompiler').newShader(Card.filter)end)
  if not ok then
   release();state.error=tostring(result)
   if V.mod.log then V.mod.log:info('Geometry FXAA disabled: '..state.error)end
   return false
  end
  shader=result;state.resources=1;return true
 end
 local function prepare(ctx)
  state.drawing=false;state.applyMs=0
  local c=C.cards and C.cards.geometryFxaa;local p=C.settings.presets[V.mod.options:get('gen3Quality')or C.settings.defaultPreset]
  local policy=p and p.cards and p.cards.geometryFxaa
  state.enabled=state.available and c and c.enabled~=false and C.post.enabled and(C.settings.renderScale or 1)<1.5
   and not(type(policy)=='table'and policy.enabled==false)and not state.error
 end
 local function bind(shader)
  if U.has(shader,'oasc_fxaa_maskEnabled')then U.send(shader,'oasc_fxaa_maskEnabled',1)end
  if U.has(shader,'oasc_fxaa_roofCoverage')then U.send(shader,'oasc_fxaa_roofCoverage',0)end
 end
 local function texture(shader,image,ctx,source)
  if not U.has(shader,'oasc_fxaa_roofCoverage')then return end
  local c=C.cards and C.cards.geometryFxaa
  local enabled=state.drawing and not state.error and c and c.textureEdges~=false
   and (tonumber(c.subpix)or .75)>0 and image and source and source.midToSlot
  if image then atlasSize[1],atlasSize[2]=image:getDimensions()end
  U.send(shader,'oasc_fxaa_atlasSize',atlasSize)
  U.send(shader,'oasc_fxaa_roofCoverage',enabled and 1 or 0)
 end
 local function beforeWorld(ctx)
  if not state.enabled then return end
  local active=love.graphics.getShader()
  if not active or not U.has(active,'oasc_fxaa_maskEnabled')then return end
  if not prepareShader()then return end
  local w,h=ctx.canvas:getDimensions();local fmt=ctx.canvas:getFormat()
  local ok,err=pcall(function()
   if w~=width or h~=height or fmt~=format then
    releaseTargets()
    mask=love.graphics.newCanvas(w,h,{format=fmt,dpiscale=1});mask:setFilter('linear','linear')
    output=love.graphics.newCanvas(w,h,{format=fmt,dpiscale=1});output:setFilter('nearest','nearest')
    width,height,format=w,h,fmt
   end
  end)
  if not ok then release();state.error=tostring(err);if V.mod.log then V.mod.log:info('Geometry FXAA disabled: '..state.error)end;return end
  state.resources=3;targets[1],targets[2],targets.depthstencil=ctx.canvas,mask,ctx.depth
  love.graphics.push('all');love.graphics.setCanvas(mask);love.graphics.setColorMask(true,true,true,true);love.graphics.clear(0,1,0,1);love.graphics.pop()
  love.graphics.setCanvas(targets);state.drawing=true
 end
 local function filter(scene)
  love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode();love.graphics.setCanvas(output)
  love.graphics.setColorMask(true,true,true,true);love.graphics.setShader(shader);love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('replace','premultiplied')
  scene:setFilter('linear','linear');love.graphics.draw(scene)
 end
 local function apply(scene,ctx)
  if not state.drawing then return scene end
  local start=love.timer.getTime();state.drawing=false
  -- Restore the ordinary target before the protected filtering pass. Dynamic
  -- actors, particles and native effects are drawn afterward, at full sharpness.
  targets[2]=nil;love.graphics.setCanvas(targets)
  local c=C.cards.geometryFxaa;texel[1],texel[2]=1/width,1/height
  tuning[2]=math.max(0,tonumber(c.edgeThreshold)or .125)
  U.send(shader,'oasc_fxaa_mask',mask);U.send(shader,'oasc_fxaa_texel',texel);U.send(shader,'oasc_fxaa_tuning',tuning)
  U.send(shader,'oasc_fxaa_subpix',math.max(0,math.min(1,tonumber(c.subpix)or .75)))
  local min,mag,anis=scene:getFilter()
  love.graphics.push('all');local ok,err=pcall(filter,scene);scene:setFilter(min,mag,anis);love.graphics.pop()
  if not ok then release();state.error=tostring(err);return scene end
  state.applyMs=(love.timer.getTime()-start)*1000;return output
 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);release();state.active=false;state.enabled=false;state.error=nil
  if C.cards then C.cards.geometryFxaa=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name]
   if p and p.cards then p.cards.geometryFxaa=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end
  end
  presets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_auxiliary_shader_warm_test.lua','tests/gen3_geometry_fxaa_test.lua','tests/gen3_geometry_fxaa_gpu_test.lua','tests/gen3_geometry_fxaa_coverage_test.lua','tests/gen3_geometry_fxaa_native_walk_test.lua','tests/gen3_geometry_fxaa_play_test.lua','tests/gen3_geometry_fxaa_motion_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/GEOMETRY_FXAA.md'},
  impact={runtimeOwners={'gen3.render.geometry-fxaa'},saveWrites={},publicHooks={},files={'gen3/lib/cards/GeometryFxaaCard.lua','gen3/cards/GEOMETRY_FXAA.md','gen3/cards/GEOMETRY_FXAA_LICENSE.txt'}},
  lifecycle={install=function()return{installed=true}end,activate=function()
   if state.active then return state end
   G.registerPresentation(Card.ID,'geometryFxaa',{'enabled','subpix','edgeThreshold','textureEdges'})
   C.cards=C.cards or{};C.cards.geometryFxaa=C.cards.geometryFxaa or{enabled=true,subpix=.75,edgeThreshold=.125,textureEdges=true}
   for name,p in pairs(C.settings.presets)do presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.geometryFxaa}
    p.cards=p.cards or{};if p.cards.geometryFxaa==nil then p.cards.geometryFxaa={enabled=name=='medium'or name=='high'} end
   end
   state.active=true;state.available=(love.graphics.getSystemLimits().multicanvas or 1)>=2;state.error=nil
   if state.available then
    -- Canvas dimensions remain frame-owned; only compile the invariant pass.
    prepare();if state.enabled then prepareShader()end
    S.register(Card.ID,'main.defines','#define OASC_FXAA_MASK 1')
    S.register(Card.ID,'main.uniforms',Card.coverageUniforms)
    S.register(Card.ID,'main.vertex.post',Card.coverageVertex,0,{x=0,y=0,z=0})
    S.register(Card.ID,'main.fragment.pre',Card.coveragePre)
    S.register(Card.ID,'main.functions',Card.coverageFunction)
    S.register(Card.ID,'main.fragment.albedo',Card.coverageAlbedo)
    S.register(Card.ID,'bindTexture',texture)
    S.register(Card.ID,'shaderSource',Card.wrap);S.register(Card.ID,'prepare',prepare);S.register(Card.ID,'bind',bind)
    S.register(Card.ID,'beforeWorld',beforeWorld,1000);S.register(Card.ID,'afterGeometry',apply,-1000);S.register(Card.ID,'release',release)
   elseif V.mod.log then V.mod.log:info('Geometry FXAA unavailable: multiple color attachments unsupported')end
   return state,{isActive=function()return state.active end}
  end,deactivate=deactivate,abort=deactivate,health=function()
   local h=S.health(Card.ID);h.active=state.active;h.available=state.available;h.enabled=state.enabled;h.ok=h.ok and not state.error;h.error=h.error or state.error
   h.resources=state.resources;h.applyMs=state.applyMs;h.gpuTimeAvailable=false;return h
  end}}
end
return Card
