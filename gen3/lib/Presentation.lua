-- The engine expects a drawable-pixel-sized override; quality only changes
-- internal world resolution, never the viewport, camera framing or UI size.
local P={}
-- LOVE 12 returns a render-target configuration, not always the Canvas itself.
-- Recognize the real world pass so QA and devices use the same final presenter.
function P.boundCanvas()
 local target=love.graphics.getCanvas()
 if type(target)=='table'then target=target[1]or target.texture end
 if type(target)=='table'then target=target.texture or target[1]end
 return target
end
function P.mirrorsOverride()
 local host=require('src.render.Renderer')
 return type(host.mirrorsWorldOverride)=='function'and host.mirrorsWorldOverride()or false
end
function P.fit(source,w,h)
 -- The engine pre-flips legacy 3D overrides on iOS/LOVE 12. Our internal
 -- canvases are now upright; compensate only at this owned override boundary.
 -- MAP/terrarium use their own upright presenter, not this field override.
 local mirror=P.mirrorsOverride()
 if source:getWidth()==w and source:getHeight()==h and not mirror then return source end
 if not P.canvas or P.canvas:getWidth()~=w or P.canvas:getHeight()~=h then
  P.release();P.canvas=love.graphics.newCanvas(w,h,{dpiscale=1});P.canvas:setFilter('nearest','nearest')
 end
 love.graphics.push('all');love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode();love.graphics.setShader()
 love.graphics.setCanvas(P.canvas);love.graphics.setBlendMode('replace','premultiplied');love.graphics.setColor(1,1,1,1)
 love.graphics.draw(source,0,mirror and h or 0,0,w/source:getWidth(),(mirror and -1 or 1)*h/source:getHeight());love.graphics.pop()
 return P.canvas
end
function P.release()if P.canvas then P.canvas:release();P.canvas=nil end end
return P
