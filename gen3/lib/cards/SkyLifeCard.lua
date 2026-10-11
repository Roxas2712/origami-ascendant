local V=...
local Card={ID='oasc.gen3.sky-life',VERSION='1.0.0',CAPABILITY='ascendant.sky-life.gen3/v1'}
Card.option={key='gen3Card_skyLife',label='VOGELZUEGE & HIMMEL',type='toggle',default=true,
 help='Gelegentliche Vogelzuege. Sternschnuppen nur bei klarer Nacht im sichtbaren Dachhimmel.'}
Card.world=[[
#pragma language glsl3
varying vec3 oasc_sky_world;
#ifdef VERTEX
uniform mat4 oasc_sky_vp;
uniform float oasc_sky_depthScale;
vec4 position(mat4 transform_projection,vec4 vertex_position){
 oasc_sky_world=vertex_position.xyz;
 vec4 p=oasc_sky_vp*vertex_position;p.z*=oasc_sky_depthScale;return p;
}
#endif
#ifdef PIXEL
uniform float oasc_sky_mode;
uniform vec4 oasc_sky_cloud;
uniform vec3 oasc_sky_ambient;
float oasc_sky_hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float oasc_sky_noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(oasc_sky_hash(i),oasc_sky_hash(i+vec2(1,0)),f.x),mix(oasc_sky_hash(i+vec2(0,1)),oasc_sky_hash(i+vec2(1,1)),f.x),f.y);}
float oasc_sky_transmission(){
 vec2 p=(oasc_sky_world.xz+oasc_sky_cloud.w*vec2(2.4,.8))/max(1.0,oasc_sky_cloud.z);
 float n=oasc_sky_noise(p)*.55+oasc_sky_noise(p*2.03+17.0)*.30+oasc_sky_noise(p*4.1+41.0)*.15;
 float cover=clamp(smoothstep(.42,.74,n)+oasc_sky_cloud.y-.35,0.0,1.0);
 return mix(1.0,1.0-.96*smoothstep(.12,.78,cover),oasc_sky_cloud.x);
}
vec4 effect(vec4 c,Image tex,vec2 uv,vec2 sc){
 if(oasc_sky_mode<.5){
  vec4 p=Texel(tex,uv);if(p.a<.05)discard;
  return vec4(p.rgb*(oasc_sky_ambient*.7+vec3(.3)*oasc_sky_transmission()),p.a)*c;
 }
 if(oasc_sky_mode<1.5){
  float spot=(1.0-smoothstep(.15,1.0,length(uv*2.0-1.0)))*.23*oasc_sky_transmission();
  return vec4(vec3(1.0-spot),1.0);
 }
 float beam=pow(max(0.0,1.0-abs(uv.y*2.0-1.0)),2.0)*(1.0-uv.x)*.12;
 return vec4(c.rgb*beam,1.0);
}
#endif
]]
Card.meteor=[[
uniform Image oasc_sky_depth;
uniform vec2 oasc_sky_size;
uniform float oasc_sky_energy;
vec4 effect(vec4 c,Image tex,vec2 uv,vec2 sc){
 vec2 q=sc/oasc_sky_size;
 // The distant rooftop city starts at y=.33 and has no depth writes.
 // Both constraints are necessary: depth alone would paint its buildings.
 if(q.y>=.30||Texel(oasc_sky_depth,q).r<.999999)discard;
 float trail=pow(uv.x,1.5)*pow(max(0.0,1.0-abs(uv.y*2.0-1.0)),2.0);
 return vec4(vec3(.70,.83,1.0)*trail*oasc_sky_energy,1.0);
}
]]
function Card.descriptor(V)
 local S,U,C,G=V.require('core/RenderSeams'),V.require('UniformState'),V.require('DioramaConfig'),V.require('GeometryConfig')
 local M=V.require('cards/SkyLifeMotion')
 local state={active=false,birds=0,meteor=false,beacons=0,updateMs=0,drawMs=0,resources=0}
 local presets={};local motion,def;local shader,meteorShader,atlas,birdMesh,shadowMesh,beaconMesh,meteorMesh
 local birdRows,shadowRows,beaconRows,meteorRows={},{},{},{}
 for i=1,30 do birdRows[i]={0,0,0,0,0};shadowRows[i]={0,0,0,0,0}end
 for i=1,48 do beaconRows[i]={0,0,0,0,0}end
 for i=1,6 do meteorRows[i]={0,0,0,0}end
 local cloud,ambient,size={0,0,520,0},{1,1,1},{1,1};local corners={{-1,-1},{1,-1},{1,1},{-1,-1},{1,1},{-1,1}}
 local meteorPhase,meteorX,meteorY;local policyEnabled=false
 local function release()
  for _,r in ipairs{birdMesh or false,shadowMesh or false,beaconMesh or false,meteorMesh or false,atlas or false}do if r then r:release()end end
  if shader then U.invalidate(shader);shader:release()end
  if meteorShader then U.invalidate(meteorShader);meteorShader:release()end
  birdMesh,shadowMesh,beaconMesh,meteorMesh,atlas,shader,meteorShader=nil,nil,nil,nil,nil,nil,nil
  motion,def=nil,nil;state.resources=0;state.birds=0;state.beacons=0;state.meteor=false
 end
 local function resources()
  if shader then return true end
  local data,file
  local ok,err=pcall(function()
   file=love.filesystem.newFileData(assert(V.mod:read('gen3/data/sky/birds.png')),'birds.png')
   data=love.image.newImageData(file);assert(data:getWidth()==64 and data:getHeight()==16,'invalid bird atlas')
   atlas=love.graphics.newImage(data);atlas:setFilter('nearest','nearest')
   shader=V.require('ShaderCompiler').newShader(Card.world);meteorShader=V.require('ShaderCompiler').newShader(Card.meteor)
   local format={{'VertexPosition','float',3},{'VertexTexCoord','float',2}}
   birdMesh=love.graphics.newMesh(format,birdRows,'triangles','stream');birdMesh:setTexture(atlas)
   shadowMesh=love.graphics.newMesh(format,shadowRows,'triangles','stream')
   beaconMesh=love.graphics.newMesh(format,beaconRows,'triangles','stream')
   meteorMesh=love.graphics.newMesh({{'VertexPosition','float',2},{'VertexTexCoord','float',2}},meteorRows,'triangles','stream')
  end)
  if data then data:release()end;if file then file:release()end
  if not ok then release();state.error=tostring(err);if V.mod.log then V.mod.log:info('Sky life disabled: '..state.error)end;return false end
  state.resources=7;return true
 end
 local function prepare(ctx)
  local start=love.timer.getTime();state.birds,state.beacons,state.meteor=0,0,false;state.updateMs=0;state.drawMs=0;meteorPhase=nil;policyEnabled=false
  local c=C.cards and C.cards.skyLife
  local p=C.settings.presets[V.mod.options:get('gen3Quality')or C.settings.defaultPreset]
  local policy=p and p.cards and p.cards.skyLife
  if not(state.active and c and c.enabled~=false and ctx.def and ctx.def.midLayout and ctx.outdoors and not ctx.cave)
   or state.error or type(policy)=='table'and policy.enabled==false then return end
  if not resources()then return end
  policyEnabled=true
  if ctx.def~=def then def=ctx.def;motion=M.new(ctx.id or def.id)end
  local a=ctx.atmosphere;local night=a and a.solar and a.solar.night or 0
  for i=1,3 do ambient[i]=a and a.ambient and a.ambient[i]or .7 end
  for i=1,4 do cloud[i]=ctx.cloudLight and ctx.cloudLight[i]or(i==3 and 520 or 0)end
  local t=ctx.time or 0;local L=def.midLayout
  if c.birds~=false and night<.8 and ctx.weatherMode~='storm' then
   M.update(motion,t,L.width*16,L.height*16);state.birds=motion.count
   local uy,uz=V.require('Camera').cardUp()
   for i=1,motion.count do local b=motion.rows[i]
    for j,q in ipairs(corners)do
     local r=birdRows[(i-1)*6+j];r[1],r[2],r[3]=b[1]+q[1]*5,b[2]+q[2]*5*uy,b[3]+q[2]*5*uz
     r[4],r[5]=(b[4]+(q[1]+1)*.5)/4,(1-q[2])*.5
     r=shadowRows[(i-1)*6+j];r[1],r[2],r[3]=b[1]+q[1]*4,.12,b[3]+q[2]*2.3;r[4],r[5]=(q[1]+1)*.5,(q[2]+1)*.5
    end
   end
  end
  local meteorAge=M.event(motion.meteors,t)
  if c.meteors~=false and meteorAge<.4 and ctx.hasSky and V.require('RooftopVista').profile(def) then
   local cover=V.require('RooftopVista').atmosphere(def,t,ctx.weatherMode)
   meteorPhase,meteorX,meteorY=M.meteor(motion,t,true,night,ctx.weatherMode,cover)
   state.meteor=meteorPhase~=nil
  end
  local beacons=c.beacons and c.beacons[ctx.id]
  if type(beacons)=='table'and night>.3 then
   for i=1,math.min(16,#beacons)do local b=beacons[i]
    if type(b)=='table'and type(b.x)=='number'and type(b.z)=='number'then
     local angle=t*(tonumber(b.speed)or .2)+(tonumber(b.phase)or 0);local radius=math.min(160,math.max(1,tonumber(b.radius)or 80))
     local k=state.beacons*3;state.beacons=state.beacons+1
     local r=beaconRows[k+1];r[1],r[2],r[3],r[4],r[5]=b.x,.16,b.z,0,.5
     for j=2,3 do r=beaconRows[k+j];local theta=angle+(j==2 and -.12 or .12)
      r[1],r[2],r[3],r[4],r[5]=b.x+math.cos(theta)*radius,.16,b.z+math.sin(theta)*radius,1,j-2
     end
    end
   end
  end
  state.updateMs=(love.timer.getTime()-start)*1000
 end
 local function world(ctx,mesh,rows,count,mode,blend)
  if count==0 or not shader or not ctx.depth then return end
  local start=love.timer.getTime();mesh:setVertices(rows,1,count);mesh:setDrawRange(1,count)
  U.send(shader,'oasc_sky_vp','row',ctx.vp);U.send(shader,'oasc_sky_depthScale',ctx.depthScale or 1)
  U.send(shader,'oasc_sky_mode',mode);U.send(shader,'oasc_sky_cloud',cloud);U.send(shader,'oasc_sky_ambient',ambient)
  love.graphics.push('all');love.graphics.setShader(shader);love.graphics.setColor(1,1,1,1)
  love.graphics.setMeshCullMode('none');love.graphics.setDepthMode('lequal',false);love.graphics.setBlendMode(blend,'premultiplied')
  love.graphics.draw(mesh);love.graphics.pop();state.drawMs=state.drawMs+(love.timer.getTime()-start)*1000
 end
 local function ground(ctx)
  world(ctx,shadowMesh,shadowRows,state.birds*6,1,'multiply')
  world(ctx,beaconMesh,beaconRows,state.beacons*3,2,'add')
 end
 local function birds(ctx)world(ctx,birdMesh,birdRows,state.birds*6,0,'alpha')end
 local function meteor(canvas,ctx,energy,thickness)
  if not policyEnabled or meteorPhase==nil or not meteorShader or not ctx.hasSky or not ctx.depth or not ctx.depth:isReadable()then return canvas end
  local start=love.timer.getTime();local w,h=canvas:getDimensions();size[1],size[2]=w,h
  local p=meteorPhase;local x=w*(.15+meteorX*.5+p*.12);local y=h*(.035+meteorY*.10+p*.075)
  local dx,dy=w*.075,h*.045;local len=math.sqrt(dx*dx+dy*dy);local nx,ny=-dy/len*thickness,dx/len*thickness
  for i,q in ipairs(corners)do local r=meteorRows[i];local u=(q[1]+1)*.5
   r[1],r[2],r[3],r[4]=x-dx*(1-u)+nx*q[2],y-dy*(1-u)+ny*q[2],u,(q[2]+1)*.5
  end
  meteorMesh:setVertices(meteorRows)
  U.send(meteorShader,'oasc_sky_depth',ctx.depth);U.send(meteorShader,'oasc_sky_size',size)
  U.send(meteorShader,'oasc_sky_energy',energy*math.sin(p*math.pi))
  love.graphics.push('all');love.graphics.setCanvas(canvas);love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode()
  love.graphics.setColorMask(true,true,true,false);love.graphics.setMeshCullMode('none');love.graphics.setColor(1,1,1,1)
  love.graphics.setBlendMode('add','premultiplied');love.graphics.setShader(meteorShader);love.graphics.draw(meteorMesh);love.graphics.pop()
  state.drawMs=state.drawMs+(love.timer.getTime()-start)*1000;return canvas
 end
 local function deactivate()
  S.unregister(Card.ID);G.unregisterPresentation(Card.ID);release();state.active=false;state.error=nil
  if C.cards then C.cards.skyLife=nil;if not next(C.cards)then C.cards=nil end end
  for name,old in pairs(presets)do local p=C.settings.presets[name]
   if p and p.cards then p.cards.skyLife=old.value;if not old.hadCards and not next(p.cards)then p.cards=nil end end
  end
  presets={};return true
 end
 return {schema='ascendant.card/v1',id=Card.ID,version=Card.VERSION,owner='origami_ascendant',
  requires={'oasc.gen3.render-seams'},optionalRequires={},consumes={},provides={Card.CAPABILITY},saveNamespace=false,
  tests={'tests/gen3_auxiliary_shader_warm_test.lua','tests/gen3_sky_life_test.lua','tests/gen3_sky_life_gpu_test.lua','tests/gen3_sky_life_play_test.lua','tests/card_rollback_test.lua'},docs={'gen3/cards/SKY_LIFE.md'},
  impact={runtimeOwners={'gen3.render.sky-life'},saveWrites={},publicHooks={},
   files={'gen3/lib/cards/SkyLifeCard.lua','gen3/lib/cards/SkyLifeMotion.lua','gen3/data/sky/birds.png','gen3/cards/SKY_LIFE.md'}},
  lifecycle={install=function()return {installed=true}end,
   activate=function()
    if state.active then return state end
    G.registerPresentation(Card.ID,'skyLife',{'enabled','birds','meteors','beacons'})
    C.cards=C.cards or{};C.cards.skyLife=C.cards.skyLife or{enabled=true,birds=true,meteors=true,beacons={}}
    for name,p in pairs(C.settings.presets)do
     presets[name]={hadCards=p.cards~=nil,value=p.cards and p.cards.skyLife}
     p.cards=p.cards or{};if p.cards.skyLife==nil then p.cards.skyLife={enabled=name~='off'and name~='low'} end
    end
    state.active=true;state.error=nil
    -- Activation occurs at mod load or an explicit toggle. Own the complete
    -- resource set before the first visible frame; release/re-enable stays lazy.
    local p=C.settings.presets[V.mod.options:get('gen3Quality')or C.settings.defaultPreset]
    local policy=p and p.cards and p.cards.skyLife
    if C.cards.skyLife.enabled~=false and not(type(policy)=='table'and policy.enabled==false)then resources()end
    S.register(Card.ID,'prepare',prepare);S.register(Card.ID,'afterWorld',ground);S.register(Card.ID,'afterActors',birds)
    S.register(Card.ID,'beforeFinish',function(canvas,ctx)return meteor(canvas,ctx,2.4,2)end)
    S.register(Card.ID,'afterFinish',function(canvas,ctx)return meteor(canvas,ctx,.65,.7)end);S.register(Card.ID,'release',release)
    return state,{isActive=function()return state.active end}
   end,deactivate=deactivate,abort=deactivate,
   health=function()local h=S.health(Card.ID);h.active=state.active;h.ok=h.ok and not state.error;h.error=h.error or state.error
    h.birds=state.birds;h.meteor=state.meteor;h.beacons=state.beacons;h.resources=state.resources
    h.updateMs=state.updateMs;h.drawMs=state.drawMs;h.gpuTimeAvailable=false;return h end}}
end
return Card
