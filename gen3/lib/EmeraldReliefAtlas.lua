-- Reusable point-light shadow maps for fixed native Secret Base relief.
-- Decorated bases use a separate cubemap atlas for tall furniture. No game state is cached.
local V=...;local A={stoneKeys=setmetatable({},{__mode='k'})}
local function key(s)return table.concat({s.at[1],s.at[2],s.at[3],s.radius,s.spread[1],s.spread[2]},':')end
A.key=key
local shaderSource=[[
uniform vec3 lamp;
uniform float extent;
uniform float maximum;
varying float altitude;
#ifdef VERTEX
vec4 position(mat4 transform,vec4 vertex){
 altitude=vertex.y/maximum;
 float w=1.0-vertex.y/lamp.y;
 return vec4((vertex.x-lamp.x)/extent,(vertex.z-lamp.z)/extent,0.0,w);
}
#endif
#ifdef PIXEL
vec4 effect(vec4 c,Image tex,vec2 uv,vec2 px){return vec4(altitude,0.0,0.0,1.0);}
#endif
]]
function A.release()
 if A.cached then A.cached.texture:release();A.cached=nil end
 V.require('EmeraldFurnitureShadowAtlas').release()
end
function A.prepare(state,sources,stones,furniture)
 local c=V.require('DioramaConfig').emeraldInteriors.secretBases.reliefShadows
 if not state or not c.atlas then return end
 if furniture and #furniture>0 then
  if A.cached then A.cached.texture:release();A.cached=nil end
  return V.require('EmeraldFurnitureShadowAtlas').prepare(state,sources,stones,furniture)
 end
 V.require('EmeraldFurnitureShadowAtlas').release()
 local stoneKey,maximum='',state.maximum
 if stones then
  local stamp=A.stoneKeys[stones]
  if not stamp then
   local values={};local top=0;for _,v in ipairs(stones)do for k=1,3 do values[#values+1]=v[k]end;top=math.max(top,v[2])end
   stamp={key=love.data.hash('sha256',table.concat(values,',')),maximum=top};A.stoneKeys[stones]=stamp
  end
  stoneKey=stamp.key;maximum=math.max(maximum,stamp.maximum)
 end
 local keys={};for _,s in ipairs(sources)do
  if s.at[2]<=maximum+c.bias then return end -- general ray fallback
  keys[#keys+1]=key(s)
 end
 local resolution=math.max(64,math.floor(c.resolution));local signature=table.concat(keys,'|')..':'..resolution..':stones:'..stoneKey
 if A.cached and A.cached.field==state and A.cached.signature==signature then return A.cached end
 A.release();if #sources==0 then return end
 local columns=math.ceil(math.sqrt(#sources*5));local rows=math.ceil(#sources*5/columns)
 local limits=love.graphics.getSystemLimits();resolution=math.min(resolution,math.floor(limits.texturesize/math.max(columns,rows)))
 if resolution<64 then return end
 local format=love.graphics.getCanvasFormats().r16f and 'r16f' or 'rgba8'
 local texture=love.graphics.newCanvas(columns*resolution,rows*resolution,{format=format,msaa=0})
 texture:setFilter('nearest','nearest');texture:setWrap('clamp','clamp')
 local tile=love.graphics.newCanvas(resolution,resolution,{format=format,msaa=0});tile:setFilter('nearest','nearest')
 local f=state.field;local vertices={}
 for z=0,f.heightPixels-1 do for x=0,f.width-1 do if f.rock(x,z)then
  for _,v in ipairs{{0,0},{1,0},{1,1},{0,0},{1,1},{0,1}}do
   vertices[#vertices+1]={x+v[1],f.height(x+v[1],z+v[2])*state.scale,z+v[2]}
  end
  for _,e in ipairs{{0,0,0,1,-1,0},{1,1,1,0,1,0},{1,0,0,0,0,-1},{0,1,1,1,0,1}}do
   if not f.rock(x+e[5],z+e[6])then
    local a={x+e[1],f.height(x+e[1],z+e[2])*state.scale,z+e[2]}
    local b={x+e[3],f.height(x+e[3],z+e[4])*state.scale,z+e[4]}
    local c,d={b[1],0,b[3]},{a[1],0,a[3]}
    for _,v in ipairs{a,b,c,a,c,d}do vertices[#vertices+1]=v end
   end
  end
 end end end
 for _,v in ipairs(stones or {})do vertices[#vertices+1]=v end
 local mesh=#vertices>0 and love.graphics.newMesh({{'VertexPosition','float',3}},vertices,'triangles','static')
 local shader=V.require('ShaderCompiler').newShader(shaderSource);shader:send('maximum',maximum)
 local lookup={};love.graphics.push('all');love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode();love.graphics.setMeshCullMode('none');love.graphics.setColor(1,1,1,1)
 love.graphics.setCanvas(texture);love.graphics.clear(0,0,0,1)
 local slot=0
 for _,s in ipairs(sources)do
  -- All potentially lit receivers below the relief cap project within this square.
  local extent=s.radius/(1-maximum/s.at[2])+math.max(s.spread[1],s.spread[2])+2
  lookup[key(s)]={slot,extent}
  for _,o in ipairs{{0,0},{s.spread[1],0},{-s.spread[1],0},{0,s.spread[2]},{0,-s.spread[2]}}do
   love.graphics.setCanvas(tile);love.graphics.clear(0,0,0,1);love.graphics.setBlendMode('lighten','premultiplied');love.graphics.setShader(shader)
   shader:send('lamp',{s.at[1]+o[1],s.at[2],s.at[3]+o[2]});shader:send('extent',extent)
   if mesh then love.graphics.draw(mesh)end
   love.graphics.setCanvas(texture);love.graphics.setShader();love.graphics.setBlendMode('replace','premultiplied')
   love.graphics.draw(tile,(slot%columns)*resolution,math.floor(slot/columns)*resolution);slot=slot+1
  end
 end
 love.graphics.pop();if mesh then mesh:release()end;tile:release();shader:release()
 A.cached={field=state,signature=signature,texture=texture,lookup=lookup,columns=columns,rows=rows,resolution=resolution,maximum=maximum}
 return A.cached
end
function A.send(shader,atlas,sources)
 if not shader:hasUniform('roomReliefAtlasInfo')then return end
 local c=V.require('DioramaConfig').emeraldInteriors.secretBases.reliefShadows
 shader:send('roomReliefAtlasInfo',atlas and {atlas.cube and 2 or 1,atlas.columns,atlas.rows,c.mapBias}or {0,1,1,c.mapBias})
 shader:send('roomFurnitureShadow',atlas and atlas.hasFurniture and V.require('DioramaConfig').roomLightRig.shadowStrength or 0)
 local indices={};for i=1,24 do local s=sources and sources[i]and sources[i].roomSource;indices[i]=atlas and s and atlas.lookup[key(s)]or {-1,1}end
 shader:send('roomReliefTiles',unpack(indices))
 if atlas then shader:send('roomReliefAtlasHeight',atlas.maximum);shader:send('roomReliefAtlas',atlas.texture);shader:send('roomReliefAtlasSize',{atlas.texture:getDimensions()})end
end
return A
