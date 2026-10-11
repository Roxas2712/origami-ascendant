-- Trainer Hill's native roof drawing contains a hanging facade, not more floor.
local V=...;local R={}
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d and d.midLayout
 if c.enabled and c.hillRoof.enabled and d.id=='EM_TRAINER_HILL_ROOF'and d.pair=='building__trainer_hill'
  and d.mapType==8 and L and L.width==26 and L.height==16 and L:midAt(12,6)==0x363 then return c.homeRooms.hillRoof end
end
function R.scene(d)if R.profile(d)then return V.require('DioramaConfig').emeraldInteriors.hillRoof end end
function R.lighting(d)local c=R.scene(d);return c and c.light end
function R.light(d,state)
 local c=R.scene(d);if not c then return end
 local night=V.require('DayNight').windowLight()
 state.sun=c.daySun*(1-night)+c.nightSun*night
end
function R.doorPose(d,a)
 if R.profile(d)and a and a.x==15 and a.y==5 then return{height=32*V.require('DioramaConfig').emeraldInteriors.heightScale,base=0,top=0}end
end
-- Pixel measurements are source geometry, not replacements for map/collision data.
function R.deckEdge(s)return 160+math.max(0,math.min(48,(s-96)/2,(304-s)/2))end
local function sourceDeckEdge(s)return 160+math.max(0,math.min(48,math.floor((s-96)/2),math.floor((303-s)/2)))end
local function nativeSeam(s)return math.min(80,37+math.floor(math.min(s-112,287-s)/2))end
local function nativeBase(s)return math.min(112,nativeSeam(s)+32)end
local function bay(s)return s>=136 and s<168 or s>=232 and s<264 end
local function hutBase(s)return math.min(112,69+math.min(s-112,288-s)/2)end
function R.plan(d)
 if not R.profile(d)then return end
 local mask,objects={},{}
 for i=1,26*16 do mask[i]={mid=0x208,void=true}end
 local function add(kind,x,y,w,h,extra)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w;o.h=h;o.noContact=true;objects[#objects+1]=o
 end
 add('hillRoofDeck',0,0,400,256);add('hillRoofHut',7,0,176,112)
 for _,x in ipairs({136,232})do add('hillRoofDoor',x/16,72/16,32,24)end
 -- Individual posts, with intact cream centres. Palette cutouts would hollow them out.
 for _,x in ipairs({96,288})do for y=60,140,16 do add('hillRoofPost',x/16,y/16,16,16,{front=y+16,sourceX=192,sourceY=172})end end
 for x=144,240,16 do add('hillRoofPost',x/16,172/16,16,16,{front=188,sourceX=x,sourceY=172})end
 for _,x in ipairs({0,32,352,384})do add('hillRoofBollard',x/16,104/16,16,20,{front=124})end
 return objects,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.hillRoof;local G=V.require('WorldGeometry')
 local function src(s,t)return L:midAt(math.floor(s/16),math.floor(t/16)),s%16,t%16 end
 local function draw(w,h,source,inside,point,shade)
  local vv=V.require('PaperSprite').build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,point,.5)
  for _,v in ipairs(vv)do v[2]=v[2]*cfg.heightScale;out[#out+1]=v end
 end
 if o.kind=='hillRoofDeck'then
  draw(400,208,function(s,t)
   if t>=64 then return 0x36b,s%16,t%16 end
   -- The native north band belongs to the roof's back edge; remove only the posts.
   if s>=96 and s<112 or s>=288 and s<304 then return src(80,t)end
   return src(s,t)
  end,function(s,t)return t<R.deckEdge(s)and not(s>=112 and s<288 and t<hutBase(s))end,function(s,t)return{x+s,0,z+t}end)
  -- Each one-pixel strip follows the sloping edge. Cap and facade share vertices.
  for s=0,399 do
   local edge=R.deckEdge(s);local foot=edge+8;local slope=R.deckEdge(s+1)-edge;local sourceEdge=sourceDeckEdge(s)
   draw(1,8,function(_,t)return src(s,sourceEdge+t)end,nil,function(u,t)return{x+s+u,0,z+edge+t+slope*u}end)
   draw(1,248-sourceEdge,function(_,t)return src(s,sourceEdge+8+t)end,nil,function(u,t)return{x+s+u,-t*c.facadeScale,z+foot+slope*u}end,G.HANGING_FACADE)
  end
 elseif o.kind=='hillRoofHut'then
  for sx=0,175 do
   local s=112+sx;local seam=nativeSeam(s);local bottom=nativeBase(s);local base=hutBase(s);local nextBase=hutBase(s+1)
   draw(1,seam,function(_,t)return src(s,t)end,nil,function(u,t)return{x+sx+u,c.hutHeight,z+t*(base+(nextBase-base)*u)/seam}end)
   draw(1,bottom-seam,function(_,t)
    local y=seam+t
    if bay(s)and y>=72 then return src(s<200 and 180 or 220,85)end
    return src(s,y)
   end,nil,function(u,t)return{x+sx+u,c.hutHeight*(1-t/(bottom-seam)),z+base+(nextBase-base)*u}end)

  end
 elseif o.kind=='hillRoofDoor'then
  draw(32,24,function(s,t)return src(o.x*16+s,72+t)end,nil,function(s,t)return{x+s,24-t,z-o.y*16+96}end)
 elseif o.kind=='hillRoofPost'then
  draw(16,16,function(s,t)return src(o.sourceX+s,o.sourceY+t)end,function(s,t)
   return s>=(t<9 and 5 or 4)and s<(t<9 and 11 or 12)
  end,function(s,t)return{x+s,c.postHeight*(16-t)/16,z-o.y*16+o.front}end)
  if contacts then contacts[#contacts+1]={x+8,z-o.y*16+o.front,5,2,c.contactStrength}end
 elseif o.kind=='hillRoofBollard'then
  draw(16,20,function(s,t)return src(o.x*16+s,104+t)end,function(s,t)
   local lo=t==0 and 7 or t<14 and 6 or t==14 and 5 or 4;return s>=lo and s<16-lo
  end,function(s,t)return{x+s,c.bollardHeight*(20-t)/20,z-o.y*16+o.front}end)
  if contacts then contacts[#contacts+1]={x+8,z-o.y*16+o.front,4,2,c.contactStrength}end
 end
end
return R
