-- Sparse sunlit haze, anchored to open ground. The same cloud field controls
-- the surface light and these shafts; no independent random flashes or lamps.
local V=...
local C={cache=setmetatable({},{__mode='k'})}
local Daylight=V.require('CloudDaylight')
local Uniform=V.require('UniformState')
local empty,defaultColor,quadOrder={},{1,.9,.72},{1,2,3,1,3,4}
local nearbyRows,nearbyPool={},{}
local nearbySource,nearbyX,nearbyZ,nearbyRadius
local connectedSource,connectedWorld,connectedDef
local actorRows,actorProfiles,vertices={},{},{}
local corners={{},{},{},{}}
local function nearer(a,b)return a.d<b.d or a.d==b.d and(a.p.key or'')<(b.p.key or'')end
C.fragment=[[
uniform Image groundShadow;
uniform mat4 vp;
float shaftVisibility(vec2 ground){
 vec4 clip=vp*vec4(ground.x,.04,ground.y,1.0);
 vec2 uv=clip.xy/clip.w*.5+.5;
 float shadow=Texel(groundShadow,clamp(uv,vec2(0.0),vec2(1.0))).r;
 float opening=smoothstep(.48,.93,cloudTransmission(ground));
 // A solid deck has no shafts. Clear skies need no visible fog columns.
 float broken=smoothstep(.12,.28,cloudLight.y)*(1.0-smoothstep(.60,.80,cloudLight.y));
 return opening*broken*(1.0-smoothstep(.12,.55,shadow))*cloudLight.x;
}
]]
local code=[[
varying vec2 ground;
#ifdef VERTEX
uniform mat4 vp;
attribute vec2 ShaftFoot;
vec4 position(mat4 t,vec4 p){ground=ShaftFoot;return vp*p;}
#endif
#ifdef PIXEL
]]..Daylight.noise..Daylight.fragment..C.fragment..[[
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 float edge=pow(max(0.0,sin(uv.x*3.141593)),2.0);
 float ends=smoothstep(0.0,.20,uv.y)*(1.0-smoothstep(.72,1.0,uv.y));
 float threads=.80+.12*sin(uv.x*63.0+sin(uv.y*3.0+cloudLight.w*.05));
 return vec4(color.rgb,color.a*edge*ends*threads*shaftVisibility(ground));
}
#endif
]]
function C.sites(def)
 local L=def.midLayout;if not L then return empty end
 if C.cache[L]then return C.cache[L]end
 local S=V.data('Shapes');local out={}
 -- Three open tiles across keep beams off roofs, cliffs and tree trunks.
 for z=2,L.height-3,5 do for x=2,L.width-3,5 do
  local xx=x+(z%3);local ok=true
  for dz=-1,1 do for dx=-1,1 do
   local cell=L:cellAt(xx+dx,z+dz)
   if not cell or cell.mid==0 or S.solid(cell)then ok=false end
  end end
  if ok then out[#out+1]={x=xx*16+8,z=z*16+8,width=40+(x*7+z*3)%24}end
 end end
 C.cache[L]=out;return out
end
-- Share the exact visible shaft footprint with the actor material.
function C.nearby(def,px,pz)
 local Map=require('src.core.game3.map')
 local source=C.sites(def)
 if Map._worldRoot==(def.id or def.name)and V.mod.options:get('gen3Neighbors')~=false then
  if connectedWorld~=Map.world or connectedDef~=def then
   connectedSource={};connectedWorld,connectedDef=Map.world,def
   local function add(d,ox,oz,id)
    if not V.data('Shapes').outdoors(d)then return end
    for i,p in ipairs(C.sites(d))do
     connectedSource[#connectedSource+1]={x=p.x+ox*16,z=p.z+oz*16,width=p.width,shapeX=p.x,shapeZ=p.z,key=id..':'..i}
    end
   end
   add(def,0,0,def.id or def.name)
   for _,e in ipairs(Map.world or{})do if e.id~=(def.id or def.name)then add(e.def,e.ox,e.oy,e.id)end end
  end
  source=connectedSource
 end
 if source==nearbySource and px==nearbyX and pz==nearbyZ then return nearbyRows,nearbyRadius end
 local n=0
 -- Refill in source order before sorting: equal-distance ties retain the
 -- same table.sort inputs as the direct path, even after camera movement.
 for _,p in ipairs(source)do
  local d=(p.x-px)^2+(p.z-pz)^2
  if d<620^2 then
   n=n+1;local row=nearbyPool[n]
   if not row then row={};nearbyPool[n]=row end
   row.p,row.d=p,d;nearbyRows[n]=row
  end
 end
 for i=n+1,#nearbyRows do nearbyRows[i]=nil end
 for i=n+1,#nearbyPool do nearbyPool[i].p=nil;nearbyPool[i].d=nil end
 table.sort(nearbyRows,nearer)
 nearbySource,nearbyX,nearbyZ=source,px,pz
 nearbyRadius=math.min(500,nearbyRows[17]and math.sqrt(nearbyRows[17].d)or 500)
 return nearbyRows,nearbyRadius
end
C.actorUniforms=[[
uniform int actorShaftCount;
uniform vec4 actorShaftSite[16]; // x, z, half width at ground, height
uniform vec2 actorShaftProfile[16]; // top width ratio, distance fade
]]
C.actorFragment=[[
float actorShaftLight(vec3 world){
 float total=0.0;
 float broken=smoothstep(.12,.28,cloudLight.y)*(1.0-smoothstep(.60,.80,cloudLight.y));
 vec2 lean=sunDirection.xz/max(.35,sunDirection.y);
 for(int i=0;i<16;i++){
  if(i>=actorShaftCount)break;
  vec4 site=actorShaftSite[i];vec2 profile=actorShaftProfile[i];
  vec2 foot=world.xz-lean*world.y;
  float fraction=clamp(world.y/site.w,0.0,1.0);
  float width=site.z*mix(1.0,profile.x,fraction);
  float edge=1.0-smoothstep(.15,1.0,length(foot-site.xy)/max(1.0,width));
  if(edge<=0.0)continue;
  float opening=smoothstep(.48,.93,cloudTransmission(foot));
  total+=edge*opening*broken*cloudLight.x*profile.y*(1.0-smoothstep(site.w*.8,site.w,world.y));
 }
 return min(.30,total*.24);
}
]]
function C.bindActors(shader,def,state,px,pz)
 local enabled=V.require('DioramaConfig').forest.enabled and state[1]>0 and state[2]<.80 and state[2]>.12
 local sites,radius=empty,500;if enabled then sites,radius=C.nearby(def,px,pz)end
 local count=math.min(16,#sites);Uniform.send(shader,'actorShaftCount',count)
 if count==0 then return end
 local rows,profiles=actorRows,actorProfiles
 for i=1,count do
  local p=sites[i].p;local sx,sz=p.shapeX or p.x,p.shapeZ or p.z;local cone=(math.floor(sx/16)+math.floor(sz/16))%3==0
  local u=math.max(0,math.min(1,(math.sqrt(sites[i].d)-radius*.55)/math.max(1,radius*.45)))
  local row=rows[i];if not row then row={};rows[i]=row end
  row[1],row[2],row[3],row[4]=p.x,p.z,p.width*(cone and .78 or .5),150+((p.shapeX or p.x)+(p.shapeZ or p.z))%55
  local profile=profiles[i];if not profile then profile={};profiles[i]=profile end
  profile[1],profile[2]=cone and .22 or 1,1-u*u*(3-2*u)
 end
 Uniform.send(shader,'actorShaftSite',unpack(rows,1,count));Uniform.send(shader,'actorShaftProfile',unpack(profiles,1,count))
end
function C.prepareShader()
 if not C.shader then C.shader=V.require('ShaderCompiler').newShader(code)end
 return C.shader
end
function C.draw(def,state,atmosphere,vp,shadow,px,pz)
 if not V.require('DioramaConfig').forest.enabled or state[1]<=0 or state[2]>=.80 or state[2]<=.12 then return 0 end
 C.prepareShader()
 local sites,radius=C.nearby(def,px,pz)
 local count=0;local direction=atmosphere.direction
 -- Follow solar azimuth/elevation, with a bounded length at the horizon.
 local color=atmosphere.solar and atmosphere.solar.sunColor or defaultColor
 for i=1,math.min(16,#sites)do
  local p=sites[i].p;local sx,sz=p.shapeX or p.x,p.shapeZ or p.z;local cone=(math.floor(sx/16)+math.floor(sz/16))%3==0
  local h=150+((p.shapeX or p.x)+(p.shapeZ or p.z))%55;local y=math.max(.35,direction[2])
  local sx,sz=direction[1]/y*h,direction[3]/y*h
  local w=p.width*(cone and .78 or .5);local top=cone and w*.22 or w
  local u=math.max(0,math.min(1,(math.sqrt(sites[i].d)-radius*.55)/math.max(1,radius*.45)))
  local fade=1-u*u*(3-2*u)
  -- Three translucent axial slices make a soft conical volume, rather than
  -- a single triangular card. Narrow shafts retain their parallel sides.
  local slices=cone and 3 or 1
  for slice=1,slices do
   local angle=(slice-1)*math.pi/3;local dx,dz=math.cos(angle),math.sin(angle)
   local a,b,c,d=corners[1],corners[2],corners[3],corners[4]
   a[1],a[2],a[3],a[4],a[5],a[6],a[7]=p.x-top*dx+sx,h,p.z-top*dz+sz,0,0,p.x-w*dx,p.z-w*dz
   b[1],b[2],b[3],b[4],b[5],b[6],b[7]=p.x+top*dx+sx,h,p.z+top*dz+sz,1,0,p.x+w*dx,p.z+w*dz
   c[1],c[2],c[3],c[4],c[5],c[6],c[7]=p.x+w*dx,.8,p.z+w*dz,1,1,p.x+w*dx,p.z+w*dz
   d[1],d[2],d[3],d[4],d[5],d[6],d[7]=p.x-w*dx,.8,p.z-w*dz,0,1,p.x-w*dx,p.z-w*dz
   for _,k in ipairs(quadOrder)do local q=corners[k]
    count=count+1;local row=vertices[count];if not row then row={};vertices[count]=row end
    row[1],row[2],row[3],row[4],row[5]=q[1],q[2],q[3],q[4],q[5]
    row[6],row[7],row[8],row[9],row[10],row[11]=color[1],color[2],color[3],.34*fade/(cone and 1.8 or 1),q[6],q[7]
   end
  end
 end
 if count==0 then return 0 end
 if not C.mesh then C.mesh=love.graphics.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2},
  {'VertexColor','float',4},{'ShaftFoot','float',2}},288,'triangles','stream')end
 C.mesh:setVertices(vertices,1,count);C.mesh:setDrawRange(1,count)
 love.graphics.push('all');love.graphics.setShader(C.shader)
 C.shader:send('vp','row',vp);C.shader:send('groundShadow',shadow);Daylight.bind(C.shader,state)
 -- Scattering replaces part of the transmitted scene instead of adding
 -- unbounded white energy to pale paving or the rooftop sky.
 love.graphics.setDepthMode('lequal',false);love.graphics.setBlendMode('alpha','alphamultiply')
 love.graphics.setColor(1,1,1,1);love.graphics.draw(C.mesh);love.graphics.pop()
 return math.min(16,#sites)
end
function C.release()
 for _,k in ipairs{'shader','mesh'}do if C[k]then C[k]:release();C[k]=nil end end
 C.cache=setmetatable({},{__mode='k'})
 nearbySource,nearbyX,nearbyZ,nearbyRadius=nil,nil,nil,nil
 connectedSource,connectedWorld,connectedDef=nil,nil,nil
 nearbyRows,nearbyPool,actorRows,actorProfiles,vertices={},{},{},{},{}
end
return C
