-- Exact native Ho-Oh summit and Lugia chamber. Presentation owns no events.
local V=...;local S={masks=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').terrain.emNavelSanctums end
function S.profile(d)
 local sizes={EM_NAVEL_ROCK_TOP={26,28,'top'},EM_NAVEL_ROCK_BOTTOM={22,22,'bottom'}};local v=d and sizes[d.id];local L=d and d.midLayout
 return cfg().enabled and v and d.pair=='general__navel_rock'and tonumber(d.mapType)==4 and L and L.width==v[1]and L.height==v[2]and v[3]or nil
end
function S.active(d)return S.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
local function rock(m)return m==0x33d or m==0x33e end
function S.floorHeight(d,z,x)
 local c=cfg();if d.id=='EM_NAVEL_ROCK_BOTTOM'then
  local b=c.bottom;if x and (x<10*16 or x>=13*16)then return 0 end;return b.platformHeight*(1-math.max(0,math.min(b.steps,math.floor((z-b.stairRow*16)/(16/b.steps))))/b.steps)
 end
 local t=c.top;return t.upperHeight-(t.upperHeight-t.lowerHeight)*math.max(0,math.min(t.steps,math.floor((z-t.stairRow*16)/(t.stairRows*16/t.steps))))/t.steps
end
function S.actorHeight(d,x,z)if S.active(d)then return S.floorHeight(d,z+15.99,x+8)end end
function S.kind(d,c)
 if not S.active(d)or not c then return end
 local m=c.mid;if m==0x33c or m==0x147 or rock(m)or m==0x364 or m==0x38b then return end
 if c.coll==7 or c.coll==255 then return'emNavelSanctumWall'end
end
local function heightAt(d,x,y,wz)
 local m=d.midLayout:midAt(x,y);local c=cfg()
 if d.id=='EM_NAVEL_ROCK_BOTTOM'then
  if m<0x33d or m==0x370 or m==0x372 or m>=0x3a0 then return c.wallHeight end
  return c.innerHeight
 end
 if m>=0x210 and m<=0x21a and y<16 then local t=c.top;local f=math.max(0,math.min(1,(wz-t.stairRow*16)/(t.stairRows*16)));return t.upperHeight-(t.upperHeight-t.lowerHeight)*f end
 if x>=9 and x<=15 and y>=22 then return c.top.lowerHeight end
 return math.max(0,(d.midLayout.height-wz/16)*c.top.mountainTierHeight)
end
function S.height(d,x,y)return heightAt(d,x,y,y*16)end
local function original(d,x,y)local m=d.midLayout:midAt(x,y);return m==0x383 and 0x36c or m end
function S.mask(ts,m,top)
 local cache=S.masks[ts];if not cache then cache={};S.masks[ts]=cache end
 local key=tostring(m)..':'..tostring(top);if cache[key]then return cache[key]end
 local poly=not top and (m==0x210 or m==0x212)and V.require('EmeraldCaveContours').polygon(ts,m,0x847b3a,.5)
 local result={};for y=0,15 do for x=0,15 do
  local yes=true
  if top then local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y);yes=math.abs(r-115/255)+math.abs(g-189/255)+math.abs(b-247/255)>.005
  elseif poly then yes=V.require('EmeraldCaveContours').contains(poly,x+.5,y+.5)end
  result[y*16+x+1]=yes
 end end;cache[key]=result;return result
end
function S.stamp(out,d,ts,x,y,ox,oz)
 if not S.kind(d,d.midLayout:cellAt(x,y))then return false end
 local G=V.require('WorldGeometry');local L=d.midLayout;local top=d.id=='EM_NAVEL_ROCK_TOP';local m=original(d,x,y);local mask=S.mask(ts,m,top);local xx,zz=(x+ox)*16,(y+oz)*16
 local first=#out+1
 local function height(wz)return heightAt(d,x,y,wz)end
 for sy=0,15 do local sx=0;while sx<16 do
  if mask[sy*16+sx+1]then local a=sx;repeat sx=sx+1 until sx==16 or not mask[sy*16+sx+1]
   local h0,h1=height(y*16+sy),height(y*16+sy+1)
   G.quad(out,{xx+a,h0,zz+sy},{xx+sx,h0,zz+sy},{xx+sx,h1,zz+sy+1},{xx+a,h1,zz+sy+1},G.uv(ts,m,a,sy,sx,sy+1,.5),1)
  else sx=sx+1 end
 end end
 local function below(wx,wz,edgeZ)
  local a,b=math.floor(wx/16),math.floor(wz/16)
  if a<0 or b<0 or a>=L.width or b>=L.height then return 0 end
  local cell=L:cellAt(a,b);if cell.mid==0x33c then return 0 end
  if S.kind(d,cell)and S.mask(ts,original(d,a,b),top)[(wz%16)*16+wx%16+1]then return heightAt(d,a,b,edgeZ)end
  -- A masked mountain texel exposes sky rather than a hidden floor shelf.
  if top and S.kind(d,cell)then return 0 end
  return S.floorHeight(d,edgeZ,wx)
 end
 for sy=0,15 do for sx=0,15 do if mask[sy*16+sx+1]then
  for _,q in ipairs{{0,1},{0,-1},{1,0},{-1,0}}do
   local a,b
   if q[1]==0 then local z=sy+(q[2]>0 and 1 or 0);a={sx,z};b={sx+1,z}else local xp=sx+(q[1]>0 and 1 or 0);a={xp,sy};b={xp,sy+1}end
   local h0,h1=height(y*16+a[2]),height(y*16+b[2])
   local low0=math.min(h0,below(x*16+sx+q[1],y*16+sy+q[2],y*16+a[2]))
   local low1=math.min(h1,below(x*16+sx+q[1],y*16+sy+q[2],y*16+b[2]))
   if low0<h0 or low1<h1 then local u=q[1]==0 and sx or sy
    G.quad(out,{xx+a[1],h0,zz+a[2]},{xx+b[1],h1,zz+b[2]},{xx+b[1],low1,zz+b[2]},{xx+a[1],low0,zz+a[2]},G.uv(ts,m<0x33d and 0x219 or 0x36c,u,0,u+1,16,.5),cfg().sideShade)
   end
  end
 end end end
 for i=first,#out do out[i][9]=-2 end;return true
end
function S.floor(out,d,ts,x,y,ox,oz)
 if not S.active(d)then return false end
 local L=d.midLayout;local m=L:midAt(x,y);if m==0x33c then return true end
 if S.kind(d,L:cellAt(x,y))then return false end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16;local tile=(rock(m)or m==0x38b)and 0x364 or m
 for sy=0,15 do local a,b=S.floorHeight(d,y*16+sy,x*16+8),S.floorHeight(d,y*16+sy+1,x*16+8)
  G.quad(out,{xx,a,zz+sy},{xx+16,a,zz+sy},{xx+16,a,zz+sy+1},{xx,a,zz+sy+1},G.uv(ts,tile,0,sy,16,sy+1,.5),m==0x147 and G.WATER or 1)
  -- Close the tiny side rises between discrete treads and a continuous rock slope.
  for _,dx in ipairs{-1,1}do local nx=x+dx
   if nx>=0 and nx<L.width then local c=L:cellAt(nx,y);local h0,h1
    if S.kind(d,c)then h0,h1=heightAt(d,nx,y,y*16+sy),heightAt(d,nx,y,y*16+sy+1)
    elseif c.mid==0x33c then h0,h1=0,0
    else h0,h1=S.floorHeight(d,y*16+sy,nx*16+8),S.floorHeight(d,y*16+sy+1,nx*16+8)end
    h0,h1=math.min(a,h0),math.min(a,h1)
    if h0<a or h1<a then local edge=xx+(dx>0 and 16 or 0)
     G.quad(out,{edge,a,zz+sy},{edge,a,zz+sy+1},{edge,h1,zz+sy+1},{edge,h0,zz+sy},G.uv(ts,d.id=='EM_NAVEL_ROCK_TOP'and 0x219 or 0x36c,0,0,1,16,.5),cfg().sideShade)
    end
   end
  end
  if a~=b then G.quad(out,{xx,a,zz+sy+1},{xx+16,a,zz+sy+1},{xx+16,b,zz+sy+1},{xx,b,zz+sy+1},G.uv(ts,d.id=='EM_NAVEL_ROCK_TOP'and 0x219 or 0x36c,0,0,16,4,.5),cfg().sideShade)end
 end
 return true
end
function S.objects(out,d,ts,ox,oz,contacts)
 if not S.active(d)or d.id~='EM_NAVEL_ROCK_BOTTOM'then return end
 local L=d.midLayout;local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local A=V.require('CaveObjectArt')
 local function put(vv,x,y)for _,v in ipairs(vv)do v[2]=v[2]+S.floorHeight(d,y*16-.01,x*16+8);out[#out+1]=G.place(v,(x+ox)*16,(y+oz)*16)end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if rock(m)then put(P.build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return A.rockPixel(m==0x33d and 0x202 or 0x203,s,t)end,0,16,cfg().rockScale,nil,nil,.5),x,y+1);contacts[#contacts+1]={(x+ox)*16+8,(y+oz+1)*16,5,2,cfg().contactStrength}end
 end end
 for _,w in ipairs(d.warps or{})do if L:midAt(w.x,w.y)==0x38b and L:midAt(w.x,w.y-1)==0x383 then
  local function src(s,t)return t<16 and 0x383 or 0x38b,s,t%16 end
  put(P.build(ts,16,32,src,function(s,t)return A.ladderPixel(ts,s,t,src,{0xcece94,0x94945a,0x192100,0x424210},{3,12,2,29})end,0,32,1,nil,function(s,t)return{s,cfg().innerHeight*(30-t)/28,(t-30)/28*16+cfg().ladderOffset}end,.5),w.x,w.y+1)
 end end
end
function S.light(d,result)
 local kind=S.active(d)and S.profile(d);if not kind then return end
 local c=cfg()[kind];result.ambient={unpack(c.ambient)};local kept={};for _,l in ipairs(result.lights)do if l.kind=='flash'or l.kind=='player'then kept[#kept+1]=l end end;result.lights=kept;result.shafts={};result.sprites={};result.fireflies=0;result.crystals=0
 if kind=='top'then result.sun=c.sun;result.direction=c.direction;return end
 for _,p in ipairs(c.positions)do result.lights[#result.lights+1]={x=p[1]*16+8,z=p[2]*16+8,y=c.lightHeight,radius=-c.radius,power=c.power,color=c.color,point=true,falloff=2,kind='navelChamber'}end
end
function S.drawBackdrop(d)
 if not S.active(d)or d.id~='EM_NAVEL_ROCK_TOP'then return end
 local ts=V.require('WorldAdapter').Native.get(d.pair);local r,g,b=V.require('BuildingMesh').pixel(ts,0x33c,0,0)
 love.graphics.clear(r,g,b,1,0,1)
end
return S
