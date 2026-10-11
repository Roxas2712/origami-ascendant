-- Close a camera-only rectangular section of native rock volumes. Horizontal
-- caps are clipped in X/Z, not bent; cut sides use the native rock palette.
local V=...
local Budget=V.require('BuildBudget')
local S={}
local function area(a,b,c)return(b[1]-a[1])*(c[3]-a[3])-(b[3]-a[3])*(c[1]-a[1])end
local function copy(v)local p={};for k=1,9 do p[k]=v[k]end;return p end
local function clip(poly,axis,value,sign)
 local out={};if #poly==0 then return out end
 local a=poly[#poly];local da=(a[axis]-value)*sign
 for _,b in ipairs(poly)do local db=(b[axis]-value)*sign
  if(da>=0)~=(db>=0)then
   local t=da/(da-db);local p={};for k=1,9 do p[k]=a[k]+(b[k]-a[k])*t end
   p[axis]=value;out[#out+1]=p
  end
  if db>=0 then out[#out+1]=copy(b)end
  a,da=b,db
 end
 return out
end
function S.collect(vertices,d,ts)
 local tanoby=V.require('TanobyChambers').profile(d);local ruin=V.require('FireRedRuinCaves').profile(d);local lost=V.require('FireRedLostCave').profile(d);local diglett=V.require('FireRedDiglettCave').profile(d);local key=V.require('TanobyKey').profile(d)
 -- Lost Cave portal soffits are horizontal too, but are not solid caps.
 local lostHeight=lost and V.require('FireRedLostCave').height()
 local caps={grid={}};local G=V.require('WorldGeometry');local M=V.require('EmeraldCaveMaterials')
 -- Profiles do not change during collection. Repeated cap triangles share
 -- immutable side UVs; preserve triangle/grid ownership separately below.
 local terraced=V.require('FireRedTerracedCaves').profile(d)
 local sanctum=V.require('EmeraldNavelSanctums').profile(d)
 local passage=V.require('EmeraldNavelPassages').profile(d)
 local fixed=V.require('EmeraldMirageTower').profile(d)and 0x219
  or V.require('EmeraldSeafloorCurrents').profile(d)and 0x281
  or V.require('EmeraldFieryPath').profile(d)and 0x274
  or V.require('EmeraldRusturf').profile(d)and 0x219
  or V.require('EmeraldMagmaHideout').profile(d)and 0x274
 local sideUVs={}
 local mids={};for mid,slot in pairs(ts.midToSlot)do mids[slot]=mid end
 local tw,th=ts.image:getDimensions()
 for i=1,#vertices,3 do local a,b,c=vertices[i],vertices[i+1],vertices[i+2]
  Budget.tick()
  if a[9]==-2 and a[2]>0 and(not lost or math.abs(a[2]-lostHeight)<.001)and math.abs(a[2]-b[2])<.001 and math.abs(a[2]-c[2])<.001 and math.abs(area(a,b,c))>.001 then
   local slot=math.floor(a[5]*th/16)*ts.cols+math.floor(a[4]*tw/16)
   local mid=assert(mids[slot],'missing native cap material');local donor
   if terraced then donor=0x299
   elseif sanctum then donor=mid<0x33d and 0x219 or 0x36c
   elseif passage then donor=mid>=0x2d0 and 0x2e1 or 0x219
   elseif fixed then donor=fixed
   elseif key then donor=0x30e
   elseif lost or diglett then donor=0x299
   elseif ruin then donor=mid>=0x308 and 0x30c or 0x299
   elseif d.pair=='general__meteor_falls'then donor=0x244
   else donor=M.family(mid)or(mid>=0x2e0 and mid<=0x30e and 0x2f9)or 0x219 end
   local sideUV=sideUVs[donor]
   if not sideUV then sideUV=tanoby and G.uv(ts,0x2b9,0,0,1,1,.5)or G.uv(ts,donor,0,0,16,16,.5);sideUVs[donor]=sideUV end
   local cap={a,b,c,x0=math.min(a[1],b[1],c[1]),x1=math.max(a[1],b[1],c[1]),
    z0=math.min(a[3],b[3],c[3]),z1=math.max(a[3],b[3],c[3]),uv=sideUV}
   caps[#caps+1]=cap
   for z=math.floor(cap.z0/16),math.ceil(cap.z1/16)-1 do for x=math.floor(cap.x0/16),math.ceil(cap.x1/16)-1 do
    Budget.tick()
    local key=x..':'..z;local row=caps.grid[key]or{};caps.grid[key]=row;row[#row+1]=cap
   end end
  end
 end
 return caps
end
local function solid(caps,x,z,h)
 local p={x,0,z}
 for _,c in ipairs(caps.grid[math.floor(x/16)..':'..math.floor(z/16)]or{})do
  if c[1][2]>=h-.001 then
   local a,b,d=area(c[1],c[2],p),area(c[2],c[3],p),area(c[3],c[1],p)
   if(a>=-.001 and b>=-.001 and d>=-.001)or(a<=.001 and b<=.001 and d<=.001)then return true end
  end
 end
 return false
end
function S.build(caps,box,neighbors)
 local out={};local G=V.require('WorldGeometry');local shade=V.require('DioramaConfig').terrain.sideShade
 local h=box[5]
 local function continued(x,z,y)
  if solid(caps,x,z,y)then return true end
  for _,other in ipairs(neighbors or{})do if other~=caps and solid(other,x,z,y)then return true end end
  return false
 end
 local nearby,seen={},{}
 for z=math.floor(box[2]/16),math.ceil(box[4]/16)-1 do for x=math.floor(box[1]/16),math.ceil(box[3]/16)-1 do
  for _,cap in ipairs(caps.grid[x..':'..z]or{})do if not seen[cap]then seen[cap]=true;nearby[#nearby+1]=cap end end
 end end
 for _,cap in ipairs(nearby)do
  if cap[1][2]>h and cap.x1>box[1]and cap.x0<box[3]and cap.z1>box[2]and cap.z0<box[4]then
   local poly={cap[1],cap[2],cap[3]}
   for _,p in ipairs({{1,box[1],1},{1,box[3],-1},{3,box[2],1},{3,box[4],-1}})do poly=clip(poly,p[1],p[2],p[3])end
   for i=2,#poly-1 do if math.abs(area(poly[1],poly[i],poly[i+1]))>.001 then
    -- Six-vertex faces also work with the existing geometry/heightfield tools.
    for _,p in ipairs({poly[1],poly[i],poly[i+1],poly[1],poly[i+1],poly[i+1]})do
     local v=copy(p);v[2]=h;v[9]=-3;out[#out+1]=v
    end
   end end
   for i,a in ipairs(poly)do local b=poly[i%#poly+1]
    local nx,nz
    if math.abs(a[1]-box[1])<.001 and math.abs(b[1]-box[1])<.001 then nx,nz=-1,0
    elseif math.abs(a[1]-box[3])<.001 and math.abs(b[1]-box[3])<.001 then nx,nz=1,0
    elseif math.abs(a[3]-box[2])<.001 and math.abs(b[3]-box[2])<.001 then nx,nz=0,-1
    elseif math.abs(a[3]-box[4])<.001 and math.abs(b[3]-box[4])<.001 then nx,nz=0,1 end
    local length=math.sqrt((a[1]-b[1])^2+(a[3]-b[3])^2)
    if nx and length>.001 and continued((a[1]+b[1])*.5+nx*.05,(a[3]+b[3])*.5+nz*.05,a[2])then
     local first=#out+1
     -- Keep rock texels world-aligned as the window moves. Never squeeze a
     -- complete 16px wall texture into a short triangle intersection segment.
     local axis=nx~=0 and 3 or 1;local base=math.floor(math.min(a[axis],b[axis])/16)*16
     local uv=cap.uv;local function u(p)return uv[1]+(uv[3]-uv[1])*math.max(0,math.min(1,(p[axis]-base)/16))end
     local crop={u(a),uv[2],u(b),uv[2]+(uv[4]-uv[2])*(1-h/a[2])}
     G.quad(out,{a[1],a[2],a[3]},{b[1],b[2],b[3]},{b[1],h,b[3]},{a[1],h,a[3]},crop,shade)
     for j=first,#out do out[j][9]=-3 end
    end
   end
  end
 end
 return out
end
function S.update(entry,d,px,pz,neighbors)
 local box=V.require('CaveCutaway').bounds(d,px,pz)
 if not box or not entry.caveCaps then return end
 local key=table.concat(box,':')
 for _,caps in ipairs(neighbors or{})do key=key..':'..tostring(caps)end
 if entry.caveSectionKey~=key then
  local vertices=S.build(entry.caveCaps,box,neighbors);entry.caveSectionCount=#vertices
  if #vertices>0 then
   if not entry.caveSection or entry.caveSection:getVertexCount()<#vertices then
    if entry.caveSection then entry.caveSection:release()end
    entry.caveSection=love.graphics.newMesh(V.require('WorldGeometry').FORMAT,math.ceil(#vertices/192)*192,'triangles','dynamic')
   end
   entry.caveSection:setVertices(vertices);entry.caveSection:setDrawRange(1,#vertices)
  end
  entry.caveSectionKey=key
 end
 if entry.caveSectionCount>0 then entry.caveSection:setTexture(entry.mesh:getTexture());return entry.caveSection end
end
return S
