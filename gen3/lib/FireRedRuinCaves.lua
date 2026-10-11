-- Native Nabelfels / Dotted Hole rock family. Visual geometry only.
local V=...;local R={pixels=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').terrain.frRuinCaves end
function R.profile(d)
 return d and cfg().enabled and (d.renderPair or d.pair)=='general__rom_082d501c'and tonumber(d.mapType)==4
  and not V.data('Shapes').outdoors(d)and ((d.id or''):match('^FR_NAVEL_ROCK_')or(d.id or''):match('^FR_SIX_ISLAND_DOTTED_HOLE_'))and true or nil
end
local function active(d)return R.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
local function base(d)return d.id=='FR_NAVEL_ROCK_BASE'end
function R.kind(d,c)
 if not active(d)or not c then return end
 local m=c.mid
 if c.coll>=0xa0 and c.coll<=0xa7 then return'frRuinLedge'end
 if(c.coll~=7 and c.coll~=0xff)or m<0x280 or m==0x282 or m==0x283 or m==0x2b7 or m==0x347 or m==0x2c0 then return end
 if base(d)then
  if m<0x308 or m>=0x33b and m<=0x33f then return'frRuinOuter'end
  if m==0x328 or m==0x32a then return'frRuinTerrace'end
 end
 return'frRuin'
end
function R.height(k)
 local c=cfg();return k=='frRuinOuter'and c.outerHeight or k=='frRuinTerrace'and c.terraceHeight or k=='frRuinLedge'and c.ledgeHeight or c.wallHeight
end
function R.floorHeight(d,z)
 if not base(d)then return 0 end
 local c=cfg();local step=math.max(0,math.min(c.stairSteps,math.floor((z-17*16)/(16/c.stairSteps))))
 return c.platformHeight*(1-step/c.stairSteps)
end
function R.actorHeight(d,x,z)
 if not active(d)then return end
 local L=d.midLayout;local m=L:midAt(math.floor((x+8)/16),math.floor((z+15.99)/16))
 return m==0x347 and cfg().pedestalHeight or R.floorHeight(d,z+15.99)
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local floorColors={[0xc5d6ce]=true,[0xa5adad]=true,[0xb5c5bd]=true}
local function original(d,x,y)
 local L=d.midLayout;local m=L:midAt(x,y)
 if m==0x28e or m==0x28f then return 0x299 end
 if m==0x353 then return 0x299 end
 if m==0x32f and L:midAt(x,y+1)==0x337 then return 0x30c end
 return m
end
function R.mask(ts,m)
 local cache=R.pixels[ts];if not cache then cache={};R.pixels[ts]=cache end
 if cache[m]then return cache[m]end
 local mask={count=0}
 for y=0,15 do for x=0,15 do
  local yes=m>=0x308 or not floorColors[rgb(V.require('BuildingMesh').pixel(ts,m,x,y))]
  mask[y*16+x+1]=yes;if yes then mask.count=mask.count+1 end
 end end
 cache[m]=mask;return mask
end
function R.pixel(ts,m,x,y)return R.mask(ts,m)[y*16+x+1]end

function R.stamp(out,d,ts,x,y,ox,oz)
 if not active(d)then return false end
 local L=d.midLayout;local c=L:cellAt(x,y);local kind=R.kind(d,c);if not kind then return false end
 local G=V.require('WorldGeometry');local C=cfg();local m=original(d,x,y);local h=R.height(kind)
 local xx,zz=(x+ox)*16,(y+oz)*16;local mask=R.mask(ts,m)
 local function height(wx,wz)
  local cx,cy=math.floor(wx/16),math.floor(wz/16)
  if cx==x and cy==y then return mask[(wz%16)*16+wx%16+1]and h or R.floorHeight(d,wz)end
  local k=R.kind(d,L:cellAt(cx,cy))
  if not k then return R.floorHeight(d,wz)end
  local mid=original(d,cx,cy)
  return R.pixel(ts,mid,wx%16,wz%16)and R.height(k)or R.floorHeight(d,wz)
 end
 -- The original floor survives underneath every masked native corner.
 R.ground(out,d,ts,base(d)and 0x32c or 0x281,x,y,ox,oz,1)
 local first=#out+1 -- The walkable platform is not part of the removable rock shell.
 if mask.count==256 then
  G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m,0,0,16,16,.5),1)
 else for sy=0,15 do local sx=0
  while sx<16 do
   if R.pixel(ts,m,sx,sy)then local start=sx;repeat sx=sx+1 until sx==16 or not R.pixel(ts,m,sx,sy)
    G.quad(out,{xx+start,h,zz+sy},{xx+sx,h,zz+sy},{xx+sx,h,zz+sy+1},{xx+start,h,zz+sy+1},G.uv(ts,m,start,sy,sx,sy+1,.5),1)
   else sx=sx+1 end
  end
 end end
 local donor=m>=0x308 and 0x30c or 0x299
 for sy=0,15 do for sx=0,15 do if R.pixel(ts,m,sx,sy)then
  for _,dir in ipairs{{0,1},{0,-1},{1,0},{-1,0}}do
   local low=height(x*16+sx+dir[1],y*16+sy+dir[2])
   if low<h then
    local a,b
    if dir[1]==0 then local z=zz+sy+(dir[2]>0 and 1 or 0);a={xx+sx,z};b={xx+sx+1,z}
    else local xp=xx+sx+(dir[1]>0 and 1 or 0);a={xp,zz+sy};b={xp,zz+sy+1}end
    local u=dir[1]==0 and sx or sy
    local bottomA,bottomB=low,low
    G.quad(out,{a[1],h,a[2]},{b[1],h,b[2]},{b[1],bottomB,b[2]},{a[1],bottomA,a[2]},G.uv(ts,donor,u,0,u+1,16,.5),C.sideShade)
   end
  end
 end end end
 for i=first,#out do out[i][9]=-2 end
 return true
end
local function ascent(d,w)
 local L=d.midLayout;local m=L:midAt(w.x,w.y);local up=L:midAt(w.x,w.y-1)
 if (up==0x28e or up==0x28f)and(m==0x296 or m==0x297)then return{upper=up,lower=m,x=w.x,y=w.y-1,h=2}
 elseif up==0x32f and m==0x337 then return{upper=up,lower=m,x=w.x,y=w.y-1,h=2}end
end
function R.ground(out,d,ts,mid,x,y,ox,oz,material)
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 local h=R.floorHeight(d,y*16)
 if h==R.floorHeight(d,(y+1)*16)then
  G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,mid,0,0,16,16,.5),material);return
 end
 for sy=0,15 do
  local a=R.floorHeight(d,y*16+sy);local b=R.floorHeight(d,y*16+sy+1)
  G.quad(out,{xx,a,zz+sy},{xx+16,a,zz+sy},{xx+16,a,zz+sy+1},{xx,a,zz+sy+1},G.uv(ts,mid,0,sy,16,sy+1,.5),material)
  if a~=b then G.quad(out,{xx,a,zz+sy+1},{xx+16,a,zz+sy+1},{xx+16,b,zz+sy+1},{xx,b,zz+sy+1},G.uv(ts,mid,0,sy,16,sy+1,.5),cfg().sideShade)end
 end
end
function R.floor(out,d,ts,x,y,ox,oz)
 if not active(d)then return false end
 local L=d.midLayout;local mid=L:midAt(x,y);local donor
 if mid==0x282 or mid==0x283 or mid==0x296 or mid==0x297 or mid==0x35b or mid==0x347 then donor=0x281
 elseif mid==0x337 then donor=0x32c end
 if not donor and not(base(d)and not R.kind(d,L:cellAt(x,y)))then return false end
 local G=V.require('WorldGeometry')
 R.ground(out,d,ts,donor or mid,x,y,ox,oz,V.data('Shapes').water(L:cellAt(x,y))and G.WATER or 1)
 return true
end
function R.objects(out,d,ts,ox,oz,contacts)
 if not active(d)then return end
 local L=d.midLayout;local C=cfg();local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local pixel=V.require('BuildingMesh').pixel
 local function place(v,x,z)for _,p in ipairs(v)do out[#out+1]=G.place(p,x+ox*16,z+oz*16)end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x282 or m==0x283 then
   local h=R.floorHeight(d,(y+1)*16)
   local verts=P.build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return not floorColors[rgb(pixel(ts,m,s,t))]end,0,16,C.rockScale,function()return 1 end,nil,.5)
   for _,v in ipairs(verts)do v[2]=v[2]+h end;place(verts,x*16,(y+1)*16)
   contacts[#contacts+1]={(x+ox)*16+8,(y+oz+1)*16,5,C.contactDepth,C.contactStrength}
  elseif m==0x2c0 then
   -- Freestanding Braille stone: retain the native full face vertically,
   -- with a closed cap and sides sampled from its unlettered stone edge.
   local xx,zz=(x+ox)*16,(y+oz)*16;local h=C.tabletHeight
   local edge=G.uv(ts,m,2,8,3,9,.5)
   G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},edge,1)
   for _,e in ipairs{{0,0,16,0},{16,0,16,16},{0,16,0,0}}do
    G.quad(out,{xx+e[1],h,zz+e[2]},{xx+e[3],h,zz+e[4]},{xx+e[3],0,zz+e[4]},{xx+e[1],0,zz+e[2]},edge,C.sideShade)
   end
   G.quad(out,{xx,h,zz+16},{xx+16,h,zz+16},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,m,0,0,16,16,.5),1)
  elseif m==0x347 then
   local xx,zz=(x+ox)*16,(y+oz)*16;local h=C.pedestalHeight;local uv=G.uv(ts,m,0,0,16,16,.5)
   G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},uv,1)
   for _,edge in ipairs{{0,0,16,0},{16,0,16,16},{16,16,0,16},{0,16,0,0}}do
    G.quad(out,{xx+edge[1],h,zz+edge[2]},{xx+edge[3],h,zz+edge[4]},{xx+edge[3],0,zz+edge[4]},{xx+edge[1],0,zz+edge[2]},G.uv(ts,m,0,0,1,1,.5),C.sideShade)
   end
  elseif m==0x353 and L:midAt(x,y+1)==0x35b then
   place(P.build(ts,16,32,function(s,t)return t<16 and 0x353 or 0x35b,s,t%16 end,function(s,t)return t>=8 and t<24 end,0,32,1,nil,
    function(s,t)return{s,C.wallHeight+4-t,16+C.panelOffset}end,.5),x*16,y*16)
  end
 end end
 local wood={[0xcece6b]=true,[0xefefa5]=true,[0xadad5a]=true,[0x7b844a]=true,[0x525a21]=true}
 for _,w in ipairs(d.warps or{})do local o=ascent(d,w)
  if o then
   local function source(s,t)return t<16 and o.upper or o.lower,s,t%16 end
   local function color(s,t)if s<0 or s>=16 or t<0 or t>=o.h*16 then return end;local mid,u,v=source(s,t);return rgb(pixel(ts,mid,u,v))end
   local function inside(s,t)
    local c=color(s,t);return wood[c]or(c==0x4a4a4a or c==0)and(wood[color(s-1,t)]or wood[color(s+1,t)]or wood[color(s,t-1)]or wood[color(s,t+1)])
   end
   local lo,hi=math.huge,0;for t=0,o.h*16-1 do for s=0,15 do if inside(s,t)then lo=math.min(lo,t);hi=math.max(hi,t+1)end end end
   assert(hi>lo,'empty native ruin ladder')
   local h=C.wallHeight;local depth=16
   local verts=P.build(ts,16,o.h*16,source,inside,0,hi,1,function()return 1 end,function(s,t)local a=(t-lo)/(hi-lo);return{s,h*(1-a),-depth*(1-a)+C.ladderOffset}end,.5)
   place(verts,o.x*16,(o.y+o.h)*16)
  end
 end
end
return R
