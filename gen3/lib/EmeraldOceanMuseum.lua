-- Slateport's native museum exhibits; no map, event or warp edits.
local V=...
local M={}
local ids={EM_SLATEPORT_CITY_OCEANIC_MUSEUM_1F=0x25d,EM_SLATEPORT_CITY_OCEANIC_MUSEUM_2F=0x261}
function M.profile(d)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout;local id=d.id or d.name
 if cfg.enabled and cfg.oceanMuseum.enabled and ids[id]and d.pair=='building__oceanic_museum'
  and L and L.width==20 and L.height==10 and L:midAt(5,0)==ids[id]then return cfg.homeRooms[id:match('2F$')and'oceanUpper'or'oceanGround']end
end
function M.plan(d,p)
 local cfg=V.require('DioramaConfig').emeraldInteriors.oceanMuseum;local L=d.midLayout
 local upper=(d.id or d.name):match('2F$');local objects,mask={},{}
 for y=0,9 do for x=0,19 do local m=L:midAt(x,y)
  if m~=1 and m~=0x20a and m~=0x20b then mask[y*20+x+1]=y<2 and{mid=1,void=true}or((y==2 or x==0)and 0x202 or 0x201)end
 end end
 local function add(o,x,y,w,h)o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o;return o end
 local blocked={[5]=true,[6]=true,[7]=true}
 if upper then blocked[10]=true end
 for x=0,19 do if not blocked[x]then
  local o=add({kind='wall',wallHeight=cfg.wallHeight,wallLast=32,wallBase=32},x,0,1,2)
  if not upper and(x==9 or x==10 or x==12 or x==13)then o.clean={0x204,0x20c}end
 end end
 add({kind='oceanStairs',down=upper,front=32,noContact=true},5,0,3,2)
 if upper then
  -- Wall-mounted vitrines include the frame below the second metatile row.
  for _,x in ipairs({8,15,18})do
   for i=#objects,1,-1 do local o=objects[i];if o.kind=='wall'and(o.x==x or o.x==x+1)then table.remove(objects,i)end end
   add({kind='oceanWallCase',cap=0,last=40,front=32,height=cfg.wallHeight,noContact=true},x,0,2,3)
  end
  add({kind='oceanPartition',front=64,noContact=true},10,0,1,4)
  for _,y in ipairs({2,5})do add({kind='oceanTable',ship=y==5,front=44,noContact=true},2,y,4,3)end
  for _,x in ipairs({12,15})do add({kind='oceanTerminal',front=31,height=cfg.terminalHeight},x,3,2,2)end
  add({kind='oceanShipPlinth',front=31,noContact=true},13,6,2,2)
  for _,y in ipairs({3,6})do add({kind='oceanCylinder',cap=0,last=32,front=31,height=cfg.cylinderHeight},18,y,1,2)end
 else
  for _,x in ipairs({9,12})do add({kind='oceanTallCase',cap=0,last=40,front=40,height=cfg.tallCaseHeight},x,0,2,3)end
  for _,y in ipairs({3,6})do add({kind='oceanCylinder',cap=0,last=32,front=31,height=cfg.cylinderHeight},2,y,1,2)end
  for _,pt in ipairs({{15,3},{18,3},{18,6}})do add({kind='oceanSmallCase',cap=5,last=32,front=31,height=cfg.smallCaseHeight},pt[1],pt[2],1,2)end
  for _,x in ipairs({5,11})do add({kind='oceanCounter',front=58,noContact=true},x,5,4,4)end
 end
 return objects,mask
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
-- Flood only connected exterior floor/shadow pixels. Closed white exhibits
-- and native glass reflections must not be erased by a global color key.
local function mask(L,ts,o)
 local pixel=V.require('BuildingMesh').pixel;local bg={}
 for _,m in ipairs({0x201,0x202,0x203,0x243,0x24b})do for y=0,15 do for x=0,15 do bg[rgb(pixel(ts,m,x,y))]=true end end end
 local candidate,empty,q={},{},{}
 for y=0,o.h-1 do for x=0,o.w-1 do local m=L:midAt(o.x+math.floor(x/16),o.y+math.floor(y/16));candidate[y*o.w+x]=bg[rgb(pixel(ts,m,x%16,y%16))]end end
 local function seed(x,y)local k=y*o.w+x;if candidate[k]and not empty[k]then empty[k]=true;q[#q+1]=k end end
 for x=0,o.w-1 do seed(x,0);seed(x,o.h-1)end;for y=0,o.h-1 do seed(0,y);seed(o.w-1,y)end
 local n=1;while q[n]do local k=q[n];n=n+1;local x,y=k%o.w,math.floor(k/o.w)
  if x>0 then seed(x-1,y)end;if x<o.w-1 then seed(x+1,y)end;if y>0 then seed(x,y-1)end;if y<o.h-1 then seed(x,y+1)end
 end
 return function(x,y)return x>=0 and x<o.w and y>=0 and y<o.h and not empty[y*o.w+x]end
end
function M.counterTop(x,y)
 if y<14 or y>=58 or x<0 or x>=64 then return false end
 local inset=({[14]=6,[15]=4,[16]=3,[17]=2,[18]=1,[19]=1,[56]=1,[57]=1})[y]or 0
 return x>=inset and x<64-inset and(y<26 or x<16 or x>=48)
end
function M.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.oceanMuseum;local G=V.require('WorldGeometry')
 local start=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local inside=mask(L,ts,o)
 local function draw(a,b,project,clip,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and inside(s,t)and(not clip or clip(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function quad(a,b,d,e,m,u,v,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,front)
  if contacts then for xx=a+4,b-2,8 do contacts[#contacts+1]={x+xx,z+front,6,2,cfg.contactStrength}end end
 end
 if o.kind=='oceanStairs'then
  -- Complete native arch, including the dark opening, joins the rear wall.
  local function raw(s,t)return L:midAt(o.x+math.floor(s/16),math.floor(t/16)),s%16,t%16 end
  local vv=V.require('PaperSprite').build(ts,48,32,raw,function()return true end,0,32,1,nil,function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
  if not o.down then
   for j=0,2 do local a=19+j*4;local high=(3-j)*c.stepHeight
    draw(a,a+2,function(s,t)return{x+s,high,z+32+(j+(t-a)/2)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
    draw(a+2,a+4,function(s,t)return{x+s,high-(t-a-2)*c.stepHeight/2,z+32+(j+1)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
   end
  end
 elseif o.kind=='oceanCounter'then
  draw(14,58,function(s,t)return{x+s,c.counterHeight,z+t}end,M.counterTop)
  draw(26,32,function(s,t)return{x+s,c.counterHeight*(32-t)/6,z+26}end,function(s)return s>=16 and s<48 end)
  draw(58,64,function(s,t)return{x+s,c.counterHeight*(64-t)/6,z+58}end,function(s)return s<16 or s>=48 end)
  -- Lit gold side faces follow the U contour, including its open centre.
  for t=14,57 do for s=0,63 do if M.counterTop(s,t)then
   for _,dx in ipairs({-1,1})do if not M.counterTop(s+dx,t)then
    local edge=s+(dx==1 and 1 or 0);quad({x+edge,c.counterHeight,z+t},{x+edge,c.counterHeight,z+t+1},{x+edge,0,z+t+1},{x+edge,0,z+t},0x260,6,13,.92)
   end end
  end end end
  contact(0,16,58);contact(48,64,58);contact(16,48,26)
 elseif o.kind=='oceanTable'then
  local function device(s,t)
   return t>=16 and t<32 and(o.ship and s>=16 and s<48 or not o.ship and s>=8 and s<46)
  end
  draw(14,44,function(s,t)return{x+s,c.tableHeight,z+14+(t-14)*c.tableDepth/30}end,nil,function(s,t)
   if device(s,t)then return source(48,32)end;return source(s,t)
  end)
  draw(44,48,function(s,t)return{x+s,c.tableHeight*(48-t)/4,z+14+c.tableDepth}end)
  local BM=V.require('BuildingMesh');local back=rgb(BM.pixel(ts,source(48,32)))
  draw(16,32,function(s,t)return{x+s,c.tableHeight+(32-t)*c.modelScale,z+14+c.tableDepth*.58}end,function(s,t)
   return device(s,t)and rgb(BM.pixel(ts,source(s,t)))~=back
  end)
  contact(2,62,14+c.tableDepth)
 elseif o.kind=='oceanShipPlinth'then
  draw(21,26,function(s,t)return{x+s,c.plinthHeight,z+17+(t-21)*9/5}end)
  draw(26,32,function(s,t)return{x+s,c.plinthHeight*(32-t)/6,z+26}end)
  draw(9,21,function(s,t)return{x+s,c.plinthHeight+(21-t)*c.modelScale,z+21}end)
  contact(1,31,26)
 elseif o.kind=='oceanPartition'then
  local a,b=x+2,x+14;local rear,front=z+32,z+64;local h=c.wallHeight
  quad({a,h,rear},{b,h,rear},{b,h,front},{a,h,front},0x225,6,6)
  quad({a,h,rear},{a,h,front},{a,0,front},{a,0,rear},0x22d,7,12,.92)
  quad({b,h,front},{b,h,rear},{b,0,rear},{b,0,front},0x22d,7,12,.92)
  draw(32,64,function(s,t)return{x+s,h*(64-t)/32,front}end,function(s)return s>=2 and s<14 end)
  -- Close rear joins to the two adjacent wall panels.
  for _,range in ipairs({{0,2},{14,16}})do
   for t=0,31 do local m=t<16 and 0x204 or 0x20c;local v=t%16
    G.quad(out,{x+range[1],h*(32-t)/32,rear},{x+range[2],h*(32-t)/32,rear},{x+range[2],h*(31-t)/32,rear},{x+range[1],h*(31-t)/32,rear},G.uv(ts,m,range[1],v,range[2],v+1,.5),1)
   end
  end
  contact(0,16,64)
 else
  local cap,last=o.cap or 8,o.last or o.h
  draw(cap,last,function(s,t)return{x+s,(last-t)*o.height/(last-cap),z+o.front}end,function(s)return o.kind~='oceanTallCase'or s<24 end)
 end
 for i=start,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return M
