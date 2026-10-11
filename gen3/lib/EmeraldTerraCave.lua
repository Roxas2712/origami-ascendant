-- Terra Cave's native lava pool: emission and stationary 3D bounce lights.
-- This is presentation only; legendary encounter/weather scripts stay native.
local V=...
local T={}
function T.profile(d)
 local c=V.require('DioramaConfig').terraCave
 return d and d.id=='EM_TERRA_CAVE_END'and d.pair=='general__cave'
  and tonumber(d.mapType)==4 and c.enabled and c or nil
end
function T.active(d)
 return T.profile(d)and V.require('DioramaConfig').billboards.enabled
  and V.require('Camera').projection()=='perspective'
end
function T.light(d,result,time)
 if not T.active(d)then return end
 local c=T.profile(d).lighting
 if not c.enabled then return end
 for i,p in ipairs(c.sources)do
  -- All three anchors are inside complete native lava tiles. If scripts
  -- replace the pool, do not keep a light hovering over the replacement.
  local mid=d.midLayout:midAt(p[1],p[2])
  if mid==0x35f or mid==0x364 then
   result.lights[#result.lights+1]={x=p[1]*16+8,z=p[2]*16+8,y=c.height,
    radius=-c.radius,power=c.power*(1+c.flicker*math.sin(time*c.speed+i*c.phaseStep)),
    color=c.color,point=true,kind='terraLava',falloff=c.falloff}
  end
 end
end
return T
