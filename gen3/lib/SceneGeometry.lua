-- The complete scene artifact producer is separate from shader/presentation code.
-- Cache source manifests follow this module and its full dependencies.
local V=...
local Geometry=V.require('WorldGeometry')
local Visibility=V.require('SceneVisibility')
local BuildBudget=V.require('BuildBudget')
local BuildQueue=V.require('NativeBuildQueue')
local Shapes=V.data('Shapes')
local hasFieldAnim,FieldAnim=pcall(require,'src.core.game3.special_field_anim')
local S={}
local keys=setmetatable({},{__mode='k'})
function S.get(Renderer,entry,ts,viewId,releaseEntry)
  local preserveRows=V.require('DioramaConfig').trees.preserveViewRows[viewId] and entry.id~=viewId
  local keyRow=keys[entry.def]
  if not keyRow or keyRow.id~=entry.id or keyRow.ox~=entry.ox or keyRow.oy~=entry.oy or keyRow.preserve~=preserveRows then
   keyRow={id=entry.id,ox=entry.ox,oy=entry.oy,preserve=preserveRows,key=entry.id..":"..tostring(entry.ox)..":"..tostring(entry.oy)..":"..tostring(preserveRows)};keys[entry.def]=keyRow
  end
  local key=keyRow.key
  local cached=Renderer.cache[key]
  local L=entry.def.midLayout
  -- Native escalator phases alter texture metatiles, not the folded solid
  -- footprint. Keep the prepared room during its short travel animation;
  -- rebuilding the entire room for every rail frame stalls the warp itself.
  local anim=hasFieldAnim and FieldAnim
  if cached and cached.layout==L and anim and anim._active and anim._layout==L then
    cached.used=Renderer.tick;return cached
  end
  local stamp=Geometry.layoutStamp(L)
  local reactiveStamp=V.require("EmeraldSecretReactive").effectStamp(entry.def)
  if cached and cached.layout==L and cached.stamp==stamp and cached.reactiveStamp==reactiveStamp then
    cached.used=Renderer.tick
    return cached
  end
  local previous=cached
  local artifact=V.require('GeometryCache')
  local function build()
  V.require('Atmosphere').prepareMap(entry.def)
  BuildBudget.check()
  BuildBudget.phase("cache")
  local artifactKey=artifact.key(entry,ts,Renderer.useInstancing and Renderer.instanceShader~=nil,preserveRows)
  local restored=artifact.load(artifactKey,entry.def,ts,entry.ox,entry.oy)
  if restored then
    if restored.instances then for _,b in ipairs(restored.instances)do if b.dynamic then restored.stats.frustumBounds=nil;break end end end
    restored.layout=L;restored.stamp=stamp;restored.reactiveStamp=reactiveStamp;restored.used=Renderer.tick
    if previous then releaseEntry(previous)end
    Renderer.cache[key]=restored;return restored
  end
  if artifactKey and artifact.record then artifact.beginRecord(ts)end
  local instances=Renderer.useInstancing and Renderer.instanceShader and {trees={},props={}} or nil
  BuildBudget.phase("geometry");BuildBudget.check()
  local vertices,stats=Geometry.build(entry.def,ts,entry.ox,entry.oy,instances,preserveRows)
  BuildBudget.phase("metadata");BuildBudget.check()
  stats.frustumBounds=Visibility.vertices(vertices)
  stats.waterReflectionBounds=V.require('WaterReflectionBounds').vertices(vertices)
  BuildBudget.phase("mesh upload");BuildBudget.check()
  local mesh=BuildQueue.own(love.graphics.newMesh(Geometry.FORMAT,vertices,"triangles","static"))
  BuildBudget.phase("heightfield");BuildBudget.check()
  cached={mesh=mesh,contacts=BuildQueue.own(V.require("ContactShadows").mesh(stats.contacts)),stats=stats,layout=L,stamp=stamp,reactiveStamp=reactiveStamp,used=Renderer.tick,heights=Geometry.heightfield(vertices)}
  if V.require('EmeraldNavelSanctums').profile(entry.def)or V.require('EmeraldNavelPassages').profile(entry.def)or V.require('EmeraldMirageTower').profile(entry.def)or V.require('EmeraldSeafloorCurrents').profile(entry.def)or V.require('EmeraldFieryPath').profile(entry.def)or V.require('EmeraldMagmaHideout').profile(entry.def)or V.require('EmeraldRusturf').profile(entry.def)or V.require('CaveTerrain').applies(entry.def)or V.require('TanobyChambers').profile(entry.def)or V.require('FireRedTerracedCaves').profile(entry.def)or V.require('TanobyKey').profile(entry.def)or V.require('FireRedDiglettCave').profile(entry.def)or V.require('FireRedLostCave').profile(entry.def)or V.require('FireRedRuinCaves').profile(entry.def)then cached.caveCaps=V.require('CaveSectionMesh').collect(vertices,entry.def,ts)end
  stats.storedVertices=#vertices
  cached.instances={}
  if artifactKey and artifact.record then
    cached.staticHeights={}
    for z,row in pairs(cached.heights)do local copy={};cached.staticHeights[z]=copy;for x,h in pairs(row)do copy[x]=h end end
  end
  local function batch(template,placements,dynamic)
    if #template==0 or #placements==0 then return end
    BuildBudget.phase("instance upload");BuildBudget.check()
    local item={mesh=BuildQueue.own(love.graphics.newMesh(Geometry.FORMAT,template,"triangles","static")),
      placements=BuildQueue.own(love.graphics.newMesh({{"WorldPlacement","float",3}},placements,"points","static")),count=#placements,dynamic=dynamic}
    item.mesh:attachAttribute("WorldPlacement",item.placements,"perinstance")
    stats.frustumBounds=Visibility.merge(stats.frustumBounds,Visibility.vertices(template),placements)
    cached.instances[#cached.instances+1]=item
    local fields={}
    for _,p in ipairs(placements)do
      BuildBudget.check()
      if not fields[p[3]] then fields[p[3]]=Geometry.heightfield(template,p[3]) end
      Geometry.mergeHeightfield(cached.heights,fields[p[3]],p[1],p[2])
      if cached.staticHeights and not dynamic then Geometry.mergeHeightfield(cached.staticHeights,fields[p[3]],p[1],p[2])end
    end
    stats.vertices=stats.vertices+#template*#placements
    stats.storedVertices=stats.storedVertices+#template+#placements
  end
  if instances then
    local keys={};for k in pairs(instances.props)do keys[#keys+1]=k end;table.sort(keys)
    for _,k in ipairs(keys)do
      local g=instances.props[k]
      batch(V.require("Props").template(ts,g.mid,g.kind,g.ground),g.placements,
        g.kind=="flower"and{mid=g.mid,kind=g.kind,ground=g.ground}or nil)
    end
    if #instances.trees>0 then batch(V.require("Trees").template(ts,Shapes.forest(entry.def)),instances.trees) end
  end
  if Geometry.layoutStamp(L)~=stamp or V.require('EmeraldSecretReactive').effectStamp(entry.def)~=reactiveStamp then
    BuildQueue.retry()
  end
  if previous then releaseEntry(previous)end
  Renderer.cache[key]=cached
  if artifactKey and artifact.record then artifact.record(artifactKey,cached,entry,ts)end
  return cached
  end
  if Renderer.cooperative and not artifact.record then
    return BuildQueue.get(key..":"..stamp..":"..tostring(reactiveStamp),Renderer.tick,build)
  end
  return build()
end
return S
