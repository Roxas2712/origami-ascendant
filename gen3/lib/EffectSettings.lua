-- One source of truth: normal persisted mod options; config is the live view.
local V=...
local S={manualCards={}}
local focusDefaults
local keys={godRays='gen3GodRays',enabled='gen3Voxel',perspective='gen3Perspective',dof='gen3Dof',bloom='gen3Bloom',vignette='gen3Vignette',lights='gen3Lights',shadows='gen3Shadows',scenery='gen3Scenery',upright='gen3Upright',cycle='gen3Daytime',neighbors='gen3Neighbors'}
local function presetValue(p,field)
 local v=p[field];if field=='bloom'then return v==true or v=='night'end;return v
end
local function value(k,default)local v=V.mod.options:get(k);if v==nil then return default end return v end
function S.apply()
 local c=V.require('DioramaConfig');local profile=value('gen3Quality',c.settings.defaultPreset)
 local selected=c.settings.presets[profile]or c.settings.presets.high
 local active=profile
 if selected.scenePresets and S.game and S.game.data then
  local id=require('src.core.game3.map').current
  local def=id and S.game.data.maps[id]
  if def and tonumber(def.mapType)==4 then active=selected.scenePresets.cave or active
  elseif def and V.data('Shapes').outdoors(def)then
   local night=V.require('TimeOfDay').sample(V.require('DayNight').time()).night or 0
   if night>=.5 then active=selected.scenePresets.night or active end
  end
 end
 local p=c.settings.presets[active]or selected
 local contextChanged=S.selected~=profile or S.effective~=active
 S.selected,S.effective=profile,active
 local upright=value('gen3Upright',p.upright)
 c.camera.projection=value('gen3Perspective',p.perspective)and 'perspective'or 'orthographic'
 c.billboards.footLighting.enabled=p.actorFoot==true
 c.billboards.rim.enabled=(p.actorRim or 0)>0;c.billboards.rim.strength=p.actorRim or 0
 c.billboards.enabled=upright;c.terrain.enabled=upright;c.grass.enabled=upright
 c.post.depthOfField=value('gen3Dof',p.dof);c.post.bloom=value('gen3Bloom',presetValue(p,'bloom'));c.post.bloomNightOnly=p.bloom=='night'
 if not focusDefaults then focusDefaults={};for k,v in pairs(c.post.coc)do focusDefaults[k]=v end end
 for k,v in pairs(focusDefaults)do if k~='enabled'then
  local selected=p.focus and p.focus[k];c.post.coc[k]=selected==nil and v or selected
 end end
 S.focusNear,S.focusFar=c.post.coc.near,c.post.coc.far
 c.post.coc.enabled=p.coc==true
 c.atmosphere.godRays.enabled=p.godRays==true and value('gen3GodRays',true)
 c.post.aces=p.aces==true;c.post.lutAmount=p.lutAmount or 0
 c.post.hdr=p.hdr==true;c.post.bloomMips=p.bloomMips or 1;c.post.dither=p.dither==true
 c.post.vignette=value('gen3Vignette',p.vignette);c.shadows.enabled=value('gen3Shadows',p.shadows)
 c.lighting.enabled=value('gen3Lights',p.lights)
 c.lighting.transmission.enabled=(p.transmission or 0)>0;c.lighting.transmission.strength=p.transmission or 0
 c.lighting.hemisphere.enabled=(p.hemisphere or 0)>0;c.lighting.hemisphere.amount=p.hemisphere or 0
 c.atmosphere.aerial.enabled=(p.aerial or 0)>0;c.atmosphere.aerial.amount=p.aerial or 0
 c.water.sparklesEnabled=value('gen3Scenery',p.scenery);c.fireflies.enabled=c.water.sparklesEnabled
 c.settings.battleResolution=p.battleResolution or 4
 c.settings.renderScale=p.scale;c.settings.maxLights=p.maxLights;c.settings.fireflyBudget=p.fireflies
 c.settings.shadowScale=p.shadowScale or .5;c.settings.shadowSoftness=p.shadowSoftness or 1
 c.post.blurRadius=p.blurPasses;c.fireflies.count=p.fireflies
 c.cycle.speed=value('gen3ClockSpeed',1)
 if contextChanged and S.cardsChanged then S.cardsChanged()end
end
-- Context changes are render-only: never rewrite the user's persisted preset.
-- Explicit edits win; otherwise Cards follow the selected day/night/cave look.
function S.cardValue(key,stored)
 local c=V.require('DioramaConfig');local base=c.settings.presets[S.selected]
 local active=c.settings.presets[S.effective];local name=key:match('^gen3Card_(.+)$')
 if not base or not active or base==active or not name then return stored end
 local default=base.cards and base.cards[name]
 if type(default)~='boolean'or S.manualCards[key]~=nil or (stored~=nil and stored~=default)then return stored end
 local policy=active.cards and active.cards[name]
 if policy==nil then return true end
 return type(policy)=='table'and policy.enabled~=false or policy==true
end
function S.preset(name,game)
 local c=V.require('DioramaConfig');local p=assert(c.settings.presets[name],'unknown quality preset')
 local menu=V.require('Menu')
 S.manualCards={}
 -- Persist one complete transaction, never a half-applied preset.
 local proxy=setmetatable({writeOptions=function()end},{__index=game})
 for field,key in pairs(keys)do menu.settings[key]:setValue(presetValue(p,field),proxy,true)end
 menu.settings.gen3Finish:setValue(p.enabled,proxy,true)
 menu.settings.gen3Fireflies:setValue(p.scenery and 'all'or'off',proxy,true)
 menu.settings.gen3Quality:setValue(name,proxy,true)
 -- Preset selection resets these switches once; subsequent manual edits stick.
 for card in pairs(c.settings.presets.crisp.cards)do
  local setting=menu.settings['gen3Card_'..card]
  if setting then
   local v=p.cards and p.cards[card];if v==nil then v=true end
   setting:setValue(type(v)=='table'and v.enabled~=false or v==true,proxy,true)
  end
 end
 if game.writeOptions then game:writeOptions()elseif game.persistOptions then game:persistOptions()end
 S.apply();if S.cardsChanged then S.cardsChanged()end;V.require('Renderer').invalidate()
end
function S.custom()
 local c=V.require('DioramaConfig');local p=c.settings.presets[value('gen3Quality',c.settings.defaultPreset)]or c.settings.presets.high
 for field,key in pairs(keys)do if value(key,presetValue(p,field))~=presetValue(p,field)then return true end end
 for card,wanted in pairs(p.cards or{})do if type(wanted)=='boolean'and value('gen3Card_'..card,wanted)~=wanted then return true end end
 return false
end
function S.changed(key,val,game)
 if key:match('^gen3Card_')then S.manualCards[key]=val end
 if key=='gen3Quality'and game then S.preset(val,game)else S.apply()end
end
return S
