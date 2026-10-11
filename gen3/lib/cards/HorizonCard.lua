local Card={ID='oasc.gen3.horizon',VERSION='1.0.0',CAPABILITY='ascendant.horizon.gen3/v1'}
Card.option={key='gen3Card_horizon',label='FERNE KULISSEN',type='toggle',default=true,
 help='Gestaffelte Papierlandschaft hinter dem aeusseren Kartenrand.'}
Card.uniforms='uniform vec4 oasc_horizon_bounds;\nuniform float oasc_horizon_border;'
Card.fragment=[[
if(oasc_horizon_border>.5){
 vec2 oasc_horizon_d=min(worldPosition.xz-oasc_horizon_bounds.xy,oasc_horizon_bounds.zw-worldPosition.xz);
 float oasc_horizon_fade=smoothstep(0.0,32.0,min(oasc_horizon_d.x,oasc_horizon_d.y));
 if(oasc_horizon_fade<.01)discard;
 color.a*=oasc_horizon_fade;
}
]]
Card.shader=[[
uniform mat4 oasc_horizon_vp;
uniform float oasc_horizon_depthY;
varying vec3 oasc_horizon_worldPosition;
#ifdef VERTEX
vec4 position(mat4 ignored,vec4 vertex_position){
 oasc_horizon_worldPosition=vertex_position.xyz;
 vec4 projected=oasc_horizon_vp*vertex_position;
 // Match the existing hanging-facade correction for the paper camera.
 // Keep XY framing, but recover the true divisor below the ground plane.
 if(vertex_position.y<0.0 && oasc_horizon_depthY!=0.0){
  float depthW=projected.w+oasc_horizon_depthY*vertex_position.y;
  projected.z*=projected.w/max(depthW,.0001);
 }
 return projected;
}
#endif
#ifdef PIXEL
uniform vec3 oasc_horizon_cameraEye;
uniform vec3 oasc_horizon_tint;
uniform vec3 oasc_horizon_color;
uniform float oasc_horizon_floor;
uniform float oasc_horizon_depthPass;
uniform vec3 oasc_horizon_focus;
uniform vec4 oasc_horizon_aerial;
uniform vec3 oasc_horizon_aerialColor;
uniform vec3 oasc_horizon_viewForward;
uniform float oasc_horizon_aerialFocusDistance;
uniform float oasc_horizon_aerialOrtho;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 vec2 sampleUV=oasc_horizon_floor>.5?vec2(fract(uv.x),.8+fract(uv.y)*.2):uv;
 vec4 p=Texel(tex,sampleUV);if(p.a<.01)discard;
 if(oasc_horizon_depthPass>.5)return vec4(dot(oasc_horizon_worldPosition-oasc_horizon_focus,oasc_horizon_viewForward),0.0,0.0,p.a);
 vec3 lit=p.rgb*oasc_horizon_color*oasc_horizon_tint;
 float distance=oasc_horizon_aerialOrtho>.5?dot(oasc_horizon_worldPosition-oasc_horizon_cameraEye,oasc_horizon_viewForward):length(oasc_horizon_worldPosition-oasc_horizon_cameraEye);
 distance=max(0.0,distance-oasc_horizon_aerialFocusDistance)+oasc_horizon_aerial.x;
 float ap=smoothstep(oasc_horizon_aerial.x,oasc_horizon_aerial.y,distance)*oasc_horizon_aerial.z;
 float lum=dot(lit,vec3(.2126,.7152,.0722));
 lit=mix(lit,mix(lit,vec3(lum),oasc_horizon_aerial.w),ap);
 lit=mix(lit,oasc_horizon_aerialColor,ap*.5);
 return vec4(lit,p.a)*color;
}
#endif
]]
function Card.descriptor(V)
 local C,S,G=V.require('DioramaConfig'),V.require('core/RenderSeams'),V.require('GeometryConfig')
 local U,Plan=V.require('UniformState'),V.require('cards/HorizonPlan')
 local Border,Camera=V.require('WorldBorder'),V.require('Camera')
 local Battle=require('src.core.game3.battle')
 local state={active=false,enabled=false,resources=0};local presets={}
 local images,meshes,rows,plans={},{},{},{};local shader,def,bounds,distanceCanvas
 local worldBounds={0,0,0,0};local tint={1,1,1};local marks={}
 local assets={'clouds','mountains-a','mountains-b','sea'}
 local corners={{0,0},{1,0},{1,1},{0,0},{1,1},{0,1}}
 local hills={{.76,.82,.85},{.48,.59,.58},{.40,.51,.43},{.31,.45,.36}}
 local sea={{.76,.82,.85},{.44,.60,.66},{.37,.54,.62},{.32,.48,.56}}
 local function release()
  for _,v in ipairs(images)do v:release()end;for _,v in ipairs(meshes)do v:release()end
  if shader then shader:release()end
  if distanceCanvas then distanceCanvas:release();distanceCanvas=nil end
  images,meshes,rows,plans={},{},{},{};shader=nil;state.resources=0
  state.enabled=false;def,bounds=nil,nil;marks={}
 end
 local function resources()
  if shader then return true end
  local started=love.timer.getTime();local file
  local ok,err=pcall(function()
   if not love.graphics.getCanvasFormats().rgba16f then error('floating-point backdrop depth unavailable')end
   shader=V.require('ShaderCompiler').newShader(Card.shader)
   for i,name in ipairs(assets)do
    local path='gen3/data/horizon/'..name..'.png'
    file=love.filesystem.newFileData(assert(V.mod:read(path),path),name..'.png')
    images[i]=love.graphics.newImage(file,{mipmaps=true});file:release();file=nil
    images[i]:setFilter('linear','linear');images[i]:setMipmapFilter('linear')
    rows[i]={};plans[i]={}
    for j=1,12 do rows[i][j]={0,0,0,0,0}end
    meshes[i]=love.graphics.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2}},rows[i],'triangles','stream')
   end
  end)
  if file then file:release()end
  state.resourceMs=(love.timer.getTime()-started)*1000
  if not ok then release();state.error=tostring(err);return false end
  state.resources=9;return true
 end
 local function configured()
  local c=C.cards and C.cards.horizon
  local p=C.settings.presets[V.mod.options:get('gen3Quality')or C.settings.defaultPreset]
  local policy=p and p.cards and p.cards.horizon
  return state.active and c and c.enabled~=false and not(type(policy)=='table'and policy.enabled==false)
   and not state.error
 end
 local function allowed(d)
  local id=d and(d.id or d.name)or''
  return configured()and not Camera.experimental()and not Battle.isActive()and(id:match('^FR_')or id:match('^EM_')or id:match('^SEVII_'))
   and V.data('Shapes').outdoors(d)and not V.require('RooftopVista').profile(d)
 end
 local function clip(previous,ctx)
  state.enabled=false
  if not allowed(ctx.def)or not resources()then def,bounds=nil,nil;return previous end
  def=ctx.def;bounds=Plan.bounds(ctx.entries,ctx.continuationMargin or 4,bounds)
  if not bounds then return previous end
  for i=1,4 do worldBounds[i]=bounds[i]*16 end
  state.enabled=true;return bounds
 end
 local function prepare(ctx)
  state.drew=false
  if not(state.enabled and def==ctx.def and allowed(ctx.def)and not ctx.presentation)then state.enabled=false;return end
  state.region=Plan.region(ctx.id,C.cards.horizon.sets)
  for key in pairs(marks)do marks[key]=nil end
  local e=Border.entry
  if e then marks[e.mesh]=true;for _,b in ipairs(e.instances or{})do marks[b.mesh]=true end end
 end
 local function bindMesh(s,mesh)
  if U.has(s,'oasc_horizon_border')then
   U.send(s,'oasc_horizon_border',state.enabled and marks[mesh]and 1 or 0)
   U.send(s,'oasc_horizon_bounds',worldBounds)
  end
 end
 local function draw(ctx)
  if not state.enabled then return end
  local g=love.graphics;local E=V.require('EnvironmentLight');local c=C.cards.horizon
  local palette=state.region=='sea'and sea or hills
  local ambient=ctx.atmosphere.ambient;local mood=ctx.weatherMood
  for i=1,3 do tint[i]=ambient[i]*(mood and mood.tint[i]or 1)end
  U.send(shader,'oasc_horizon_vp','row',ctx.vp);U.send(shader,'oasc_horizon_cameraEye',ctx.eye)
  U.send(shader,'oasc_horizon_depthPass',0)
  local dx,dy,dz=ctx.target[1]-ctx.eye[1],ctx.target[2]-ctx.eye[2],ctx.target[3]-ctx.eye[3]
  local depthY=Camera.projection()=='perspective'and Camera.verticalCorrection() and dy/math.sqrt(dx*dx+dy*dy+dz*dz)or 0
  local floorY=Plan.floorDepth(ctx.vp,depthY)
  U.send(shader,'oasc_horizon_depthY',depthY)
  U.send(shader,'oasc_horizon_tint',tint);U.send(shader,'oasc_horizon_aerial',E.aerial);U.send(shader,'oasc_horizon_aerialColor',E.airColor)
  U.send(shader,'oasc_horizon_viewForward',E.forward);U.send(shader,'oasc_horizon_aerialFocusDistance',E.focusDistance);U.send(shader,'oasc_horizon_aerialOrtho',E.ortho)
  g.push('all');g.setShader(shader);g.setDepthMode('less',true);g.setMeshCullMode('none');g.setBlendMode('alpha','alphamultiply');g.setColor(1,1,1,1)
  for i=1,4 do
   local p=Plan.layer(bounds,i,ctx.focus.px,Camera.elevation(),c.parallax~=false,plans[i])
   local tex=i==4 and(state.region=='sea'and images[4]or images[3])or images[i]
   local r=rows[i]
   -- Top silhouette plus a solid lower continuation, all in the depth buffer.
   for j=1,12 do local q=corners[(j-1)%6+1];local v=r[j];local lower=j>6
    v[1]=p.x+(q[1]-.5)*p.width;v[3]=p.z
    v[2]=lower and(p.top-p.height+(p.bottom-p.top+p.height)*q[2])or(p.top-p.height*q[2])
    v[4],v[5]=q[1],lower and 1 or q[2]
   end
   if i==4 then
    -- The distant land/sea floor continues under the paper silhouette cards.
    -- It lies below all real map geometry and fills side/south views too.
    for j=1,6 do local q=corners[j];local v=r[j]
     v[1],v[2],v[3]=Plan.floor(ctx.vp,(q[1]*2-1)*1.01,(q[2]*2-1)*1.01,floorY)
     local follow=c.parallax~=false and .5 or 0
     v[4],v[5]=(v[1]-ctx.focus.px*follow)/2048,(v[3]-ctx.focus.py*follow)/1024
    end
    meshes[i]:setDrawRange(1,6)
   end
   meshes[i]:setVertices(r);meshes[i]:setTexture(tex);U.send(shader,'oasc_horizon_color',palette[i]);U.send(shader,'oasc_horizon_floor',i==4 and 1 or 0);g.draw(meshes[i])
  end
  g.pop();state.drew=true
 end
 local function focusMetadata(previous,ctx)
  if not(state.enabled and state.drew)then return previous end
  local g=love.graphics;local w,h=ctx.depth:getDimensions()
  if not distanceCanvas or distanceCanvas:getWidth()~=w or distanceCanvas:getHeight()~=h then
   if distanceCanvas then distanceCanvas:release()end
   distanceCanvas=g.newCanvas(w,h,{format='rgba16f',dpiscale=1});distanceCanvas:setFilter('nearest','nearest')
  end
  state.resources=10
  U.send(shader,'oasc_horizon_depthPass',1);U.send(shader,'oasc_horizon_focus',ctx.point)
  g.push('all');g.setCanvas({distanceCanvas,depthstencil=ctx.depth});g.origin();g.setScissor();g.setColorMask(true,true,true,true)
  g.clear(0,0,0,0,false,false);g.setShader(shader);g.setDepthMode('lequal',false);g.setMeshCullMode('none');g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1)
  -- Reuse exact world geometry and discard alpha exactly as in the color pass.
  -- Scene depth rejects pixels hidden by native trees/buildings/actors.
  for i=1,4 do U.send(shader,'oasc_horizon_floor',i==4 and 1 or 0);g.draw(meshes[i])end
  g.pop();U.send(shader,'oasc_horizon_depthPass',0)
  return distanceCanvas
 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);release();Border.release();state.active=false;state.error=nil
  if C.cards then C.cards.horizon=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name];if p and p.cards then p.cards.horizon=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end end
  presets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_horizon_test.lua','tests/gen3_horizon_resource_lifecycle_test.lua','tests/gen3_horizon_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/HORIZON.md'},
  impact={runtimeOwners={'gen3.render.horizon'},saveWrites={},publicHooks={},files={'gen3/lib/cards/HorizonCard.lua','gen3/lib/cards/HorizonPlan.lua','gen3/cards/HORIZON.md','gen3/data/horizon/clouds.png','gen3/data/horizon/mountains-a.png','gen3/data/horizon/mountains-b.png','gen3/data/horizon/sea.png'}},
  lifecycle={install=function()return{installed=true}end,activate=function()
   if state.active then return state end
   C.cards=C.cards or{};C.cards.horizon=C.cards.horizon or{enabled=true,parallax=true,sets={default='kanto-hills',coast='sea'}}
   G.registerPresentation(Card.ID,'horizon',{'enabled','parallax','sets'})
   for name,p in pairs(C.settings.presets)do presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.horizon};p.cards=p.cards or{};if p.cards.horizon==nil then p.cards.horizon={enabled=name~='off'and name~='low'} end end
   state.active=true;S.register(Card.ID,'borderBounds',clip);S.register(Card.ID,'prepare',prepare)
   S.register(Card.ID,'main.uniforms',Card.uniforms);S.register(Card.ID,'main.fragment.final',Card.fragment)
   S.register(Card.ID,'bindMesh',bindMesh);S.register(Card.ID,'beforeWorld',draw,-1000);S.register(Card.ID,'release',release)
   S.register(Card.ID,'focusMetadata',focusMetadata)
   -- Decode/upload scenery before the first visible border draw. The lazy
   -- path still handles renderer release and a later low -> high change.
   if configured()then resources()end
   return state,{isActive=function()return state.active end}
  end,deactivate=deactivate,abort=deactivate,health=function()
   local h=S.health(Card.ID);for k,v in pairs(state)do h[k]=v end;h.ok=h.ok and not state.error;return h
  end}}
end
return Card
