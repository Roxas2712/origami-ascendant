-- Ember Spa has walkable bathing water, not Surf water. Visual pool levels
-- never replace native behavior/collision or the healing and tutor scripts.
local V=...;local A={cache=setmetatable({},{__mode='k'})}
local rim={[0x330]=true,[0x331]=true,[0x332]=true,[0x333]=true,[0x338]=true,[0x33a]=true,[0x360]=true,[0x361]=true}
local water={[0x326]=true,[0x327]=true,[0x339]=true,[0x137]=true}
function A.profile(d)return d and d.id=='FR_ONE_ISLAND_KINDLE_ROAD_EMBER_SPA'and (d.renderPair or d.pair)=='general__rom_082d4fec'end
local function cfg()return V.require('DioramaConfig').terrain.frEmberSpa end
function A.rock()return false end
function A.ladderUpper()return false end
function A.floorMid(m)return m end
function A.objects()end
function A.rim(m)return rim[m]end
function A.water(m)return water[m]or rim[m]or m==0x127 or m==0x12f end
function A.shore(_,m)return rim[m]or water[m]end
local function color(ts,m,x,y)local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y);return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function A.mask(ts,m)
 local c=A.cache[ts]
 if not c then
  c={floor={},water={}};A.cache[ts]=c
  for _,mid in ipairs{0x281,0x32d,0x339,0x326,0x327}do for y=0,15 do for x=0,15 do
   local t=mid==0x281 or mid==0x32d;local set=t and c.floor or c.water;set[color(ts,mid,x,y)]=true
  end end end
 end
 if not c[m]then local a={count=0}
  for y=0,15 do for x=0,15 do local v=color(ts,m,x,y);local yes=not c.floor[v]and not c.water[v];a[y*16+x+1]=yes;if yes then a.count=a.count+1 end end end
  c[m]=a
 end
 return c[m]
end
function A.pool(x,y)
 for _,p in ipairs(cfg().pools)do if x>=p.x0 and x<=p.x1 and y>=p.y0 and y<=p.y1 then return p end end
end
function A.waterHeight(x,y)
 local p=A.pool(x,y);return p and p.level*V.require('DioramaConfig').terrain.frTerracedCaves.platformHeight or 0
end
function A.floorHeight(d,x,z)
 local cx,cy=math.floor(x/16),math.floor(z/16);local m=d.midLayout:midAt(cx,cy)
 if m==0x127 or m==0x12f or m==0x137 then
  for _,f in ipairs(cfg().falls)do if cx>=f.x0 and cx<=f.x1 then
   local base=cfg().upperLevel*V.require('DioramaConfig').terrain.frTerracedCaves.platformHeight
   local t=math.max(0,math.min(1,(f.bottomRow*16-z)/((f.bottomRow-f.topRow)*16)))
   return base+cfg().fallHeight*t
  end end
 end
 if A.water(m)then return A.waterHeight(cx,cy)end
end
function A.plan(d,p)
 local L=d.midLayout;local C=cfg();local shared=V.require('DioramaConfig').terrain.frTerracedCaves
 p.borderTop=function(_,y)return(y<C.upperEdgeRow and C.upperLevel*shared.platformHeight or 0)+shared.wallHeight end
 for y=0,L.height-1 do for x=0,L.width-1 do local k=y*L.width+x+1;local c=L:cellAt(x,y)
  if A.water(c.mid)then
   local h=A.waterHeight(x,y);p.base[k]=h;p.top[k]=h+C.rimHeight
   if p.level[k]then p.level[k]=h/shared.platformHeight end
  elseif c.coll==7 or c.coll==255 then
   local h=y<C.upperEdgeRow and C.upperLevel*shared.platformHeight or 0
   p.base[k]=h;p.top[k]=h+shared.wallHeight
  end
 end end
end
function A.floor(out,d,ts,x,y,ox,oz)
 local m=d.midLayout:midAt(x,y);if not A.water(m)then return false end
 local G=V.require('WorldGeometry');local h=A.floorHeight(d,x*16,y*16);local low=A.floorHeight(d,x*16,(y+1)*16-.001)
 local xx,zz=(x+ox)*16,(y+oz)*16
 G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,low,zz+16},{xx,low,zz+16},G.uv(ts,m,0,0,16,16,.5),G.WATER)
 return true
end
function A.light(d,result)
 local C=cfg();if not(A.profile(d)and C.enabled and C.lighting.enabled and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective')then return end
 local c=C.lighting;result.ambient={unpack(c.ambient)}
 -- Stable broad ceiling light, with weak warm reflections at the thermal
 -- pools. No player-following glow, volcanic ash or random shafts indoors.
 local kept={};for _,l in ipairs(result.lights)do if l.kind=='flash'or l.kind=='player'then kept[#kept+1]=l end end
 result.lights=kept;result.shafts={};result.sprites={}
 for _,q in ipairs(c.ceiling)do result.lights[#result.lights+1]={x=q[1]*16,y=q[3],z=q[2]*16,radius=-c.radius,power=c.power,color=c.color,falloff=2,kind='spaCeiling',point=true}end
 for _,p in ipairs(C.pools)do
  result.lights[#result.lights+1]={x=(p.x0+p.x1+1)*8,y=p.level*V.require('DioramaConfig').terrain.frTerracedCaves.platformHeight+c.poolHeight,z=(p.y0+p.y1+1)*8,radius=-c.poolRadius,power=c.poolPower,color=c.poolColor,falloff=2,kind='spaReflection',point=true}
 end
end
return A
