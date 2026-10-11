-- Fixed ceiling fixtures for the measured native Silph layouts. Room gaps
-- and full-height wall courses block light even when visually cut away.
local V=...;local S={}
function S.profile(d)
 local c=V.require('DioramaConfig').silphLighting;local L=d and d.midLayout
 if not(c and c.enabled and L and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4ecc')then return end
 local room=c.rooms[d.id or d.name];if not room or L.width~=room.width or L.height~=room.height then return end
 local sources={}
 for _,p in ipairs(room.points)do
  local mid=L:midAt(math.floor(p[1]),math.floor(p[2]))
  -- Never illuminate an unmeasured replacement layout's void.
  if not mid or mid==0 or mid==8 then return end
  sources[#sources+1]={at={p[1]*16,c.height,p[2]*16},radius=c.radius,power=c.power,nightPower=c.nightPower,
   color=room.warm and c.warmColor or c.color,spread=c.spread,direction={0,-1,0},cone=c.cone}
 end
 return {ambient=c.ambient,night=c.night,sources=sources,localSelection=true,silph=true}
end
function S.capture(L,objects,ox,oz)
 local R=V.require('RoomLightRig');local boxes=R.geometry[L];if not boxes then return end
 local c=V.require('DioramaConfig').silphLighting
 -- Merge contiguous void tiles into exact rectangles. These are structural
 -- spaces between rooms, not walkable cells or furniture-sized shadow masks.
 local previous={}
 for y=0,L.height-1 do
  local row={};local x=0
  while x<L.width do
   if L:midAt(x,y)==8 or L:midAt(x,y)==0 then
    local first=x;repeat x=x+1 until x==L.width or (L:midAt(x,y)~=8 and L:midAt(x,y)~=0)
    local key=first..':'..x;local b=previous[key]
    if b then b.hi[3]=(y+oz+1)*16 else
     b={lo={(first+ox)*16,0,(y+oz)*16},hi={(x+ox)*16,c.wallHeight,(y+oz+1)*16},wall=true};boxes[#boxes+1]=b
    end
    row[key]=b
   else x=x+1 end
  end
  previous=row
 end
 for _,o in ipairs(objects)do if o.kind=='silphWallCourse'then
  local x,z=(o.x+ox)*16,(o.y+oz+2)*16;local h=math.max(c.wallHeight,V.require('DioramaConfig').interiors.silphWallPlants.wallHeight)
  local vertices={{x,0,z-c.wallThickness},{x+16,0,z},{x,h,z-c.wallThickness},{x+16,h,z}}
  R.capture(L,{kind='wall'},vertices,1,4)
 end end
end
return S
