-- Paper-camera adapter of VASC weather.4 WorldWeather precipitation.
-- Source: .worktrees/vasc-weather-sky-20260928/shared/WorldWeather.lua.
-- Design reference: Kanto Dynamic Weather's world-space rain, independently
-- implemented for VASC's scene lifecycle, bounded cache and native palette.
local V=...
local M={MAX_QUADS=12000,CELL=32,RADIUS=5,last={draws=0,count=0}}
local mesh,shader,cacheKey,failed,placements,instanced
M.useInstancing=true
local vertexStorage
local tick,sourceClock=0,nil
local function hash(x,z,s)
 local n=(x*104729+z*13007+s*7919)%2147483647
 n=(n*48271)%2147483647;n=(n*48271)%2147483647
 return n/2147483647
end
M.hash=hash
-- Resolve stable helpers once per mesh build, and each roof-cell coordinate
-- once per sample rather than once per rendered map. No surface values are
-- retained: native script edits and rebuilt roofs are read directly.
function M.surfaceResolver(drawList)
 local shapes=V.data('Shapes')
 return function(map,x,z,heightOnly)
  local height=0
  local hx,hz=math.floor((x+map.ox)/8),math.floor((z+map.oz)/8)
  for _,cache in ipairs(drawList)do
   local row=cache.heights[hz]
   height=math.max(height,row and row[hx]or 0)
  end
  -- Slanted trajectory probes only need the roof clearance. Terrain traits
  -- belong to the terminal impact sample, not the four probes above it.
  if heightOnly then return height+.18 end
  local c=map.layout:cellAt(math.floor(x/16),math.floor(z/16))
  local open=c and not shapes.solid(c)
  return height+.18,open and height<1,c and shapes.water(c)
 end
end
function M.advance(now,storm)
 if sourceClock~=nil then
  local dt=now-sourceClock
  if dt>0 and dt<2 then tick=tick+dt*(storm and 1.35 or 1)end
 end
 sourceClock=now;return tick
end
local corners={{-1,0},{1,0},{1,1},{-1,0},{1,1},{-1,1}}
local trajectory={.25,.5,.75,1}
-- Ground and top-of-rain-column intersections of the actual projection.
-- This includes portrait/orthographic cameras and camera offsets without
-- treating the player's local radius as the visible world.
function M.bounds(vp,height,wind,cell)
 local minx,minz,maxx,maxz=math.huge,math.huge,-math.huge,-math.huge
 for _,y in ipairs{0,height}do for _,u in ipairs{-1,1}do for _,v in ipairs{-1,1}do
  local a,b=vp[1]-u*vp[13],vp[3]-u*vp[15]
  local d,e=vp[5]-v*vp[13],vp[7]-v*vp[15]
  local c=u*(vp[14]*y+vp[16])-vp[2]*y-vp[4]
  local f=v*(vp[14]*y+vp[16])-vp[6]*y-vp[8]
  local det=a*e-b*d
  assert(math.abs(det)>1e-9,'singular precipitation projection')
  local x,z=(c*e-b*f)/det,(a*f-c*d)/det
  minx,minz,maxx,maxz=math.min(minx,x),math.min(minz,z),math.max(maxx,x),math.max(maxz,z)
 end end end
 local pad=wind+cell
 return {math.floor((minx-pad)/cell),math.floor((minz-pad)/cell),math.ceil((maxx+pad)/cell),math.ceil((maxz+pad)/cell)}
end
function M.build(map,focus,storm,neighbors,resolve,profile,bounds,cell,cfg,storage)
 local snow=storm=="snow"
 cell=cell or M.CELL;cfg=cfg or {}
 storm=storm==true or storm=="storm"
 local samplers,stats={}, {groundCells=0,samples=0,impacts=0}
 if not resolve then resolve=function(m,x,z)
  local fn=samplers[m];if not fn then fn=M.sampler(m,stats);samplers[m]=fn end
  return fn(m,x,z)
 end end
 -- Camera-cell changes rebuild the same bounded mesh. Keep row storage
 -- separate from the live array so shrinking coverage cannot upload stale
 -- vertices, while growing back reuses the rows instead of triggering GC.
 local verts,n,used=storage and storage.vertices or {},0,0
 local previous=#verts
 local function add(x,y,z,phase,width,length,kind)
  if n>=M.MAX_QUADS then return end
  n=n+1
  if storage and storage.instanced then
   used=used+1;local row=storage.rows[used]or{};storage.rows[used]=row
   row[1],row[2],row[3],row[4],row[5],row[6],row[7]=x,y,z,phase,width,length,kind
   verts[used]=row;return
  end
  for _,c in ipairs(corners)do
   used=used+1
   local row=storage and storage.rows[used]or nil
   if not row then row={};if storage then storage.rows[used]=row end end
   row[1],row[2],row[3],row[4],row[5]=x,y,z,c[1],c[2]
   row[6],row[7],row[8],row[9]=phase,width,length,kind
   verts[used]=row
  end
 end
 local gx,gz=math.floor(focus[1]/cell),math.floor(focus[3]/cell)
 local function at(x,z,heightOnly)
  local cx,cz=math.floor(x/16),math.floor(z/16)
  if map.inBounds and map:inBounds(cx,cz)then return resolve(map,x,z,heightOnly)end
  for _,nb in ipairs(neighbors or {})do
   local nx,nz=x-(nb.ox or 0),z-(nb.oy or 0)
   if nb.map and nb.map.inBounds and nb.map:inBounds(math.floor(nx/16),math.floor(nz/16))then
    return resolve(nb.map,nx,nz,heightOnly)
   end
  end
  return focus[2]or 0,false
 end
 bounds=bounds or {gx-M.RADIUS,gz-M.RADIUS,gx+M.RADIUS,gz+M.RADIUS}
 local drops=snow and (cfg.snowDrops or 5)or profile and profile.drops or storm and 4 or 3
 -- columnKey is the caller's surface/layout generation. A neighboring map
 -- entering/leaving view alternates a few generations while walking. Keep
 -- four bounded viewports so returning across that seam reuses its columns.
 local columns
 if storage and storage.columnKey~=nil then
  local stamp=table.concat({storage.columnKey,cell,tostring(snow),tostring(storm),drops,
   cfg.snowSize or 1.05,tostring(cfg.impactsEnabled),cfg.splashSize or 2.4,
   cfg.rippleSize or 4.2,cfg.impactLift or .45,focus[2]or 0},':')
  local cells=math.max(0,bounds[3]-bounds[1]+1)*math.max(0,bounds[4]-bounds[2]+1)
  if cells*drops*(snow and 1 or 2)<=M.MAX_QUADS then
   storage.columnGenerations=storage.columnGenerations or {}
   storage.columnSerial=(storage.columnSerial or 0)+1
   local generations=storage.columnGenerations
   local generation=generations[stamp]
   if not generation then
    -- The key includes table identities; retain their owners until eviction
    -- so the allocator cannot reuse an address for unrelated roof geometry.
    generation={columns={},surfaceRefs=storage.surfaceRefs}
    generations[stamp]=generation
   end
   generation.used=storage.columnSerial
   local count,oldest,age=0,nil,math.huge
   for k,g in pairs(generations)do
    count=count+1
    if k~=stamp and g.used<age then oldest,age=k,g.used end
   end
   if count>4 then generations[oldest]=nil;count=count-1 end
   stats.cachedGenerations=count
   storage.columns=generation.columns;storage.columnStamp=stamp
   columns=storage.columns
   for z,row in pairs(columns)do
    if z<bounds[2]or z>bounds[4]then columns[z]=nil
    else for x in pairs(row)do if x<bounds[1]or x>bounds[3]then row[x]=nil end end end
   end
  else
   storage.columns=nil;storage.columnStamp=nil
   storage.columnGenerations=nil;storage.columnSerial=nil
  end
 end
 stats.columnsBuilt,stats.columnsReused,stats.cachedColumns=0,0,0
 local recording
 local function emit(x,y,z,phase,width,length,kind)
  if recording then
   local i=#recording
   recording[i+1],recording[i+2],recording[i+3]=x,y,z
   recording[i+4],recording[i+5],recording[i+6],recording[i+7]=phase,width,length,kind
  end
  add(x,y,z,phase,width,length,kind)
 end
 for iz=bounds[2],bounds[4]do for ix=bounds[1],bounds[3]do
  local row=columns and columns[iz]
  if columns and not row then row={};columns[iz]=row end
  local saved=row and row[ix]
  if saved then
   for i=1,#saved,7 do add(saved[i],saved[i+1],saved[i+2],saved[i+3],saved[i+4],saved[i+5],saved[i+6])end
   stats.impacts=stats.impacts+saved.impacts;stats.columnsReused=stats.columnsReused+1
  else
  recording=columns and {}or nil
  local previousImpacts=stats.impacts
  for k=1,drops do
   local x=(ix+.10+hash(ix,iz,k)*.8)*cell
   local z=(iz+.10+hash(ix,iz,k+7)*.8)*cell
   local y,ground,water=at(x,z)
   -- Sample the slanted trajectory too, so a drop cannot enter beneath a
   -- neighbouring eave while wind carries it toward its terminal column.
   local wind=snow and 6 or storm and 21 or 10
   for _,t in ipairs(trajectory)do
    local roof=at(x-wind*t,z+wind*.52*t,true)
    if roof>y then y=roof;ground=false end
   end
   local phase=hash(ix,iz,k+19)
   emit(x,y,z,phase,snow and((cfg.snowSize or 1.05)+hash(ix,iz,k+29)*.65)or(.32+hash(ix,iz,k+29)*.26),7+hash(ix,iz,k+37)*7,snow and 2 or 0)
   if not snow and ground and cfg.impactsEnabled~=false then
    local size=water and (cfg.rippleSize or 4.2)or(cfg.splashSize or 2.4)
    emit(x,y+(cfg.impactLift or .45),z,phase,size,0,water and 1 or 3)
    stats.impacts=stats.impacts+1
   end
  end
  if recording then recording.impacts=stats.impacts-previousImpacts;row[ix]=recording end
  stats.columnsBuilt=stats.columnsBuilt+1
  end
  if columns then stats.cachedColumns=stats.cachedColumns+1 end
 end end
 for i=used+1,previous do verts[i]=nil end
 M.buildStats=stats
 return verts,n
end
M.GLSL=[[
varying vec2 dropUV;
varying float dropAlpha;
varying float dropKind;
varying float dropCycle;
#ifdef VERTEX
uniform mat4 vp;
uniform vec3 curve;
uniform vec3 axisR;
uniform vec3 axisU;
uniform float fallHeight;
uniform float weatherPixelWidth;
uniform vec3 weatherEye;
uniform float weatherClock;
uniform float wind;
attribute vec4 DropData;
#ifdef RAIN_INSTANCES
attribute vec3 RainPosition;
#endif
vec4 position(mat4 transform_projection,vec4 vertex_position){
 float rate=(DropData.w>1.5 && DropData.w<2.5) ? .10+.035*DropData.x : .92;
 float cycle=fract(weatherClock*rate+DropData.x);
#ifdef RAIN_INSTANCES
 vec3 p=RainPosition;
#else
 vec3 p=vertex_position.xyz;
#endif
 dropUV=VertexTexCoord.xy;dropKind=DropData.w;dropCycle=cycle;
 dropAlpha=1.0;
 if((DropData.w>1.5 && DropData.w<2.5)){
  float fall=1.0-cycle;
  p+=vec3(-wind*fall+sin(weatherClock*.7+DropData.x*28.0)*2.0*fall,fall*fallHeight,wind*.52*fall);
  float depth=abs((vp*vec4(p,1.0)).w);
  float size=min(DropData.y,4.4*depth/max(.001,abs(vp[0][0])*weatherPixelWidth));
  p+=axisR*dropUV.x*size+axisU*(dropUV.y*2.0-1.0)*size;
  dropAlpha*=smoothstep(5.0,16.0,distance(p,weatherEye));
  dropAlpha*=smoothstep(0.0,.07,cycle)*(1.0-smoothstep(.96,1.0,cycle));
 }else if(DropData.w<.5){
  float height=(1.0-cycle)*fallHeight;
  vec3 trail=normalize(vec3(-wind,fallHeight,wind*.52));
  // The trajectory ends on the same sampled surface as its splash.
  p+=vec3(-wind*(1.0-cycle),height,wind*.52*(1.0-cycle));
  float depth=abs((vp*vec4(p,1.0)).w);
  // Bound projected size before a drop reaches the eye: no giant foreground
  // strips, including portrait/first person cameras.
  float width=DropData.y;
  float length=DropData.z;
  dropAlpha*=smoothstep(7.0,22.0,distance(p,weatherEye));
  p+=axisR*(dropUV.x*width)+trail*(dropUV.y*length);
  dropAlpha*=smoothstep(.0,.05,cycle)*(1.0-smoothstep(.97,1.0,cycle));
 }else if(DropData.w>2.5){
  // Upright spray at the actual impact point, bottom anchored to the floor.
  p+=axisR*dropUV.x*DropData.y;
  p.y+=dropUV.y*DropData.y*1.6;
 }else{
  p.x+=dropUV.x*DropData.y;p.z+=(dropUV.y*2.0-1.0)*DropData.y;
 }
 vec2 delta=p.xz-curve.xy;p.y-=dot(delta,delta)*curve.z;
 return vp*vec4(p,1.0);
}
#endif
#ifdef PIXEL
uniform vec3 weatherColor;
uniform float rainIntensity;
uniform float impactDuration;
uniform float impactOpacity;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 sc){
 float alpha;
 if(dropKind>1.5 && dropKind<2.5){
  vec2 q=abs(vec2(dropUV.x,dropUV.y*2.0-1.0));
  // Small pixel crosses and square flakes; never circular bokeh sprites.
  if(dropCycle>.45 && q.x>.34 && q.y>.34)discard;
  alpha=.90*dropAlpha;
 }else if(dropKind<.5){
  // Three readable intensity steps retain the voxel character of the world.
  float tip=1.0-floor(clamp(dropUV.y,0.0,.999)*3.0)/3.0;
  alpha=(.28+.35*tip)*dropAlpha;
 }else if(dropKind>2.5){
  float age=dropCycle/impactDuration;
  if(age>=1.0)discard;
  vec2 q=vec2(dropUV.x,dropUV.y);
  float rise=4.0*age*(1.0-age);
  // Two kicked-up droplets and a short base glint, no translucent quad.
  float spray=1.0-smoothstep(.10,.27,length(vec2(abs(q.x)-(.12+age*.65),q.y-rise*.70)));
  float base=(1.0-smoothstep(.04,.12,q.y))*(1.0-smoothstep(.15,.65,abs(q.x)));
  alpha=max(spray,base*.7)*(1.0-age)*impactOpacity;
 }else{
  float age=dropCycle/impactDuration;
  if(age>=1.0)discard;
  vec2 q=floor(vec2(dropUV.x,dropUV.y*2.0-1.0)*5.0+.5)/5.0;
  float d=max(max(abs(q.x),abs(q.y)),(abs(q.x)+abs(q.y))*.70);
  float radius=.14+age*.72;
  alpha=(1.0-smoothstep(.06,.19,abs(d-radius)))*(1.0-age)*impactOpacity*dropAlpha;
 }
 if(dropKind<1.5 || dropKind>2.5)alpha*=rainIntensity;
 if(alpha<.01)discard;
 return vec4(weatherColor,alpha)*color;
}
#endif
]]
function M.prepareShader()
 local useInstances=M.useInstancing and love.graphics.getSupported().instancing or false
 if instanced~=nil and instanced~=useInstances then M.invalidate()end
 instanced=useInstances
 if not shader then shader=V.require('ShaderCompiler').newShader((instanced and '#define RAIN_INSTANCES\n'or'')..M.GLSL)end
 return shader
end
function M.draw(entries,drawList,mode,vp,eye,focus,tint,pixelWidth,amount)
 M.last={draws=0,count=0}
 if mode~='rain' and mode~='storm' and mode~='snow'then return false end
 local g=love.graphics
 M.prepareShader()
 local cfg=V.require('DioramaConfig').weather.precipitation
 local cell=math.max(8,cfg.cell)
 local profile=V.require('RainStrength').profile(mode)
 local roof=0
 for _,cache in ipairs(drawList)do
  if not cache.weatherTop then
   local top=0;for _,row in pairs(cache.heights)do for _,h in pairs(row)do top=math.max(top,h)end end
   cache.weatherTop=top
  end
  roof=math.max(roof,cache.weatherTop)
 end
 local bounds=M.bounds(vp,cfg.height+roof,mode=='storm' and 21 or 10,cell)
 local perCell=mode=='snow' and cfg.snowDrops or profile.drops*2
 -- Preserve full coverage at extreme zoom before enforcing the mesh budget.
 while (bounds[3]-bounds[1]+1)*(bounds[4]-bounds[2]+1)*perCell>M.MAX_QUADS do
  cell=cell*1.25;bounds=M.bounds(vp,cfg.height+roof,21,cell)
 end
 local key=cell..':'..mode..':'..profile.key..':'..profile.drops..':'..cfg.snowDrops..':'..cfg.snowSize..':'..tostring(cfg.impactsEnabled)..':'..tostring(cfg.splashSize)..':'..tostring(cfg.rippleSize)..':'..tostring(cfg.impactLift)..':'..(focus[2]or 0)
 local wrappers,neighbors={},{}
 for i,e in ipairs(entries)do
  local L=e.def.midLayout
  local w={def=e.def,ox=e.ox*16,oz=e.oy*16,layout=L}
  function w:inBounds(x,z)return x>=0 and z>=0 and x<self.layout.width and z<self.layout.height end
  wrappers[i]=w
  key=key..':'..e.id..':'..e.ox..':'..e.oy..':'..tostring(L)..':'..V.require('WorldGeometry').layoutStamp(L)
  if i>1 then neighbors[#neighbors+1]={map=w,ox=w.ox,oy=w.oz}end
 end
 -- Renderer heightfields are immutable after entry construction. A rebuilt
 -- roof/geometry entry must invalidate cached columns even at the same camera.
 -- Empty border heightfields contribute nothing and can change while walking.
 for _,cache in ipairs(drawList)do if next(cache.heights)then key=key..':'..tostring(cache.heights)end end
 local columnKey=key;key=table.concat(bounds,':')..':'..key
 if key~=cacheKey then
  vertexStorage=vertexStorage or {vertices={},rows={},instanced=instanced}
  vertexStorage.columnKey=columnKey
  -- Keep identities used in the generation key alive. Otherwise Lua could
  -- recycle an old table address for different geometry before the next draw.
  local refs={}
  for _,w in ipairs(wrappers)do refs[#refs+1]=w.layout end
  for _,cache in ipairs(drawList)do if next(cache.heights)then refs[#refs+1]=cache.heights end end
  vertexStorage.surfaceRefs=refs
  local vertices,n=M.build(wrappers[1],focus,mode,neighbors,M.surfaceResolver(drawList),profile,bounds,cell,cfg,vertexStorage)
  if instanced then
   if not mesh then
    local quad={};for i,c in ipairs(corners)do quad[i]={0,0,0,c[1],c[2]}end
    mesh=g.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2}},quad,'triangles','static')
    placements=g.newMesh({{'RainPosition','float',3},{'DropData','float',4}},M.MAX_QUADS,'points','dynamic')
    mesh:attachAttribute('RainPosition',placements,'perinstance');mesh:attachAttribute('DropData',placements,'perinstance')
   end
   if #vertices>0 then placements:setVertices(vertices,1,#vertices)end
  else
   if not mesh then mesh=g.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'DropData','float',4}},M.MAX_QUADS*6,'triangles','dynamic')end
   if #vertices>0 then mesh:setVertices(vertices,1,#vertices);mesh:setDrawRange(1,#vertices)end
  end
  M.count=n;cacheKey=key;M.rebuilds=(M.rebuilds or 0)+1
 end
 local uy,uz=V.require('Camera').cardUp()
 shader:send('vp','row',vp);shader:send('curve',{0,0,0});shader:send('weatherPixelWidth',pixelWidth or g.getWidth())
 shader:send('axisR',{1,0,0});shader:send('axisU',{0,uy,uz});shader:send('fallHeight',cfg.height)
 shader:send('impactDuration',cfg.impactDuration or .32);shader:send('impactOpacity',cfg.impactOpacity or .85)
 shader:send('weatherEye',eye);shader:send('rainIntensity',profile.alpha)
 shader:send('weatherClock',M.advance(V.require('Weather').clock,mode=='storm'))
 shader:send('wind',mode=='snow' and 6 or mode=='storm' and 21 or 10)
 shader:send('weatherColor',mode=='snow' and {.88+.10*tint[1],.91+.08*tint[2],1}or {.72+.12*tint[1],.77+.12*tint[2],.84+.12*tint[3]})
 g.push('all');g.setShader(shader);g.setDepthMode('lequal',false);g.setColor(1,1,1,amount or 1)
 g.setBlendMode('alpha','alphamultiply')
 if M.count>0 then if instanced then g.drawInstanced(mesh,M.count)else g.draw(mesh)end end
 g.pop()
 M.last={draws=1,count=M.count,mode=mode,bounds=bounds,cell=cell};return true
end
function M.invalidate(keepShader)
 -- Scene/config changes invalidate precipitation columns, not shader code.
 -- Full release and an instancing-mode change still drop the program.
 for _,o in ipairs({mesh or false,placements or false})do if o then o:release()end end
 if not keepShader then
  if shader then shader:release()end
  shader,instanced=nil,nil
 end
 mesh,cacheKey,vertexStorage,placements=nil,nil,nil,nil;sourceClock=nil;tick=0
end
return M
