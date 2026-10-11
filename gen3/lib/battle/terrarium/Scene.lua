-- OASC host for the existing portable Terrarium art. No field renderer, map
-- loading, VASC singleton or second battle clock participates in this path.
local V=...
local S={}
local M=V.require('Mat4')
local Locations=V.require('battle/terrarium/Locations')
local prefix='battle/terrarium/vendor/'
local shaderSource=[[
uniform mat4 vp;uniform mat4 model;
uniform float battleSpritePass;uniform float battleDepthTest;uniform Image battleDepth;
uniform vec3 ambient;uniform int lightCount;
uniform vec4 lightPosition[5];uniform vec4 lightColor[5];
uniform Image stageAO;uniform float receiveShadow;uniform vec4 stageOrigin;
varying vec3 world;varying float shade;
#ifdef VERTEX
attribute float VertexShade;
vec4 position(mat4 t,vec4 p){world=(model*p).xyz;shade=mix(VertexShade,1.0,battleSpritePass);return vp*vec4(world,1.0);}
#endif
#ifdef PIXEL
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 // Captured actors are screen-space images; the bowl camera is perspective.
 // Sampling by screen position avoids perspective-warping their native art.
 vec4 p=Texel(tex,battleSpritePass>.5?screen/love_ScreenSize.xy:uv);if(p.a<.01)discard;
 if(battleDepthTest>.5 && gl_FragCoord.z>Texel(battleDepth,screen/love_ScreenSize.xy).r+.0000001)discard;
 if(battleSpritePass>.5)p.rgb/=max(p.a,.001);
 vec3 light=ambient;
 for(int i=0;i<5;i++){if(i<lightCount){
  float f=max(0.0,1.0-length(world-lightPosition[i].xyz)/lightPosition[i].w);
  light+=lightColor[i].rgb*lightColor[i].a*f*f*.55;
 }}
 light=min(light,vec3(battleSpritePass>.5?1.1:1.25));
 float ao=Texel(stageAO,(world.xz-stageOrigin.xz)/stageOrigin.w+.5).r;
 light*=mix(1.0,ao,receiveShadow*(1.0-battleSpritePass));
 return vec4(p.rgb*light*shade,p.a)*color;
}
#endif
]]
local function load(name)return V.require(prefix..name)end
function S.prepareShader()
 S.shader=S.shader or V.require('ShaderCompiler').newShader(shaderSource)
end
local function init()
 if S.service then return end
 S.prepareShader()
 local d=love.image.newImageData(1,1);d:setPixel(0,0,1,1,1,1)
 S.white=love.graphics.newImage(d);d:release()
 local G={}
 function G.newMesh(vertices,indices)
  local mesh=love.graphics.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'VertexShade','float',1}},vertices,'triangles','static')
  mesh:setVertexMap(indices);return mesh
 end
 function G.draw(mesh,texture,model)
  love.graphics.setShader(S.shader);S.shader:send('model','row',model)
  mesh:setTexture(texture);love.graphics.draw(mesh)
 end
 function G.seams()end;function G.glass()end
 function G.shadowReception(value)S.shader:send('receiveShadow',value and 1 or 0)end
 local lights={available=function()return true end,clear=function()S.rig=nil end}
 function lights.stage(_,tint,lamps)S.rig={tint=tint,lamps=lamps};return S.rig end
 local designs=load('BallDesigns')
 local api={Voxel3D=G,Mat4=M,clock=function()return V.require('DayNight').gameSeconds(S.game)end,
  resolveStyle=function(map)return {id=map.family}end,
  idleEnabled=function()return false end,
  ballStyle=function(map)return designs.resolve('auto','standard',map.id)end,
  ballAppearance=function(key)return designs.definitions[key]or designs.definitions.poke end,
  branding=function()return load('Branding')({path=V.path..'/gen3/lib/'..prefix:sub(1,-2)})end}
 api.gymDesign=load('GymDesigns')(function(path)return V.mod:read('gen3/lib/'..prefix..path)end,1,Locations.silphOccupied)
 api.lighting=load('Lighting')({lights=lights,graphics=G,clock=api.clock,
  enabled=function()return V.mod.options:get('gen3Lights')~=false end})
 -- The presentation backdrop follows the edition UI, independently of the
 -- authored bowl's Poké Ball materials. Keep the portable vendor unchanged.
 local background=load('Background')({ballAppearance=function()
  local accent=V.require('EditionAccent').color()
  return {base=accent,accent=accent}
 end})
 api.drawBackground=function(arena)background.draw(arena,'auto')end;api.releaseBackground=background.release
 local atmosphere=load('GymAtmosphere')(api)
 api.drawAtmosphere=atmosphere.draw;api.releaseAtmosphere=atmosphere.release
 S.graphics=G;S.service=load('Terarrium')(api)
end
function S.create(game,battle)
 if not V.require('battle/BattleViews').terrariumAvailable()then return nil,'no terrariums for this edition'end
 local id,def=V.require('WorldAdapter').current(game)
 local mapped=Locations.id(id);if not mapped then return nil,'no Kanto location'end
 init();S.game=game
 local setup=S.service.setup({id=mapped,family=Locations.family(id,def,battle.terrain)})
 local arena={mid={0,0},terarrium=setup}
 local camera=S.service.camera(arena,0)
 local vp=M.mul(M.scale(1,-1,1),M.mul(M.perspective(camera.fov,240/160,1,3000),M.lookAt(camera.eye,camera.focus,camera.up)))
 local scene={kind='terrarium',map=id,arena=arena,scale=1,focus={px=0,py=0},
  vp=vp,eye=camera.eye,target=camera.focus,feet={},ground={}}
 for _,side in ipairs({'player','enemy'})do
  local p=setup.actors[side];scene.feet[side]={p[1],p[3]};scene.ground[side]=p[2]
  if side=='player' or not battle.wild then
   p=setup.trainers[side];scene.feet[side..'Trainer']={p[1],p[3]};scene.ground[side..'Trainer']=p[2]
  end
 end
 return scene
end
function S.render(game,scene,width,height,presentation,record)
 S.game=game
 if V.require('WorldAdapter').current(game)~=scene.map then return nil,'map changed during battle'end
 local scale=math.max(1,math.min(3,V.require('DioramaConfig').settings.renderScale*3))
 local w,h=math.floor(width*scale),math.floor(height*scale)
 if not S.canvas or S.canvas:getWidth()~=w or S.canvas:getHeight()~=h then
  if S.canvas then S.canvas:release();S.depth:release()end
  S.canvas=love.graphics.newCanvas(w,h,{dpiscale=1});S.canvas:setFilter('nearest','nearest')
  S.depth=love.graphics.newCanvas(w,h,{format='depth24',readable=true,dpiscale=1});S.depth:setFilter('nearest','nearest')
 end
 presentation:prepare(record)
 S.service.prepareLighting(scene.arena,0)
 local rig=S.rig;local ambient=rig and rig.tint or {1,1,1}
 local atmosphere={ambient=ambient,lights={}}
 if V.mod.options:get('gen3Lights')~=false then presentation:lights(record,atmosphere)else presentation.battleLightCount=0 end
 local lamps={};for _,l in ipairs(rig and rig.lamps or{})do lamps[#lamps+1]=l end
 for _,l in ipairs(atmosphere.lights)do lamps[#lamps+1]={x=l.x,y=l.y,z=l.z,radius=math.abs(l.radius),power=l.power,color=l.color}end
 local positions,colors={},{}
 for i=1,5 do local l=lamps[i];positions[i]=l and {l.x,l.y,l.z,l.radius}or{0,0,0,1};colors[i]=l and {l.color[1],l.color[2],l.color[3],l.power}or{0,0,0,0}end
 local shader=S.shader
 shader:send('vp','row',scene.vp);shader:send('model','row',M.identity())
 shader:send('battleSpritePass',0);shader:send('battleDepthTest',0)
 shader:send('ambient',ambient);shader:send('lightCount',#lamps)
 shader:send('lightPosition',unpack(positions));shader:send('lightColor',unpack(colors))
 shader:send('stageAO',rig and rig.stageAO or S.white);shader:send('stageOrigin',rig and rig.stageOrigin or {0,0,0,152})
 shader:send('receiveShadow',1)
 S.graphics.vp=scene.vp;S.graphics.eye=scene.eye
 love.graphics.setCanvas({S.canvas,depthstencil=S.depth});love.graphics.origin();love.graphics.setScissor()
 local back=V.require('EditionAccent').ui().back
 love.graphics.clear(back[1],back[2],back[3],1,0,1);love.graphics.setDepthMode('less',true)
 love.graphics.setMeshCullMode('none');love.graphics.setBlendMode('alpha','alphamultiply');love.graphics.setColor(1,1,1,1)
 S.service.draw(scene.arena,0)
 shader:send('model','row',M.identity())
 presentation:drawLayers(record,shader,scene.vp,S.depth,w,h,atmosphere,{count=#lamps})
 S.service.overlay(scene.arena,0)
 S.stats={map=scene.map,mode='terrarium',design=scene.arena.terarrium.id,lights=#lamps,
  bakes=S.service.lightingStatus()and S.service.lightingStatus().bakes or 0}
 return S.canvas
end
function S.release()
 if S.service then S.service.release()end
 for _,key in ipairs({'shader','white','canvas','depth'})do if S[key]then S[key]:release();S[key]=nil end end
 S.service,S.graphics,S.rig,S.game,S.stats=nil,nil,nil,nil,nil
end
return S
