-- Thin, translucent light volumes between fixed ceiling openings and floor.
local V=...
local C={}
local code=[[
uniform mat4 vp;
uniform float seconds;
uniform float strandAmount;
#ifdef VERTEX
vec4 position(mat4 t,vec4 p){return vp*p;}
#endif
#ifdef PIXEL
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 float edge=pow(max(0.0,sin(uv.x*3.141593)),1.7);
 float ends=smoothstep(0.0,.10,uv.y)*(1.0-smoothstep(.78,1.0,uv.y));
 float strands=1.0-strandAmount*(.15-.15*sin(uv.x*73.0+sin(uv.y*4.0+seconds*.15)));
 // Forest beams: soft wide cone, brightest where it meets the ground.
 float body=mix(1.0,.55+.45*uv.y,1.0-strandAmount);
 return vec4(color.rgb,color.a*edge*ends*strands*body);
}
#endif
]]
function C.prepareShader()
 if not C.shader then C.shader=V.require('ShaderCompiler').newShader(code)end
 return C.shader
end
function C.draw(shafts,vp,time)
 if #shafts==0 then return end
 C.prepareShader()
 if not C.mesh or C.mesh:getVertexCount()<math.min(16,#shafts)*6 then
  if C.mesh then C.mesh:release()end
  C.mesh=love.graphics.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'VertexColor','float',4}},math.max(4,math.min(16,#shafts))*6,'triangles','stream')
 end
 local verts={}
 for n,s in ipairs(shafts)do if n>16 then break end
  local x,z=s.x,s.z
  local w,h,a=(s.width or 42)/2,s.height or 88,s.alpha or .17
  local points={{x-w,h,z-17,0,0},{x-w+w*2/3,h,z-17,1,0},{x+w,.3,z+5,1,1},{x-w,.3,z+5,0,1}}
  if s.width then
   -- Slanted sun beam as in the reference forest clip: it enters from the
   -- upper left and widens towards the canopy opening.
   local sx,top=h*(s.slant or 0),w*(s.spread or 1)
   points={{x-sx-top,h,z-h*.12,0,0},{x-sx+top,h,z-h*.12,1,0},{x+w,.3,z+4,1,1},{x-w,.3,z+4,0,1}}
  end
  for _,i in ipairs({1,2,3,1,3,4})do
   local p=points[i];verts[#verts+1]={p[1],p[2]+(s.y or 0),p[3],p[4],p[5],s.color[1],s.color[2],s.color[3],a*s.fade}
  end
 end
 C.mesh:setVertices(verts,1,#verts);C.mesh:setDrawRange(1,#verts)
 love.graphics.push('all');love.graphics.setShader(C.shader)
 C.shader:send('vp','row',vp);C.shader:send('seconds',time);C.shader:send('strandAmount',shafts[1].width and 0 or 1)
 love.graphics.setBlendMode(shafts[1].width and 'add' or 'alpha','alphamultiply');love.graphics.setDepthMode('lequal',false)
 love.graphics.setColor(1,1,1,1);love.graphics.draw(C.mesh);love.graphics.pop()
end
function C.release()
 for _,name in ipairs({'mesh','shader'})do if C[name]then C[name]:release();C[name]=nil end end
end
return C
