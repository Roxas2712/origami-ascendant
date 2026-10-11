-- Post-processing only. Native atlas/sprite sampling and the UI remain sharp.
local V=...
local F={}
local Seams=V.renderSeams or{version=0,shader=function()return ''end,chain=function(_,canvas)return canvas end}
local emptyContext={}
local DepthFocus=V.require('DepthOfField')
local scratch={step={0,0},focus={0,0,0},threshold={.66,.96},lower={0,0}}
local blurSource=[[
uniform vec2 stepUV;
vec4 effect(vec4 c,Image tex,vec2 uv,vec2 screen){
 return Texel(tex,uv)*.227027+
 (Texel(tex,uv-stepUV)+Texel(tex,uv+stepUV))*.1945946+
 (Texel(tex,uv-stepUV*2.0)+Texel(tex,uv+stepUV*2.0))*.1216216+
 (Texel(tex,uv-stepUV*3.0)+Texel(tex,uv+stepUV*3.0))*.054054+
 (Texel(tex,uv-stepUV*4.0)+Texel(tex,uv+stepUV*4.0))*.0162162;
}
]]
local finishSource=[[
uniform float acesAmount;uniform float exposure;
uniform Image lutA;uniform Image lutB;uniform float lutMix;uniform float lutAmount;
vec3 aces(vec3 x){return clamp((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14),0.0,1.0);}
vec3 grade(Image l,vec3 c){
 c=clamp(c,0.0,1.0);float sl=c.b*31.0;float s0=floor(sl),s1=min(s0+1.0,31.0);
 vec2 a=vec2((s0*32.0+c.r*31.0+.5)/1024.0,(c.g*31.0+.5)/32.0);
 vec2 b=vec2((s1*32.0+c.r*31.0+.5)/1024.0,a.y);
 return mix(Texel(l,a).rgb,Texel(l,b).rgb,sl-s0);
}
uniform Image bloomScene;
uniform float bloomIntensity;
uniform Image raysScene;
uniform float raysAmount;
uniform float ditherAmount;
uniform Image softScene;
uniform Image emissionScene;
uniform float maskedGlow;
uniform float focusY;
uniform vec3 focusSettings;
uniform float glowAmount;
uniform vec2 glowThreshold;
uniform float vignetteAmount;
uniform float warmAmount;
uniform float bottomBlur;
uniform vec2 lowerFocus;
uniform float edgeBlur;
uniform float softness;
uniform float toneMapping;
uniform float saturation;
vec4 effect(vec4 c,Image tex,vec2 uv,vec2 screen){
 vec3 sharp=Texel(tex,uv).rgb;
 vec3 soft=Texel(softScene,uv).rgb;
 // Two unequal focus ramps: distant background and a softer foreground.
 float away=abs(focusY-uv.y);
 float blur=smoothstep(focusSettings.x,focusSettings.y,focusY-uv.y)*focusSettings.z;
 blur+=smoothstep(lowerFocus.x,lowerFocus.y,uv.y-focusY)*bottomBlur;
 blur=max(blur,smoothstep(.32,.50,abs(uv.x-.5))*edgeBlur);
 blur=max(blur,softness*smoothstep(focusSettings.x,focusSettings.x+.08,away));
 vec3 rgb=mix(sharp,soft,blur);
 float lum=dot(soft,vec3(.2126,.7152,.0722));
 rgb+=mix(soft*smoothstep(glowThreshold.x,glowThreshold.y,lum),Texel(emissionScene,uv).rgb,maskedGlow)*glowAmount;
 rgb+=Texel(bloomScene,uv).rgb*bloomIntensity;
 rgb+=Texel(raysScene,uv).rgb*raysAmount;
 rgb*=exposure;rgb=mix(rgb,aces(rgb),acesAmount);
 if(lutAmount>0.0)rgb=mix(rgb,mix(grade(lutA,rgb),grade(lutB,rgb),lutMix),lutAmount);
 float edge=dot(uv-.5,uv-.5);
 rgb*=1.0-smoothstep(.15,.49,edge)*vignetteAmount;
 float midtone=4.0*clamp(lum,0.0,1.0)*(1.0-clamp(lum,0.0,1.0));
 rgb*=mix(vec3(1.0),vec3(1.16,1.025,.84),warmAmount*midtone);
 float luminance=dot(rgb,vec3(.2126,.7152,.0722));
 rgb=max(vec3(0.0),mix(vec3(luminance),rgb,saturation));
 // Optional legacy shoulder; disabled in the contrast-first preset.
 float peak=max(rgb.r,max(rgb.g,rgb.b));
 float mappedPeak=peak>.9?.9+.1*(1.0-exp(-10.0*(peak-.9))):peak;
 rgb=mix(rgb,rgb*(mappedPeak/max(peak,.0001)),toneMapping);
 float noise=fract(52.9829189*fract(dot(screen,vec2(.06711056,.00583715))));
 rgb+=(noise-.5)*ditherAmount;
 return vec4(rgb,1.0)*c;
}
]]
F.baseShaderSource=finishSource
-- Compile the original arithmetic when every new finish effect is disabled.
-- Multiplying a disabled effect by zero can still change driver reassociation
-- and round an 8-bit output differently. Keep the active source unchanged.
local legacyStart=assert(finishSource:find('uniform Image softScene;',1,true))
local legacyFinishSource=finishSource:sub(legacyStart)
for _,block in ipairs{
 ' rgb+=Texel(bloomScene,uv).rgb*bloomIntensity;\n',
 ' rgb+=Texel(raysScene,uv).rgb*raysAmount;\n',
 ' rgb*=exposure;rgb=mix(rgb,aces(rgb),acesAmount);\n',
 ' if(lutAmount>0.0)rgb=mix(rgb,mix(grade(lutA,rgb),grade(lutB,rgb),lutMix),lutAmount);\n',
 ' float noise=fract(52.9829189*fract(dot(screen,vec2(.06711056,.00583715))));\n rgb+=(noise-.5)*ditherAmount;\n',
}do
 local first,last=assert(legacyFinishSource:find(block,1,true))
 legacyFinishSource=legacyFinishSource:sub(1,first-1)..legacyFinishSource:sub(last+1)
end
function F.buildShaderSource()
 local source=finishSource
 local function insert(slot,marker)
  local text=Seams.shader(slot);if text==''then return end
  local at=assert(source:find(marker,1,true),'missing finish seam '..slot)
  source=source:sub(1,at-1)..text..source:sub(at)
 end
 insert('finish.uniforms','uniform float acesAmount;')
 insert('finish.functions','vec4 effect(vec4 c,Image tex,vec2 uv,vec2 screen)')
 insert('finish.pre',' rgb*=exposure;')
 insert('finish.post',' return vec4(rgb,1.0)*c;')
 return source
end
function F.apply(canvas,outdoors,focusY,windowAmount,cave,mapView,def,emission,context)
 local ctx=context and context.frameCtx or emptyContext
 canvas=Seams.chain('beforeFinish',canvas,ctx)
 local cfg=V.require('DioramaConfig').post
 local dofScale=mapView and mapView.dofScale or 1
 if not cfg.enabled then return Seams.chain('afterFinish',canvas,ctx)end
 -- Small Emerald rooms stay in focus across their entire floor plan.
 local crispRoom=def and V.data('Emerald').map(def) and (tonumber(def.mapType)==8 or tonumber(def.mapType)==9)
 local focusAllowed=not crispRoom and not (context and context.disabled)
 local cocRequested=cfg.depthOfField and cfg.coc and cfg.coc.enabled
 local dof=cfg.depthOfField and focusAllowed and not cocRequested
 local softness=cfg.softness and focusAllowed and not cocRequested
 local rig=outdoors and V.require('DioramaConfig').cycle.enabled and V.require('TimeOfDay').sample(V.require('DayNight').time())
 local cc=V.require('DioramaConfig').caves
 local glow=cave and (cfg.bloom and cc.glowEnabled and cc.glowStrength or 0)or(cfg.bloom and cfg.bloomStrength*(outdoors and (rig and rig.bloom or windowAmount or 0)or 1)or 0)
 if emission then glow=cfg.bloom and V.require('RoomEmission').profile(def).bloom or 0 end
 local warm=(cfg.warmGrading and cfg.warmStrength or 0)+(rig and rig.warm or 0)
 local hdr=cfg.hdr and canvas:getFormat()=='rgba16f'
 local w,h=canvas:getDimensions();local bw,bh=math.ceil(w/2),math.ceil(h/2)
 if not F.output or F.output:getWidth()~=w or F.output:getHeight()~=h or F.hdr~=hdr then
  F.releaseTargets();F.hdr=hdr
  F.a=love.graphics.newCanvas(bw,bh,{format=hdr and 'rgba16f' or 'rgba8',dpiscale=1});F.b=love.graphics.newCanvas(bw,bh,{format=hdr and 'rgba16f' or 'rgba8',dpiscale=1})
  F.output=love.graphics.newCanvas(w,h,{dpiscale=1})
  F.a:setFilter('linear','linear');F.b:setFilter('linear','linear');F.output:setFilter('nearest','nearest')
 end
 F.prepare(ctx.lutOverride==nil)
 local cocActive=cocRequested and focusAllowed and F.depthShader and DepthFocus.apply(canvas,context,cfg.coc,dofScale)
 if cocRequested then
  local tilt=math.max(0,math.min(1,cfg.coc.tiltAmount or 0))
  dof=cocActive and tilt>0;dofScale=dofScale*tilt
 end
 love.graphics.push('all');love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode()
 love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('replace','premultiplied')
 -- Blur the composed scene with adjacent samples and repeated passes.
 -- Widely spaced taps on nearest art create duplicate edges/vertical bands.
 local needsBlur=(dof or (not hdr and cfg.bloom) or softness)and(dof or glow~=0 or softness or warm~=0)
 local needsSoft=needsBlur or not hdr or warm~=0
 local softScene=needsSoft and F.a or canvas
 if needsSoft then
 local minFilter,magFilter,anisotropy=canvas:getFilter()
 canvas:setFilter('linear','linear')
 love.graphics.setShader();love.graphics.setCanvas(F.a);love.graphics.draw(canvas,0,0,0,bw/w,bh/h)
 canvas:setFilter(minFilter,magFilter,anisotropy)
 end
 love.graphics.setShader(F.blur)
 -- Preserve the legacy warm-only path (unblurred when bloom/DOF are off).
 -- If blur was enabled, warm grading still consumes its luminance.
 for pass=1,(needsBlur and math.max(1,math.min(hdr and 2 or 4,math.floor(cfg.blurRadius or 1)))or 0)do
  scratch.step[1],scratch.step[2]=1/bw,0;F.blur:send('stepUV',scratch.step);love.graphics.setCanvas(F.b);love.graphics.draw(F.a)
  scratch.step[1],scratch.step[2]=0,1/bh;F.blur:send('stepUV',scratch.step);love.graphics.setCanvas(F.a);love.graphics.draw(F.b)
 end
 if emission and not hdr then
  if not F.glowA then
   F.glowA=love.graphics.newCanvas(bw,bh,{format=hdr and 'rgba16f' or 'rgba8',dpiscale=1});F.glowB=love.graphics.newCanvas(bw,bh,{format=hdr and 'rgba16f' or 'rgba8',dpiscale=1})
   F.glowA:setFilter("linear","linear");F.glowB:setFilter("linear","linear")
  end
  love.graphics.setShader();love.graphics.setCanvas(F.glowA);love.graphics.draw(emission,0,0,0,bw/w,bh/h)
  love.graphics.setShader(F.blur)
  for pass=1,math.max(1,math.min(4,math.floor(cfg.blurRadius or 1)))do
   scratch.step[1],scratch.step[2]=1/bw,0;F.blur:send('stepUV',scratch.step);love.graphics.setCanvas(F.glowB);love.graphics.draw(F.glowA)
   scratch.step[1],scratch.step[2]=0,1/bh;F.blur:send('stepUV',scratch.step);love.graphics.setCanvas(F.glowA);love.graphics.draw(F.glowB)
  end
 end
 local atmosphere=V.require('DioramaConfig').atmosphere
 local rays=hdr and atmosphere and V.require('GodRays').apply(canvas,context,atmosphere.godRays)or nil
 local solar=rig or V.require('TimeOfDay').sample(V.require('DayNight').time())
 local bloomAllowed=cfg.bloom and not(cfg.bloomNightOnly and (rig and rig.bloom or 0)==0 and (solar.night or 0)<.5 and not emission and not cave)
 local bloom=hdr and bloomAllowed and V.require('HdrBloom').apply(canvas,cfg,emission,glow) or nil
 love.graphics.setCanvas(F.output);love.graphics.setShader(F.finish)
 if F.depthShader then DepthFocus.bind(F.finish,context,cocActive,canvas)end
 if not F.legacyShader then
  F.finish:send('bloomScene',bloom or F.a);F.finish:send('bloomIntensity',bloom and (cfg.bloomIntensity or .35) or 0)
  F.finish:send('raysScene',rays or F.a);F.finish:send('raysAmount',rays and 1 or 0)
  F.finish:send('ditherAmount',cfg.dither and math.min(1/255,math.max(0,cfg.ditherAmount or 1/255)) or 0)
 end
 F.finish:send('emissionScene',emission and not hdr and F.glowA or F.a);F.finish:send('maskedGlow',emission and not hdr and 1 or 0)
 F.finish:send('softScene',softScene);F.finish:send('focusY',focusY or .5)
 scratch.focus[1],scratch.focus[2],scratch.focus[3]=cfg.focusBand,cfg.blurReach,dof and cfg.blurStrength*dofScale*(outdoors and (rig and rig.dof or 1)or .3)or 0
 F.finish:send('focusSettings',scratch.focus)
 F.finish:send('glowThreshold',cave and cc.glowThreshold or scratch.threshold)
 F.finish:send('glowAmount',hdr and 0 or glow)
 F.finish:send('vignetteAmount',cfg.vignette and cfg.vignetteStrength or 0)
 local graded=not F.legacyShader and V.require('ColorGrade').send(F.finish,cfg,rig,canvas,ctx.lutOverride)or 0
 -- The legacy scene is already lit for display. Unit-exposure ACES would
 -- lift 18% grey to 27%, washing out nights and caves. Anchor that midpoint
 -- while retaining the HDR shoulder; disabling ACES keeps legacy exposure.
 if not F.legacyShader then
  F.finish:send('acesAmount',cfg.aces and 1 or 0)
  F.finish:send('exposure',math.max(.01,cfg.exposure or 1)*(cfg.aces and math.max(.01,cfg.acesExposure or .72)or 1))
 end
 F.finish:send('warmAmount',graded>0 and 0 or warm)
 scratch.lower[1],scratch.lower[2]=cfg.lowerFocusBand,cfg.lowerBlurReach;F.finish:send('lowerFocus',scratch.lower)
 F.finish:send('bottomBlur',dof and cfg.bottomBlurStrength*dofScale*(rig and rig.foregroundDof or 1)or 0)
 F.finish:send('edgeBlur',dof and cfg.edgeBlurStrength*dofScale*(rig and rig.dof or 1)or 0)
 F.finish:send('softness',softness and cfg.softnessStrength or 0)
 F.finish:send('toneMapping',cfg.toneMapping and 1 or 0)
 F.finish:send('saturation',graded>0 and 1 or (cfg.colorGrading and cfg.saturation or 1))
 love.graphics.draw(canvas);love.graphics.pop()
 return Seams.chain('afterFinish',F.output,ctx)
end
-- Shader programs do not depend on target dimensions or HDR format.
function F.prepare(allowLegacy)
 local cfg=V.require('DioramaConfig').post
 -- Renderer prewarms without the frame's LUT override. Retain the last
 -- apply decision so prewarm cannot switch programs back on every frame.
 if allowLegacy~=nil then F.allowLegacy=allowLegacy end
 if F.seamVersion~=Seams.version then
  local current=F.buildShaderSource()
  -- The shared seam generation also changes for world snippets and Lua
  -- hooks. Rebuild only when this pass's actual source has changed.
  if current~=F.seamSource then
   if F.finish then F.finish:release();F.finish=nil end
   F.seamSource=current
  end
  F.seamVersion=Seams.version
 end
 local legacy=F.allowLegacy~=false and F.seamSource==finishSource and not cfg.hdr and not cfg.aces
  and (cfg.lutAmount or 0)<=0 and not cfg.dither and (cfg.exposure or 1)==1
  and not(cfg.depthOfField and cfg.coc and cfg.coc.enabled)
 if F.legacyShader~=legacy then
  if F.finish then F.finish:release();F.finish=nil end
  F.legacyShader=legacy
 end
 if not F.blur then F.blur=V.require('ShaderCompiler').newShader(blurSource)end
 if not F.finish then
  if legacy then
   F.finish=V.require('ShaderCompiler').newShader(legacyFinishSource);F.depthShader=false
  else
  local current=F.seamSource
  local source=DepthFocus.finishUniforms..current:gsub('vec3 rgb=mix%(sharp,soft,blur%);','vec3 rgb=mix(sharp,soft,blur);if(cocActive>.5)rgb=depthFocus(rgb,uv);')
  local ok,shader=pcall(V.require('ShaderCompiler').newShader,source)
  if not ok and current~=finishSource then
   Seams.failShaders(shader);F.seamVersion=Seams.version;current=F.buildShaderSource();F.seamSource=current
   source=DepthFocus.finishUniforms..current:gsub('vec3 rgb=mix%(sharp,soft,blur%);','vec3 rgb=mix(sharp,soft,blur);if(cocActive>.5)rgb=depthFocus(rgb,uv);')
   ok,shader=pcall(V.require('ShaderCompiler').newShader,source)
  end
  F.depthShader=ok
  if ok then F.finish=shader else DepthFocus.disable(shader);F.finish=V.require('ShaderCompiler').newShader(current)end
  end
 end
 if not legacy and cfg.coc and cfg.coc.enabled and DepthFocus.supported()then DepthFocus.prepare()end
end
function F.releaseTargets()
 V.require('HdrBloom').releaseTargets();DepthFocus.releaseTargets();V.require('GodRays').releaseTargets()
 F.hdr=nil
 for _,name in ipairs({'a','b','glowA','glowB','output'})do if F[name]then F[name]:release();F[name]=nil end end
end
function F.release()
 F.releaseTargets();V.require('HdrBloom').release();DepthFocus.release();V.require('GodRays').release();F.depthShader=nil
 F.allowLegacy=nil
 for _,name in ipairs{'blur','finish'}do if F[name]then F[name]:release();F[name]=nil end end
end
return F
