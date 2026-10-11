-- Native Mystery Events house, including the visitor's swapped layout.
local V=...
local M={}
function M.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout;local id=d.id or d.name
 if not(c.enabled and c.mysteryHouse.enabled and d.mapType==8 and d.pair=='building__mystery_events_house'and L and L.width==12)then return end
 if id=='EM_SOOTOPOLIS_CITY_MYSTERY_EVENTS_HOUSE_1F'and L.height==8 and L:midAt(0,0)==0x207
  or id=='EM_SOOTOPOLIS_CITY_MYSTERY_EVENTS_HOUSE_B1F'and L.height==10 and L:midAt(0,0)==0x205 then return c.homeRooms.mysteryHouse end
end
function M.lighting(d)
 if not M.profile(d)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.mysteryHouse
 return (d.id or d.name):match('_B1F$')and c.basementLight or c.houseLight
end
-- Measured full native plant silhouette, retaining greys shared with the floor.
local spans={{7,9},{6,10},{3,13},{2,14},{2,14},{1,15},{0,16},{0,16},
 {1,15},{0,16},{0,16},{1,15},{2,14},{2,14},{3,13},{5,11},{6,10},{6,10},
 {4,12},{3,13},{2,14},{2,14},{2,14},{2,14},{2,14},{2,14},{2,14},{2,14},{3,13},{3,13},{4,12}}
function M.plantInside(s,t)local a=spans[t];return a and s>=a[1]and s<a[2]end
-- Case outlines are measured explicitly: their grey trim shares wall colours.
function M.caseInside(kind,s,t)
 if kind=='pc'then
  if t<13 or t>=40 then return false end
  local a=t==13 and 3 or t==14 and 2 or t==15 and 1 or t==38 and 1 or t==39 and 2 or 0
  return s>=a and s<16-a
 elseif kind=='cabinet'then
  if t<12 or t>=40 then return false end
  local a=(t==12 or t==39)and 1 or 0;return s>=a and s<32-a
 elseif kind=='drawer'then
  if t<1 or t>=24 then return false end
  if t==23 then return s<4 or s>=12 end
  return t~=1 or s>=1 and s<15
 end
 return false
end
function M.plan(d)
 if not M.profile(d)then return end
 local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.mysteryHouse
 local basement=(d.id or d.name):match('_B1F$');local width=basement and 12 or 11;local objects,mask={},{}
 local function floor(x,y)return(x==0 or y==2)and 0x236 or 0x235 end
 local function add(o,x,y,w,h)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=o.kind=='wall'and{mid=1,void=true}or floor(xx,yy)end
  end end
  return o
 end
 local blocked=not basement and L:midAt(3,0)==0x239
 for x=0,width-1 do
  local clean
  if basement and(x==0 or x==11)or not basement and x>=7 then clean={0x205,0x20d}
  elseif blocked and x>=2 and x<=4 then clean={0x202+x-2,0x20a+x-2}
  elseif not basement and(L:midAt(x,1)==0x213 or L:midAt(x,1)==0x22b)then clean={L:midAt(x,0),x==6 and 0x20e or 0x20d}end
  add({kind='wall',wallBase=32,wallLast=32,wallHeight=c.wallHeight,clean=clean},x,0,1,2)
 end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local mid=L:midAt(x,y)
  if mid==0 or mid==1 then mask[y*L.width+x+1]={mid=mid,void=true}
  elseif mid==0x213 or mid==0x218 or mid==0x223 or mid==0x22b or(y==1 and blocked and x>=2 and x<=4)then
   add({kind='mysteryPlant',noContact=true},x,y,1,2)
  elseif mid==0x227 then
   add({kind='mysteryCase',case='pc',cap=13,split=18,last=40,front=48,height=c.pcHeight,depth=6},x,y,1,3)
  elseif mid==0x214 then
   add({kind='mysteryCase',case='cabinet',cap=12,split=17,last=40,front=48,height=c.cabinetHeight,depth=8},x,y,2,3)
  elseif mid==0x22f then
   add({kind='mysteryCase',case='drawer',cap=1,split=8,last=24,front=32,height=c.drawerHeight,depth=7},x,y,1,2)
  elseif mid==0x216 then
   add({kind='fold',cap=0,split=25,last=32,front=32,height=c.tableHeight,depth=25,
    background={{mid=0x235}},positionMask=true},x,y,2,2)
  elseif mid==0x210 or mid==0x211 then
   add({kind='card',cap=0,last=16,front=16,height=c.chairHeight,background={{mid=0x235}},positionMask=true},x,y,1,1)
  end
 end end
 return objects,mask
end
function M.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.mysteryHouse
 if o.kind=='mysteryCase'then
  local function band(first,last,project)
   local vv=V.require('PaperSprite').build(ts,o.w,o.h,function(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end,
    function(s,t)return t>=first and t<last and M.caseInside(o.case,s,t)end,0,o.h,1,nil,project,.5)
   for _,v in ipairs(vv)do v[2]=v[2]*cfg.heightScale;out[#out+1]=v end
  end
  band(o.cap,o.split,function(s,t)return{x+s,o.height,z+o.front-o.depth+(t-o.cap)*o.depth/(o.split-o.cap)}end)
  band(o.split,o.last,function(s,t)return{x+s,o.height*(o.last-t)/(o.last-o.split),z+o.front}end)
  return
 end
 local vv=V.require('PaperSprite').build(ts,16,32,function(s,t)return L:midAt(o.x,o.y+math.floor(t/16)),s,t%16 end,
  M.plantInside,0,32,1,nil,function(s,t)return{x+s,(32-t)*c.plantHeight/32*cfg.heightScale,z+32}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
 if contacts then contacts[#contacts+1]={x+8,z+31,5,2,c.contactStrength}end
end
return M
