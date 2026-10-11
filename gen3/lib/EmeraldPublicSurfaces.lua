-- Measured BPEE Center/Mart drawings. Objects are independent of native
-- adjacency; floor medallions, exit rugs and event coordinates are untouched.
local V=...
local P={}
function P.plan(def,p)
 local L=def.midLayout;local c=V.require('DioramaConfig').emeraldInteriors
 local objects,mask={},{}
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w*16;o.h=h*16;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=donor or p.floor end
  end end
  return o
 end
 local function fold(x,y,w,h,cap,split,last,height,depth,front,bg)
  return add({kind='fold',cap=cap,split=split,last=last,height=height,depth=depth,front=front or last,background=bg},x,y,w,h)
 end
 local function card(x,y,w,h,cap,last,front,height,bg)
  return add({kind='card',cap=cap,last=last,front=front or last,height=height,background=bg or {{mid=p.floor}}},x,y,w,h)
 end
 local function clear(x,w,clean,keep)
  for _,o in ipairs(objects)do if o.kind=='wall' and o.x>=x and o.x<x+w then o.clean=clean;o.keepBefore=keep end end
 end
 local last=p.family=='mart'and 10 or 13
 for x=1,last-1 do add({kind='wall',wallHeight=p.family=='mart'and 24 or 32,wallFloor=p.family=='mart'and p.floor},x,0,1,2,{mid=p.void,void=true})end
 for _,x in ipairs({0,last})do add({kind='corner',right=x==last,floor=p.floor,wallHeight=p.family=='mart'and 24 or 32,diagonal=p.family=='mart'and 8 or 16},x,0,1,3,{mid=p.void,void=true})end
 if p.family=='center' then
  local h=c.publicCounterHeight
  fold(4,2,6,3,12,22,32,h,14,32).removeBalls=true
  for _,x in ipairs({4,9})do
   local a=fold(x,1,1,2,8,24,26,h,26,44);a.repeatTop=10
   local ball=card(x,2,1,2,8,21,25,13,{{mid=0x202},{mid=0x221}});ball.base=h;ball.trim=2;ball.opaque=true
   clear(x,1,{0x20b,0x213})
  end
  card(5,1,2,2,1,29,34,32,{}).opaque=true
  clear(5,2,{0x20b,0x213})
  card(8,1,1,2,8,28,33,23,{}).opaque=true
  clear(8,1,{0x20b,0x213},24)
  card(10,0,1,3,8,40,48,37,{}).opaque=true
  clear(10,1,{0x20b,0x213})
  if def.id=='EM_LAVARIDGE_TOWN_POKEMON_CENTER_1F' then
   -- The bath exit is a real doorway, not a bookshelf; keep its complete art.
   card(1,0,3,3,0,48,48,38,{{mid=p.floor}})
   clear(1,3,{0x20b,0x213})
  else
   fold(2,1,2,2,1,8,24,26,8,32,{{mid=p.floor}})
   clear(2,2,{0x20b,0x213})
   card(1,0,1,3,10,40,47,30,{{mid=p.floor},{mid=0x20b},{mid=0x213}}).positionMask=true
   clear(1,1,{0x20b,0x213})
  end
  fold(11,6,2,2,0,23,30,c.publicTableHeight,27,31,{{mid=p.floor}})
  add({kind='escalator',floor=p.floor},0,5,2,3)
 elseif p.family=='link' then
  -- Service tops and lowered gates are separate from the tall white returns.
  for _,r in ipairs({{0,3},{4,1},{6,2},{10,2}})do fold(r[1],2,r[2],2,12,22,32,c.publicCounterHeight,17,32)end
  for _,x in ipairs({5,9})do fold(x,3,1,1,0,6,14,6,10,14)end
  for _,x in ipairs({3,8,12})do
   local hh=x==3 and 43 or 60
   local returnCard=card(x,0,1,math.ceil(hh/16),10,hh,hh,hh-10,{{mid=p.floor},{mid=0x20b},{mid=0x213}});returnCard.trim=2;returnCard.opaque=true
   clear(x,1,{0x20b,0x213})
  end
  card(3,2,1,3,10,39,46,31,{{mid=p.floor}})
  for _,x in ipairs({8,12})do
   fold(x,3,1,2,13,18,32,20,8,34,{{mid=p.floor}})
   card(x,4,1,1,0,15,24,17,{{mid=p.floor}}).base=10
  end
  add({kind='escalator',floor=p.floor},0,5,2,3)
  -- Both ornamental floor emblems at rows 5/6 remain native ground.
  for _,x in ipairs({5,6,9,10})do card(x,8,1,2,0,29,31,30,{{mid=p.floor}}).positionMask=true end
 else
  -- Cash wrap: native glass top and opaque front, with its long return.
  fold(0,3,3,2,13,24,32,c.publicCounterHeight,18,32)
  local arm=fold(2,1,1,3,12,40,48,c.publicCounterHeight,36,48);arm.repeatTop=nil
  clear(2,1,{0x212,0x21d})
  for _,x in ipairs({3,4,5})do
   card(x,0,1,2,8,31,34,26,{{mid=0x201}})
   clear(x,1,{0x212,0x21d})
  end
  for _,x in ipairs({6,8})do
   fold(x,0,2,3,14,20,40,c.publicShelfHeight,8,46,{{mid=p.floor}})
   clear(x,2,{0x212,0x21d})
  end
  -- Two-sided center gondola and single wall gondola retain their native
  -- book/bottle drawings; no generated replacement texture is introduced.
  fold(6,4,2,3,0,6,48,c.publicShelfHeight,7,44,{{mid=p.floor}})
  fold(10,4,1,3,0,6,48,c.publicShelfHeight,7,44,{{mid=p.floor}})
  card(10,2,1,2,0,31,32,31,{{mid=p.floor}}).positionMask=true
 end
 if p.family~='mart' then
  for y=3,L.height-1 do for x=0,L.width-1 do
   local mid=L:midAt(x,y)
   if mid==0x226 or mid==0x234 then
    fold(x,y,1,1,0,10,15,c.publicStoolHeight,12,15,{{mid=p.floor}})
   end
  end end
 end
 return objects,mask
end
function P.build(out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').emeraldInteriors
 if o.kind=='corner' then
  -- Remove the already painted diagonal before forming a real wall return.
  for sx=0,15 do for sy=0,o.wallHeight-1 do
   local offset=math.max(0,o.right and sx-(16-o.diagonal)or o.diagonal-1-sx);local nativeY=sy+offset
   local mid=o.sourceRows and o.sourceRows[math.floor(nativeY/16)+1]or L:midAt(o.x,math.floor(nativeY/16));local off1=math.max(0,o.right and sx+1-(16-o.diagonal)or o.diagonal-2-sx);local z0=z+o.wallHeight+offset;local z1=z+o.wallHeight+off1
   G.quad(out,{x+sx,(o.wallHeight-sy)*cfg.heightScale,z0},{x+sx+1,(o.wallHeight-sy)*cfg.heightScale,z1},
    {x+sx+1,(o.wallHeight-1-sy)*cfg.heightScale,z1},{x+sx,(o.wallHeight-1-sy)*cfg.heightScale,z0},G.uv(ts,mid,sx,nativeY%16,sx+1,nativeY%16+1,.5),1)
  end end
  for sx=0,15 do for sy=o.wallHeight,47 do if sy>=o.wallHeight+math.max(0,o.right and sx-(16-o.diagonal)or o.diagonal-1-sx)then
   G.quad(out,{x+sx,0,z+sy},{x+sx+1,0,z+sy},{x+sx+1,0,z+sy+1},{x+sx,0,z+sy+1},G.uv(ts,o.floor,sx,sy%16,sx+1,sy%16+1,.5),1)
  end end end
 else
  local pixel=V.require('BuildingMesh').pixel;local bg={}
  local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
  for yy=0,15 do for xx=0,15 do bg[rgb(pixel(ts,o.floor,xx,yy))]=true end end
  local function source(sx,sy)return L:midAt(o.x+math.floor(sx/16),o.y+math.floor(sy/16)),sx%16,sy%16 end
  local vv=V.require('PaperSprite').build(ts,32,48,source,function(sx,sy)
   local m,u,v=source(sx,sy);local r,g,b,a=pixel(ts,m,u,v);return a>.5 and not bg[rgb(r,g,b)]
  end,0,48,1,nil,function(sx,sy)return{x+sx,(48-sy)*cfg.publicStairRise,z+sy}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
end
return P
