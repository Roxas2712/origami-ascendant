local V = ...
local seamsOK,Seams=pcall(V.require,'core/RenderSeams')
if not seamsOK then Seams={version=0,shader=function()return ''end,run=function()end,chain=function(_,canvas)return canvas end}end
V.renderSeams=Seams
local frameCtx={}
local Adapter=V.require("WorldAdapter")
local Geometry=V.require("WorldGeometry")
local Camera=V.require("Camera")
local Shapes=V.data("Shapes")
local Weather=V.require("Weather")
local DayNight=V.require("DayNight")
local Lights=V.require("LocalLights")
local Atmosphere=V.require("Atmosphere")
local WorldRain=V.require("WorldRain")
local Shadows=V.require("PaperShadows")
local Finish=V.require("PaperFinish")
local DepthFocus=V.require("DepthOfField")
local Transition=require("src.core.game3.battle_transition")
local Border=V.require("WorldBorder")
local NativeEffects=V.require("NativeEffects")
local PowerPlantRoom=V.require('PowerPlantRoom')
local WaterScene=V.require("WaterScene")
local EnvironmentLight=V.require('EnvironmentLight')
local PaperTransmission=V.require('PaperTransmission')
local ActorLighting=V.require('ActorLighting')
local SpriteRim=V.require('SpriteRim')
local Trace=V.require('TransitionTrace')
local Uniform=V.require('UniformState')
local BuildBudget=V.require('BuildBudget')
local BuildQueue=V.require('NativeBuildQueue')
local Visibility=V.require('SceneVisibility')
local SceneGeometry=V.require('SceneGeometry')
local FieldWork=V.require('FieldWork')
local Renderer={cache={},tick=0,stats={},useInstancing=true,waterStrength=1}
-- Scratch vectors are copied by UniformState before another pass mutates them.
local uniformPayloads={}
-- Transient frame storage has one owner. Consumers finish synchronously;
-- completed public stats deliberately remain a separate snapshot per frame.
local frameStorage={drawList={},atlases={},caveNeighbors={},props={},weatherMap={},
  sceneTargets={},textureContext={},rainFocus={0,0,0},weatherOptions={worldHeat=true,worldFog=true},fog={},
  cameraContext={},interiorView={},focus={},veil={},forest={},forestColor={},forestLight={},bindings={}}
local defaultPocket={0,.01}
local function clear(row)for k in pairs(row)do row[k]=nil end;return row end
local function clearFrameStorage()
  for _,row in pairs(frameStorage)do clear(row)end
end
local zero4,white3,right2,badgeDefault={0,0,0,0},{1,1,1},{1,0},{0,0,1,0}
local function payload(name,...)
  local row=uniformPayloads[name]
  if not row then row={};uniformPayloads[name]=row end
  local n=select('#',...)
  for i=n+1,#row do row[i]=nil end
  for i=1,n do row[i]=select(i,...)end
  return row
end
local baseShaderSource=string.format('#define OASC_MAGMA_LAVA %.1f\n',Geometry.MAGMA_LAVA)..V.require('StaticLightGrid').uniforms..V.require('CloudShafts').actorUniforms..V.require('ClosedShell').shader..V.require('PowerPlantRoom').sectionUniforms..V.require("RoomLightShader")..V.require("SilphCutaway").uniforms..V.require('CaveCutaway').uniforms..V.require('EmeraldFlowers').shader..V.require('RoomRecessClip').uniforms..V.require('CeladonCrystal').uniforms..V.require('SeasonalFoliage').uniforms..EnvironmentLight.uniforms..PaperTransmission.uniforms..ActorLighting.uniforms..SpriteRim.uniforms..[[
uniform float waterMirrorPass;
uniform float occludedPlayerPass;
uniform float actorSunResponse;
varying vec3 worldPosition;
varying vec4 waterSourceClip;
varying float roomVoidFace;
uniform vec3 roomVoidColor;
uniform Image roomEmissionMask;
uniform float roomEmissionPower;
uniform float roomEmissionOnly;
uniform float roomClipEnabled;
uniform vec4 roomClipBounds;
varying float electricBeam;
varying float glassFace;
varying float roofPaneFace;
varying float windowEligible;
varying float windowTexture;
varying float windowVariationCode;
varying vec2 towerSource;
uniform vec4 ghostPass;
uniform vec3 ghostColor;
varying float labFace;
uniform float battleSpritePass;
uniform float battleDepthTest;
uniform Image battleDepth;
uniform float labFacadeFill;
varying float waterFace;
varying float fenceFace;
varying float signFace;
uniform float signLightResponse;
uniform float signAlphaCutoff;
uniform float spriteAlphaCutoff;
varying float spriteFace;
uniform float signBloomCeiling;
uniform float hdrEmission;
uniform float fenceLightResponse;
uniform vec3 groundLightColor;
uniform vec4 localGroupBounds[6];
uniform float localWallOnly[24];
uniform float localFalloff[24];
uniform float localPoint[24];
uniform float caveMode;
uniform float caveActorLight;
uniform float caveSpillLimit;
uniform float caveMaterialResponse;
uniform float caveAmbientTexture;
uniform float caveDiffuseFloor;
uniform vec3 cameraEye;
varying float actorFace;
varying float nativeLavaFace;
uniform vec4 waterSparkles; // cell size, strength, density, speed
uniform vec3 sparkleColor;
uniform vec4 hoennLight; // caustics, legacy lava emission, seconds, native Terra lava
uniform vec2 waterMotion; // game seconds, effect strength
uniform vec4 localPosition[24];
uniform vec4 localColor[24];
uniform float localBounce[24];
uniform vec3 facadeFill;
uniform vec3 facadeLightColor;
uniform int lightCount;
uniform float windowAmount;
uniform vec3 windowEmission;
uniform float glassTextureStrength;
uniform float spillLimit;
uniform float windowConePower;
uniform Image glassMask;
varying float roofBadgeFace;
uniform vec3 gymSignColor;
varying float shade;
varying float plantFace;
varying float grassFace;
uniform vec2 surfaceHighlights; // floor-only highlight shoulder, daytime
uniform vec2 plantLift; // daylight lift: trees, tall grass
uniform vec4 moonFill; // rgb, amount
uniform vec2 surfaceSheen; // water light reflection, rain wetness
uniform vec4 caveActorTint; // rgb, amount
uniform Image badgeCookie; // gym stained-glass badge projection
uniform vec4 badgeArea; // centre xz, size, strength
uniform vec4 sandGrade; // rgb multiplier, amount (outdoor paths)
uniform vec3 moonWater; // night water grade (reference: deep saturated blue)
uniform float actorNightFill;
varying float opacity;
uniform vec3 worldTint;
uniform vec3 sunDirection;
uniform float sunStrength;
uniform float daylightDirect;
uniform vec2 duskShadow; // red direct-light occlusion, retained ambient fraction
uniform float snowCover;
uniform vec3 sunColor;
uniform float daylightSaturation;
uniform vec4 grassGrade; // r,g,b multipliers, strength
uniform vec4 cloudShadow; // scale (world px), strength, drift x, drift z (already time-integrated)
uniform Image groundShadow;
uniform vec2 canvasSize;
uniform float shadowStrength;
uniform vec2 fieldSkyDistance;
uniform vec3 fieldSkyColor;
]]..ActorLighting.functions..SpriteRim.functions..[[
#ifdef VERTEX
uniform mat4 vp;
uniform float roomDepthScale;
uniform float belowGroundDepthY;
attribute float VertexShade;
attribute vec3 BillboardAnchor;
uniform vec2 billboardRight;
uniform vec3 wind; // seconds, amplitude px, speed
#ifdef WORLD_INSTANCES
attribute vec3 WorldPlacement;
#endif
vec4 position(mat4 transform_projection, vec4 vertex_position) {
 vec2 anchor=BillboardAnchor.xy;
#ifdef WORLD_INSTANCES
  vertex_position.xyz=vertex_position.xyz*WorldPlacement.z+vec3(WorldPlacement.x,0.0,WorldPlacement.y);
  anchor=anchor*WorldPlacement.z+WorldPlacement.xy;
#endif
]]..V.require('PowerPlantRoom').sectionVertex..[[
  if(closedShellHidden(BillboardAnchor.z,vp,vertex_position))return vec4(0.0,0.0,2.0,1.0);
  if(BillboardAnchor.z>.5){

    vertex_position.xz=anchor+billboardRight*(vertex_position.x-anchor.x)+vec2(-billboardRight.y,billboardRight.x)*(vertex_position.z-anchor.y);
  }
  if(BillboardAnchor.z>1.01 && BillboardAnchor.z<1.5 && wind.y>0.0){
    // Dynamic texture: grass tufts and tree crowns sway gently around their
    // fixed foot. Weight rides in the billboard flag (1+weight); phase is
    // world-anchored so neighbouring plants move as a soft travelling gust.
    float weight=BillboardAnchor.z-1.0;
    float lift=clamp(vertex_position.y/16.0,0.0,2.0);
    float t=wind.x*wind.z;
    float gust=.6+.4*sin(t*.37+anchor.x*.013);
    vertex_position.x+=sin(t+anchor.x*.09+anchor.y*.05)*wind.y*weight*lift*gust;
  }
]]..V.require("SilphCutaway").vertex..V.require('CaveCutaway').vertex..V.require('EmeraldFlowers').vertex..[[
  foliageRoot=anchor-foliageMapOrigin;
  nativeLavaFace=1.0-step(.01,abs(VertexShade-OASC_MAGMA_LAVA));
  worldPosition=vertex_position.xyz;
  plantFace=step(1.01,BillboardAnchor.z);
  cutTreeFoliage=1.0-step(.001,abs(VertexShade-1.76));
  stationaryFoliage=max(step(1.0005,BillboardAnchor.z)*(1.0-step(1.01,BillboardAnchor.z)),
    1.0-step(.001,abs(BillboardAnchor.z+4.0))); // native folded forest gates
  grassFace=step(1.5,BillboardAnchor.z);
  electricBeam=step(8.9,VertexShade)*(1.0-step(9.3,VertexShade))*(1.0+step(9.15,VertexShade));
  roomVoidFace=step(6.9,VertexShade)*(1.0-step(7.1,VertexShade));
  spriteFace=max(step(.5,BillboardAnchor.z),step(1.7,VertexShade)*(1.0-step(1.9,VertexShade)));
  actorFace=step(1.7,VertexShade)*(1.0-step(1.9,VertexShade));
  waterFace=step(3.5,VertexShade)*(1.0-step(4.5,VertexShade));
  fenceFace=step(4.5,VertexShade)*(1.0-step(5.5,VertexShade));
  signFace=step(5.1,VertexShade)*(1.0-step(5.5,VertexShade));
  towerSource=vec2(worldPosition.x-anchor.x,anchor.y-worldPosition.z);
  windowVariationCode=BillboardAnchor.z;
  windowTexture=step(.5,BillboardAnchor.z);
  windowEligible=step(-.5,BillboardAnchor.z); // negative flag: unlit landmark storey
  glassFace=step(2.0,VertexShade)*(1.0-step(3.5,VertexShade));
  roofPaneFace=(1.0-step(.01,abs(VertexShade-6.0)))*step(.01,BillboardAnchor.z)*windowEligible;
  roofBadgeFace=max(glassFace,1.0-step(.01,abs(VertexShade-6.0)));
  labFace=step(2.0,VertexShade)*(1.0-step(2.5,VertexShade));
  shade=max(glassFace,waterFace)>0.5?1.0:abs(VertexShade);
  // Fold shading belongs to the paper facade, not the emissive window mask.
  if(fenceFace>.5 || actorFace>.5 || VertexShade>5.5)shade=1.0;
  if(glassFace>0.5) shade=1.0-clamp(VertexShade-mix(3.0,2.0,labFace),0.0,0.49)*0.65;
  opacity=VertexShade<0.0?0.27:1.0;
 ]]..ActorLighting.vertex..[[
  waterSourceClip=vp*vertex_position;
  vec4 mirrorPosition=vertex_position;
  mirrorPosition.y*=1.0-2.0*waterMirrorPass;
  vec4 projected=vp*mirrorPosition;
  // The corrected paper camera removes Y from W. Reflected geometry below
  // the plane needs depth headroom just like recessed rooms.
  if(waterMirrorPass>.5)projected.z*=.1;
  // Vertical correction removes height from screen W. A hanging facade
  // needs its original camera-space divisor for depth, otherwise negative
  // heights exceed the far clip plane. Other materials retain their depth.
  if(abs(VertexShade-8.0)<.01 && vertex_position.y<0.0 && belowGroundDepthY!=0.0){
    float depthW=projected.w+belowGroundDepthY*vertex_position.y;
    projected.z*=projected.w/max(depthW,.0001);
  }
  // Preserve the corrected camera's depth order, but leave clip-space
  // headroom for stairwells below y=0. XY framing is unchanged.
  projected.z*=roomDepthScale;
  if(glassFace>.5 || (VertexShade>5.5 && nativeLavaFace<.5)) {
    // Snap only building vertices to this render target's pixel grid. Shared
    // roof/facade endpoints land on the same pixel, even under perspective.
    vec2 pixelPosition=(projected.xy/projected.w*.5+.5)*canvasSize;
    projected.xy=((floor(pixelPosition+.5)/canvasSize)*2.0-1.0)*projected.w;
  }
  return projected;
}
#endif
#ifdef PIXEL
]]..V.require('CloudDaylight').noise..[[
#endif
#ifdef PIXEL
]]..V.require('CloudDaylight').fragment..V.require('CloudShafts').actorFragment..V.require('WindowVariation').fragment..V.require('GhostWindows').fragment..V.require('Puddles').fragment..V.require('SurfaceSteps').fragment..V.require('WaterReflections').fragment..PaperTransmission.functions..[[
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  if(waterMirrorPass>.5 && (worldPosition.y<.7 || waterFace>.5 || roomVoidFace>.5)) discard;
]]..V.require('RoomRecessClip').fragment..V.require('CaveCutaway').fragment..[[
  if(roomClipEnabled>.5 && (worldPosition.x<roomClipBounds.x || worldPosition.z<roomClipBounds.y || worldPosition.x>roomClipBounds.z || worldPosition.z>roomClipBounds.w)) discard;
  if(battleDepthTest>.5 && gl_FragCoord.z>Texel(battleDepth,screen/love_ScreenSize.xy).r+.0000001) discard;
  if(roomVoidFace>.5)return vec4(roomEmissionOnly>.5?vec3(0.0):roomVoidColor,1.0);
  vec4 pixel=Texel(tex,uv);
]]..V.require('EmeraldFlowers').fragment..[[
  // Native animated electric gates contain opaque floor texels in their atlas.
  // Keep only their cyan/magenta energy on this explicit material, every frame.
  if(electricBeam>.5){
    if(pixel.a<.5)discard;
    // FireRed uses bounded native white/cyan cutouts, Emerald a live color mask.
    if(electricBeam<1.5 && (pixel.b<.9 || min(pixel.r,pixel.g)>.1))discard;
    return vec4(pixel.rgb,1.0);
  }
  if(pixel.a<mix(max(mix(0.5,signAlphaCutoff,signFace),spriteFace*spriteAlphaCutoff),.01,battleSpritePass)) discard;
  if(occludedPlayerPass>0.0)return vec4(.10,.13,.18,pixel.a*occludedPlayerPass);
  if(battleSpritePass>.5)pixel.rgb/=max(pixel.a,.001);
  if(grassGrade.a>0.0 && actorFace<.5 && waterFace<.5 && (plantFace<.5 || grassFace>.5)) {
    // FireRed's cool mint lawn reads washed-out under daylight. Shift only
    // mint-green albedo (green>blue>red) toward the reference's warmer, deeper
    // grass; trees, water, paths and actors fail the hue test and stay native.
    float mint=step(pixel.b,pixel.g)*step(pixel.r*1.15,pixel.b)*step(pixel.r*1.35,pixel.g);
    pixel.rgb=mix(pixel.rgb,pixel.rgb*grassGrade.rgb,mint*grassGrade.a);
  }
  if(sandGrade.a>0.0 && actorFace<.5 && worldPosition.y<.5) {
    // FireRed's lemon path sand reads too bright under the diorama light;
    // the reference paths are a darker ochre. Only bright yellow ground
    // texels (red>=green>blue, strongly warm) are graded.
    float sand=step(pixel.g,pixel.r+.02)*step(pixel.b,pixel.g*.80)*step(.55,pixel.r)*step(.22,pixel.r-pixel.b);
    pixel.rgb=mix(pixel.rgb,pixel.rgb*sandGrade.rgb,sand*sandGrade.a);
  }
]]..V.require('SeasonalFoliage').fragment..[[
  vec3 normal=normalize(cross(dFdx(worldPosition),dFdy(worldPosition)));
  if(dot(normal,cameraEye-worldPosition)<0.0)normal=-normal;
  float incidence=dot(normal,normalize(sunDirection));
  // Daylight has one direction. abs() lit the shaded face as strongly as
  // the sun-facing wall; retain that established response only at night.
  float sunlight=mix(abs(incidence),max(0.0,incidence),daylightDirect)*sunStrength;
  // A camera-facing paper card is not a body's surface normal. Give actors
  // a soft two-sided/top response, still gated by the same clouds and shadows.
  if(actorFace>.5) sunlight=mix(sunlight,max(sunlight,max(abs(incidence)*.65,max(0.0,normalize(sunDirection).y)*.60)*sunStrength),actorSunResponse*daylightDirect);
  if(snowCover>0.0 && actorFace<.5 && waterFace<.5 && spriteFace<.5 && glassFace<.5 && fenceFace<.5 && normal.y>.65){
    float patch=cloudNoise(floor(worldPosition.xz/2.0)*.15);
    float cover=mix(.60,1.0,smoothstep(.20,.65,patch))*snowCover;
    // Solid collision does not mean dry artwork: coast/ship metatiles contain
    // native water too. Blue mask channel is render-only and atlas-specific.
    if(worldPosition.y<.6)cover*=1.0-Texel(glassMask,uv).b;
    if(worldPosition.y<.6)cover*=1.0-.78*snowTrack(worldPosition.xz);
    float texture=dot(pixel.rgb,vec3(.2126,.7152,.0722));
    pixel.rgb=mix(pixel.rgb,vec3(.80,.87,.94)*(.72+.28*texture),cover);
  }
  vec2 shadowUV=waterMirrorPass>.5?waterSourceClip.xy/waterSourceClip.w*.5+.5:screen/canvasSize;
  vec2 tap=vec2(4.5)/canvasSize;
  float shadow=0.0;
  // Raised paper faces never receive the ground-only shadow. Skip its five
  // texture reads rather than fetching them and multiplying by exact zero.
  if(worldPosition.y<.9 && shadowStrength>0.0){
    shadow=Texel(groundShadow,shadowUV).r*.28;
    shadow+=(Texel(groundShadow,shadowUV+vec2(tap.x,0)).r+Texel(groundShadow,shadowUV-vec2(tap.x,0)).r
      +Texel(groundShadow,shadowUV+vec2(0,tap.y)).r+Texel(groundShadow,shadowUV-vec2(0,tap.y)).r)*.18;
    shadow*=1.0-smoothstep(.1,.9,worldPosition.y);
  }
 ]]..EnvironmentLight.ambient..[[
  vec3 baseTint=(ambientTint+facadeFill*glassFace*windowEligible*windowAmount*mix(1.0,labFacadeFill,labFace))*(1.0+sunlight*sunColor)*(1.0-shadow*shadowStrength);
  // Only red dusk separates cool ambient from occluded warm direct sunlight.
  // The zero-weight branch preserves the approved day/night/interior pixels.
  if(duskShadow.x>0.0){
    vec3 duskTint=ambientTint*(1.0-shadow*shadowStrength*duskShadow.y)
      +ambientTint*sunlight*sunColor*(1.0-shadow*min(1.0,shadowStrength*1.35));
    baseTint=mix(baseTint,duskTint,duskShadow.x);
  }
  baseTint=cloudDaylight(baseTint,ambientTint,sunlight,sunColor,shadow,worldPosition.xz);
  baseTint+=vec3(.44,.50,.65)*skyEvents.x*(.3+.7*max(0.0,dot(normal,normalize(vec3(skyEvents.z,.8,skyEvents.w)))));
  vec3 roomEmission=vec3(0.0);
  if(roomEmissionPower>0.0)roomEmission=pixel.rgb*Texel(roomEmissionMask,uv).r*roomEmissionPower*hdrEmission;
  if(roomEmissionOnly>.5)return vec4(clamp(roomEmission,0.0,1.0),1.0);
  vec3 illumination=baseTint;
  vec3 spill=vec3(0.0);
  if(actorLocalActive>.5){spill=pixel.rgb*actorLocalLight;illumination+=actorLocalLight;}
  if(actorLocalActive<.5 || actorFragmentCount>0){
  for(int i=0;i<24;i++) {
    if(i>=lightCount)break;
    if(actorLocalActive>.5 && actorFragmentSource[i]<.5)continue;
    if((i/4)*4==i){
      vec4 bounds=localGroupBounds[i/4];
      if(worldPosition.x<bounds.x || worldPosition.z<bounds.y || worldPosition.x>bounds.z || worldPosition.z>bounds.w){
        i=(i+3<int(lightCount)?i+3:int(lightCount)-1);continue;
      }
    }
    bool fixedSource=false;
    vec4 position=localPosition[i],color=localColor[i];
    float bounce=localBounce[i],falloffPower=localFalloff[i],wallOnly=localWallOnly[i],point=localPoint[i];
      // Spatial cells conservatively include nearby sources. Outside the
      // actual sphere (or with zero power), this light contributes exactly
      // zero; avoid cone, room-shadow and material work for that fragment.
      if(color.a==0.0)continue;
      vec3 delta=worldPosition-position.xyz;
      float falloff=max(0.0,1.0-length(delta)/abs(position.w));
      if(falloff<=0.0)continue;
      // Facade lights shine into the street, never through their own house.
      // Keep the emitter's facade out of its own spill. Glass alone is
      // emissive; the cone opens beyond the wall toward ground and actors.
      float outward=position.w<0.0?1.0:smoothstep(2.0,12.0,delta.z);
      if(position.w>0.0)outward*=pow(max(0.0,delta.z)/max(length(delta.xz),.001),windowConePower);
      // Local bounced window light reaches its facade, bounded to that wall.
      outward=max(outward,bounce*glassFace*(1.0-smoothstep(1.0,5.0,abs(delta.z))));
      if(outward<=0.0)continue;
      float groundFace=1.0-smoothstep(.1,.9,worldPosition.y);
      vec3 hue=mix(color.rgb,facadeLightColor,glassFace*step(0.0,position.w));
      // Ground pools use a neutral cream response; surrounding artwork keeps
      // its own original palette. Match old light luminance, not green hue.
      vec3 cream=groundLightColor*dot(color.rgb,vec3(.2126,.7152,.0722))/dot(groundLightColor,vec3(.2126,.7152,.0722));
      hue=mix(hue,cream,groundFace*step(0.0,position.w));
      // Preserve the original quadratic response for all existing lights.
      float attenuation=falloffPower==2.0?falloff*falloff:pow(falloff,max(.25,falloffPower));
      float incidence=1.0;
      if(point>.5 && actorFace<.5) {
        // Small diffuse bounce keeps rock corners readable; direct light
        // still follows the true surface normal. Flat actor cards are unlit
        // normals: their painted volume receives the radial light directly.
        incidence=mix(caveDiffuseFloor,1.0,max(0.0,dot(normal,-delta/max(length(delta),.0001))));
      }
      bool roomSource=!fixedSource && roomSourceDirection[i].w>-1.0;
      if(roomSource){
        vec3 toLight=-delta/max(length(delta),.0001);
        incidence=actorFace>.5?roomLightModel.y:mix(roomLightModel.x,1.0,max(0.0,dot(normal,toLight)));
        float cone=smoothstep(roomSourceDirection[i].w,min(.99,roomSourceDirection[i].w+.5),dot(normalize(roomSourceDirection[i].xyz),-toLight));
        attenuation*=cone;
        if(attenuation>0.0)attenuation*=roomSourceShadow(worldPosition,normal,position.xyz,roomSourceArea[i],roomReliefTiles[i]);
      }
      vec3 energy=hue*color.a*attenuation*1.15*outward*incidence;
      // Painted actor cards take the cave point light head-on; keep them
      // from blowing out into a flat orange silhouette.
      if(point>.5 && actorFace>.5) energy*=caveActorLight;
      energy*=mix(1.0,glassFace,wallOnly);
      if(fenceFace>.5)energy=vec3(dot(energy,vec3(.2126,.7152,.0722)))*mix(fenceLightResponse,signLightResponse,signFace);
      illumination+=energy;
      // Keep window spill amber even on green grass, without whitening
      // environmental lights or changing the native daytime surface.
      vec3 response=mix(pixel.rgb,vec3(1.0),position.w>0.0?mix(.45,.65,glassFace):.35);
      if(position.w>0.0)response=mix(response,vec3(dot(response,vec3(.2126,.7152,.0722))),groundFace);
      if(point>.5 && actorFace<.5) {
        // Neutral rock reflectance keeps native texture contrast without
        // multiplying amber light by the green tint painted into cave caps.
        response=mix(vec3(1.0),pixel.rgb,caveMaterialResponse);
      }
      // Actors keep their own palette under a point light (no whitening).
      if(point>.5 && actorFace>.5)response=pixel.rgb;
      if(roomSource || fenceFace>.5)response=pixel.rgb;
      spill+=response*energy;
  }
  }
  if(actorLocalActive<.5){
  vec2 staticCell=floor((worldPosition.xz-staticLightArea.xy)/16.0);
  bool staticCellValid=staticLightRows>=.5 && staticCell.x>=0.0 && staticCell.y>=0.0 && staticCell.x<staticLightArea.z && staticCell.y<staticLightArea.w;
  vec4 staticIds=vec4(0.0);
  for(int staticSlot=0;staticSlot<24;staticSlot++) {
    if(!staticCellValid)break;
    int channel=staticSlot-(staticSlot/4)*4;
    if(channel==0){
      float pack=floor(float(staticSlot)/4.0);
      staticIds=Texel(staticLightGrid,vec2((staticCell.x*6.0+pack+.5)/(staticLightArea.z*6.0),(staticCell.y+.5)/staticLightArea.w));
    }
    float sourceId=channel==0?staticIds.r:(channel==1?staticIds.g:(channel==2?staticIds.b:staticIds.a));
    if(sourceId<.5)break;
    bool fixedSource=true;int i=0;
    float row=(sourceId-.5)/staticLightRows;
    vec4 position=Texel(staticLightData,vec2(1.0/6.0,row));
      // Spatial cells conservatively include nearby sources. Outside the
      // actual sphere (or with zero power), this light contributes exactly
      // zero; avoid cone, room-shadow and material work for that fragment.
      vec3 delta=worldPosition-position.xyz;
      float falloff=max(0.0,1.0-length(delta)/abs(position.w));
      if(falloff<=0.0)continue;
      vec4 color=Texel(staticLightData,vec2(.5,row));
      if(color.a==0.0)continue;
      vec4 params=Texel(staticLightData,vec2(5.0/6.0,row));
      float bounce=params.x,falloffPower=params.y,wallOnly=params.z,point=params.w;
      // Facade lights shine into the street, never through their own house.
      // Keep the emitter's facade out of its own spill. Glass alone is
      // emissive; the cone opens beyond the wall toward ground and actors.
      float outward=position.w<0.0?1.0:smoothstep(2.0,12.0,delta.z);
      if(position.w>0.0)outward*=pow(max(0.0,delta.z)/max(length(delta.xz),.001),windowConePower);
      // Local bounced window light reaches its facade, bounded to that wall.
      outward=max(outward,bounce*glassFace*(1.0-smoothstep(1.0,5.0,abs(delta.z))));
      if(outward<=0.0)continue;
      float groundFace=1.0-smoothstep(.1,.9,worldPosition.y);
      vec3 hue=mix(color.rgb,facadeLightColor,glassFace*step(0.0,position.w));
      // Ground pools use a neutral cream response; surrounding artwork keeps
      // its own original palette. Match old light luminance, not green hue.
      vec3 cream=groundLightColor*dot(color.rgb,vec3(.2126,.7152,.0722))/dot(groundLightColor,vec3(.2126,.7152,.0722));
      hue=mix(hue,cream,groundFace*step(0.0,position.w));
      // Preserve the original quadratic response for all existing lights.
      float attenuation=falloffPower==2.0?falloff*falloff:pow(falloff,max(.25,falloffPower));
      float incidence=1.0;
      if(point>.5 && actorFace<.5) {
        // Small diffuse bounce keeps rock corners readable; direct light
        // still follows the true surface normal. Flat actor cards are unlit
        // normals: their painted volume receives the radial light directly.
        incidence=mix(caveDiffuseFloor,1.0,max(0.0,dot(normal,-delta/max(length(delta),.0001))));
      }
      bool roomSource=!fixedSource && roomSourceDirection[i].w>-1.0;
      if(roomSource){
        vec3 toLight=-delta/max(length(delta),.0001);
        incidence=actorFace>.5?roomLightModel.y:mix(roomLightModel.x,1.0,max(0.0,dot(normal,toLight)));
        float cone=smoothstep(roomSourceDirection[i].w,min(.99,roomSourceDirection[i].w+.5),dot(normalize(roomSourceDirection[i].xyz),-toLight));
        attenuation*=cone;
        if(attenuation>0.0)attenuation*=roomSourceShadow(worldPosition,normal,position.xyz,roomSourceArea[i],roomReliefTiles[i]);
      }
      vec3 energy=hue*color.a*attenuation*1.15*outward*incidence;
      // Painted actor cards take the cave point light head-on; keep them
      // from blowing out into a flat orange silhouette.
      if(point>.5 && actorFace>.5) energy*=caveActorLight;
      energy*=mix(1.0,glassFace,wallOnly);
      if(fenceFace>.5)energy=vec3(dot(energy,vec3(.2126,.7152,.0722)))*mix(fenceLightResponse,signLightResponse,signFace);
      illumination+=energy;
      // Keep window spill amber even on green grass, without whitening
      // environmental lights or changing the native daytime surface.
      vec3 response=mix(pixel.rgb,vec3(1.0),position.w>0.0?mix(.45,.65,glassFace):.35);
      if(position.w>0.0)response=mix(response,vec3(dot(response,vec3(.2126,.7152,.0722))),groundFace);
      if(point>.5 && actorFace<.5) {
        // Neutral rock reflectance keeps native texture contrast without
        // multiplying amber light by the green tint painted into cave caps.
        response=mix(vec3(1.0),pixel.rgb,caveMaterialResponse);
      }
      // Actors keep their own palette under a point light (no whitening).
      if(point>.5 && actorFace>.5)response=pixel.rgb;
      if(roomSource || fenceFace>.5)response=pixel.rgb;
      spill+=response*energy;
  }
  }
  float peakSpill=max(spill.r,max(spill.g,spill.b));
  float limit=mix(spillLimit,caveSpillLimit,caveMode);
  spill*=(limit*(1.0-exp(-peakSpill/limit)))/max(peakSpill,.0001);
  float contact=Texel(groundShadow,shadowUV).g;
  contact*=1.0-smoothstep(.1,1.5,worldPosition.y);
  vec3 ambientAlbedo=pixel.rgb;
  if(caveMode>.5 && actorFace<.5)ambientAlbedo=mix(vec3(1.0),pixel.rgb,caveAmbientTexture);
  // Night water mirrors nearby lamps and windows as a rippling sheen.
  if(waterFace>0.5) spill*=1.0+surfaceSheen.x*(.65+.35*sin(worldPosition.x*.35+waterMotion.x*1.6)*sin(worldPosition.z*.5-waterMotion.x*1.1));
  // Rain: ground darkens and becomes glossy, catching the local lights.
  if(surfaceSheen.y>0.0 && snowCover<.5 && actorFace<.5 && plantFace<.5 && worldPosition.y<.6 && waterFace<.5) {
    ambientAlbedo*=1.0-.26*surfaceSheen.y;
    spill*=1.0+.30*surfaceSheen.y;
  }
  vec3 lit=(ambientAlbedo*shade*baseTint + shade*spill)*(1.0-contact);
]]..PaperTransmission.fragment..[[
  if(surfaceHighlights.y>0.0 && actorFace<.5 && waterFace<.5 && spriteFace<.5 && worldPosition.y<.6 && normal.y>.95) {
    float peak=max(lit.r,max(lit.g,lit.b));
    float excess=max(0.0,peak-surfaceHighlights.x);
    lit*=max(0.0,peak-excess*surfaceHighlights.y)/max(.0001,peak);
  }
  lit=rainPuddles(lit,pixel.rgb,normal,worldPosition,illumination,max(snowCover,max(max(spriteFace,waterFace),max(glassFace,fenceFace))));
  if(badgeArea.w>0.0) {
    // Gym skylight: the badge in stained glass, projected onto the arena.
    vec2 bu=(worldPosition.xz-badgeArea.xy)/badgeArea.z+vec2(.5);
    float inside=step(0.0,bu.x)*step(bu.x,1.0)*step(0.0,bu.y)*step(bu.y,1.0);
    float edge=smoothstep(0.0,.07,min(min(bu.x,1.0-bu.x),min(bu.y,1.0-bu.y)));
    float floorish=1.0-smoothstep(1.0,8.0,worldPosition.y);
    vec3 glass=Texel(badgeCookie,clamp(bu,0.0,1.0)).rgb;
    lit+=pixel.rgb*glass*badgeArea.w*inside*edge*mix(.45,1.0,floorish)*(1.0-contact)*(1.0-.75*actorFace);
  }
  if(roofBadgeFace>.5 && windowAmount>0.0) {
    float signInk=Texel(glassMask,uv).a;
    if(signInk>.5) {
      // Self-lit native ink without HDR overexposure or a white halo.
      lit=mix(lit,max(lit,pixel.rgb*.78),windowAmount);
    } else if(signInk>.1 && max(gymSignColor.r,max(gymSignColor.g,gymSignColor.b))>0.0) {
      // Measured native letters/ball ink only; the sign plate stays opaque.
      lit=mix(lit,gymSignColor*.78,windowAmount);
    }
  }
  if(max(glassFace,roofPaneFace)>0.5 && windowEligible>.5 && Texel(glassMask,uv).r>0.5) {
    vec4 lamp=windowLamp(windowVariationCode);
    float roofCover=1.0-roofPaneFace*snowCover*.85;
    lit=mix(lit,windowEmission*hdrEmission*lamp.rgb*mix(1.0,dot(pixel.rgb,vec3(.2126,.7152,.0722)),max(windowTexture,roofPaneFace)*glassTextureStrength),windowAmount*lamp.a*roofCover);
  }
  if(glassFace>.5 && windowEligible<.5 && ghostPass.z>0.0 && Texel(glassMask,uv).g>.5) {
    lit=ghostBehindPane(lit,towerSource);
  }
  if(waterFace>0.5 && waterMotion.y>0.0) {
    // Native water behavior selects the surface; blue texels exclude stone
    // banks and bridge supports in the same metatile. World-space waves join
    // across atlas/map boundaries and never displace the original UVs.
    float wet=step(.24,pixel.b-pixel.r)*step(.04,pixel.g-pixel.r);
    vec2 p=floor(worldPosition.xz)+vec2(.5);
    float t=waterMotion.x;
    float a=sin(p.x*.19+p.y*.07+t*.8+sin(p.y*.13-t*.45));
    float b=sin(p.y*.23-p.x*.06-t*.65+sin(p.x*.11+t*.35));
    float crest=smoothstep(.82,.995,a*b);
    float energy=clamp(dot(illumination,vec3(.2126,.7152,.0722)),0.0,1.0);
    float amount=wet*waterMotion.y;
    lit*=1.0+amount*.025*(a+b);
    lit+=vec3(.67,.90,1.0)*crest*.10*energy*amount;
    if(waterSparkles.y>0.0) {
      // Sparse world-anchored glints pulse on complete water surfaces only.
      // Quantized positions retain pixel edges; bank/bridge texels stay dry.
      vec2 cell=floor(p/waterSparkles.x);
      float seed=fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453);
      vec2 center=(cell+vec2(.2+.6*seed,.2+.6*fract(seed*17.3)))*waterSparkles.x;
      vec2 d=abs(p-floor(center));
      float crossPixel=max((1.0-step(.6,d.x))*(1.0-step(1.6,d.y)),(1.0-step(1.6,d.x))*(1.0-step(.6,d.y)));
      float pulse=pow(max(0.0,sin(t*waterSparkles.w+seed*31.0)),8.0);
      lit+=sparkleColor*crossPixel*pulse*step(seed,waterSparkles.z)*waterSparkles.y*wet*waterMotion.y;
    }
    lit*=mix(vec3(1.0),moonWater,wet*moonFill.a);
  }
  if(waterFace>.5){
    float wet=step(.24,pixel.b-pixel.r)*step(.04,pixel.g-pixel.r);
    lit=reflectedWater(lit,worldPosition,wet,shadow*shadowStrength,screen/love_ScreenSize.xy);
  }
  if(hoennLight.x>0.0 && actorFace<.5) {
    vec2 p=floor(worldPosition.xz*.5)*2.0;
    float t=hoennLight.z;
    float a=sin(p.x*.12+p.y*.04+t*.65+sin(p.y*.07-t*.3));
    float b=sin(p.y*.14-p.x*.05-t*.5+sin(p.x*.08+t*.4));
    float net=pow(max(0.0,1.0-abs(a+b)),9.0);
    lit+=pixel.rgb*vec3(.34,.85,1.0)*net*hoennLight.x*(1.0-contact);
  }
  if(hoennLight.y>0.0 && actorFace<.5) {
    float hot=step(.65,pixel.r)*(1.0-step(.40,pixel.g))*(1.0-step(.28,pixel.b));
    float pulse=.88+.12*sin(hoennLight.z*1.8+worldPosition.x*.025+worldPosition.z*.02);
    lit=mix(lit,pixel.rgb*vec3(1.35,1.0,.7)*pulse*hdrEmission,hot*hoennLight.y);
  }
  if(hoennLight.w>0.0 && actorFace<.5 && (worldPosition.y<.5 || nativeLavaFace>.5)) {
    // Terra's native orange melt AND yellow animation highlights emit.
    // Brown rock texels contain blue; do not turn the mixed shoreline luminous.
    float molten=step(.65,pixel.r)*(1.0-step(.28,pixel.b));
    lit=mix(lit,pixel.rgb*hdrEmission,molten*hoennLight.w);
  }
  if(plantFace>.5) {
    // Reference day clips keep foliage as bright as the lawn around it.
    lit*=mix(plantLift.x,plantLift.y,grassFace);
  }
  if(moonFill.a>0.0 && plantFace>.5) {
    // Moonlit foliage: the reference keeps trees and tall grass readable at
    // night with a cool teal sheen instead of sinking into black.
    lit+=vec3(dot(pixel.rgb,vec3(.2126,.7152,.0722)))*moonFill.rgb*moonFill.a*shade;
  }
  if(caveMode>.5 && actorFace>.5) {
    // The player carries the light: keep native sprite colours readable.
    // FLASH lights them warm; without it they stay a dim silhouette in the dark.
    lit=mix(lit,pixel.rgb*caveActorTint.rgb,caveActorTint.a);
  }
  if(moonFill.a>0.0 && actorFace>.5 && caveMode<.5) {
    // Characters stay readable at night like the reference (soft fill).
    lit+=pixel.rgb*actorNightFill*moonFill.a;
  }
  if(actorFace>.5 && actorShaftCount>0) {
    lit+=pixel.rgb*sunColor*actorShaftLight(worldPosition)*(1.0-shadow*.96);
  }
]]..SpriteRim.fragment..[[
  if(cloudShadow.y>0.0) {
    // Large soft cloud shadows drift across ground and objects alike, like the
    // reference footage. World-anchored so they never swim with the camera.
    float cover=cloudCover((worldPosition.xz+cloudShadow.zw)/cloudShadow.x);
    lit*=1.0-cover*cloudShadow.y;
  }
  if(daylightSaturation>0.0 && abs(daylightSaturation-1.0)>.001) {
    float grey=dot(lit,vec3(.2126,.7152,.0722));
    lit=mix(vec3(grey),lit,daylightSaturation);
  }
  // Non-emissive signs stay below the finish shader's existing .66 bloom
  // threshold, even in strong light pools. Preserve hue and daytime art.
  if(signFace>.5 && windowAmount>0.0) {
    float luminance=dot(lit,vec3(.2126,.7152,.0722));
    lit*=min(1.0,signBloomCeiling/max(luminance,.0001));
  }
 ]]..EnvironmentLight.fragment..V.require('CeladonCrystal').fragment..[[
  lit=max(lit,roomEmission);
  // Local low-eye views fade their bounded native continuation into a narrow
  // sky seam. Normal views/battles use zero; no extra full-screen composite.
  if(fieldSkyDistance.y>0.0){
    float distanceToEye=length(worldPosition.xz-cameraEye.xz);
    lit=mix(lit,fieldSkyColor,smoothstep(fieldSkyDistance.x,fieldSkyDistance.y,distanceToEye));
  }
  return vec4(hdrEmission>1.0?max(lit,vec3(0.0)):clamp(lit,0.0,1.0),opacity*mix(1.,pixel.a,battleSpritePass))*color;
}
#endif
]]
local function insert(source,slot,marker,before)
 local snippet=Seams.shader(slot)
 if snippet==''then return source end
 local at=assert(source:find(marker,1,true),'missing render seam '..slot)
 if not before then at=at+#marker end
 return source:sub(1,at-1)..snippet..source:sub(at)
end
function Renderer.buildShaderSource(unwrapped)
 local source=Seams.shader('main.defines')..baseShaderSource
 source=insert(source,'main.uniforms','uniform float waterMirrorPass;',true)
 source=insert(source,'main.functions','vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen)',true)
 source=insert(source,'main.vertex.pre','  if(closedShellHidden',true)
 source=insert(source,'main.vertex.post','  worldPosition=vertex_position.xyz;',true)
 source=insert(source,'main.fragment.pre','vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {',false)
 source=insert(source,'main.fragment.albedo','  vec4 pixel=Texel(tex,uv);',false)
 source=insert(source,'main.fragment.lit','  vec3 lit=(ambientAlbedo*shade*baseTint + shade*spill)*(1.0-contact);',false)
 -- Source-local filters share `params`/`color` across world, actor and reflection
 -- paths. No consumer means no inserted bytes, including whitespace.
 source=insert(source,'main.light.static','  vec4 color=Texel(staticLightData,vec2(.5,row)),params=Texel(staticLightData,vec2(5.0/6.0,row));',false)
 source=insert(source,'main.light.static','  vec4 params=Texel(staticLightData,vec2(5.0/6.0,row));',false)
 source=insert(source,'main.light.static','      vec4 params=Texel(staticLightData,vec2(5.0/6.0,row));',false)
 source=insert(source,'main.light.window','    vec4 lamp=windowLamp(windowVariationCode);',false)
 source=insert(source,'main.fragment.final','  return vec4(hdrEmission',true)
 if unwrapped then return source end
 return Seams.chain('shaderSource',source)
end
Renderer.baseShaderSource=baseShaderSource
local function release(object)if object and object.release then object:release() end end
local programFields={'shader','instanceShader','maskShader','instanceMaskShader','actorVertexLighting','actorRimLighting','depthOnly','instanceDepthOnly','depthAttempted'}
local function releasePrograms()
 V.require('WorldDepthPrepass').clear()
 local seen={}
 local function dispose(row)
  for _,name in ipairs(programFields)do local value=row[name]
   if type(value)=='userdata'and not seen[value]then seen[value]=true;release(value)end
   row[name]=nil
  end
 end
 for _,row in pairs(Renderer.programs or{})do dispose(row)end
 dispose(Renderer);Renderer.programs=nil;Renderer.programKey=nil
end
local function selectProgram(key)
 if Renderer.programKey==key then return end
 local bank=Renderer.programs or{};Renderer.programs=bank
 if Renderer.programKey then
  local row=bank[Renderer.programKey]or{};bank[Renderer.programKey]=row
  for _,name in ipairs(programFields)do row[name]=Renderer[name]end
 end
 local row=bank[key]or{};bank[key]=row
 for _,name in ipairs(programFields)do Renderer[name]=row[name]end
 Renderer.programKey=key
end
local function releaseEntry(entry)
  V.require('FieldVolumes').release(entry)
 Seams.run('releaseMesh',entry.mesh)
 release(entry.mesh);release(entry.contacts);release(entry.caveSection)
 for _,batch in ipairs(entry.instances or {})do Seams.run('releaseMesh',batch.mesh);release(batch.mesh);release(batch.placements) end
end
-- Retain only the current and previous angle's geometry. Entering a battle
-- at the fixed normal angle must not destroy the player's 24-degree field.
-- Live layout stamps are still checked by SceneGeometry on every reuse.
local geometryViews={}
local geometrySerial=0
local function borderState()
 local state={}
 for k,v in pairs(Border)do if type(v)~='function'then state[k]=v end end
 return state
end
local function useBorder(state)
 for k,v in pairs(Border)do if type(v)~='function'then Border[k]=nil end end
 for k,v in pairs(state or{cache={},serial=0,count=0,trees=0})do Border[k]=v end
end
local function disposeView(view)
 for _,entry in pairs(view.cache or{})do releaseEntry(entry)end
 local active=borderState();useBorder(view.border);Border.release();useBorder(active)
end
function Renderer.selectGeometry()
 local key=Camera.geometryKey()
 if Renderer.geometryKey==key then return end
 BuildQueue.cancel();Renderer.buildPending=false
 if Renderer.geometryKey then
  local previous=geometryViews[Renderer.geometryKey]
  previous.cache,previous.border=Renderer.cache,borderState()
 end
 geometrySerial=geometrySerial+1
 local view=geometryViews[key]or{cache={}}
 view.used=geometrySerial;geometryViews[key]=view
 Renderer.cache=view.cache;useBorder(view.border);Renderer.geometryKey=key
 -- All angle-dependent templates and frame bindings must match the selected
 -- geometry. Compiled shaders and native sprites are independent of angle.
 Renderer.atlasGeneration=(Renderer.atlasGeneration or 0)+1
 WaterScene.key=nil;clearFrameStorage()
 Lights.release();WorldRain.invalidate(true)
 V.require('Trees').release();V.require('Props').release()
 local count,oldest,age=0,nil,math.huge
 for k,v in pairs(geometryViews)do
  count=count+1;if k~=key and v.used<age then oldest,age=k,v.used end
 end
 if count>3 then disposeView(geometryViews[oldest]);geometryViews[oldest]=nil end
end
function Renderer.invalidate()
 BuildQueue.cancel();Renderer.buildPending=false
 Renderer.atlasGeneration=(Renderer.atlasGeneration or 0)+1
 WaterScene.key=nil
 for key,view in pairs(geometryViews)do if key~=Renderer.geometryKey then disposeView(view)end end
 geometryViews={};Renderer.geometryKey=nil
 for _,entry in pairs(Renderer.cache)do releaseEntry(entry)end
 Renderer.cache={};Border.release();clearFrameStorage()
end
function Renderer.release()
  Seams.run("release")
  V.require('RoomBackdrop').release()
  V.require('GeometryCacheLookahead').release()
  V.require('AnimatedAtlasUpload').release()
  V.require('AtlasComposite').release()
  V.require("EmeraldReliefShadows").release()
  V.require("Presentation").release()
  V.require("EmeraldGymVisibility").release()
  V.require("EmeraldPyramidTop").release()
  Renderer.invalidate()
  Renderer.lastFrame=nil;release(Renderer.loadingCanvas);Renderer.loadingCanvas=nil
  Renderer.visibleEntries=nil;Renderer.mirrorEntries=nil
  for _,row in pairs(Renderer.actorMeshes or{})do release(row.mesh)end;Renderer.actorMeshes=nil
  Atmosphere.release()
  V.require('RooftopVista').release();V.require('CloudShafts').release();V.require('SkyEvents').release()
  Lights.release();Renderer.lightState=nil;V.require('ColorGrade').release()
  WorldRain.invalidate();V.require('HeatHaze').release()
  V.require("RoomEmission").release()
  WaterScene.release();Shadows.release();V.require("ContactShadows").release();Finish.release();NativeEffects.release()
  releasePrograms()
  for _,name in ipairs({"canvas","depth","shader","instanceShader","actorMesh","doorCanvas","doorMesh"})do release(Renderer[name]);Renderer[name]=nil end
end
function Renderer.prepareShaders()
  local post=V.require('DioramaConfig').post
  -- A rejected finish snippet can remove the same owner's main snippets.
  -- Resolve that before caching this version of the world source.
  if post.enabled then Finish.prepare()end
  local ambientEnabled=EnvironmentLight.shaderAmbientEnabled()
  if Renderer.seamVersion~=Seams.version or Renderer.ambientShaderEnabled~=ambientEnabled then
    local current=Renderer.buildShaderSource()
    -- Hook-only changes (or finish-only Cards) must not discard already
    -- compiled world programs and their driver-side first-draw state.
    if current~=Renderer.seamSource or Renderer.ambientShaderEnabled~=ambientEnabled then
      releasePrograms()
      Renderer.seamSource=current
    end
    Renderer.seamVersion=Seams.version
    Renderer.ambientShaderEnabled=ambientEnabled
    Renderer.compiledSeamSource=EnvironmentLight.prepareShader(Renderer.seamSource,ambientEnabled)
    Renderer.compiledBaseSource=EnvironmentLight.prepareShader(baseShaderSource,ambientEnabled)
  end
  local shaderSource=Renderer.compiledSeamSource
  local baseShaderSource=Renderer.compiledBaseSource
  local unshadowed=Renderer.roomProgram==false
  selectProgram(unshadowed and 'outdoor'or'room')
  if unshadowed then
   shaderSource=V.require('RoomShadowProgram').outdoor(shaderSource)
   baseShaderSource=V.require('RoomShadowProgram').outdoor(baseShaderSource)
  end
  if post.enabled and post.hdr and V.require('DioramaConfig').atmosphere.godRays.enabled then V.require('GodRays').prepare()end
  if post.enabled and post.hdr and V.require('HdrBloom').sceneFormat(true)=='rgba16f' then V.require('HdrBloom').prepare()end
  if (post.lutAmount or 0)>0 then V.require('ColorGrade').prepare()end
  if not Renderer.shader then
    local ok,shader,foot,rim,mask=pcall(SpriteRim.compile,shaderSource)
    if not ok and shaderSource~=baseShaderSource then
      Seams.failShaders(shader);Renderer.seamVersion=Seams.version;Renderer.seamSource=Renderer.buildShaderSource();shaderSource=EnvironmentLight.prepareShader(Renderer.seamSource,ambientEnabled);Renderer.compiledSeamSource=shaderSource
      releasePrograms();selectProgram(unshadowed and 'outdoor'or'room')
      if unshadowed then shaderSource=V.require('RoomShadowProgram').outdoor(shaderSource)end
      ok,shader,foot,rim,mask=pcall(SpriteRim.compile,shaderSource)
    end
    if not ok then error(shader,0)end
    Renderer.shader,Renderer.actorVertexLighting,Renderer.actorRimLighting,Renderer.maskShader=shader,foot,rim,mask
  end
  if not Renderer.instanceShader and love.graphics.getSupported().instancing then
    local ok,shader,unusedFoot,unusedRim,mask=pcall(function()
      return love.graphics.newShader(V.require('SurfaceDerivatives').prepare("#define WORLD_INSTANCES\n"..shaderSource)),nil,nil,false
    end)
    if not ok then
      if shaderSource==baseShaderSource then error(shader,0)end
      Seams.failShaders(shader)
      -- The provider stripped all shader owners; retry once with base source.
      return Renderer.prepareShaders()
    end
    Renderer.instanceShader,Renderer.instanceMaskShader=shader,mask
  end
  if not Renderer.depthAttempted then
   Renderer.depthAttempted=true
   local D=V.require('WorldDepthPrepass');local raw=Renderer.buildShaderSource(true)
   local ok,shader=pcall(function()return V.require('ShaderCompiler').newShader(D.source(raw))end)
   if ok then
    Renderer.depthOnly=shader
    if Renderer.instanceShader then
     local valid,instance=pcall(function()return V.require('ShaderCompiler').newShader(D.source('#define WORLD_INSTANCES\n'..raw))end)
     if valid then Renderer.instanceDepthOnly=instance
     else release(Renderer.depthOnly);Renderer.depthOnly=nil end
    end
   end
   -- An optional acceleration must never take the native world down on a
   -- driver that rejects its shader. Retry only after program invalidation.
  end
end
local function targets(width,height,readableDepth)
  Renderer.prepareShaders()
  readableDepth=readableDepth==true
  local post=V.require('DioramaConfig').post
  local sceneFormat=V.require('HdrBloom').sceneFormat(post.enabled and post.hdr)
  if Renderer.canvas and Renderer.canvas:getWidth()==width and Renderer.canvas:getHeight()==height and Renderer.readableDepth==readableDepth and Renderer.canvas:getFormat()==sceneFormat then return end
  Renderer.atlasGeneration=(Renderer.atlasGeneration or 0)+1
  Renderer.readableDepth=readableDepth;Renderer.hdr=sceneFormat=='rgba16f'
  release(Renderer.canvas);release(Renderer.depth)
  Renderer.canvas=love.graphics.newCanvas(width,height,{format=sceneFormat,dpiscale=1})
  Renderer.canvas:setFilter("nearest","nearest")
  Renderer.depth=love.graphics.newCanvas(width,height,{format="depth24",readable=readableDepth,dpiscale=1})
  if readableDepth then Renderer.depth:setFilter("nearest","nearest")end
end
local function combined(ts)return V.require('AtlasComposite').get(ts,Renderer.atlasGeneration or 0)end
local function waitingFrame(width,height)
  Renderer.buildPending=true
  if Renderer.lastFrame then return Renderer.lastFrame end
  if not Renderer.loadingCanvas then
    Renderer.loadingCanvas=love.graphics.newCanvas(width,height,{dpiscale=1})
    love.graphics.push('all');love.graphics.setCanvas(Renderer.loadingCanvas)
    love.graphics.clear(.035,.045,.055,1);love.graphics.pop()
  end
  return Renderer.loadingCanvas
end
-- Per-texture bindings belong immediately before each textured scene draw.
-- The source is a tileset, sprite descriptor, or nil (e.g. animated doors).
-- Shadow/mask-only passes keep their existing bindings untouched.
local function drawTextured(mesh,source,instances)
  local shader=love.graphics.getShader()
  local original,replacement
  if shader==Renderer.shader or shader==Renderer.instanceShader or shader==Renderer.depthOnly or shader==Renderer.instanceDepthOnly then
    original=mesh:getTexture()
    local context=frameStorage.textureContext;context.shader,context.source,context.frame=shader,source,frameCtx
    replacement=Seams.chain('textureSource',original,context)
    if replacement~=original then mesh:setTexture(replacement)end
    Seams.run('bindTexture',shader,replacement,frameCtx,source)
    Seams.run('bindMesh',shader,mesh,frameCtx,source,instances)
  end
  local stage
  if Trace.destinationActive() and Trace.pass=='world' then
    stage='destination '..(Trace.pass or 'unknown')..(instances and ' instances' or ' geometry')
    Trace.destination(stage..' draw begin',function()return 'vertices='..mesh:getVertexCount()..' instances='..tostring(instances or 1)end)
  end
  if instances then love.graphics.drawInstanced(mesh,instances)else love.graphics.draw(mesh)end
  if stage then Trace.destination(stage..' draw ready')end
  if original and replacement~=original then mesh:setTexture(original)end
end
local function drawActor(row)
  if not row.visible then return end
  local sprite=row.sprite
  ActorLighting.bind(love.graphics.getShader(),row.x,row.h,row.z)
  SpriteRim.bind(love.graphics.getShader(),sprite.image,sprite.imageData,sprite.quads)
  local stage
  if Trace.destinationActive()then
   stage='destination '..(Trace.pass or 'unknown')..' actor '..tostring(row.gid)
   Trace.destination(stage..' draw begin',function()return 'vertices='..row.mesh:getVertexCount()..' sprite='..sprite.image:getWidth()..'x'..sprite.image:getHeight()end)
  end
  drawTextured(row.mesh,sprite)
  if stage then Trace.destination(stage..' draw ready')end
end
-- Actor rows own their CPU vertices as well as the stream mesh. Keep the
-- original quad winding and arithmetic; only storage lifetime changes.
local function actorVertex(vertices,i,x,y,z,u,v,material)
  local out=vertices[i]
  if not out then out={};vertices[i]=out end
  out[1],out[2],out[3],out[4],out[5],out[6]=x,y,z,u,v,material
  out[7],out[8],out[9]=0,0,0
end
local function actorQuad(vertices,n,s0,t0,s1,t1,x,h,z,rx,rz,ux,uy,uz,hw,height,u0,v0,u1,v1,material)
  BuildBudget.tick()
  local top,bottom=height-t0,height-t1
  local left,right=s0-hw,s1-hw
  local ax,ay,az=x+rx*left+ux*top,h+uy*top,z+rz*left+uz*top
  local bx,by,bz=x+rx*right+ux*top,h+uy*top,z+rz*right+uz*top
  local cx,cy,cz=x+rx*right+ux*bottom,h+uy*bottom,z+rz*right+uz*bottom
  local dx,dy,dz=x+rx*left+ux*bottom,h+uy*bottom,z+rz*left+uz*bottom
  actorVertex(vertices,n+1,ax,ay,az,u0,v0,material)
  actorVertex(vertices,n+2,bx,by,bz,u1,v0,material)
  actorVertex(vertices,n+3,cx,cy,cz,u1,v1,material)
  actorVertex(vertices,n+4,ax,ay,az,u0,v0,material)
  actorVertex(vertices,n+5,cx,cy,cz,u1,v1,material)
  actorVertex(vertices,n+6,dx,dy,dz,u0,v1,material)
end
local function actor(actor,eye,target,mode,def,ts)
  -- Shadow silhouettes use the full sprite; interior colour passes may clip
  -- it. Keep those two geometries separate, and reuse each within this frame.
  Renderer.actorMeshes=Renderer.actorMeshes or{}
  local slot=assert(actor._renderSlot)*2+(def and 1 or 0)
  local row=Renderer.actorMeshes[slot]
  if not row then
    local full={}
    row={vertices={},target={0,0,0},fullRect=full,fullRects={full}};Renderer.actorMeshes[slot]=row
  end
  if row.tick==Renderer.tick then return drawActor(row)end
  row.tick=Renderer.tick;row.visible=false
  local sprite=Adapter.Sprites.get(actor.gid)
  if not sprite then return end
  local frame,flip=Adapter.Sprites.pose(sprite,V.require('FieldCamera').spriteFacing(actor.facing,actor.isPlayer),actor.phase,actor.flip,actor.pose)
  local q=sprite.quads[frame]
  if not q then return end
  local sx,sy,sw,sh=q:getViewport()
  local iw,ih=sprite.image:getDimensions()
  local leftU,topV,rightU,bottomV=sx/iw,sy/ih,(sx+sw)/iw,(sy+sh)/ih
  if flip then leftU,rightU=rightU,leftU end
  sprite.image:setFilter("nearest","nearest")
  local x,z=actor.x+8+(actor.xOffset or 0),actor.z+16+(actor.zOffset or 0)
  row.target[1],row.target[2],row.target[3]=x,0,z
  local rx,rz,ux,uy,uz=V.require("Billboard").axes(eye,row.target)
  local hs=V.require("Billboard").heightScale()
  if not V.data('Emerald').active() and actor.gid==95 then hs=hs*V.require("DioramaConfig").props.cutTreeHeightScale end
  ux,uy,uz=ux*hs,uy*hs,uz*hs
  if not V.require('DioramaConfig').billboards.enabled then ux,uy,uz=0,0,-1 end
  local h=V.require('DioramaConfig').billboards.enabled and (actor.yOffset or 0)or .1
  local hw=sprite.width/2
  local material=V.require('SeasonalFoliage').actorShade(actor.gid,V.data('Emerald').active())
  local vertices=row.vertices
  local rects=def and not Camera.experimental() and V.require('DioramaConfig').billboards.enabled and
    V.require('RocketActorOcclusion').rectangles(def,ts,x-hw,z-sprite.height,sprite.width,sprite.height)
  local count=0
  -- nil means the whole sprite; an empty clipping result means invisible.
  local full=row.fullRect
  full[1],full[2],full[3],full[4]=0,0,sprite.width,sprite.height
  for _,r in ipairs(rects or row.fullRects)do
    local u0,u1=leftU+(rightU-leftU)*r[1]/sprite.width,leftU+(rightU-leftU)*r[3]/sprite.width
    local v0,v1=topV+(bottomV-topV)*r[2]/sprite.height,topV+(bottomV-topV)*r[4]/sprite.height
    actorQuad(vertices,count,r[1],r[2],r[3],r[4],x,h,z,rx,rz,ux,uy,uz,hw,sprite.height,u0,v0,u1,v1,material)
    count=count+6
  end
  if count==0 then return end
  if not row.mesh or row.mesh:getVertexCount()<count then
    release(row.mesh);row.mesh=love.graphics.newMesh(Geometry.FORMAT,math.max(6,count),"triangles","stream")
  end
  row.mesh:setDrawRange(1,count)
  row.mesh:setVertices(vertices,1,count);row.mesh:setTexture(sprite.image)
  row.x,row.h,row.z,row.sprite,row.visible,row.gid=x,h,z,sprite,true,actor.gid
  drawActor(row)
end
-- Pose ownership is stable per map. No animation means no resolver probes;
-- repeated measurement/overlay calls reuse the current native door pose.
local doorOwners=setmetatable({},{__mode='k'})
local doorModules={'FireRedInteriorDoors','EmeraldPacifidlog','EmeraldFortreeArchitecture','FireRedFinalRooms','FireRedLeagueRooms','TrainerTowerRoof','EmeraldTrainerHillRoof','EmeraldTrainerHillEntrance','EmeraldBattlePalace','EmeraldBattleFactory','EmeraldBattleDome','EmeraldBattleArena','EmeraldTowerChallengeRooms','EmeraldTowerPublic','EmeraldChampionRoom','EmeraldPetalburgGym','EmeraldLeagueRooms','EmeraldIslandHarbors','EmeraldWreckDeck','EmeraldSkyPillar'}
local function doorPose(def,anim,extended)
 if not anim then return nil end
 local bank=doorOwners[def];if not bank then bank={};doorOwners[def]=bank end
 local key=extended and 'overlay' or 'measure';local row=bank[key]
 if row and row.tick==Renderer.tick and row.anim==anim and row.x==anim.x and row.y==anim.y then return row.pose end
 row=row or{};bank[key]=row;local pose
 if row.owner then pose=V.require(row.owner).doorPose(def,anim)end
 if not pose then for i,name in ipairs(doorModules)do
  if extended or(i~=2 and i~=3)then pose=V.require(name).doorPose(def,anim);if pose then row.owner=name;break end end
 end end
 row.tick,row.anim,row.x,row.y,row.pose=Renderer.tick,anim,anim.x,anim.y,pose;return pose
end
local function currentDoor(id,def)
  local Doors=require("src.core.game3.doors")
  return Doors.getActiveAnim(id)or V.require('EmeraldBattlePalace').scriptDoor(def,Doors.getActiveAnim())or V.require('EmeraldBattleFactory').scriptDoor(def,Doors.getActiveAnim())or V.require('EmeraldBattleDome').scriptDoor(def,Doors.getActiveAnim())
end
local function doorOverlay(id,def)
  local Doors=require("src.core.game3.doors")
  local anim=currentDoor(id,def)
  if not anim then return nil end
  if not Renderer.doorCanvas then
    Renderer.doorCanvas=love.graphics.newCanvas(64,32,{dpiscale=1})
    Renderer.doorCanvas:setFilter("nearest","nearest")
    Renderer.doorMesh=love.graphics.newMesh(Geometry.FORMAT,6,"triangles","stream")
  end
  love.graphics.setCanvas(Renderer.doorCanvas);love.graphics.origin()
  love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setScissor()
  love.graphics.clear(0,0,0,0);love.graphics.setColor(1,1,1,1)
  Doors.draw(anim.x*16-16,anim.y*16-16)
  local x,z=anim.x*16-16,(anim.y+1)*16+.15
  local vertices={}
  local roomDoor=doorPose(def,anim,true)
  local height=32*V.require('Billboard').heightScale()
  for _,b in ipairs(Geometry.buildings(def))do
    if b.doorX==anim.x and b.doorY==anim.y then
      local profile=V.data("BuildingProfiles").get(b,def.midLayout)
      height=height*(profile.paper and profile.paper.wallScale or profile.foldWallScale or 1);break
    end
  end
  if roomDoor then height=roomDoor.height;z=z+(roomDoor.zOffset or 0)end
  local base=roomDoor and roomDoor.base or 0
  Geometry.quad(vertices,{x,height+base,z},{x+64,height+base,z},{x+64,base,z},{x,base,z},{0,roomDoor and roomDoor.top or 0,1,1},1)
  Renderer.doorMesh:setVertices(vertices);Renderer.doorMesh:setTexture(Renderer.doorCanvas)
  return Renderer.doorMesh
end
local function obstructed(x,y,z)
  for _,cached in ipairs(frameStorage.drawList)do
    if Geometry.blocked(cached.heights,x,y,z)then return true end
  end
  return false
end
local function drawShadowActors()
  local b=frameStorage.bindings
  for _,a in ipairs(b.actors)do actor(a,b.eye,b.target,b.mode)end
  if b.shadowCasters then b.shadowCasters(b.vp)end
end
local boundShaders=setmetatable({},{__mode='k'})
local profileRows={}
local function profile(name,def)
 local bank=profileRows[name];if not bank then bank=setmetatable({},{__mode='k'});profileRows[name]=bank end
 local row=bank[def]
 if not row or row.tick~=Renderer.tick then
  row=row or{};bank[def]=row;row.tick=Renderer.tick;row.a,row.b=V.require(name).profile(def)
 end
 return row.a,row.b
end
local function shadowUniforms(shader)
  if boundShaders[shader]==Renderer.tick then return end;boundShaders[shader]=Renderer.tick
  local b=frameStorage.bindings
  local game,id,def,presentation,p=b.game,b.id,b.def,b.presentation,b.p
  local eye,target,vp,config,cloudLight=b.eye,b.target,b.vp,b.config,b.cloudLight
  local skyEvents,focus,roomVoidColor,roomClip,stats=b.skyEvents,b.focus,b.roomVoidColor,b.roomClip,b.stats
  local camCfg,interior,outdoors,atmosphere,lights=b.camCfg,b.interior,b.outdoors,b.atmosphere,b.lights
  local shadow,shadowStrength,width,height,pixelWidth=b.shadow,b.shadowStrength,b.width,b.height,b.pixelWidth
  local pixelHeight,weatherMode,weatherMood,effectDepthScale=b.pixelHeight,b.weatherMode,b.weatherMood,b.effectDepthScale
    EnvironmentLight.bind(shader);PaperTransmission.bind(shader);ActorLighting.begin(shader,lights);SpriteRim.begin(shader)
    PowerPlantRoom.bindSection(shader,not presentation and def or nil,p.px+8,p.py+16)
    V.require('RoomRecessClip').send(shader,def,vp)
    local cam=V.require('DioramaConfig').camera
    local dx,dy,dz=target[1]-eye[1],target[2]-eye[2],target[3]-eye[3]
    Uniform.send(shader,'belowGroundDepthY',Camera.projection()=='perspective'and Camera.verticalCorrection() and dy/math.sqrt(dx*dx+dy*dy+dz*dz)or 0)
    V.require('CloudDaylight').bind(shader,cloudLight);Uniform.send(shader,'skyEvents',skyEvents)
    V.require('CloudShafts').bindActors(shader,def,cloudLight,focus.px,focus.py)
    Uniform.send(shader,'hdrEmission',Renderer.hdr and math.max(1.001,config.post.hdrEmission or 2.5)or 1)
    shader:send("battleSpritePass",0);shader:send("battleDepthTest",0)
    V.require("RoomEmission").bind(shader)
    Uniform.send(shader,"roomVoidColor",roomVoidColor)
    Uniform.send(shader,"roomClipEnabled",roomClip and 1 or 0)
    Uniform.send(shader,"roomClipBounds",roomClip or zero4)
    stats.cutawayWalls=V.require("SilphCutaway").bind(shader,not presentation and def or nil,p.px+8,p.py+16)
    stats.caveCutaway=V.require('CaveCutaway').bind(shader,not presentation and def or nil,p.px+8,p.py+16)
    V.require('GhostWindows').bind(shader,DayNight.gameSeconds(game),DayNight.windowLight(),not presentation and id or '')
    right2[1],right2[2]=Camera.right();shader:send('billboardRight',right2)
    Uniform.send(shader,'fieldSkyDistance',Camera.experimental()and outdoors and payload('fieldSkyDistance',360,560)or payload('fieldSkyDistance',0,0))
    Uniform.send(shader,'fieldSkyColor',Renderer.fieldSkyColor or payload('fieldSkyColor',1,1,1))
    Uniform.send(shader,'spriteAlphaCutoff',V.require('DioramaConfig').billboards.alphaCutoff)
    Uniform.send(shader,'cameraEye',eye)
    Uniform.send(shader,'actorSunResponse',config.billboards.sunResponse or 1)
    shader:send('roomDepthScale',effectDepthScale)
    Uniform.send(shader,'groundShadow',shadow);Uniform.send(shader,'canvasSize',payload('canvasSize',pixelWidth or width,pixelHeight or height))
    Uniform.send(shader,'shadowStrength',shadowStrength)
    Uniform.send(shader,'sunColor',atmosphere.solar and atmosphere.solar.sunColor or payload('fieldSkyColor',1,1,1))
    Uniform.send(shader,'daylightDirect',outdoors and atmosphere.solar and (1-(atmosphere.solar.night or 0)) or 0)
    Uniform.send(shader,'duskShadow',payload('duskShadow',outdoors and atmosphere.solar and atmosphere.solar.dusk or 0,atmosphere.solar and atmosphere.solar.duskAmbientOcclusion or 0))
    V.require('Puddles').bind(shader,outdoors and config.weather.enabled,weatherMode,Weather.clock,weatherMood)
    Uniform.send(shader,'snowCover',outdoors and config.weather.enabled and Weather.visual.snow*config.weather.snow.cover or 0)
    V.require('SurfaceSteps').bind(shader,id,outdoors and Weather.visual.snow>.01)
    V.require('CeladonCrystal').bind(shader,atmosphere)
    V.require('SeasonalFoliage').bind(shader,def,outdoors,config.weather.enabled and Weather.visual.snow*config.weather.snow.cover or 0)
    local hl=config.surfaceHighlights
    Uniform.send(shader,'surfaceHighlights',payload('surfaceHighlights',hl.knee,outdoors and hl.maps[def.id or def.name]and hl.compression*(1-(atmosphere.solar and atmosphere.solar.night or 1))or 0))
    Uniform.send(shader,'daylightSaturation',atmosphere.solar and atmosphere.solar.saturation or 1)
    do local g=V.require('DioramaConfig').grass;local amount=g.gradeEnabled and outdoors and atmosphere.solar and (atmosphere.solar.grass or 0)*(g.gradeStrength or 1) or 0
      Uniform.send(shader,'grassGrade',payload('grassGrade',g.gradeColor[1],g.gradeColor[2],g.gradeColor[3],amount))
      local pl=V.require('DioramaConfig').foliageLift;local fm=V.require('DioramaConfig').forest;local day=outdoors and pl and pl.enabled and not (fm and fm.enabled and fm.maps[def.id or def.name]) and (1-((atmosphere.solar and atmosphere.solar.night) or 1)) or 0
      Uniform.send(shader,'plantLift',payload('plantLift',1+(pl and pl.tree or 0)*day,1+(pl and pl.grass or 0)*day))
      local sg=V.require('DioramaConfig').sand
      local night=(atmosphere.solar and atmosphere.solar.night) or 0
      local sc=payload("sandColor",1,1,1);if sg then for i=1,3 do sc[i]=sg.color[i]+((sg.nightColor or sg.color)[i]-sg.color[i])*night end end
      -- Night: reference paths read olive under moonlight, not brown.
      Uniform.send(shader,'sandGrade',payload('sandGrade',sc[1],sc[2],sc[3],sg and sg.enabled and outdoors and 1 or 0)) end
    do local c=V.require('DioramaConfig').clouds;local day=atmosphere.solar and 1-(atmosphere.solar.night or 0) or 0
      local t=DayNight.gameSeconds(game)
      Uniform.send(shader,'cloudShadow',payload('cloudShadow',c.scale,(c.enabled and outdoors and weatherMode~='rain' and weatherMode~='storm' and weatherMode~='fog') and c.strength*day*(1-cloudLight[1]) or 0,t*c.driftX,t*c.driftZ)) end
    do local m=V.require('DioramaConfig').moonFoliage;local night=outdoors and (atmosphere.solar and (atmosphere.solar.night or 0) or (atmosphere.moon and 1 or 0)) or 0
      Uniform.send(shader,'moonFill',payload('moonFill',m.color[1],m.color[2],m.color[3],m.enabled and night or 0));Uniform.send(shader,'actorNightFill',m.actorFill or 0);Uniform.send(shader,'moonWater',m.water or payload('fieldSkyColor',1,1,1)) end
    do local d=V.require('DioramaConfig').dynamicTexture
      Uniform.send(shader,'wind',payload('wind',DayNight.gameSeconds(game)%3600,(d.enabled and outdoors) and d.amplitude or 0,d.speed)) end
    local hp=profile('EmeraldPlaces',def)
    Uniform.send(shader,'hoennLight',payload('hoennLight',hp and hp.caustics or 0,hp and hp.lava or 0,DayNight.gameSeconds(game),hp and hp.nativeLava or 0))
    Uniform.send(shader,'waterMotion',payload('waterMotion',DayNight.gameSeconds(game),Renderer.waterStrength))
    V.require('WaterReflections').bind(shader,atmosphere,outdoors,weatherMode,weatherMood)
    Uniform.send(shader,'waterSparkles',V.require('Scenery').water(def,outdoors,DayNight.windowLight()))
    Uniform.send(shader,'sparkleColor',V.require('DioramaConfig').water.sparkleColor)
    do local sh=V.require('DioramaConfig').sheen or {}
      local wet=outdoors and config.weather.enabled and math.max(V.require('WeatherMood').rainAmount(weatherMode,weatherMood),V.require('Puddles').amount)*(sh.rain or 0)or 0
      Uniform.send(shader,'surfaceSheen',payload('surfaceSheen',outdoors and (sh.mapWater and sh.mapWater[def.id or def.name]or sh.water or 0) or 0,wet)) end
    do local cc=V.require('DioramaConfig').caves;Uniform.send(shader,'caveActorTint',atmosphere.flash and cc.actorFlashTint or atmosphere.darkCave and cc.actorDarkTint or cc.actorLitTint) end
    do local b=Renderer.badgeState
      if not Renderer.blankImage then local d=love.image.newImageData(1,1);Renderer.blankImage=love.graphics.newImage(d);d:release() end
      Uniform.send(shader,'badgeCookie',b and b.texture or Renderer.blankImage)
      Uniform.send(shader,'badgeArea',b and b.area or badgeDefault) end
end
function Renderer.draw(game,width,height,mode,neighbors,pixelWidth,pixelHeight,presentation)
  Renderer.tick=Renderer.tick+1
  Camera.worldBounds=nil
  V.require('FieldCamera').prepare(game,presentation)
  V.require('AnimatedAtlasUpload').install()
  Geometry.lenient=true
  local id,def=Adapter.current(game)
  if not id then return false end
  local backgroundReady=FieldWork.update(game,presentation)
  if V.require('GeometryCache').validateIndex()then V.require('GeometryPrefetch').pump(backgroundReady)end
  -- Select the room's fixed 50-degree cache before any scene lookup.
  if not presentation then V.require('DioramaConfig').camera.elevationDegrees=V.require('GraphicsOverlay').effectiveAngle(def)end
  Renderer.selectGeometry()
  local outdoors=Shapes.outdoors(def)
  Renderer.roomProgram=not outdoors or profile('RoomLightRig',def)~=nil
  local config=V.require('DioramaConfig')
  local mapView=outdoors and not presentation and (config.mapViews or {})[id] or nil
  local interior=not presentation and profile('IndoorSurfaces',def)
  if interior then mapView=frameStorage.interiorView;mapView.dofScale=config.interiors.dofScale end
  local camCfg=config.camera
  -- Set the effective scale before querying visible neighboring geometry.
  Camera.envScale=Camera.environmentScale(def,outdoors,mapView,presentation,V.require('HauntedFog').active(def))
  -- Resolve presentation-only camera Cards before culling / border coverage.
  local cameraContext=frameStorage.cameraContext
  cameraContext.game,cameraContext.def,cameraContext.id=game,def,id
  cameraContext.presentation,cameraContext.player=presentation,Adapter.Player
  Camera.override=Seams.chain('camera',false,cameraContext)or nil
  local entries,ahead=Adapter.maps(game,neighbors,width,height,nil,nil,
    outdoors and neighbors and not presentation and Renderer.cooperative and 192 or nil)
  if #entries==0 then return false end
  local heatAmount=outdoors and config.weather.enabled and Weather.visual.heat*config.weather.heatStrength or 0
  local fogDepth=config.weather.fog.volumetric~=false and (id:match('^FR_')or id:match('^EM_')or id:match('^SEVII_ONE_ISLAND'))
  local focusDepth=not Camera.experimental() and config.post.enabled and config.post.depthOfField and config.post.coc.enabled and DepthFocus.supported()
  Renderer.prepareShaders()
  local drawList,atlases=clear(frameStorage.drawList),clear(frameStorage.atlases)
  local previousMap=Renderer.preparedMap
  local stats=frameStorage.stats or{};frameStorage.stats=stats
  for k in pairs(stats)do stats[k]=nil end
  stats.map,stats.maps,stats.buildings,stats.vertices,stats.storedVertices,stats.camera=id,0,0,0,0,mode
  for _,entry in ipairs(entries)do
    local pair=entry.def.pair or entry.def.midLayout.pair
    -- get() binds the engine's animation bank. Do not keep switching that
    -- singleton between neighbor pairs every frame (it resets water to frame 0).
    local ts=Adapter.Native._pairs[pair] or Adapter.Native.get(pair)
    if ts then
      if not atlases[pair] then atlases[pair]=combined(ts) end
      local cached=SceneGeometry.get(Renderer,entry,ts,id,releaseEntry)
      if not cached then return waitingFrame(pixelWidth or width,pixelHeight or height)end
      cached.atlas=ts;cached.def=entry.def
      cached.foliageOrigin=cached.foliageOrigin or {entry.ox*16,entry.oy*16}
      cached.mesh:setTexture(atlases[pair]);drawList[#drawList+1]=cached
      if Camera.experimental()then
       local volumes=V.require('FieldVolumes')
       local sides=volumes.get(cached,entry.def,ts,entry.ox,entry.oy)
       if volumes.pending then return waitingFrame(pixelWidth or width,pixelHeight or height)end
       if sides then
        if sides.scene then sides.scene.mesh:setTexture(atlases[pair]);drawList[#drawList]=sides.scene end
        if sides.mesh then sides.mesh:setTexture(atlases[pair]);drawList[#drawList+1]=sides end
       end
      end
      for _,batch in ipairs(cached.instances)do batch.mesh:setTexture(atlases[pair]) end
      stats.maps=stats.maps+1;stats.buildings=stats.buildings+cached.stats.buildings
      stats.vertices=stats.vertices+cached.stats.vertices
      stats.storedVertices=stats.storedVertices+cached.stats.storedVertices
    elseif entry.id==id then return false end
  end
  Renderer.buildPending=false
  -- A cold MAP selection needs complete geometry for placement, not a full
  -- field frame, postprocessing stack, or new Retina render targets.
  if presentation and presentation.prepareOnly then return true end
  local actors=Adapter.actors(game,mode,entries)
  if Camera.experimental()=='first'then
   for i=#actors,1,-1 do if actors[i].isPlayer then table.remove(actors,i)end end
  end
  if Renderer.cooperative and not presentation and previousMap~=id
    and not SpriteRim.prepareActors(actors,Adapter.Sprites,id,Renderer.tick,outdoors)then
    return waitingFrame(pixelWidth or width,pixelHeight or height)
  end
  Trace.destination('destination targets begin')
  targets(pixelWidth or width,pixelHeight or height,(presentation and presentation.readableDepth)or not outdoors or heatAmount>0 or not not fogDepth or focusDepth or (config.post.hdr and config.atmosphere.godRays.enabled and V.require('GodRays').supported()))
  Trace.destination('destination targets ready',function()
   local hash=love.data.encode('string','hex',love.data.hash('sha256',Renderer.compiledSeamSource or ''))
   return 'worldShader='..hash..' depth='..Renderer.depth:getFormat()..' readable='..tostring(Renderer.readableDepth)
  end)
  if V.require('GeometryCache').index then V.require('GeometryCacheLookahead').update(game,id,def,backgroundReady)end
  V.require('RooftopVista').prepare(def,game)
  local activePair=def.pair or def.midLayout.pair
  local Animation=require("src.core.game3.tileset_anim")
  if Animation._pair~=activePair then Animation.bindPair(activePair) end
  -- Bound retained GPU meshes to the visible connection set plus a small LRU.
  local count=0;for _ in pairs(Renderer.cache)do count=count+1 end
  if count>12 then
    for key,cached in pairs(Renderer.cache)do
      if cached.used<Renderer.tick-1 then releaseEntry(cached);Renderer.cache[key]=nil end
    end
  end
  local weatherMap=frameStorage.weatherMap;weatherMap.id,weatherMap.def=id,def
  local weatherMode=config.weather.enabled and Weather.mode(weatherMap)or 'clear'
  local nativeDoor=currentDoor(id,def)
  local measuredDoor=not presentation and doorPose(def,nativeDoor,false)
  local door=(outdoors or measuredDoor)and V.require('DioramaConfig').billboards.enabled and doorOverlay(id,def)
  stats.doorOverlay=door~=nil and door~=false
  local p=Adapter.Player
  local roomClip=not presentation and V.require('EmeraldPetalburgGym').clipBounds(def,p.py)
  local roomProfile=profile('EmeraldRoomSurfaces',def)
  local roofScene=profile('TrainerTowerRoof',def)or V.require('EmeraldTrainerHillRoof').scene(def)or (roomProfile and roomProfile.roof and V.require('DioramaConfig').emeraldInteriors.department.roof) or profile('FireRedDepartmentRoof',def) or V.require('EmeraldSkyPillar').summit(def) or (profile('RooftopVista',def)and config.interiors.departmentRoof)
  if (outdoors or tonumber(def.mapType)==4)and not roofScene and profile('EmeraldNavelSanctums',def)~='top'and not profile('EmeraldWreckRooms',def)and not profile('EmeraldNewMauville',def)then
    local ts=Adapter.Native._pairs[activePair]
    local border,entry,ready=Border.get(def,ts,entries,p.px,p.py,Renderer.useInstancing and Renderer.instanceShader~=nil,width,height,Renderer.cooperative and previousMap~=id and not V.require('GeometryCache').record and Renderer.tick or nil)
    if ready==false then return waitingFrame(pixelWidth or width,pixelHeight or height)end
    if outdoors and not presentation and Border.coverageBounds then
      -- Neighbour selection is centred on the native player. A camera clamp
      -- must not reveal a connected map outside that already-built coverage.
      local ex,ez=Camera.groundExtents(width,height)
      local bounds=frameStorage.playBounds or{};frameStorage.playBounds=bounds
      bounds[1],bounds[2]=math.max(Border.coverageBounds[1],(p.px-ex)/16),math.max(Border.coverageBounds[2],(p.py-ez)/16)
      bounds[3],bounds[4]=math.min(Border.coverageBounds[3],(p.px+ex)/16),math.min(Border.coverageBounds[4],(p.py+ez)/16)
      Camera.worldBounds=bounds
    end
    if border then
      border:setTexture(atlases[activePair]);drawList[#drawList+1]=entry
      for _,batch in ipairs(entry.instances)do batch.mesh:setTexture(atlases[activePair])end
      stats.vertices=stats.vertices+entry.stats.vertices
      stats.storedVertices=stats.storedVertices+entry.stats.storedVertices
    end
    stats.borderQuads=Border.count;stats.borderTrees=Border.trees
  end
  local Objects=require("src.core.game3.objects")
  local focus=presentation and presentation.focus or Camera.nativeFocus(p,Objects)
  if interior and not Camera.experimental()then
    local L=def.midLayout;local follow=config.interiors.follow
    -- Long, turning ship corridors cannot share the small-room centre bias:
    -- it leaves the player offscreen at the stairs and cabin entrances.
    if profile('InteriorShipCorridors',def)then follow=config.interiors.shipCorridors.follow end
    local indigo=profile('InteriorIndigoReception',def);if indigo then follow=indigo.follow end
    local labFollow=V.require('InteriorLab').cameraFollow(def);if labFollow then follow=labFollow end
    frameStorage.focus.px,frameStorage.focus.py=(L.width*8-8)*(1-follow)+focus.px*follow,
      (L.height*8-8)*(1-follow)+focus.py*follow
    focus=frameStorage.focus
  end
  if not presentation then
    local panX,panZ=V.require('EmeraldTruck').cameraOffset(def)
    local liftX,liftZ=V.require('InteriorElevator').cameraOffset(def)
    panX,panZ=panX+liftX,panZ+liftZ
    if panX~=0 or panZ~=0 then frameStorage.focus.px,frameStorage.focus.py=focus.px+panX,focus.py+panZ;focus=frameStorage.focus end
  end
  -- Caves keep the closer framing of the cave reference clips.
  local focusHeight
  if not presentation and V.require('EmeraldMagmaHideout').active(def)then focusHeight=V.require('EmeraldMagmaHideout').actorHeight(def,focus.px,focus.py)end
  if not presentation and profile('FireRedIcefallArt',def)and V.require('FireRedIcefallArt').entrance(def)then
    focusHeight=V.require('FireRedTerracedCaves').actorHeight(def,focus.px,focus.py)
  end
  local vp,eye,target,ray=(presentation and presentation.matrix or Camera.matrix)(mode,focus.px+(mapView and mapView.focusOffsetX or 0),focus.py+(mapView and mapView.focusOffsetZ or 0),p.facing,width,height,obstructed,not outdoors,focusHeight)
  stats.cameraX,stats.cameraY=focus.px,focus.py
  local atmosphere=Atmosphere.prepare(def,p.px,p.py,DayNight.gameSeconds(game),outdoors)
  Renderer.badgeState=not outdoors and V.require('GymBadgeLight').prepare(def) or nil
  if Renderer.badgeState then V.require('GymBadgeLight').shafts(Renderer.badgeState,atmosphere.shafts) end
  frameCtx.game,frameCtx.def,frameCtx.id=game,def,id
  frameCtx.outdoors,frameCtx.cave=outdoors,tonumber(def.mapType)==4
  frameCtx.hasSky=type(roofScene)=='table'
  frameCtx.vp,frameCtx.eye,frameCtx.target,frameCtx.focus=vp,eye,target,focus
  frameCtx.atmosphere,frameCtx.dt,frameCtx.time=atmosphere,Renderer.frameDt or 0,DayNight.gameSeconds(game)
  frameCtx.pixelWidth,frameCtx.pixelHeight=Renderer.canvas:getDimensions()
  frameCtx.depth,frameCtx.canvas=Renderer.depth,Renderer.canvas
  frameCtx.playerX,frameCtx.playerZ,frameCtx.playerFacing=p.px+8,p.py+16,p.facing
  frameCtx.weatherMode,frameCtx.presentation=weatherMode,presentation
  frameCtx.lights=nil
  local weatherMood=config.weather.enabled and V.require('WeatherMood').sample(weatherMap)or nil
  local cloudLight=V.require('CloudDaylight').prepare(def,outdoors,atmosphere.solar,DayNight.gameSeconds(game),weatherMode,weatherMood and weatherMood.cloud)
  V.require('CloudDaylight').apply(atmosphere,cloudLight)
  frameCtx.cloudLight=cloudLight
  local skyEvents=V.require('SkyEvents').prepare(weatherMap,weatherMode,atmosphere.solar,DayNight.gameSeconds(game),weatherMood)
  frameCtx.skyEvents,frameCtx.weatherMood=skyEvents,weatherMood
  atmosphere=Seams.chain('lighting',atmosphere,frameCtx);frameCtx.atmosphere=atmosphere
  -- Lighting providers may supply an actual shadow rig on an outdoor map.
  -- Keep that authoritative state on the complete prewarmed room program.
  if not Renderer.roomProgram and atmosphere.roomRig and (atmosphere.roomRig.shadow or 0)>0 then
    Renderer.roomProgram=true;Renderer.prepareShaders()
  end
  EnvironmentLight.prepare(atmosphere,outdoors,Adapter.Native._pairs[activePair],eye,target,Camera.projection(),config.weather.enabled and Weather.visual.fog or 0,DayNight.time())
  stats.bounce=EnvironmentLight.meanColor
  PaperTransmission.prepare(atmosphere,outdoors)
  SpriteRim.prepare(atmosphere,outdoors,vp,target,Renderer.canvas:getWidth(),Renderer.canvas:getHeight())
  if presentation and presentation.hideActors then local props=clear(frameStorage.props);for _,a in ipairs(actors)do if a.battleProp then props[#props+1]=a end end;actors=props end
  V.require("Billboard").sort(actors,eye)
  for i,a in ipairs(actors)do a._renderSlot=i end
  frameCtx.actors=actors
  frameCtx.drawList=drawList
  Trace.destination('destination card prepare begin')
  Seams.run("prepare",frameCtx)
  Trace.destination('destination card prepare ready')
  Shadows.actorList=actors
  local bindings=frameStorage.bindings
  bindings.actors,bindings.eye,bindings.target,bindings.mode=actors,eye,target,mode
  bindings.shadowCasters=presentation and presentation.shadowCasters;bindings.vp=vp
  Trace.pass='shadow';Trace.destination('destination shadows begin')
  local shadow=Shadows.render(drawList,vp,pixelWidth or width,pixelHeight or height,outdoors,drawShadowActors,eye,atmosphere.solar)
  Trace.destination('destination shadows ready')
  Trace.pass='world';Trace.destination('destination scene target bind begin')
  love.graphics.setCanvas({Renderer.canvas,depthstencil=Renderer.depth})
  Trace.destination('destination scene target bind ready')
  love.graphics.origin();love.graphics.setScissor()
  local blackBackdrop=not outdoors and not roofScene and (tonumber(def.mapType)==8 or tonumber(def.mapType)==9 or Shapes.roomTileset(def)) and tonumber(def.mapType)~=4 and tonumber(def.mapType)~=5
  local roomVoidColor=blackBackdrop and V.require("RoomBackdrop").color or V.require("DioramaConfig").interiors.voidColor
  if roofScene and type(roofScene)=='table' then
    local night=DayNight.windowLight();local sky=frameStorage.sky or{};frameStorage.sky=sky
    for i=1,3 do sky[i]=roofScene.skyDay[i]+(roofScene.skyNight[i]-roofScene.skyDay[i])*night end
    love.graphics.clear(sky[1],sky[2],sky[3],1,0,1)
    V.require('FieldSky').draw(Renderer.canvas:getWidth(),Renderer.canvas:getHeight(),sky,weatherMode)
  elseif outdoors and Camera.experimental()then
    local night=DayNight.windowLight();local overcast=weatherMode=='storm'or weatherMode=='rain'or weatherMode=='fog'
    local day=overcast and {.52,.62,.72}or{.48,.72,.92}
    local sky=Renderer.fieldSkyColor or{};Renderer.fieldSkyColor=sky
    sky[1]=day[1]*(1-night)+.025*night;sky[2]=day[2]*(1-night)+.045*night;sky[3]=day[3]*(1-night)+.09*night
    love.graphics.clear(sky[1],sky[2],sky[3],1,0,1)
    V.require('FieldSky').draw(Renderer.canvas:getWidth(),Renderer.canvas:getHeight(),sky,weatherMode)
  else love.graphics.clear(outdoors and .06 or roomVoidColor[1],outdoors and .085 or roomVoidColor[2],outdoors and .11 or roomVoidColor[3],1,0,1)end
  V.require('RooftopVista').draw(def,Renderer.canvas:getWidth(),Renderer.canvas:getHeight(),p.px,p.py,DayNight.gameSeconds(game),weatherMode)
  V.require("EmeraldNavelSanctums").drawBackdrop(def)
  V.require("EmeraldPyramidTop").drawBackdrop(def,Renderer.canvas:getWidth(),Renderer.canvas:getHeight())
  V.require('EmeraldSkyPillar').drawBackdrop(def,Renderer.canvas:getWidth(),Renderer.canvas:getHeight(),DayNight.gameSeconds(game))
  love.graphics.setDepthMode("less",true);love.graphics.setMeshCullMode("none")
  love.graphics.setBlendMode("alpha","alphamultiply");love.graphics.setColor(1,1,1,1)
  if presentation and presentation.lights then presentation.lights(atmosphere)end
  local lights=Lights.prepare(drawList,focus.px,focus.py,outdoors,atmosphere,Renderer.lightState)
  Renderer.lightState=lights;frameCtx.lights=lights
  local shadowStrength=outdoors and (atmosphere.moon and .20 or .32)or .24
  if outdoors then shadowStrength=shadowStrength*DayNight.strengthAt(DayNight.time())end
  if atmosphere.solar then shadowStrength=shadowStrength*(1-atmosphere.solar.weight)+atmosphere.solar.shadowStrength*atmosphere.solar.weight end
  shadowStrength=shadowStrength*(weatherMood and weatherMood.shadow or((weatherMode=='rain'or weatherMode=='storm')and .45 or 1))
  local shadowConfig=V.require('DioramaConfig').shadows
  shadowStrength=shadowStrength*(shadowConfig.enabled and shadowConfig.strength or 0)
  local effectDepthScale=(interior or profile('EmeraldWreckCorridors',def) or profile('PokemonTowerShell',def) or profile('FireRedGymRooms',def) or profile('SevenIslandRooms',def) or profile('SeaCottage',def) or profile('CopycatRoom',def) or profile('VolunteerHouse',def) or profile('InteriorTrashedHouse',def) or profile('InteriorDisplayHouses',def) or profile('SafariRooms',def) or profile('PowerPlantRoom',def) or profile('MansionShell',def) or profile('EmeraldTrickQuiz',def) or profile('RocketRoomShell',def) or profile('TrainerTowerRooms',def) or profile('TrainerTowerRoof',def) or V.require('SilphStairs').recessed(def) or V.require('GateStairs').recessed(def) or V.require('EmeraldSkyPillar').summit(def)) and Camera.projection()=='perspective' and Camera.verticalCorrection() and .5 or 1
  bindings.game=game
  bindings.id=id
  bindings.def=def
  bindings.presentation=presentation
  bindings.p=p
  bindings.eye=eye
  bindings.target=target
  bindings.vp=vp
  bindings.config=config
  bindings.cloudLight=cloudLight
  bindings.skyEvents=skyEvents
  bindings.focus=focus
  bindings.roomVoidColor=roomVoidColor
  bindings.roomClip=roomClip
  bindings.stats=stats
  bindings.camCfg=camCfg
  bindings.interior=interior
  bindings.outdoors=outdoors
  bindings.atmosphere=atmosphere
  bindings.lights=lights
  bindings.shadow=shadow
  bindings.shadowStrength=shadowStrength
  bindings.width=width
  bindings.height=height
  bindings.pixelWidth=pixelWidth
  bindings.pixelHeight=pixelHeight
  bindings.weatherMode=weatherMode
  bindings.weatherMood=weatherMood
  bindings.effectDepthScale=effectDepthScale
  frameCtx.depthScale=effectDepthScale
  shadowUniforms(Renderer.shader)
  Seams.run("bind",Renderer.shader,frameCtx)
  Lights.send(Renderer.shader,lights)
  love.graphics.setShader(Renderer.shader);Uniform.send(Renderer.shader,"vp","row",vp)



  local tint=atmosphere.ambient
  local overcast=outdoors and (weatherMode=="rain" and .88 or weatherMode=="storm" and .78 or weatherMode=="snow" and .94 or 1) or 1
  if weatherMood then overcast=1;tint=payload("weatherTint",tint[1]*weatherMood.tint[1],tint[2]*weatherMood.tint[2],tint[3]*weatherMood.tint[3])end
  Uniform.send(Renderer.shader,"worldTint",payload("worldTint",tint[1]*overcast,tint[2]*overcast,tint[3]*overcast))
  Uniform.send(Renderer.shader,"sunDirection",atmosphere.direction);Uniform.send(Renderer.shader,"sunStrength",atmosphere.sun)

  Renderer.visibleEntries=Renderer.visibleEntries or{}
  Renderer.mirrorEntries=Renderer.mirrorEntries or{}
  -- Vertex Cards declare their conservative world-space expansion. Unknown
  -- Cards keep drawing complete geometry, including with an older provider.
  local deformation=Seams.vertexBounds and Seams.vertexBounds()
  local unbounded=not deformation and(Seams.shader('main.vertex.pre')~=''or Seams.shader('main.vertex.post')~='')
  local windPadding=config.dynamicTexture.enabled and outdoors and config.dynamicTexture.amplitude or 0
  local visible,culled,culledVertices=Visibility.select(drawList,Renderer.visibleEntries,vp,false,windPadding,pixelWidth or width,pixelHeight or height,unbounded,deformation)
  local reflected,mirrorCulled,mirrorVertices=Visibility.select(drawList,Renderer.mirrorEntries,vp,true,windPadding,math.max(1,(pixelWidth or width)*.5),math.max(1,(pixelHeight or height)*.5),unbounded,deformation)
  stats.culledEntries,stats.culledVertices=culled,culledVertices
  stats.mirrorCulledEntries,stats.mirrorCulledVertices=mirrorCulled,mirrorVertices
  local prepass=outdoors and not presentation and Renderer.depthOnly and Renderer.depthPrepass~=false
  if Renderer.depthPrepass==nil and V.require('EffectSettings').effective=='crisp' and camCfg.elevationDegrees>=45 then prepass=false end
  local function drawWorldDepth(list,mirror)
   local D=V.require('WorldDepthPrepass');love.graphics.setColorMask(false,false,false,false)
   local function depth(shader,instances)
    shadowUniforms(D.proxy(shader));local proxy=D.proxy(shader)
    proxy:send('vp','row',vp);proxy:send('waterMirrorPass',mirror and 1 or 0)
    love.graphics.setShader(shader)
    for _,cached in ipairs(list)do
     if instances then for _,batch in ipairs(cached.instances)do drawTextured(batch.mesh,cached.atlas,batch.count)end
     else drawTextured(cached.mesh,cached.atlas)end
    end
   end
   depth(Renderer.depthOnly,false)
   if Renderer.instanceDepthOnly then depth(Renderer.instanceDepthOnly,true)end
   love.graphics.setColorMask(true,true,true,true);love.graphics.setShader(Renderer.shader)
   love.graphics.setDepthMode('less',true)
  end
  Trace.destination('destination light bindings ready')
  Trace.destination('destination reflections begin')
  local mirrored=WaterScene.prepare(entries,pixelWidth or width,pixelHeight or height,config.water.reflections.enabled and config.water.reflections.scene~=false,Renderer.canvas:getFormat())
  WaterScene.bind(Renderer.shader,false)
  local reflectionClip=mirrored and WaterScene.clip(vp,drawList)or nil
  if reflectionClip and(reflectionClip[3]<=0 or reflectionClip[4]<=0)then mirrored=false;WaterScene.active=false end
  if mirrored then
    love.graphics.setCanvas({WaterScene.color,depthstencil=WaterScene.depth})
    love.graphics.setScissor()
    love.graphics.clear(0,0,0,0,0,1)
    -- Clear the entire target first: old reflected pixels must never survive
    -- camera movement. Only the subsequent scene rendering is restricted.
    if not reflectionClip or reflectionClip[3]>0 and reflectionClip[4]>0 then
      if reflectionClip then love.graphics.setScissor(unpack(reflectionClip))end
      WaterScene.bind(Renderer.shader,true)
      for _,cached in ipairs(reflected)do
        Lights.bindGlass(Renderer.shader,cached.atlas,cached.def)
        V.require('RoomEmission').bind(Renderer.shader,not presentation and cached.def or nil,cached.atlas)
        V.require('SeasonalFoliage').origin(Renderer.shader,cached)
        drawTextured(cached.mesh,cached.atlas)
      end
      V.require('RoomEmission').bind(Renderer.shader)
      if Renderer.instanceShader then
        local shader=Renderer.instanceShader;shadowUniforms(shader);Seams.run("bind",shader,frameCtx);Lights.send(shader,lights);Lights.bindGlass(shader)
        Uniform.send(shader,'vp','row',vp);Uniform.send(shader,'worldTint',payload("worldTint",tint[1]*overcast,tint[2]*overcast,tint[3]*overcast))
        Uniform.send(shader,'sunDirection',atmosphere.direction);Uniform.send(shader,'sunStrength',atmosphere.sun)
        WaterScene.bind(shader,true);love.graphics.setShader(shader)
        for _,cached in ipairs(reflected)do V.require('SeasonalFoliage').origin(shader,cached);for _,batch in ipairs(cached.instances)do drawTextured(batch.mesh,cached.atlas,batch.count)end end
        love.graphics.setShader(Renderer.shader)
      end
      Lights.bindGlass(Renderer.shader)
      if door then drawTextured(door)end
      for _,a in ipairs(actors)do actor(a,eye,target,mode,not presentation and def or nil,Adapter.Native._pairs[activePair])end
      V.require('SkyEvents').drawRainbow(skyEvents,cloudLight,vp,focus.px,focus.py,atmosphere.solar,true)
      love.graphics.setScissor()
    end
    love.graphics.setCanvas({Renderer.canvas,depthstencil=Renderer.depth})
    WaterScene.bind(Renderer.shader,false)
  end
  Trace.destination('destination reflections ready')
  stats.waterScene=mirrored;stats.waterReflectionPixels=mirrored and (reflectionClip and reflectionClip[3]*reflectionClip[4]or WaterScene.color:getWidth()*WaterScene.color:getHeight())or 0
  -- On shallow views many canopies overlap. Reject hidden fragments with a
  -- cheap alpha/depth pass before running the full world lighting shader.
  if prepass then drawWorldDepth(visible,false)end
  stats.depthPrepass=not not prepass
  Trace.destination('destination world begin')
  Seams.run("beforeWorld",frameCtx)
  local caveNeighbors=clear(frameStorage.caveNeighbors);for _,cached in ipairs(drawList)do if cached.caveCaps then caveNeighbors[#caveNeighbors+1]=cached.caveCaps end end
  for _,cached in ipairs(visible)do
    V.require('SeasonalFoliage').origin(Renderer.shader,cached)
    Lights.bindGlass(Renderer.shader,cached.atlas,cached.def);V.require("RoomEmission").bind(Renderer.shader,not presentation and cached.def or nil,cached.atlas);drawTextured(cached.mesh,cached.atlas)
    local section=V.require('CaveSectionMesh').update(cached,not presentation and def or nil,p.px+8,p.py+16,caveNeighbors)
    if section then drawTextured(section,cached.atlas)end
  end
  V.require("RoomEmission").bind(Renderer.shader)
  if Renderer.instanceShader then
    local shader=Renderer.instanceShader
    shadowUniforms(shader)
    Seams.run("bind",shader,frameCtx)
    WaterScene.bind(shader,false)
    Lights.send(shader,lights)
    Lights.bindGlass(shader)
    Uniform.send(shader,"sunDirection",atmosphere.direction);Uniform.send(shader,"sunStrength",atmosphere.sun);
    Uniform.send(shader,"vp","row",vp);

    Uniform.send(shader,"worldTint",payload("worldTint",tint[1]*overcast,tint[2]*overcast,tint[3]*overcast))
    love.graphics.setShader(shader)
    for _,cached in ipairs(visible)do
      V.require('SeasonalFoliage').origin(shader,cached)
      for _,batch in ipairs(cached.instances)do drawTextured(batch.mesh,cached.atlas,batch.count) end
    end
    love.graphics.setShader(Renderer.shader)
  end
  if prepass then love.graphics.setDepthMode('less',true)end
  Lights.bindGlass(Renderer.shader)
  if door then drawTextured(door) end
  Trace.destination('destination world ready')
  local worldScene=Seams.chain('afterGeometry',Renderer.canvas,frameCtx)
  if worldScene~=Renderer.canvas then
    local target=frameStorage.sceneTargets;target[1],target.depthstencil=worldScene,Renderer.depth
    love.graphics.setCanvas(target)
  end
  frameCtx.canvas=worldScene
  if not presentation then NativeEffects.behind()end
  Trace.pass='actors';Trace.destination('destination actors begin')
  local actorDef=not presentation and def or nil
  local actorTiles=actorDef and Adapter.Native._pairs[actorDef.pair]
  Seams.run("afterWorld",frameCtx)
  for _,a in ipairs(actors)do actor(a,eye,target,mode,actorDef,actorTiles) end
  Seams.run("afterActors",frameCtx)
  Trace.destination('destination actors ready')
  -- Only hidden player pixels pass this inverted depth test. No extra target,
  -- readback, NPC redraw or lighting evaluation is needed for the silhouette.
  local ghost=V.require('DioramaConfig').billboards.occludedPlayerOpacity
  if ghost>0 and not presentation and V.mod.options:get('gen3PlayerSilhouette')~=false then
    Uniform.send(Renderer.shader,'occludedPlayerPass',ghost)
    love.graphics.setDepthMode('greater',false)
    for _,a in ipairs(actors)do if a.isPlayer then actor(a,eye,target,mode,actorDef,actorTiles)end end
    Uniform.send(Renderer.shader,'occludedPlayerPass',0)
    love.graphics.setColor(1,1,1,1);love.graphics.setDepthMode('less',true)
  end
  ActorLighting.bind(Renderer.shader);SpriteRim.bind(Renderer.shader)
  if presentation and presentation.drawLayers then presentation.drawLayers(Renderer.shader,vp,Renderer.depth,pixelWidth or width,pixelHeight or height,atmosphere,lights)end
  if not presentation then NativeEffects.front(def);NativeEffects.heal(def,vp,effectDepthScale)end;stats.nativeEffects=NativeEffects.count
  stats.healSprites=NativeEffects.healCount;stats.healAnchored=NativeEffects.healAnchored
  Trace.destination('destination native effects ready')
  Trace.destination('destination room emission begin')
  local emissionWidth,emissionHeight=Renderer.canvas:getDimensions()
  local roomEmission=not presentation and config.post.enabled and config.post.bloom and V.require("RoomEmission").render(def,visible,Renderer.shader,Renderer.depth,emissionWidth,emissionHeight,Renderer.canvas:getFormat())
  Trace.destination('destination room emission ready')
  Trace.destination('destination atmosphere begin')
  Atmosphere.draw(atmosphere,vp)
  stats.rainbow=V.require('SkyEvents').drawRainbow(skyEvents,cloudLight,vp,focus.px,focus.py,atmosphere.solar)
  stats.cloudShafts=V.require('CloudShafts').draw(def,cloudLight,atmosphere,vp,shadow,focus.px,focus.py)
  local rainFocus=frameStorage.rainFocus;rainFocus[1],rainFocus[2],rainFocus[3]=p.px,0,p.py
  local precipitation=outdoors and WorldRain.draw(entries,drawList,weatherMood and weatherMood.precipMode or weatherMode,vp,eye,rainFocus,tint,pixelWidth or width,weatherMood and weatherMood.amount)
  stats.rainQuads=precipitation and WorldRain.last.count or 0
  stats.rainBuilds=WorldRain.rebuilds or 0
  stats.fireflies=atmosphere.fireflies;stats.crystals=atmosphere.crystals;stats.lunar=atmosphere.moon;stats.shafts=#atmosphere.shafts;stats.flash=atmosphere.flash
  stats.hoennTheme=(V.data('EmeraldLandscapes')[id]or{}).theme;stats.hoennSprites=atmosphere.hoennSprites or 0;stats.localLights=lights.count;stats.windowAmount=lights.amount
  stats.weather=weatherMode;stats.daytime=DayNight.time()
  if not presentation then NativeEffects.overlay(pixelWidth or width,pixelHeight or height)end
  stats.fieldOverlays=NativeEffects.overlayCount
  Renderer.stats=stats
  stats.projection=Camera.projection();stats.elevation=math.deg(Camera.elevation())
  local _,focusY=Camera.project(vp,p.px+8,16*V.require('Billboard').heightScale(),p.py+16)
  -- New colour processing belongs after fog/weather, immediately before the
  -- RGBA8 output. The disabled path retains the original composition order.
  Trace.destination('destination atmosphere ready')
  Trace.destination('destination postprocess begin')
  local focusContext=DepthFocus.context
  focusContext.depth,focusContext.vp,focusContext.eye,focusContext.target=Renderer.depth,vp,eye,target
  focusContext.depthScale=effectDepthScale
  focusContext.time,focusContext.hasSky=DayNight.time(),type(roofScene)=='table'
  focusContext.shadow,focusContext.outdoors,focusContext.solar=shadow,outdoors,atmosphere.solar
  focusContext.direction,focusContext.cloudLight,focusContext.projection=atmosphere.direction,cloudLight,Camera.projection()
  -- Battle cards test scene depth but do not write it. Keep them sharp until
  -- their final composited depth is available; transitions stay untouched.
  focusContext.disabled=not not Camera.experimental() or presentation~=nil or (Transition.isActive and Transition.isActive())
  focusContext.point[1],focusContext.point[2],focusContext.point[3]=p.px+8,16*V.require('Billboard').heightScale(),p.py+16
  local finishLast=focusDepth or Renderer.hdr or config.post.dither or config.post.aces or (config.post.lutAmount or 0)>0
  focusContext.frameCtx=frameCtx
  local finished=finishLast and worldScene or Finish.apply(worldScene,outdoors,focusY or .5,lights.amount,lights.cave,mapView,def,roomEmission,focusContext)
  local fogContext
  if fogDepth then
    fogContext=frameStorage.fog
    fogContext.depth,fogContext.depthScale,fogContext.ungradedScene=Renderer.depth,effectDepthScale,worldScene
    fogContext.voidColor,fogContext.eye,fogContext.outdoors,fogContext.solar=roomVoidColor,eye,outdoors,atmosphere.solar
  end
  if fogContext then V.require('VolumeFog').begin()end
  if not outdoors and V.require('HauntedFog').active(def)then finished=V.require('HauntedFog').apply(finished,vp,p.px,p.py,DayNight.gameSeconds(game),nil,fogContext);stats.haunted=true end
  do local vl=V.require('PlaceEffects').veil
    if vl then
      local opts=frameStorage.veil
      opts.density,opts.surge,opts.pocket=vl.density,false,vl.pocket or defaultPocket
      opts.color,opts.light,opts.clearCore,opts.ribbonMix=vl.color,vl.light,vl.clearCore or 1,vl.ribbons or .6
      finished=V.require('HauntedFog').apply(finished,vp,p.px,p.py,DayNight.gameSeconds(game),opts,fogContext)
    end end
  do local fc=V.require('DioramaConfig').forest
    if outdoors and fc.enabled and fc.haze and fc.maps[def.id or def.name] then
      -- Forest haze: low-contrast green veil drifting through the canopy (reference forest clip).
      local n=atmosphere.solar and atmosphere.solar.night or 0;local h=fc.haze;local col,lig=frameStorage.forestColor,frameStorage.forestLight
      local evening=V.require('DioramaConfig').daylight.goldenHour
      local warm=evening and evening.enabled and math.max(atmosphere.solar and atmosphere.solar.evening or 0,atmosphere.solar and atmosphere.solar.dusk or 0)or 0
      for i=1,3 do
        local hc=h.color[i]+((evening and evening.hazeColor[i]or h.color[i])-h.color[i])*warm
        local hl=h.light[i]+((evening and evening.hazeLight[i]or h.light[i])-h.light[i])*warm
        col[i]=hc+(h.nightColor[i]-hc)*n;lig[i]=hl+(h.nightLight[i]-hl)*n
      end
      local opts=frameStorage.forest;local place=profile('EmeraldPlaces',def)
      opts.density,opts.surge,opts.pocket=(place and place.forestFog)or h.density,false,h.pocket or defaultPocket
      opts.color,opts.light,opts.clearCore,opts.preTinted=col,lig,h.clearCore or 1,true
      local persistent=fc.persistent and fc.persistent.maps[def.id or def.name]and fc.persistent
      opts.height,opts.ribbonMix=h.height,h.ribbonMix
      if persistent then
        opts.density,opts.clearCore=persistent.density,persistent.clearCore
        opts.color,opts.light=persistent.color,persistent.light
        opts.height,opts.ribbonMix,opts.pocket=persistent.height,persistent.ribbonMix,persistent.pocket or opts.pocket
      end
      finished=V.require('HauntedFog').apply(finished,vp,p.px,p.py,DayNight.gameSeconds(game),opts,fogContext)
    end end
  finished=V.require('EmeraldPlaces').veil(def,finished,vp,p.px,p.py,DayNight.gameSeconds(game),fogContext)
  if not presentation then finished=V.require('EmeraldGymVisibility').apply(finished,def,vp,p.px,p.py)end
  local ep=profile('EmeraldPlaces',def)
  local localFog=V.require('PlaceEffects').veil or (ep and ep.mist)
  local fogged
  finished,fogged=V.require('SceneFog').apply(finished,def,vp,p.px,p.py,Weather.clock,
    Weather.visual.fog*config.weather.fogDensity,localFog,fogContext)
  if fogContext then
    local fog=V.require('VolumeFog');finished=fog.finish(finished);stats.fogLayers=fog.layers;stats.fogComposites=fog.layers>0 and 1 or 0
    if stats.haunted then V.require('HauntedFog').drawWisps(finished,vp,DayNight.gameSeconds(game),fogContext)end
  end
  stats.dynamicFog=fogged
  if heatAmount>0 then finished=V.require('HeatHaze').apply(finished,Renderer.depth,vp,heatAmount,Weather.clock)end
  local weatherOptions=frameStorage.weatherOptions
  weatherOptions.worldPrecipitation,weatherOptions.worldHeat,weatherOptions.worldFog=precipitation,true,true
  finished=Weather.apply(finished,pixelWidth or width,pixelHeight or height,
    weatherMap,math.max(1,(pixelHeight or height)/height),weatherMode,weatherOptions)
  if finishLast then finished=Finish.apply(finished,outdoors,focusY or .5,lights.amount,lights.cave,mapView,def,roomEmission,focusContext)end
  if V.require('GeometryCache').index then V.require('GeometryGpuWarm').update(V.require('GeometryCacheLookahead').targets,backgroundReady)end
  if blackBackdrop then finished=V.require('RoomBackdrop').apply(finished,worldScene,Renderer.depth,presentation~=nil)end
  Trace.destination('destination postprocess ready')
  Renderer.preparedMap=id;Renderer.lastFrame=finished
  -- Prepare connected native geometry before it enters the viewport. The
  -- same bounded queue publishes only complete meshes; gameplay keeps running.
  if backgroundReady and outdoors and neighbors and not presentation and Renderer.cooperative
    and not V.require('GeometryCache').record then
    for _,entry in ipairs(ahead or entries)do
      local preserve=config.trees.preserveViewRows[id]and entry.id~=id
      local key=entry.id..':'..tostring(entry.ox)..':'..tostring(entry.oy)..':'..tostring(preserve)
      local cached=Renderer.cache[key]
      if not cached or cached.layout~=entry.def.midLayout then
        local pair=entry.def.pair or entry.def.midLayout.pair
        local ts=Adapter.Native._pairs[pair]or Adapter.Native.get(pair)
        if ts then SceneGeometry.get(Renderer,entry,ts,id,releaseEntry)end
        break
      end
    end
  end
  if outdoors and neighbors and not presentation and Renderer.cooperative then
    V.require('ConnectionWarm').update(game,Renderer,width,height,releaseEntry)
  end
  return finished
end
return Renderer
