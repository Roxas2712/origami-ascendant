-- Native Fighting Dojo: separate the timber floor, rear wall and freestanding
-- pillars/statues. Trainers, gift balls and all interaction logic stay native.
local V=...;local R={}
local function cfg()return V.require('DioramaConfig').interiors.fireredDojo end
function R.profile(d)
 local L=d and d.midLayout
 return cfg().enabled and d and d.id=='FR_SAFFRON_CITY_DOJO'and d.mapType==8 and d.pair=='pewter_gym'and L and L.width==14 and L.height==16 and L:midAt(4,1)==0x2c5 and L:midAt(6,8)==0x2cb or nil
end
function R.plan(d)
 if not R.profile(d)then return end
 local mask={};for i=1,224 do mask[i]={mid=8,void=true,separateSurface=true}end
 local objects={{kind='dojoFloor'},{kind='dojoWall'},{kind='dojoCrest',x=96,y=40,w=16,h=16}}
 for _,x in ipairs{64,128}do objects[#objects+1]={kind='dojoPillar',x=x,y=24,w=16,h=85}end
 for _,x in ipairs{48,144}do objects[#objects+1]={kind='dojoStatue',x=x,y=192,w=16,h=32}end
 return{mask=mask,objects=objects}
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local statueColors={[0x7b7b7b]=true,[0xdee6e6]=true,[0x52526b]=true,[0xb5b5a5]=true,[0xffffff]=true}
local crestColors={[0x7b7b7b]=true,[0x52526b]=true,[0x318c31]=true,[0xefffef]=true,[0x6bcea5]=true,[0x63adce]=true,[0x4a84a5]=true}
function R.inside(ts,L,o,s,t)
 if s<0 or t<0 or s>=o.w or t>=o.h then return false end
 if o.kind=='dojoPillar'then return t<84 or s>0 and s<15 end
 local x,z=o.x+s,o.y+t;local color=rgb(V.require('BuildingMesh').pixel(ts,L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16))
 return (o.kind=='dojoStatue'and statueColors or crestColors)[color]or false
end
function R.replaced(x,z)
 return z>=48 and z<112 and(x>=64 and x<96 or x>=128 and x<160)
  or z>=192 and z<240 and(x>=48 and x<80 or x>=144 and x<176)
  or x>=96 and x<112 and z>=48 and z<56
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local G,P=V.require('WorldGeometry'),V.require('PaperSprite');local hs=V.require('Billboard').heightScale()
 local function src(x,z)return L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16 end
 local function draw(w,h,source,inside,point,shade)
  local vv=P.build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,point,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 for _,o in ipairs(objects)do local first=#out+1
  if o.kind=='dojoFloor'then
   draw(176,192,function(s,t)local x,z=s+16,t+48
    if R.replaced(x,z)then return 0x2c0,x%16,z%16 end
    return src(x,z)
   end,nil,function(s,t)return{s+16,0,t+48}end)
   draw(48,16,function(s,t)return src(s+80,t+240)end,function(s,t)local r,g,b=V.require('BuildingMesh').pixel(ts,src(s+80,t+240));return r+g+b>0 end,function(s,t)return{s+80,0,t+240}end)
  elseif o.kind=='dojoWall'then
   local h=c.wallHeight*hs
   local function wall(s,t)local x,z=s+16,t+16
    if x>=64 and x<80 or x>=128 and x<144 then return z<32 and 0x2c1 or 0x2c9,x%16,z%16 end
    if x>=96 and x<112 and z>=40 then return 0x2c9,x%16,z%16 end
    return src(x,z)
   end
   draw(176,32,wall,nil,function(s,t)return{s+16,h*(32-t)/32,48}end)
   draw(176,1,function(s)return wall(s,0)end,nil,function(s,t)return{s+16,h,48-c.wallDepth+t*c.wallDepth}end)
   for _,edge in ipairs{0,176}do draw(1,32,function(_,t)return wall(math.min(175,edge),t)end,nil,function(s,t)return{16+edge,h*(32-t)/32,48-c.wallDepth+s*c.wallDepth}end,c.sideShade)end
  else
   local crest=o.kind=='dojoCrest';local pillar=o.kind=='dojoPillar'
   local base=crest and 48.1 or o.y+o.h;local height=(crest and 16 or pillar and c.pillarHeight or c.statueHeight)*hs
   local depth=crest and .5 or pillar and c.pillarDepth or c.statueDepth
   local function source(s,t)return src(o.x+s,o.y+t)end
   local function inside(s,t)return R.inside(ts,L,o,s,t)end
   local function point(s,t,dep)return{o.x+s+ox*16,height*(o.h-t)/o.h+(crest and 3*hs or 0),base-dep+oz*16}end
   draw(o.w,o.h,source,inside,function(s,t)return{o.x+s,height*(o.h-t)/o.h+(crest and 3*hs or 0),base}end)
   -- Closed silhouette sides/cap follow native texels, without the floor
   -- rectangle or the old baked diagonal shadow moving with the object.
   for t=0,o.h-1 do for s=0,o.w-1 do if inside(s,t)then
    local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
    for _,e in ipairs{{-1,0,s,t,s,t+1},{1,0,s+1,t+1,s+1,t},{0,-1,s+1,t,s,t},{0,1,s,t+1,s+1,t+1}}do
     if not inside(s+e[1],t+e[2])then G.quad(out,point(e[3],e[4],0),point(e[5],e[6],0),point(e[5],e[6],depth),point(e[3],e[4],depth),uv,e[2]==-1 and 1 or c.sideShade)end
    end
   end end end
   if not crest then contacts[#contacts+1]={o.x+8+ox*16,base+oz*16,7,c.contactRadius,c.contactStrength}end
  end
  V.require('RoomLightRig').capture(L,{kind=o.kind=='dojoFloor'and 'card'or o.kind=='dojoCrest'and 'plant'or o.kind=='dojoWall'and 'wall'or o.kind},out,first,#out)
 end
end
function R.lighting(d)
 if not R.profile(d)then return end;local c=cfg();local sources={}
 for _,p in ipairs(c.lights)do sources[#sources+1]={at={p[1],c.lightHeight,p[2]},radius=c.lightRadius,power=c.lightPower,color=c.lightColor,spread=c.lightSpread}end
 return{fixed=true,ambient=c.ambient,sources=sources}
end
return R
