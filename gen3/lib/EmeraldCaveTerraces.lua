-- Native stair connectivity defines render heights; collision/elevation remain
-- engine-owned. A stair ending at solid rock is not an invented passage.
local V=...;local R={cache=setmetatable({},{__mode='k'})}
local dirs={{1,0},{-1,0},{0,1},{0,-1}}
local names={EM_VICTORY_ROAD_1F=true,EM_VICTORY_ROAD_B1F=true,EM_VICTORY_ROAD_B2F=true,
 EM_ALTERING_CAVE=true,EM_GRANITE_CAVE_B2F=true,EM_SEAFLOOR_CAVERN_ROOM1=true,EM_SEAFLOOR_CAVERN_ROOM9=true,
 EM_SHOAL_CAVE_LOW_TIDE_INNER_ROOM=true,EM_SHOAL_CAVE_LOW_TIDE_STAIRS_ROOM=true,
 EM_SHOAL_CAVE_HIGH_TIDE_ENTRANCE_ROOM=true,EM_SHOAL_CAVE_HIGH_TIDE_INNER_ROOM=true,
 EM_SHOAL_CAVE_LOW_TIDE_ENTRANCE_ROOM=true,EM_MARINE_CAVE_END=true,EM_TERRA_CAVE_END=true,
 EM_ARTISAN_CAVE_B1F=true,EM_SKY_PILLAR_ENTRANCE=true}
local function cfg()return V.require('DioramaConfig').terrain.emCaveTerraces end
local function solid(c)return c and(c.coll==7 or c.coll==255)end
local function stair(m)return m==0x204 end
local function jump(c)return c and c.coll>=0xa0 and c.coll<=0xa7 end
function R.profile(d)return d and cfg().enabled and names[d.id]and d.pair=='general__cave'and tonumber(d.mapType)==4 end
function R.active(d)return R.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
function R.plan(d)
 local L=d.midLayout;local stamp=V.require('WorldGeometry').layoutStamp(L);local p=R.cache[L]
 if p and p.stamp==stamp then return p end
 p={stamp=stamp,level={},stairs={},top={},base={},objectMask={}}
 local components,groups={},{}
 local function index(x,y)if x>=0 and y>=0 and x<L.width and y<L.height then return y*L.width+x+1 end end
 local function walk(x,y)local k=index(x,y);if not k then return end;local c=L:cellAt(x,y);return not solid(c)and not jump(c)and not stair(c.mid)and c end
 for y=0,L.height-1 do for x=0,L.width-1 do local k=index(x,y);local start=walk(x,y)
  if start and not components[k]then
   local id=#groups+1;local g={cells={k},edges={},minimum=0};groups[id]=g;components[k]=id
   local queue={{x,y}};local at=1
   while at<=#queue do local a=queue[at]
    for _,v in ipairs(dirs)do local nx,ny=a[1]+v[1],a[2]+v[2];local nk=index(nx,ny);local c=walk(nx,ny)
     if c and c.elev==start.elev and not components[nk]then components[nk]=id;g.cells[#g.cells+1]=nk;queue[#queue+1]={nx,ny}end
    end;at=at+1
   end
  end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do if stair(L:midAt(x,y))and not stair(L:midAt(x,y-1))then
  local last=y;while last+1<L.height and stair(L:midAt(x,last+1))do last=last+1 end
  local n,b=components[index(x,y-1)],components[index(x,last+1)];local count=last-y+1
  assert(n,'native cave stair has no north landing '..d.id..':'..x..','..y)
  assert(n~=b,'native cave stair connects the same floor '..d.id)
  if b then groups[n].edges[#groups[n].edges+1]={b,-count};groups[b].edges[#groups[b].edges+1]={n,count}
  else groups[n].minimum=math.max(groups[n].minimum,count)end
  for row=y,last do p.stairs[index(x,row)]={north=index(x,y-1),south=b and index(x,last+1),offset=row-y,count=count}end
 end end end
 local visited={}
 for id,g in ipairs(groups)do if not visited[id]then
  local queue={id};local values={[id]=0};visited[id]=true;local at,lowest=1,-g.minimum
  while at<=#queue do local n=queue[at]
   for _,e in ipairs(groups[n].edges)do local v=values[n]+e[2]
    if values[e[1]]~=nil then assert(values[e[1]]==v,'inconsistent native cave stair cycle '..d.id)
    else values[e[1]]=v;lowest=math.min(lowest,v-groups[e[1]].minimum);visited[e[1]]=true;queue[#queue+1]=e[1]end
   end;at=at+1
  end
  for _,n in ipairs(queue)do for _,k in ipairs(groups[n].cells)do p.level[k]=values[n]-lowest end end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do local k=index(x,y);local lo,hi=math.huge,0
  for _,v in ipairs(dirs)do local nk=index(x+v[1],y+v[2]);local n=nk and p.level[nk]
   if n then lo=math.min(lo,n);hi=math.max(hi,n)end
  end
  p.base[k]=(jump(L:cellAt(x,y))and hi or lo<math.huge and lo or 0)*cfg().platformHeight
  p.top[k]=hi>0 and hi*cfg().platformHeight or V.require('DioramaConfig').terrain.caveWallHeight
 end end
 p.objects=V.require('EmeraldCaveObjects').plan(d);p.stalagmites=V.require('EmeraldCaveStalagmites').plan(d)
 for _,plan in ipairs{p.objects,p.stalagmites}do for k,o in pairs(plan.mask)do p.objectMask[k]=o end end
 for _,plan in ipairs{p.objects,p.stalagmites}do for _,o in ipairs(plan.objects)do if o.kind=='rock'then
  local high=0
  for row=o.y,o.y+(o.h or 1)-1 do local k=row*L.width+o.x+1;high=math.max(high,o.base>0 and p.top[k]or p.base[k])end
  for row=o.y,o.y+(o.h or 1)-1 do local k=row*L.width+o.x+1;if o.base>0 then p.top[k]=high else p.base[k]=high end end
 end end end
 for _,o in ipairs(p.objects.objects)do if o.kind=='ladder'and o.h==2 then
  local k=o.y*L.width+o.x+1;local foot=k+L.width
  local base=p.level[foot]and p.level[foot]*cfg().platformHeight or p.base[foot]
  p.base[k]=base;p.top[k]=math.max(p.top[k],base+V.require('DioramaConfig').terrain.caveWallHeight)
 end end
 p.cells=V.require('Terrain').plan(d,{})
 R.cache[L]=p;return p
end
function R.floorHeight(d,x,z,p)
 p=p or R.plan(d);local L=d.midLayout;local cx,cy=math.floor(x/16),math.floor(z/16)
 if cx<0 or cy<0 or cx>=L.width or cy>=L.height then return 0 end
 local k=cy*L.width+cx+1;local run=p.stairs[k]
 if run then return((p.level[run.north]or 0)-run.offset-math.floor(z%16/16*cfg().stairSteps)/cfg().stairSteps)*cfg().platformHeight end
 return p.level[k]and p.level[k]*cfg().platformHeight or p.base[k]or 0
end
function R.actorHeight(d,x,z)if R.active(d)then return R.floorHeight(d,x+8,z+15.99)end end
local function wall(d,x,y,p)
 local k=y*d.midLayout.width+x+1;local o=p.objectMask[k]
 if o then return o.kind=='rock'and o.base>0 or o.kind=='ladder'and o.h==2 and y==o.y end
 return p.cells[k]=='wall'
end
local function material(d,x,y,p)
 local o=p.objectMask[y*d.midLayout.width+x+1]
 return o and(o.kind=='rock'and o.floor or y==o.y and o.h==2 and o.wall or o.floor)
  or V.require('EmeraldCaveObjects').donor(d,x,y)or d.midLayout:midAt(x,y)
end
local function polygon(d,ts,x,y,p)
 return V.require('EmeraldCaveContours').polygon(ts,material(d,x,y,p))
end
function R.surfaceHeight(d,ts,x,z,p)
 p=p or R.plan(d);local L=d.midLayout;local cx,cy=math.floor(x/16),math.floor(z/16)
 if cx<0 or cy<0 or cx>=L.width or cy>=L.height then return 0 end
 local k=cy*L.width+cx+1
 if wall(d,cx,cy,p)and V.require('EmeraldCaveContours').contains(polygon(d,ts,cx,cy,p),x%16,z%16)then return p.top[k]end
 return R.floorHeight(d,x,z,p)
end
-- A foreground wall can be lowered by the camera cutaway. Retain the hidden
-- side of an adjoining terrace down to the lowest cut, so that revealing the
-- terrace does not reveal an unmeshed black slot behind the removed rock.
local function neighborHeight(d,ts,x,z,p,cuttable)
 local high=R.surfaceHeight(d,ts,x,z,p)
 if not cuttable then
  local L=d.midLayout;local cx,cy=math.floor(x/16),math.floor(z/16)
  if cx>=0 and cy>=0 and cx<L.width and cy<L.height then
   local k=cy*L.width+cx+1;local terrain=V.require('DioramaConfig').terrain
   if wall(d,cx,cy,p)and p.base[k]==0 and p.top[k]==terrain.caveWallHeight then
    high=math.min(high,terrain.caveCutaway.height)
   end
  end
 end
 return high
end
function R.floor(out,d,ts,x,y,ox,oz)
 if not R.active(d)then return false end
 local p=R.plan(d);local L=d.midLayout;local k=y*L.width+x+1
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 local h=R.floorHeight(d,x*16,y*16,p);local m=material(d,x,y,p)
 local function side(ax,az,bx,bz,high,low,donor,u0,u1,v0,v1)
  if high<=low then return end
  G.quad(out,{ax,high,az},{bx,high,bz},{bx,low,bz},{ax,low,az},G.uv(ts,donor or 0x219,u0 or 0,v0 or 0,u1 or 16,v1 or 16,.5),cfg().sideShade)
 end
 if wall(d,x,y,p)then
  local E=V.require('EmeraldCaveContours');local poly=polygon(d,ts,x,y,p);local top=p.top[k]
  local cuttable=h==0 and top==V.require('DioramaConfig').terrain.caveWallHeight
  local portal=V.require('EmeraldCavePortals').at(d,x,y)
  local inscription=E.inscription(d,x,y)
  local cap=portal and portal.cap or inscription and inscription.cap or m
  local slot=assert(ts.midToSlot[cap]);local tw,th=ts.image:getDimensions();local ax,ay=slot%ts.cols*16,math.floor(slot/ts.cols)*16
  local trimmed=#poly~=4 or poly[1][1]~=0 or poly[1][2]~=0 or poly[2][1]~=16 or poly[2][2]~=0 or poly[3][1]~=16 or poly[3][2]~=16 or poly[4][1]~=0 or poly[4][2]~=16
  if trimmed then
   G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m,0,0,16,16,.5),1)
  end
  local first=#out+1
  local function vertex(a)return{xx+a[1],top,zz+a[2],(ax+math.max(.5,math.min(15.5,a[1])))/tw,(ay+math.max(.5,math.min(15.5,a[2])))/th,1,0,0,0}end
  if h~=top or not trimmed then
   for i=2,#poly-1 do for _,a in ipairs{poly[1],poly[i],poly[i+1],poly[1],poly[i+1],poly[i+1]}do out[#out+1]=vertex(a)end end
  end
  for i,a in ipairs(poly)do local b=poly[i%#poly+1];local dx,dz=b[1]-a[1],b[2]-a[2];local len=math.sqrt(dx*dx+dz*dz);local count=math.ceil(len);local n=0
   local function lower(j)local t=(j+.5)/count;return neighborHeight(d,ts,x*16+a[1]+dx*t+dz/len*.01,y*16+a[2]+dz*t-dx/len*.01,p,cuttable)end
   while n<count do local low=lower(n);local start=n;repeat n=n+1 until n==count or lower(n)~=low
    local sx,sz=xx+a[1]+dx*start/count,zz+a[2]+dz*start/count
    local ex,ez=xx+a[1]+dx*n/count,zz+a[2]+dz*n/count
    local donor=V.require('EmeraldCaveMaterials').side(d,m)or 0x219
    if a[2]==16 and b[2]==16 and(portal or inscription)then
     donor=portal and portal.upper or inscription.front
     side(ex,ez,sx,sz,top,low,donor,ex-xx,sx-xx)
    else side(sx,sz,ex,ez,top,low,donor,0,math.min(16,len*(n-start)/count))end
   end
  end
  if cuttable then for i=first,#out do out[i][9]=-2 end end
  -- A clipped wall can have raised walkable background outside its rock
  -- contour. That background needs its own closed perimeter as well.
  for _,v in ipairs(dirs)do for t=0,15 do
   local sx=v[1]~=0 and(v[1]>0 and 15.99 or .01)or t+.5
   local sy=v[2]~=0 and(v[2]>0 and 15.99 or .01)or t+.5
   if not E.contains(poly,sx,sy)then
    local low=neighborHeight(d,ts,x*16+sx+v[1]*.02,y*16+sy+v[2]*.02,p,false)
    if v[1]==0 then local z=zz+(v[2]>0 and 16 or 0);side(xx+t,z,xx+t+1,z,h,low,0x219,t,t+1)
    else local px=xx+(v[1]>0 and 16 or 0);side(px,zz+t,px,zz+t+1,h,low,0x219,t,t+1)end
   end
  end end
 else
  local run=p.stairs[k]
  if run then
   for row=0,15 do local high=R.floorHeight(d,x*16,y*16+row,p)
    G.quad(out,{xx,high,zz+row},{xx+16,high,zz+row},{xx+16,high,zz+row+1},{xx,high,zz+row+1},G.uv(ts,m,0,row,16,row+1,.5),1)
    local low=R.floorHeight(d,x*16,y*16+row+1,p)
    if row<15 then side(xx,zz+row+1,xx+16,zz+row+1,high,low,0x204,0,16,row,row+1)end
   end
  else
   if jump(L:cellAt(x,y))then
    local vv={};V.require('CaveTerrain').ledge(vv,d,ts,x,y,ox,oz)
    for _,v in ipairs(vv)do v[2]=v[2]+h;out[#out+1]=v end
   else G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m,0,0,16,16,.5),V.data('Shapes').water(L:cellAt(x,y))and G.WATER or 1)end
  end
  -- Close raised floors and stair ends against their actual adjacent height.
  -- Merge equal-height runs instead of emitting sixteen separate coplanar
  -- faces along every tile. UVs still follow the same native edge pixels.
  for _,v in ipairs(dirs)do
   local function heights(t)
    local sx=v[1]~=0 and(v[1]>0 and 15 or 0)or t;local sy=v[2]~=0 and(v[2]>0 and 15 or 0)or t
    local high=R.floorHeight(d,x*16+sx,y*16+sy,p)
    -- Sample just across the shared edge, not one pixel into the neighbour:
    -- a clipped native corner can change height within that last pixel.
    local nx=x*16+sx+(v[1]>0 and 1 or v[1]==0 and .5 or 0)+v[1]*.01
    local nz=y*16+sy+(v[2]>0 and 1 or v[2]==0 and .5 or 0)+v[2]*.01
    return high,neighborHeight(d,ts,nx,nz,p,false)
   end
   local t=0
   while t<16 do
    local high,low=heights(t);local start=t;t=t+1
    while t<16 do local h2,l2=heights(t);if h2~=high or l2~=low then break end;t=t+1 end
    if v[1]==0 then local z=zz+(v[2]>0 and 16 or 0);side(xx+start,z,xx+t,z,high,low,0x219,start,t)
    else local px=xx+(v[1]>0 and 16 or 0);side(px,zz+start,px,zz+t,high,low,0x219,start,t)end
   end
  end
 end
 return true
end
function R.objects(out,d,ts,ox,oz,contacts)
 if not R.active(d)then return end
 local p=R.plan(d);local L=d.midLayout
 for _,entry in ipairs{{p.objects,'EmeraldCaveObjects'},{p.stalagmites,'EmeraldCaveStalagmites'}}do
  for _,o in ipairs(entry[1].objects)do
   local vv,cc={},{};V.require(entry[2]).build(vv,d,ts,ox,oz,cc,{objects={o}})
   local k=o.y*L.width+o.x+1
   local base=o.kind=='rock'and(o.base>0 and p.top[k]or p.base[k])or R.floorHeight(d,o.x*16,(o.y+o.h-1)*16,p)
   for _,v in ipairs(vv)do
    if o.kind=='ladder'then
     local height=V.require('DioramaConfig').terrain.caveWallHeight
     local rise=o.h==1 and height or p.top[k]-base
     assert(rise>0,'native ascent ladder lost its vertical span')
     v[2]=base+v[2]/height*rise
    else v[2]=v[2]+base-o.base end
    if base>0 then v[9]=0 end;out[#out+1]=v
   end
   for _,c in ipairs(cc)do c[6]=base;contacts[#contacts+1]=c end
  end
 end
end
function R.lighting(d,result)
 if not R.active(d)then return end
 for _,l in ipairs(result.lights or{})do if l.kind~='crystal'then l.y=l.y+R.floorHeight(d,l.x,l.z)end end
 for _,s in ipairs(result.sprites or{})do if s.kind~='crystalGlow'then s.y=s.y+R.floorHeight(d,s.x,s.z)end end
 for _,s in ipairs(result.shafts or{})do s.y=R.floorHeight(d,s.x,s.z)end
end
function R.rockHeight(d,x,z)if R.active(d)then local p=R.plan(d);local L=d.midLayout;local cx,cy=math.floor(x/16),math.floor(z/16);return wall(d,cx,cy,p)and p.top[cy*L.width+cx+1]or R.floorHeight(d,x,z,p)end end
return R
