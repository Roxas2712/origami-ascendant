-- RC field-camera policy: experimental first/third-person modes are disabled.
-- Retain the setting key only to migrate older saved preferences to NORMAL.
local V=...
local F={disabled=true,yaw=0,targetYaw=0,pitch=20,presentation=false}
F.setting=V.require('ModSetting').new('gen3FieldCamera','FIELD CAMERA',{'normal'},{'NORMAL'},'normal')
function F.enabled()return nil end
function F.interactive()return false end
function F.spriteFacing(facing)return facing end
function F.prepare(game,presentation)F.game=game;F.presentation=not not presentation end
function F.apply(game)
 F.game=game
 if game and V.mod.options:get('gen3FieldCamera')~='normal'then
  F.setting:setValue('normal',game,true)
 end
end
return F
