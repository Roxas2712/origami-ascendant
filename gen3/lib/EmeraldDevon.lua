-- Devon Corporation: original reception niches, research desks and executive furniture.
local V=...
local D={}
local ids={EM_RUSTBORO_CITY_DEVON_CORP_1F='devonReception',EM_RUSTBORO_CITY_DEVON_CORP_2F='devonLab',EM_RUSTBORO_CITY_DEVON_CORP_3F='devonOffice'}
function D.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local p=c.homeRooms[ids[d.id or d.name]];local L=d.midLayout
 if c.enabled and c.devon.enabled and p and L and L.width==20 and L.height==10 and d.pair==(p.lab and'general__facility'or'building__facility')
  and L:midAt(p.reception and 14 or 2,0)==0x38b then return p end
end
function D.plan(d,p)
 local c=V.require('DioramaConfig').emeraldInteriors.devon;local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for y=0,9 do for x=0,19 do local m=L:midAt(x,y)
  local floor=y>=2 and m~=0x201
  if p.reception and y<5 then floor=y>=2 and(x>=3 and x<=8 or x>=13 and x<=15)end
  if not floor then mask[y*20+x+1]={mid=0x201,void=true}
  elseif m~=0x206 and m~=0x207 then mask[y*20+x+1]=0x380 end
 end end
 local function wall(x,y,clean)
  add('wall',x,y,1,2,{wallHeight=c.wallHeight,wallLast=32,wallBase=32,clean=clean,nativeUpper=clean and true or nil})
 end
 if p.reception then
  for x=3,8 do wall(x,0,(x==3 or x==8)and{0x388,0x390}or nil)end
  for _,x in ipairs({2,9,12,16})do add('devonNicheSide',x,0,1,5,{right=x==9 or x==16})end
  for _,x in ipairs({0,1,2,9,10,11,12,16,17,18})do wall(x,3,{0x388,0x390})end
  add('devonStairs',13,0,3,3)
  add('devonCounter',3,3,5,2)
  for _,x in ipairs({3,8})do add('devonRoundCase',x,1,1,2)end
 else
  for x=0,18 do
   if not(x>=1 and x<=3)and not(p.lab and x>=13 and x<=15)then
    wall(x,0,p.office and x>=8 and x<=10 and{0x388,0x390}or nil)
   end
  end
  add('devonStairs',1,0,3,3,{down=p.office})
  if p.lab then
   add('devonStairs',13,0,3,3,{down=true})
   for y=2,8 do for x=0,18 do local m=L:midAt(x,y)
    if m==0x3a3 then add('devonDesk',x,y,2,2)
    elseif m==0x3a5 then add('devonDrawing',x,y,2,2)
    elseif m==0x3a7 then add('devonStool',x,y,1,1)
    elseif m==0x39d then add('devonBin',x,y,1,1)end
   end end
  else
   add('devonSofa',8,1,3,2)
   for _,y in ipairs({4,6})do add('devonGlassCase',1,y,1,2)end
   add('devonChair',5,4,1,3);add('devonChair',17,4,1,3,{reverse=true})
   add('devonTable',7,3,5,5);add('devonTable',15,3,2,5)
  end
 end
 return objects,mask
end
function D.actorHeight(d,x,z)
 if not D.profile(d)then return end
 local px,pz=x+8,z+16;local tx,ty=math.floor(px/16),math.floor((pz-1)/16)
 local m=d.midLayout:midAt(tx,ty)
 if (m==0x350 or m==0x307)and D.profile(d).office then local c=V.require('DioramaConfig').emeraldInteriors;return c.devon.seatHeight*c.heightScale end
 if m==0x3a7 and px>=tx*16+3 and px<tx*16+13 and pz>=ty*16+5 and pz<=ty*16+16 then
  local c=V.require('DioramaConfig').emeraldInteriors;return c.devon.seatHeight*c.heightScale
 end
end
function D.roundInside(s,t)
 if t<8 or t>30 then return false end
 local inset=t<12 and 12-t or t>=27 and t-26 or 0
 return s>=inset and s<16-inset
end
function D.chairInside(s,t,reverse)
 local q=reverse and 15-s or s
 if t<8 or t>=40 then return false end
 if t==8 then return q>=1 and q<4 end
 if t<11 then return q<5 end
 if t==38 then return q<4 or q>=11 and q<15 end
 if t==39 then return q>=1 and q<3 or q>=12 and q<14 end
 return (t>=12 and t<=15 or t>=31 and t<=35)or q<15
end
function D.tableInside(s,t,w)
 if t<13 or t>=72 then return false end
 if t==13 then return s>=1 and s<w-1 end
 if t>=68 then return s>=2 and s<6 or s>=w-6 and s<w-2 end
 return true
end
function D.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.devon;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function band(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function quad(m,u,v,uu,vv,a,b,d,e)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,uu,vv,.5),1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,cfg.contactStrength}end end end
 if o.kind=='devonDesk'then
  band(11,25,function(s,t)return{x+s,c.deskHeight,z+15+t-11}end,function(s,t)return t>11 or s>=1 and s<31 end,function(s,t)if s>=2 and s<16 then return source(20,t)end;return source(s,t)end)
  band(25,32,function(s,t)return{x+s,c.deskHeight*(32-t)/7,z+29}end,function(s,t)return t<28 or s>=2 and s<5 or s>=27 and s<30 end)
  band(8,24,function(s,t)return{x+s,c.deskHeight+(24-t)*c.pcHeight/16,z+21}end,function(s,t)return s>=2 and s<16 and(t>8 or s>=3 and s<15)end);contact(0,32,29)
 elseif o.kind=='devonDrawing'then
  band(1,23,function(s,t)return{x+s,c.deskHeight,z+8+(t-1)*20/22}end,function(s,t)return t>1 or s>=1 and s<31 end)
  band(23,31,function(s,t)return{x+s,c.deskHeight*(31-t)/8,z+28}end,function(s,t)return t<26 or s>=2 and s<5 or s>=27 and s<30 end);contact(0,32,28)
 elseif o.kind=='devonStool'then
  local function shape(s,t)if t<1 or t>=14 then return false end;local inset=t==1 and 5 or t==2 and 4 or t>=12 and 5 or t==11 and 4 or 3;return s>=inset and s<16-inset end
  band(1,9,function(s,t)return{x+s,c.seatHeight,z+6+(t-1)*9/8}end,shape)
  band(9,14,function(s,t)return{x+s,c.seatHeight*(14-t)/5,z+15}end,shape);contact(2,14,15)
 elseif o.kind=='devonBin'then
  band(0,16,function(s,t)return{x+s,c.binHeight*(16-t)/16,z+16}end,function(s,t)return s>=3 and s<13 and(t>0 or s>=5 and s<11)end);contact(3,13,16)
 elseif o.kind=='devonCounter'then
  band(14,22,function(s,t)return{x+s,c.counterHeight,z+20+(t-14)}end)
  band(22,32,function(s,t)return{x+s,c.counterHeight*(32-t)/10,z+28}end,function(s,t)return t<28 or s>=2 and s<6 or s>=o.w-6 and s<o.w-2 end);contact(0,o.w,28)
 elseif o.kind=='devonRoundCase'then
  band(8,14,function(s,t)return{x+s,c.caseHeight,z+25+(t-8)}end,D.roundInside)
  band(14,31,function(s,t)return{x+s,c.caseHeight*(31-t)/17,z+31}end,D.roundInside);contact(2,14,31)
 elseif o.kind=='devonGlassCase'then
  local function shape(s,t)if t==3 then return s>=1 and s<15 end;if t>=28 then return s>=1 and s<4 or s>=12 and s<15 end;return true end
  band(3,13,function(s,t)return{x+s,c.caseHeight,z+20+(t-3)}end,shape)
  band(13,32,function(s,t)return{x+s,c.caseHeight*(32-t)/19,z+30}end,shape);contact(0,16,30)
 elseif o.kind=='devonTable'then
  local function shape(s,t)return D.tableInside(s,t,o.w)end
  band(13,62,function(s,t)return{x+s,c.executiveTableHeight,z+20+(t-13)*46/49}end,shape)
  band(62,72,function(s,t)return{x+s,c.executiveTableHeight*(72-t)/10,z+66}end,shape);contact(0,o.w,66)
 elseif o.kind=='devonChair'then
  local function q(s)return o.reverse and 15-s or s end
  local function mask(s,t)return D.chairInside(s,t,o.reverse)end
  band(8,38,function(s,t)return{x+s,c.chairHeight*(38-t)/30,z+36}end,function(s,t)return q(s)<5 and mask(s,t)end)
  -- Close the long side back, so the far arm is connected rather than floating.
  local lo,hi=o.reverse and 11 or 0,o.reverse and 16 or 5
  for _,xx in ipairs({lo,hi})do
   band(8,38,function(s,t)return{x+xx,c.chairHeight*(38-t)/30,z+36-c.chairDepth+q(s)*c.chairDepth/5}end,function(s,t)return q(s)<5 and mask(s,t)end)
  end
  band(8,11,function(s,t)return{x+s,c.chairHeight,z+36-c.chairDepth+(t-8)*c.chairDepth/3}end,function(s,t)return q(s)<5 and mask(s,t)end)
  band(18,31,function(s,t)return{x+s,c.seatHeight,z+20+(t-18)*16/13}end,function(s,t)return q(s)>=5 and q(s)<15 and mask(s,t)end)
  band(11,18,function(s,t)return{x+s,c.seatHeight+(18-t)*4/7,z+20}end,function(s,t)return q(s)>=5 and mask(s,t)end)
  band(31,40,function(s,t)return{x+s,c.seatHeight*(40-t)/9,z+36}end,mask);contact(0,16,36)
 elseif o.kind=='devonSofa'then
  band(8,19,function(s,t)return{x+s,c.seatHeight+(19-t)*(c.sofaHeight-c.seatHeight)/11,z+23}end,function(s,t)return s>=2 and s<46 end)
  band(19,27,function(s,t)return{x+s,c.seatHeight,z+23+(t-19)*9/8}end)
  band(27,32,function(s,t)return{x+s,c.seatHeight*(32-t)/5,z+32}end,function(s,t)
   if t<29 then return s>=1 and s<47 end
   if t==29 then return s>=2 and s<46 end
   return s>=2 and s<5 or s>=43 and s<46
  end);contact(1,47,32)
 elseif o.kind=='devonStairs'then
  band(0,32,function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
  if not o.down then for j=0,2 do local row=20+j*4;local h=(3-j)*c.stepHeight
   band(row,row+2,function(s,t)return{x+s,h,z+32+(j+(t-row)/2)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
   band(row+2,row+4,function(s,t)return{x+s,h-(t-row-2)*c.stepHeight/2,z+32+(j+1)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
  end end
 elseif o.kind=='devonNicheSide'then
  local a,b=x+(o.right and 0 or 12),x+(o.right and 4 or 16);local h=c.wallHeight
  for zz=z+32,z+64,16 do
   quad(0x388,0,0,4,4,{a,h,zz},{b,h,zz},{b,h,zz+16},{a,h,zz+16})
   for _,xx in ipairs({a,b})do for j,m in ipairs({0x388,0x390})do local ht,hb=h*(3-j)/2,h*(2-j)/2
    quad(m,0,0,16,16,{xx,ht,zz},{xx,ht,zz+16},{xx,hb,zz+16},{xx,hb,zz})
   end end
  end
  for _,zz in ipairs({z+32,z+80})do for j,m in ipairs({0x388,0x390})do local ht,hb=h*(3-j)/2,h*(2-j)/2
   quad(m,0,0,4,16,{a,ht,zz},{b,ht,zz},{b,hb,zz},{a,hb,zz})
  end end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return D
