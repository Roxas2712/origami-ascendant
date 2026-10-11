-- Three overlapping paper crests travel over the actual arena. The original
-- Surf task still owns time, sound, alpha, hit timing and battler movement.
local V=...
local W={}
local function clamp(x)return math.max(0,math.min(1,x))end
function W.matches(task)
 return task.active and task.draw and tostring(task.name):find('CreateSurfWave',1,true)~=nil
end
function W.sample(task)
 if task._scan then
  -- The pret task replaces the older procedural task in the current engine.
  -- Its scroll counter advances each native tick; the 5-bit EVA field owns
  -- opacity (26 ticks in, hold, 26 ticks out). No presentation clock is added.
  return clamp(math.abs(task.data[2]or 0)/134)*46,(task._scan[1]%32)/16,
   (task.ga and task.ga[0]or 0)~=0
 end
 return task.data[14]or 0,task._alpha or 0,task.data[8]==1
end
function W.geometry(scene,frame,enemy,muddy)
 local floor=scene.battleFootprint or(scene.stage and scene.stage.platform and scene.stage.platform.def)
  or{x=0,z=15,radius=80}
 local radius=floor.radius-2
 local ground=scene.ground or{}
 local y=(floor.height or math.max(ground.player or 0,ground.enemy or 0))+.2
 local u=clamp((frame-2)/38);if enemy then u=1-u end
 local centre=floor.z+radius*(.76-1.48*u)
 local rise=math.sin(math.pi*clamp(frame/46))
 local vertices={}
 local colors=muddy and{{.30,.19,.08},{.48,.31,.13},{.68,.49,.25}}or{{.025,.28,.47},{.025,.48,.66},{.07,.67,.77}}
 local foam=muddy and{.89,.80,.59}or{.96,.98,.88}
 local function vertex(x,h,z,c,shade)
  return {x,h,z,c[1]*shade,c[2]*shade,c[3]*shade}
 end
 local function quad(a,b,c,d)
  for _,p in ipairs({a,b,c,a,c,d})do vertices[#vertices+1]=p end
 end
 -- Far to near. Every strip has a tapered, scalloped top and a cream cut edge;
 -- both ends meet the circular floor instead of exposing rectangular sides.
 for layer=1,3 do
  local z=math.max(floor.z-radius+.1,math.min(floor.z+radius-.1,centre+(layer-2)*8))
  local width=math.sqrt(math.max(0,radius*radius-(z-floor.z)^2))
  local function crest(i)
   local q=i/32*2-1;local taper=math.sqrt(math.max(0,1-q*q))
   local curl=1+.17*math.sin(q*15-frame*.25+layer)+.07*math.sin(q*31+layer)
   local height=(12+(4-layer)*3)*rise*taper*curl
   return floor.x+q*width,y+height,math.min(height,1.45*taper)
  end
  for i=0,31 do
   local ax,ah,ae=crest(i);local bx,bh,be=crest(i+1)
   local c=colors[layer];local shade=i%4==0 and .94 or 1
   quad(vertex(ax,y,z,c,shade),vertex(bx,y,z,c,shade),vertex(bx,bh-be,z,c,1),vertex(ax,ah-ae,z,c,1))
   quad(vertex(ax,ah-ae,z,foam,1),vertex(bx,bh-be,z,foam,1),vertex(bx,bh,z,foam,1),vertex(ax,ah,z,foam,1))
  end
 end
 return vertices
end
function W.draw(scene,task,vm)
 local frame,alpha,muddy=W.sample(task);if alpha<=.01 then return end
 local vertices=W.geometry(scene,frame,vm:attackerSide()=='enemy',muddy)
 local P=V.require('battle/PaperBattleScene')
 local screen={}
 for _,p in ipairs(vertices)do
  local x,y=P.project(scene,p[1],p[2],p[3])
  screen[#screen+1]={x,y,0,0,p[4],p[5],p[6],alpha}
 end
 W.mesh=W.mesh or love.graphics.newMesh(screen,'triangles','dynamic')
 W.mesh:setVertices(screen)
 love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setMeshCullMode('none');love.graphics.setColor(1,1,1,1)
 love.graphics.setBlendMode('alpha','alphamultiply');love.graphics.draw(W.mesh)
end
function W.release()if W.mesh then W.mesh:release();W.mesh=nil end end
return W
