-- Gate lounge furniture: native glass and chair art, independent surfaces.
local V=...;local S={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.gateFurniture end
function S.plan(d,objects,mask)
 local L=d.midLayout;if L then S.rooms[L]=nil end
 if not cfg().enabled or not L or d.mapType~=8 or d.pair~='house'or not(d.id or d.name or''):match('^FR_ROUTE_')then return end
 local owned={};S.rooms[L]=owned
 local function add(kind,x,y,w,h,right)
  local o={kind=kind,x=x,y=y,w=w*16,h=h*16,right=right};objects[#objects+1]=o;owned[#owned+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=0x281,separateSurface=true}end end
 end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x2d6 and x+1<L.width and y+1<L.height and L:midAt(x+1,y)==0x2d7 and L:midAt(x,y+1)==0x2de and L:midAt(x+1,y+1)==0x2df then
   add('gateGlassTable',x,y,2,2)
  elseif m==0x2e6 or m==0x2e7 then add('gateChair',x,y,1,1,m==0x2e7)end
 end end
end
local function cutout(L,ts,o)
 local B=V.require('BuildingMesh');local clear,empty,q={},{},{}
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local bg={}
 for _,m in ipairs({0x281,0x282,0x283})do for t=0,15 do for s=0,15 do bg[rgb(B.pixel(ts,m,s,t))]=true end end end
 if o.kind=='gateChair'then bg[rgb(B.pixel(ts,0x2e6,3,14))]=true end
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 for t=0,o.h-1 do for s=0,o.w-1 do local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v);clear[t*o.w+s]=a<.5 or bg[rgb(r,g,b)]end end
 local function seed(s,t)local k=t*o.w+s;if clear[k]and not empty[k]then empty[k]=true;q[#q+1]=k end end
 for s=0,o.w-1 do seed(s,0);seed(s,o.h-1)end;for t=0,o.h-1 do seed(0,t);seed(o.w-1,t)end
 local j=1;while q[j]do local k=q[j];j=j+1;local s,t=k%o.w,math.floor(k/o.w)
  if s>0 then seed(s-1,t)end;if s<o.w-1 then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t<o.h-1 then seed(s,t+1)end
 end
 return source,function(s,t)return s>=0 and s<o.w and t>=0 and t<o.h and not empty[t*o.w+s]end
end
function S.build(out,objects,L,ts,ox,oz,contacts)
 if not cfg().enabled then return end
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local c=cfg()
 for _,o in ipairs(objects)do if o.kind=='gateGlassTable'or o.kind=='gateChair'then
  local x,z=(o.x+ox)*16,(o.y+oz)*16;local source,inside=cutout(L,ts,o)
  local function band(lo,hi,project,part)
   local vv=P.build(ts,o.w,o.h,source,function(s,t)return t>=lo and t<hi and inside(s,t)and(not part or part(s,t))end,0,o.h,1,nil,project,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
  end
  local function box(a,b,back,front,lo,hi,uv)
   G.quad(out,{a,hi,back},{b,hi,back},{b,hi,front},{a,hi,front},uv,1)
   G.quad(out,{a,hi,front},{b,hi,front},{b,lo,front},{a,lo,front},uv,c.sideShade)
   G.quad(out,{b,hi,back},{a,hi,back},{a,lo,back},{b,lo,back},uv,c.sideShade)
   G.quad(out,{a,hi,back},{a,hi,front},{a,lo,front},{a,lo,back},uv,c.sideShade)
   G.quad(out,{b,hi,front},{b,hi,back},{b,lo,back},{b,lo,front},uv,c.sideShade)
  end
  if o.kind=='gateGlassTable'then
   local h,d,r=c.tableHeight,c.tableDepth,c.tableRim
   -- The reflection and rounded rim remain opaque, including shared palette
   -- colours enclosed by the table. Only connected floor pixels are removed.
   band(0,26,function(s,t)return{x+s,h,z+t*d/26}end)
   band(26,29,function(s,t)return{x+s,h-(t-26)*r/3,z+d}end)
   band(29,31,function(s,t)return{x+s,(31-t)*(h-r)/2,z+d}end)
   local uv=G.uv(ts,0x2de,4,13,5,14,.5)
   for _,xx in ipairs({3,27})do box(x+xx,x+xx+2,z+3,z+5,0,h-r,uv)end
   -- A thin apron follows each side, not a solid block under the glass.
   for _,xx in ipairs({1,30})do G.quad(out,{x+xx,h,z+4*d/26},{x+xx,h,z+23*d/26},{x+xx,h-r,z+23*d/26},{x+xx,h-r,z+4*d/26},uv,c.sideShade)end
   V.require('GateLighting').box(L,x+3,h-r,z+3,26,r,d-6,false)
   contacts[#contacts+1]={x+16,z+d,13,c.contactRadius,c.contactStrength}
  else
   local function back(s)return o.right and s>=11 or not o.right and s<5 end
   local h=c.seatHeight;local front=c.seatFront
   band(0,11,function(s,t)return{x+s,h+(11-t)*c.backRise/11*V.require("Billboard").heightScale(),z+front}end,back)
   band(4,11,function(s,t)return{x+s,h,z+front-c.seatDepth+(t-4)*c.seatDepth/7}end,function(s)return not back(s)end)
   band(11,16,function(s,t)return{x+s,h*(16-t)/5,z+front}end)
   contacts[#contacts+1]={x+8,z+front,5,c.contactRadius,c.contactStrength}
  end
 end end
end
function S.actorOffset(d,px,pz)
 if not cfg().enabled then return end
 for _,o in ipairs(S.rooms[d and d.midLayout]or{})do
  if o.kind=='gateChair'and px>=o.x*16 and px<(o.x+1)*16 and pz>o.y*16 and pz<=(o.y+1)*16 then
   return cfg().seatHeight,cfg().seatFront-16
  end
 end
end
return S
