-- Event-island ferry halls. The ferry, sailor and travel script stay native.
local V=...;local H={}
local ids={EM_BIRTH_ISLAND_HARBOR=true,EM_NAVEL_ROCK_HARBOR=true}
function H.profile(d)
 local c=V.require('DioramaConfig').interiors.emIslandHarbors;local L=d and d.midLayout
 return c.enabled and d and ids[d.id]and d.mapType==8 and d.pair=='general__island_harbor'
  and L and L.width==18 and L.height==14 and L:midAt(8,2)==0x20e and L:midAt(8,5)==0x239 and c or nil
end
function H.plan(d)
 if not H.profile(d)then return end
 local mask={};for i=1,18*14 do mask[i]={mid=0x201,void=true,separateSurface=true}end
 return{mask=mask,objects={{kind='islandHarborHall'}}}
end
function H.build(out,d,ts,ox,oz,contacts)
 local c=H.profile(d);if not c then return end
 local L=d.midLayout;local G=V.require('WorldGeometry');local xx,zz=ox*16,oz*16
 local function source(x,y)return L:midAt(math.floor(x/16),math.floor(y/16)),x%16,y%16 end
 local function draw(w,h,src,inside,point,shade)
  local vv=V.require('PaperSprite').build(ts,w,h,src,inside or function()return true end,0,h,1,type(shade)=='function'and shade or shade and function()return shade end,
   function(s,t)local p=point(s,t);return{p[1]+xx,p[2],p[3]+zz}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function railFloor(s,t)
  return t>=64 and t<77 and(s<84 or s>=188)or t>=80 and t<93 and(s>=80 and s<120 or s>=152 and s<192)
   or t>=64 and t<93 and(s>=80 and s<86 or s>=186 and s<192)or t>=192 and t<205
 end
 local function floor(s,t)
  local y=t+48
  if railFloor(s,y)then return y>=192 and 0x170 or 0x3a1,s%16,y%16 end
  return source(s,y)
 end
 draw(272,160,floor,nil,function(s,t)return{s,0,t+48}end,function(s,t)local m=floor(s,t);return m==0x170 and G.WATER or 1 end)
 -- Native wall row: upper trim to lower edge, with cap and closed returns.
 local first=#out+1
 draw(272,32,function(s,t)return source(s,16+t)end,nil,function(s,t)return{s,c.wallHeight*(1-t/32),48}end)
 draw(272,1,function(s)return source(s,16)end,nil,function(s,t)return{s,c.wallHeight,48-c.wallDepth+t*c.wallDepth}end)
 for _,x in ipairs{0,272}do draw(1,32,function(_,t)return source(math.min(x,271),16+t)end,nil,function(s,t)return{x,c.wallHeight*(1-t/32),48-c.wallDepth+s*c.wallDepth}end,c.sideShade)end
 V.require('RoomLightRig').capture(L,{kind='wall'},out,first,#out)
 local pixel=V.require('BuildingMesh').pixel
 local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local background={}
 for _,m in ipairs{0x170,0x3a1}do for y=0,15 do for x=0,15 do background[key(pixel(ts,m,x,y))]=true end end end
 local function railInside(_,_,mid,u,v)return v<13 and not background[key(pixel(ts,mid,u,v))]end
 local function rail(ax,az,bx,bz)
  local length=math.sqrt((bx-ax)^2+(bz-az)^2)
  local dx,dz=(bx-ax)/length,(bz-az)/length
  local function pt(s,h,depth)return{ax+dx*s-dz*depth,h,az+dz*s+dx*depth}end
  local function src(s,t)return 0x3c2,s%16,t end
  draw(length,13,src,railInside,function(s,t)return pt(s,c.railHeight*(1-t/13),0)end)
  draw(length,13,src,railInside,function(s,t)return pt(s,c.railHeight*(1-t/13),-c.railDepth)end,c.sideShade)
  draw(length,1,function(s)return 0x3c2,s%16,0 end,nil,function(s,t)return pt(s,c.railHeight,-c.railDepth+t*c.railDepth)end)
 end
 for _,r in ipairs{{0,68,82,68},{82,68,82,84},{82,84,120,84},{152,84,190,84},{190,84,190,68},{190,68,272,68},{0,196,272,196}}do rail(unpack(r))end
 -- The painted gangway is a small solid landing; it ends before the ferry
 -- object's native anchor and must not turn the water into walkable geometry.
 draw(32,16,function(s,t)return source(120+s,80+t)end,nil,function(s,t)return{120+s,c.gangwayHeight,80+t}end)
 draw(32,8,function(s,t)return source(120+s,96+t)end,nil,function(s,t)return{120+s,c.gangwayHeight*(1-t/8),96}end,c.sideShade)
 for _,x in ipairs{120,152}do draw(1,16,function(_,t)return source(math.min(x,151),80+t)end,nil,function(s,t)return{x,c.gangwayHeight*(1-s),80+t}end,c.sideShade)end
end
function H.actorHeight(d,x,z,gid)
 local c=H.profile(d);if c and gid~=140 and x+8>=120 and x+8<152 and z+16>=80 and z+16<=96 then return c.gangwayHeight end
end
function H.doorPose(d,a)
 local c=H.profile(d);if c and a and a.x==8 and a.y==2 then return{height=c.wallHeight,base=0,top=0}end
end
function H.lighting(d)
 local c=H.profile(d);if not c then return end
 local sources={}
 for _,x in ipairs{40,72,104,168,200,232}do sources[#sources+1]={at={x,c.wallHeight*.65,49},power=c.windowPower,nightPower=c.windowNightPower,radius=c.windowRadius,color=c.windowColor,nightColor=c.windowColor,spread={8,3},direction={0,-.5,1}}end
 sources[#sources+1]={at={136,c.ceilingHeight,70},power=c.ceilingPower,nightPower=c.ceilingNightPower,radius=c.ceilingRadius,color=c.ceilingColor,spread={28,12}}
 return{ambient=c.ambient,night=c.night,sources=sources}
end
return H
