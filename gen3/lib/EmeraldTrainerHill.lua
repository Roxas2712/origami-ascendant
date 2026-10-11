-- Trainer Hill consumes the live, engine-composed floor. No challenge data writes.
local V=...
local H={}
local columns={}
for _,m in ipairs({0x223,0x224,0x22b,0x22c,0x233,0x234,0x25b,0x25c,0x263,0x264,0x26b,0x26c,
 0x283,0x284,0x28b,0x28c,0x293,0x294,0x2a3,0x2a4,0x2ab,0x2ac,0x2b4,0x2b6,
 0x2c3,0x2c4,0x2cb,0x2cc,0x2d3,0x2d4,0x2e3,0x2e4,0x2eb,0x2ec,0x2f3,0x2f4})do columns[m]=true end
local tall={[0x237]=true,[0x26f]=true,[0x297]=true,[0x2b7]=true,[0x2d7]=true,[0x2f7]=true}
function H.tallInside(s,t)
 if t<8 or t>=48 then return false end
 local inset=({[8]=5,[9]=3,[10]=2,[11]=1,[46]=1,[47]=3})[t]or 0
 return s>=inset and s<16-inset
end
local bars={}
for _,m in ipairs({0x221,0x259,0x281,0x2a1,0x2c1,0x2e1})do bars[m]='middle'end
for _,m in ipairs({0x22a,0x232,0x262,0x26a,0x28a,0x292,0x2aa,0x2b2,0x2ca,0x2d2,0x2ea,0x2f2})do bars[m]='left'end
for _,m in ipairs({0x228,0x230,0x260,0x268,0x288,0x290,0x2a8,0x2b0,0x2c8,0x2d0,0x2e8,0x2f0})do bars[m]='right'end
function H.column(m)return columns[m]or false end
function H.floorMid(m)
 if m<0x250 then return 0x23b elseif m<0x280 then return 0x273 elseif m<0x2a0 then return 0x29b
 elseif m<0x2c0 then return 0x2bb elseif m<0x2e0 then return 0x2db else return 0x2fb end
end
function H.barInside(m,s,t)
 local k=bars[m];if not k or t<8 or t>=16 then return false end
 if k=='left'then return s>=(t==15 and 4 or 3)end
 if k=='right'then return s<(t==15 and 12 or 13)end
 return true
end
local left={6,4,2,1,0,0,0,0,0,0,0,0,0,0,0,1}
local right={9,11,13,14,15,15,15,15,15,15,16,16,16,16,16,15}
function H.columnInside(s,t)return t>=13 and t<29 and s>=left[t-12]and s<right[t-12]end
function H.kind(d)
 local id=d and(d.id or d.name or'')
 if id=='EM_TRAINER_HILL_ELEVATOR'then return'lift'end
 if id:match('^EM_TRAINER_HILL_[1-4]F$')then return'floor'end
end
function H.profile(d)
 local k=H.kind(d);local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if not(k and c.enabled and c.trainerHill.enabled and d.mapType==8 and L)then return end
 if k=='floor'and d.pair=='building__trainer_hill'and L.width==16 and(L.height==21 or L.height==22)and L:midAt(0,0)==0x201
  or k=='lift'and d.pair=='building__battle_frontier'and L.width==6 and L.height==8 and L:midAt(0,0)==0x328 then return c.homeRooms[k=='lift'and'hillLift'or'hillFloor']end
end
function H.lighting(d)
 if H.profile(d)then local c=V.require('DioramaConfig').emeraldInteriors.trainerHill;return H.kind(d)=='lift'and c.liftLight or c.floorLight end
end
function H.plan(d)
 if not H.profile(d)then return end
 local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.trainerHill;local objects,mask={},{}
 local function add(o,x,y,w,h)o.x=x;o.y=y;o.w=w;o.h=h;o.noContact=true;objects[#objects+1]=o end
 if H.kind(d)=='lift'then
  for x=0,4 do add({kind='wall',wallCap=8,wallLast=48,wallBase=48,wallHeight=c.liftWallHeight},x,0,16,48)end
  for y=0,7 do for x=0,5 do if y<3 or L:midAt(x,y)==1 then mask[y*6+x+1]={mid=1,void=true}end end end
 else
  add({kind='hillFloor'},0,0,L.width*16,L.height*16)
  for k=1,L.width*L.height do mask[k]={mid=0x208,void=true}end
  for _,x in ipairs({0,1,2,3,11,12,13,14})do add({kind='hillRear',last=32,height=c.wallHeight},x,0,16,32)end
  for _,x in ipairs({4,10})do add({kind='hillSide'},x,0,16,48)end
  for _,x in ipairs({4,5,9,10})do add({kind='hillRear',last=32,height=c.wallHeight},x,3,16,32)end
  for x=6,8 do add({kind='hillRear',last=45,height=c.wallHeight*45/32},x,3,16,48)end
  for y=5,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
   if m==0x255 and L:midAt(x,y-1)==0x24d then add({kind='hillPartition'},x,y-1,16,32)
   elseif tall[m]then add({kind='hillTall',mid=m},x,y-2,16,48)
   elseif columns[m]then add({kind='hillColumn',mid=m},x,y-1,16,32)
   elseif bars[m]then add({kind='hillBar',mid=m},x,y,16,16)end
  end end
 end
 return objects,mask
end
local function wallPixel(s,t)
 local x,y=math.floor(s/16),math.floor(t/16)
 return y<2 and(x<=3 or x>=11 and x<=14)or y<3 and(x==4 or x==10)
  or y>=3 and y<5 and x>=4 and x<=10 or t>=80 and t<93 and x>=6 and x<=8
end
function H.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.trainerHill;local G=V.require('WorldGeometry')
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,point,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and inside(s,t)end,0,o.h,1,nil,point,.5)
  for _,v in ipairs(vv)do v[2]=v[2]*cfg.heightScale;out[#out+1]=v end
 end
 if o.kind=='hillFloor'then
  local erased={}
  for yy=5,L.height-1 do for xx=0,L.width-1 do local m=L:midAt(xx,yy)
   if tall[m]then for t=yy*16-24,yy*16+15 do for s=xx*16,xx*16+15 do erased[t*o.w+s]=H.floorMid(m)end end
   elseif columns[m]then for t=yy*16-3,yy*16+15 do for s=xx*16,xx*16+15 do erased[t*o.w+s]=H.floorMid(m)end end
   elseif bars[m]then for t=yy*16+8,yy*16+15 do for s=xx*16,xx*16+15 do erased[t*o.w+s]=H.floorMid(m)end end end
  end end
  draw(0,o.h,function(s,t)local m=L:midAt(math.floor(s/16),math.floor(t/16));return not wallPixel(s,t)and m~=0x208 and m~=0x24d and m~=0x255 end,
   function(s,t)return{x+s,0,z+t}end,function(s,t)return erased[t*o.w+s]or L:midAt(math.floor(s/16),math.floor(t/16)),s%16,t%16 end)
 elseif o.kind=='hillSide'then
  local left=o.x==4;local lo,hi=left and 0 or 8,left and 8 or 16
  -- Join the rear wall's row-two anchor to the front wall at row five.
  -- Close both faces; a single inner face left the outside as a black slit.
  draw(0,48,function(s)return s>=lo and s<hi end,function(s,t)return{x+s,c.wallHeight,z+32+t}end)
  local h=c.wallHeight*cfg.heightScale
  for _,edge in ipairs({x+lo,x+hi})do
   local vv=V.require('PaperSprite').build(ts,48,32,function(s,t)return t<16 and 0x201 or 0x209,s%16,t%16 end,
    function()return true end,0,32,1,nil,function(s,t)return{edge,h*(32-t)/32,z+32+s}end,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
  end
 elseif o.kind=='hillRear'then
  draw(0,o.last,function(s,t)local m,u,v=source(s,t);local r,g,b,a=V.require('BuildingMesh').pixel(ts,m,u,v);return a>.5 and r+g+b>0 end,
   function(s,t)return{x+s,o.height*(o.last-t)/o.last,z+o.last}end)
 elseif o.kind=='hillPartition'then
  draw(0,6,function()return true end,function(s,t)return{x+s,c.partitionHeight,z+26+t}end)
  draw(6,32,function()return true end,function(s,t)return{x+s,c.partitionHeight*(32-t)/26,z+32}end)
  for _,side in ipairs({0,16})do
   local nx=o.x+(side==0 and -1 or 1)
   if nx<0 or nx>=L.width or L:midAt(nx,o.y)~=0x24d then
    local u=side==0 and 0 or 15;local m=L:midAt(o.x,o.y)
    G.quad(out,{x+side,c.partitionHeight*cfg.heightScale,z+26},{x+side,c.partitionHeight*cfg.heightScale,z+32},{x+side,0,z+32},{x+side,0,z+26},G.uv(ts,m,u,6,u+1,16,.5),c.sideShade)
   end
  end
  if contacts then contacts[#contacts+1]={x+8,z+32,8,1,c.contactStrength}end
 elseif o.kind=='hillTall'then
  -- Native three-tile cylinder: elliptical cap, upright body and curved base.
  draw(8,21,H.tallInside,function(s,t)return{x+s,c.tallHeight,z+48-c.tallDepth+(t-8)*c.tallDepth/13}end)
  draw(21,48,H.tallInside,function(s,t)return{x+s,c.tallHeight*(48-t)/27,z+48}end)
  if contacts then contacts[#contacts+1]={x+8,z+48,7,2,c.contactStrength}end
 elseif o.kind=='hillColumn'then
  draw(13,22,H.columnInside,function(s,t)return{x+s,c.columnHeight,z+29-c.columnDepth+(t-13)*c.columnDepth/9}end)
  draw(22,29,H.columnInside,function(s,t)return{x+s,c.columnHeight*(29-t)/7,z+29}end)
  -- Close the exposed cutout contour with its original rim pixels.
  for t=22,28 do for s=0,15 do if H.columnInside(s,t)then
   local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
   local hi=c.columnHeight*(29-t)/7*cfg.heightScale;local lo=c.columnHeight*(28-t)/7*cfg.heightScale;local back=z+29-c.columnDepth
   if not H.columnInside(s-1,t)then G.quad(out,{x+s,hi,back},{x+s,hi,z+29},{x+s,lo,z+29},{x+s,lo,back},uv,c.sideShade)end
   if not H.columnInside(s+1,t)then G.quad(out,{x+s+1,hi,z+29},{x+s+1,hi,back},{x+s+1,lo,back},{x+s+1,lo,z+29},uv,c.sideShade)end
  end end end
  if contacts then contacts[#contacts+1]={x+8,z+29,7,2,c.contactStrength}end
 elseif o.kind=='hillBar'then
  local function inside(s,t)return H.barInside(o.mid,s,t)end
  draw(8,13,inside,function(s,t)return{x+s,c.barHeight,z+16-c.barDepth+(t-8)*c.barDepth/5}end)
  draw(13,16,inside,function(s,t)return{x+s,c.barHeight*(16-t)/3,z+16}end)
  local function occupied(s,t)
   local xx,yy=o.x+math.floor(s/16),o.y+math.floor(t/16)
   return xx>=0 and xx<L.width and yy>=0 and yy<L.height and H.barInside(L:midAt(xx,yy),s%16,t%16)
  end
  for t=13,15 do for s=0,15 do if inside(s,t)then
   local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local hi=c.barHeight*(16-t)/3*cfg.heightScale;local lo=c.barHeight*(15-t)/3*cfg.heightScale
   if not occupied(s-1,t)then G.quad(out,{x+s,hi,z+16-c.barDepth},{x+s,hi,z+16},{x+s,lo,z+16},{x+s,lo,z+16-c.barDepth},uv,c.sideShade)end
   if not occupied(s+1,t)then G.quad(out,{x+s+1,hi,z+16},{x+s+1,hi,z+16-c.barDepth},{x+s+1,lo,z+16-c.barDepth},{x+s+1,lo,z+16},uv,c.sideShade)end
  end end end
  if contacts then contacts[#contacts+1]={x+8,z+16,7,1,c.contactStrength}end
 end
end
return H
