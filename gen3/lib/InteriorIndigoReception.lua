-- Measured native Indigo reception: the offset rear wall is not a standard
-- Center translated as one cutout. Keep floor emblems and each device separate.
local V=...;local I={}
function I.profile(d)
 local p=V.require('DioramaConfig').interiors.indigoReception;local L=d and d.midLayout
 if p.enabled and d and (d.id or d.name)=='FR_INDIGO_PLATEAU_POKEMON_CENTER_1F'
  and d.pair=='network' and L and L.width==26 and L.height==18
  and L:midAt(10,10)==0x2b1 and L:midAt(11,9)==0x2aa and L:midAt(4,1)==0x33b then return p end
end
function I.plan(d)
 if not I.profile(d)then return end
 local L=d.midLayout;local objects,mask,owners={},{},{}
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;if not(type(mask[k])=="table" and mask[k].void)then mask[k]=donor or 0x281 end;owners[k]=o end end
  return o
 end
 for x=1,7 do add({kind='wall',x=x,y=0,clear=x==2 or x==6,wallSource={0x284,0x28c}},x,0,1,2,{mid=0,void=true})end
 for _,x in ipairs({0,8})do add({kind='wallCorner',x=x,y=0,right=x==8},x,0,1,3,{mid=0,void=true})end
 for x=11,23 do add({kind='wall',x=x,y=8,clear=x==11 or x==12 or x==15 or x==16 or x==17 or x==22 or x==23,
  wallSource={0x284,0x28c}},x,8,1,2,{mid=0,void=true})end
 add({kind='indigoWallJoin',x=9,y=6,w=2},9,6,2,4,{mid=0,void=true})
 add({kind='wallCorner',x=24,y=8,right=true},24,8,1,3,{mid=0,void=true})
 local function panel(x,y,w,h,front,base)
  return add({kind='panel',x=x,y=y,w=w,last=h,front=front or h,base=base or 0,contour=true,
   background={0x281,0x284,0x28c,0x2b7}},x,y,w,math.ceil(h/16))
 end
 for _,x in ipairs({2,6})do panel(x,0,1,48,48)end
 panel(11,9,2,28,28)
 add({kind='panel',x=15,y=9,w=2,cap=0,split=10,last=25,depth=12,front=30,base=11,
  sideMid=0x2ad,sideX=2,sideY=9},15,9,2,2)
 add({kind='counter',x=10,y=10,w=7},10,10,7,2)
 add({kind='panel',x=17,y=8,w=1,cap=12,split=18,last=39,depth=9,front=43,base=0,sideMid=0x62,sideX=1,sideY=6},17,8,1,3)
 add({kind='panel',x=22,y=8,w=2,cap=11,split=16,last=39,depth=12,front=42,base=0,sideMid=0x2cb,sideX=1,sideY=6},22,8,2,3)
 add({kind='indigoSideCounter',x=0,y=5,w=3,h=5,front=80},0,5,3,5)
 for y=3,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if m==0x300 and L:midAt(x,y+1)==0x301 then
   add({kind='plant',x=x,y=y+1,ground=0x281},x,y,1,2)
  elseif m==0x29c and L:midAt(x+1,y)==0x29d then
   add({kind='roundtable',x=x,y=y},x,y,2,2)
  elseif m==0x2f5 or m==0x2fd then add({kind='stool',x=x,y=y},x,y,1,1)
  elseif m==0x2d0 and L:midAt(x+1,y)==0x2d1 then add({kind='escalator',x=x,y=y},x,y,2,3)end
 end end
 return {objects=objects,mask=mask,owners=owners}
end
function I.wallJoin(N,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry')
 for sx=0,31 do
  local offset=math.min(14+sx,32);local nextOffset=math.min(15+sx,32)
  for sy=0,31 do
   local ty=sy+offset;local m=L:midAt(o.x+math.floor(sx/16),o.y+math.floor(ty/16))
   G.quad(out,{x+sx,32-sy,z+32+offset},{x+sx+1,32-sy,z+32+nextOffset},
    {x+sx+1,31-sy,z+32+nextOffset},{x+sx,31-sy,z+32+offset},G.uv(ts,m,sx%16,ty%16,sx%16+1,ty%16+1,.5),1)
  end
  for sy=32+offset,63 do
   G.quad(out,{x+sx,0,z+sy},{x+sx+1,0,z+sy},{x+sx+1,0,z+sy+1},{x+sx,0,z+sy+1},
    G.uv(ts,0x281,sx%16,sy%16,sx%16+1,sy%16+1,.5),1)
  end
 end
end
function I.sideCounter(N,out,L,ts,o,x,z)
 local h=V.require('DioramaConfig').interiors.indigoReception.sideCounterHeight
 local source,inside=N.nativeMask(L,ts,o,48,80,{0x281,0x2b7},{})
 -- Preserve the native L-shaped plan and its clerk opening; no bounding box
 -- fills the walkable hollow. Pixel edges form the shallow opaque thickness.
 local G=V.require('WorldGeometry')
 for sy=0,79 do for sx=0,47 do if inside(sx,sy)then
  local m,u,v=source(sx,sy);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
  local xx,zz=x+sx,z+sy
  G.quad(out,{xx,h,zz},{xx+1,h,zz},{xx+1,h,zz+1},{xx,h,zz+1},uv,1)
  if not inside(sx,sy+1)then G.quad(out,{xx,h,zz+1},{xx+1,h,zz+1},{xx+1,0,zz+1},{xx,0,zz+1},uv,.85)end
  if not inside(sx-1,sy)then G.quad(out,{xx,h,zz},{xx,h,zz+1},{xx,0,zz+1},{xx,0,zz},uv,.9)end
  if not inside(sx+1,sy)then G.quad(out,{xx+1,h,zz+1},{xx+1,h,zz},{xx+1,0,zz},{xx+1,0,zz+1},uv,.9)end
 end end end
end
return I
