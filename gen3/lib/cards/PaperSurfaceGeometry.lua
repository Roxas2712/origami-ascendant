-- Card-owned, presentation-only attributes. The original mesh/cache stays intact.
-- First-order interpolated distances avoid undefined derivatives of dFdx normals.
local M={ATTRIBUTE='oasc_surface_edge',FORMAT={{'oasc_surface_edge','byte',4}}}
local packed=setmetatable({},{__mode='k'})
function M.remember(mesh,bytes)packed[mesh]=bytes end
function M.capture(mesh,tick)
 local bytes=packed[mesh];packed[mesh]=nil
 if bytes then return bytes end
 if mesh:getVertexCount()*36>32*1024*1024 then return nil end
 -- Reuse a small numeric buffer and pack 64 vertices per string. The old
 -- path allocated one 36-byte string per vertex on every native cache miss.
 local parts,values={},{};local stride=64
 local format='<'..string.rep('f',stride*9)
 for first=1,mesh:getVertexCount(),stride do
  local last=math.min(mesh:getVertexCount(),first+stride-1);local n=0
  for i=first,last do
   local x,y,z,u,v,shade,ax,az,flag=mesh:getVertex(i)
   values[n+1],values[n+2],values[n+3]=x,y,z
   values[n+4],values[n+5],values[n+6]=u,v,shade
   values[n+7],values[n+8],values[n+9]=ax,az,flag;n=n+9
   tick('capture')
  end
  parts[#parts+1]=love.data.pack('string',n==stride*9 and format or '<'..string.rep('f',n),unpack(values,1,n))
 end
 return table.concat(parts)
end
function M.fromPacked(bytes)
 assert(type(bytes)=='string'and #bytes%36==0 and #bytes<=32*1024*1024,'invalid surface vertices')
 return {getVertexCount=function()return #bytes/36 end,
  getVertex=function(_,i)return love.data.unpack('<fffffffff',bytes,(i-1)*36+1)end}
end
function M.packRows(data)
 if not data then return nil end
 local rows={}
 for i,row in ipairs(data.rows)do
  rows[i]=love.data.pack('string','<I4BBB',row.index,row[1]and 1 or 0,row[2]and 1 or 0,row[3]and 1 or 0)
 end
 return {count=data.count,packed=table.concat(rows)}
end
local function eligible(shade,flag)
 -- Folded window-bearing facades (2..3.5) are physical paper surfaces;
 -- their emissive flags must not prevent the adjoining roof from finding its fold.
 return shade>=2 and shade<3.5 or flag<.5 and shade>0 and (shade<1.7 or math.abs(shade-6)<.01)
end
function M.build(mesh,tick)
 tick=tick or function()end
 local count=mesh:getVertexCount();assert(count%3==0,'paper surface requires triangle lists')
 local triangles,buckets,lines={},{},{};local stats={vertices=count,triangles=0,creases=0,roofCreases=0,roofTriangles=0,facadeTriangles=0}
 -- Canonical rounded coordinates receive compact numeric IDs. Keeping long
 -- coordinate/edge strings for every triangle can trigger Lua string-table
 -- growth that cannot yield at a cooperative deadline.
 local points={};local nextPoint=0
 local function point(x,y,z)
  x,y,z=math.floor(x*1000+.5),math.floor(y*1000+.5),math.floor(z*1000+.5)
  local ys=points[x];if not ys then ys={};points[x]=ys end
  local zs=ys[y];if not zs then zs={};ys[y]=zs end
  local id=zs[z];if not id then nextPoint=nextPoint+1;id=nextPoint;zs[z]=id end
  return id
 end
 local function edge(t,j,k1,k2,x1,y1,z1,x2,y2,z2,oppositeY,oppositeZ)
  if k1>k2 then k1,k2=k2,k1 end
  -- Bound individual hash-table growth: a large native wall mesh can have
  -- tens of thousands of unique edges. Rehashing one monolithic table is an
  -- atomic pause that the coroutine deadline cannot interrupt. Symmetric
  -- endpoint hashes keep every shared edge in the same small partition.
  local bucket=(k1+k2)%61+1;local edges=buckets[bucket]
  if not edges then edges={};buckets[bucket]=edges end
  -- count bounds every point ID. The normal Card budget is far below
  -- 2^26 vertices; keep a collision-free fallback for standalone callers.
  local k=count<67108864 and(k1*count+k2)or(k1..'/'..k2);local e=edges[k]
  if not e then e={};edges[k]=e end
  e[#e+1]=t;t.edges[j]=e
  local qy1,qz1=math.floor(y1*1000+.5),math.floor(z1*1000+.5)
  local qy2,qz2=math.floor(y2*1000+.5),math.floor(z2*1000+.5)
  if qy1==qy2 and qz1==qz2 and x1~=x2 and(t.shade==6 or t.shade>=2 and t.shade<3.5)then
   if not e.line then
    local lk=qy1..','..qz1;local line=lines[lk]or{};lines[lk]=line
    e.line=true;e.lo=math.floor(math.min(x1,x2)*1000+.5)
    e.hi=math.floor(math.max(x1,x2)*1000+.5);e.covered=0;line[#line+1]=e
   end
   -- A nondegenerate triangle has at most one horizontal edge.
   t.sy,t.sz=oppositeY-y1,oppositeZ-z1
  end
 end
 for i=1,count,3 do
  -- Most vertices are floor tiles: reject them without allocating point tables.
  local ax,ay,az,au,av,ash,aax,aaz,af=mesh:getVertex(i)
  local bx,by,bz,bu,bv,bsh,bax,baz,bf=mesh:getVertex(i+1)
  local cx,cy,cz,cu,cv,csh,cax,caz,cf=mesh:getVertex(i+2)
  if math.max(ay,by,cy)>1 and eligible(ash,af)and eligible(bsh,bf)and eligible(csh,cf)then
   local ux,uy,uz=bx-ax,by-ay,bz-az
   local vx,vy,vz=cx-ax,cy-ay,cz-az
   local nx,ny,nz=uy*vz-uz*vy,uz*vx-ux*vz,ux*vy-uy*vx
   local area=math.sqrt(nx*nx+ny*ny+nz*nz)
   if area>1e-6 then
    local t={shade=ash,index=i,nx=nx/area,ny=ny/area,nz=nz/area,edges={}}
    triangles[#triangles+1]=t;stats.triangles=stats.triangles+1
    if ash==6 then stats.roofTriangles=stats.roofTriangles+1 elseif ash>=2 and ash<3.5 then stats.facadeTriangles=stats.facadeTriangles+1 end
    local ka,kb,kc=point(ax,ay,az),point(bx,by,bz),point(cx,cy,cz)
    edge(t,1,kb,kc,bx,by,bz,cx,cy,cz,ay,az)
    edge(t,2,kc,ka,cx,cy,cz,ax,ay,az,by,bz)
    edge(t,3,ka,kb,ax,ay,az,bx,by,bz,cy,cz)
   end
  end
  tick('scan')
 end
 local function dot(a,b)return math.abs(a.nx*b.nx+a.ny*b.ny+a.nz*b.nz)end
 local function mark(e)
  if e.crease then return end;e.crease=true;stats.creases=stats.creases+1
  for _,t in ipairs(e)do if t.shade==6 then stats.roofCreases=stats.roofCreases+1;break end end
 end
 -- Ordinary two-manifold joints: never outline a coplanar diagonal or an
 -- exposed edge. Building eaves additionally accept a continuous roof with
 -- its one-pixel apron plus one joining facade (an unambiguous T joint).
 for _,edges in pairs(buckets)do for _,e in pairs(edges)do
  if not e.line and #e==2 and dot(e[1],e[2])<.984807753 then mark(e)end
  tick('joins')
 end end
 for _,line in pairs(lines)do
  local events={}
  for _,e in ipairs(line)do
   events[#events+1]={at=e.lo,edge=e,begin=true};events[#events+1]={at=e.hi,edge=e}
   tick('joins')
  end
  table.sort(events,function(a,b)return a.at<b.at end)
  local active,refs={},{};local previous=events[1].at
  for _,event in ipairs(events)do
   local span=event.at-previous
   if span>0 then
    for i=#refs,1,-1 do refs[i]=nil end
    for e in pairs(active)do for _,t in ipairs(e)do refs[#refs+1]=t end end
    local crease=#refs==2 and dot(refs[1],refs[2])<.984807753
    if #refs==3 then
     for i=1,3 do
      local a,b,c=refs[i],refs[i%3+1],refs[(i+1)%3+1]
      if a.sy and b.sy and dot(a,b)>=.984807753 and dot(a,c)<.984807753
       and a.sy*b.sy+a.sz*b.sz<-1e-6 then crease=true end
     end
    end
    if crease then for e in pairs(active)do e.covered=e.covered+span end end
   end
   if event.begin then active[event.edge]=true else active[event.edge]=nil end
   previous=event.at;tick('joins')
  end
  for _,e in ipairs(line)do if e.covered>=e.hi-e.lo and e.hi>e.lo then mark(e)end;tick('joins')end
 end
 if stats.creases==0 then return nil,stats end
 local data={count=count,rows={}}
 for _,t in ipairs(triangles)do
  local e=t.edges
  if e[1].crease or e[2].crease or e[3].crease then
   data.rows[#data.rows+1]={index=t.index,
    e[1].crease or false,e[2].crease or false,e[3].crease or false}
  end
  tick('attributes')
 end
 return data,stats
end
-- Public LÖVE Mesh APIs only: the release host deliberately does not expose FFI.
-- Blank attributes are zero; only triangles touching a real fold need writes.
function M.upload(data,tick,own)
 local mesh=love.graphics.newMesh(M.FORMAT,data.count,'triangles','static')
 own(mesh);tick('allocate')
 local function write(row)
  for vertex=1,3 do
   local a=row[1]and (vertex==1 and 255 or 0)or 255
   local b=row[2]and (vertex==2 and 255 or 0)or 255
   local c=row[3]and (vertex==3 and 255 or 0)or 255
   mesh:setVertex(row.index+vertex-1,a,b,c,255)
  end
  tick('upload')
 end
 if data.packed then
  assert(type(data.packed)=='string'and #data.packed%7==0,'invalid surface attributes')
  local row={}
  for at=1,#data.packed,7 do
   local index,a,b,c=love.data.unpack('<I4BBB',data.packed,at)
   assert(index>=1 and index+2<=data.count and index%3==1 and a<=1 and b<=1 and c<=1,'invalid surface triangle')
   row.index,row[1],row[2],row[3]=index,a==1,b==1,c==1;write(row)
  end
 else
  for _,row in ipairs(data.rows)do write(row)end
 end
 return mesh
end
return M
