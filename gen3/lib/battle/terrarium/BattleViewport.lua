-- Window composition only. Native surfaces always use uniform display scales.
local View={}
function View.layout(x,y,w,h,paperScale)
 local pad=math.min(w,h)*.018
 local hud=math.min((w-3*pad)/240,h/230)
 local menu=math.min((w-2*pad)/240,h/260)
 -- Fit the silhouette in portrait, rather than its empty side margins.
 local world=math.min((w-2*pad)/(240*.62*(paperScale or 1)),(h-2*pad)/160)
 local overlay=math.min(w/240,h/160)
 return {x=x,y=y,w=w,h=h,pad=pad,
  world={x=x+w/2-120*world,y=y+h/2-80*world-menu*5,scale=world},
  left={x=x+pad,y=y+pad,scale=hud},
  right={x=x+w-pad-120*hud,y=y+pad,scale=hud},
  menu={x=x+w/2-120*menu,y=y+h-pad-48*menu,scale=menu},
  overlay={x=x+w/2-120*overlay,y=y+h/2-80*overlay,scale=overlay}}
end
function View.safeRect(game)
 local x,y,w,h=require('src.core.SafeArea').rect()
 local controls=game and game.touchControls
 if h>w and controls and controls.visible and controls:visible()and controls.layout then
  local layout=controls:layout();local bottom=y+h
  for _,key in ipairs({'dpad','a','b','start','select'})do
   local zone=layout[key]
   if zone and zone.cy and(zone.h or zone.w)then bottom=math.min(bottom,zone.cy-(zone.h or zone.w)/2-8)end
  end
  local hotbar=layout.hotbar
  if controls.hotbarShown and controls:hotbarShown()and hotbar and hotbar.cy and hotbar.w then
   y=math.max(y,hotbar.cy+hotbar.w/2+8)
  end
  h=math.max(1,bottom-y)
 end
 return x,y,w,h
end
function View.fullscreen()
 local ui=require('src.core.game3.battle.ui')
 if ui._mode=='bag'or ui._mode=='party'then return true end
 local stack=require('src.ui.game3.stack')
 if stack.fullscreen()then return true end
 for _,name in ipairs({'bag_menu','party_menu','pokedex','help_system','stat_growth'})do
  -- The mod sandbox's package.loaded is not the engine module registry.
  local m=require('src.ui.game3.'..name)
  if m and m.isOpen and m.isOpen()then return true end
 end
 -- FR/LG never opens the RSE registration screen. Loading its separate
 -- menu tree here caused a cold import stall on the first battle frame.
 if require('src.core.GameVersion').layout()~='rse'then return false end
 local dex=require('src.ui.game3.rse.pokedex')
 return dex and dex.active and dex.active()or false
end
function View.draw(self,world,hud,layout,fullscreen,veil)
 local g=love.graphics
 g.origin();g.setShader();g.setDepthMode();g.setScissor();g.clear(0,0,0,1)
 g.setColor(1,1,1,1);g.setBlendMode('alpha','premultiplied')
 local function draw(canvas,rect,at)
  self.viewportQuad=self.viewportQuad or g.newQuad(0,0,240,160,240,160)
  self.viewportQuad:setViewport(rect[1],rect[2],rect[3],rect[4],240,160)
  g.draw(canvas,self.viewportQuad,at.x,at.y,0,at.scale,at.scale)
 end
 g.setScissor(layout.x,layout.y,layout.w,layout.h)
 draw(world,{0,0,240,160},layout.world)
 if (self.viewportDim or 0)>0 then
  g.setBlendMode('alpha');g.setColor(0,0,0,self.viewportDim)
  g.rectangle('fill',layout.x,layout.y,layout.w,layout.h)
  g.setColor(1,1,1,1);g.setBlendMode('alpha','premultiplied')
 end
 if fullscreen then
  g.setBlendMode('alpha');g.setColor(0,0,0,.7);g.rectangle('fill',layout.x,layout.y,layout.w,layout.h)
  g.setColor(1,1,1,1);g.setBlendMode('alpha','premultiplied')
  draw(hud,{0,0,240,160},layout.overlay)
 else
  draw(hud,{0,0,120,112},layout.left)
  draw(hud,{120,0,120,112},layout.right)
  draw(hud,{0,112,240,48},layout.menu)
 end
 -- A native MAP intro wipe covers the viewport once. It is not part of
 -- either HP box and must not be split/scaled with the HUD rectangles.
 local mask=self.viewportMask
 if mask then
  g.setBlendMode('alpha');g.setColor(0,0,0,1)
  g.rectangle('fill',layout.x,layout.y,layout.w,layout.h*mask[1]/160)
  local bottom=layout.y+layout.h*mask[2]/160
  g.rectangle('fill',layout.x,bottom,layout.w,layout.y+layout.h-bottom)
 end
 if veil and(veil[4]or 0)>0 then
  g.setScissor();g.setBlendMode('alpha');g.setColor(unpack(veil))
  local w,h=require('src.render.GameViewport').dimensions();g.rectangle('fill',0,0,w,h)
 end
end
return View
