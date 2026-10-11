local Card={ID='oasc.gen3.grass-displacement',VERSION='1.0.0',CAPABILITY='ascendant.grass-displacement.gen3/v1'}
Card.option={key='gen3Card_grassDisplacement',label='GRAS VERDRAENGEN',type='toggle',default=true,
 help='Gras weicht beim Laufen aus und richtet sich danach wieder auf.'}
local uniforms=[[
uniform vec4 oasc_grass_player;
uniform vec4 oasc_grass_actors[8];
uniform int oasc_grass_count;
]]
local functions=[[
#ifdef VERTEX
vec2 oasc_grass_push(vec2 anchor, vec4 actor) {
 vec2 d=anchor-actor.xy;
 float influence=(1.0-smoothstep(0.0,max(actor.z,.001),length(d)))*actor.w;
 return normalize(d+vec2(.0001))*influence;
}
#endif
]]
local vertex=[[
// Match the existing grass material flag; tree crowns must remain untouched.
if(BillboardAnchor.z>=1.5) {
 vec2 oasc_grass_delta=oasc_grass_push(anchor,oasc_grass_player);
 for(int oasc_grass_i=0;oasc_grass_i<8;oasc_grass_i++) {
  if(oasc_grass_i>=oasc_grass_count)break;
  oasc_grass_delta+=oasc_grass_push(anchor,oasc_grass_actors[oasc_grass_i]);
 }
 float oasc_grass_amount=min(length(oasc_grass_delta),1.0);
 if(oasc_grass_amount>0.0) {
  float oasc_grass_lift=clamp(vertex_position.y/16.0,0.0,2.0);
  vertex_position.xz+=normalize(oasc_grass_delta)*oasc_grass_amount*oasc_grass_lift*6.0;
  vertex_position.y*=1.0-oasc_grass_amount*oasc_grass_lift*.25;
 }
}
]]
function Card.descriptor(V)
 local S=V.require('core/RenderSeams');local U=V.require('UniformState');local cfg=V.require('DioramaConfig')
 local GeometryConfig=V.require('GeometryConfig')
 local state={active=false,count=0,player={},rows={},selected={},distances={},matches={},payloads={}}
 local public={isActive=function()return state.active end}
 local emptyActors={}
 for i=1,8 do state.rows[i]={};state.payloads[i]={0,0,0,0}end
 local playerPayload={0,0,0,0}
 local priorPresets={}
 local function clearMotion(row)
  row.x,row.z,row.gid,row.strength,row.rest,row.stop=nil,nil,nil,0,0,0
 end
 local function reset()
  state.map=nil;state.layout=nil;state.count=0;clearMotion(state.player)
  for i=1,8 do clearMotion(state.rows[i]);state.rows[i].used=false;state.selected[i]=nil;state.distances[i]=nil;state.matches[i]=nil
   local p=state.payloads[i];p[1],p[2],p[3],p[4]=0,0,0,0
  end
  playerPayload[1],playerPayload[2],playerPayload[3],playerPayload[4]=0,0,0,0
 end
 local function motion(row,x,z,dt,gid)
  local dx,dz=row.x and x-row.x or 0,row.z and z-row.z or 0
  local distance=math.sqrt(dx*dx+dz*dz)
  if row.gid~=gid or distance>32 then clearMotion(row);distance=0 end
  if dt>0 then
   if distance>.001 then
    local target=math.min(1,distance/dt/48)
    row.strength=(row.strength or 0)+(target-(row.strength or 0))*(1-math.exp(-dt*20))
    row.rest=0;row.stop=row.strength
   else
    row.rest=math.min(.4,(row.rest or 0)+dt)
    local t=row.rest/.4;row.strength=(row.stop or 0)*(1-t*t*(3-2*t))
   end
  end
  row.x,row.z,row.gid=x,z,gid
 end
 local function prepare(ctx)
  local c=cfg.cards and cfg.cards.grassDisplacement
  if not(state.active and c)then return end
  local layout=ctx.def and ctx.def.midLayout
  if state.map~=ctx.id or state.layout~=layout then reset();state.map=ctx.id;state.layout=layout end
  local dt=math.max(0,math.min(.1,tonumber(ctx.dt)or 0))
  local x,z=ctx.playerX or 0,ctx.playerZ or 0
  motion(state.player,x,z,dt,'player')
  local strength=c.enabled~=false and tonumber(c.strength)or 0;strength=math.max(0,math.min(1,strength or 0))
  local radius=math.max(1,math.min(64,tonumber(c.radius)or 14))
  playerPayload[1],playerPayload[2],playerPayload[3],playerPayload[4]=x,z,radius,(state.player.strength or 0)*strength
  local profile=V.mod.options:get('gen3Quality')or cfg.settings.defaultPreset
  local preset=cfg.settings.presets[profile];local policy=preset and preset.cards and preset.cards.grassDisplacement
  local useActors=c.actors~=false and not(type(policy)=='table'and policy.actors==false)
  for i=1,8 do state.selected[i]=nil;state.distances[i]=nil;state.matches[i]=nil;state.rows[i].used=false end
  local count=0
  if useActors then for _,a in ipairs(ctx.actors or emptyActors)do if not a.isPlayer and not a.battleProp then
   local ax,az=a.x+8+(a.xOffset or 0),a.z+16+(a.zOffset or 0)
   local d=(ax-x)^2+(az-z)^2
   local at=1;while at<=count and state.distances[at]<=d do at=at+1 end
   if at<=8 then
    count=math.min(8,count+1)
    for j=count,at+1,-1 do state.selected[j]=state.selected[j-1];state.distances[j]=state.distances[j-1]end
    state.selected[at]=a;state.distances[at]=d
   end
  end end end
  -- Adapter records are transient and sort order can change. Match persistent
  -- tracks by graphics and nearest previous foot instead of table identity.
  for i=1,count do
   local a=state.selected[i];local ax,az=a.x+8+(a.xOffset or 0),a.z+16+(a.zOffset or 0)
   local match,best=nil,32*32
   for j,row in ipairs(state.rows)do if not row.used and row.gid==a.gid and row.x then
    local d=(ax-row.x)^2+(az-row.z)^2;if d<best then match,best=j,d end
   end end
   if match then state.matches[i]=match;state.rows[match].used=true end
  end
  -- Reserve every existing match before assigning free rows to new arrivals.
  for i=1,count do
   local a=state.selected[i];local ax,az=a.x+8+(a.xOffset or 0),a.z+16+(a.zOffset or 0)
   local match=state.matches[i]
   if not match then for j,row in ipairs(state.rows)do if not row.used then match=j;clearMotion(row);break end end end
   local row=state.rows[match];row.used=true;motion(row,ax,az,dt,a.gid)
   local p=state.payloads[i];p[1],p[2],p[3],p[4]=ax,az,radius,(row.strength or 0)*strength
  end
  for i=count+1,8 do state.payloads[i][4]=0 end
  for _,row in ipairs(state.rows)do if not row.used then clearMotion(row)end end
  state.count=count
 end
 local function bind(shader)
  U.send(shader,'oasc_grass_player',playerPayload)
  U.send(shader,'oasc_grass_count',state.count)
  if state.count>0 then U.send(shader,'oasc_grass_actors',unpack(state.payloads,1,state.count))end
 end
 local function deactivate()
  S.unregister(Card.ID);GeometryConfig.unregisterPresentation(Card.ID);reset();state.active=false
  if cfg.cards then cfg.cards.grassDisplacement=nil;if not next(cfg.cards)then cfg.cards=nil end end
  for name,previous in pairs(priorPresets)do
   local p=cfg.settings.presets[name]
   if p and p.cards then p.cards.grassDisplacement=previous.value
    if not previous.hadCards and not next(p.cards)then p.cards=nil end
   end
  end
  priorPresets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',
  requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},
  tests={'tests/gen3_grass_displacement_card_test.lua','tests/gen3_grass_displacement_gpu_test.lua','tests/gen3_grass_displacement_play_test.lua','tests/gen3_grass_displacement_menu_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/GRASS_DISPLACEMENT.md'},saveNamespace=false,
  impact={runtimeOwners={'gen3.render.grass-displacement'},saveWrites={},publicHooks={},files={
   'gen3/lib/cards/GrassDisplacementCard.lua','gen3/cards/GRASS_DISPLACEMENT.md'}},
  lifecycle={install=function()return {installed=true}end,
   activate=function()
    if state.active then return state,public end
    GeometryConfig.registerPresentation(Card.ID,'grassDisplacement',{'enabled','radius','strength','actors'})
    cfg.cards=cfg.cards or{};cfg.cards.grassDisplacement=cfg.cards.grassDisplacement or{enabled=true,radius=14,strength=1,actors=true}
    for name,p in pairs(cfg.settings.presets)do
     priorPresets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.grassDisplacement}
     p.cards=p.cards or{};p.cards.grassDisplacement=p.cards.grassDisplacement or{actors=name~='low'}
    end
    reset();state.active=true
    S.register(Card.ID,'main.uniforms',uniforms..functions)
    -- The clamped vector moves X/Z by at most 2*6 world pixels. Y only
    -- contracts toward zero (factor .5..1), including elevated/negative grass.
    S.register(Card.ID,'main.vertex.post',vertex,nil,{x=12,y=0,z=12,ground=true})
    S.register(Card.ID,'prepare',prepare)
    S.register(Card.ID,'bind',bind);S.register(Card.ID,'release',reset)
    return state,public
   end,deactivate=deactivate,abort=deactivate,
   health=function()local h=S.health(Card.ID);h.active=state.active;h.actors=state.count;return h end}}
end
return Card
