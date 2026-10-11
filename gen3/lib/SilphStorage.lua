-- Native storage drawings share cells: rack fronts can overlap box tops.
local V=...;local S={rooms=setmetatable({},{__mode="k"})}
local function cfg()return V.require('DioramaConfig').interiors.silphStorage end
function S.profile(d)return cfg().enabled and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4ecc'and(d.id or d.name or''):match('^FR_SILPH_CO_%d+F$')and d.midLayout end
function S.plan(d,objects,mask)
 local L=d.midLayout;if L then S.rooms[L]=nil end
 if not S.profile(d)then return end;local boxes,rackCells,owned={},{},{};S.rooms[L]=owned
 local function mid(x,y)if x<0 or y<0 or x>=L.width or y>=L.height then return -1 end;return L:midAt(x,y)end
 local function claim(x,y)mask[y*L.width+x+1]={mid=0x334,separateSurface=true}end
 local function add(o)
  objects[#objects+1]=o;owned[#owned+1]=o
  for y=o.y,o.y+o.h-1 do for x=o.x,o.x+o.w-1 do claim(x,y)end end
  for y=o.y,o.y+o.h do local m=mid(o.x+o.w,y);if m==0x336 or m==0x357 then claim(o.x+o.w,y)end end
  for x=o.x,o.x+o.w-1 do local m=mid(x,o.y+o.h);if m==0x33b or m==0x33d or m==0x33c then claim(x,o.y+o.h)end end
 end
 for y=0,L.height-1 do for x=0,L.width-1 do
  if mid(x,y)==0x310 and mid(x+1,y)==0x311 and not(mid(x,y-1)==0x310 and mid(x+1,y-1)==0x311)then
   local h=1;while mid(x,y+h)==0x310 and mid(x+1,y+h)==0x311 do h=h+1 end
   local a,b=mid(x,y+h),mid(x+1,y+h)
   if (a==0x318 or a==0x393)and(b==0x319 or b==0x394)then
    for yy=y,y+h do for dx=0,1 do rackCells[yy*L.width+x+dx+1]=true end end
    add({kind='silphRack',x=x,y=y,w=2,h=h+1,front=h*16,leftEnd=a==0x393 and 8 or 16,rightEnd=b==0x394 and 8 or 16})
   end
  end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=mid(x,y);local k=y*L.width+x+1
  if not boxes[k]and(m==0x99 or m==0x395 or (m==0x393 or m==0x394)and rackCells[k])then
   local start=(m==0x393 or m==0x394)and 8 or 0;local h=1
   while mid(x,y+h)==0x395 do h=h+1 end
   local last=mid(x,y+h);local front=h*16;local hidden=false
   if last==0x392 then h=h+1
   elseif m==0x99 and h==1 then front=8
   elseif (last==0x310 or last==0x311)and rackCells[(y+h)*L.width+x+1]then hidden=true
   else h=nil end
   if h then
    -- A standalone box includes its native top and front in one tile.
    if m==0x99 then front=8 end
    add({kind='silphBoxes',x=x,y=y,w=1,h=h,start=start,front=front,hiddenFront=hidden})
    for yy=y,y+h-1 do boxes[yy*L.width+x+1]=true end
   end
  end
 end end
end
function S.build(out,objects,L,ts,ox,oz,contacts)
 if not cfg().enabled then return end;local c=cfg();local G=V.require('WorldGeometry');local P=V.require('PaperSprite')
 for _,o in ipairs(objects)do if o.kind=='silphRack'or o.kind=='silphBoxes'then
  local x,z=(o.x+ox)*16,(o.y+oz)*16;local W,H=o.w*16,o.h*16
  local height=o.kind=='silphRack'and c.rackHeight or c.boxHeight
  local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local function band(first,last,project,filter)
   local vv=P.build(ts,W,H,src,function(s,t)return t>=first and t<last and(not filter or filter(s,t))end,0,H,1,nil,project,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
  end
  local front=o.front;local start=o.start or 0;local depth=front+(o.kind=='silphRack'and c.rackFrontInset or 0)
  band(start,front,function(s,t)return{x+s,height,z+start+(t-start)*(depth-start)/(front-start)}end)
  if not o.hiddenFront then
   band(front,H,function(s,t)return{x+s,height*(H-t)/(H-front),z+depth}end,
    o.kind=='silphRack'and function(s,t)return t<front+(s<16 and o.leftEnd or o.rightEnd)end or nil)
  end
  -- Native edge texels close each long top, never a rectangle over its aisle.
  for _,sx in ipairs({0,W-1})do for t=start,front-1 do
   local m,u,v=src(sx,t);local a=z+start+(t-start)*(depth-start)/(front-start);local b=z+start+(t+1-start)*(depth-start)/(front-start);local xx=x+(sx==0 and 0 or W)
   G.quad(out,{xx,height,a},{xx,height,b},{xx,0,b},{xx,0,a},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)
  end end
  for sx=5,W-2,8 do contacts[#contacts+1]={x+sx,z+depth,5,c.contactRadius,c.contactStrength}end
 end end
end
-- FireRed graphics 92 is the native pickup ball. Its small drawing belongs
-- inside its floor cell, not on the rear edge of the raised box in front.
function S.actorOffset(d,px,pz,gid)
 if gid~=92 or not d or not S.profile(d)then return end
 for _,o in ipairs(S.rooms[d.midLayout]or{})do
  if o.kind=='silphBoxes'and px>=o.x*16 and px<(o.x+o.w)*16 and math.abs(pz-o.y*16)<.01 then return 0,-cfg().itemInset end
 end
end
return S
