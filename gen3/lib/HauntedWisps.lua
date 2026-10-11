-- Map-local visual wandering. Adjacent floor cells keep interpolation inside
-- the actual room. No native encounter, inventory or gameplay RNG is changed.
local V=...
local W={maps=setmetatable({},{__mode='k'}),contacts={},ambientEvents={}}
local function apparition(t)
 if t<0 or t>2.8 then return 0 end
 return math.max(0,math.min(1,(2.8-t)/.65))
end
-- Private RNG: presentation must not consume the native encounter RNG.
local function rng()
 if not W.contactRng then W.contactRng=love.math.newRandomGenerator(math.floor(love.timer.getTime()*1000000)%2147483647)end
 return W.contactRng
end
function W.eyeChoice()return rng():random(1,4)==1 end
function W.contactTarget()
 local count=math.max(1,math.min(3,math.floor(V.require('DioramaConfig').haunted.wisps or 1)))
 return rng():random(1,count)
end
-- Pick the first, second or third contact per floor. Holding a contact counts
-- once; leave the wisp before another touch. Keep the choice across rebuilds.
function W.touchAmount(def,i,time,x,z,px,pz)
 local id=def and(def.id or def.name);if not id then return 0,false end
 local inside=(x-px)^2+(z-pz)^2<=14^2
 local state=W.contacts[id];local hit=false
 if not state and inside then
  state={target=W.contactTarget(),count=0,inside={}};W.contacts[id]=state
 end
 if not state then return 0,false end
 if inside and not state.inside[i]and not state.time then
  state.count=state.count+1
  if state.count>=state.target then state.index=i;state.time=time;hit=true end
 end
 state.inside[i]=inside
 if not state.time or state.index~=i then return 0,false end
 return apparition(time-state.time),hit,state
end
function W.resetContacts()W.contacts={};W.ambientEvents={};W.contactRng=nil end
local function hash(n)return(n*48271%2147483647)/2147483647 end
function W.plan(def)
 local L=def and def.midLayout;if not L then return end
 local old=W.maps[L];if old then return old end
 local nodes,byCell={},{};local Shapes=V.data('Shapes')
 for z=1,L.height-1 do for x=1,L.width-1 do
  local c=L:cellAt(x,z)
  if c and c.mid~=0 and c.mid~=8 and not Shapes.solid(c)and not Shapes.water(c)then
   local node={x=x*16+8,z=z*16+8,neighbors={}}
   nodes[#nodes+1]=node;byCell[z*L.width+x]=node
  end
 end end
 for k,node in pairs(byCell)do
  local x,z=k%L.width,math.floor(k/L.width)
  for _,d in ipairs{{1,0},{-1,0},{0,1},{0,-1}}do
   local p=byCell[(z+d[2])*L.width+x+d[1]]
   if p then node.neighbors[#node.neighbors+1]=p end
  end
 end
 local seed=17;for ch in tostring(def.id):gmatch('.')do seed=(seed*31+ch:byte())%65521 end
 local plan={nodes=nodes,seed=seed,walkers={}}
 W.maps[L]=plan;return plan
end
function W.position(def,i,time)
 local plan=W.plan(def);if not plan or #plan.nodes==0 then return end
 local step=math.floor(time/6);local p=plan.walkers[i]
 if not p or step<p.step or step-p.step>20 then
  local node=plan.nodes[1+math.floor(hash(plan.seed+i*997)*#plan.nodes)]
  p={from=node,to=node,step=step-1};plan.walkers[i]=p
 end
 while p.step<step do
  p.step=p.step+1;p.from=p.to
  local choices=p.from.neighbors
  p.to=#choices>0 and choices[1+math.floor(hash(plan.seed+i*997+p.step*7919)*#choices)]or p.from
 end
 local t=math.min(1,(time%6)/4);t=t*t*(3-2*t)
 return p.from.x+(p.to.x-p.from.x)*t,p.from.z+(p.to.z-p.from.z)*t
end
local function ambientTiming(i,time,def)
 local plan=def and W.plan(def);local seed=plan and plan.seed or 17
 local window=120;local offset=hash(seed*97)*window
 local localTime=time+offset;local cycle=math.floor(localTime/window)
 local at=24+hash(seed*71+cycle*7919)*64
 local count=V.require('DioramaConfig').haunted.wisps or 3
 local chosen=1+math.floor(hash(seed*113+cycle*65537)*count)
 if i~=chosen then return nil,cycle end
 return localTime-cycle*window-at,cycle
end
function W.ghostAmount(i,time,def)
 local contact=def and W.contacts[def.id or def.name]
 if contact and contact.time and apparition(time-contact.time)>0 then return 0 end
 local age=ambientTiming(i,time,def)
 return age and apparition(age)or 0
end
-- A transformation is one transaction: accept the voice, then publish its
-- silhouette and optional eyes in that same frame. Keep event decisions over
-- renderer rebuilds, so a replayed draw cannot replay the laugh.
function W.presentation(def,i,time,x,z,px,pz)
 local id=def and(def.id or def.name);if not id then return 0,0 end
 local event=W.contacts[id];local age;local contact=false
 if event and event.time and apparition(time-event.time)>0 then
  if event.index~=i then return 0,0 end
  age=time-event.time;contact=true
 else
  local cycle;age,cycle=ambientTiming(i,time,def)
  if not age or apparition(age)<=0 then return 0,0 end
  event=W.ambientEvents[id]
  if not event or event.cycle~=cycle then event={cycle=cycle};W.ambientEvents[id]=event end
 end
 if not event.decided then
  event.decided=true
  -- Arrival halfway through a scheduled apparition consumes it; no late laugh.
  event.allowed=(contact or age<=.25)and V.require('HauntedVoice').start(time,x,z,px,pz,contact)or false
  if event.allowed then event.eyes=W.eyeChoice()end
 end
 if not event.allowed then return 0,0 end
 local eyes=0
 if event.eyes then
  -- Two short pulses, owned by the same apparition, never by a draw pass.
  eyes=math.max(0,1-math.abs(age-.32)/.16,1-math.abs(age-.95)/.20)
 end
 return apparition(age),eyes
end
function W.prepare()
 W.pic=W.pic or require('src.core.game3.pokemon').ghostPic()
 if not W.pic or not W.pic.image then return end
 W.shader=W.shader or V.require('ShaderCompiler').newShader('uniform mat4 vp; uniform float depthScale; vec4 position(mat4 t,vec4 p){vec4 q=vp*p;q.z*=depthScale;return q;}')
 return W.pic
end
function W.draw(sprites,vp,depthScale)
 local visible=false;for _,p in ipairs(sprites)do if (p.ghost or 0)>0 then visible=true;break end end
 if not visible then return end
 local pic=W.prepare();if not pic then return end
 local G=V.require('WorldGeometry');local vertices={}
 local uy,uz=V.require('Camera').cardUp()
 for _,p in ipairs(sprites)do if (p.ghost or 0)>0 then
  local h=22;local height=h*V.require('Billboard').heightScale();local z=p.z;local x=p.x-h/2;local y=p.y-4
  G.quad(vertices,{x,y+height*uy,z+height*uz},{x+h,y+height*uy,z+height*uz},{x+h,y,z},{x,y,z},{0,0,1,1},1)
  W.mesh=W.mesh or love.graphics.newMesh(G.FORMAT,6,'triangles','stream')
  W.mesh:setVertices(vertices);W.mesh:setTexture(pic.image)
  love.graphics.push('all');love.graphics.setShader(W.shader);W.shader:send('vp','row',vp);W.shader:send('depthScale',depthScale or 1)
  love.graphics.setBlendMode('alpha');love.graphics.setColor(.75,.66,.95,p.ghost*.65);love.graphics.draw(W.mesh)
  love.graphics.pop()
  vertices={}
 end end
end
-- Screen-space scare: the eyes belong to the apparition event, but sit at
-- the top of the final game viewport. They never modify the ghost artwork.
local eyeCode=[[
 uniform float amount;
 float eye(vec2 uv,vec2 center,float side){
  vec2 p=(uv-center)/vec2(.09,.035);p.y+=side*.16*p.x;
  float shape=abs(p.x)+p.y*p.y;
  return 1.0-smoothstep(.72,1.0,shape)+.25*exp(-2.8*dot(p,p));
 }
 vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
  vec2 p=screen/love_ScreenSize.xy;
  float a=max(eye(p,vec2(.40,.16),-1.0),eye(p,vec2(.60,.16),1.0));
  return vec4(1.0,.008,.018,min(1.0,a)*amount);
 }
]]
function W.drawScreen(game,width,height)
 if game.phase~='field' or require('src.core.game3.battle').isActive()
  or require('src.ui.game3.stack').fullscreen()or V.require('Menu').active()
  or V.require('Renderer').buildPending then return false end
 local id,def=V.require('WorldAdapter').current(game);local H=V.require('HauntedFog')
 if not H.active(def)or not H.wispState or H.wispState.map~=id then return false end
 local amount=0
 for _,p in ipairs(H.wispState.sprites)do amount=math.max(amount,(p.redEyes or 0)*(p.ghost or 0))end
 if amount<=0 then return false end
 W.eyeShader=W.eyeShader or V.require('ShaderCompiler').newShader(eyeCode)
 local g=love.graphics;g.push('all');g.origin();g.setScissor();g.setDepthMode();g.setStencilTest()
 g.setShader(W.eyeShader);W.eyeShader:send('amount',amount);g.setBlendMode('alpha');g.setColor(1,1,1,1)
 g.rectangle('fill',0,0,width or g.getWidth(),height or g.getHeight());g.pop();return true
end
function W.release()
 for _,k in ipairs{'mesh','shader','eyeShader'}do if W[k]then W[k]:release();W[k]=nil end end
 W.pic=nil;W.maps=setmetatable({},{__mode='k'})
end
return W
