-- One FR/LG provider dispatches each scene to shared paper art or Kanto art.
-- Keep the exact provider with the scene across live view changes.
local V=...
local H=V.require('battle/terrarium/KantoPaperHabitats')
local S={};local used={}
function S.create(game,battle)
 local id,def=V.require('WorldAdapter').current(game)
 local profile=H.resolveBattle(id,def,battle)
 local key=profile and'battle/terrarium/EmeraldScene'or'battle/terrarium/Scene'
 local provider=V.require(key);used[provider]=true
 local scene,reason=provider.create(game,battle)
 if scene then
  scene.kantoProvider=provider
  scene.weatherMap={id=id,def=def}
 end
 return scene,reason
end
function S.render(game,scene,width,height,...)
 local p=assert(scene.kantoProvider)
 local result,reason=p.render(game,scene,width,height,...)
 -- Terrarium providers do not pass through the field Renderer/WorldRain.
 -- Composite the existing battle weather before the separate native HUD.
 -- Weather owns the outdoor/disabled guards and the shared, advancing clock.
 if result then
  local w,h=result:getDimensions()
  result=V.require('Weather').applyBattle(result,w,h,scene.weatherMap,h/height)
 end
 S.stats=p.stats or{map=scene.map,edition=scene.edition,mode='terrarium',artStatus='kanto-authored'}
 return result,reason
end
function S.update(game,scene,dt)
 local p=scene.kantoProvider
 if p.update then return p.update(game,scene,dt)end
 return false
end
for _,name in ipairs({'enter','leave','wheel','preference','camera'})do
 local method=name
 S[method]=function(scene,...)
  if not scene then return end -- native view retains the provider, not a scene
  local p=scene.kantoProvider
  if p[method]then return p[method](scene,...)end
 end
end
function S.drawIntroOverlay(presentation,record)
 local p=record.scene.kantoProvider
 if p.drawIntroOverlay then return p.drawIntroOverlay(presentation,record)end
end
function S.release()
 for p in pairs(used)do p.release()end
 used={};S.stats=nil
end
return S
