-- Cache only uniforms whose writes are owned by the caller. Compare scalar
-- values inside vectors: callers may mutate their reusable payload in place.
local U={enabled=true,sent=0,skipped=0,cache=setmetatable({},{__mode='k'}),uniforms=setmetatable({},{__mode='k'})}
-- A linked shader's interface is immutable. Cache both present and absent
-- names; released programs must not be retained by the interface cache.
function U.has(shader,name)
 local bank=U.uniforms[shader];if not bank then bank={};U.uniforms[shader]=bank end
 local value=bank[name]
 if value==nil then value=shader:hasUniform(name);bank[name]=value end
 return value
end
function U.send(shader,name,...)
 if not U.enabled then U.cache[shader]=nil;shader:send(name,...);U.sent=U.sent+1;return end
 local bank=U.cache[shader];if not bank then bank={};U.cache[shader]=bank end
 local row=bank[name];local n=select('#',...);local same=row and row.n==n
 if same then for i=1,n do
  local a,b=select(i,...),row[i]
  if type(a)=='table'then
   if type(b)~='table'or #a~=#b then same=false;break end
   for k=1,#a do if a[k]~=b[k]then same=false;break end end
  elseif a~=b then same=false end
  if not same then break end
 end end
 if same then U.skipped=U.skipped+1;return end
 shader:send(name,...);U.sent=U.sent+1
 row=row or{};bank[name]=row
 for i=n+1,row.n or 0 do row[i]=nil end;row.n=n
 for i=1,n do
  local a=select(i,...)
  if type(a)=='table'then
   local b=type(row[i])=='table'and row[i]or{};row[i]=b
   for k=#a+1,#b do b[k]=nil end;for k=1,#a do b[k]=a[k]end
  else row[i]=a end
 end
end
function U.invalidate(shader)if shader then U.cache[shader]=nil else U.cache=setmetatable({},{__mode='k'})end end
return U
