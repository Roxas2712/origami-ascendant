-- Native Mauville game-corner artwork; no collision/event/map changes.
local V=...
local M={}
function M.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.mauvilleCorner.enabled and(d.id or d.name)=='EM_MAUVILLE_CITY_GAME_CORNER'
  and d.pair=='building__mauville_game_corner'and L and L.width==22 and L.height==12
  and L:midAt(2,5)==0x224 and L:midAt(14,6)==0x222 then return c.homeRooms.mauvilleCorner end
end
function M.plan(d)
 local c=V.require('DioramaConfig').emeraldInteriors.mauvilleCorner;local L=d.midLayout;local objects,mask={},{}
 local function add(o,x,y,w,h)o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=o.kind~='wall';objects[#objects+1]=o;return o end
 for y=0,11 do for x=0,21 do local m=L:midAt(x,y);local k=y*22+x+1
  if m==1 or y<2 or x>=18 and y<3 then mask[k]={mid=1,void=true}
  elseif m~=0x206 and m~=0x207 then mask[k]=x==0 and 0x203 or 0x202 end
 end end
 for x=0,21 do
  local raised=x>=18
  local o=add({kind='wall',wallHeight=c.wallHeight,wallCap=raised and 18 or 0,wallLast=raised and 48 or 32,wallBase=raised and 48 or 32},x,0,1,raised and 3 or 2)
  if x<=1 or x>=5 and x<=7 then o.clean={0x212,0x21a}end
 end
 add({kind='mauCounter'},9,0,7,5)
 for x=0,1 do add({kind='mauVending'},x,1,1,2)end
 for x=5,7 do add({kind='mauPlant'},x,1,1,2)end
 add({kind='mauBin'},2,2,1,1);add({kind='mauBin'},21,4,1,1)
 for _,x in ipairs({18,20})do add({kind='mauBench'},x,3,2,1)end
 for _,x in ipairs({2,7})do add({kind='mauSlots'},x,5,2,5)end
 for _,x in ipairs({1,4,6,9})do for y=6,9 do add({kind='mauStool'},x,y,1,1)end end
 for _,x in ipairs({14,18})do add({kind='mauRoulette'},x,6,2,3)end
 return objects,mask
end
function M.actorHeight(d,x,z)
 if not M.profile(d)then return end
 local cx,cy=math.floor((x+8)/16),math.floor((z+15.99)/16)
 if(cx==1 or cx==4 or cx==6 or cx==9)and cy>=6 and cy<=9 then
  local c=V.require('DioramaConfig').emeraldInteriors;return c.mauvilleCorner.stoolHeight*c.heightScale
 end
end
function M.counterInside(s,t)
 if t<27 or t>=72 then return false end
 if t<45 then return s<16 or s>=96 end
 if t>=60 then local inset=math.max(1,t-64);return s>=inset and s<112-inset end
 return true
end
function M.rouletteInside(s,t)
 if t<1 or t>=45 then return false end
 local inset=(t==1 or t==44)and 1 or 0;return s>=inset and s<32-inset
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function M.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.mauvilleCorner;local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(s,t,a,b,d,e,shade)local m,u,v=source(s,t);G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+3,b-2,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,cfg.contactStrength}end end end
 -- Remove only the measured native background palette. White highlights on
 -- machines, pots and roulette wheels remain opaque. Plant outlines share
 -- the wall's dark ink, so the wall colours are listed without that ink.
 local bg={};for _,m in ipairs({0x202,0x204})do for v=0,15 do for u=0,15 do bg[rgb(B.pixel(ts,m,u,v))]=true end end end
 local function object(s,t)local m,u,v=source(s,t);return not bg[rgb(B.pixel(ts,m,u,v))]end
 if o.kind=='mauPlant'then
  for _,v in ipairs({0x63adce,0xefe6f7,0xbdcee6,0x31849c,0x7b7b8c})do bg[v]=true end
  draw(3,31,function(s,t)return{x+s,c.plantHeight*(31-t)/28,z+31}end,object);contact(3,13,31)
 elseif o.kind=='mauBin'then
  draw(1,16,function(s,t)return{x+s,c.binHeight*(16-t)/15,z+16}end,object);contact(4,12,16)
 elseif o.kind=='mauVending'then
  draw(2,10,function(s,t)return{x+s,c.vendingHeight,z+32-c.vendingDepth+(t-2)*c.vendingDepth/8}end,object)
  draw(10,32,function(s,t)return{x+s,c.vendingHeight*(32-t)/22,z+32}end,object)
  for _,s in ipairs({0,16})do patch(s==0 and 0 or 15,11,{x+s,c.vendingHeight,z+32-c.vendingDepth},{x+s,c.vendingHeight,z+32},{x+s,0,z+32},{x+s,0,z+32-c.vendingDepth},.95)end
  contact(0,16,32)
 elseif o.kind=='mauCounter'then
  draw(27,60,function(s,t)return{x+s,c.counterHeight,z+t}end,M.counterInside)
  draw(60,72,function(s,t)return{x+s,c.counterHeight*(72-t)/12,z+60}end,M.counterInside)
  for _,s in ipairs({0,16,96,112})do patch(8,62,{x+s,c.counterHeight,z+32},{x+s,c.counterHeight,z+45},{x+s,0,z+45},{x+s,0,z+32},.95)end
  patch(8,62,{x+16,c.counterHeight,z+45},{x+96,c.counterHeight,z+45},{x+96,0,z+45},{x+16,0,z+45},.95)
  contact(8,104,60)
 elseif o.kind=='mauSlots'then
  draw(0,76,function(s,t)
   local side=math.min(1,s/8,(32-s)/8);local endcap=math.min(1,(76-t)/4)
   return{x+s,c.machineHeight*side*endcap,z+t}
  end,object)
  contact(3,29,76)
 elseif o.kind=='mauStool'then
  draw(3,11,function(s,t)return{x+s,c.stoolHeight,z+16-c.stoolDepth+(t-3)*c.stoolDepth/8}end,object)
  draw(11,16,function(s,t)return{x+s,c.stoolHeight*(16-t)/5,z+16}end,object);contact(3,13,16)
 elseif o.kind=='mauBench'then
  draw(0,11,function(s,t)return{x+s,c.benchHeight,z+16-c.benchDepth+t*c.benchDepth/11}end,object)
  draw(11,16,function(s,t)return{x+s,c.benchHeight*(16-t)/5,z+16}end,object)
  for _,s in ipairs({2,30})do patch(2,12,{x+s,c.benchHeight,z+16-c.benchDepth},{x+s,c.benchHeight,z+16},{x+s,0,z+16},{x+s,0,z+16-c.benchDepth},.95)end
  contact(2,30,16)
 elseif o.kind=='mauRoulette'then
  draw(1,38,function(s,t)return{x+s,c.tableHeight,z+44-c.tableDepth+(t-1)*c.tableDepth/37}end,M.rouletteInside)
  draw(38,45,function(s,t)return{x+s,c.tableHeight*(45-t)/7,z+44}end,M.rouletteInside)
  for _,s in ipairs({1,31})do patch(2,40,{x+s,c.tableHeight,z+44-c.tableDepth},{x+s,c.tableHeight,z+44},{x+s,0,z+44},{x+s,0,z+44-c.tableDepth},.95)end
  contact(2,30,44)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return M
