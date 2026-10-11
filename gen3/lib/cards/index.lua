-- One registration entry per Card. No other module imports Card definitions.
local V=...
local Index={
 {module='cards/Gen3PaperBattleCard',service='battle'},
 {module='cards/RenderSeamsCard'},
 -- Grass displacement is withheld from this RC: moving cutouts expose dark seams.
 {module='cards/PaperCutCard'},
 {module='cards/PaperSurfaceCard'},
 {module='cards/ParticlesCard'},
 {module='cards/LampIgnitionCard'},
 {module='cards/SkyLifeCard'},
 {module='cards/GeometryFxaaCard'},
 {module='cards/AtlasMipmapsCard'},
 {module='cards/WaterTouchCard'},
 {module='cards/StormDramaCard'},
 {module='cards/ColorScriptCard'},
 -- Extra field camera lead/dialog zoom/city pullout are disabled for this RC.
 {module='cards/HorizonCard'},
 {module='cards/FoldTransitionsCard'},
 {module='cards/PaperUiCard'},
 {module='cards/PhotoModeCard'},
 {module='cards/FieldZoomCard'},
}
function Index.options(schema)
 for _,entry in ipairs(Index)do
  local card=V.require(entry.module);entry.card=card
  if card.option then
   local spec={};for k,v in pairs(card.option)do spec[k]=v end
   local config=V.require('DioramaConfig');local profile=V.mod.options:get('gen3Quality')or config.settings.defaultPreset
   local p=config.settings.presets[profile];local key=spec.key:match('^gen3Card_(.+)$')
   local wanted=p and p.cards and p.cards[key]
   if type(wanted)=='boolean'then spec.default=wanted end
   schema[#schema+1]=spec
  end
  for _,extra in ipairs(card.options or {})do
   local spec={};for k,v in pairs(extra)do spec[k]=v end
   schema[#schema+1]=spec
  end
 end
end
function Index.register(registry,services)
 for _,entry in ipairs(Index)do
  local card=V.require(entry.module)
  assert(registry:register(card.descriptor(entry.service and services[entry.service]or V)))
 end
end
function Index.apply(registry)
 local wanted={};for _,entry in ipairs(Index)do
  local card=entry.card or V.require(entry.module);entry.card=card
  wanted[card.ID]=not card.option or V.require('EffectSettings').cardValue(card.option.key,V.mod.options:get(card.option.key))~=false
 end
 -- A disabled provider must not be implicitly resurrected by its consumers.
 local changed=true
 while changed do
  changed=false
  for id,on in pairs(wanted)do if on then
   for _,dependency in ipairs(registry.cards[id].card.requires)do
    if wanted[dependency]==false then wanted[id]=false;changed=true;break end
   end
  end end
 end
 local errors={}
 for i=#registry.activationOrder,1,-1 do
  local id=registry.activationOrder[i]
  if not wanted[id]then local ok,err=registry:deactivate(id,nil,'option disabled');if not ok then errors[#errors+1]={id=id,error=err}end end
 end
 for _,entry in ipairs(Index)do if wanted[entry.card.ID]then
  local ok,err=registry:activate(entry.card.ID);if not ok then errors[#errors+1]={id=entry.card.ID,error=err}end
 end end
 return {errors=errors}
end
return Index
