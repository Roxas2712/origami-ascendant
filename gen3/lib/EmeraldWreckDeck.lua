-- Native abandoned-ship drawing folded into connected deck levels.
-- All coordinates here describe source art; ROM movement/warps remain untouched.
local V=...;local D={}
local function config()return V.require('DioramaConfig').terrain.emWreckDeck end
function D.profile(d)
 local L=d and d.midLayout;local c=config()
 return c.enabled and V.require('DioramaConfig').billboards.enabled and d and d.id=='EM_ABANDONED_SHIP_DECK'
  and d.pair=='general__facility'and d.mapType==4 and L and L.width==24 and L.height==22 and L:midAt(13,15)==0x2ce and c or nil
end
function D.ground(d,x,z)
 local c=D.profile(d);if not c then return end
 if x>=208 and x<240 and z>=208 then return c.deckHeight*math.max(0,1-(z-208)/48)end
 if x>=160 and x<192 and z>=128 and z<160 then return c.upperHeight-(c.upperHeight-c.deckHeight)*(z-128)/32 end
 if x>=112 and x<224 and z<160 then return c.upperHeight end
 return c.deckHeight
end
function D.actorHeight(d,x,z)return D.ground(d,x+8,z+16)end
function D.doorPose(d,a)
 local c=D.profile(d);if not c or not a then return end
 if a.y==9 and(a.x==8 or a.x==13)then return{height=c.upperHeight-c.deckHeight,base=c.deckHeight,top=0}end
 if a.y==5 and a.x==12 then return{height=c.officeHeight-c.upperHeight,base=c.upperHeight,top=0}end
end
function D.border(out,d,ts,x,y)
 local c=D.profile(d);if not c then return false end
 local G=V.require('WorldGeometry');local sx,sz=x*16,y*16
 local deck=x<23 and y<13
 local height=deck and (x>=7 and c.officeHeight or x>=3 and c.upperHeight or c.deckHeight)or 0
 local mid=deck and 0x228 or 0x170
 G.quad(out,{sx,height,sz},{sx+16,height,sz},{sx+16,height,sz+16},{sx,height,sz+16},G.uv(ts,mid),deck and 1 or G.WATER)
 if deck and (x==3 or x==7)then
  local base=x==3 and c.deckHeight or c.upperHeight
  G.quad(out,{sx,height,sz},{sx,height,sz+16},{sx,base,sz+16},{sx,base,sz},G.uv(ts,0x3c9),c.sideShade)
 end
 if deck and y==12 then
  G.quad(out,{sx,c.deckHeight,sz+16},{sx+16,c.deckHeight,sz+16},{sx+16,0,sz+16},{sx,0,sz+16},G.uv(ts,0x3ca),c.sideShade)
 end
 return true
end
function D.build(d,ts,ox,oz)
 local c=D.profile(d);if not c then return end
 local L=d.midLayout;local G=V.require('WorldGeometry');local out,contacts={},{}
 local xx,zz=(ox or 0)*16,(oz or 0)*16
 local pixel=V.require('BuildingMesh').pixel
 local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local floorColors={};for y=0,15 do for x=0,15 do floorColors[key(pixel(ts,0x228,x,y))]=true end end
 local function src(s,t)return L:midAt(math.floor(s/16),math.floor(t/16)),s%16,t%16 end
 local function art(sx,sy,w,h,inside,point,shade,source)
  local vv=V.require('PaperSprite').build(ts,w,h,source or function(s,t)return src(sx+s,sy+t)end,inside or function()return true end,0,h,1,shade and function()return shade end,
   function(s,t)local p=point(s,t);return{p[1]+xx,p[2],p[3]+zz}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function quad(a,b,cc,dd,mid,shade)
  for _,p in ipairs{a,b,cc,dd}do p[1]=p[1]+xx;p[3]=p[3]+zz end
  G.quad(out,a,b,cc,dd,G.uv(ts,mid),shade)
 end
 local function clean(s,t)
  local m,u,v=src(s,t)
  if m==0x21f or m==0x227 or m==0x22f or m==0x260 or m==0x262 or m==0x2a1 or m>=0x265 and m<=0x26a then return 0x228,u,v end
  return m,u,v
 end
 local function floor(sx,sy,w,h,height,z0,z1)
  art(sx,sy,w,h,nil,function(s,t)return{sx+s,height,z0+t*(z1-z0)/h}end,nil,function(s,t)return clean(sx+s,sy+t)end)
 end
 local function face(sx,sy,w,h,height,base,z)
  art(sx,sy,w,h,nil,function(s,t)return{sx+s,height+(base-height)*t/h,z}end,c.sideShade)
 end
 local function side(x,z0,z1,base,height,mid)
  quad({x,height,z0},{x,height,z1},{x,base,z1},{x,base,z0},mid,c.sideShade)
 end
 -- The native surf/foam boundary remains at its original world coordinates.
 for y=13,21 do for x=0,23 do
  local mid=y<16 and 0x19e or L:midAt(x,y)
  if mid==0x334 then mid=0x19e end
  quad({x*16,0,y*16},{x*16+16,0,y*16},{x*16+16,0,y*16+16},{x*16,0,y*16+16},mid,G.WATER)
 end end
 for y=0,12 do quad({368,0,y*16},{384,0,y*16},{384,0,y*16+16},{368,0,y*16+16},0x170,G.WATER)end
 -- Lower deck and continuous native hanging hull; gangway is a real stair.
 floor(0,160,368,48,c.deckHeight,160,208)
 floor(0,0,48,160,c.deckHeight,0,160)
 face(0,208,208,48,c.deckHeight,0,208)
 face(240,208,128,48,c.deckHeight,0,208)
 side(0,0,208,0,c.deckHeight,0x3ca);side(368,0,208,0,c.deckHeight,0x3ca)
 -- Port roof and the two upper walk strips beside the native middle stairs.
 floor(48,0,64,128,c.upperHeight,0,160)
 floor(112,96,48,32,c.upperHeight,96,160)
 floor(192,96,32,32,c.upperHeight,96,160)
 floor(160,96,32,32,c.upperHeight,96,128)
 face(48,128,112,32,c.upperHeight,c.deckHeight,160)
 face(192,128,48,32,c.upperHeight,c.deckHeight,160)
 side(48,0,160,c.deckHeight,c.upperHeight,0x3c9)
 -- Raised bridge/office and starboard window wall, with closed returns.
 floor(112,0,112,64,c.officeHeight,0,96)
 face(112,64,112,32,c.officeHeight,c.upperHeight,96)
 side(112,0,96,c.upperHeight,c.officeHeight,0x3c9)
 floor(224,0,144,96,c.officeHeight,0,160)
 face(240,96,128,64,c.officeHeight,c.deckHeight,160)
 face(224,96,16,32,c.officeHeight,c.upperHeight,160)
 side(224,0,160,c.upperHeight,c.officeHeight,0x3c9)
 side(368,0,160,c.deckHeight,c.officeHeight,0x3c9)
 local function stairs(sx,sy,w,h,top,bottom)
  local step=c.stepDepth;local n=h/step
  for j=0,n-1 do local t=j*step;local a=top+(bottom-top)*j/n;local b=top+(bottom-top)*(j+1)/n
   art(sx,sy+t,w,step,nil,function(s,v)return{sx+s,a,sy+t+v}end)
   art(sx,sy+t+step-1,w,1,nil,function(s,v)return{sx+s,a+(b-a)*v,sy+t+step}end,c.sideShade)
   for _,x in ipairs{sx,sx+w}do side(x,sy+t,sy+t+step,bottom,a,0x3c9)end
  end
 end
 stairs(160,128,32,32,c.upperHeight,c.deckHeight)
 stairs(208,208,32,48,c.deckHeight,0)
 -- Rail openings are native cutouts, not opaque green quads. Their source
 -- row follows the folded deck edge, independent of the gameplay grid.
 local function pose(x,y)
  if y>=10 then return c.deckHeight,y*16 end
  if x<3 then return c.deckHeight,y*16 end
  if x<7 then return c.upperHeight,y*20 end
  if x<14 then
   if y<4 then return c.officeHeight,y*24 end
   return c.upperHeight,96+(y-6)*32
  end
  return c.officeHeight,y*160/6
 end
 for y=0,12 do for x=0,22 do local m=L:midAt(x,y)
  if m>=0x265 and m<=0x26a then
   local height,z=pose(x,y);local edge=y==12 and 208 or (y==7 and x>=3 and x<14)and 160 or (y==5 and x>=14)and 160 or z+16
   art(x*16,y*16,16,16,function(_,_,mid,u,v)return not floorColors[key(pixel(ts,mid,u,v))]end,function(s,t)return{x*16+s,height+c.railHeight*(1-t/16),edge}end)
  elseif m==0x260 or m==0x262 or m==0x2a1 then
   local height,z=pose(x,y);local _,last=pose(x,y+1)
   -- Side rails follow the depth axis. The native narrow trim supplies the
   -- vertical profile; its surrounding green deck texels are cut away.
   art(x*16,y*16,16,16,function(_,_,mid,u,v)return not floorColors[key(pixel(ts,mid,u,v))]end,function(s,t)return{x*16+4,height+c.railHeight*(1-s/16),z+t*(last-z)/16}end)
  elseif m==0x21f then
   local h=16;while L:midAt(x,y+h/16)==0x227 or L:midAt(x,y+h/16)==0x22f do h=h+16 end
   local height,z=pose(x,y+h/16-1)
   art(x*16,y*16,16,h,function(_,_,mid,u,v)return not floorColors[key(pixel(ts,mid,u,v))]end,function(s,t)return{x*16+s,height+(h-t)*c.funnelScale,z+16}end)
   contacts[#contacts+1]={xx+x*16+8,zz+z+16,6,2,c.contactStrength}
  end
 end end
 return out,{contacts=contacts,lights={},buildings=0,trees=0,cells=L.width*L.height,vertices=#out,terrainCells=0,wreckDeck=true}
end
return D
