-- Source-authored indoor lighting. Blockers follow rendered furniture bounds,
-- never collision cells; no map state is written. Unknown rooms use old lighting.
local V=...;local R={geometry=setmetatable({},{__mode='k'}),MAX=24}
local Budget=V.require('BuildBudget')
-- Provider initialization may load many independent room modules. Yield only
-- inside the geometry queue; direct tools and runtime lookups stay synchronous.
local function provider(name)
 local module=V.require(name);Budget.check();return module
end
function R.profile(d)
 local c=provider('DioramaConfig').roomLightRig;local L=d and d.midLayout
 if not(c and c.enabled and L)then return end
 -- These six providers accept only native EM_ room identities. Avoid loading
 -- their geometry dependencies during the first FireRed indoor frame.
 local emerald=(d.id or d.name or ''):match('^EM_')
 local power=provider('EmeraldNewMauville').lighting(d);if power then return power end
 local wreck=provider('EmeraldWreckRooms').lighting(d);if wreck then return wreck end
 local home=provider('HomeLighting').profile(d);if home then return home end
 local emeraldHome=provider('EmeraldHomeLighting').profile(d);if emeraldHome then return emeraldHome end
 local tatami=provider('EmeraldTatamiLighting').profile(d);if tatami then return tatami end
 local timber=provider('EmeraldTimberLighting').profile(d);if timber then return timber end
 local residential=provider('EmeraldResidentialLighting').profile(d);if residential then return residential end
 local pyre=provider('EmeraldPyreLighting').profile(d);if pyre then return pyre end
 local contest=provider('EmeraldContestLighting').profile(d);if contest then return contest end
 local transitEntrance=emerald and provider('EmeraldTransitLighting').profile(d);if transitEntrance then return transitEntrance end
 local aquaEntry=provider('EmeraldAquaEntryLighting').profile(d);if aquaEntry then return aquaEntry end
 local specialHome=provider('EmeraldSpecialHomeLighting').profile(d);if specialHome then return specialHome end
 local finale=emerald and provider('EmeraldLeagueFinalLighting').profile(d);if finale then return finale end
 local league=provider('EmeraldLeagueLighting').profile(d);if league then return league end
 local gameClub=emerald and provider('EmeraldGameClubLighting').profile(d);if gameClub then return gameClub end
 local sootopolis=provider('EmeraldSootopolisLighting').profile(d);if sootopolis then return sootopolis end
 local mossdeep=provider('EmeraldMossdeepLighting').profile(d);if mossdeep then return mossdeep end
 local petalburg=provider('EmeraldPetalburgLighting').profile(d);if petalburg then return petalburg end
 local fortree=provider('EmeraldFortreeLighting').profile(d);if fortree then return fortree end
 local energyGym=provider('EmeraldEnergyGymLighting').profile(d);if energyGym then return energyGym end
 local rockGym=provider('EmeraldRockGymLighting').profile(d);if rockGym then return rockGym end
 local tent=emerald and provider('EmeraldTentLighting').profile(d);if tent then return tent end
 local tidal=emerald and provider('EmeraldTidalLighting').profile(d);if tidal then return tidal end
 local harbor=provider('EmeraldHarborLighting').profile(d);if harbor then return harbor end
 local station=emerald and provider('EmeraldStationLighting').profile(d);if station then return station end
 local yard=provider('EmeraldShipyardLighting').profile(d);if yard then return yard end
 local transit=provider('TransitLighting').profile(d);if transit then return transit end
 local condo=provider('CondoLighting').profile(d);if condo then return condo end
 local pyramid=provider('EmeraldPyramidLighting').profile(d);if pyramid then return pyramid end
 local hall=provider('EmeraldFrontierHallLighting').profile(d);if hall then return hall end
 local social=provider('EmeraldFrontierSocialLighting').profile(d);if social then return social end
 local tower=provider('EmeraldTowerLighting').profile(d);if tower then return tower end
 local pike=provider('EmeraldPikeLighting').profile(d);if pike then return pike end
 local palace=provider('EmeraldPalaceLighting').profile(d);if palace then return palace end
 local factory=provider('EmeraldFactoryLighting').profile(d);if factory then return factory end
 local dome=provider('EmeraldDomeLighting').profile(d);if dome then return dome end
 local arena=provider('EmeraldArenaLighting').profile(d);if arena then return arena end
 local shipPublic=provider('ShipPublicLighting').profile(d);if shipPublic then return shipPublic end
 local shipCabin=provider('ShipCabinLighting').profile(d);if shipCabin then return shipCabin end
 local cabin=provider('InteriorElevator').lighting(d);if cabin then return cabin end
 local casino=provider('InteriorCasino').lighting(d);if casino then return casino end
 local celio=provider('InteriorCelio').lighting(d);if celio then return celio end
 local tanoby=provider('TanobyChambers').lighting(d);if tanoby then return tanoby end
 local dojo=provider('FireRedDojo').lighting(d);if dojo then return dojo end
 local frCable=provider('FireRedCableRooms').lighting(d);if frCable then return frCable end
 local islandHarbor=provider('EmeraldIslandHarbors').lighting(d);if islandHarbor then return islandHarbor end
 local harbor=provider('FireRedHarbors').lighting(d);if harbor then return harbor end
 local tunnel=provider('FireRedTunnels').lighting(d);if tunnel then return tunnel end
 local gym=provider('FireRedGymRooms').lighting(d);if gym then return gym end
 local seven=provider('SevenIslandRooms').lighting(d);if seven then return seven end
 local cottage=provider('SeaCottage').lighting(d);if cottage then return cottage end
 local copycat=provider('CopycatRoom').lighting(d);if copycat then return copycat end
 local volunteer=provider('VolunteerHouse').lighting(d);if volunteer then return volunteer end
 local trashed=provider('InteriorTrashedHouse').lighting(d);if trashed then return trashed end
 local display=provider('InteriorDisplayHouses').lighting(d);if display then return display end
 local safari=provider('SafariRooms').lighting(d);if safari then return safari end
 local power=provider('PowerPlantRoom').lighting(d);if power then return power end
 local mansion=provider('MansionShell').lighting(d);if mansion then return mansion end
 local final=provider('FireRedFinalRooms').lighting(d);if final then return final end
 local league=provider('FireRedLeagueRooms').lighting(d);if league then return league end
 local lobby=provider('TrainerTowerLobby').lighting(d);if lobby then return lobby end
 local tower=provider('TrainerTowerRooms').lighting(d);if tower then return tower end
 local rocket=provider('RocketLighting').profile(d);if rocket then return rocket end
 local silph=provider('SilphLighting').profile(d);if silph then return silph end
 local gate=provider('GateLighting').profile(d);if gate then return gate end
 local doors=provider('EmeraldTrickDoors').lighting(d);if doors then return doors end
 local secret=provider('EmeraldSecretBases').lighting(d);if secret then return secret end
 local fossil=provider('EmeraldFossilTunnel').lighting(d);if fossil then return fossil end
 local aqua=provider('EmeraldAquaOperations').lighting(d);if aqua then return aqua end
 local cable=provider('EmeraldCableRooms').lighting(d);if cable then return cable end
 local roof=provider('EmeraldTrainerHillRoof').lighting(d);if roof then return roof end
 local entry=provider('EmeraldTrainerHillEntrance').lighting(d);if entry then return entry end
 local hill=provider('EmeraldTrainerHill').lighting(d);if hill then return hill end
 local truck=provider('EmeraldTruck').lighting(d);if truck then return truck end
 local mystery=provider('EmeraldMysteryHouse').lighting(d);if mystery then return mystery end
 local quiz=provider('EmeraldTrickQuiz').lighting(d);if quiz then return quiz end
 local slide=provider('EmeraldTrickSlide').lighting(d);if slide then return slide end
 local steps=provider('EmeraldTrickSteps').lighting(d);if steps then return steps end
 local maze=provider('EmeraldTrickMaze').lighting(d);if maze then return maze end
 local corridor=provider('EmeraldTrickCorridor').lighting(d);if corridor then return corridor end
 local trick=provider('EmeraldTrickHouse').lighting(d);if trick then return trick end
 local id=d.id or d.name or ''
 local function fits(p)return p and L.width==p.width and L.height==p.height and (d.renderPair or d.pair)==p.pair end
 local exact=c.rooms[id];if fits(exact)then return exact end
 -- Only measured room families inherit a plan. Anchors guard the actual
 -- healer/counter/shelf placement, not just a room name or walkable rectangle.
 if tonumber(d.mapType)~=8 or not L.midAt then return end
 for _,family in ipairs(c.families or{})do
  local p=c.rooms[family.template]
  if id:match(family.pattern)and fits(p)then
   local match=true
   for _,a in ipairs(family.anchors)do if L:midAt(a[1],a[2])~=a[3]then match=false;break end end
   if match then return p end
  end
 end
end
function R.begin(L,d)
 R.reliefStones=R.reliefStones or setmetatable({},{__mode='k'});R.reliefStones[L]={}
 R.reliefFurniture=R.reliefFurniture or setmetatable({},{__mode='k'});R.reliefFurniture[L]={}
 R.geometry[L]=R.profile(d)and{}or nil
end
local skip={secretRelief=true,fossilRock=true,fossilStone=true,a1Pipe=true,a1Rail=true,a1Stool=true,a1Bin=true,cableFloor=true,hillRoofDeck=true,hillRoofHut=true,hillEntryFloor=true,hillFloor=true,truckFloor=true,mysteryPlant=true,trickSlidePot=true,trickPlant=true,chair=true,seat=true,plant=true,bed=true,card=true,a2Pipe=true,a2Rail=true,a2Stool=true,a2Bin=true}
function R.capture(L,o,vertices,first,last,x,z)
 local list=R.geometry[L];if not list or skip[o.kind]then return end
 if V.require('EmeraldNewMauville').capture(list,o,x,z)then return end
 if V.require('EmeraldWreckRooms').capture(list,o,x,z)then return end
 if V.require('EmeraldCableRooms').capture(list,o,x,z)then return end
 if V.require('EmeraldTrainerHillEntrance').capture(list,o,x,z)then return end
 if V.require('DepartmentLightBlockers').capture(list,o,x,z)then return end
 if V.require('ResearchLightBlockers').capture(list,o,x,z)then return end
 if V.require('InteriorCelio').capture(list,o,vertices,first,last)then return end
 if V.require('SeaCottageShadows').capture(list,o,vertices,first,last)then return end
 if o.kind=='secretStone'then
  local stones=R.reliefStones and R.reliefStones[L];if stones then for i=first,last do local v=vertices[i];stones[#stones+1]={v[1],v[2],v[3]}end end
  return
 end
 local before=#list
 if V.require('EmeraldSecretDecorShadows').capture(list,o,vertices,first,last)then
  if o.style~='poster' then
   local furniture=R.reliefFurniture and R.reliefFurniture[L]
   if furniture then
    for i=first,last do local v=vertices[i];furniture[#furniture+1]={v[1],v[2],v[3]}end
    for i=before+1,#list do list[i].atlasFurniture=true end
   end
  end
  return
 end
 if V.require('EmeraldHomeLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldTatamiLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldTimberLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldResidentialLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldPyreLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldContestLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldAquaEntryLighting').capture(list,o,x,z,vertices,first,last)then return end
 if V.require('EmeraldSpecialHomeLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldLeagueFinalLighting').capture(list,o,x,z,vertices,first,last)then return end
 if V.require('EmeraldLeagueLighting').capture(list,o,x,z,vertices,first,last)then return end
 if V.require('EmeraldGameClubLighting').capture(list,o,x,z,vertices,first,last)then return end
 if V.require('EmeraldSootopolisLighting').capture(list,o,x,z,vertices,first,last,L)then return end
 if V.require('EmeraldMossdeepLighting').capture(list,o,x,z,vertices,first,last)then return end
 if V.require('EmeraldPetalburgLighting').capture(list,o,x,z,L)then return end
 if V.require('EmeraldFortreeLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldEnergyGymLighting').capture(list,o,x,z,L)then return end
 if V.require('EmeraldRockGymLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldTentLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldTidalLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldHarborLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldStationLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldShipyardLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldTransitLighting').capture(list,o,x,z,L)then return end
 if V.require('TransitLighting').capture(list,o,x,z)then return end
 if V.require('CondoLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldPyramidLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldFrontierHallLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldFrontierSocialLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldTowerLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldPikeLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldPalaceLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldFactoryLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldDomeLighting').capture(list,o,x,z)then return end
 if V.require('EmeraldArenaLighting').capture(list,o,x,z)then return end
 if V.require('ShipPublicLighting').capture(list,o,x,z)then return end
 if V.require('ShipCabinLighting').capture(list,o,x,z)then return end
 if V.require('InteriorHouseVariants').capture(list,o,x,z)then return end
 local lo={math.huge,math.huge,math.huge};local hi={-math.huge,-math.huge,-math.huge}
 for i=first,last do local v=vertices[i]
  -- Discard donor floor geometry; it must never become a shadow box.
  if v[2]>.05 then for k=1,3 do lo[k]=math.min(lo[k],v[k]);hi[k]=math.max(hi[k],v[k])end end
 end
 if hi[2]<2 or hi[1]-lo[1]<2 then return end
 local wall=o.kind:lower():find('wall',1,true)or o.kind=='a2Rim'or o.kind=='a1Rim'
 if o.kind=='fold'and(o.height or 0)<16 or o.kind=='table'or o.kind=='roundtable'or o.kind=='glass'or o.kind=='workshopCounter'then
  -- Tabletops cast, open space below them stays open.
  lo[2]=math.max(0,hi[2]-2)
 elseif wall then lo[2]=0 end
 if o.kind=='a2Rim'or o.kind=='a1Rim'then hi[2]=math.max(hi[2],V.require('DioramaConfig').roomLightRig.cutawayWallHeight)end
 if hi[3]-lo[3]<.5 then lo[3]=lo[3]-.25;hi[3]=hi[3]+.25 end
 local box={lo=lo,hi=hi,wall=wall and true or false}
 -- Merge only collinear equal-height wall runs; corners and door gaps remain.
 if wall then
  for _,b in ipairs(list)do if b.wall then
   if math.abs(b.lo[2]-lo[2])<.1 and math.abs(b.hi[2]-hi[2])<.1 then
    if math.abs(b.lo[3]-lo[3])<.1 and math.abs(b.hi[3]-hi[3])<.1 and lo[1]<=b.hi[1]+.01 and hi[1]>=b.lo[1]-.01 then
     b.lo[1]=math.min(lo[1],b.lo[1]);b.hi[1]=math.max(hi[1],b.hi[1]);return
    end
    if math.abs(b.lo[1]-lo[1])<.1 and math.abs(b.hi[1]-hi[1])<.1 and lo[3]<=b.hi[3]+.01 and hi[3]>=b.lo[3]-.01 then
     b.lo[3]=math.min(lo[3],b.lo[3]);b.hi[3]=math.max(hi[3],b.hi[3]);return
    end
   end
  end end
 end
 list[#list+1]=box
end
function R.prepare(d,px,pz)
 local p=R.profile(d);if not p then return end
 local c=V.require('DioramaConfig').roomLightRig
 local night=p.fixed and 0 or math.max(0,math.min(1,V.require('DayNight').windowLight()))
 local amb={};for k=1,3 do amb[k]=p.ambient[k]*(1-night)+(p.night or p.ambient)[k]*night end
 local lights={}
 for index,s in ipairs(p.sources)do
  local power=s.power*(1-night)+(s.nightPower or s.power)*night
  local col={};for k=1,3 do col[k]=s.color[k]*(1-night)+(s.nightColor or s.color)[k]*night end
  lights[#lights+1]={x=s.at[1],y=s.at[2],z=s.at[3],radius=-s.radius,power=power,color=col,kind='room',falloff=s.falloff or 2,
   roomRank=not p.localSelection and index or nil,roomSource=s,direction=s.direction or {0,-1,0},spread=s.spread or {8,8}}
 end
 local cast=V.require('DioramaConfig').shadows.enabled and c.shadows
 local relief=cast and V.require('EmeraldReliefShadows').prepare(d)or nil
 local stones=R.reliefStones and R.reliefStones[d.midLayout]
 local furniture=R.reliefFurniture and R.reliefFurniture[d.midLayout]
 local atlas=relief and V.require('EmeraldReliefAtlas').prepare(relief,p.sources,stones,furniture)
 local boxes={};for _,b in ipairs(R.geometry[d.midLayout]or{})do
  if not(atlas and atlas.hasFurniture and b.atlasFurniture)then boxes[#boxes+1]=b end
 end
 if relief and not atlas and stones and #stones>0 then
  V.require('EmeraldSecretDecorShadows').capture(boxes,{kind='secretDecor',style='stone'},stones,1,#stones)
 end
 if p.movingShadows then p.movingShadows(d,boxes,px,pz)end
 table.sort(boxes,function(a,b)
  if p.localSelection and px and pz then
   local function distance(b)
    local lo,hi=b.worldLow or b.lo,b.worldHigh or b.hi
    local x=math.max(lo[1]-px,0,px-hi[1]);local z=math.max(lo[3]-pz,0,pz-hi[3]);return x*x+z*z
   end
   local ad,bd=distance(a),distance(b);if ad~=bd then return ad<bd end
  end
  if a.wall~=b.wall then return a.wall end
  -- Stable tie-breaks; existing small room plans retain fixed selection.
  local av=(a.hi[1]-a.lo[1])*(a.hi[3]-a.lo[3])*a.hi[2];local bv=(b.hi[1]-b.lo[1])*(b.hi[3]-b.lo[3])*b.hi[2]
  if av~=bv then return av>bv end
  if a.lo[3]~=b.lo[3]then return a.lo[3]<b.lo[3]end;return a.lo[1]<b.lo[1]
 end)
 local state={relief=relief,reliefAtlas=atlas,boxes=boxes,count=math.min(R.MAX,#boxes),diffuseFloor=c.diffuseFloor,actorGain=c.actorGain,
  shadow=cast and 1 or 0,
  samples=V.require('DioramaConfig').settings.maxLights<=6 and 1 or c.shadowSamples}
 return amb,lights,state
end
local payload
local function buffers()
 if payload then return payload end
 payload={lows={},highs={},frames={},slopes={},dirs={},areas={},model={}}
 for _,key in ipairs{'lows','highs','frames','slopes','dirs','areas'}do
  for i=1,24 do payload[key][i]={}end
 end
 return payload
end
function R.send(shader,state,sources)
 V.require("EmeraldReliefAtlas").send(shader,state and state.shadow>0 and state.reliefAtlas or nil,sources)
 V.require("EmeraldReliefShadows").send(shader,state and state.shadow>0 and state.relief or nil)
 local c=V.require('DioramaConfig').roomLightRig
 local p=buffers();local lows,highs,frames,slopes=p.lows,p.highs,p.frames,p.slopes
 for i=1,R.MAX do
  local b=state and state.boxes[i];local lo,hi,frame,slope=lows[i],highs[i],frames[i],slopes[i]
  for k=1,3 do lo[k]=b and b.lo[k]or 0;hi[k]=b and b.hi[k]or 0 end
  lo[4]=b and(b.wall and 1 or c.shadowStrength)or 0
  for k=1,4 do frame[k]=b and b.frame and b.frame[k]or 0 end
  for k=1,2 do slope[k]=b and b.slope and b.slope[k]or 0 end
 end
 local U=V.require('UniformState')
 if U.has(shader,'roomBlockCount')then
  U.send(shader,'roomBlockCount',state and state.count or 0)
  U.send(shader,'roomBlockLow',unpack(lows));U.send(shader,'roomBlockHigh',unpack(highs));U.send(shader,'roomBlockFrame',unpack(frames));U.send(shader,'roomBlockSlope',unpack(slopes))
 end
 p.model[1],p.model[2],p.model[3],p.model[4]=c.diffuseFloor,c.actorGain,state and state.shadow or 0,state and state.samples or 1
 if U.has(shader,'roomLightModel')then U.send(shader,'roomLightModel',p.model)end
 if U.has(shader,'roomBalancedArea')then V.require('UniformState').send(shader,'roomBalancedArea',c.balancedAreaShadows and 1 or 0)end
 local dirs,areas=p.dirs,p.areas
 for i=1,24 do local l=sources and sources[i];local r=l and l.roomSource
  local d,a=dirs[i],areas[i]
  d[1],d[2],d[3],d[4]=r and l.direction[1]or 0,r and l.direction[2]or -1,r and l.direction[3]or 0,r and(r.cone or 0)or -2
  a[1],a[2]=r and l.spread[1]or 0,r and l.spread[2]or 0
 end
 if U.has(shader,'roomSourceDirection')then U.send(shader,'roomSourceDirection',unpack(dirs))end
 if U.has(shader,'roomSourceArea')then U.send(shader,'roomSourceArea',unpack(areas))end
end
function R.release()R.reliefStones=nil;R.reliefFurniture=nil;V.require("EmeraldReliefShadows").release();R.geometry=setmetatable({},{__mode='k'})end
return R
