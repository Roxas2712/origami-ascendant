-- Sevii ferry halls: native wall course, open railings and quay surfaces.
-- Ferry/sailor objects and all travel/door scripts stay engine-owned.
local V=...;local R={}
local ids={FR_BIRTH_ISLAND_HARBOR=true,FR_FIVE_ISLAND_HARBOR=true,FR_FOUR_ISLAND_HARBOR=true,FR_NAVEL_ROCK_HARBOR=true,FR_SEVEN_ISLAND_HARBOR=true,FR_SIX_ISLAND_HARBOR=true,FR_THREE_ISLAND_HARBOR=true,FR_TWO_ISLAND_HARBOR=true,SEVII_ONE_ISLAND_HARBOR=true}
local function cfg()return V.require('DioramaConfig').interiors.fireredHarbors end
function R.profile(d)
 local L=d and d.midLayout
 return cfg().enabled and d and ids[d.id] and d.pair=='harbor' and d.mapType==8 and L and L.width==18 and L.height==14 and L:midAt(8,1)==0x2c1 and L:midAt(8,7)==0x2ad and L:midAt(0,12)==0x2a5 or nil
end
function R.plan(d)
 if not R.profile(d)then return end;local mask={};for i=1,252 do mask[i]={mid=0x287,void=true,separateSurface=true}end
 return{mask=mask,objects={{kind='harborFloor'},{kind='harborWall'},{kind='harborRails'},{kind='harborGangway'}}}
end
function R.railInside(s,t)
 return t>=0 and t<12 and (t<4 or t<11 and s%8>=2 and s%8<=5 or t==11 and s%8>=3 and s%8<=4)
end
-- Native rail drawings are removed from the floor only in measured courses.
function R.railFloor(x,z)
 return z>=64 and z<76 and (x<104 or x>=168) or z>=68 and z<108 and (x>=96 and x<104 or x>=168 and x<176)
  or z>=96 and z<108 and (x>=96 and x<128 or x>=144 and x<176) or z>=192 and z<204
end
function R.build(out,d,ts,ox,oz,contacts)
 if not R.profile(d)then return end
 local L,c=d.midLayout,cfg();local P,G=V.require('PaperSprite'),V.require('WorldGeometry');local hs=V.require('Billboard').heightScale()
 local function src(x,z)return L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16 end
 local function draw(w,h,source,inside,point,shade)
  local vv=P.build(ts,w,h,source,inside or function()return true end,0,h,1,type(shade)=='function'and shade or shade and function()return shade end or nil,point,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 local function ground(s,t)local z=t+48;if R.railFloor(s,z)then return 0x282,s%16,z%16 end;return src(s,z)end
 draw(272,160,ground,function(s,t)return not(s>=128 and s<144 and t+48>=112 and t+48<124)end,function(s,t)return{s,0,t+48}end,function(s,t)
  local m=ground(s,t);return m==0x12b and G.WATER or 1
 end)
 local first=#out+1;local height=c.wallHeight*hs
 -- The door artwork remains in the facade. Its native warp must not cut
 -- through the wall header (the generic room builder did exactly that).
 draw(272,40,function(s,t)return src(s,t+8)end,nil,function(s,t)return{s,height*(40-t)/40,48}end)
 draw(272,1,function(s)return src(s,8)end,nil,function(s,t)return{s,height,48-c.wallDepth+t*c.wallDepth}end)
 for _,x in ipairs{0,272}do draw(1,40,function(_,t)return src(math.min(271,x),t+8)end,nil,function(s,t)return{x,height*(40-t)/40,48-c.wallDepth+s*c.wallDepth}end,c.sideShade)end
 V.require('RoomLightRig').capture(L,{kind='wall'},out,first,#out)
 local railH=c.railHeight*hs
 local function railSource(s,t)return 0x28d,s%16,t end
 local function rail(length,point)
  draw(length,12,railSource,R.railInside,function(s,t)return point(s,railH*(12-t)/12,0)end)
  -- One-pixel depth and closed top; holes are true missing geometry.
  draw(length,12,railSource,R.railInside,function(s,t)return point(s,railH*(12-t)/12,-c.railDepth)end,c.sideShade)
  draw(length,1,function(s)return 0x28d,s%16,1 end,nil,function(s,t)return point(s,railH,-c.railDepth+t*c.railDepth)end)
 end
 for _,a in ipairs{{0,102,68},{170,102,68},{100,25,100},{145,27,100},{0,272,196}}do
  rail(a[2],function(s,h,depth)return{a[1]+s,h,a[3]+depth}end)
 end
 for _,x in ipairs{102,170}do rail(32,function(s,h,depth)return{x+depth,h,68+s}end)end
 -- Six shallow native gangway treads descend toward the ferry. Keep their
 -- 16-pixel footprint and expose a short front riser instead of a flat stripe.
 for step=0,5 do local z=112+step*2;local y=c.gangwayDepth*(6-step)/6
  draw(16,2,function(s,t)return src(128+s,z+t)end,nil,function(s,t)return{128+s,y,z+t}end)
  draw(16,1,function(s)return src(128+s,z+1)end,nil,function(s,t)return{128+s,y-c.gangwayDepth*t/6,z+2}end,c.sideShade)
  for _,x in ipairs{128,144}do draw(1,2,function(_,t)return src(math.min(143,x),z+t)end,nil,function(s,t)return{x,y*(1-s),z+t}end,c.sideShade)end
 end
 draw(16,1,function(s)return src(128+s,112)end,nil,function(s,t)return{128+s,c.gangwayDepth*t,112}end,c.sideShade)
end
function R.lighting(d)
 if not R.profile(d)then return end;local c=cfg();local hs=V.require('Billboard').heightScale();local sources={}
 for _,x in ipairs{56,88,184,216}do sources[#sources+1]={at={x,c.wallHeight*hs*.55,49},power=c.windowPower,nightPower=c.windowNightPower,radius=c.windowRadius,color=c.windowColor,nightColor=c.windowNightColor,spread={12,4},direction={0,-.7,1}}end
 sources[#sources+1]={at={136,c.ceilingHeight,100},power=c.ceilingPower,nightPower=c.ceilingNightPower,radius=c.ceilingRadius,color=c.ceilingColor,spread={24,18}}
 return{ambient=c.ambient,night=c.night,sources=sources}
end
return R
