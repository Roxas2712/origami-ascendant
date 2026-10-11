-- Native wipes/fades keep logical coordinates and timing, but OASC's field
-- retains its framing and uses the field/battle pixel budget on mobile.
local V=...
local T={}
local function selected()
 return V.require('battle/BattleViews').preference()~='native'and V.require('DioramaConfig').battle.enabled
end
-- A stationary black fade needs one ready field image. Continue the native
-- clock/callback, but do not redraw the map behind an opaque transition.
function T.reuse(pw,ph,vw,vh)
 local native=require('src.core.game3.battle_transition')
 local p=T.dimensions
 if not selected()or not T.ready or not T.canvas or T.sequence~=native._opts
  or(native._frame or 0)<(T.frame or 0)or not native.isActive()or not p or p[1]~=pw or p[2]~=ph or p[3]~=vw or p[4]~=vh then return false end
 T.frame=native._frame;T.pending={pw=pw,ph=ph,dpi=T.canvas:getDPIScale()};return true
end
function T.capture(source,pw,ph,vw,vh,ready)
 local dpi=math.max(1,math.min(pw/vw,ph/vh))
 if selected()and V.require('MobileRenderBudget').active()then
  dpi=math.min(dpi,V.require('battle/BattleResolution').limit())
 end
 if not T.canvas or T.canvas:getWidth()~=vw or T.canvas:getHeight()~=vh or math.abs(T.canvas:getDPIScale()-dpi)>.001 then
  if T.canvas then T.canvas:release()end
  T.canvas=love.graphics.newCanvas(vw,vh,{dpiscale=dpi});T.canvas:setFilter('nearest','nearest')
 end
 local g=love.graphics;g.push('all');g.origin();g.setShader();g.setScissor();g.setDepthMode()
 g.setCanvas(T.canvas);g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1)
 g.draw(source,0,0,0,vw/source:getWidth(),vh/source:getHeight());g.pop()
 T.pending={pw=pw,ph=ph,dpi=dpi}
 local transition=require('src.core.game3.battle_transition')
 T.sequence=transition._opts;T.frame=transition._frame
 T.ready=ready~=false;T.dimensions={pw,ph,vw,vh};T.opacity=0
 if T.installed then return end;T.installed=true
 local native=require('src.core.game3.battle_transition');local previous=native.drawWorld
 native.drawWorld=function(canvas,w,h)
  local pending=T.pending;T.pending=nil
  if not pending then return previous(canvas,w,h)end
  -- Native scanline/zoom transitions tear a 3D field into moving grass and
  -- terrain strips. Keep their native clock/callback, but fade the stationary
  -- field to black before entering the selected MAP/terrarium presentation.
  if selected()then
   g.push('all');g.origin();g.setShader();g.setScissor();g.setDepthMode()
   local opacity=math.min(1,(native._frame or 0)/24);local old=T.opacity or 0
   local delta=old>=1 and 0 or math.max(0,(opacity-old)/(1-old))
   g.setCanvas(T.canvas);g.setBlendMode('alpha');g.setColor(0,0,0,delta)
   if delta>0 then g.rectangle('fill',0,0,w,h)end;g.pop();T.opacity=math.max(old,opacity)
   native._worldDrawn=true
   require('src.render.Renderer'):setWorldOverride(V.require('Presentation').fit(T.canvas,pending.pw,pending.ph))
   return true
  end
  local create=g.newCanvas;local fx=native._fx;local mosaic=fx and fx.mosaic
  if fx then fx.mosaic=0 end
  if native._scratch and math.abs(native._scratch:getDPIScale()-pending.dpi)>.001 then native._scratch:release();native._scratch=nil end
  g.newCanvas=function(cw,ch,opts)
   if cw==w and ch==h then
    local settings={};for k,v in pairs(opts or{})do settings[k]=v end
    settings.dpiscale=pending.dpi;return create(cw,ch,settings)
   end
   return create(cw,ch,opts)
  end
  local ok,result=pcall(previous,T.canvas,w,h)
  g.newCanvas=create;if fx then fx.mosaic=mosaic end
  if not ok then error(result,0)end
  require('src.render.Renderer'):setWorldOverride(V.require('Presentation').fit(T.canvas,pending.pw,pending.ph))
  return result
 end
end
return T
