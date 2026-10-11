-- Cinnabar's native quiz room: independent devices and closed room shells.
-- All gates are derived from live metatiles; scripts/collision remain native.
local V=...;local R={}
local machines={{16,16},{128,16},{240,16},{16,144},{208,144},{352,144},{208,256},{16,272}}
local function cfg()return V.require('DioramaConfig').interiors.fireredFireGym end
function R.profile(d)
 local L=d and d.midLayout
 return cfg().enabled and d and d.id=='FR_CINNABAR_ISLAND_GYM'and (d.renderPair or d.pair)=='building__rom_082d4d7c'and d.mapType==8 and L and L.width==30 and L.height==26 and L:midAt(11,10)==0x2cc and L:midAt(5,4)==0x2b2 or nil
end
function R.machineInside(s,t)
 if s<0 or s>=32 or t<0 or t>=32 then return false end
 local lo,hi=0,24
 if t==0 then lo,hi=8,16 elseif t==1 then lo,hi=7,17 elseif t==2 then lo,hi=6,18 elseif t==3 then lo,hi=1,23 end
 if s>=lo and s<hi then return true end
 -- The handset's rounded ends are independent of the machine body.
 if t==10 then return s>=26 and s<30 elseif t>=11 and t<=25 then return s>=25 and s<31
 elseif t==26 then return s>=24 and s<30 elseif t==27 then return s>=24 and s<29 end
 return false
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{};for i=1,780 do mask[i]={mid=8,void=true,separateSurface=true}end
 local function add(kind,x,y,w,h,p)p=p or{};p.kind=kind;p.x=x;p.y=y;p.w=w;p.h=h;objects[#objects+1]=p end
 add('fireFloor',0,0,480,400)
 add('fireRear',16,0,448,32)
 for _,x in ipairs{0,464}do add('fireDivider',x,14,16,370)end
 add('fireDivider',336,78,16,306)
 -- Each cross-wall is split around its two-tile native quiz gate.
 for _,a in ipairs{{16,160,160,80},{208,336,160,272},{352,464,160,416},{208,336,272,272},{16,160,288,80}}do
  local x,last,base,gate=unpack(a)
  add('firePartition',x,base-35,gate-x,35)
  add('firePartition',gate+32,base-35,last-gate-32,35)
  if L:midAt(gate/16,base/16-1)==0x2a5 then add('fireGate',gate,base-32,32,32)end
 end
 add('firePartition',352,221,64,35)
 add('firePipe',160,14,48,338)
 -- The narrow final barrier extends beyond the pipe housing. Its native
 -- script removes only the floor extension, not the orange housing panel.
 if L:midAt(11,22)==0x29f then add('fireEndGate',179,352,10,32)end
 for _,a in ipairs(machines)do add('fireMachine',a[1],a[2],32,32)end
 for _,x in ipairs{368,432}do add('fireStatue',x,304,16,32)end
 return{objects=objects,mask=mask,owners={}}
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local P,B,G=V.require('PaperSprite'),V.require('BuildingMesh'),V.require('WorldGeometry');local hs=V.require('Billboard').heightScale()
 local function src(x,z)return L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16 end
 local function clean(x,z)
  for _,a in ipairs(machines)do if x>=a[1]and x<a[1]+32 and z>=a[2]and z<a[2]+32 then
   local t=z-a[2]
   if t<16 then return a[2]==16 and 0x28b or 0x2a2,x%16,z%16 end
   -- The floor behind every quiz device uses the native shaded floor tile.
   return 0x289,x%16,z%16
  end end
  if z>=304 and z<352 and(x>=368 and x<400 or x>=432 and x<464)then return 0x281,x%16,z%16 end
  if x>=176 and x<192 and z>=352 and z<384 and L:midAt(11,22)==0x29f then return 0x281,x%16,z%16 end
  return src(x,z)
 end
 local function draw(w,h,source,inside,project,shade)
  local vv=P.build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 local function contains(o,x,z)return x>=o.x and x<o.x+o.w and z>=o.y and z<o.y+o.h end
 local solids={};for _,o in ipairs(objects)do if o.kind~='fireFloor'and o.kind~='fireMachine'and o.kind~='fireStatue'then solids[#solids+1]=o end end
 for _,o in ipairs(objects)do local first=#out+1
  local function source(s,t)return src(o.x+s,o.y+t)end
  local function cleaned(s,t)return clean(o.x+s,o.y+t)end
  local base=o.y+o.h
  if o.kind=='fireFloor'then
   draw(o.w,o.h,clean,function(x,z)
    for _,a in ipairs(solids)do if contains(a,x,z)then return false end end
    local r,g,b=B.pixel(ts,clean(x,z));return r+g+b>0
   end,function(s,t)return{s,0,t}end)
  elseif o.kind=='fireRear'then
   local height=c.wallHeight*hs
   local function wall(s,t)local x=o.x+s;if x>=160 and x<208 then return t<16 and 0x283 or 0x28b,x%16,t%16 end;return cleaned(s,t)end
   draw(o.w,32,wall,nil,function(s,t)return{o.x+s,height*(32-t)/32,32}end)
   draw(o.w,1,function(s)return wall(s,0)end,nil,function(s,t)return{o.x+s,height,32-c.wallDepth+t*c.wallDepth}end)
   for _,edge in ipairs{0,o.w}do draw(1,32,function(_,t)return wall(math.min(o.w-1,edge),t)end,nil,function(s,t)return{o.x+edge,height*(32-t)/32,32-c.wallDepth+s*c.wallDepth}end,c.sideShade)end
  elseif o.kind=='fireMachine'or o.kind=='fireStatue'then
   local machine=o.kind=='fireMachine';local height=(machine and c.machineHeight or c.statueHeight)*hs
   local inside=machine and R.machineInside or function(s,t)return V.require('FireRedGymRooms').inside({kind='gymStatue',w=16,h=32},s,t)end
   draw(o.w,32,source,inside,function(s,t)return{o.x+s,height*(32-t)/32,base}end)
   -- Extrude only contour texels, never the source background rectangle.
   if machine then for t=0,31 do for s=0,31 do if inside(s,t)then
    local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local x,z=o.x+s+ox*16,base+oz*16;local h0,h1=height*(32-t)/32,height*(31-t)/32
    if not inside(s-1,t)then G.quad(out,{x,h0,z-c.machineDepth},{x,h0,z},{x,h1,z},{x,h1,z-c.machineDepth},uv,c.sideShade)end
    if not inside(s+1,t)then G.quad(out,{x+1,h0,z},{x+1,h0,z-c.machineDepth},{x+1,h1,z-c.machineDepth},{x+1,h1,z},uv,c.sideShade)end
    if not inside(s,t-1)then G.quad(out,{x,h0,z-c.machineDepth},{x+1,h0,z-c.machineDepth},{x+1,h0,z},{x,h0,z},uv)end
   end end end end
   contacts[#contacts+1]={o.x+(machine and 12 or 8)+ox*16,base+oz*16,machine and 11 or 7,c.contactRadius,c.contactStrength}
  elseif o.kind=='firePartition'or o.kind=='fireGate'then
   local height=c.partitionHeight*hs;local split=o.h-16
   draw(o.w,16,function(s,t)return cleaned(s,split+t)end,nil,function(s,t)return{o.x+s,height*(16-t)/16,base}end)
   draw(o.w,split,cleaned,nil,function(s,t)return{o.x+s,height,o.y+t*o.h/split}end)
   for _,edge in ipairs{0,o.w}do draw(1,16,function(_,t)return cleaned(math.min(o.w-1,edge),split+t)end,nil,function(s,t)return{o.x+edge,height*(16-t)/16,o.y+s*o.h}end,c.sideShade)end
  elseif o.kind=='fireDivider'then
   local height=c.dividerHeight*hs
   draw(o.w,o.h,source,nil,function(s,t)return{o.x+s,height,o.y+t}end)
   for _,edge in ipairs{0,o.w}do draw(o.h,1,function(s)return source(math.min(o.w-1,edge),s)end,nil,function(s,t)return{o.x+edge,height*(1-t),o.y+s}end,c.sideShade)end
   draw(o.w,1,function(s)return source(s,o.h-1)end,nil,function(s,t)return{o.x+s,height*(1-t),base}end,c.sideShade)
  elseif o.kind=='firePipe'then
   local height=c.pipeHousingHeight*hs;local depth=o.h-16
   draw(o.w,depth,source,nil,function(s,t)
    local rise=0;if s>=14 and s<=34 then rise=c.pipeRadius*math.sin(math.pi*(s-14)/20)*math.min(1,math.max(0,(depth-t-8)/8))end
    return{o.x+s,height+rise,o.y+t*o.h/depth}
   end)
   draw(o.w,16,function(s,t)return source(s,depth+t)end,nil,function(s,t)return{o.x+s,height*(16-t)/16,base}end)
   for _,edge in ipairs{0,o.w}do draw(depth,1,function(s)return source(math.min(o.w-1,edge),s)end,nil,function(s,t)return{o.x+edge,height*(1-t),o.y+s*o.h/depth}end,c.sideShade)end
  elseif o.kind=='fireEndGate'then
   -- This gate runs north/south: its narrow native panel is a raised
   -- strip with closed edge faces, ending at the exact collision tile.
   local height=c.endGateHeight*hs
   draw(o.w,o.h,source,nil,function(s,t)return{o.x+s,height,o.y+t}end)
   for _,edge in ipairs{0,o.w}do draw(o.h,1,function(s)return source(math.min(o.w-1,edge),s)end,nil,function(s,t)return{o.x+edge,height*(1-t),o.y+s}end,c.sideShade)end
   draw(o.w,1,function(s)return source(s,31)end,nil,function(s,t)return{o.x+s,height*(1-t),base}end,c.sideShade)
  end
  V.require('RoomLightRig').capture(L,{kind=(o.kind=='fireRear'or o.kind=='firePartition'or o.kind=='fireDivider')and 'wall'or 'plant'},out,first,#out)
 end
end
function R.lighting(d)
 if not R.profile(d)then return end;local c=cfg();local sources={}
 for _,p in ipairs(c.lights)do sources[#sources+1]={at={p[1],c.lightHeight,p[2]},color=c.lightColor,power=c.lightPower,radius=c.lightRadius,spread=c.lightSpread}end
 return{fixed=true,ambient=c.ambient,sources=sources}
end
return R
