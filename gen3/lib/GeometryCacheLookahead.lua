-- Predict destination scenes (including their baked connection offsets) from
-- existing map metadata only. Never
-- load native maps, change the active tileset, or create GPU objects here.
local V=...
local L={targets={},pendingCatalog=false}
local lastIndex,catalog,lastMap,lastTime,active
local builder,deadline,work
local function clock()return (V.clock or love.timer.getTime)()end
local function checkpoint()
 work=work+1
 -- The work bound also makes progress predictable with a frozen QA clock.
 if work>=128 or(work%16==0 and clock()>=deadline)then coroutine.yield()end
end
local function buildCatalog(idx)
 local result={}
 for key,scene in pairs(idx.scenes)do
  if type(key)=='string'and #key==64 and key:match('^[0-9a-f]+$')and idx.entries[key]
   and type(scene)=='table'and type(scene.map)=='string'then
   local views={}
   if scene.ox==0 and scene.oz==0 then views[scene.map]=true end
   if type(scene.views)=='table'then for map,present in pairs(scene.views)do
    if type(map)=='string'and present==true then views[map]=true end
    checkpoint()
   end end
   for map in pairs(views)do
    local list=result[map]or{};result[map]=list
    list[#list+1]={key=key,scene=scene,primary=scene.map==map and scene.ox==0 and scene.oz==0}
    checkpoint()
   end
  end
  checkpoint()
 end
 for _,list in pairs(result)do
  table.sort(list,function(a,b)
   if a.primary~=b.primary then return a.primary end
   return a.key<b.key
  end)
  checkpoint()
 end
 return result
end
function L.update(game,id,def,backgroundAllowed)
 V.require('NativeMapLookahead').update(game,id,def)
 local C=V.require('GeometryCache');local P=V.require('GeometryPrefetch')
 -- Mobile retires the old GPU scene at a warp, but can retain one bounded
 -- CPU payload for the nearest destination across that retirement.
 local mobile=V.require('MobileRenderBudget').active()
 local targetLimit=mobile and 1 or 4
 local enabled=V.require('DioramaConfig').renderCache.prefetch~=false
 local idx=C.index
 if not enabled or C.enabled==false or C.record or type(idx)~='table'or type(idx.scenes)~='table'then
  if active then P.release();V.require('GeometryGpuWarm').release();active=false end
  L.targets={};L.pendingCatalog=false
  builder,lastIndex,catalog,lastMap,lastTime=nil,nil,nil,nil,nil
  return
 end
 active=true
 if idx~=lastIndex then
  -- No stale or partial target list may reach CPU/GPU prefetch while the
  -- new index is being grouped. Rendering can use its normal cache path.
  L.targets={};P.want(L.targets)
  if lastIndex then V.require('GeometryGpuWarm').release()end
  lastIndex=idx;catalog=nil;lastMap,lastTime=nil,nil
  builder=coroutine.create(function()return buildCatalog(idx)end)
  L.pendingCatalog=true
 end
 if builder then
  work=0;deadline=clock()+.0005
  local ok,result=coroutine.resume(builder);assert(ok,result)
  if coroutine.status(builder)~='dead'then return end
  catalog=result;builder=nil;L.pendingCatalog=false
 end
 local t=clock()
 if lastMap==id and lastTime and t-lastTime<.25 then P.pump(backgroundAllowed);return end
 lastMap,lastTime=id,t
 local player=V.require('WorldAdapter').Player
 local x,z=(player.px or 0)/16,(player.py or 0)/16
 local destinations={}
 local function add(map,score)
  if map~=id and catalog[map]then destinations[map]=math.min(destinations[map]or math.huge,score)end
 end
 for _,warp in ipairs(def.warps or{})do
  add(warp.destMap or warp.toMap or warp.map or warp.target,math.abs(x-(tonumber(warp.x)or x))+math.abs(z-(tonumber(warp.y)or z)))
 end
 local connections=require('src.core.game3.connections')
 local w,h=connections.sizeOf(def)
 for _,conn in ipairs(connections.each(def))do
  local distance=conn.dir=='north'and z or conn.dir=='south'and h-z or conn.dir=='west'and x or w-x
  add(conn.map,math.max(0,distance))
 end
 local ranked={};for map,score in pairs(destinations)do ranked[#ranked+1]={map=map,score=score}end
 table.sort(ranked,function(a,b)if a.score~=b.score then return a.score<b.score end;return a.map<b.map end)
 -- The scene loader computes this fingerprint in budgeted slices. Avoid
 -- synchronously encoding the full config from the drawing/prefetch path.
 local config=C.configDigest;local projection=V.require('Camera').geometryKey()
 if not config then return end
 local wanted,queued={},{}
 for _,dest in ipairs(ranked)do
  local target=game.data and game.data.maps and game.data.maps[dest.map]
  local targetProjection=V.require('GraphicsOverlay').indoorLocked(target)and V.require('Camera').geometryKey(50)or projection
  for _,item in ipairs(catalog[dest.map])do
   if (not mobile or item.primary)and item.scene.config==config and item.scene.projection==targetProjection then
    local expected=idx.entries[item.key]
    if expected and not queued[expected]then
     queued[expected]=true;wanted[#wanted+1]={digest=expected,filename=idx.version==2 and expected or item.key,
      maxBytes=mobile and 8*1024*1024 or nil}
    end
    if #wanted>=targetLimit then break end
   end
  end
  if #wanted>=targetLimit then break end
 end
 -- Only the nearest destination may make small progress during walking.
 if wanted[1]then wanted[1].priority=true end
 L.targets=wanted;P.want(wanted);P.pump(backgroundAllowed)
end
function L.release()
 V.require('NativeMapLookahead').release()
 V.require('GeometryPrefetch').release();V.require('GeometryGpuWarm').release();L.targets={}
 lastIndex,catalog,lastMap,lastTime,active,builder=nil,nil,nil,nil,nil,nil
 L.pendingCatalog=false
end
return L
