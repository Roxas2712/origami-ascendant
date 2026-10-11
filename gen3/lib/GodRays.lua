-- Quarter-resolution sun shafts. Sky/emissive sources also work in vistas;
-- top-down maps use directly sunlit ground gaps from the existing shadow map.
local V=...
local G={source={0,0,1,0},color={1,1,1},params={20,.25,.96,.3},cloud={0,0,520,0}}
local cloudCode=V.require('CloudDaylight')
local maskSource=cloudCode.noise..cloudCode.fragment..[[
uniform Image rayDepth;uniform Image rayShadow;uniform mat4 rayInverse;uniform mat4 rayVP;
uniform float groundGaps;uniform float emissionThreshold;uniform float skyOpen;
vec4 effect(vec4 c,Image scene,vec2 uv,vec2 screen){
 float z=Texel(rayDepth,uv).r;vec3 rgb=Texel(scene,uv).rgb;
 float peak=max(rgb.r,max(rgb.g,rgb.b));
 // Black map void is not a visible sky opening.
 if(z>=.999999)return vec4(skyOpen*smoothstep(.025,.12,peak),skyOpen,0.0,1.0);
 vec4 p=rayInverse*vec4(uv*2.0-1.0,z*2.0-1.0,1.0);vec3 world=p.xyz/p.w;
 // Raised roof/canopy geometry is an occluder, never a ground source.
 vec3 normal=cross(dFdx(world),dFdy(world));
 float up=abs(normal.y)/max(length(normal),.00001);
 float ground=(1.0-smoothstep(2.0,6.0,world.y))*smoothstep(.65,.9,up);
 vec4 floorClip=rayVP*vec4(world.x,.04,world.z,1.0);
 vec2 floorUV=floorClip.xy/floorClip.w*.5+.5;
 float shadow=Texel(rayShadow,clamp(floorUV,vec2(0.0),vec2(1.0))).r;
 float direct=(1.0-smoothstep(.12,.65,shadow))*mix(1.0,cloudTransmission(world.xz),cloudLight.x);
 float emissive=smoothstep(emissionThreshold,emissionThreshold+.6,peak);
 return vec4(max(emissive,ground*direct*groundGaps),ground,0.0,1.0);
}
]]
local raySource=[[
uniform vec4 raySource; // xy: point/direction, z: directional mode
uniform vec4 rayParams; // samples, strength, decay, maximum UV travel
uniform vec3 rayColor;
vec4 effect(vec4 c,Image mask,vec2 uv,vec2 screen){
 vec2 vector=raySource.z>.5?raySource.xy:raySource.xy-uv;
 vector/=max(1.0,length(vector));vec2 stepUV=vector*rayParams.w/rayParams.x;
 vec2 p=uv;float illumination=1.0,total=0.0,weight=0.0;
 for(int i=0;i<24;i++){
  if(float(i)>=rayParams.x)break;p+=stepUV;
  if(p.x<0.0||p.y<0.0||p.x>1.0||p.y>1.0)break;
  total+=Texel(mask,p).r*illumination;weight+=illumination;illumination*=rayParams.z;
 }
 vec4 center=Texel(mask,uv);
 // Constant illumination contributes nothing. Only light crossing a gap
 // leaves a shaft, so the pass cannot bleach a uniformly bright town.
 float shaft=max(0.0,total/max(weight,.0001)-center.r)*center.g;
 return vec4(rayColor*shaft*rayParams.y,0.0);
}
]]
local function disable(reason)
 G.failed=true;if V.mod and V.mod.log then V.mod.log:info('Sun shafts disabled: '..tostring(reason))end
end
function G.supported()
 if G.failed then return false end
 if G.support==nil then local f=love.graphics.getCanvasFormats(true);G.support=f.depth24==true and f.rgba16f==true end
 if not G.support then disable('readable depth24/rgba16f unavailable');return false end
 return true
end
function G.prepare()
 if not G.supported()then return false end
 if G.maskShader then return true end
 local ok,a=pcall(V.require('ShaderCompiler').newShader,maskSource);if not ok then disable(a);return false end
 local valid,b=pcall(V.require('ShaderCompiler').newShader,raySource);if not valid then a:release();disable(b);return false end
 G.maskShader,G.rayShader=a,b;return true
end
local function smooth(a,b,x)local v=math.max(0,math.min(1,(x-a)/(b-a)));return v*v*(3-2*v)end
function G.weight(context,cfg)
 if not cfg or not cfg.enabled or not context or context.disabled or not context.outdoors or not context.solar then return 0 end
 local direction=context.direction;local len=math.sqrt(direction[1]^2+direction[2]^2+direction[3]^2)
 if len<.001 then return 0 end
 local elevation=math.deg(math.asin(math.max(-1,math.min(1,direction[2]/len))))
 local daylight=1-(context.solar.night or 0)
 -- Fade at both ends, rather than popping at the specification's 5°/35° gates.
 local low=smooth(5,10,elevation)*(1-smooth(28,35,elevation))
 local deck=context.cloudLight and context.cloudLight[2]or 0
 local clockGate=1
 if context.time then
  local t=context.time%1200
  clockGate=math.max(1-smooth(120,240,t),smooth(420,520,t)*(1-smooth(590,640,t)))
 end
 return daylight*low*clockGate*(1-smooth(.35,.85,deck))
end
function G.project(context)
 local m,eye,dir=context.vp,context.eye,context.direction
 local x,y,z=eye[1]+dir[1]*10000,eye[2]+dir[2]*10000,eye[3]+dir[3]*10000
 local w=m[13]*x+m[14]*y+m[15]*z+m[16]
 if context.projection~='orthographic' and w>.01 then
  G.source[1]=(m[1]*x+m[2]*y+m[3]*z+m[4])/w*.5+.5
  G.source[2]=(m[5]*x+m[6]*y+m[7]*z+m[8])/w*.5+.5;G.source[3]=0
 else
  -- A sun behind the eye has a valid projected bearing, not a mirrored point.
  local dx=m[1]*dir[1]+m[2]*dir[2]+m[3]*dir[3]
  local dy=m[5]*dir[1]+m[6]*dir[2]+m[7]*dir[3]
  local len=math.sqrt(dx*dx+dy*dy);if len<1e-8 then return false end
  G.source[1],G.source[2],G.source[3]=dx/len,dy/len,1
 end
 return true
end
function G.apply(scene,context,cfg)
 local weight=G.weight(context,cfg);G.lastWeight=weight
 if weight<=0 or not context.depth or not context.shadow or not G.prepare()or not G.project(context)then return nil end
 local inverse=V.require('DepthOfField').projectionFor(context.vp,context.depthScale)
 if not inverse then return nil end
 local w,h=scene:getDimensions();local qw,qh=math.max(1,math.ceil(w/4)),math.max(1,math.ceil(h/4))
 if G.width~=qw or G.height~=qh then
  G.releaseTargets();local ok,err=pcall(function()
   G.mask=love.graphics.newCanvas(qw,qh,{format='rgba8',dpiscale=1})
   G.output=love.graphics.newCanvas(qw,qh,{format='rgba16f',dpiscale=1})
   G.mask:setFilter('linear','linear');G.output:setFilter('linear','linear')
  end)
  if not ok then G.releaseTargets();disable(err);return nil end;G.width,G.height=qw,qh
 end
 G.params[1]=math.max(16,math.min(24,math.floor(cfg.samples or 20)))
 G.params[2]=weight*math.max(0,cfg.strength or .25);G.params[3]=.96;G.params[4]=math.max(0,math.min(1,cfg.travel or .3))
 for i=1,3 do G.color[i]=context.solar.sunColor and context.solar.sunColor[i]or 1 end
 for i=1,4 do G.cloud[i]=context.cloudLight and context.cloudLight[i]or(i==3 and 520 or 0)end
 local g=love.graphics;g.push('all');g.origin();g.setScissor();g.setDepthMode();g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1)
 g.setCanvas(G.mask);g.setShader(G.maskShader)
 G.maskShader:send('rayDepth',context.depth);G.maskShader:send('rayShadow',context.shadow)
 G.maskShader:send('rayInverse','row',inverse);G.maskShader:send('rayVP','row',context.vp)
 G.maskShader:send('groundGaps',cfg.surfaceOpenings==false and 0 or 1);G.maskShader:send('emissionThreshold',cfg.emissionThreshold or 1.2)
 G.maskShader:send('skyOpen',context.hasSky and 1 or 0)
 G.maskShader:send('cloudLight',G.cloud);g.draw(scene,0,0,0,qw/w,qh/h)
 g.setCanvas(G.output);g.setShader(G.rayShader);G.rayShader:send('raySource',G.source);G.rayShader:send('rayParams',G.params);G.rayShader:send('rayColor',G.color);g.draw(G.mask)
 g.pop();return G.output
end
function G.releaseTargets()
 for _,name in ipairs{'mask','output'}do if G[name]then G[name]:release();G[name]=nil end end;G.width,G.height=nil,nil
end
function G.release()
 G.releaseTargets();for _,name in ipairs{'maskShader','rayShader'}do if G[name]then G[name]:release();G[name]=nil end end
 G.failed,G.support=nil,nil
end
return G
