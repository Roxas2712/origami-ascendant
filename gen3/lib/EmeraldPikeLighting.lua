-- Fixed lighting for measured Pike layouts, independent of random-room state.
local V=...;local P={}
function P.profile(d)
 local pike=V.require('EmeraldBattlePike');local _,kind=pike.kind(d)
 if not(kind and pike.profile(d))then return end
 local c=V.require('DioramaConfig').emeraldInteriors.battlePike.lighting
 return c.enabled and c[kind]or nil
end
function P.capture(list,o,x,z)
 if not o.kind:match('^pike')then return false end
 if o.kind=='pikeWall'then return false end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battlePike
 local function box(a,b,at,height)
  local half=c.lighting.blockerThickness/2
  list[#list+1]={lo={x+a,0,z+at-half},hi={x+b,height*cfg.heightScale,z+at+half},wall=false}
 end
 if o.kind=='pikePillar'then
  -- Never include the donor floor beneath the upright native column.
  box(2,14,32,c.pillarHeight)
 elseif o.kind=='pikeDevice'then
  box(o.shape=='display'and 9 or 1,o.shape=='display'and 39 or 15,o.last,c[o.shape..'Height'])
 end
 return true
end
return P
