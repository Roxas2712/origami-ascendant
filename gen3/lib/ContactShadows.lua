-- Render-only contacts: soft ellipses and an optional owned hard stack layer.
-- Packed in the green channel alongside the red directional-shadow mask.
local V=...
local S={records=setmetatable({},{__mode="k"}),stackDirection={0,0}}
local source=[[
uniform mat4 vp;
varying float strength;
varying float contactAspect;
#ifdef VERTEX
attribute float ContactStrength;
attribute float ContactAspect;
vec4 position(mat4 t,vec4 p){strength=ContactStrength;contactAspect=ContactAspect;return vp*p;}
#endif
#ifdef PIXEL
vec4 effect(vec4 c,Image tex,vec2 uv,vec2 screen){
 vec2 q=uv*2.0-1.0;
 float radius=contactAspect>0.0?length(vec2(max(0.0,abs(q.x)*contactAspect-(contactAspect-1.0)),q.y)):length(q);
 if(radius>=1.0)discard;
 float mask=(1.0-smoothstep(.12,1.0,radius))*strength;
 return vec4(0.0,mask,0.0,1.0);
}
#endif
]]
-- A negative ContactStrength marks the extra small ellipse. Base vertices
-- and the legacy shader are unchanged when no stack layer is installed.
local stackSource=source:gsub('uniform mat4 vp;',[[uniform mat4 vp;
uniform vec2 stackOffset;
uniform float stackAmount;]])
stackSource=stackSource:gsub('strength=ContactStrength;contactAspect=ContactAspect;return vp%*p;',
 'strength=ContactStrength;contactAspect=ContactAspect;if(strength<0.0)p.xz+=stackOffset;return vp*p;')
stackSource=stackSource:gsub('float mask=%(1.0%-smoothstep%(.12,1.0,radius%)%)%*strength;',
 'float mask=(1.0-smoothstep(.12,1.0,radius))*(strength<0.0?stackAmount:strength);')
local function stacked()
 local c=S.stackLayer
 return c and c.enabled~=false and (tonumber(c.stackShadow)or 0)>0 or false
end
function S.prepareShader(includeOwnedLayer)
 local active=stacked();local name=active and 'stackShader'or 'shader'
 if not S[name]then S[name]=V.require('ShaderCompiler').newShader(active and stackSource or source)end
 -- The owning Card computes its intensity in prepare, after startup. Warm
 -- its variant without changing that layer's enabled state or geometry.
 if includeOwnedLayer and S.stackLayer and not S.stackShader then
  S.stackShader=V.require('ShaderCompiler').newShader(stackSource)
 end
 return S[name],active
end
local function shader(vp)
 local sh,active=S.prepareShader();local U=V.require('UniformState');U.send(sh,'vp','row',vp)
 if active then
  U.send(sh,'stackAmount',math.max(0,math.min(1,tonumber(S.stackLayer.stackShadow)or 0)))
  U.send(sh,'stackOffset',S.stackDirection)
 end
 love.graphics.setShader(sh)
end
-- Consumers remove only their own layer; retained scene entries restore their
-- original mesh lazily on the next draw, without rebuilding map geometry.
function S.removeStackLayer(layer)
 if S.stackLayer~=layer then return false end
 S.stackLayer=nil;S.stackDirection[1],S.stackDirection[2]=0,0
 if S.stackShader then S.stackShader:release();S.stackShader=nil end
 return true
end
local format={{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'ContactStrength','float',1},{'ContactAspect','float',1}}
local quadFormat=string.rep('f',42)
local corners={{-1,-1},{1,-1},{1,1},{-1,-1},{1,1},{-1,1}}
local actorVertices={}
-- Old geometry caches store front edges as rows of overlapping small ellipses.
-- Join only those tightly spaced, identical consecutive front-edge records.
-- Trees/props at normal cell spacing and separate furniture stay independent.
function S.frontEdges(contacts)
 local result={};local i=1
 while i<=#contacts do
  local c=contacts[i];local j=i
  if c[3]==7 then
   while j<#contacts do local a,b=contacts[j],contacts[j+1];local step=b[1]-a[1]
    if (step~=6 and step~=8) or b[2]~=c[2] or b[3]~=c[3] or b[4]~=c[4] or b[5]~=c[5] or b[6]~=c[6] then break end
    j=j+1
   end
  end
  if j>i then
   local last=contacts[j];local rx=(last[1]-c[1])*.5+c[3]
   result[#result+1]={(c[1]+last[1])*.5,c[2],rx,c[4],c[5],c[6],rx/math.max(.01,c[4])}
  else result[#result+1]=c end
  i=j+1
 end
 return result
end
function S.mesh(contacts)
 if not contacts or #contacts==0 then return end
 -- One packed quad per contact avoids thirteen short-lived Lua tables.
 -- Mesh input still contains the same six float32 vertices and UVs.
 local chunks={};local hard=stacked()
 for i,c in ipairs(S.frontEdges(contacts))do
  local x,z,rx,rz,strength=unpack(c);local y=(c[6]or 0)+.06
  local x0,x1,z0,z1=x-rx,x+rx,z-rz,z+rz
  local aspect=c[7]or 0
  chunks[#chunks+1]=love.data.pack('string',quadFormat,
   x0,y,z0,0,0,strength,aspect, x1,y,z0,1,0,strength,aspect, x1,y,z1,1,1,strength,aspect,
   x0,y,z0,0,0,strength,aspect, x1,y,z1,1,1,strength,aspect, x0,y,z1,0,1,strength,aspect)
  -- The continuous soft base already anchors a furniture/building edge.
  -- A second dark line would make that edge resemble a trench at night.
  if hard and aspect==0 then
   local ax,bx,az,bz=x-rx*.62,x+rx*.62,z-rz*.62,z+rz*.62
   chunks[#chunks+1]=love.data.pack('string',quadFormat,
    ax,y,az,0,0,-1,0, bx,y,az,1,0,-1,0, bx,y,bz,1,1,-1,0,
    ax,y,az,0,0,-1,0, bx,y,bz,1,1,-1,0, ax,y,bz,0,1,-1,0)
  end
 end
 if #chunks==0 then return end
 local bytes=love.data.newByteData(table.concat(chunks))
 local ok,mesh=pcall(love.graphics.newMesh,format,bytes,'triangles','static')
 bytes:release();assert(ok,mesh);S.records[mesh]={contacts=contacts,stacked=hard};return mesh
end
function S.draw(drawList,vp)
 if not V.require('DioramaConfig').contact.enabled then return end
 shader(vp)
 for _,entry in ipairs(drawList)do if entry.contacts then
  local old=entry.contacts;local record=S.records[old]
  if record and record.stacked~=stacked()then
   entry.contacts=S.mesh(record.contacts);S.records[old]=nil;old:release()
  end
  love.graphics.draw(entry.contacts)
 end end
end
-- Soft blob under every walking character (reference: visible even at night).
function S.drawActors(actors,vp)
 local cfg=V.require('DioramaConfig').contact
 if not cfg.enabled or not cfg.actorStrength or cfg.actorStrength<=0 or #actors==0 then return end
 local hard=stacked();local v=actorVertices;local count=0
 for _,a in ipairs(actors)do
  if not a.hidden then
   local x,z=a.x+8+(a.xOffset or 0),a.z+14+(a.zOffset or 0)
   local rx,rz=cfg.actorRadius[1],cfg.actorRadius[2]
   local st=cfg.actorStrength*(a.yOffset and a.yOffset<-2 and .5 or 1)
   for _,p in ipairs(corners)do
    count=count+1;local row=v[count]
    if not row then row={};v[count]=row end
    row[1],row[2],row[3]=x+p[1]*rx,(a.contactY or 0)+.07,z+p[2]*rz
    row[4],row[5],row[6],row[7]=(p[1]+1)/2,(p[2]+1)/2,st,0
   end
   if hard then for _,p in ipairs(corners)do
    count=count+1;local row=v[count];if not row then row={};v[count]=row end
    row[1],row[2],row[3]=x+p[1]*rx*.62,(a.contactY or 0)+.07,z+p[2]*rz*.62
    row[4],row[5],row[6],row[7]=(p[1]+1)/2,(p[2]+1)/2,-1,0
   end end
  end
 end
 if count==0 then return end
 if not S.actorMesh or S.actorMesh:getVertexCount()<count then
  if S.actorMesh then S.actorMesh:release()end
  S.actorMesh=love.graphics.newMesh(format,math.max(count,96),'triangles','stream')
 end
 S.actorMesh:setVertices(v,1,count);S.actorMesh:setDrawRange(1,count)
 shader(vp);love.graphics.draw(S.actorMesh)
end
function S.release()
 if S.shader then S.shader:release();S.shader=nil end
 if S.stackShader then S.stackShader:release();S.stackShader=nil end
 if S.actorMesh then S.actorMesh:release();S.actorMesh=nil end
 actorVertices={};S.records=setmetatable({},{__mode="k"})
end
return S
