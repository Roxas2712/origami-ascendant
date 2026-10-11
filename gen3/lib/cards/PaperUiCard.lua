-- Native Gen3 windows currently expose frame helpers, not a public draw hook.
-- Do not register an invented hook or replace Window/Chrome engine functions.
local Card={ID='oasc.gen3.paper-ui',VERSION='1.0.0',CAPABILITY='ascendant.paper-ui.gen3/v1'}
Card.option={key='gen3Card_paperUi',label='PAPIER-MENUES (NICHT VERFUEGBAR)',type='toggle',default=false,available=false,
 help='Diese Engine bietet keine Fensterschnittstelle. Native Menues bleiben erhalten.'}
function Card.descriptor(V)
 local reason='Native Gen3 Window/Chrome drawing has no supported public mod hook'
 local function unavailable()return{installed=false,available=false,reason=reason}end
 local function deactivate()return true end
 return{schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',
  requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_paper_ui_availability_test.lua'},docs={'gen3/cards/PAPER_UI.md'},
  impact={runtimeOwners={'gen3.render.paper-ui'},saveWrites={},publicHooks={},
   files={'gen3/lib/cards/PaperUiCard.lua','gen3/cards/PAPER_UI.md'}},
  lifecycle={install=unavailable,activate=function()return false,reason end,
   deactivate=deactivate,abort=deactivate,
   health=function()return{ok=true,available=false,active=false,installed=false,reason=reason,resources=0}end}}
end
return Card
