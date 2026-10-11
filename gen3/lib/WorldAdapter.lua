-- Read-only bridge to FireRed's native field. No compatibility proxy, map
-- replacement, collision rewrite or synthetic NPC state enters the renderer.
local V = ...
local Shapes = V.data("Shapes")
local Map = require("src.core.game3.map")
local Player = require("src.core.game3.player")
local Runtime = require("src.core.game3.runtime")
local Native = require("src.core.game3.tileset_native")
local Objects = require("src.core.game3.objects")
local Sprites = require("src.core.game3.ow_sprites")
local Space = require("src.core.game3.scripting.space")
local Adapter={Native=Native,Player=Player,Sprites=Sprites}
function Adapter.current(game)
  local session=Runtime.getSession()
  if not session or game.phase~="field" then return nil end
  local id=Map.current or session.map
  local def=game.data and game.data.maps and game.data.maps[id]
  if not def then return nil end
  Map.ensureMidLayout(game,id,def)
  if not def.midLayout then return nil end
  return id,V.require("NativeTilesetIdentity").resolve(def)
end
function Adapter.maps(game,neighbors,width,height,margin,worldReady,aheadMargin)
  local id,def=Adapter.current(game)
  if not id then return {} end
  local out={{id=id,def=def,ox=0,oy=0}}
  local ahead=aheadMargin and {out[1]}
  if neighbors and Shapes.outdoors(def) then
    local ex,ez=V.require("Camera").groundExtents(width,height)
    if not worldReady then Map.refreshWorld(game,math.ceil(ex/16)+12,math.ceil(ez/16)+12,id)end
    for _,entry in ipairs(Map.world or {}) do
      if entry.def.midLayout and (not V.data('Emerald').active() or V.data('Emerald').isSupported(entry.id,entry.def)) then
        local L=entry.def.midLayout
        local left,top=entry.ox*16,entry.oy*16
        local dx=math.max(left-Player.px,0,Player.px-(left+L.width*16))
        local dz=math.max(top-Player.py,0,Player.py-(top+L.height*16))
        local visible=dx<=ex+(margin or 0) and dz<=ez+(margin or 0)
        if visible or (ahead and dx<=ex+aheadMargin and dz<=ez+aheadMargin) then
          local resolved=V.require("NativeTilesetIdentity").resolve(entry.def)
          local row=resolved==entry.def and entry or setmetatable({def=resolved},{__index=entry})
          if visible then out[#out+1]=row end
          if ahead then ahead[#ahead+1]=row end
        end
      end
    end
  end
  return out,ahead
end
local actorRows,actors={},{}
local function nextActor(out)
 local i=#out+1;local a=actorRows[i]or{pose={}};actorRows[i]=a;out[i]=a;return a
end
function Adapter.actors(game,mode,entries)
  local out=actors;for i=#out,1,-1 do out[i]=nil end
  local id,def=Adapter.current(game)
  local function append(eo,def,mapId,ox,oz,neighbor)
    local gid=eo.graphicsId or (eo.def and (eo.def.graphicsId or eo.def.graphics))
    if eo.def and Space.resolveObjectGraphicsId then gid=Space.resolveObjectGraphicsId(eo.def,neighbor) or gid end
    local x,z=eo.px or eo.cellX*16,eo.py or eo.cellY*16
    local paperY,paperZ=V.require("Furniture").actorOffset(def,x,z,gid,eo.currentElevation or eo.elevation or(eo.def and eo.def.elevation))
    local a=nextActor(out);a.isPlayer=nil;a.battleProp=not V.data('Emerald').active()and(gid==92 or gid==94)
    a.gid,a.x,a.z,a.zOffset=gid,x+ox,z+oz,paperZ
    a.mapId,a.localId=mapId,eo.localId
    a.contactY=V.require('EmeraldMagmaHideout').actorHeight(def,x,z)or V.require('EmeraldCaveTerraces').actorHeight(def,x,z)or V.require('FireRedTerracedCaves').actorHeight(def,x,z)
    a.xOffset,a.yOffset,a.facing=eo.raiseX or 0,-(eo.raiseY or 0)+paperY,eo.facing
    a.phase,a.flip=Objects.walkPhase(eo),eo.stepFlip
    a.pose.fieldMove=nil;a.pose.frame,a.pose.bow=eo.customFrame,(eo.bowFrames or 0)>0 or eo.raiseHand==true
  end
  for _,eo in ipairs(Objects.forDraw())do append(eo,def,id,0,0)end
  -- The engine retains/adopts the same live objects across connected maps.
  -- Consume that pool read-only, including movement, visibility and script
  -- graphics, rather than dropping every actor outside the active map.
  local Ghosts=require('src.core.game3.ghosts')
  for _,entry in ipairs(entries or{})do if entry.id~=id then
    local neighbor=Space.neighborObjectState and Space.neighborObjectState(entry.id)
    for _,eo in ipairs(Ghosts.forDraw(entry.id)or{})do
      append(eo,entry.def,entry.id,entry.ox*16,entry.oy*16,neighbor)
    end
  end end
  if (not Player.isVisible or Player.isVisible()) then
    local jump=Player.spriteYOffset or 0
    if jump==0 and Player.jumpSpriteY then jump=Player.jumpSpriteY() or 0 end
    local paperY,paperZ=V.require("Furniture").actorOffset(def,Player.px,Player.py,nil,Player.currentElevation~=0 and Player.currentElevation or Player.elevation)
    local a=nextActor(out);a.isPlayer=true;a.battleProp=nil;a.mapId,a.localId=id,nil
    a.gid,a.x,a.z,a.zOffset=Sprites.playerGraphicsId(game),Player.px,Player.py,paperZ
    a.contactY=V.require('EmeraldMagmaHideout').actorHeight(def,Player.px,Player.py)or V.require('EmeraldCaveTerraces').actorHeight(def,Player.px,Player.py)or V.require('FireRedTerracedCaves').actorHeight(def,Player.px,Player.py)
    a.xOffset,a.yOffset,a.facing=Player.spriteXOffset or 0,-jump+paperY,Player.drawFacing and Player.drawFacing()or Player.facing
    a.phase,a.flip=Player.walkPhase(),Player.drawFlip()
    a.pose.frame,a.pose.bow=nil,nil;a.pose.fieldMove=(Player.fieldMoveAnim or 0)>0
  end
  return out
end
return Adapter
