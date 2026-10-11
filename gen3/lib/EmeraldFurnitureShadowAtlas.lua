-- Fixed source cubemaps preserve all opaque decoration contours, including
-- plants above the lamps. Red stores room depth, green stores furniture depth.
local V=...;local C={keys=setmetatable({},{__mode='k'})}
local shaderSource=[[
uniform vec3 lamp;
uniform float radius;
uniform float face;
uniform vec2 channel;
varying vec3 world;
#ifdef VERTEX
vec4 position(mat4 transform,vec4 vertex){
 world=vertex.xyz;vec3 d=world-lamp;vec3 p;
 if(face<.5)p=vec3(-d.z,d.y,d.x);
 else if(face<1.5)p=vec3(d.z,d.y,-d.x);
 else if(face<2.5)p=vec3(d.x,-d.z,d.y);
 else if(face<3.5)p=vec3(d.x,d.z,-d.y);
 else if(face<4.5)p=vec3(d.x,d.y,d.z);
 else p=vec3(-d.x,d.y,-d.z);
 return vec4(p.xy,p.z-.02,p.z);
}
#endif
#ifdef PIXEL
vec4 effect(vec4 c,Image tex,vec2 uv,vec2 px){
 float depth=length(world-lamp)/radius;
 if(depth>1.0)discard;
 return vec4(mix(vec2(1.0),vec2(depth),channel),1.0,1.0);
}
#endif
]]
local function geometryKey(vertices)
 if not vertices or #vertices==0 then return '' end
 local k=C.keys[vertices];if k then return k end
 local a={};for _,v in ipairs(vertices)do for i=1,3 do a[#a+1]=v[i]end end
 k=love.data.hash('sha256',table.concat(a,','));C.keys[vertices]=k;return k
end
function C.release()if C.cached then C.cached.texture:release();C.cached=nil end end
function C.prepare(state,sources,stones,furniture)
 if #sources==0 then return end
 local config=V.require('DioramaConfig').emeraldInteriors.secretBases.reliefShadows
 local resolution=math.max(64,math.floor(config.decorResolution or config.resolution/2))
 local key=V.require('EmeraldReliefAtlas').key;local keys={}
 for _,s in ipairs(sources)do keys[#keys+1]=key(s)end
 local signature=table.concat(keys,'|')..':'..resolution..':'..geometryKey(stones)..':'..geometryKey(furniture)
 if C.cached and C.cached.field==state and C.cached.signature==signature then return C.cached end
 C.release()
 local columns=math.ceil(math.sqrt(#sources*30));local rows=math.ceil(#sources*30/columns)
 resolution=math.min(resolution,math.floor(love.graphics.getSystemLimits().texturesize/math.max(columns,rows)))
 if resolution<64 then return end
 local format=love.graphics.getCanvasFormats().rg16f and 'rg16f' or 'rgba8'
 local texture=love.graphics.newCanvas(columns*resolution,rows*resolution,{format=format,msaa=0})
 texture:setFilter('nearest','nearest');texture:setWrap('clamp','clamp')
 local tile=love.graphics.newCanvas(resolution,resolution,{format=format,msaa=0});tile:setFilter('nearest','nearest')
 local f=state.field;local vertices={}
 for z=0,f.heightPixels-1 do for x=0,f.width-1 do if f.rock(x,z)then
  for _,p in ipairs{{0,0},{1,0},{1,1},{0,0},{1,1},{0,1}}do vertices[#vertices+1]={x+p[1],f.height(x+p[1],z+p[2])*state.scale,z+p[2]}end
  for _,e in ipairs{{0,0,0,1,-1,0},{1,1,1,0,1,0},{1,0,0,0,0,-1},{0,1,1,1,0,1}}do
   if not f.rock(x+e[5],z+e[6])then
    local a={x+e[1],f.height(x+e[1],z+e[2])*state.scale,z+e[2]}
    local b={x+e[3],f.height(x+e[3],z+e[4])*state.scale,z+e[4]}
    local c,d={b[1],0,b[3]},{a[1],0,a[3]}
    for _,p in ipairs{a,b,c,a,c,d}do vertices[#vertices+1]=p end
   end
  end
 end end end
 for _,p in ipairs(stones or{})do vertices[#vertices+1]=p end
 local format3={{'VertexPosition','float',3}}
 local mesh=#vertices>0 and love.graphics.newMesh(format3,vertices,'triangles','static')
 local decor=love.graphics.newMesh(format3,furniture,'triangles','static')
 local shader=V.require('ShaderCompiler').newShader(shaderSource);local lookup={};local slot=0
 love.graphics.push('all');love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode();love.graphics.setMeshCullMode('none');love.graphics.setColor(1,1,1,1)
 love.graphics.setCanvas(texture);love.graphics.clear(1,1,1,1)
 for _,s in ipairs(sources)do
  lookup[key(s)]={slot,s.radius}
  for _,offset in ipairs{{0,0},{s.spread[1],0},{-s.spread[1],0},{0,s.spread[2]},{0,-s.spread[2]}}do
   for face=0,5 do
    love.graphics.setCanvas(tile);love.graphics.clear(1,1,1,1);love.graphics.setBlendMode('darken','premultiplied');love.graphics.setShader(shader)
    shader:send('lamp',{s.at[1]+offset[1],s.at[2],s.at[3]+offset[2]});shader:send('radius',s.radius);shader:send('face',face)
    shader:send('channel',{1,0});if mesh then love.graphics.draw(mesh)end
    shader:send('channel',{0,1});love.graphics.draw(decor)
    love.graphics.setCanvas(texture);love.graphics.setShader();love.graphics.setBlendMode('replace','premultiplied')
    love.graphics.draw(tile,(slot%columns)*resolution,math.floor(slot/columns)*resolution);slot=slot+1
   end
  end
 end
 love.graphics.pop();if mesh then mesh:release()end;decor:release();tile:release();shader:release()
 C.cached={field=state,signature=signature,texture=texture,lookup=lookup,columns=columns,rows=rows,resolution=resolution,maximum=state.maximum,hasFurniture=true,cube=true}
 return C.cached
end
return C
