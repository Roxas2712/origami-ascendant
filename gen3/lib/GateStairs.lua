-- Measured gate staircase footprints. Native cells and travel remain untouched.
local V=...;local S={rooms=setmetatable({},{__mode="k"})}
local patterns={
 {down=true,tiles={0x2aa,0x2ab,0x2ac,0x2b2,0x2b3,0x2b4,0x2ba,0x2bb,0x2bc}},
 {down=false,tiles={0x2ad,0x2ae,0x2af,0x2b5,0x2b6,0x2b7,0x2bd,0x2be,0x2bf}},
}
local function cfg()return V.require('DioramaConfig').interiors.gateStairs end
function S.recessed(d)return d and S.rooms[d.midLayout] and cfg().enabled end
function S.plan(d,objects,mask,ramps)
 if d.midLayout then S.rooms[d.midLayout]=nil end
 if not cfg().enabled or d.mapType~=8 or d.pair~='house' or not(d.id or d.name or''):match('^FR_ROUTE_')then return end
 local L=d.midLayout;if not L then return end
 for y=0,L.height-3 do for x=0,L.width-3 do for _,p in ipairs(patterns)do
  local complete=true
  for i,m in ipairs(p.tiles)do if L:midAt(x+(i-1)%3,y+math.floor((i-1)/3))~=m then complete=false;break end end
  if complete then
   S.rooms[L]=true
   local o={kind='gateStairs',x=x,y=y,down=p.down}
   objects[#objects+1]=o;ramps[#ramps+1]=o
   -- The upper end of the ascending rail extends into the preceding tile.
   if not p.down and y>0 and L:midAt(x+2,y-1)==0x2a7 then
    mask[(y-1)*L.width+x+3]={mid=0x281,separateSurface=true}
   end
   for yy=y,y+2 do for xx=x,x+2 do mask[yy*L.width+xx+1]={mid=0,void=true,separateSurface=true}end end
  end
 end end end
end
function S.height(o,px,pz)
 local x,z=px-o.x*16,pz-o.y*16;local c=cfg()
 if o.down then
  if x<4 or x>=32 or z<14 or z>38 then return end
  return -c.height+(math.floor((x-4)/4)+1)*c.height/7
 end
 if x<16 or x>=48 or z<16 or z>40 then return end
 return (math.floor((x-16)/4)+1)*c.height/8
end
function S.build(out,objects,L,ts,ox,oz)
 local G=V.require('WorldGeometry');local c=cfg();if not c.enabled then return end
 local function q(a,b,d,e,uv,shade)G.quad(out,a,b,d,e,uv,shade or 1)end
 for _,o in ipairs(objects)do if o.kind=='gateStairs'then
  local x,z=(o.x+ox)*16,(o.y+oz)*16
  local function uv(s,t)return G.uv(ts,L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16,s%16+1,t%16+1,.5)end
  local tread=o.down and uv(30,20)or uv(19,27)
  local rim=o.down and uv(2,10)or uv(27,5)
  local edge=o.down and uv(5,13)or uv(16,16)
  local side=o.down and uv(5,12)or uv(26,36)
  local riser=o.down and uv(21,24)or uv(20,19)
  local function box(a,b,back,front,lo,hi,top,face)
   q({a,hi,back},{b,hi,back},{b,hi,front},{a,hi,front},top)
   q({a,hi,front},{b,hi,front},{b,lo,front},{a,lo,front},face,c.sideShade)
   q({b,hi,back},{a,hi,back},{a,lo,back},{b,lo,back},face,c.sideShade)
   q({a,hi,back},{a,hi,front},{a,lo,front},{a,lo,back},face,c.riserShade)
   q({b,hi,front},{b,hi,back},{b,lo,back},{b,lo,front},face,c.riserShade)
  end
  -- Restore only ground outside the measured stair body/shaft, never a
  -- floor quad over the descending flight. Keep the donor's native pixel phase.
  local function floorRect(sx,sy,w,h)
   local yy=sy
   while yy<sy+h do
    local yh=math.min(sy+h,16*(math.floor(yy/16)+1))-yy;local xx=sx
    while xx<sx+w do
     local xw=math.min(sx+w,16*(math.floor(xx/16)+1))-xx
     q({x+xx,0,z+yy},{x+xx+xw,0,z+yy},{x+xx+xw,0,z+yy+yh},{x+xx,0,z+yy+yh},G.uv(ts,0x281,xx%16,yy%16,xx%16+xw,yy%16+yh))
     xx=xx+xw
    end
    yy=yy+yh
   end
  end
  if o.down then floorRect(0,0,48,10);floorRect(34,10,14,34);floorRect(0,44,48,4)
  else floorRect(0,0,48,48)end
  local start=o.down and 4 or 16;local count=o.down and 7 or 8
  local back,front=o.down and 14 or 16,o.down and 38 or 40
  local low=o.down and -c.height or 0
  for i=0,count-1 do
   local a=x+start+i*4;local h=low+(i+1)*c.height/count
   -- Internal risers share the exact tread edge; no floating diagonal sprite.
   box(a,a+4,z+back,z+front,low,h,tread,riser)
   q({a,h+.02,z+back},{a+1,h+.02,z+back},{a+1,h+.02,z+front},{a,h+.02,z+front},edge)
  end
  if o.down then
   box(x,x+4,z+10,z+44,-c.height,c.railHeight,rim,side)
   box(x+4,x+34,z+10,z+14,-c.height,c.railHeight,rim,side)
   box(x+4,x+34,z+38,z+44,-c.height,c.railHeight,rim,side)
  else
   local trim=uv(20,42)
   for _,zz in ipairs({13,40})do
    local a,b=x+13,x+48;local ha,hb=c.railHeight,c.height+c.railHeight
    q({a,ha,z+zz},{b,hb,z+zz},{b,hb,z+zz+3},{a,ha,z+zz+3},rim)
    q({a,ha,z+zz+3},{b,hb,z+zz+3},{b,0,z+zz+3},{a,0,z+zz+3},side,c.sideShade)
    q({b,hb,z+zz},{a,ha,z+zz},{a,0,z+zz},{b,0,z+zz},side,c.sideShade)
    q({a,ha,z+zz},{a,ha,z+zz+3},{a,0,z+zz+3},{a,0,z+zz},edge)
    q({b,hb,z+zz+3},{b,hb,z+zz},{b,0,z+zz},{b,0,z+zz+3},side,c.sideShade)
    q({a,2,z+zz+3.01},{b,2,z+zz+3.01},{b,0,z+zz+3.01},{a,0,z+zz+3.01},trim)
   end
  end
 end end
end
return S
