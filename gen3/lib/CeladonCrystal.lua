-- Native fountain in front of Celadon's department store. The historical
-- module/uniform names remain compatible; the illuminated object is water.
local V=...
local C={enabled=true}
local colors={{.35,.86,1},{.76,.43,1},{1,.46,.67},{1,.78,.35}}
function C.active(def)
 local L=def and def.midLayout
 return C.enabled and def and (def.id or def.name)=='FR_CELADON_CITY' and L
  and L:midAt(13,19)==0x2d1 and L:midAt(13,20)==0x2d4
end
function C.color(time)
 local phase=(time or 0)/18;local i=math.floor(phase);local t=phase-i
 t=t*t*(3-2*t)
 local a,b=colors[i%#colors+1],colors[(i+1)%#colors+1]
 return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t}
end
function C.apply(def,result,time,outdoors)
 if not outdoors or not C.active(def)then return end
 local night=V.require('DayNight').windowLight()
 result.cityFountainClock={1,time or 0}
 if night<=0 or V.require('DioramaConfig').lighting.enabled==false then return end
 local color=C.color(time)
 result.cityCrystal={amount=night,color=color}
 -- Fixed world source; approaching the plaza cannot turn the fountain on.
 result.lights[#result.lights+1]={x=216,y=8,z=327,radius=-35,power=.58*night,color=color,falloff=1.6,kind='cityCrystal'}
end
function C.bind(shader,state)
 local c=state and state.cityCrystal
 shader:send('cityCrystalAmount',c and c.amount or 0)
 shader:send('cityCrystalColor',c and c.color or {0,0,0})
 shader:send('cityFountainClock',state and state.cityFountainClock or {0,0})
end
C.uniforms=[[
uniform float cityCrystalAmount;
uniform vec3 cityCrystalColor;
uniform vec2 cityFountainClock;
]]
C.fragment=[[
  if(cityFountainClock.x>.5 && actorFace<.5 && worldPosition.y<32.0
    && worldPosition.x>=192.0 && worldPosition.x<240.0
    && worldPosition.z>=288.0 && worldPosition.z<352.0){
    vec3 nativeCrystal=Texel(tex,uv).rgb;
    // Native basin water and jet, never the gold/grey rim or green lawn.
    if(nativeCrystal.b>.65 && nativeCrystal.b>nativeCrystal.g+.04
      && nativeCrystal.g>nativeCrystal.r+.08){
      float facet=dot(nativeCrystal,vec3(.2126,.7152,.0722));
      vec3 emission=cityCrystalColor*(.76+.24*facet);
      float jet=step(4.1,worldPosition.y)*step(.84,nativeCrystal.b);
      lit=mix(lit,emission,cityCrystalAmount*mix(.38,.78,jet));
      // Falling highlights on the jet and rings travelling out from its base.
      // Modulate the already-lit water: unlit nights remain dark, and the
      // motion stays visible after the coloured night-light blend as well.
      float stream=pow(.5+.5*sin(worldPosition.y*1.3+cityFountainClock.y*9.0),5.0);
      float radius=length(worldPosition.xz-vec2(216.0,324.0));
      float ripple=pow(.5+.5*sin(radius*.75-cityFountainClock.y*3.0),8.0);
      lit*=mix(.93+.17*ripple,.88+.30*stream,jet);
    }
  }
]]
return C
