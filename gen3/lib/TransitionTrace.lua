-- Durable, bounded map-load breadcrumbs. No per-frame I/O, native pointers,
-- saves or network traffic. A process kill can leave the last step on disk.
local V=...
local Map=require('src.core.game3.map')
local Player=require('src.core.game3.player')
local T={limit=96,rows={},seen={},active=false}
local file='OASC-TRANSITION.txt'
local function read()
 if not(V.mod.cache and V.mod.cache.read)then return ''end
 local ok,body=pcall(V.mod.cache.read,V.mod.cache,file)
 return ok and type(body)=='string'and body:sub(-64000)or ''
end
T.previous=read()
local function clean(value)
 return tostring(value==nil and '?'or value):gsub('[\r\n]',' '):sub(1,300)
end
local function call(fn,...)
 if type(fn)~='function'then return end
 local ok,a,b,c,d=pcall(fn,...);if ok then return a,b,c,d end
end
function T.text()
 local lines={'OASC map transition trace v2',T.header or 'No map transition in this session.'}
 for _,row in ipairs(T.rows)do lines[#lines+1]=row end
 return table.concat(lines,'\n')
end
function T.flush()
 if not(V.mod.cache and V.mod.cache.write)then return false end
 local ok=pcall(V.mod.cache.write,V.mod.cache,file,T.text())
 local diagnostics=V.loaded and V.loaded.SupportDiagnostics
 if diagnostics then pcall(diagnostics.flush)end
 return ok
end
function T.step(stage,detail)
 if not T.active or T.seen[stage]then return end
 if #T.rows>=T.limit then
  if stage~='OASC draw failed'and stage~='OASC destination ready'then return end
  table.remove(T.rows)
 end
 T.seen[stage]=true
 local stats=call(love.graphics.getStats)or {};local lua=call(collectgarbage,'count')or 0
 local R=V.loaded.Renderer;local target='none'
 if R and R.canvas then
  local w,h=call(R.canvas.getDimensions,R.canvas)
  target=tostring(w)..'x'..tostring(h)..' '..clean(call(R.canvas.getFormat,R.canvas))
 end
 local queue=V.loaded.NativeBuildQueue;local budget=V.loaded.BuildBudget
 local cache=V.loaded.GeometryCache;local prefetch=V.loaded.GeometryPrefetch
 T.rows[#T.rows+1]=string.format('%.3fs | %s | map=%s pos=%s,%s | lua=%.1f MiB textures=%.1f MiB | target=%s pending=%s build=%s phase=%s cache=%s workerFailures=%s | %s',
  (love.timer.getTime()-T.started),clean(stage),clean(Map and Map.current),clean(Player and Player.cellX),clean(Player and Player.cellY),
  lua/1024,(stats.texturememory or 0)/1048576,target,clean(R and R.buildPending),clean(queue and queue.job and queue.job.key),
  clean(budget and budget.phase()),clean(cache and cache.reason),clean(prefetch and prefetch.failed),clean(detail))
 T.flush()
end
-- The source room is still drawn during the native warp. Do not let that
-- consume the destination's GPU breadcrumbs before the new map is entered.
function T.destinationActive()
 return T.active and Map.current==T.to and T.seen['native map entered']==true
end
function T.destination(stage,detail)
 if not T.destinationActive() or T.seen[stage] then return end
 if type(detail)=='function'then detail=call(detail)end
 T.step(stage,detail)
end
function T.begin(from,to,kind)
 T.rows,T.seen={},{};T.pass=nil;T.active=true;T.started=love.timer.getTime();T.from,T.to=from,to
 local engine=call(require,'src.core.Version')or {};local a,b,c=call(love.getVersion)
 local renderer,version,vendor,gpu=call(love.graphics.getRendererInfo)
 local pw,ph=call(love.graphics.getPixelDimensions)
 T.header=string.format('Session %s | OASC %s | engine %s | LOVE %s.%s.%s | %s %s %s %s | pixels %sx%s\nFrom %s -> %s | kind=%s | quality=%s\nMemory values below are Lua/textures only; not total process RAM.',
  os.date('!%Y%m%dT%H%M%SZ'),clean(V.mod._origamiPackageVersion or V.mod.version),clean(engine.engine),clean(a),clean(b),clean(c),
  clean(renderer),clean(version),clean(vendor),clean(gpu),clean(pw),clean(ph),clean(from),clean(to),clean(kind),clean(call(V.mod.options.get,V.mod.options,'gen3Quality')))
 local w,h=call(love.graphics.getDimensions)
 T.step('warp announced',string.format('logical=%sx%s dpi=%s platform=%s',clean(w),clean(h),clean(call(love.graphics.getDPIScale)),clean(call(love.system.getOS))))
end
function T.ready()
 if not T.active then return end
 if not Map or Map.current~=T.to or not T.seen['native map entered']then return end
 T.step('OASC destination ready');T.active=false
end
function T.install()
 if T.installed then return end;T.installed=true
 V.mod.hooks:wrap('warp.destination',function(nextFn,map,x,y,ctx)
  local m,nx,ny=nextFn(map,x,y,ctx)
  T.begin(ctx and ctx.lastMap,m,ctx and ctx.warp and ctx.warp.kind)
  return m,nx,ny
 end,-1000)
 V.mod.events:on('map.exited',function(e)
  if not T.active or T.to~=e.toMapId then T.begin(e.mapId,e.toMapId,'map event')end
  T.step('native map exit')
 end)
 V.mod.events:on('map.entered',function()T.step('native map entered')end)
end
return T
