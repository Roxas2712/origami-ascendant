-- Optional, prebuilt local render artifacts. Missing/stale/corrupt entries use
-- the native mesher. No saves, gameplay data, or runtime cache files are written.
local V=...
local C={enabled=true,hits=0,misses=0,errors={},native=setmetatable({},{__mode='k'})}
local root='gen3/render-cache/'
local hash=V.require('CacheHash').sha256
local Budget=V.require('BuildBudget')
local Queue=V.require('NativeBuildQueue')
function C.validateIndex(seconds)
 if C.index~=nil then return C.index or nil end
 local data,reason=V.require('GeometryValidation').poll(seconds)
 C.reason=reason
 if data then C.index=data;return data end
 if reason~='validation pending'then C.index=false end
end
-- A bake/reload may request another validation after its finite worker ends.
function C.resetIndex()
 if not V.require('GeometryValidation').reset()then return false end
 C.index=nil;C.reason=nil;return true
end
local function index()return C.validateIndex()end
local function nativeSignature(def,ts)
 local saved=C.native[ts];if saved then return saved end
 local cache=require('src.core.game3.dataset').cache()
 local mt=getmetatable(def);local nativeDef=mt and type(mt.__index)=='table'and mt.__index or def
 local d=V.require('NativeTilesetIdentity').describe(nativeDef,cache);local pieces={}
 if d then
  for _,id in ipairs{d.primary,d.secondary}do for _,file in ipairs{'tiles.4bpp','metatiles.bin','attributes.bin','palettes.bin'}do
   pieces[#pieces+1]=assert(cache:read('data/generated/gba/map_tree/tilesets/'..id..'/'..file))
  end end
 else
  local E=require('src.import.gba.extract_island1');local p=(E.NATIVE_ROOT or(E.CACHE_ROOT..'/native'))..'/'..ts.pair..'/'
  pieces[1]=assert(cache:read(p..'mids.idx'));pieces[2]=assert(cache:read(p..'palettes.bin'));pieces[3]=cache:read(p..'mids_over.idx')or''
 end
 saved=hash(love.data.compress('string','lz4',table.concat(pieces)));C.native[ts]=saved;return saved
end
local function definition(def)
 -- Repaired native identities use a thin __index view over the original map.
 local out={};local mt=getmetatable(def)
 if mt and type(mt.__index)=='table'then for k,v in pairs(definition(mt.__index))do out[k]=v end end
 for k,v in pairs(def)do out[k]=v end
 return out
end
-- Keep shallow snapshots of every distinct configuration table. Comparing
-- each table once catches additions, removals, replacements and nested edits
-- without recursively revisiting shared colour/layout tables on every key.
local configRoot,configRows,configContractVersion
local function sameConfiguration(cfg,root,rows)
 if not rawequal(cfg,root)or not rows then return false end
 for _,row in ipairs(rows)do
  local count=0
  for k,v in pairs(row.source)do
   if not rawequal(row.values[k],v)or(v==0 and 1/v~=1/row.values[k])then return false end
   count=count+1
  end
  if count~=row.count then return false end
 end
 return true
end
local function configurationRows(cfg)
 local rows,seen={},{}
 local function visit(t)
  if seen[t]then return end;seen[t]=true
  local row={source=t,values={},count=0};rows[#rows+1]=row
  for k,v in pairs(t)do
   row.values[k]=v;row.count=row.count+1
   if type(v)=='table'then visit(v)end
  end
 end
 visit(cfg);return rows
end
local function copy(t,seen)
 if type(t)~='table'then return t end
 seen=seen or{};if seen[t]then return seen[t]end
 local out={};seen[t]=out
 for k,v in pairs(t)do out[k]=copy(v,seen)end;return out
end
local function configuration()
 local cfg=V.require('DioramaConfig')
 local projection=V.require('GeometryConfig')
 if configContractVersion~=projection.version or not sameConfiguration(cfg,configRoot,configRows)then
  -- Lighting/post/UI controls do not change cached vertices or metadata.
  -- Keep baked facade shading, light positions and unknown settings guarded.
  -- Encode an immutable snapshot in loading slices. Options or Card contracts
  -- may change while suspended: publish neither their fingerprint nor their
  -- validation rows unless they still describe this exact snapshot.
  local version,rows=projection.version,configurationRows(cfg)
  local geometryConfig=copy(projection.project(cfg))
  local encoded=V.require('RenderCacheCodec').encode(geometryConfig,0,Budget.ownsCurrent()and Budget.check)
  assert(projection.version==version and rawequal(cfg,V.require('DioramaConfig'))
   and sameConfiguration(cfg,cfg,rows),'configuration changed during cache key encoding')
  C.configDigest=hash(love.data.compress('string','lz4',encoded))
  configRoot,configRows,configContractVersion=cfg,rows,version
 end
 return C.configDigest
end
C.configurationFingerprint=configuration
-- Offsets change when a visible neighbor becomes the current map. Reuse its
-- canonical definition bytes while still comparing every native field, so
-- in-place script/layout edits cannot select stale geometry. Bound snapshots
-- independently of the renderer's GPU cache.
local keyParts,tick={},0
local function sameBits(a,b)
 if type(a)~='table'then return a==b and(a~=0 or 1/a==1/b)end
 if type(b)~='table'then return false end
 for k,v in pairs(a)do if not sameBits(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
local function encodedPart(owner,value,codec)
 tick=tick+1
 local row=keyParts[owner]
 if row and sameBits(value,row.snapshot)then row.used=tick;return row.bytes end
 -- Freeze the definition before the encoder yields. An in-place script edit
 -- during suspension must never associate mixed/old bytes with a new layout.
 local snapshot=copy(value)
 local raw=codec.encode(snapshot,1,Budget.ownsCurrent()and Budget.check)
 assert(sameBits(definition(owner),snapshot),'native definition changed during cache key encoding')
 keyParts[owner]={snapshot=snapshot,bytes=raw,used=tick}
 local count,oldest,age=0,nil,math.huge
 for key,item in pairs(keyParts)do
  count=count+1;if item.used<age then oldest,age=key,item.used end
 end
 if count>8 then keyParts[oldest]=nil end
 return raw
end
local keyNames={'cols','config','def','game','instancing','love','native','ox','oz','preserveRows','projection','rows','slots','version'}
local function geometryDefinition(value)
 if type(value)~='table'then return value end
 local out={}
 for k,v in pairs(value)do
  -- ROM script addresses never enter the mod's geometry producer. Native
  -- script changes still alter live cells/overrides, which remain guarded.
  if k~='scriptPtr'and k~='scriptKey'and k~='mapScripts'then out[k]=geometryDefinition(v)end
  Budget.tick()
 end
 return out
end
function C.health()return {hits=C.hits,misses=C.misses,errors=C.errors,reason=C.reason,coverage='FireRed/LeafGreen Kanto and selected Sevii; Emerald builds live'}end
function C.key(entry,ts,instancing,preserveRows,portable)
 -- A cooperative cold load must not publish a native scene just because the
 -- authenticated index is still decoding. Failed validation still falls back.
 if C.enabled and not C.record and Budget.ownsCurrent()then
  local started=love.timer.getTime()
  while not C.validateIndex(.004)and C.reason=='validation pending'and love.timer.getTime()-started<5 do
   coroutine.yield('geometry index validation')
  end
 end
 -- Animated flower cutouts must remain live; the non-instanced fallback
 -- bakes them into its main mesh and therefore cannot use this bundle.
 if not C.enabled or not instancing or(not C.record and not index())then return end
 if not(entry.id:match('^FR_')or entry.id:match('^SEVII_ONE_ISLAND'))then return end
 local previousPhase=Budget.ownsCurrent()and Budget.phase()
 if previousPhase then Budget.phase('cache key')end
 local ok,value=pcall(function()
  local codec=V.require('RenderCacheCodec')
  local values={version=1,love={love.getVersion()},game=require('src.core.GameVersion').get(),
   def=definition(entry.def),ox=entry.ox,oz=entry.oy,preserveRows=not not preserveRows,
   instancing=not not instancing,config=configuration(),projection=V.require('Camera').geometryKey(),
   native=nativeSignature(entry.def,ts),slots=ts.midToSlot,cols=ts.cols,rows=ts.rows}
  local inputSnapshot
  if portable then
   inputSnapshot=copy(values.def)
   values.def=geometryDefinition(inputSnapshot);values.game='frlg-geometry';values.love={'vertex-f32-v1'}
  end
  -- The field order and depth exactly match RenderCacheCodec.encode(values).
  -- Missing fields keep the canonical map length rather than writing nil.
  local count=0;for _,name in ipairs(keyNames)do if values[name]~=nil then count=count+1 end end
  local parts={'m'..love.data.pack('string','<I4',count)};local lovePart
  for _,name in ipairs(keyNames)do if values[name]~=nil then
   parts[#parts+1]=codec.encode(name,1)
   parts[#parts+1]=name=='def'and not portable and encodedPart(entry.def,values.def,codec)
    or codec.encode(values[name],1,Budget.ownsCurrent()and Budget.check)
   if name=='love'then lovePart=#parts end
  end end
  if inputSnapshot then assert(sameBits(definition(entry.def),inputSnapshot),'native definition changed during input key encoding')end
  local key=hash(love.data.compress('string','lz4',table.concat(parts)))
  -- The shipped float32 vertex/instance payload was baked on LOVE 11.5.
  -- LOVE 12 reads exactly the same payload format. Try that legacy address
  -- only after every other live input has matched, never a map-name alias.
  -- New bakes and unknown graphics ABIs keep their own full-version key.
  local idx=C.index
  if not portable and not C.record and idx and idx.inputContract=='native-geometry-v1'and not idx.entries[key]then
   local liveLove=parts[lovePart]
   local function address()return hash(love.data.compress('string','lz4',table.concat(parts)))end
   if values.love[1]==12 then
    parts[lovePart]=codec.encode({11,5,0,'Mysterious Mysteries'},1)
    local legacy=address();if idx.entries[legacy]then return legacy end
    parts[lovePart]=liveLove
   end
   if idx.inputEntries and(values.game=='firered'or values.game=='leafgreen')
    and(values.love[1]==11 or values.love[1]==12)then
    local inputKey=C.key(entry,ts,instancing,preserveRows,true)
    if inputKey and idx.inputEntries[inputKey]then return inputKey end
   end
  end
  return key
 end)
 if previousPhase then Budget.phase(previousPhase)end
 if ok then return value end
 C.errors[entry.id]=tostring(value)
end
local function bytes(mesh,width)
 local parts={}
 local format=width==9 and '<fffffffff'or'<fff'
 for i=1,mesh:getVertexCount()do parts[i]=love.data.pack('string',format,mesh:getVertex(i))end
 return table.concat(parts)
end
-- Store cave triangles once as float64 data. Grid rows refer to the same cap
-- objects: duplicating them changes cutaway deduplication and wastes memory.
local capFormat='<'..string.rep('d',35)
local function packCaps(caps)
 if not caps then return nil end
 local chunks={}
 for _,cap in ipairs(caps)do
  local row={};for i=1,3 do for j=1,9 do row[#row+1]=cap[i][j]end end
  for _,k in ipairs{'x0','x1','z0','z1'}do row[#row+1]=cap[k]end
  for i=1,4 do row[#row+1]=cap.uv[i]end
  chunks[#chunks+1]=love.data.pack('string',capFormat,unpack(row))
 end
 return table.concat(chunks)
end
local function restoreCaps(raw,checkpoint)
 if raw==nil then return nil end
 assert(type(raw)=='string'and #raw%280==0,'invalid cave caps')
 local caps={grid={}}
 for at=1,#raw,280 do
  -- Decode directly into locals: the temporary row and nested copy loops
  -- dominate large cave restores on LuaJIT. Preserve all 35 float64 checks.
  local v1,v2,v3,v4,v5,v6,v7,v8,v9,
        v10,v11,v12,v13,v14,v15,v16,v17,v18,
        v19,v20,v21,v22,v23,v24,v25,v26,v27,
        v28,v29,v30,v31,v32,v33,v34,v35=love.data.unpack(capFormat,raw,at)
  assert(
   v1==v1 and math.abs(v1)<10000000 and v2==v2 and math.abs(v2)<10000000 and v3==v3 and math.abs(v3)<10000000 and v4==v4 and math.abs(v4)<10000000 and v5==v5 and math.abs(v5)<10000000 and
   v6==v6 and math.abs(v6)<10000000 and v7==v7 and math.abs(v7)<10000000 and v8==v8 and math.abs(v8)<10000000 and v9==v9 and math.abs(v9)<10000000 and v10==v10 and math.abs(v10)<10000000 and
   v11==v11 and math.abs(v11)<10000000 and v12==v12 and math.abs(v12)<10000000 and v13==v13 and math.abs(v13)<10000000 and v14==v14 and math.abs(v14)<10000000 and v15==v15 and math.abs(v15)<10000000 and
   v16==v16 and math.abs(v16)<10000000 and v17==v17 and math.abs(v17)<10000000 and v18==v18 and math.abs(v18)<10000000 and v19==v19 and math.abs(v19)<10000000 and v20==v20 and math.abs(v20)<10000000 and
   v21==v21 and math.abs(v21)<10000000 and v22==v22 and math.abs(v22)<10000000 and v23==v23 and math.abs(v23)<10000000 and v24==v24 and math.abs(v24)<10000000 and v25==v25 and math.abs(v25)<10000000 and
   v26==v26 and math.abs(v26)<10000000 and v27==v27 and math.abs(v27)<10000000 and v28==v28 and math.abs(v28)<10000000 and v29==v29 and math.abs(v29)<10000000 and v30==v30 and math.abs(v30)<10000000 and
   v31==v31 and math.abs(v31)<10000000 and v32==v32 and math.abs(v32)<10000000 and v33==v33 and math.abs(v33)<10000000 and v34==v34 and math.abs(v34)<10000000 and v35==v35 and math.abs(v35)<10000000,
   'invalid cave coordinate')
  local cap={x0=v28,x1=v29,z0=v30,z1=v31,uv={v32,v33,v34,v35},
   {v1,v2,v3,v4,v5,v6,v7,v8,v9},
   {v10,v11,v12,v13,v14,v15,v16,v17,v18},
   {v19,v20,v21,v22,v23,v24,v25,v26,v27}}
  assert(cap.x1>=cap.x0 and cap.z1>=cap.z0 and cap.x1-cap.x0<=4096 and cap.z1-cap.z0<=4096,'invalid cave bounds')
  caps[#caps+1]=cap
  for z=math.floor(cap.z0/16),math.ceil(cap.z1/16)-1 do for x=math.floor(cap.x0/16),math.ceil(cap.x1/16)-1 do
   local key=x..':'..z;local bucket=caps.grid[key]or{};caps.grid[key]=bucket;bucket[#bucket+1]=cap
  end end
  if checkpoint then checkpoint()end
 end
 return caps
end
function C.beginRecord(ts)
 -- Template hits skip glass registration. Bake each entry independently of
 -- previously visited maps while leaving their live atlas masks intact.
 V.require('PaperBuildings').release()
 V.require('LocalLights').beginGlassCapture(ts)
end
function C.encode(record)
 return V.require('GeometryPayload').encode(record)
end
function C.decode(raw)
 -- Worker/tool decodes remain synchronous. A cold main-thread miss shares
 -- the same cooperative deadline as restore; no partial record is published.
 if raw:sub(1,4)=='OGC5'and not C.readChunk then
  C.readChunk=V.require('GeometryChunks').reader(function(path,offset,length)
   if not offset then return V.mod:read(path)end
   local file=assert(love.filesystem.newFile(V.mod.path..'/'..path,'r'),'missing chunk bank')
   local ok,raw=pcall(function()assert(file:seek(offset),'chunk seek');return assert(file:read(length))end)
   file:close();if not ok then error(raw,0)end;return raw
  end,V.require('MobileRenderBudget').active()and 512*1024 or nil)
 end
 return V.require('GeometryPayload').decode(raw,Budget.ownsCurrent()and Budget.check,C.readChunk)
end
function C.pack(cached,ts)
 local record={version=2,mesh=bytes(cached.mesh,9),stats=cached.stats,heights=V.require('HeightFieldCodec').encode(cached.staticHeights or cached.heights),
  caveCaps=packCaps(cached.caveCaps),furniture=V.require('FurnitureRestore').capture(cached.layout),glass=V.require('LocalLights').finishGlassCapture(ts),instances={}}
 for _,b in ipairs(cached.instances)do record.instances[#record.instances+1]={
  mesh=not b.dynamic and bytes(b.mesh,9)or nil,dynamic=b.dynamic,
  originalVertices=b.mesh:getVertexCount(),placements=bytes(b.placements,3),count=b.count}end
 return C.encode(record)
end
local function releaseCreated(created)
 for i=#created,1,-1 do created[i]:release();created[i]=nil end
end
-- The queue owns partial uploads until it publishes the complete scene. A
-- restore error empties the same list, making later cancellation a no-op.
local function ownRestore(created)
 if Budget.ownsCurrent()then Queue.own({release=function()releaseCreated(created)end})end
end
local function activate(c,record,def,ts,ox,oz,created)
 local G=V.require('WorldGeometry')
 Budget.phase('cave plan');Budget.check()
 V.require('FireRedTerracedCaves').prepare(def)
 Budget.check();Budget.phase('cache activation')
 for i,b in ipairs(record.instances)do if b.dynamic then
  local batch=c.instances[i]
  -- Resolve live flower silhouettes only when the destination is used.
  local vertices=V.require('Props').template(ts,b.dynamic.mid,b.dynamic.kind,b.dynamic.ground)
  Budget.check()
  batch.mesh=love.graphics.newMesh(G.FORMAT,vertices,'triangles','static');created[#created+1]=batch.mesh
  Budget.check()
  local fields={}
  for j=1,b.count do
   local x,z,scale=batch.placements:getVertex(j)
   if not fields[scale]then fields[scale]=G.heightfield(vertices,scale)end
   G.mergeHeightfield(c.heights,fields[scale],x,z)
   Budget.tick()
  end
  local delta=#vertices-b.originalVertices
  c.stats.vertices=c.stats.vertices+delta*b.count;c.stats.storedVertices=c.stats.storedVertices+delta
  batch.mesh:attachAttribute('WorldPlacement',batch.placements,'perinstance')
  Budget.check()
 end end
 local F=V.require('Furniture');local objects,mask=F.plan(def)
 -- Live registration can load room providers on its first use. Keep the
 -- completed plan and owned meshes across slices instead of combining that
 -- work with the following build in one unbounded activation step.
 Budget.check()
 if not V.require('FurnitureRestore').restore(record.furniture,def,objects)then
  F.build({},objects,def.midLayout,ts,ox,oz,mask,{})
 end
 Budget.check()
 V.require('LocalLights').importGlass(ts,record.glass)
 return c
end
function C.activate(c,def,ts,ox,oz)
 assert(c.pendingRecord and c.pendingObjects,'scene already activated')
 local ok,result=pcall(activate,c,c.pendingRecord,def,ts,ox,oz,c.pendingObjects)
 if not ok then releaseCreated(c.pendingObjects);error(result)end
 c.pendingRecord,c.pendingObjects=nil,nil
 return result
end
function C.restore(record,def,ts,ox,oz,staging)
 local created=staging and staging.created or{}
 local checkpoint=staging and staging.checkpoint or(Budget.ownsCurrent()and Budget.check)
 if not staging then ownRestore(created)end
 local function mesh(format,data,width,mode)
  assert(type(data)=='string'and #data>0 and #data%(width*4)==0,'invalid mesh data')
  local buffer=love.data.newByteData(data)
  local ok,m=pcall(love.graphics.newMesh,format,buffer,mode,'static');buffer:release();assert(ok,m)
  if width==9 and #created==0 then V.require('cards/PaperSurfaceGeometry').remember(m,data)end
  created[#created+1]=m;if checkpoint then checkpoint()end;return m
 end
 local ok,result=pcall(function()
  assert((record.version==1 or record.version==2)and type(record.stats)=='table'and type(record.instances)=='table','invalid scene record')
  local heights=record.version==2 and V.require('HeightFieldCodec').decode(record.heights,checkpoint)or record.heights
  assert(type(heights)=='table','invalid scene heightfield')
  local G=V.require('WorldGeometry');local c={mesh=mesh(G.FORMAT,record.mesh,9,'triangles'),
   stats=record.stats,heights=heights,caveCaps=restoreCaps(record.caveCaps,checkpoint),instances={}}
  c.contacts=V.require('ContactShadows').mesh(c.stats.contacts)
  if c.contacts then created[#created+1]=c.contacts end
  if checkpoint then checkpoint()end
  for _,b in ipairs(record.instances)do
   assert(type(b.count)=='number'and b.count>0 and b.count==math.floor(b.count),'invalid instance count')
   local batch={placements=mesh({{'WorldPlacement','float',3}},b.placements,3,'points'),count=b.count,dynamic=b.dynamic}
   if b.dynamic then
    assert(b.dynamic.kind=='flower'and type(b.dynamic.mid)=='number'and type(b.originalVertices)=='number','invalid animated prop')
   else batch.mesh=mesh(G.FORMAT,b.mesh,9,'triangles')end
   assert(batch.placements:getVertexCount()==batch.count,'instance length mismatch')
   if batch.mesh then batch.mesh:attachAttribute('WorldPlacement',batch.placements,'perinstance')end
   c.instances[#c.instances+1]=batch
  end
  if staging then
   c.pendingRecord,c.pendingObjects=record,created
   return c
  end
  return activate(c,record,def,ts,ox,oz,created)
 end)
 if ok then return result end
 releaseCreated(created)
 error(result)
end
function C.load(key,def,ts,ox,oz)
 if not key or C.record then return end
 local idx=index();local expected=idx and(idx.entries[key]or idx.inputEntries and idx.inputEntries[key])
 if not expected then C.misses=C.misses+1;return end
 local ok,result=pcall(function()
  -- Version 2 stores each identical payload once, under its existing SHA-256.
  -- Keep version 1 readable and retain all source/native/content checks.
  local filename=key
  if idx.version==2 then
   assert(type(expected)=='string'and #expected==64 and expected:match('^[0-9a-f]+$'),'invalid geometry content address')
   filename=expected
  end
  local policy=V.require('DioramaConfig').renderCache
  if policy.prefetch~=false then
   local uploaded=policy.gpuWarm~=false and V.require('GeometryGpuWarm').take(expected)
   if uploaded then ownRestore(uploaded.pendingObjects);return C.activate(uploaded,def,ts,ox,oz)end
   local prefetch=V.require('GeometryPrefetch')
   local prepared=prefetch.take(expected)
   if not prepared and Budget.ownsCurrent()then
    prepared=prefetch.await({digest=expected,filename=filename})
   end
   if prepared then return C.restore(prepared,def,ts,ox,oz)end
  end
  local raw=assert(V.mod:read(root..filename..'.data'),'missing geometry record')
  assert(hash(raw)==expected,'geometry checksum mismatch')
  return C.restore(C.decode(raw),def,ts,ox,oz)
 end)
 if ok then C.hits=C.hits+1;return result end
 C.errors[key]=tostring(result);idx.entries[key]=nil;if idx.inputEntries then idx.inputEntries[key]=nil end;C.misses=C.misses+1
end
return C
