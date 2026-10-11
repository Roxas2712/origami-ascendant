local V=...
local Views={}
function Views.terrariumAvailable()
 local version=require('src.core.GameVersion').get()
 return version=='firered' or version=='leafgreen' or version=='emerald'
end
function Views.terrariumProvider()
 return require('src.core.GameVersion').get()=='emerald' and 'battle/terrarium/EmeraldScene' or 'battle/terrarium/KantoScene'
end
function Views.choices()
 local choices={{'ORIGINAL','native'},{'KARTE','paper'}}
 if Views.terrariumAvailable()then choices[#choices+1]={'TERRARIUM','terrarium'}end
 return choices
end
function Views.allowed(view)
 return view=='native' or view=='paper' or view=='terrarium' and Views.terrariumAvailable()
end
function Views.preference()
 local value=V.mod.options:get('gen3BattleView')
 if Views.allowed(value)then return value end
 -- Migrate the former two-state choice; Map stays the default.
 return V.mod.options:get('gen3PaperBattles')==false and 'native' or 'paper'
end
return Views
