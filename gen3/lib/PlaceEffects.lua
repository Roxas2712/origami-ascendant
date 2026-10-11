-- Place themes: per-location particles and lights that give special places
-- their own atmosphere (Cinnabar/Mt. Ember ash and sparks, Seafoam/Icefall
-- ice glitter and shimmer, Cerulean Cave light crystals, Sevii caves, ...).
-- Visual only; map data, collisions and scripts are never touched.
local V=...
local Budget=V.require('BuildBudget')
local P={}
local function cfg()return V.require('DioramaConfig').places end
local function hash(a,b)local h=math.sin(a*127.1+b*311.7)*43758.5453;return h-math.floor(h)end
function P.theme(def)
 local c=cfg();if not(c and c.enabled and def)then return nil end
 local id=def.id or def.name or ''
 for _,r in ipairs(c.rules)do if id:match(r[1])then return c.themes[r[2]],r[2] end end
 return nil
end
local function lerp3(a,b,t)return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t}end
-- Particles live on a world grid around the player so they stay anchored while
-- the camera follows; each cell owns one particle with its own phase.
local function field(px,pz,spacing,radius,fn)
 local cx,cz=math.floor((px+8)/spacing),math.floor((pz+8)/spacing);local r=math.ceil(radius/spacing)
 for gz=cz-r,cz+r do for gx=cx-r,cx+r do fn(gx,gz,gx*spacing,gz*spacing,hash(gx,gz)) end end
end
local function sprite(result,s,light)
 result.sprites[#result.sprites+1]=s
 if light then result.lights[#result.lights+1]=s end
end
function P.apply(def,result,px,pz,time,data,outdoors)
 P.current=nil;P.veil=nil
 local t=P.theme(def);if not t or V.require('TanobyChambers').profile(def)then return end
 local measuredPower=not outdoors and V.require('PowerPlantRoom').profile(def)
 local measuredMansion=not outdoors and V.require('MansionShell').profile(def)
 local measuredLeague=not outdoors and (V.require('FireRedLeagueRooms').profile(def)or V.require('FireRedFinalRooms').profile(def))
 local measuredRocket=not outdoors and V.require('RocketLighting').profile(def)
 local night=outdoors and V.require('DayNight').windowLight()or 1
 -- Ambient and lamp tint (caves/rooms only; outdoor light stays with the day cycle).
 if t.ambient and not outdoors and not measuredLeague and not measuredMansion and not measuredPower then result.ambient={t.ambient[1],t.ambient[2],t.ambient[3]} end
 if t.lampColor then for _,l in ipairs(result.lights)do if l.kind=='player' then l.color=t.lampColor end end end
 if t.tint and outdoors then local k=t.tint;result.ambient={result.ambient[1]*k[1],result.ambient[2]*k[2],result.ambient[3]*k[3]} end
 local budget=cfg().lightBudget;local lights=0
 -- Falling volcanic ash: soft grey flakes drifting down and sideways.
 if t.ash then local a=t.ash
  field(px,pz,a.spacing,a.radius,function(gx,gz,x,z,h)
   local fall=((time*a.speed+h*a.height)%a.height)
   local y=a.height-fall
   sprite(result,{x=x+h*a.spacing+math.sin(time*.6+h*9)*a.sway+fall*a.wind,y=y,z=z+hash(gz,gx)*a.spacing,
    size=a.size*(.6+.6*h),color=a.color,alpha=a.alpha*math.min(1,fall/12)*math.min(1,y/6),kind='ash'})
  end)
 end
 -- Rising embers/sparks: bright orange points that flicker out as they climb.
 if t.sparks and not measuredMansion then local s=t.sparks
  field(px,pz,s.spacing,s.radius,function(gx,gz,x,z,h)
   if h<s.density then
    local life=((time*s.speed*(.7+.6*h)+h*7)%1)
    local flick=.6+.4*math.sin(time*23+h*50)
    local l={x=x+h*s.spacing+math.sin(time*2+h*13)*s.sway*life,y=2+life*s.height,z=z+hash(gz,gx)*s.spacing,
     size=s.size,color=s.color,alpha=(1-life)*flick,power=s.power*(1-life)*flick,radius=-s.lightRadius,kind='spark'}
    local lit=lights<budget and h<s.density*.35;if lit then lights=lights+1 end
    sprite(result,l,lit)
   end
  end)
 end
 -- Ice glitter: tiny cold specks that twinkle on and off on the floor.
 if t.glitter then local g=t.glitter
  field(px,pz,g.spacing,g.radius,function(gx,gz,x,z,h)
   local L=def.midLayout;local gx0,gz0=math.floor((x+h*g.spacing)/16),math.floor((z+hash(gz,gx)*g.spacing)/16)
   local inside=L and gx0>=0 and gz0>=0 and gx0<L.width and gz0<L.height
   local cell=inside and L:cellAt(gx0,gz0);local Sh=V.data('Shapes')
   local ok
   if g.water then ok=cell and Sh.water(cell) else ok=cell and P.isInside(def,gx0,gz0) and not Sh.water(cell) end
   if h<g.density and ok then
    local tw=math.max(0,math.sin(time*g.speed*(.6+h)+h*40));tw=tw^g.sharp
    if tw>.02 then sprite(result,{x=x+h*g.spacing,y=g.height,z=z+hash(gz,gx)*g.spacing,size=g.size*(.6+.8*tw),color=g.color,alpha=tw,kind='glitter'})end
   end
  end)
 end
 -- Ice shimmer: a few soft cool lights that wander slowly like reflected water.
 if t.shimmer and not measuredLeague then local s=t.shimmer
  for i=1,s.count do
   local a=time*s.speed*(1+i*.21)+i*2.1
   local r=s.orbit*(.5+.5*math.sin(time*.13+i*1.7))
   local l={x=px+8+math.cos(a)*r,y=s.height,z=pz+8+math.sin(a*1.3)*r*.8,radius=-s.radius,
    power=s.power*(.7+.3*math.sin(time*1.7+i)),color=s.color,kind='shimmer'}
   if lights<budget then result.lights[#result.lights+1]=l;lights=lights+1 end
  end
 end
 -- Light crystals: real faceted 3D clusters growing from the cave walls
 -- (built once per map, drawn with depth), one coloured light pool each.
 if t.crystals then local c=t.crystals
  local sites=P.crystalSites(def,c)
  local near={}
  for _,q in ipairs(sites)do local d=(q.x-px)^2+(q.z-pz)^2;if d<c.reach^2 then near[#near+1]={q=q,d=d}end end
  table.sort(near,function(a,b)return a.d<b.d end)
  for i=1,math.min(#near,c.lights or 6)do local q=near[i].q
   local col=P.crystalColor(c,q,time)
   local pulse=.8+.2*math.sin(time*c.pulse+q.seed*9)
   if lights<budget then lights=lights+1
    result.lights[#result.lights+1]={x=q.x,y=q.y+12,z=q.z+8,radius=-c.radius,power=c.power*pulse,color=col,kind='crystal',falloff=1.4}
   end
  end
  for _,n in ipairs(near)do local q=n.q
   if n.d<(c.reach*.8)^2 then
    local col=P.crystalColor(c,q,time)
    result.sprites[#result.sprites+1]={x=q.x,y=q.y+q.h*.55,z=q.z+2,size=q.h*.9,color=col,alpha=.8+.2*math.sin(time*c.pulse+q.seed*9),kind='crystalGlow'}
   end
  end
  P.current={def=def,c=c,time=time}
  result.crystals=#near
 else P.current=nil end
 -- Floating motes: slow dust/snow/ember specks drifting in the lamp light.
 if t.motes then local m=t.motes
  field(px,pz,m.spacing,m.radius,function(gx,gz,x,z,h)
   if h<m.density and P.isInside(def,math.floor((x+h*m.spacing)/16),math.floor((z+hash(gz,gx)*m.spacing)/16)) then
    local ph=time*m.speed+h*20
    local y=m.base+((ph*3)%m.height)
    local fade=math.sin(math.pi*((ph*3)%m.height)/m.height)
    sprite(result,{x=x+h*m.spacing+math.sin(ph)*6,y=y,z=z+hash(gz,gx)*m.spacing+math.cos(ph*.7)*4,size=m.size,color=m.color,alpha=m.alpha*fade,kind='mote'})
   end
  end)
 end
 -- Glowing warp pads (Silph Co. teleporters): pulsing light on in-building warps.
 if t.pads and not measuredRocket then local pd=t.pads
  for _,w in ipairs(def.warps or {})do
   if w.x and w.y and (not pd.nativeMids or def.midLayout and pd.nativeMids[def.midLayout:midAt(w.x,w.y)]) and (not pd.destPattern or tostring(w.destMap or ''):match(pd.destPattern)) then
    local x,z=w.x*16+8,w.y*16+8
    if (x-px)^2+(z-pz)^2<pd.reach^2 then
     local pulse=.6+.4*math.sin(time*pd.speed+w.x+w.y)
     if lights<budget then lights=lights+1
      result.lights[#result.lights+1]={x=x,y=6,z=z,radius=-pd.radius,power=pd.power*pulse,color=pd.color,kind='pad'} end
     sprite(result,{x=x,y=2,z=z,size=pd.size,color=pd.color,alpha=.7*pulse,kind='glitter',haloAlpha=.5})
    end
   end
  end
 end
 -- Generic alarm for unmeasured hideouts. Measured Rocket floors have
 -- fixed fixtures and never tint the whole room around the player.
 if t.alarm and not measuredRocket then local al=t.alarm
  local k=math.max(0,math.sin(time*al.speed))^2
  if lights<budget then lights=lights+1
   result.lights[#result.lights+1]={x=px+8,y=al.height,z=pz-20,radius=-al.radius,power=al.power*k,color=al.color,kind='alarm'} end
  local a2=result.ambient;result.ambient={a2[1]*(1+al.tint*k),a2[2]*(1-al.tint*.5*k),a2[3]*(1-al.tint*.5*k)}
 end
 -- Spotlights (League rooms): fixed pools on the arena floor, gently breathing.
 if t.spots and def.midLayout and not measuredLeague then local sp=t.spots;local L=def.midLayout
  for i,o in ipairs(sp.at)do
   local x,z=L.width*16*o[1],L.height*16*o[2]
   if lights<budget then lights=lights+1
    result.lights[#result.lights+1]={x=x,y=sp.height,z=z,radius=-sp.radius,power=sp.power*(.9+.1*math.sin(time*.7+i)),color=o[3] or sp.color,kind='spot',falloff=1.6} end
  end
 end
 -- Veil: a thin drifting mist over the whole room (Agatha, mystic places).
 P.veil=t.veil
 -- Ceiling holes (ruins): reuse the cave skylight placement.
 if t.skylights and not measuredMansion then local sc=t.skylights;local A=V.require('Atmosphere')
  for _,p in ipairs(A.skylights(def,sc))do
   local d=(p.x-px)^2+(p.z-pz)^2
   if d<sc.reach^2 then local k=math.min(1,(sc.reach-math.sqrt(d))/70)
    result.shafts[#result.shafts+1]={x=p.x,z=p.z,color=sc.dayColor,fade=k,width=sc.width,height=sc.height,alpha=sc.alpha,slant=sc.slant,spread=sc.spread}
    if lights<budget then lights=lights+1
     result.lights[#result.lights+1]={x=p.x,y=8,z=p.z,radius=-sc.poolRadius,power=sc.poolPower*k,color=sc.dayColor,falloff=2} end
   end
  end
 end
 -- Electric sparks (Power Plant): short bright flashes near walls.
 if t.zaps and not measuredPower and data and data.edges then local z=t.zaps
  for _,p in ipairs(data.edges)do
   local d=(p.x-px)^2+(p.z-pz)^2
   if d<z.reach^2 and (p.seed%1)<z.density then
    local on=math.sin(time*z.speed+p.seed*31)>z.threshold
    if on then
     local l={x=p.x+6,y=z.height,z=p.z+4,radius=-z.radius,power=z.power,color=z.color,kind='zap',size=z.size,alpha=1}
     local lit=lights<budget;if lit then lights=lights+1 end
     sprite(result,l,lit)
    end
   end
  end
 end
end
-- Interior mask: in FireRed caves the black void around the cave is often
-- walkable-flagged, so "not solid" is not "inside". Flood-fill the real cave
-- floor from the map's warps (doors, ladders, holes) across non-solid cells.
P.inside=setmetatable({},{__mode='k'})
function P.interior(def)
 local L=def.midLayout;if P.inside[L]then return P.inside[L]end
 local Sh=V.data('Shapes');local W,H=L.width,L.height;local m={}
 local function ok(x,z)if x<0 or z<0 or x>=W or z>=H then return false end;local q=L:cellAt(x,z);return q and q.mid~=0 and not Sh.solid(q)end
 local queue={}
 for _,w in ipairs(def.warps or {})do if w.x and w.y and x~=nil or true then
  local x,z=w.x,w.y;if x and z and ok(x,z) and not m[z*W+x]then m[z*W+x]=true;queue[#queue+1]={x,z}end end end
 local n=1
 while queue[n]do Budget.tick();local x,z=queue[n][1],queue[n][2];n=n+1
  for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}})do local nx,nz=x+d[1],z+d[2]
   if ok(nx,nz) and not m[nz*W+nx]then m[nz*W+nx]=true;queue[#queue+1]={nx,nz}end end end
 if n==1 then for z=0,H-1 do for x=0,W-1 do Budget.tick();if ok(x,z)then m[z*W+x]=true end end end end
 P.inside[L]=m;return m
end
function P.floorCount(def)
 local L=def.midLayout;local n=0;for _ in pairs(P.interior(def))do n=n+1 end;return n
end
function P.isInside(def,x,z)local L=def.midLayout;return x>=0 and z>=0 and x<L.width and z<L.height and P.interior(def)[z*L.width+x]==true end
-- Crystal sites, chosen like a level artist would:
--  * on the cave's own rock rim (rock cell whose south neighbour is real cave
--    floor), so the cluster grows out of the wall's front edge toward the
--    camera and leans over the floor;
--  * the wall must continue to at least one side (no pillars, pedestals,
--    loose rocks); never the void, water or the map border;
--  * corners/nooks and water edges score higher; best spots win, far apart.
P.sites=setmetatable({},{__mode='k'})
function P.crystalSites(def,c)
 local key=def.midLayout
 if P.sites[key] then return P.sites[key] end
 local L=def.midLayout;local Sh=V.data('Shapes');local T=V.require('Terrain')
 local W,H=L.width,L.height
 local function cell(x,z)if x<0 or z<0 or x>=W or z>=H then return nil end;return L:cellAt(x,z)end
 local function floor(x,z)return P.isInside(def,x,z) and not Sh.water(cell(x,z)) end
 local function water(x,z)local q=cell(x,z);return q and Sh.water(q) end
 local function rock(x,z)local q=cell(x,z);return q and Sh.solid(q) and q.mid~=0 end
 local cand={}
 for z=1,H-2 do for x=1,W-2 do
  Budget.tick()
  local q=cell(x,z)
  local nearWarp=false
  for _,w in ipairs(def.warps or {})do if w.x and w.y and math.abs(w.x-x)<=2 and math.abs(w.y-z)<=3 then nearWarp=true end end
  if not nearWarp and rock(x,z) and floor(x,z+1) and not floor(x,z-1) and (rock(x-1,z) or rock(x+1,z)) then
   local nook=((rock(x-1,z+1) and 1 or 0)+(rock(x+1,z+1) and 1 or 0))
   local corner=(rock(x-1,z) and rock(x+1,z)) and 0 or 1
   local wet=0;for dz=0,3 do for dx=-2,2 do if water(x+dx,z+dz) then wet=1 end end end
   local open=0;for dz=1,3 do for dx=-1,1 do if floor(x+dx,z+dz) then open=open+1 end end end
   local score=6*nook+3*corner+4*wet+open*.6+hash(x*3+1,z*7+2)*3
   local kind=T.kind(def,q);local top=V.require('EmeraldCaveTerraces').rockHeight(def,x*16,z*16)or V.require('FireRedTerracedCaves').rockHeight(def,x*16,z*16)or(kind and T.height(kind)or 0)
   cand[#cand+1]={x=x*16+8+(hash(x,z)-.5)*5,z=z*16+12,y=top,seed=hash(z,x)*97,score=score,
    h=c.size*(.85+.3*hash(z,x))*(nook>0 and 1.12 or 1),lean=math.pi*.5+((rock(x-1,z) and not rock(x+1,z)) and -.5 or (rock(x+1,z) and not rock(x-1,z)) and .5 or 0),open=true}
  end
 end end
 table.sort(cand,function(a,b)return a.score>b.score end)
 local target=math.max(c.min or 2,math.min(c.max or 6,math.floor(P.floorCount(def)/(c.perCells or 140)+.5)))
 local kept={};local spacing=math.min(c.spacing or 40,math.max(W,H)*16*.4)
 for _,q in ipairs(cand)do Budget.tick();local ok=true
  for _,k in ipairs(kept)do if (q.x-k.x)^2+(q.z-k.z)^2<spacing^2 then ok=false;break end end
  if ok and #kept<(c.max or 99) then kept[#kept+1]=q end end
 if kept[1] then kept[1].h=kept[1].h*1.35 end -- one hero formation per cave
 if V.require('DioramaConfig').places.debug then for _,q in ipairs(kept)do print('CRY',def.id,math.floor(q.x/16),math.floor(q.z/16),q.y,q.score) end end
 P.sites[key]=kept;return kept
end
function P.crystalColor(c,q,time)
 local k=math.floor(q.seed)%#c.colors+1;local col=c.colors[k]
 if c.cycle then local u=(time*c.cycle+q.seed*.1)%#c.colors;local a=math.floor(u)+1;local b=a%#c.colors+1;col=lerp3(c.colors[a],c.colors[b],u%1) end
 return col
end
-- Faceted prism cluster geometry. Faces are flat-shaded on the CPU from a
-- fixed key light; the tip carries an emissive core, the base sinks into rock.
local function prism(out,cx,cy,cz,h,r,lean,dir,col,emit)
 local n=6;local L={-.45,.75,.50};local ll=math.sqrt(L[1]^2+L[2]^2+L[3]^2);L={L[1]/ll,L[2]/ll,L[3]/ll}
 local ax,az=math.cos(dir)*lean,math.sin(dir)*lean
 local function pt(a,rr,y)local k=y/h;return {cx+math.cos(a)*rr+ax*y,cy+y,cz+math.sin(a)*rr*.8+az*y} end
 local shoulder=h*.72
 for i=0,n-1 do
  local a0,a1=i*2*math.pi/n,(i+1)*2*math.pi/n
  local b0,b1=pt(a0,r,-2),pt(a1,r,-2);local s0,s1=pt(a0,r*.82,shoulder),pt(a1,r*.82,shoulder);local tip=pt(0,0,h)
  local am=(a0+a1)/2;local nx,nz=math.cos(am),math.sin(am)
  local side=math.max(0,nx*L[1]+nz*L[3])*.8+.35
  local rim=(nz>.3) and .30 or (nx<-.3 and .18 or 0)
  local function v(p,t,sh)local e=emit*t
   out[#out+1]={p[1],p[2],p[3],math.min(1,col[1]*(sh+e*1.4)+e*.25),math.min(1,col[2]*(sh+e*1.4)+e*.25),math.min(1,col[3]*(sh+e*1.4)+e*.25),1} end
  -- side quad (base dark -> shoulder bright)
  v(b0,0,side*.45);v(b1,0,side*.45);v(s1,.35,side+rim)
  v(b0,0,side*.45);v(s1,.35,side+rim);v(s0,.35,side+rim)
  -- tip facet
  local up=math.max(0,.6*L[2]+.4*(nx*L[1]+nz*L[3]))+.45
  v(s0,.4,up);v(s1,.4,up);v(tip,.9,up+.3)
 end
end
function P.buildMesh(def,c)
 local verts={}
 for _,q in ipairs(P.crystalSites(def,c))do
  -- rough dark rock socket so the cluster grows out of the stone
  for j=0,5 do local a0,a1=j*math.pi/3,(j+1)*math.pi/3;local r=7.5
   local function v(xx,yy,zz,k)verts[#verts+1]={xx,yy,zz,.10*k,.10*k,.12*k,1}end
   v(q.x,q.y+2.2,q.z+1,1.4);v(q.x+math.cos(a0)*r,q.y-.5,q.z+1+math.sin(a0)*r*.7,.8);v(q.x+math.cos(a1)*r,q.y-.5,q.z+1+math.sin(a1)*r*.7,.8)
  end
  local s=q.seed;local dir=q.open and q.lean or hash(s,1)*6.28
  local shards={{0,0,1,0,.10},{-4.5,1.2,.70,-.8,.34},{4.8,1.6,.62,.8,.36},{-1.8,3.8,.46,.3,.42},{2.6,-1.8,.52,1.7,.26},{-3.8,-1.8,.40,-1.9,.30},{1.2,3.6,.34,1.0,.48}}
  for j,sh in ipairs(shards)do
   Budget.check()
   local col=c.colors[(math.floor(s)+(j>=5 and 1 or 0))%#c.colors+1]
   local ox,oz=sh[1],sh[2]
   prism(verts,q.x+ox,q.y,q.z+oz,q.h*sh[3]*(.9+.2*hash(s,j)),2.4+2.2*sh[3],sh[5],dir+sh[4]*.6,col,.55)
  end
 end
 if #verts==0 then return nil end
 Budget.check()
 return love.graphics.newMesh({{'VertexPosition','float',3},{'VertexColor','float',4}},verts,'triangles','static')
end
-- Publish only a complete mesh. CPU construction may yield in a map-load
-- job; after upload the module owns the cached object even if that job is
-- canceled. No live atmosphere/current-map state is changed by warming.
function P.prepareMesh(def,c)
 P.meshes=P.meshes or setmetatable({},{__mode='k'})
 local key=def.midLayout
 if P.meshes[key]==nil then P.meshes[key]=P.buildMesh(def,c) or false end
 return P.meshes[key]
end
local crystalShader
function P.prepareShader()
 if not crystalShader then crystalShader=V.require('ShaderCompiler').newShader([[
uniform mat4 vp;uniform float glow;
#ifdef VERTEX
vec4 position(mat4 t,vec4 p){return vp*p;}
#endif
#ifdef PIXEL
vec4 effect(vec4 c,Image tex,vec2 uv,vec2 s){return vec4(c.rgb*glow,1.0);}
#endif
]]) end
 return crystalShader
end
function P.draw(vp,time)
 local cur=P.current;if not cur then return end
 local m=P.prepareMesh(cur.def,cur.c);if not m then return end
 P.prepareShader()
 love.graphics.push('all');love.graphics.setShader(crystalShader)
 local target=love.graphics.getCanvas();local post=V.require('DioramaConfig').post
 if type(target)=='table'then target=target[1];if type(target)=='table'then target=target[1]or target.canvas end end -- MRT attachment descriptors
 if target and not target.getFormat then target=nil end
 -- Only the crystal's own coloured facets emit HDR energy. Lowering the
 -- whole cave's bloom threshold would also turn its ambient floor into glow.
 local emission=post.hdr and target and target:getFormat()=='rgba16f'and math.max(1,post.hdrEmission or 2.5)or 1
 crystalShader:send('vp','row',vp);crystalShader:send('glow',(.92+.08*math.sin(time*(cur.c.pulse or 1)))*emission)
 love.graphics.setDepthMode('lequal',true);love.graphics.setMeshCullMode('none');love.graphics.setBlendMode('alpha')
 love.graphics.setColor(1,1,1,1);love.graphics.draw(m);love.graphics.pop()
end
function P.release()
 for _,m in pairs(P.meshes or {})do if m then m:release()end end
 P.meshes=nil;P.sites=setmetatable({},{__mode='k'})
 if crystalShader then crystalShader:release();crystalShader=nil end
end
return P
