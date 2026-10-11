-- Native Orania gym surfaces. Live metatiles own the two electrical locks;
-- no script, event, collision or puzzle state is changed by this module.
local V=...;local E={}
local function cfg()return V.require('DioramaConfig').interiors.fireredElectricGym end
function E.profile(d)
 local L=d and d.midLayout
 return cfg().enabled and d and d.id=='FR_VERMILION_CITY_GYM'and (d.renderPair or d.pair)=='building__rom_082d4d34'and d.mapType==8 and L and L.width==12 and L.height==22 and L:midAt(0,0)==0x288 and L:midAt(5,0)==0x2ca or nil
end
function E.plan(d)
 if not E.profile(d)then return end
 local objects,mask={},{};local L=d.midLayout
 for i=1,L.width*L.height do mask[i]={mid=8,void=true,separateSurface=true}end
 local function add(kind,x,y,w,h,p)p=p or{};p.kind=kind;p.x=x;p.y=y;p.w=w;p.h=h;objects[#objects+1]=p end
 add('electricFloor',0,32,176,304)
 add('electricWall',10,0,156,32)
 for _,x in ipairs{0,120}do add('electricWall',x,96,56,32)end
 add('electricBorder',10,32,156,64)
 for _,x in ipairs{48,112}do add('electricPillar',x,16,16,40)end
 for _,x in ipairs{32,128}do add('electricPower',x,96,16,48)end
 for y=10,14,2 do for x=1,9,2 do add('electricBin',x*16,y*16,16,16)end end
 for _,x in ipairs{48,112}do add('electricStatue',x,256,16,32)end
 add('electricBeam',48,96,80,32)
 return{objects=objects,mask=mask,owners={}}
end
local binRuns={{6,10},{4,12},{3,13},{2,14},{2,14},{2,14},{2,14},{2,14},{2,14},{2,14},{2,14},{2,14},{3,13},{4,12},{6,10}}
function E.inside(o,s,t)
 if s<0 or s>=o.w or t<0 or t>=o.h then return false end
 if o.kind=='electricBin'then local a=binRuns[t+1];return a and s>=a[1]and s<a[2]or false end
 if o.kind=='electricStatue'then return V.require('FireRedGymRooms').inside({kind='gymStatue',w=16,h=32},s,t)end
 if o.kind=='electricPillar'then return t<38 and(s>=1 and s<15 or t>=2 and t<35)end
 if o.kind=='electricPower'then
  if t<8 or t>=40 then return false end
  if t<16 then return s>=2 and s<6 or s>=10 and s<14 end
  return true
 end
 return false
end
function E.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local G,P,B=V.require('WorldGeometry'),V.require('PaperSprite'),V.require('BuildingMesh');local hs=V.require('Billboard').heightScale()
 local function src(x,z)return L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16 end
 local function draw(w,h,source,inside,project,shade)
  local vv=P.build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 local function rgb(x,z)local r,g,b=B.pixel(ts,src(x,z));return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local function border(x,z)
  if z<32 or z>=96 or x<10 or x>=166 then return false end
  local col=rgb(x,z)
  return col==0xb5b5a5 or col==0xffffff
 end
 local clear={}
 for _,o in ipairs(objects)do if o.kind=='electricBin'or o.kind=='electricStatue'or o.kind=='electricPillar'or o.kind=='electricPower'then
  for t=0,o.h-1 do for s=0,o.w-1 do clear[(o.y+t)*192+o.x+s]=true end end
 end end
 for _,o in ipairs(objects)do local first=#out+1
  local function source(s,t)return src(o.x+s,o.y+t)end
  if o.kind=='electricFloor'then
   draw(o.w,o.h,function(s,t)local z=t+32
    if clear[z*192+s]or(z>=96 and z<128 and s>=56 and s<120)then return 0x281,s%16,z%16 end
    return src(s,z)
   end,function(s,t)local z=t+32;local m=L:midAt(math.floor(s/16),math.floor(z/16))
    if not m or m==8 or border(s,z)then return false end
    if z<96 and rgb(s,z)==0 then return false end
    if z>=96 and z<128 and(s<56 or s>=120)then return false end
    return true
   end,function(s,t)return{s,0,t+32}end)
  elseif o.kind=='electricWall'then
   local height=c.wallHeight*hs;local base=o.y+o.h
   local function wallSource(s,t)local x=o.x+s
    if o.y==0 and t>=16 and x>=48 and x<128 then return src(44,t)end
    if o.y==96 and((x>=32 and x<48)or(x>=128 and x<144))then return src(47,t)end
    return source(s,t)
   end
   draw(o.w,o.h,wallSource,nil,function(s,t)return{o.x+s,height*(32-t)/32,base}end)
   draw(o.w,c.wallDepth,function(s)return wallSource(s,0)end,nil,function(s,t)return{o.x+s,height,base-c.wallDepth+t}end)
   for _,edge in ipairs{0,o.w}do draw(c.wallDepth,o.h,function(_,t)return wallSource(math.min(o.w-1,edge),t)end,nil,function(s,t)return{o.x+edge,height*(32-t)/32,base-c.wallDepth+s}end,c.sideShade)end
  elseif o.kind=='electricBorder'then
   draw(o.w,o.h,source,function(s,t)return border(o.x+s,o.y+t)end,function(s,t)return{o.x+s,c.cutawayHeight,o.y+t}end)
   for t=0,o.h-1 do for s=0,o.w-1 do local x,z=o.x+s,o.y+t;if border(x,z)then
    local m,u,v=src(x,z);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
    for _,a in ipairs{{-1,0,0,0,0,1},{1,0,1,0,1,1},{0,-1,0,0,1,0},{0,1,0,1,1,1}}do if not border(x+a[1],z+a[2])then
     local xx,zz=x+ox*16,z+oz*16
     G.quad(out,{xx+a[3],c.cutawayHeight,zz+a[4]},{xx+a[5],c.cutawayHeight,zz+a[6]},{xx+a[5],0,zz+a[6]},{xx+a[3],0,zz+a[4]},uv,c.sideShade)
    end end
   end end end
  elseif o.kind=='electricBeam'then
   -- Flood white cores from cyan energy pixels. White wall-cap texels share
   -- the palette but are disconnected and must not hover over an open gate.
   local white,energy,queue={},{},{}
   for t=6,25 do for s=0,79 do local color=rgb(o.x+s,o.y+t);local k=t*80+s
    if color==0x21b5e6 or color==0xadffe6 then energy[k]=true;queue[#queue+1]=k
    elseif color==0xffffff then white[k]=true end
   end end
   local i=1;while queue[i]do local k=queue[i];i=i+1;local s,t=k%80,math.floor(k/80)
    for _,a in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do local x,z=s+a[1],t+a[2];local n=z*80+x
     if x>=0 and x<80 and z>=6 and z<26 and white[n]and not energy[n]then energy[n]=true;queue[#queue+1]=n end
    end
   end
   draw(o.w,o.h,source,function(s,t)return energy[t*80+s]end,function(s,t)return{o.x+s,c.beamHeight*hs*(32-t)/32,128.02}end,G.ELECTRIC_BEAM_FR)
  elseif o.kind=='electricBin'then
   draw(o.w,o.h,source,function(s,t)return t<8 and E.inside(o,s,t)end,function(s,t)return{o.x+s,c.binHeight,o.y+8+t*c.binDepth/8}end)
   draw(o.w,o.h,source,function(s,t)return t>=8 and E.inside(o,s,t)end,function(s,t)return{o.x+s,c.binHeight*(15-t)/7,o.y+8+c.binDepth}end)
   -- Close the curved rim with native side texels; no flat donor rectangle.
   for t=0,7 do for s=0,15 do if E.inside(o,s,t)then
    for _,a in ipairs{{-1,0,0,0,0,1},{1,0,1,0,1,1},{0,-1,0,0,1,0}}do
     if t+a[2]<0 or not E.inside(o,s+a[1],t+a[2])then
      local m,u,v=source(math.max(2,math.min(13,s)),10);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
      local x,z=o.x+s+ox*16,o.y+8+t*c.binDepth/8+oz*16
      G.quad(out,{x+a[3],c.binHeight,z+a[4]*c.binDepth/8},{x+a[5],c.binHeight,z+a[6]*c.binDepth/8},{x+a[5],0,z+a[6]*c.binDepth/8},{x+a[3],0,z+a[4]*c.binDepth/8},uv,c.sideShade)
     end
    end
   end end end
   contacts[#contacts+1]={o.x+8+ox*16,o.y+16+oz*16,6,c.contactRadius,c.contactStrength}
  else
   local statue=o.kind=='electricStatue';local pillar=o.kind=='electricPillar';local top=pillar and 0 or statue and 0 or 8;local bottom=pillar and 38 or statue and 32 or 40
   local height=(pillar and c.pillarHeight or statue and c.statueHeight or c.powerHeight)*hs;local base=o.y+bottom
   draw(o.w,o.h,source,function(s,t)return E.inside(o,s,t)end,function(s,t)return{o.x+s,(bottom-t)*height/(bottom-top),base}end)
   contacts[#contacts+1]={o.x+8+ox*16,base+oz*16,7,c.contactRadius,c.contactStrength}
  end
  V.require('RoomLightRig').capture(L,{kind=o.kind=='electricWall'and 'wall'or 'plant'},out,first,#out)
 end
end
function E.lighting(d)if E.profile(d)then return cfg().light end end
return E
