-- Native Dig supplies the depth. Render an opaque cutout through the paper
-- floor instead of reflecting its downward offsets into airborne bounces.
local D={}
local function clamp(x)return math.max(0,math.min(1,x))end
function D.sample(phase,oy,height,age,invisible)
 local depth=clamp(math.max(0,oy or 0)/math.max(1,height))
 local hole=clamp((age or 0)/.22)
 if phase=='hidden'or phase=='waitingUp'then depth=1;hole=1 end
 if phase=='up'then hole=1 end
 if phase=='closing'then depth=0;hole=1-clamp((age or 0)/.4)end
 return {depth=depth,hole=hole,visible=not invisible and depth<1 and phase~='hidden'and phase~='waitingUp',
  sink=depth*height,lift=phase=='closing'and 2.4*math.sin(math.pi*clamp((age or 0)/.35))or 0}
end
return D
