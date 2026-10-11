-- Four measured native stair drawings in the Silph atlas. Rendering only:
-- source cells, behaviors, scripts and warps remain owned by the engine.
local V=...
local S={rooms=setmetatable({},{__mode="k"})}
local variants={
 {left=true,down=false,tiles={0x26a,0x26b,0x338,0x272,0x273,0x274,0x27a,0x27b,0x27c}},
 {left=false,down=true,tiles={0x338,0x338,0x26f,0x275,0x276,0x277,0x27d,0x27e,0x27f}},
 {left=true,down=true,tiles={0x354,0x338,0x338,0x352,0x353,0x3b2,0x35a,0x35b,0x35c}},
 {left=false,down=false,tiles={0x338,0x350,0x351,0x3b3,0x358,0x359,0x3a9,0x360,0x361}},
}
local function cfg()return V.require('DioramaConfig').interiors.silphStairs end
function S.recessed(def)return def and S.rooms[def.midLayout] and cfg().enabled end
function S.plan(def,objects,mask)
 if def.midLayout then S.rooms[def.midLayout]=nil end
 local f=tonumber((def.id or def.name or ''):match('^FR_SILPH_CO_(%d+)F$'))
 if not cfg().enabled or not f or f<1 or f>11 or def.mapType~=8 or (def.renderPair or def.pair)~='building__rom_082d4ecc' then return end
 local L=def.midLayout;if not L or L.height<5 then return end
 local stairs={}
 for x=0,L.width-3 do for _,v in ipairs(variants)do
  local same=true
  for i,m in ipairs(v.tiles)do if L:midAt(x+(i-1)%3,1+math.floor((i-1)/3))~=m then same=false;break end end
  if same then stairs[#stairs+1]={kind='silphStairs',x=x,y=1,left=v.left,down=v.down}end
 end end
 -- Incomplete/script-modified drawings remain native, never partially erased.
 if #stairs~=((f==1 or f==11)and 1 or 2)then return end
 S.rooms[L]=true
 for _,o in ipairs(stairs)do
  objects[#objects+1]=o
  for y=1,3 do for x=o.x,o.x+2 do mask[y*L.width+x+1]={mid=0x334,void=o.down,separateSurface=true}end end
  for x=o.x,o.x+2 do if L:midAt(x,4)==0x33b or L:midAt(x,4)==0x33c then
   mask[4*L.width+x+1]={mid=0x334,separateSurface=true}
  end end
 end
 -- Reconstruct only the measured rear course in row 0. Source 269/271 is
 -- the native level sign; the other columns use the uncovered wall 330/338.
 for x=0,L.width-1 do
  local m=L:midAt(x,0)
  if m==0x330 or m==0x269 then
   objects[#objects+1]={kind='silphStairWall',x=x,y=0,top=m,bottom=m==0x269 and 0x271 or 0x338}
   for y=0,1 do mask[y*L.width+x+1]={mid=0x335,void=y==0,separateSurface=true}end
  elseif m==0x288 or m==0x28c then
   objects[#objects+1]={kind='silphStairJamb',x=x,y=0,left=m==0x288,join=L:midAt(x,2)==(m==0x288 and 0x33e or 0x33f)}
   for y=0,3 do mask[y*L.width+x+1]={mid=0,void=true,separateSurface=true}end
  end
 end
end
function S.height(o,px,pz)
 local x,z=px-o.x*16,pz-o.y*16
 if x<0 or x>=48 or z<16 or z>48 then return nil end
 local n=math.min(7,math.floor(x/6));local step=o.left and 8-n or n+1
 return step/8*(o.down and -1 or 1)*cfg().height
end
local function colours(L,ts,o)
 local B=V.require('BuildingMesh');local G=V.require('WorldGeometry')
 local target={{239,239,239},{189,197,197},{82,82,107},{247,230,165},{148,156,156}}
 local best,uv={},{}
 for y=0,47 do for x=0,47 do
  local m=L:midAt(o.x+math.floor(x/16),o.y+math.floor(y/16));local u,v=x%16,y%16
  local r,g,b,a=B.pixel(ts,m,u,v)
  if a>=.5 then for i,c in ipairs(target)do
   local d=(r*255-c[1])^2+(g*255-c[2])^2+(b*255-c[3])^2
   if not best[i]or d<best[i]then best[i]=d;uv[i]=G.uv(ts,m,u,v,u+1,v+1,.5)end
  end end
 end end
 return uv
end
function S.build(out,objects,L,ts,ox,oz)
 local G=V.require('WorldGeometry');local c=cfg()
 local function q(a,b,d,e,uv,shade)G.quad(out,a,b,d,e,uv,shade or 1)end
 for _,o in ipairs(objects)do
  local c=o.stairConfig or c -- Shared native flight mesh; caller owns its tuning.
  local x,z=(o.x+ox)*16,(o.y+oz)*16
  if o.kind=='silphStairWall'then
   local vv=V.require('PaperSprite').build(ts,16,32,function(sx,sy)
    return sy<16 and o.top or o.bottom,sx,sy%16
   end,function()return true end,0,32,c.wallScale,nil,nil,.5)
   for _,v in ipairs(vv)do out[#out+1]=G.place(v,x,z+32)end
  elseif o.kind=='silphStairJamb'then
   local h=32*c.wallScale*V.require('Billboard').heightScale()
   local a,b=o.left and x+8 or x,o.left and x+16 or x+8
   local m=o.left and 0x290 or 0x294
   local uv=G.uv(ts,m,o.left and 8 or 0,0,o.left and 16 or 8,16,.5)
   q({a,h,z+64},{b,h,z+64},{b,0,z+64},{a,0,z+64},uv)
   local cap=G.uv(ts,0x290,10,8,11,9,.5)
   q({a,h,z+32},{b,h,z+32},{b,h,z+64},{a,h,z+64},cap)
   if o.join then
    local ca,cb=o.left and x or x+8,o.left and x+8 or x+16
    for row=0,1 do
     q({ca,h*(2-row)/2,z+64},{cb,h*(2-row)/2,z+64},
      {cb,h*(1-row)/2,z+64},{ca,h*(1-row)/2,z+64},G.uv(ts,row==0 and 0x330 or 0x338,0,0,8,16,.5))
    end
   end
   local inner=o.left and b or a
   q({inner,h,z+32},{inner,h,z+64},{inner,0,z+64},{inner,0,z+32},cap,c.sideShade)
  elseif o.kind=='silphStairs'then
   local uv=colours(L,ts,o)
   for i=0,7 do
    local step=o.left and 8-i or i+1;local h=step*c.height/8*(o.down and -1 or 1)
    local a,b=x+i*6,x+(i+1)*6;local back,front=z+16,z+48
    q({a,h,back},{b,h,back},{b,h,front},{a,h,front},uv[1])
    if i<7 then
     local nextStep=o.left and 7-i or i+2;local nh=nextStep*c.height/8*(o.down and -1 or 1)
     q({b,math.max(h,nh),back},{b,math.max(h,nh),front},
      {b,math.min(h,nh),front},{b,math.min(h,nh),back},uv[2],c.riserShade)
    end
    q({a,h,front},{b,h,front},{b,0,front},{a,0,front},uv[5],c.sideShade)
    q({b,h,back},{a,h,back},{a,0,back},{b,0,back},uv[5],c.sideShade)
    local edge=o.left and b or a
    q({edge,h+.02,back},{edge+(o.left and -1 or 1),h+.02,back},
     {edge+(o.left and -1 or 1),h+.02,front},{edge,h+.02,front},uv[3])
    for _,zz in ipairs({back,front-1})do
     local sign=o.down and -1 or 1
     local ha=(o.left and 1-i/8 or i/8)*c.height*sign+c.railHeight
     local hb=(o.left and 1-(i+1)/8 or (i+1)/8)*c.height*sign+c.railHeight
     q({a,ha,zz},{a+1,ha,zz},{a+1,h,zz},{a,h,zz},uv[3])
     q({a,ha,zz},{b,hb,zz},{b,hb,zz+1},{a,ha,zz+1},uv[4])
     q({a,ha,zz+1},{b,hb,zz+1},{b,hb-1,zz+1},{a,ha-1,zz+1},uv[4])
    end
   end
   -- Close the exposed terminal side of an ascending flight.
   if not o.down then
    local endX=o.left and x or x+48
    q({endX,c.height,z+16},{endX,c.height,z+48},{endX,0,z+48},{endX,0,z+16},uv[5],c.sideShade)
   end
  end
 end
end
return S
