-- Solar-only rendering rig. Moonlight, caves and game clocks are untouched.
local V=...
local D={}
local function mix(a,b,t)return a+(b-a)*t end
local function rgb(a,b,t)return {mix(a[1],b[1],t),mix(a[2],b[2],t),mix(a[3],b[3],t)}end
function D.prepare(outdoors,time)
 local cfg=V.require('DioramaConfig').daylight
 if not outdoors or not cfg.enabled then return nil end
 local DN=V.require('DayNight');local az,el,moon=DN.bodyAt(time)
 local phase=DN.mix(time)
 local weight=math.min(1,(phase.day or 0)+(phase.golden or 0)+(phase.dusk or 0)+(phase.dawn or 0))
 if weight<=0 or moon and not (phase.dusk or phase.dawn)then return nil end
 local warm=math.min(1,(phase.golden or 0)+(phase.dusk or 0)+(phase.dawn or 0))
 az=math.rad(mix(az,cfg.goldenAzimuth,warm));el=math.rad(mix(el,cfg.goldenElevation,warm))
 local k=math.min(cfg.maxShadowShear,1/math.max(.1,math.tan(el)))
 local length=mix(cfg.dayShadowLength,cfg.goldenShadowLength,warm)
 return {weight=weight,ambient=rgb(cfg.dayAmbient,cfg.goldenAmbient,warm),sunColor=rgb(cfg.daySunColor,cfg.goldenSunColor,warm),
  sun=mix(cfg.daySunStrength,cfg.goldenSunStrength,warm),direction={math.cos(az)*math.cos(el),math.sin(el),math.sin(az)*math.cos(el)},
  shear={-math.cos(az)*k*length,-math.sin(az)*k*length},shadowStrength=cfg.shadowStrength,
  shadowSoftness=cfg.shadowSoftness,buildingShadows=cfg.buildingShadows,saturation=1+(cfg.saturation-1)*weight,warm=warm}
end
return D
