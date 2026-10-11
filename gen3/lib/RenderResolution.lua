-- Keep screen-sized field rendering separate from world/geometry settings.
-- Supersampling is optional: never rewrite the user's quality/effect options.
local V=...
local R={}
function R.scale()
 local scale=V.require('DioramaConfig').settings.renderScale or 1
 if V.mod.options:get('gen3Supersampling')==true then return scale end
 return math.min(1,scale)
end
function R.dimensions(w,h)
 local mobile=V.require('MobileRenderBudget')
 if mobile.active()then return mobile.dimensions(w,h)end
 if V.mod.options:get('gen3Supersampling')==true then return w,h end
 -- Integer reduction preserves nearest-neighbour pixel edges on Retina.
 -- Native UI remains at drawable resolution; only the world is bounded.
 local divisor=math.max(1,math.ceil(math.max(w/1920,h/1920,math.sqrt(w*h/2073600))))
 return math.max(1,math.floor(w/divisor)),math.max(1,math.floor(h/divisor))
end
return R
