-- Optional mod-owned renderer seam for the verified public engine. It does
-- not modify installed engine files or replace battle rules/input/update.
local V=...
local Bridge={}
function Bridge.install(Ui)
 if Ui.presentationApiVersion==2 and Ui.drawBattler then return end
 local Version=require('src.core.Version')
 -- Version numbers only select the older drawing layout. New releases use
 -- the current bridge; compatibility depends on capabilities, not a release
 -- whitelist. Native API v2 above needs no bridge at all.
 local engine=tostring(Version.engine)
 local release=engine:match('^(%d+%.%d+%.%d+)$')or engine:match('^(%d+%.%d+%.%d+)[+%-]')
 local legacy=release=='0.3.61'or release=='0.3.62'or release=='0.3.63'
 local bridge=legacy and 'BattleRender0361'or 'BattleRender0374'
 for _,key in ipairs{'draw','pump','takeCommand','bindState'}do assert(type(Ui[key])=='function','OASC presentation: missing native '..key)end
 local source=assert(V.mod:read('gen3/compat/'..bridge..'.lua'))
 local draw=assert((loadstring or load)(source,'@OrigamiAscendant/compat/'..bridge..'.lua'))(Ui)
 local prior={draw=Ui.draw,drawBattler=Ui.drawBattler,drawBall=Ui.drawBall,
  presentationApiVersion=Ui.presentationApiVersion,presentationHudVersion=Ui.presentationHudVersion,
  presentationSlotsVersion=Ui.presentationSlotsVersion}
 local replacement={draw=function(...)
  if not Ui.presentation then return prior.draw(...)end
  return draw.draw(...)
 end,drawBattler=draw.drawBattler,drawBall=draw.drawBall,presentationApiVersion=2,
  presentationHudVersion=1,presentationSlotsVersion=1}
 for key,value in pairs(replacement)do Ui[key]=value end
 V.mod.log:info('OASC public '..Version.engine..' rendering bridge active; native battle logic retained')
 return function()
  for key,value in pairs(replacement)do if Ui[key]==value then Ui[key]=prior[key]end end
 end
end
return Bridge
