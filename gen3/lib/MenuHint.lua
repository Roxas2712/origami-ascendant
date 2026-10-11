-- Screen-space menu discovery, independent of the optional performance HUD.
local V=...
local H={}
local states=setmetatable({},{__mode='k'})
function H.mobile(game)
 local os=love.system.getOS()
 return os=='iOS'or os=='Android'or(game and game.touchControls and game.touchControls.visible==true)
end
function H.available(game)
 return game and game.phase=='field'and not require('src.ui.game3.stack').busy()
  and not require('src.core.game3.battle_transition').isActive()
  and not V.require('GraphicsOverlay').open
end
function H.showAngle(game,angle)
 local t=(V.clock or love.timer.getTime)();local s=states[game]or{start=t};states[game]=s
 s.angle=angle;s.angleUntil=t+3
end
function H.currentAngle(game)
 local s=states[game];return s and (V.clock or love.timer.getTime)()< (s.angleUntil or 0)and s.angle or nil
end
function H.layout(game)return{8,8,H.mobile(game)and 48 or 186,48}end
function H.alpha(game)
 if not H.available(game)then return 0 end
 local t=(V.clock or love.timer.getTime)();local s=states[game]
 if not s then s={start=t};states[game]=s end
 local elapsed=(t-s.start)%90
 return elapsed<6 and math.min(1,elapsed/.35,(6-elapsed)/.6)or 0
end
function H.pointer(game,x,y)
 if not H.available(game)then return false end
 local r=H.layout(game);if x<r[1]or y<r[2]or x>=r[1]+r[3]or y>=r[2]+r[4]then return false end
 if not H.mobile(game)and H.alpha(game)<=0 and not H.currentAngle(game)then return false end
 V.require('Menu').openQuick(game);return true
end
function H.draw(game)
 if not H.available(game)then return end
 local a=H.alpha(game);local mobile=H.mobile(game);local angle=H.currentAngle(game)
 if angle then a=1 end
 if a<=0 and not mobile then return end
 local g=love.graphics;local L=V.require('MenuLocale')
 H.font=H.font or g.newFont(13)
 g.push('all');g.origin();g.setCanvas();g.setShader();g.setScissor();g.setDepthMode();g.setStencilTest();g.setColorMask(true,true,true,true);g.setBlendMode('alpha');g.setFont(H.font)
 g.setColor(0,0,0,mobile and .28 or .38*a);g.rectangle('fill',8,8,mobile and 48 or 186,48,7,7)
 g.setColor(1,1,1,mobile and .85 or a);g.print(mobile and 'O'or'F3 · OASC menu',mobile and 27 or 18,mobile and 24 or 16)
 if mobile and a>0 then
  g.setColor(0,0,0,.45*a);g.rectangle('fill',62,8,220,48,7,7);g.setColor(1,1,1,a)
  g.print(L.text('Tap O: OASC menu','O antippen: OASC-Menue'),72,15);g.print(L.text('Tap to open','Antippen zum Oeffnen'),72,33)
 elseif not mobile then g.print(angle and ('V · '..tostring(angle)..'°')or L.text('V: camera angle','V: Kamerawinkel'),18,34)end
 if mobile and angle then g.setColor(0,0,0,.6);g.rectangle('fill',62,62,110,32,7,7);g.setColor(1,1,1,1);g.print(tostring(angle)..'°',74,70)end
 g.pop()
end
return H
