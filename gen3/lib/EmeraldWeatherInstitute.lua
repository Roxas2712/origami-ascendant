-- Weather Institute: original laboratory art, geometry independent of native cells.
local V=...
local W={}
local ids={EM_ROUTE119_WEATHER_INSTITUTE_1F='weatherGround',EM_ROUTE119_WEATHER_INSTITUTE_2F='weatherUpper'}
function W.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local p=c.homeRooms[ids[d.id or d.name]];local L=d.midLayout
 if c.enabled and c.weatherInstitute.enabled and p and d.pair=='building__lab'and L and L.width==20 and L.height==(p.upper and 12 or 14)
  and L:midAt(17,0)==0x27d and L:midAt(p.upper and 5 or 8,1)==0x22c then return p end
end
function W.plan(d,p)
 local c=V.require('DioramaConfig').emeraldInteriors.weatherInstitute;local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for y=0,L.height-1 do for x=0,19 do local m=L:midAt(x,y)
  if m==0x201 or y<2 then mask[y*20+x+1]={mid=0x201,void=true}
  elseif m~=0x206 and m~=0x207 then mask[y*20+x+1]=p.floor end
 end end
 for x=0,19 do if x<16 or x>18 then
  add('wall',x,0,1,2,{wallHeight=c.wallHeight,wallLast=32,wallBase=32,clean={0x25f,0x267}})
 end end
 add('weatherStairs',16,0,3,3,{down=p.upper})
 for y=0,L.height-1 do for x=0,19 do local m=L:midAt(x,y)
  if m==0x22c then add('weatherCabinet',x,y,2,2)
  elseif m==0x288 then add('weatherTerminal',x,y,2,3)
  elseif m==0x260 or m==0x264 then
   add('weatherDesk',x,y,L:midAt(x+1,y)==0x269 and 1 or 2,3)
  elseif m==0x25e or m==0x256 or m==0x257 then add('weatherChair',x,y,1,1,{reverse=m~=0x25e})
  elseif m==0x255 then add('weatherPlant',x,y,1,2)
  end
 end end
 if p.upper then
  add('weatherDivider',4,0,1,7,{frontRow=3});add('weatherDivider',4,7,1,4,{reverse=true,frontRow=0})
 else
  add('weatherBed',0,2,2,2);add('weatherMedicalPC',2,0,1,3)
  for _,x in ipairs({3,7})do add('weatherDivider',x,0,1,7,{frontRow=3});add('weatherDivider',x,7,1,4,{frontRow=0})end
  for x=0,19 do if x<3 or x>7 then add('wall',x,8,1,2,{wallHeight=c.wallHeight,wallLast=32,wallBase=32})end end
 end
 return objects,mask
end
local plantRows={
 [13]="0000000100000000",
 [14]="0000001110000000",
 [15]="0000001111000000",
 [16]="0000011111000000",
 [17]="0011111111011100",
 [18]="1111111111111110",
 [19]="1111111111111111",
 [20]="0111111111111110",
 [21]="0011111111111000",
 [22]="0011111111111100",
 [23]="0111111111111100",
 [24]="1111111111111100",
 [25]="1111111111111100",
 [26]="0111111111111100",
 [27]="0111111111111100",
 [28]="0001111111111000",
 [29]="0000111111110000",
 [30]="0000001111000000",
}
function W.plantInside(s,t)local row=plantRows[t];return row and row:sub(s+1,s+1)=="1"or false end
function W.deskInside(s,t,width)
 if t<1 or t>=47 then return false end
 if t<5 then return false end -- PC cap is drawn separately, not floor pixels.
 if t>=41 then local q=s%16;return q>=2 and q<5 or q>=12 and q<15 end
 return s>=0 and s<width
end
function W.pcInside(s,t)
 local q=s%16
 if t==1 then return q>=2 and q<8 end
 if t==2 then return q>=2 and q<13 end
 if t<4 then return q>=2 and q<14 end
 if t<15 then return q>=2 and q<14 end
 return q>=1 and q<15
end
function W.chairInside(s,t,reverse)
 if reverse then s=15-s end
 if t==0 then return s>=2 and s<4 end
 if t<4 then return s>=1 and s<5 end
 if t==4 then return s>=1 and s<13 end
 if t<14 then return s>=1 and s<15 end
 return s>=2 and s<5 or s>=11 and s<14
end
function W.actorHeight(d,x,z)
 if not W.profile(d)then return end
 local px,pz=x+8,z+16;local tx,ty=math.floor(px/16),math.floor((pz-1)/16);local m=d.midLayout:midAt(tx,ty)
 if(m==0x25e or m==0x256 or m==0x257)and px>=tx*16+3 and px<tx*16+14 and pz>=ty*16+5 and pz<=ty*16+16 then
  local c=V.require('DioramaConfig').emeraldInteriors;return c.weatherInstitute.seatHeight*c.heightScale
 end
end
function W.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.weatherInstitute;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function band(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function quad(m,u,v,uu,vv,a,b,d,e)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,uu,vv,.5),1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,cfg.contactStrength}end end end
 if o.kind=='weatherCabinet'then
  band(0,11,function(s,t)return{x+s,c.cabinetHeight,z+20+t}end)
  band(11,32,function(s,t)return{x+s,c.cabinetHeight*(32-t)/21,z+31}end);contact(0,32,31)
 elseif o.kind=='weatherDesk'then
  band(5,40,function(s,t)return{x+s,c.deskHeight,z+14+(t-5)*26/35}end,nil,function(s,t)
   -- Use the original empty part of this same tabletop beneath the raised PC.
   return source(s,t<24 and 24+(t%8)or t)
  end)
  band(40,47,function(s,t)return{x+s,c.deskHeight*(47-t)/7,z+40}end,function(s,t)return W.deskInside(s,t,o.w)end)
  band(1,21,function(s,t)return{x+s,c.deskHeight+c.pcHeight*(21-t)/20,z+23}end,W.pcInside)
  contact(0,o.w,40)
 elseif o.kind=='weatherChair'then
  local function mask(s,t)return W.chairInside(s,t,o.reverse)end
  -- Side-facing back follows the original chair; seat stays horizontal.
  band(0,11,function(s,t)return{x+s,c.seatHeight+(11-t)*c.chairBackHeight/11,z+8}end,function(s,t)local q=o.reverse and 15-s or s;return q<5 and mask(s,t)end)
  band(4,13,function(s,t)return{x+s,c.seatHeight,z+5+(t-4)*9/9}end,function(s,t)local q=o.reverse and 15-s or s;return q>=5 and mask(s,t)end)
  band(13,16,function(s,t)return{x+s,c.seatHeight*(16-t)/3,z+14}end,mask);contact(2,15,14)
 elseif o.kind=='weatherTerminal'then
  band(20,32,function(s,t)return{x+s,c.deskHeight,z+32+(t-20)}end,nil,function(s,t)return source(25+(s%6),21+(t%10))end)
  band(32,39,function(s,t)return{x+s,c.deskHeight*(39-t)/7,z+44}end,function(s,t)return t<35 or s>=2 and s<5 or s>=20 and s<31 end)
  band(10,30,function(s,t)return{x+s,c.deskHeight+c.terminalHeight*(30-t)/20,z+40}end,function(s,t)
   if t==10 then return s>=13 and s<20 end
   if t==11 then return s>=3 and s<8 or s>=10 and s<23 end
   if t<20 then return s>=2 and s<23 end
   return s>=1 and s<24
  end);contact(0,32,44)
 elseif o.kind=='weatherMedicalPC'then
  band(8,40,function(s,t)return{x+s,c.medicalPCHeight*(40-t)/32,z+40}end,function(s,t)
   if t==8 then return s>=3 and s<13 end
   if t==9 then return s>=2 and s<14 end
   if t==10 then return s>=1 and s<15 end
   if t==38 then return s>=1 and s<15 end
   if t==39 then return s>=2 and s<14 end
   return true
  end);contact(1,15,40)
 elseif o.kind=='weatherBed'then
  local function mask(s,t)
   if t==0 then return s>=8 and s<24 end
   if t<3 then return s>=6 and s<26 end
   if t<12 then return s>=5 and s<27 end
   if t<30 then return s>=4 and s<28 end
   return s>=5 and s<8 or s>=24 and s<27
  end
  band(0,5,function(s,t)return{x+s,c.bedHeight+(5-t)*1.2,z+8}end,mask)
  band(5,26,function(s,t)return{x+s,c.bedHeight,z+8+(t-5)}end,mask)
  band(26,32,function(s,t)return{x+s,c.bedHeight*(32-t)/6,z+29}end,mask);contact(4,28,29)
 elseif o.kind=='weatherPlant'then
  band(13,31,function(s,t)return{x+s,c.plantHeight*(31-t)/18,z+31}end,W.plantInside,function(s,t)if t>=16 then return 0x25d,s,t%16 end;return source(s,t)end);contact(2,14,31)
 elseif o.kind=='weatherStairs'then
  band(0,32,function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
  if not o.down then for j=0,2 do local row=20+j*4;local h=(3-j)*c.stepHeight
   band(row,row+2,function(s,t)return{x+s,h,z+32+(j+(t-row)/2)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
   band(row+2,row+4,function(s,t)return{x+s,h-(t-row-2)*c.stepHeight/2,z+32+(j+1)*c.stairDepth/3}end,function(s)return s>=16 and s<32 end)
  end end
 elseif o.kind=='weatherDivider'then
  local h=c.wallHeight;local back=z+32;local front=z+o.h-.5
  for zz=back,front-1,16 do
   local ending=math.min(zz+16,front)
   quad(0x26b,0,0,16,16,{x,h,zz},{x+16,h,zz},{x+16,h,ending},{x,h,ending})
   for _,xx in ipairs({x,x+16})do for j,m in ipairs({0x25f,0x267})do
    local ht,hb=h*(3-j)/2,h*(2-j)/2
    quad(m,0,0,16,16,{xx,ht,zz},{xx,ht,ending},{xx,hb,ending},{xx,hb,zz})
   end end
  end
  local start=o.frontRow*16
  band(start+16,start+64,function(s,t)return{x+s,h*(start+64-t)/48,front}end,nil,function(s,t)
   if o.reverse then return ({0x270,0x278,0x280})[math.min(3,math.floor((t-start-16)/16)+1)],s,t%16 end
   return source(s,t)
  end)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return W
