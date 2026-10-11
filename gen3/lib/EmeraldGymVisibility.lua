-- Read native trainer-progress visibility (Dewford and Pyramid); never write it.
local V=...
local F={}
local shaderCode=[[
uniform vec2 focusPixels;
uniform float radiusPixels;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 vec4 base=Texel(tex,uv);
 float visible=1.0-smoothstep(radiusPixels-.5,radiusPixels+.5,length(screen-focusPixels));
 return vec4(base.rgb*visible,base.a);
}
]]
function F.radius(def,field)
 local pyramid=V.require('EmeraldPyramidFloor')
 if not V.require('EmeraldDewfordGym').profile(def)and not(pyramid.kind(def)=='floor'and pyramid.profile(def))then return end
 return field.flashRadius()
end
function F.apply(scene,def,vp,px,pz)
 local radius=F.radius(def,require('src.core.game3.field_view'))
 if not radius then return scene end
 local C=V.require('Camera');local cx,cy=C.project(vp,px+8,8,pz+16)
 local rx=C.project(vp,px+8+radius,8,pz+16)
 if not cx or not rx then return scene end
 local w,h=scene:getDimensions()
 if not F.target or F.target:getWidth()~=w or F.target:getHeight()~=h or F.target:getFormat()~=scene:getFormat() then
  if F.target then F.target:release()end
  F.target=love.graphics.newCanvas(w,h,{format=scene:getFormat(),dpiscale=1});F.target:setFilter('nearest','nearest')
 end
 F.shader=F.shader or V.require('ShaderCompiler').newShader(shaderCode)
 F.shader:send('focusPixels',{cx*w,cy*h});F.shader:send('radiusPixels',math.abs(rx-cx)*w)
 love.graphics.push('all');love.graphics.setCanvas(F.target);love.graphics.origin()
 love.graphics.setDepthMode();love.graphics.setShader(F.shader);love.graphics.setColor(1,1,1,1)
 love.graphics.setBlendMode('replace');love.graphics.draw(scene);love.graphics.pop()
 return F.target
end
function F.release()
 if F.target then F.target:release();F.target=nil end
 if F.shader then F.shader:release();F.shader=nil end
end
return F
