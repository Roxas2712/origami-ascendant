-- Data-only, lossless float64 metadata with binary strings. Never load Lua
-- source from a geometry-cache payload; malformed caches fall back to meshing.
local C={}
function C.encode(value,initialDepth,checkpoint)
 initialDepth=initialDepth or 0
 assert(type(initialDepth)=='number'and initialDepth>=0 and initialDepth%1==0,'cache initial depth')
 local out,active={},{}
 local work=0
 local function tick()
  work=work+1
  if checkpoint and work%128==0 then checkpoint()end
 end
 local function emit(v,depth)
  tick()
  assert(depth<96,'cache nesting')
  local t=type(v)
  if t=='number'then
   assert(v==v and math.abs(v)<math.huge,'non-finite cache number')
   out[#out+1]='n'..love.data.pack('string','<d',v)
  elseif t=='string'then out[#out+1]='s'..love.data.pack('string','<I4',#v)..v
  elseif t=='boolean'then out[#out+1]=v and 't'or'f'
  elseif t=='table'then
   assert(not active[v],'cyclic cache data');active[v]=true
   local keys,max,dense={},0,true
   for k in pairs(v)do
    assert(type(k)=='number'or type(k)=='string','cache key type');keys[#keys+1]=k
    if type(k)=='number'and k>=1 and k%1==0 then max=math.max(max,k)else dense=false end
    tick()
   end
   -- Native cell arrays are large and dense. Their canonical order is known;
   -- avoid one blocking table.sort and keep the scan cooperatively bounded.
   if dense and max==#keys then
    for i=1,#keys do keys[i]=i;tick()end
   else table.sort(keys,function(a,b)if type(a)~=type(b)then return type(a)<type(b)end;return a<b end)end
   out[#out+1]='m'..love.data.pack('string','<I4',#keys)
   for _,k in ipairs(keys)do emit(k,depth+1);emit(v[k],depth+1)end
   active[v]=nil
  else error('unsupported cache type '..t)end
 end
 emit(value,initialDepth);return table.concat(out)
end
function C.decode(bytes,checkpoint)
 assert(type(bytes)=='string'and #bytes<=128*1024*1024,'cache size')
 local unpackData=love.data.unpack
 local at,nodes,nextCheck=1,0,128
 local function check()
  if checkpoint and nodes>=nextCheck then nextCheck=nodes+128;checkpoint()end
 end
 local function count()local n;n,at=unpackData('<I4',bytes,at);return n end
 local function read(depth)
  nodes=nodes+1;assert(nodes<=4000000 and depth<96,'cache complexity')
  check()
  local tag=bytes:byte(at);at=at+1
  if tag==110 then -- n
   local n;n,at=unpackData('<d',bytes,at);assert(n==n and math.abs(n)<math.huge,'cache number');return n
  elseif tag==115 then local n=count();assert(at+n-1<=#bytes,'cache string length');local s=bytes:sub(at,at+n-1);at=at+n;return s -- s
  elseif tag==116 then return true -- t
  elseif tag==102 then return false -- f
  elseif tag==109 then -- m
   local n=count();assert(n<=1000000,'cache table length');local t={}
   for _=1,n do
    -- Height grids and geometry metadata contain many numeric key/value pairs.
    -- Read both float64 values in one call without recursive scalar dispatch.
    -- The serialized format and all malformed-input limits remain unchanged.
    if bytes:byte(at)==110 and bytes:byte(at+9)==110 then
     nodes=nodes+2;assert(nodes<=4000000 and depth+1<96,'cache complexity')
     check()
     local keyTag,k,valueTag,v
     keyTag,k,valueTag,v,at=unpackData('<BdBd',bytes,at)
     assert(k==k and math.abs(k)<math.huge and v==v and math.abs(v)<math.huge,'cache number')
     assert(t[k]==nil,'duplicate cache key');t[k]=v
    else
     local k=read(depth+1);assert(type(k)=='string'or type(k)=='number','cache key');assert(t[k]==nil,'duplicate cache key');t[k]=read(depth+1)
    end
   end
   return t
  end
  error('invalid cache tag')
 end
 local value=read(0);assert(at==#bytes+1,'trailing cache bytes');return value
end
return C
