-- Prepare the native animation pack incrementally; publish only when complete.
-- No animation scripts, battle state, ROM data or engine functions are replaced.
local V=...
local W={stats={state='idle',images=0,maxSliceMs=0,totalMs=0,slices={}}}
local key='oasc:battle-animation-assets'
local root='data/generated/gba/pokemon/battle_anims/'
-- Native createsprite lazily imports these definitions on its first call.
-- Load each module in a separate warm slice; never invoke a callback/template.
-- Optional port modules may be absent on other hosts; native loading remains
-- authoritative and the image pack can still be prepared if one is missing.
local animationModules={
 'anim_templates','anim_port.g1_callbacks_b','anim_port.g1_callbacks',
 'anim_port.g2_callbacks','anim_port.g3_callbacks','anim_port.g4_cb_a',
 'anim_port.g4_cb_b','anim_port.g4_callbacks','anim_port.rs_callbacks',
 'anim_port.rs_early_callbacks','anim_callbacks','anim_port.g1_pic_sizes',
 'anim_port.g1_templates','anim_port.g2_mon_sizes','anim_port.g2_templates',
}
local function clock()return love.timer.getTime()end
local function release(pack)
 for _,info in pairs(pack and pack.tags or {})do if type(info)=='table'then
  for _,name in ipairs{'image','idxImage','idxData'}do
   local resource=info[name];if resource and resource.release then resource:release()end
  end
 end end
end
local function cleanup(job)
 if job.data then job.data:release();job.data=nil end
 if job.pack then release(job.pack);job.pack=nil end
end
local function transparent(_,_,r,g,b,a)
 if a<.01 or (math.abs(r-98/255)<.004 and math.abs(g-41/255)<.004 and math.abs(b-1)<.004)
  or (b>.95 and r>.30 and r<.50 and g<.25)then return 0,0,0,0 end
 return r,g,b,a
end
local function work(job,cache,Anim,Warm,Pal)
 local pack
 local function current()
  return W.job==job and not Anim._packLoaded and require('src.core.GameVersion').get()=='firered'
 end
 local function slice(t,label)
  local ms=(clock()-t)*1000;W.stats.totalMs=W.stats.totalMs+ms;W.stats.maxSliceMs=math.max(W.stats.maxSliceMs,ms)
  local s=W.stats.slices[label]or{count=0,totalMs=0,maxMs=0};W.stats.slices[label]=s
  s.count=s.count+1;s.totalMs=s.totalMs+ms;s.maxMs=math.max(s.maxMs,ms)
  Warm.yield()
 end
 local ok,why=pcall(function()
  local t=clock();local bytes=cache:read(root..'pack.lua')
  if type(bytes)~='string'then W.stats.state='unavailable';return end
  slice(t,'read');if not current()then W.stats.state='native-owner';return end
  t=clock();local fn=assert((loadstring or load)(bytes,'@oasc/native-battle-pack'))
  slice(t,'compile');if not current()then W.stats.state='native-owner';return end
  t=clock();pack=assert(fn());assert(type(pack)=='table' and type(pack.tags)=='table');job.pack=pack
  local tags={};for tag in pairs(pack.tags)do tags[#tags+1]=tag end
  table.sort(tags,function(a,b)return tostring(a)<tostring(b)end)
  W.stats.tags=#tags;slice(t,'metadata')
  for _,name in ipairs(animationModules)do
   if not current()then W.stats.state='native-owner';return end
   t=clock();local loaded=pcall(require,'src.core.game3.battle.'..name)
   local counter=loaded and 'modules' or 'modulesSkipped'
   W.stats[counter]=(W.stats[counter]or 0)+1
   slice(t,'module:'..name)
  end
  local function reader(file)return cache:read(root..file)end
  for _,tag in ipairs(tags)do
   if not current()then W.stats.state='native-owner';return end
   t=clock();local info=pack.tags[tag]
   if type(info)=='table' and not info.image and info.file then
    local data=assert(Pal.loadImageData(reader(info.file),info.file),'Missing animation image: '..tostring(info.file))
    job.data=data
    data:mapPixel(transparent)
    local image=love.graphics.newImage(data);info.image=image;data:release();job.data=nil
    image:setFilter('nearest','nearest');info.w=image:getWidth();info.h=image:getHeight()
    Pal.hydrateIndex(info,tag,image,reader);W.stats.images=W.stats.images+1
   end
   slice(t,'image')
  end
  if not current()then W.stats.state='native-owner';return end
  Anim.loadPack(pack);job.pack=nil;W.stats.state='ready'
 end)
 cleanup(job)
 if not ok then
  W.stats.state='failed';W.stats.error=tostring(why)
  if V.mod and V.mod.log then V.mod.log:warn('Native battle warm-up skipped: %s',tostring(why))end
 end
end
function W.queue()
 if W.stats.state~='idle' and W.stats.state~='pending'then return end
 local Warm=require('src.core.game3.warm')
 -- A host reset can discard its coroutine. Release unpublished resources
 -- before retrying; a pack already adopted by Anim remains engine-owned.
 if W.stats.state=='pending' and not Warm.pending(key)then
  if W.job then cleanup(W.job)end;W.job=nil;W.stats.state='idle'
 end
 if W.stats.state~='idle'then return end
 local Anim=require('src.core.game3.battle.anim')
 if Anim._packLoaded then W.stats.state='native-owner';return end
 -- FireRed's strict cache is authoritative. Other editions retain their loader.
 if require('src.core.GameVersion').get()~='firered'then return end
 local cache=require('src.core.game3.dataset').cache()
 if not(cache and cache.read)then return end
 W.stats={state='pending',images=0,maxSliceMs=0,totalMs=0,slices={}}
 local job={};W.job=job
 Warm.add(key,function()work(job,cache,Anim,Warm,require('src.core.game3.battle.anim_pal'))end,3)
end
function W.install()
 if W.installed then return end;W.installed=true;W.queue()
 W.unsubscribe=V.mod.hooks:wrap('core.update',function(nextFn,game,dt)
  W.queue();return nextFn(game,dt)
 end)
end
return W
