-- Haunted fog (Pokémon Tower upper floors), built on the VASC fog idea:
-- broad drifting ribbons, a slow "surge" that rolls the bank in, and a
-- readable pocket around the player. Unlike the VASC screen overlay the
-- ribbons here are anchored to world space, so they stay put while the
-- camera follows the player, and the pocket follows the player's lamp.
local V=...
local H={}
local code=[[
uniform Image scene;
uniform mat3 groundFromScreen;
uniform vec2 worldAnchor; // player world xz / 16 (tiles)
uniform float time;
uniform float density;
uniform float surge;
uniform vec2 pocket;      // inner, outer radius in tiles
uniform vec3 fogColor;
uniform vec3 fogLight;
uniform float clearCore; // fog left inside the pocket
uniform float preserveVoid;
uniform float ribbonMix; // 0 = even veil, 1 = full VASC ribbons
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){float v=0.0,a=.5;for(int i=0;i<4;i++){v+=a*noise(p);p=p*2.03+vec2(17.0,9.0);a*=.5;}return v;}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 vec4 base=Texel(scene,uv);
 // Reconstruct the fixed world plane from the actual camera. A local
 // pixels-per-tile estimate slides sideways and stretches while walking.
 vec3 ground=groundFromScreen*vec3(uv*2.0-1.0,1.0);
 vec2 w=ground.xy/ground.z/16.0;
 vec2 d=w-worldAnchor;
 // VASC ribbons: long horizontal bands that drift sideways at different speeds.
 float r1=fbm(vec2(w.x*.16-time*.22,w.y*.55+sin(time*.07)*.6));
 float r2=fbm(vec2(w.x*.09+time*.13+11.0,w.y*.38-time*.03));
 float ribbons=smoothstep(.25,.90,r1*.62+r2*.55);
 float wisps=fbm(w*.45+vec2(time*.35,-time*.12));
 // Pocket around the lamp; the surge squeezes it and thickens the bank.
 float dist=length(d*vec2(1.0,1.25));
 float inner=pocket.x*(1.0-.35*surge),outer=pocket.y*(1.0-.25*surge);
 float veil=smoothstep(inner,outer,dist+ (wisps-.5)*1.6);
 // Reference: a smooth, even veil; the ribbons only breathe slowly within it.
 float amount=clamp(density*(1.0-ribbonMix+ribbonMix*ribbons)*(.55+.45*veil)+surge*.18*veil,0.0,.93)*mix(clearCore,1.0,veil);
 vec3 fog=mix(fogColor,fogLight,(ribbons*.45+wisps*.15)*ribbonMix*1.6);
 amount*=mix(1.0,smoothstep(.005,.045,max(base.r,max(base.g,base.b))),preserveVoid);
 return vec4(mix(base.rgb,fog,amount),1.0);
}
]]
local function cfg()return V.require('DioramaConfig').haunted end
function H.active(def)
 local c=cfg()
 if not(c and c.enabled and def)then return false end
 local id=def.id or def.name or ''
 if c.maps[id]then return true end
 for _,pat in ipairs(c.patterns or{})do if id:match(pat)then return true end end
 return false
end
function H.surge(time)
 local s=math.max(0,math.min(1,(math.sin(time*.17+1.4)-.36)/.64))
 return s*s*(3-2*s)
end
-- Generic veil pass. opts overrides the haunted config (forest haze uses it).
function H.apply(canvas,vp,px,pz,time,opts,context)
 local c=opts or H.params()
 if context and context.depth then
  local result=V.require('VolumeFog').apply(canvas,vp,px,pz,time,c,context)
  if not V.require('VolumeFog').batching and not opts and H.wispState and #H.wispState.sprites>0 then
   H.drawWisps(result,vp,time,context)
  end
  return result
 end
 local w,h=canvas:getDimensions()
 if not H.shader then H.shader=V.require('ShaderCompiler').newShader(code)end
 -- ping-pong so two veil passes in one frame never read their own target
 H.bufs=H.bufs or {}
 local out
 for i=1,2 do local b=H.bufs[i]
  if not b or b:getWidth()~=w or b:getHeight()~=h or b:getFormat()~=canvas:getFormat() then if b then b:release() end
   b=love.graphics.newCanvas(w,h,{format=canvas:getFormat(),dpiscale=1});b:setFilter('nearest','nearest');H.bufs[i]=b end
  if b~=canvas and not out then out=b end
 end
 H.out=out
 local C=V.require('Camera')
 local s=H.shader
 s:send('preserveVoid',c.preserveVoid and 1 or 0);s:send('scene',canvas);s:send('groundFromScreen','row',C.groundInverse(vp))
 s:send('worldAnchor',{(px+8)/16,(pz+8)/16})
 s:send('time',time);s:send('density',c.density);s:send('surge',c.surge and H.surge(time)or 0)
 s:send('pocket',c.pocket);s:send('fogColor',c.color);s:send('fogLight',c.light);s:send('clearCore',c.clearCore or .45);s:send('ribbonMix',c.ribbonMix or .65)
 love.graphics.push('all');love.graphics.origin();love.graphics.setCanvas(H.out);love.graphics.setDepthMode()
 love.graphics.setShader(s);love.graphics.setBlendMode('replace','premultiplied');love.graphics.setColor(1,1,1,1)
 love.graphics.draw(canvas);love.graphics.pop()
 -- Will-o'-wisps glow through the bank (drawn after the fog, like the reference).
 if not opts and H.wispState and #H.wispState.sprites>0 then
  H.drawWisps(H.out,vp,time,context)
 end
 return H.out
end
function H.drawWisps(canvas,vp,time,context)
 if not H.wispState or #H.wispState.sprites==0 then return end
 love.graphics.push('all');love.graphics.setDepthMode()
 -- Postprocess colour buffers have no implicit depth attachment. Reuse the
 -- scene depth for occlusion, without clearing or writing it.
 local depth=context and context.depth
 love.graphics.setCanvas(depth and {canvas,depthstencil=depth} or canvas)
 love.graphics.setDepthMode(depth and 'lequal' or 'always',false)
 love.graphics.setBlendMode('add')
 V.require('Atmosphere').draw({shafts={},sprites=H.wispState.sprites,time=time,depthTest=depth~=nil},vp)
 V.require('HauntedWisps').draw(H.wispState.sprites,vp,context and context.depthScale);love.graphics.pop()
end
-- Darkness, FLASH lamp and will-o'-wisps for Atmosphere.prepare.
-- Without FLASH the floor is dark and the player is not lit; FLASH lights the
-- player and pushes the fog and the wisps back (visual only - the native
-- ghost/Silph Scope mechanics are untouched).
H.flash=0
function H.lights(result,px,pz,time,flashOn,def)
 local c=cfg()
 local dt=H.lastTime and math.max(0,math.min(.25,time-H.lastTime)) or 0;H.lastTime=time
 local target=flashOn and 1 or 0
 if target>H.flash then H.flash=math.min(target,H.flash+dt/c.flashRamp) else H.flash=math.max(target,H.flash-dt/c.flashRamp) end
 if dt==0 then H.flash=target end
 local f=H.flash
 for i=1,3 do result.ambient[i]=c.darkAmbient[i]+(c.ambient[i]-c.darkAmbient[i])*f end
 if f>0 then
  result.lights[#result.lights+1]={x=px+8,y=c.lampHeight,z=pz+12,radius=-c.lampRadius,power=c.lampPower*f*(1+.03*math.sin(time*2.1)),
   color=c.lampColor,falloff=c.lampFalloff,kind='haunt'}
 end
 H.wispState={map=def and(def.id or def.name),sprites={}}
 for i=1,c.wisps do
  local x,z=V.require('HauntedWisps').position(def,i,time)
  if x then
  local pulse=(.6+.4*math.sin(time*3.1+i*1.7))*(1-.85*f)
  local l={x=x,y=10+math.sin(time*1.3+i)*3,z=z,radius=-c.wispRadius,power=c.wispPower*pulse,color=c.wispColor,kind='wisp',wispIndex=i,size=c.wispSize,alpha=pulse,stretch=.75,squash=1.35}
  local W=V.require('HauntedWisps');W.touchAmount(def,i,time,x,z,px+8,pz+16)
  result.lights[#result.lights+1]=l;H.wispState.sprites[#H.wispState.sprites+1]=l
  end
 end
 -- Resolve contact ownership after all wisps were sampled, so ambient and
 -- contact events cannot produce two silhouettes or two voices in one frame.
 local W=V.require('HauntedWisps')
 for i,l in ipairs(H.wispState.sprites)do
  l.ghost,l.redEyes=W.presentation(def,l.wispIndex,time,l.x,l.z,px+8,pz+16)
  l.ghost=l.ghost*(1-.85*f);l.alpha=l.alpha*(1-l.ghost)
 end
end
-- Fog parameters for this frame (FLASH thins the bank and widens the pocket).
function H.params()
 local c=cfg();local f=H.flash
 local p={}
 for i=1,2 do p[i]=c.darkPocket[i]+(c.flashPocket[i]-c.darkPocket[i])*f end
 return {density=c.darkDensity+(c.density*c.flashFog-c.darkDensity)*f,surge=c.surge and f<.5,pocket=p,color=c.mistColor or c.color,light=c.mistLight or c.light,height=c.mistHeight or 48,clearCore=.95-.45*f,ribbonMix=c.mistRibbonMix or .65}
end
function H.release()
 H.wispState=nil
 V.require('HauntedVoice').reset()
 V.require('HauntedWisps').release()
 V.require('VolumeFog').release()
 if H.shader then H.shader:release();H.shader=nil end
 for _,b in ipairs(H.bufs or {})do b:release() end;H.bufs=nil;H.out=nil
end
return H
