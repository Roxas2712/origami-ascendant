-- The only engine-dependent part of the Card. It never patches battle start,
-- update, commands, terrain selection, HP, parties, collision or saved state.
local V=...
local Battle=require('src.core.game3.battle')
local Background=require('src.core.game3.battle.bg')
local Scene=V.require('battle/PaperBattleScene')
local Views=V.require('battle/BattleViews')
local Adapter={}
Adapter.__index=Adapter

function Adapter.new(deps)
  local self=setmetatable({deps=deps,installed=false,starts=0,finishes=0,failures=0},Adapter)
  self.presentation=V.require('battle/PaperBattlePresentation').new(function()
    local r=self.active
    if self.installed and r and r.scene and Battle.isActive()
      and rawequal(Battle.getState(),r.battle)and self.deps.owns(r.game)then return r end
  end)
  self.public={schema='ascendant.paper-battle.gen3/v1',apiVersion=1,
    health=function()return self:health()end,toggle=function(game)return self:toggle(game)end,
    select=function(game,view)return self:select(game,view)end,choices=Views.choices}
  return self
end

function Adapter:health()
  return {ok=self.installed and self.error==nil and not(self.active and self.active.failed),state=not self.installed and 'retired'
      or self.active and (self.active.scene and self.active.view or 'native') or 'idle',
    starts=self.starts,finishes=self.finishes,failures=self.failures,
    reason=self.active and self.active.reason or self.error,
    map=self.active and self.active.scene and self.active.scene.map}
end

function Adapter:update(game)
  if not self.installed then return end
  local st=Battle.isActive() and Battle.getState() or nil
  if not self.deps.owns(game) then st=nil end
  if self.active and (not rawequal(self.active.battle,st) or not rawequal(self.active.game,game))then
    if self.active.provider and self.active.provider.leave then self.active.provider.leave(self.active.scene)end
    self.active=nil;self.finishes=self.finishes+1
  end
  if not st or self.active then return end
  local record={game=game,battle=st,scenes={}}
  self.active=record;self.starts=self.starts+1
  if self.deps.mode()=='off' or Views.preference()=='native' then
    record.reason='disabled at battle start'
  else self:enable(record,Views.preference(),'battle')end
end

function Adapter:enable(record,view,entry)
  local st=record.battle
  local c=V.require('DioramaConfig').battle
  view=view or 'paper'
  local emeraldTerrarium=view=='terrarium'and require('src.core.GameVersion').get()=='emerald'
  local wally=emeraldTerrarium and st.kinds and st.kinds.tutorial=='wally'
  local link=emeraldTerrarium and st.link
    and(not st.multi or st.double and st.linkGenders and st.linkSeatOf
      and(not st.towerLinkMulti or st.trainerPicId~=nil and st.trainerB and st.trainerB.pic~=nil))
  if not Views.allowed(view)then return nil,'no terrariums for this edition'end
  if self.error then record.reason='renderer failure: '..self.error
  elseif not c.enabled then record.reason='card disabled'
  elseif Battle._headless or(st.double and(view~='terrarium' or require('src.core.GameVersion').get()~='emerald' or require('src.core.game3.battle.ui').presentationSlotsVersion~=1)) or st.ghostBattle or(st.safari and(view~='terrarium' or require('src.core.GameVersion').get()~='emerald')) or(st.tutorial and not wally)
    or st.oldManTutorial or st.pokedude or(st.link and not link)or(st.multi and not link)or(st.kinds and((st.kinds.tutorial and not wally)or st.kinds.recordedLink)) then
    record.reason='special battle uses native presentation'
  elseif view=='paper' and self.deps.supportsMap and not self.deps.supportsMap(record.game) then record.reason='map uses native presentation'
  elseif Background._backgroundId==10 and not link then record.reason='link battle uses native presentation'
  else
    local provider=Scene
    if view=='terrarium'then
      local key=Views.terrariumProvider()
      self.terrariumProviders=self.terrariumProviders or {}
      self.terrariumProviders[key]=self.terrariumProviders[key] or V.require(key)
      provider=self.terrariumProviders[key]
    end
    local scene=record.scenes[view]
    if not scene then
      local ok,result,reason=pcall(provider.create,record.game,st)
      if not ok then self:failed(result,true);return nil,tostring(result) end
      scene=result;record.reason=reason
      if scene then record.scenes[view]=scene end
    end
    if scene and scene.pendingMap then
      -- Build the requested map while the current battle presentation remains
      -- authoritative. A field Renderer.lastFrame is never a battle frame.
      record.pendingView=view
      if not record.scene then record.scene,record.provider,record.view=scene,provider,view end
      return view
    end
    if scene then
      record.pendingView=nil
      local changed=record.scene~=scene
      if changed and record.provider and record.provider.leave then record.provider.leave(record.scene)end
      record.scene,record.provider,record.view,record.reason,record.failed=scene,provider,view,nil,nil
      if changed and provider.enter then provider.enter(scene,entry or 'switch')end
      return view
    end
    -- A completed cold build may still have no safe formation. Retire its
    -- loading cover so the native battle can continue instead of staying black.
    if record.pendingView==view then
      record.pendingView=nil
      if record.scene and record.scene.pendingMap then
        record.scene=nil;record.provider=nil;record.view='native'
      end
    end
  end
  return nil,record.reason
end

-- Only the optional Emerald opening holds native updates. No battle table is
-- edited: an in-flight move resumes at the same native frame after the reveal.
function Adapter:tick(game,dt)
  self:update(game)
  local r=self.active
  if r and r.pendingView then
    -- Re-evaluate readiness, rather than retaining the map-loading sentinel.
    local view=r.pendingView;r.scenes[view]=nil
    self:enable(r,view)
  end
  if not r or not r.scene or not r.provider.update then return false end
  local ok,hold=pcall(r.provider.update,game,r.scene,dt)
  if not ok then self:failed(hold);return false end
  if not hold then
    local motionOk,err=pcall(self.presentation.updateMotion,self.presentation,r,dt)
    if not motionOk then self:failed(err);return false end
  end
  return hold
end

-- Changing presentation never restarts combat or advances its native clock.
-- Each fitted arena is retained for the exact battle, including live F6/5 use.
function Adapter:select(game,view)
  if not self.installed or not self.deps.owns(game) or not Views.allowed(view)then return nil end
  self:update(game)
  local r=self.active
  if not r or r.game~=game then return nil end
  r.pendingView=nil
  if view=='native'then if r.provider and r.provider.leave then r.provider.leave(r.scene)end;r.nativePops=nil;r.scene=nil;r.view='native';r.reason='native view selected';return view end
  return self:enable(r,view)
end
function Adapter:toggle(game)
  if not self.installed or not self.deps.owns(game)then return nil end
  self:update(game)
  local r=self.active;if not r then return nil end
  local choices=Views.choices();local current=r.scene and r.view or 'native';local at=1
  for i,c in ipairs(choices)do if c[2]==current then at=i end end
  for offset=1,#choices-1 do
    local selected=self:select(game,choices[(at+offset-1)%#choices+1][2])
    if selected then return selected end
  end
end

function Adapter:failed(err,recoverable)
  local reason=tostring(err);self.failures=self.failures+1
  -- A changed map invalidates this arena, not the renderer for later battles.
  if not recoverable then self.error=reason end
  self.presentation:cancelFrame()
  if self.active then if self.active.provider and self.active.provider.leave then self.active.provider.leave(self.active.scene)end;self.active.pendingView=nil;self.active.scene=nil;self.active.reason=reason;self.active.failed=true
    if recoverable and self.active.view then self.active.scenes[self.active.view]=nil end
  end
  V.mod.log:warn('Paper battle Card fell back to native: %s',reason)
end

function Adapter:install()
  if self.installed then return true end
  self.presentation:install()
  self.installed=true;self.error=nil
  local previousDraw,previousBackground=Battle.draw,Background.draw
  self.previousDraw,self.previousBackground=previousDraw,previousBackground
  self.drawWrapper=function(game,w,h,...)
    if not self.installed or not self.deps.owns(game) then return previousDraw(game,w,h,...) end
    self:update(game)
    local record=self.active
    local canvas
    if record and record.scene then
      love.graphics.push('all')
      local ok,result,reason=pcall(record.provider.render,game,record.scene,w or 240,h or 160,self.presentation,record)
      love.graphics.pop()
      if ok and result then canvas=result
      else self:failed(ok and (reason or 'no scene canvas') or result,ok and reason=='map changed during battle')end
    end
    if canvas and record.scene.cinematic and not record.scene.nativeIntroVisible then
      love.graphics.push('all');love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setScissor()
      love.graphics.setBlendMode('alpha','premultiplied')
      if (record.scene.paperPopup or record.scene.edition=='emerald')and record.scene.kind=='terrarium'then
        love.graphics.setColor(0,0,0,1);love.graphics.rectangle('fill',0,0,w or 240,h or 160)
      end
      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(canvas,0,0,0,(w or 240)/canvas:getWidth(),(h or 160)/canvas:getHeight())
      love.graphics.pop();return true
    end
    -- Narrow dynamic scope: outside this exact native draw Background.draw
    -- remains byte-for-byte native (including other mods and headless tests).
    self.drawing=canvas and {canvas=canvas,record=record,width=w or 240,height=h or 160} or nil
    self.presentation:bind()
    local ok,result=pcall(previousDraw,game,w,h,...)
    self.presentation:unbind()
    self.drawing=nil
    if not ok then error(result,0)end -- Never hide native battle errors.
    return result
  end
  self.backgroundWrapper=function(...)
    local draw=self.drawing
    if not self.installed or not draw or draw.record~=self.active
      or not rawequal(Battle.getState(),draw.record.battle)then return previousBackground(...)end
    -- Preserve native palette flashes, screen shaders, intro and attack
    -- translations. The scenery is substituted at precisely the native pass.
    love.graphics.push('all')
    love.graphics.setDepthMode()
    love.graphics.setBlendMode('alpha','premultiplied')
    if (draw.record.scene.paperPopup or draw.record.scene.edition=='emerald')and draw.record.scene.kind=='terrarium'then
      love.graphics.push('all');love.graphics.setShader();love.graphics.setColor(0,0,0,1)
      love.graphics.rectangle('fill',0,0,draw.width,draw.height);love.graphics.pop()
    end
    -- Native palette shaders return straight RGB. With an alpha silhouette
    -- they must not paint their white blend into the empty canvas margin.
    if (draw.record.scene.paperPopup or draw.record.scene.edition=='emerald')and draw.record.scene.kind=='terrarium'
      and love.graphics.getShader and love.graphics.getShader()then
      love.graphics.setBlendMode('alpha','alphamultiply')
    end
    local background=self.presentation:background(draw.canvas)
    love.graphics.draw(background,0,0,0,draw.width/background:getWidth(),draw.height/background:getHeight())
    self.presentation:contacts(draw.record)
    love.graphics.pop()
    return true
  end
  Battle.draw=self.drawWrapper;Background.draw=self.backgroundWrapper
  return true
end

function Adapter:release()
  self.installed=false;self.drawing=nil;self.active=nil
  self.presentation:release()
  for _,provider in pairs(self.terrariumProviders or{})do provider.release()end
  self.terrariumProviders=nil
  -- Don't remove a wrapper installed later by another owner. Our retained
  -- links become inert, so its nextFn can still safely reach native rendering.
  if Battle.draw==self.drawWrapper then Battle.draw=self.previousDraw end
  if Background.draw==self.backgroundWrapper then Background.draw=self.previousBackground end
end
return Adapter
