-- Hoenn-specific presentation. No writes to maps, scripts, collision or saves.
local V=...
local E={cache=setmetatable({},{__mode='k'})}
local profiles={
 woods={forestFog=.40},canopy={},rainforest={},
 granite={ambient={.085,.09,.075}},
 falls={ambient={.25,.22,.24},caustics=.13,mist=.10},
 tidal={ambient={.15,.21,.26},caustics=.10,mist=.07},
 ice={ambient={.20,.28,.36},caustics=.12},
 haunted={ambient={.24,.23,.30},mist=.26},
 volcano={lava=1},lava={ambient={.19,.095,.055},lava=1},
 underwater={ambient={.24,.49,.56},caustics=.40,mist=.16},
}
function E.profile(def)
 if V.require('EmeraldMagmaHideout').active(def)then return V.require('DioramaConfig').terrain.emMagmaHideout.environment,'magma'end
 if V.require('EmeraldTerraCave').active(def)then return V.require('EmeraldTerraCave').profile(def).environment,'terra'end
 local row=def and V.data('EmeraldLandscapes')[def.id or def.name]
 if row and row.theme=='underwater'and V.require('EmeraldUnderwater').profile(def)then return V.require('DioramaConfig').underwater.environment,row.theme end
 return row and profiles[row.theme],row and row.theme
end
function E.install()
 local cfg=V.require('DioramaConfig')
 -- Hoenn's small tree crowns lose their depth in the wide Kanto framing.
 -- Move outdoor framing closer; preserve the accepted room/cave distance.
 local previousZoom=cfg.camera.zoom
 cfg.camera.zoom=1.35
 cfg.camera.caveZoomScale=cfg.camera.caveZoomScale*previousZoom/cfg.camera.zoom
 cfg.camera.indoorZoomScale=cfg.camera.indoorZoomScale*previousZoom/cfg.camera.zoom
 for _,id in ipairs({'EM_SKY_PILLAR_TOP','EM_SKY_PILLAR_1F','EM_SKY_PILLAR_2F','EM_SKY_PILLAR_3F','EM_SKY_PILLAR_4F','EM_SKY_PILLAR_5F','EM_SKY_PILLAR_OUTSIDE','EM_SKY_PILLAR_ENTRANCE'})do V.data('Emerald').supported[id]=true end
 cfg.mapViews.EM_SKY_PILLAR_TOP={zoomScale=cfg.skyPillar.zoomScale,focusOffsetZ=-8,dofScale=cfg.skyPillar.dofScale}
 for id in pairs(V.data('EmeraldCaveCoverage'))do V.data('Emerald').supported[id]=true end
 for id in pairs(V.data('EmeraldLandscapes'))do V.data('Emerald').supported[id]=true end
 for _,id in ipairs({'EM_PETALBURG_WOODS','EM_FORTREE_CITY','EM_ROUTE119'})do cfg.forest.maps[id]=true end
 cfg.trees.pairStyle.general__rustboro={widthScale=1.0,heightScale=1.4,preserveCrownHeight=false,preserveScreenHeight=false,crownShade=.80,trunkShade=.26}
 local rules=cfg.places.rules
 for _,r in ipairs({{'^EM_GRANITE_CAVE','rocktunnel'},{'^EM_SHOAL_CAVE_LOW_TIDE_ICE_ROOM$','ice'},
  {'^EM_MAGMA_HIDEOUT','lava'},{'^EM_MT_CHIMNEY$','volcano'}})do rules[#rules+1]=r end
 for _,p in ipairs({'^EM_GRANITE_CAVE_B','^EM_MAGMA_HIDEOUT','^EM_SHOAL_CAVE_LOW_TIDE_ICE_ROOM$'})do cfg.caves.skylights.darkMaps[#cfg.caves.skylights.darkMaps+1]=p end
end
local function hash(x,y)return math.abs(math.sin(x*12.9898+y*78.233)*43758.5453)%1 end
local function sites(def)
 local L=def.midLayout
 if E.cache[L]then return E.cache[L]end
 local result={floor={},water={},hot={}}
 local ts=require('src.core.game3.tileset_native').get(def.pair)
 local pixel=V.require('BuildingMesh').pixel;local hotMids={}
 for y=0,L.height-1 do for x=0,L.width-1 do
  local c=L:cellAt(x,y);local p={x=x*16+8,z=y*16+8,seed=hash(x,y)}
  if c.mid~=0 and c.coll~=7 and c.coll~=255 then
   result.floor[#result.floor+1]=p
   if c.coll==0x29 then result.water[#result.water+1]=p end
  end
  if def.pair=='general__lavaridge' then
   if hotMids[c.mid]==nil then
    local n=0
    for sy=2,14,4 do for sx=2,14,4 do local r,g,b=pixel(ts,c.mid,sx,sy);if r>.65 and g<.4 and b<.28 then n=n+1 end end end
    hotMids[c.mid]=n>=8
   end
   if hotMids[c.mid]then result.hot[#result.hot+1]=p end
  end
 end end
 E.cache[L]=result;return result
end
local siteCache=setmetatable({},{__mode='k'})
local function nearby(items,px,pz,limit,spacing)
 -- Lay out emitters once in map space, before any player-distance test.
 -- Greedy placement from the nearest floor tile made entire pools chase you.
 local fixed=siteCache[items]
 if not fixed then
  fixed={};local sorted={};for i,p in ipairs(items)do sorted[i]=p end
  table.sort(sorted,function(a,b)return a.seed<b.seed end)
  spacing=math.max(spacing,260/math.sqrt(limit))
  for _,p in ipairs(sorted)do
   local free=true;for _,q in ipairs(fixed)do if (p.x-q.x)^2+(p.z-q.z)^2<spacing^2 then free=false;break end end
   if free then fixed[#fixed+1]=p end
  end
  siteCache[items]=fixed
 end
 local out={}
 for _,p in ipairs(fixed)do
  local d=math.sqrt((p.x-px)^2+(p.z-pz)^2)
  if d<260 then out[#out+1]={x=p.x,z=p.z,seed=p.seed,fade=math.min(1,(260-d)/70)}end
 end
 return out
end
function E.apply(def,result,px,pz,time,outdoors)
 V.require("EmeraldDepartmentRoof").light(def,result)
 V.require('EmeraldSkyPillar').light(def,result)
 local p,theme=E.profile(def);if not p then return end
 local data=sites(def);local start=#result.sprites
 if p.ambient and not outdoors and (theme~='granite' or V.require('Atmosphere').isDarkCave(def))then result.ambient={unpack(p.ambient)} end
 if V.require('EmeraldPyre').light(def,result,px,pz)then start=0 end
 if theme=='haunted' and outdoors then for i=1,3 do result.ambient[i]=result.ambient[i]*.72 end end
 if theme=='underwater'then result.sun=0;result.lights={};result.shafts={};result.sprites={};start=0 end
 if theme=='falls' or theme=='tidal' or theme=='underwater'then
  local water=theme=='underwater'and V.require('EmeraldUnderwater').profile(def)
  local lc=water and water.light
  for i,s in ipairs(nearby(theme=='underwater' and data.floor or data.water,px,pz,lc and lc.count or 5,lc and lc.spacing or 74))do
   local col=lc and lc.color or theme=='underwater' and {.30,.83,1}or{.48,.77,1}
   result.lights[#result.lights+1]={x=s.x,y=lc and lc.height or 12,z=s.z,radius=-(lc and lc.radius or 65),power=((lc and lc.power or .36)+(lc and lc.pulse or .10)*math.sin(time*(lc and lc.speed or .7)+s.seed*7))*s.fade,color=col,point=water~=nil and water~=false,kind=water and 'underwaterDiffuse'or nil}
   if theme=='underwater' and s.seed<.6 then
    local sc=water and water.shaft
    result.shafts[#result.shafts+1]={x=s.x,z=s.z,color=sc and sc.color or {.45,.87,1},fade=s.fade,width=sc and sc.width or 20,height=sc and sc.height or 170,alpha=sc and sc.alpha or .10,slant=sc and sc.slant or .35,spread=sc and sc.spread or 1.8}
   end
   local particles=water and water.particles
   for k=1,particles and particles.count or 4 do
    local t=(time*(particles and particles.speed or .10)+s.seed+k*.23)%1
    result.sprites[#result.sprites+1]={x=s.x+math.sin(time*.3+k)*11,y=3+t*(particles and particles.height or 52),z=s.z+math.cos(k)*12,
     size=particles and particles.size or theme=='underwater' and 2.2 or 4,color=col,alpha=math.sin(t*math.pi)*(particles and particles.alpha or .55)*s.fade,kind='mote'}
   end
  end
 end
 if theme=='haunted'then
  local night=outdoors and V.require('DayNight').windowLight()or 1
  for _,s in ipairs(nearby(data.floor,px,pz,4,80))do
   local power=(.45+.15*math.sin(time*.8+s.seed*9))*(.35+.65*night)*s.fade
   local ground=V.require('EmeraldPyre').actorHeight(def,s.x-8,s.z-16)or 0
   local l={x=s.x+math.sin(time*.2+s.seed*9)*7,y=ground+15+math.sin(time*.4+s.seed*9)*4,z=s.z,radius=-34,power=power,color={.51,.63,1},kind='wisp',size=8,alpha=.7*s.fade}
   result.lights[#result.lights+1]=l;result.sprites[#result.sprites+1]=l
  end
 end
 if p.lava then
  for _,s in ipairs(nearby(data.hot,px,pz,8,54))do
   result.lights[#result.lights+1]={x=s.x,y=12,z=s.z,radius=-85,power=(.9+.12*math.sin(time*1.4+s.seed*9))*s.fade,color={1,.34,.08}}
  end
 end
 if theme=='canopy'then
  local night=V.require('DayNight').windowLight()
  for _,w in ipairs(def.warps or{})do
   if tostring(w.destMap):find('HOUSE')or tostring(w.destMap):find('DECORATION_SHOP')then
    result.lights[#result.lights+1]={x=w.x*16+8,y=18,z=w.y*16+23,radius=-42,power=night*.85,color={1,.75,.35}}
   end
  end
 end
 result.hoennSprites=#result.sprites-start
end
function E.veil(def,canvas,vp,px,pz,time,context)
 local p,theme=E.profile(def)
 if not p or not p.mist then return canvas end
 local water=theme=='underwater'
 return V.require('HauntedFog').apply(canvas,vp,px,pz,time,{density=V.require('EmeraldPyre').profile(def)and V.require('DioramaConfig').emeraldInteriors.pyre.mist or p.mist,surge=false,pocket={0,1},clearCore=1,ribbonMix=.75,
  color=water and {.03,.16,.21}or{.16,.19,.25},light=water and {.12,.40,.46}or{.32,.38,.45}},context)
end
return E
