-- Native triangle-height ray intersections; empty regions use a conservative skip.
return [[
uniform Image roomReliefHeights;
uniform Image roomReliefDistances;
uniform vec4 roomReliefMeta; // width, depth, maximum height, reserved
uniform vec4 roomReliefControl; // enabled, height bias, iteration budget, reserved
uniform Image roomReliefAtlas;
uniform vec4 roomReliefAtlasInfo; // enabled, columns, rows, receiver bias
uniform vec2 roomReliefAtlasSize;
uniform float roomReliefAtlasHeight;
uniform float roomFurnitureShadow;
uniform vec2 roomReliefTiles[24]; // first slot, projection half extent
#if defined(PIXEL) || defined(ACTOR_VERTEX_LIGHTING)
float roomReliefHeight(vec4 h,vec2 f){
 return f.x>=f.y ? h.x+(h.y-h.x)*f.x+(h.z-h.y)*f.y : h.x+(h.z-h.w)*f.x+(h.w-h.x)*f.y;
}
vec3 roomReliefTrace(vec3 start, vec3 source){
 float visibility=1.0,finished=1.0,used=0.0;
 if(roomReliefControl.x>.5){
  vec3 delta=source-start;float speed=length(delta.xz);
  float t=.001;bool running=true;finished=0.0;
  for(int k=0;k<96;k++){
   if(!running || float(k)>=roomReliefControl.z)break;
   used=float(k+1);vec3 p=start+delta*t;
   if(t>=.999 || (delta.y>=0.0 && p.y>=roomReliefMeta.z+roomReliefControl.y)){
    running=false;finished=1.0;
   }else{
    vec2 cell=floor(p.xz),uv=(cell+vec2(.5))/roomReliefMeta.xy;
    bool inside=cell.x>=0.0 && cell.y>=0.0 && cell.x<roomReliefMeta.x && cell.y<roomReliefMeta.y;
    float empty=inside?max(0.0,Texel(roomReliefDistances,uv).r*255.0-1.5):0.0;
    if(empty>1.0){t+=empty/max(speed,.00001);}
    else{
     vec4 h=inside?Texel(roomReliefHeights,uv)*roomReliefMeta.z:vec4(0.0);
     float tx=abs(delta.x)<.00001?2.0:((delta.x>0.0?cell.x+1.0:cell.x)-start.x)/delta.x;
     float tz=abs(delta.z)<.00001?2.0:((delta.z>0.0?cell.y+1.0:cell.y)-start.z)/delta.z;
     float endT=min(1.0,min(tx,tz));
     vec3 endP=start+delta*endT;
     float gap=min(p.y-roomReliefHeight(h,p.xz-cell),endP.y-roomReliefHeight(h,endP.xz-cell));
     // A quad contains two triangles. Include the diagonal crossing; testing
     // only the cell endpoints would miss concave/convex native corner relief.
     float diag=delta.x-delta.z;
     if(abs(diag)>.00001){
      float middle=t+((p.z-cell.y)-(p.x-cell.x))/diag;
      if(middle>t && middle<endT){vec3 q=start+delta*middle;gap=min(gap,q.y-roomReliefHeight(h,q.xz-cell));}
     }
     if(gap < -roomReliefControl.y){visibility=0.0;finished=1.0;running=false;}
     else{t=max(t+.000005,endT+.000005);}
    }
   }
  }
  if(finished<.5)visibility=0.0;
 }
 return vec3(visibility,finished,used);
}
float roomReliefVisibility(vec3 receiver,vec3 source,vec2 tile,float tap){
 float visible=1.0;
 if(roomReliefControl.x>.5){
  if(roomReliefAtlasInfo.x>1.5 && tile.x>=0.0){
   vec3 d=receiver-source,a=abs(d);float face;vec3 p;
   if(a.x>=a.y && a.x>=a.z){
    if(d.x>=0.0){face=0.0;p=vec3(-d.z,d.y,d.x);}else{face=1.0;p=vec3(d.z,d.y,-d.x);}
   }else if(a.y>=a.z){
    if(d.y>=0.0){face=2.0;p=vec3(d.x,-d.z,d.y);}else{face=3.0;p=vec3(d.x,d.z,-d.y);}
   }else{
    if(d.z>=0.0){face=4.0;p=vec3(d.x,d.y,d.z);}else{face=5.0;p=vec3(-d.x,d.y,-d.z);}
   }
   vec2 uv=p.xy/max(.0001,p.z)*.5+.5;
   float slot=tile.x+tap*6.0+face;
   vec2 cell=vec2(mod(slot,roomReliefAtlasInfo.y),floor(slot/roomReliefAtlasInfo.y));
   vec2 inset=.5*roomReliefAtlasInfo.yz/roomReliefAtlasSize;
   uv=(cell+clamp(uv,inset,vec2(1.0)-inset))/roomReliefAtlasInfo.yz;
   vec2 depths=Texel(roomReliefAtlas,uv).rg*tile.y;
   float distance=max(0.0,length(d)-roomReliefAtlasInfo.w);
   visible=min(step(distance,depths.r),mix(1.0,step(distance,depths.g),roomFurnitureShadow));
  }else if(roomReliefAtlasInfo.x>.5 && tile.x>=0.0 && receiver.y<source.y){
   vec2 p=(receiver.xz-source.xz)/(1.0-receiver.y/source.y)/tile.y*.5+.5;
   if(p.x>=0.0 && p.y>=0.0 && p.x<=1.0 && p.y<=1.0){
    float slot=tile.x+tap;
    vec2 cell=vec2(mod(slot,roomReliefAtlasInfo.y),floor(slot/roomReliefAtlasInfo.y));
    vec2 inset=.5*roomReliefAtlasInfo.yz/roomReliefAtlasSize;
    vec2 uv=(cell+clamp(p,inset,vec2(1.0)-inset))/roomReliefAtlasInfo.yz;
    float h=Texel(roomReliefAtlas,uv).r*roomReliefAtlasHeight;
    visible=step(h,receiver.y+roomReliefAtlasInfo.w);
   }
  }else{visible=roomReliefTrace(receiver,source).x;}
 }
 return visible;
}

#endif
]]
