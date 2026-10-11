-- Solar/lunar scene lighting and bounded, world-anchored paper effects.
local V=...
local Budget=V.require('BuildBudget')
local A={cache=setmetatable({},{__mode="k"})}
local function hash(x,z,s)return ((x*104729+z*13007+s*7919)*48271%2147483647)/2147483647 end
local function candidates(def)
 if A.cache[def]then return A.cache[def]end
 local L=def.midLayout;local cells,edges={},{}
 local salt=0;for c in tostring(def.id):gmatch('.')do salt=(salt*31+c:byte())%65521 end
 local function open(x,z)
  if x<0 or z<0 or x>=L.width or z>=L.height then return false end
  local c=L:cellAt(x,z)
  if c and V.require('PondLights').isFireRed(def) and V.data('Shapes').water(c)
   and not V.require('PondLights').freshWater(def,x,z)then return false end
  return c and not V.data('Shapes').solid(c) and c.mid~=0 and c.mid~=8
 end
 for z=2,L.height-2 do for x=1,L.width-2 do Budget.tick();if open(x,z)then
  local h=hash(x,z,salt)
  if h<.065 then cells[#cells+1]={x=x*16+8,z=z*16+8,seed=h*1000}end
  if h<.14 and (not open(x-1,z)or not open(x+1,z)or not open(x,z-1))then
   local nearWarp=false
   for _,w in ipairs(def.warps or{})do if math.abs(x-w.x)+math.abs(z-w.y)<3 then nearWarp=true;break end end
   if not nearWarp then edges[#edges+1]={x=x*16+3,z=z*16+5,seed=h*1000}end
  end
 end end end
 local shafts={}
 for _,p in ipairs(edges)do
  Budget.tick()
  local free=true;for _,q in ipairs(shafts)do if (p.x-q.x)^2+(p.z-q.z)^2<72^2 then free=false;break end end
  if free then shafts[#shafts+1]=p end
 end
 -- Forest clearings: open cells surrounded by canopy, spaced like the
 -- reference sun columns (never on warps). Deterministic per map.
 local glades={}
 local forest=V.require('DioramaConfig').forest
 local spacing=forest.reach/math.sqrt(math.max(1,forest.count))
 for _,p in ipairs(cells)do
  Budget.tick()
  local gx,gz=math.floor(p.x/16),math.floor(p.z/16)
  local free=true;for _,q in ipairs(glades)do if (p.x-q.x)^2+(p.z-q.z)^2<spacing^2 then free=false;break end end
  if free then glades[#glades+1]={x=p.x,z=p.z,seed=p.seed}end
 end
 -- FireRed consumes complete components and rejects map-edge water. Cutting
 -- the search short leaves sea fragments that masquerade as small ponds.
 -- Pond rims: the reference night clips show small warm glints spaced one
 -- per tile along the far (north) bank of small ponds, not along the sea.
 local banks={}
 local pc=V.require('DioramaConfig').pondLights
 if pc and pc.enabled then
  local Shapes=V.data('Shapes');local seen={}
  local function wet(x,z)if x<0 or z<0 or x>=L.width or z>=L.height then return false end;local c=L:cellAt(x,z);return c and Shapes.water(c)end
  for z=0,L.height-1 do for x=0,L.width-1 do Budget.tick();local k=z*L.width+x
   if not seen[k] and wet(x,z)then
    local queue,n={k},1;seen[k]=true
    local bounded=V.require('PondLights').isFireRed(def);local border=false;local fresh=true
    while queue[n] and (bounded or #queue<=pc.maxCells) do
     Budget.tick()
     local i=queue[n];n=n+1;local xx,zz=i%L.width,math.floor(i/L.width)
     if bounded then fresh=fresh and V.require('PondLights').freshWater(def,xx,zz)end
     border=border or xx==0 or zz==0 or xx==L.width-1 or zz==L.height-1
     for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}})do local nx,nz=xx+d[1],zz+d[2];local j=nz*L.width+nx
      if wet(nx,nz)and not seen[j]then seen[j]=true;queue[#queue+1]=j end end
    end
    if #queue<=pc.maxCells and not(bounded and (border or not fresh))then
     for _,i in ipairs(queue)do Budget.tick();local xx,zz=i%L.width,math.floor(i/L.width)
      if not wet(xx,zz-1)then banks[#banks+1]={x=xx*16+8,z=zz*16+1.5,seed=(xx*7+zz*13)%17}end end
    end
   end
  end end
 end
 A.cache[def]={cells=cells,edges=edges,shafts=shafts,glades=glades,banks=banks};return A.cache[def]
end
-- Read-only sites for native water classification/QA and map tools.
function A.pondBanks(def)return candidates(def).banks end
-- Sparse ceiling openings: open floor spots (whole 3x3 walkable), far apart,
-- at most sc.max per map; deterministic per map.
A.skyCache=setmetatable({},{__mode='k'})
function A.skylights(def,sc)
 local L=def.midLayout;if A.skyCache[L]then return A.skyCache[L]end
 local S=V.data('Shapes');local out={};local PE=V.require('PlaceEffects')
 if A.isDarkCave(def)then A.skyCache[L]=out;return out end
 local id=def.id or def.name or ''
 for _,pat in ipairs(sc.darkMaps or {})do if id:match(pat)then A.skyCache[L]=out;return out end end
 local salt=0;for ch in tostring(def.id):gmatch('.')do salt=(salt*31+ch:byte())%65521 end
 local function open(x,z)if x<0 or z<0 or x>=L.width or z>=L.height then return false end
  local c=L:cellAt(x,z);return c and not S.solid(c) and not S.water(c) and c.mid~=0 and PE.isInside(def,x,z) end
 -- how many: one opening per sc.perCells floor cells, spread over the whole cave
 local floorCells=PE.floorCount(def)
 local target=math.max(sc.min,math.min(sc.max,math.floor(floorCells/sc.perCells+.5)))
 local cand={}
 for z=1,L.height-2 do for x=1,L.width-2 do
  Budget.tick()
  local ok=open(x,z) and open(x+1,z) and open(x-1,z) and open(x,z+1) and open(x,z-1)
  if ok then for _,w in ipairs(def.warps or {})do if w.x and w.y and math.abs(w.x-x)<=2 and math.abs(w.y-z)<=2 then ok=false end end end
  if ok then cand[#cand+1]={x=x*16+8,z=z*16+8,h=hash(x,z,salt)} end
 end end
 table.sort(cand,function(a,b)return a.h<b.h end)
 local tunnel=V.require('FireRedDiglettCave').skylights(def,cand,sc)
 if tunnel then out=tunnel;target=#out end
 -- dart-throwing with a shrinking radius: evenly spread but still irregular
 local spacing=sc.spacing
 while #out<target and spacing>=48 do
  for _,p in ipairs(cand)do
   Budget.tick()
   if #out>=target then break end
   local free=true;for _,q in ipairs(out)do if (p.x-q.x)^2+(p.z-q.z)^2<spacing^2 then free=false;break end end
   if free then out[#out+1]=p end
  end
  spacing=spacing*.8
 end
 for i,p in ipairs(out)do p.size=.8+.45*hash(i,salt,3) end
 if V.require('DioramaConfig').places.debug then for _,p in ipairs(out)do print('SKY',def.id,math.floor(p.x/16),math.floor(p.z/16))end end
 A.skyCache[L]=out;return out
end
function A.isDarkCave(def)
 if tonumber(def.cave)==V.require('DioramaConfig').caves.nativeDarkFlag then return true end
 local id=def.id or def.name or ''
 for _,pat in ipairs(V.require('DioramaConfig').caves.darkMaps or {})do if id:match(pat)then return true end end
 return false
end
local function closest(items,x,z,limit,reach)
 local out={};reach=reach or 170
 for _,p in ipairs(items)do local d=(p.x-x)^2+(p.z-z)^2;if d<reach^2 then out[#out+1]={p=p,d=d}end end
 table.sort(out,function(a,b)return a.d<b.d end)
 for i=#out,limit+1,-1 do out[i]=nil end
 return out
end
function A.flashActive()
 local Space=require('src.core.game3.scripting.space')
 if not Space or not Space.store then return false end
 local FieldMoves=require('src.core.game3.field_moves')
 return require('src.core.game3.scripting.flags').getFlag(Space.store,nil,FieldMoves.SYS_FLAGS.FLASH_ACTIVE)==true
end
function A.prepare(def,px,pz,time,outdoors)
 local cave=tonumber(def.mapType)==4 and not V.require('TanobyChambers').profile(def)and not V.require('EmeraldWreckRooms').profile(def)and not V.require('EmeraldNewMauville').profile(def)
 local caveCfg=V.require("DioramaConfig").caves
 local tunedCave=cave and not outdoors and caveCfg.enabled
 local DN=V.require('DayNight');local tint=DN.tint(outdoors)
 local az,el,moon=DN.bodyAt(DN.time());az,el=math.rad(az),math.rad(el)
 local direction={math.cos(az)*math.cos(el),math.max(.08,math.sin(el)),math.sin(az)*math.cos(el)}
 local roomAmbient,roomLights,roomRig
 if not outdoors and not cave then roomAmbient,roomLights,roomRig=V.require('RoomLighting').prepare(def,px,pz)end
 local ambient=outdoors and {tint[1]*.76,tint[2]*.76,tint[3]*.76}
   or cave and (tunedCave and caveCfg.ambient or {.20,.24,.32})or roomAmbient
 -- Warm daylight grades the native palette without replacing its colours.
 -- Fade this correction with solar elevation so moonlight and twilight keep
 -- their own palette, and local window/firefly lights retain their hue.
 local solarGrade=outdoors and not moon and math.min(1,math.max(0,math.sin(el))/.7)or 0
 if outdoors then
  ambient={tint[1]*(.76-.04*solarGrade),tint[2]*(.76-.06*solarGrade),tint[3]*(.76-.13*solarGrade)}
 end
 if outdoors then
  local night=DN.windowLight()
  local target=V.require('DioramaConfig').lighting.nightAmbient
  for i=1,3 do ambient[i]=ambient[i]*(1-night)+target[i]*night end
 end
 local solar=V.require('Daylight').prepare(outdoors,DN.time())
 if solar then
  local w=solar.weight
  for i=1,3 do
   ambient[i]=ambient[i]*(1-w)+solar.ambient[i]*w
   direction[i]=direction[i]*(1-w)+solar.direction[i]*w
   solar.sunColor[i]=1+(solar.sunColor[i]-1)*w
  end
 end
 local sun=outdoors and (moon and .13 or .36)*math.max(0,math.sin(el))or 0
 if solar then sun=sun*(1-solar.weight)+solar.sun*solar.weight end
 if outdoors and V.require('DioramaConfig').cycle.enabled then
  local rig=V.require('TimeOfDay').sample(DN.time())
  ambient,direction,sun=rig.ambient,rig.direction,rig.sun
  -- Exact plateau keeps the approved night shader and shadow path.
  solar=rig
  moon=rig.night>.5
 end
 local forestCfg=V.require('DioramaConfig').forest
 local forestMap=outdoors and forestCfg and forestCfg.enabled and forestCfg.maps[def.id or def.name]
 if forestMap then
  -- Dense canopy: the reference forest is markedly darker than open routes.
  local k=forestCfg.ambientScale
  -- Golden hour under the canopy is dimmer still (reference clip ~.8x).
  local w=math.max(0,math.min(1,((solar and solar.sunColor and 1-solar.sunColor[3]) or 0)*1.6))
  local evening=V.require('DioramaConfig').daylight.goldenHour
  local dimAmount=forestCfg.warmDim or 0
  if evening and evening.enabled then dimAmount=dimAmount+((evening.forestDim or dimAmount)-dimAmount)*math.max(solar and solar.evening or 0,solar and solar.dusk or 0)end
  local dim=1-dimAmount*w*(1-((solar and solar.night) or 0))
  ambient={ambient[1]*k[1]*dim,ambient[2]*k[2]*dim,ambient[3]*k[3]*dim};sun=sun*forestCfg.sunScale*dim
 end
 local result={roomRig=roomRig,solar=solar,ambient=ambient,direction=direction,sun=sun,cave=cave,lights={},sprites={},shafts={},moon=moon,fireflies=0,crystals=0,flash=cave and A.flashActive()or false,time=time}
 local data=candidates(def)
 if cave then
  -- Ceiling gaps: a few sparse openings per cave let a soft beam fall onto
  -- an open floor spot (daylight by day, moonlight at night).
  local sc=caveCfg.skylights
  local theme=V.require('PlaceEffects').theme(def)
  local skyScale=theme and theme.skylightScale or 1
  if sc and sc.enabled and tunedCave then
   for _,c in ipairs(closest(A.skylights(def,sc),px,pz,sc.visible,sc.reach))do
    local p=c.p;local fade=math.min(1,math.max(0,(sc.reach-math.sqrt(c.d))/70))
    local DNt=V.require('DayNight');local night=DNt.windowLight()
    local col={};for i=1,3 do col[i]=sc.dayColor[i]+(sc.nightColor[i]-sc.dayColor[i])*night end
    local k=fade*(1-(1-sc.nightStrength)*night)*skyScale
    local sz=p.size or 1
    result.shafts[#result.shafts+1]={x=p.x,z=p.z,color=col,fade=k,width=sc.width*sz,height=sc.height,alpha=sc.alpha,slant=sc.slant,spread=sc.spread}
    result.lights[#result.lights+1]={x=p.x,y=8,z=p.z,radius=-sc.poolRadius*sz,power=sc.poolPower*k,color=col,falloff=2}
    -- dust drifting in the beam
    for m=1,sc.motes do
     local ph=time*.35+m*1.7+p.x*.01
     local y=4+((ph*9)%sc.height*.6)
     local fadeM=math.sin(math.pi*((ph*9)%(sc.height*.6))/(sc.height*.6))
     result.sprites[#result.sprites+1]={x=p.x+math.sin(ph*1.3+m)*sc.width*sz*.3-y*sc.slant,y=y,z=p.z+math.cos(ph+m)*5,
      size=4,color=col,alpha=.8*fadeM*k,kind='mote'}
    end
   end
  end
  local flicker=1
  if tunedCave and caveCfg.flickerEnabled then
   local t=time*caveCfg.flickerSpeed
   flicker=1+caveCfg.flickerAmplitude*(math.sin(t)+.5*math.sin(t*1.73))/1.5
  end
  -- Observe native FLASH state only; never grant an HM, badge, or flag.
  -- FireRed has no lantern: without FLASH the player carries no light at all.
  if result.flash or not (tunedCave and caveCfg.noLamp) then
  result.lights[#result.lights+1]={x=px+8,y=tunedCave and caveCfg.lightHeight or 13,z=pz+12,
   radius=tunedCave and -(result.flash and caveCfg.flashRadius or caveCfg.playerRadius)or(result.flash and -110 or -34),
   power=tunedCave and (result.flash and caveCfg.flashPower or caveCfg.playerPower)*flicker or(result.flash and .72 or .20),
   color=tunedCave and caveCfg.lightColor or {1,.88,.65},falloff=tunedCave and caveCfg.falloff or 2,kind='player'}
  end
 elseif not outdoors then
  result.lights=roomLights
 end
 if not outdoors and V.require('HauntedFog').active(def)then V.require('HauntedFog').lights(result,px,pz,time,A.flashActive() and A.flashMap==(def.id or def.name),def)end
 -- Outdoor FLASH (night): a cool pool around the player while on the map
 -- where it was used; leaving the map clears the native flag again.
 if A.flashMap then
  local here=def.id or def.name
  if here~=A.flashMap then
   pcall(function()
    local Space=require('src.core.game3.scripting.space');local FM=require('src.core.game3.field_moves')
    if Space.store then require('src.core.game3.scripting.flags').setFlag(Space.store,nil,FM.SYS_FLAGS.FLASH_ACTIVE,false)end
   end)
   A.flashMap=nil
  elseif not outdoors and V.require('HauntedFog').active(def) and A.flashActive() then
   -- handled by HauntedFog.lights (lamp, fog retreat)
  elseif outdoors and A.flashActive() then
   local fc=V.require('DioramaConfig').flash
   result.lights[#result.lights+1]={x=px+8,y=fc.height,z=pz+10,radius=-fc.radius,power=fc.power,color=fc.color,falloff=fc.falloff or 2,kind='flash'}
  else A.flashMap=nil end
 end
 if forestMap then
  -- Tall soft light columns fall onto clearings, tinted by time of day:
  -- warm white by day, orange at dawn/golden hour, cool blue at night.
  local rig=solar or {}
  local warm=math.max(0,math.min(1,((rig.sunColor and 1-rig.sunColor[3]) or 0)*1.6))
  local night=rig.night or (moon and 1 or 0)
  local c1,c2,c3=forestCfg.dayColor,forestCfg.warmColor,forestCfg.nightColor
  local col={}
  for i=1,3 do col[i]=(c1[i]*(1-warm)+c2[i]*warm)*(1-night)+c3[i]*night end
  local strength=forestCfg.strength*((1-night)+forestCfg.nightStrength*night)
  -- Golden hour: the reference shows a narrow, near-vertical, saturated orange column.
  local boost=1+(forestCfg.warmBoost or 0)*warm*(1-night)
  local lerp=function(a,b)return a and b and a+(b-a)*warm or a end
  local slant,spread=lerp(forestCfg.slant,forestCfg.warmSlant),lerp(forestCfg.spread,forestCfg.warmSpread)
  -- Density is chosen once for the whole map. Never swap the nearest two
  -- openings under a walking player; only fade fixed sites at the far edge.
  for _,c in ipairs(closest(data.glades,px,pz,#data.glades,forestCfg.reach))do
   local p=c.p;local fade=math.min(1,math.max(0,(forestCfg.reach-math.sqrt(c.d))/60))*strength
   if fade>0 then
    result.shafts[#result.shafts+1]={x=p.x,z=p.z,color=col,fade=fade,width=forestCfg.width,height=forestCfg.height,alpha=forestCfg.alpha*boost,slant=slant,spread=spread,kind='forestSun'}
    result.lights[#result.lights+1]={x=p.x,y=10,z=p.z,radius=-forestCfg.poolRadius,power=forestCfg.poolPower*fade*(1-.45*warm),color=col,kind='forestSun'}
   end
  end
 end
 local forest=V.require('DioramaConfig').forest
 local persistent=outdoors and forest.enabled and forest.persistent and forest.persistent.maps[def.id or def.name]and forest.persistent
 local daylight=persistent and persistent.fireflies and 1 or (outdoors and DN.windowLight()or 1)
 local fireflyWeather=1
 if outdoors and not(persistent and persistent.fireflies)then
  local W=V.require('Weather');local map={id=def.id or def.name,def=def}
  local mood=V.require('WeatherMood').sample(map)
  local weather=W.mode(map)
  local cloud=mood and mood.cloud or ((weather=='clear'or weather=='heat')and 0 or 1)
  local cloudDaylight=V.require('CloudDaylight');local cloudMode=cloudDaylight.setting:get()
  if cloudMode~='original'then cloud=math.max(cloud,cloudDaylight.cover(W.clock,weather,cloudMode,cloud))end
  fireflyWeather=V.require('Scenery').fireflyVisibility(solar and solar.night or daylight,cloud,W.visual.snow or 0)
 end
 local mode=V.mod.options:get('gen3Fireflies')or'all'
 local drift=outdoors and not V.require('DioramaConfig').scenery.preserveNightMaps[def.id or def.name] and V.require('DioramaConfig').fireflies.driftEnabled
 local count=drift and V.require('DioramaConfig').fireflies.count or (outdoors and 9 or 4)
 count=math.min(count,V.require('DioramaConfig').settings.fireflyBudget)
 if V.require('DioramaConfig').fireflies.enabled~=false and mode~='off' and (outdoors or (mode=='all' and cave))then
  local selected
  if outdoors then
   -- Stable population for the whole map, not a nearest-N set that swaps
   -- glowing sources whenever the player crosses a selection boundary.
   selected={};local n=math.min(count,#data.cells)
   for i=1,n do selected[i]={p=data.cells[math.floor((i-.5)*#data.cells/n)+1]}end
  else selected=closest(data.cells,px,pz,count)end
  for _,c in ipairs(selected)do
   local p=c.p;local pulse=.35+.65*(.5+.5*math.sin(time*1.6+p.seed))^2
   local l={x=p.x+math.sin(time*.43+p.seed)*5,y=7+math.sin(time*.7+p.seed)*3,
    z=p.z+math.cos(time*.37+p.seed)*4,radius=-22,power=.34*pulse*daylight,
    color={.71,1,.26},kind='firefly',size=3.8,alpha=pulse*daylight}
   if drift then l=V.require('Scenery').firefly(p,time,daylight)end
   local bc=V.require('DioramaConfig').fireflies.bright
   if l.bright and bc then l.radius=-bc.radius;l.power=l.power*bc.power;l.y=bc.height+(l.y-V.require('DioramaConfig').fireflies.height);l.color=bc.color or l.color;l.size=l.size*(bc.size or 1) end
   if tunedCave then l.power=l.power*caveCfg.fireflyStrength;l.alpha=l.alpha*math.sqrt(caveCfg.fireflyStrength)end
   l.alpha=l.alpha*fireflyWeather;l.power=l.power*fireflyWeather
   if l.alpha>0 and l.power>0 then
    result.lights[#result.lights+1]=l;result.sprites[#result.sprites+1]=l;result.fireflies=result.fireflies+1
   end
  end
 end
 local pc=V.require('DioramaConfig').pondLights
 local lamp=outdoors and pc and pc.enabled and DN.windowLight() or 0
 local townPond=outdoors and pc and pc.enabled and V.require('PondLights').apply(def,result,px,pz,time,lamp)
 if lamp>0 and not townPond then
  for _,c in ipairs(closest(data.banks or {},px,pz,pc.count,pc.reach))do
   local p=c.p;local flick=1-pc.flicker*(.5+.5*math.sin(time*1.1+p.seed))
   local l={x=p.x,y=1.2,z=p.z,radius=-pc.radius,power=pc.power*lamp*flick,color=pc.color,kind='pond',size=pc.size,stretch=pc.stretch,squash=pc.squash,alpha=lamp*flick}
   result.lights[#result.lights+1]=l;result.sprites[#result.sprites+1]=l
  end
 end
 V.require('EmeraldCityLamps').lights(def,result,px,pz,outdoors)
 V.require('PlaceEffects').apply(def,result,px,pz,time,data,outdoors)
 V.require('CeladonCrystal').apply(def,result,time,outdoors)
 -- Only true dark caves (FireRed needs FLASH there) stay pitch dark. Every
 -- other cave keeps a readable base light; islands add atmosphere on top.
 if tunedCave then
  local dark=A.isDarkCave(def)
  result.darkCave=dark
  if not dark then local f,g=caveCfg.litFloor,caveCfg.litGain;local b=result.ambient
   -- new table: the config table must never be mutated per frame
   result.ambient={b[1]*g+f[1],b[2]*g+f[2],b[3]*g+f[3]}
  end
 end
 V.require('EmeraldPlaces').apply(def,result,px,pz,time,outdoors)
 V.require('EmeraldTerraCave').light(def,result,time)
 V.require('EmeraldCaveTerraces').lighting(def,result)
 V.require('FireRedTerracedCaves').lighting(def,result)
 V.require('FireRedDiglettCave').lighting(def,result)
 V.require('FireRedEmberSpa').light(def,result)
 V.require('EmeraldNavelSanctums').light(def,result)
 V.require('EmeraldNavelPassages').light(def,result)
 V.require('EmeraldMirageTower').light(def,result)
 V.require('EmeraldFieryPath').light(def,result)
 V.require('EmeraldRusturf').light(def,result)
 V.require('EmeraldMagmaHideout').light(def,result,time)
 V.require('EmeraldSeafloorCurrents').light(def,result)
 V.require('FireRedDepartmentRoof').light(def,result)
 V.require('EmeraldTrainerHillRoof').light(def,result)
 V.require('EmeraldFossilTunnel').light(def,result)
 V.require('EmeraldSecretBases').light(def,result)
 if V.require('DioramaConfig').places.debug then print('PLACEDBG',def.id,#result.sprites,(V.require('PlaceEffects').theme(def))~=nil) end
 return result
end
local mesh,texture,shader
-- Reuse bounded upload rows; rebuilding several hundred Lua tables every
-- frame makes the collector compete with walking and battle presentation.
local vertices={}
local corners={{-1,1,0,0},{1,1,1,0},{1,-1,1,1},{-1,1,0,0},{1,-1,1,1},{-1,-1,0,1}}
local spriteCells={crystalGlow=0,ash=1,glitter=2,crystal=3,spark=4,zap=2}
local haloScales={crystalGlow=1.6,crystal=3.2,glitter=2.6,spark=3.0,zap=3.5,wisp=0,mote=0}
local function vertex(i,x,y,z,u,v,r,g,b,a)
 local row=vertices[i]
 if not row then row={};vertices[i]=row end
 row[1],row[2],row[3],row[4],row[5]=x,y,z,u,v
 row[6],row[7],row[8],row[9]=r,g,b,a
end
-- Shared resources belong to Atmosphere, not a cancelable map job.
-- Warm under the map-load budget; draws remain valid for synchronous tools.
function A.prepareResources()
 if not texture then
  -- Sprite atlas, 5 cells of 32px: 0 soft glow, 1 ash flake, 2 sparkle cross,
  -- 3 crystal shard, 4 ember. Pixel cells are drawn as 2x2 art pixels.
  local data=love.image.newImageData(160,32)
  for y=0,31 do for x=0,31 do
   local dx,dy=(x-15.5)/15.5,(y-15.5)/15.5
   local d=dx*dx+dy*dy;local alpha=math.exp(-d*7)*.43+(d<.015 and .75 or 0)
   data:setPixel(x,y,1,1,.8,math.min(1,alpha))
  end end
  local function px(cell,x,y,v,a)for yy=0,1 do for xx=0,1 do data:setPixel(cell*32+x*2+xx,y*2+yy,v,v,v,a or 1)end end end
  local function art(cell,rows)for y,row in ipairs(rows)do for x=1,#row do local c=row:sub(x,x)
   if c=='#' then px(cell,x-1,y-1,1)elseif c=='+' then px(cell,x-1,y-1,.78)elseif c=='-' then px(cell,x-1,y-1,.55)elseif c=='.' then px(cell,x-1,y-1,1,.35)end end end end
  art(1,{'','','','','','      -+-','     -++#-','     +###+','      +##-','       --'})
  art(2,{'','','','       .','       #','       #','    .##+##.','       #','       #','       .'})
  art(3,{'','      #','     #+#','     #+-#','    #++--#','    #+---#','    #+---#','    #+---#','    #+---#','    #+---#','    #+---#','    #+---#','     #+-#','      ##'})
  art(4,{'','','','','','       .','      .#.','     .###.','      .#.','       .'})
  local ok,image=pcall(love.graphics.newImage,data);data:release()
  if not ok then error(image,0)end
  texture=image;texture:setFilter('nearest','nearest')
 end
 if not shader then shader=V.require('ShaderCompiler').newShader([[uniform mat4 vp;vec4 position(mat4 t,vec4 p){return vp*p;}]])end
 if not mesh then
  mesh=love.graphics.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'VertexColor','float',4}},512*6,'triangles','stream')
  mesh:setTexture(texture)
 end
end
function A.prepareMap(def)
 Budget.phase('atmosphere sites');Budget.check()
 candidates(def);Budget.check()
 local C=V.require('DioramaConfig');local P=V.require('PlaceEffects')
 local outdoors=V.data('Shapes').outdoors(def)
 local cave=tonumber(def.mapType)==4 and not V.require('TanobyChambers').profile(def)and not V.require('EmeraldWreckRooms').profile(def)and not V.require('EmeraldNewMauville').profile(def)
 if cave and not outdoors and C.caves.enabled and C.caves.skylights and C.caves.skylights.enabled then
  A.skylights(def,C.caves.skylights);Budget.check()
 end
 local theme=P.theme(def)
 if theme and not V.require('TanobyChambers').profile(def)then
  if theme.glitter or theme.motes or theme.crystals then P.interior(def);Budget.check()end
  if theme.crystals then
   P.crystalSites(def,theme.crystals);Budget.check()
   Budget.phase('crystal mesh');P.prepareMesh(def,theme.crystals);Budget.check()
  end
  if theme.skylights and not(not outdoors and V.require('MansionShell').profile(def))then A.skylights(def,theme.skylights);Budget.check()end
 end
 Budget.phase('atmosphere resources')
 A.prepareResources();Budget.check()
 if V.require('HauntedFog').active(def)then V.require('HauntedWisps').prepare();Budget.check()end
 if theme and theme.crystals then P.prepareShader();Budget.check()end
end
function A.draw(state,vp)
 V.require('CaveShafts').draw(state.shafts,vp,state.time)
 V.require('PlaceEffects').draw(vp,state.time)
 if #state.sprites==0 then return end
 A.prepareResources()
 local uy,uz=V.require('Camera').cardUp();local count=0
 for n,p in ipairs(state.sprites)do if n>512 then break end
  local cell=spriteCells[p.kind]or 0;local u0,u1=cell/5,(cell+1)/5
  if p.kind~='crystalGlow' then for _,c in ipairs(corners)do
   count=count+1
   vertex(count,p.x+c[1]*p.size*.5*(p.stretch or 1),p.y+c[2]*p.size*uy*(p.squash or 1),p.z+c[2]*p.size*uz*(p.squash or 1),c[3]==0 and u0 or u1,c[4],p.color[1],p.color[2],p.color[3],p.alpha or 1)
  end end
 end
 local nCore=count
 -- Emissive halo pass: keep the existing order and 512-quad budget.
 for _,p in ipairs(state.sprites)do local k=haloScales[p.kind]
  if k and k>0 and count<512*6-6 then
   local sz=p.size*k;local a=(p.alpha or 1)*(p.haloAlpha or .55)
   for _,c in ipairs(corners)do
    count=count+1
    vertex(count,p.x+c[1]*sz*.5,p.y+c[2]*sz*.5*uy,p.z+c[2]*sz*.5*uz,c[3]*.2,c[4],p.color[1],p.color[2],p.color[3],a)
   end
  end
 end
 -- Preserve the existing all-halo blend behavior as well as mixed passes.
 if nCore==0 then nCore=count end
 mesh:setVertices(vertices,1,count)
 love.graphics.push('all');love.graphics.setShader(shader);shader:send('vp','row',vp)
 love.graphics.setDepthMode(state.depthTest==false and 'always' or 'lequal',false);love.graphics.setColor(1,1,1,1)
 if count>nCore then love.graphics.setBlendMode('add');mesh:setDrawRange(nCore+1,count-nCore);love.graphics.draw(mesh);love.graphics.setBlendMode('alpha') end
 mesh:setDrawRange(1,nCore);love.graphics.draw(mesh)
 love.graphics.pop()
end
function A.release()
 V.require('PondLights').release()
 V.require('CaveShafts').release()
 V.require('PlaceEffects').release()
 V.require('RoomLighting').release()
 V.require('HauntedFog').release()
 for _,o in ipairs({mesh or false,texture or false,shader or false})do if o then o:release()end end
 mesh,texture,shader=nil,nil,nil;vertices={};A.cache=setmetatable({},{__mode='k'})
end
return A
