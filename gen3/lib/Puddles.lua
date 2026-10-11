-- Regional surface-water envelope. Presentation only: never touches map cells.
local V=...
local M={amount=0}
function M.update(dt,mode,outside,mood)
 local cfg=V.require('DioramaConfig').weather.puddles
 if not cfg or not cfg.enabled then M.amount=0;return end
 dt=type(dt)=='number' and dt==dt and dt<math.huge and math.max(0,dt)or 0
 local visible=V.require('WeatherMood').precipitation(mode,mood)
 local raining=outside and V.require('WeatherMood').rainAmount(mode,mood)or 0
 local rate=raining*(visible=='storm'and cfg.stormRate or 1)/cfg.fillSeconds-(1-raining)/cfg.drySeconds
 M.amount=math.max(0,math.min(1,M.amount+dt*rate))
end
function M.bind(shader,outside,mode,clock,mood)
 local cfg=V.require('DioramaConfig').weather.puddles
 local active=outside and cfg.enabled
 shader:send('puddleState',{active and M.amount or 0,clock,cfg.scale,active and V.require('WeatherMood').rainAmount(mode,mood)or 0})
 shader:send('puddleLook',{cfg.coverage,cfg.reflection,cfg.ripples,cfg.grassRetention})
end
M.fragment=[[
uniform vec4 puddleState; // accumulated water, clock, world scale, falling rain
uniform vec4 puddleLook; // coverage, reflection, ring strength, grass retention
// World coordinates, not tile UVs: connected tiles share one continuous shoreline.
vec3 rainPuddles(vec3 lit,vec3 albedo,vec3 normal,vec3 p,vec3 light,float material){
 if(puddleState.x<=0.0 || material>.5 || p.y>.5 || normal.y<.95)return lit;
 vec2 q=floor(p.xz)+vec2(.5);
 float green=smoothstep(.02,.10,albedo.g-max(albedo.r,albedo.b));
 float retention=mix(1.0,puddleLook.w,green);
 float basin=cloudNoise(q/puddleState.z)*.72+cloudNoise(q/(puddleState.z*.37)+29.0)*.28;
 float threshold=.88-puddleState.x*puddleLook.x*retention;
 float pool=smoothstep(threshold,threshold+.025,basin)*smoothstep(.03,.18,puddleState.x);
 float energy=clamp(dot(light,vec3(.2126,.7152,.0722)),.06,1.0);
 float wave=sin(q.x*.27+q.y*.13+puddleState.y*1.2)*sin(q.y*.39-puddleState.y*.8);
 vec3 reflection=vec3(.40,.54,.63)*energy*(.92+.08*wave);
 vec3 wet=mix(lit*.72,reflection,puddleLook.y);
 // Sparse expanding rings restricted to the actual pool mask, no opaque quad.
 vec2 cell=floor(q/12.0);float seed=cloudHash(cell);
 vec2 center=(cell+vec2(.2+.6*seed,.2+.6*cloudHash(cell+17.0)))*12.0;
 float age=fract(puddleState.y*1.3+seed*19.0);
 float ring=(1.0-smoothstep(.25,.7,abs(length(q-center)-age*5.0)))*(1.0-age);
 wet+=vec3(.65,.76,.83)*energy*ring*puddleLook.z*puddleState.w;
 return mix(lit,wet,pool);
}
]]
return M
