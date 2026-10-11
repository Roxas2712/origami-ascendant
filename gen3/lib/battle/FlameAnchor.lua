-- Measured FireRed front-sprite flame cores, in native 64x64 source pixels.
local A={points={[4]={43,36},[5]={51,24},[6]={59,32}}}
function A.screen(species,pose)
 local p=A.points[species];if not p or not pose then return end
 local x,y=(p[1]-32)*(pose.sx or 1),(p[2]-32)*(pose.sy or 1)
 local c,s=math.cos(pose.rot or 0),math.sin(pose.rot or 0)
 return pose.x+c*x-s*y,pose.y+s*x+c*y
end
return A
