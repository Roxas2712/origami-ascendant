-- Stern's two floors share one native workshop seen through an open gallery.
local V=...
local Y={}
local ids={EM_SLATEPORT_CITY_STERNS_SHIPYARD_1F='shipyardGround',EM_SLATEPORT_CITY_STERNS_SHIPYARD_2F='shipyardUpper'}
function Y.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local p=c.homeRooms[ids[d.id or d.name]];local L=d.midLayout
 if c.enabled and c.shipyard.enabled and p and d.pair=='general__facility'and L and L.width==p.width and L.height==16 and L:midAt(3,0)==(p.upper and 0x2c4 or 0x2b4)then return p end
end
function Y.plan(d,p)
 local c=V.require('DioramaConfig').emeraldInteriors.shipyard;local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o
 end
 local function floor(x,y,w,h,m)for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;if not(type(mask[k])=='table'and mask[k].void)then mask[k]=m or 0x202 end end end end
 for y=0,15 do for x=0,L.width-1 do if y<2 or y==15 or x==L.width-1 then mask[y*L.width+x+1]={mid=0x201,void=true}end end end
 for x=0,L.width-2 do if x<2 or x>4 then
  local o=add('wall',x,0,1,2,{wallHeight=c.wallHeight,wallLast=32,wallBase=32})
  if not p.upper and(x<2 or x>=8 and x<=10)then o.clean={0x219,0x221}end
 end end
 add('yardStairs',2,0,3,3,{down=p.upper});floor(2,2,3,1)
 for y=2,14 do for x=0,L.width-2 do
  local m=L:midAt(x,y)
  if m==0x240 or m==0x241 then add('yardDesk',x,y,2,2,{pc=m==0x241});floor(x,y,2,2)
  elseif m==0x20c then add('yardDraft',x,y,2,2);floor(x,y,2,2)
  elseif m==0x21d or m==0x225 then add('yardStool',x,y,1,1);floor(x,y,1,1)
  elseif m==0x205 then add('yardBin',x,y,1,1);floor(x,y,1,1)
  end
 end end
 local base=p.upper and -c.galleryDepth or 0
 add('yardBoat',11,4,4,6,{base=base})
 add('yardRig',8,4,3,4,{base=base,upper=p.upper})
 if p.upper then
  add('yardGallery',8,5,8,8);floor(8,5,8,8,{mid=0x201,void=true})
  for _,b in ipairs({{10,9,3},{14,10,2}})do add('yardGirder',b[1],b[2],1,b[3],{base=base,height=c.upperGirderHeight})end
 else
  -- Strip only machinery pixels from its factory floor. The concrete berth
  -- is rebuilt from its original border texels by yardBoat.
  add('yardModel',0,1,2,2);floor(0,2,2,1)
  floor(8,4,7,6,0x229)
  add('yardDivider',6,0,1,15);floor(6,2,1,13)
  add('yardBay',7,3,9,4);floor(7,3,9,4,0x229)
  for _,x in ipairs({8,9,10})do add('yardCabinet',x,1,1,2);floor(x,2,1,1,0x229)end
  for _,b in ipairs({{7,4,3},{10,9,4},{14,10,3}})do
   add('yardGirder',b[1],b[2],1,b[3],{height=c.girderHeight});floor(b[1],b[2],1,b[3],0x229)
  end
  for _,b in ipairs({{19,3,2,4},{7,11,3,4},{18,10,3,4}})do add('yardStock',b[1],b[2],b[3],b[4]);floor(b[1],b[2],b[3],b[4],0x229)end
 end
 return objects,mask
end
function Y.actorHeight(d,x,z)
 local p=Y.profile(d);if not p then return end
 local px,pz=x+8,z+16;local cfg=V.require('DioramaConfig').emeraldInteriors
 if p.upper and px>136 and px<248 and pz>88 and pz<200 then
  return -cfg.shipyard.galleryDepth*cfg.heightScale
 end
 -- Native stools are walkable. Lift only the feet over their seat footprint;
 -- movement and the metatile collision remain entirely native.
 local tx=math.floor(px/16);local ty=math.floor((pz-1)/16)
 local m=d.midLayout:midAt(tx,ty)
 if(m==0x21d or m==0x225)and px>=tx*16+3 and px<tx*16+13 and pz>=ty*16+5 and pz<=ty*16+16 then
  return cfg.shipyard.seatHeight*cfg.heightScale
 end
end
local boat={{0x2d0,0x2d1,0x2d2,0x2d3},{0x233,0x234,0x235,0x236},{0x23b,0x23c,0x23d,0x23e},{0x243,0x244,0x245,0x246},{0x24b,0x24c,0x24d,0x24e},{0x229,0x255,0x256,0x229}}
local rig={{0x2d5,0x2d6,0x2d7},{0x224,0x25b,0x25c},{0x229,0x263,0x264},{0x229,0x26b,0x26c}}
function Y.hullInside(s,t)
 if t<8 or t>=66 then return false end
 local inset=t<12 and(25-(t-8)*2)or t<20 and math.max(10,16-math.floor((t-12)*.875))or 9
 return s>=inset and s<64-inset and not(t>=64 and s>=20 and s<44)
end
function Y.deskInside(s,t)
 if t<11 or t>=32 then return false end
 if t==11 then return s>=1 and s<31 end
 if t<28 then return true end
 return s>=2 and s<6 or s>=26 and s<30
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function Y.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.shipyard;local G=V.require('WorldGeometry');local BM=V.require('BuildingMesh');local first=#out+1;local base=o.base or 0
 local function source(s,t)
  local cells=o.kind=='yardBoat'and boat or o.kind=='yardRig'and rig
  return cells and cells[math.floor(t/16)+1][math.floor(s/16)+1]or L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16
 end
 local function draw(w,h,a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,w,h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function band(a,b,project,inside,src)draw(o.w,o.h,a,b,project,inside,src)end
 local function quad(m,u,v,uu,vv,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,uu,vv,.5),shade or 1)end
 local function flat(m,a,b,d,e,h,shade)quad(m,0,0,16,16,{a,h,b},{d,h,b},{d,h,e},{a,h,e},shade)end
 local function contact(a,b,zz)if contacts and base==0 then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,cfg.contactStrength}end end end
 local bg={};for _,m in ipairs({0x202,0x204,0x228,0x229})do for v=0,15 do for u=0,15 do bg[rgb(BM.pixel(ts,m,u,v))]=true end end end
 local function cut(s,t)return not bg[rgb(BM.pixel(ts,source(s,t)))]end
 if o.kind=='yardModel'then
  local bounds={{10,13},{9,14},{8,22},{4,25},{3,28},{3,28},{3,29},{3,29},{3,28},{3,26},{4,26},{5,25},{6,25}}
  band(16,24,function(s,t)return{x+s,c.modelCabinetHeight,z+18+(t-16)*14/8}end,nil,function(s,t)
   if t<22 and s>=3 and s<29 then return source(6,21)end;return source(s,t)
  end)
  band(24,32,function(s,t)return{x+s,c.modelCabinetHeight*(32-t)/8,z+32}end)
  local r,g,b=BM.pixel(ts,source(0,0));local wall=rgb(r,g,b)
  band(8,21,function(s,t)return{x+s,c.modelCabinetHeight+(21-t)*c.modelHeight/13,z+24}end,function(s,t)
   local a=bounds[t-7];return a and s>=a[1]and s<a[2]and rgb(BM.pixel(ts,source(s,t)))~=wall
  end);contact(1,31,32)
 elseif o.kind=='yardDesk'then
  local function top(s,t)if o.pc and s>=2 and s<16 then return source(20,t)end;return source(s,t)end
  band(11,25,function(s,t)return{x+s,c.deskHeight,z+15+(t-11)*14/14}end,Y.deskInside,top)
  band(25,32,function(s,t)return{x+s,c.deskHeight*(32-t)/7,z+29}end,Y.deskInside)
  if o.pc then band(8,24,function(s,t)return{x+s,c.deskHeight+(24-t)*c.pcHeight/16,z+21}end,function(s,t)return s>=3 and s<16 and(t>8 or s>=4 and s<15)end)end
  contact(1,31,29)
 elseif o.kind=='yardDraft'then
  local function inside(s,t)if t<1 or t>=31 then return false elseif t==1 or t==25 then return s>=1 and s<31 elseif t>25 then return s>=2 and s<5 or s>=27 and s<30 end;return true end
  band(1,23,function(s,t)return{x+s,c.deskHeight,z+6+(t-1)*20/22}end,inside)
  band(23,31,function(s,t)return{x+s,c.deskHeight*(31-t)/8,z+26}end,inside);contact(1,31,26)
 elseif o.kind=='yardStool'then
  band(1,9,function(s,t)return{x+s,c.seatHeight,z+5+(t-1)*9/8}end,cut)
  band(9,14,function(s,t)return{x+s,c.seatHeight*(14-t)/5,z+14}end,cut);contact(3,13,14)
 elseif o.kind=='yardBin'then
  band(1,15,function(s,t)return{x+s,c.binHeight*(15-t)/14,z+15}end,cut);contact(3,13,15)
 elseif o.kind=='yardCabinet'then
  band(1,6,function(s,t)return{x+s,c.cabinetHeight,z+28-6+(t-1)*6/5}end)
  band(6,28,function(s,t)return{x+s,c.cabinetHeight*(28-t)/22,z+28}end);contact(1,15,28)
 elseif o.kind=='yardStairs'then
  band(0,32,function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
  if not o.down then for j=0,2 do local row=20+j*4;local h=(3-j)*c.stepHeight
   band(row,row+2,function(s,t)return{x+s,h,z+32+(j+(t-row)/2)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
   band(row+2,row+4,function(s,t)return{x+s,h-(t-row-2)*c.stepHeight/2,z+32+(j+1)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
  end end
 elseif o.kind=='yardDivider'then
  local function wall(a,b)
   for zz=a,b-1,16 do local stop=math.min(b,zz+16)
    flat(0x20a,x+2,z+zz,x+14,z+stop,c.wallHeight)
    for _,xx in ipairs({x+2,x+14})do quad(0x221,0,0,16,16,{xx,c.wallHeight,z+zz},{xx,c.wallHeight,z+stop},{xx,0,z+stop},{xx,0,z+zz},.95)end
   end
  end
  wall(32,144);wall(184,240)
  draw(16,34,0,34,function(s,t)return{x+s,c.wallHeight*(34-t)/34,z+144}end,nil,function(s,t)return L:midAt(6,7+math.floor(t/16)),s,t%16 end)
  quad(0x221,0,0,16,16,{x+2,c.wallHeight,z+184},{x+14,c.wallHeight,z+184},{x+14,0,z+184},{x+2,0,z+184})
 elseif o.kind=='yardBay'then
  -- A continuous rear beam and right pier, separate from rig/boat artwork.
  quad(0x20b,0,13,16,16,{x,c.bayHeight,z+32},{x+128,c.bayHeight,z+32},{x+128,c.bayHeight,z+48},{x,c.bayHeight,z+48})
  for xx=0,112,16 do quad(0x221,0,0,16,16,{x+xx,c.bayHeight,z+48},{x+xx+16,c.bayHeight,z+48},{x+xx+16,0,z+48},{x+xx,0,z+48})end
  flat(0x211,x+128,z+16,x+144,z+64,c.bayHeight)
  quad(0x220,0,0,16,16,{x+128,c.bayHeight,z+64},{x+144,c.bayHeight,z+64},{x+144,0,z+64},{x+128,0,z+64})
 elseif o.kind=='yardGirder'then
  band(0,o.h,function(s,t)return{x+s,base+(o.h-t)*o.height/o.h,z+o.h}end,cut);contact(1,15,o.h)
 elseif o.kind=='yardStock'then
  band(0,o.h,function(s,t)return{x+s,(o.h-t)*c.stockHeight/o.h,z+o.h}end,cut);contact(1,o.w-1,o.h)
 elseif o.kind=='yardRig'then
  local h=o.upper and c.upperRigHeight or c.rigHeight
  local function inside(s,t)
   if t<10 or t>=56 then return false end
   if t<18 then local a=t<12 and 27 or t<14 and 25 or 23;return s>=a and s<71-a end
   if t<22 then return s>=17 and s<44 end
   return s>=16
  end
  band(10,56,function(s,t)return{x+s,base+(56-t)*h/46,z+56}end,inside);contact(16,48,56)
 elseif o.kind=='yardBoat'then
  -- Keep the berth border on the floor; replace only pixels occupied by hull.
  local function pad(s,t)return t>=24 and t<72 or t>=72 and s>=16 and s<48 end
  local function padSource(s,t)
   if Y.hullInside(s,t)or(t>=64 and t<89 and s>=20 and s<44)then return source(3,48)end
   return source(s,t)
  end
  band(24,96,function(s,t)return{x+s,base+.05,z+t}end,pad,padSource)
  band(8,44,function(s,t)return{x+s,base+c.hullHeight,z+32+(t-8)*32/36}end,Y.hullInside)
  band(44,66,function(s,t)return{x+s,base+c.hullHeight*(66-t)/22,z+64}end,Y.hullInside)
  local function nose(s)return s>=20 and s<44 end
  band(64,74,function(s,t)return{x+s,base+c.noseHeight,z+64+(t-64)*20/10}end,nose)
  band(74,89,function(s,t)return{x+s,base+c.noseHeight*(89-t)/15,z+84}end,nose)
  for _,s in ipairs({9,55})do quad(0x234,1,5,2,6,{x+s,base+c.hullHeight,z+46},{x+s,base+c.hullHeight,z+64},{x+s,base,z+64},{x+s,base,z+46},.96)end
  for _,s in ipairs({20,44})do quad(0x24c,8,5,9,6,{x+s,base+c.noseHeight,z+64},{x+s,base+c.noseHeight,z+84},{x+s,base,z+84},{x+s,base,z+64},.96)end
 elseif o.kind=='yardGallery'then
  local depth=-c.galleryDepth
  -- Floor rim above, workshop floor below. No black rectangle around rails.
  flat(0x202,x,z,x+128,z+8,0);flat(0x202,x,z+120,x+128,z+128,0)
  flat(0x202,x,z+8,x+8,z+120,0);flat(0x202,x+120,z+8,x+128,z+120,0)
  for yy=0,7 do for xx=0,7 do local a,b=math.max(8,xx*16),math.min(120,xx*16+16);local top,bot=math.max(8,yy*16),math.min(120,yy*16+16)
   if a<b and top<bot then flat(0x229,x+a,z+top,x+b,z+bot,depth)end
  end end
  for _,e in ipairs({{8,8,120,8},{120,8,120,120},{120,120,8,120},{8,120,8,8}})do
   quad(0x221,0,0,16,16,{x+e[1],0,z+e[2]},{x+e[3],0,z+e[4]},{x+e[3],depth,z+e[4]},{x+e[1],depth,z+e[2]},G.HANGING_FACADE)
   draw(112,12,0,12,function(s,t)return{x+e[1]+(e[3]-e[1])*s/112,c.railHeight*(12-t)/12,z+e[2]+(e[4]-e[2])*s/112}end,V.require('EmeraldStations').railInside,function(s,t)return 0x269,s%16,t end)
  end
  for _,xx in ipairs({8,120})do
   for zz=8,120,16 do
    quad(0x269,2,1,5,12,{x+xx-1,c.railHeight,z+zz},{x+xx+1,c.railHeight,z+zz},{x+xx+1,0,z+zz},{x+xx-1,0,z+zz})
    flat(0x269,x+xx-1,z+zz-1,x+xx+1,z+zz+1,c.railHeight)
   end
   quad(0x269,2,1,3,2,{x+xx-1,c.railHeight,z+8},{x+xx+1,c.railHeight,z+8},{x+xx+1,c.railHeight,z+120},{x+xx-1,c.railHeight,z+120})
  end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale;if base<0 or o.kind=='yardGallery'and out[i][2]<0 then out[i][6]=G.HANGING_FACADE end end
end
return Y
