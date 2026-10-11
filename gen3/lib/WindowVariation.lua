-- Optional, stateless household lamps. Uses the existing saved-time sky dial;
-- never consumes game RNG, changes glass masks, or writes gameplay/save state.
local V=...
local W={}
W.setting=V.require('ModSetting').new('gen3WindowLife','FENSTERLEBEN',
 {'original','varied','living'},{'ORIGINAL','LAMPENVARIANZ','LEBENDIG'},'living')
local function hash(n)return ((n*73+19)%997)/997 end
function W.buildingKey(b)
 if not(tostring(b.mapId):match('^FR_')or tostring(b.mapId):match('^EM_'))then return nil end
 local h=0;local s=b.mapId..':'..b.x0..':'..b.y0
 for i=1,#s do h=(h*31+s:byte(i))%128 end
 return h
end
-- Facade eligibility already carries a float: these binary-exact bands keep
-- the original textured (> .5) / flat (< .5) glass flags and shadow anchors.
-- Each merged pane has ONE constant tag across all its native pixel runs.
function W.code(building,pane,textured)
 if pane>127 then return nil end
 return (textured==false and .125 or .625)+(building*128+pane)/131072
end
function W.decode(code)
 if not code then return nil end
 local base=code>=.625 and code<.75 and .625 or code>=.125 and code<.25 and .125
 if not base then return nil end
 local n=math.floor((code-base)*131072+.5)
 return math.floor(n/128),n%128
end
function W.hour(dial)
 -- Inverse of DayNight.nativeTime; matches 18:00 dusk / 04:00 dawn.
 dial=dial%1200
 if dial<300 then return 4+dial/50 end
 if dial<600 then return 10+(dial-300)*8/300 end
 return (18+(dial-600)/60)%24
end
local function state(building,pane,hour)
 local h=hour%24;local late=h<6 or h>=23
 local seed=building*131+pane*17
 local dim=hash(seed+h*37)<(late and .48 or .12)
 local power=(.84+.14*hash(building+7))*(.9+.1*hash(seed+11))
 if dim then power=power*(.35+.25*hash(seed+h*13))end
 local warmth=math.min(1,hash(building+31)*.8+hash(seed+h*7)*.2)
 return {1,.89+.11*warmth,.78+.22*warmth,power}
end
function W.sample(code,mode,hour)
 local building,pane=W.decode(code)
 mode=mode or W.setting:get()
 if not building or mode=='original'then return {1,1,1,1}end
 if mode=='varied'then return state(building,pane,20)end
 hour=hour or W.hour(V.require('DayNight').time())
 local a=math.floor(hour);local u=math.min(1,(hour-a)/.25);u=u*u*(3-2*u)
 local from,to=state(building,pane,(a+23)%24),state(building,pane,a)
 local result={};for i=1,4 do result[i]=from[i]+(to[i]-from[i])*u end
 return result
end
function W.bind(shader)
 local mode=W.setting:get()
 shader:send('windowLife',{mode=='original'and 0 or mode=='varied'and 1 or 2,W.hour(V.require('DayNight').time())})
end
-- Same bounded arithmetic as Lua, so pane emission, spill and water sheen
-- use identical colour and dimming, independently of the 24-light budget.
W.fragment=[[
uniform vec2 windowLife;
float lampHash(float n){return mod(n*73.0+19.0,997.0)/997.0;}
vec4 lampState(float building,float pane,float hour){
 float h=mod(hour,24.0);bool late=h<6.0 || h>=23.0;
 float seed=building*131.0+pane*17.0;
 float power=(.84+.14*lampHash(building+7.0))*(.9+.1*lampHash(seed+11.0));
 if(lampHash(seed+h*37.0)<(late?.48:.12))power*=.35+.25*lampHash(seed+h*13.0);
 float warmth=min(1.0,lampHash(building+31.0)*.8+lampHash(seed+h*7.0)*.2);
 return vec4(1.0,.89+.11*warmth,.78+.22*warmth,power);
}
vec4 windowLamp(float code){
 bool textured=code>=.625 && code<.75;bool flatPane=code>=.125 && code<.25;
 if(windowLife.x<.5 || !(textured || flatPane))return vec4(1.0);
 float n=floor((code-(textured?.625:.125))*131072.0+.5);
 float building=floor(n/128.0),pane=mod(n,128.0);
 if(windowLife.x<1.5)return lampState(building,pane,20.0);
 float h=floor(windowLife.y);float u=clamp(fract(windowLife.y)/.25,0.0,1.0);u=u*u*(3.0-2.0*u);
 return mix(lampState(building,pane,h+23.0),lampState(building,pane,h),u);
}
]]
return W
