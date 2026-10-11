-- OASC owns presentation only. Capture each native animated front sprite,
-- light/depth-test it in the world pass, then return that layer to the native
-- battle compositor at its original particle Z band. No second battle clock.
local V=...
local Ui=require('src.core.game3.battle.ui')
local Coords=require('src.core.game3.battle.anim_coords')
local Pokemon=require('src.core.game3.pokemon')
local Chrome=require('src.ui.game3.battle_chrome')
local Healthbox=require('src.core.game3.battle.healthbox')
local TrainerPic=require('src.core.game3.trainer_pic')
local Versions=require('src.import.gba.versions')
local GameVersion=require('src.core.GameVersion')
local function playerFront(gender,battle)
 if GameVersion.get()=='emerald' then
  local ids=require('src.core.game3.constants').of('emerald').trainer_classes.byName
  if battle and battle.kinds and battle.kinds.tutorial=='wally'then return ids.TRAINER_PIC_WALLY end
  return gender==1 and ids.TRAINER_PIC_MAY or ids.TRAINER_PIC_BRENDAN
 end
 return gender==1 and Versions.TRAINER_PIC_LEAF or Versions.TRAINER_PIC_RED
end
local PicCoords=require('src.core.game3.battle.pic_coords')
local Anim=require('src.core.game3.battle.anim')
local Scene=V.require('battle/PaperBattleScene')
local TrainerBall=V.require('battle/TrainerBall')
local CatchPresentation=V.require('battle/CatchPresentation')
local SpriteGround=V.require('battle/SpriteGround')
local SpriteRim=V.require('SpriteRim')
-- Older engines retain the verified readback fallback. Patched engines expose
-- the exact native silhouette, including animation frames and Spinda spots.
local shapeOK,SpriteShape=pcall(require,'src.core.game3.sprite_shape')
if not shapeOK then SpriteShape=nil end
local SpriteSize=V.require('battle/SpriteSize')
local PopupActors=V.require('battle/PopupActors')
local OrigamiSpawn=V.require('battle/OrigamiSpawn')
local OrigamiHud=V.require('battle/OrigamiHud')
local MapPopup=V.require('battle/MapPopup')
local PopupDialogue=V.require('battle/PopupDialogue')
local FastIntro=V.require('battle/FastIntro')
local EffectFit=V.require('battle/EffectFit')
local SurfWave=V.require('battle/terrarium/SurfWave')
local DigPresentation=V.require('battle/DigPresentation')
local Slots=V.require('battle/BattleSlots')
local BattleViewport=V.require('battle/terrarium/BattleViewport')
local MonAnim=require('src.core.game3.mon_anim')
local AnimSprites=require('src.core.game3.battle.anim_sprites')
local G=V.require('WorldGeometry')
local C=V.require('DioramaConfig').battle
local function paperPopup(scene)return scene and(scene.paperPopup or scene.edition=='emerald')end
local handSource=[[
     uniform vec2 hand;
     vec4 effect(vec4 color,Image tex,vec2 uv,vec2 sc){
      vec4 p=Texel(tex,uv);
      // Replace only the tiny held-ball area with the closed hand color.
      if(distance(uv*64.0,hand)<2.4)p.rgb=vec3(.94,.71,.52);
      return p*color;
     }
    ]]
local Presentation={};Presentation.__index=Presentation
local sideOf=Slots.key
local function speciesOf(b)return b and(b.expTransform and b.expTransform.species or b.species or b.mon and Pokemon.speciesOf(b.mon))end
local function safeGraphics(fn)
 love.graphics.push('all');local ok,result=pcall(fn);love.graphics.pop()
 if not ok then error(result,0)end;return result
end
local function newCanvas(w,h,dpi,format)
 local c=love.graphics.newCanvas(w,h,{dpiscale=dpi or 1,format=format});c:setFilter('nearest','nearest');return c
end
function Presentation.new(current)
 return setmetatable({current=current,metrics={},sources={},layers={},wrappers={}},Presentation)
end
function Presentation:replacesIntro(record)
 return PopupActors.replacesNativeIntro(record and record.scene,require('src.core.game3.battle')._phase)
end
function Presentation:updateMotion(record,dt)
 if not paperPopup(record.scene)then return end
 if record.scene.fast and record.scene.entry=='battle'and not record.fastIntroPrepared then
  record.fastIntroPrepared=FastIntro.prepare(require('src.core.game3.battle.intro_seq'),record.battle)
 end
 local phase=require('src.core.game3.battle')._phase
 record.spawnMotion=record.spawnMotion or{}
 for _,side in ipairs(Slots.mons(record.battle))do
  local b=Slots.battler(record.battle,side);local motion=record.spawnMotion[side]
  local folded=(record.scene.actorFold and record.scene.actorFold[side])or(record.scene.dialogue and record.scene.dialogue[side])or 0
  local native=Anim.present(Slots.id(side))or{}
  if b and phase=='intro'and folded>=1 and(not record.battle.double or native.visible~=false and(native.scale or 1)>=1)
   and (not motion or motion.battler~=b)and MonAnim.enabled()then
   local sprite=MonAnim.newSprite(speciesOf(b));MonAnim.summary(sprite,speciesOf(b),false)
   motion={battler=b,sprite=sprite,clock=0,age=0};record.spawnMotion[side]=motion
  end
  if motion and not motion.done then
   if (phase~='intro'and phase~='command')or b~=motion.battler then motion.done=true
   else
    motion.clock=motion.clock+math.min(dt or 0,.1);motion.age=motion.age+(dt or 0)
    while motion.clock>=1/60 do motion.clock=motion.clock-1/60;MonAnim.step(motion.sprite)end
    motion.pose=MonAnim.transform(motion.sprite)
    if MonAnim.done(motion.sprite)or motion.age>4 then motion.done=true end
   end
  end
 end
 for side,pop in pairs(record.nativePops or{})do
  pop.age=pop.age+math.min(dt or 0,.1)
  if pop.age>=.45 or pop.battler~=Slots.battler(record.battle,side)then record.nativePops[side]=nil end
 end
 for side,d in pairs(record.dig or{})do
  d.age=d.age+math.min(dt or 0,.1)
  local p=Anim.present(Slots.id(side)or side)
  if not(d.task.active and d.task.name==d.taskName)then
   if p.invisible or p.battlerInvisible or d.phase=='down'then d.phase='hidden'
   elseif d.phase=='up'then d.phase='closing';d.age=0 end
  end
  if d.phase=='closing'and d.age>=.4 or d.battler~=Slots.battler(record.battle,side)then record.dig[side]=nil end
 end
end
local function resolution(record)
 if record and record.scene and(V.require('battle/MapBattleViewport').active(record.scene)or record.scene.pendingMap)then
  local fit=V.require('battle/MapBattleViewport').resolution(record.game)
  if V.require('MobileRenderBudget').active()then return math.min(fit,V.require('battle/BattleResolution').limit())end
  return fit
 end
 return V.require('battle/BattleResolution').sprites(require('src.render.Renderer'):fitScale())
end
local function resized(canvas,w,h,dpi)
 if canvas then
  local pw,ph=canvas:getPixelDimensions()
  if pw==w*dpi and ph==h*dpi then return canvas end
  canvas:release()
 end
 return newCanvas(w,h,dpi)
end
-- Deliberately supersample the logical 240x160 battle target. Only swapping
-- inside the exact owned Display.present scope avoids shrinking the lit actor
-- layers back to GBA resolution before the final window composite. Native UI
-- coordinates, particles, viewport fitting and all input remain unchanged.
function Presentation:presentFrame(prev,game,...)
 local r=self.current()
 if not r or r.game~=game then return prev(game,...)end
 local host=require('src.render.Renderer')
 host:setUISize(240,160)
 self.viewportDim=0;self.viewportMask=nil
 local prior=host.canvas
 self.displayCanvas=resized(self.displayCanvas,240,160,resolution(r))
 local owned=self.displayCanvas;host.canvas=owned
 local transition=require('src.core.game3.battle_transition')
 local mapViewport=V.require('battle/MapBattleViewport').active(r.scene)
 local viewport=Ui.presentationHudVersion==1 and (mapViewport or paperPopup(r.scene)and r.scene.kind=='terrarium')and not transition.isActive()
 local folding=Ui.presentationHudVersion==1 and OrigamiHud.pending(r)and not transition.isActive()
 if viewport or folding then
  self.hudCanvas=resized(self.hudCanvas,240,160,resolution(r))
  safeGraphics(function()love.graphics.setCanvas(self.hudCanvas);love.graphics.clear(0,0,0,0)end)
  self.viewportRecord=viewport and r or nil;self.origamiHudRecord=folding and r or nil
 end
 local ok,result=pcall(prev,game,...)
 self.viewportRecord=nil;self.origamiHudRecord=nil;self.hudPrevious=nil
 if host.canvas==owned then host.canvas=prior end
 if not ok then error(result,0)end
 return result
end
-- Rendering can retire an arena inside Display.present. Stop routing this
-- frame's native HUD through that stale scene before endFrame composes it.
function Presentation:cancelFrame()
 self:restoreCaptureFilters()
 if self.hudPrevious then love.graphics.setCanvas(self.hudPrevious)end
 self.viewportRecord=nil;self.origamiHudRecord=nil;self.hudPrevious=nil;self.layerStamps=nil
end
-- Preserve the rendered world resolution through the supersampled compositor.
function Presentation:background(canvas)
 local dim,br,bg,bb=V.require('battle/MoveLights').backgroundDim(Anim._bgBlend,Anim._vm and Anim._vm.active)
 if dim then require('src.core.game3.battle.ball_open').setBlendShader(dim,br,bg,bb)end
 return canvas
end
function Presentation:measureImage(key,img)
 if self.metrics[key]then return self.metrics[key]end
 local native=img and SpriteShape and SpriteShape.get(img)
 if native then self.metrics[key]=native.metrics;return native.metrics end
 local m={bottom=56,height=48}
 if img then
  local canvas=newCanvas(64,64)
  safeGraphics(function()
   love.graphics.setCanvas(canvas);love.graphics.origin();love.graphics.setShader();love.graphics.setScissor();love.graphics.setDepthMode()
   love.graphics.setBlendMode('alpha','alphamultiply');love.graphics.clear(0,0,0,0)
   love.graphics.setColor(1,1,1,1);love.graphics.draw(img)
  end)
  local data=canvas:newImageData();local top,bottom=64,-1
  for y=0,63 do for x=0,63 do local _,_,_,a=data:getPixel(x,y)
   if a>.5 then top=math.min(top,y);bottom=math.max(bottom,y)end
  end end
  if V.require('DioramaConfig').billboards.rim.enabled then SpriteRim.mask(img,data)end
  data:release();canvas:release()
  if bottom>=top then m={bottom=bottom+1,height=bottom-top+1}end
 end
 self.metrics[key]=m;return m
end
function Presentation:measure(species,form)
 local entry=Pokemon.frontPic(species,form)
 return self:measureImage('mon:'..tostring(species)..':'..tostring(form or 0),entry and entry.image)
end
function Presentation:height(species)
 local dex=Pokemon.dexEntry and Pokemon.dexEntry(species)
 return SpriteSize.height(dex and dex.height,C.spriteHeight)
end
function Presentation:foldSpan(record,side)
 local height=C.trainerHeight
 if not side:find('Trainer')then
  local b=Anim.shownBattler(Slots.id(side)or side,Slots.battler(record.battle,side))or Slots.battler(record.battle,side)
  height=self:height(speciesOf(b))
 end
 return {height=height*(record.scene.scale or 1)}
end
function Presentation:geometry(record,side,species,form)
 side=sideOf(side);if not record.scene.feet[side]then return end
 local m=self:measure(species,form)
 local scale=Scene.spriteHeight(record.scene,side,self:height(species))/m.height
 local x,y=Scene.foot(record.scene,side)
 y=y-(m.bottom-32)*scale
 if self.capturing then self.captureGeometry={x,y,scale}end
 return x,y,scale
end
function Presentation:groundPose(record,side,image,cx,cy,rot,sx,sy,pres,battler)
 if self.capturing then self:captureFilter(image)end
 side=sideOf(side)
 local foot=record.scene.feet[side]
 -- Scale native pixel excursions to the fitted paper sprite, retaining pose
 -- state for the native view. Dig/Fly visibility remains upstream.
 local motionScale=1
 if paperPopup(record.scene)and pres then
  local _,_,s=self:geometry(record,side,speciesOf(battler),0);motionScale=s or 1
  cx=cx+(pres.ox or 0)*(motionScale-1);cy=cy+(pres.oy or 0)*(motionScale-1)
 end
 if not foot or battler and battler.mon and (tonumber(battler.mon.hp)or 1)<=0 then return end
 self.groundOutlines=self.groundOutlines or setmetatable({},{__mode='k'})
 local native=SpriteShape and SpriteShape.get(image)
 local outline=native and native.outline or self.groundOutlines[image]
 if not outline then
  local w,h=image:getDimensions();local canvas=newCanvas(w,h)
  safeGraphics(function()
   love.graphics.setCanvas(canvas);love.graphics.origin();love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setScissor()
   love.graphics.clear(0,0,0,0);love.graphics.setBlendMode('alpha','alphamultiply');love.graphics.setColor(1,1,1,1);love.graphics.draw(image)
  end)
  local data=canvas:newImageData();outline=SpriteGround.outline(data)
  if V.require('DioramaConfig').billboards.rim.enabled then SpriteRim.mask(image,data)end
  data:release();canvas:release()
  self.groundOutlines[image]=outline
 end
 local fx,fy=Scene.foot(record.scene,side)
 local gx,gy=Scene.project(record.scene,foot[1]+8,record.scene.ground and record.scene.ground[side]or 0,foot[2])
 local slope=math.abs(gx-fx)>.001 and (gy-fy)/(gx-fx)or 0
 local bounce=Ui.bounceOffset and Ui.bounceOffset('mon',Slots.id(side))or 0
 local x,y,lift=SpriteGround.animatedCenter(outline,cx,cy,rot,sx,sy,fx,fy,slope,1/resolution(record),pres and(pres.oy or 0)*motionScale,bounce)
 self.spriteTransforms=self.spriteTransforms or{};self.spriteTransforms[side]={image=image,x=x,y=y,rot=rot,sx=sx,sy=sy}
 self.rimTransforms=self.rimTransforms or{};self.rimTransforms[side]=self.spriteTransforms[side]
 if self.capturing then
  local radius=64*math.max(math.abs(sx),math.abs(sy))
  self.capturePose={x-radius,y-radius,x+radius,y+radius}
  self.groundLift=self.groundLift or {};self.groundLift[side]=lift
 end
 return x,y
end
function Presentation:wrap(object,key,fn)
 local prev=object[key];local wrapped=function(...)return fn(prev,...)end
 self.wrappers[#self.wrappers+1]={object,key,prev,wrapped};object[key]=wrapped
end
function Presentation:ballTarget(record,key)
 local side=Slots.key(key or'player');local id=Slots.id(side)
 local x,y=Scene.foot(record.scene,side)
 local b=Anim.shownBattler(id,Slots.battler(record.battle,side))or Slots.battler(record.battle,side)
 return {x,y-Scene.spriteHeight(record.scene,side,self:height(speciesOf(b)))*.25}
end
function Presentation:catchAnchor(record)
 local id=require('src.core.game3.battle.catch_seq')._target or 1
 local side=Slots.key(id);local x,y=Scene.foot(record.scene,side)
 local b=Slots.battler(record.battle,side)
 local _,_,scale=self:geometry(record,side,speciesOf(b),b and b.form or 0)
 local base=(record.battle.double and Coords.DOUBLES or Coords.SINGLES)[id]
 return CatchPresentation.anchor(base,{x,y},scale)
end
function Presentation:drawFittedParticles(record,draw,...)
 local anchors={}
 for _,side in ipairs(Slots.mons(record.battle))do
  local b=Anim.shownBattler(Slots.id(side)or side,Slots.battler(record.battle,side))or Slots.battler(record.battle,side)
  local sp=speciesOf(b);local x,y,scale=self:geometry(record,side,sp,b and b.form or 0)
  local id=Slots.id(side);local base=(record.battle.double and Coords.DOUBLES or Coords.SINGLES)[id]
  local delta=id%2==0 and((PicCoords.back[sp]or 0)+4)or((PicCoords.front[sp]or 0)-(PicCoords.elev[sp]or 0))
  anchors[side]={x,y-delta*scale,scale,base.x,base.y}
  anchors[id]=anchors[side]
  if paperPopup(record.scene)then local fx,fy=Scene.foot(record.scene,side);anchors[side].ground={fx,fy}end
 end
 if record.battle.safari then
  local hand=self.trainerHands.playerTrainer
  local base=Coords.SINGLES[0]
  anchors.player={hand[1],hand[2],hand[3],base.x,base.y};anchors[0]=anchors.player
  -- Emerald's native block starts at the trainer's hand offset (-18,+12),
  -- and lands below the wild sprite (+32), not at either mon's centre.
  local foe=Coords.SINGLES[1];local e=anchors.enemy
  anchors.player.projectiles={POKEBLOCK={
   {hand[1],hand[2],hand[3],base.x-18,base.y+12},
   {e.ground[1],e.ground[2]-4*e[3],e[3],foe.x,foe.y+32},
  }}
 end
 local vm=Anim._vm
 local p=anchors[record.battle.double and vm and vm:attackerId()or 0]or anchors.player
 local e=anchors[record.battle.double and vm and vm:targetId()or 1]or anchors.enemy
 p.all=anchors
 local previous=self.effectTaskAnchors;self.effectTaskAnchors={player=p,enemy=e}
 local result={pcall(EffectFit.draw,AnimSprites._pool,p,e,draw,...)}
 self.effectTaskAnchors=previous
 if not result[1]then error(result[2],0)end
 self.effectFit={count=result[2],playerScale=anchors.player[3],enemyScale=anchors.enemy[3]}
 return unpack(result,3)
end
function Presentation:install()
 self:prepareShaders()
 self.publicBridgeRelease=V.require('battle/PublicPresentation').install(Ui)
 assert(Ui.presentationApiVersion==2 and Ui.drawBattler,'OASC battle presentation engine patch v2 required')
 local owner=self
 -- The native scrolling terrain strip belongs to its flat intro. Drawing
 -- it over an owned 3D arena sweeps grass cutouts across the whole scene.
 if Chrome.drawEntry then self:wrap(Chrome,'drawEntry',function(prev,...)
  if owner.current()then return end
  return prev(...)
 end)end
 local vmClass=require('src.core.game3.battle.anim_vm')
 if vmClass.drawBackground then self:wrap(vmClass,'drawBackground',function(prev,vm)
  if not owner.current()or(vm._animBgId==nil and not(vm._bgFade and vm._bgFade.y>0))then return prev(vm)end
  owner.animationBackground=owner.animationBackground or newCanvas(240,160)
  safeGraphics(function()
   love.graphics.setCanvas(owner.animationBackground);love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode();love.graphics.setShader()
   love.graphics.clear(0,0,0,0);love.graphics.setBlendMode('alpha','alphamultiply');prev(vm)
  end)
  safeGraphics(function()
   love.graphics.setShader();love.graphics.setBlendMode('alpha','premultiplied')
   local a=C.moveLights.animationBackgroundOpacity
   love.graphics.setColor(a,a,a,a);love.graphics.draw(owner.animationBackground,0,0)
  end)
 end)end
 -- Catching also owns native sprite callbacks inside BallOpen.update. Keep
 -- its initial arc and shrink offsets native so live view switches are safe.
 self:wrap(require('src.core.game3.battle.catch_seq'),'update',function(prev,...)
  local st=require('src.core.game3.battle').getState()
  if (GameVersion.get()~='emerald'and not paperPopup(owner.current()and owner.current().scene))or not st then return prev(...)end
  local old,native=owner.effectNativeCoords,owner.nativeCatch
  owner.effectNativeCoords=true;owner.nativeCatch=true
  local result={pcall(prev,...)}
  owner.effectNativeCoords=old;owner.nativeCatch=native
  if not result[1]then error(result[2],0)end
  return unpack(result,2)
 end)
 self:wrap(require('src.core.game3.battle.anim_tasks'),'spawn',function(prev,name,priority,args,vm)
  local task=prev(name,priority,args,vm);local r=owner.current()
  local down=tostring(name):find('DigDownMovement',1,true);local up=tostring(name):find('DigUpMovement',1,true)
  if r and (GameVersion.get()=='emerald'or paperPopup(r.scene))and task and(down or up)then
   local side=sideOf(vm:attackerId());local mode=tonumber(args and args[1])or 0
   r.dig=r.dig or{};r.dig[side]={task=task,taskName=task.name,battler=Slots.battler(r.battle,side),age=0,
    phase=down and(mode==0 and'down'or'hidden')or(mode==0 and'waitingUp'or'up')}
  end
  return task
 end)
 local intro=require('src.core.game3.battle.intro_seq')
 for _,method in ipairs({'push','pushTimed'})do self:wrap(Ui,method,function(prev,text,...)
  local r=owner.current();local d=r and r.scene.dialogue
  if d and owner:replacesIntro(r)then
   if text==intro.introText(r.battle)then PopupDialogue.message(d,'wild')
   elseif text==intro.sendOutText(r.battle,'player')then PopupDialogue.message(d,'go')end
  end
  return prev(text,...)
 end)end
 self:wrap(intro,'update',function(prev,...)
  local r=owner.current();local d=r and r.scene.dialogue
  if d then
   if d.fast and r.scene.cinematic and d.phase=='enemy'and intro._waitingMsg and not Ui.dialogPending()then return false end
   local hold,action=PopupDialogue.beforeNative(d,intro._waitingMsg,Ui.dialogPending())
   if hold then return false end
   if action=='releaseGo'then assert(FastIntro.releaseSendOut(intro,intro.sendOutText(r.battle,'player')),'native send-out message changed')end
  end
  return prev(...)
 end)
 self:wrap(require('src.core.game3.battle.anim_tasks'),'draw',function(prev,...)
  local anchors=owner.effectTaskAnchors;if not anchors then return prev(...)end
  local p,e=anchors.player,anchors.enemy;local args={...}
  local r=owner.current();local replaced={}
  local function localFit()
   local dx=e[1]-p[1];local sx=math.abs(e[4]-p[4])>.001 and dx/(e[4]-p[4])or p[3];local sy=(p[3]+e[3])*.5
   local shear=math.abs(dx)>.001 and(e[2]-p[2]-sy*(e[5]-p[5]))/dx or 0
   love.graphics.translate(p[1],p[2]);love.graphics.shear(0,shear);love.graphics.scale(sx,sy);love.graphics.translate(-p[4],-p[5])
  end
  -- Fit each task separately: a full-arena crest must not inherit another
  -- task's attacker/target shear. Native iteration still owns the Z bands.
  for _,task in ipairs(require('src.core.game3.battle.anim_tasks')._pool or{})do
   if task.active and task.draw then
    local original=task.draw
    local wave=r and r.scene.kind=='terrarium'and paperPopup(r.scene)and SurfWave.matches(task)
    replaced[#replaced+1]={task,original}
    task.draw=function(t,vm)return safeGraphics(function()
     if wave then return SurfWave.draw(r.scene,t,vm)end
     localFit();return original(t,vm)
    end)end
   end
  end
  local result={pcall(prev,unpack(args))}
  for _,saved in ipairs(replaced)do saved[1].draw=saved[2]end
  if not result[1]then error(result[2],0)end
  return unpack(result,2)
 end)
 -- Emerald effects simulate in their original coordinate space in every
 -- view. Only the draw pass fits their trajectories to the current arena.
 -- Scope includes launch-time sprite constructors as well as frame callbacks.
 local VM=require('src.core.game3.battle.anim_vm')
 for _,method in ipairs({'launch','update'})do self:wrap(VM,method,function(prev,...)
  if GameVersion.get()~='emerald'and not paperPopup(owner.current()and owner.current().scene)then return prev(...)end
  local old=owner.effectNativeCoords;owner.effectNativeCoords=true
  local result={pcall(prev,...)};owner.effectNativeCoords=old
  if not result[1]then error(result[2],0)end
  return unpack(result,2)
 end)end
 -- Observe the native faint/return tween. Origami may lengthen this visual
 -- tween; sound, visibility and completion callbacks keep their native order.
 self:wrap(Anim,'tweenStage',function(prev,frames,onStep,onComplete)
  local f=owner.faintCapture
  local r=owner.current()
  if not f and r and r.scene.mapPopup and OrigamiSpawn.enabled()then
   local seq=require('src.core.game3.battle.switch_seq');local step=seq._steps and seq._steps[seq._i]
   if step and step.kind=='withdraw'then
    local d=step.data or{};local side=Slots.key(d.id or d.side or 'player')
    local b=Slots.battler(r.battle,side)
    f={progress=0,battler=b,mon=b and b.mon,kind='recall'}
    r.faints=r.faints or{};r.faints[side]=f
   end
  end
  if not f then return prev(frames,onStep,onComplete)end
  -- Keep the native completion callback as the sole handoff. A paper return
  -- gets enough presentation time to close visibly before that callback.
  if r and r.scene.mapPopup and OrigamiSpawn.enabled()then frames=math.max(frames,48)end
  f.frames=frames
  return prev(frames,function(u,...)
   f.progress=u;if onStep then return onStep(u,...)end
  end,function(...)
   f.complete=true;if onComplete then return onComplete(...)end
  end)
 end)
 self:wrap(Anim,'faintMon',function(prev,key,...)
  local r=owner.current();if not r or(GameVersion.get()~='emerald'and not paperPopup(r.scene)and not(r.scene.mapPopup and OrigamiSpawn.enabled()))then return prev(key,...)end
  local side=sideOf(key or'enemy');local b=Slots.battler(r.battle,side);local f={progress=0,battler=b,mon=b and b.mon,kind='faint'}
  r.faints=r.faints or{};r.faints[side]=f
  local previous=owner.faintCapture;owner.faintCapture=f
  local result={pcall(prev,key,...)};owner.faintCapture=previous
  if not result[1]then error(result[2],0)end
  return unpack(result,2)
 end)
 -- The native intro window is a full-screen black wipe, not HUD ink.
 -- When the paper entrance owns that transition, exposing win0 to the split
 -- HUD compositor turns it into two moving black cards above the arena.
 -- Give drawing a shallow view only; the native stage/clock remains intact.
 self:wrap(Ui,'draw',function(prev,...)
  local prior=owner.drawingPaperIntro;local r=owner.current()
  local scene=r and r.scene
  local mapMask=owner.viewportRecord and V.require('battle/MapBattleViewport').active(scene)
  local nativeStage=mapMask and Anim.stage()
  owner.viewportMask=nativeStage and nativeStage.win0 or nil
  owner.drawingPaperIntro=mapMask or r and(owner:replacesIntro(r)or scene and scene.kind=='terrarium'and scene.entry=='battle'and scene.cinematic)or false
  local result={pcall(prev,...)};owner.drawingPaperIntro=prior
  if not result[1]then error(result[2],0)end
  return unpack(result,2)
 end)
 self:wrap(Anim,'stage',function(prev,...)
  local stage=prev(...)
  if not owner.drawingPaperIntro or not stage or not stage.win0 then return stage end
  local view=owner.introStageView or{};owner.introStageView=view
  for k in pairs(view)do view[k]=nil end
  for k,v in pairs(stage)do if k~='win0'then view[k]=v end end
  return view
 end)
 self:wrap(require('src.core.game3.display'),'present',function(prev,game,...)return owner:presentFrame(prev,game,...)end)
 self:wrap(require('src.ui.game3.ui_pass'),'drawUi',function(prev,...)
  if not owner.viewportRecord and not owner.origamiHudRecord then return prev(...)end
  local args={...}
  return safeGraphics(function()love.graphics.setCanvas(owner.hudCanvas);return prev(unpack(args))end)
 end)
 self:wrap(require('src.ui.game3.help_system'),'draw',function(prev,...)
  if not owner.viewportRecord and not owner.origamiHudRecord then return prev(...)end
  local args={...}
  return safeGraphics(function()love.graphics.setCanvas(owner.hudCanvas);return prev(unpack(args))end)
 end)
 self:wrap(require('src.render.Renderer'),'endFrame',function(prev,host,...)
  local r=owner.viewportRecord
  if not r then
   if owner.origamiHudRecord then safeGraphics(function()
    love.graphics.setCanvas(host.canvas);love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode();love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('alpha','premultiplied')
    OrigamiHud.draw(owner.hudCanvas,owner.origamiHudRecord)
   end)end
   return prev(host,...)
  end
  local hud=owner.hudCanvas
  if owner.origamiHudRecord then
   owner.paperHudCanvas=resized(owner.paperHudCanvas,240,160,resolution(owner.current()))
   safeGraphics(function()
    love.graphics.setCanvas(owner.paperHudCanvas);love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode();love.graphics.clear(0,0,0,0);love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('alpha','premultiplied')
    OrigamiHud.draw(owner.hudCanvas,owner.origamiHudRecord)
   end)
   hud=owner.paperHudCanvas
  end
  require('src.render.GameViewport').setTarget()
  local x,y,w,h=BattleViewport.safeRect(r.game)
  local mapViewport=V.require('battle/MapBattleViewport')
  local layout=mapViewport.active(r.scene)and mapViewport.layout(r.game)or BattleViewport.layout(x,y,w,h,r.scene.windowFitScale)
  owner.viewportLayout=layout
  owner.viewportFullscreen=BattleViewport.fullscreen()
  safeGraphics(function()BattleViewport.draw(owner,host.canvas,hud,layout,owner.viewportFullscreen,host.screenVeil)end)
  host.worldActive=false;host.uprightActive=false;host.worldOverride=nil
  require('src.render.PaletteFX').setPass(nil)
  return {width=layout.w,height=layout.h}
 end)
 local okPopup,popup=pcall(require,'src.ui.game3.map_name_popup')
 if okPopup and popup.draw then self:wrap(popup,'draw',function(prev,...)
  local r=owner.current();if r and paperPopup(r.scene)then return end
  return prev(...)
 end)end
 self.api={frontSprites=true,
  voiceoverDim=function(amount)
   if not owner.viewportRecord then return false end
   owner.viewportDim=amount
   -- Darken only existing HUD ink. Lit healthbox/dialog are drawn afterwards.
   owner.dimCanvas=resized(owner.dimCanvas,240,160,owner.hudCanvas:getDPIScale())
   safeGraphics(function()
    local g=love.graphics;g.origin();g.setShader();g.setScissor();g.setDepthMode()
    g.setCanvas(owner.dimCanvas);g.clear(0,0,0,0)
    g.setBlendMode('replace','premultiplied');g.setColor(1-amount,1-amount,1-amount,1)
    g.draw(owner.hudCanvas)
    g.setCanvas(owner.hudCanvas);g.setColor(1,1,1,1);g.draw(owner.dimCanvas)
   end)
   return true
  end,
  beginHud=function()
   if owner.viewportRecord or owner.origamiHudRecord then owner.hudPrevious=love.graphics.getCanvas();love.graphics.setCanvas(owner.hudCanvas)end
  end,
  endHud=function()
   if owner.hudPrevious then love.graphics.setCanvas(owner.hudPrevious);owner.hudPrevious=nil end
  end,
  poseCenter=function(side,image,cx,cy,rot,sx,sy,pres,battler,id)
   local r=owner.current()
   if r then return owner:groundPose(r,id or side,image,cx,cy,rot,sx,sy,pres,battler)end
  end,
  ballPosition=function(ball)
   local r=owner.current()
   if r and owner:replacesIntro(r)then return -10000,-10000,0 end
   if r then
    local catch=require('src.core.game3.battle.catch_seq')._ball
    if paperPopup(r.scene)and catch and not catch.dead and catch.stage==ball then
     return CatchPresentation.ball(ball,owner.trainerHands.playerTrainer,owner:catchAnchor(r))
    end
    local target=owner:ballTarget(r,Slots.ballId(Anim.stage(),ball))
    if ball.side=='enemy'then return target[1],target[2],math.max(.24,math.min(.45,(r.scene.scale or 1)*.35))end
    local trainer=Slots.trainer(r.battle,Slots.ballId(Anim.stage(),ball))
    return TrainerBall.position(ball,owner.trainerHands and owner.trainerHands[trainer],target)
   end
  end,
  center=function(side,sp,form)if owner.nativeCatch then return end;local r=owner.current();if r then return owner:geometry(r,side,sp,form)end end,
  scale=function(side,sp,form,id)local r=owner.current();if not r then return 1 end;local _,_,s=owner:geometry(r,id or side,sp,form);return s or 1 end,
  drawBattler=function(side,b,id)if owner.capturing then return false end;owner:blit(Slots.key(id or side));return true end,
  drawTrainer=function(side)
   owner:blit(side..'PartnerTrainer');owner:blit(side..'Trainer');return true
  end}
 -- A visual return phase follows native send-out completion. This wrapper
 -- observes the native animation tick; it never schedules battle tasks.
 self:wrap(Anim,'update',function(prev,dt,...)
  local result=prev(dt,...);local r=owner.current()
  if r then OrigamiHud.update(r,dt);MapPopup.update(r,dt,require('src.core.game3.battle')._phase,Anim.stage(),{player=Anim.present('player'),enemy=Anim.present('enemy')})end
  local dialogue=r and r.scene.dialogue
  if dialogue and dialogue.fast and dialogue.phase=='go'and intro._waitingMsg then
   -- Battle.update normally waits for Ui.pump before calling IntroSeq.update.
   -- Release the send-out only after its native typewriter has completed.
   -- The following throw still uses the native animation clock.
   intro.update()
  end
  if r and not r.battle.double and not owner:replacesIntro(r)then
   local stage=Anim.stage();local ball=stage.balls and stage.balls[0]
   if not(ball and ball.visible)then ball=stage.ball end
   local f=r.ballFlight
   if ball and ball.visible and ball.side=='player' and (ball.frame or 0)==0 and (not f or f.caught)then
    f={ball=ball};r.ballFlight=f
   end
   if f and f.age then f.age=f.age+math.max(0,dt or 1/60);f.caught=f.age>=37/60 end
  end
  return result
 end)
 self:wrap(require('src.core.game3.battle.ball_open'),'draw',function(prev,...)
  local r=owner.current();if r and owner:replacesIntro(r)then
   if r.provider.drawIntroOverlay then safeGraphics(function()r.provider.drawIntroOverlay(owner,r)end)end
   return
  end
  local result
  if r and paperPopup(r.scene)and require('src.core.game3.battle.catch_seq').busy()then
   local a=owner:catchAnchor(r);local args={...}
   result=safeGraphics(function()
    love.graphics.translate(a.x,a.y);love.graphics.scale(a.scale,a.scale);love.graphics.translate(-a.nx,-a.ny)
    return prev(unpack(args))
   end)
  else result=prev(...)end
  local f=r and r.ballFlight
  if f and not f.caught then
   local x,y,scale,rot=TrainerBall.returnPosition(f.age,owner.trainerHands and owner.trainerHands.playerTrainer,owner:ballTarget(r))
   if x then
    if Ui.drawBall then safeGraphics(function()
     love.graphics.setDepthMode()
     Ui.drawBall({visible=true,side='return',x=x,y=y,rot=rot,scale=scale,frame=0,ballId=f.ballId or 0})
    end)end
   end
  end
  return result
 end)
 self:wrap(Anim,'ballOpen',function(prev,key,x,y,...)
  local r=owner.current()
  if r and r.battle.double then
   local side=Slots.key(key);local target=owner:ballTarget(r,side);x,y=target[1],target[2]
   r.nativePops=r.nativePops or{};r.nativePops[side]={battler=Slots.battler(r.battle,side),age=0}
  elseif r and not owner:replacesIntro(r)then
   local target=owner:ballTarget(r,key);x,y=target[1],target[2]
   if sideOf(key)=='player'then
    r.ballFlight=r.ballFlight or {};r.ballFlight.age=0;r.ballFlight.caught=false
    r.ballFlight.ballId=Anim.ballIdOf and Anim.ballIdOf(key)or 0
   end
  end
  return prev(key,x,y,...)
 end)
 self:wrap(Anim,'drawParticles',function(prev,...)
  local r=owner.current();if r and owner:replacesIntro(r)then return end
  if r and(GameVersion.get()=='emerald'or paperPopup(r.scene))then return owner:drawFittedParticles(r,prev,...)end
  return prev(...)
 end)
 self:wrap(Coords,'coords',function(prev,st,key)
  local r=owner.current();local base=prev(st,key)
  if owner.effectNativeCoords then return base end
  if not r or(st and st~=r.battle)or not base then return base end
  local id=Coords.idOf(key);if not id or not r.scene.feet[Slots.key(id)]then return base end
  local side=Slots.key(id);local sp=speciesOf(Anim.shownBattler(Slots.id(side)or side,Slots.battler(r.battle,side))or Slots.battler(r.battle,side))
  local x,y=owner:geometry(r,side,sp,0)
  local delta=id%2==0 and((PicCoords.back[sp]or 0)+4)or((PicCoords.front[sp]or 0)-(PicCoords.elev[sp]or 0))
  return {x=x,y=y-delta,x,y-delta}
 end)
 -- Keep the original skin, decoration, text, animated HP/EXP and status icons.
 -- Only its paper/background pixels become translucent and gently light-tinted.
 local nativeFrames=Chrome.drawMenuFrames
 self:wrap(Chrome,'drawPanel',function(prev,...)
  if not owner.current()then return prev(...)end
  -- Emerald adds user-frame windows over the baked panel. Composite these
  -- together before applying opacity, so overlapping fills don't turn solid.
  return owner:skin('panel',function(...)
   prev(...);if nativeFrames then nativeFrames(...)end
  end,...)
 end)
 if nativeFrames then self:wrap(Chrome,'drawMenuFrames',function(prev,...)
  if not owner.current()then return prev(...)end
 end)end
 self:wrap(Healthbox,'draw',function(prev,...)
  if not owner.current()then return prev(...)end
  local r=owner.current();local side,battler,opts=...
  if OrigamiHud.enabled(r)then
   local key=sideOf(side);local stage=Anim.stage();local hb=(stage and stage.healthbox or{})[key]
   owner.paperHealthOptions=owner.paperHealthOptions or{};local adjusted=owner.paperHealthOptions[key]or{};owner.paperHealthOptions[key]=adjusted
   for k in pairs(adjusted)do adjusted[k]=nil end;for k,v in pairs(opts or{})do adjusted[k]=v end
   adjusted.ox=(adjusted.ox or 0)-(hb and hb.ox or 0)
   return owner:skin('health',prev,side,battler,adjusted)
  end
  return owner:skin('health',prev,...)
 end)
end
local skinSource=[[
uniform float alpha;uniform float health;uniform vec3 lightTint;uniform float paperTexture;
float crease(float x){return exp(-abs(fract(x)-.5)*85.0);}

vec4 effect(vec4 color,Image tex,vec2 uv,vec2 sc){
 vec4 p=Texel(tex,uv);vec3 c=p.rgb/max(p.a,.001);
 float paper=smoothstep(.55,.82,min(c.r,min(c.g,c.b)));
 float a=p.a*mix(alpha,mix(1.0,alpha,paper),health);
 vec2 paperPoint=uv*vec2(240.0,160.0);
 float grain=sin(paperPoint.x*2.3+paperPoint.y*1.7)*sin(paperPoint.y*2.1-paperPoint.x*.7);
 float folds=crease(paperPoint.x*.037+paperPoint.y*.051)-crease(paperPoint.x*.037+paperPoint.y*.051+.018);
 float folds2=crease(paperPoint.x*.021-paperPoint.y*.063)-crease(paperPoint.x*.021-paperPoint.y*.063+.016);
 float textureGain=1.0+paperTexture*mix(1.0,paper,health)*(grain*.004+(folds+folds2)*.028);
 return vec4(c*lightTint*textureGain*a,a)*color;
}]]
function Presentation:prepareShaders()
 -- Install runs in the mod loading phase, before interactive battle frames.
 self.skinShader=self.skinShader or V.require('ShaderCompiler').newShader(skinSource)
 self.handShader=self.handShader or V.require('ShaderCompiler').newShader(handSource)
 OrigamiHud.prepare()
 local palette=require('src.core.game3.battle.anim_pal')
 if palette.shader then palette.shader()end
end
function Presentation:skin(kind,fn,...)
 local args={...};self.skinCanvas=self.skinCanvas or newCanvas(240,160)
 safeGraphics(function()
  love.graphics.setCanvas(self.skinCanvas);love.graphics.origin();love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setScissor()
  love.graphics.setBlendMode('alpha','alphamultiply');love.graphics.clear(0,0,0,0);fn(unpack(args))
 end)
 self.skinShader=self.skinShader or V.require('ShaderCompiler').newShader(skinSource)
 safeGraphics(function()
  love.graphics.setShader(self.skinShader);self.skinShader:send('alpha',kind=='panel'and C.panelOpacity or C.healthOpacity)
  self.skinShader:send('health',kind=='health'and 1 or 0)
  self.skinShader:send('paperTexture',OrigamiHud.enabled(self.current())and 1 or 0)
  local tint=self.ambient or{1,1,1};local a=C.skinLightResponse
  self.skinShader:send('lightTint',{1-a+a*tint[1],1-a+a*tint[2],1-a+a*tint[3]})
  love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('alpha','premultiplied')
  -- Original HP skins relocated to the top corners; arena stays unobstructed.
  local dx,dy=0,0
  if kind=='health'then
   local r=self.current()
   if r and r.battle.double then
    local id=Slots.id(args[1]);local center=Healthbox.center(r.battle,id)
    local x,y=Slots.player(id)and 4 or 124,id>=2 and 36 or 6
    dx,dy=x-(center.x-32),y-(center.y-16)
   elseif sideOf(args[1])=='player'then dx,dy=-122,-66 else dx,dy=116,-8 end
  end
  love.graphics.draw(self.skinCanvas,dx,dy)
 end)
end
function Presentation:bind()
 self.drawPrevious=Ui.presentation;if self.current()then Ui.presentation=self.api end
end
function Presentation:unbind()
 if Ui.presentation==self.api then Ui.presentation=self.drawPrevious end;self.drawPrevious=nil
end
-- Trainers here are static native portraits. Retain the source capture while
-- its image, fitted position and target stay unchanged; lighting stays live.
-- Preserve crisp native pixel edges in enlarged paper figures. Restore the native
-- image filter before leaving capture, so original battles/UI keep their pixels.
function Presentation:captureFilter(image)
 if not image or C.spriteSampling=='nearest' then return end
 local filters=self.captureFilters
 if not filters then filters={};self.captureFilters=filters end
 if not filters[image]then
  local min,mag,anisotropy=image:getFilter();filters[image]={min,mag,anisotropy}
  image:setFilter('nearest','nearest')
 end
end
function Presentation:filteredDraw(image,draw)
 self:captureFilter(image)
 local ok,result=pcall(draw)
 self:restoreCaptureFilters()
 if not ok then error(result,0)end
 return result
end
function Presentation:restoreCaptureFilters()
 for image,filter in pairs(self.captureFilters or{})do image:setFilter(unpack(filter))end
 self.captureFilters=nil
end
function Presentation:prepareTrainer(record,side)
 local player=side:sub(1,6)=='player'
 local avatar=side=='playerTrainer'
 local wally=avatar and record.battle.kinds and record.battle.kinds.tutorial=='wally'
 local gender=Slots.trainerGender(record.battle,side)
 local pic
 if record.battle.multi and record.battle.linkGenders and not(record.battle.towerLinkMulti and not player)then
  pic=playerFront(gender)
 elseif avatar then pic=playerFront(gender,record.battle)
 elseif side=='playerPartnerTrainer' then
  local partner=record.battle.partner
  local info=partner and require('src.core.game3.scripting.trainers').info(partner.trainerId)
  pic=info and info.pic
 elseif side=='enemyPartnerTrainer' then pic=record.battle.trainerB and record.battle.trainerB.pic
 else pic=record.battle.trainerPicId end
 -- The shared link controller supplies FR/LG's Red/Leaf portrait IDs even
 -- under Emerald. Resolve those two avatars against the current edition's
 -- front sprites, leaving native battle metadata and Union Room classes alone.
 if side=='enemyTrainer'and record.battle.link and not record.battle.multi and not record.battle.unionRoom
  and GameVersion.get()=='emerald'and(pic==135 or pic==136)then pic=playerFront(pic==136 and 1 or 0)end
 local entry=pic and TrainerPic.front(pic)
 local image=entry and entry.image
 local m=image and self:measureImage('trainer:'..pic,image)
 local foot=record.scene.feet[side];local x,y=Scene.foot(record.scene,side)
 local top=y-Scene.spriteHeight(record.scene,side,C.trainerHeight)
 local scale=m and (y-top)/m.height or 1
 self.trainerHands=self.trainerHands or{}
 if player then
  local portrait
  if wally then portrait='wally'
  elseif not avatar and GameVersion.get()=='emerald'and pic==require('src.core.game3.constants').of('emerald').trainer_classes.byName.TRAINER_PIC_STEVEN then portrait='steven'end
  self.trainerHands[side]=image and TrainerBall.hand(GameVersion.get(),gender,x,y,scale,m.bottom,portrait)or nil
 end
 local hideBall=avatar and not self:replacesIntro(record)and record.ballFlight and not record.ballFlight.caught or false
 if avatar and paperPopup(record.scene)and require('src.core.game3.battle.catch_seq').busy()then
  local catch=require('src.core.game3.battle.catch_seq')._ball
  hideBall=catch~=nil and not catch.dead and catch.stage.visible
 end
 if avatar and record.scene.popupBallThrown and not record.ballFlight then hideBall=true end
 if wally then hideBall=false end -- Wally's original front portrait has an empty hand.
 -- LOVE can clear Canvas contents on a window mode change even when the
 -- scene projection and source Canvas identity are unchanged (same aspect).
 local windowWidth,windowHeight=love.graphics.getDimensions()
 local pixelWidth,pixelHeight=love.graphics.getPixelDimensions()
 local key={self.sources[side],image or false,x,y,scale,m and m.bottom or 0,hideBall,
  windowWidth,windowHeight,pixelWidth,pixelHeight}
 self.trainerCaptures=self.trainerCaptures or{}
 local previous=self.trainerCaptures[side];local unchanged=previous~=nil
 for i,v in ipairs(key)do if not previous or previous[i]~=v then unchanged=false;break end end
 if unchanged then return end
 self:captureFilter(image)
 safeGraphics(function()
  love.graphics.setCanvas(self.sources[side]);love.graphics.origin();love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setScissor()
  love.graphics.setBlendMode('alpha','alphamultiply');love.graphics.clear(0,0,0,0);love.graphics.setColor(1,1,1,1)
  if image then
   if hideBall then
    self.handShader=self.handShader or V.require('ShaderCompiler').newShader(handSource)
    self.handShader:send('hand',TrainerBall.anchor(GameVersion.get(),gender))
    love.graphics.setShader(self.handShader)
   end
   self.rimTransforms=self.rimTransforms or{}
   self.rimTransforms[side]={image=image,x=x,y=y,rot=0,sx=player and -scale or scale,sy=scale,ox=32,oy=m.bottom}
   love.graphics.draw(image,x,y,0,player and -scale or scale,scale,32,m.bottom)
   local iw,ih=image:getDimensions()
   self.bounds[side]={x-math.max(32,iw-32)*scale,y-m.bottom*scale,x+math.max(32,iw-32)*scale,y+(ih-m.bottom)*scale}
  else self.bounds[side]=nil end
 end)
 self.sourceRevisions=self.sourceRevisions or{};self.sourceRevisions[side]=(self.sourceRevisions[side]or 0)+1
 self.trainerCaptures[side]=key
end
-- Choose the texture owner before capture. Intro/front cutouts must not first
-- rasterize the native back/slide sprite into the same full-size target.
function Presentation:introSource(record,side)
 if side:find('Trainer')then return false end
 if record.scene.mapPopup then
  local p=record.scene.actorFold and record.scene.actorFold[side]
  return p and p>0 and(p<1 or side=='enemy'and record.battle.wild and require('src.core.game3.battle')._phase=='intro')
 end
 if not paperPopup(record.scene)then return false end
 local battler=Slots.battler(record.battle,side)
 local faint=record.faints and record.faints[side]
 local pop=record.nativePops and record.nativePops[side]
 local motion=record.spawnMotion and record.spawnMotion[side]
 return self:replacesIntro(record)or pop and pop.battler==battler
  or faint and not faint.complete and faint.battler==battler
  or motion and not motion.done and not faint
  or record.dig and record.dig[side]and not(faint and not faint.complete)
end
function Presentation:prepare(record)
 MapPopup.update(record,0,require('src.core.game3.battle')._phase,Anim.stage(),{player=Anim.present('player'),enemy=Anim.present('enemy')})
 self.bounds=self.bounds or{}
 self:bind();self.capturing=true
 local ok,err=pcall(function()
  for _,side in ipairs(Slots.actorKeys)do
   if record.scene.feet[side]then
    self.sources[side]=resized(self.sources[side],240,160,resolution(record))
    if side:find('Trainer')then self:prepareTrainer(record,side)
    elseif record.scene.actorVisible and record.scene.actorVisible[side]==false then
     if self.battlerCaptures then self.battlerCaptures[side]=nil end
    elseif self:introSource(record,side)then
     if self.battlerCaptures then self.battlerCaptures[side]=nil end
    else
     if self.introCaptures then self.introCaptures[side]=nil end
     if V.require('battle/BattlerCaptureCache').changed(self,record,side,Slots.battler(record.battle,side),Anim.present(Slots.id(side)or side),resolution(record),Ui,Anim)then
     self.sourceRevisions=self.sourceRevisions or{};self.sourceRevisions[side]=(self.sourceRevisions[side]or 0)+1
     self.captureGeometry=nil;self.capturePose=nil
     if self.rimTransforms then self.rimTransforms[side]=nil end
     safeGraphics(function()
      love.graphics.setCanvas(self.sources[side]);love.graphics.origin();love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setScissor()
      love.graphics.setBlendMode('alpha','alphamultiply');love.graphics.clear(0,0,0,0);love.graphics.setColor(1,1,1,1)
      local back=Slots.player(side);local id=Slots.id(side)
      Ui.drawBattler(Slots.battler(record.battle,side),(record.battle.double and Coords.DOUBLES or Coords.SINGLES)[id],back,id)
      local g=self.captureGeometry;local pose=Anim.present(Slots.id(side)or side)or{}
      -- Geometry comes from the native renderer (including its form/transform).
      -- A generous circumscribed square covers affine rotation and stat masks.
      -- Scanline distortion and substitute use native-specific coordinates:
      -- retain the full target for those instead of guessing their bounds.
      if self.capturePose and not pose.hShift then self.bounds[side]=self.capturePose
      elseif g and not pose.hShift and not pose.substitute then
       local radius=64*g[3]*math.abs(pose.scale or 1)*math.max(math.abs(pose.sx or 1),math.abs(pose.sy or 1))
       local cx=g[1]+(pose.ox or 0)
       local cy=g[2]+(pose.oy or 0)+(Ui.bounceOffset and Ui.bounceOffset('mon',Slots.id(side))or 0)
       self.bounds[side]={cx-radius,cy-radius,cx+radius,cy+radius}
      else self.bounds[side]=nil end
     end)
     end
    end
   end
  end
 end)
 self:restoreCaptureFilters();self.capturing=false;self:unbind();if not ok then error(err,0)end
 if record.scene.mapPopup then
  local folding={};for _,side in ipairs{'player','enemy'}do local p=record.scene.actorFold[side];-- Keep the wild cutout planted until the native slide has finished.
   -- Rendering owns this replacement; native timing and attack poses are untouched.
   local wildIntro=side=='enemy'and record.battle.wild and require('src.core.game3.battle')._phase=='intro'
   if p and p>0 and(p<1 or wildIntro)then folding[#folding+1]=side end end
  if #folding>0 then self:prepareIntro(record,folding,'fold')end
 end
end
-- The popup precedes the native send-out. Its cutouts use the current party
-- and trainer portraits, without changing native animation visibility/poses.
function Presentation:prepareIntro(record,sides,mode)
 self.introCaptures=self.introCaptures or{}
 for _,side in ipairs(sides or Slots.mons(record.battle))do
  local b=Anim.shownBattler(Slots.id(side)or side,Slots.battler(record.battle,side))or Slots.battler(record.battle,side)
  local species=speciesOf(b);local picSp,shiny,personality=species,false,nil
  if Ui.picArgs and species then picSp,shiny,personality=Ui.picArgs(b,species)end
  local form=b and b.form or 0
  if Ui.battlerPic then local _,f=Ui.battlerPic(Slots.id(side),b,species);form=f or form end
  local entry=species and Pokemon.frontPic(picSp,form,shiny,personality)
  local motion=mode~='faint'and mode~='fold'and mode~='dig'and record.spawnMotion and record.spawnMotion[side]
  local pose=motion and not motion.done and motion.pose
  if pose and form==0 then entry=MonAnim.framePic(picSp,pose.frame,shiny)or entry end
  local image=entry and entry.image
  if image and self.sources[side]then
   local m=self:measure(picSp,form);local x,y=Scene.foot(record.scene,side)
   local scale=Scene.spriteHeight(record.scene,side,self:height(species))/m.height
   local cx,cy=x,y-(m.bottom-32)*scale;local sx,sy,rot=Slots.player(side)and -scale or scale,scale,0
   if pose then
    rot=pose.rotation or 0;sx=sx*(pose.sx or 1);sy=sy*(pose.sy or 1)
    cx,cy=self:groundPose(record,side,image,cx+(pose.x2 or 0),cy+(pose.y2 or 0),rot,sx,sy,
     {ox=pose.x2,oy=pose.y2},b)
   end
   local digging=mode=='dig'and record.dig and record.dig[side]
   local sample
   if digging then
    local p=Anim.present(Slots.id(side)or side)or{}
    -- Native visible stays false until the entire two-turn script ends.
    -- The up task already cleared invisible and explicitly animates emergence.
    local emerging=digging.phase=='up'or digging.phase=='closing'
    local hidden=p.invisible or p.battlerInvisible or(p.visible==false and not emerging)
    sample=DigPresentation.sample(digging.phase,p.oy,m.height,digging.age,hidden)
    digging.sample=sample;cy=cy+(sample.sink-sample.lift)*scale
   end
   local lw,lh=love.graphics.getDimensions();local pw,ph=love.graphics.getPixelDimensions()
   local stamp={record,self.sources[side],image,cx,cy,rot,sx,sy,sample and sample.visible or not sample,sample and y or false,lw,lh,pw,ph}
   local old=self.introCaptures[side];local same=old~=nil
   for i,v in ipairs(stamp)do if not old or old[i]~=v then same=false;break end end
   if not same then
   safeGraphics(function()
    love.graphics.setCanvas(self.sources[side]);love.graphics.origin();love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setScissor()
    love.graphics.clear(0,0,0,0);love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('alpha','alphamultiply')
    if sample then love.graphics.setScissor(0,0,240,math.max(0,y))end
    if not sample or sample.visible then
    self.spriteTransforms=self.spriteTransforms or{};self.spriteTransforms[side]={image=image,x=cx,y=cy,rot=rot,sx=sx,sy=sy}
    self.rimTransforms=self.rimTransforms or{};self.rimTransforms[side]=self.spriteTransforms[side]
    self:filteredDraw(image,function()love.graphics.draw(image,cx,cy,rot,sx,sy,32,32)end)
   end
   end)
   self.introCaptures[side]=stamp
   self.sourceRevisions=self.sourceRevisions or{};self.sourceRevisions[side]=(self.sourceRevisions[side]or 0)+1
   self.introCaptureMisses=(self.introCaptureMisses or 0)+1
   else self.introCaptureHits=(self.introCaptureHits or 0)+1 end
   local radius=64*math.max(math.abs(sx),math.abs(sy))
   self.bounds[side]={cx-radius,cy-radius,cx+radius,cy+radius}
  end
 end
end
-- Integer logical bounds preserve sampling and leave padding for raster edges.
-- Full-size targets keep native shader coordinates, animations and depth UVs.
function Presentation:region(side)
 local b=self.bounds and self.bounds[side]
 if not b then return 0,0,240,160 end
 local l,t=math.max(0,math.floor(b[1])-2),math.max(0,math.floor(b[2])-2)
 local r,d=math.min(240,math.ceil(b[3])+2),math.min(160,math.ceil(b[4])+2)
 return l,t,math.max(0,r-l),math.max(0,d-t)
end
-- Inverse projection at a fixed world Z. Vertical-corrected paper projection
-- is affine on this plane: even rotated/affine attack poses keep their pixels.
local function plane(m,sx,sy,z,out)
 local u,v=sx/240*2-1,sy/160*2-1
 local a,b=m[1]-u*m[13],m[2]-u*m[14]
 local c,d=m[5]-v*m[13],m[6]-v*m[14]
 local p=-(m[3]-u*m[15])*z-m[4]+u*m[16]
 local q=-(m[7]-v*m[15])*z-m[8]+v*m[16]
 local det=a*d-b*c
 out=out or{};out[1],out[2],out[3]=(p*d-b*q)/det,(a*q-p*c)/det,z;return out
end
-- Use the same current cutout (including Dig clipping and faint folds) as the
-- actor pass. Map and terrarium passes project this silhouette onto their floor.
function Presentation:shadowCasters(record,draw,vp)
 self.shadowMesh=self.shadowMesh or love.graphics.newMesh(G.FORMAT,OrigamiSpawn.COLUMNS*OrigamiSpawn.ROWS*6,'triangles','stream')
 for _,side in ipairs(Slots.actorKeys)do
  local scene=record.scene;local foot=scene.feet[side]
  if foot and self.sources[side]and not(scene.actorVisible and scene.actorVisible[side]==false)then
   local x,y,w,h=self:region(side);local anchor={foot[1],scene.ground[side],foot[2]}
   local fold=scene.actorFold and scene.actorFold[side]or 1;local lean=scene.actorLean and scene.actorLean[side]or 0
   local direction=scene.actorFall and scene.actorFall[side]and -1 or 1
   local transform=OrigamiSpawn.transform(anchor,fold,lean,direction,scene,self:foldSpan(record,side))
   local function p(px,py)return transform(plane(vp or scene.vp,px,py,foot[2]))end
   local vertices={}
   OrigamiSpawn.quads(vertices,G,p,x,y,w,h,1,OrigamiSpawn.active(fold,direction))
   self.shadowMesh:setVertices(vertices);self.shadowMesh:setDrawRange(1,#vertices);draw(self.shadowMesh,self.sources[side])
  end
 end
end
function Presentation:drawLayers(record,shader,vp,depth,w,h,atmosphere,lights)
 self.shaderFeatures=self.shaderFeatures or setmetatable({},{__mode='k'})
 local features=self.shaderFeatures[shader]
 if not features then features={popup=shader:hasUniform('popupSpriteFold')};self.shaderFeatures[shader]=features end
 local sharp=C.spriteScreenResolution~=false
 if sharp then w,h=240*resolution(record),160*resolution(record)end
 -- The shared world shader must keep compatible render-target attachments.
 -- Sharp layers have their own raster size, so retain one matching depth
 -- attachment while sampling the untouched world depth for occlusion.
 local target=love.graphics.getCanvas()
 if type(target)=='table'then target=target[1];if type(target)=='table'then target=target[1]end end
 local format=target and target:getFormat()or 'rgba8'
 local layerDepth=depth
 if sharp then
  layerDepth=self.layerDepth
  if layerDepth and(layerDepth:getWidth()~=w or layerDepth:getHeight()~=h or layerDepth:getFormat()~=depth:getFormat())then
   layerDepth:release();layerDepth=nil
  end
  if not layerDepth then layerDepth=love.graphics.newCanvas(w,h,{dpiscale=1,format=depth:getFormat(),readable=false});self.layerDepth=layerDepth end
 end
 self.ambient=atmosphere.ambient;self.lightCount=lights.count
 self.mesh=self.mesh or love.graphics.newMesh(G.FORMAT,OrigamiSpawn.COLUMNS*OrigamiSpawn.ROWS*6,'triangles','stream')
 for _,side in ipairs(Slots.actorKeys)do
  if record.scene.feet[side]and not(record.scene.actorVisible and record.scene.actorVisible[side]==false)then
   local Cache=V.require('battle/LayerCache')
   self.layerStamps=self.layerStamps or{};self.layerScratch=self.layerScratch or{}
   local stamp=self.layerScratch;stamp.source,stamp.revision=self.sources[side],self.sourceRevisions and self.sourceRevisions[side]
   stamp.vp,stamp.depth,stamp.depthRevision=vp,depth,record.scene.depthRevision
   stamp.w,stamp.h,stamp.ambient,stamp.lights,stamp.lightCount=w,h,atmosphere.ambient,atmosphere.lights,lights.count
   stamp.foot,stamp.ground=record.scene.feet[side],record.scene.ground[side]
   stamp.fall=record.scene.actorFall and record.scene.actorFall[side];stamp.popup=features.popup
   stamp.progress=record.scene.actorFold and record.scene.actorFold[side];stamp.lean=record.scene.actorLean and record.scene.actorLean[side]
   local old=self.layerStamps[side]
   local reuse=record.scene.depthRevision~=nil and old and old.record==record and self.layers[side] and self.layers[side]:getFormat()==format and Cache.same(old.values,stamp)
   if reuse then self.layerHits=(self.layerHits or 0)+1 else
   local layer=self.layers[side]
   if layer and(layer:getWidth()~=w or layer:getHeight()~=h or layer:getFormat()~=format)then layer:release();layer=nil end
   layer=layer or newCanvas(w,h,1,format);self.layers[side]=layer
   local z=record.scene.feet[side][2]
   local progress=record.scene.actorFold and record.scene.actorFold[side]or 1
   local lean=record.scene.actorLean and record.scene.actorLean[side]or 0
   local folding=(progress<1 or lean~=0)and(record.scene.mapPopup or features.popup)
   local geometry=self.layerGeometry or{};self.layerGeometry=geometry
   local stored=geometry[side]
   if not stored then stored={vp={},vertices={},points={{},{},{},{}}};geometry[side]=stored end
   local same=not folding and stored and stored.z==z and stored.vp
   if same then for i=1,16 do if stored.vp[i]~=vp[i]then same=false;break end end end
   local vertices=folding and{}or stored.vertices
   if same then
   elseif folding then
    local x,y,rw,rh=self:region(side)
    local foot={record.scene.feet[side][1],record.scene.ground[side],z}
    local direction=record.scene.actorFall and record.scene.actorFall[side]and -1 or 1
    local transform=OrigamiSpawn.transform(foot,progress,lean,direction,record.scene,self:foldSpan(record,side))
    local function p(sx,sy)return transform(plane(vp,sx,sy,z))end
    OrigamiSpawn.quads(vertices,G,p,x,y,rw,rh,1.8,OrigamiSpawn.active(progress,direction))
   else
    local p=stored.points
    plane(vp,0,0,z,p[1]);plane(vp,240,0,z,p[2]);plane(vp,240,160,z,p[3]);plane(vp,0,160,z,p[4])
    for i=1,6 do
     local j=i==4 and 1 or i==5 and 3 or i==6 and 4 or i;local q=p[j]
     local v=vertices[i]or{};vertices[i]=v
     v[1],v[2],v[3]=q[1],q[2],q[3];v[4],v[5]=(j==2 or j==3)and 1 or 0,(j>=3)and 1 or 0
     v[6],v[7],v[8],v[9]=1.8,0,0,0
    end
   end
   if not same and not folding then stored.z=z;for i=1,16 do stored.vp[i]=vp[i]end end
   self.mesh:setVertices(vertices);self.mesh:setDrawRange(1,#vertices)
   -- This draw shares the world shader with the last map atlas. Bind the
   -- actual sprite texture through the same seam so atlas-only sampling state
   -- cannot quantize this HD canvas to the previous atlas's texel grid.
   self.textureContext=self.textureContext or{}
   self.textureContext.shader=shader
   self.mesh:setTexture(V.require('core/RenderSeams').chain('textureSource',self.sources[side],self.textureContext))
   safeGraphics(function()
    if sharp then
     -- Sample the existing scene depth: keep its raster and lighting, but
     -- rasterize the native sprite once at the final presentation resolution.
     love.graphics.setCanvas({layer,depthstencil=layerDepth});love.graphics.setDepthMode()
     shader:send('battleDepth',depth);shader:send('battleDepthTest',1)
    else
     love.graphics.setCanvas({layer,depthstencil=depth});love.graphics.setDepthMode('lequal',false)
    end
    love.graphics.setScissor();love.graphics.clear(0,0,0,0,false,false)
    local x,y,rw,rh=self:region(side)
    if not folding then love.graphics.setScissor(x*w/240,y*h/160,rw*w/240,rh*h/160)end
    love.graphics.setShader(shader);shader:send('battleSpritePass',1)
    V.require('ActorLighting').bind(shader,record.scene.feet[side][1],record.scene.ground[side],record.scene.feet[side][2])
    local pose=self.rimTransforms and self.rimTransforms[side]
    local native=Anim.present(Slots.id(side)or side)or{}
    -- Scanline/substitute masks are owned by the native animation, not affine.
    SpriteRim.bind(shader,pose and not native.hShift and not native.substitute and pose.image,nil,nil,pose)
    if features.popup then shader:send('popupSpriteFold',folding and 1 or 0)end
    love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('alpha','alphamultiply');love.graphics.draw(self.mesh)
   end)
   shader:send('battleSpritePass',0);shader:send('battleDepthTest',0)
   V.require('ActorLighting').bind(shader);SpriteRim.bind(shader)
   if features.popup then shader:send('popupSpriteFold',0)end
   local row=old or{};self.layerStamps[side]=row;row.record=record;row.values=Cache.copy(stamp,row.values)
   self.layerMisses=(self.layerMisses or 0)+1
   end
  elseif self.layers[side]then self.layers[side]:release();self.layers[side]=nil end
 end
end
function Presentation:blit(side)
 local current=self.current()
 if current and current.scene.actorVisible and current.scene.actorVisible[side]==false then return end
 local layer=self.layers[side];if not layer then return end
 local x,y,w,h=self:region(side);if w==0 or h==0 then return end
 if current and current.scene.actorFold and(current.scene.actorFold[side]or 1)<1 then x,y,w,h=0,0,240,160 end
 local r=self.current();local fold=r and r.scene.actorFold and r.scene.actorFold[side]
 local lean=r and r.scene.actorLean and r.scene.actorLean[side]or 0
 if fold and fold<1 or lean~=0 then x,y,w,h=0,0,240,160 end
 safeGraphics(function()
  -- Preserve native global screen FX/palette shaders at the layer's Z band.
  love.graphics.setDepthMode();love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('alpha','premultiplied')
  local lw,lh=layer:getDimensions()
  self.blitQuad=self.blitQuad or love.graphics.newQuad(0,0,lw,lh,lw,lh)
  self.blitQuad:setViewport(x*lw/240,y*lh/160,w*lw/240,h*lh/160,lw,lh)
  love.graphics.draw(layer,self.blitQuad,x,y,0,240/lw,160/lh)
 end)
end
function Presentation:lights(record,atmosphere)
 self.battleLightCount=0;self.moveLightCount=0
 if not C.lightsEnabled then return end
 local time=V.require('DayNight').gameSeconds(record.game)
 for _,side in ipairs(Slots.mons(record.battle))do
  local b=Anim.shownBattler(Slots.id(side)or side,Slots.battler(record.battle,side))or Slots.battler(record.battle,side)
  local pres=Anim.present(Slots.id(side)or side)
  local dig=record.dig and record.dig[side]
  local present=dig and dig.sample and dig.sample.visible or not dig and not(pres and(pres.visible==false or pres.invisible or pres.battlerInvisible))
  if C.flameSpecies[speciesOf(b)]and present then
   local power=dig and dig.sample and(1-dig.sample.depth)^2 or 1
   local foot=record.scene.feet[side];local scene=record.scene
   local x,y,z=foot[1],(scene.ground and scene.ground[side]or 0)+self:height(speciesOf(b))*.5*(scene.scale or 1),foot[2]
   local fx,fy=V.require('battle/FlameAnchor').screen(speciesOf(b),self.spriteTransforms and self.spriteTransforms[side])
   if fx then
    local vp=Scene.matrix(nil,scene.focus.px,scene.focus.py,nil,240,160,scene)
    local pt=plane(vp,fx,fy,z)
    if scene.actorFold then pt=OrigamiSpawn.point(pt,{foot[1],scene.ground and scene.ground[side]or 0,z},scene.actorFold[side]or 1,scene.actorLean and scene.actorLean[side]or 0,scene.actorFall and scene.actorFall[side]and -1 or 1,scene,self:foldSpan(record,side))end
    x,y,z=unpack(pt)
   end
   if scene.actorVisible and scene.actorVisible[side]==false then power=0 end
   local localFlame=V.require('battle/FlameAnchor').points[speciesOf(b)]~=nil
   atmosphere.lights[#atmosphere.lights+1]={kind='battle',flameLight=true,x=x,y=y,z=z,radius=-(localFlame and 20*(scene.scale or 1)or C.flameRadius),
    power=(localFlame and .50 or C.flamePower)*power*(1+.035*math.sin(time*7)),color={1,.56,.24},falloff=2}
   self.battleLightCount=self.battleLightCount+1
  end
 end
 local collect=function()
  self.moveLightCount=V.require('battle/MoveLights').collect(require('src.core.game3.battle.anim_sprites')._pool,record.scene,atmosphere,Anim._vm,self.effectTaskAnchors)
 end
 if self.drawFittedParticles and(require('src.core.GameVersion').get()=='emerald'or record.scene.paperPopup)then self:drawFittedParticles(record,collect)else collect()end
 self.battleLightCount=self.battleLightCount+self.moveLightCount

end
function Presentation:contacts(record)
 safeGraphics(function()
  love.graphics.setShader()
  for side in pairs(record.scene.feet)do
   local p=Anim.present(Slots.id(side)or side)or{}
   local present=side:find('Trainer')or not(p.visible==false or p.invisible or p.battlerInvisible)
   if record.scene.actorVisible and record.scene.actorVisible[side]==false then present=false end
   if record.dig and record.dig[side]then present=false end
   if present then local x,y=Scene.foot(record.scene,side)
    local size=record.scene.contactScale or 1
    for i=3,1,-1 do love.graphics.setColor(0,0,0,C.contactOpacity/3);love.graphics.ellipse('fill',x,y,(7+i)*size,(1+i*.5)*size)end
   end
  end
 end)
end
function Presentation:release()
 self:restoreCaptureFilters()
 OrigamiHud.release()
 SurfWave.release()
 self:unbind()
 for i=#self.wrappers,1,-1 do local w=self.wrappers[i];if w[1][w[2]]==w[4]then w[1][w[2]]=w[3]end end
 self.wrappers={}
 if self.publicBridgeRelease then self.publicBridgeRelease();self.publicBridgeRelease=nil end
 for _,group in ipairs({self.sources,self.layers})do for k,v in pairs(group)do v:release();group[k]=nil end end
 for _,key in ipairs({'layerDepth','skinCanvas','skinShader','handShader','mesh','shadowMesh','displayCanvas','backgroundCanvas','animationBackground','blitQuad','hudCanvas','dimCanvas','paperHudCanvas','viewportQuad'})do if self[key]then self[key]:release();self[key]=nil end end
 self.bounds=nil;self.introCaptures=nil;self.battlerCaptures=nil;self.trainerCaptures=nil;self.trainerHands=nil;self.groundOutlines=nil;self.groundLift=nil
 self.metrics={};self.sourceRevisions=nil;self.layerStamps=nil;self.layerScratch=nil;self.captureScratch=nil;self.layerGeometry=nil
end
return Presentation
