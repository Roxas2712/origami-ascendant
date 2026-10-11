-- Battle Tower lobby and partner lounge: native furniture is split into
-- measured surfaces without touching registration, partner or battle logic.
local V=...
local R={}
function R.kind(d)
 local id=d and(d.id or d.name)
 if id=='EM_BATTLE_FRONTIER_BATTLE_TOWER_LOBBY'then return'lobby' end
 if id=='EM_BATTLE_FRONTIER_BATTLE_TOWER_MULTI_PARTNER_ROOM'then return'partner'end
end
function R.profile(d)
 local k=R.kind(d);if not k then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.towerPublic.enabled and d.pair=='building__battle_frontier'and L
  and L.width==(k=='lobby'and 26 or 22)and L.height==(k=='lobby'and 10 or 16)
  and L:midAt(0,0)==0x209 then return c.homeRooms[k=='lobby'and'towerLobby'or'towerPartner']end
end
function R.plan(d)
 if not R.profile(d)then return end
 local k=R.kind(d);local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.towerPublic;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local i=yy*L.width+xx+1;if not(type(mask[i])=='table'and mask[i].void)then mask[i]=0x200 end end end
  return o
 end
 for y=0,L.height-1 do for x=0,L.width-1 do if x==L.width-1 or y<2 or L:midAt(x,y)==1 then mask[y*L.width+x+1]={mid=1,void=true}end end end
 for x=0,L.width-2 do
  local clean=k=='lobby'and(x>=1 and x<=4 or x==8 or x==12 or x==16 or x==20 or x==22)
  add('wall',x,0,1,2,{clean=clean and{0x209,0x211}or nil,wallHeight=c.wallHeight,wallBase=32,wallLast=32})
 end
 if k=='lobby'then
  add('towerCounter',4,1,17,5)
  for _,x in ipairs({4,8,12,16})do add('towerDeskDevice',x,4,1,2)end
  add('towerMonitor',1,0,3,3)
  add('towerPC',22,0,1,3)
  -- Restore the original lane rug fields and clean floor beside the long bars.
  for y=2,5 do for x=4,20 do mask[y*L.width+x+1]=0x200 end end
 end
 for y=2,L.height-2 do for x=0,L.width-2 do local m=L:midAt(x,y)
  if m==0x26e or m==0x25f then add('towerPlant',x,y,1,2)
  elseif m==0x228 then add('towerBench',x,y,1,3)
  elseif m==0x202 or m==0x203 or m==0x204 or m==0x205 then mask[y*L.width+x+1]=0x200 end
 end end
 return objects,mask
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local k=R.kind(d);local sx=(k=='lobby'and 24 or 20)*16
 if x+8<sx+1 or x+8>=sx+11 then return end
 local rows=k=='lobby'and{4}or{4,9}
 for _,y in ipairs(rows)do if z+16>=y*16+5 and z+16<=y*16+48 then
  local c=V.require('DioramaConfig').emeraldInteriors;return c.towerPublic.seatHeight*c.heightScale
 end end
end
function R.doorPose(d,a)
 if not R.profile(d)or not a or a.y~=1 then return end
 local c=V.require('DioramaConfig').emeraldInteriors
 return{height=c.towerPublic.wallHeight*c.heightScale,base=0,top=0}
end
function R.counterInside(s,t)
 if s<0 or s>=272 or t<8 or t>=80 then return false end
 local q=s%64
 return q<16 or t>=60 and(q<32 or q>=48)
end
function R.benchInside(s,t)
 if t<0 or t>=47 then return false end
 if t==0 then return s>=12 and s<14 end
 if t<4 then return s>=11 and s<15 end
 if t==4 or t==44 then return s>=2 and s<15 end
 if t==45 then return s>=2 and s<14 end
 if t==46 then return s>=2 and s<4 or s>=12 and s<14 end
 return s>=1 and s<15
end
function R.monitorInside(s,t)
 if t<17 or t>=40 then return false end
 local a=t==17 and 20 or t==18 and 10 or t<35 and 9 or t==35 and 10 or t<38 and 18 or t==38 and 19 or 20
 return s>=a and s<48-a
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.towerPublic;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and inside(s,t)end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(mid,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,mid,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,c.contactStrength}end end end
 if o.kind=='towerCounter'then
  local function clean(s,t)
   if s<256 and s%64<16 and t>=48 then return t<64 and 0x219 or 0x221,s%16,t%16 end
   return source(s,t)
  end
  draw(8,72,R.counterInside,function(s,t)return{x+s,c.counterHeight,z+t+8}end,clean)
  draw(72,80,R.counterInside,function(s,t)return{x+s,c.counterHeight*(80-t)/8,z+80}end,clean)
  -- Close every exposed border of the C/T-shaped tops with the native grey
  -- frame. Leave their front edges to the actual eight-row front artwork.
  for t=8,71 do for s=0,271 do if R.counterInside(s,t)then
   local function edge(a,b)patch(0x221,8,10,{x+a[1],c.counterHeight,z+a[2]+8},{x+b[1],c.counterHeight,z+b[2]+8},{x+b[1],0,z+b[2]+8},{x+a[1],0,z+a[2]+8},.97)end
   if not R.counterInside(s-1,t)then edge({s,t},{s,t+1})end
   if not R.counterInside(s+1,t)then edge({s+1,t+1},{s+1,t})end
   if not R.counterInside(s,t-1)then edge({s+1,t},{s,t})end
  end end end
  for s=0,271,8 do if R.counterInside(s,72)then contact(s,s+8,80)end end
 elseif o.kind=='towerDeskDevice'then
  local function inside(s,t)local a=t==4 and 3 or t<7 and 1 or t==23 and 2 or 0;return s>=a and s<16-a end
  draw(4,24,inside,function(s,t)return{x+s,c.counterHeight+c.deviceHeight*(24-t)/20,z+28}end)
 elseif o.kind=='towerPlant'then
  draw(3,31,V.require('EmeraldFrontierReception').plantInside,function(s,t)return{x+s,c.plantHeight*(31-t)/28,z+31}end);contact(2,14,31)
 elseif o.kind=='towerMonitor'then
  -- Original 48px source includes wall stripes and floor. Retain only the
  -- continuous monitor silhouette, including white screen and stand pixels.
  draw(17,40,R.monitorInside,function(s,t)return{x+s,c.monitorHeight*(40-t)/23,z+40}end);contact(16,32,40)
 elseif o.kind=='towerPC'then
  local function inside(s,t)local a=t==8 and 3 or t==9 and 2 or t==10 and 1 or t==39 and 1 or 0;return s>=a and s<16-a end
  draw(8,14,inside,function(s,t)return{x+s,c.pcHeight,z+40-c.pcDepth+(t-8)*c.pcDepth/6}end)
  draw(14,40,inside,function(s,t)return{x+s,c.pcHeight*(40-t)/26,z+40}end)
  for _,ss in ipairs({0,16})do patch(4,1,8,{x+ss,c.pcHeight,z+40-c.pcDepth},{x+ss,c.pcHeight,z+40},{x+ss,0,z+40},{x+ss,0,z+40-c.pcDepth},.97)end;contact(0,16,40)
 elseif o.kind=='towerBench'then
  draw(0,44,function(s,t)return R.benchInside(s,t)and s>=11 end,function(s,t)return{x+11,c.seatHeight+(s-11)*(c.backHeight-c.seatHeight)/4,z+t}end)
  draw(4,44,function(s,t)return R.benchInside(s,t)and s<11 end,function(s,t)return{x+s,c.seatHeight,z+t}end)
  draw(44,47,R.benchInside,function(s,t)return{x+s,c.seatHeight*(47-t)/3,z+44}end)
  for t=1,43 do local m,u,v=source(13,t)
   patch(m,u,v,{x+11,c.backHeight,z+t},{x+13,c.backHeight,z+t},{x+13,c.backHeight,z+t+1},{x+11,c.backHeight,z+t+1})
   patch(m,u,v,{x+13,c.backHeight,z+t},{x+13,c.backHeight,z+t+1},{x+13,0,z+t+1},{x+13,0,z+t},.97)
  end
  for _,tt in ipairs({1,44})do patch(0x228,13,5,{x+11,c.backHeight,z+tt},{x+13,c.backHeight,z+tt},{x+13,0,z+tt},{x+11,0,z+tt},.97)end
  patch(0x238,5,13,{x+1,c.seatHeight,z+5},{x+1,c.seatHeight,z+44},{x+1,0,z+44},{x+1,0,z+5},.97)
  contact(1,15,44)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
