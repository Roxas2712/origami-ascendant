-- The league reception reuses the measured Center objects at their native
-- positions. Its wider lobby has two independent counters and two tables.
local V=...
local R={}
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout;local id=d.id or d.name
 if not(c.enabled and c.leagueReception.enabled and L and d.pair=='building__pokemon_center')then return end
 if id=='EM_EVER_GRANDE_CITY_POKEMON_LEAGUE_1F'and L.width==20 and L.height==12 and L:midAt(9,6)==0x286 then return c.homeRooms.leagueReception end
 if id=='EM_EVER_GRANDE_CITY_POKEMON_LEAGUE_2F'and L.width==14 and L.height==10 and L:midAt(3,2)==0x2a6 then return c.homeRooms.leagueReceptionLink end
end
function R.plan(d)
 local p=R.profile(d);if not p then return end
 if p.family=='link'then return V.require('EmeraldPublicSurfaces').plan(d,p)end
 local L=d.midLayout;local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.leagueReception
 local objects,mask={},{}
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=donor or p.floor end
  end end;return o
 end
 local function fold(x,y,w,h,cap,split,last,height,depth,front,bg)
  return add({kind='fold',cap=cap,split=split,last=last,height=height,depth=depth,front=front or last,background=bg},x,y,w,h)
 end
 local function card(x,y,w,h,cap,last,front,height,bg)
  return add({kind='card',cap=cap,last=last,front=front,height=height,background=bg or{{mid=p.floor}}},x,y,w,h)
 end
 local function clear(x,w,keep)for _,o in ipairs(objects)do if o.kind=='wall'and o.x>=x and o.x<x+w then o.clean={0x20b,0x213};o.keepBefore=keep end end end
 for y=0,11 do mask[y*20+20]={mid=0x201,void=true}end
 for x=1,17 do add({kind='wall',wallHeight=c.wallHeight},x,0,1,2,{mid=0x201,void=true})end
 for _,x in ipairs({0,18})do add({kind='corner',right=x==18,floor=p.floor,wallHeight=c.wallHeight,diagonal=16},x,0,1,3,{mid=0x201,void=true})end
 for _,r in ipairs({{0,6},{14,5}})do fold(r[1],2,r[2],3,12,22,32,c.counterHeight,14,32).removeBalls=true end
 for _,x in ipairs({5,14})do
  fold(x,1,1,2,8,24,26,c.counterHeight,26,44).repeatTop=10
  local ball=card(x,2,1,2,8,21,25,13,{{mid=0x202},{mid=0x221}});ball.base=c.counterHeight;ball.trim=2;ball.opaque=true
  clear(x,1)
 end
 card(1,1,2,2,1,29,34,c.healerHeight,{}).opaque=true;clear(1,2)
 card(4,1,1,2,8,28,33,23,{}).opaque=true;clear(4,1,24)
 card(6,0,1,3,8,40,48,c.pcHeight,{}).opaque=true;clear(6,1)
 add({kind='receptionMonitor',front=32+cfg.wallClearance,noContact=true},3,0,2,2);clear(3,2)
 for _,a in ipairs({{3,10},{15,8}})do add({kind='receptionTable',height=c.tableHeight,noContact=true},a[1],a[2],2,2)end
 for _,a in ipairs({{1,10},{2,10},{17,6},{18,6}})do
  local o=card(a[1],a[2],1,2,0,31,31,c.plantHeight,{{mid=0x240},{mid=0x202}});o.positionMask=true
 end
 for y=3,11 do for x=0,18 do local m=L:midAt(x,y)
  if m==0x226 or m==0x234 then fold(x,y,1,1,0,10,15,c.stoolHeight,12,15,{{mid=p.floor},{mid=0x202}})end
 end end
 add({kind='escalator',floor=p.floor},0,6,2,3)
 return objects,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local B=V.require('BuildingMesh')
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 if o.kind=='receptionMonitor'then
  -- Native case and reflection share wall palette entries. Preserve the solid
  -- silhouette by measured rows instead of deleting matching interior colors.
  local vv=V.require('PaperSprite').build(ts,32,32,source,function(s,t)
   if t<8 or t>=23 then return false end
   local inset=(t==8 or t==22)and 3 or(t==9 or t==21)and 2 or 1
   return s>=inset and s<24-inset
  end,0,32,1,nil,function(s,t)return{x+s,32-t,z+o.front}end,.5)
  for _,v in ipairs(vv)do v[2]=v[2]*cfg.heightScale;out[#out+1]=v end
  return
 end
 local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local floor={};for yy=0,15 do for xx=0,15 do floor[key(B.pixel(ts,0x240,xx,yy))]=true end end
 -- The oval is opaque. Derive its outer span from each native row, retain
 -- the one-pixel pale rim and fill the interior rather than erasing whites.
 local spans={}
 for t=0,30 do local a,b=32,-1
  for s=0,31 do local m,u,v=source(s,t);if not floor[key(B.pixel(ts,m,u,v))]then a=math.min(a,s);b=math.max(b,s)end end
  if b>=a then spans[t]={math.max(0,a-1),math.min(32,b+2)}end
 end
 local vv=V.require('PaperSprite').build(ts,32,32,source,function(s,t)local q=spans[t];return q and s>=q[1]and s<q[2]end,0,32,1,nil,function(s,t)
  if t<25 then return{x+s,o.height,z+7+t}end
  return{x+s,o.height*(31-t)/6,z+32}
 end,.5)
 for _,v in ipairs(vv)do v[2]=v[2]*cfg.heightScale;out[#out+1]=v end
 if contacts then contacts[#contacts+1]={x+16,z+31,12,2,cfg.leagueReception.contactStrength}end
end
return R
