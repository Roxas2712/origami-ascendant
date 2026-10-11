-- This source is appended to the mod-owned codec and payload modules. Channels
-- contain data only; no requested path or payload is evaluated as Lua code.
local requests,results,root=...
require('love.filesystem');require('love.data');require('love.thread');require('love.system')
local os=love.system.getOS()
local function digest(s)return type(s)=='string'and #s==64 and s:match('^[0-9a-f]+$')end
local bank
local readChunk=chunks.reader(function(path,offset,length)
 if not offset then return love.filesystem.read(root..'/'..path)end
 if not bank then
  local info=love.filesystem.getInfo(root..'/'..path)
  assert(info and info.type=='file'and info.size<=128*1024*1024,'invalid chunk bank')
  bank=assert(love.filesystem.newFile(root..'/'..path,'r'))
 end
 assert(bank:seek(offset),'chunk bank seek');return bank:read(length)
end,(os=='iOS'or os=='Android')and 512*1024 or nil)
while true do
 local request=requests:demand()
 if request==false then break end
 local ok,record,size=pcall(function()
  assert(digest(request.filename)and digest(request.digest),'invalid geometry address')
  local path=root..'/gen3/render-cache/'..request.filename..'.data'
  local info=love.filesystem.getInfo(path)
  assert(info and info.type=='file'and info.size>=8 and info.size<=128*1024*1024,'invalid geometry file size')
  local raw=assert(love.filesystem.read(path),'missing geometry record')
  assert(love.data.encode('string','hex',love.data.hash('sha256',raw))==request.digest,'geometry checksum mismatch')
  return payload.decode(raw,nil,readChunk,request.maxBytes)
 end)
 -- A Channel recursively copies table trees in one uninterruptible call.
 -- Hand over a flat, data-only blob; the main thread decodes it in slices.
 local transfer
 if ok then
  local encoded,value=pcall(codec.encode,record,0)
  if encoded then transfer=value else ok=false;record=value end
 end
 results:push({digest=request.digest,ok=ok,transfer=transfer,size=ok and size or 0,error=not ok and tostring(record)or nil})
end
if bank then bank:close()end
