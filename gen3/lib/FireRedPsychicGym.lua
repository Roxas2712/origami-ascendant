-- Saffron's nine native teleport rooms. Geometry never owns teleport routing.
local V=...;local R={}
local function cfg()return V.require('DioramaConfig').interiors.fireredPsychicGym end
function R.profile(d)
 local L=d and d.midLayout
 return cfg().enabled and d and d.id=='FR_SAFFRON_CITY_GYM'and (d.renderPair or d.pair)=='building__rom_082d4d64'and d.mapType==8 and L and L.width==30 and L.height==26 and L:midAt(14,8)==0x2a5 and L:midAt(14,12)==0x2aa or nil
end
function R.plan(d)
 if not R.profile(d)then return end
 local objects,mask={},{};for i=1,780 do mask[i]={mid=8,void=true,separateSurface=true}end
 local function add(kind,x,y,w,h,p)p=p or{};p.kind=kind;p.x=x;p.y=y;p.w=w;p.h=h;objects[#objects+1]=p end
 for _,y in ipairs{0,128,256}do for _,x in ipairs{0,160,320}do
  add('psychicFloor',x,y+32,144,96)
  add('psychicWall',x,y,144,32,{rear=y==0})
  for _,s in ipairs{16,112}do add('psychicPillar',x+s,y,16,35,{rear=y==0})end
 end end
 for _,x in ipairs{144,304}do add('psychicDivider',x,28,16,356)end
 for _,x in ipairs{192,256}do add('psychicStatue',x,304,16,32)end
 add('psychicExit',208,384,48,16);add('psychicCrest',224,125,16,18)
 return{objects=objects,mask=mask,owners={}}
end
function R.crestInside(s,t)local inset=({6,4,3,2,2,2,2,2,2,4,3,3,3,2,2,3,4,6})[t+1];return inset and s>=inset and s<16-inset or false end
function R.pillarInside(s,t)return t>=0 and t<35 and s>= (t==34 and 1 or 0)and s<(t==34 and 15 or 16)end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local G,P,B=V.require('WorldGeometry'),V.require('PaperSprite'),V.require('BuildingMesh');local hs=V.require('Billboard').heightScale()
 local function src(x,z)return L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16 end
 local function draw(w,h,source,inside,project,shade)
  local vv=P.build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 local function pillar(x)local s=x%160;return s>=16 and s<32 or s>=112 and s<128 end
 local function wallHeight(z)return (z<32 and c.wallHeight or c.partitionHeight)*hs end
 local function dividerHeight(z)
  if z%128<32 then return wallHeight(z)end
  return c.dividerHeight*hs
 end
 local function floorSource(x,z)
  if z%128>=32 and z%128<48 and pillar(x)then return 0x28a,x%16,z%16 end
  if z>=304 and z<336 and(x>=192 and x<208 or x>=256 and x<272)then return 0x281,x%16,z%16 end
  if x>=224 and x<240 and z>=125 and z<128 and R.crestInside(x-224,z-125)then return 0x281,x%16,z%16 end
  return src(x,z)
 end
 for _,o in ipairs(objects)do local first=#out+1
  local function source(s,t)return src(o.x+s,o.y+t)end
  if o.kind=='psychicFloor'then
   draw(o.w,o.h,function(s,t)return floorSource(o.x+s,o.y+t)end,nil,function(s,t)return{o.x+s,0,o.y+t}end)
  elseif o.kind=='psychicExit'then
   draw(o.w,o.h,source,function(s,t)local r,g,b=B.pixel(ts,source(s,t));return r+g+b>0 end,function(s,t)return{o.x+s,0,o.y+t}end)
  elseif o.kind=='psychicWall'then
   local height=wallHeight(o.y);local base=o.y+32
   local function wall(s,t)if pillar(o.x+s)or(o.y==128 and o.x+s>=224 and o.x+s<240)then return t<16 and 0x283 or 0x28b,s%16,t%16 end;return source(s,t)end
   draw(144,32,wall,nil,function(s,t)return{o.x+s,height*(32-t)/32,base}end)
   -- The inner cap slopes up from the preceding room's floor. A flat
   -- raised slab would cover its last teleporter row.
   local depth=o.rear and c.wallDepth or c.partitionDepth
   draw(144,1,function(s)if o.rear then return wall(s,0)end;return 0x283,s%16,1 end,nil,function(s,t)return{o.x+s,o.rear and height or height*t,base-depth+t*depth}end,o.rear and 1 or c.capShade)
   for _,edge in ipairs{0,144}do draw(1,32,function(_,t)return wall(math.min(143,edge),t)end,nil,function(s,t)return{o.x+edge,height*(32-t)/32*(o.rear and 1 or s),base-depth+s*depth}end,c.sideShade)end
  elseif o.kind=='psychicDivider'then
   -- Each constant-height section has its own closed shell. This connects the
   -- tall rear wall to lower room dividers without interpolated corner gaps.
   local start=0
   while start<o.h do local height=dividerHeight(o.y+start);local stop=start+1
    while stop<o.h and dividerHeight(o.y+stop)==height do stop=stop+1 end
    draw(16,stop-start,function(s,t)return source(s,start+t)end,nil,function(s,t)return{o.x+s,height,o.y+start+t}end)
    for _,edge in ipairs{0,16}do draw(stop-start,1,function(s)return source(math.min(15,edge),start+s)end,nil,function(s,t)return{o.x+edge,height*(1-t),o.y+start+s}end,c.sideShade)end
    for _,z in ipairs{start,stop}do draw(16,1,function(s)return source(s,math.min(o.h-1,z))end,nil,function(s,t)return{o.x+s,height*(1-t),o.y+z}end,c.sideShade)end
    start=stop
   end
  elseif o.kind=='psychicCrest'then
   draw(o.w,o.h,source,R.crestInside,function(s,t)return{o.x+s,c.crestBaseHeight+c.crestHeight*hs*(18-t)/18,160.02}end)
  else
   local column=o.kind=='psychicPillar';local height=column and wallHeight(o.y)*35/32 or c.statueHeight*hs;local base=o.y+o.h
   draw(o.w,o.h,source,column and R.pillarInside or function(s,t)return V.require('FireRedGymRooms').inside({kind='gymStatue',w=16,h=32},s,t)end,function(s,t)return{o.x+s,height*(o.h-t)/o.h,base}end)
   contacts[#contacts+1]={o.x+8+ox*16,base+oz*16,7,c.contactRadius,c.contactStrength}
  end
  V.require('RoomLightRig').capture(L,{kind=(o.kind=='psychicWall'or o.kind=='psychicDivider')and 'wall'or 'plant'},out,first,#out)
 end
end
function R.lighting(d)
 if not R.profile(d)then return end
 local c=cfg();local sources={}
 for _,z in ipairs{80,208,336}do for _,x in ipairs{72,232,392}do sources[#sources+1]={at={x,c.lightHeight,z},power=c.lightPower,radius=c.lightRadius,color=c.lightColor,spread=c.lightSpread}end end
 return{fixed=true,ambient=c.ambient,sources=sources}
end
return R
