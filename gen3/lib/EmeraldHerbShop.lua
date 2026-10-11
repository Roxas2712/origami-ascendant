-- Native Lavaridge herb shop: preserve display whites and yellow planter faces.
local V=...
local H={}
function H.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.herbShop.enabled and(d.id or d.name)=='EM_LAVARIDGE_TOWN_HERB_SHOP'and d.pair=='building__shop'
  and L and L.width==12 and L.height==8 and L:midAt(5,1)==0x29d and L:midAt(10,3)==0x312 then return c.homeRooms.herbShop end
end
function H.plan(d)
 local c=V.require('DioramaConfig').emeraldInteriors.herbShop;local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o;return o end
 for y=0,7 do for x=0,11 do
  local m=L:midAt(x,y)
  if m==1 or y<2 then mask[y*12+x+1]={mid=1,void=true}
  elseif m~=0x216 and m~=0x217 then mask[y*12+x+1]=0x268 end
 end end
 for x=0,10 do
  local o=add('wall',x,0,1,2,{wallHeight=c.wallHeight,wallLast=32,wallBase=32})
  if x==5 then o.clean={0x288,0x290};o.keepBefore=24 end
 end
 add('herbCounter',0,2,5,2,{noContact=true})
 add('herbRegister',5,1,1,3,{noContact=true})
 add('herbShelf',10,3,1,3,{noContact=true})
 for _,x in ipairs({0,9})do add('herbPlanter',x,6,2,2,{noContact=true})end
 return objects,mask
end
function H.planterInside(s,t)
 if t<10 or t>=32 then return false end
 if t==10 then return s>=4 and s<28 end
 if t<13 then return s>=1 and s<31 end
 return true
end
function H.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.herbShop
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside)
  local v=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,p in ipairs(v)do p[2]=p[2]*cfg.heightScale;out[#out+1]=p end
 end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,cfg.contactStrength}end end end
 if o.kind=='herbCounter'then
  draw(13,23,function(s,t)return{x+s,c.counterHeight,z+22+(t-13)}end)
  draw(23,32,function(s,t)return{x+s,c.counterHeight*(32-t)/9,z+32}end);contact(0,80,32)
 elseif o.kind=='herbRegister'then
  -- Complete case, including the white side and base. No white color key.
  draw(8,48,function(s,t)return{x+s,c.registerHeight*(48-t)/40,z+48}end);contact(0,16,48)
 elseif o.kind=='herbShelf'then
  draw(0,48,function(s,t)return{x+s,c.shelfHeight*(48-t)/48,z+48}end,function(s,t)
   if t==0 then return s>=4 end
   if t==1 then return s>=2 end
   return true
  end);contact(0,16,48)
 elseif o.kind=='herbPlanter'then
  draw(10,32,function(s,t)return{x+s,c.planterHeight*(32-t)/22,z+32}end,H.planterInside);contact(0,32,32)
 end
end
return H
