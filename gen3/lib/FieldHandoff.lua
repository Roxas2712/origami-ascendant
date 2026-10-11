-- VASC LoadingCompanion presentation adapted to the Gen3 field renderer.
-- Only genuine pending geometry owns a cover; no extra wait or input lock.
local V=...
local H={}
local function art(g,t,species)
 local function box(x,y,w,h,r,green,b)
  g.setColor(r,green,b,1);g.rectangle('fill',x,y,w,h)
  g.setColor(r*.72,green*.72,b*.72,1);g.rectangle('fill',x+w-2,y+2,2,h)
 end
 -- Small block-built Pokéball; the seam and button rotate with the ball.
 g.push();g.translate(0,10);g.rotate(t*1.6)
 for y=-12,11,3 do local width=math.floor(math.sqrt(144-(y+1.5)^2)/3)*3
  box(-width,y,width*2,3,y<0 and .92 or .91,y<0 and .16 or .94,y<0 and .18 or .97)
 end
 box(-12,-1.5,24,3,.12,.17,.23);box(-4,-4,8,8,.12,.17,.23);box(-2,-2,4,4,1,1,1);g.pop()
 g.push();g.translate(0,3-math.abs(math.sin(t*7))*.8)
 local p=species=='pikachu';local r,b=p and .98 or .61,p and .10 or .25;local green=p and .77 or .38
 -- Profile, ears and tail remain recognisable at a small loading-icon size.
 if p then
  box(-19,-15,5,10,r,green,b);box(-22,-20,9,5,r,green,b);box(-18,-25,5,6,r,green,b)
 else box(-21,-16,12,8,r,green,b);box(-23,-17,5,6,.94,.83,.58)end
 box(-10,-18,15,14,r,green,b);box(-1,-26,14,13,r,green,b)
 box(0,-37,4,13,r,green,b);box(8,-35,4,11,r,green,b)
 box(0,-37,4,4,.18,.12,.10);box(8,-35,4,4,.18,.12,.10)
 if not p then box(-6,-15,13,5,.95,.85,.62)end
 box(9,-22,2,3,.09,.09,.12);box(12,-18,3,2,.13,.10,.09)
 if p then box(6,-17,3,3,.91,.20,.14)end
 local step=math.sin(t*7)*3
 box(-8+step,-5,6,3,r,green,b);box(2-step,-5,6,3,r,green,b)
 g.pop()
end

local function render(w,h,now,badgeOnly)
 local g=love.graphics
 g.origin();g.setShader();g.setScissor();g.setDepthMode();g.setStencilTest();g.setBlendMode('alpha');if not badgeOnly then g.setColor(.025,.04,.065,1);g.rectangle('fill',0,0,w,h)end
 if now-H.started<.18 then return end
 H.font=H.font or g.newFont(14)
 local scale=math.min(2,math.max(1,w/800),(w-24)/283)
 g.translate(w-164*scale,h-54*scale);g.scale(scale)
 g.setColor(.025,.04,.065,.94);g.rectangle('fill',-132,-69,283,105,9,9)
 g.push();g.translate(-88,0);art(g,now-H.started,H.species);g.pop()
 g.setFont(H.font);g.setColor(.93,.96,1,1)
 local L=V.require('MenuLocale');g.print(L.text('Loading area ...','Gebiet laden ...'),-47,-24)
 local dots=math.floor((now-H.started)*4)%4
 for i=1,3 do g.setColor(.95,.76,.28,i<=dots and 1 or .25);g.rectangle('fill',-45+(i-1)*11,2,5,5)end
 H.visible=true
end
function H.pending(renderer,width,height)
 local now=love.timer.getTime();local id=require('src.core.game3.map').current
 if not H.started or H.map~=id then
  H.started=now;H.map=id;local hash=0;for ch in tostring(id):gmatch('.')do hash=hash+ch:byte()end
  H.species=hash%2==0 and 'pikachu'or'eevee'
 end
 -- Fast cache hits keep the complete old frame without an indicator flash.
 if renderer.lastFrame and now-H.started<.18 then return renderer.lastFrame end
 if not H.canvas or H.canvas:getWidth()~=width or H.canvas:getHeight()~=height then
  if H.canvas then H.canvas:release()end
  H.canvas=love.graphics.newCanvas(width,height,{dpiscale=1});H.canvas:setFilter('nearest','nearest')
 end
 local g=love.graphics;g.push('all');g.setCanvas(H.canvas);render(width,height,now);g.pop();return H.canvas
end
-- Draw after the final native composite/fold cover, which otherwise hides the
-- field-target indicator. Startup and map readiness still own the lifetime.
function H.overlay(game,force)
 if not H.started then return end
 if not force and love.timer.getTime()-H.started<.18 then return end
 if not force and (not V.require('Renderer').buildPending or game.phase~='field'
  or require('src.core.game3.battle').isActive()or require('src.ui.game3.stack').fullscreen())then return end
 local g=love.graphics;g.push('all');g.setCanvas();render(g.getWidth(),g.getHeight(),love.timer.getTime(),H.foldVisible);g.pop()
end
function H.ready()
 H.started=nil;H.map=nil;H.visible=false
 -- A finished cover must not retain another viewport-sized target between
 -- rooms. The next cold load recreates it only when actually needed.
 if H.canvas then H.canvas:release();H.canvas=nil end
end
function H.release()
 for _,key in ipairs{'canvas','font'}do if H[key]then H[key]:release();H[key]=nil end end
 H.ready();H.foldVisible=false
end
return H
