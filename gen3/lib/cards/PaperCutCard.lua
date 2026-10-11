local Card={ID='oasc.gen3.paper-cut',VERSION='1.0.1',CAPABILITY='ascendant.paper-cut.gen3/v1'}
Card.option={key='gen3Card_paperCut',label='PAPIERKANTEN',type='toggle',default=true,
 help='Feine Schnittkanten und kurze, harte Stapelschatten.'}
local uniforms=[[
uniform vec3 oasc_cut_params;
uniform vec2 oasc_cut_texel;
uniform Image oasc_cut_mask;
uniform float oasc_cut_source; // -1 unavailable, 0 atlas, 1 exterior-only sprite mask
]]
local functions=[[
#ifdef PIXEL
float oasc_cut_alpha(Image tex,vec2 uv){
 if(uv.x<0.0||uv.y<0.0||uv.x>=1.0||uv.y>=1.0)return 0.0;
 return Texel(tex,uv).a;
}
float oasc_cut_edge(Image tex,vec2 uv){
 if(oasc_cut_source>.5)return Texel(oasc_cut_mask,uv).a;
 vec2 d=oasc_cut_texel*oasc_cut_params.y;
 float n=4.0-oasc_cut_alpha(tex,uv+vec2(d.x,0.0))-oasc_cut_alpha(tex,uv-vec2(d.x,0.0))
  -oasc_cut_alpha(tex,uv+vec2(0.0,d.y))-oasc_cut_alpha(tex,uv-vec2(0.0,d.y));
 return Texel(tex,uv).a*clamp(n,0.0,1.0);
}
#endif
]]
local fragment=[[
if(oasc_cut_source>=0.0 && actorFace<.5 && max(max(spriteFace,plantFace),max(fenceFace,signFace))>.5){
 float oasc_cut_e=oasc_cut_edge(tex,uv);
 // Keep cut paper in the existing lighting: it must not emit white at night.
 float oasc_cut_light=clamp(max(max(lit.r,lit.g),lit.b)*1.15,0.0,1.0);
 vec3 oasc_cut_paper=vec3(.95,.92,.86)*oasc_cut_light*oasc_cut_params.z;
 lit=mix(lit,lit*.35+oasc_cut_paper*.65,oasc_cut_e*oasc_cut_params.x);
}
]]
function Card.descriptor(V)
 local S=V.require('core/RenderSeams');local U=V.require('UniformState');local cfg=V.require('DioramaConfig')
 local G=V.require('GeometryConfig');local Contacts=V.require('ContactShadows')
 local state={active=false,masks={},layer={enabled=false,stackShadow=0},maskCount=0}
 local public={isActive=function()return state.active end}
 local params,texel={0,1,1},{1,1};local priorPresets={}
 local function release()
  for _,row in pairs(state.masks)do if row.owned then row.image:release()end end
  state.masks={};state.maskCount=0
  if state.blank then state.blank:release();state.blank=nil end
 end
 local function prepare(ctx)
  local c=cfg.cards and cfg.cards.paperCut
  local profile=V.mod.options:get('gen3Quality')or cfg.settings.defaultPreset
  local p=cfg.settings.presets[profile];local policy=p and p.cards and p.cards.paperCut
  local enabled=state.active and c and c.enabled~=false and not(type(policy)=='table'and policy.enabled==false)
  params[1]=enabled and math.max(0,math.min(1,tonumber(c.strength)or .55))or 0
  params[2]=c and math.max(1,math.min(2,math.floor((tonumber(c.width)or 1)+.5)))or 1
  params[3]=c and math.max(0,math.min(1.5,tonumber(c.warmth)or 1))or 1
  state.layer.enabled=not not enabled
  state.layer.stackShadow=c and math.max(0,math.min(1,tonumber(c.stackShadow)or .55))or 0
  local direction=ctx.atmosphere and ctx.atmosphere.direction
  local x,z=direction and -direction[1]or 0,direction and -direction[3]or 0
  local length=math.sqrt(x*x+z*z)
  Contacts.stackDirection[1],Contacts.stackDirection[2]=x/math.max(length,.0001)*1.5,z/math.max(length,.0001)*1.5
 end
 local function bind(shader)
  U.send(shader,'oasc_cut_params',params);U.send(shader,'oasc_cut_source',-1)
 end
 local function texture(shader,image,ctx,source)
  if not U.has(shader,'oasc_cut_source')then return end
  if not state.blank then
   local data=love.image.newImageData(1,1);state.blank=love.graphics.newImage(data);data:release()
  end
  U.send(shader,'oasc_cut_mask',state.blank)
  if params[1]<=0 or not image or not source then U.send(shader,'oasc_cut_source',-1);return end
  local w,h=image:getDimensions();texel[1],texel[2]=1/w,1/h;U.send(shader,'oasc_cut_texel',texel)
  -- Native tilesets also expose quads. They use direct atlas alpha sampling;
  -- only actor sheets need a per-pose exterior mask (and its flood fill).
  if source.midToSlot then U.send(shader,'oasc_cut_source',0)
  elseif source.quads then
   -- Native actor sheets already provide CPU pixels and per-pose bounds. Flood
   -- the exterior per pose so eyes and enclosed alpha holes never get a rim.
   if not source.imageData then U.send(shader,'oasc_cut_source',-1);return end
   local rim=V.require('SpriteRim');local native=rim.cache[image]
   local row=state.masks[image]
   local borrowed=native and native.width==params[2]and native.data==source.imageData and native.image
   if borrowed then
    if not row or row.image~=borrowed then
     if row and row.owned then row.image:release()end
     if not row then state.maskCount=state.maskCount+1 end
     row={image=borrowed,data=source.imageData,width=params[2],owned=false};state.masks[image]=row
    end
   elseif not row or not row.owned or row.data~=source.imageData or row.width~=params[2]then
    local data=rim.normals(source.imageData,source.quads,params[2])
    local mask=love.graphics.newImage(data);data:release();mask:setFilter('nearest','nearest');mask:setWrap('clamp','clamp')
    if row and row.owned then row.image:release()end
    if not row then state.maskCount=state.maskCount+1 end
    row={image=mask,data=source.imageData,width=params[2],owned=true};state.masks[image]=row
   end
   U.send(shader,'oasc_cut_mask',row.image);U.send(shader,'oasc_cut_source',1)
  else U.send(shader,'oasc_cut_source',-1)end
 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);Contacts.removeStackLayer(state.layer);release();state.active=false
  if cfg.cards then cfg.cards.paperCut=nil;if not next(cfg.cards)then cfg.cards=nil end end
  for name,old in pairs(priorPresets)do local p=cfg.settings.presets[name]
   if p and p.cards then p.cards.paperCut=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end
  end
  priorPresets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',
  requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_paper_cut_card_test.lua','tests/gen3_paper_cut_gpu_test.lua','tests/gen3_paper_cut_play_test.lua','tests/gen3_paper_cut_menu_play_test.lua','tests/gen3_contact_stack_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/PAPER_CUT.md'},
  impact={runtimeOwners={'gen3.render.paper-cut'},saveWrites={},publicHooks={},files={'gen3/lib/cards/PaperCutCard.lua','gen3/cards/PAPER_CUT.md'}},
  lifecycle={install=function()return {installed=true}end,
   activate=function()
    if state.active then return state,public end
    assert(not Contacts.stackLayer,'contact stack layer already owned')
    G.registerPresentation(Card.ID,'paperCut',{'enabled','strength','width','warmth','stackShadow'})
    cfg.cards=cfg.cards or{};cfg.cards.paperCut=cfg.cards.paperCut or{enabled=true,strength=.55,width=1,warmth=1,stackShadow=.55}
    for name,p in pairs(cfg.settings.presets)do
     priorPresets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.paperCut}
     p.cards=p.cards or{};if p.cards.paperCut==nil then p.cards.paperCut={enabled=name~='off'and name~='low'} end
    end
    state.active=true;Contacts.stackLayer=state.layer
    -- Scene loading precedes the first prepare hook. Apply the preset now so
    -- contact meshes are built with their final layer instead of being rebuilt
    -- synchronously inside the first visible shadow pass.
    prepare({})
    S.register(Card.ID,'main.uniforms',uniforms);S.register(Card.ID,'main.functions',functions)
    S.register(Card.ID,'main.fragment.lit',fragment);S.register(Card.ID,'prepare',prepare)
    S.register(Card.ID,'bind',bind);S.register(Card.ID,'bindTexture',texture);S.register(Card.ID,'release',release)
    return state,public
   end,deactivate=deactivate,abort=deactivate,
   health=function()
    local h=S.health(Card.ID);h.active=state.active;h.spriteMasks=state.maskCount;h.ownedMasks=0;h.borrowedMasks=0
    for _,row in pairs(state.masks)do local k=row.owned and 'ownedMasks'or 'borrowedMasks';h[k]=h[k]+1 end
    return h
   end}}
end
return Card
