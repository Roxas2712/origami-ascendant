-- A below-floor surface is visible only through its measured floor opening.
-- Use the actual camera homography, including architectural correction.
local V=...;local R={MAX=4}
R.uniforms=[[
uniform int roomRecessCount;
uniform vec4 roomRecessBounds[4];
uniform mat3 roomRecessGroundFromScreen;
]]
R.fragment=[[
 if(worldPosition.y<-.001 && roomRecessCount>0){
  vec3 ground=roomRecessGroundFromScreen*vec3(screen/love_ScreenSize.xy*2.0-1.0,1.0);
  vec2 atFloor=ground.xy/ground.z;
  for(int i=0;i<4;i++){
   if(i>=roomRecessCount)break;
   vec4 b=roomRecessBounds[i];
   if(worldPosition.x>=b.x-.001 && worldPosition.z>=b.y-.001 && worldPosition.x<=b.z+.001 && worldPosition.z<=b.w+.001){
    if(atFloor.x<b.x || atFloor.y<b.y || atFloor.x>b.z || atFloor.y>b.w)discard;
    break;
   }
  }
 }
]]
function R.bounds(d)
 if not(d and d.midLayout)then return {}end
 local bounds=V.require('EmeraldWreckCorridors').recesses(d)
 if #bounds>0 then return bounds end
 bounds=V.require('InteriorShipCorridors').recesses(d)
 if #bounds>0 then return bounds end
 bounds=V.require('InteriorShipPublic').recesses(d)
 if #bounds>0 then return bounds end
 bounds=V.require('InteriorCasino').recesses(d)
 if #bounds>0 then return bounds end
 return V.require('InteriorTransit').recesses(d)
end
function R.shaft(out,b,depth,uv,shade)
 local G=V.require('WorldGeometry')
 for _,e in ipairs({{b[1],b[2],b[3],b[2]},{b[3],b[2],b[3],b[4]},
  {b[3],b[4],b[1],b[4]},{b[1],b[4],b[1],b[2]}})do
  G.quad(out,{e[1],0,e[2]},{e[3],0,e[4]},
   {e[3],-depth,e[4]},{e[1],-depth,e[2]},uv,shade)
 end
end
function R.send(shader,d,vp)
 local bounds=R.bounds(d);assert(#bounds<=R.MAX,'recess clip budget exceeded')
 shader:send('roomRecessCount',#bounds)
 if #bounds==0 then return end
 local padded={};for i=1,R.MAX do padded[i]=bounds[i]or{0,0,0,0}end
 shader:send('roomRecessBounds',unpack(padded))
 shader:send('roomRecessGroundFromScreen','row',V.require('Camera').groundInverse(vp))
end
return R
