-- Local presentation: accumulated snow tracks and generated snow/wet footsteps.
-- Never changes native movement, RNG, collision, weather or sound settings.
local V=...
local S={clock=0,maps={},sounds={},steps=0,played=0}
local function tracks(id)return S.maps[id]or{}end
function S.sample(dt,id,x,z,active,snow,wet)
 S.clock=S.clock+math.max(0,math.min(dt or 0,.25))
 local last=S.last;S.last={id=id,x=x,z=z,active=active}
 if not active or not last or not last.active or last.id~=id then S.distance=0;return end
 local dx,dz=x-last.x,z-last.z;local d=math.sqrt(dx*dx+dz*dz)
 if d>24 then S.distance=0;return end -- warp/teleport cannot leave a trail
 S.distance=(S.distance or 0)+d
 if S.distance<8 then return end
 S.distance=S.distance%8
 local kind=snow>.12 and'snow'or wet and'wet'or nil
 if not kind then return end
 S.steps=S.steps+1
 if kind=='snow'then
  local a=math.atan2(dz,dx);local side=S.steps%2==0 and 1.6 or -1.6
  local list=tracks(id);S.maps[id]=list
  -- Prune expired tracks across visited maps; at most 24 footprints per map.
  for map,old in pairs(S.maps)do if map~=id and (#old==0 or S.clock-old[#old].time>65)then S.maps[map]=nil end end
  list[#list+1]={x=x-math.sin(a)*side,z=z+math.cos(a)*side,angle=a,time=S.clock}
  if #list>24 then table.remove(list,1)end
 end
 return kind
end
-- Small deterministic foley voices: liquid impact/droplets or dry snow friction.
-- Private seeds never consume gameplay RNG. Four voices let the tail of a
-- splash finish under the next footstep instead of cutting it off immediately.
function S.pcm(kind,variant)
 assert(kind=='wet'or kind=='snow','unknown footstep surface')
 variant=((variant or 1)-1)%4+1
 local rate=22050;local duration=kind=='wet'and .29 or .34
 local n=math.floor(rate*duration);local samples={};local peak=0
 local seed=1729+variant*7919;local low,soft,band1,band2=0,0,0,0
 local phase=0;local pi=math.pi
 local function random()
  seed=seed*48271%2147483647;return seed/1073741823.5-1
 end
 local drops={}
 for j=1,7 do
  drops[j]={at=.018+j*.023+random()*.009,f=550+j*130+random()*170,amp=.10+random()*.035}
 end
 for i=0,n-1 do
  local t=i/rate;local noise=random()
  low=low*.78+noise*.22;soft=soft*.96+noise*.04
  local signal
  if kind=='wet'then
   -- A low hollow impact, broad water displacement, then separate bubbles.
   local hit=math.sin(2*pi*(155*t-180*t*t))*math.exp(-t*48)*.42
   local splash=(low-soft)*2.1*math.exp(-t*15)
   local spray=(noise-low)*.13*math.exp(-t*24)
   local droplets=0
   for _,q in ipairs(drops)do
    local u=t-q.at
    if u>0 then
     local onset=math.min(1,u/.002)
     droplets=droplets+q.amp*math.sin(2*pi*q.f*(u-1.3*u*u))*math.exp(-u*55)*onset
    end
   end
   signal=hit+splash+spray+droplets
  else
   -- Granular compression followed by a friction squeak as the sole twists.
   -- A noise-driven resonator avoids a pure electronic whistle.
   local pressure=math.sin(pi*math.min(1,t/.29))^1.4
   local stick=.58+.42*math.sin(2*pi*(43*t+24*t*t)+variant)^2
   local freq=1050+variant*45+720*math.sin(pi*math.min(1,t/.30))
   local radius=.965
   local resonant=(1-radius)*noise+2*radius*math.cos(2*pi*freq/rate)*band1-radius*radius*band2
   band2=band1;band1=resonant
   phase=phase+2*pi*freq/rate
   local squeak=(resonant*1.6+math.sin(phase)*.055)*pressure*stick
   local crunch=(noise-low)*.30*(.24+.76*math.sin(2*pi*91*t+variant)^8)*math.exp(-t*9)
   local compress=soft*.75*math.exp(-t*16)
   signal=compress+crunch+squeak
  end
  local edge=math.min(1,t/.003)*math.min(1,(duration-t)/.035)
  signal=signal*edge;samples[i+1]=signal;peak=math.max(peak,math.abs(signal))
 end
 local data=love.sound.newSoundData(n,rate,16,1)
 local gain=.82/math.max(peak,.001)
 for i=0,n-1 do data:setSample(i,samples[i+1]*gain)end
 return data
end
function S.play(kind)
 if not(love.audio and love.sound)then return false end
 local volume=require('src.core.game3.audio')._sfxVolume or 1
 if volume<=0 then return false end
 S.voices=S.voices or {};local voices=S.voices[kind]or{};S.voices[kind]=voices
 local voice=S.played%4+1;local source=voices[voice]or V.require('FoleyBank').get(kind..'-'..voice)
 if not source then local data=S.pcm(kind,voice);source=love.audio.newSource(data,'static');data:release();voices[voice]=source end
 S.sounds[kind]=source
 source:stop();source:setVolume(volume*.34);source:play();S.played=S.played+1;return true
end
function S.update(game,dt,id,def)
 local P=V.require('WorldAdapter').Player
 local active=id and def and V.data('Shapes').outdoors(def)and not require('src.core.game3.battle').isActive()and not P.surfing and not P.biking and not P.jumping and not P.underwater
 local cfg=V.require('DioramaConfig').weather
 -- Use the rendered ground cover, not stale precipitation state when weather
 -- is disabled or the current map hides snow. Stop any remaining foley tails.
 local snow=active and cfg.enabled and (V.require('Weather').visual.snow or 0)*(cfg.snow.cover or 0)or 0
 if snow<=.12 then
  for _,voice in pairs(S.voices and S.voices.snow or {})do voice:stop()end
  if S.sounds.snow then S.sounds.snow:stop()end
 end
 local map=id and{id=id,def=def}or nil
 local mode=V.require('Weather').mode(map)
 local mood=V.require('WeatherMood').sample(map)
 local kind=S.sample(dt,id,P.px+8,P.py+16,not not active,snow,V.require('WeatherMood').rainAmount(mode,mood)>.15 or V.require('Puddles').amount>.15)
 if kind then S.play(kind)end
end
function S.bind(shader,id,enabled)
 local list={}
 if enabled then for _,p in ipairs(tracks(id))do
  local fade=math.max(0,1-(S.clock-p.time)/65)
  if fade>0 then list[#list+1]={p.x,p.z,p.angle,fade}end
 end end
 shader:send('snowTrackCount',#list)
 if #list>0 then shader:send('snowTracks',unpack(list))end
end
function S.reset()S.last=nil;S.distance=0;S.maps={};S.clock=0 end
S.fragment=[[
uniform float snowTrackCount;
uniform vec4 snowTracks[24];
float snowTrack(vec2 p){
 float mark=0.0;
 for(int i=0;i<24;i++){if(float(i)<snowTrackCount){
  vec4 f=snowTracks[i];vec2 d=p-f.xy;float c=cos(f.z),s=sin(f.z);
  vec2 q=vec2(c*d.x+s*d.y,-s*d.x+c*d.y)/vec2(2.9,1.3);
  mark=max(mark,(1.0-smoothstep(.6,1.0,length(q)))*f.w);
 }}
 return mark;
}
]]
return S
