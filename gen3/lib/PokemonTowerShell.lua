-- Measured tower shell and four native stair orientations. Presentation only.
local V=...;local R={rooms=setmetatable({},{__mode="k"})}
local function cfg()return V.require('DioramaConfig').interiors.pokemonTowerShell end
local variants={
 {left=false,down=false,tiles={0x294,0x29d,0x29f,0x2a8,0x296,0x2a4,0x29c,0x29e,0x2ac}},
 {left=true,down=false,tiles={0x2bb,0x2bc,0x2bd,0x2c3,0x2c4,0x2c5,0x2d5,0x2cc,0x2cd}},
 {left=false,down=true,tiles={0x2b0,0x2b1,0x2b2,0x2b8,0x2b9,0x2ba,0x2c0,0x2c1,0x2c2}},
 {left=true,down=true,tiles={0x2be,0x2a6,0x2a7,0x2ad,0x2ae,0x2af,0x2b5,0x2b6,0x2b7}},
 {left=true,down=true,tiles={0x2a5,0x2a6,0x2a7,0x2ad,0x2ae,0x2af,0x2b5,0x2b6,0x2b7}}}
local bases={[2]=128,[3]=96,[4]=80,[5]=64,[6]=64,[7]=48,[8]=48,[9]=32,[10]=32,[11]=32,[12]=32,[13]=32,[14]=48,[15]=48,[16]=64,[17]=64,[18]=80,[19]=96,[20]=128}
function R.wallBase(x)return bases[math.floor(x/16)]end
function R.profile(d)
 local L=d and d.midLayout;local n=d and tonumber((d.id or''):match('^FR_POKEMON_TOWER_([1-7])F$'))
 return cfg().enabled and n and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4efc'and L and L.width==24 and L.height==20 and L:midAt(9,0)==0x298 and n or nil
end
function R.stairs(L)
 local stairs={}
 for y=0,17 do for x=0,21 do for _,p in ipairs(variants)do if L:midAt(x,y)==p.tiles[1]then
  local match=true;for i,m in ipairs(p.tiles)do if L:midAt(x+(i-1)%3,y+math.floor((i-1)/3))~=m then match=false;break end end
  if match then stairs[#stairs+1]={kind='towerStair',x=x,y=y,left=p.left,down=p.down}end
 end end end end
 return stairs
end
function R.plan(d)
 if d and d.midLayout then R.rooms[d.midLayout]=nil end
 local n=R.profile(d);if not n then return end;local L=d.midLayout;local stairs=R.stairs(L)
 if #stairs~=((n==1 or n==7)and 1 or 2)then return end
 R.rooms[L]=stairs
 local objects={{kind='towerShell'}};local mask={}
 for x=2,20 do for y=0,bases[x]/16-1 do mask[y*24+x+1]={mid=0x281,void=true,separateSurface=true}end end
 for _,o in ipairs(stairs)do
  objects[#objects+1]=o
  for y=o.y-1,math.min(19,o.y+3)do for x=o.x,o.x+2 do mask[y*24+x+1]={mid=0x282,void=true,separateSurface=true}end end
 end
 return{objects=objects,mask=mask}
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 for _,o in ipairs(R.rooms[d.midLayout]or{})do
  local a=o.x*16+(o.left and 0 or 16);local t=(x-a)/32
  if t>=0 and t<=1 and z>=o.y*16+16 and z<=o.y*16+44 then
   local step=math.min(7,math.floor(t*8));return (o.left and 8-step or step+1)/8*cfg().stairHeight*(o.down and -1 or 1)
  end
 end
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();if not c.enabled then return end
 local G,P,B=V.require('WorldGeometry'),V.require('PaperSprite'),V.require('BuildingMesh');local hs=V.require('Billboard').heightScale()
 local function src(x,z)return L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16 end
 local function draw(w,h,source,inside,point,shade)
  local vv=P.build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,point,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 local function q(a,b,d,e,uv,shade)
  local function p(v)return{v[1]+ox*16,v[2],v[3]+oz*16}end
  G.quad(out,p(a),p(b),p(d),p(e),uv,shade)
 end
 local owned={}
 for _,o in ipairs(objects)do if o.kind=='towerMemorial'or o.kind=='towerReception'or o.kind=='towerStatue'then
  for y=o.y,o.y+o.h/16-1 do for x=o.x,o.x+o.w/16-1 do owned[y*24+x+1]=true end end
 end end
 local stairs=R.stairs(L)
 for _,o in ipairs(objects)do
  if o.kind=='towerShell'then
   local height=c.wallHeight*hs;local cap={}
   -- A recessed flight is inside the room, never visible through the void
   -- beyond its native floor outline. Depth-writing black skirt closes that
   -- outer boundary below ground only; no added wall above the floor.
   local footprint={}
   for zz=0,319 do for xx=0,383 do
    local r,g,b=B.pixel(ts,src(xx,zz));if r+g+b>0 then footprint[zz*384+xx]=true end
   end end
   local void=G.uv(ts,0x281,0,0,1,1,.5)
   for key in pairs(footprint)do local xx,zz=key%384,math.floor(key/384)
    for _,e in ipairs{{-1,0,xx,zz,xx,zz+1},{1,0,xx+1,zz+1,xx+1,zz},{0,-1,xx+1,zz,xx,zz},{0,1,xx,zz+1,xx+1,zz+1}}do
     if not footprint[(zz+e[2])*384+xx+e[1]]then
      q({e[3],0,e[4]},{e[5],0,e[6]},{e[5],-c.stairHeight-2,e[6]},{e[3],-c.stairHeight-2,e[4]},void,0)
     end
    end
   end
   for x=32,335 do local base=R.wallBase(x)
    for z=0,base-27 do local r,g,b=B.pixel(ts,src(x,z));if r+g+b>0 then cap[z*384+x]=true end end
   end
   -- The six-pixel coping stays horizontal; the purple 26-pixel wall
   -- course stands upright at its exact native floor boundary.
   for col=2,20 do local x0,base=col*16,bases[col]
    draw(16,26,function(s,t)local x=x0+s;local z=base-26+t
     for _,a in ipairs(stairs)do if not a.down and not a.left and x>=(a.x+2)*16 and x<(a.x+3)*16 and z>=a.y*16-8 then
      return t<10 and 0x298 or 0x2a0,x%16,(t+6)%16
     end end
     return src(x,z)
    end,nil,function(s,t)return{x0+s,height*(26-t)/26,base}end)
   end
   draw(384,128,src,function(s,t)return cap[t*384+s]end,function(s,t)return{s,height,t+26}end)
   for key in pairs(cap)do local x,z=key%384,math.floor(key/384)
    for _,e in ipairs{{-1,0,x,z,x,z+1},{1,0,x+1,z+1,x+1,z},{0,-1,x+1,z,x,z}}do
     if not cap[(z+e[2])*384+x+e[1]]then
      for t=0,25 do local mid=t<10 and 0x298 or 0x2a0;local uv=G.uv(ts,mid,x%16,(t+6)%16,x%16+1,(t+6)%16+1,.5)
       q({e[3],height*(26-t)/26,e[4]+26},{e[5],height*(26-t)/26,e[6]+26},{e[5],height*(25-t)/26,e[6]+26},{e[3],height*(25-t)/26,e[4]+26},uv,c.sideShade)
      end
     end
    end
   end
  elseif o.kind=='towerStair'then
   local x,z=o.x*16,o.y*16;local start=x+(o.left and 0 or 16);local finish=start+32;local back,front=z+16,z+44
   -- Source cards include a rail in the preceding row and a shadow below.
   -- Keep native green floor pixels, restore only the removed colored body.
   draw(48,80,function(s,t)local xx,zz=x+s,z-16+t;local r,g,b=B.pixel(ts,src(xx,zz))
    if r+g+b>0 and not(g>r and r==b)then return xx<48 and 0x285 or 0x282,xx%16,zz%16 end
    return src(xx,zz)
   end,function(s,t)local xx,zz=x+s,z-16+t;local base=R.wallBase(xx)
    if (base and zz<base)or owned[math.floor(zz/16)*24+math.floor(xx/16)+1]then return false end
    if o.down and xx>=start and xx<finish and zz>=back and zz<front then return false end
    local r,g,b=B.pixel(ts,src(xx,zz));return r+g+b>0
   end,function(s,t)return{x+s,0,z-16+t}end)
   local palette={}
   for t=0,47 do for s=0,47 do local m,u,v=src(x+s,z+t);local col=rgb(B.pixel(ts,m,u,v));if not palette[col]then palette[col]=G.uv(ts,m,u,v,u+1,v+1,.5)end end end
   local function tex(col)return assert(palette[col],string.format('tower stair missing native color %06x',col))end
   local tread,edge,side,rail,dark=tex(0xe6e6ff),tex(0xbda5e6),tex(0x9c7bce),tex(0xceadf7),tex(0x52526b)
   local sign=o.down and -1 or 1;local H=c.stairHeight
   for i=0,7 do
    local a,b=start+i*4,start+(i+1)*4;local n=o.left and 8-i or i+1;local h=sign*n*H/8;local nh=sign*(o.left and 7-i or i)*H/8
    q({a,h,back},{b,h,back},{b,h,front},{a,h,front},tread)
    local boundary=o.left and b or a
    q({boundary,h,back},{boundary,h,front},{boundary,nh,front},{boundary,nh,back},edge,c.riserShade)
    q({a,h+.01,back},{a+1,h+.01,back},{a+1,h+.01,front},{a,h+.01,front},edge)
    for _,zz in ipairs{back,front}do q({a,h,zz},{b,h,zz},{b,0,zz},{a,0,zz},side,c.sideShade)end
   end
   local highX=o.left and start or finish
   q({highX,sign*H,back},{highX,sign*H,front},{highX,0,front},{highX,0,back},side,c.sideShade)
   for _,zz in ipairs{back-2,front}do
    for i=0,7 do local a,b=start+i*4,start+(i+1)*4
     local ha=o.down and c.railHeight or (o.left and 1-i/8 or i/8)*H+c.railHeight
     local hb=o.down and c.railHeight or (o.left and 1-(i+1)/8 or (i+1)/8)*H+c.railHeight
     q({a,ha,zz},{b,hb,zz},{b,hb,zz+2},{a,ha,zz+2},rail)
     for _,edgeZ in ipairs{zz,zz+2}do q({a,ha,edgeZ},{b,hb,edgeZ},{b,hb-2,edgeZ},{a,ha-2,edgeZ},side)end
     local foot=o.down and 0 or (o.left and 8-i or i+1)*H/8
     q({a+1,ha-1,zz+2},{a+2,ha-1,zz+2},{a+2,foot,zz+2},{a+1,foot,zz+2},dark)
     q({a+2,ha-1,zz+2},{a+3,ha-1,zz+2},{a+3,foot,zz+2},{a+2,foot,zz+2},rail)
    end
   end
   if o.down then
    q({highX,c.railHeight,back-2},{highX,c.railHeight,front+2},{highX,c.railHeight-2,front+2},{highX,c.railHeight-2,back-2},rail)
   end
  end
 end
end
return R
