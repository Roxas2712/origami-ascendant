-- One anchored light value for the whole painted character card.
local V=...
local A={foot={0,0,0,0},fragment={},features=setmetatable({},{__mode='k'}),active=setmetatable({},{__mode='k'})}
A.uniforms=[[
uniform vec4 actorFoot; // world foot xyz, active draw
uniform float actorFootMode;
uniform float actorFragmentSource[24];
uniform int actorFragmentCount;
varying vec2 actorShadowUV;
varying vec3 actorLocalLight;
varying float actorLocalActive;
]]
A.functions=[[
#if defined(VERTEX) && defined(ACTOR_VERTEX_LIGHTING)
vec3 actorSourceEnergy(vec3 foot,vec4 position,vec4 color,float falloffPower,float wallOnly,float point){
 vec3 delta=foot-position.xyz;
 float falloff=max(0.0,1.0-length(delta)/max(abs(position.w),.001));
 float outward=position.w<0.0?1.0:smoothstep(2.0,12.0,delta.z);
 if(position.w>0.0)outward*=pow(max(0.0,delta.z)/max(length(delta.xz),.001),windowConePower);
 float attenuation=falloffPower==2.0?falloff*falloff:pow(falloff,max(.25,falloffPower));
 return color.rgb*color.a*attenuation*1.15*outward*(1.0-wallOnly)*(point>.5?caveActorLight:1.0);
}
vec3 actorLightAt(vec3 foot){
 vec3 energy=vec3(0.0);
 for(int i=0;i<24;i++){
  if(i>=lightCount)break;
  if(actorFragmentSource[i]>.5)continue;
  if((i/4)*4==i){
   vec4 b=localGroupBounds[i/4];
   if(foot.x<b.x || foot.z<b.y || foot.x>b.z || foot.z>b.w){i=(i+3<lightCount?i+3:lightCount-1);continue;}
  }
  vec4 position=localPosition[i],color=localColor[i];
  if(color.a==0.0 || localWallOnly[i]>=1.0 || length(foot-position.xyz)>=abs(position.w))continue;
  vec3 e=actorSourceEnergy(foot,position,color,localFalloff[i],localWallOnly[i],localPoint[i]);
  if(roomSourceDirection[i].w>-1.0 && max(e.r,max(e.g,e.b))>0.0){
   vec3 delta=foot-position.xyz;vec3 ray=delta/max(length(delta),.0001);
   float cone=smoothstep(roomSourceDirection[i].w,min(.99,roomSourceDirection[i].w+.5),dot(normalize(roomSourceDirection[i].xyz),ray));
   e*=roomLightModel.y*cone;
   if(cone>0.0)e*=roomSourceShadow(foot,vec3(0.0,1.0,0.0),position.xyz,roomSourceArea[i],roomReliefTiles[i]);
  }
  energy+=e;
 }
 vec2 cell=floor((foot.xz-staticLightArea.xy)/16.0);
 bool valid=staticLightRows>=.5 && cell.x>=0.0 && cell.y>=0.0 && cell.x<staticLightArea.z && cell.y<staticLightArea.w;
 vec4 ids=vec4(0.0);
 for(int slot=0;slot<24;slot++){
  if(!valid)break;
  int channel=slot-(slot/4)*4;
  if(channel==0)ids=Texel(staticLightGrid,vec2((cell.x*6.0+floor(float(slot)/4.0)+.5)/(staticLightArea.z*6.0),(cell.y+.5)/staticLightArea.w));
  float id=channel==0?ids.r:(channel==1?ids.g:(channel==2?ids.b:ids.a));
  if(id<.5)break;
  float row=(id-.5)/staticLightRows;
  vec4 position=Texel(staticLightData,vec2(1.0/6.0,row));
  if(length(foot-position.xyz)>=abs(position.w))continue;
  vec4 color=Texel(staticLightData,vec2(.5,row)),params=Texel(staticLightData,vec2(5.0/6.0,row));
  energy+=actorSourceEnergy(foot,position,color,params.y,params.z,params.w);
 }
 return energy;
}
#endif
]]
A.vertex=[[
 actorLocalLight=vec3(0.0);actorLocalActive=0.0;
 vec4 actorFootClip=vp*vec4(actorFoot.xyz,1.0);
 actorShadowUV=actorFootClip.xy/actorFootClip.w*.5+.5;
#ifdef ACTOR_VERTEX_LIGHTING
 if(actorFootMode>.5 && actorFoot.w>.5 && actorFace>.5 && cutTreeFoliage<.5){
  actorLocalLight=actorLightAt(actorFoot.xyz);actorLocalActive=1.0;
 }
#endif
]]
function A.supports(shader)
 if not shader then return false end
 local supported=A.features[shader]
 if supported==nil then supported=shader:hasUniform('actorFoot');A.features[shader]=supported end
 return supported
end
function A.begin(shader,lights)
 V.require('RoomShadowProgram').bind(shader,lights and lights.roomRig)
 if not A.supports(shader)then return end
 local enabled=V.require('DioramaConfig').billboards.footLighting.enabled
 A.active[shader]=true
 A.foot[1],A.foot[2],A.foot[3],A.foot[4]=0,0,0,0
 local U=V.require('UniformState');U.send(shader,'actorFoot',A.foot);if U.has(shader,'actorFootMode')then U.send(shader,'actorFootMode',enabled and 1 or 0)end
 local count=0
 for i=1,24 do
  local l=lights and lights.sources and lights.sources[i]
  -- A tail flame stays localized on its sprite. A whole-card sample would
  -- turn Charmander's entire body into the emitter the user rejected.
  local flag=l and l.flameLight and 1 or 0;A.fragment[i]=flag;count=count+flag
 end
 if U.has(shader,'actorFragmentSource')then U.send(shader,'actorFragmentSource',unpack(A.fragment))end
 if U.has(shader,'actorFragmentCount')then U.send(shader,'actorFragmentCount',count)end
end
function A.bind(shader,x,y,z)
 if not shader or not A.active[shader]then return end
 A.foot[1],A.foot[2],A.foot[3],A.foot[4]=x or 0,y or 0,z or 0,x and 1 or 0
 V.require('UniformState').send(shader,'actorFoot',A.foot)
end
function A.compile(source)
 -- Capability probe using the real vertex texture/shadow program. Older
 -- drivers keep the established fragment-light path if vertex sampling fails.
 local language=V.require('SurfaceDerivatives').language
 source=source:gsub('if%(worldPosition.y<%.9 && shadowStrength>0%.0%)',[[if(actorFace>.5 && actorFoot.w>.5 && shadowStrength>0.0){
 vec2 footUV=actorShadowUV;
 vec2 stepUV=vec2(1.5)/canvasSize;
 shadow=Texel(groundShadow,footUV).b*.5;
 shadow+=(Texel(groundShadow,footUV+stepUV).b+Texel(groundShadow,footUV-stepUV).b)*.25;
 }else if(worldPosition.y<.9 && shadowStrength>0.0)]])
 local optimized=V.require('RoomShadowProgram').prepare(source)
 local function compile(text)
  text=language(text)
  local trace=V.loaded and V.loaded.TransitionTrace
  local hash=trace and love.data.encode('string','hex',love.data.hash('sha256',text)):sub(1,12)
  if trace then trace.step('before world shader '..hash,#text..' source bytes')end
  local valid,result=pcall(love.graphics.newShader,text)
  if trace then trace.step('after world shader '..hash,valid and 'compiled'or tostring(result))end
  if not valid then error(result,0)end
  return result
 end
 local ok,shader=pcall(compile,'#define ACTOR_VERTEX_LIGHTING\n'..optimized)
 if not ok and optimized~=source then
  V.mod.log:info('Room shadow specialization unavailable; retaining reference: '..tostring(shader))
  ok,shader=pcall(compile,'#define ACTOR_VERTEX_LIGHTING\n'..source)
 end
 if ok then return shader,true end
 V.mod.log:info('Actor vertex lighting unavailable; retaining fragment lights: '..tostring(shader))
 return compile(source),false
end
return A
