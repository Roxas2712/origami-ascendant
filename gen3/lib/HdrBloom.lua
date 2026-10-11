-- Half/quarter/eighth-resolution bloom. No engine HUD or sprite textures enter
-- this module; unsupported floating-point targets retain the legacy finish.
local V=...
local B={mips={},step={0,0},warned={}}
local down=[[
uniform vec2 texel;
uniform vec2 thresholdKnee;
uniform float prefilter;
vec3 thresholdColor(vec3 c){
 float b=max(c.r,max(c.g,c.b));float k=max(thresholdKnee.y,.0001);
 float s=clamp(b-thresholdKnee.x+k,0.0,2.0*k);s=s*s/(4.0*k);
 return c*max(s,max(0.0,b-thresholdKnee.x))/max(b,.0001);
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 vec3 s=Texel(tex,uv).rgb*.5;
 s+=(Texel(tex,uv+texel*vec2(-1,-1)).rgb+Texel(tex,uv+texel*vec2(1,-1)).rgb+
     Texel(tex,uv+texel*vec2(-1,1)).rgb+Texel(tex,uv+texel*vec2(1,1)).rgb)*.125;
 if(prefilter>.5)s=thresholdColor(s);
 return vec4(s,1.0);
}
]]
local up=[[
uniform vec2 texel;uniform float scatter;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 vec3 s=Texel(tex,uv).rgb*4.0;
 s+=(Texel(tex,uv+texel*vec2(-1,0)).rgb+Texel(tex,uv+texel*vec2(1,0)).rgb+
     Texel(tex,uv+texel*vec2(0,-1)).rgb+Texel(tex,uv+texel*vec2(0,1)).rgb)*2.0;
 s+=Texel(tex,uv+texel*vec2(-1,-1)).rgb+Texel(tex,uv+texel*vec2(1,-1)).rgb+
    Texel(tex,uv+texel*vec2(-1,1)).rgb+Texel(tex,uv+texel*vec2(1,1)).rgb;
 return vec4(s*(scatter/16.0),0.0);
}
]]
local knee={1,.5}
local function warn(reason)
 if B.warned[reason]then return end;B.warned[reason]=true
 if V.mod and V.mod.log then V.mod.log:info('HDR bloom disabled: '..reason)end
end
function B.sceneFormat(enabled)
 if not enabled or B.failed then return 'rgba8' end
 local f=love.graphics.getCanvasFormats()
 if f.rgba16f then return 'rgba16f' end
 -- Scene transparency is still used by the world/battle compositor, so an
 -- RGB-only fallback is not safe here. Keep the existing RGBA8 renderer.
 warn('rgba16f unavailable');return 'rgba8'
end
function B.releaseTargets()
 for i,c in ipairs(B.mips)do c:release();B.mips[i]=nil end
 B.width,B.height,B.format,B.count=nil,nil,nil,nil
end
function B.release()
 B.releaseTargets();B.failed=nil;B.reason=nil
 for _,n in ipairs{'down','up'}do if B[n]then B[n]:release();B[n]=nil end end
end
local function disable(reason)
 B.release();B.failed=true;B.reason=tostring(reason);warn(B.reason)
end
function B.prepare()
 if B.failed then return false end
 if B.down and B.up then return true end
 local a,b
 local ok,err=pcall(function()
  a=V.require('ShaderCompiler').newShader(down);b=V.require('ShaderCompiler').newShader(up)
 end)
 if not ok then
  if a then a:release()end;if b then b:release()end
  disable(err);return false
 end
 B.down,B.up=a,b;return true
end
local function targets(scene,cfg)
 local w,h=scene:getDimensions();local format=scene:getFormat()
 local count=math.max(1,math.min(3,math.floor(cfg.bloomMips or 3)))
 if B.width~=w or B.height~=h or B.format~=format or B.count~=count then
  B.releaseTargets();B.width,B.height,B.format,B.count=w,h,format,count
  for i=1,count do
   local c=love.graphics.newCanvas(math.max(1,math.ceil(w/2^i)),math.max(1,math.ceil(h/2^i)),{format=format,dpiscale=1})
   B.mips[i]=c;c:setFilter('linear','linear');c:setWrap('clamp','clamp')
  end
 end
end
local function render(scene,cfg,emission,emissionStrength,rays)
 love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode()
 love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('replace','premultiplied')
 knee[1],knee[2]=cfg.bloomThreshold or 1,cfg.bloomKnee or .5;B.down:send('thresholdKnee',knee)
 local source=scene;scene:setFilter('linear','linear')
 for i,target in ipairs(B.mips)do
  local sw,sh=source:getDimensions();local tw,th=target:getDimensions()
  B.step[1],B.step[2]=1/sw,1/sh;B.down:send('texel',B.step);B.down:send('prefilter',i==1 and 1 or 0)
  love.graphics.setCanvas(target);love.graphics.setShader(B.down);love.graphics.draw(source,0,0,0,tw/sw,th/sh)
  if i==1 and emission and (emissionStrength or 0)>0 then
   love.graphics.setShader();love.graphics.setBlendMode('add','premultiplied')
   love.graphics.setColor(emissionStrength,emissionStrength,emissionStrength,0)
   love.graphics.draw(emission,0,0,0,tw/emission:getWidth(),th/emission:getHeight())
   love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('replace','premultiplied')
  end
  if i==1 and rays then
   love.graphics.setShader();love.graphics.setBlendMode('add','premultiplied')
   love.graphics.draw(rays,0,0,0,tw/rays:getWidth(),th/rays:getHeight())
   love.graphics.setBlendMode('replace','premultiplied')
  end
  source=target
 end
 love.graphics.setShader(B.up);love.graphics.setBlendMode('add','premultiplied');B.up:send('scatter',cfg.bloomScatter or .6)
 for i=B.count,2,-1 do
  source=B.mips[i];local target=B.mips[i-1];local sw,sh=source:getDimensions()
  B.step[1],B.step[2]=1/sw,1/sh;B.up:send('texel',B.step)
  love.graphics.setCanvas(target);love.graphics.draw(source,0,0,0,target:getWidth()/sw,target:getHeight()/sh)
 end
 return B.mips[1]
end
function B.apply(scene,cfg,emission,emissionStrength,rays)
 if not B.prepare()then return nil end
 local ok,err=pcall(targets,scene,cfg)
 if not ok then disable(err);return nil end
 local min,mag,aniso=scene:getFilter()
 love.graphics.push('all')
 local rendered,result=pcall(render,scene,cfg,emission,emissionStrength,rays)
 scene:setFilter(min,mag,aniso);love.graphics.pop()
 if not rendered then disable(result);return nil end
 return result
end
return B
