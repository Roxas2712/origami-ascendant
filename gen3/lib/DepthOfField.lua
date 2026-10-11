-- Depth-driven paper focus. Two separable half-resolution layers keep near
-- silhouettes out of the far blur; their premultiplied coverage softens edges.
local V=...
-- Depth focus is a built-in effect, independent of optional render Cards.
local seamsOK,Seams=pcall(V.require,'core/RenderSeams')
if not seamsOK then Seams=nil end
local D={projection={},inverse={},augmented={},direction={0,0,-1},focus={0,0,0},
 params={32,48,1,.6},step={0,0},size={1,1},context={point={0,0,0}},targets={}}
D.uniforms=[[
uniform float cocActive;
uniform Image cocDepth;
uniform mat4 cocInverse;
uniform vec3 cocDirection;
uniform vec3 cocFocus;
uniform vec4 cocParams; // sharp band, ramp distance, near, far
uniform Image cocDistance;
uniform float cocDistanceActive;
float signedCoC(vec2 uv){
 vec4 distanceSample=vec4(0.0);
 if(cocDistanceActive>.5)distanceSample=Texel(cocDistance,uv);
 float delta;
 if(distanceSample.a>.01)delta=distanceSample.r;
 else{
  float z=Texel(cocDepth,uv).r;if(z>=.999999)return 0.0;
  vec4 p=cocInverse*vec4(uv*2.0-1.0,z*2.0-1.0,1.0);
  delta=dot(p.xyz/p.w-cocFocus,cocDirection);
 }
 float c=smoothstep(cocParams.x,cocParams.x+cocParams.y,abs(delta));
 return delta<0.0?-c*cocParams.z:c*cocParams.w;
}
]]
D.finishUniforms=D.uniforms..[[
uniform Image cocFarScene;
uniform Image cocNearScene;
uniform vec2 cocSize;
vec3 depthFocus(vec3 sharp,vec2 uv){
 float coc=signedCoC(uv);vec3 result=sharp;
 if(coc>0.0){
  // Full-resolution depth gates the upsample, preserving sharp sprite edges.
  vec2 at=uv*cocSize-.5,cell=floor(at),f=fract(at);vec3 rgb=vec3(0.0);float sum=0.0;
  for(int y=0;y<2;y++)for(int x=0;x<2;x++){
   vec2 p=(cell+vec2(float(x),float(y))+.5)/cocSize;
   vec4 s=Texel(cocFarScene,p);float w=(x==0?1.0-f.x:f.x)*(y==0?1.0-f.y:f.y);
   w*=step(coc*.75,s.a*2.0-1.0+.025);rgb+=s.rgb*w;sum+=w;
  }
  if(sum>.0001)result=mix(sharp,rgb/sum,clamp(coc,0.0,1.0));
 }
 vec4 nearLayer=Texel(cocNearScene,uv);
 return result*(1.0-nearLayer.a)+nearLayer.rgb;
}
]]
local prefilter=D.uniforms..[[
vec4 effect(vec4 c,Image scene,vec2 uv,vec2 screen){
 return vec4(Texel(scene,uv).rgb,.5+.5*signedCoC(uv));
}
]]
local blur=[[
uniform vec2 cocStep;
uniform float nearPass;
uniform float verticalPass;
uniform Image cocMetadata;
vec4 effect(vec4 c,Image scene,vec2 uv,vec2 screen){
 vec4 center=Texel(scene,uv);float radius=max(0.0,center.a*2.0-1.0);
 vec4 result=vec4(0.0);float total=0.0;
 for(int i=-4;i<=4;i++){
  float fi=float(i);vec2 p=clamp(uv+cocStep*fi,vec2(0.0),vec2(1.0));
  vec4 s=Texel(scene,p);float w=exp(-fi*fi/8.0);
  if(nearPass>.5){
   if(verticalPass<.5){
    float nearAmount=max(0.0,1.0-s.a*2.0);
    float reach=1.0-smoothstep(nearAmount*4.0,nearAmount*4.0+1.0,abs(fi));
    result+=vec4(s.rgb*nearAmount,nearAmount)*w*reach;
   }else{
    float nearAmount=max(max(0.0,1.0-Texel(cocMetadata,p).a*2.0),s.a);
    float reach=1.0-smoothstep(nearAmount*4.0,nearAmount*4.0+1.0,abs(fi));
    result+=s*w*reach;
   }
   total+=w;
  }else{
   float tapRadius=s.a*2.0-1.0;
   w*=step(radius*.75,tapRadius+.025);result.rgb+=s.rgb*w;total+=w;
  }
 }
 if(nearPass>.5)return result/max(total,.0001);
 return vec4(total>.0001?result.rgb/total:center.rgb,center.a);
}
]]
local function disable(reason)
 D.failed=true
 if V.mod and V.mod.log then V.mod.log:info('Depth focus disabled: '..tostring(reason))end
end
D.disable=disable
function D.prepare()
 if D.failed then return false end
 if D.prefilter then return true end
 local ok,a=pcall(V.require('ShaderCompiler').newShader,prefilter)
 if not ok then disable(a);return false end
 local valid,b=pcall(V.require('ShaderCompiler').newShader,blur)
 if not valid then a:release();disable(b);return false end
 D.prefilter,D.blur=a,b;return true
end
function D.supported()
 if D.failed then return false end
 if D.readableDepth==nil then D.readableDepth=love.graphics.getCanvasFormats(true).depth24==true end
 if not D.readableDepth then disable('readable depth24 unavailable');return false end
 return true
end
-- In-place Gauss-Jordan: moving cameras do not allocate inverse matrices.
function D.projectionFor(vp,scale)
 scale=scale or 1;local changed=D.depthScale~=scale
 for i=1,16 do if D.projection[i]~=vp[i]then changed=true end end
 if not changed then return D.inverse end
 local a=D.augmented
 for r=1,4 do for c=1,8 do
  local i=(r-1)*4+c
  a[(r-1)*8+c]=c<=4 and vp[i]*(r==3 and scale or 1)or(c-4==r and 1 or 0)
 end end
 for c=1,4 do
  local pivot=c
  for r=c+1,4 do if math.abs(a[(r-1)*8+c])>math.abs(a[(pivot-1)*8+c])then pivot=r end end
  if math.abs(a[(pivot-1)*8+c])<1e-12 then return nil end
  for k=1,8 do local i,j=(c-1)*8+k,(pivot-1)*8+k;a[i],a[j]=a[j],a[i]end
  local v=a[(c-1)*8+c];for k=1,8 do local i=(c-1)*8+k;a[i]=a[i]/v end
  for r=1,4 do if r~=c then local f=a[(r-1)*8+c]
   for k=1,8 do local i=(r-1)*8+k;a[i]=a[i]-f*a[(c-1)*8+k]end
  end end
 end
 for r=1,4 do for c=1,4 do D.inverse[(r-1)*4+c]=a[(r-1)*8+c+4]end end
 for i=1,16 do D.projection[i]=vp[i]end;D.depthScale=scale
 return D.inverse
end
function D.bindProjection(shader,depth)
 shader:send('cocDepth',depth);shader:send('cocInverse','row',D.inverse)
 shader:send('cocDirection',D.direction);shader:send('cocFocus',D.focus);shader:send('cocParams',D.params)
 shader:send('cocDistance',D.distanceSource or depth);shader:send('cocDistanceActive',D.distanceSource and 1 or 0)
end
function D.apply(source,context,cfg,scale)
 if not context or context.disabled or not context.depth or not D.supported()or not D.prepare()then return false end
 if not D.projectionFor(context.vp,context.depthScale)then disable('singular projection');return false end
 local direction=D.direction;local len=0
 local point=Seams and Seams.chain('focusPoint',context.point,context)or context.point
 for i=1,3 do direction[i]=context.target[i]-context.eye[i];len=len+direction[i]^2;D.focus[i]=point[i]end
 len=math.sqrt(len);if len<.001 then return false end
 for i=1,3 do direction[i]=direction[i]/len end
 D.params[1],D.params[2]=math.max(0,cfg.sharpRange or 32),math.max(1,cfg.focusRange or 48)
 D.params[3],D.params[4]=math.max(0,math.min(1,cfg.near or 1))*(scale or 1),math.max(0,math.min(1,cfg.far or .6))*(scale or 1)
 local w,h=source:getDimensions();local bw,bh=math.max(1,math.ceil(w/2)),math.max(1,math.ceil(h/2));local format=source:getFormat()
 if D.width~=bw or D.height~=bh or D.format~=format then
  D.releaseTargets()
  local ok,err=pcall(function()for _,name in ipairs{'meta','farH','farV','nearH','nearV'}do
   local t=love.graphics.newCanvas(bw,bh,{format=format,dpiscale=1});t:setFilter('nearest','nearest');D.targets[name]=t
  end end)
  if not ok then D.releaseTargets();disable(err);return false end
  D.targets.nearV:setFilter('linear','linear');D.width,D.height,D.format=bw,bh,format
 end
 -- Resolve after target allocation: resizing clears the previous frame's source.
 -- Alpha marks visible geometry with a corrected architectural projection.
 D.distanceSource=Seams and Seams.chain('focusMetadata',false,context)or nil
 local t=D.targets;local g=love.graphics
 g.push('all');g.origin();g.setScissor();g.setDepthMode();g.setColor(1,1,1,1);g.setBlendMode('replace','premultiplied')
 g.setCanvas(t.meta);g.setShader(D.prefilter);D.bindProjection(D.prefilter,context.depth)
 local min,mag,anis=source:getFilter();source:setFilter('nearest','nearest');g.draw(source,0,0,0,bw/w,bh/h);source:setFilter(min,mag,anis)
 g.setShader(D.blur);D.blur:send('cocMetadata',t.meta)
 local radius=math.max(.25,cfg.radius or 3)*(h/708)/4
 for layer=0,1 do local near=layer==1
  D.blur:send('nearPass',near and 1 or 0);D.blur:send('verticalPass',0)
  D.step[1],D.step[2]=radius/bw,0;D.blur:send('cocStep',D.step)
  g.setCanvas(near and t.nearH or t.farH);g.draw(t.meta)
  D.blur:send('verticalPass',1);D.step[1],D.step[2]=0,radius/bh;D.blur:send('cocStep',D.step)
  g.setCanvas(near and t.nearV or t.farV);g.draw(near and t.nearH or t.farH)
 end
 g.pop();D.size[1],D.size[2]=bw,bh;return true
end
function D.bind(shader,context,active,fallback)
 shader:send('cocActive',active and 1 or 0)
 if active then
  D.bindProjection(shader,context.depth);shader:send('cocFarScene',D.targets.farV);shader:send('cocNearScene',D.targets.nearV);shader:send('cocSize',D.size)
 else shader:send('cocDepth',fallback);shader:send('cocFarScene',fallback);shader:send('cocNearScene',fallback)end
end
function D.releaseTargets()
 D.distanceSource=nil
 for k,t in pairs(D.targets)do t:release();D.targets[k]=nil end;D.width,D.height,D.format=nil,nil,nil
end
function D.release()
 D.releaseTargets();for _,k in ipairs{'prefilter','blur'}do if D[k]then D[k]:release();D[k]=nil end end
 D.failed=nil;D.depthScale=nil;D.readableDepth=nil
end
return D
