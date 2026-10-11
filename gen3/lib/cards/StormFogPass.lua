-- Isolated Card-owned instance of the established volumetric fog pipeline.
-- Depth-aware height fog. Four world-space integration samples, at half
-- resolution; the full-resolution composite rejects samples across geometry.
local V=...
local Seams=V.require('core/RenderSeams')
local U=V.require('UniformState')
local moonTint,white,black={.22,.30,.42},{1,1,1},{0,0,0}
local function create()
local F={color={},light={},anchor={},shape={},pocket={},size={}}
local base=V.require('VolumeFog')
F.integrate,F.composite=base.integrate,base.composite
-- Empty slots reproduce the original source byte for byte. Cards own only
-- their snippets; the existing four-sample integration and depth resolve stay.
function F.buildIntegrateSource()
 local source=F.integrate
 local uniforms=Seams.shader('fog.uniforms')
 local density=Seams.shader('fog.density')
 if uniforms~=''then source=uniforms..source end
 if density~=''then source=source:gsub('  tau%+=d;',function()return density..'  tau+=d;'end,1)end
 return source
end
function F.apply(source,vp,x,z,time,c,context)
 local g=love.graphics;local w,h=source:getDimensions()
 if not F.shader or F.seamVersion~=Seams.version then
  local shader=V.require('ShaderCompiler').newShader(F.buildIntegrateSource())
  if F.shader then U.invalidate(F.shader);F.shader:release()end;F.shader=shader;F.seamVersion=Seams.version
 end
 if not F.compose then F.compose=V.require('ShaderCompiler').newShader(F.composite)end
 local fw,fh=math.max(1,math.ceil(w/2)),math.max(1,math.ceil(h/2))
 if not F.layer or F.layer:getWidth()~=fw or F.layer:getHeight()~=fh or F.layer:getFormat()~=source:getFormat() then
  if F.layer then F.layer:release()end
  F.layer=g.newCanvas(fw,fh,{format=source:getFormat(),dpiscale=1});F.layer:setFilter('nearest','nearest')
 end
 F.outputs=F.outputs or{}
 local out
 for i=1,2 do
  local b=F.outputs[i]
  if not b or b:getWidth()~=w or b:getHeight()~=h or b:getFormat()~=source:getFormat() then
   if b then b:release()end;b=g.newCanvas(w,h,{format=source:getFormat(),dpiscale=1});b:setFilter('nearest','nearest');F.outputs[i]=b
  end
  if b~=source and not out then out=b end
 end
 -- Interior cutaways compress clip Z; reconstruct from that same projection.
 -- The same projection feeds several fog layers and stationary frames. Cache
 -- by its values, not table identity (camera matrices may mutate in place).
 local scale=context.depthScale or 1
 local unchanged=F.projection and F.depthScale==scale
 if unchanged then for i=1,16 do if F.projection[i]~=vp[i]then unchanged=false;break end end end
 if not unchanged then
  F.projection=F.projection or {};local adjusted=F.adjustedProjection or {};F.adjustedProjection=adjusted
  for i=1,16 do F.projection[i]=vp[i];adjusted[i]=vp[i]*((i>=9 and i<=12)and scale or 1)end
  F.depthScale=scale;F.inverse=V.require('HeatHaze').inverse(adjusted)
 end
 local inverse=F.inverse
 local color,light=F.color,F.light
 for i=1,3 do color[i],light[i]=c.color[i],c.light[i]end
 if context.outdoors and not c.preTinted then
  local night=context.solar and context.solar.night or 0
  local tint=context.solar and context.solar.sunColor or white
  for i=1,3 do local moon=moonTint[i]
   color[i]=color[i]*((1-night)+moon*night)
   light[i]=light[i]*((1-night)*(.85+.15*tint[i])+moon*night)
  end
 end
 local s=F.shader
 F.anchor[1],F.anchor[2]=x+8,z+8
 F.shape[1],F.shape[2],F.shape[3],F.shape[4]=c.density,c.height or(context.outdoors and 42 or 24),time,c.surge and V.require('HauntedFog').surge(time)or 0
 F.pocket[1],F.pocket[2],F.pocket[3]=c.pocket[1]*16,c.pocket[2]*16,c.clearCore or .45
 F.size[1],F.size[2]=fw,fh
 U.send(s,'sceneDepth',context.depth);U.send(s,'inverseVP','row',inverse);U.send(s,'cameraEye',context.eye)
 U.send(s,'anchor',F.anchor);U.send(s,'fogShape',F.shape)
 U.send(s,'fogColor',color);U.send(s,'fogLight',light);U.send(s,'preserveRoomVoid',context.ungradedScene and not context.outdoors and 1 or 0)
 U.send(s,'ungradedScene',context.ungradedScene or source);U.send(s,'roomVoidColor',context.voidColor or black)
 U.send(s,'fogPocket',F.pocket);U.send(s,'ribbonMix',c.ribbonMix or .65)
 Seams.run('bindFog',s,context,time)
 U.send(F.compose,'sceneDepth',context.depth);U.send(F.compose,'inverseVP','row',inverse)
 U.send(F.compose,'fogLayer',F.layer);U.send(F.compose,'fogSize',F.size)
 g.push('all');g.origin();g.setDepthMode();g.setScissor();g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1)
 g.setCanvas(F.layer);g.setShader(s);g.draw(source,0,0,0,fw/w,fh/h)
 g.setCanvas(out);g.setShader(F.compose);g.draw(source);g.pop()
 return out
end
function F.release()
 F.seamVersion=nil;F.projection=nil;F.adjustedProjection=nil;F.inverse=nil;F.depthScale=nil
 if F.shader then U.invalidate(F.shader)end
 if F.compose then U.invalidate(F.compose)end
 for _,key in ipairs{'layer','shader','compose'}do if F[key]then F[key]:release();F[key]=nil end end
 for _,b in ipairs(F.outputs or{})do b:release()end;F.outputs=nil
end
return F
end
return create
