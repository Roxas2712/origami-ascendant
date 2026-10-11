local V=...
local Card={ID='oasc.gen3.particles',VERSION='1.0.0',CAPABILITY='ascendant.particles.gen3/v1'}
Card.option={key='gen3Card_particles',label='UMGEBUNGSPARTIKEL',type='toggle',default=true,
 help='Pollen, fallende Blaetter, Lichtstaub, Glut und Schornsteindampf. Maximal 300 Partikel.'}
Card.GLSL=[[
#pragma language glsl3
varying vec4 oasc_particles_color;
varying vec2 oasc_particles_uv;
#ifdef VERTEX
uniform mat4 oasc_particles_vp;
uniform vec2 oasc_particles_up;
uniform float oasc_particles_depthScale;
attribute vec3 oasc_particles_position;
attribute vec3 oasc_particles_shape;
attribute vec4 oasc_particles_tint;
vec4 position(mat4 transform_projection,vec4 vertex_position){
 vec2 q=vertex_position.xy;
 float a=oasc_particles_shape.y;
 q=mat2(cos(a),sin(a),-sin(a),cos(a))*q*oasc_particles_shape.x;
 vec3 p=oasc_particles_position+vec3(q.x,q.y*oasc_particles_up.x,q.y*oasc_particles_up.y);
 oasc_particles_uv=vec2((VertexTexCoord.x+oasc_particles_shape.z)/8.0,VertexTexCoord.y);
 oasc_particles_color=oasc_particles_tint;
 vec4 projected=oasc_particles_vp*vec4(p,1.0);
 projected.z*=oasc_particles_depthScale;
 return projected;
}
#endif
#ifdef PIXEL
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 vec4 p=Texel(tex,oasc_particles_uv)*oasc_particles_color;
 if(p.a<.005)discard;
 return p;
}
#endif
]]
function Card.descriptor(V)
 local S,U,C,G=V.require('core/RenderSeams'),V.require('UniformState'),V.require('DioramaConfig'),V.require('GeometryConfig')
 local Pool=V.require('cards/ParticlePool');local pool=Pool.new()
 local state={active=false,updateMs=0,drawMs=0,maxUpdateMs=0,maxDrawMs=0,setupMs=0,resourceMs=0,emitters={},count=0}
 local presets={};local up={1,0};local mesh,instances,shader,atlas
 local def,layout,stamp,maps,forest,ready,smoke,smokeCamera
 local function release()
  if mesh then mesh:release();mesh=nil end
  if instances then instances:release();instances=nil end
  if shader then U.invalidate(shader);shader:release();shader=nil end
  if atlas then atlas:release();atlas=nil end
  smoke=nil;smokeCamera=nil;pool.count=0;state.count=0;state.emitters={};def,layout,stamp,maps,ready=nil,nil,nil,nil,nil
 end
 local function resources()
  if mesh then return true end
  local start=love.timer.getTime()
  local file,data
  local ok,err=pcall(function()
   assert(love.graphics.getSupported().instancing,'GPU instancing unavailable')
   file=love.filesystem.newFileData(assert(V.mod:read('gen3/data/particles/atlas.png')),'atlas.png')
   data=love.image.newImageData(file);assert(data:getWidth()==128 and data:getHeight()==16,'invalid particle atlas')
   atlas=love.graphics.newImage(data);atlas:setFilter('linear','linear');atlas:setWrap('clamp','clamp')
   shader=V.require('ShaderCompiler').newShader(Card.GLSL)
   mesh=love.graphics.newMesh({{'VertexPosition','float',2},{'VertexTexCoord','float',2}},
    {{-1,-1,0,1},{1,-1,1,1},{1,1,1,0},{-1,-1,0,1},{1,1,1,0},{-1,1,0,0}},'triangles','static')
   instances=love.graphics.newMesh({{'oasc_particles_position','float',3},{'oasc_particles_shape','float',3},{'oasc_particles_tint','float',4}},Pool.MAX,'points','stream')
   mesh:attachAttribute('oasc_particles_position',instances,'perinstance')
   mesh:attachAttribute('oasc_particles_shape',instances,'perinstance')
   mesh:attachAttribute('oasc_particles_tint',instances,'perinstance');mesh:setTexture(atlas)
  end)
  if data then data:release()end;if file then file:release()end
  state.resourceMs=(love.timer.getTime()-start)*1000
  if not ok then release();state.error=tostring(err);if V.mod.log then V.mod.log:info('Environment particles disabled: '..state.error)end;return false end
  return true
 end
 local function policy()
  local p=C.settings.presets[V.mod.options:get('gen3Quality')or C.settings.defaultPreset]
  return p and p.cards and p.cards.particles
 end
 local function add(kind,count,x,y,z,radius,height,seed)
  state.emitters[#state.emitters+1]={kind=kind,count=count,x=x,y=y,z=z,radius=radius,height=height,seed=seed or #state.emitters+1}
 end
 local function setup(ctx,c)
  local start=love.timer.getTime();state.emitters={};def=ctx.def;layout=def.midLayout
  stamp=V.require('WorldGeometry').layoutStamp(layout);maps=c.maps;forest=false
  local id=ctx.id or def.id or ''
  forest=ctx.outdoors and C.forest and C.forest.maps[id]or false
  local selected=c.maps[id]
  if selected==nil then
   if forest then selected=c.maps.forest
   elseif ctx.outdoors and(id:match('CINNABAR')or id:match('MT_EMBER')or id=='EM_MT_CHIMNEY')then selected=c.maps.volcano
   elseif ctx.outdoors and(id:match('^EM_ROUTE')or id:match('^FR_ROUTE_')or id:match('^SEVII_.*PATH'))then selected=c.maps.route
   elseif id=='FR_VERMILION_CITY_GYM'then selected=c.maps.electricGym end
  end
  if id=='FR_VERMILION_CITY_GYM'and type(selected)=='table'and selected.kind=='sparks'then
   local plan=V.require('FireRedElectricGym').plan(def)
   local powerIndex=0;local count=math.max(0,math.floor(tonumber(selected.count)or 15))
   if plan then for _,o in ipairs(plan.objects)do if o.kind=='electricPower'then
    powerIndex=powerIndex+1
    add('sparks',math.floor(count/2)+(powerIndex==1 and count%2 or 0),o.x+8,
     C.interiors.fireredElectricGym.powerHeight*V.require('Billboard').heightScale()+1,o.y+40.1,2,8)
   end end end
  elseif type(selected)=='table'and Pool.styles[selected.kind]then
   -- Distributed across real walkable floor cells, not camera-centred circles.
   local Sh=V.data('Shapes');local total=math.min(300,math.max(0,math.floor(tonumber(selected.count)or 0)))
   -- Store cells compactly; only the selected (at most 300) sites need tables.
   local candidates={};local width=layout.width
   for z=1,layout.height-2 do for x=1,layout.width-2 do
    local q=layout:cellAt(x,z)
    if q and q.mid~=0 and not Sh.solid(q)and not Sh.water(q)then candidates[#candidates+1]=z*width+x end
   end end
   if tonumber(selected.cellsPerParticle)and selected.cellsPerParticle>0 then
    total=math.min(300,math.max(1,math.floor(#candidates/selected.cellsPerParticle+.5)))
   end
   local sites={}
   for i=1,total do if #candidates>0 then
    local cell=candidates[(i*7919)%#candidates+1];local h=(i*37*7919+104729)%65521/65521
    sites[#sites+1]={x=(cell%width)*16+8,y=2,z=math.floor(cell/width)*16+8,h=h,c=math.cos(h*math.pi*2),s=math.sin(h*math.pi*2)}
   end end
   if #sites>0 then
    add(selected.kind,#sites,0,0,0,selected.radius or 6,selected.height,1)
    local emitter=state.emitters[#state.emitters];emitter.sites=sites
    if selected.size then emitter.sizeScale=selected.size/Pool.styles[selected.kind][2]end
   end
  end
  if ctx.cave and c.maps.caveEntrance~=false then
   for _,w in ipairs(def.warps or{})do
    local dest=w.destMap or w.map;local exterior=ctx.game and ctx.game.data and ctx.game.data.maps[dest]
    if w.x and w.y and exterior and V.data('Shapes').outdoors(exterior)then
     add('entrance',8,w.x*16+8,2,w.y*16+8,9,20)
     state.emitters[#state.emitters].exterior={def=exterior,id=dest}
    end
   end
  end
  smoke=nil
  if ctx.outdoors and c.maps.chimneys~=false then smoke=V.require('cards/ChimneySmoke').build(def)end
  smokeCamera=smoke and V.require('Camera').elevation()
  state.setupMs=(love.timer.getTime()-start)*1000;ready=true
 end
 local function prepare(ctx)
  local start=love.timer.getTime();Pool.begin(pool);state.count=0
  local c=C.cards and C.cards.particles
  local policy=policy()
  if not(state.active and c and c.enabled~=false and ctx.def and ctx.def.midLayout)or state.error
   or type(policy)=='table'and policy.enabled==false then return end
  if not resources()then return end
  local L=ctx.def.midLayout;local currentStamp=V.require('WorldGeometry').layoutStamp(L)
  if not ready or ctx.def~=def or L~=layout or stamp~=currentStamp or maps~=c.maps or smoke and smokeCamera~=V.require('Camera').elevation() then setup(ctx,c)end
  local limit=math.min(Pool.MAX,math.max(0,math.floor(tonumber(c.budget)or 300)),type(policy)=='table'and policy.budget or 300)
  local emission=math.max(0,math.min(3,tonumber(c.emission)or 1))
  local a=ctx.atmosphere;local ambient=a and a.ambient
  local brightness=ambient and math.min(1,(ambient[1]+ambient[2]+ambient[3])/3+.1)or .7
  local t=ctx.time or 0;local d=C.dynamicTexture
  local wind=d and d.enabled and math.sin(t*(d.speed or 1)*.08)*math.min(2,d.amplitude or 1)or 0
  local weather=ctx.weatherMode;local night=a and a.solar and a.solar.night or 0
  if smoke then V.require('cards/ChimneySmoke').emit(smoke,ctx,pool,Pool,emission,limit,wind,brightness)end
  for _,em in ipairs(state.emitters)do
   local kind=em.kind;local opacity=1
   if kind=='entrance'then
    local exteriorWeather=em.exterior and V.require('Weather').peekSkyState(em.exterior)or weather
    kind=exteriorWeather=='snow'and'snowdrift'or'dust'
   end
   if kind=='pollen'then opacity=(weather=='rain'or weather=='storm'or weather=='snow')and 0 or 1-night end
   if kind=='leaves'and weather=='snow'then opacity=0 end
   if opacity>0 then Pool.emit(pool,kind,em.count*emission,em.x,em.y,em.z,em.radius,em.height,t,wind,brightness,opacity,em.seed,limit,nil,em.sites,em.sizeScale)end
  end
  if (forest or ctx.cave)and a and a.shafts and c.maps.shaftDust~=false then
   for _,shaft in ipairs(a.shafts)do
    if (shaft.fade or 0)>0 and(shaft.alpha or 0)>0 then
     Pool.emit(pool,'dust',5*emission,shaft.x,2,shaft.z,math.min(8,(shaft.width or 12)*.25),
      (shaft.height or 40)*.55,t,0,math.max(.3,brightness),shaft.fade,shaft.x*17+shaft.z,limit,shaft.slant)
    end
   end
  end
  state.count=pool.count;state.updateMs=(love.timer.getTime()-start)*1000
  state.maxUpdateMs=math.max(state.maxUpdateMs,state.updateMs)
 end
 local function draw(ctx)
  local start=love.timer.getTime();state.drawMs=0
  if pool.count==0 or not mesh or not ctx.depth or not ctx.canvas then return end
  up[1],up[2]=V.require('Camera').cardUp()
  U.send(shader,'oasc_particles_depthScale',ctx.depthScale or 1)
  U.send(shader,'oasc_particles_vp','row',ctx.vp);U.send(shader,'oasc_particles_up',up)
  instances:setVertices(pool.rows,1,pool.count)
  -- Renderer already has the matching scene/depth targets bound. Preserve
  -- every GL state; transparent motes test depth but never write it.
  love.graphics.push('all');love.graphics.setShader(shader);love.graphics.setColor(1,1,1,1)
  love.graphics.setDepthMode('lequal',false);love.graphics.setBlendMode('alpha','alphamultiply')
  love.graphics.drawInstanced(mesh,pool.count);love.graphics.pop()
  state.drawMs=(love.timer.getTime()-start)*1000;state.maxDrawMs=math.max(state.maxDrawMs,state.drawMs)
 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);release();state.active=false;state.error=nil
  if C.cards then C.cards.particles=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name]
   if p and p.cards then p.cards.particles=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end
  end
  presets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',
  requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_chimney_native_test.lua','tests/gen3_chimney_smoke_test.lua','tests/gen3_particle_resource_lifecycle_test.lua','tests/gen3_particle_setup_test.lua','tests/gen3_particles_card_test.lua','tests/gen3_particles_gpu_test.lua','tests/gen3_particles_play_test.lua','tests/gen3_particles_absence_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/PARTICLES.md'},
  impact={runtimeOwners={'gen3.render.particles'},saveWrites={},publicHooks={},
   files={'gen3/lib/cards/ParticlesCard.lua','gen3/lib/cards/ParticlePool.lua','gen3/lib/cards/ChimneySmoke.lua','gen3/data/particles/atlas.png','gen3/cards/PARTICLES.md'}},
  lifecycle={install=function()return {installed=true}end,
   activate=function()
    if state.active then return state end
    G.registerPresentation(Card.ID,'particles',{'enabled','budget','emission','maps'})
    C.cards=C.cards or{};C.cards.particles=C.cards.particles or{enabled=true,budget=300,emission=1,
     maps={route={kind='pollen',count=40,cellsPerParticle=30,size=2.5},forest={kind='leaves',count=25},volcano={kind='embers',count=30},
      electricGym={kind='sparks',count=15},chimneys=true,caveEntrance=true,shaftDust=true}}
    for name,p in pairs(C.settings.presets)do
     presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.particles}
     p.cards=p.cards or{};if p.cards.particles==nil then p.cards.particles={enabled=name~='off',budget=name=='low'and 80 or 300} end
    end
    state.active=true;state.error=nil
    -- Activation runs during mod loading (or an explicit menu toggle).
    -- Compile/upload here, before the first visible particle frame. Keep the
    -- lazy path for renderer release/recreation and off -> enabled presets.
    local selected=policy()
    if C.cards.particles.enabled~=false and not(type(selected)=='table'and selected.enabled==false)then resources()end
    S.register(Card.ID,'prepare',prepare);S.register(Card.ID,'afterActors',draw);S.register(Card.ID,'release',release)
    return state,{isActive=function()return state.active end}
   end,deactivate=deactivate,abort=deactivate,
   health=function()
    local h=S.health(Card.ID);h.active=state.active;h.ok=h.ok and not state.error;h.error=h.error or state.error
    h.count=pool.count;h.budget=Pool.MAX;h.emitters=#state.emitters;h.updateMs=state.updateMs;h.drawMs=state.drawMs
    h.maxUpdateMs=state.maxUpdateMs;h.maxDrawMs=state.maxDrawMs;h.setupMs=state.setupMs;h.resourceMs=state.resourceMs
    h.chimneys=smoke and #smoke.groups or 0;h.visibleChimneys=smoke and smoke.visible or 0;h.smokingChimneys=smoke and smoke.active or 0;h.chimneyRolls=smoke and smoke.rolls or 0
    h.gpuTimeAvailable=false;h.resources=mesh~=nil;return h
   end}}
end
return Card
