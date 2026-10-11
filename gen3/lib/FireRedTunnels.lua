-- The two native Underground Paths share wall courses and stair profiles.
-- Visual surfaces only: hidden items, exits and movement remain engine-owned.
local V=...;local R={}
local function cfg()return V.require('DioramaConfig').interiors.fireredTunnels end
function R.profile(d)
 local L=d and d.midLayout;if not(cfg().enabled and d and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4ee4'and L)then return end
 if d.id=='FR_UNDERGROUND_PATH_NORTH_SOUTH_TUNNEL'and L.width==8 and L.height==64 and L:midAt(5,1)==0x2ae and L:midAt(1,58)==0x2ac then return 'northSouth'end
 if d.id=='FR_UNDERGROUND_PATH_EAST_WEST_TUNNEL'and L.width==80 and L.height==8 and L:midAt(77,1)==0x2ae and L:midAt(1,2)==0x2ad then return 'eastWest'end
end
function R.stairInside(s,t,left)
 if s<0 or s>=32 or t<0 or t>=64 then return false end
 local top=left and 8+math.floor(s/2)or 23-math.floor(s/2)
 local edge=left and s or 31-s;local bottom=math.min(61,58+edge)
 return t>=top and t<bottom
end
function R.plan(d)
 local name=R.profile(d);if not name then return end;local L=d.midLayout;local mask={};for i=1,L.width*L.height do mask[i]={mid=8,void=true,separateSurface=true}end
 local W,H=L.width*16,L.height*16
 return{mask=mask,owners={},objects={{kind='tunnelFloor'},{kind='tunnelRear'},{kind='tunnelSides'},{kind='tunnelStair',x=W-48,y=16,left=false},{kind='tunnelStair',x=16,y=H-96,left=true}}}
end
function R.build(out,d,ts,ox,oz,contacts)
 local name=R.profile(d);if not name then return end
 local L,c=d.midLayout,cfg();local W,H=L.width*16,L.height*16;local hs=V.require('Billboard').heightScale();local P,G=V.require('PaperSprite'),V.require('WorldGeometry');local plan=R.plan(d)
 local stairs={plan.objects[4],plan.objects[5]}
 local function source(x,z)return L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16 end
 local function replacement(x,z)
  for _,o in ipairs(stairs)do if x>=o.x and x<o.x+32 and z>=o.y and z<o.y+64 then
   if z<32 then if R.stairInside(x-o.x,z-o.y,o.left)then return 0x28d,x%16,z%16 end
   elseif z<40 then return 0x295,x%16,z%16
   else return name=='eastWest'and(z>=48 and z<64 and 0x2bb or z>=64 and z<80 and 0x291)or 0x289,x%16,z%16 end
  end end
  return source(x,z)
 end
 local function draw(w,h,src,inside,point,shade)
  local vv=P.build(ts,w,h,src,inside or function()return true end,0,h,1,shade and function()return shade end or nil,point,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 draw(W-32,H-72,function(s,t)return replacement(s+16,t+40)end,nil,function(s,t)return{s+16,0,t+40}end)
 local first=#out+1;local height=c.wallHeight*hs
 draw(W-32,32,function(s,t)return replacement(s+16,t+8)end,nil,function(s,t)return{s+16,height*(32-t)/32,40}end)
 draw(W-32,1,function(s)return source(s+16,8)end,nil,function(s,t)return{s+16,height,40-c.wallDepth+t*c.wallDepth}end)
 for _,edge in ipairs{16,W-16}do draw(1,32,function(_,t)return replacement(math.min(W-17,edge),t+8)end,nil,function(s,t)return{edge,height*(32-t)/32,40-c.wallDepth+s*c.wallDepth}end,c.sideShade)end
 V.require('RoomLightRig').capture(L,{kind='wall'},out,first,#out)
 -- Low side and foreground rims are closed; native corners stay continuous.
 local low=c.sideHeight*hs
 for _,x in ipairs{8,W-16}do
  draw(8,H-72,function(s,t)return source(x+s,t+40)end,nil,function(s,t)return{x+s,low,t+40}end)
  for _,edge in ipairs{0,8}do draw(H-72,1,function(s)return source(x+math.min(7,edge),s+40)end,nil,function(s,t)return{x+edge,low*(1-t),s+40}end,c.sideShade)end
  draw(8,1,function(s)return source(x+s,40)end,nil,function(s,t)return{x+s,low*(1-t),40}end,c.sideShade)
 end
 draw(W-16,16,function(s,t)return source(s+8,H-32+t)end,nil,function(s,t)return{s+8,low,H-32+t}end)
 for _,z in ipairs{H-32,H-16}do draw(W-16,1,function(s)return source(s+8,math.min(H-17,z))end,nil,function(s,t)return{s+8,low*(1-t),z}end,c.sideShade)end
 for _,o in ipairs(stairs)do
  local base=o.y+48;local scale=c.stairScale*hs;local depth=c.railDepth
  local function src(s,t)return source(o.x+s,o.y+t)end
  local function inside(s,t)return R.stairInside(s,t,o.left)end
  draw(32,64,src,inside,function(s,t)return{o.x+s,(61-t)*scale,base}end)
  -- Native stepped outline closes the stair's top and sides, not its
  -- rectangular source tile. No wall/floor card is lifted with the stair.
  for t=0,63 do for s=0,31 do if inside(s,t)then
   local m,u,v=src(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local x,z=o.x+s+ox*16,base+oz*16;local a,b=(61-t)*scale,(60-t)*scale
   if not inside(s-1,t)then G.quad(out,{x,a,z-depth},{x,a,z},{x,b,z},{x,b,z-depth},uv,c.sideShade)end
   if not inside(s+1,t)then G.quad(out,{x+1,a,z},{x+1,a,z-depth},{x+1,b,z-depth},{x+1,b,z},uv,c.sideShade)end
   if not inside(s,t-1)then G.quad(out,{x,a,z-depth},{x+1,a,z-depth},{x+1,a,z},{x,a,z},uv)end
   if not inside(s,t+1)then G.quad(out,{x,b,z},{x+1,b,z},{x+1,b,z-depth},{x,b,z-depth},uv,c.sideShade)end
  end end end
  -- Eight real treads behind the thin native side profile. The railing
  -- is not a solid slab stretched across the whole stair width.
  for step=0,7 do
   local s=step*4;local top=o.left and 8+math.floor((s+2)/2)or 23-math.floor((s+2)/2)
   local rise=(61-(top+28))*scale
   local nextTop=o.left and 8+math.floor((s+6)/2)or 23-math.floor((s+6)/2)
   local nextRise=math.max(0,(61-(nextTop+28))*scale)
   local m,u,v=src(s+2,top+14);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
   local x,z=o.x+s+ox*16,base+oz*16
   G.quad(out,{x,rise,z-c.stairDepth},{x+4,rise,z-c.stairDepth},{x+4,rise,z-depth},{x,rise,z-depth},uv)
   G.quad(out,{x+4,rise,z-c.stairDepth},{x+4,nextRise,z-c.stairDepth},{x+4,nextRise,z-depth},{x+4,rise,z-depth},uv,c.sideShade)
  end
  contacts[#contacts+1]={o.x+16+ox*16,base+oz*16,14,c.contactRadius,c.contactStrength}
 end
end
function R.lighting(d)
 local name=R.profile(d);if not name then return end;local c=cfg();local L=d.midLayout;local W,H=L.width*16,L.height*16;local hs=V.require('Billboard').heightScale();local sources={}
 local function add(x,y,z,power,radius,color)sources[#sources+1]={at={x,y,z},power=power,radius=radius,color=color,spread=c.lightSpread}end
 -- Lamps are part of the native rear-wall drawing, including the one
 -- overlapping the right stair's source tiles. Match their raised position.
 local xs=name=='northSouth'and{40,88}or{40,200,360,520,760,920,1080,1240}
 for _,x in ipairs(xs)do add(x,c.wallHeight*hs*19/32,41,c.lampPower,c.lampRadius,c.lampColor)end
 -- Diffuse ceiling fill keeps the long narrow path readable between ends;
 -- it adds no invented wall fixtures and remains fixed at night.
 if name=='northSouth'then for z=120,H-64,112 do add(W/2,c.ceilingHeight,z,c.ceilingPower,c.ceilingRadius,c.ceilingColor)end
 else for x=120,W-64,160 do add(x,c.ceilingHeight,76,c.ceilingPower,c.ceilingRadius,c.ceilingColor)end end
 return{fixed=true,localSelection=true,ambient=c.ambient,sources=sources}
end
return R
