-- Prepare the nearest connected field in its destination coordinates. Read-only:
-- never switch the native map/player, and publish only complete queue results.
local V=...
local W={}
local target
function W.update(game,renderer,width,height,releaseEntry)
 if V.require('MobileRenderBudget').active()or V.require('GeometryCache').record
  or V.require('DioramaConfig').renderCache.prefetch==false then return end
 local A=V.require('WorldAdapter');local Map=require('src.core.game3.map')
 if type(Map.computeWorld)~='function'then return end
 local id,def=A.current(game);if not id or not V.data('Shapes').outdoors(def)then return end
 local C=require('src.core.game3.connections');local w,h=C.sizeOf(def)
 local px,py=A.Player.px/16,A.Player.py/16;local nearest,distance
 for _,c in ipairs(C.each(def))do
  local d=game.data.maps[c.map]
  if d and d.midLayout and V.data('Shapes').outdoors(d)then
   local dw,dh=C.sizeOf(d);local along=(c.dir=='north'or c.dir=='south')and px or py
   local span=(c.dir=='north'or c.dir=='south')and dw or dh
   local gap=c.dir=='north'and py or c.dir=='south'and h-py or c.dir=='west'and px or w-px
   if along>=c.offset and along<c.offset+span and gap>=-1 and gap<=8 and(not distance or gap<distance)then nearest,distance=c,gap end
  end
 end
 if not nearest then target=nil;return end
 local d=game.data.maps[nearest.map];local ex,ez=V.require('Camera').groundExtents(width,height)
 local key=id..':'..nearest.map..':'..V.require('Camera').geometryKey()..':'..ex..':'..ez
 if not target or target.key~=key then
  local resolve=V.require('NativeTilesetIdentity').resolve
  local entries={{id=nearest.map,def=resolve(d),ox=0,oy=0}}
  for _,e in ipairs(Map.computeWorld(game.data.maps,nearest.map,Map.WORLD_HOPS,math.ceil(ex/16)+12,math.ceil(ez/16)+12))do
   if not V.data('Emerald').active()or V.data('Emerald').isSupported(e.id,e.def)then
    entries[#entries+1]={id=e.id,def=resolve(e.def),ox=e.ox,oy=e.oy}
   end
  end
  local actors={};local space=require('src.core.game3.scripting.space')
  for _,o in ipairs(d.objects or{})do
   local gid=space.resolveObjectGraphicsId and space.resolveObjectGraphicsId(o)or o.graphicsId or o.graphics
   if type(gid)=='number'then actors[#actors+1]={gid=gid}end
  end
  target={key=key,entries=entries,actors=actors}
 end
 local dw,dh=C.sizeOf(d);local x,y
 if nearest.dir=='north'then x,y=px-nearest.offset,dh
 elseif nearest.dir=='south'then x,y=px-nearest.offset,-1
 elseif nearest.dir=='west'then x,y=dw,py-nearest.offset
 else x,y=-1,py-nearest.offset end
 for _,e in ipairs(target.entries)do
  local l=e.def.midLayout
  if l then
   local dx=math.max(e.ox-x,0,x-e.ox-l.width)*16;local dz=math.max(e.oy-y,0,y-e.oy-l.height)*16
   if dx<=ex+32 and dz<=ez+32 then
    local ts=A.Native._pairs[e.def.pair or l.pair]
    if not ts then return end
    if not V.require('SceneGeometry').get(renderer,e,ts,nearest.map,releaseEntry)then return end
   end
  end
 end
 if not V.require('SpriteRim').prepareActors(target.actors,A.Sprites,nearest.map,renderer.tick,true)then return end
 d=target.entries[1].def
 local ts=A.Native._pairs[d.pair or d.midLayout.pair];if not ts then return end
 local B=V.require('WorldBorder')
 for i=1,2 do
  local borderEntries=target.entries
  if V.data('Emerald').active()then
   borderEntries={}
   for _,e in ipairs(target.entries)do
    local l=e.def.midLayout
    if l and math.max(e.ox-x,0,x-e.ox-l.width)*16<=ex and math.max(e.oy-y,0,y-e.oy-l.height)*16<=ez then borderEntries[#borderEntries+1]=e end
   end
  end
  if not B.prepare(d,ts,borderEntries,x*16,y*16,renderer.useInstancing and renderer.instanceShader~=nil,width,height,renderer.tick)then return end
  if nearest.dir=='north'then y=y-1 elseif nearest.dir=='south'then y=y+1 elseif nearest.dir=='west'then x=x-1 else x=x+1 end
 end
end
return W
