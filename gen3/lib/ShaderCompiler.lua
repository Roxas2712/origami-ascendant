-- OASC-only compiler boundary: every auxiliary pass uses the same GLES rules.
-- Never replace love.graphics.newShader globally (engine / other mods own it).
local V=...
local C={}
function C.newShader(...)
 local n=select('#',...);local args={...}
 for i=1,n do
  if type(args[i])=='string' then args[i]=V.require('SurfaceDerivatives').language(args[i])end
 end
 local trace=V.loaded and V.loaded.TransitionTrace
 local checksum=trace and type(args[1])=='string'and love.data.encode('string','hex',love.data.hash('sha256',args[1]))or 'non-source'
 if trace then trace.step('before auxiliary shader '..checksum:sub(1,12),#tostring(args[1])..' source bytes')end
 local ok,result=pcall(love.graphics.newShader,unpack(args,1,n))
 if trace then trace.step('after auxiliary shader '..checksum:sub(1,12),ok and 'compiled'or tostring(result))end
 if not ok then
  local log=V.loaded and V.loaded.SupportDiagnostics
  if log then pcall(log.record,'shader-error',tostring(result))end
  error(result,2)
 end
 return result
end
return C
