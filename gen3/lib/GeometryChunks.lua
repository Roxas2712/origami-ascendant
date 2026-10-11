-- Data-only, authenticated cache-bank reads. The caller owns file access;
-- the worker can seek, while a synchronous fallback can use its mod reader.
local V=...
local C={}
function C.reader(read,maxCachedBytes)
 maxCachedBytes=maxCachedBytes or 4*1024*1024
 assert(type(maxCachedBytes)=='number'and maxCachedBytes>=65536 and maxCachedBytes<=4*1024*1024,'chunk retention budget')
 local index,cached,used,touched,tick=nil,{},0,{},0
 return function(digest)
  assert(type(digest)=='string'and #digest==64 and digest:match('^[0-9a-f]+$'),'invalid chunk digest')
  tick=tick+1
  if cached[digest]then touched[digest]=tick;return cached[digest]end
  if not index then
   local raw=assert(read('gen3/render-cache/chunks.index'),'missing geometry chunk index')
   assert(#raw<=8*1024*1024,'chunk index size')
   index=V.require('RenderCacheCodec').decode(raw)
   assert(index.version==1 and type(index.entries)=='table'and type(index.bytes)=='number'and index.bytes>0 and index.bytes<=128*1024*1024,'invalid chunk index')
  end
  local row=assert(index.entries[digest],'missing geometry chunk')
  assert(type(row)=='table'and type(row.offset)=='number'and row.offset>=0 and row.offset%1==0
   and type(row.size)=='number'and row.size>=5 and row.size<=128*1024 and row.size%1==0
   and row.offset+row.size<=index.bytes,'invalid chunk address')
  local packed=assert(read('gen3/render-cache/chunks.bank',row.offset,row.size),'missing chunk bank')
  assert(#packed==row.size,'truncated geometry chunk')
  local size=love.data.unpack('<I4',packed)
  assert(size>0 and size<=65536,'geometry chunk decoded size')
  local raw=love.data.decompress('string','zlib',packed:sub(5))
  assert(#raw==size and love.data.encode('string','hex',love.data.hash('sha256',raw))==digest,'geometry chunk checksum')
  while used+#raw>maxCachedBytes do
   local oldest,age;for key,t in pairs(touched)do if not age or t<age then oldest,age=key,t end end
   if not oldest then break end
   used=used-#cached[oldest];cached[oldest],touched[oldest]=nil,nil
  end
  cached[digest]=raw;touched[digest]=tick;used=used+#raw
  return raw
 end
end
return C
