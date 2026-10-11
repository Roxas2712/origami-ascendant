-- Native sliding-door puzzle. Live metatiles are the only door-state authority.
local V=...;local D={}
local caps={[0x226]=true,[0x222]=true,[0x22d]=true,[0x21e]=true,[0x22e]=true,[0x22f]=true}
local fronts={[0x235]=true,[0x236]=true,[0x237]=true,[0x23a]=true,[0x23d]=true,[0x24a]=true,[0x24d]=true}
local backs={[0x218]=true,[0x219]=true}
local horizontal={[0x238]={closed=true,red=true},[0x23b]={closed=true},[0x248]={red=true},[0x24b]={}}
function D.band(mid)if backs[mid]then return 11,16 elseif caps[mid]or fronts[mid]then return 0,16 end end
function D.occupied(L,s,t)
 local x,y=math.floor(s/16),math.floor(t/16)
 if x<0 or y<0 or x>=L.width or y>=L.height then return false end
 local a,b=D.band(L:midAt(x,y));return a and t%16>=a and t%16<b or false
end
function D.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.trickDoors.enabled and(d.id or d.name)=='EM_ROUTE110_TRICK_HOUSE_PUZZLE3'
  and d.mapType==8 and d.pair=='building__trick_house_puzzle'and L and L.width==16 and L.height==22
  and L:midAt(0,0)==0x201 and L:midAt(0,2)==0x226 and L:midAt(4,9)==0x22e then return c.homeRooms.trickDoors end
end
function D.lighting(d)if D.profile(d)then return V.require('EmeraldTrickSteps').roomLighting(d)end end
function D.plan(d)
 if not D.profile(d)then return end
 local L=d.midLayout;local objects,mask=V.require('EmeraldTrickSteps').rearPlan(L);local claimed={}
 local function hide(x,y,w,h)for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=1,void=true}end end end
 for y=2,L.height-1 do for x=0,L.width-1 do
  local mid=L:midAt(x,y);local k=y*L.width+x+1;local a,b=D.band(mid)
  if a and not claimed[k]then
   local front=caps[mid]and fronts[L:midAt(x,y+1)]
   local depth=front and 32 or 16
   objects[#objects+1]={kind='trickDoorWoodWall',x=x,y=y,w=16,h=depth,mid=mid,first=a,depth=depth,front=front,noContact=true}
   hide(x,y,1,front and 2 or 1);if front then claimed[k+L.width]=true end
  end
  local state=horizontal[mid]
  if state then
   objects[#objects+1]={kind='trickDoorFloor',x=x,y=y,w=32,h=32,noContact=true}
   if state.closed then objects[#objects+1]={kind='trickDoorWallH',x=x,y=y,w=32,h=32,noContact=true}
   else for _,part in ipairs({0,1})do objects[#objects+1]={kind='trickDoorWallJamb',x=x,y=y,w=32,h=32,part=part,noContact=true}end end
   hide(x,y,2,2)
  end
  if mid==0x23a or mid==0x23d then
   objects[#objects+1]={kind='trickDoorWallV',x=x,y=y,w=16,h=32,red=mid==0x23a,noContact=true}
   hide(x,y+1,1,1)
  end
  if mid==1 then hide(x,y,1,1)end
 end end
 return objects,mask
end
function D.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.trickDoors;local G=V.require('WorldGeometry')
 local function floor(xx,zz,w,h)
  for t=0,h-1,16 do for s=0,w-1,16 do G.quad(out,{xx+s,0,zz+t},{xx+s+16,0,zz+t},{xx+s+16,0,zz+t+16},{xx+s,0,zz+t+16},G.uv(ts,0x208,0,0,16,16,.5),1)end end
 end
 local function band(width,height,source,inside,project)
  local vv=V.require('PaperSprite').build(ts,width,height,source,inside,0,height,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 if o.kind=='trickDoorFloor'then
  floor(x,z,32,32)
  -- Floor above the original lintel is preserved; no coloured frame stays flat.
  band(32,32,source,function(_,t)return t<8 end,function(s,t)return{x+s,.01,z+t}end);return
 end
 if o.kind=='trickDoorWallH'or o.kind=='trickDoorWallJamb'then
  local h=c.doorHeight*cfg.heightScale
  band(32,32,source,function(s,t)
   if t<8 then return false end
   if o.kind=='trickDoorWallH'then return true end
   -- Open jamb outline: two pixels at the cap, three below it.
   local width=t<12 and 2 or 3
   return o.part==0 and s<width or o.part==1 and s>=32-width
  end,function(s,t)return{x+s,h*(32-t)/24,z+32}end)
  return
 end
 if o.kind=='trickDoorWallV'then
  floor(x,z+16,16,16)
  local h=c.doorHeight*cfg.heightScale;local half=c.leafThickness/2;local start=z+16;local last=start+c.leafDepth
  local a=o.red and 0x238 or 0x23b;local b=o.red and 0x240 or 0x243
  local function art(s,t)return(t<16 and a or b)+math.floor(s/16),s%16,t%16 end
  for _,sign in ipairs({-1,1})do band(16,32,art,function(_,t)return t>=8 end,function(s,t)return{x+8+half*sign,h*(32-t)/24,start+s*c.leafDepth/16}end)end
  local mid=L:midAt(o.x,o.y)
  G.quad(out,{x+8-half,h,start},{x+8+half,h,start},{x+8+half,h,last},{x+8-half,h,last},G.uv(ts,mid,5,0,11,16,.5),1)
  G.quad(out,{x+8-half,h,last},{x+8+half,h,last},{x+8+half,0,last},{x+8-half,0,last},G.uv(ts,mid,5,0,11,16,.5),1)
  return
 end
 local h=c.woodHeight*cfg.heightScale;local a,depth=o.first,o.depth
 floor(x,z,16,depth)
 if a>0 then G.quad(out,{x,.01,z},{x+16,.01,z},{x+16,.01,z+a},{x,.01,z+a},G.uv(ts,o.mid,0,0,16,a,.5),1)end
 G.quad(out,{x,h,z+a},{x+16,h,z+a},{x+16,h,z+depth},{x,h,z+depth},G.uv(ts,o.mid,0,a,16,16,.5),1)
 local function occupied(s,t)return D.occupied(L,o.x*16+s,o.y*16+t)end
 local function edge(ax,az,bx,bz,front)
  local m=front and L:midAt(o.x,o.y+1)or 0x235
  G.quad(out,{x+ax,h,z+az},{x+bx,h,z+bz},{x+bx,0,z+bz},{x+ax,0,z+az},G.uv(ts,m,0,0,16,16,.5),front and 1 or c.sideShade)
  if contacts then contacts[#contacts+1]={x+(ax+bx)/2,z+(az+bz)/2,ax==bx and 1.2 or math.abs(bx-ax)*.4375,az==bz and 1.2 or math.abs(bz-az)*.4375,c.contactStrength}end
 end
 local function runs(first,last,open,draw)local start;for i=first,last do if i<last and open(i)then start=start or i elseif start then draw(start,i);start=nil end end end
 runs(a,depth,function(t)return not occupied(-1,t)end,function(p,q)edge(0,p,0,q)end)
 runs(a,depth,function(t)return not occupied(16,t)end,function(p,q)edge(16,q,16,p)end)
 runs(0,16,function(s)return not occupied(s,a-1)end,function(p,q)edge(q,a,p,a)end)
 runs(0,16,function(s)return not occupied(s,depth)end,function(p,q)edge(p,depth,q,depth,o.front)end)
end
return D
