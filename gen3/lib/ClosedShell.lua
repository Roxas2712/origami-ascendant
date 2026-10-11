-- Opt-in outward normals for axis-aligned opaque shell faces. Cards remain
-- double-sided. Keep the complete geometry, cull its hidden faces per pass.
local V=...
local S={left=-10,right=-11,bottom=-12,top=-13,back=-14,front=-15}
function S.tag(out,first,normal,section)
 for i=first,#out do out[i][9]=assert(S[normal])-(section and 20 or 0)end
end
S.shader=[[
vec3 closedShellNormal(float flag){
 // -30..-35 retain the same normals on the Power Plant's view section.
 if(flag< -29.5 && flag> -35.5)flag+=20.0;
 if(abs(flag+10.0)<.01)return vec3(-1.0,0.0,0.0);
 if(abs(flag+11.0)<.01)return vec3(1.0,0.0,0.0);
 if(abs(flag+12.0)<.01)return vec3(0.0,-1.0,0.0);
 if(abs(flag+13.0)<.01)return vec3(0.0,1.0,0.0);
 if(abs(flag+14.0)<.01)return vec3(0.0,0.0,-1.0);
 if(abs(flag+15.0)<.01)return vec3(0.0,0.0,1.0);
 return vec3(0.0);
}
bool closedShellHidden(float flag,mat4 vp,vec4 p){
 vec3 n=closedShellNormal(flag);
 if(dot(n,n)<.5)return false;
 // Test the projected outward orientation, including orthographic and the
 // architectural vertical correction. The physical camera eye alone is
 // insufficient once the projection's height divisor has been corrected.
 vec3 a=abs(n.x)>.5?vec3(0.0,1.0,0.0):(abs(n.y)>.5?vec3(0.0,0.0,1.0):vec3(1.0,0.0,0.0));
 vec3 b=cross(n,a);
 vec4 q=vp*p,da=vp*vec4(a,0.0),db=vp*vec4(b,0.0);
 vec2 u=da.xy*q.w-q.xy*da.w,v=db.xy*q.w-q.xy*db.w;
 // Camera.matrix flips Y for LÖVE: an outward visible face is clockwise.
 return u.x*v.y-u.y*v.x>=0.0;
}
]]
return S
