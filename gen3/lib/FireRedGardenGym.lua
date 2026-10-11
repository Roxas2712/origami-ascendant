-- Native Prismania conservatory: source art stays separate from floor donors.
-- CUT trees and trainers belong to the engine, never to this furniture plan.
local V=...;local R={}
local function cfg()return V.require('DioramaConfig').interiors.fireredGardenGym end
function R.profile(d)
 local L=d and d.midLayout
 return cfg().enabled and d and d.id=='FR_CELADON_CITY_GYM'and (d.renderPair or d.pair)=='building__rom_082d4d4c'and d.mapType==8 and L and L.width==14 and L.height==20 and L:midAt(6,0)==0x2b3 and L:midAt(6,6)==0x2b7 or nil
end
local heads={[0x285]=true,[0x286]=true,[0x287]=true,[0x297]=true,[0x28d]=true,[0x2ba]=true,[0x2bb]=true}
local tails={[0x28d]=true,[0x295]=true,[0x2bf]=true,[0x2be]=true}
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 for i=1,L.width*L.height do mask[i]={mid=8,void=true,separateSurface=true}end
 local function add(kind,x,y,w,h,p)p=p or{};p.kind=kind;p.x=x;p.y=y;p.w=w;p.h=h;objects[#objects+1]=p end
 add('gardenFloor',16,32,176,288);add('gardenWall',16,0,176,48)
 for _,x in ipairs{0,192}do add('gardenSide',x,0,16,288);add('gardenEnd',x,288,16,16)end
 for y=0,19 do for x=0,13 do local m=L:midAt(x,y)
  if heads[m]and tails[L:midAt(x,y+1)]then add('gardenHedge',x*16,y*16+8,16,21)end
  if m==0x2b6 or m==0x2b7 then add('gardenFlower',x*16,y*16,16,16)end
 end end
 for _,x in ipairs{64,128}do add('gardenStatue',x,240,16,32)end
 return{objects=objects,mask=mask,owners={}}
end
local hedgeRuns={{6,10},{4,12},{3,13},{2,14},{2,14},{1,15},{1,15},{1,15},{1,15},{0,16},{0,16},{0,16},{0,16},{0,16},{0,16},{1,15},{1,15},{2,14},{3,13},{5,11},{6,10}}
function R.hedgeInside(s,t)
 local a=hedgeRuns[t+1];return a and s>=a[1]and s<a[2]or false
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local G,P,B=V.require('WorldGeometry'),V.require('PaperSprite'),V.require('BuildingMesh');local hs=V.require('Billboard').heightScale()
 local function src(x,z)return L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16 end
 local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local bg={[0x428c8c]=true}
 for _,m in ipairs{0x281,0x282,0x289,0x28a}do for t=0,15 do for s=0,15 do bg[key(B.pixel(ts,m,s,t))]=true end end end
 local bottom={}
 for x=16,191 do bottom[x]=48;for z=0,47 do if bg[key(B.pixel(ts,src(x,z)))]then bottom[x]=z;break end end end
 local clear={}
 for _,o in ipairs(objects)do
  if o.kind=='gardenHedge'or o.kind=='gardenFlower'or o.kind=='gardenStatue'then
   local last=o.kind=='gardenHedge'and 24 or o.h
   for t=0,last-1 do for s=0,15 do clear[(o.y+t)*224+o.x+s]=o end end
  end
 end
 local function draw(w,h,source,inside,project,shade)
  local vv=P.build(ts,w,h,source,inside or function()return true end,0,h,1,shade,project,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 local function floorSource(x,z)
  local o=clear[z*224+x]
  if o then
   if o.kind=='gardenStatue'then return z<256 and 0x29d or 0x2a5,x%16,z%16 end
   -- The left wall has its own native shaded ground strip. Retain it
   -- beneath plants instead of inserting a bright rectangular floor donor.
   if x<32 then return math.floor(z/16)%2==0 and 0x289 or 0x28a,x%16,z%16 end
   local mid=(math.floor(x/16)+math.floor(z/16))%2==0 and 0x281 or 0x282
   if z<40 then return 0x289,x%16,z%16 end
   return mid,x%16,z%16
  end
  return src(x,z)
 end
 for _,o in ipairs(objects)do local first=#out+1
  local function source(s,t)return src(o.x+s,o.y+t)end
  if o.kind=='gardenFloor'then
   draw(o.w,o.h,function(s,t)return floorSource(o.x+s,o.y+t)end,function(s,t)local x,z=o.x+s,o.y+t;return z>=bottom[x]and L:midAt(math.floor(x/16),math.floor(z/16))~=8 end,function(s,t)return{o.x+s,0,o.y+t}end)
  elseif o.kind=='gardenWall'then
   local height=c.wallHeight*hs
   -- Group only columns sharing a native foot row. A quad spanning a corner
   -- would send its last vertex below the floor; close each step explicitly.
   local start=0
   while start<o.w do
    local base=bottom[o.x+start];local stop=start+1
    while stop<o.w and bottom[o.x+stop]==base do stop=stop+1 end
    draw(stop-start,base,function(s,t)return source(start+s,t)end,nil,function(s,t)return{o.x+start+s,height*(base-t)/base,base}end)
    draw(stop-start,c.wallDepth,function(s)return source(start+s,0)end,nil,function(s,t)return{o.x+start+s,height,base-c.wallDepth+t}end)
    if stop<o.w then local nextBase=bottom[o.x+stop];local lo=math.min(base,nextBase);local depth=math.abs(base-nextBase)
     draw(depth,base,function(_,t)return source(stop-1,t)end,nil,function(s,t)return{o.x+stop,height*(base-t)/base,lo+s}end,function()return c.sideShade end)
    end
    start=stop
   end
   for _,edge in ipairs{0,o.w}do local sx=math.min(o.w-1,edge);local base=bottom[o.x+sx]
    draw(c.wallDepth,base,function(_,t)return source(sx,t)end,nil,function(s,t)return{o.x+edge,height*(base-t)/base,base-c.wallDepth+s}end,function()return c.sideShade end)
   end
  elseif o.kind=='gardenSide'then
   draw(o.w,o.h,source,function(s,t)return key(B.pixel(ts,source(s,t)))~=0 end,function(s,t)return{o.x+s,c.cutawayHeight,o.y+t}end)
   for _,edge in ipairs{0,o.w}do draw(o.h,c.cutawayHeight,function(s)return source(math.min(15,edge),s)end,nil,function(s,t)return{o.x+edge,c.cutawayHeight-t,o.y+s}end,function()return c.sideShade end)end
  elseif o.kind=='gardenEnd'then
   local height=c.endHeight;local depth=c.endDepth;local front=o.y+16
   draw(16,16,source,nil,function(s,t)return{o.x+s,height*(16-t)/16,front}end)
   draw(16,depth,function(s)return source(s,0)end,nil,function(s,t)return{o.x+s,height,front-depth+t}end)
   for _,edge in ipairs{0,16}do draw(depth,16,function(_,t)return source(math.min(15,edge),t)end,nil,function(s,t)return{o.x+edge,height*(16-t)/16,front-depth+s}end,function()return c.sideShade end)end
  elseif o.kind=='gardenHedge'then
   -- Keep each shrub's visible texels, including its darker stacked edge.
   -- Only its overwritten lower contour comes from the isolated native shrub.
   local stacked=L:midAt(o.x/16,math.floor(o.y/16)+1)==0x28d
   draw(16,21,function(s,t)if stacked and t>=16 then return src(80+s,40+t)end;return source(s,t)end,R.hedgeInside,function(s,t)return{o.x+s,c.hedgeHeight*hs*(21-t)/21,o.y+21}end,function(_,t)return 1-c.hedgeBaseShade*math.max(0,(t-12)/9)end)
   contacts[#contacts+1]={o.x+8+ox*16,o.y+21+oz*16,7,c.contactRadius,c.contactStrength}
  elseif o.kind=='gardenFlower'then
   draw(16,16,source,function(s,t)return not bg[key(B.pixel(ts,source(s,t)))]end,function(s,t)return{o.x+s,c.flowerHeight*hs*(16-t)/16,o.y+16}end)
   contacts[#contacts+1]={o.x+8+ox*16,o.y+16+oz*16,5,c.contactRadius,c.contactStrength}
  elseif o.kind=='gardenStatue'then
   draw(16,32,source,function(s,t)return V.require('FireRedGymRooms').inside({kind='gymStatue',w=16,h=32},s,t)end,function(s,t)return{o.x+s,c.statueHeight*hs*(32-t)/32,o.y+32}end)
   contacts[#contacts+1]={o.x+8+ox*16,o.y+32+oz*16,7,c.contactRadius,c.contactStrength}
  end
  V.require('RoomLightRig').capture(L,{kind=o.kind=='gardenWall'and 'wall'or 'plant'},out,first,#out)
 end
end
function R.lighting(d)
 if not R.profile(d)then return end
 local c=cfg();local sources={}
 for _,a in ipairs(c.sources)do sources[#sources+1]={at={a[1],c.lightHeight,a[2]},power=a[3],nightPower=a[5]and a[3]*c.windowNightScale or a[3],radius=a[4],color=a[5]and c.windowColor or c.lampColor,spread=c.spread}end
 return{ambient=c.ambient,night=c.nightAmbient,sources=sources}
end
return R
