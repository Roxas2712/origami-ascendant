local Card={ID='oasc.gen3.render-seams',VERSION='1.0.0',CAPABILITY='ascendant.render-seams.gen3/v1'}
Card.option={key='gen3Card_renderSeams',label='RENDER-CARDS',type='toggle',default=true,
 help='Schaltet die zusaetzlichen Render-Cards samt eigener Ressourcen an/aus.'}
function Card.descriptor(V)
 local S=V.require('core/RenderSeams')
 local cfg=V.require('DioramaConfig')
 local function release()S.run('release');S.enable(false);if cfg.cards then cfg.cards.renderSeams=nil;if not next(cfg.cards)then cfg.cards=nil end end;return true end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',
  requires={},optionalRequires={},consumes={},provides={Card.CAPABILITY},
  tests={'tests/gen3_render_seams_test.lua','tests/gen3_render_seams_absence_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/RENDER_SEAMS.md'},saveNamespace=false,
  impact={runtimeOwners={'gen3.render.seams'},saveWrites={},publicHooks={},files={
   'gen3/lib/cards/RenderSeamsCard.lua','gen3/lib/core/RenderSeams.lua','gen3/cards/RENDER_SEAMS.md'}},
  lifecycle={install=function()return {installed=true}end,
   activate=function()cfg.cards=cfg.cards or{};cfg.cards.renderSeams=cfg.cards.renderSeams or{enabled=true};S.enable(true);return {active=true},{register=S.register,unregister=S.unregister}end,
   deactivate=release,abort=release,
   health=function()return {ok=true,enabled=S.enabled,version=S.version,gpuTimeAvailable=false}end}}
end
return Card
