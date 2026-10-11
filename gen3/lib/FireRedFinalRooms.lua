-- Final League chambers: original artwork split along measured surface seams.
local V=...;local R={}
local function cfg()return V.require('DioramaConfig').interiors.fireredFinalRooms end
function R.profile(d)
 local L=d and d.midLayout;if not(L and cfg().enabled and d.mapType==8)then return end
 if d.id=='FR_POKEMON_LEAGUE_CHAMPIONS_ROOM'and (d.renderPair or d.pair)=='building__rom_082d50c4'and L.width==14 and L.height==20 and L:midAt(6,9)==0x3f7 and L:midAt(6,16)==0x3cd then return'CHAMPION'end
 if d.id=='FR_POKEMON_LEAGUE_HALL_OF_FAME'and (d.renderPair or d.pair)=='building__rom_082d50dc'and L.width==12 and L.height==14 and L:midAt(5,7)==0x2c4 and L:midAt(2,9)==0x2b4 then return'HALL'end
end
function R.lighting(d)
 local name=R.profile(d);if not name then return end
 local c=cfg();local p=c.lights[name];local sources={}
 for _,a in ipairs(p.at)do sources[#sources+1]={at={a[1],c.lightHeight,a[2]},radius=c.lightRadius,power=c.lightPower,color=p.color,spread=c.lightSpread}end
 return{fixed=true,ambient=p.ambient,localSelection=true,sources=sources}
end
function R.actorHeight(d,x,z)
 if R.profile(d)~='CHAMPION'then return end
 local foot=z+16;if x+8<88 or x+8>120 or foot>=80 then return 0 end
 local rise=cfg().exitRise*V.require('Billboard').heightScale()
 if foot<64 then return rise end
 local k=math.floor((foot-64)/4);local lower=(foot-64)%4>=2 and 1 or 0
 return rise*math.max(0,4-k-lower)/4
end
function R.doorPose(d,a)
 if R.profile(d)=='CHAMPION'and a and a.x==6 and a.y==2 then
  local c=cfg();local hs=V.require('Billboard').heightScale()
  return{zOffset=16,base=c.exitRise*hs,height=(c.championWallHeight-c.exitRise)*32/48*hs,top=0}
 end
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local mask={};for i=1,L.width*L.height do mask[i]={mid=8,void=true,separateSurface=true}end
 return{objects={{kind='finalRoom',x=0,y=0,w=L.width*16,h=L.height*16}},mask=mask,owners={}}
end
local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.build(out,d,ts,ox,oz,contacts)
 local name=R.profile(d);if not name then return end
 local L,c=d.midLayout,cfg();local hs=V.require('Billboard').heightScale();local G,B,P=V.require('WorldGeometry'),V.require('BuildingMesh'),V.require('PaperSprite');local rig=V.require('RoomLightRig')
 local function source(s,t)return L:midAt(math.floor(s/16),math.floor(t/16)),s%16,t%16 end
 local function pixel(s,t)local m,u,v=source(s,t);return B.pixel(ts,m,u,v)end
 local function draw(w,h,src,inside,project,shade)
  local vv={}
  if w==1 and not inside then
   -- Batch a vertical run only while it stays within one native atlas tile.
   local t=0
   while t<h do
    local m,u,v=src(0,t);local last=t+1
    while last<h do local mm,uu,vv=src(0,last);if mm~=m or uu~=u or vv~=v+last-t then break end;last=last+1 end
    G.quad(vv,project(0,t),project(1,t),project(1,last),project(0,last),G.uv(ts,m,u,v,u+1,v+last-t,.5),shade or 1)
    t=last
   end
  else vv=P.build(ts,w,h,src,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)end
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 local function capture(first,wall)rig.capture(L,{kind=wall and'frLeagueWall'or'finalObject'},out,first,#out)end
 local function opaque(s,t)local r,g,b,a=pixel(s,t);return a>.5 and math.max(r,g,b)>.01 end
 local champion=name=='CHAMPION';local w=champion and 208 or 176
 local function rear(s)return champion and(64+math.max(0,32-s,s-176))or(40+math.max(0,(16-s)/2,(s-160)/2))end
 local pillars={}
 if champion then for _,x in ipairs{24,168}do for _,y in ipairs{72,184}do pillars[#pillars+1]={x,y,16,24}end end
 else for _,x in ipairs{32,128}do for _,y in ipairs{48,96,144}do pillars[#pillars+1]={x,y,16,32}end end end
 local function replacement(s,t)
  for _,o in ipairs(pillars)do if s>=o[1]-4 and s<o[1]+o[3]+4 and t>=o[2]and t<o[2]+o[4]+12 then
   if champion then return source(o[1]<100 and 40 or 167,t)end
   return 0x2b0,s%16,t%16
  end end
  if not champion and s>=72 and s<104 and t>=40 and t<80 then return 0x2b0,s%16,t%16 end
  return source(s,t)
 end
 draw(w,L.height*16,replacement,function(s,t)
  return t>=rear(s)and opaque(s,t)and not(champion and s>=88 and s<120 and t<80)
   and not((s<8 or s>=w-8)and t>=(champion and 96 or 48)and t<(champion and 176 or 192))
   and not(champion and t>=224 and((s>=64 and s<86)or(s>=122 and s<144)))
 end,function(s,t)return{s,0,t}end)
 -- Continuous rear wall follows the native bevel, without independent tile lifts.
 local wallFirst
 for s=0,w-1 do
  if s%8==0 then wallFirst=#out+1 end
  local a=champion and math.max(0,37-s,s-170)or math.max(0,math.floor((15-s)/2),math.floor((s-160)/2))
  local niche=champion and s>=88 and s<120
  local b=niche and 48 or math.floor(rear(s));local base=niche and c.exitRise*hs or 0
  local high=(champion and c.championWallHeight or c.hallWallHeight)*hs
  local first=#out+1
  if niche then
   draw(1,48,function(_,t)return source(s,t)end,nil,function(u,t)return{s+u,base+(high-base)*(1-t/48),64}end)
  else
  draw(1,b-a,function(_,t)
   if not champion and s>=72 and s<104 and a+t>=28 then return source(64,a+t)end
   return source(s,a+t)
  end,nil,function(u,t)return{s+u,base+(high-base)*(1-t/(b-a)),niche and 48 or rear(s+u)}end)
  end
  if s%8==7 and not niche then capture(wallFirst,true)end
 end
 -- Low side-wall cutaways retain the native light strip on an upright face.
 for _,right in ipairs{false,true}do local first=#out+1;local x=right and w-8 or 0
  local start,finish=champion and 96 or 48,champion and 176 or 192
  draw(8,finish-start,function(s,t)return source(x+s,start+t)end,function(s,t)return opaque(x+s,start+t)end,
   function(s,t)return{right and w-8 or 8,c.sideWallHeight*hs*(right and s/8 or 1-s/8),start+t}end)
  draw(8,finish-start,function(s,t)return source(x+s,start+t)end,function(s,t)return opaque(x+s,start+t)end,
   function(s,t)return{x+s,c.sideWallHeight*hs,start+t}end)
  for s=0,7 do
   local last=finish-1;while last>=start and not opaque(x+s,last)do last=last-1 end
   if last>=start then local m,u,v=source(x+s,last)
    G.quad(out,{x+s+ox*16,c.sideWallHeight*hs,last+1+oz*16},{x+s+1+ox*16,c.sideWallHeight*hs,last+1+oz*16},{x+s+1+ox*16,0,last+1+oz*16},{x+s+ox*16,0,last+1+oz*16},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)
   end
  end
  capture(first,true)
 end
 if champion then
  local high=c.championWallHeight*hs;local rise=c.exitRise*hs
  -- White landing, four native tread/riser rows; native path/collision untouched.
  draw(32,16,function(s,t)return source(88+s,48+t)end,function(s)return s>=4 and s<28 end,function(s,t)return{88+s,rise,48+t}end)
  for k=0,3 do local z=64+k*4;local hi=rise*(4-k)/4;local lo=rise*(3-k)/4
   draw(32,2,function(s,t)return source(88+s,z+t)end,function(s)return s>=4 and s<28 end,function(s,t)return{88+s,hi,z+t}end)
   draw(32,2,function(s,t)return source(88+s,z+2+t)end,function(s)return s>=4 and s<28 end,function(s,t)return{88+s,hi-(hi-lo)*t/2,z+2}end,c.riserShade)
   draw(32,2,function(s,t)return source(88+s,z+2+t)end,function(s)return s>=4 and s<28 end,function(s,t)return{88+s,lo,z+2+t}end)
  end
  -- Native white bridge rails become low solid strips on the same footprint.
  for _,x in ipairs{80,122}do local first=#out+1;local h=c.bridgeRailHeight*hs
   draw(6,96,function(s,t)return source(x+s,224+t)end,nil,function(s,t)return{x+s,h,224+t}end)
   for _,edge in ipairs{0,6}do
    draw(96,6,function(s,t)return source(x+(edge==0 and 0 or 5),224+s)end,nil,
     function(s,t)return{x+edge,h*(1-t/6),224+s}end,c.sideShade)
   end
   capture(first)
  end
  for _,x in ipairs{88,116}do local first=#out+1
   local function rail(t)return(c.railHeight+c.exitRise*math.max(0,math.min(1,(32-t)/16)))*hs end
   draw(4,32,function(s,t)return source(x+s,48+t)end,nil,function(s,t)return{x+s,rail(t),48+t}end)
   for _,edge in ipairs{0,4}do
    draw(32,8,function(s,t)return source(x+(edge==0 and 0 or 3),48+s)end,nil,
     function(s,t)return{x+edge,rail(s)*(1-t/8),48+s}end,c.sideShade)
   end
   capture(first)
  end
 end
 -- Explicit contour masks discard only sampled floor/shadow palette entries.
 local bg={};local donors=champion and{0x38f}or{0x2b0,0x2b1}
 for _,m in ipairs(donors)do for y=0,15 do for x=0,15 do local r,g,b=B.pixel(ts,m,x,y);bg[key(r,g,b)]=true end end end
 if champion then bg[key(pixel(40,70))]=true end
 local function prop(x,y,ww,hh,front,height,src,background,contour)
  local first=#out+1;local rows={}
  for t=0,hh-1 do local a,b=ww,-1
   for s=0,ww-1 do local m,u,v=(contour or src)(s,t);local r,g,bl,alpha=B.pixel(ts,m,u,v)
    if alpha>.5 and math.max(r,g,bl)>.01 and not background[key(r,g,bl)]then a=math.min(a,s);b=math.max(b,s)end
   end;rows[t]={a,b}
  end
  draw(ww,hh,src,function(s,t)return s>=rows[t][1]and s<=rows[t][2]end,function(s,t)return{x+s,height*(hh-t)/hh,front}end)
  for t=0,hh-1 do local r=rows[t];if r[1]<=r[2]then for _,s in ipairs{r[1],r[2]+1}do
   local m,u,v=src(math.min(ww-1,s),t)
   G.quad(out,{x+s+ox*16,height*(hh-t)/hh,front-c.objectDepth+oz*16},{x+s+ox*16,height*(hh-t)/hh,front+oz*16},{x+s+ox*16,height*(hh-t-1)/hh,front+oz*16},{x+s+ox*16,height*(hh-t-1)/hh,front-c.objectDepth+oz*16},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)
  end end end
  contacts[#contacts+1]={x+ww/2+ox*16,front+oz*16,ww*.4,c.contactRadius,c.contactStrength};capture(first)
 end
 for _,o in ipairs(pillars)do prop(o[1],o[2],o[3],o[4],o[2]+o[4],o[4]*hs,function(s,t)return source(o[1]+s,o[2]+t)end,bg,function(s,t)return source(o[1]+s,(champion and 184 or 144)+t)end)end
 if champion then
  for _,x in ipairs{64,128}do for _,y in ipairs{240,272,304}do prop(x,y,16,16,y+16,c.bridgeLightHeight*hs,function(s,t)return source(x+s,y+t)end,{})end end
 end
 if not champion then
  prop(72,44,32,32,76,c.consoleHeight*hs,function(s,t)return source(72+s,44+t)end,bg)
  local first=#out+1
  draw(32,16,function(s,t)return source(72+s,28+t)end,nil,function(s,t)return{72+s,c.consoleHeight*hs+c.consoleSlope*(1-t/16),76-c.consoleDepth+c.consoleDepth*t/16}end)
  capture(first)
 end
end
return R
