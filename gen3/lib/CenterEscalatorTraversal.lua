-- The folded escalator is solid furniture. Its original native warp is the
-- only entrance, approached from its open right side. Native travel remains
-- responsible for direction, animation, destination and landing.
local V=...
local T={}
function T.install()
 if T.installed then return end;T.installed=true
 local C=require('src.core.game3.collision');local Map=require('src.core.game3.map')
 local enter,escalator=C.canEnter,C.isEscalatorWarp
 local function object(tx,ty)
  local api=V.mod.exports.gen3
  if not api or api.getMode()=='off'then return end
  local def=Map.currentDef();if not def or not(V.require('IndoorSurfaces').profile(def)or V.require('EmeraldRoomSurfaces').profile(def))then return end
  -- Plans are cached by the furniture provider; native moving stair frames
  -- keep the original footprint until the warp finishes.
  local L=def.midLayout
  if T.layout~=L then T.layout=L;T.objects=V.require('Furniture').plan(def)end
  for _,o in ipairs(T.objects or{})do
   if o.kind=='escalator'and tx>=o.x and tx<o.x+2 and ty>=o.y and ty<o.y+3 then return o end
  end
 end
 C.canEnter=function(game,tx,ty,opts)
  if object(tx,ty)then return false,'paper escalator' end
  return enter(game,tx,ty,opts)
 end
 C.isEscalatorWarp=function(game,tx,ty,dir)
  local o=object(tx,ty)
  if o and dir~='left'then return nil end
  return escalator(game,tx,ty,dir)
 end
end
return T
