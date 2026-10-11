-- Directional ambient and clear-air depth. No extra render target/readback.
local V=...
local E={means=setmetatable({},{__mode='k'}),samples=0,
 sky={1,1,1},ground={1,1,1},bounce={0,0,0},aerial={160,420,0,.5},
 airColor={0,0,0},forward={0,0,-1},hemi=0,bounceAmount=0,focusDistance=0,ortho=0}
E.uniforms=[[
uniform vec3 skyAmbient;
uniform vec3 groundAmbient;
uniform vec3 bounceColor;
uniform float hemiAmount;
uniform float bounceAmount;
uniform vec4 aerial;
uniform vec3 aerialColor;
uniform vec3 viewForward;
uniform float aerialFocusDistance;
uniform float aerialOrtho;
]]
E.ambient=[[
  vec3 ambientTint=worldTint;
  if(hemiAmount>0.0){
    float up=normal.y*.5+.5;
    vec3 hemi=mix(groundAmbient,skyAmbient,up);
    vec3 directional=worldTint*hemi/max(dot(worldTint,vec3(.2126,.7152,.0722)),.001);
    // Preserve the calibrated exposure: directional hue may change, but
    // hemisphere ambient cannot be brighter than the established ambient.
    float reference=dot(worldTint,vec3(.2126,.7152,.0722));
    directional*=min(1.0,reference/max(dot(directional,vec3(.2126,.7152,.0722)),.001));
    float amount=hemiAmount*(actorFace>.5?.4:1.0);
    ambientTint=mix(worldTint,directional,amount);
    float wall=1.0-abs(normal.y);
    float low=1.0-smoothstep(0.0,24.0,worldPosition.y);
    ambientTint+=bounceColor*wall*low*bounceAmount*(1.0-up)*(actorFace>.5?.4:1.0);
  }
]]
E.fragment=[[
  if(aerial.z>0.0 && caveMode<.5){
    float distance=aerialOrtho>.5?dot(worldPosition-cameraEye,viewForward):length(worldPosition-cameraEye);
    // Distances are measured beyond the focus plane, not from an arbitrary
    // telephoto camera setback. The player stays clear at every zoom level.
    distance=max(0.0,distance-aerialFocusDistance)+aerial.x;
    float ap=smoothstep(aerial.x,aerial.y,distance)*aerial.z;
    float lumA=dot(lit,vec3(.2126,.7152,.0722));
    lit=mix(lit,mix(lit,vec3(lumA),aerial.w),ap);
    lit=mix(lit,aerialColor,ap*.5);
  }
]]
local function luminance(c)return c[1]*.2126+c[2]*.7152+c[3]*.0722 end
local function clamp(x)return math.max(0,math.min(1,x))end
function E.mean(ts,outdoors)
 -- Native tilesets already own CPU ImageData. Reuse it; a Canvas readback
 -- here would reintroduce the map-change stall this renderer is avoiding.
 if not ts or not ts.imageData then return outdoors and E.outdoorFallback or E.indoorFallback end
 local d,over=ts.imageData,ts.overImageData
 local cached=E.means[d];if cached and cached.over==over then return cached.color end
 local r,g,b,n=0,0,0,0
 for y=4,d:getHeight()-1,8 do for x=4,d:getWidth()-1,8 do
  local rr,gg,bb,a=d:getPixel(x,y)
  if over then local ar,ag,ab,aa=over:getPixel(x,y);if aa>.5 then rr,gg,bb,a=ar,ag,ab,aa end end
  if a>.5 then r,g,b,n=r+rr,g+gg,b+bb,n+1 end
 end end
 local color=n>0 and {r/n,g/n,b/n}or(outdoors and E.outdoorFallback or E.indoorFallback)
 E.means[d]={over=over,color=color};E.samples=E.samples+1;return color
end
E.outdoorFallback={.35,.45,.25};E.indoorFallback={.3,.28,.26}
function E.prepare(atmosphere,outdoors,ts,eye,target,projection,fog,time)
 local c=V.require('DioramaConfig');local h=c.lighting.hemisphere;local a=c.atmosphere.aerial
 local ambient=atmosphere.ambient;local light=luminance(ambient)
 local sky=outdoors and V.require('DayNight').windowScene(time).sky or ambient
 local skyLum=math.max(.001,luminance(sky));local night=outdoors and atmosphere.solar and atmosphere.solar.night or 0
 local groundScale=outdoors and (.9-.3*night)or(atmosphere.cave and .5 or .85)
 local mean=E.mean(ts,outdoors);E.meanColor=mean
 for i=1,3 do
  E.sky[i]=outdoors and sky[i]*light/skyLum or light
  E.ground[i]=outdoors and ambient[i]*groundScale or light*groundScale
  -- Indoor/cave bounce is neutral, preserving their authored light palette.
  E.bounce[i]=(outdoors and mean[i]or luminance(mean))*light
  E.airColor[i]=sky[i]*math.min(1,light/skyLum)
 end
 E.hemi=h.enabled and clamp(h.amount)or 0
 E.bounceAmount=h.enabled and math.max(0,h.bounce)*E.hemi or 0
 E.aerial[1]=a.start;E.aerial[2]=math.max(a.start+1,a.finish)
 E.aerial[3]=outdoors and a.enabled and clamp(a.amount)*(1-.7*clamp(fog or 0))or 0
 E.aerial[4]=clamp(a.desaturate)
 local dx,dy,dz=target[1]-eye[1],target[2]-eye[2],target[3]-eye[3]
 E.focusDistance=math.sqrt(dx*dx+dy*dy+dz*dz)
 local length=math.max(.001,E.focusDistance)
 E.forward[1],E.forward[2],E.forward[3]=dx/length,dy/length,dz/length
 E.ortho=projection=='orthographic'and 1 or 0
end
-- Keep the rc.4 assembly untouched; specialize only the compiled disabled
-- variant. A uniform-zero branch changes driver arithmetic at water pixels
-- even though the extra ambient contribution is mathematically zero.
function E.shaderAmbientEnabled()
 local h=V.require('DioramaConfig').lighting.hemisphere
 return h.enabled and (h.amount or 0)>0 or false
end
function E.prepareShader(source,enabled)
 if enabled then return source end
 local first,last=source:find(E.ambient,1,true)
 if not first then return source end
 return source:sub(1,first-1)..'  vec3 ambientTint=worldTint;\n'..source:sub(last+1)
end
function E.bind(shader)
 local U=V.require('UniformState')
 if shader:hasUniform('hemiAmount')then
 U.send(shader,'skyAmbient',E.sky);U.send(shader,'groundAmbient',E.ground)
 U.send(shader,'bounceColor',E.bounce);U.send(shader,'hemiAmount',E.hemi);U.send(shader,'bounceAmount',E.bounceAmount)
 end
 U.send(shader,'aerial',E.aerial);U.send(shader,'aerialColor',E.airColor)
 U.send(shader,'viewForward',E.forward);U.send(shader,'aerialFocusDistance',E.focusDistance);U.send(shader,'aerialOrtho',E.ortho)
end
return E
