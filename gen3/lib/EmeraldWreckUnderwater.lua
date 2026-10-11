-- Submerged ship compartments: native walls and an open connecting hatch.
-- Dark deck patches and resurfacing zones are floor artwork, never furniture.
local V=...;local U={}
local rooms={EM_ABANDONED_SHIP_UNDERWATER1={8,8},EM_ABANDONED_SHIP_UNDERWATER2={22,8}}
local function cfg()return V.require('DioramaConfig').emeraldInteriors.wreck.underwater end
function U.profile(d)
 local a=V.require('DioramaConfig').emeraldInteriors;local r=d and rooms[d.id];local L=d and d.midLayout
 if a.enabled and a.wreck.enabled and cfg().enabled and r and tonumber(d.mapType)==5 and d.pair=='general__inside_ship'and L and L.width==r[1]and L.height==r[2]and L:midAt(1,0)==0x2ce then return cfg().profile end
end
function U.plan(d)
 if not U.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 for y=0,L.height-1 do for x=0,L.width-1 do if y<2 or L:midAt(x,y)==0x201 then mask[y*L.width+x+1]={mid=0x201,void=true}end end end
 local x=0;while x<L.width do local m=L:midAt(x,0)
  if m==0x2d8 then
   objects[#objects+1]={kind='wreckUnderwaterHatch',x=x,y=0,w=48,h=32,noContact=true}
   mask[L.width+x+2]=0x2cf;x=x+3
  elseif m>=0x2cc and m<=0x2ce then objects[#objects+1]={kind='wreckUnderwaterWall',x=x,y=0,w=16,h=32,noContact=true};x=x+1
  else x=x+1 end
 end
 return objects,mask
end
function U.build(out,L,ts,o,x,z)
 local c=cfg();local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local B=V.require('BuildingMesh');local hs=V.require('DioramaConfig').emeraldInteriors.heightScale;local h=c.wallHeight*hs
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),math.floor(t/16)),s%16,t%16 end
 local function inside(s,t)
  if o.kind~='wreckUnderwaterHatch'then return true end
  local m,u,v=source(s,t);local r,g,b=B.pixel(ts,m,u,v)
  -- Native hatch opening is the same dark blue as the surrounding deep deck.
  local rr,gg,bb=B.pixel(ts,0x2dc,8,8)
  return math.abs(r-rr)+math.abs(g-gg)+math.abs(b-bb)>.005
 end
 local vv=P.build(ts,o.w,32,source,inside,0,32,1,nil,function(s,t)return{x+s,h*(32-t)/32,z+32}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
 for sx=0,o.w-1,16 do
  local mid=L:midAt(o.x+sx/16,0)
  G.quad(out,{x+sx,h,z+32-c.wallDepth},{x+sx+16,h,z+32-c.wallDepth},{x+sx+16,h,z+32},{x+sx,h,z+32},G.uv(ts,mid,0,0,16,3,.5),1)
 end
 -- Closed end faces and back, except the actual native hatch passage.
 for _,sx in ipairs{0,o.w}do G.quad(out,{x+sx,h,z+32-c.wallDepth},{x+sx,h,z+32},{x+sx,0,z+32},{x+sx,0,z+32-c.wallDepth},G.uv(ts,0x2d7,8,8,9,9,.5),c.sideShade)end
 if o.kind=='wreckUnderwaterWall'then
  G.quad(out,{x+o.w,h,z+32-c.wallDepth},{x,h,z+32-c.wallDepth},{x,0,z+32-c.wallDepth},{x+o.w,0,z+32-c.wallDepth},G.uv(ts,0x2d7),c.sideShade)
 else
  -- Give the opening a real depth; preserve the native curved front outline.
  for t=0,31 do for s=0,o.w-1 do if inside(s,t)then for _,q in ipairs{{1,0},{-1,0},{0,1},{0,-1}}do
   local nx,ny=s+q[1],t+q[2]
   if nx>=0 and nx<o.w and ny>=0 and ny<32 and not inside(nx,ny)then
    local ax,ay,bx,by
    if q[1]~=0 then ax=s+(q[1]>0 and 1 or 0);bx=ax;ay=t;by=t+1 else ax=s;bx=s+1;ay=t+(q[2]>0 and 1 or 0);by=ay end
    G.quad(out,{x+ax,h*(32-ay)/32,z+32},{x+bx,h*(32-by)/32,z+32},{x+bx,h*(32-by)/32,z+32-c.wallDepth},{x+ax,h*(32-ay)/32,z+32-c.wallDepth},G.uv(ts,0x2d7,8,8,9,9,.5),c.sideShade)
   end
  end end end end
 end
end
function U.capture(list,o,x,z)
 if not o.kind:match('^wreckUnderwater')then return false end
 local h=cfg().wallHeight*V.require('DioramaConfig').emeraldInteriors.heightScale;local depth=cfg().wallDepth
 local function wall(left,right)
  local last=list[#list]
  -- Native row order is left-to-right. Equal, touching opaque prisms have
  -- exactly the same shadow volume as their union; do not bridge the hatch.
  if last and last.wreckWall and last.hi[1]==left and last.lo[2]==0 and last.hi[2]==h
    and last.lo[3]==z+32-depth and last.hi[3]==z+32 then last.hi[1]=right
  else list[#list+1]={lo={left,0,z+32-depth},hi={right,h,z+32},wall=true,wreckWall=true}end
 end
 if o.kind=='wreckUnderwaterWall'then wall(x,x+o.w)
 else for _,span in ipairs{{0,16},{32,48}}do wall(x+span[1],x+span[2])end end
 return true
end
function U.lighting(d)
 if not U.profile(d)then return end
 local c=cfg();local L=d.midLayout;local sources={}
 for x=0,L.width-1,2 do local m=L:midAt(x,0)
  if m>=0x2cc and m<=0x2ce then sources[#sources+1]={at={x*16+8,c.lightHeight,32+c.lightForward},radius=c.radius,power=c.power,color=c.color,spread={5,5},direction={0,-.5,1},cone=-.4}end
 end
 return{fixed=true,localSelection=true,ambient=c.ambient,sources=sources}
end
return U
