-- Psychic gym: contour shadows around the native teleport islands.
local V=...;local M={}
function M.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors.mossdeepLighting
 if c.enabled and d and d.mapType==8 and V.require('EmeraldMossdeepGym').profile(d)then return c.room end
end
function M.capture(list,o,x,z,vertices,first,last)
 if not o.kind:match('^mossGym')then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.mossdeepGym
 local box,contour=V.require('RoomShadowContours').writer(list,x,z,all.heightScale)
 if o.kind=='mossGymWall'then
  contour(16,16,0,c.wallHeight,function(s,t)return V.require('EmeraldMossdeepGym').wallInside(o.mid,s,t)end)
 elseif o.kind=='mossGymPillar'then box(0,16,4,16,0,c.pillarHeight,true)
 elseif o.kind=='mossGymStatue'then box(5,11,27.75,28.25,0,c.statueHeight-3)
 elseif o.kind=='mossGymPodium'then
  -- Reuse the actually rendered horizontal pixel runs. The native floor
  -- texels were already removed there; do not fill the surrounding rectangle.
  local world=V.require('RoomShadowContours').writer(list,0,0,1)
  local height=c.podiumHeight*all.heightScale
  for i=first,last,6 do
   local loX,loZ,hiX,hiZ=math.huge,math.huge,-math.huge,-math.huge;local top=true
   for j=i,math.min(i+5,last)do local v=vertices[j]
    if math.abs(v[2]-height)>.001 then top=false end
    loX=math.min(loX,v[1]);hiX=math.max(hiX,v[1]);loZ=math.min(loZ,v[3]);hiZ=math.max(hiZ,v[3])
   end
   if top and hiX>loX and hiZ>loZ then world(loX,hiX,loZ,hiZ,0,height,true)end
  end
 end
 return true
end
return M
