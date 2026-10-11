-- The Route 16 middle course mixes floor, a horizontal white cap and wall.
local V=...;local S={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.gateDivider end
local function smooth(a,b,x)local t=math.max(0,math.min(1,(x-a)/(b-a)));return t*t*(3-2*t)end
function S.plan(d,objects,mask)
 local L=d.midLayout;if L then S.rooms[L]=nil end
 if not(cfg().enabled and L and d.id=='FR_ROUTE_16_NORTH_ENTRANCE_1F'and d.pair=='house'and d.mapType==8 and L.width==14 and L.height==18)then return end
 local courses={{0x2fb,0x2fc,0x2fd},{0x303,0x304,0x305},{0x30b,0x30c,0x30d}}
 for row,p in ipairs(courses)do for x=1,11 do
  if L:midAt(x,4+row)~=p[x==1 and 1 or x==11 and 3 or 2]then return end
 end end
 local o={kind='gateDivider',x=1,y=5,w=11*16};objects[#objects+1]=o;S.rooms[L]=o
 for y=5,7 do for x=1,11 do mask[y*L.width+x+1]={mid=0,void=true,separateSurface=true}end end
end
function S.build(out,objects,L,ts,ox,oz)
 local c=cfg();if not c.enabled then return end
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite')
 for _,o in ipairs(objects)do if o.kind=='gateDivider'then
  local x,z=(o.x+ox)*16,(o.y+oz)*16;local front=z+48;local back=front-c.depth
  local height=c.height*V.require('Billboard').heightScale();o.world={x,x+o.w,front,height}
  local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local function append(vv)for _,v in ipairs(vv)do out[#out+1]=v end end
  -- All native floor pixels above the cap stay intact. Behind the folded
  -- wall, use the same native floor phase; the map itself remains unchanged.
  append(P.build(ts,o.w,48,function(s,t)if t<10 then return src(s,t)end;return 0x281,s%16,t%16 end,
   function(_,t)return z+t<back end,0,48,1,nil,function(s,t)return{x+s,0,z+t}end,.5))
  for _,edge in ipairs({front,back})do
   append(P.build(ts,o.w,48,src,function(_,t)return t>=20 end,0,48,1,function()return 13 end,
    function(s,t)return{x+s,(48-t)*height/28,edge,x+o.w/2,front,0}end,.5))
  end
  append(P.build(ts,o.w,48,src,function(_,t)return t>=10 and t<20 end,0,48,1,function()return 14 end,
   function(s,t)return{x+s,height,back+(t-10)*c.depth/10,x+o.w/2,front,0}end,.5))
  for _,side in ipairs({0,o.w})do for t=20,47 do
   local mid,u,v=src(side==0 and 0 or o.w-1,t);local hi,lo=(48-t)*height/28,(47-t)*height/28
   G.quad(out,{x+side,hi,back,x+o.w/2,front,0},{x+side,hi,front,x+o.w/2,front,0},
    {x+side,lo,front,x+o.w/2,front,0},{x+side,lo,back,x+o.w/2,front,0},G.uv(ts,mid,u,v,u+1,v+1,.5),13)
  end end
  -- A visual cutaway never lowers the actual wall's light blocker.
  V.require('GateLighting').box(L,x,0,back,o.w,height,c.depth,true)
 end end
end
function S.sections(d,px,pz)
 if not d or d.id~='FR_ROUTE_16_NORTH_ENTRANCE_1F'or d.pair~='house'or d.mapType~=8 then return {}end
 local o=S.rooms[d.midLayout];local c=cfg();if not(c.enabled and o and o.world)then return {}end
 local g=o.world;local distance=g[3]-pz
 local across=1-smooth(0,c.sideMargin,math.max(g[1]-px,px-g[2],0))
 local amount=across*smooth(-c.behindMargin,0,distance)*(1-smooth(c.nearDistance,c.farDistance,distance))
 if V.require('Camera').projection()~='perspective'then amount=0 end
 -- Always register the cap, including at full height, so it keeps its depth.
 return {{g[1],g[2],g[3],g[4]+(c.cutHeight-g[4])*amount}}
end
return S
