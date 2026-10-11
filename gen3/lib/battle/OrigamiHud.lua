-- Native HUD pixels unfold from compact paper bundles. Presentation only:
-- native text, HP, inputs and battle clocks keep their existing ownership.
local V=...
local H={DURATION=.3,COLUMNS=12,ROWS=5}
local Origami=V.require('battle/OrigamiSpawn')
local Anim=require('src.core.game3.battle.anim')
local Version=require('src.core.GameVersion')
local boxes={{key='player',x=0,y=0,w=120,h=50},{key='enemy',x=120,y=0,w=120,h=42},{key='panel',x=0,y=112,w=240,h=48}}
H.boxes=boxes
local function smooth(x)x=math.max(0,math.min(1,x));return x*x*(3-2*x)end
function H.enabled(record)
 return record and record.scene and not record.battle.double and Version.get()=='firered'and Origami.enabled()
end
function H.update(record,dt)
 if not H.enabled(record)then
  if record and record.paperHud then for _,s in pairs(record.paperHud)do s.age=H.DURATION end end
  return
 end
 local state=record.paperHud
 if not state then state={};record.paperHud=state end
 local stage=Anim.stage();local health=stage and stage.healthbox or{}
 for _,b in ipairs(boxes)do
  local mon=record.battle[b.key];local token=b.key=='panel'and record.battle or mon and(mon.mon or mon)
  local visible=b.key=='panel'or token and not(health[b.key]and health[b.key].visible==false)
  local s=state[b.key]
  if not s then s={};state[b.key]=s end
  if token~=s.token then s.token=token;s.age=0;s.seen=false end
  if visible and not s.visible and not s.seen then s.age=0 end
  s.visible=not not visible
  if visible then s.seen=true;s.age=math.min(H.DURATION,(s.age or 0)+math.max(0,math.min(dt or 0,.1)))end
 end
end
local function modal()
 for _,name in ipairs{'bag_menu','party_menu','pokedex','stat_growth'}do
  local m=package.loaded['src.ui.game3.'..name]
  if m and m.isOpen and m.isOpen()then return true end
 end
end
function H.pending(record)
 if not H.enabled(record)then H.update(record,0);return false end
 if modal()then return false end
 H.update(record,0)
 for _,s in pairs(record.paperHud)do if s.visible and s.age<H.DURATION then return true end end
 return false
end
function H.progress(record,key)
 local s=record.paperHud and record.paperHud[key]
 return s and s.age/H.DURATION or 1
end
-- A folded sheet passes through an irregular, compact bundle before the
-- diagonal flaps spread; the last few frames ease back to its exact flat plane.
function H.point(u,v,progress,w,h)
 if progress>=1 then return u*w*.5,v*h*.5,0 end
 local spread=smooth((progress-.06)/.82);local flat=smooth((progress-.48)/.52)
 local radius=6.5;local theta=u*math.pi*1.45+v*.45
 local envelope=math.sqrt(math.max(.06,1-v*v*.8))
 local bx=math.sin(theta)*radius*envelope
 local by=(v*.64+math.cos(theta)*.4)*radius
 local bz=math.cos(theta)*radius*envelope
 local crease=math.abs(u+v*.48)-.45
 local fold=(1-flat)*math.sin(crease*math.pi*2.1)
 local x=bx*(1-spread)+u*w*.5*spread+fold*h*.075*spread
 local y=by*(1-spread)+v*h*.5*spread+fold*h*.12*spread
 local z=bz*(1-spread)+math.abs(fold)*h*.24*spread
 local settle=progress>.86 and math.sin((progress-.86)/.14*math.pi*2)*(1-progress)*1.3 or 0
 return x,y+settle,z
end
local surfaces={};local mask
local format={{'VertexPosition','float',2},{'VertexTexCoord','float',2},{'VertexColor','float',4}}
local function surface(box)
 local s=surfaces[box.key];if s then return s end
 s={points={},triangles={},vertices={}};surfaces[box.key]=s
 for j=0,H.ROWS do for i=0,H.COLUMNS do s.points[#s.points+1]={u=i/H.COLUMNS*2-1,v=j/H.ROWS*2-1}end end
 local function tri(a,b,c)s.triangles[#s.triangles+1]={s.points[a],s.points[b],s.points[c],depth=0}end
 for j=0,H.ROWS-1 do for i=0,H.COLUMNS-1 do
  local a=j*(H.COLUMNS+1)+i+1;local c=a+H.COLUMNS+1
  tri(a,a+1,c+1);tri(a,c+1,c)
 end end
 for i=1,#s.triangles*3 do s.vertices[i]={0,0,0,0,1,1,1,1}end
 s.mesh=love.graphics.newMesh(format,s.vertices,'triangles','stream');return s
end
local function farFirst(a,b)return a.depth<b.depth end
local function drawSheet(canvas,box,progress)
 local s=surface(box);local cx,cy=box.x+box.w*.5,box.y+box.h*.5
 for _,p in ipairs(s.points)do p.x,p.y,p.z=H.point(p.u,p.v,progress,box.w,box.h)end
 for _,t in ipairs(s.triangles)do t.depth=t[1].z+t[2].z+t[3].z end
 table.sort(s.triangles,farFirst)
 local i=0
 for _,t in ipairs(s.triangles)do
  local a,b,c=t[1],t[2],t[3];local ux,uy,uz=b.x-a.x,b.y-a.y,b.z-a.z;local vx,vy,vz=c.x-a.x,c.y-a.y,c.z-a.z
  local nx,ny,nz=uy*vz-uz*vy,uz*vx-ux*vz,ux*vy-uy*vx;local len=math.sqrt(nx*nx+ny*ny+nz*nz)
  local facing=len>1e-9 and math.abs(nz)/len or 1
  local shade=1-(1-facing)*.28*(1-smooth(progress))
  for k=1,3 do local p=t[k];i=i+1;local row=s.vertices[i]
   row[1],row[2]=cx+p.x,cy+p.y;row[3],row[4]=(box.x+(p.u+1)*box.w*.5)/240,(box.y+(p.v+1)*box.h*.5)/160
   row[5],row[6],row[7],row[8]=shade,shade,shade,1
  end
 end
 s.mesh:setVertices(s.vertices);s.mesh:setTexture(canvas);love.graphics.draw(s.mesh)
end
local maskSource=[[
uniform vec3 folded;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 vec2 p=uv*vec2(240.0,160.0);
 if((folded.x>.5&&p.x<120.0&&p.y<50.0)||(folded.y>.5&&p.x>=120.0&&p.y<42.0)||(folded.z>.5&&p.y>=112.0))return vec4(0.0);
 return Texel(tex,uv)*color;
}]]
local flags={0,0,0}
function H.prepare()
 mask=mask or V.require('ShaderCompiler').newShader(maskSource)
 for _,box in ipairs(boxes)do surface(box)end
end
function H.draw(canvas,record)
 H.prepare()
 for i,b in ipairs(boxes)do local s=record.paperHud[b.key];flags[i]=s and s.visible and s.age<H.DURATION and 1 or 0 end
 love.graphics.setShader(mask);mask:send('folded',flags);love.graphics.draw(canvas);love.graphics.setShader()
 for i,b in ipairs(boxes)do if flags[i]==1 then drawSheet(canvas,b,H.progress(record,b.key))end end
end
function H.release()
 for _,s in pairs(surfaces)do s.mesh:release()end;surfaces={}
 if mask then mask:release();mask=nil end
end
return H
