-- The native octagonal platform, its two stairs and recessed door are measured
-- separately. Presentation heights never alter cell elevation or event paths.
local V=...
local R={}
function R.profile(d)
 if not d then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.championRoom.enabled and(d.id or d.name)=='EM_EVER_GRANDE_CITY_CHAMPIONS_ROOM'and d.pair=='building__elite_four'and L and L.width==14 and L.height==14 and L:midAt(6,7)==0x313 and L:midAt(3,10)==0x329 then return c.homeRooms.championRoom end
end
local function rear(s)return 64+math.max(0,64-s,s-144)end
local function front(s)return 128+math.min(32,s-32,176-s)end
local function bottom(s)return math.min(208,s+160,368-s)end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.championRoom;local foot=z+16
 if foot>=160 then return c.platformHeight*cfg.heightScale*math.max(0,(208-foot)/48)end
 if x+8>=80 and x+8<=128 and foot<=80 then return(c.platformHeight+c.exitRise*math.max(0,math.min(1,(80-foot)/32)))*cfg.heightScale end
 return c.platformHeight*cfg.heightScale
end
function R.doorPose(d,a)
 if not R.profile(d)or not a or a.y~=2 then return end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.championRoom
 return{base=(c.platformHeight+c.exitRise)*cfg.heightScale,height=c.wallHeight*.5*cfg.heightScale,top=0}
end
function R.plan(d)
 if not R.profile(d)then return end
 local mask={};for i=1,196 do mask[i]={mid=1,void=true}end
 return{{kind='championRoom',x=0,y=0,w=208,h=208,noContact=true}},mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.championRoom;local P=V.require('PaperSprite');local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(math.floor(s/16),math.floor(t/16)),s%16,t%16 end
 local function draw(w,h,src,inside,project)
  local vv=P.build(ts,w,h,src,inside or function()return true end,0,h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 -- The newly exposed space below the platform needs a closed chamber floor.
 -- Use the original cyan floor texel, shaded beneath the raised platform.
 local perimeter={{0,128},{64,64},{144,64},{208,128},{208,160},{160,208},{48,208},{0,160}}
 local uv=G.uv(ts,0x313,8,8,9,9,.5);local center={x+104,0,z+136}
 for i,a in ipairs(perimeter)do local b=perimeter[i%#perimeter+1];G.quad(out,center,{x+a[1],0,z+a[2]},{x+b[1],0,z+b[2]},center,uv,c.floorShade)end
 -- One native pixel column per contour segment: all top/bottom vertices meet
 -- their neighbour even where the raster artwork has a diagonal edge.
 for s=32,175 do
  local a,b=rear(s),front(s)
  draw(1,b-a,function(_,t)return source(s,a+t)end,function(_,t)return not(s>=80 and s<128 and a+t<80)end,function(u,t)
   return{x+s+u,c.platformHeight,z+math.max(rear(s+u),math.min(front(s+u),a+t))}
  end)
  if s<80 or s>=128 then
   local depth=bottom(s)-b
   draw(1,depth,function(_,t)return source(s,b+t)end,nil,function(u,t)return{x+s+u,c.platformHeight*(1-t/depth),z+front(s+u)}end)
  end
 end
 -- Close the two straight side faces using the native pedestal texture.
 for _,side in ipairs({32,176})do for zz=96,112,16 do
  local donor=side==32 and 33 or 174
  for t=0,47 do local m,u,v=source(donor,144+t)
   G.quad(out,{x+side,c.platformHeight*(48-t)/48,z+zz},{x+side,c.platformHeight*(48-t)/48,z+zz+16},{x+side,c.platformHeight*(47-t)/48,z+zz+16},{x+side,c.platformHeight*(47-t)/48,z+zz},G.uv(ts,m,u,v,u+1,v+1,.5),.96)
  end
 end end
 -- Preserve the native glass/white outer rim as a low solid surround.
 local function rim(s,t)
  if t<rear(s)then return false end
  if s>=32 and s<176 and t<bottom(s)then return false end
  if s>=80 and s<128 then return false end
  local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v)
  return m~=1 and a>=.5 and math.max(r,g,b)>.02
 end
 draw(208,208,source,rim,function(s,t)return{x+s,c.surroundHeight,z+t}end)
 for t=0,207 do for s=0,207 do if rim(s,t)then
  local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
  local function edge(ss,tt,a,b)
   if ss<0 or ss>=208 or tt<0 or tt>=208 or not rim(ss,tt)then G.quad(out,{x+a[1],c.surroundHeight,z+a[2]},{x+b[1],c.surroundHeight,z+b[2]},{x+b[1],0,z+b[2]},{x+a[1],0,z+a[2]},uv,.94)end
  end
  edge(s-1,t,{s,t},{s,t+1});edge(s+1,t,{s+1,t+1},{s+1,t});edge(s,t-1,{s+1,t},{s,t});edge(s,t+1,{s,t+1},{s+1,t+1})
 end end end
 -- Rear wall follows the original diagonal wings. The door niche remains at
 -- z48, behind the upper flight, with the original door texels still live.
 for s=0,207 do
  local a=math.max(0,48-s,s-160);local b=rear(s);local niche=s>=80 and s<128
  if niche then a=0;b=48 end
  local base=niche and c.platformHeight+c.exitRise or c.platformHeight
  local height=niche and c.wallHeight*.75 or c.wallHeight
  draw(1,b-a,function(_,t)return source(s,a+t)end,nil,function(u,t)return{x+s+u,base+height*(1-t/(b-a)),z+(niche and 48 or rear(s+u))}end)
  if not niche then
   local m,u,v=source(s,b-1);local zz0,zz1=rear(s),rear(s+1)
   G.quad(out,{x+s,base,z+zz0},{x+s+1,base,z+zz1},{x+s+1,c.surroundHeight,z+zz1},{x+s,c.surroundHeight,z+zz0},G.uv(ts,m,u,v,u+1,v+1,.5),.95)
  end
 end
 -- Texture the two niche returns from the adjacent native wall columns.
 for _,s in ipairs({80,128})do
  local donor=s==80 and 79 or 128
  for t=0,63 do local m,u,v=source(donor,t)
   G.quad(out,{x+s,c.platformHeight+c.wallHeight*(64-t)/64,z+48},{x+s,c.platformHeight+c.wallHeight*(64-t)/64,z+64},{x+s,c.platformHeight+c.wallHeight*(63-t)/64,z+64},{x+s,c.platformHeight+c.wallHeight*(63-t)/64,z+48},G.uv(ts,m,u,v,u+1,v+1,.5),.95)
  end
 end
 local function step(a,b,high,low)
  local face=b-2
  draw(48,face-a,function(s,t)return source(s+80,a+t)end,nil,function(s,t)return{x+80+s,high,z+a+t}end)
  draw(48,2,function(s,t)return source(s+80,face+t)end,nil,function(s,t)return{x+80+s,high-(high-low)*t/2,z+face}end)
  draw(48,2,function(s,t)return source(s+80,a)end,nil,function(s,t)return{x+80+s,low,z+face+t}end)
  local base=a<80 and c.platformHeight or 0
  for _,side in ipairs({80,128})do
   local m,u,v=source(side==80 and 80 or 127,a);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
   for _,r in ipairs({{a,face,high},{face,b,low}})do
    G.quad(out,{x+side,r[3],z+r[1]},{x+side,r[3],z+r[2]},{x+side,base,z+r[2]},{x+side,base,z+r[1]},uv,.96)
   end
  end
 end
 for a=160,200,8 do local h=c.platformHeight*(208-a)/48;step(a,a+8,h,h-c.platformHeight/6)end
 step(48,64,c.platformHeight+c.exitRise,c.platformHeight+c.exitRise*2/3)
 step(64,72,c.platformHeight+c.exitRise*2/3,c.platformHeight+c.exitRise/3)
 step(72,80,c.platformHeight+c.exitRise/3,c.platformHeight)
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
 if contacts then for s=40,168,8 do if s<80 or s>128 then contacts[#contacts+1]={x+s,z+front(s)+1,5,1.5,c.contactStrength}end end end
end
return R
