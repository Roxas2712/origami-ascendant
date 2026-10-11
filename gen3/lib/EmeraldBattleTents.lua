-- Measured Emerald battle-tent art. Native challenges, events and cells stay owned by the engine.
local V=...
local T={}
local towns={EM_SLATEPORT_CITY=true,EM_FALLARBOR_TOWN=true,EM_VERDANTURF_TOWN=true}
function T.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 local town,room=(d.id or d.name or''):match('^(EM_.+)_BATTLE_TENT_(.+)$')
 if not(c.enabled and c.battleTents.enabled and towns[town]and L)then return end
 local garden=town=='EM_VERDANTURF_TOWN'and room=='BATTLE_ROOM'
 local p=c.homeRooms[room=='LOBBY'and'tentLobby'or room=='CORRIDOR'and'tentCorridor'or room=='BATTLE_ROOM'and(garden and'tentGarden'or'tentBattle')or'']
 if not p or d.pair~=(garden and'general__battle_tent'or'building__battle_tent')or L.width~=p.width or L.height~=p.height then return end
 if L:midAt(p.check[1],p.check[2])~=p.check[3]then return end
 return p
end
function T.plan(d,p)
 local c=V.require('DioramaConfig').emeraldInteriors.battleTents;local L=d.midLayout;local objects,mask={},{}
 local function add(o,x,y,w,h)o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y);local k=y*L.width+x+1
  if m==p.void or y<2 then mask[k]={mid=p.void,void=true}
  elseif p.lobby and y<7 then mask[k]=(x+y)%2==0 and 0x211 or 0x210 end
 end end
 local width=p.garden and 13 or p.lobby and 13 or p.corridor and 5 or 10
 for x=0,width-1 do
  local wall=add({kind='wall',wallHeight=c.wallHeight,wallBase=32,wallLast=32},x,0,1,2)
  if p.lobby and(x==2 or x==3 or x==9 or x==10)then wall.clean={0x205,0x20d}end
 end
 if p.lobby then
  add({kind='tentCounter'},2,1,9,5)
  add({kind='tentSign'},3,5,3,2)
  add({kind='tentPC'},11,3,1,3)
  add({kind='tentCurtain'},0,2,1,3)
  add({kind='tentCurtain',right=true},12,2,1,3)
 end
 if p.garden then
  -- The outdoor ring and its complete blue border remain native ground art.
  for y=2,8 do for x=0,12 do local m=L:midAt(x,y)
   if m==0xd or m==4 then add({kind='tentPlant'},x,y,1,1);mask[y*L.width+x+1]=1 end
  end end
 end
 return objects,mask
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
-- Measured worktop contour. Painted vertical trim at the back-arm ends is
-- excluded from the horizontal top and supplied by the perimeter extrusion.
local counterRows={
 {14,15,1,31,113,143},
 {15,25,0,32,112,144},
 {25,26,0,31,113,144},
 {26,27,0,32,112,144},
 {27,56,0,16,128,144},
 {56,58,0,17,127,144},
 {58,59,1,18,126,143},
 {59,60,1,19,125,143},
 {60,61,1,22,122,143},
 {61,62,1,62,82,143},
 {62,63,1,63,81,143},
 {63,65,2,64,80,142},
 {65,67,3,64,80,141},
 {67,68,4,64,80,140},
 {68,69,5,64,80,139},
 {69,70,6,64,80,138},
 {70,71,7,64,80,137},
 {71,72,8,64,80,136},
 {72,73,10,64,80,134},
 {73,74,12,63,81,132},
 {74,75,15,64,80,129},
}
function T.counterInside(s,t)
 for _,r in ipairs(counterRows)do if t>=r[1]and t<r[2]then return s>=r[3]and s<r[4]or s>=r[5]and s<r[6]end end
 return false
end
function T.signInside(s,t)
 if t<0 or t>=24 then return false end
 if t==0 then return s>=23 and s<31 end
 if t<=2 then return s>=22 and s<32 end
 if t<18 then return s>=10 and s<38 end
 if t==18 then return s>=11 and s<37 end
 if t<21 then return s>=19 and s<29 end
 return s>=20 and s<28
end
function T.pcInside(s,t)
 if t<9 or t>=40 then return false end
 local inset=t==9 and 3 or t==10 and 2 or t==11 and 1 or t==39 and 2 or t==38 and 1 or 0
 return s>=inset and s<16-inset
end
function T.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battleTents;local G=V.require('WorldGeometry');local BM=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(src,inside,project)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,inside,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(s,t,a,b,d,e,shade)
  local m,u,v=source(s,t);G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)
 end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,cfg.contactStrength}end end end
 if o.kind=='tentCounter'then
  -- Mirror only the patch occluded by the freestanding information sign.
  -- The U-shaped counter is exactly symmetric; the sign gets its own card.
  local function topSource(s,t)if s>=24 and s<56 and t>=64 then s=143-s end;return source(s,t)end
  local inside=T.counterInside
  draw(topSource,inside,function(s,t)return{x+s,c.counterHeight,z+t}end)
  -- Extrude every exposed contour edge, including the open middle and curves.
  local uv=G.uv(ts,L:midAt(o.x+5,o.y+4),8,12,9,16,.5)
  for t=14,75 do for s=0,143 do if inside(s,t)then
   local h=c.counterHeight
   if not inside(s-1,t)then G.quad(out,{x+s,h,z+t},{x+s,h,z+t+1},{x+s,0,z+t+1},{x+s,0,z+t},uv,.94)end
   if not inside(s+1,t)then G.quad(out,{x+s+1,h,z+t+1},{x+s+1,h,z+t},{x+s+1,0,z+t},{x+s+1,0,z+t+1},uv,.94)end
   if not inside(s,t-1)then G.quad(out,{x+s+1,h,z+t},{x+s,h,z+t},{x+s,0,z+t},{x+s+1,0,z+t},uv,.98)end
   if not inside(s,t+1)then G.quad(out,{x+s,h,z+t+1},{x+s+1,h,z+t+1},{x+s+1,0,z+t+1},{x+s,0,z+t+1},uv,1)end
  end end end
  contact(6,64,76);contact(80,138,76)
 elseif o.kind=='tentSign'then
  draw(nil,T.signInside,function(s,t)return{x+s,c.signHeight*(24-t)/24,z+24}end);contact(20,28,24)
 elseif o.kind=='tentPC'then
  draw(nil,function(s,t)return t<16 and T.pcInside(s,t)end,function(s,t)return{x+s,c.terminalHeight,z+40-c.terminalDepth+(t-9)*c.terminalDepth/7}end)
  draw(nil,function(s,t)return t>=16 and T.pcInside(s,t)end,function(s,t)return{x+s,c.terminalHeight*(40-t)/24,z+40}end)
  for _,s in ipairs({0,16})do patch(1,18,{x+s,c.terminalHeight,z+40-c.terminalDepth},{x+s,c.terminalHeight,z+40},{x+s,0,z+40},{x+s,0,z+40-c.terminalDepth},.96)end
  contact(1,15,40)
 elseif o.kind=='tentCurtain'then
  -- Side fabric bends along the room edge rather than becoming a floor stripe.
  draw(nil,function(s,t)
   local m,u,v=source(s,t);local k=rgb(BM.pixel(ts,m,u,v))
   return t<48 and(k==0xef9473 or k==0xde6b63 or k==0xce4252)
  end,function(s,t)
   return{x+(o.right and 16 or 0),c.wallHeight*(o.right and s or 16-s)/16,z+t}
  end)
 elseif o.kind=='tentPlant'then
  local empty={}
  for t=0,15 do for s=0,15 do empty[rgb(BM.pixel(ts,1,s,t))]=true end end
  draw(nil,function(s,t)local m,u,v=source(s,t);return not empty[rgb(BM.pixel(ts,m,u,v))]end,function(s,t)return{x+s,c.plantHeight*(16-t)/16,z+16}end)
  contact(3,13,16)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return T
