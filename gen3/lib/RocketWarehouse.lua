-- Native Five Island storage: retain the puzzle grid, fold only complete
-- crate/pallet drawings. This is not a collision-driven solid-tile extrusion.
local V=...;local W={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.rocketWarehouse end
function W.profile(d)
 return d and d.id=='FR_FIVE_ISLAND_ROCKET_WAREHOUSE'and cfg().enabled and V.require('RocketRoomShell').profile(d)
end
function W.plan(d,objects,mask)
 local L=d.midLayout;if L then W.rooms[L]=nil end
 if not W.profile(d)then return end
 local owned,seen={},{};W.rooms[L]=owned
 local function mid(x,y)if x<0 or y<0 or x>=L.width or y>=L.height then return end;return L:midAt(x,y)end
 local function add(kind,x,y,w,h,front)
  local rearPallet=kind=='warehousePallet'and L:midAt(x,y)==0x3f2
  local o={kind=kind,x=x,y=y,w=w,h=h,front=front,back=rearPallet and 16 or 0,depth=rearPallet and 30 or front};owned[#owned+1]=o;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1
   local old=mask[k];mask[k]={mid=0x281,void=type(old)=='table'and old.void,separateSurface=true};seen[k]=true
  end end
  -- Remove only baked floor shadow tiles adjoining this source drawing.
  for yy=y,y+h do if yy<L.height and x+w<L.width then local m=mid(x+w,yy)
   if m==0x283 or m==0x284 then mask[yy*L.width+x+w+1]={mid=0x281,separateSurface=true}end
  end end
 end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=mid(x,y)
  if not seen[y*L.width+x+1]then
   if m==0x395 or m==0x99 then
    local h=0;while mid(x,y+h)==0x395 do h=h+1 end
    if mid(x,y+h)==0x99 then add('warehouseBoxes',x,y,1,h+1,h*16+8)end
   elseif (m==0x3f0 or m==0x3f2)and mid(x+1,y)==m+1 and mid(x,y+1)==0x3f8 and mid(x+1,y+1)==0x3f9 then
    add('warehousePallet',x,y,2,2,18)
   end
  end
  -- The entrance threshold remains the original flat door/rug art.
  if m>=0x3e0 and m<=0x3e2 or m>=0x1a and m<=0x1c then mask[y*L.width+x+1]={mid=m,separateSurface=true}end
 end end
end
function W.build(out,objects,L,ts,ox,oz,contacts)
 if not W.rooms[L]then return end
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local c=cfg()
 for _,o in ipairs(W.rooms[L])do
  local x,z=(o.x+ox)*16,(o.y+oz)*16;local width,height=o.w*16,o.h*16
  local h=o.kind=='warehouseBoxes'and c.boxHeight or c.palletHeight
  local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local function band(a,b,project)
   local vv=P.build(ts,width,height,src,function(s,t)return t>=a and t<b end,0,height,1,nil,project,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
  end
  local function depth(t)return z+o.back+t*(o.depth-o.back)/o.front end
  band(0,o.front,function(s,t)return{x+s,h,depth(t)}end)
  band(o.front,height,function(s,t)return{x+s,h*(height-t)/(height-o.front),z+o.depth}end)
  for _,sx in ipairs{0,width-1}do for t=0,o.front-1 do
   local m,u,v=src(sx,t);local xx=x+(sx==0 and 0 or width)
   G.quad(out,{xx,h,depth(t)},{xx,h,depth(t+1)},{xx,0,depth(t+1)},{xx,0,depth(t)},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)
  end end
  for s=0,width-1 do local m,u,v=src(s,0)
   G.quad(out,{x+s+1,h,depth(0)},{x+s,h,depth(0)},{x+s,0,depth(0)},{x+s+1,0,depth(0)},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)
  end
  for s=5,width-2,8 do contacts[#contacts+1]={x+s,z+o.depth,5,c.contactRadius,c.contactStrength}end
 end
end
-- The native pickup is on the floor behind the box; never inherit box height.
function W.actorOffset(d,px,pz,gid)
 if gid~=92 or not W.profile(d)then return end
 for _,o in ipairs(W.rooms[d.midLayout]or{})do
  if o.kind=='warehouseBoxes'and math.floor((px+8)/16)==o.x and math.abs(pz-o.y*16)<.01 then return 0,-cfg().itemInset end
 end
end
return W
