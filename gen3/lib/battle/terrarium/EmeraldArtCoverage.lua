-- Rendering a family fallback is not evidence of bespoke location artwork.
-- This is shared by the renderer's diagnostics and the complete map audit.
local C={}
function C.resolve(h,registry)
 local exact=registry[h.key]
 if exact then return exact,'dedicated',h.key end
 local base=registry[h.family]
 if base then
  local shared=h.landmark~=nil or h.family=='underwater'
  return base,shared and'shared' or'base',h.family
 end
 if h.family=='forest'and not h.landmark then return nil,'baseline','forest'end
 return nil,'missing','forest'
end
return C
