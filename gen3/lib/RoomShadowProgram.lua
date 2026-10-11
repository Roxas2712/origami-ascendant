-- Compile-time specialization: retain the exported scene source and the
-- general rotated/sloped implementation, with a cheaper axis-aligned path.
local V=...;local P={}
P.fast=[[
uniform float oasc_room_axisAligned;
float oasc_room_hit(vec3 lo,vec3 hi,vec3 origin,vec3 direction){
 vec3 a=(lo-origin)/direction,b=(hi-origin)/direction;
 vec3 nearT=min(a,b),farT=max(a,b);
 float entry=max(nearT.x,max(nearT.y,nearT.z));
 float leave=min(farT.x,min(farT.y,farT.z));
 return leave>max(entry,.002) && entry<.998 && leave>0.0?1.0:0.0;
}
vec3 oasc_room_safe(vec3 d){
 return vec3(abs(d.x)<.0001?.0001:d.x,abs(d.y)<.0001?.0001:d.y,abs(d.z)<.0001?.0001:d.z);
}
float roomBalancedVisibility(vec3 receiver,vec3 source,vec2 area){
 if(oasc_room_axisAligned<.5)return oasc_room_reference(receiver,source,area);
 float v0=1.0,v1=1.0,v2=1.0,v3=1.0,v4=1.0;
 vec2 a=area*.61237244;
 vec3 spread=vec3(abs(a.x),0.0,abs(a.y));
 vec3 rayLow=min(receiver,source-spread)-vec3(1.0);
 vec3 rayHigh=max(receiver,source+spread)+vec3(1.0);
 // These five directions are independent of the blocker. Keep division in
 // the slab expression, preserving the reference arithmetic and epsilon.
 vec3 d0=oasc_room_safe(source-receiver);
 vec3 d1=oasc_room_safe((source+vec3(a.x,0.0,a.y))-receiver);
 vec3 d2=oasc_room_safe((source+vec3(-a.x,0.0,a.y))-receiver);
 vec3 d3=oasc_room_safe((source+vec3(a.x,0.0,-a.y))-receiver);
 vec3 d4=oasc_room_safe((source-vec3(a.x,0.0,a.y))-receiver);
 for(int j=0;j<roomBlockCount;j++){
  vec4 block=roomBlockLow[j];vec3 hi=roomBlockHigh[j];
  if(any(lessThan(rayHigh,block.xyz)) || any(greaterThan(rayLow,hi)))continue;
  float transmission=1.0-block.w;
  if(v0>transmission && oasc_room_hit(block.xyz,hi,receiver,d0)>.5)v0=transmission;
  if(v1>transmission && oasc_room_hit(block.xyz,hi,receiver,d1)>.5)v1=transmission;
  if(v2>transmission && oasc_room_hit(block.xyz,hi,receiver,d2)>.5)v2=transmission;
  if(v3>transmission && oasc_room_hit(block.xyz,hi,receiver,d3)>.5)v3=transmission;
  if(v4>transmission && oasc_room_hit(block.xyz,hi,receiver,d4)>.5)v4=transmission;
 }
 float visible=v0;visible+=v1;visible+=v2;visible+=v3;visible+=v4;
 return visible*.2;
}
]]
function P.prepare(source)
 if source:find('float oasc_room_reference(',1,true)then return source end
 local start=source:find('float roomBalancedVisibility(',1,true)
 local finish=start and source:find('float roomSourceShadow(',start,true)
 if not finish then return source end
 local reference=source:sub(start,finish-1):gsub('float roomBalancedVisibility%(','float oasc_room_reference(',1)
 return source:sub(1,start-1)..reference..P.fast..source:sub(finish)
end
-- Outdoor maps without a room rig never cast blocker/relief shadows. Compile
-- that invariant into a separate program; do not remove it from room shaders.
local outdoorSources,outdoorResults,nextOutdoor={},{},1
local function outdoor(source)
 local first=source:find('float roomSourceShadow(vec3 p, vec3 n, vec3 source, vec2 area,vec2 tile){',1,true)
 local last=first and source:find('float roomSourceShadow(vec3 p,vec3 n,vec3 source,vec2 area){',first,true)
 if not last then return source end
 return source:sub(1,first-1)..'float roomSourceShadow(vec3 p,vec3 n,vec3 source,vec2 area,vec2 tile){return 1.0;}\n'..source:sub(last)
end
function P.outdoor(source)
 for i=1,2 do if outdoorSources[i]==source then return outdoorResults[i]end end
 local result=outdoor(source)
 outdoorSources[nextOutdoor],outdoorResults[nextOutdoor]=source,result
 nextOutdoor=3-nextOutdoor
 return result
end
function P.bind(shader,state)
 if not shader or not V.require('UniformState').has(shader,'oasc_room_axisAligned')then return end
 local aligned=true
 for i=1,state and state.count or 0 do
  local b=state.boxes[i];local f,s=b and b.frame,b and b.slope
  if f and ((f[1]or 0)~=0 or (f[2]or 0)~=0 or (f[3]or 0)~=0 or (f[4]or 0)~=0)or s and (s[2]or 0)~=0 then aligned=false;break end
 end
 V.require('UniformState').send(shader,'oasc_room_axisAligned',aligned and 1 or 0)
end
return P
