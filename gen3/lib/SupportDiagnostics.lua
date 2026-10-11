-- VASC incident receipts and manual support transport, adapted to native Gen3 UI.
local V=...
local D={}
local mod=V.mod
local Inbox=V.require('ErrorInbox')
D.inbox=Inbox.new()
D.inbox.context.package='OASC'
D.inbox.context.version=mod._origamiPackageVersion or mod.version
D.inbox.context.session='OASC-'..os.date('!%Y%m%dT%H%M%SZ')
local previous=''
if mod.cache and mod.cache.read then
 local ok,body=pcall(mod.cache.read,mod.cache,'OASC-ERRORS.txt')
 if ok and type(body)=='string'then previous=body:sub(-64000)end
end
function D.text()
 local lines={'Origami Ascendant error log v1','Session: '..D.inbox.context.session}
 for _,r in ipairs(D.inbox.items)do lines[#lines+1]=D.inbox:report(r)end
 local trace=V.loaded and V.loaded.TransitionTrace
 local battleClock=V.loaded and V.loaded['battle/MenuClock']
 if battleClock then local ok,body=pcall(battleClock.text);if ok then lines[#lines+1]=body end end
 if trace then
  lines[#lines+1]=trace.text()
  if trace.previous~=''then lines[#lines+1]='PREVIOUS SESSION / MAP TRACE\n'..trace.previous end
 end
 return table.concat(lines,'\n\n')
end
function D.flush()
 if #D.inbox.items==0 and previous~=''and not(V.loaded and V.loaded.TransitionTrace)then return true end
 if mod.cache and mod.cache.write then return mod.cache:write('OASC-ERRORS.txt',D.text())end
 return false
end
function D.record(event,reason,fields)
 fields=fields or {};fields.status='error';fields.reason=reason
 local receipt,isNew=D.inbox:observe(event,fields)
 if receipt then pcall(D.flush)end
 return receipt,isNew
end
-- Adapter failures are handled locally and logged as warnings; they do not
-- necessarily reach the engine's modStatus.errors queue.
function D.captureFailures()
 local exports=mod.exports or {}
 local renderer=exports.rendererError
 if renderer and renderer~=D.lastError then
  D.lastError=renderer;D.record('renderer-error',renderer)
 elseif not renderer then D.lastError=nil end
 local battle=exports.gen3 and exports.gen3.battle
 if not battle or type(battle.health)~='function' then return end
 local ok,health=pcall(battle.health)
 if not ok or type(health)~='table' then return end
 if health.ok then D.lastBattleError=nil;return end
 local reason=health.reason
 -- An intentionally retired Card has no failure reason.
 if not reason or reason=='' or reason==D.lastBattleError then return end
 D.lastBattleError=reason
 D.record('battle-presentation-error',tostring(reason),{
  actual='native',provider='gen3.battle.presentation.paper',
  stage=health.state,mapId=health.map,renderFailures=health.failures})
end
function D.install()
 if D.api then return D.api end
 -- Startup failures need hardware context before the first game update.
 pcall(V.require('ErrorsMenu').captureContext,D.inbox.context,nil,mod)
 local sender=V.require('SupportSend').new(mod,function()
  D.captureFailures()
  local body=D.text()
  if previous~=''then body=body..'\n--- PREVIOUS SESSION ---\n'..previous end
  local perf=V.loaded.PerformanceLog
  if perf then
   body=body..string.format('\nPerformance: frames=%d; mean_ms=%.3f; max_ms=%.3f; over100=%d\n',perf.frames,perf.total*1000/math.max(1,perf.frames),perf.max*1000,perf.over100)
   for _,s in ipairs(perf.worst or {})do body=body..string.format('slow_ms=%.3f stage=%s map=%s phase=%s\n',s[1]*1000,s[2],s[3],s[4])end
  end
  return body
 end)
 D.api=V.require('ErrorsMenu').install(mod,D.inbox,{language=V.require('MenuLocale').language,
  supportProvider={supportSender=function()return sender end},
  session=function()return D.inbox.context.session end,
  push=function(game,screen)
   screen.__oascErrors=true
   return V.require('Menu').openScreen(game,screen)
  end})
 local onNew=D.inbox.onNew
 D.inbox.onNew=function(r)if onNew then onNew(r)end;pcall(D.flush)end
 local elapsed=0
 mod.hooks:wrap('core.update',function(nextFn,game,dt)
  local result=nextFn(game,dt);elapsed=elapsed+(dt or 0)
  if elapsed>=2 then
   elapsed=0;pcall(D.api.poll,game)
   D.captureFailures()
  end
  return result
 end)
 local quit=love.quit
 love.quit=function(...)
  local result=quit and quit(...);pcall(D.captureFailures);pcall(D.flush);return result
 end
 return D.api
end
function D.open(game)
 local api=D.install();pcall(api.poll,game);D.captureFailures()
 return api.open(game)
end
return D
