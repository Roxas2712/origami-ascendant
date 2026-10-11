-- Laboratory objects are measured independently, including adjacent cabinets.
-- Native tile cells and events are read only; mask is a rendering floor donor.
local V=...
local M={}
-- The narrow, 28-tile corridor needs local tracking at its three doorways.
function M.cameraFollow(def)
 local L=def and def.midLayout
 if not L or def.pair~='oak_lab' or (def.id or def.name)~='FR_CINNABAR_ISLAND_POKEMON_LAB_ENTRANCE'
  or L.width~=28 or L.height~=12 then return end
 local p=V.require('IndoorSurfaces').profile(def);if not p then return end
 for _,x in ipairs({13,19,25})do if L:midAt(x,4)~=0x2bd then return end end
 return p.follow
end
function M.plan(def)
 if def.pair~='oak_lab' or not V.require('IndoorSurfaces').profile(def)then return end
 local L=def.midLayout;local oak=(def.id or def.name)=='FR_OAKS_LAB'
 local floor=oak and 0x289 or 0x81
 local objects,mask,owners={},{},{}
 local function add(o,x,y,w,h,donor)
  objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1;mask[k]=donor or floor;owners[k]=o
  end end
  return o
 end
 local function fold(x,y,w,cap,split,last,height,depth,front)
  return add({kind='labFold',x=x,y=y,w=w,cap=cap,split=split,last=last,
   height=height,depth=depth,front=front or last,ground=floor,
   background={floor,oak and 0x281 or 0x79,0x69,0x71}},x,y,w,math.ceil(last/16))
 end
 local function stand(x,y,w,h,first,last,front,base,bg)
  return add({kind='standing',x=x,y=y,w=w,sy=first,pixelH=last-first,
   front=front or last,base=base or 0,background=bg or {floor,0x69,0x71,oak and 0x281 or 0x79}},x,y,w,h)
 end
 local function clearWall(x,w,y)
  for _,o in ipairs(objects)do if o.kind=='wall' and o.y==(y or 0) and o.x>=x and o.x<x+w then
   o.clear=true;o.wallSource={0x69,0x71}
  end end
 end
 -- Wall baselines may step down along the Cinnabar corridor. Recognize the
 -- source upper band, never reinterpret furniture rows as another wall.
 local wallTop={[0x68]=true,[0x69]=true,[0x6a]=true,[0x314]=true,[0x315]=true,[0x316]=true,[0x324]=true,[0x2bd]=true,[0x2be]=true}
 for y=0,L.height-3 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if y==0 and m~=0 and m~=8 or y==4 and wallTop[m] then
   add({kind='wall',x=x,y=y},x,y,1,2,{mid=0,void=true})
  end
 end end
 if oak then
  fold(0,0,1,10,16,40,24,8,40);fold(1,1,1,0,7,24,17,8,24);clearWall(0,2)
  -- Rear computer and empty writing desk have separate tabletops/devices.
  for _,x in ipairs({2,4})do
   local o=fold(x,1,2,5,16,24,10,16,24)
   if x==2 then o.computer=true end
   clearWall(x,2)
  end
  for _,x in ipairs({9,11})do fold(x,0,2,10,20,40,24,10,40);clearWall(x,2)end
  for _,r in ipairs({{0,7,5},{8,7,5}})do fold(r[1],r[2],r[3],10,20,40,24,10,40)end
  local machine=stand(1,3,2,3,4,48,46)
  machine.kind='panel';machine.contour=true;machine.last=48;machine.base=0;machine.front=46
  machine.background={floor};machine.backgroundPixels={{0x2a3,0,0}}
  fold(8,4,3,3,20,25,10,20,26)
  for y=3,4 do fold(0,y,1,0,8,16,8,9,16)end
 end
 for y=1,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if (oak and (m==0x29b or m==0x29c)) or (not oak and m==0x94 and L:midAt(x,y-1)==0x8c)then
   add({kind='plant',x=x,y=y,ground=floor,bg={0x69,0x71,0x79},labPot=true},x,y-1,1,2)
  elseif not oak then
   if y==1 and (m==0x73 or m==0x301) and (L:midAt(x+1,y)==0x74 or L:midAt(x+1,y)==0x302)then
    fold(x,0,2,10,20,40,24,10,40);clearWall(x,2)
   elseif y==1 and m==0x62 then
    fold(x,0,1,9,15,40,26,8,40);clearWall(x,1)
   elseif y==1 and m==0x75 then
    local o=fold(x,1,2,5,16,24,10,16,24);o.computer=true;clearWall(x,2)
   elseif y==1 and m==0x320 then
    fold(x,0,3,12,17,40,26,8,40);clearWall(x,3)
   elseif y==1 and m==0x31b then
    fold(x,0,1,12,17,40,24,8,40);clearWall(x,1)
   elseif y==1 and m==0x2c0 then
    local o=stand(x,0,2,3,8,48,46);o.kind='panel';o.contour=true;o.last=48;o.front=46
    clearWall(x,2)
   elseif m==0x2cb or m==0x2f3 or m==0x30c or m==0x310 then
    local o=fold(x,y,1,0,9,16,7,10,15)
    if m==0x2f3 then
     o.y=y-1;o.cap=0;o.split=9;o.last=17;o.front=17;o.depth=10
     for yy=y-1,y do local k=yy*L.width+x+1;mask[k]={mid=0x2f8,x0=0,y0=0,x1=1,y1=1};owners[k]=o end
    end
   elseif m==0x6f and L:midAt(x+1,y)==0x8f then
    local o=fold(x,y,2,5,48,55,12,42,55);o.bench=true
   elseif m==0x305 and L:midAt(x+1,y)==0x306 then
    local o=fold(x,y,3,12,26,32,11,17,32);o.workstation=true
   elseif (m==0x2e0 or m==0x2fd) and L:midAt(x+1,y)~=(0)then
    local o=m==0x2fd and fold(x,y,3,12,56,64,11,44,64) or fold(x,y,3,5,42,48,11,37,48)
    if m==0x2fd then o.looseDevice=true end
    if m==0x2e0 then o.ground=0x2f8;o.background={0x2f8};for yy=y,y+2 do for xx=x,x+2 do mask[yy*L.width+xx+1]={mid=0x2f8,x0=0,y0=0,x1=1,y1=1} end end end
   elseif m==0x2c8 and L:midAt(x+1,y)==0x2c9 then
    fold(x,y,2,0,27,32,10,24,32)
   elseif m==0x2ca or m==0x2d2 then
    fold(x,y,1,0,11,16,7,11,16)
   elseif m==0x2cc then
    local o=fold(x,y,2,12,69,80,11,63,80);o.reception=true
   elseif m==0x99 then
    fold(x,y,1,0,10,16,10,10,16)
   elseif m==0x2fb and L:midAt(x+1,y)==0x2fc then
    fold(x,y,2,0,17,40,24,14,40)
   elseif y==1 and m==0x31f then
    stand(x,y,1,2,0,24,24);clearWall(x,1)
   elseif m==0x2e5 or m==0x2e4 then
    fold(x,y,1,0,26,40,11,28,40)
   end
  end
 end end
 return {objects=objects,mask=mask,owners=owners}
end
return M
