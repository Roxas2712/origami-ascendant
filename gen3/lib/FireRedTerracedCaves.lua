-- Native earth/rock caves with walkable terraces. Visual surfaces only; native
-- Strength switches, boulders, ladder warps and excavation scripts stay owned
-- by the engine. Fossil imprints are floor art, never plateau seeds.
local V=...;local R={plans=setmetatable({},{__mode='k'})}
local Budget=V.require('BuildBudget')
local names={FR_MT_MOON_1F=true,FR_MT_MOON_B1F=true,FR_MT_MOON_B2F=true,FR_VICTORY_ROAD_1F=true,FR_VICTORY_ROAD_2F=true,FR_VICTORY_ROAD_3F=true,FR_THREE_ISLAND_DUNSPARCE_TUNNEL=true}
local rocks={[0x282]=true,[0x283]=true,[0x2b6]=true,[0x318]=true,[0x31c]=true,[0x31d]=true,[0x31e]=true,[0x31f]=true,[0x320]=true}
local greyNames={FR_ROCK_TUNNEL_1F=true,FR_ROCK_TUNNEL_B1F=true,FR_SIX_ISLAND_ALTERING_CAVE=true}
local greyMasks=setmetatable({},{__mode='k'})
local dirs={{1,0},{-1,0},{0,1},{0,-1}}
local function cerulean(d)return V.require('FireRedCeruleanArt').profile(d)end
local function spa(d)return V.require('FireRedEmberSpa').profile(d)end
local function ember(d)return V.require('FireRedEmberArt').profile(d)end
local function icefall(d)return V.require('FireRedIcefallArt').profile(d)end
local function ice(d)return V.require('FireRedIceArt').profile(d)or icefall(d)end
local function art(d)
 if spa(d)then return V.require('FireRedEmberSpa')end
 if ember(d)then return V.require('FireRedEmberArt')end
 if cerulean(d)then return V.require('FireRedCeruleanArt')end
 if icefall(d)then return V.require('FireRedIcefallArt')end
 if ice(d)then return V.require('FireRedIceArt')end
end
local function rock(d,m)
 local a=art(d);if a then return a.rock(m)end
 return rocks[m]
end
local function stair(d,m)return m==(cerulean(d)and 0x91 or 0x284)end
local function cfg()return V.require('DioramaConfig').terrain.frTerracedCaves end
local function grey(d)return d and (d.renderPair or d.pair)=='general__rom_082d4df4'and greyNames[d.id]end
function R.profile(d)return d and cfg().enabled and tonumber(d.mapType)==4 and((d.renderPair or d.pair)=='general__rom_082d4bfc'and names[d.id]or cfg().rockTunnelAndAltering and grey(d)or cfg().cerulean and cerulean(d)or cfg().seafoam and V.require('FireRedIceArt').profile(d)or cfg().icefall and icefall(d)or cfg().ember and ember(d)or V.require('DioramaConfig').terrain.frEmberSpa.enabled and spa(d))and true or nil end
local function active(d)return R.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
local function solid(c)return c and(c.coll==7 or c.coll==255)end
local function jump(c)return c and c.coll>=0xa0 and c.coll<=0xa7 end
function R.kind(d,c)
 if not active(d)or not c then return end
 if art(d)and(art(d).ladderUpper(c.mid)or ice(d)and c.mid==0x2cd)then return end
 if spa(d)then
  if art(d).rim(c.mid)then return'frBrownRock'end
  if art(d).water(c.mid)then return end
 end
 if ember(d)and c.mid>=0x350 and c.mid<=0x353 then return end
 if ember(d)and c.mid==0x354 then return'frBrownPedestal'end
 if jump(c)then return'frBrownLedge'end
 if solid(c)and c.mid>=0x280 and not rock(d,c.mid)and not(c.mid>=0x2c8 and c.mid<=0x2ca)then return'frBrownRock'end
end
function R.height(kind)return kind=='frBrownPedestal'and cfg().emberPedestalHeight or kind=='frBrownLedge'and cfg().ledgeHeight or cfg().wallHeight end
function R.plan(d)
 local L=d.midLayout;local stamp=V.require('WorldGeometry').layoutStamp(L);local p=R.plans[L]
 if p and p.stamp==stamp then return p end
 -- Keep a partial plan private. Native cache activation can now prepare it
 -- across frames before any border or actor asks for the finished heights.
 p={stamp=stamp,upper={},level={},top={},base={},stairs={}}
 local components,groups={},{}
 local function index(x,y)if x>=0 and y>=0 and x<L.width and y<L.height then return y*L.width+x+1 end end
 local function walk(x,y)
  local k=index(x,y);if not k then return end;local c=L:cellAt(x,y)
  return not solid(c)and not jump(c)and not stair(d,c.mid) and c
 end
 for y=0,L.height-1 do for x=0,L.width-1 do local k=index(x,y);local start=walk(x,y)
  Budget.tick()
  if start and not components[k]then
   local id=#groups+1;local group={cells={k},edges={}};groups[id]=group;components[k]=id
   local queue={{x,y}};local at=1
   while at<=#queue do local q=queue[at]
    Budget.tick()
    for _,a in ipairs(dirs)do local nx,ny=q[1]+a[1],q[2]+a[2];local nk=index(nx,ny);local c=walk(nx,ny)
     if c and not components[nk]and c.elev==start.elev then components[nk]=id;group.cells[#group.cells+1]=nk;queue[#queue+1]={nx,ny}end
    end
    at=at+1
   end
  end
 end end
 -- Stairs constrain adjacent connected floors: north is one storey higher.
 -- Moon B2F has nested terraces; seeding every stair at the same absolute
 -- height would raise the lower landing of the next stair incorrectly.
 for y=0,L.height-1 do for x=0,L.width-1 do Budget.tick();if stair(d,L:midAt(x,y))and not stair(d,L:midAt(x,y-1))then
  local last=y;while last+1<L.height and stair(d,L:midAt(x,last+1))do last=last+1;Budget.tick()end
  local n,b=components[index(x,y-1)],components[index(x,last+1)];local count=last-y+1
  assert(n and b and n~=b,'native stair lacks separate landings '..d.id..':'..x..','..y)
  groups[n].edges[#groups[n].edges+1]={b,-count};groups[b].edges[#groups[b].edges+1]={n,count}
  for row=y,last do p.stairs[index(x,row)]={north=index(x,y-1),south=index(x,last+1),offset=row-y,count=count}end
 end end end
 local visited={}
 for id,g in ipairs(groups)do if not visited[id]then
  local queue={id};local values={[id]=0};visited[id]=true;local at,lowest=1,0
  while at<=#queue do local n=queue[at]
   Budget.tick()
   for _,e in ipairs(groups[n].edges)do local v=values[n]+e[2]
    if values[e[1]]~=nil then assert(values[e[1]]==v,'inconsistent native stair cycle '..d.id)
    else values[e[1]]=v;lowest=math.min(lowest,v);visited[e[1]]=true;queue[#queue+1]=e[1]end
   end
   at=at+1
  end
  for _,n in ipairs(queue)do local level=values[n]-lowest
   for _,k in ipairs(groups[n].cells)do Budget.tick();p.level[k]=level;if level>0 then p.upper[k]=true end end
  end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do
  Budget.tick()
  local c=L:cellAt(x,y);local h=R.height(R.kind(d,c))
  local ground=0
  for _,a in ipairs(dirs)do local nx,ny=x+a[1],y+a[2]
   if nx>=0 and ny>=0 and nx<L.width and ny<L.height and p.upper[ny*L.width+nx+1]then ground=math.max(ground,(p.level[ny*L.width+nx+1]or 0)*cfg().platformHeight) end
  end
  if not jump(c)and ground>0 then h=ground end
  p.base[y*L.width+x+1]=ground
  p.top[y*L.width+x+1]=h
 end end
 -- Boulder-occupied terrace cells still support the adjoining low rim.
 -- Otherwise one solid object interrupts the height inference and creates
 -- an isolated full-height wall tile on an otherwise short terrace.
 if ice(d)then for y=0,L.height-1 do for x=0,L.width-1 do
  Budget.tick()
  local k=y*L.width+x+1;local c=L:cellAt(x,y)
  if R.kind(d,c)then local ground=p.base[k]
   for _,a in ipairs(dirs)do local nx,ny=x+a[1],y+a[2];local nk=index(nx,ny)
    if nk and art(d).rock(L:midAt(nx,ny))then ground=math.max(ground,p.base[nk]or 0)end
   end
   if ground>p.base[k]then p.base[k]=ground;p.top[k]=ground end
  end
 end end end
 if icefall(d)or spa(d)then art(d).plan(d,p)end
 R.plans[L]=p;return p
end
function R.prepare(d)
 if active(d)then return R.plan(d)end
end
-- A linear index is valid only inside the layout. At x=-1 or x=width it
-- otherwise aliases the preceding/following native row and cuts arbitrary
-- low strips into the repeated border. Raised baths/waterfalls own their
-- continuation policy; ordinary cave borders keep the configured rock top.
local function wallTop(d,p,x,y)
 local L=d.midLayout
 if x>=0 and y>=0 and x<L.width and y<L.height then return p.top[y*L.width+x+1]or cfg().wallHeight end
 return p.borderTop and p.borderTop(x,y)or cfg().wallHeight
end
function R.floorHeight(d,x,z,plan)
 if icefall(d)or spa(d)then local h=art(d).floorHeight(d,x,z);if h then return h end end
 local L=d.midLayout;local cx,cy=math.floor(x/16),math.floor(z/16);local p=plan or R.plan(d)
 if cx<0 or cy<0 or cx>=L.width or cy>=L.height then return 0 end
 if stair(d,L:midAt(cx,cy)) then
  local run=assert(p.stairs[cy*L.width+cx+1]);local a=(p.level[run.north]or 0)*cfg().platformHeight
  local t=math.floor((z%16)/16*cfg().stairSteps)/cfg().stairSteps
  return a-(run.offset+t)*cfg().platformHeight
 end
 local k=cy*L.width+cx+1
 return p.level[k]and p.level[k]*cfg().platformHeight or solid(L:cellAt(cx,cy))and p.base[k]or 0
end
function R.actorHeight(d,x,z)
 if active(d)then
  if ember(d)and d.midLayout:midAt(math.floor((x+8)/16),math.floor((z+15.99)/16))==0x354 then return cfg().emberPedestalHeight end
  return R.floorHeight(d,x+8,z+15.99)
 end
end
function R.rockHeight(d,x,z)
 if not active(d)then return end
 local L=d.midLayout;local cx,cy=math.floor(x/16),math.floor(z/16)
 return R.kind(d,L:cellAt(cx,cy))and wallTop(d,R.plan(d),cx,cy)or R.floorHeight(d,x,z)
end
function R.lighting(d,result)
 if not active(d)then return end
 for _,l in ipairs(result.lights or{})do if l.kind~='crystal'then l.y=l.y+R.floorHeight(d,l.x,l.z)end end
 for _,s in ipairs(result.sprites or{})do if s.kind~='crystalGlow'then s.y=s.y+R.floorHeight(d,s.x,s.z)end end
 for _,s in ipairs(result.shafts or{})do s.y=R.floorHeight(d,s.x,s.z)end
end
local function donor(m)return(m==0x28e or m==0x28f or m==0x2b5)and 0x299 or m end
local function mask(ts,m,d)
 m=donor(m)
 if art(d)then return art(d).mask(ts,m)end
 if not grey(d)then return V.require('FireRedLostCave').mask(ts,m)end
 -- Native olive earth has a different palette from the brown-cave family.
 -- Derive it from its own floor tile, never replace or recolor the sprite.
 local cache=greyMasks[ts];local BM=V.require('BuildingMesh')
 local function color(mid,x,y)local r,g,b=BM.pixel(ts,mid,x,y);return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 if not cache then
  cache={floor={}};greyMasks[ts]=cache
  for y=0,15 do for x=0,15 do cache.floor[color(0x281,x,y)]=true end end
 end
 if not cache[m]then
  local ink={count=0}
  for y=0,15 do for x=0,15 do local yes=not cache.floor[color(m,x,y)];ink[y*16+x+1]=yes;if yes then ink.count=ink.count+1 end end end
  cache[m]=ink
 end
 return cache[m]
end
-- Height of the actual visible pixel, including mixed water/rock shore tiles.
function R.surfaceHeight(d,ts,wx,wz,plan)
 local p=plan or R.plan(d);local L=d.midLayout;local x,y=math.floor(wx/16),math.floor(wz/16);local c=L:cellAt(x,y)
 if R.kind(d,c)then
  if mask(ts,c.mid,d)[(wz%16)*16+wx%16+1]then return wallTop(d,p,x,y)end
  if art(d)and art(d).shore(ts,donor(c.mid))then return spa(d)and art(d).waterHeight(x,y)or 0 end
 end
 return R.floorHeight(d,wx,wz,p)
end
-- Border rebuilds sample each repeated rock cell more than a thousand times.
-- Resolve its native material/classification once per layout revision, while
-- retaining the exact same per-pixel mask and floor-height fallback. This
-- cache is only used while stamping active terrain, never to classify Off.
local function surfaceSampler(d,ts,p)
 p.surfaceSamples=p.surfaceSamples or setmetatable({},{__mode='k'})
 local rows=p.surfaceSamples[ts]
 if not rows then rows={};p.surfaceSamples[ts]=rows end
 local L=d.midLayout;local policy=art(d)
 local function sampleAt(x,y)
  local row=rows[y];if not row then row={};rows[y]=row end
  local sample=row[x]
  if not sample then
   local c=L:cellAt(x,y);sample={}
   if R.kind(d,c)then
    sample.ink=mask(ts,c.mid,d);sample.top=wallTop(d,p,x,y)
    if policy and policy.shore(ts,donor(c.mid))then sample.shore=spa(d)and policy.waterHeight(x,y)or 0 end
   end
   row[x]=sample
  end
  return sample
 end
 return function(wx,wz)
  local sample=sampleAt(math.floor(wx/16),math.floor(wz/16))
  if sample.ink then
   if sample.ink[(wz%16)*16+wx%16+1]then return sample.top end
   if sample.shore~=nil then return sample.shore end
  end
  return R.floorHeight(d,wx,wz,p)
 end,function(x,y,h)
  local sample=sampleAt(x,y)
  return sample.ink and sample.ink.count==256 and sample.top==h
 end
end
function R.stamp(out,d,ts,x,y,ox,oz)
 local L=d.midLayout;local c=L:cellAt(x,y);if not R.kind(d,c)then return false end
 local G=V.require('WorldGeometry');local C=cfg();local p=R.plan(d);local h=wallTop(d,p,x,y)
 local portal=(ice(d)or ember(d))and c.mid==0x28c and L:midAt(x,y+1)==0x294
 local m=portal and 0x299 or donor(c.mid);local ink=mask(ts,m,d);local xx,zz=(x+ox)*16,(y+oz)*16
 -- This native grey wall donor has earth pixels only in its bottom row.
 -- Keep those in the ground contour, not stretched along a vertical face.
 local sideRows=(grey(d)or cerulean(d))and 15 or 16
 local ground=R.floorHeight(d,x*16,y*16,p)
 local shore=art(d)and art(d).shore(ts,m)
 if shore then ground=spa(d)and art(d).waterHeight(x,y)or 0 end
 if ground<h then
  G.quad(out,{xx,ground,zz},{xx+16,ground,zz},{xx+16,ground,zz+16},{xx,ground,zz+16},G.uv(ts,shore and m or spa(d)and 0x32d or 0x281),shore and G.WATER or 1)
 else
  -- A terrace rim meets its walkable floor at the same height. Fill only
  -- the sand pixels; overlapping complete quads would flicker at the seam.
  for sy=0,15 do local sx=0;while sx<16 do if not ink[sy*16+sx+1]then local a=sx;repeat sx=sx+1 until sx==16 or ink[sy*16+sx+1]
   G.quad(out,{xx+a,ground,zz+sy},{xx+sx,ground,zz+sy},{xx+sx,ground,zz+sy+1},{xx+a,ground,zz+sy+1},G.uv(ts,spa(d)and 0x32d or 0x281,a,sy,sx,sy+1,.5),1)
  else sx=sx+1 end end end
 end
 local first=#out+1
 local neighbor,uniform=surfaceSampler(d,ts,p)
 if ink.count==256 then G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m,0,0,16,16,.5),1)
 else for sy=0,15 do local sx=0;while sx<16 do if ink[sy*16+sx+1]then local a=sx;repeat sx=sx+1 until sx==16 or not ink[sy*16+sx+1]
  G.quad(out,{xx+a,h,zz+sy},{xx+sx,h,zz+sy},{xx+sx,h,zz+sy+1},{xx+a,h,zz+sy+1},G.uv(ts,m,a,sy,sx,sy+1,.5),1)
 else sx=sx+1 end end end end
 -- A full cap surrounded by equal full caps exposes no sides at all.
 local enclosed=not portal and ink.count==256 and uniform(x-1,y,h)and uniform(x+1,y,h)and uniform(x,y-1,h)and uniform(x,y+1,h)
 if not enclosed then
 -- A fully opaque cap has no interior boundary. Only its perimeter can
 -- expose a side; retain the original row/column order and vertex attributes.
 for sy=0,15 do local step=not portal and ink.count==256 and sy>0 and sy<15 and 15 or 1
 for sx=0,15,step do local edgeHeight=ink[sy*16+sx+1]and h or ground
 if edgeHeight>0 then for _,dir in ipairs(dirs)do
  local nx,ny=sx+dir[1],sy+dir[2]
  -- Interior rock pixels share this cell's top. Portal donor art is the
  -- exception: its visible mask differs from the native sampled mask.
  local low
  if not portal and nx>=0 and nx<16 and ny>=0 and ny<16 and ink[ny*16+nx+1]then low=h
  else low=neighbor(x*16+nx,y*16+ny)end
  if low<edgeHeight and not(portal and dir[2]==1 and sy==15)then local a,b,u
   if dir[1]==0 then local z=zz+sy+(dir[2]>0 and 1 or 0);a={xx+sx,z};b={xx+sx+1,z};u=sx
   else local xp=xx+sx+(dir[1]>0 and 1 or 0);a={xp,zz+sy};b={xp,zz+sy+1};u=sy end
   G.quad(out,{a[1],edgeHeight,a[2]},{b[1],edgeHeight,b[2]},{b[1],low,b[2]},{a[1],low,a[2]},G.uv(ts,0x299,u,0,u+1,sideRows,.5),C.sideShade)
  end
 end end end end
 end
 if portal then
  local mouth={};V.require('FireRedLostCave').portal(mouth,ts,c.mid,xx,zz,'north')
  local sourceHeight=V.require('DioramaConfig').terrain.frLostCave.wallHeight
  for _,v in ipairs(mouth)do v[2]=v[2]*h/sourceHeight;out[#out+1]=v end
 end
 -- Full rock walls also occlude actors on elevated landings. Keep short
 -- bath rims intact. Cerulean terrace rims also hide actors on the lower
 -- landing, so they share the closed section with their raised floor below.
 if h-ground>=C.wallHeight-.001 or cerulean(d)and h>ground then for i=first,#out do out[i][9]=-2 end end
 return true
end
function R.floor(out,d,ts,x,y,ox,oz)
 if not active(d)then return false end
 local L=d.midLayout;if R.kind(d,L:cellAt(x,y))then return false end
 if (icefall(d)or spa(d))and art(d).floor(out,d,ts,x,y,ox,oz)then return true end
 local first=#out+1
 local m=L:midAt(x,y);local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 if art(d)then m=art(d).floorMid(m,ts)end
 if (not art(d)and rocks[m])or grey(d)and m==0x2cd or m==0x296 or m==0x297 or not ice(d)and m==0x31b then m=0x281 end
 local plan=R.plan(d);local h=R.floorHeight(d,x*16,y*16,plan)
 if not stair(d,m)then G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m,0,0,16,16,.5),art(d)and V.data('Shapes').water(L:cellAt(x,y))and G.WATER or 1)
 else
  for sy=0,15 do local a=R.floorHeight(d,x*16,y*16+sy,plan);local b=R.floorHeight(d,x*16,y*16+sy+1,plan)
   G.quad(out,{xx,a,zz+sy},{xx+16,a,zz+sy},{xx+16,a,zz+sy+1},{xx,a,zz+sy+1},G.uv(ts,m,0,sy,16,sy+1,.5),1)
   if a~=b then G.quad(out,{xx,a,zz+sy+1},{xx+16,a,zz+sy+1},{xx+16,b,zz+sy+1},{xx,b,zz+sy+1},G.uv(ts,m,0,sy,16,sy+1,.5),cfg().sideShade)end
  end
 end
 -- Cerulean has walkable moss rims and bridges beside water, not only solid
 -- wall metatiles. Close the exposed boundary of those raised floor quads.
 if art(d)then for _,dir in ipairs(dirs)do for t=0,15 do
  local sx=dir[1]~=0 and(dir[1]>0 and 15 or 0)or t
  local sy=dir[2]~=0 and(dir[2]>0 and 15 or 0)or t
  local high=R.floorHeight(d,x*16+sx,y*16+sy,plan)
  local low=R.surfaceHeight(d,ts,x*16+sx+dir[1],y*16+sy+dir[2],plan)
  if high>low then
   local a,b
   if dir[1]==0 then local z=zz+sy+(dir[2]>0 and 1 or 0);a={xx+sx,z};b={xx+sx+1,z}
   else local px=xx+sx+(dir[1]>0 and 1 or 0);a={px,zz+sy};b={px,zz+sy+1}end
   G.quad(out,{a[1],high,a[2]},{b[1],high,b[2]},{b[1],low,b[2]},{a[1],low,a[2]},G.uv(ts,0x299,t,0,t+1,15,.5),cfg().sideShade)
  end
 end end end
 -- The cut plane follows the player's supporting floor. An elevated
 -- Cerulean terrace can occlude a lower landing just like a solid rock wall;
 -- include its native cap and side faces so CaveSectionMesh closes the cut.
 -- At/above the terrace the cut plane is higher and its floor stays intact.
 if cerulean(d)and(h>0 or stair(d,m))then for i=first,#out do out[i][9]=-2 end end
 return true
end
function R.objects(out,d,ts,ox,oz,contacts)
 if not active(d)then return end
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local L=d.midLayout;local C=cfg()
 local function place(v,x,z,h)for _,p in ipairs(v)do local q=G.place(p,(x+ox)*16,(z+oz)*16);q[2]=q[2]+(h or 0);out[#out+1]=q end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if not art(d)and(rocks[m]or grey(d)and m==0x2cd)then
   local h=R.floorHeight(d,x*16,y*16)
   place(P.build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return mask(ts,m,d)[t*16+s+1]end,0,16,C.rockScale,function()return 1 end,nil,.5),x,y+1,h)
   contacts[#contacts+1]={(x+ox)*16+8,(y+oz+1)*16,5,C.contactDepth,C.contactStrength,h}
  end
 end end
 if art(d)then art(d).objects(out,d,ts,ox,oz,contacts,R.floorHeight)end
 for _,w in ipairs(d.warps or{})do local lower=L:midAt(w.x,w.y);local upper=L:midAt(w.x,w.y-1)
  if(upper==0x28e or upper==0x28f or upper==0x2b5)and(lower==0x296 or lower==0x297 or lower==0x31b or (ice(d)or ember(d))and lower==0x2b7)then
   local function source(s,t)return t<16 and upper or lower,s,t%16 end
   local A=V.require('CaveObjectArt');local colors=grey(d)and{0xefde7b,0xdeb53a,0x4a4a4a,0x4a5252}or{0xffefa5,0xcead7b,0x4a4a3a,0x525242}
   local function inside(s,t)if art(d)then return art(d).ladderPixel(ts,s,t,source)end;return A.ladderPixel(ts,s,t,source,colors,{0,15,0,31})end
   local lo,hi=32,0;for t=0,31 do for s=0,15 do if inside(s,t)then lo=math.min(lo,t);hi=math.max(hi,t+1)end end end
   assert(hi>lo,'missing native cave ladder')
   local base=R.floorHeight(d,w.x*16,w.y*16);local top=wallTop(d,R.plan(d),w.x,w.y-1)
   if cerulean(d)then top=base+C.ceruleanLadderHeight elseif ice(d)then top=base+C.iceLadderHeight elseif ember(d)then top=base+C.emberLadderHeight end
   place(P.build(ts,16,32,source,inside,0,32,1,function()return 1 end,function(s,t)local f=(t-lo)/(hi-lo);return{s,base+(top-base)*(1-f),-16*(1-f)+C.ladderOffset}end,.5),w.x,w.y+1)
  end
 end
end
-- A synchronous border build repeats ordinary earth/grey-rock neighborhoods.
-- Cache only fully exterior stamps: no terrace floors or coordinate-specific
-- water/bath continuations. Each writer belongs to one build, so native edits,
-- atlas changes and settings never retain templates across rebuilds.
function R.borderWriter(d,ts)
 if not R.profile(d)or art(d)or R.plan(d).borderTop then return end
 local L=d.midLayout;local templates={}
 local function instanceKey(x,y)
  -- Include all four neighbors in the exterior-only condition.
  if not(x < -1 or y < -1 or x > L.width or y > L.height)then
   return nil
  end
  local c=L:cellAt(x,y);local key={c.mid,c.coll}
  for _,dir in ipairs(dirs)do
   local other=L:cellAt(x+dir[1],y+dir[2]);key[#key+1]=other.mid;key[#key+1]=other.coll
  end
  return 'frBrownRock:'..table.concat(key,':')
 end
 local function write(out,x,y)
  local key=instanceKey(x,y)
  if not key then return R.stamp(out,d,ts,x,y,0,0)end
  local template=templates[key];local xx,zz=x*16,y*16
  if template then
   for _,v in ipairs(template)do
    out[#out+1]={v[1]+xx,v[2],v[3]+zz,v[4],v[5],v[6],v[7],v[8],v[9]}
   end
   return true
  end
  local first=#out+1;local result=R.stamp(out,d,ts,x,y,0,0)
  if result then
   template={};templates[key]=template
   for i=first,#out do local v=out[i]
    template[#template+1]={v[1]-xx,v[2],v[3]-zz,v[4],v[5],v[6],v[7],v[8],v[9]}
   end
  end
  return result
 end
 -- Only this guarded key may group rigid exterior instances. Boundary
 -- terraces and special cave art retain the expanded stamp path.
 return write,instanceKey
end
return R
