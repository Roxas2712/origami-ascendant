-- Internal Card: the neutral registry owns activation/rollback; the adapter
-- alone owns Gen3 seams, and the scene alone owns presentation choices.
local Card={ID='oasc.gen3.overworld-battle',VERSION='1.0.0',
  CAPABILITY='ascendant.paper-battle.gen3/v1'}
function Card.descriptor(adapter)
  assert(adapter,'Paper battle adapter required')
  return {
    schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',
    requires={},optionalRequires={},consumes={},provides={Card.CAPABILITY},
    tests={'tests/gen3_paper_battle_card_test.lua','tests/gen3_paper_battle_play_test.lua','tests/gen3_paper_battle_scene_test.lua',
      'tests/gen3_battle_startup_failure_test.lua'},
    docs={'gen3/PAPER_BATTLE_CARD.md'},saveNamespace=false,
    impact={runtimeOwners={'gen3.battle.presentation.paper'},saveWrites={},publicHooks={},
      files={'gen3/lib/cards/Gen3PaperBattleCard.lua','gen3/lib/battle/Gen3BattleAdapter.lua',
        'gen3/lib/battle/PaperBattleScene.lua','gen3/lib/battle/PaperBattlePresentation.lua'}},
    lifecycle={
      install=function()return {installed=true}end,
      activate=function()
        -- Keep startup failures on the same health/log path as draw failures.
        -- The registry still aborts and unwinds any partial installation.
        local ok,err=pcall(adapter.install,adapter)
        if not ok then adapter:failed(err);error(err,0)end
        return adapter,adapter.public
      end,
      deactivate=function()adapter:release();return true end,
      abort=function()adapter:release();return true end,
      health=function()return adapter:health()end,
    },
  }
end
return Card
