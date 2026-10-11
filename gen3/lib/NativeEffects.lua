-- Draw the native field-effect state in the paper camera. Never step, finish,
-- replace or synthesize native animation/gameplay state here.
local V=...
local E=require('src.core.game3.field_effects')
local P=require('src.core.game3.player')
local N={count=0}
local function rawSprite(image,q,x,z,base,height,flip,ground,front,liftY,vflip,surface,heightScale)
 local sx,sy,sw,sh=0,0,image:getWidth(),image:getHeight()
 if q then sx,sy,sw,sh=q:getViewport()end
 local iw,ih=image:getDimensions()
 local uv={sx/iw,sy/ih,(sx+sw)/iw,(sy+sh)/ih}
 if flip then uv[1],uv[3]=uv[3],uv[1]end
 if vflip then uv[2],uv[4]=uv[4],uv[2]end
 local verts={};local G=V.require('WorldGeometry')
 if surface then
  G.quad(verts,surface[1],surface[2],surface[3],surface[4],uv,1)
 elseif ground then
  G.quad(verts,{x,.12,z},{x+sw,.12,z},{x+sw,.12,z+sh},{x,.12,z+sh},uv,1)
 else
  local uy,uz=V.require('Camera').cardUp();height=height or 0
  local low=height*(heightScale or 1);local high=(height+sh)*(heightScale or 1)
  local lift=.15+(liftY or 0)
  G.quad(verts,{x,high*uy+lift,base+high*uz},{x+sw,high*uy+lift,base+high*uz},
   {x+sw,low*uy+lift,base+low*uz},{x,low*uy+lift,base+low*uz},uv,1)
 end
 if not N.mesh then N.mesh=love.graphics.newMesh(G.FORMAT,6,'triangles','stream')end
 N.mesh:setVertices(verts);N.mesh:setTexture(image);love.graphics.draw(N.mesh);N.count=N.count+1
end
local function sprite(name,w,h,frames,frame,x,z,base,height,flip,ground,front,liftY)
 local load=E.getSpriteSheet or E.loadSheet
 local s=load and load(name,w,h,frames)
 local q=s and (front and s.quadsFront or s.quads)[frame]
 if q then rawSprite(s.image,q,x,z,base,height,flip,ground,front,liftY)end
end
local function grass(front)
 local fx=E._fx;if not fx then return end
 local frame=fx.seq and (fx.frame or 0)or ({1,2,3,4,0})[fx.step+1]or 0
 if front then
  local feet=P.py+16;if feet<fx.cy*16+8 or feet>(fx.cy+1)*16+2 then return end
 end
 sprite(fx.sheet or 'tall_grass',16,16,5,frame,fx.cx*16,fx.cy*16,(fx.cy+1)*16,0,false,not front,front)
end
function N.behind()
 N.count=0;N.shipCount=0
 if P.surfing or P.surfHopping or P.dismounting then
  -- Current engines keep the animation on the native surf bob, while older
  -- engines expose a shared clock. Read either without advancing gameplay.
  local bob=E._surfBob
  local step=math.floor((bob and bob.animClock or E._surfClock or 0)/48)%2
  local frame=(P.facing=='up' and 2 or (P.facing=='left' or P.facing=='right')and 4 or 0)+step
  local flip=P.facing=='right'
  local load=E.getSpriteSheet or E.loadSheet
  local sheet=load and load('surf_blob',32,32,6)
  local blob=sheet and sheet.frames and sheet.frames<6 and E.manifestObject and E.manifestObject('surf_blob')
  if blob and blob.anims then
   local seq=blob.anims[({down=1,up=2,left=3,right=4})[P.facing]or 1]
   local cmd=seq and seq[1];frame=cmd and cmd[2]or 0;flip=cmd and cmd[4]==true or false
  end
  local x,z=P.px,P.py
  if P.surfHopping then x,z=(P.targetX or P.cellX)*16,(P.targetY or P.cellY)*16
  elseif P.dismounting then x,z=P.cellX*16,P.cellY*16 end
  local q=sheet and sheet.quads[frame]
  if q then rawSprite(sheet.image,q,x-8,z-8+(bob and bob.y2 or 0),z+24,0,flip,true)end
 end
 grass(false)
end
function N.front(def)
  V.require('CenterEscalatorTraversal').install()
  V.require('CameraContinuity').install()
  local gates=V.require('EmeraldRotatingGates');gates.draw(def);N.count=N.count+gates.count
  grass(true)
  for _,s in ipairs(V.require('EmeraldAshEffects').sprites(def))do
   rawSprite(s.image,s.quad,s.x,s.z,s.base,0,s.flip,false,false,s.lift,s.vflip)
  end
  for _,s in ipairs(V.require('EmeraldSecretReactive').sprites(def))do
   rawSprite(s.image,s.quad,s.x,s.z,s.base,0,s.flip,false,false,0,s.vflip,s.surface)
  end
  for _,s in ipairs(V.require('ShipEffects').snapshot(def))do
   -- Smoke shares the boat actor's compensated pixel height; without this
   -- it sits behind the enlarged hull instead of above its smokestack.
   rawSprite(s.image,s.quad,s.x,s.y,s.base,s.height,false,s.ground,nil,nil,nil,nil,V.require('Billboard').heightScale())
   N.shipCount=N.shipCount+1
  end
 for _,a in ipairs(E._anims or{})do
  if a.kind=='cut_grass_scatter' or a.kind=='rock_smash'then
   local cut=a.kind=='cut_grass_scatter';local size=cut and 8 or 16
   for _,p in ipairs(a.particles or{})do
    local base=(a.cy or P.cellY)*16+16
    sprite(cut and 'cut_grass' or 'rock_smash',size,size,cut and 1 or 4,cut and 0 or p.frame%4,
     p.x,p.y,base,base-p.y-size,false,false)
   end
  elseif a.kind=='fly_takeoff' or a.kind=='fly_landing'then
   local base=P.py+16
   -- Flight rises vertically in the world, so roofs cannot slice through
   -- the bird. Keep the native screen-space ascent distance at this tilt.
   local uy=V.require('Camera').cardUp()
   local lift=(a.targetPy-a.py)/uy
   sprite('fly_bird',64,64,5,a.frame,a.px,a.py,base,base-a.targetPy-64,false,false,false,lift)
  elseif a.kind=='emote' or a.kind=='exclamation'then
   local t=a.targetObj
   local x=t and (t.px or (t.cellX or t.x or 0)*16)or 0
   local z=t and (t.py or (t.cellY or t.y or 0)*16)or 0
   local paperY,paperZ=V.require('Furniture').actorOffset(def,x,z)
   local uy,uz=V.require('Camera').cardUp();local lift=paperY/uy
   sprite('emoticons',16,16,15,a.frame,x,z-16,z+16+paperZ-lift*uz,16+lift,false,false)
  end
 end
end
function N.heal(def,vp,depthScale)
 N.healCount=0;N.healAnchored=0;N.hofCount=0
 local Heal=require('src.core.game3.pokecenter_heal')
 local sprites=V.require('NativeHealingSprites').snapshot(Heal)
 local hof=V.require('EmeraldHallOfFame').recordSprites(def)
 if #sprites==0 and #hof==0 then return end
 if not N.glowShader then N.glowShader=V.require('ShaderCompiler').newShader([[uniform mat4 vp;
 uniform float roomDepthScale;
 vec4 position(mat4 t,vec4 p){vec4 q=vp*p;q.z*=roomDepthScale;return q;}]])end
 love.graphics.push('all');love.graphics.setShader(N.glowShader)
 N.glowShader:send('vp','row',vp);N.glowShader:send('roomDepthScale',depthScale or 1);love.graphics.setDepthMode('lequal',false)
 for _,s in ipairs(sprites)do
  local w,h=s.image:getDimensions();if s.quad then local _,_,qw,qh=s.quad:getViewport();w,h=qw,qh end
  -- Native OAM is anchored to the player at (112,72). Translate back to the
  -- original map artwork, then onto that artwork's actual paper surface.
  local x,z=P.px-112+s.x,P.py-72+s.y
  local surface=V.require('CenterHealingSurface').surface(def,x,z,w,h,s.kind)
  local base=V.require('Furniture').paperAnchor(def,x+w/2,z+h/2)
  if surface then
   rawSprite(s.image,s.quad,x,z,0,0,false,false,false,0,false,surface)
   N.healAnchored=N.healAnchored+1
  elseif base then
   rawSprite(s.image,s.quad,x,z,base+.3,base-z-h,false,false)
   N.healAnchored=N.healAnchored+1
  else rawSprite(s.image,s.quad,x,z,z+h,0,false,false)end
  N.healCount=N.healCount+1
 end
 for _,s in ipairs(hof)do rawSprite(s.image,s.quad,s.x,s.z,s.base,0,s.flip,false,false,s.lift,s.vflip,s.surface);N.hofCount=N.hofCount+1 end
 love.graphics.pop()
end
function N.overlay(width,height)
 N.overlayCount=0
 love.graphics.push('all');love.graphics.setShader();love.graphics.setDepthMode()
 local scale=height/160
 for _,a in ipairs(E._anims or{})do
  if a.kind=='flash' and a.alpha>0 then
   love.graphics.setColor(1,1,1,a.alpha);love.graphics.rectangle('fill',0,0,width,height)
   N.overlayCount=N.overlayCount+1
  elseif a.kind=='sweet_scent'then
   love.graphics.setColor(1,.7,.9,.6*(1-a.timer/a.maxDur));love.graphics.setLineWidth(math.max(1,scale))
   love.graphics.circle('line',width/2,height/2,a.radius*scale)
   love.graphics.circle('line',width/2,height/2,math.max(0,a.radius-20)*scale)
   N.overlayCount=N.overlayCount+1
  end
 end
 love.graphics.pop()
end
function N.release()V.require('EmeraldRotatingGates').release();if N.mesh then N.mesh:release();N.mesh=nil end;if N.glowShader then N.glowShader:release();N.glowShader=nil end;N.count=0 end
return N
