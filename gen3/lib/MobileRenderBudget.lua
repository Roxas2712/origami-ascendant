-- Bound intermediate field targets on mobile independently of user options.
-- Native UI/presentation still uses the drawable size and the same framing.
local B={maxPixels=1280*720,maxEdge=1280}
function B.active()
 local os=love.system and love.system.getOS and love.system.getOS()
 return os=='iOS' or os=='Android'
end
function B.dimensions(w,h)
 if not B.active()then return w,h end
 local scale=math.min(1,B.maxEdge/math.max(w,h),math.sqrt(B.maxPixels/(w*h)))
 return math.max(1,math.floor(w*scale)),math.max(1,math.floor(h*scale))
end
function B.enter(renderer,id)
 if not B.active()then B.map=nil;return end
 if B.map and B.map~=id then renderer.invalidate()end
 B.map=id
end
return B
