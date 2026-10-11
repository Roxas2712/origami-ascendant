-- Lilycove gallery: original paintings, freestanding panels and sculptures.
local V=...
local A={}
local ids={EM_LILYCOVE_CITY_LILYCOVE_MUSEUM_1F=0x20b,EM_LILYCOVE_CITY_LILYCOVE_MUSEUM_2F=0x279}
function A.profile(d)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local id=d.id or d.name;local L=d.midLayout
 if cfg.enabled and cfg.artMuseum.enabled and ids[id]and d.pair=='building__lilycove_museum'and L
  and L.width==22 and L.height==14 and L:midAt(0,0)==ids[id]then return cfg.homeRooms[id:match('2F$')and'artUpper'or'artGround']end
end
function A.plan(d,p)
 local c=V.require('DioramaConfig').emeraldInteriors.artMuseum;local L=d.midLayout
 local upper=(d.id or d.name):match('2F$');local objects,mask={},{}
 local function add(o,x,y,w,h)o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o;return o end
 for y=0,13 do for x=0,21 do local m=L:midAt(x,y)
  if m==0x201 then mask[y*22+x+1]={mid=m,void=true}
  elseif m~=0x216 and m~=0x217 then
   mask[y*22+x+1]=y<2 and{mid=0x201,void=true}or upper and((x+y)%2==0 and 0x269 or 0x268)or(x==0 or y==2)and 0x203 or 0x202
  end
 end end
 if upper then
  for x=0,21 do if x<12 or x>14 then
   if x==3 or x==18 then add({kind='artRearCorner',right=x==18,noContact=true},x,0,1,3)
   else local back=x<3 or x>18
    add({kind='wall',wallHeight=c.wallHeight,wallCap=back and 16 or 0,wallLast=back and 48 or 32,wallBase=back and 48 or 32},x,0,1,3)
    if back then mask[2*22+x+1]={mid=0x201,void=true}end
   end
  end end
  add({kind='artStairs',down=true,noContact=true},12,0,3,2)
  for _,x in ipairs({11,15})do
   for _,o in ipairs(objects)do if o.kind=='wall'and o.x==x then o.clean={0x281,0x289}end end
   add({kind='artStatue',cap=0,last=32,height=c.smallStatueHeight,front=32,upper=true},x,1,1,2)
  end
  for _,q in ipairs({{1,4},{9,4},{17,4},{5,8},{13,8}})do
   add({kind='artPanel',front=56,noContact=true},q[1],q[2],4,4)
  end
 else
  for x=0,20 do if x~=13 and(x<15 or x>17)then add({kind='wall',wallHeight=c.wallHeight,wallLast=32,wallBase=32},x,0,1,2)end end
  add({kind='artStairs',noContact=true},15,0,3,2)
  add({kind='artDivider',front=80,noContact=true},13,0,1,5)
  add({kind='artPartition',front=32,noContact=true},0,5,9,2)
  add({kind='artDivider',front=64,noContact=true},9,5,1,4)
  add({kind='artRingCounter',front=74,noContact=true},1,9,6,5)
  add({kind='artSculptureTable',front=58,noContact=true},15,6,5,4)
  add({kind='artStatue',cap=0,last=32,height=c.statueHeight,front=32},15,11,1,2)
  add({kind='artStatue',cap=0,last=16,height=c.bustHeight,front=16},18,11,1,1)
 end
 return objects,mask
end
function A.ringTop(s,t)
 if s<0 or s>=96 or t<14 or t>=74 then return false end
 local inset=({[14]=6,[15]=4,[16]=3,[17]=2,[18]=1,[19]=1,[70]=1,[71]=1,[72]=2,[73]=2})[t]or 0
 return s>=inset and s<96-inset and(t<24 or t>=62 or s<16 or s>=80)
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local function outline(L,ts,o)
 local pixel=V.require('BuildingMesh').pixel;local bg={}
 for _,m in ipairs(o.upper and{0x268,0x269,0x289,0x281}or{0x202,0x203,0x23f,0x23e,0x24f,0x246})do for y=0,15 do for x=0,15 do bg[rgb(pixel(ts,m,x,y))]=true end end end
 local clear,empty,q={},{},{}
 for t=0,o.h-1 do for s=0,o.w-1 do clear[t*o.w+s]=bg[rgb(pixel(ts,L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16))]end end
 local function seed(s,t)local k=t*o.w+s;if clear[k]and not empty[k]then empty[k]=true;q[#q+1]=k end end
 for s=0,o.w-1 do seed(s,0);seed(s,o.h-1)end;for t=0,o.h-1 do seed(0,t);seed(o.w-1,t)end
 local n=1;while q[n]do local k=q[n];n=n+1;local s,t=k%o.w,math.floor(k/o.w)
  if s>0 then seed(s-1,t)end;if s<o.w-1 then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t<o.h-1 then seed(s,t+1)end
 end
 return function(s,t)return not empty[t*o.w+s]end
end
function A.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.artMuseum;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(m,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-2,8 do contacts[#contacts+1]={x+xx,z+zz,6,2,cfg.contactStrength}end end end
 if o.kind=='artStairs'then
  draw(0,32,function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
  if not o.down then for j=0,2 do local a=20+j*4;local h=(3-j)*c.stepHeight
   draw(a,a+2,function(s,t)return{x+s,h,z+32+(j+(t-a)/2)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
   draw(a+2,a+4,function(s,t)return{x+s,h-(t-a-2)*c.stepHeight/2,z+32+(j+1)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
  end end
 elseif o.kind=='artRearCorner'then
  -- The back wall steps forward one tile at each wing, with a closed return.
  local xx=x+(o.right and 0 or 16);local back,front=z+32,z+48
  for t=0,31 do local m=t<16 and 0x281 or 0x289
   G.quad(out,{xx,c.wallHeight-t,back},{xx,c.wallHeight-t,front},{xx,c.wallHeight-t-1,front},{xx,c.wallHeight-t-1,back},G.uv(ts,m,0,t%16,16,t%16+1,.5),.95)
  end
  draw(16,48,function(s,t)return{x+s,c.wallHeight*(48-t)/32,front}end,nil,function(s,t)return t<32 and 0x281 or 0x289,s,t%16 end)
 elseif o.kind=='artPartition'then
  draw(0,32,function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
  patch(0x209,8,15,{x,c.wallHeight,z+32-c.partitionDepth},{x+o.w,c.wallHeight,z+32-c.partitionDepth},{x+o.w,c.wallHeight,z+32},{x,c.wallHeight,z+32})
  contact(0,o.w,32)
 elseif o.kind=='artDivider'then
  local a,b=x,x+16;local back=z+(o.y==0 and 32 or -16);local front=z+o.front;local h=c.wallHeight
  patch(0x211,6,6,{a,h,back},{b,h,back},{b,h,front},{a,h,front})
  for zz=back,front-1,16 do local last=math.min(front,zz+16)
   for _,xx in ipairs({a,b})do for t=0,31 do
    local m=t<16 and 0x20b or 0x213;local top=h*(32-t)/32;local bottom=h*(31-t)/32
    G.quad(out,{xx,top,zz},{xx,top,last},{xx,bottom,last},{xx,bottom,zz},G.uv(ts,m,0,t%16,16,t%16+1,.5),.95)
   end end
  end
  draw(o.h-32,o.h,function(s,t)return{x+s,h*(o.h-t)/32,front}end)
  contact(0,16,o.front)
 elseif o.kind=='artPanel'then
  draw(8,26,function(s,t)return{x+s,c.panelHeight,z+o.front-c.panelDepth+(t-8)*c.panelDepth/18}end)
  draw(26,56,function(s,t)return{x+s,c.panelHeight*(56-t)/30,z+o.front}end)
  for _,s in ipairs({0,64})do patch(0x26e,3,12,{x+s,c.panelHeight,z+o.front-c.panelDepth},{x+s,c.panelHeight,z+o.front},{x+s,0,z+o.front},{x+s,0,z+o.front-c.panelDepth},.95)end
  patch(0x26e,3,12,{x,c.panelHeight,z+o.front-c.panelDepth},{x+64,c.panelHeight,z+o.front-c.panelDepth},{x+64,0,z+o.front-c.panelDepth},{x,0,z+o.front-c.panelDepth})
  contact(0,64,o.front)
 elseif o.kind=='artRingCounter'then
  draw(14,74,function(s,t)return{x+s,c.counterHeight,z+t}end,A.ringTop)
  draw(24,32,function(s,t)return{x+s,c.counterHeight*(32-t)/8,z+24}end,function(s)return s>=16 and s<80 end)
  draw(74,80,function(s,t)return{x+s,c.counterHeight*(80-t)/6,z+74}end,function(s,t)return s>=4 and s<92 end)
  for _,r in ipairs({{0,20,70},{16,24,62},{80,24,62},{96,20,70}})do
   patch(0x253,6,12,{x+r[1],c.counterHeight,z+r[2]},{x+r[1],c.counterHeight,z+r[3]},{x+r[1],0,z+r[3]},{x+r[1],0,z+r[2]},.95)
  end
  patch(0x253,6,12,{x+16,c.counterHeight,z+62},{x+80,c.counterHeight,z+62},{x+80,0,z+62},{x+16,0,z+62},.95)
  contact(0,96,74)
 elseif o.kind=='artSculptureTable'then
  local inside=outline(L,ts,o);local function statue(s,t)return s>=16 and s<64 and t>=17 and t<40 end
  draw(14,58,function(s,t)return{x+s,c.plinthHeight,z+14+(t-14)*c.plinthDepth/44}end,inside,function(s,t)
   if statue(s,t)then return source(70,40)end;return source(s,t)
  end)
  draw(58,64,function(s,t)return{x+s,c.plinthHeight*(64-t)/6,z+14+c.plinthDepth}end,inside)
  local BM=V.require('BuildingMesh');local bg=rgb(BM.pixel(ts,source(70,40)))
  draw(17,40,function(s,t)return{x+s,c.plinthHeight+(40-t)*c.sculptureScale,z+14+c.plinthDepth*.62}end,function(s,t)return statue(s,t)and rgb(BM.pixel(ts,source(s,t)))~=bg end)
  contact(2,78,14+c.plinthDepth)
 elseif o.kind=='artStatue'then
  draw(o.cap,o.last,function(s,t)return{x+s,(o.last-t)*o.height/(o.last-o.cap),z+o.front}end,outline(L,ts,o))
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return A
