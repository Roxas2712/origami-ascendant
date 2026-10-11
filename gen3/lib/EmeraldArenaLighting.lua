-- Fixed ceiling lights and measured blockers for the three Battle Arena rooms.
local V=...;local A={}
function A.profile(d)
 local arena=V.require('EmeraldBattleArena');local _,kind=arena.kind(d)
 if not(kind and arena.profile(d))then return end
 local c=V.require('DioramaConfig').emeraldInteriors.battleArena.lighting
 return c.enabled and c[kind]or nil
end
function A.capture(list,o,x,z)
 if not o.kind:match('^arena')then return false end
 if o.kind=='arenaWall'then return false end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battleArena
 local function box(a,b,back,front,low,high)
  list[#list+1]={lo={x+a,low*cfg.heightScale,z+back},hi={x+b,high*cfg.heightScale,z+front},wall=false}
 end
 if o.kind=='arenaBench'then
  -- Preserve the air underneath the native open-legged bench.
  box(0,o.w,4,o.h-5,c.benchHeight-c.lighting.slabThickness,c.benchHeight)
 elseif o.kind=='arenaMonitor'then
  box(9,39,23.75,24.25,o.base,o.base+c.monitorHeight)
 elseif o.kind=='arenaDevice'then
  box(1,15,20.75,21.25,o.base,o.base+c.deviceHeight)
 elseif o.kind=='arenaPC'then
  box(1,15,39.75,40.25,0,c.pcHeight)
 end
 -- Dais tiles, mats and ramps are continuous walking surfaces, not dozens of
 -- shadow boxes. Their existing front faces/contact shading remain visible.
 -- Plants keep the native masked silhouette rather than a rectangular caster.
 return true
end
return A
