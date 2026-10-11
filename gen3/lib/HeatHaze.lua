-- Ground-bound heat refraction. No colour wash; depth rejects roofs, actors,
-- trees and the sky, including at the displaced sample near their silhouette.
local V=...
local H={}
local shader,canvas
local Uniform=V.require("UniformState")
local lastVP,inverseVP
local pixelSize,heat={0,0},{0,0,0}
local inverseRows={{},{},{},{}}
function H.inverse(m,out)
 local a=inverseRows
 for r=1,4 do for c=1,8 do a[r][c]=c<=4 and m[(r-1)*4+c]or(c-4==r and 1 or 0)end end
 for c=1,4 do
  local pivot=c;for r=c+1,4 do if math.abs(a[r][c])>math.abs(a[pivot][c])then pivot=r end end
  assert(math.abs(a[pivot][c])>1e-12,'singular heat projection');a[c],a[pivot]=a[pivot],a[c]
  local d=a[c][c];for k=1,8 do a[c][k]=a[c][k]/d end
  for r=1,4 do if r~=c then local f=a[r][c];for k=1,8 do a[r][k]=a[r][k]-f*a[c][k]end end end
 end
 out=out or{};for r=1,4 do for c=5,8 do out[(r-1)*4+c-4]=a[r][c]end end;return out
end
H.GLSL=[[
uniform Image sceneDepth;
uniform mat4 inverseVP;
uniform vec2 pixelSize;
uniform vec3 heat; // time, displacement pixels, speed
vec3 worldAt(vec2 uv){
 float d=Texel(sceneDepth,uv).r;
 vec4 p=inverseVP*vec4(uv*2.0-1.0,d*2.0-1.0,1.0);
 return p.xyz/p.w;
}
vec4 effect(vec4 color,Image scene,vec2 uv,vec2 screen){
 vec3 p=worldAt(uv);
 float ground=1.0-smoothstep(.5,4.0,abs(p.y));
 float t=heat.x*heat.z;
 float bands=sin(p.z*.27-t*2.7)+.45*sin(p.z*.51+t*1.9+p.x*.018);
 float pockets=.35+.65*(.5+.5*sin(p.x*.032+p.z*.021-t*.6));
 vec2 delta=vec2(bands,sin(p.x*.026+t)*.22)*pixelSize*heat.y*ground*pockets;
 vec2 sampleUV=clamp(uv+delta,pixelSize,vec2(1.0)-pixelSize);
 vec3 q=worldAt(sampleUV);
 float sameSurface=1.0-smoothstep(.5,3.0,abs(q.y-p.y));
 return Texel(scene,mix(uv,sampleUV,sameSurface))*color;
}
]]
function H.apply(source,depth,vp,amount,time)
 if amount<=0 then return source end
 local g=love.graphics;local w,h=source:getDimensions()
 if not shader then shader=V.require('ShaderCompiler').newShader(H.GLSL)end
 if not canvas or canvas:getWidth()~=w or canvas:getHeight()~=h or canvas:getFormat()~=source:getFormat() then
  if canvas then canvas:release()end
  canvas=g.newCanvas(w,h,{format=source:getFormat(),dpiscale=1});canvas:setFilter('nearest','nearest')
 end
 local cfg=V.require('DioramaConfig').weather.heat
 local changed=not lastVP
 if lastVP then for i=1,16 do if lastVP[i]~=vp[i]then changed=true;break end end end
 if changed then
  inverseVP=H.inverse(vp,inverseVP);lastVP=lastVP or{};for i=1,16 do lastVP[i]=vp[i]end
 end
 pixelSize[1],pixelSize[2]=1/w,1/h;heat[1],heat[2],heat[3]=time,cfg.pixels*amount,cfg.speed
 Uniform.send(shader,'sceneDepth',depth);Uniform.send(shader,'inverseVP','row',inverseVP)
 Uniform.send(shader,'pixelSize',pixelSize);Uniform.send(shader,'heat',heat)
 g.push('all');g.origin();g.setCanvas(canvas);g.setDepthMode('always',false)
 g.setShader(shader);g.setColor(1,1,1,1);g.setBlendMode('replace','premultiplied');g.draw(source);g.pop()
 return canvas
end
function H.release()
 if canvas then canvas:release()end;if shader then shader:release()end;canvas,shader=nil,nil;lastVP,inverseVP=nil,nil
end
return H
