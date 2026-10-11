-- Fill the available play surface without stretching native sprites or HUD.
local V=...
local View={}
local Base=V.require('battle/terrarium/BattleViewport')
function View.active(scene)
 local game=require('src.core.GameVersion').get()
 return (game=='firered' or game=='leafgreen' or game=='emerald')and scene and scene.map
  and scene.kind~='terrarium'and V.require('DioramaConfig').battle.mapViewport~=false
end
-- Use the field's approved pixel budget, keeping logical fitting unchanged.
-- Native HUD layout still uses the full drawable; MAP must not bypass the
-- Retina cap and multiply every lighting/depth/postprocess target by four.
function View.resolution(game)
 local _,_,w,h=Base.safeRect(game)
 local uw,uh=love.graphics.getDimensions();local pw,ph=love.graphics.getPixelDimensions()
 local scale=math.max(1,math.ceil(math.max(w/240*pw/math.max(1,uw),h/160*ph/math.max(1,uh))))
 local rw,rh=V.require('RenderResolution').dimensions(240*scale,160*scale)
 return math.max(1,math.min(rw/240,rh/160))
end
function View.layout(game)
 local x,y,w,h=Base.safeRect(game)
 local layout=Base.layout(x,y,w,h)
 local scale=math.max(w/240,h/160)
 layout.world={x=x+w/2-120*scale,y=y+h/2-80*scale,scale=scale}
 -- Fit actor bounds inside the visible crop, below the original HP skins
 -- and above the separately positioned native command/message surface.
 local world=layout.world
 layout.actorFrame={
  left=math.max(0,(x-world.x)/scale)+2,
  right=math.min(240,(x+w-world.x)/scale)-2,
  top=math.max(0,(layout.left.y+48*layout.left.scale-world.y)/scale)+2,
  bottom=math.min(160,(layout.menu.y-world.y)/scale)-2,
 }
 return layout
end
return View
