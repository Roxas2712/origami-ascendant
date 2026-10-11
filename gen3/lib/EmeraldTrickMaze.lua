-- Puzzle 1's connected cabinet maze. Geometry reads live native tiles only.
local V=...
local M={}
local back={[0x21a]=true,[0x21b]=true,[0x21c]=true,[0x21d]=true,[0x232]=true,[0x233]=true,[0x234]=true}
local full={[0x221]=true,[0x222]=true,[0x228]=true,[0x22b]=true,[0x22c]=true}
local front={[0x223]=true,[0x224]=true,[0x225]=true,[0x22a]=true,[0x230]=true}
function M.band(mid)
 if back[mid]then return 12,16 elseif full[mid]then return 0,16 elseif front[mid]then return 0,16 end
end
function M.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.trickMaze.enabled and(d.id or d.name)=='EM_ROUTE110_TRICK_HOUSE_PUZZLE1'
  and d.mapType==8 and d.pair=='building__trick_house_puzzle'and L and L.width==16 and L.height==22
  and L:midAt(0,0)==0x201 and L:midAt(0,1)==0x232 then return c.homeRooms.trickMaze end
end
function M.lighting(d)
 if M.profile(d)then return V.require('DioramaConfig').emeraldInteriors.trickMaze.lighting end
end
function M.plan(d)
 if not M.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 for x=0,14 do
  objects[#objects+1]={kind='trickMazeRearWall',x=x,y=0,w=16,h=32,door=x>=12,noContact=true}
  for y=0,1 do mask[y*L.width+x+1]={mid=1,void=true}end
 end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y);local a,b=M.band(m)
  if m==1 then mask[y*L.width+x+1]={mid=1,void=true}end
  if a then
   objects[#objects+1]={kind='trickMazeWall',x=x,y=y,w=16,h=16,mid=m,first=a,last=b,noContact=true}
   mask[y*L.width+x+1]={mid=1,void=true}
  end
 end end
 return objects,mask
end
function M.occupied(L,s,t)
 local x,y=math.floor(s/16),math.floor(t/16)
 if x<0 or y<0 or x>=L.width or y>=L.height then return false end
 local a,b=M.band(L:midAt(x,y));return a and t%16>=a and t%16<b or false
end
function M.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.trickMaze
 local G=V.require('WorldGeometry');local h=c.height*cfg.heightScale
 if o.kind=='trickMazeRearWall'then
  local last=o.door and 32 or 28;local height=(o.door and c.doorHeight or c.wallHeight)*cfg.heightScale
  local vv=V.require('PaperSprite').build(ts,16,32,function(s,t)return L:midAt(o.x,math.floor(t/16)),s,t%16 end,
   function(_,t)return t<last end,0,32,1,nil,function(s,t)return{x+s,height*(last-t)/last,z+32}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end;return
 end
 local a,b=o.first,o.last
 -- Preserve the native exposed floor strip behind each cabinet cap. The
 -- floor revealed beneath a raised facade uses the same native tatami tile.
 if o.y>1 then
  G.quad(out,{x,0,z},{x+16,0,z},{x+16,0,z+16},{x,0,z+16},G.uv(ts,0x208,0,0,16,16,.5),1)
  if a>0 then
   -- A small material offset avoids coplanar overlap with the donor floor.
   G.quad(out,{x,.01,z},{x+16,.01,z},{x+16,.01,z+a},{x,.01,z+a},G.uv(ts,o.mid,0,0,16,a,.5),1)
  end
 end
 G.quad(out,{x,h,z+a},{x+16,h,z+a},{x+16,h,z+b},{x,h,z+b},G.uv(ts,o.mid,0,a,16,front[o.mid]and 7 or b,.5),1)
 local function occupied(s,t)return M.occupied(L,o.x*16+s,o.y*16+t)end
 local function side(ax,az,bx,bz,nativeFront)
  local m=nativeFront and o.mid or 0x224
  local u=nativeFront and math.min(ax,bx)or(az+bz)%16
  G.quad(out,{x+ax,h,z+az},{x+bx,h,z+bz},{x+bx,0,z+bz},{x+ax,0,z+az},G.uv(ts,m,u,7,u+1,16,.49),nativeFront and 1 or c.sideShade)
 end
 for s=0,15 do
  if not occupied(s,a-1)then side(s+1,a,s,a)end
  if not occupied(s,b)then side(s,b,s+1,b,front[o.mid])end
 end
 for t=a,b-1 do
  if not occupied(-1,t)then side(0,t,0,t+1)end
  if not occupied(16,t)then side(16,t+1,16,t)end
 end
 if contacts then
  if not occupied(8,b)then contacts[#contacts+1]={x+8,z+b,7,1.5,c.contactStrength}end
  if not occupied(-1,math.floor((a+b)/2))then contacts[#contacts+1]={x,z+(a+b)/2,1.5,(b-a)/2,c.contactStrength}end
  if not occupied(16,math.floor((a+b)/2))then contacts[#contacts+1]={x+16,z+(a+b)/2,1.5,(b-a)/2,c.contactStrength}end
 end
end
return M
