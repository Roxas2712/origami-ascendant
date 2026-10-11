local V=...
local Mat4=V.require("Mat4")
local C=V.require('DioramaConfig').camera
local Camera={zoom=C.zoom,defaultZoom=C.zoom,modes={"paper"}}
local hasScene,Scene=pcall(require,'src.core.game3.camera_object')
-- Current Gen3 scripts move an invisible camera event object. Older runtimes
-- expose the same target through Objects; neither path moves the player.
function Camera.nativeFocus(player,objects)
 -- Mod package.loaded is a private shim, not the engine's live module table.
 local target=hasScene and Scene.object and Scene.object()
 if target then return target end
 return objects.cameraTarget and objects.cameraTarget()or player
end
function Camera.valid(mode)return mode=="paper" or mode=="off" end
local function nativeElevation()return math.rad(math.max(20,math.min(65,C.projection=="orthographic"and C.orthographicElevationDegrees or C.elevationDegrees)))end
function Camera.experimental()
 -- Scene templates must be built against their native cache angle, even
 -- when the user is looking through the optional free camera.
 local mode=V.require('FieldCamera').enabled()
 if mode and V.require('BuildBudget').ownsCurrent()then return nil end
 return mode
end
function Camera.yaw()return Camera.experimental()and V.require('FieldCamera').yaw or 0 end
function Camera.right()local yaw=Camera.yaw();return math.cos(yaw),-math.sin(yaw)end
function Camera.geometryElevation()return nativeElevation()end
function Camera.geometryProjection()return C.projection=="orthographic"and"orthographic"or"perspective"end
function Camera.verticalCorrection()return C.verticalCorrection and not Camera.experimental()end
function Camera.elevation()
 if Camera.experimental()then return math.rad(V.require('FieldCamera').pitch)end
 local degrees=Camera.override and Camera.override.elevationDegrees
 return degrees and math.rad(math.max(20,math.min(65,degrees)))or nativeElevation()
end
function Camera.projection()if Camera.experimental()then return 'perspective'end;return C.projection=="orthographic"and"orthographic"or"perspective"end
function Camera.cardUp()
 if not V.require("DioramaConfig").billboards.enabled or(Camera.projection()=="orthographic"and V.require('DioramaConfig').billboards.legacyLeanInOrthographic)then
  return math.cos(Camera.elevation()),-math.sin(Camera.elevation())
 end
 return 1,0
end
function Camera.zoomMultiplier()
 local o=Camera.override
 return o and math.max(.25,math.min(4,tonumber(o.zoomMul)or 1))or 1
end
function Camera.distance()
 local d=math.max(80,C.distance*Camera.zoom*(Camera.envScale or 1))
 return Camera.override and d/Camera.zoomMultiplier()or d
end
function Camera.environmentScale(def,outdoors,mapView,presentation,haunted)
 if tonumber(def.mapType)==4 or haunted then return C.caveZoomScale or 1 end
 if not outdoors then return C.indoorZoomScale or 1 end
 local scale=mapView and mapView.zoomScale or 1
 local id=def.id or def.name or ''
 if not presentation and Camera.projection()=='perspective' and id:match('^EM_')then
  scale=scale*(C.emeraldOutdoorScale or 1)
 end
 return scale
end
function Camera.fov()if Camera.experimental()then return math.rad(50)end;return math.rad(math.max(8,math.min(35,C.fovDegrees)))end
function Camera.geometryKey(degrees)
 local elevation=degrees and math.rad(math.max(20,math.min(65,degrees)))or nativeElevation()
 return (C.projection=="orthographic"and"orthographic"or"perspective")..':'..elevation..':'..tostring(V.require('DioramaConfig').billboards.enabled)..":"..tostring(V.require("DioramaConfig").billboards.legacyLeanInOrthographic)..":"..tostring(V.require("DioramaConfig").billboards.preservePixelAspect)
end
function Camera.groundExtents(width,height)
 if Camera.experimental()then
  local reach=80/math.tan(math.rad(7));local side=reach*math.tan(Camera.fov()/2)*width/height
  local radius=math.sqrt(reach*reach+side*side)+160;return radius,radius
 end
 local e=Camera.elevation();local aspect=width/height
 local o=Camera.override
 local padX=o and math.abs((o.offsetX or 0)+(o.shakeX or 0))or 0
 local padZ=o and math.abs((o.offsetZ or 0)+(o.shakeZ or 0))or 0
 if Camera.projection()=="orthographic"then
  local span=height*1.25*C.orthographicZoom*(Camera.zoom/Camera.defaultZoom)
  if Camera.override then span=span/Camera.zoomMultiplier()end
  return span*aspect/2+64+padX,span/(2*math.sin(e))+64+padZ
 end
 local d=Camera.distance();local half=math.min(Camera.fov()/2,e-.05)
 local t=d*math.sin(e)/(math.sin(e)-math.cos(e)*math.tan(half))
 local z=math.abs(d*math.cos(e)-t*(math.cos(e)+math.sin(e)*math.tan(half)))
 return t*math.tan(half)*aspect+64+padX,z+64+padZ
end
function Camera.connect(dx,dz,x,z)
 local last=Camera.lastPose
 if not last then return end
 Camera.connection={target={last.target[1]+dx,last.target[2],last.target[3]+dz},distance=last.distance,x=x,z=z,time=(V.clock or love.timer.getTime)()}
end
function Camera.matrix(mode,px,py,facing,width,height,obstructed,indoors,targetHeight)
 if Camera.experimental()then
  local P=require('src.core.game3.player');local yaw=Camera.yaw();local e=Camera.elevation()
  local head=math.min(48,32*V.require('Billboard').heightScale()*.92)
  -- Both modes share a forward-looking lens. Third Person translates the eye
  -- behind the native feet, instead of orbiting the map from above.
  local boom=Camera.experimental()=='third'and 96 or 0
  local eye={P.px+8+math.sin(yaw)*boom,head+(boom>0 and 28 or 0)+(targetHeight or 0),P.py+16+math.cos(yaw)*boom}
  local target={eye[1]-math.sin(yaw)*64,eye[2]-math.tan(e)*64,eye[3]-math.cos(yaw)*64}
  local vp=Mat4.mul(Mat4.scale(1,-1,1),Mat4.mul(Mat4.perspective(Camera.fov(),width/height,C.near,C.far),Mat4.lookAt(eye,target,{0,1,0})))
  Camera.boundaryScale=1;Camera.connection=nil
  Camera.lastPose={target=target,distance=64}
  return vp,eye,target
 end
 local target={px+8,(indoors and 8 or 0)+(targetHeight or 0),py+8-(indoors and 24 or 0)}
 local o=Camera.override
 if o then target[1]=target[1]+(o.offsetX or 0)+(o.shakeX or 0);target[3]=target[3]+(o.offsetZ or 0)+(o.shakeZ or 0)end
 local e,d=Camera.elevation(),Camera.distance()
 local function compose(distance,scale)
 local d=distance
 local eye={target[1],target[2]+d*math.sin(e),target[3]+d*math.cos(e)}
 local projection
 if Camera.projection()=="orthographic"then
  local span=height*1.25*C.orthographicZoom*(Camera.zoom/Camera.defaultZoom)
  if Camera.override then span=span/Camera.zoomMultiplier()end
  span=span*scale
  projection=Mat4.ortho(-span*width/height/2,span*width/height/2,-span/2,span/2,C.near,C.far)
 else projection=Mat4.perspective(Camera.fov(),width/height,C.near,C.far)end
 local vp=Mat4.mul(Mat4.scale(1,-1,1),Mat4.mul(projection,Mat4.lookAt(eye,target,{0,1,0})))
 -- Architectural vertical correction: retain perspective across the ground,
 -- but use the foot's perspective divisor for upright height. Otherwise even
 -- a telephoto lens keystones tall facades viewed at a steep pitch.
 if Camera.projection()=='perspective' and Camera.verticalCorrection() then vp[14]=0 end
 return vp,eye
 end
 local vp,eye=compose(d,1)
 Camera.boundaryScale=1
 if not indoors and Camera.worldBounds then
  local originalVP=vp;local originalTarget={target[1],target[2],target[3]}
  local function fit(limit)
   local scale,dx,dz=Camera.fitGroundBounds(originalVP,originalTarget,Camera.worldBounds,limit)
   target[1],target[3]=originalTarget[1]+dx,originalTarget[3]+dz
   vp,eye=compose(d*scale,scale);Camera.boundaryScale=scale
   local u,v=Camera.project(vp,originalTarget[1],0,originalTarget[3])
   return u and u>=.12 and u<=.88 and v>=.12 and v<=.88,scale
  end
  local visible,scale=fit(1)
  if not visible then
   -- A perspective trapezoid can contain all corners while its narrow end
   -- excludes the focus. Find the widest view that also keeps it on screen.
   local lo,hi=0,scale
   for i=1,12 do local mid=(lo+hi)*.5;if fit(mid)then lo=mid else hi=mid end end
   fit(math.max(lo,.001))
  end
 end
 local blend=Camera.connection
 if blend and not indoors then
  local age=(V.clock or love.timer.getTime)()-blend.time
  local a=math.min(1,age/.3);a=a*a*(3-2*a)
  local P=require('src.core.game3.player')
  target[1]=blend.target[1]+P.px-blend.x+(target[1]-blend.target[1]-P.px+blend.x)*a
  target[3]=blend.target[3]+P.py-blend.z+(target[3]-blend.target[3]-P.py+blend.z)*a
  local distance=blend.distance+(d*Camera.boundaryScale-blend.distance)*a
  vp,eye=compose(distance,distance/d)
  if Camera.worldBounds then
   local scale,dx,dz=Camera.fitGroundBounds(vp,target,Camera.worldBounds,1)
   target[1],target[3]=target[1]+dx,target[3]+dz
   distance=distance*scale;Camera.boundaryScale=distance/d
   vp,eye=compose(distance,distance/d)
  end
  if a>=1 then Camera.connection=nil end
 elseif indoors then Camera.connection=nil end
 Camera.lastPose={target={target[1],target[2],target[3]},distance=math.sqrt((eye[2]-target[2])^2+(eye[3]-target[3])^2)}
 return vp,eye,target
end
function Camera.project(m,x,y,z)
 local w=m[13]*x+m[14]*y+m[15]*z+m[16]
 if w<=0 then return nil end
 return (m[1]*x+m[2]*y+m[3]*z+m[4])/w*.5+.5,
   (m[5]*x+m[6]*y+m[7]*z+m[8])/w*.5+.5
end
-- Inverse of the ground-plane homography, including perspective and camera
-- translation. Screen-space fog must use this, not a scale around the player.
function Camera.groundInverse(m)
 local a,b,c,d,e,f,g,h,i=m[1],m[3],m[4],m[5],m[7],m[8],m[13],m[15],m[16]
 local det=a*(e*i-f*h)-b*(d*i-f*g)+c*(d*h-e*g)
 assert(math.abs(det)>1e-12,'singular ground projection')
 return {(e*i-f*h)/det,(c*h-b*i)/det,(b*f-c*e)/det,
  (f*g-d*i)/det,(a*i-c*g)/det,(c*d-a*f)/det,
  (d*h-e*g)/det,(b*g-a*h)/det,(a*e-b*d)/det}
end
-- Bounds are native map/connection coverage in tiles, including its border.
-- Stop the camera at the edge; only zoom closer if the whole viewport cannot
-- fit. This is presentation-only and never changes the saved zoom or player.
function Camera.fitGroundBounds(vp,target,bounds,maxScale)
 local inv=Camera.groundInverse(vp)
 local loX,loZ,hiX,hiZ=math.huge,math.huge,-math.huge,-math.huge
 for _,x in ipairs{-1,1}do for _,z in ipairs{-1,1}do
  local w=inv[7]*x+inv[8]*z+inv[9]
  local px,pz=(inv[1]*x+inv[2]*z+inv[3])/w,(inv[4]*x+inv[5]*z+inv[6])/w
  loX,loZ,hiX,hiZ=math.min(loX,px),math.min(loZ,pz),math.max(hiX,px),math.max(hiZ,pz)
 end end
 -- Horizon continuation fades over its outer 32 pixels. Stay inside that seam.
 local x0,z0,x1,z1=bounds[1]*16+34,bounds[2]*16+34,bounds[3]*16-34,bounds[4]*16-34
 local scale=math.min(maxScale or 1,(x1-x0)/(hiX-loX),(z1-z0)/(hiZ-loZ))
 local minX,maxX=x0-(loX-target[1])*scale,x1-(hiX-target[1])*scale
 local minZ,maxZ=z0-(loZ-target[3])*scale,z1-(hiZ-target[3])*scale
 local tx=math.max(minX,math.min(maxX,target[1]))
 local tz=math.max(minZ,math.min(maxZ,target[3]))
 return scale,tx-target[1],tz-target[3]
end
return Camera
