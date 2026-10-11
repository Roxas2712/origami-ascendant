-- Depth-aware height fog. Four world-space integration samples, at half
-- resolution; the full-resolution composite rejects samples across geometry.
local V=...
local U=V.require('UniformState')
local F={color={},light={},anchor={},shape={},pocket={},size={}}
local moon={.22,.30,.42};local white={1,1,1};local black={0,0,0}
F.integrate=[[
uniform Image sceneDepth;
uniform mat4 inverseVP;
uniform vec3 cameraEye;
uniform vec2 anchor;
uniform vec4 fogShape; // density, height, time, surge
uniform vec3 fogColor;
uniform vec3 fogLight;
uniform vec3 fogPocket; // inner/outer radius (world pixels), retained centre fog
uniform float ribbonMix;
uniform float preserveRoomVoid;
uniform Image ungradedScene;
uniform vec3 roomVoidColor;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
vec3 worldAt(vec2 uv,float depth){vec4 p=inverseVP*vec4(uv*2.0-1.0,depth*2.0-1.0,1.0);return p.xyz/p.w;}
vec4 effect(vec4 color,Image scene,vec2 uv,vec2 screen){
 float depth=Texel(sceneDepth,uv).r;
 if(depth>=.999999)return vec4(0.0);
 vec3 surface=worldAt(uv,depth);
 vec3 delta=cameraEye-surface;float distance=length(delta);vec3 ray=delta/max(.001,distance);
 float span=min(distance,220.0);
 if(ray.y>.001)span=min(span,max(0.0,(fogShape.y*2.4-surface.y)/ray.y));
 float tau=0.0,light=0.0;
 for(int i=0;i<4;i++){
  vec3 p=surface+ray*(float(i)+.5)*span*.25;
  vec2 drift=vec2(fogShape.z*1.7,-fogShape.z*.6);
  vec2 w=p.xz+vec2(p.y*.35,-p.y*.22);
  float bank=noise((w+drift)*.012)*.67+noise((w-drift*.6)*.033+17.0)*.33;
  float wisps=noise((w+drift*.35)*vec2(.025,.065)+bank*2.0);
  float shape=mix(1.0,.30+bank*.90+wisps*.35,ribbonMix);
  float height=exp(-max(0.0,p.y)/fogShape.y);
  float pocket=smoothstep(fogPocket.x,fogPocket.y,length((p.xz-anchor)*vec2(1.0,1.15)));
  float d=shape*height*mix(fogPocket.z,1.0,pocket);
  tau+=d;light+=d*(.30+.50*bank+.20*wisps);
 }
 float opacity=min(.88,1.0-exp(-tau*span*.25*.026*(fogShape.x+fogShape.w*.10)));
 vec3 scatter=mix(fogColor,fogLight,clamp(light/max(tau,.0001),0.0,1.0));
 // Luminous surfaces keep a restrained coloured glow inside the mist.
 vec3 behind=Texel(scene,uv).rgb;
 // Room shells draw opaque near-black cutaway masks into depth too.
 vec3 raw=Texel(ungradedScene,uv).rgb;vec3 voidDelta=abs(raw-roomVoidColor);
 float voidPixel=max(1.0-step(.0035,max(voidDelta.r,max(voidDelta.g,voidDelta.b))),1.0-step(.0035,max(raw.r,max(raw.g,raw.b))));
 opacity*=1.0-preserveRoomVoid*voidPixel;
 float glow=smoothstep(.58,.95,max(behind.r,max(behind.g,behind.b)));
 scatter+=behind*glow*.10;
 return vec4(scatter*opacity,opacity);
}
]]
F.composite=[[
uniform Image fogLayer;
uniform Image sceneDepth;
uniform mat4 inverseVP;
uniform vec2 fogSize;
vec3 worldAt(vec2 uv){float d=Texel(sceneDepth,uv).r;vec4 p=inverseVP*vec4(uv*2.0-1.0,d*2.0-1.0,1.0);return p.xyz/p.w;}
vec4 effect(vec4 color,Image scene,vec2 uv,vec2 screen){
 vec4 base=Texel(scene,uv);if(Texel(sceneDepth,uv).r>=.999999)return base;
 vec3 p=worldAt(uv);vec2 at=uv*fogSize-.5,cell=floor(at),f=fract(at);
 vec4 fog=vec4(0.0);float weight=0.0;
 for(int y=0;y<2;y++)for(int x=0;x<2;x++){
  vec2 q=clamp((cell+vec2(float(x),float(y))+.5)/fogSize,vec2(.5)/fogSize,vec2(1.0)-vec2(.5)/fogSize);
  vec3 other=worldAt(q);
  float w=(x==0?1.0-f.x:f.x)*(y==0?1.0-f.y:f.y);
  w*=exp(-abs(p.y-other.y)*.45-length(p.xz-other.xz)*.06);
  fog+=Texel(fogLayer,q)*w;weight+=w;
 }
 fog=weight>.0001?fog/weight:Texel(fogLayer,uv);
 return vec4(base.rgb*(1.0-fog.a)+fog.rgb,base.a)*color;
}
]]
function F.prepareShaders()
 if not F.shader then F.shader=V.require('ShaderCompiler').newShader(F.integrate)end
 if not F.compose then F.compose=V.require('ShaderCompiler').newShader(F.composite)end
end
function F.apply(source,vp,x,z,time,c,context)
 local g=love.graphics;local w,h=source:getDimensions()
 F.prepareShaders()
 local fw,fh=math.max(1,math.ceil(w/2)),math.max(1,math.ceil(h/2))
 if not F.layer or F.layer:getWidth()~=fw or F.layer:getHeight()~=fh or F.layer:getFormat()~=source:getFormat() then
  if F.layer then F.layer:release()end
  F.layer=g.newCanvas(fw,fh,{format=source:getFormat(),dpiscale=1});F.layer:setFilter('nearest','nearest')
 end
 F.outputs=F.outputs or{}
 local out
 for i=1,2 do
  local b=F.outputs[i]
  if not b or b:getWidth()~=w or b:getHeight()~=h or b:getFormat()~=source:getFormat() then
   if b then b:release()end;b=g.newCanvas(w,h,{format=source:getFormat(),dpiscale=1});b:setFilter('nearest','nearest');F.outputs[i]=b
  end
  if b~=source and not out then out=b end
 end
 -- Interior cutaways compress clip Z; reconstruct from that same projection.
 -- The same projection feeds several fog layers and stationary frames. Cache
 -- by its values, not table identity (camera matrices may mutate in place).
 local scale=context.depthScale or 1
 local unchanged=F.projection and F.depthScale==scale
 if unchanged then for i=1,16 do if F.projection[i]~=vp[i]then unchanged=false;break end end end
 if not unchanged then
  F.projection=F.projection or {};local adjusted=F.adjustedProjection or {};F.adjustedProjection=adjusted
  for i=1,16 do F.projection[i]=vp[i];adjusted[i]=vp[i]*((i>=9 and i<=12)and scale or 1)end
  F.depthScale=scale;F.inverse=V.require('HeatHaze').inverse(adjusted,F.inverse)
 end
 local inverse=F.inverse
 local color,light=F.color,F.light;for i=1,3 do color[i],light[i]=c.color[i],c.light[i]end
 if context.outdoors and not c.preTinted then
  local night=context.solar and context.solar.night or 0
  local tint=context.solar and context.solar.sunColor or white
  for i=1,3 do local moon=moon[i]
   color[i]=color[i]*((1-night)+moon*night)
   light[i]=light[i]*((1-night)*(.85+.15*tint[i])+moon*night)
  end
 end
 local s=F.shader
 F.anchor[1],F.anchor[2]=x+8,z+8
 F.shape[1],F.shape[2],F.shape[3],F.shape[4]=c.density,c.height or(context.outdoors and 42 or 24),time,c.surge and V.require('HauntedFog').surge(time)or 0
 F.pocket[1],F.pocket[2],F.pocket[3]=c.pocket[1]*16,c.pocket[2]*16,c.clearCore or .45
 F.size[1],F.size[2]=fw,fh
 U.send(s,'sceneDepth',context.depth);U.send(s,'inverseVP','row',inverse);U.send(s,'cameraEye',context.eye)
 U.send(s,'anchor',F.anchor);U.send(s,'fogShape',F.shape)
 U.send(s,'fogColor',color);U.send(s,'fogLight',light);U.send(s,'preserveRoomVoid',context.ungradedScene and not context.outdoors and 1 or 0)
 U.send(s,'ungradedScene',context.ungradedScene or source);U.send(s,'roomVoidColor',context.voidColor or black)
 U.send(s,'fogPocket',F.pocket);U.send(s,'ribbonMix',c.ribbonMix or .65)
 U.send(F.compose,'sceneDepth',context.depth);U.send(F.compose,'inverseVP','row',inverse)
 U.send(F.compose,'fogLayer',F.layer);U.send(F.compose,'fogSize',F.size)
 g.push('all');g.origin();g.setDepthMode();g.setScissor();g.setColor(1,1,1,1)
 g.setCanvas(F.layer);g.setShader(s)
 if F.batching then
  if F.layers==0 then g.clear(0,0,0,0)end
  g.setBlendMode('alpha','premultiplied');g.draw(source,0,0,0,fw/w,fh/h)
  F.layers=F.layers+1;F.pendingOutput=out;g.pop();return source
 end
 g.setBlendMode('replace','premultiplied');g.draw(source,0,0,0,fw/w,fh/h)
 g.setCanvas(out);g.setShader(F.compose);g.draw(source);g.pop();F.composites=(F.composites or 0)+1
 return out
end
-- Several regional veils share one half-size accumulation target and one
-- depth-aware full-size resolve. StormDrama may add one independent pass.
function F.begin()F.batching=true;F.layers=0;F.pendingOutput=nil end
function F.finish(source)
 F.batching=false
 if not F.pendingOutput then return source end
 local out=F.pendingOutput;F.pendingOutput=nil
 local g=love.graphics;g.push('all');g.origin();g.setDepthMode();g.setScissor();g.setBlendMode('replace','premultiplied')
 g.setCanvas(out);g.setShader(F.compose);g.setColor(1,1,1,1);g.draw(source);g.pop()
 F.composites=(F.composites or 0)+1;return out
end
function F.release()
 F.batching=false;F.pendingOutput=nil;F.layers=0;F.projection=nil;F.adjustedProjection=nil;F.inverse=nil;F.depthScale=nil
 for _,key in ipairs{'layer','shader','compose'}do if F[key]then F[key]:release();F[key]=nil end end
 for _,b in ipairs(F.outputs or{})do b:release()end;F.outputs=nil
end
return F
