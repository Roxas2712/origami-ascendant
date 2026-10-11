-- Measured gate rooms: fixed ceiling lights and actual native window openings.
local V=...;local S={}
function S.profile(d)
 local c=V.require('DioramaConfig').gateLighting;local L=d and d.midLayout
 if not(c.enabled and L and V.require('GateFixtures').profile(d))then return end
 local room=c.rooms[d.id or d.name];if not room or room.width~=L.width or room.height~=L.height then return end
 local sources={}
 for _,p in ipairs(room.points)do
  local mid=L:midAt(math.floor(p[1]),math.floor(p[2]));if not mid or mid==0 or mid==8 then return end
  sources[#sources+1]={at={p[1]*16,c.height,p[2]*16},radius=c.radius,power=c.power,nightPower=c.nightPower,
   color=c.color,spread=c.spread,direction={0,-1,0},cone=c.cone}
 end
 for x=0,L.width-2 do
  local a,b=L:midAt(x,0),L:midAt(x+1,0)
  if a==0x298 and b==0x299 or a==0x2a8 and b==0x2a9 then
   sources[#sources+1]={at={(x+1)*16,c.windowHeight,34},radius=c.windowRadius,power=c.windowPower,nightPower=c.windowNightPower,
    color=c.windowColor,spread=c.windowSpread,direction={0,-.7,.7},cone=0}
  end
 end
 return {ambient=c.ambient,night=c.night,sources=sources,localSelection=true,gate=true}
end
-- Capture only actual solid surfaces. No billboard-sized boxes around plants,
-- no closed volume below glass tables, no filled rectangle in an L-shaped rail.
function S.box(L,x,y,z,w,h,depth,wall)
 local R=V.require('RoomLightRig');local boxes=R.geometry[L];if not boxes then return end
 local lo,hi={x,y,z},{x+w,y+h,z+depth}
 for _,b in ipairs(boxes)do if b.gate and b.wall==wall and b.lo[2]==lo[2]and b.hi[2]==hi[2]then
  if b.lo[1]==lo[1]and b.hi[1]==hi[1]and z<=b.hi[3]+.01 and z+depth>=b.lo[3]-.01 then b.lo[3]=math.min(z,b.lo[3]);b.hi[3]=math.max(z+depth,b.hi[3]);return end
  if b.lo[3]==lo[3]and b.hi[3]==hi[3]and x<=b.hi[1]+.01 and x+w>=b.lo[1]-.01 then b.lo[1]=math.min(x,b.lo[1]);b.hi[1]=math.max(x+w,b.hi[1]);return end
 end end
 boxes[#boxes+1]={lo=lo,hi=hi,wall=wall,gate=true}
end
function S.compact(L)
 local boxes=V.require('RoomLightRig').geometry[L];if not boxes then return end
 local changed=true
 while changed do
  changed=false
  for i=#boxes,2,-1 do local a=boxes[i]
   if a.gate then for j=1,i-1 do local b=boxes[j]
    if b.gate and a.wall==b.wall and a.lo[2]==b.lo[2]and a.hi[2]==b.hi[2]then
     for _,axis in ipairs({1,3})do local other=4-axis
      if a.lo[other]==b.lo[other]and a.hi[other]==b.hi[other]and a.lo[axis]<=b.hi[axis]+.01 and a.hi[axis]>=b.lo[axis]-.01 then
       b.lo[axis]=math.min(a.lo[axis],b.lo[axis]);b.hi[axis]=math.max(a.hi[axis],b.hi[axis]);table.remove(boxes,i);changed=true;break
      end
     end
     if changed then break end
    end
   end end
   if changed then break end
  end
 end
end
return S
