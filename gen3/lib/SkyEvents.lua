-- Weather accents share the saved clock. Thunder is queued by simulation,
-- never by render count; the rainbow is a short-lived post-rain phenomenon.
local V=...
local S={sources={},pending={},played=0}
local function smooth(x)x=math.max(0,math.min(1,x));return x*x*(3-2*x)end
local function hash(n)return((n*48271+1729)*48271%2147483647)/2147483647 end
function S.enabled(map)
 local C=V.require('CloudDaylight')
 return C.supports(map and(map.def or map))and V.require('Weather').isOutdoor(map)and V.require('DioramaConfig').weather.enabled
  and C.setting:get()~='original'
end
function S.lightning(clock)
 local slot=math.floor(clock/41);local n=hash(slot+1)
 local start=slot*41+4+n*16;local phase=clock-start
 local distance=.5+hash(slot+17)*2.5
 local strength=0
 if phase>=0 and phase<.12 then strength=(1-phase/.12)^2
 elseif phase>=.19 and phase<.28 then strength=.42*(1-(phase-.19)/.09)^2 end
 local angle=hash(slot+91)*math.pi*2
 return strength,{key='front:'..slot,start=start,distance=distance,delay=distance*2.9,
  x=math.cos(angle),z=math.sin(angle),variant=slot%3}
end
function S.pcm(variant)
 variant=variant or 0
 local rate,duration=22050,4.4;local data=love.sound.newSoundData(math.floor(rate*duration),rate,16,1)
 local seed,low,deep=1729+(variant or 0)*7919,0,0
 for i=0,data:getSampleCount()-1 do
  seed=seed*48271%2147483647;local noise=seed/1073741823.5-1
  low=low*.87+noise*.13;deep=deep*.985+noise*.015
  local t=i/rate;local env=math.min(1,t/.018)*math.exp(-t*.95)*smooth((duration-t)/.8)
  local crack=low*1.3*math.exp(-t*7)
  local rumble=deep*3.6*(.75+.25*math.sin(t*8.7+variant))
  local rolling=low*.5*math.exp(-((t-1.15)/.45)^2)
  data:setSample(i,math.max(-.92,math.min(.92,(crack+rumble+rolling)*env)))
 end
 return data
end
function S.play(event)
 if not(love.audio and love.sound)then return false end
 local volume=require('src.core.game3.audio')._sfxVolume or 1
 if volume<=0 then return false end
 local source=S.sources[event.variant]or V.require('FoleyBank').get('thunder-'..event.variant)
 if not source then local data=S.pcm(event.variant);source=love.audio.newSource(data,'static');data:release();S.sources[event.variant]=source end
 source:stop();source:setVolume(volume*(.70-event.distance*.12))
 source:setPitch(1.04-event.distance*.045);source:setRelative(true);source:setPosition(event.x*.35,0,.5)
 source:play();S.played=S.played+1;return true
end
function S.update(dt,map,mode)
 local W=V.require('Weather');local clock=W.clock
 if not S.enabled(map)then S.reset();return end
 local previous=S.clock;S.clock=clock
 if previous and(clock<previous or clock-previous>2)then S.pending={}end
 if mode=='rain'or mode=='storm'then S.wet=(S.wet or 0)+math.max(0,dt)
 elseif mode=='clear'or mode=='heat'then
  if(S.wet or 0)>8 then S.lastRain=clock end;S.wet=0
 else S.wet=0 end
 local _,event=S.lightning(clock)
 local mood=V.require('WeatherMood').sample(map)
 local audible=not mood or(mood.precipMode=='storm'and mood.amount>.15)
 if audible and mode=='storm'and previous and clock>=previous and clock-previous<2 and previous<event.start and clock>=event.start then
  event.due=event.start+event.delay;S.pending[#S.pending+1]=event
 end
 for i=#S.pending,1,-1 do local e=S.pending[i]
  if clock>=e.due then S.play(e);table.remove(S.pending,i)end
 end
end
function S.rainbow(age,solar,mode)
 if not age or age<0 or age>140 or(mode~='clear'and mode~='heat'and mode~='rain')then return 0 end
 local d=solar and solar.direction
 if not d then return 0 end
 -- Low sun behind the viewer; the bow lies opposite the sun. No night bow.
 local angle=smooth((.68-d[2])/.18)*smooth((d[3]-.02)/.22)
 return smooth(age/18)*smooth((140-age)/35)*(1-(solar.night or 0))*angle
end
function S.prepare(map,mode,solar,clock,mood)
 if not S.enabled(map)then return {0,0,0,0}end
 local flash,event=S.lightning(clock)
 if mode~='storm'then flash=0 end
 flash=flash*(mood and(mood.precipMode=='storm'and mood.amount or 0)or 1)
 local W=V.require('Weather');local age=S.lastRain and clock-S.lastRain
 if W.setting:get()=='auto'then
  local phase=clock%W.AUTO_SECONDS
  local previous=W.modeAt(map,'auto',clock-phase-.01)
  if previous=='rain'or previous=='storm'then age=phase end
 end
 return {flash,S.rainbow(age,solar,mode),event.x,event.z}
end
function S.reset()
 for variant=0,2 do local source=V.require('FoleyBank').sources['thunder-'..variant];if source then source:stop()end end
 S.pending={};S.clock=nil;S.wet=0;S.lastRain=nil
 for _,source in pairs(S.sources)do if source:isPlaying()then source:stop()end end
end
function S.release()
 S.reset();for _,source in pairs(S.sources)do source:release()end;S.sources={}
 if S.mesh then S.mesh:release();S.mesh=nil end
 if S.shader then S.shader:release();S.shader=nil end
end
function S.drawRainbow(state,cloud,vp,px,pz,solar,reflection)
 if state[2]<=0 then return false end
 local C=V.require('CloudDaylight')
 if not S.shader then S.shader=V.require('ShaderCompiler').newShader([[
 uniform mat4 vp;uniform float reflectionSign;varying vec2 ground;
 #ifdef VERTEX
 vec4 position(mat4 t,vec4 p){ground=p.xz;p.y*=reflectionSign;return vp*p;}
 #endif
 #ifdef PIXEL
 ]]..C.noise..C.fragment..[[
 vec4 effect(vec4 c,Image tex,vec2 uv,vec2 sc){
 float edges=smoothstep(0.0,.16,uv.x)*(1.0-smoothstep(.84,1.0,uv.x));
 return vec4(c.rgb,c.a*edges*cloudTransmission(ground));}
 #endif
 ]])end
 local colors={{1,.40,.35},{1,.66,.32},{1,.90,.44},{.48,.90,.54},{.37,.73,1},{.52,.53,1},{.76,.48,.94}}
 local verts={};local cx,cz=px-solar.direction[1]*90,pz-100
 for band,color in ipairs(colors)do for segment=0,47 do
  local a,b=segment/48*math.pi,(segment+1)/48*math.pi
  local r=128-band*2.1;local points={{a,r},{b,r},{b,r-2.4},{a,r-2.4}}
  for _,i in ipairs{1,2,3,1,3,4}do local q=points[i]
   verts[#verts+1]={cx+math.cos(q[1])*q[2],8+math.sin(q[1])*q[2]*.85,cz,q[1]/math.pi,0,color[1],color[2],color[3],state[2]*.16}
  end
 end end
 if not S.mesh then S.mesh=love.graphics.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'VertexColor','float',4}},#verts,'triangles','stream')end
 S.mesh:setVertices(verts);love.graphics.push('all');love.graphics.setShader(S.shader)
 S.shader:send('vp','row',vp);S.shader:send('reflectionSign',reflection and -1 or 1);C.bind(S.shader,cloud)
 love.graphics.setDepthMode('lequal',false);love.graphics.setBlendMode('add','alphamultiply');love.graphics.setColor(1,1,1,1)
 love.graphics.draw(S.mesh);love.graphics.pop();return true
end
return S
