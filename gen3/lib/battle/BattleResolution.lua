-- Cap offscreen pixels, never logical battle coordinates or viewport fitting.
-- Changing quality during battle is handled by existing canvas resize paths.
local V=...
local R={}
local function finite(value,default)
 value=tonumber(value)
 if not value or value~=value or value==math.huge or value==-math.huge then return default end
 return value
end
function R.limit()
 local limit=math.max(1,math.min(8,math.floor(finite(V.require('DioramaConfig').settings.battleResolution,4))))
 -- Match the field's mobile pixel budget. Native UI keeps drawable resolution;
 -- only the 240 x 160 scenery/sprite intermediates are bounded.
 if V.require('MobileRenderBudget').active()then
  local budget=V.require('MobileRenderBudget')
  limit=math.min(limit,math.floor(math.min(budget.maxEdge/240,math.sqrt(budget.maxPixels/(240*160)))))
 end
 return math.max(1,limit)
end
function R.sprites(fit)
 local c=V.require('DioramaConfig').battle
 local limit=R.limit();local base=math.max(1,math.min(limit,math.floor(finite(c.spriteResolution,1))))
 if c.spriteScreenResolution==false then return base end
 return math.max(base,math.min(limit,math.ceil(finite(fit,1))))
end
function R.scenery(fit)
 local limit=R.limit()
 return math.min(limit,math.max(4,math.ceil(math.max(0,finite(fit,1))*1.5)))
end
return R
