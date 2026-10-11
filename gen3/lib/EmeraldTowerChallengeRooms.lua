-- Tower transit/challenge rooms. Native scripts, floor emblems and dynamic
-- metatiles remain authoritative; only walls, plants and columns are lifted.
local V=...
local R={}
local defs={
 CORRIDOR={18,6,'hall',8,3,0x229},
 MULTI_CORRIDOR={18,6,'hall',8,3,0x229},
 ELEVATOR={6,8,'elevator',2,5,0x265},
 BATTLE_ROOM={10,10,'battle',4,4,0x251},
 MULTI_BATTLE_ROOM={10,10,'battle',4,4,0x251},
}
function R.kind(d)
 local key=d and(d.id or d.name or''):match('^EM_BATTLE_FRONTIER_BATTLE_TOWER_(.+)$')
 return defs[key],key
end
function R.profile(d)
 local p=R.kind(d);if not p then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if cfg.enabled and cfg.towerChallenge.enabled and d.pair=='building__battle_frontier'and L and L.width==p[1]and L.height==p[2]and L:midAt(p[4],p[5])==p[6]then
  return cfg.homeRooms[p[3]=='hall'and'towerHall'or p[3]=='elevator'and'towerElevator'or'towerBattle']
 end
end
function R.doorPose(d,a)
 if not R.profile(d)or not a then return end
 local p=R.kind(d);if p[3]=='elevator'or a.y~=1 then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors
 return{height=cfg.towerChallenge.wallHeight*cfg.heightScale,base=0,top=0}
end
function R.plan(d)
 if not R.profile(d)then return end
 local p=R.kind(d);local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.towerChallenge
 local objects,mask={},{}
 local function clear(x,y,mid)mask[y*L.width+x+1]=mid or{mid=1,void=true}end
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o end
 for y=0,L.height-1 do for x=0,L.width-1 do if L:midAt(x,y)==1 then clear(x,y)end end end
 if p[3]=='elevator'then
  for x=0,4 do
   add('challengeLiftWall',x,0,1,3)
   for y=0,2 do clear(x,y)end
  end
 else
  for x=0,L.width-(p[3]=='battle'and 1 or 2)do
   add('wall',x,0,1,2,{wallHeight=c.wallHeight,wallBase=32,wallLast=32,clean=p[3]=='battle'and(x==0 or x==9)and{0x22f,0x237}or nil})
   clear(x,0);clear(x,1)
  end
  if p[3]=='hall'then
   for x=0,16 do if L:midAt(x,2)==0x203 or L:midAt(x,2)==0x204 then clear(x,2,0x200)end end
   for y=2,4 do for x=0,16 do if L:midAt(x,y)==0x26e or L:midAt(x,y)==0x25f then
    add('challengePlant',x,y,1,2);clear(x,y,0x229);clear(x,y+1,0x200)
   end end end
  else
   for _,x in ipairs({0,9})do
    add('challengeColumn',x,1,1,2);clear(x,2,0x23c)
    add('challengeColumn',x,7,1,2);clear(x,7,x==0 and 0x23b or 0x23a);clear(x,8,x==0 and 0x23b or 0x23a)
   end
  end
 end
 return objects,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.towerChallenge
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and inside(s,t)end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do v[2]=v[2]*cfg.heightScale;out[#out+1]=v end
 end
 if o.kind=='challengeLiftWall'then
  -- Source row 0 contains eight pixels of void; it is not a black wall cap.
  draw(8,48,function()return true end,function(s,t)return{x+s,c.liftWallHeight*(48-t)/40,z+48}end)
 elseif o.kind=='challengePlant'then
  draw(3,31,V.require('EmeraldFrontierReception').plantInside,function(s,t)return{x+s,c.plantHeight*(31-t)/28,z+31}end)
  if contacts then contacts[#contacts+1]={x+8,z+31,5,2,c.contactStrength}end
 elseif o.kind=='challengeColumn'then
  draw(8,32,V.require('EmeraldFrontierReception').columnInside,function(s,t)return{x+s,c.columnHeight*(32-t)/24,z+32}end)
  if contacts then contacts[#contacts+1]={x+8,z+32,6,2,c.contactStrength}end
 end
end
return R
