-- Explicit native-pixel emission masks. Never infer lamps from scene brightness.
local V=...;local Uniform=V.require('UniformState');local E={cache=setmetatable({},{__mode='k'})}
function E.profile(def)
 local p=V.require('RoomLightRig').profile(def)
 return p and p.emission and p.emission.enabled~=false and p.emission or nil
end
function E.mask(def,ts)
 local p=E.profile(def);if not p or not ts then return end
 local ids={};for _,r in ipairs(p.regions)do
  for y=math.floor(r.rect[2]/16),math.floor((r.rect[2]+r.rect[4]-1)/16)do
   for x=math.floor(r.rect[1]/16),math.floor((r.rect[1]+r.rect[3]-1)/16)do ids[#ids+1]=def.midLayout:midAt(r.at[1]+x,r.at[2]+y)end
  end
 end
 local key=table.concat(ids,",")
 local cached=E.cache[ts];if cached and cached.profile==p and cached.key==key then return cached.image end
 if cached then cached.image:release()end
 local w,h=ts.image:getDimensions();local data=love.image.newImageData(w,h)
 local BM=V.require('BuildingMesh');local L=def.midLayout
 for _,region in ipairs(p.regions)do
  local allowed={};for _,rgb in ipairs(region.palette)do allowed[rgb]=true end
  for y=region.rect[2],region.rect[2]+region.rect[4]-1 do
   for x=region.rect[1],region.rect[1]+region.rect[3]-1 do
    local mid=L:midAt(region.at[1]+math.floor(x/16),region.at[2]+math.floor(y/16))
    if ts.midToSlot[mid]then
     local r,g,b,a,ax,ay=BM.pixel(ts,mid,x%16,y%16)
     local rgb=math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)
     if a>.5 and allowed[rgb]then data:setPixel(ax,ay,1,0,0,1)end
    end
   end
  end
 end
 local image=love.graphics.newImage(data);image:setFilter('nearest','nearest');data:release()
 E.cache[ts]={profile=p,image=image,key=key};return image
end
function E.bind(shader,def,ts,only)
 local p=def and E.profile(def);local mask=p and E.mask(def,ts)
 if not E.blank then local d=love.image.newImageData(1,1);E.blank=love.graphics.newImage(d);d:release()end
 Uniform.send(shader,'roomEmissionMask',mask or E.blank)
 Uniform.send(shader,'roomEmissionOnly',only and 1 or 0)
 local night=mask and V.require('DayNight').windowLight()or 0
 Uniform.send(shader,'roomEmissionPower',mask and (p.day*(1-night)+p.night*night)or 0)
end
-- The emission replay uses the world program. On Metal its colour format and
-- blend state must match the already drawn world pipeline, avoiding a second
-- large-program pipeline compilation at the first illuminated room. Emission
-- fragments are opaque, so alpha/alphamultiply replaces them just as before.
local metal=love.graphics.getRendererInfo()=='Metal'
local function mark(stage,detail)
 local trace=V.loaded and V.loaded.TransitionTrace
 if trace then trace.destination(stage,detail)end
end
function E.render(def,drawList,shader,depth,w,h,sceneFormat)
 if not E.profile(def)then return end
 local format=metal and (sceneFormat or 'rgba8')or 'rgba8'
 mark('destination emission allocation begin',function()return w..'x'..h..' '..format end)
 if not E.canvas or E.canvas:getWidth()~=w or E.canvas:getHeight()~=h or E.canvas:getFormat()~=format then
  if E.canvas then E.canvas:release();E.canvas=nil end
  E.canvas=love.graphics.newCanvas(w,h,{format=format,dpiscale=1});E.canvas:setFilter('nearest','nearest')
 end
 mark('destination emission allocation ready')
 love.graphics.push('all');love.graphics.origin();love.graphics.setScissor()
 mark('destination emission target bind begin')
 love.graphics.setCanvas({E.canvas,depthstencil=depth})
 mark('destination emission target bind ready')
 mark('destination emission clear begin')
 love.graphics.clear(0,0,0,0,false,false)
 mark('destination emission clear ready')
 love.graphics.setDepthMode('lequal',false)
 love.graphics.setBlendMode(metal and 'alpha'or 'replace',metal and 'alphamultiply'or 'premultiplied')
 love.graphics.setColor(1,1,1,1);love.graphics.setShader(shader)
 local trace=V.loaded and V.loaded.TransitionTrace
 local tracing=trace and trace.destinationActive()
 for i,entry in ipairs(drawList)do
  local slot=tracing and i<=4 and tostring(i)
  if slot then mark('destination emission mesh '..slot..' bind begin')end
  E.bind(shader,entry.def,entry.atlas,true)
  if slot then mark('destination emission mesh '..slot..' draw begin',function()return 'vertices='..entry.mesh:getVertexCount()end)end
  love.graphics.draw(entry.mesh)
  if slot then mark('destination emission mesh '..slot..' draw ready')end
 end
 mark('destination emission meshes ready',function()return 'meshes='..#drawList end)
 E.bind(shader)
 mark('destination emission restore begin')
 love.graphics.pop()
 mark('destination emission restore ready')
 return E.canvas
end
function E.release()
 for _,v in pairs(E.cache)do v.image:release()end;E.cache=setmetatable({},{__mode='k'})
 for _,k in ipairs{'blank','canvas'}do if E[k]then E[k]:release();E[k]=nil end end
end
return E
