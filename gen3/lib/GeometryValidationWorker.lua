-- Appended to the mod-owned codec and index validator. One bounded job, then
-- terminate. Only validated index data or an error returns to the main state.
local results,root,raw=...
require('love.filesystem');require('love.data')
local ok,value=pcall(function()
 assert(type(root)=='string'and root~=''and not root:match('^[/\\]')and not root:find('..',1,true),'invalid mod root')
 local function read(path)
  local info=love.filesystem.getInfo(path)
  assert(info and info.type=='file'and info.size<=4*1024*1024,'source missing/oversized: '..path)
  return love.filesystem.read(path)
 end
 return validator.validate(raw,function(p)return read(root..'/'..p)end,read)
end)
-- Return the authenticated original bytes, avoiding Channel's atomic copy of
-- thousands of index/scenes tables. The renderer parses these in slices.
results:push({ok=ok,raw=ok and raw or nil,error=not ok and tostring(value)or nil})
