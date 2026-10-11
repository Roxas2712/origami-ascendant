-- Aqua B1: measured rooms, native artwork and unchanged teleport/gameplay data.
local V=...;local R={}
function R.kind(d)return d and(d.id or d.name)=='EM_AQUA_HIDEOUT_B1F'end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d and d.midLayout
 if R.kind(d)and c.enabled and c.aquaOperations.enabled and d.mapType==8 and d.pair=='general__facility'
  and L and L.width==52 and L.height==24 and L:midAt(29,6)==0x22b and L:midAt(18,9)==0x3c3 then return c.homeRooms.aquaOperations end
end
function R.lighting(d)if R.profile(d)then return V.require('DioramaConfig').emeraldInteriors.aquaOperations.light end end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local list,mask={},{}
 local function add(k,x,y,w,h,p)
  p=p or{};p.kind='a1'..k;p.x=x;p.y=y;p.w=w*16;p.h=h*16;p.noContact=true;list[#list+1]=p
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=0x228,void=true}end end
 end
 add('Wall',1,2,6,3,{clean={{64,96}}})
 add('Wall',8,0,6,3)
 add('Wall',15,0,10,3,{clean={{96,160}}})
 add('Wall',26,0,7,3)
 add('Wall',15,6,10,2,{bottom=32,clean={{0,32},{128,160}}})
 add('Wall',26,6,7,3,{clean={{48,112}}})
 add('Wall',1,12,24,3)
 add('Wall',26,14,7,3)
 add('Wall',1,22,32,2)
 add('Wall',41,0,9,3,{clean={{0,32},{80,144}}})
 add('Wall',41,19,9,2)
 add('Machine',5,2,2,4,{start=8,base=56,wall=true})
 add('Tank',29,6,4,6)
 for _,a in ipairs{{6,6},{8,8},{17,18},{22,18}}do add('Desk',a[1],a[2],2,2)end
 for _,a in ipairs{{6,8},{8,10},{17,16},{21,16},{23,17},{18,17},{17,20},{23,20}}do add('Stool',a[1],a[2],1,1)end
 for _,a in ipairs{{5,7},{10,9}}do add('Bin',a[1],a[2],1,1)end
 for _,a in ipairs{{21,1,3},{23,1,4},{41,1,3},{46,1,3},{48,1,4}}do add('Crate',a[1],a[2],2,a[3],{last=a[3]*16-2})end
 for _,a in ipairs{{16,15,2},{24,14,3},{24,18,2},{25,18,2}}do add('Cylinder',a[1],a[2],1,a[3])end
 add('Worktable',17,15,2,2);add('Worktable',22,15,2,2)
 add('Cabinet',15,7,2,2)
 add('OfficeTable',18,9,2,2)
 add('Sofa',21,8,1,3)
 add('Model',23,7,2,2)
 local common=V.require('EmeraldAquaHideout')
 local rims={[0x209]=true,[0x20a]=true,[0x20b]=true,[0x210]=true,[0x211]=true,[0x213]=true,[0x259]=true,[0x220]=true}
 local rails={[0x286]=true,[0x28e]=true,[0x2a6]=true,[0x262]=true,[0x26a]=true}
 for y=0,L.height-1 do for x=0,L.width-1 do if not mask[y*L.width+x+1]then
  local m=L:midAt(x,y)
  if m==0x201 then mask[y*L.width+x+1]={mid=m,void=true}
  elseif common.isRail(m)or rails[m]then add('Rail',x,y,1,1,{water=true})
  elseif rims[m]then add('Rim',x,y,1,1)
  elseif m==0x21f or m==0x227 or m==0x22f or m==0x237 then add('Pipe',x,y,1,1)end
 end end end
 return list,mask
end
-- Exact native sofa outline; its rug greys also occur inside the cushions.
function R.sofaInside(s,t)
 if t==8 then return s>=12 and s<15 end
 if t==9 or t==10 then return s>=11 and s<16 end
 if t==11 or t>=16 and t<=30 or t==36 or t==37 then return s>=1 and s<16 end
 if t>=12 and t<=15 or t>=31 and t<=35 then return s>=0 and s<16 end
 if t==38 then return s>=1 and s<5 or s>=12 and s<16 end
 if t==39 then return s>=2 and s<4 or s>=13 and s<15 end
 return false
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.aquaOperations;local k=o.kind:sub(3)
 if k=='Tank'or k=='Machine'or k=='Desk'or k=='Stool'or k=='Bin'or k=='Rail'or k=='Rim'or k=='Pipe'then
  local a={};for key,v in pairs(o)do a[key]=v end;a.kind='a2'..k
  V.require('EmeraldAquaBasement').build(out,L,ts,a,x,z,contacts);return
 end
 local first=#out+1
 local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,point,source)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source or src,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,point,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function floor(mid,a,b)
  draw(a or 0,b or o.h,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)return mid,s%16,t%16 end)
 end
 local base
 if k=='Wall'then
  local bottom=o.bottom or math.min(40,o.h)
  local function clean(s,t)
   local m,u,v=src(s,t)
   for _,r in ipairs(o.clean or{})do if s>=r[1]and s<r[2]then m=t<16 and 0x2e0 or t<32 and 0x221 or 0x229 end end
   return m,u,v
  end
  -- Thin upright wall on a low foundation occupying the native painted strip.
  -- A full-height 40px slab would cover adjacent floor/player with a huge roof.
  local G=V.require('WorldGeometry');local h=c.wallHeight*bottom/40
  local rear=bottom-c.wallDepth;local plinth=c.foundationHeight
  G.quad(out,{x,plinth,z},{x+o.w,plinth,z},{x+o.w,plinth,z+rear},{x,plinth,z+rear},G.uv(ts,0x2e0,2,6,14,8,.5),c.wallCapShade)
  G.quad(out,{x,h,z+rear},{x+o.w,h,z+rear},{x+o.w,h,z+bottom},{x,h,z+bottom},G.uv(ts,0x2e0,2,0,14,4,.5),1)
  G.quad(out,{x,plinth,z+rear},{x+o.w,plinth,z+rear},{x+o.w,h,z+rear},{x,h,z+rear},G.uv(ts,0x221,2,2,14,14,.5),1)
  draw(0,bottom,nil,function(s,t)return{x+s,c.wallHeight*(bottom-t)/40,z+bottom}end,clean)
  draw(bottom,o.h,nil,function(s,t)return{x+s,0,z+t}end,clean)
 elseif k=='Crate'then
  floor(0x228,math.max(0,40-o.y*16))
  local _,inside=V.require('EmeraldCableRooms').cutout(L,ts,o.x*16,o.y*16,o.w,o.h,{0x228,0x221,0x229})
  local h=c.crateHeight+(o.h-48);base=o.last
  draw(0,3,inside,function(s,t)return{x+s,h,z+base-c.crateDepth+t*c.crateDepth/3}end)
  draw(3,base,inside,function(s,t)return{x+s,h*(base-t)/(base-3),z+base}end)
 elseif k=='Cylinder'then
  floor(0x202)
  local _,inside=V.require('EmeraldCableRooms').cutout(L,ts,o.x*16,o.y*16,o.w,o.h,{0x202,0x203})
  base=o.h-2;draw(0,base,inside,function(s,t)return{x+s,(c.cylinderHeight+o.h-32)*(base-t)/base,z+base}end)
 elseif k=='Worktable'or k=='OfficeTable'then
  local office=k=='OfficeTable';floor(office and 0x3e5 or 0x202)
  local _,inside=V.require('EmeraldCableRooms').cutout(L,ts,o.x*16,o.y*16,o.w,o.h,{office and 0x3e5 or 0x202})
  base=25
  draw(0,base,inside,function(s,t)return{x+s,c.tableHeight,z+t}end)
  draw(base,32,inside,function(s,t)return{x+s,c.tableHeight*(32-t)/7,z+base}end)
 elseif k=='Cabinet'then
  floor(0x3e5,16)
  local _,inside=V.require('EmeraldCableRooms').cutout(L,ts,o.x*16,o.y*16,o.w,o.h,{0x221,0x3e5})
  base=31;draw(0,base,inside,function(s,t)return{x+s,c.cabinetHeight*(base-t)/base,z+base}end)
 elseif k=='Sofa'then
  floor(0x3e5)
  local inside=R.sofaInside
  -- Native side-facing sofa: upright back, horizontal cushion, low front.
  base=39
  draw(7,base,function(s,t)return inside(s,t)and s>=12 end,function(s,t)return{x+12,c.sofaHeight-(s-12)*(c.sofaHeight-c.seatHeight)/4,z+t}end)
  draw(7,base,function(s,t)return inside(s,t)and s<12 end,function(s,t)return{x+s,c.seatHeight,z+t}end)
  draw(base,48,inside,function(s,t)return{x+s,c.seatHeight*(48-t)/9,z+base}end)
  -- Give the side-facing back thickness so it never becomes a floating line
  -- when viewed along the camera plane from the neighbouring chamber.
  local G=V.require('WorldGeometry');local m,u,v=src(13,18);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
  G.quad(out,{x+12,c.sofaHeight,z+9},{x+16,c.sofaHeight,z+9},{x+16,c.sofaHeight,z+38},{x+12,c.sofaHeight,z+38},uv,1)
  G.quad(out,{x+16,c.sofaHeight,z+9},{x+16,c.sofaHeight,z+38},{x+16,c.seatHeight,z+38},{x+16,c.seatHeight,z+9},uv,1)
  G.quad(out,{x+12,c.sofaHeight,z+9},{x+16,c.sofaHeight,z+9},{x+16,c.seatHeight,z+9},{x+12,c.seatHeight,z+9},uv,1)
  G.quad(out,{x+16,c.sofaHeight,z+38},{x+12,c.sofaHeight,z+38},{x+12,0,z+38},{x+16,0,z+38},uv,1)
 elseif k=='Model'then
  floor(0x3e5,16);base=28
  local _,inside=V.require('EmeraldCableRooms').cutout(L,ts,o.x*16,o.y*16,o.w,o.h,{0x221,0x3e5,0x3e6})
  draw(0,20,inside,function(s,t)return{x+s,c.modelHeight*(20-t)/20+c.shelfHeight,z+20}end)
  draw(20,base,inside,function(s,t)return{x+s,c.shelfHeight*(base-t)/(base-20),z+20}end)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
 if contacts and base then contacts[#contacts+1]={x+o.w/2,z+base,o.w*.4,2,c.contactStrength}end
end
return R
