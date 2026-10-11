-- Optional engine byte-hash bridge. The mod never accesses FFI or host files.
local V=...
local M={};local initialized,bridge,backend=false,nil,'love'
local function fallback(raw)return love.data.encode('string','hex',love.data.hash('sha256',raw))end
local function initialize()
 if initialized then return end;initialized=true
 local mod=V and V.mod
 if not(mod and type(mod.sha256)=='function')then return end
 local ok=pcall(function()
  for _,raw in ipairs{'','abc',string.rep('\0\255\128',67)}do
   assert(mod:sha256(raw)==fallback(raw),'engine SHA-256 self-test')
  end
 end)
 if ok then
  bridge=function(raw)return mod:sha256(raw)end;backend='engine'
  if type(mod.sha256Backend)=='function'then
   local valid,name=pcall(mod.sha256Backend,mod)
   if valid and type(name)=='string'then backend=name end
  end
 end
end
function M.sha256(raw)
 assert(type(raw)=='string','cache hash expects byte string')
 initialize()
 if bridge then
  local ok,result=pcall(bridge,raw)
  if ok and type(result)=='string'and #result==64 and not result:find('[^0-9a-f]')then return result end
  bridge=nil;backend='love'
 end
 return fallback(raw)
end
function M.backend()initialize();return backend end
return M
