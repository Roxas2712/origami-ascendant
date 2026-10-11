-- Project the actual native cutout silhouettes onto the ground. A shared
-- half-resolution mask keeps overlapping tree/house shadows from stacking.
local V=...
local S={}
local Trace=V.require('TransitionTrace')
local U=V.require('UniformState');local right,shear,axis,padding={},{},{},{x=12,y=0,z=12}
local source=V.require('ClosedShell').shader..V.require('EmeraldFlowers').shader..[[
varying float elevation;
varying float electricBeam;
varying float building;
uniform mat4 vp;
uniform vec2 shear;
uniform float buildingCast;
#ifdef VERTEX
attribute vec3 BillboardAnchor;
attribute float VertexShade;
uniform vec2 billboardRight;
#ifdef WORLD_INSTANCES
attribute vec3 WorldPlacement;
#endif
vec4 position(mat4 t,vec4 p){
 vec2 anchor=BillboardAnchor.xy;
#ifdef WORLD_INSTANCES
 p.xyz=p.xyz*WorldPlacement.z+vec3(WorldPlacement.x,0.0,WorldPlacement.y);
 anchor=anchor*WorldPlacement.z+WorldPlacement.xy;
#endif
 if(dot(closedShellNormal(BillboardAnchor.z),vec3(-shear.x,1.0,-shear.y))<0.0)return vec4(0.0,0.0,2.0,1.0);
 if(BillboardAnchor.z>.5){
  
  p.xz=anchor+billboardRight*(p.x-anchor.x)+vec2(-billboardRight.y,billboardRight.x)*(p.z-anchor.y);
 }
 // The solar rig opts roofs/facades into soft directional silhouettes.
 // Night keeps contact only; the independent green channel never blurs.
]]..V.require('EmeraldFlowers').vertex..[[
 building=(VertexShade>=2.0 && VertexShade<3.5)||VertexShade>5.5?1.0:0.0;
 electricBeam=step(8.9,VertexShade)*(1.0-step(9.1,VertexShade));
 elevation=p.y;
 p.xz+=p.y*shear;p.y=.04;
 return vp*p;
}
#endif
#ifdef PIXEL
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 if(electricBeam>.5)discard;
 vec4 pixel=Texel(tex,uv);
]]..V.require('EmeraldFlowers').fragment..[[
 float alpha=pixel.a;
 if((building>.5 && buildingCast<=0.0) || elevation<.7 || alpha<.5)discard;
 float opacity=color.a*(building>.5?buildingCast:1.0);
 return vec4(opacity,0.0,opacity,1.0);
}
#endif
]]
local blurSource=[[
   uniform vec2 axis;
   vec4 effect(vec4 c,Image tex,vec2 uv,vec2 screen){
    vec2 rb=Texel(tex,uv).rb*.227027;
    rb+=(Texel(tex,uv+axis).rb+Texel(tex,uv-axis).rb)*.1945946;
    rb+=(Texel(tex,uv+axis*2.0).rb+Texel(tex,uv-axis*2.0).rb)*.1216216;
    rb+=(Texel(tex,uv+axis*3.0).rb+Texel(tex,uv-axis*3.0).rb)*.054054;
    rb+=(Texel(tex,uv+axis*4.0).rb+Texel(tex,uv-axis*4.0).rb)*.016216;
    return vec4(rb.x,Texel(tex,uv).g,rb.y,1.0);
   }]]
function S.prepareShaders(soften)
 if not S.shader then
  S.shader=V.require('ShaderCompiler').newShader(source)
  if love.graphics.getSupported().instancing then
   S.instance=V.require('ShaderCompiler').newShader('#define WORLD_INSTANCES\n'..source)
  end
 end
 if soften and not S.blur then S.blur=V.require('ShaderCompiler').newShader(blurSource)end
end
function S.render(drawList,vp,width,height,outdoors,drawActors,eye,solar)
 local quality=V.require("DioramaConfig").settings
 local scale=quality.shadowScale or .5
 local w,h=math.ceil(width*scale),math.ceil(height*scale)
 if not S.canvas or S.canvas:getWidth()~=w or S.canvas:getHeight()~=h then
  if S.canvas then S.canvas:release()end
  S.canvas=love.graphics.newCanvas(w,h,{dpiscale=1});S.canvas:setFilter('linear','linear')
 end
 S.prepareShaders(false)
 local dx,dz=V.require('DayNight').shearAt(V.require('DayNight').time())
 -- Long dawn shadows are bounded to avoid covering several connected maps.
 local length=math.sqrt(dx*dx+dz*dz)
 local scale=length>1.8 and 1.8/length or 1
 local cfg=V.require("DioramaConfig").shadows
 local lengthScale=outdoors and (cfg.dayLength+(cfg.nightLength-cfg.dayLength)*V.require("DayNight").windowLight())or .4
 scale=scale*lengthScale/V.require("Billboard").heightScale()
 dx,dz=dx*scale,dz*scale
 if not outdoors then dx,dz=.18,.28 end
 if solar then
  local w=solar.weight or 1;local hs=V.require('Billboard').heightScale()
  dx,dz=dx*(1-w)+solar.shear[1]/hs*w,dz*(1-w)+solar.shear[2]/hs*w
 end
 -- Cull in the projected shadow plane, including offscreen casters whose
 -- shadow reaches the view. Main-camera culling alone loses those shadows.
 local Visibility=V.require('SceneVisibility')
 local Seams=V.require('core/RenderSeams');local deformation=Seams.vertexBounds()
 local unknown=not deformation and(Seams.shader('main.vertex.pre')~=''or Seams.shader('main.vertex.post')~='')
 local matrix=S.casterMatrix or{};S.casterMatrix=matrix
 for row=0,3 do
  local k=row*4
  matrix[k+1],matrix[k+2],matrix[k+3],matrix[k+4]=vp[k+1],vp[k+1]*dx+vp[k+3]*dz,vp[k+3],vp[k+4]+vp[k+2]*.04
 end
 local selected=S.visible or{};S.visible=selected;local n=0

 for _,entry in ipairs(drawList)do
  local bounds=entry.stats and entry.stats.frustumBounds
  if unknown or Visibility.visible(bounds,matrix,false,0,w,h,deformation)
   or Visibility.visible(bounds,vp,false,0,w,h,padding)then n=n+1;selected[n]=entry end
 end
 for i=#selected,n+1,-1 do selected[i]=nil end
 S.culled=#drawList-n;drawList=selected
 love.graphics.push('all');love.graphics.setCanvas(S.canvas);love.graphics.origin()
 love.graphics.setScissor();love.graphics.setDepthMode();love.graphics.clear(0,0,0,1)
 love.graphics.setBlendMode('lighten','premultiplied');love.graphics.setColor(1,1,1,1)
 right[1],right[2]=V.require('Camera').right();shear[1],shear[2]=dx,dz
 U.send(S.shader,'buildingCast',solar and solar.buildingShadows and (solar.buildingWeight or solar.weight or 1)or 0)
 U.send(S.shader,'billboardRight',right)
 U.send(S.shader,'vp','row',vp);U.send(S.shader,'shear',shear)
 love.graphics.setShader(S.shader)
 if cfg.enabled then
 for i,entry in ipairs(drawList)do
  local stage
  if Trace.destinationActive()then stage='destination shadow mesh '..i;Trace.destination(stage..' draw begin',function()return 'vertices='..entry.mesh:getVertexCount()end)end
  love.graphics.draw(entry.mesh)
  if stage then Trace.destination(stage..' draw ready')end
 end
 if S.instance then
  U.send(S.instance,'buildingCast',solar and solar.buildingShadows and (solar.buildingWeight or solar.weight or 1)or 0)
  U.send(S.instance,'billboardRight',right)
  U.send(S.instance,'vp','row',vp);U.send(S.instance,'shear',shear);love.graphics.setShader(S.instance)
  for _,entry in ipairs(drawList)do for _,batch in ipairs(entry.instances)do
   local stage
   if Trace.destinationActive()then stage='destination shadow instances';Trace.destination(stage..' draw begin',function()return 'vertices='..batch.mesh:getVertexCount()..' instances='..batch.count end)end
   love.graphics.drawInstanced(batch.mesh,batch.count)
   if stage then Trace.destination(stage..' draw ready')end
  end end
 end
 love.graphics.setShader(S.shader)
 -- Blue stores only environmental occluders. Actors and contact shadows
 -- keep writing red/green, so a character cannot shadow itself.
 love.graphics.setColorMask(true,true,false,true)
 if drawActors then drawActors()end
 end
 love.graphics.setColorMask(true,true,false,true)
 Trace.destination('destination contact shadows begin')
 V.require("ContactShadows").draw(drawList,vp)
 if S.actorList then V.require("ContactShadows").drawActors(S.actorList,vp)end
 Trace.destination('destination contact shadows ready')
 love.graphics.pop()
 local softness=solar and solar.shadowSoftness*(quality.shadowSoftness or 1)or 0
 if cfg.enabled and softness>0 then
  S.prepareShaders(true)
  if not S.soft or S.soft:getWidth()~=w or S.soft:getHeight()~=h then
   if S.soft then S.soft:release();S.temp:release()end
   S.soft=love.graphics.newCanvas(w,h,{dpiscale=1});S.temp=love.graphics.newCanvas(w,h,{dpiscale=1})
   S.soft:setFilter('linear','linear');S.temp:setFilter('linear','linear')
  end
  love.graphics.push('all');love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode()
  love.graphics.setBlendMode('replace','premultiplied');love.graphics.setColor(1,1,1,1);love.graphics.setShader(S.blur)
  love.graphics.setCanvas(S.temp);axis[1],axis[2]=softness/width,0;U.send(S.blur,'axis',axis);love.graphics.draw(S.canvas)
  love.graphics.setCanvas(S.soft);axis[1],axis[2]=0,softness/height;U.send(S.blur,'axis',axis);love.graphics.draw(S.temp)
  love.graphics.pop();return S.soft
 end
 return S.canvas
end
function S.release()
 for _,name in ipairs({'canvas','shader','instance','soft','temp','blur'})do if S[name]then S[name]:release();S[name]=nil end end
end
return S
