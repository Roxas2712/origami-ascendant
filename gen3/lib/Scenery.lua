-- Scope new scenery animation to outdoors while keeping accepted night views.
local V=...
local S={}
function S.active(def,outdoors,night)
 return outdoors and not (night>.5 and V.require('DioramaConfig').scenery.preserveNightMaps[def.id or def.name])
end
function S.water(def,outdoors,night)
 local c=V.require('DioramaConfig').water
 local fade=V.require('DioramaConfig').scenery.preserveNightMaps[def.id or def.name]and (1-night)or 1
 return {c.sparkleCellSize,outdoors and c.sparklesEnabled and c.sparkleStrength*fade or 0,c.sparkleDensity,c.sparkleSpeed}
end
function S.fireflyVisibility(night,cloud,snow)
 local function smooth(x)x=math.max(0,math.min(1,x));return x*x*(3-2*x)end
 return smooth((night-.3)/.5)*(1-smooth((cloud-.2)/.4))*(1-smooth((snow-.02)/.18))
end
function S.firefly(p,time,night)
 local c=V.require('DioramaConfig').fireflies
 local phase=time*c.driftSpeed+p.seed
 local pulse=.30+.70*(.5+.5*math.sin(time*1.35+p.seed))^2
 local fade=math.max(0,math.min(1,(night-c.nightStart)/(1-c.nightStart)))
 return {x=p.x+math.sin(phase)*c.driftRadius[1],z=p.z+math.cos(phase*.83)*c.driftRadius[2],
  y=c.height+math.sin(phase*1.8)*c.bobHeight,radius=-22,power=c.power*pulse*fade,
  color=c.color,kind='firefly',size=c.size,alpha=pulse*fade,
  -- Reference night clips: a few fireflies are bright enough to light the
  -- tree crowns they drift past.
  bright=c.bright and math.floor(p.seed*97)%c.bright.every==0}
end
return S
