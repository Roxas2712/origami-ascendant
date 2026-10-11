-- Measured Abandoned Ship cabins. Reuse the exact native inside_ship furniture
-- cutouts, while keeping damaged carpet, connecting passages and warp rugs.
local V=...;local C={}
local rooms={
 EM_ABANDONED_SHIP_ROOMS_1F={w=18,h=18,blocks={{1,0},{10,0},{1,9},{10,9}},anchor={13,16,0x264},bridges={{8,11,2,3},{13,8,1,3}}},
 EM_ABANDONED_SHIP_ROOMS_B1F={w=28,h=8,blocks={{1,0},{10,0},{19,0}},anchor={13,6,0x156}},
 EM_ABANDONED_SHIP_HIDDEN_FLOOR_ROOMS={w=44,h=16,blocks={{1,0,12,7},{15,0,13,7},{30,0,13,7},{1,8,12,7},{15,8,13,7},{30,8,13,7}},anchor={36,14,0x264},bridges={{28,1,2,3}}},
 EM_ABANDONED_SHIP_ROOM_B1F={w=10,h=8,blocks={{1,0}},anchor={4,7,0x264}},
 EM_ABANDONED_SHIP_ROOMS2_B1F={w=18,h=8,blocks={{1,0},{10,0}},anchor={13,7,0x264},cross=true},
 EM_ABANDONED_SHIP_ROOMS2_1F={w=10,h=18,blocks={{1,0},{1,9}},anchor={4,16,0x264},passage=true},
}
function C.profile(d)
 local a=V.require('DioramaConfig').emeraldInteriors;local L=d and d.midLayout
 local r=d and rooms[d.id or d.name]
 if a.enabled and a.wreck.enabled and a.wreck.cabins.enabled and r and tonumber(d.mapType)==4
  and d.pair=='general__inside_ship'and L and L.width==r.w and L.height==r.h
  and L:midAt(0,0)==0x236 and L:midAt(unpack(r.anchor,1,2))==r.anchor[3]then return a.wreck.cabinProfile,r end
end
function C.plan(d)
 local _,r=C.profile(d);local L=d.midLayout;local a=V.require('DioramaConfig').emeraldInteriors
 local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for y=0,L.height-1 do for x=0,L.width-1 do mask[y*L.width+x+1]={mid=0x201,void=true}end end
 local function floor(x,y)
  local m=L:midAt(x,y)
  mask[y*L.width+x+1]=0x238
  if m<0x200 or m==0x264 or m==0x265 or m==0x2aa or m==0x2ab then mask[y*L.width+x+1]=nil end
 end
 local bridges=r.bridges or(r.cross and{{8,2,2,3}}or r.passage and{{4,8,1,3}}or{})
 local function opening(x,y)
  for _,b in ipairs(bridges)do if x>=b[1]and x<b[1]+b[3]and y>=b[2]and y<b[2]+b[4]then return true end end
 end
 for _,b in ipairs(r.blocks)do local left,row,width,height=b[1],b[2],b[3]or 7,b[4]or 8
  for x=left,left+width-1 do
   if not opening(x,row)then
    add('wall',x,row,1,2,{wallHeight=a.wreck.wallHeight,wallLast=32,wallBase=32})
   end
   for y=row+2,row+height-1 do floor(x,y)end
  end
  for y=row+2,row+height-1 do
   if not opening(left-1,y)then add('tidalCabinSide',left,y,1,1,{left=true})end
   if not opening(left+width,y)then add('tidalCabinSide',left+width,y,1,1)end
  end
 end
 for _,b in ipairs(bridges)do for y=b[2],b[2]+b[4]-1 do for x=b[1],b[1]+b[3]-1 do floor(x,y)end end end
 local function clearWall(x,y,w)
  for _,o in ipairs(objects)do if o.kind=='wall'and o.y==y-1 and o.x>=x and o.x<x+w then o.clean={0x227,0x22f};o.keepBefore=24 end end
 end
 for y=1,L.height-1 do for x=1,L.width-1 do local m=L:midAt(x,y)
  if m==0x248 or m==0x275 or m==0x269 or m==0x24c then
   add('tidalCabinBed',x,y,2,3,{reverse=m~=0x248});clearWall(x,y,2)
  elseif m==0x256 or m==0x20f then add('tidalCabinTable',x,y,2,2)
  elseif m==0x260 or m==0x261 then add('tidalCabinChair',x,y,1,1,{reverse=m==0x261})
  elseif m==0x299 then add('tidalCabinDesk',x,y,2,2)
  elseif m==0x262 or m==0x277 or m==0x235 or m==0x267 or m==0x268 then add('tidalCabinBin',x,y,1,1)end
 end end
 return objects,mask
end
function C.actorHeight(d,x,z)
 if not C.profile(d)then return end
 local m=d.midLayout:midAt(math.floor((x+8)/16),math.floor((z+15.99)/16))
 if m==0x260 or m==0x261 then local a=V.require('DioramaConfig').emeraldInteriors;return a.ship.seatHeight*a.heightScale end
end
function C.lighting(d)
 local _,r=C.profile(d);if not r then return end
 local c=V.require('DioramaConfig').emeraldInteriors.wreck.cabins
 local sources={}
 for _,b in ipairs(r.blocks)do sources[#sources+1]={at={(b[1]+(b[3]and b[3]/2 or 3))*16,c.lightHeight,(b[2]+(b[4]or 8)*.625)*16},
  color=c.color,power=c.power,nightPower=c.nightPower,radius=c.radius,spread={18,14}}end
 return{ambient=c.ambient,night=c.night,sources=sources}
end
return C
