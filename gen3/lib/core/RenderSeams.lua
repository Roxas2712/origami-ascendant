-- Owner-scoped, ordered extension points. Empty/disabled seams emit no bytes.
local V=...
local S={version=0,enabled=false,slots={},hooks={},errors={},serial=0,profileDraws=false}
local drawSlots={textureSource=true,bindTexture=true,bindMesh=true}
local shaderSlots={['main.defines']=true,['main.uniforms']=true,['main.functions']=true,
 ['main.vertex.pre']=true,['main.vertex.post']=true,['main.fragment.pre']=true,['main.fragment.albedo']=true,['main.fragment.lit']=true,
 ['main.light.static']=true,['main.light.window']=true,['main.fragment.final']=true,['finish.uniforms']=true,['finish.functions']=true,
 ['finish.pre']=true,['finish.post']=true,['fog.uniforms']=true,['fog.density']=true}
local hookSlots={focusPoint=true,focusMetadata=true,borderBounds=true,camera=true,lighting=true,fogParams=true,bindFog=true,textureSource=true,shaderSource=true,afterGeometry=true,prepare=true,bind=true,bindTexture=true,bindMesh=true,releaseMesh=true,beforeWorld=true,afterWorld=true,afterActors=true,
 beforeFinish=true,afterFinish=true,release=true}
local vertexSlots={'main.vertex.pre','main.vertex.post'}
local boundsVersion,boundsKnown=-1,true
local bounds={x=0,y=0,z=0,ground=false}
function S.enable(value)
 value=value==true
 if S.enabled~=value then S.enabled=value;S.version=S.version+1 end
end
function S.register(owner,slot,entry,priority,padding)
 assert(type(owner)=='string'and owner~='','render seam owner required')
 local bank=shaderSlots[slot]and S.slots or hookSlots[slot]and S.hooks
 assert(bank,'unknown render seam '..tostring(slot))
 local kind=shaderSlots[slot]and 'string'or 'function'
 local fn=kind=='function'and(type(entry)=='table'and entry.fn or entry)or entry
 assert(type(fn)==kind,'invalid render seam '..slot)
 local extent
 if padding~=nil then
  assert((slot=='main.vertex.pre'or slot=='main.vertex.post')and type(padding)=='table','bounds require a vertex slot')
  extent={}
  for _,axis in ipairs{'x','y','z'}do
   local value=padding[axis];if value==nil then value=0 end
   assert(type(value)=='number'and value>=0 and value<math.huge,'invalid vertex bound '..axis)
   extent[axis]=value
  end
  assert(padding.ground==nil or type(padding.ground)=='boolean','invalid vertex ground bound')
  extent.ground=padding.ground==true
 end
 S.serial=S.serial+1
 local row={owner=owner,logName="card "..owner,perDraw=drawSlots[slot],fn=fn,priority=priority or 0,padding=extent,serial=S.serial,live=true,calls=0,ms=0,maxMs=0}
 local rows=bank[slot]or{};bank[slot]=rows;rows[#rows+1]=row
 table.sort(rows,function(a,b)return a.priority<b.priority or a.priority==b.priority and a.serial<b.serial end)
 S.errors[owner]=nil;S.version=S.version+1
 return row
end
function S.unregister(owner)
 local changed=false
 for _,bank in ipairs{S.slots,S.hooks}do for slot,rows in pairs(bank)do
  local kept={}
  for _,row in ipairs(rows)do
   if row.owner==owner then row.live=false;changed=true else kept[#kept+1]=row end
  end
  if #kept==0 then bank[slot]=nil else bank[slot]=kept end
 end end
 if changed then S.version=S.version+1 end
end
function S.shader(slot)
 if not S.enabled then return ''end
 local rows=S.slots[slot];if not rows then return ''end
 local text={};for _,row in ipairs(rows)do if row.live then text[#text+1]=row.fn end end
 return #text>0 and ('\n'..table.concat(text,'\n')..'\n')or ''
end
-- Conservative world-space expansion declared per vertex snippet. Unknown
-- displacement disables culling; no allocation/string concatenation per frame.
-- The returned table is shared and read-only to callers.
function S.vertexBounds()
 if boundsVersion~=S.version then
  boundsVersion=S.version;boundsKnown=true
  bounds.x,bounds.y,bounds.z,bounds.ground=0,0,0,false
  if S.enabled then for _,slot in ipairs(vertexSlots)do
   for _,row in ipairs(S.slots[slot]or{})do if row.live and row.fn~=''then
    local p=row.padding
    if not p then boundsKnown=false
    else
     bounds.x,bounds.y,bounds.z=bounds.x+p.x,bounds.y+p.y,bounds.z+p.z
     bounds.ground=bounds.ground or p.ground
    end
   end end
  end end
  if bounds.x==math.huge or bounds.y==math.huge or bounds.z==math.huge then boundsKnown=false end
 end
 if boundsKnown then return bounds end
end
function S.fail(owner,reason)
 S.errors[owner]=tostring(reason);S.unregister(owner)
 if V.mod and V.mod.log then V.mod.log:warn('Render Card %s disabled: %s',owner,tostring(reason))end
end
function S.failShaders(reason)
 local owners={};for _,rows in pairs(S.slots)do for _,row in ipairs(rows)do owners[row.owner]=true end end
 for _,row in ipairs(S.hooks.shaderSource or{})do owners[row.owner]=true end
 for owner in pairs(owners)do S.fail(owner,reason)end
end
local function call(row,...)
 -- Keep owner failure isolation, but avoid two clocks and a log aggregation
 -- for every mesh/texture binding. Explicit diagnostic mode can restore it.
 if row.perDraw and not S.profileDraws then
  local ok,result=pcall(row.fn,...);row.calls=row.calls+1
  if not ok then S.fail(row.owner,result);return nil end
  return result
 end
 local start=(V.clock or love.timer.getTime)()
 local ok,result=pcall(row.fn,...)
 local elapsed=(V.clock or love.timer.getTime)()-start
 row.calls=row.calls+1;row.ms=elapsed*1000;row.maxMs=math.max(row.maxMs,row.ms)
 local log=V.loaded and V.loaded.PerformanceLog
 if log then log.record(row.logName,elapsed)end
 if not ok then S.fail(row.owner,result);return nil end
 return result
end
function S.run(hook,...)
 local rows=S.enabled and S.hooks[hook]
 if rows then for _,row in ipairs(rows)do if row.live then call(row,...)end end end
end
function S.chain(hook,canvas,ctx)
 local rows=S.enabled and S.hooks[hook]
 if rows then for _,row in ipairs(rows)do if row.live then canvas=call(row,canvas,ctx)or canvas end end end
 return canvas
end
function S.health(owner)
 local calls,ms,maxMs=0,0,0
 for _,rows in pairs(S.hooks)do for _,row in ipairs(rows)do if row.owner==owner then
  calls=calls+row.calls;ms=ms+row.ms;maxMs=math.max(maxMs,row.maxMs)
 end end end
 return {ok=not S.errors[owner],error=S.errors[owner],calls=calls,submissionMs=ms,maxSubmissionMs=maxMs,perDrawTiming=S.profileDraws,gpuTimeAvailable=false}
end
return S
