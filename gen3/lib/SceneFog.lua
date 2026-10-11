-- World-anchored banks: weather outdoors, intermittent low mist in natural caves.
-- Reuses the Tower shader without its darkness, wisps or FLASH ownership.
local V=...
local F={weatherColor={},weatherLight={}}
local function smooth(x)x=math.max(0,math.min(1,x));return x*x*(3-2*x)end
-- Lavender's local mist arrives in uneven apparitions, with genuinely clear
-- gaps. Pure clock sampling keeps visits and frozen captures deterministic.
local apparitions={{7,3,5,2},{34,2.5,7,2},{62,4,4,1.6}}
function F.lavenderEnvelope(time)
 local t=time%84
 for _,p in ipairs(apparitions)do
  local age=t-p[1]
  if age>=0 and age<p[2]+p[3]+p[4]then
   return smooth(age/p[2])*(1-smooth((age-p[2]-p[3])/p[4]))
  end
 end
 return 0
end
function F.weatherAmount(def,amount,time)
 -- A local apparition during calm AUTO weather, not a new regional front.
 -- The envelope owns its fade; explicit CLEAR/native and precipitation keep
 -- their normal weather. No mutation of the shared weather state is needed.
 if def and def.id=='FR_LAVENDER_TOWN'and V.data('Shapes').outdoors(def)then
  local weather=V.require('Weather');local selected=weather.setting:get()
  if selected=='auto'and weather.modeAt({id=def.id,def=def},selected,time)=='clear'then
   return math.max(amount or 0,V.require('DioramaConfig').weather.fogDensity)
  end
 end
 return amount
end
function F.envelope(time,seed)
 local c=V.require('DioramaConfig').weather.fog
 local phase=((time+(seed or 0))%c.period)/c.period
 -- Clear pause, slow arrival, lingering bank, slow retreat. Continuous slope.
 return smooth((phase-.15)/.25)*(1-smooth((phase-.65)/.30))
end
function F.params(def,amount,time)
 local w=V.require('DioramaConfig').weather;local c=w.fog
 if not(w.enabled and c.enabled and def)or V.require('HauntedFog').active(def)then return end
 local outside=V.data('Shapes').outdoors(def)
 local cave=not outside and tonumber(def.mapType)==4 and c.naturalPairs[(def.renderPair or def.pair)]
 if not outside and not cave then return end
 local seed=0;for i=1,#(def.id or '')do seed=(seed*31+def.id:byte(i))%997 end
 local wave=F.envelope(time,cave and seed or 0)
 -- Fog weather keeps a low bank between passing thicker banks. The clear
 -- pause belongs to intermittent cave mist; the weather transition already
 -- fades outdoor fog in/out through amount.
 if outside then wave=.4+.6*wave end
 local density=outside and (amount or 0)*(c.minDensity+(c.maxDensity-c.minDensity)*wave)
   or c.caveDensity*wave
 -- Weather fog is a deep bank, not the thin ground mist used in caves.
 -- Optical depth scales with the weather fade; clear weather stays exact.
 if outside then density=density*(c.weatherDensityScale or 3)end
 if outside and def.id=='FR_LAVENDER_TOWN'then
  density=(amount or 0)*c.maxDensity*(c.weatherDensityScale or 3)*F.lavenderEnvelope(time)
 end
 if density<=.0001 then return end
 return {density=density,surge=false,pocket=c.pocket,color=outside and c.color or c.caveColor,
   light=outside and c.light or c.caveLight,
   height=outside and (c.weatherHeight or 64)or nil,
   clearCore=outside and (c.weatherClearCore or .7)or c.clearCore,
   ribbonMix=c.ribbonMix,preserveVoid=true}
end
function F.apply(canvas,def,vp,x,z,time,amount,hasLocalVeil,context)
 amount=F.weatherAmount(def,amount,time)
 local params=not hasLocalVeil and F.params(def,amount,time)
 if not params then return canvas,false end
 if context and context.outdoors then
  -- Moonlit scattering must separate from the dark road beneath it. Reusing
  -- the forest/cave veil's .22/.30/.42 multiplier made fog look like dimming.
  local solar=context.solar or {};local night=solar.night or 0
  local tint=solar.sunColor
  for i=1,3 do
   local moon=i==1 and .55 or i==2 and .60 or .72
   F.weatherColor[i]=params.color[i]*(1-night+moon*night)
   F.weatherLight[i]=params.light[i]*((1-night)*(.85+.15*(tint and tint[i]or 1))+moon*night)
  end
  params.color,params.light,params.preTinted=F.weatherColor,F.weatherLight,true
 end
 if V.renderSeams then params=V.renderSeams.chain('fogParams',params,def)end
 return V.require('HauntedFog').apply(canvas,vp,x,z,time,params,context),true
end
return F
