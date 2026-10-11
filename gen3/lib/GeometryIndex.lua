-- Data-only validation shared by the background validator and its fixtures.
-- Readers are supplied by our own worker; no source is ever evaluated.
local V=...
local I={}
local function digest(s)return type(s)=='string'and #s==64 and s:match('^[0-9a-f]+$')end
local function path(s,prefix)
 return type(s)=='string'and #s<=512 and s:sub(1,#prefix)==prefix
  and s:match('^[%w_./-]+$')and not s:find('..',1,true)
end
function I.validate(raw,readMod,readEngine)
 local data=V.require('RenderCacheCodec').decode(raw)
 assert(type(data)=='table'and(data.version==1 or data.version==2)
  and type(data.sources)=='table'and type(data.entries)=='table'
  and data.sources['gen3/lib/GeometryCache.lua'],'invalid geometry index')
 -- Current artifacts are addressed by GeometryCache.key's exact native
 -- definition, atlas slots/bytes, game, LOVE ABI, geometry config and angle.
 -- An unrelated engine UI/audio update must not disable that cache. Legacy
 -- indexes retain their original full-engine guard until explicitly migrated.
 assert(data.inputContract==nil or data.inputContract=='native-geometry-v1','invalid geometry input contract')
 local nativeInputs=data.inputContract=='native-geometry-v1'
 local sources=data.engineSources
 assert(type(sources)=='table'and #sources>=1 and #sources<=4096 and digest(data.engine),'invalid engine fingerprint')
 local hash=function(s)return love.data.hash('sha256',s)end
 local hex=function(s)return love.data.encode('string','hex',s)end
 local rows,previous={},''
 local total=0
 local function read(reader,p)
  local s=assert(reader(p),'unreadable source: '..p)
  assert(type(s)=='string'and #s<=4*1024*1024,'source size: '..p)
  total=total+#s;assert(total<=64*1024*1024,'source validation budget')
  return s
 end
 for _,p in ipairs(sources)do
  assert(path(p,'src/')and p:match('%.lua$')and p>previous,'engine source path/order')
  previous=p
  if not nativeInputs then rows[#rows+1]=p..'\0'..hash(read(readEngine,p))end
 end
 if not nativeInputs then assert(hex(hash(table.concat(rows)))==data.engine,'engine fingerprint stale')end
 local count=0
 for p,expected in pairs(data.sources)do
  count=count+1;assert(count<=4096,'source count')
  assert(path(p,'gen3/')and digest(expected),'mod source path/digest')
  assert(hex(hash(read(readMod,p)))==expected,'source mismatch: '..p)
 end
 for key,expected in pairs(data.entries)do
  assert(digest(key)and digest(expected),'invalid geometry content address')
 end
 if data.inputEntries then
  assert(nativeInputs and type(data.inputEntries)=='table','invalid geometry input addresses')
  for key,expected in pairs(data.inputEntries)do assert(digest(key)and digest(expected),'invalid geometry input address')end
 end
 return data
end
return I
