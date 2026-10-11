-- Mossdeep game club. Presentation only; original scripts own access.
local V=...
local M={}
local ids={EM_MOSSDEEP_CITY_GAME_CORNER_1F='mossGround',EM_MOSSDEEP_CITY_GAME_CORNER_B1F='mossBasement'}
function M.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local id=d.id or d.name;local L=d.midLayout
 if not(c.enabled and c.mossdeepClub.enabled and ids[id]and L and L.width==12 and L.height==10)then return end
 local basement=ids[id]=='mossBasement'
 if d.pair~=(basement and'building__generic_building'or'building__mossdeep_game_corner')or L:midAt(0,0)~=(basement and 0x205 or 0x203)then return end
 return c.homeRooms[ids[id]]
end
function M.plan(d,p)
 local c=V.require('DioramaConfig').emeraldInteriors.mossdeepClub;local L=d.midLayout;local basement=p.basement
 local objects,mask={},{}
 local function add(o,x,y,w,h)o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=o.kind~='wall';objects[#objects+1]=o;return o end
 if basement then
  -- The central orange rug belongs to the floor, including its full border.
  for y=0,9 do for x=0,11 do local m=L:midAt(x,y);local k=y*12+x+1
   if m==1 or y<2 then mask[k]={mid=1,void=true}
   elseif not(x>=4 and x<=7 and y>=4 and y<=6)then mask[k]=y==2 and 0x224 or x==0 and 0x239 or 0x223 end
  end end
  for x=0,11 do if x<2 or x>4 then
   local o=add({kind='wall',wallHeight=c.wallHeight,wallBase=32,wallLast=32},x,0,1,2)
   if x==0 or x==11 then o.clean={0x205,0x20d}end
  end end
  add({kind='mossStairs'},2,0,3,2)
  for _,q in ipairs({{0,1},{11,1},{0,7},{11,7}})do add({kind='mossPlant',front=32},q[1],q[2],1,2)end
 else
  for y=0,9 do for x=0,11 do local m=L:midAt(x,y);local k=y*12+x+1
   if y<2 then mask[k]={mid=1,void=true}
   elseif m~=0x22d and m~=0x22e then mask[k]=y==2 and(x==0 and 0x201 or 0x202)or(x==0 and 0x209 or 0x20a)end
  end end
  for x=0,11 do if x<3 or x>7 then
   local o=add({kind='wall',wallHeight=c.wallHeight,wallBase=35,wallLast=32},x,0,1,2)
   if x==2 or x==8 or x==10 then o.clean={0x203,0x20b}end
  end end
  add({kind='mossDoor'},3,0,5,3)
  add({kind='mossCounter',front=40,gateOpen=L:midAt(5,2)==0x22c and L:midAt(5,3)==0x234},2,1,7,3)
  add({kind='mossPC',front=40},10,0,1,3)
  for _,x in ipairs({2,7})do
   add({kind='mossTable',front=40},x,5,2,3)
   for xx=x,x+1 do add({kind='mossStool',above=true,front=13},xx,5,1,1)end
  end
  for _,x in ipairs({1,9})do for y=6,7 do add({kind='mossStool',front=15},x,y,1,1)end end
 end
 return objects,mask
end
function M.counterTop(s,t,open)
 if open and s>=50 and s<62 then return false end
 if s<0 or s>=112 or t<5 or t>=40 then return false end
 if t<29 then return(s<16 or s>=96)and(t>5 or s>0 and s<111)end
 return true
end
function M.counterFrontInside(s,t,open)
 if open and s>=50 and s<62 then return false end
 if t<40 or t>=46 then return false end
 if t<42 then return true end
 if t==42 then return s>=1 and s<50 or s>=62 and s<111 end
 if t==43 then return s>=2 and s<8 or s>=42 and s<49 or s>=63 and s<70 or s>=104 and s<110 end
 if t==44 then return s>=2 and s<8 or s>=42 and s<48 or s>=64 and s<70 or s>=104 and s<110 end
 return s>=3 and s<7 or s>=43 and s<47 or s>=65 and s<69 or s>=105 and s<109
end
local plantRows={
 [1]={7,9},[2]={6,10},[3]={3,13},[4]={2,14},[5]={2,14},[6]={1,15},[7]={0,16},[8]={0,16},[9]={1,15},
 [10]={0,16},[11]={0,16},[12]={1,15},[13]={2,14},[14]={2,14},[15]={4,12},[16]={5,11},[17]={6,10},[18]={6,10},[19]={6,10},
 [20]={3,13},[21]={2,14},[22]={2,14},[23]={2,14},[24]={2,14},[25]={2,14},[26]={2,14},[27]={2,14},[28]={2,14},[29]={2,14},[30]={3,13},[31]={4,12},
}
function M.plantInside(s,t)local r=plantRows[t];return r and s>=r[1]and s<r[2]or false end
function M.stoolInside(o,s,t)
 if t==1 then return s>=4 and s<12 end
 if t==2 then return s>=3 and s<13 end
 if t>=3 and t<=10 then return s>=2 and s<14 end
 if t==11 or t==12 then return s>=3 and s<13 end
 if not o.above and t==13 then return s>=3 and s<7 or s>=9 and s<13 end
 if not o.above and t==14 then return s>=4 and s<6 or s>=10 and s<12 end
 return false
end
function M.tableInside(s,t)
 if t<13 or t>=47 then return false end
 if t==13 then return s>=3 and s<29 elseif t==14 then return s>=2 and s<30 elseif t==15 then return s>=1 and s<31 end
 if t==43 then return s>=1 and s<31 elseif t==44 then return s>=2 and s<30 end
 if t>=45 then return s>=2 and s<7 or s>=25 and s<30 end
 return true
end
function M.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.mossdeepClub;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,project,inside)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(s,t,a,b,d,e,shade)local m,u,v=source(s,t);G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+3,b-2,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,cfg.contactStrength}end end end
 if o.kind=='mossDoor'then
  draw(0,35,function(s,t)return{x+s,c.wallHeight*(35-t)/35,z+35}end,function(s,t)
   if t<32 then return true end
   local col,u=math.floor(s/16),s%16;return col<2 and u>=9 and u<15 or col>2 and u>=2 and u<8
  end)
 elseif o.kind=='mossStairs'then
  draw(0,32,function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
  for j=0,2 do local a=20+j*4;local h=(3-j)*c.stepHeight
   draw(a,a+2,function(s,t)return{x+s,h,z+32+(j+(t-a)/2)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
   draw(a+2,a+4,function(s,t)return{x+s,h-(t-a-2)*c.stepHeight/2,z+32+(j+1)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
  end
 elseif o.kind=='mossPlant'then
  draw(1,32,function(s,t)return{x+s,c.plantHeight*(32-t)/31,z+32}end,M.plantInside);contact(3,13,32)
 elseif o.kind=='mossPC'then
  local function inside(s,t)local inset=t==8 and 3 or t==9 and 2 or t==10 and 1 or t==38 and 1 or t==39 and 2 or 0;return s>=inset and s<16-inset end
  draw(8,16,function(s,t)return{x+s,c.terminalHeight,z+40-c.terminalDepth+(t-8)*c.terminalDepth/8}end,inside)
  draw(16,40,function(s,t)return{x+s,c.terminalHeight*(40-t)/24,z+40}end,inside)
  for _,s in ipairs({0,16})do patch(1,17,{x+s,c.terminalHeight,z+40-c.terminalDepth},{x+s,c.terminalHeight,z+40},{x+s,0,z+40},{x+s,0,z+40-c.terminalDepth},.95)end
  contact(0,16,40)
 elseif o.kind=='mossCounter'then
  draw(5,40,function(s,t)return{x+s,c.counterHeight,z+t}end,function(s,t)return M.counterTop(s,t,o.gateOpen)end)
  draw(40,46,function(s,t)return{x+s,c.counterHeight*(46-t)/6,z+40}end,function(s,t)return M.counterFrontInside(s,t,o.gateOpen)end)
  for _,s in ipairs({0,16,96,112})do patch(4,40,{x+s,c.counterHeight,z+6},{x+s,c.counterHeight,z+29},{x+s,0,z+29},{x+s,0,z+6},.95)end
  local ranges=o.gateOpen and{{16,50},{62,96}}or{{16,96}}
  for _,r in ipairs(ranges)do patch(4,40,{x+r[1],c.counterHeight,z+29},{x+r[2],c.counterHeight,z+29},{x+r[2],0,z+29},{x+r[1],0,z+29},.95)end
  if o.gateOpen then
   for _,s in ipairs({50,62})do patch(s==50 and 49 or 62,34,{x+s,c.counterHeight,z+29},{x+s,c.counterHeight,z+40},{x+s,0,z+40},{x+s,0,z+29},.95)end
   contact(0,50,40);contact(62,112,40)
  else contact(0,112,40)end
 elseif o.kind=='mossTable'then
  draw(13,40,function(s,t)return{x+s,c.tableHeight,z+40-c.tableDepth+(t-13)*c.tableDepth/27}end,M.tableInside)
  draw(40,47,function(s,t)return{x+s,c.tableHeight*(47-t)/7,z+40}end,M.tableInside)
  for _,s in ipairs({0,32})do patch(1,40,{x+s,c.tableHeight,z+40-c.tableDepth},{x+s,c.tableHeight,z+40},{x+s,c.tableHeight-2,z+40},{x+s,c.tableHeight-2,z+40-c.tableDepth},.95)end
  contact(0,32,40)
 elseif o.kind=='mossStool'then
  local inside=function(s,t)return M.stoolInside(o,s,t)end;local last=o.above and 13 or 15
  draw(1,11,function(s,t)return{x+s,c.stoolHeight,z+o.front-c.stoolDepth+(t-1)*c.stoolDepth/10}end,inside)
  draw(11,last,function(s,t)return{x+s,c.stoolHeight*(last-t)/(last-11),z+o.front}end,inside)
  contact(3,13,o.front)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return M
