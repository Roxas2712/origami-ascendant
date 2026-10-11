-- Independent shader segment: all room uniforms are inert for legacy lights.
-- The balanced five-ray path shares blocker transforms; sample positions and
-- minimum-transmission semantics match the reference path. Keep the legacy
-- branch for authored relief/other sampling modes (see LIGHT_EVALUATION.md).
local V=...;return V.require('EmeraldReliefShader')..[[
uniform int roomBlockCount;
uniform vec4 roomBlockLow[24];
uniform vec3 roomBlockHigh[24];
uniform vec4 roomBlockFrame[24]; // pivot x/z, cos(angle)-1, sin(angle); zero = world AABB
uniform vec2 roomBlockSlope[24]; // z origin, height change per z; zero = level box
uniform float roomBalancedArea;
uniform vec4 roomLightModel; // diffuse floor, actor gain, shadow weight, samples
uniform vec4 roomSourceDirection[24]; // w<-1 = legacy source
uniform vec2 roomSourceArea[24];
#if defined(PIXEL) || defined(ACTOR_VERTEX_LIGHTING)
float roomVisibility(vec3 receiver, vec3 source,vec2 tile,float tap) {
 float visibility=roomReliefVisibility(receiver,source,tile,tap);
 // Visibility is a minimum, never a product: an equal/weaker blocker cannot
 // darken a ray again. Opaque walls still run after translucent furniture.
 for(int j=0;j<roomBlockCount;j++)if(visibility>1.0-roomBlockLow[j].w){
  vec3 origin=receiver,d=source-receiver;
  vec4 frame=roomBlockFrame[j];
  if(dot(abs(frame),vec4(1.0))>.00001){
   float c=1.0+frame.z,s=frame.w;
   vec2 localStart=receiver.xz-frame.xy;
   origin.xz=vec2(c*localStart.x+s*localStart.y,-s*localStart.x+c*localStart.y);
   d.xz=vec2(c*d.x+s*d.z,-s*d.x+c*d.z);
  }
  vec2 slope=roomBlockSlope[j];
  origin.y-=slope.y*(origin.z-slope.x);d.y-=slope.y*d.z;
  vec3 safeD=vec3(abs(d.x)<.0001?.0001:d.x,abs(d.y)<.0001?.0001:d.y,abs(d.z)<.0001?.0001:d.z);
  vec3 a=(roomBlockLow[j].xyz-origin)/safeD;
  vec3 b=(roomBlockHigh[j]-origin)/safeD;
  vec3 nearT=min(a,b),farT=max(a,b);
  float entry=max(nearT.x,max(nearT.y,nearT.z));
  float leave=min(farT.x,min(farT.y,farT.z));
  if(leave>max(entry,.002) && entry<.998 && leave>0.0){
   // Keep one exit: nested calls inside the 24-light loop miscompile on
   // the macOS GL driver when a fully opaque blocker returns early.
   visibility=min(visibility,1.0-roomBlockLow[j].w);
  }
 }
 return visibility;
}
float roomBalancedVisibility(vec3 receiver,vec3 source,vec2 area){
 float v0=1.0,v1=1.0,v2=1.0,v3=1.0,v4=1.0;
 vec2 a=area*.61237244;
 // All five finite rays fit inside these bounds. The one-pixel expansion
 // also covers the reference slab test's .0001 safe-direction adjustment.
 vec3 spread=vec3(abs(a.x),0.0,abs(a.y));
 vec3 rayLow=min(receiver,source-spread)-vec3(1.0);
 vec3 rayHigh=max(receiver,source+spread)+vec3(1.0);
 for(int j=0;j<roomBlockCount;j++){
  vec4 boundsFrame=roomBlockFrame[j];
  if(dot(abs(boundsFrame),vec4(1.0))<=.00001 && roomBlockSlope[j].y==0.0 &&
     (any(lessThan(rayHigh,roomBlockLow[j].xyz)) || any(greaterThan(rayLow,roomBlockHigh[j]))))continue;
  float transmission=1.0-roomBlockLow[j].w;
  if(max(v0,max(max(v1,v2),max(v3,v4)))>transmission){
   vec3 origin=receiver;
   vec4 frame=roomBlockFrame[j];vec2 slope=roomBlockSlope[j];
   bool rotated=dot(abs(frame),vec4(1.0))>.00001;
   float c=1.0+frame.z,s=frame.w;
   if(rotated){
    vec2 localStart=receiver.xz-frame.xy;
    origin.xz=vec2(c*localStart.x+s*localStart.y,-s*localStart.x+c*localStart.y);
   }
   origin.y-=slope.y*(origin.z-slope.x);
   if(v0>transmission){
    vec3 d=(source)-receiver;
    if(rotated)d.xz=vec2(c*d.x+s*d.z,-s*d.x+c*d.z);
    d.y-=slope.y*d.z;
    vec3 safeD=vec3(abs(d.x)<.0001?.0001:d.x,abs(d.y)<.0001?.0001:d.y,abs(d.z)<.0001?.0001:d.z);
    vec3 lo=(roomBlockLow[j].xyz-origin)/safeD,hi=(roomBlockHigh[j]-origin)/safeD;
    vec3 nearT=min(lo,hi),farT=max(lo,hi);
    float entry=max(nearT.x,max(nearT.y,nearT.z)),leave=min(farT.x,min(farT.y,farT.z));
    if(leave>max(entry,.002) && entry<.998 && leave>0.0)v0=min(v0,transmission);
   }
   if(v1>transmission){
    vec3 d=(source+vec3(a.x,0.0,a.y))-receiver;
    if(rotated)d.xz=vec2(c*d.x+s*d.z,-s*d.x+c*d.z);
    d.y-=slope.y*d.z;
    vec3 safeD=vec3(abs(d.x)<.0001?.0001:d.x,abs(d.y)<.0001?.0001:d.y,abs(d.z)<.0001?.0001:d.z);
    vec3 lo=(roomBlockLow[j].xyz-origin)/safeD,hi=(roomBlockHigh[j]-origin)/safeD;
    vec3 nearT=min(lo,hi),farT=max(lo,hi);
    float entry=max(nearT.x,max(nearT.y,nearT.z)),leave=min(farT.x,min(farT.y,farT.z));
    if(leave>max(entry,.002) && entry<.998 && leave>0.0)v1=min(v1,transmission);
   }
   if(v2>transmission){
    vec3 d=(source+vec3(-a.x,0.0,a.y))-receiver;
    if(rotated)d.xz=vec2(c*d.x+s*d.z,-s*d.x+c*d.z);
    d.y-=slope.y*d.z;
    vec3 safeD=vec3(abs(d.x)<.0001?.0001:d.x,abs(d.y)<.0001?.0001:d.y,abs(d.z)<.0001?.0001:d.z);
    vec3 lo=(roomBlockLow[j].xyz-origin)/safeD,hi=(roomBlockHigh[j]-origin)/safeD;
    vec3 nearT=min(lo,hi),farT=max(lo,hi);
    float entry=max(nearT.x,max(nearT.y,nearT.z)),leave=min(farT.x,min(farT.y,farT.z));
    if(leave>max(entry,.002) && entry<.998 && leave>0.0)v2=min(v2,transmission);
   }
   if(v3>transmission){
    vec3 d=(source+vec3(a.x,0.0,-a.y))-receiver;
    if(rotated)d.xz=vec2(c*d.x+s*d.z,-s*d.x+c*d.z);
    d.y-=slope.y*d.z;
    vec3 safeD=vec3(abs(d.x)<.0001?.0001:d.x,abs(d.y)<.0001?.0001:d.y,abs(d.z)<.0001?.0001:d.z);
    vec3 lo=(roomBlockLow[j].xyz-origin)/safeD,hi=(roomBlockHigh[j]-origin)/safeD;
    vec3 nearT=min(lo,hi),farT=max(lo,hi);
    float entry=max(nearT.x,max(nearT.y,nearT.z)),leave=min(farT.x,min(farT.y,farT.z));
    if(leave>max(entry,.002) && entry<.998 && leave>0.0)v3=min(v3,transmission);
   }
   if(v4>transmission){
    vec3 d=(source-vec3(a.x,0.0,a.y))-receiver;
    if(rotated)d.xz=vec2(c*d.x+s*d.z,-s*d.x+c*d.z);
    d.y-=slope.y*d.z;
    vec3 safeD=vec3(abs(d.x)<.0001?.0001:d.x,abs(d.y)<.0001?.0001:d.y,abs(d.z)<.0001?.0001:d.z);
    vec3 lo=(roomBlockLow[j].xyz-origin)/safeD,hi=(roomBlockHigh[j]-origin)/safeD;
    vec3 nearT=min(lo,hi),farT=max(lo,hi);
    float entry=max(nearT.x,max(nearT.y,nearT.z)),leave=min(farT.x,min(farT.y,farT.z));
    if(leave>max(entry,.002) && entry<.998 && leave>0.0)v4=min(v4,transmission);
   }
  }
 }
 float visible=v0;visible+=v1;visible+=v2;visible+=v3;visible+=v4;
 return visible*.2;
}
float roomSourceShadow(vec3 p, vec3 n, vec3 source, vec2 area,vec2 tile){
 if(roomLightModel.z<=0.0)return 1.0;
 vec3 start=p+n*.35;
 if(roomLightModel.w>1.5 && roomBalancedArea>.5 && roomReliefControl.x<.5)
  return mix(1.0,roomBalancedVisibility(start,source,area),roomLightModel.z);
 float visible=roomVisibility(start,source,tile,0.0);
 if(roomLightModel.w>1.5 && roomBalancedArea>.5 && roomReliefControl.x<.5){
  // Equal weights halve the central hard step without increasing ray count.
  // Quincunx moments match the legacy cross (0.3 * area^2 on each axis).
  // Relief atlases keep their authored five projections and tap indices.
  vec2 a=area*.61237244;
  visible+=roomVisibility(start,source+vec3(a.x,0.0,a.y),tile,0.0);
  visible+=roomVisibility(start,source+vec3(-a.x,0.0,a.y),tile,0.0);
  visible+=roomVisibility(start,source+vec3(a.x,0.0,-a.y),tile,0.0);
  visible+=roomVisibility(start,source-vec3(a.x,0.0,a.y),tile,0.0);
  visible*=.2;
 }else if(roomLightModel.w>1.5){
  visible*=.4;
  visible+=.15*roomVisibility(start,source+vec3(area.x,0.0,0.0),tile,1.0);
  visible+=.15*roomVisibility(start,source-vec3(area.x,0.0,0.0),tile,2.0);
  visible+=.15*roomVisibility(start,source+vec3(0.0,0.0,area.y),tile,3.0);
  visible+=.15*roomVisibility(start,source-vec3(0.0,0.0,area.y),tile,4.0);
 }
 return mix(1.0,visible,roomLightModel.z);
}
float roomSourceShadow(vec3 p,vec3 n,vec3 source,vec2 area){return roomSourceShadow(p,n,source,area,vec2(-1.0,1.0));}
#endif
]]
