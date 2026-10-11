-- Safari's L-shaped lobby: measured native silhouettes and open counter volumes.
local V=...
local S={}
function S.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.safariEntrance.enabled and(d.id or d.name)=='EM_ROUTE121_SAFARI_ZONE_ENTRANCE'
 and d.pair=='building__shop'and L and L.width==18 and L.height==14
 and L:midAt(6,2)==0x2a8 and L:midAt(16,8)==0x2d0 then return c.homeRooms.safariEntrance end
end
function S.plan(d)
 local c=V.require('DioramaConfig').emeraldInteriors.safariEntrance;local objects,mask={},{}
 local function add(kind,x,y,w,h)
  local o={kind=kind,x=x,y=y,w=w*16,h=h*16,noContact=true};objects[#objects+1]=o;return o
 end
 local function floor(x,y,w,h,mid)for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*18+xx+1]=mid or 0x268 end end end
 for y=0,13 do for x=0,17 do if y<2 or y>=6 and x<12 then mask[y*18+x+1]={mid=1,void=true}end end end
 for x=0,17 do
  local o=add('wall',x,0,1,2);o.wallHeight=c.wallHeight;o.wallLast=32;o.wallBase=32
  if x==6 or x==11 or x==12 then o.clean={0x288,0x290}end
 end
 add('transitCounter',6,1,6,3);floor(6,2,6,1,0x270);floor(6,3,6,1)
 for _,x in ipairs({7,9})do add('transitPlanter',x,4,2,2);floor(x,4,2,2)end
 for _,p in ipairs({{0,4},{12,7},{12,12},{17,12}})do add('safariPlant',p[1],p[2],1,2);floor(p[1],p[2],1,2)end
 add('safariTerminal',12,0,1,3);floor(12,2,1,1,0x270)
 for _,p in ipairs({{14,3},{17,3},{17,4}})do add('safariChair',p[1],p[2],1,1);floor(p[1],p[2],1,1)end
 add('safariSideCounter',16,6,2,6);floor(16,6,2,6)
 -- Native shadow tiles below the old counter are replaced by the original
 -- floor, then small alpha-masked contacts are drawn at the new base only.
 floor(16,12,1,1)
 return objects,mask
end
function S.sideTop(s,t)return t>=8 and t<86 and(s<16 or t<22 or t>=72)end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function S.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.safariEntrance
 local BM=V.require('BuildingMesh');local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local bg={}
 for _,m in ipairs({0x268,0x270,0x278,0x280})do for v=0,15 do for u=0,15 do bg[rgb(BM.pixel(ts,m,u,v))]=true end end end
 local function cut(s,t)return not bg[rgb(BM.pixel(ts,source(s,t)))]end
 local function contact(xx,zz,rx,rz)if contacts then contacts[#contacts+1]={x+xx,z+zz,rx,rz,cfg.contactStrength}end end
 if o.kind=='safariPlant'then
  draw(0,32,function(s,t)return{x+s,(32-t)*cfg.transit.plantHeight/29,z+31}end,cut);contact(8,31,5,2)
 elseif o.kind=='safariTerminal'then
  -- PC case is opaque white; use its measured outline, not white color-keying.
  draw(8,40,function(s,t)return{x+s,(40-t)*c.terminalHeight/32,z+43}end,function(s,t)
   local inset=t==8 and 3 or(t==9 or t==39)and 2 or(t==10 or t==38)and 1 or 0
   return s>=inset and s<16-inset
  end)
  contact(8,43,5,2)
 elseif o.kind=='safariChair'then
  -- These two native chair orientations have a one-pixel side backrest.
  -- Preserve the complete silhouette as an upright cutout; splitting its
  -- tiny backrest from the seat introduced detached fragments in perspective.
  draw(0,15,function(s,t)return{x+s,c.chairHeight*(15-t)/15,z+14}end,cut);contact(8,14,5,2)
 elseif o.kind=='safariSideCounter'then
  local h=c.counterHeight
  draw(8,86,function(s,t)return{x+s,h,z+t+6}end,S.sideTop)
  draw(86,96,function(s,t)return{x+s,h*(96-t)/10,z+92}end,function(s,t)return t<95 or s%16>0 and s%16<15 end)
  draw(22,32,function(s,t)return{x+s,h*(32-t)/10,z+28}end,function(s)return s>=16 end)
  local function panel(xx,a,b)
   G.quad(out,{x+xx,h,z+a},{x+xx,h,z+b},{x+xx,0,z+b},{x+xx,0,z+a},G.uv(ts,0x2d1,2,9,3,14,.5),.96)
  end
  panel(0,14,92);panel(16,28,78);panel(32,14,28);panel(32,78,92)
  for zz=18,90,8 do contact(1,zz,2,5)end
  for xx=4,28,8 do contact(xx,92,5,2)end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return S
