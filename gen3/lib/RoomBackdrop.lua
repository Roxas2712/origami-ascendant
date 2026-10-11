-- Restore the room's empty backdrop after bloom, fog, grading and dithering.
-- Keep the original scene/depth as coverage; finished colour is not coverage.
local V=...
local B={color={0,0,0}}
local shader,canvas
B.GLSL=[[
uniform Image roomScene;
uniform Image roomDepth;
uniform float roomKeepLayers;
vec4 effect(vec4 color,Image finished,vec2 uv,vec2 screen){
 vec3 raw=Texel(roomScene,uv).rgb;
 float depth=Texel(roomDepth,uv).r;
 if((roomKeepLayers<.5 && depth>=1.0) || max(raw.r,max(raw.g,raw.b))<=0.0)return vec4(0.0,0.0,0.0,1.0);
 return Texel(finished,uv);
}
]]
function B.apply(finished,scene,depth,keepLayers)
 local g=love.graphics;local w,h=finished:getDimensions()
 if not shader then shader=V.require('ShaderCompiler').newShader(B.GLSL)end
 if not canvas or canvas:getWidth()~=w or canvas:getHeight()~=h or canvas:getFormat()~=finished:getFormat()then
  if canvas then canvas:release()end
  canvas=g.newCanvas(w,h,{format=finished:getFormat(),dpiscale=1});canvas:setFilter('nearest','nearest')
 end
 shader:send('roomScene',scene);shader:send('roomDepth',depth);shader:send('roomKeepLayers',keepLayers and 1 or 0)
 g.push('all');g.origin();g.setCanvas(canvas);g.setDepthMode('always',false)
 g.setShader(shader);g.setColor(1,1,1,1);g.setBlendMode('replace','premultiplied');g.draw(finished);g.pop()
 return canvas
end
function B.release()
 if canvas then canvas:release()end;if shader then shader:release()end
 canvas,shader=nil,nil
end
return B
