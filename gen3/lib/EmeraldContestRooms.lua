-- One set of native stage measurements for Lilycove and all six contest maps.
local V=...
local C={}
local stages={EM_CONTEST_HALL=true,EM_CONTEST_HALL_COOL=true,EM_CONTEST_HALL_BEAUTY=true,EM_CONTEST_HALL_CUTE=true,EM_CONTEST_HALL_SMART=true,EM_CONTEST_HALL_TOUGH=true}
local function kind(d)local id=d.id or d.name;return stages[id]and'stage'or id=='EM_LILYCOVE_CITY_CONTEST_LOBBY'and'lobby'or id=='EM_LILYCOVE_CITY_CONTEST_HALL'and'hall'end
function C.profile(d)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local k=kind(d);local L=d.midLayout
 if not(cfg.enabled and cfg.contestRooms.enabled and k and L)then return end
 local p=cfg.homeRooms[k=='stage'and'contestStage'or k=='lobby'and'contestLobby'or'contestHall']
 if d.pair~=(k=='stage'and'general__contest'or'building__contest')or L.width~=p.width or L.height~=p.height then return end
 if L:midAt(p.check[1],p.check[2])~=p.check[3]then return end
 return p
end
local function platforms(k)return k=='hall'and{{18,7},{6,19},{30,19}}or k=='stage'and{{0,1}}or{}end
function C.actorHeight(d,x,z)
 if not C.profile(d)then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.contestRooms
 local xx,zz=x+8,z+16
 for _,p in ipairs(platforms(kind(d)))do
  local s,t=xx-p[1]*16,zz-p[2]*16
  if s>=0 and s<240 and t>=0 and t<160 then
   return c.stageHeight*(s>=96 and s<144 and t>=112 and(160-t)/48 or 1)*cfg.heightScale
  end
 end
 return 0
end
function C.plan(d)
 local p=C.profile(d);if not p then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.contestRooms;local L=d.midLayout;local k=kind(d);local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind='contest'..kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 local function clear(x,y,w,h,void)for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]=void and{mid=0x201,void=true}or 0x260 end end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x201 or m==0x203 then clear(x,y,1,1,true)end
 end end
 if k=='lobby'then
  for x=0,30 do
   local o=add('Wall',x,0,1,2,{wallHeight=c.lobbyWallHeight})
   if x==11 or x==18 or x==19 then o.clean={0x2ca,0x262}end
   clear(x,0,1,2,true)
  end
  -- Door frames and native actors remain on their original coordinates.
  add('Counter',11,1,8,3);clear(11,2,8,3)
  add('PC',19,0,1,3);clear(19,2,1,3)
  for y=0,11 do for x=0,30 do local m=L:midAt(x,y)
   if m==0x238 or m==0x239 then add('Seat',x,y,1,2,{edge=true});clear(x,y,1,2)
   elseif m==0x2dd then add('Blender',x,y,1,1);clear(x,y,1,1)end
  end end
 elseif k=='hall'then
  for x=0,50 do
   local corner=x==4 or x==9 or x==41 or x==46
   local y
   if x>=10 and x<=40 then y=0 elseif x>=5 and x<=45 then y=2 else y=4 end
   if corner then
    local back=(x==9 or x==41)and 0 or 2
    add('Return',x,back,1,6,{right=x>25});clear(x,back,1,6,true)
   else add('Wall',x,y,1,4,{wallHeight=c.hallWallHeight});clear(x,y,1,4,true)end
  end
  for y=0,33 do for x=0,50 do local m=L:midAt(x,y)
   if m==0x248 or m==0x249 then add('Seat',x,y,1,2);clear(x,y,1,3)
   elseif m==0x24a then add('Plant',x,y,1,2);clear(x,y,1,2)end
  end end
 end
 for _,a in ipairs(platforms(k))do add('Stage',a[1],a[2],15,10);clear(a[1],a[2],15,10)
  if k=='hall'then clear(a[1],a[2]+10,16,1);for y=a[2],a[2]+9 do clear(a[1]+15,y,1,1)end end
 end
 return objects,mask
end
local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local floor={[0xf7b59c]=true,[0xd6ad7b]=true,[0xce9c7b]=true,[0xb58c5a]=true}
function C.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.contestRooms;local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function cut(s,t)local m,sx,sy=source(s,t);return not floor[key(B.pixel(ts,m,sx,sy))]end
 local function contact(w,t)if contacts then for s=4,w-1,8 do contacts[#contacts+1]={x+s,z+t,5,1.5,c.contactStrength}end end end
 local function side(ax,az,bx,bz,h,mid)
  G.quad(out,{x+ax,h,z+az},{x+bx,h,z+bz},{x+bx,0,z+bz},{x+ax,0,z+az},G.uv(ts,mid,0,0,16,16,.5),.93)
 end
 if o.kind=='contestWall'then
  draw(0,o.h,function(s,t)return{x+s,o.wallHeight*(o.h-t)/o.h,z+o.h}end,nil,o.clean and function(s,t)return o.clean[math.floor(t/16)+1],s,t%16 end)
 elseif o.kind=='contestReturn'then
  -- The stepped rear wall has real side returns, not floating curtain strips.
  local xx=x+(o.right and 0 or 16);local h=c.hallWallHeight
  for t=0,63 do local m=({0x22f,0x211,0x213,0x262})[math.floor(t/16)+1]
   G.quad(out,{xx,h*(64-t)/64,z+64},{xx,h*(64-t)/64,z+96},{xx,h*(63-t)/64,z+96},{xx,h*(63-t)/64,z+64},G.uv(ts,m,0,t%16,16,t%16+1,.5),.96)
  end
  draw(32,96,function(s,t)return{x+s,h*(96-t)/64,z+96}end,nil,function(s,t)return({0x22f,0x211,0x213,0x262})[math.floor((t-32)/16)+1],s,t%16 end)
 elseif o.kind=='contestPlant'then
  draw(0,32,function(s,t)return{x+s,c.plantHeight*(32-t)/32,z+30}end,cut);contact(16,30)
 elseif o.kind=='contestSeat'then
  draw(0,32,function(s,t)return{x+s,c.seatHeight*(32-t)/32,z+30}end,cut);contact(16,30)
 elseif o.kind=='contestBlender'then
  draw(0,10,function(s,t)return{x+s,c.blenderHeight,z+6+t}end,cut)
  draw(10,16,function(s,t)return{x+s,c.blenderHeight*(16-t)/6,z+16}end,cut);contact(16,16)
 elseif o.kind=='contestPC'then
  draw(8,48,function(s,t)return{x+s,c.pcHeight*(48-t)/40,z+48}end,function(s,t)return cut(s,t)and(t>=10 or s>=2 and s<14)end);contact(16,48)
 elseif o.kind=='contestCounter'then
  local function inside(s,t)return t>=10 and t<38 and(s<16 or s>=112 or t>=29)end
  draw(10,38,function(s,t)return{x+s,c.counterHeight,z+t+10}end,inside)
  draw(38,48,function(s,t)return{x+s,c.counterHeight*(48-t)/10,z+48}end,cut)
  for _,s in ipairs({0,16,112,128})do side(s,20,s,39,c.counterHeight,0x2d8)end
  contact(128,48)
 elseif o.kind=='contestStage'then
  local h=c.stageHeight
  draw(0,144,function(s,t)return{x+s,h,z+(t<128 and t or 128+(t-128)*2)}end,function(s,t)return t<112 or s<96 or s>=144 end)
  draw(144,160,function(s,t)return{x+s,h*(160-t)/16,z+160}end,function(s)return s<96 or s>=144 end)
  for a=112,152,8 do local top=h*(160-a)/48;local low=h*(152-a)/48
   draw(a,a+4,function(s,t)return{x+s,top,z+t}end,function(s)return s>=96 and s<144 end)
   draw(a+4,a+8,function(s,t)return{x+s,top+(low-top)*(t-a-4)/4,z+a+4}end,function(s)return s>=96 and s<144 end)
   draw(a+4,a+8,function(s,t)return{x+s,low,z+t}end,function(s)return s>=96 and s<144 end,function(s,t)return source(s,a)end)
  end
  side(0,0,0,160,h,0x224);side(240,160,240,0,h,0x226);side(240,0,0,0,h,0x20d)
  contact(96,160);if contacts then for s=148,236,8 do contacts[#contacts+1]={x+s,z+160,5,1.5,c.contactStrength}end end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return C
