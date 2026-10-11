-- Bounded local diagnostics, independent of the optional FPS HUD. No save payloads.
local V=...
local Budget=V.require('BuildBudget')
local P={wrappers={},stages={},worst={},frames=0,total=0,over33=0,over100=0,max=0}
local function now()return (V.clock or love.timer.getTime)()end
local function context()
 local M=require('src.core.game3.map');local B=require('src.core.game3.battle')
 local phase=B._phase or 'field'
 if love.window and love.window.hasFocus and not love.window.hasFocus()then phase=phase..' (unfocused)'end
 return tostring(M.current or 'boot'),phase
end
local function clean(s)return tostring(s):gsub('[\t\r\n]',' ')end
function P.record(name,seconds)
 local s=P.stages[name]or{n=0,total=0,max=0};P.stages[name]=s
 s.n=s.n+1;s.total=s.total+seconds;s.max=math.max(s.max,seconds)
 if seconds>.033 then
  local map,phase=context();P.worst[#P.worst+1]={seconds,name,map,phase,now()-P.started}
  if #P.worst>200 then table.sort(P.worst,function(a,b)return a[1]>b[1]end);P.worst[201]=nil end
 end
end
function P.flush(reason)
 if not P.path or not P.diskEnabled()then return end
 local lines={'Origami Ascendant performance v1','reason\t'..clean(reason),'identity\t'..clean(love.filesystem.getIdentity()),
 'frames\t'..P.frames,'mean_ms\t'..string.format('%.3f',P.total*1000/math.max(1,P.frames)),
 'max_ms\t'..string.format('%.3f',P.max*1000),'frames_over_33ms\t'..P.over33,'frames_over_100ms\t'..P.over100,
 'stage\tcalls\ttotal_ms\tmax_ms'}
 local map,phase=context();local w,h=love.graphics.getPixelDimensions()
 local renderer=V.require('Renderer');local canvas=renderer.canvas
 lines[#lines+1]='runtime\tversion='..clean(V.mod._origamiPackageVersion or '?')..' os='..clean(love.system.getOS())..' map='..clean(map)..' phase='..clean(phase)
 lines[#lines+1]=string.format('memory\tlua_mib=%.2f drawable=%dx%d field=%dx%d',collectgarbage('count')/1024,w,h,canvas and canvas:getWidth()or 0,canvas and canvas:getHeight()or 0)
 local g=love.graphics.getStats();lines[#lines+1]=string.format('graphics\tdrawcalls=%d texture_mib=%.2f',g.drawcalls or 0,(g.texturememory or 0)/1048576)
 local keys={};for k in pairs(P.stages)do keys[#keys+1]=k end;table.sort(keys)
 for _,k in ipairs(keys)do local s=P.stages[k];lines[#lines+1]=string.format('%s\t%d\t%.3f\t%.3f',clean(k),s.n,s.total*1000,s.max*1000)end
 lines[#lines+1]='slow_ms\tstage\tmap\tphase\tsession_seconds'
 table.sort(P.worst,function(a,b)return a[1]>b[1]end)
 for _,s in ipairs(P.worst)do lines[#lines+1]=string.format('%.3f\t%s\t%s\t%s\t%.3f',s[1]*1000,clean(s[2]),clean(s[3]),clean(s[4]),s[5])end
 love.filesystem.createDirectory('performance')
 local ok=love.filesystem.write(P.relativePath,table.concat(lines,'\n')..'\n');if not ok then return end
 P.flushed=now()
end
function P.wanted()
 return P.diskEnabled()or not V.mod.options or V.mod.options:get('gen3LiveDisplay')~=false
end
function P.uninstall()
 if not P.installed then return end
 P.flush('disabled')
 for i=#P.wrappers,1,-1 do local w=P.wrappers[i]
  if w.object[w.key]==w.wrapper then w.object[w.key]=w.original end
  P.wrappers[i]=nil
 end
 P.installed=false;P.last=nil
end
function P.present()
 if not P.wanted()then P.uninstall();return end
 if not P.installed then P.install()end
 local t=now()
 if P.last then local dt=t-P.last;P.frames=P.frames+1;P.total=P.total+dt;P.max=math.max(P.max,dt)
  if dt>.033333 then P.over33=P.over33+1 end;if dt>.1 then P.over100=P.over100+1 end
  if dt>.033 then P.record('frame interval (includes present/wait)',dt)end
 end
 P.last=t
 if t-(P.flushed or t)>30 then pcall(P.flush,'checkpoint')end
end
function P.wrap(object,key,label,skip)
 local original=object[key];if type(original)~='function'then return end
 local wrapper=function(...)
  if skip and skip(...)then return original(...)end
  local timer=Budget.ownsCurrent()and Budget.workTime or now
  local t=timer();local a,b,c,d,e,f=original(...);local dt=timer()-t;P.record(label,dt)
  if label=='geometry build'then local def=select(1,...);P.record(label..' '..tostring(def and(def.id or def.name)),dt)end
  return a,b,c,d,e,f
 end
 object[key]=wrapper;P.wrappers[#P.wrappers+1]={object=object,key=key,original=original,wrapper=wrapper}
end
function P.wrapRestore(artifacts)
 -- Background warm-up has its own per-resume timing. Foreground restores
 -- without a staging argument can also yield through BuildBudget.check;
 -- P.wrap uses workTime for those, excluding intervening frame waits.
 P.wrap(artifacts,'restore','geometry cache GPU restore',function(record,def,ts,ox,oz,staging)
  return staging
 end)
end
function P.diskEnabled()
 return V.mod.options and V.mod.options:get('gen3PerformanceLog')==true or os.getenv('OA_QA_PERFORMANCE_LOG')=='1'
end
function P.install()
 if P.installed or not P.wanted()then return end;P.installed=true;P.started=P.started or now();P.flushed=now()
 P.relativePath='performance/'..os.date('%Y%m%d-%H%M%S')..'-'..(math.floor(P.started*1000)%100000)..'.tsv'
 P.path=love.filesystem.getSaveDirectory()..'/'..P.relativePath
 if P.diskEnabled()then print('[OASC performance] '..P.path)end
 P.wrap(require('src.core.game3.map'),'load','native map load')
 local artifacts=V.require('GeometryCache')
 P.wrap(artifacts,'validateIndex','geometry cache identity')
 P.wrap(artifacts,'load','geometry cache load')
 P.wrap(artifacts,'decode','geometry cache decode')
 P.wrapRestore(artifacts)
 P.wrap(artifacts,'activate','geometry cache activation')
 P.wrap(V.require('GeometryGpuWarm'),'update','geometry GPU preparation (CPU submission)')
 P.wrap(V.require('GeometryPrefetch'),'pump','geometry prefetch poll')
 P.wrap(V.require('GeometryCacheLookahead'),'update','geometry lookahead')
 P.wrap(V.require('PaperFinish'),'apply','paper finish (CPU submission)')
 P.wrap(V.require('WorldGeometry'),'build','geometry build')
 P.wrap(V.require('WorldGeometry'),'heightfield','heightfield build')
 P.wrap(V.require('WorldBorder'),'get','border preparation')
 P.wrap(V.require('Renderer'),'draw','world render (CPU submission)')
 -- Attribute first-use stalls without wrapping every graphics draw or
 -- collecting stack traces during normal play. These are coarse stages;
 -- nested totals must not be added together as independent frame costs.
 for _,item in ipairs{
  {'Renderer','prepareShaders'},{'PaperFinish','prepare'},
  {'SpriteRim','compile'},{'SpriteRim','mask'},{'SpriteRim','normals'},
  {'Atmosphere','prepare'},{'LocalLights','prepare'},
  {'SceneGeometry','get'},{'AtlasComposite','get'},
 }do P.wrap(V.require(item[1]),item[2],'detail '..item[1]..'.'..item[2])end
 P.wrap(V.require('WorldAdapter').Native,'get','native atlas load')
 local battle=V.require('battle/PaperBattlePresentation')
 P.wrap(battle,'prepare','battle sprite preparation')
 P.wrap(battle,'drawLayers','battle lighting layers')
 P.wrap(battle,'measureImage','battle sprite measurement')
 P.wrap(battle,'groundPose','battle planted sprite outline')
 if not P.quitInstalled then
  P.quitInstalled=true;local previous=love.quit
  love.quit=function(...)local cancel=previous and previous(...);pcall(P.flush,cancel and 'quit cancelled' or 'normal exit');return cancel end
 end
 P.flush('started')
end
return P
