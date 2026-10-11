-- Native Magma Hideout architecture. All heights and masks are presentation
-- data; native elevation, collision, objects, scripts and warps are read-only.
local V=...;local M={cache=setmetatable({},{__mode='k'}),art=setmetatable({},{__mode='k'})}
local dirs={{1,0},{-1,0},{0,1},{0,-1}}
local function cfg()return V.require('DioramaConfig').terrain.emMagmaHideout end
local names={EM_MAGMA_HIDEOUT_1F=true,EM_MAGMA_HIDEOUT_2F_1R=true,EM_MAGMA_HIDEOUT_2F_2R=true,EM_MAGMA_HIDEOUT_2F_3R=true,EM_MAGMA_HIDEOUT_3F_1R=true,EM_MAGMA_HIDEOUT_3F_2R=true,EM_MAGMA_HIDEOUT_3F_3R=true,EM_MAGMA_HIDEOUT_4F=true}
function M.profile(d)return d and cfg().enabled and names[d.id]and d.pair=='general__lavaridge'and tonumber(d.mapType)==4 end
function M.active(d)return M.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
local function stair(m)return m==0x2af or m==0xaf or m==0xcf end
local function solid(c)return c and(c.coll==7 or c.coll==255)end
local function lava(m)return m==0x2bd or m==0x21c or m==0x333 end
local lavaEdges={[0x213]=true,[0x214]=true,[0x215]=true,[0x21b]=true,[0x21d]=true,[0x31e]=true,[0x32a]=true,[0x32b]=true,[0x32c]=true,[0x332]=true,[0x334]=true,[0x289]=true,[0x33a]=true,[0x33b]=true,[0x33c]=true,[0x3a3]=true}
local starts={[0x358]={2,2,0x308},[0x35a]={2,2,0x3a2},[0x365]={2,2,0x3a2},[0x392]={2,2,0x3a2},[0x394]={2,2,0x3a2},[0x35c]={1,2,0x3a2},[0x36d]={2,3,0x308},[0x380]={2,3,0x308},[0x382]={2,3,0x3a2},[0x384]={2,3,0x3a2},[0x386]={2,3,0x3a2},[0x368]={7,3,0x308}}
local machine={};for m=0x358,0x39d do machine[m]=true end;machine[0x3a8]=true;machine[0x3a9]=true
function M.kind(d,c)
 if not M.active(d)or not c then return end
 if c.mid==0x256 then return'emMagmaWall'end -- upper arch, even on a passable native entrance
 if c.mid==0x308 or c.mid==0x310 or c.mid==0x311 or c.mid==0x3a2 then return end -- blocked floor is still floor art
 if not solid(c)or lava(c.mid)or machine[c.mid]or c.mid==0x20e then return end
 return'emMagmaWall'
end
function M.height()return cfg().wallHeight end
function M.plan(d)
 local L=d.midLayout;local stamp=V.require('WorldGeometry').layoutStamp(L);local p=M.cache[L]
 if p and p.stamp==stamp then return p end
 p={stamp=stamp,level={},stairs={},base={},top={},mask={},objects={},floorSites={},lavaSites={}}
 local function index(x,y)if x>=0 and y>=0 and x<L.width and y<L.height then return y*L.width+x+1 end end
 local components,groups={},{}
 local function walk(x,y)local k=index(x,y);if not k then return end;local c=L:cellAt(x,y);return not solid(c)and not stair(c.mid)and c end
 for y=0,L.height-1 do for x=0,L.width-1 do local k=index(x,y);local c=walk(x,y)
  if c and not components[k]then
   local n=#groups+1;local g={cells={k},edges={}};groups[n]=g;components[k]=n;local q={{x,y}};local at=1
   while q[at]do local a=q[at];at=at+1
    for _,v in ipairs(dirs)do local nx,ny=a[1]+v[1],a[2]+v[2];local nk=index(nx,ny);local other=walk(nx,ny)
     if other and other.elev==c.elev and not components[nk]then components[nk]=n;g.cells[#g.cells+1]=nk;q[#q+1]={nx,ny}end
    end
   end
  end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do if stair(L:midAt(x,y))and not stair(L:midAt(x,y-1))then
  local last=y;while last+1<L.height and stair(L:midAt(x,last+1))do last=last+1 end
  local a,b=components[index(x,y-1)],components[index(x,last+1)];local count=last-y+1
  assert(a and b and a~=b,'Magma stairs require two distinct native landings '..d.id..':'..x..','..y)
  groups[a].edges[#groups[a].edges+1]={b,-count};groups[b].edges[#groups[b].edges+1]={a,count}
  for row=y,last do p.stairs[index(x,row)]={north=index(x,y-1),offset=row-y,count=count}end
 end end end
 local seen={}
 for n,g in ipairs(groups)do if not seen[n]then
  local q={n};local values={[n]=0};seen[n]=true;local at,low=1,0
  while q[at]do local a=q[at];at=at+1
   for _,edge in ipairs(groups[a].edges)do local value=values[a]+edge[2]
    if values[edge[1]]~=nil then assert(values[edge[1]]==value,'Magma stair cycle mismatch')
    else values[edge[1]]=value;low=math.min(low,value);seen[edge[1]]=true;q[#q+1]=edge[1]end
   end
  end
  for _,a in ipairs(q)do for _,k in ipairs(groups[a].cells)do p.level[k]=(values[a]-low)*cfg().platformHeight end end
 end end
 -- Native elevation zero is a wildcard on door/exit cells, not a floor
 -- seventy pixels below its adjoining landing. Resolve these small portal
 -- components from the nearest real walkable floor before extending rock.
 for y=0,L.height-1 do for x=0,L.width-1 do local c=L:cellAt(x,y);local k=index(x,y)
  if p.level[k]and c.elev==0 and c.mid~=0x271 and c.coll~=0x2b then
   local queue={{x,y}};local seen={[k]=true};local at=1;local found
   while queue[at]and not found do local a=queue[at];at=at+1
    for _,v in ipairs(dirs)do local nx,ny=a[1]+v[1],a[2]+v[2];local nk=index(nx,ny)
     if nk and not seen[nk]then local n=L:cellAt(nx,ny);seen[nk]=true
      if p.level[nk]and n.coll==0x2b then found=p.level[nk];break
      elseif not solid(n)and not stair(n.mid)then queue[#queue+1]={nx,ny}end
     end
    end
   end
   if found then p.level[k]=found end
  end
 end end
 -- Extend the closest authored floor height into supporting rock. Shared
 -- boundaries close to the sampled neighbor height, including raised tiers.
 local q={};local distance={}
 for y=0,L.height-1 do for x=0,L.width-1 do local k=index(x,y)
  if p.level[k]then p.base[k]=p.level[k];distance[k]=0;q[#q+1]={x,y};if L:cellAt(x,y).coll==0x2b then p.floorSites[#p.floorSites+1]={x=x*16+8,z=y*16+8,y=p.level[k]}end
  end
  if lava(L:midAt(x,y))then p.lavaSites[#p.lavaSites+1]={x=x*16+8,z=y*16+8,y=0}end
 end end
 local at=1;while q[at]do local a=q[at];at=at+1;local k=index(a[1],a[2])
  for _,v in ipairs(dirs)do local x,y=a[1]+v[1],a[2]+v[2];local nk=index(x,y)
   if nk and not distance[nk]then distance[nk]=distance[k]+1;p.base[nk]=p.base[k];q[#q+1]={x,y}end
  end
 end
 for k=1,L.width*L.height do p.base[k]=p.base[k]or 0;p.top[k]=p.base[k]+cfg().wallHeight end
 -- Each contiguous pool shares one level near its own native landing.
 -- An upper basin must not drop to world zero behind a tall artificial rim.
 p.lavaLevel={};local poolSeen={}
 for y=0,L.height-1 do for x=0,L.width-1 do local first=index(x,y);local m=L:midAt(x,y)
  if(lava(m)or lavaEdges[m])and not poolSeen[first]then
   local queue={{x,y}};local cells={};poolSeen[first]=true;local at,level=1,math.huge
   while queue[at]do local a=queue[at];at=at+1;local k=index(a[1],a[2]);cells[#cells+1]=k;level=math.min(level,p.base[k])
    for _,v in ipairs(dirs)do local xx,yy=a[1]+v[1],a[2]+v[2];local nk=index(xx,yy)
     if nk and not poolSeen[nk]then local m=L:midAt(xx,yy);if lava(m)or lavaEdges[m]then poolSeen[nk]=true;queue[#queue+1]={xx,yy}end end
    end
   end
   for _,k in ipairs(cells)do p.lavaLevel[k]=level;p.top[k]=level+cfg().lavaRimHeight;p.base[k]=math.min(p.base[k],p.top[k])end
  end
 end end
 for _,s in ipairs(p.lavaSites)do s.y=p.lavaLevel[math.floor(s.z/16)*L.width+math.floor(s.x/16)+1]or 0 end
 -- A retaining wall between authored stair landings ends at the upper
 -- landing. Adding a full cave wall on top hid nearby trainers behind an
 -- invented parapet. Scan bounded solid runs in both map axes; perimeter
 -- rock with no landing on both sides retains its normal wall height.
 p.terrace={}
 for _,axis in ipairs{{1,0},{0,1}}do
  for y=0,L.height-1 do for x=0,L.width-1 do local k=index(x,y)
   if M.kind(d,L:cellAt(x,y))then
    local prev=index(x-axis[1],y-axis[2]);local high=prev and p.level[prev]
    if high and not M.kind(d,L:cellAt(x-axis[1],y-axis[2]))then
     local run={};local xx,yy=x,y
     while index(xx,yy)and M.kind(d,L:cellAt(xx,yy))do run[#run+1]=index(xx,yy);xx,yy=xx+axis[1],yy+axis[2]end
     local last=index(xx,yy);local low=last and p.level[last]
     if low and low~=high then for _,key in ipairs(run)do if not p.lavaLevel[key]then
      local top=math.max(high,low);p.terrace[key]=math.max(p.terrace[key]or 0,top);p.top[key]=p.terrace[key]
     end end end
    end
   end
  end end
 end
 for k in pairs(p.terrace)do p.base[k]=math.min(p.base[k],p.top[k])end
 -- The machines have bounded native frames. Adjacent machines never fuse.
 for y=0,L.height-1 do for x=0,L.width-1 do local k=index(x,y);local spec=starts[L:midAt(x,y)]
  if spec and not p.mask[k]then
   local w,h,donor=unpack(spec)
   -- Short cabinet variants have their lower metal band in the second row.
   if (L:midAt(x,y)==0x384)and L:midAt(x,y+2)~=0x37d and L:midAt(x,y+2)~=0x3a8 then h=2 end
   local o={x=x,y=y,w=w*16,h=h*16,donor=donor,base=p.base[index(x,y+h)]or p.base[k]}
   p.objects[#p.objects+1]=o
   for yy=y,y+h-1 do for xx=x,x+w-1 do local key=index(xx,yy);assert(key and machine[L:midAt(xx,yy)],'incomplete native Magma machine '..d.id..':'..x..','..y);assert(not p.mask[key],'overlapping machine');p.mask[key]=o;p.base[key]=o.base end end
  end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do if machine[L:midAt(x,y)]then assert(p.mask[index(x,y)],'unowned Magma machine tile '..d.id..':'..x..','..y)end end end
 M.cache[L]=p;return p
end
function M.floorHeight(d,x,z,p)
 p=p or M.plan(d);local L=d.midLayout;local cx,cy=math.floor(x/16),math.floor(z/16)
 if cx<0 or cy<0 or cx>=L.width or cy>=L.height then local bx=math.max(0,math.min(L.width-1,cx));local by=math.max(0,math.min(L.height-1,cy));return p.base[by*L.width+bx+1]or 0 end
 local k=cy*L.width+cx+1;local run=p.stairs[k]
 if run then return p.level[run.north]-(run.offset+math.floor(z%16/16*cfg().stairSteps)/cfg().stairSteps)*cfg().platformHeight end
 return p.lavaLevel[k]or p.level[k]or p.base[k]or 0
end
function M.actorHeight(d,x,z)if M.active(d)then return M.floorHeight(d,x+8,z+15.99)end end
-- These native edge tiles include walkable ash outside their curved rock.
local aliases={[0x323]=0x274,[0x32d]=0x274,[0x331]=0x307,[0x347]=0x274,[0x34d]=0x307}
local edgeCache=setmetatable({},{__mode='k'})
function M.polygon(ts,m)
 if not lavaEdges[m]then return V.require('EmeraldFieryPath').polygon(ts,aliases[m]or m,cfg().edgePadding)end
 local cache=edgeCache[ts];if not cache then cache={};edgeCache[ts]=cache end;if cache[m]then return cache[m]end
 -- These mixed native metatiles contain both orange lava and red rock.
 -- Only the rock footprint is lifted; the original pool remains at zero.
 local points,seen={},{}
 local function add(x,y)local k=y*17+x;if not seen[k]then seen[k]=true;points[#points+1]={x,y}end end
 for y=0,15 do for x=0,15 do local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y)
  if not(r>.65 and b<.12)then add(x,y);add(x+1,y);add(x,y+1);add(x+1,y+1)end
 end end
 local function cross(a,b,c)return(b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])end
 table.sort(points,function(a,b)return a[1]==b[1]and a[2]<b[2]or a[1]<b[1]end)
 local lo,hi={},{};for _,p in ipairs(points)do while #lo>=2 and cross(lo[#lo-1],lo[#lo],p)<=0 do lo[#lo]=nil end;lo[#lo+1]=p end
 for i=#points,1,-1 do local p=points[i];while #hi>=2 and cross(hi[#hi-1],hi[#hi],p)<=0 do hi[#hi]=nil end;hi[#hi+1]=p end
 local poly={};for i=1,#lo-1 do poly[#poly+1]=lo[i]end;for i=1,#hi-1 do poly[#poly+1]=hi[i]end
 assert(#poly>=3,'missing mixed lava rock contour');cache[m]=poly;return poly
end
local function contains(poly,x,y)return V.require('EmeraldCaveContours').contains(poly,x,y)end
function M.surface(d,ts,x,z,p)
 local L=d.midLayout;local cx,cy=math.floor(x/16),math.floor(z/16);local c=L:cellAt(cx,cy);local k=cx>=0 and cy>=0 and cx<L.width and cy<L.height and cy*L.width+cx+1 or nil
 if M.kind(d,c)and contains(M.polygon(ts,c.mid),x%16,z%16)then local bk=k or math.max(0,math.min(L.height-1,cy))*L.width+math.max(0,math.min(L.width-1,cx))+1;return p.top[bk]or cfg().wallHeight end
 return M.floorHeight(d,x,z,p)
end
function M.floor(out,d,ts,x,y,ox,oz)
 if not M.active(d)then return false end
 local p=M.plan(d);local L=d.midLayout;local k=x>=0 and y>=0 and x<L.width and y<L.height and y*L.width+x+1 or nil;local c=L:cellAt(x,y);local m=c.mid;local G=V.require('WorldGeometry');local C=cfg();local xx,zz=(x+ox)*16,(y+oz)*16
 local h=M.floorHeight(d,x*16,y*16,p);local object=p.mask[k];if object then m=c.mid==0x35c and 0x2bd or object.donor;h=c.mid==0x35c and 0 or object.base end
 local first=#out+1;local cuttable=M.kind(d,c)and not object
 local function side(ax,az,bx,bz,high,low,donor,u0,u1,v0,v1)
  if high<=low+.001 then return end
  G.quad(out,{ax,high,az},{bx,high,bz},{bx,low,bz},{ax,low,az},G.uv(ts,donor or 0x274,u0 or 0,v0 or 0,u1 or 16,v1 or 16,.02),C.sideShade)
 end
 if cuttable then
  local poly=M.polygon(ts,m);local bk=k or math.max(0,math.min(L.height-1,y))*L.width+math.max(0,math.min(L.width-1,x))+1;local top=p.top[bk]or C.wallHeight
  local portal=m==0x256;local exit=m==0x20d or m==0x20f
  local cap=(portal or exit or p.terrace[k])and 0x271 or m
  local slot=assert(ts.midToSlot[cap]);local tw,th=ts.image:getDimensions();local ax,ay=slot%ts.cols*16,math.floor(slot/ts.cols)*16
  local trimmed=#poly~=4 or poly[1][1]~=0 or poly[1][2]~=0 or poly[2][1]~=16 or poly[2][2]~=0 or poly[3][1]~=16 or poly[3][2]~=16 or poly[4][1]~=0 or poly[4][2]~=16
  if trimmed then G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m),lavaEdges[m]and G.MAGMA_LAVA or 1)end
  local function vertex(a)return{xx+a[1],top,zz+a[2],(ax+math.max(.5,math.min(15.5,a[1])))/tw,(ay+math.max(.5,math.min(15.5,a[2])))/th,1,0,0,-2}end
  for i=2,#poly-1 do for _,a in ipairs{poly[1],poly[i],poly[i+1],poly[1],poly[i+1],poly[i+1]}do out[#out+1]=vertex(a)end end
  for i,a in ipairs(poly)do local b=poly[i%#poly+1];local dx,dz=b[1]-a[1],b[2]-a[2];local len=math.sqrt(dx*dx+dz*dz);local count=math.ceil(len);local n=0
   local function low(j)local t=(j+.5)/count;return M.surface(d,ts,x*16+a[1]+dx*t+dz/len*.05,y*16+a[2]+dz*t-dx/len*.05,p)end
   while n<count do local lo=low(n);local start=n;repeat n=n+1 until n==count or math.abs(low(n)-lo)>.001
    local sx,sz=xx+a[1]+dx*start/count,zz+a[2]+dz*start/count;local ex,ez=xx+a[1]+dx*n/count,zz+a[2]+dz*n/count
    if portal and a[2]==16 and b[2]==16 then side(ex,ez,sx,sz,top,lo,m,ex-xx,sx-xx)
    elseif exit and a[2]==0 and b[2]==0 then side(sx,sz,ex,ez,top,lo,m,sx-xx,ex-xx)
    else side(sx,sz,ex,ez,top,lo,0x274,0,math.min(16,len*(n-start)/count))end
   end
  end
  for i=first,#out do out[i][9]=-2 end
 else
  if p.stairs[k]then
   for row=0,15 do local high=M.floorHeight(d,x*16,y*16+row,p);local low=M.floorHeight(d,x*16,y*16+row+1,p)
    G.quad(out,{xx,high,zz+row},{xx+16,high,zz+row},{xx+16,high,zz+row+1},{xx,high,zz+row+1},G.uv(ts,m,0,row,16,row+1,.02),1)
    side(xx,zz+row+1,xx+16,zz+row+1,high,low,m,0,16,row,row+1)
   end
  elseif (m==0x309 or m==0x208)and L:midAt(x,y+1)==0x20e then
   local a,b=C.exitThresholdOffset,C.exitThresholdOffset+C.exitThresholdDepth
   G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+a},{xx,h,zz+a},G.uv(ts,m,0,0,16,a,.02),1)
   G.quad(out,{xx,h,zz+a},{xx+16,h,zz+a},{xx+16,h,zz+b},{xx,h,zz+b},G.uv(ts,0x20e,0,0,16,C.exitThresholdDepth,.02),1)
   G.quad(out,{xx,h,zz+b},{xx+16,h,zz+b},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m,0,b,16,16,.02),1)
  else G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m),lava(m)and G.MAGMA_LAVA or 1)end
 end
 -- Close every supporting floor perimeter, including partial rock backgrounds
 -- and machine footprints. Hidden faces remain below an opaque player cut.
 if h>0 or k and p.stairs[k]then
 for _,v in ipairs(dirs)do
  local function heights(t)
   local sx=v[1]~=0 and(v[1]>0 and 15.99 or .01)or t+.5;local sy=v[2]~=0 and(v[2]>0 and 15.99 or .01)or t+.5
   local high=object and object.base or M.floorHeight(d,x*16+sx,y*16+sy,p)
   local nx,nz=x*16+sx+v[1]*.02,y*16+sy+v[2]*.02;local low=M.surface(d,ts,nx,nz,p)
   if M.kind(d,L:cellAt(math.floor(nx/16),math.floor(nz/16)))then low=math.min(low,C.cutFloor)end
   return high,low
  end
  local t=0;while t<16 do local high,low=heights(t);local start=t;t=t+1
   while t<16 do local nh,nl=heights(t);if math.abs(nh-high)>.001 or math.abs(nl-low)>.001 then break end;t=t+1 end
   if v[1]==0 then local z=zz+(v[2]>0 and 16 or 0);side(xx+start,z,xx+t,z,high,low,0x274,start,t)
   else local px=xx+(v[1]>0 and 16 or 0);side(px,zz+start,px,zz+t,high,low,0x274,start,t)end
  end
 end
 end
 return true
end
function M.machineMask(d,ts,o)
 local key=o.x..':'..o.y..':'..o.w..':'..o.h;local stamp=V.require('WorldGeometry').layoutStamp(d.midLayout);local cache=M.art[d.midLayout];if not cache or cache.stamp~=stamp then cache={stamp=stamp};M.art[d.midLayout]=cache end;if cache[key]then return cache[key]end
 local mask={};local pixel=V.require('BuildingMesh').pixel;local L=d.midLayout
 for y=0,o.h-1 do for x=0,o.w-1 do local m=L:midAt(o.x+math.floor(x/16),o.y+math.floor(y/16));local r,g,b=pixel(ts,m,x%16,y%16)
  -- Metal/cream/blue pixels are disjoint from this atlas's red rock palette.
  mask[y*o.w+x]=not(r>g+.04 and r>b+.08)
 end end
 cache[key]=mask;return mask
end
function M.objects(out,d,ts,ox,oz,contacts)
 if not M.active(d)then return end
 local G=V.require('WorldGeometry');local L=d.midLayout;local C=cfg()
 for _,o in ipairs(M.plan(d).objects)do local mask=M.machineMask(d,ts,o)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,function(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end,function(s,t)return mask[t*o.w+s]end,0,o.h,C.machineScale,nil,nil,.02)
  for _,v in ipairs(vv)do v[2]=v[2]+o.base;out[#out+1]=G.place(v,(o.x+ox)*16,(o.y+oz)*16+o.h)end
  contacts[#contacts+1]={(o.x+ox)*16+o.w/2,(o.y+oz)*16+o.h,o.w*.4,C.contactDepth,C.contactStrength,o.base}
 end
end
local function sources(items,count,spacing)
 local out={};if #items==0 then return out end
 local cx,cz=0,0;for _,p in ipairs(items)do cx=cx+p.x;cz=cz+p.z end;cx,cz=cx/#items,cz/#items
 for i=1,count do local best,score
  for _,p in ipairs(items)do local d=i==1 and-((p.x-cx)^2+(p.z-cz)^2)or math.huge
   if i>1 then for _,q in ipairs(out)do d=math.min(d,(p.x-q.x)^2+(p.z-q.z)^2)end end
   if not score or d>score then best,score=p,d end
  end
  if i>1 and score<spacing*spacing then break end
  out[#out+1]=best
 end
 return out
end
function M.light(d,result,time)
 if not M.active(d)then return end
 local C=cfg().lighting;local p=M.plan(d);result.ambient={unpack(C.ambient)};result.sun=0;result.shafts={};result.sprites={}
 local kept={};for _,l in ipairs(result.lights)do if l.kind=='flash'then kept[#kept+1]=l end end;result.lights=kept
 p.ceiling=p.ceiling or sources(p.floorSites,C.count,C.spacing);p.lava=p.lava or sources(p.lavaSites,C.lavaCount,C.lavaSpacing)
 for _,s in ipairs(p.ceiling)do result.lights[#result.lights+1]={x=s.x,z=s.z,y=s.y+C.height,radius=-C.radius,power=C.power,color=C.color,point=true,falloff=2,kind='magmaCeiling'}end
 for i,s in ipairs(p.lava)do result.lights[#result.lights+1]={x=s.x,z=s.z,y=s.y+C.lavaHeight,radius=-C.lavaRadius,power=C.lavaPower*(1+C.flicker*math.sin((time or 0)*C.flickerSpeed+i)),color=C.lavaColor,point=true,falloff=2,kind='magmaLava'}end
end
return M
