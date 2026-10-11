-- Four Elite chambers and five stair halls; native scripts own every door.
local V=...;local R={}
function R.profile(d)
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.leagueLighting
 if not(c.enabled and d and d.mapType==8)then return end
 local room=V.require('EmeraldLeagueRooms').profile(d);if not room then return end
 local kind=V.require('EmeraldLeagueRooms').kind(d);local sources={}
 local style=kind=='hall'and c.hall or c.styles[room.lightingStyle]
 if kind=='hall'then
  local L=d.midLayout;local zs=L.height==34 and c.longHallZ or c.hallZ
  for i,z in ipairs(zs)do
   local base=V.require('EmeraldLeagueRooms').actorHeight(d,80,z-16)
   sources[#sources+1]={at={i%2==1 and 76 or 100,base+c.hallHeight,z},radius=c.hallRadius,power=c.hallPower,nightPower=c.hallNightPower,color=style.color,spread=c.hallSpread}
  end
 else
  for _,s in ipairs(c.roomSources)do
   local q={};for k,v in pairs(s)do q[k]=v end;q.color=style.color;sources[#sources+1]=q
  end
 end
 return{localSelection=true,ambient=style.ambient,night=style.night,sources=sources}
end
function R.capture(list,o,x,z,vertices,first,last)
 if not o.kind:match('^league')then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.leagueRooms;local scale=all.heightScale
 local box=V.require('RoomShadowContours').writer(list,x,z,scale)
 if o.kind=='leagueWall'then
  local base=o.raised and c.hallRise or 0;local door=o.x==(o.raised and 5 or 6)
  -- Preserve the door aperture; the high lintel remains a wall. Never
  -- stretch a full wall-volume across the native animated doorway.
  box(0,16,47.75,48.25,base+(door and 32*c.wallHeight/42 or 0),base+c.wallHeight,true)
  box(0,16,42,48,base+c.wallHeight,base+c.wallHeight+.25,true)
 elseif o.kind=='leagueCutaway'then box(0,16,32,48,0,c.cutawayHeight,true)
 elseif o.kind=='leagueEntryGate'then box(0,16,31.75,32.25,0,c.cutawayHeight)
 elseif o.kind=='leagueLanding'then box(0,o.w,0,32,0,c.hallRise,true)
 elseif o.kind=='leagueStairs'then
  -- Parallel sloping top and bottom: a ray sees the 5px rail, never a
  -- 37px rectangle extending through the lower flight or the player.
  for _,s in ipairs({{4,16},{64,76}})do
   list[#list+1]={lo={x+s[1],c.hallRise*scale,z},hi={x+s[2],(c.hallRise+c.railHeight)*scale,z+o.h},slope={z,-c.hallRise*scale/o.h},wall=false}
  end
 elseif o.kind=='leagueAlcove'then
  local world=V.require('RoomShadowContours').writer(list,0,0,1);local height=c.alcoveRim*scale
  for i=first,last,6 do
   local a,b,u,v=math.huge,-math.huge,math.huge,-math.huge;local top=true
   for j=i,math.min(i+5,last)do local q=vertices[j];if math.abs(q[2]-height)>.001 then top=false end
    a=math.min(a,q[1]);b=math.max(b,q[1]);u=math.min(u,q[3]);v=math.max(v,q[3])
   end
   if top and b>a and v>u then world(a,b,u,v,0,height,true)end
  end
 end
 return true
end
return R
