-- The native bent return passage, including its three separate rear walls.
local V=...
local T={}
function T.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.trickCorridor.enabled and(d.id or d.name)=='EM_ROUTE110_TRICK_HOUSE_CORRIDOR'
  and d.mapType==8 and d.pair=='building__generic_building'and L and L.width==16 and L.height==24
  and L:midAt(3,0)==0x2e3 and L:midAt(0,6)==0x2e3 and L:midAt(3,20)==0x2e3 then
  return c.homeRooms.trickCorridor
 end
end
function T.lighting(d)
 if T.profile(d)then return V.require('DioramaConfig').emeraldInteriors.trickCorridor.lighting end
end
function T.plan(d)
 if not T.profile(d)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.trickCorridor
 local L=d.midLayout;local objects,mask={},{}
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if m==0x201 then mask[y*L.width+x+1]={mid=m,void=true}end
  if(m==0x215 and L:midAt(x,y+1)==0x21d)
   or(m==0x2e3 and L:midAt(x,y+1)==0x2eb)
   or(m==0x2e4 and L:midAt(x,y+1)==0x2ec)then
   objects[#objects+1]={kind='wall',x=x,y=y,w=16,h=32,wallHeight=c.wallHeight,wallBase=32,wallLast=32,
    clean=m~=0x215 and{0x215,0x21d}or nil}
   for yy=y,y+1 do mask[yy*L.width+x+1]={mid=0x201,void=true}end
   if m~=0x215 then
    objects[#objects+1]={kind='card',x=x,y=y,w=16,h=48,cap=0,last=38,front=32.25,height=c.pillarHeight,
     opaque=true,bounds=m==0x2e3 and{0,7}or{9,16}}
    mask[(y+2)*L.width+x+1]=m==0x2e3 and 0x221 or 0x229
   end
  end
 end end
 return objects,mask
end
return T
