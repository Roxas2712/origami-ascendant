-- Reversible outdoor daylight: moving cloud cover changes the direct beam,
-- diffuse fill and shadow softness together. Deterministic saved-game time.
local V=...
local C={}
C.setting=V.require('ModSetting').new('gen3CloudLight','WOLKENLICHT',
 {'original','living','overcast','breaks'},{'ORIGINAL','BELEBT','BEDECKT','AUFLOCKERND'},'living')
local function smooth(x)x=math.max(0,math.min(1,x));return x*x*(3-2*x)end
-- The native FireRed adapter retains three legacy Sevii outdoor IDs.
-- Share this scope with the weather front and sky event passes.
function C.supports(def)
 local id=tostring(def and(def.id or def.name)or'')
 return id:match('^EM_')~=nil or id:match('^FR_')~=nil or id=='SEVII_ONE_ISLAND'
  or id=='SEVII_ONE_ISLAND_KINDLE_ROAD' or id=='SEVII_ONE_ISLAND_TREASURE_BEACH'
end
function C.cover(seconds,weather,mode,minimumOverride)
 local frames={{0,.16},{70,.32},{130,.82},{210,.90},{270,.25},{360,.16}}
 local t=seconds%360;local cover=.16
 for i=1,#frames-1 do local a,b=frames[i],frames[i+1]
  if t>=a[1]and t<b[1]then cover=a[2]+(b[2]-a[2])*smooth((t-a[1])/(b[1]-a[1]));break end
 end
 if mode=='overcast'then cover=.90 elseif mode=='breaks'then cover=.26+.12*math.sin(seconds/50)end
 local minimum=({rain=.76,storm=.94,snow=.68,fog=.88,sand=.65,ash=.60})[weather]or 0
 return math.max(minimumOverride or minimum,cover)
end
function C.prepare(def,outdoors,solar,seconds,weather,minimumOverride)
 local mode=C.setting:get();local cfg=V.require('DioramaConfig')
 local fr=C.supports(def)
 local day=solar and (1-(solar.night or 0))or 0
 if mode=='original'or not fr or not outdoors or not cfg.clouds.enabled or day<=0 then return {0,0,520,0}end
 return {day,C.cover(seconds,weather,mode,minimumOverride),cfg.clouds.scale or 520,seconds}
end
function C.apply(atmosphere,state)
 if state[1]<=0 or not atmosphere.solar then return end
 local old=atmosphere.solar;local solar={};for k,v in pairs(old)do solar[k]=v end
 -- Avoid changing the time-of-day rig consumed by other passes.
 solar.shadowSoftness=(old.shadowSoftness or 1.5)+(2+state[2]*5)*state[1]
 atmosphere.solar=solar
 -- Replace the old fixed forest sun columns with the cloud-gated pass in
 -- daylight. Keep their moonlit form and ORIGINAL mode exactly as before.
 for _,s in ipairs(atmosphere.shafts or{})do if s.kind=='forestSun'then s.fade=s.fade*(1-state[1])end end
 for _,l in ipairs(atmosphere.lights or{})do if l.kind=='forestSun'then l.power=l.power*(1-state[1])end end
end
function C.bind(shader,state)
 shader:send('cloudLight',state)
 shader:send('cloudOrigin',V.require('CameraContinuity').origin)
end
C.noise=[[
float cloudHash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float cloudNoise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(cloudHash(i),cloudHash(i+vec2(1,0)),f.x),mix(cloudHash(i+vec2(0,1)),cloudHash(i+vec2(1,1)),f.x),f.y);}
float cloudCover(vec2 p){float n=cloudNoise(p)*.55+cloudNoise(p*2.03+17.0)*.30+cloudNoise(p*4.1+41.0)*.15;return smoothstep(.42,.74,n);}
]]
C.fragment=[[
uniform vec4 skyEvents; // lightning pulse, post-rain bow, flash bearing X/Z
uniform vec2 cloudOrigin;
uniform vec4 cloudLight; // daylight weight, deck coverage, world scale, saved seconds
float cloudTransmission(vec2 world){
 vec2 drift=vec2(cloudLight.w*2.4,cloudLight.w*.8);
 float cover=clamp(cloudCover((world+cloudOrigin+drift)/max(1.0,cloudLight.z))+(cloudLight.y-.35),0.0,1.0);
 return 1.0-.96*smoothstep(.12,.78,cover);
}
// Shared with thin-paper transmission; avoid a second cloud-noise evaluation.
float cloudDirectTransmission=1.0;
vec3 cloudDaylight(vec3 legacy,vec3 ambient,float sun,vec3 colour,float shadow,vec2 world){
 if(cloudLight.x<=0.0)return legacy;
 float transmission=cloudTransmission(world),cover=1.0-transmission;
 cloudDirectTransmission=mix(1.0,transmission,cloudLight.x);
 vec3 diffuse=ambient*mix(vec3(1.04,1.03,1.01),vec3(.91,.96,1.02),cover);
 // Occluders remove the warm direct beam; sky fill remains in shade.
 // This replaces the old nearly black multiplication of the entire surface.
 diffuse*=1.0-shadow*.16;
 vec3 beam=ambient*(sun+.045)*mix(colour,vec3(1.0,.87,.64),skyEvents.y*.18)*transmission*(1.0-shadow*.96)*(1.0+skyEvents.y*.08);
 vec3 light=diffuse+beam;
 // Soft highlight shoulder: preserve the native texture on pale paving.
 light/=1.0+max(vec3(0.0),light-vec3(1.0))*.75;
 return mix(legacy,light,cloudLight.x);
}
]]
return C
