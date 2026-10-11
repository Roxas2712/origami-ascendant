-- Native FR/LG link-service hall. Keep each service desk, terminal and
-- architectural return independent: adjacency in the map is not an object.
local V=...
local N={}
function N.plan(def)
 local p=V.require('IndoorSurfaces').profile(def)
 if not p or p~=V.require('DioramaConfig').interiors.centerUpstairs then return nil end
 local L=def.midLayout;local objects,mask,owners={},{},{}
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1
   -- A foreground pilaster must not put a floor tile back behind the wall.
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=donor or 0x281 end;owners[k]=o
  end end
  return o
 end
 local function rect(x,y,w,h,o)return add(o,x,y,w,h)end
 for x=1,13 do
  add({kind='wall',x=x,y=0,clear=x==3 or x==8 or x==12 or x==13,
   wallSource={0x284,0x28c}},x,0,1,2,{mid=0,void=true})
 end
 for _,x in ipairs({0,14})do
  add({kind='wallCorner',x=x,y=0,right=x==14},x,0,1,3,{mid=0,void=true})
 end
 -- The wall's two white pilasters stop at their original feet. In
 -- particular the left one must not include the separate PC beneath it.
 for _,spec in ipairs({{3,43},{13,62}})do
  rect(spec[1],0,1,math.ceil(spec[2]/16),{kind='standing',x=spec[1],y=0,w=1,
   sy=8,pixelH=spec[2]-8,left=2,right=14,front=spec[2],depth=3})
 end
 local function panel(x,w,cap,split,last,depth,front,height)
  return rect(x,2,w,math.ceil(last/16),{kind='panel',x=x,y=2,w=w,cap=cap,split=split,
   last=last,depth=depth,front=front,height=height,base=0,sideMid=0x2e9,sideX=6,sideY=4})
 end
 for _,range in ipairs({{0,3},{4,1},{6,2},{10,2}})do panel(range[1],range[2],12,25,32,19,32,10)end
 -- Low connecting gates are deliberately lower than the red service top.
 for _,x in ipairs({5,9})do panel(x,1,16,20,30,9,30,6)end
 panel(3,1,10,18,40,12,40,22)
 for _,x in ipairs({8,12})do
  panel(x,1,13,17,36,12,35,19)
  rect(x,1,1,1,{kind='standing',x=x,y=1,w=1,sy=3,pixelH=26,front=48,base=19,
   backgroundPixels={{0x2fe,0,0},{0x2fe,0,5},{0x2fe,0,7}}})
 end
 rect(14,5,1,2,{kind='panel',x=14,y=5,w=1,last=32,front=32,base=0,contour=true,background={0x281}})
 rect(0,5,2,3,{kind='escalator',x=0,y=5,reverse=true})
 for y=4,L.height-1 do for x=0,L.width-1 do
  local mid=L:midAt(x,y)
  if mid==0x300 and L:midAt(x,y+1)==0x301 then
   rect(x,y,1,2,{kind='plant',x=x,y=y+1,ground=0x281})
  elseif mid==0x2f5 or mid==0x2fd then
   rect(x,y,1,1,{kind='stool',x=x,y=y})
  end
 end end
 return {objects=objects,mask=mask,owners=owners}
end
return N
