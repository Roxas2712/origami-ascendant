local Card={ID='oasc.gen3.paper-surface',VERSION='1.0.0',CAPABILITY='ascendant.paper-surface.gen3/v1'}
Card.option={key='gen3Card_paperSurface',label='PAPIEROBERFLAECHE',type='toggle',default=true,
 help='Feine Papierfasern und beleuchtete Falzkanten bei tiefstehender Sonne.'}
local uniforms=[[
uniform Image oasc_surface_fiber;
uniform vec4 oasc_surface_params; // scale, fiber strength, crease strength, warm daylight
uniform float oasc_surface_mesh;
varying vec4 oasc_surface_distances;
#ifdef VERTEX
attribute vec4 oasc_surface_edge;
#endif
]]
local vertex=[[
oasc_surface_distances=oasc_surface_edge;
]]
local pre=[[
// All implicit texture derivatives and edge coverage run before any discard.
vec2 oasc_surface_uv=(worldPosition.xz+worldPosition.y*.37)*oasc_surface_params.x;
vec3 oasc_surface_n=vec3(0.0,0.0,1.0);
// Avoid a fiber texture fetch when its uniform daylight weight is zero.
if(oasc_surface_params.w>0.0)oasc_surface_n=Texel(oasc_surface_fiber,oasc_surface_uv).rgb*2.0-1.0;
vec3 oasc_surface_width=max(fwidth(oasc_surface_distances.xyz),vec3(.001));
vec3 oasc_surface_coverage=vec3(1.0)-smoothstep(vec3(0.0),oasc_surface_width,oasc_surface_distances.xyz);
float oasc_surface_fold=max(max(oasc_surface_coverage.x,oasc_surface_coverage.y),oasc_surface_coverage.z)
 *step(.5,oasc_surface_distances.w)*oasc_surface_mesh;
]]
local fragment=[[
if(oasc_surface_params.w>0.0 && max(max(spriteFace,actorFace),max(plantFace,grassFace))<.5
 && max(max(fenceFace,signFace),max(waterFace,roomVoidFace))<.5 && max(nativeLavaFace,electricBeam)<.5
 && roofPaneFace<.5){
 vec3 oasc_surface_fn=normalize(vec3(oasc_surface_n.xy*oasc_surface_params.y,1.0));
 float oasc_surface_grazing=1.0-abs(dot(normal,normalize(cameraEye-worldPosition)));
 float oasc_surface_light=max(0.0,sunStrength*daylightDirect)*oasc_surface_params.w*(1.0-shadow*shadowStrength);
 float oasc_surface_grain=dot(oasc_surface_fn.xy,normalize(sunDirection.xz+vec2(.0001)))*mix(.35,1.0,oasc_surface_grazing);
 float oasc_surface_facing=dot(normal,normalize(sunDirection));
 float oasc_surface_crease=oasc_surface_fold*oasc_surface_params.z*oasc_surface_facing;
 lit*=1.0+oasc_surface_light*(oasc_surface_grain*.3+clamp(oasc_surface_crease,-.12,.10));
}
]]
function Card.descriptor(V)
 local S=V.require('core/RenderSeams');local U=V.require('UniformState');local cfg=V.require('DioramaConfig')
 local G=V.require('GeometryConfig');local Geo=V.require('cards/PaperSurfaceGeometry');local DN=V.require('DayNight')
 local state={active=false,rows={},queue={},bytes=0,pending=0,maxSliceMs=0,completed=0,creaseEdges=0,roofCreaseEdges=0,skippedMeshes=0,cancelledMeshes=0,maxSlicePhase='idle'}
 local metal=select(1,love.graphics.getRendererInfo())=='Metal'
 -- Metal caches raw BufferBindings even for inputs absent from the current
 -- shader. Never replace a published attribute on a live parent mesh: a
 -- subsequent shadow/reflection draw can still dereference the old buffer.
 -- Values must not reference their weak parent key (LuaJIT is Lua 5.1).
 local retained=setmetatable({},{__mode='k'})
 local function retainedBytes()
  local bytes=0
  for mesh,row in pairs(retained)do
   if pcall(mesh.getVertexCount,mesh)then bytes=bytes+row.bytes
   else row.attribute:release();retained[mesh]=nil end
  end
  return bytes
 end
 local public={isActive=function()return state.active end}
 local params={.02,.6,.8,0};local priorPresets={};local enabled=false
 local function clock()return (V.clock or love.timer.getTime)()end
 local function releaseMesh(mesh)
  local row=state.rows[mesh];if not row then return end
  if row.attribute then
   if metal then
    pcall(mesh.setAttributeEnabled,mesh,Geo.ATTRIBUTE,false)
    retained[mesh]={attribute=row.attribute,bytes=row.bytes,stats=row.stats}
   else
    pcall(mesh.detachAttribute,mesh,Geo.ATTRIBUTE)
    row.attribute:release()
   end
   row.attribute=nil
  end
  if row.upload then row.upload:release();row.upload=nil end
  if row.co then state.pending=state.pending-1 end
  row.co=nil;row.cancelled=true;state.bytes=state.bytes-row.bytes;state.rows[mesh]=nil
 end
 local function release()
  for mesh in pairs(state.rows)do releaseMesh(mesh)end
  state.queue={};state.pending=0
  local worker=V.loaded and V.loaded['cards/PaperSurfaceWorker'];if worker then worker.release()end
  if state.image then state.image:release();state.image=nil end
 end
 local function image()
  if state.image then return state.image end
  local file,data,texture
  local ok,err=pcall(function()
   file=love.filesystem.newFileData(assert(V.mod:read('gen3/data/paper/fiber-normal.png')),'fiber-normal.png')
   data=love.image.newImageData(file)
   assert(data:getWidth()==512 and data:getHeight()==512,'paper fiber must be 512 square')
   texture=love.graphics.newImage(data,{mipmaps=true,linear=true})
   texture:setFilter('linear','linear');texture:setMipmapFilter('linear');texture:setWrap('repeat','repeat')
  end)
  if data then data:release()end;if file then file:release()end
  if not ok then if texture then texture:release()end;error(err,0)end
  state.image=texture;return texture
 end
 local function pump()
  local row=state.queue[1]
  while row do
   -- A cancelled native build can free its owned mesh before it ever enters
   -- the renderer cache. Treat that as normal cancellation, not a Card fault.
   if not row.cancelled and not pcall(row.mesh.getVertexCount,row.mesh)then
    state.cancelledMeshes=state.cancelledMeshes+1;releaseMesh(row.mesh)
   end
   if not row.cancelled then break end
   table.remove(state.queue,1);row=state.queue[1]
  end
  if not row then return end
  local started=clock();row.deadline=started+.00035;row.steps=0
  local ok,attribute,stats=coroutine.resume(row.co)
  local elapsed=(clock()-started)*1000
  if elapsed>state.maxSliceMs then state.maxSliceMs=elapsed;state.maxSlicePhase=row.phase or 'scan'end
  if not ok then releaseMesh(row.mesh);error(attribute,0)end
  if coroutine.status(row.co)=='dead'then
   row.co=nil;state.pending=state.pending-1;state.completed=state.completed+1
   row.attribute=attribute;row.upload=nil;row.stats=stats;state.creaseEdges=state.creaseEdges+stats.creases;state.roofCreaseEdges=state.roofCreaseEdges+(stats.roofCreases or 0)
   if attribute then row.mesh:attachAttribute(Geo.ATTRIBUTE,attribute);row.mesh:setAttributeEnabled(Geo.ATTRIBUTE,true)
   else state.bytes=state.bytes-row.bytes;row.bytes=0 end
   table.remove(state.queue,1)
  end
 end
 local function prepare(ctx)
  local c=cfg.cards and cfg.cards.paperSurface
  local quality=V.mod.options:get('gen3Quality')or cfg.settings.defaultPreset
  local p=cfg.settings.presets[quality];p=p and p.cards and p.cards.paperSurface
  enabled=state.active and c and c.enabled~=false and not(type(p)=='table'and p.enabled==false)
  local phase=DN.mix(DN.time());local warm=math.min(1,(phase.dawn or 0)+(phase.golden or 0)+(phase.dusk or 0))
  params[1]=c and math.max(.001,math.min(.1,tonumber(c.scale)or .02))or .02
  params[2]=c and math.max(0,math.min(1,tonumber(c.strength)or .6))or 0
  params[3]=c and math.max(0,math.min(1,tonumber(c.crease)or .8))or 0
  params[4]=enabled and ctx.outdoors and not ctx.cave and warm or 0
  if enabled then pump()end
 end
 local function bind(shader)
  U.send(shader,'oasc_surface_fiber',image());U.send(shader,'oasc_surface_params',params)
  U.send(shader,'oasc_surface_mesh',0)
 end
 local function bindMesh(shader,mesh,ctx,source,instances)
  local row=state.rows[mesh]
  if enabled and ctx.outdoors and not ctx.cave and source and source.midToSlot and not instances and not row then
   local kept=retained[mesh]
   if kept then
    row={mesh=mesh,attribute=kept.attribute,bytes=kept.bytes,stats=kept.stats}
    retained[mesh]=nil;state.rows[mesh]=row;state.bytes=state.bytes+row.bytes
    mesh:setAttributeEnabled(Geo.ATTRIBUTE,true)
   end
  end
  if enabled and ctx.outdoors and not ctx.cave and source and source.midToSlot and not instances and not row then
   local bytes=mesh:getVertexCount()*4
   -- Sparse four-byte attributes also cover combined city meshes. The
   -- retained-memory cap applies across all meshes; scanning/upload stays sliced.
   if bytes<=32*1024*1024-state.bytes-retainedBytes()then
    row={mesh=mesh,bytes=bytes};state.rows[mesh]=row;state.bytes=state.bytes+bytes;state.pending=state.pending+1
    row.co=coroutine.create(function()
     local function tick(phase)
      row.phase=phase;row.steps=row.steps+1
      if row.steps>=2048 or row.steps%16==0 and clock()>row.deadline then coroutine.yield()end
     end
     local hasWorker,worker=pcall(V.require,'cards/PaperSurfaceWorker')
     local data,stats,handled
     if hasWorker then
      local raw=Geo.capture(mesh,tick)
      if raw then data,stats,handled=worker.build(raw)end
     end
     if not handled then data,stats=Geo.build(mesh,tick)end
     if not data then return nil,stats end
     -- Separate the atomic GPU upload from adjacency work in its own slice.
     coroutine.yield()
     local attribute=Geo.upload(data,tick,function(value)row.upload=value end)
     return attribute,stats
    end)
    state.queue[#state.queue+1]=row
   else
    row={mesh=mesh,bytes=0,skipped=true};state.rows[mesh]=row;state.skippedMeshes=state.skippedMeshes+1
   end
  end
  U.send(shader,'oasc_surface_mesh',row and row.attribute and enabled and 1 or 0)
 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);release();state.active=false;enabled=false
  if cfg.cards then cfg.cards.paperSurface=nil;if not next(cfg.cards)then cfg.cards=nil end end
  for name,old in pairs(priorPresets)do local p=cfg.settings.presets[name]
   if p and p.cards then p.cards.paperSurface=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end
  end
  priorPresets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',
  requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_paper_surface_partition_test.lua','tests/gen3_paper_surface_gpu_test.lua','tests/gen3_paper_surface_geometry_test.lua','tests/gen3_paper_surface_play_test.lua','tests/gen3_paper_surface_menu_play_test.lua','tests/card_rollback_test.lua'},
  docs={'gen3/cards/PAPER_SURFACE.md'},impact={runtimeOwners={'gen3.render.paper-surface'},saveWrites={},publicHooks={},files={
   'gen3/lib/cards/PaperSurfaceCard.lua','gen3/lib/cards/PaperSurfaceGeometry.lua','gen3/lib/cards/PaperSurfaceWorker.lua','gen3/data/paper/fiber-normal.png',
   'gen3/data/paper/FIBER_PROVENANCE.json','gen3/cards/PAPER_SURFACE.md'}},
  lifecycle={install=function()return {installed=true}end,
   activate=function()
    if state.active then return state,public end
    image()
    G.registerPresentation(Card.ID,'paperSurface',{'enabled','scale','strength','crease'})
    cfg.cards=cfg.cards or{};cfg.cards.paperSurface=cfg.cards.paperSurface or{enabled=true,scale=.02,strength=.6,crease=.8}
    for name,p in pairs(cfg.settings.presets)do
     priorPresets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.paperSurface}
     p.cards=p.cards or{};if p.cards.paperSurface==nil then p.cards.paperSurface={enabled=name~='off'and name~='low'} end
    end
    state.active=true
    S.register(Card.ID,'main.uniforms',uniforms)
    -- Only forwards an attribute; it never moves a vertex.
    S.register(Card.ID,'main.vertex.post',vertex,nil,{x=0,y=0,z=0})
    S.register(Card.ID,'main.fragment.pre',pre);S.register(Card.ID,'main.fragment.lit',fragment)
    S.register(Card.ID,'prepare',prepare);S.register(Card.ID,'bind',bind);S.register(Card.ID,'bindMesh',bindMesh)
    S.register(Card.ID,'releaseMesh',releaseMesh);S.register(Card.ID,'release',release)
    return state,public
   end,deactivate=deactivate,abort=deactivate,
   health=function()
    local h=S.health(Card.ID);h.active=state.active;h.pendingMeshes=state.pending;h.attributeBytes=state.bytes
    h.completedMeshes=state.completed;h.creaseEdges=state.creaseEdges;h.roofCreaseEdges=state.roofCreaseEdges;h.maxBuildSliceMs=state.maxSliceMs;h.maxSlicePhase=state.maxSlicePhase;h.skippedMeshes=state.skippedMeshes
    h.cancelledMeshes=state.cancelledMeshes;h.retainedAttributeBytes=retainedBytes()
    h.fiberMipmaps=state.image and state.image:getMipmapCount()or 0
    return h
   end}}
end
return Card
