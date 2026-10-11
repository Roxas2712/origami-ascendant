-- Native market cloth, timber and merchandise are independent surfaces.
-- Merchant positions and the walkable space under each canopy stay native.
local V=...
local M={}
local goods={[0x20b]=true,[0x20c]=true,[0x21b]=true,[0x21c]=true,[0x22b]=true,
 [0x213]=true,[0x223]=true,[0x344]=true,[0x28d]=true,[0x28e]=true,
 [0x366]=true,[0x33e]=true,[0x33f]=true,[0x32e]=true,[0x32f]=true}
local ground={[0xe6e6ef]=true,[0xcecede]=true,[0xc5b5de]=true,[0xa59ca5]=true,
 [0x948ca5]=true,[0x5a7363]=true,[0x73c5a5]=true,[0x42b584]=true,[0xa5d6c5]=true}
local function color(ts,m,x,y)
 local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y)
 return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)
end
function M.object(ts,m,x,y)return not ground[color(ts,m,x,y)]end
function M.plan(d)
 local p={stalls={},goods={},mask={}}
 if d.id~='EM_SLATEPORT_CITY'or d.pair~='general__slateport'
  or not V.require('DioramaConfig').slateportMarket.enabled
  or not V.require('DioramaConfig').billboards.enabled
  or V.require('Camera').projection()~='perspective'then return p end
 local L=d.midLayout
 local function mark(o,kind)
  for y=o.y,o.y+o.h/16-1 do for x=o.x,o.x+o.w/16-1 do
   local i=y*L.width+x+1;p.mask[i]=p.mask[i]or{};p.mask[i][kind]=o
  end end
 end
 -- Validate native top and foot metatiles before treating a strip as cloth.
 for y=41,49,4 do for _,a in ipairs({{2,80,0x205,0x23d},{10,64,0x225,0x26b}})do
  if L:midAt(a[1],y)==a[3]and L:midAt(a[1],y+2)==a[4]then
   local o={x=a[1],y=y,w=a[2],h=48};p.stalls[#p.stalls+1]=o;mark(o,'stall')
  end
 end end
 for y=1,L.height-3 do for x=0,L.width-5 do
  if L:midAt(x,y)==0x270 and L:midAt(x+4,y)==0x272 and L:midAt(x,y+2)==0x263 and L:midAt(x+4,y+2)==0x264 then
   local o={x=x,y=y,w=80,h=48,banner=true};p.stalls[#p.stalls+1]=o;mark(o,'stall')
  end
 end end
 for y=33,55 do for x=2,13 do
  local mid=L:midAt(x,y)
  if goods[mid]then
   local stack=(mid==0x32e or mid==0x32f)and L:midAt(x,y+1)==mid+8
   local o={x=x,y=y,w=16,h=stack and 32 or 16,mid=mid};p.goods[#p.goods+1]=o;mark(o,'goods')
  end
 end end
 return p
end
function M.role(ts,L,o,x,y)
 if x<8 or x>=o.w-8 or y<1 or y>=47 then return end
 local m=L:midAt(o.x+math.floor(x/16),o.y+math.floor(y/16))
 if not M.object(ts,m,x%16,y%16)then return end
 if y<(o.banner and 25 or 26)then return 'roof'end
 if y<(o.banner and 32 or 29)then return 'fringe'end
 if x<16 or x>=o.w-16 then return 'post'end
end
function M.floor(out,d,ts,x,y,ox,oz,part)
 local L=d.midLayout;local mid=L:midAt(x,y)
 local function replaced(px,py)
  if part.goods and M.object(ts,mid,px,py)then return true end
  if part.stall then
   local o=part.stall
   if M.role(ts,L,o,(x-o.x)*16+px,(y-o.y)*16+py)then return true end
   local c=color(ts,mid,px,py)
   return c==0xc5b5de or c==0xa59ca5 or c==0x948ca5 or c==0x5a7363
  end
  return color(ts,mid,px,py)==0x948ca5
 end
 local vv=V.require('PaperSprite').build(ts,16,16,function(px,py)
  local donor=x==2 and 0x210 or 0x211
  if part.stall and part.stall.banner then donor=L:midAt(x,part.stall.y-1)end
  return replaced(px,py)and donor or mid,px,py
 end,function()return true end,0,0,1,nil,function(px,py)return{(x+ox)*16+px,0,(y+oz)*16+py}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
end
function M.project(role,x,y,banner)
 local c=V.require('DioramaConfig').slateportMarket
 local scale=V.require('Billboard').heightScale();local h=c.postHeight*scale
 local endRow=banner and 25 or 26;local postRows=banner and 15 or 18
 local postStart=47-postRows
 if role=='post'then return{x,(47-y)*h/postRows,47}end
 if role=='fringe'then return{x,h+(postStart-y)*scale,47}end
 -- Hip cloth has its native ridge at row 10; eaves join the fringe at 26.
 local rise=y<10 and(y-1)/9 or(endRow-y)/(endRow-10)
 return{x,h+(postStart-endRow)*scale+rise*c.roofRise,47-(endRow-y)*c.roofDepthScale}
end
function M.build(out,d,ts,ox,oz,contacts,p)
 local G=V.require('WorldGeometry');local S=V.require('PaperSprite');local L=d.midLayout
 local c=V.require('DioramaConfig').slateportMarket
 for _,o in ipairs(p.stalls)do
  local function source(x,y)return L:midAt(o.x+math.floor(x/16),o.y+math.floor(y/16)),x%16,y%16 end
  for _,role in ipairs({'roof','fringe','post'})do
   local vv=S.build(ts,o.w,o.h,source,function(x,y)return M.role(ts,L,o,x,y)==role end,0,0,1,
    function()return role=='roof'and G.BUILDING_ROOF or 5 end,
    function(x,y)return M.project(role,x,y,o.banner)end,.5,function()return -1 end)
   for _,v in ipairs(vv)do out[#out+1]=G.place(v,(o.x+ox)*16,(o.y+oz)*16)end
  end
  for _,px in ipairs({11,o.w-11})do contacts[#contacts+1]={(o.x+ox)*16+px,(o.y+oz)*16+47,3,c.contactDepth,c.contactStrength}end
 end
 for _,o in ipairs(p.goods)do
  local scale=o.mid==0x366 and c.signScale or(o.h>16 or o.mid==0x33e or o.mid==0x33f)and c.crateScale or c.goodsScale
  local vv=S.build(ts,o.w,o.h,function(x,y)return L:midAt(o.x,o.y+math.floor(y/16)),x,y%16 end,
   function(x,y,m,s,t)return M.object(ts,m,s,t)end,0,o.h,scale,function()return 5 end,nil,.5)
  for _,v in ipairs(vv)do v[3]=v[3]+o.h;v[8]=v[8]+o.h;out[#out+1]=G.place(v,(o.x+ox)*16,(o.y+oz)*16)end
  contacts[#contacts+1]={(o.x+ox)*16+8,(o.y+oz)*16+o.h,5,c.contactDepth,c.contactStrength}
 end
end
return M
