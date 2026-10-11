-- Exact Mansion table/seat drawings. Native books and geometry are sampled
-- independently from the baked floor/shadow pixels surrounding them.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.mansionFurniture end
function R.profile(d)return cfg().enabled and V.require('MansionShell').profile(d)end
function R.plan(d,objects,mask)
 local L=d.midLayout;if L then R.rooms[L]=nil end;if not R.profile(d)then return end
 local owned={};R.rooms[L]=owned;local wood=d.id=='FR_POKEMON_MANSION_B1F';local floor=wood and 0x286 or 0x284
 local function add(kind,x,y,w,h,extra)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;owned[#owned+1]=o;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=floor,separateSurface=true}end end
  return o
 end
 for y=0,L.height-4 do for x=0,L.width-3 do local m=L:midAt(x,y)
  if m==0x308 or m==0x329 or m==0x35c then
   local endrow=m==0x35c and 0x364 or 0x320;local valid=true
   local rows={{m,m+1,m+2},{0x310,0x311,0x312},{0x318,0x319,0x31a},{endrow,endrow+1,endrow+2}}
   for dy,row in ipairs(rows)do for dx,mid in ipairs(row)do local real=L:midAt(x+dx-1,y+dy-1)
    if real~=mid and not(dy==2 and real==0x374+dx)then valid=false end
   end end
   if valid then
    add('mansionTable',x,y,3,4)
    -- Only the measured right-side shadow strip belongs to this table.
    for yy=y,y+3 do if x+3<L.width then local mid=L:midAt(x+3,yy)
     if mid==(wood and 0x28e or 0x28c)then mask[yy*L.width+x+4]={mid=floor,separateSurface=true}end
    end end
   end
  end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x2f0 or m==0x2f1 or m==0x35a or m==0x35b then add('mansionChair',x,y,1,1,{right=m==0x2f1 or m==0x35b})end
 end end
end
function R.actorOffset(d,px,pz,gid)
 if gid~=92 or not R.profile(d)then return end
 for _,o in ipairs(R.rooms[d.midLayout]or{})do if o.kind=='mansionTable'then
  local x,z=px+8-o.x*16,pz+16-o.y*16
  if x>=0 and x<48 and z>=13 and z<49 then return cfg().tableHeight,0 end
 end end
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 if not cfg().enabled or not R.rooms[L]then return end
 local c=cfg();local B,P=V.require('BuildingMesh'),V.require('PaperSprite')
 local hs=V.require('Billboard').heightScale();local rig=V.require('RoomLightRig')
 local function draw(w,h,src,inside,project,shade)
  local vv=P.build(ts,w,h,src,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 for _,o in ipairs(R.rooms[L])do local x,z=(o.x+ox)*16,(o.y+oz)*16
  local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  if o.kind=='mansionTable'then
   local donor={[0x375]=0x310,[0x376]=0x311,[0x377]=0x312}
   local function plain(s,t)local m,u,v=source(s,t);return donor[m]or m,u,v end
   local first=#out+1
   -- Native drawing: top starts on row 13, two edge rows at 49..50,
   -- feet on rows 51..55. RGB 123/123/123 is the baked shadow, not a panel.
   draw(48,36,function(s,t)return plain(s,t+13)end,nil,function(s,t)return{x+s,c.tableHeight,z+13+t}end)
   draw(48,2,function(s,t)return source(s,t+49)end,nil,function(s,t)return{x+s,c.tableHeight-c.tableRim*t/2,z+49}end)
   for _,side in ipairs{0,48}do
    draw(36,2,function(s,t)return plain(side==0 and 0 or 47,13+s)end,nil,
     function(s,t)return{x+side,c.tableHeight-c.tableRim*t/2,z+13+s}end,c.sideShade)
   end
   draw(48,2,function(s,t)return plain(s,13)end,nil,function(s,t)return{x+s,c.tableHeight-c.tableRim*t/2,z+13}end,c.sideShade)
   rig.capture(L,{kind='table'},out,first,#out)
   local function leg(s,t)
    local m,u,v=source(s,t+51);local r,g,b=B.pixel(ts,m,u,v)
    return not(math.abs(r*255-123)<.1 and math.abs(g*255-123)<.1 and math.abs(b*255-123)<.1)
   end
   for _,front in ipairs{14,49}do for _,left in ipairs{1,42}do
    draw(5,5,function(s,t)return source(left+s,t+51)end,function(s,t)return leg(left+s,t)end,
     function(s,t)return{x+left+s,(c.tableHeight-c.tableRim)*(5-t)/5,z+front}end)
    contacts[#contacts+1]={x+left+2,z+front,3,c.contactRadius,c.contactStrength}
   end end
   -- Books stay flat and retain the exact source pixels, including their cover.
   for dx=0,2 do local mid=L:midAt(o.x+dx,o.y+1);local clean=donor[mid]
    if clean then
     local function book(s,t)
      local r,g,b,a=B.pixel(ts,mid,s,t);local rr,gg,bb,aa=B.pixel(ts,clean,s,t)
      return a>.5 and(math.abs(r-rr)+math.abs(g-gg)+math.abs(b-bb)>.001 or a~=aa)
     end
     draw(16,16,function(s,t)return mid,s,t end,book,function(s,t)return{x+dx*16+s,c.tableHeight+c.bookLift,z+16+t}end)
    end
   end
  elseif o.kind=='mansionChair'then
   local function src(s,t)return L:midAt(o.x,o.y),o.right and 15-s or s,t end
   local function xx(s)return x+(o.right and 16-s or s)end
   local function band(x0,y0,w,h,project,inside)
    draw(w,h,function(s,t)return src(s+x0,t+y0)end,inside, function(s,t)return project(s+x0,t+y0)end)
   end
   -- A narrow upright blue back and a horizontal blue seat; floor texels are
   -- never folded with either. Native right-facing art uses the mirrored pose.
   band(0,1,5,9,function(s,t)return{xx(s),c.seatHeight+(10-t)*c.backScale*hs,z+11}end)
   band(4,4,9,7,function(s,t)return{xx(s),c.seatHeight,z+t}end)
   band(4,11,9,2,function(s,t)return{xx(s),c.seatHeight-c.seatRim*(t-11)/2,z+11}end)
   for _,left in ipairs{2,9}do
    band(left,13,3,3,function(s,t)return{xx(s),(c.seatHeight-c.seatRim)*(16-t)/3,z+11}end,function(s,t)
     local m,u,v=src(left+s,13+t);local r,g,b=B.pixel(ts,m,u,v)
     return math.max(r,g,b)-math.min(r,g,b)>.01 or r<.4
    end)
    contacts[#contacts+1]={xx(left+1),z+11,2,c.contactRadius,c.contactStrength}
   end
   for _,edge in ipairs{4,13}do band(edge-1,4,1,7,function(s,t)return{xx(edge),c.seatHeight-c.seatRim*(s-edge+1),z+t}end)end
  end
 end
end
return R
