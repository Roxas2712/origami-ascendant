-- Low timber maze: original tops, connected extruded edges, native floor hatches.
local V=...
local T={}
local timber={}
for _,m in ipairs({0x280,0x281,0x282,0x283,0x284,0x288,0x289,0x28a,0x28b,0x28c,0x290,0x291,0x292,0x293,0x294})do timber[m]=true end
function T.isTimber(m)return timber[m]or false end
function T.band(m)
 if timber[m]then return 0,16 elseif m==0x286 then return 12,16 end
end
function T.occupied(L,s,t)
 local x,y=math.floor(s/16),math.floor(t/16)
 if x<0 or y<0 or x>=L.width or y>=L.height then return false end
 local a,b=T.band(L:midAt(x,y));return a and t%16>=a and t%16<b or false
end
function T.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if not(c.enabled and c.trickSteps.enabled and d.mapType==8 and d.pair=='building__trick_house_puzzle'
  and L and L.width==16 and L.height==22 and L:midAt(0,0)==0x201)then return end
 local id=d.id or d.name
 if id=='EM_ROUTE110_TRICK_HOUSE_PUZZLE2'and L:midAt(2,0)==0x205 and L:midAt(3,0)==0x206
  or id=='EM_ROUTE110_TRICK_HOUSE_PUZZLE4'and L:midAt(2,0)==0x201 and L:midAt(2,18)==0x286
  or id=='EM_ROUTE110_TRICK_HOUSE_PUZZLE6'and L:midAt(0,2)==0x289 and L:midAt(5,2)==0x280 and L:midAt(8,3)==0x280
  or id=='EM_ROUTE110_TRICK_HOUSE_PUZZLE7'and L:midAt(0,2)==0x280 and L:midAt(3,2)==0x280 and L:midAt(12,3)==0x289 then return c.homeRooms.trickSteps end
end
function T.lighting(d)
 if T.profile(d)then return T.roomLighting(d)end
end
function T.roomLighting(d)
 local c=V.require('DioramaConfig').emeraldInteriors.trickSteps.lighting;local sources={}
 for _,a in ipairs(c.ceilingPositions)do sources[#sources+1]={at={a[1],c.height,a[2]},radius=c.radius,power=c.power,nightPower=c.nightPower,color=c.color,spread=c.spread,cone=-.1}end
 for x=0,14 do if d.midLayout:midAt(x,0)==0x205 then
  sources[#sources+1]={at={x*16+8,c.windowHeight,33},radius=c.windowRadius,power=c.windowPower,nightPower=c.windowNightPower,color=c.windowColor,spread={5,1},direction={0,-.35,1},cone=.15}
 end end
 return{ambient=c.ambient,night=c.night,localSelection=true,sources=sources}
end
function T.rearPlan(L)
 local objects,mask={},{}
 for x=0,14 do
  local pillar=L:midAt(x,0)==0x206
  objects[#objects+1]={kind='trickStepRearWall',x=x,y=0,w=16,h=32,clean=pillar,noContact=true}
  for y=0,1 do mask[y*L.width+x+1]={mid=1,void=true}end
  if pillar then
   objects[#objects+1]={kind='trickStepPillar',x=x,y=0,w=16,h=48,noContact=true}
   mask[2*L.width+x+1]=0x210
  end
 end
 return objects,mask
end
function T.plan(d)
 if not T.profile(d)then return end
 local L=d.midLayout;local objects,mask=T.rearPlan(L)
 for y=2,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  local a,b=T.band(m)
  if a then objects[#objects+1]={kind='trickStepWall',x=x,y=y,w=16,h=16,mid=m,first=a,last=b,noContact=true};mask[y*L.width+x+1]={mid=1,void=true}
  elseif m==1 then mask[y*L.width+x+1]={mid=1,void=true}end
 end end
 return objects,mask
end
function T.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.trickSteps;local G=V.require('WorldGeometry')
 if o.kind=='trickStepRearWall'or o.kind=='trickStepPillar'then
  local pillar=o.kind=='trickStepPillar';local last=pillar and 37 or 32
  local h=(pillar and c.pillarHeight or c.wallHeight)*cfg.heightScale
  local vv=V.require('PaperSprite').build(ts,16,pillar and 48 or 32,function(s,t)
   local m=o.clean and(t<16 and 0x201 or 0x209)or L:midAt(o.x,math.floor(t/16));return m,s,t%16
  end,function(s,t)return t<last and(not pillar or(s<7 and t>=1))end,0,last,1,nil,function(s,t)return{x+s,h*(last-t)/last,z+32+(pillar and .25 or 0)}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end;return
 end
 local mid=L:midAt(o.x,o.y);local a,b=T.band(mid)
 local h=(mid==0x286 and c.lipHeight or c.height)*cfg.heightScale
 G.quad(out,{x,0,z},{x+16,0,z},{x+16,0,z+16},{x,0,z+16},G.uv(ts,0x208,0,0,16,16,.5),1)
 if a>0 then G.quad(out,{x,.01,z},{x+16,.01,z},{x+16,.01,z+a},{x,.01,z+a},G.uv(ts,mid,0,0,16,a,.5),1)end
 G.quad(out,{x,h,z+a},{x+16,h,z+a},{x+16,h,z+b},{x,h,z+b},G.uv(ts,mid,0,a,16,b,.5),1)
 local function edge(ax,az,bx,bz)
  G.quad(out,{x+ax,h,z+az},{x+bx,h,z+bz},{x+bx,0,z+bz},{x+ax,0,z+az},G.uv(ts,0x235,2,8,14,15,.5),c.sideShade)
  if contacts then contacts[#contacts+1]={x+(ax+bx)/2,z+(az+bz)/2,ax==bx and 1.2 or math.abs(bx-ax)*.4375,az==bz and 1.2 or math.abs(bz-az)*.4375,c.contactStrength}end
 end
 local function occupied(s,t)return T.occupied(L,o.x*16+s,o.y*16+t)end
 -- Contiguous exposed runs retain one native wood face and one soft contact.
 local function runs(first,last,open,draw)
  local start
  for i=first,last do
   if i<last and open(i)then start=start or i
   elseif start then draw(start,i);start=nil end
  end
 end
 runs(a,b,function(t)return not occupied(-1,t)end,function(p,q)edge(0,p,0,q)end)
 runs(a,b,function(t)return not occupied(16,t)end,function(p,q)edge(16,q,16,p)end)
 runs(0,16,function(s)return not occupied(s,a-1)end,function(p,q)edge(q,a,p,a)end)
 runs(0,16,function(s)return not occupied(s,b)end,function(p,q)edge(p,b,q,b)end)
end
return T
