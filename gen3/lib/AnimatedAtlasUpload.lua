-- Keep native animation uploads off the texture still used by queued draws.
-- Hosts with the public flush/markDirty/ensureAlt contract retain two buffers.
-- Pixel data and animation timing stay native.
local V=...
local U={enabled=true,rings=setmetatable({},{__mode='k'}),active=false}
local function rebind(old,new)
 local view=require('src.core.game3.field_view')
 local seen={}
 local function visit(t)
  if type(t)=='userdata'and t.typeOf and t:typeOf('SpriteBatch')then
   if t:getTexture()==old then t:setTexture(new)end
  elseif type(t)=='table'and not seen[t]then
   seen[t]=true;for _,v in pairs(t)do visit(v)end
  end
 end
 -- Include retained native view/void-fade batches, not only the paper pass.
 for _,key in ipairs{'_nativeBatch','_nativeBatches','_nativeOverBatches','_nativeOverByRow','_voidFrom'}do visit(view[key])end
end
local function restore()
 for ts,ring in pairs(U.rings)do
  rebind(ts.image,ring.original);ts.image=ring.original
  ts.image:replacePixels(ts.imageData)
  for _,im in ipairs(ring.images)do if im~=ring.original then im:release()end end
  U.rings[ts]=nil
 end
end
function U.release()
 U.active=false;restore()
 if U.nativeFlush then
  local n=require("src.core.game3.tileset_native")
  if n.flush==U.flushWrapper then n.flush=U.nativeFlush end
  U.nativeFlush=nil;U.nativeRevisions=false;U.installed=false
 end
end
function U.install()
 if not U.enabled then U.release();return end
 U.active=true
 if U.installed then return end
 -- Public 0.3.61 and 0.3.74 own double-buffered partial uploads. Adding a
 -- second texture ring breaks its deferred flush contract and repeats work.
 local native=require('src.core.game3.tileset_native')
 if type(native.flush)=='function'and type(native.markDirty)=='function'and type(native.ensureAlt)=='function'then
  local original=native.flush;U.nativeFlush=original
  local wrapper
  wrapper=function(ts,under,over,...)
   local result=original(ts,under,over,...)
   if U.active and U.nativeRevisions and U.flushWrapper==wrapper and (under or over)then
    ts._oascRenderRevision=(ts._oascRenderRevision or 0)+1
   end
   return result
  end
  U.flushWrapper=wrapper
  U.nativeGeneration=(U.nativeGeneration or 0)+1
  native.flush=U.flushWrapper;U.nativeRevisions=true;U.installed=true
  return
 end
 local anim=require('src.core.game3.tileset_anim')
 local apply,invalidate=anim._applyKind,anim.invalidate
 U.originalApply=apply
 anim._applyKind=function(entry,kind,frame)
  if not U.active or not U.enabled then
   if next(U.rings)then restore()end
   return apply(entry,kind,frame)
  end
  local bank=entry.banks and entry.banks[kind];local ts=entry.atlas
  if not(bank and bank.frames>0 and ts and ts.image and ts.imageData)or entry.frames[kind]==frame%bank.frames then return apply(entry,kind,frame)end
  local ring=U.rings[ts]
  if not ring then ring={images={ts.image},index=1,original=ts.image};U.rings[ts]=ring end
  local index=ring.index%3+1;local old=ts.image
  if not ring.images[index]then
   local im=love.graphics.newImage(ts.imageData)
   im:setFilter(old:getFilter());im:setWrap(old:getWrap());ring.images[index]=im
  end
  ts.image=ring.images[index];ring.index=index
  local ok,err=pcall(apply,entry,kind,frame)
  if not ok then ts.image=old;error(err)end
  rebind(old,ts.image)
 end
 anim.invalidate=function(...)
  -- Restore native-owned handles before its atlas/animation caches are reset.
  restore();return invalidate(...)
 end
 U.installed=true
end
return U
