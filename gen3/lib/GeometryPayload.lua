-- Shared by the main state and our own read-only cache worker.
-- OGC4 puts equal vertex-byte lanes together before zlib compression. Every
-- float bit is restored before upload. OGC2/OGC3 remain readable.
local V=...
local P={}
local limit=128*1024*1024
local hasFfi,ffi=pcall(require,'ffi')
local function lanes(bytes,width,inverse,checkpoint)
 assert(type(bytes)=='string'and #bytes<=limit,'invalid vertex bytes')
 if #bytes==0 or #bytes%width~=0 then return bytes end
 local count=#bytes/width
 if hasFfi then
  local input=ffi.cast('const uint8_t*',bytes)
  local output=ffi.new('uint8_t[?]',#bytes)
  for lane=0,width-1 do
   for row=0,count-1 do
    local vertex=row*width+lane;local plane=lane*count+row
    if inverse then output[vertex]=input[plane]else output[plane]=input[vertex]end
    if checkpoint and row%65536==65535 then checkpoint()end
   end
  end
  return ffi.string(output,#bytes)
 end
 -- Portable fallback for LÖVE builds without LuaJIT; bound temporary tables.
 local pieces,chunk={},{}
 for i=0,#bytes-1 do
  local source=inverse and (i%width)*count+math.floor(i/width)
    or (i%count)*width+math.floor(i/count)
  chunk[#chunk+1]=bytes:sub(source+1,source+1)
  if #chunk==8192 then pieces[#pieces+1]=table.concat(chunk);chunk={};if checkpoint then checkpoint()end end
 end
 pieces[#pieces+1]=table.concat(chunk);return table.concat(pieces)
end
local function transform(record,inverse,checkpoint)
 local result={};for k,v in pairs(record)do result[k]=v end
 if type(record.mesh)=='string'then result.mesh=lanes(record.mesh,36,inverse,checkpoint)end
 if type(record.instances)=='table'then
  result.instances={}
  for k,b in pairs(record.instances)do
   assert(type(b)=='table','invalid mesh instance');local copy={};for n,v in pairs(b)do copy[n]=v end
   if type(b.mesh)=='string'then copy.mesh=lanes(b.mesh,36,inverse,checkpoint)end
   if type(b.placements)=='string'then copy.placements=lanes(b.placements,12,inverse,checkpoint)end
   result.instances[k]=copy
  end
 end
 return result
end
function P.encode(record)
 local decoded=V.require('RenderCacheCodec').encode(transform(record,false))
 assert(#decoded>0 and #decoded<=limit,'scene decoded size')
 local compressed=love.data.compress('string','zlib',decoded,9)
 assert(#compressed<=limit-12,'scene compressed size')
 return 'OGC4'..love.data.pack('string','<I4I4',#decoded,#compressed)..compressed
end
function P.decode(raw,checkpoint,readChunk,maxBytes)
 maxBytes=maxBytes or limit
 assert(type(maxBytes)=='number'and maxBytes>0 and maxBytes<=limit,'scene decode budget')
 assert(type(raw)=='string'and #raw>=8 and #raw<=limit,'invalid scene envelope')
 local magic=raw:sub(1,4)
 assert(magic=='OGC2'or magic=='OGC3'or magic=='OGC4'or magic=='OGC5','invalid scene envelope')
 local size=love.data.unpack('<I4',raw,5)
 assert(size>0 and size<=maxBytes,'scene decoded size')
 local decoded
 if magic~='OGC2'then
  assert(#raw>=12,'truncated scene envelope')
  local compressedSize=love.data.unpack('<I4',raw,9)
  assert(compressedSize>0 and compressedSize==#raw-12,'scene compressed length mismatch')
  decoded=love.data.decompress('string','zlib',raw:sub(13))
 else decoded=love.data.decompress('string','lz4',raw:sub(5))end
 assert(#decoded==size,'scene length mismatch')
 if checkpoint then checkpoint()end
 local record=V.require('RenderCacheCodec').decode(decoded,checkpoint)
 if magic=='OGC5'then
  assert(type(readChunk)=='function','geometry chunk reader unavailable')
  local total=0
  local function expand(value,width)
   assert(type(value)=='table'and value.lanes==width and type(value.bytes)=='number'
    and value.bytes>0 and value.bytes<=maxBytes-size-total and value.bytes%width==0
    and type(value.chunks)=='table'and #value.chunks>=1 and #value.chunks<=16384,'invalid chunked mesh')
   local parts,n={},0
   for i,digest in ipairs(value.chunks)do
    local part=readChunk(digest);n=n+#part;total=total+#part
    assert(n<=value.bytes and size+total<=maxBytes,'chunked scene size')
    parts[i]=part;if checkpoint then checkpoint()end
   end
   assert(n==value.bytes,'chunked mesh length');return table.concat(parts)
  end
  if type(record.mesh)=='table'then record.mesh=expand(record.mesh,36)end
  if type(record.instances)=='table'then for _,b in pairs(record.instances)do
   if type(b.mesh)=='table'then b.mesh=expand(b.mesh,36)end
   if type(b.placements)=='table'then b.placements=expand(b.placements,12)end
  end end
  size=size+total;assert(size<=maxBytes,'expanded scene size')
 end
 if magic=='OGC4'or magic=='OGC5'then record=transform(record,true,checkpoint)end
 return record,size
end
return P
