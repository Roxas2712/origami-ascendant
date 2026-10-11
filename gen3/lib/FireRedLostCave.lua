-- Lost Cave's native room shell. Geometry only; the directional warp puzzle
-- remains in the engine. Other brown-cave terraces need a separate profile.
local V=...;local R={masks=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').terrain.frLostCave end
function R.profile(d)return d and cfg().enabled and (d.renderPair or d.pair)=='general__rom_082d4bfc'and tonumber(d.mapType)==4 and(d.id or''):match('^FR_FIVE_ISLAND_LOST_CAVE_')and true or nil end
local function active(d)return R.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
function R.kind(d,c)
 if not active(d)or not c or(c.coll~=7 and c.coll~=255)or c.mid<0x280 or c.mid==0x282 or c.mid==0x283 then return end
 return'frLostWall'
end
function R.height()return cfg().wallHeight end
local floors={[0x948c73]=true,[0xadad8c]=true,[0x7b735a]=true,[0xbdbd9c]=true}
local function color(ts,m,x,y)local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y);return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local function donor(m)
 if m==0x28f or m==0x28e or m==0x28c then return 0x299 end
 return m
end
function R.mask(ts,m)
 local cache=R.masks[ts];if not cache then cache={};R.masks[ts]=cache end
 if cache[m]then return cache[m]end
 local mask={count=0};for y=0,15 do for x=0,15 do local c=color(ts,m,x,y);local yes=not floors[c]and not((m==0x30a or m==0x309)and c==0x21313a);mask[y*16+x+1]=yes;if yes then mask.count=mask.count+1 end end end
 cache[m]=mask;return mask
end
-- Native arch pixels stand at the wall seam. The dark core sits behind the
-- frame, with short connecting faces around every aperture boundary.
function R.portal(out,ts,mid,xx,zz,side)
 local G=V.require('WorldGeometry');local h=cfg().wallHeight;local depth=cfg().portalDepth
 local function dark(s,t)return color(ts,mid,s,t)==0 or color(ts,mid,s,t)==0x21313a end
 local firstDark=16
 for t=0,15 do for s=0,15 do if dark(s,t)then firstDark=math.min(firstDark,side=='west'and s or side=='east'and(15-s)or t)end end end
 local function height(a)
  local opening=cfg().portalOpeningHeight
  return a<=firstDark and h-(h-opening)*a/math.max(1,firstDark)or opening*(16-a)/(16-firstDark)
 end
 local function point(s,t,recess)
  if side=='west'then return{xx+16-recess,height(s),zz+t}
  elseif side=='east'then return{xx+recess,height(16-s),zz+16-t}
  else return{xx+s,height(t),zz+16-recess}end
 end
 local function level(s,t)return dark(s,t)and depth or 0 end
 for t=0,15 do for s=0,15 do local z=level(s,t)
  G.quad(out,point(s,t,z),point(s+1,t,z),point(s+1,t+1,z),point(s,t+1,z),G.uv(ts,mid,s,t,s+1,t+1,.5),1)
  if z>0 and((side=='north'and t==15)or(side=='west'and s==15)or(side=='east'and s==0))then
   local a,b,c,e
   if side=='north'then a,b=point(s,16,0),point(s+1,16,0);c,e=point(s+1,16,depth),point(s,16,depth)
   elseif side=='west'then a,b=point(16,t,0),point(16,t+1,0);c,e=point(16,t+1,depth),point(16,t,depth)
   else a,b=point(0,t,0),point(0,t+1,0);c,e=point(0,t+1,depth),point(0,t,depth)end
   G.quad(out,a,b,c,e,G.uv(ts,mid,s,t,s+1,t+1,.5),1)
  end
  if z==0 then
   for _,e in ipairs{{1,0},{-1,0},{0,1},{0,-1}}do local a,b=s+e[1],t+e[2]
    if a>=0 and a<16 and b>=0 and b<16 and level(a,b)>0 then
     local s0,t0,s1,t1=s,t,s,t
     if e[1]~=0 then s0=s+(e[1]>0 and 1 or 0);s1=s0;t1=t+1 else t0=t+(e[2]>0 and 1 or 0);t1=t0;s1=s+1 end
     G.quad(out,point(s0,t0,0),point(s1,t1,0),point(s1,t1,depth),point(s0,t0,depth),G.uv(ts,0x299,0,8,1,9,.5),cfg().sideShade)
    end
   end
  end
 end end
end
function R.stamp(out,d,ts,x,y,ox,oz)
 local L=d.midLayout;local c=L:cellAt(x,y);if not R.kind(d,c)then return false end
 local G=V.require('WorldGeometry');local h=R.height();local m=donor(c.mid);local mask=R.mask(ts,m);local xx,zz=(x+ox)*16,(y+oz)*16
 G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,0x281),1)
 local first=#out+1
 if c.mid==0x30a or c.mid==0x309 then
  for sy=0,15 do for sx=0,15 do if color(ts,c.mid,sx,sy)==0x21313a then
   G.quad(out,{xx+sx,0,zz+sy},{xx+sx+1,0,zz+sy},{xx+sx+1,0,zz+sy+1},{xx+sx,0,zz+sy+1},G.uv(ts,c.mid,sx,sy,sx+1,sy+1,.5),1)
  end end end
 end
 local function occupied(wx,wz)
  local cx,cy=math.floor(wx/16),math.floor(wz/16);local other=L:cellAt(cx,cy)
  return R.kind(d,other)and R.mask(ts,donor(other.mid))[(wz%16)*16+wx%16+1]
 end
 if mask.count==256 then G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m,0,0,16,16,.5),1)
 else for sy=0,15 do local sx=0;while sx<16 do if mask[sy*16+sx+1]then local a=sx;repeat sx=sx+1 until sx==16 or not mask[sy*16+sx+1]
  G.quad(out,{xx+a,h,zz+sy},{xx+sx,h,zz+sy},{xx+sx,h,zz+sy+1},{xx+a,h,zz+sy+1},G.uv(ts,m,a,sy,sx,sy+1,.5),1)
 else sx=sx+1 end end end end
 local portal=c.mid==0x28c and L:midAt(x,y+1)==0x294 and'north'or c.mid==0x30a and'west'or c.mid==0x309 and'east'
 for sy=0,15 do for sx=0,15 do if mask[sy*16+sx+1]then
  for _,dir in ipairs{{0,1},{0,-1},{1,0},{-1,0}}do
   local skip=portal=='north'and dir[2]==1 and sy==15 or portal=='west'and dir[1]==1 and sx==15 or portal=='east'and dir[1]==-1 and sx==0
   if not skip and not occupied(x*16+sx+dir[1],y*16+sy+dir[2])then
    local a,b,u;if dir[1]==0 then local z=zz+sy+(dir[2]>0 and 1 or 0);a={xx+sx,z};b={xx+sx+1,z};u=sx
    else local xp=xx+sx+(dir[1]>0 and 1 or 0);a={xp,zz+sy};b={xp,zz+sy+1};u=sy end
    G.quad(out,{a[1],h,a[2]},{b[1],h,b[2]},{b[1],0,b[2]},{a[1],0,a[2]},G.uv(ts,0x299,u,0,u+1,16,.5),cfg().sideShade)
   end
  end
 end end end
 if portal then R.portal(out,ts,c.mid,xx,zz,portal)end
 for i=first,#out do out[i][9]=-2 end
 return true
end
function R.floor(out,d,ts,x,y,ox,oz)
 if not active(d)then return false end
 local m=d.midLayout:midAt(x,y)
 if m~=0x282 and m~=0x283 and m~=0x296 and m~=0x297 then return false end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,0x281),1);return true
end
function R.objects(out,d,ts,ox,oz,contacts)
 if not active(d)then return end
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local L=d.midLayout;local C=cfg()
 local function place(v,x,z)for _,p in ipairs(v)do out[#out+1]=G.place(p,(x+ox)*16,(z+oz)*16)end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x282 or m==0x283 then
   place(P.build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return not floors[color(ts,m,s,t)]end,0,16,C.rockScale,function()return 1 end,nil,.5),x,y+1)
   contacts[#contacts+1]={(x+ox)*16+8,(y+oz+1)*16,5,C.contactDepth,C.contactStrength}
  end
 end end
 for _,w in ipairs(d.warps or{})do local lower=L:midAt(w.x,w.y);local upper=L:midAt(w.x,w.y-1)
  if(upper==0x28e or upper==0x28f)and(lower==0x296 or lower==0x297)then
   local function source(s,t)return t<16 and upper or lower,s,t%16 end
   local A=V.require('CaveObjectArt');local colors={0xffefa5,0xcead7b,0x4a4a3a,0x525242}
   local function inside(s,t)return A.ladderPixel(ts,s,t,source,colors,{0,15,0,31})end
   local lo,hi=32,0;for t=0,31 do for s=0,15 do if inside(s,t)then lo=math.min(lo,t);hi=math.max(hi,t+1)end end end
   assert(hi>lo,'missing native ladder')
   place(P.build(ts,16,32,source,inside,0,32,1,function()return 1 end,function(s,t)local f=(t-lo)/(hi-lo);return{s,C.wallHeight*(1-f),-16*(1-f)+C.ladderOffset}end,.5),w.x,w.y+1)
  end
 end
end
return R
