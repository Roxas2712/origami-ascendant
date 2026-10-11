-- Four measured S.S. Anne corridor layouts; never modifies native cells/warps.
local V=...
local C={}
local layouts={
 FR_SSANNE_1F_CORRIDOR={w=32,h=22,check={19,0,0x3bf},walls={{18,0,3},{1,6,17},{21,6,9}},
  stairs={{x=1,y=6,h=4,left=0,right=32,back=40,front=64,up=true,reverse=true,railStart=14,clearWall=true,floor=0x298},
   {x=26,y=16,h=3,left=0,right=32,back=16,front=40,railStart=8,railOffset=32,floor=0x299}}},
 FR_SSANNE_2F_CORRIDOR={w=34,h=16,check={6,9,0x3bf},walls={{1,0,4},{30,0,3},{28,6,2},{5,9,23}},
  stairs={{x=2,y=2,h=2,left=14,right=46,back=0,front=24,reverse=true,railStart=0,noRear=true,floor=0x299},
   {x=30,y=0,h=4,left=14,right=46,back=40,front=64,up=true,railStart=30,clearWall=true,floor=0x299},
   {x=1,y=10,h=5,left=0,right=32,back=40,front=64,up=true,reverse=true,railStart=14,floor=0x298}}},
 FR_SSANNE_3F_CORRIDOR={w=22,h=8,check={3,1,0x282},walls={{1,0,20}},
  stairs={{x=18,y=2,h=2,left=14,right=46,back=0,front=24,reverse=true,railStart=0,noRear=true,floor=0x298}},exit=true},
 FR_SSANNE_B1F_CORRIDOR={w=24,h=8,check={2,1,0x3bf},walls={{1,1,21}},
  stairs={{x=19,y=1,h=4,left=14,right=46,back=40,front=64,up=true,railStart=30,clearWall=true,floor=0x298}},bucket=true},
}
local border={};for _,m in ipairs({0x286,0x287,0x28e,0x28f,0x2be,0x2b6,0x284,0x283,0x285,0x2a6,0x2a7,0x2ae,0x2af,0x28b,0x28d,0x293,0x295,0x2ad})do border[m]=true end
function C.profile(d)
 local c=V.require('DioramaConfig').interiors.shipCorridors;local L=d.midLayout;local id=d.id or d.name
 local p=layouts[id]
 if not c.enabled or (d.renderPair or d.pair)~='general__rom_082d4d94'or not p or not L or L.width~=p.w or L.height~=p.h or L:midAt(p.check[1],p.check[2])~=p.check[3]then return end
 return c.rooms[id]
end
function C.plan(d)
 if not C.profile(d)or not V.require('IndoorSurfaces').profile(d)then return end
 local p=layouts[d.id or d.name];local L=d.midLayout;local objects,mask,owners,ramps={},{},{},{}
 local function add(o,x,y,w,h)
  o.x=x;o.y=y;o.w=w;o.last=h*16;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1;owners[k]=o;mask[k]={mid=0x288,void=true}end end
  return o
 end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x288 or m==0x290 then mask[y*L.width+x+1]={mid=0x288,void=true}
  elseif border[m]then add({kind='shipCorridorFloor',base=.01},x,y,1,1)end
 end end
 for _,r in ipairs(p.walls)do for x=r[1],r[1]+r[3]-1 do
  local cap=L:midAt(x,r[2]);local clear=cap==0x28b or cap==0x28d or cap==0x286
  for _,s in ipairs(p.stairs)do if s.clearWall and r[2]==s.y and x>=s.x and x<s.x+3 then clear=true end end
  add({kind='shipCorridorWall',base=.01,clear=clear},x,r[2],1,2)
 end end
 for _,s in ipairs(p.stairs)do
  local o={kind='shipCorridorStairs',base=.01};for k,v in pairs(s)do o[k]=v end
  ramps[#ramps+1]=add(o,s.x,s.y,3,s.h)
 end
 if p.exit then add({kind='shipCorridorExit',base=.01},0,3,2,3)end
 if p.bucket then
  local o=add({kind='shipPublicBucket',cap=1,front=16},21,5,1,1)
  mask[5*L.width+22]=0x298
 end
 return {objects=objects,mask=mask,owners=owners,ramps=ramps}
end
function C.recesses(d)
 if not C.profile(d)then return {}end
 local bounds={}
 for _,s in ipairs(layouts[d.id or d.name].stairs)do if not s.up then
  bounds[#bounds+1]={s.x*16+s.left,s.y*16+s.back,s.x*16+s.right,s.y*16+s.front}
 end end
 return bounds
end
function C.stairHeight(o,x,z)
 local dx,dz=x-o.x*16,z-o.y*16
 if dx<o.left or dx>=o.right or dz<o.back or dz>o.front then return end
 local n=math.min(7,math.floor((dx-o.left)/4));local step=o.reverse and 8-n or n+1
 local h=V.require('DioramaConfig').interiors.shipCorridors.stairHeight
 return step*h/8-(o.up and 0 or h)
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local paletteCache=setmetatable({},{__mode='k'})
local function floorPalette(ts)
 if not paletteCache[ts]then
  local p={};local BM=V.require('BuildingMesh')
  for _,m in ipairs({0x298,0x299})do for y=0,15 do for x=0,15 do p[rgb(BM.pixel(ts,m,x,y))]=true end end end
  paletteCache[ts]=p
 end
 return paletteCache[ts]
end
function C.build(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.shipCorridors;local G=V.require('WorldGeometry');local BM=V.require('BuildingMesh')
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(w,h,src,inside,project)
  local vv=V.require('PaperSprite').build(ts,w,h,src,inside,0,h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 if o.kind=='shipCorridorWall'then
  local function wallSource(s,t)if o.clear then return t<16 and 0x28c or 0x294,s,t%16 end;return source(s,t)end
  draw(16,32,wallSource,function(_,t)return t>=6 end,function(s,t)return{x+s,c.wallHeight*(32-t)/26,z+32}end)
 elseif o.kind=='shipCorridorFloor'or o.kind=='shipCorridorExit'then
  local palette=floorPalette(ts)
  draw(o.w*16,o.last,source,function(s,t,m,u,v)
   return o.kind=='shipCorridorExit'and s>=11 and s<29 and t>=12 and t<36 or palette[rgb(BM.pixel(ts,m,u,v))]==true
  end,function(s,t)return{x+s,o.kind=='shipCorridorExit'and c.rugHeight or 0,z+t}end)
 elseif o.kind=='shipCorridorStairs'then
  local palette=floorPalette(ts)
  -- Preserve the original floor contour outside the aperture, including
  -- corners beside the stairs; white native boundary pixels are not floor.
  local function floorSource(s,t)
   local m,u,v=source(s,t)
   if palette[rgb(BM.pixel(ts,m,u,v))]then return m,u,v end
   return o.floor,s%16,t%16
  end
  draw(48,o.last,floorSource,function(s,t)
   return t>=(o.clearWall and 32 or 0)and not(s>=o.left and s<o.right and t>=o.back and t<o.front)
  end,function(s,t)return{x+s,0,z+t}end)
  local tread=G.uv(ts,0x2ac,9,6,10,7,.5);local riser=G.uv(ts,0x2ab,4,9,5,10,.5)
  for i=0,7 do
   local a=o.left+i*4;local h=C.stairHeight(o,o.x*16+a,o.y*16+o.back);local bottom=o.up and 0 or -c.stairHeight
   api.prism(out,ts,0,x+a,z+o.back,4,o.front-o.back,bottom,h-bottom,tread,riser,riser)
   G.quad(out,{x+a,h+.02,z+o.back},{x+a+1,h+.02,z+o.back},{x+a+1,h+.02,z+o.front},{x+a,h+.02,z+o.front},riser,1)
  end
  if not o.up then
   -- A recessed flight needs a shaft, not an exposed stack of step prisms.
   -- Its four vertical boundaries join the existing floor aperture at y=0.
   -- They occlude the submerged treads through the adjacent floor/cutaway.
   V.require('RoomRecessClip').shaft(out,{x+o.left,z+o.back,x+o.right,z+o.front},c.stairHeight,riser,c.shaftShade)
  end
  for _,front in ipairs(o.noRear and{true}or{false,true})do
   local function railSource(s,t)
    local sy=o.railStart+t+(front and (o.railOffset or 24)or 0)
    if o.up then sy=sy+(o.reverse and math.floor((s-o.left)/2)or -math.floor((s-o.left)/2))end
    return source(s,sy)
   end
   draw(48,8,railSource,function(s)return s>=o.left and s<o.right end,function(s,t)
    -- Descending flights are openings in this floor: their safety rails
    -- stay level around the opening, rather than sinking with the treads.
    local f=(s-o.left)/32;local h=o.up and (o.reverse and 1-f or f)*c.stairHeight or 0
    return{x+s,h+c.railHeight*(8-t)/8,z+(front and o.front or o.back)}
   end)
  end
 end
end
return C
