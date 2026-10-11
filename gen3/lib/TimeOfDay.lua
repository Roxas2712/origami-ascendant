-- One continuous render-only rig; never writes cartridge time or map data.
local V=...
local T={}
local function blend(a,b,u)
 if type(a)=='table' then local c={} for i=1,#a do c[i]=blend(a[i],b[i],u)end return c end
 return a+(b-a)*u
end
local function night(c)
 local cfg=V.require('DioramaConfig');local DN=V.require('DayNight')
 local az,el=DN.bodyAt(900);az,el=math.rad(az),math.rad(el)
 local dx,dz=DN.shearAt(900)
 return {ambient=cfg.lighting.nightAmbient,direction={math.cos(az)*math.cos(el),math.sin(el),math.sin(az)*math.cos(el)},
  sun=.13*math.sin(el),sunColor={1,1,1},shear={dx*cfg.shadows.nightLength,dz*cfg.shadows.nightLength},
  shadowStrength=.20,shadowSoftness=0,buildingWeight=0,saturation=1,lamps=1,bloom=1,warm=0,transmission=0,evening=0,night=1,dof=1,foregroundDof=1,grass=0}
end
local function frame(f)
 if f.night then return night()end
 local cfg=V.require('DioramaConfig').daylight
 local tuning=cfg.enabled and cfg.cycleSun and cfg.cycleSun.enabled and cfg.cycleSun
 local key=f.time==0 and 'dawn' or f.time==300 and 'day' or f.time==560 and 'golden'
 local sun=tuning and key and tuning[key]
 local evening=cfg.enabled and cfg.goldenHour and cfg.goldenHour.enabled and key=='golden' and cfg.goldenHour
 local az,el=math.rad(sun and sun.azimuth or f.azimuth),math.rad(sun and sun.elevation or f.elevation)
 local k=math.min(cfg.maxShadowShear,1/math.max(.1,math.tan(el)))*(sun and sun.length or f.length)
 -- Lowering the sun must not erase its floor illumination a second time.
 -- Preserve source-keyframe irradiance, then apply the explicit solar gain.
 local power=f.sun
 if sun then power=power*math.sin(math.rad(f.elevation))/math.sin(el)*sun.sunScale end
 return {evening=evening and 1 or 0,ambient=evening and evening.ambient or f.ambient,direction={math.cos(az)*math.cos(el),math.sin(el),math.sin(az)*math.cos(el)},sun=power,sunColor=evening and evening.color or sun and sun.color or f.color,
  shear={-math.cos(az)*k,-math.sin(az)*k},shadowStrength=sun and sun.shadow or f.shadow,shadowSoftness=sun and sun.softness or f.softness,buildingWeight=f.cast,
  saturation=f.saturation,lamps=f.lamps,bloom=f.bloom,warm=f.warm,transmission=f.transmission or 1,night=0,dof=f.dof or 1,foregroundDof=f.foregroundDof or 1,grass=f.grass or 0}
end
local function sunset(out,t)
 local daylight=V.require('DioramaConfig').daylight
 local c=daylight.redDusk
 out.dusk=0;out.duskAmbientOcclusion=c and c.ambientOcclusion or 0
 if not daylight.enabled or not c or not c.enabled or t<=c.start or t>=c.finish then return end
 local u=t<c.peak and (t-c.start)/(c.peak-c.start)or(c.finish-t)/(c.finish-c.peak)
 local w=u*u*(3-2*u)
 local az,el=math.rad(c.azimuth),math.rad(c.elevation)
 local k=math.min(daylight.maxShadowShear,1/math.max(.1,math.tan(el)))*c.length
 local target={ambient=c.ambient,sunColor=c.color,sun=c.groundSun/math.sin(el),
  direction={math.cos(az)*math.cos(el),math.sin(el),math.sin(az)*math.cos(el)},
  shear={-math.cos(az)*k,-math.sin(az)*k},shadowStrength=c.shadow,
  shadowSoftness=c.softness,buildingWeight=1}
 for key,value in pairs(target)do out[key]=blend(out[key],value,w)end
 -- Lamps/fireflies retain their existing continuous curve; room windows use it too.
 out.dusk=w
end
local function segment(time)
 local c=V.require('DioramaConfig').cycle
 local t=(time%1200);local frames=c.keyframes
 for i=1,#frames-1 do
  local a,b=frames[i],frames[i+1]
  if t>=a.time and t<b.time then
   local u=(t-a.time)/(b.time-a.time);u=u*u*(3-2*u)
   return t,a,b.repeatDawn and frames[1]or b,u
  end
 end
end
-- Window/firefly callers only need this scalar. Do not allocate two complete
-- rigs and their blended vectors for every lamp query. Read the live keyframes
-- each time so edits and presets take effect immediately, without a stale cache.
function T.lamps(time)
 local _,a,b,u=segment(time)
 if not a then return nil end
 local from,to=a.night and 1 or a.lamps,b.night and 1 or b.lamps
 return from+(to-from)*u
end
function T.sample(time)
 local t,a,b,u=segment(time)
 if not a then return nil end
 local ra,rb=frame(a),frame(b);local out={}
 for k,v in pairs(ra)do out[k]=blend(v,rb[k],u)end
 out.lutA=a.lut or (a.night and 'night' or 'neutral');out.lutB=b.lut or (b.night and 'night' or 'neutral');out.lutMix=u
 sunset(out,t)
 out.weight=1;out.buildingShadows=out.buildingWeight>0
 return out
end
return T
