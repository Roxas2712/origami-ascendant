-- Directional, wave-broken light reflections on native water only.
-- Microfacet light plus the clipped planar scene; no gameplay mutation.
local V=...
local W={}
function W.bind(shader,atmosphere,outdoors,weather,mood)
 local c=V.require('DioramaConfig').water.reflections
 local cloud=weather=='storm'and .10 or weather=='rain'and .22 or weather=='fog'and .35 or weather=='snow'and .45 or 1
 local moon=atmosphere.moon
 local color=moon and {.62,.76,1}or atmosphere.solar and atmosphere.solar.sunColor or {1,.93,.76}
 local agitation=weather=='storm'and 1.7 or weather=='rain'and 1.3 or 1
 if mood then cloud=mood.sky;agitation=mood.agitation end
 shader:send('waterReflection',{c.enabled and 1 or 0,math.min(.48,c.roughness*agitation),c.localStrength,c.waveSlope*agitation})
 shader:send('waterSky',{color[1],color[2],color[3],outdoors and cloud*(moon and c.moonStrength or c.sunStrength)*math.max(0,atmosphere.sun or 0)or 0})
end
W.fragment=[[
uniform Image waterScene;
uniform vec2 waterSceneTexel;
uniform Image waterBanks;
uniform vec4 waterBankArea;
uniform float waterSceneEnabled;
uniform vec4 waterReflection; // enabled, roughness, local strength, wave slope
uniform vec4 waterSky; // sun/moon color and weather-weighted radiance
float waterSpecular(vec3 n,vec3 v,vec3 l,float roughness){
 float nl=max(dot(n,l),0.0),nv=max(dot(n,v),0.0);
 if(nl<=0.0 || nv<=0.0)return 0.0;
 vec3 h=normalize(v+l);float nh=max(dot(n,h),0.0);
 float a2=pow(roughness,4.0);
 float d=a2/(3.141593*pow(nh*nh*(a2-1.0)+1.0,2.0));
 float k=pow(roughness+1.0,2.0)/8.0;
 float g=(nv/(nv*(1.0-k)+k))*(nl/(nl*(1.0-k)+k));
 float f=.02+.98*pow(1.0-max(dot(v,h),0.0),5.0);
 return d*g*f/max(.001,4.0*nv);
}
vec3 reflectedWater(vec3 lit,vec3 p,float wet,float shadow,vec2 screenUV){
 if(waterReflection.x<.5 || wet<.5)return lit;
 vec2 q=floor(p.xz*2.0)*.5;float t=waterMotion.x;
 vec3 n=normalize(vec3(waterReflection.w*(sin(q.x*.17+q.y*.07+t*.85)+.4*sin(q.y*.31-t)),1.0,
  waterReflection.w*(cos(q.y*.19-q.x*.08-t*.65)+.35*cos(q.x*.37+t*.7))));
 vec3 view=normalize(cameraEye-p);
 if(waterSceneEnabled>.5){
  vec2 bankUV=(p.xz-waterBankArea.xy)/waterBankArea.zw;
  float depth=Texel(waterBanks,bankUV).r*128.0;
  float shore=smoothstep(3.0,22.0,depth);
  // Beer-Lambert-like depth absorption retains the native blue palette.
  vec3 shallow=lit*vec3(.80,1.02,.92);
  vec3 deep=lit*vec3(.58,.74,.87);
  lit=mix(shallow,deep,1.0-exp(-depth*.025));
  vec2 offset=n.xz*vec2(.013,.010)*shore;
  vec2 uv=screenUV+offset;
  vec2 texel=waterSceneTexel;
  // Small roughness footprint avoids a pristine mirror and hard aliasing.
  vec4 scene=Texel(waterScene,uv)*.4;
  scene+=Texel(waterScene,uv+texel*vec2(1.5,.5))*.15;
  scene+=Texel(waterScene,uv-texel*vec2(1.5,.5))*.15;
  scene+=Texel(waterScene,uv+texel*vec2(.5,1.5))*.15;
  scene+=Texel(waterScene,uv-texel*vec2(.5,1.5))*.15;
  float edge=smoothstep(0.0,.02,min(min(uv.x,uv.y),min(1.0-uv.x,1.0-uv.y)));
  float fresnel=.36+.55*pow(1.0-max(0.0,dot(n,view)),3.0);
  float weight=min(.62,fresnel)*shore*edge;
  lit=lit*(1.0-scene.a*weight)+scene.rgb*weight;
  // Quiet capillary line, not white ocean surf on every pond.
  float lap=sin(depth*.85-t*1.2+sin(q.x*.08+q.y*.11))*.5+.5;
  float bank=exp(-pow((depth-7.0)/3.0,2.0));
  lit+=lit*bank*lap*.12;
 }
 vec3 reflection=waterSky.rgb*waterSky.a*waterSpecular(n,view,normalize(sunDirection),waterReflection.y)*(1.0-shadow)*mix(1.0,cloudTransmission(p.xz),cloudLight.x);
 for(int i=0;i<24;i++){if(i<lightCount){
  vec3 delta=p-localPosition[i].xyz;
  float range=max(0.0,1.0-length(delta)/max(1.0,abs(localPosition[i].w)));
  // Window emitters face the street/water; no mirror behind the facade.
  float outward=localPosition[i].w<0.0?1.0:smoothstep(2.0,12.0,delta.z);
  outward*=1.0-localWallOnly[i];
  reflection+=localColor[i].rgb*localColor[i].a*range*range*outward*waterReflection.z*
   waterSpecular(n,view,normalize(-delta+vec3(0,.001,0)),max(.20,waterReflection.y));
 }}
 // Facades use the same world-space catalogue as their ground spill.
 for(int slot=0;slot<24;slot++){
  float id=staticLightId(slot,p.xz);if(id<.5)break;
  float row=(id-.5)/staticLightRows;
  vec4 position=Texel(staticLightData,vec2(1.0/6.0,row));
  vec4 color=Texel(staticLightData,vec2(.5,row));
  vec4 params=Texel(staticLightData,vec2(5.0/6.0,row));
  vec3 delta=p-position.xyz;
  float range=max(0.0,1.0-length(delta)/max(1.0,abs(position.w)));
  float outward=position.w<0.0?1.0:smoothstep(2.0,12.0,delta.z);
  reflection+=color.rgb*color.a*range*range*outward*(1.0-params.z)*waterReflection.z*
   waterSpecular(n,view,normalize(-delta+vec3(0,.001,0)),max(.20,waterReflection.y));
 }
 // Keep the source color in intense glints without a broad white bloom mask.
 float peak=max(reflection.r,max(reflection.g,reflection.b));
 reflection*=.75*(1.0-exp(-peak/.75))/max(.0001,peak);
 return lit+reflection*wet;
}
]]
return W
