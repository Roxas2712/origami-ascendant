-- Upright cards share the current camera plane’s horizontal basis.
-- CPU actors and shader instances keep native feet, without per-object yaw.
local V=...
local B={}
-- A steep view foreshortens upright art. Compensate its world height about
-- the fixed foot, without pitching the card or changing any map coordinates.
function B.heightScale()
 local C=V.require('Camera')
 if (C.experimental()and C.geometryProjection()or C.projection())=='perspective' and V.require('DioramaConfig').billboards.preservePixelAspect then
  return 1/math.cos(C.experimental()and C.geometryElevation()or C.elevation())
 end
 return 1
end
function B.up()
 return V.require('Camera').cardUp()
end
-- The camera has one shared horizontal basis. Never
-- swivel edge cards toward the eye position: that makes trees/fences lean.
function B.axes(eye,target)
 local uy,uz=B.up()
 local rx,rz=V.require('Camera').right();return rx,rz,0,uy,uz
end
local sortX,sortZ=1,0
local function farther(a,b)
 local az=(a.z+(a.zOffset or 0))*sortX-(a.x+(a.xOffset or 0))*sortZ
 local bz=(b.z+(b.zOffset or 0))*sortX-(b.x+(b.xOffset or 0))*sortZ
 if az~=bz then return az<bz end
 if a.x~=b.x then return a.x<b.x end
 return (a.gid or 0)<(b.gid or 0)
end
function B.sort(actors,eye)
 sortX,sortZ=V.require('Camera').right()
 table.sort(actors,farther)
end
return B
