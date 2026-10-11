-- Native Lanette workshop and Scott room: measured fixtures, no player lamp.
local V=...;local R={}
local rooms={
 EM_ROUTE114_LANETTES_HOUSE={key='lanette',pair='building__lab',w=12,h=8,anchors={{0,0,0x210},{7,0,0x212},{4,3,0x230},{9,6,0x22c}}},
 EM_BATTLE_FRONTIER_SCOTTS_HOUSE={key='scott',pair='building__battle_frontier',w=6,h=8,anchors={{0,0,0x3bb},{5,3,0x3df},{5,4,0x3dc},{2,7,0x3b5}}},
}
function R.profile(d)
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.specialHomeLighting
 local r=d and rooms[d.id or d.name];local L=d and d.midLayout
 if not(all.enabled and c.enabled and r and d.mapType==8 and d.pair==r.pair and L and L.width==r.w and L.height==r.h)then return end
 for _,a in ipairs(r.anchors)do if L:midAt(a[1],a[2])~=a[3]then return end end
 return c[r.key]
end
function R.capture(list,o,x,z)
 if o.specialHomeLighting~='lanette'or o.kind~='fold'then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.specialHomeLighting
 local box=V.require('RoomShadowContours').writer(list,x,z,all.heightScale)
 local a,b=0,o.w;if o.bounds then a,b=o.bounds[1],o.bounds[2]end
 local h=o.height;local table=o.bench or o.desk
 box(a,b,o.front-o.depth,o.front,table and h-c.tableThickness or 0,h,true)
 local function device(a,b,offset,low,high)
  box(a,b,o.front+offset-c.deviceThickness/2,o.front+offset+c.deviceThickness/2,low,high,true)
 end
 if o.bench then
  local height=(o.pcHeight or 22)*all.deviceScale;local offset=o.deviceOffset or -16
  device(1,15,offset,h,h+height-5*all.deviceScale)
  device(2,15,offset,h+height-5*all.deviceScale,h+height-all.deviceScale)
 end
 if o.pc then
  device(1,10,-10,h,h+18*all.deviceScale)
  device(10,23,-10,h,h+19*all.deviceScale)
 end
 if o.book then device(21,30,-9,h,h+13*all.deviceScale)end
 if o.benchCup then device(5,15,-10,h,h+8*all.deviceScale)end
 if o.labBall then device(3,9,-10,h,h+7*all.deviceScale)end
 if o.shelfBox then box(9,23,o.front-17,o.front-9,h,h+all.boxHeight)end
 return true
end
return R
