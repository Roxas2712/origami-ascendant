-- Mossdeep Space Center. Original displays stay on the wall; desks stand free.
local V=...
local S={}
local ids={EM_MOSSDEEP_CITY_SPACE_CENTER_1F='spaceGround',EM_MOSSDEEP_CITY_SPACE_CENTER_2F='spaceUpper'}
function S.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local p=c.homeRooms[ids[d.id or d.name]];local L=d.midLayout
 if c.enabled and c.spaceCenter.enabled and p and d.pair=='general__facility'and L and L.width==16 and L.height==10
  and L:midAt(13,0)==(p.upper and 0x2c4 or 0x2b4)and L:midAt(3,0)==0x2f8 then return p end
end
function S.plan(d,p)
 local c=V.require('DioramaConfig').emeraldInteriors.spaceCenter;local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for y=0,9 do for x=0,15 do local m=L:midAt(x,y)
  if y<2 then mask[y*16+x+1]={mid=0x201,void=true}
  elseif m~=0x206 and m~=0x207 then mask[y*16+x+1]=0x2f0 end
 end end
 for x=0,15 do if x<12 or x>14 then
  local o=add('wall',x,0,1,2,{wallHeight=c.wallHeight,wallLast=32,wallBase=32})
  if x<3 or x==15 then o.clean={0x219,0x221};o.nativeUpper=true end
 end end
 add('spaceStairs',12,0,3,3,{down=p.upper})
 for _,x in ipairs(p.upper and{1,2,15}or{0,1,2,15})do add('spaceCabinet',x,1,1,2)end
 for y=2,9 do for x=0,15 do
  local m=L:midAt(x,y)
  if m==0x361 then add('spaceStool',x,y,1,1)
  elseif m==0x362 or m==0x363 then add('spaceDesk',x,y,2,2,{pc=m==0x363})
  elseif m==0x368 or m==0x3e4 then add('spaceDrawing',x,y,2,2)end
 end end
 if p.upper then add('spacePartition',0,0,1,5);add('spaceRail',1,4,12,1)end
 return objects,mask
end
function S.actorHeight(d,x,z)
 if not S.profile(d)then return end
 local px,pz=x+8,z+16;local tx,ty=math.floor(px/16),math.floor((pz-1)/16)
 if d.midLayout:midAt(tx,ty)==0x361 and px>=tx*16+3 and px<tx*16+13 and pz>=ty*16+5 and pz<=ty*16+16 then
  local cfg=V.require('DioramaConfig').emeraldInteriors;return cfg.spaceCenter.seatHeight*cfg.heightScale
 end
end
function S.stoolInside(s,t)
 if t<1 or t>=15 then return false end
 local inset=t==1 and 5 or t==2 and 3 or t>=13 and 4 or 2
 return s>=inset and s<16-inset
end
function S.deskInside(s,t)
 if t<11 or t>=32 then return false end
 if t==11 then return s>=1 and s<31 end
 if t>=29 then return s>=2 and s<5 or s>=27 and s<30 end
 return true
end
function S.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.spaceCenter;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function band(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function quad(m,u,v,uu,vv,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,uu,vv,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,cfg.contactStrength}end end end
 if o.kind=='spaceCabinet'then
  band(0,5,function(s,t)return{x+s,c.cabinetHeight,z+19+t}end)
  band(5,24,function(s,t)return{x+s,c.cabinetHeight*(24-t)/19,z+24}end);contact(0,16,24)
 elseif o.kind=='spaceDesk'then
  band(11,25,function(s,t)return{x+s,c.deskHeight,z+15+(t-11)}end,S.deskInside,function(s,t)
   if o.pc and s>=2 and s<16 then return source(20,t)end;return source(s,t)
  end)
  band(25,32,function(s,t)return{x+s,c.deskHeight*(32-t)/7,z+29}end,S.deskInside)
  if o.pc then band(8,24,function(s,t)return{x+s,c.deskHeight+(24-t)*c.pcHeight/16,z+21}end,function(s,t)return s>=2 and s<16 and(t>8 or s>=3 and s<15)end)end
  contact(1,31,29)
 elseif o.kind=='spaceDrawing'then
  -- This samples the live metatile: event-driven DataPad/blank table survives.
  band(2,24,function(s,t)return{x+s,c.deskHeight,z+7+(t-2)*20/22}end,function(s,t)return t>2 or s>=1 and s<31 end)
  band(24,32,function(s,t)return{x+s,c.deskHeight*(32-t)/8,z+27}end,function(s,t)return t<29 or s>=2 and s<5 or s>=27 and s<30 end);contact(1,31,27)
 elseif o.kind=='spaceStool'then
  band(1,10,function(s,t)return{x+s,c.seatHeight,z+6+(t-1)*10/9}end,S.stoolInside)
  band(10,15,function(s,t)return{x+s,c.seatHeight*(15-t)/5,z+16}end,S.stoolInside);contact(2,14,16)
 elseif o.kind=='spaceStairs'then
  band(0,32,function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
  if not o.down then for j=0,2 do local row=20+j*4;local h=(3-j)*c.stepHeight
   band(row,row+2,function(s,t)return{x+s,h,z+32+(j+(t-row)/2)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
   band(row+2,row+4,function(s,t)return{x+s,h-(t-row-2)*c.stepHeight/2,z+32+(j+1)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
  end end
 elseif o.kind=='spaceRail'then
  band(2,14,function(s,t)return{x+s,c.railHeight*(14-t)/12,z+12}end,function(s,t)return t<5 or t>=11 or s%8>=2 and s%8<6 end)
  contact(0,o.w,12)
 elseif o.kind=='spacePartition'then
  for zz=32,64,16 do
   quad(0x20a,0,0,16,16,{x+2,c.wallHeight,z+zz},{x+14,c.wallHeight,z+zz},{x+14,c.wallHeight,z+zz+16},{x+2,c.wallHeight,z+zz+16})
   for _,xx in ipairs({2,14})do quad(0x221,0,0,16,16,{x+xx,c.wallHeight,z+zz},{x+xx,c.wallHeight,z+zz+16},{x+xx,0,z+zz+16},{x+xx,0,z+zz},.96)end
  end
  band(48,80,function(s,t)return{x+s,c.wallHeight*(80-t)/32,z+80}end)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return S
