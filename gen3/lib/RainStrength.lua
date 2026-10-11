-- One shared density/audio profile; AUTO follows the weather director.
local V=...
local R={}
R.setting=V.require('ModSetting').new('rainStrength','RAIN STRENGTH',
 {'auto','light','normal','heavy'},{'AUTO','LIGHT','NORMAL','HEAVY'},'auto')
local profiles={light={key='light',drops=1,alpha=.70,audio=.45},
 normal={key='normal',drops=3,alpha=1,audio=1},
 heavy={key='heavy',drops=4,alpha=1.18,audio=1.3}}
function R.profile(mode)
 local key=R.setting:get()
 if not profiles[key]then key=mode=='storm' and 'heavy' or 'normal'end
 return profiles[key]
end
return R
