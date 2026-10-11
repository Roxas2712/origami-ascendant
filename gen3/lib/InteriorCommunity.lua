-- Two native community layouts whose counter/partition art must not become walls.
local V=...;local M={}
function M.profile(d)
 local c=V.require('DioramaConfig').interiors.community;local L=d.midLayout
 if not(c.enabled and L and (d.renderPair or d.pair)=='building__rom_082d4f74'and L.width==12)then return end
 local p=c.rooms[d.id or d.name]
 if p and L.height==p.height and L:midAt(0,0)==p.anchor then return p end
end
function M.plan(d)
 local p=M.profile(d);if not p then return end
 local c=V.require('DioramaConfig').interiors.community;local L=d.midLayout
 local objects,mask,owners={},{},{}
 local function add(o,x,y,w,h,donor)
  o.x=x;o.y=y;o.w=w;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*12+xx+1;mask[k]=donor or p.floor;owners[k]=o end end
  return o
 end
 local function fold(x,y,w,cap,split,last,height,depth,donor)
  return add({kind='clubFold',cap=cap,split=split,last=last,height=height,depth=depth,front=last,background={donor or p.floor}},x,y,w,math.ceil(last/16),donor)
 end
 add({kind='communityWall',front=32,daycare=p.daycare},0,0,p.daycare and 12 or 11,2,{mid=8,void=true})
 if p.daycare then
  add({kind='communityCounter',front=64},0,1,5,3)
  add({kind='clubPC',last=40,front=40},10,0,1,3)
  fold(8,4,2,0,27,32,c.tableHeight,26,0x2a3)
  for _,x in ipairs{7,10}do for y=4,5 do fold(x,y,1,3,13,16,c.seatHeight,10,0x2a3)end end
  fold(2,4,1,3,13,16,c.seatHeight,10)
  for _,y in ipairs{4,6}do fold(0,y,1,1,26,31,c.planterHeight,25)end
 else
  for _,x in ipairs{0,2}do add({kind='panel',cap=11,split=13,last=40,height=27,depth=6,front=40,base=0,sideMid=0x2a8,sideX=1,sideY=3},x,0,2,3)end
  add({kind='clubPC',last=40,front=40},10,0,1,3)
  for _,y in ipairs{4,12}do
   fold(4,y,3,0,27,32,c.tableHeight,26,0x2a3)
   for _,x in ipairs{3,7}do add({kind='clubSeat',side=true,right=x==7,last=32,front=32},x,y,1,2,0x2a3)end
  end
  for _,x in ipairs{0,10}do for _,y in ipairs{4,6,12,14}do fold(x,y,1,1,26,31,c.planterHeight,25)end end
  for _,x in ipairs{0,8}do add({kind='communityWall',partition=true,front=32},x,8,3,2)end
  add({kind='communityCabinet',front=42},0,8,2,3)
  fold(3,9,1,0,14,16,14,6)
  for _,x in ipairs{9,10}do add({kind='communityChair',front=32},x,9,1,2)end
 end
 for y=0,1 do for x=0,(p.daycare and 11 or 10)do mask[y*12+x+1]={mid=8,void=true}end end
 -- Original rug borders and the actual exit tiles are never inferred/repainted.
 return {objects=objects,mask=mask,owners=owners}
end
function M.build(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.community
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(w,h,inside,project,src)
  local vv=V.require('PaperSprite').build(ts,w,h,src or source,inside,0,h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 if o.kind=='communityWall'then
  local function wall(s,t)
   local xx=s
   if o.daycare then
    if s>=160 and s<176 then xx=144+s%16 end
    if s>=64 and s<80 and t>=24 then xx=80+s%16 end
   elseif o.partition then return L:midAt(4,math.floor(t/16)),8,t%16
   elseif s<64 or s>=160 then xx=64+s%16 end
   return source(xx,t)
  end
  draw(o.w*16,30,function()return true end,function(s,t)return{x+s,c.wallHeight*(30-t)/30,z+32}end,wall)
 elseif o.kind=='communityCounter'then
  -- Native L: top above the attendant floor; the white fascia is separate.
  draw(80,48,function(s,t)return (s<64 and t>=27 and t<40)or(s>=64 and t>=9 and t<40)end,
   function(s,t)return{x+s,c.counterHeight,z+18+(t-9)*28/31}end)
  draw(80,48,function(s,t)return t>=40 and t<48 end,
   function(s,t)return{x+s,c.counterHeight*(48-t)/8,z+46}end)
 elseif o.kind=='communityCabinet'then
  draw(32,42,function(s,t)return t>=11 end,function(s,t)return{x+s,28*(42-t)/31,z+42}end)
 elseif o.kind=='communityChair'then
  draw(16,32,function(s,t)return t>1 and s>0 and s<15 end,function(s,t)
   if t<18 then return{x+s,c.backHeight-(t-2)*(c.backHeight-c.seatHeight)/16,z+20}end
   if t<27 then return{x+s,c.seatHeight,z+20+(t-18)*10/9}end
   return{x+s,c.seatHeight*(32-t)/5,z+30}
  end)

 end
end
return M
