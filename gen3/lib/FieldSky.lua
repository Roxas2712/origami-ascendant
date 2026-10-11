-- Conditional ray-based skybox, following VASC Sky.paint's world anchoring.
-- One full-size background draw, no texture upscaling or extra scene composite.
local V=...
local S={}
local source=[[
uniform vec2 size;
uniform vec3 forwardRay,rightRay,upRay;
uniform vec3 horizonColor;
uniform float night,cloudAmount,clock;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 screen){
 vec2 p=screen/size;
 vec3 ray=normalize(forwardRay+rightRay*(2.0*p.x-1.0)+upRay*(1.0-2.0*p.y));
 float elevation=max(0.0,ray.y);
 vec3 zenith=mix(vec3(.18,.43,.78),vec3(.005,.009,.035),night);
 vec3 color=mix(horizonColor,zenith,smoothstep(0.0,.65,elevation));
 // Clouds and stars follow world bearing, never the screen or map visit.
 float bearing=atan(ray.x,ray.z);vec2 angular=vec2(bearing,elevation);
 float cloud=noise(vec2(ray.x,ray.z)*8.0+vec2(clock*.002,clock*.001));
 cloud=cloud*.65+noise(vec2(ray.x,ray.z)*19.0+clock*.003)*.35;
 float band=smoothstep(.015,.09,elevation)*(1.0-smoothstep(.20,.50,elevation));
 color=mix(color,mix(vec3(.86,.90,.96),vec3(.08,.10,.16),night),smoothstep(.53,.73,cloud)*band*(.25+.65*cloudAmount));
 vec2 starCell=floor(angular*450.0);float star=step(.998,hash(starCell));
 vec2 point=fract(angular*450.0)-.5;star*=1.0-smoothstep(.10,.30,length(point));
 color+=vec3(.65,.72,.88)*star*night*(1.0-cloudAmount)*smoothstep(.03,.1,elevation);
 return vec4(color,1.0);
}
]]
function S.draw(width,height,color,weather)
 local C=V.require('Camera');if not C.experimental()then return end
 S.shader=S.shader or love.graphics.newShader(source)
 local sh=S.shader;local yaw,e=C.yaw(),C.elevation();local sy,cy,sp,cp=math.sin(yaw),math.cos(yaw),math.sin(e),math.cos(e)
 local t=math.tan(C.fov()/2);sh:send('size',{width,height})
 sh:send('forwardRay',{-sy*cp,-sp,-cy*cp});sh:send('rightRay',{cy*t*width/height,0,-sy*t*width/height})
 sh:send('upRay',{-sy*sp*t,cp*t,-cy*sp*t});sh:send('horizonColor',color)
 sh:send('night',V.require('DayNight').windowLight());sh:send('clock',V.require('Weather').clock)
 sh:send('cloudAmount',(weather=='storm'or weather=='fog')and 1 or(weather=='rain'or weather=='snow')and .8 or .1)
 love.graphics.push('all');love.graphics.setDepthMode('always',false);love.graphics.setShader(sh);love.graphics.setBlendMode('replace');love.graphics.setColor(1,1,1,1)
 love.graphics.rectangle('fill',0,0,width,height);love.graphics.pop()
end
return S
