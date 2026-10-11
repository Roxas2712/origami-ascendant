-- Measured Frontier lounges: retain native blue floor, separate wall plants,
-- terminals and side-facing seats. No collision, event or RNG writes.
local V=...
local R={seats=setmetatable({},{__mode="k"})}
function R.profile(d)
 if not d then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 local n=tonumber((d.id or d.name or''):match('^EM_BATTLE_FRONTIER_LOUNGE([1-9])$'))
 if not(c.enabled and c.frontierLounges.enabled and n and L and d.pair=='building__battle_frontier')then return end
 local wide=n==2 or n==5
 if L.width~=(wide and 14 or 10)or L.height~=(wide and 8 or 10)or L:midAt(0,0)~=0x3bd then return end
 return c.homeRooms[wide and'frontierLoungeWide'or'frontierLounge']
end
function R.plan(d)
 local p=R.profile(d);if not p then return end
 local L=d.midLayout;local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.frontierLounges
 local objects,mask={},{}
 local function floor(x,y)return(x+y)%2==0 and 0x3c8 or 0x3c9 end
 local function add(o,x,y,w,h)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=floor(xx,yy)end
  end end;return o
 end
 for y=0,L.height-1 do for x=0,L.width-1 do
  if L:midAt(x,y)==1 or y<2 then mask[y*L.width+x+1]={mid=1,void=true}end
 end end
 for x=0,L.width-2 do
  add({kind='wall',clean={0x3bd,0x3c5},wallHeight=c.wallHeight,wallBase=32,wallLast=32},x,0,1,2)
 end
 for y=0,L.height-1 do for x=0,L.width-2 do
  local m=L:midAt(x,y)
  if m==0x3c6 or m==0x3c7 or m==0x3dc then add({kind='frontLoungePlant'},x,y,1,2)
  elseif m==0x395 or m==0x3a4 then add({kind='frontLoungeDevice'},x,y,1,3)
  elseif m==0x3dd or m==0x3da then
   local h=2;while y+h-1<L.height-1 and L:midAt(x,y+h-1)~=(m==0x3dd and 0x3ed or 0x3e8)do h=h+1 end
   add({kind='frontLoungeSeat',right=m==0x3da},x,y,1,h)
  elseif m==0x3df or m==0x3e7 or m==0x3ef or m==0x3f7 then
   add({kind='frontLoungeSeat',right=m==0x3df or m==0x3e7},x,y,1,1)
  end
 end end
 local seats={};for _,o in ipairs(objects)do if o.kind=="frontLoungeSeat"then seats[#seats+1]=o end end;R.seats[L]=seats
 return objects,mask
end
function R.seatInside(o,s,t)
 local q=o.right and 15-s or s
 if t<0 or t>=o.h-1 then return false end
 if t==0 then return q>=2 and q<4 end
 if t<4 then return q>=1 and q<5 end
 if t==4 then return q>=1 and q<14 end
 return q>=1 and q<15
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local px,pz=x+8,z+16
 if not R.seats[d.midLayout]then R.plan(d)end
 for _,o in ipairs(R.seats[d.midLayout])do if px>=o.x*16+(o.right and 1 or 5) and px<o.x*16+(o.right and 11 or 15) and pz>=o.y*16+4 and pz<=o.y*16+o.h then
  return c.frontierLounges.seatHeight*c.heightScale
 end end
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.frontierLounges
 local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and inside(s,t)end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(s,t,a,b,d,e,shade)local m,u,v=source(s,t);G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 if o.kind=='frontLoungePlant'then
  -- Use the floor-backed native version as the alpha mask even at the wall.
  -- This keeps the wall stripes out of the foliage and retains white pot pixels.
  local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
  local bg={};for _,m in ipairs({0x3c8,0x3c9})do for yy=0,15 do for xx=0,15 do bg[key(B.pixel(ts,m,xx,yy))]=true end end end
  draw(3,31,function(s,t)return not bg[key(B.pixel(ts,t<16 and 0x3dc or 0x3e4,s,t%16))]end,
   function(s,t)return{x+s,c.plantHeight*(31-t)/28,z+31}end)
  if contacts then contacts[#contacts+1]={x+8,z+31,5,2,c.contactStrength}end
 elseif o.kind=='frontLoungeDevice'then
  local function inside(s,t)local inset=t==12 and 3 or t==13 and 2 or t==14 and 1 or t==39 and 1 or 0;return s>=inset and s<16-inset end
  draw(12,18,inside,function(s,t)return{x+s,c.deviceHeight,z+40-c.deviceDepth+(t-12)*c.deviceDepth/6}end)
  draw(18,40,inside,function(s,t)return{x+s,c.deviceHeight*(40-t)/22,z+40}end)
  for _,ss in ipairs({0,16})do patch(1,20,{x+ss,c.deviceHeight,z+40-c.deviceDepth},{x+ss,c.deviceHeight,z+40},{x+ss,0,z+40},{x+ss,0,z+40-c.deviceDepth},.96)end
  if contacts then contacts[#contacts+1]={x+8,z+40,7,2,c.contactStrength}end
 elseif o.kind=='frontLoungeSeat'then
  local function q(s)return o.right and 16-s or s end
  local function mask(s,t)return R.seatInside(o,s,t)end
  local edge=o.right and 11 or 5
  draw(0,o.h-3,function(s,t)return mask(s,t)and(o.right and 15-s or s)<5 end,
   function(s,t)return{x+edge,c.backHeight-(q(s)-1)*(c.backHeight-c.seatHeight)/4,z+t}end)
  draw(4,o.h-3,function(s,t)return mask(s,t)and(o.right and 15-s or s)>=5 end,
   function(s,t)return{x+s,c.seatHeight,z+t}end)
  draw(o.h-3,o.h-1,mask,function(s,t)return{x+s,c.seatHeight*(o.h-1-t)/2,z+o.h-3}end)
  -- Give the sideways backrest thickness: from a frontal camera a single
  -- X-facing plane would vanish into a thin floating stripe.
  local outer=o.right and 13 or 3
  for t=1,o.h-4 do
   patch(o.right and 13 or 2,t,{x+outer,c.backHeight,z+t},{x+edge,c.backHeight,z+t},{x+edge,c.backHeight,z+t+1},{x+outer,c.backHeight,z+t+1})
   patch(o.right and 13 or 2,t,{x+outer,c.backHeight,z+t},{x+outer,c.backHeight,z+t+1},{x+outer,0,z+t+1},{x+outer,0,z+t},.96)
  end
  for _,tt in ipairs({1,o.h-3})do patch(o.right and 13 or 2,5,{x+outer,c.backHeight,z+tt},{x+edge,c.backHeight,z+tt},{x+edge,0,z+tt},{x+outer,0,z+tt},.96)end
  -- Closed underside and short seat edge, using the native dark frame texel.
  local a,b=o.right and 1 or 5,o.right and 11 or 15
  for _,ss in ipairs({a,b})do patch(7,o.h-3,{x+ss,c.seatHeight,z+4},{x+ss,c.seatHeight,z+o.h-3},{x+ss,0,z+o.h-3},{x+ss,0,z+4},.95)end
  patch(7,o.h-3,{x+a,c.seatHeight,z+4},{x+b,c.seatHeight,z+4},{x+b,0,z+4},{x+a,0,z+4},.95)
  if contacts then for zz=6,o.h-3,8 do contacts[#contacts+1]={x+8,z+zz,6,2,c.contactStrength}end end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
