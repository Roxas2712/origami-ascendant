-- Height-aware fixtures for the Champion, recording room and League lobby.
-- Geometry and native scripts remain owned by the measured room modules.
local V=...;local R={}
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors.leagueFinalLighting
 if not(c.enabled and d and d.mapType==8)then return end
 if V.require('EmeraldChampionRoom').profile(d)then return c.champion end
 if V.require('EmeraldHallOfFame').profile(d)then return c.fame end
 local p=V.require('EmeraldLeagueReception').profile(d)
 if p then return p.family=='link'and c.link or c.reception end
end
function R.capture(list,o,x,z,vertices,first,last)
 local champion=o.kind=='championRoom';local fame=o.kind:match('^fame')
 if not(champion or fame or o.kind=='receptionTable')then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local scale=all.heightScale
 local thickness=all.leagueFinalLighting.wallThickness
 local box=V.require('RoomShadowContours').writer(list,x,z,scale)
 local function wall(ax,az,bx,bz,low,high)
  local dx,dz=bx-ax,bz-az;local length=math.sqrt(dx*dx+dz*dz)
  list[#list+1]={lo={0,low*scale,-thickness/2},hi={length,high*scale,thickness/2},
   frame={x+ax,z+az,dx/length-1,dz/length},wall=true,
   worldLow={x+math.min(ax,bx)-thickness,low*scale,z+math.min(az,bz)-thickness},
   worldHigh={x+math.max(ax,bx)+thickness,high*scale,z+math.max(az,bz)+thickness}}
 end
 if champion then
  local c=all.championRoom;local h=c.platformHeight
  -- Follow the diagonal wings, never the bounding box of the entire room.
  for _,r in ipairs({{0,128,64,64},{64,64,80,64},{128,64,144,64},{144,64,208,128},
   {80,48,80,64},{128,48,128,64}})do wall(r[1],r[2],r[3],r[4],h,h+c.wallHeight)end
  -- The original exit doorway stays open below its lintel.
  wall(80,48,96,48,h+c.exitRise,h+c.exitRise+c.wallHeight*.75)
  wall(112,48,128,48,h+c.exitRise,h+c.exitRise+c.wallHeight*.75)
  wall(96,48,112,48,h+c.exitRise+c.wallHeight*.5,h+c.exitRise+c.wallHeight*.75)
  for _,r in ipairs({{32,96,32,128},{32,128,64,160},{64,160,80,160},
   {128,160,144,160},{144,160,176,128},{176,128,176,96}})do wall(r[1],r[2],r[3],r[4],0,h)end
  -- Real step heights: no tall enclosing block across either flight.
  for a=160,200,8 do
   local high=h*(208-a)/48;box(80,128,a,a+6,0,high,true);box(80,128,a+6,a+8,0,high-h/6,true)
  end
  for _,r in ipairs({{48,62,1},{62,70,2/3},{70,78,1/3}})do box(80,128,r[1],r[2],h,h+c.exitRise*r[3],true)end
 elseif o.kind=='fameRear'then
  local h=all.hallOfFame.wallHeight
  for _,r in ipairs({{0,48,16,40},{16,40,80,40},{80,40,88,60},{88,60,152,60},
   {152,60,160,40},{160,40,224,40},{224,40,240,48}})do wall(r[1],r[2],r[3],r[4],0,h)end
 elseif o.kind=='fameSide'then
  local c=all.hallOfFame;local a=o.right and 20 or 0;local b=o.right and 32 or 12
  box(a,b,0,160,0,c.sideHeight,true)
  list[#list+1]={lo={x+a,0,z+160},hi={x+b,c.sideHeight*scale,z+208},
   slope={z+160,-(c.sideHeight-c.frontHeight)*scale/48},wall=false}
 elseif o.kind=='fameConsole'then
  -- Reuse opaque native row spans. Sloping display casts a thin sloping
  -- shadow; palette colors inside the display never become holes.
  local rows={}
  for i=first,last,6 do
   local lo={math.huge,math.huge,math.huge};local hi={-math.huge,-math.huge,-math.huge}
   for j=i,i+5 do local q=vertices[j];for k=1,3 do lo[k]=math.min(lo[k],q[k]);hi[k]=math.max(hi[k],q[k])end end
   if hi[3]>lo[3]and hi[1]>lo[1]then
    local key=string.format('%.5f:%.5f:%.5f',lo[3],hi[3],hi[2])
    local row=rows[key]
    if row then row.lo[1]=math.min(row.lo[1],lo[1]);row.hi[1]=math.max(row.hi[1],hi[1])
    else rows[key]={lo={lo[1],hi[2]-scale,lo[3]},hi={hi[1],hi[2],hi[3]},
     slope={lo[3],-(hi[2]-lo[2])/(hi[3]-lo[3])},wall=false}end
   end
  end
  local ordered={};for _,row in pairs(rows)do ordered[#ordered+1]=row end
  table.sort(ordered,function(a,b)return a.lo[3]<b.lo[3]end)
  local previous
  for _,row in ipairs(ordered)do
   if previous and previous.lo[1]==row.lo[1]and previous.hi[1]==row.hi[1]
    and math.abs(previous.hi[3]-row.lo[3])<.001
    and math.abs(previous.slope[2]-row.slope[2])<.001
    and math.abs(previous.hi[2]+previous.slope[2]*(row.lo[3]-previous.slope[1])-row.hi[2])<.001 then
    previous.hi[3]=row.hi[3]
   else list[#list+1]=row;previous=row end
  end
 elseif o.kind=='receptionTable'then
  local h=o.height*scale;local world=V.require('RoomShadowContours').writer(list,0,0,1)
  for i=first,last,6 do
   local a,b,u,v=math.huge,-math.huge,math.huge,-math.huge;local top=true
   for j=i,i+5 do local q=vertices[j];if math.abs(q[2]-h)>.001 then top=false end
    a=math.min(a,q[1]);b=math.max(b,q[1]);u=math.min(u,q[3]);v=math.max(v,q[3])end
   if top and b>a and v>u then world(a,b,u,v,h-2*scale,h,true)end
  end
 end
 -- Floors and entry mats do not enclose shadow volumes.
 return true
end
return R
