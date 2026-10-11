-- Conservative XY clip tests. Depth is deliberately excluded: paper rooms
-- and mirrored geometry alter clip Z after projection. Unknown bounds draw.
local V=...
local Budget=V.require('BuildBudget')
local S={enabled=true}
local function point(b,x,y,z)
 b[1]=math.min(b[1],x);b[2]=math.min(b[2],y);b[3]=math.min(b[3],z)
 b[4]=math.max(b[4],x);b[5]=math.max(b[5],y);b[6]=math.max(b[6],z)
end
function S.vertices(vertices)
 if #vertices==0 then return nil end
 local b={math.huge,0,math.huge,-math.huge,0,-math.huge,0}
 for i,v in ipairs(vertices)do
  if i%256==0 then Budget.check()end
  point(b,v[1],v[2],v[3])
  local flag=v[9]or 0
  if flag>.5 then
   -- Covers billboard rotation as well as the current horizontal right axis.
   local r=math.abs(v[1]-(v[7]or 0))
   point(b,(v[7]or 0)-r,v[2],v[3]-r);point(b,(v[7]or 0)+r,v[2],v[3]+r)
  end
  if flag>1.01 then b[7]=math.max(b[7],2*(flag-1))end
  if v[6]>=10 and v[6]<=14 then point(b,v[7]or v[1],0,v[8]or v[3])end
 end
 return b
end
function S.merge(b,other,placements)
 if not other then return b end
 b=b or{math.huge,0,math.huge,-math.huge,0,-math.huge,0}
 if placements then
  for i,p in ipairs(placements)do
   if i%256==0 then Budget.check()end
   local scale=p[3]or 1
   point(b,other[1]*scale+p[1],other[2]*scale,other[3]*scale+p[2])
   point(b,other[4]*scale+p[1],other[5]*scale,other[6]*scale+p[2])
  end
 else point(b,other[1],other[2],other[3]);point(b,other[4],other[5],other[6])end
 b[7]=math.max(b[7],other[7]or 0)
 return b
end
function S.visible(b,m,mirror,wind,width,height,deformation)
 if not S.enabled or not b then return true end
 local pad=math.abs(wind or 0)*(b[7]or 0)+.01
 local x0,x1,z0,z1=b[1]-pad,b[4]+pad,b[3]-.01,b[6]+.01
 local y0,y1=b[2]-.01,b[5]+.01
 if deformation then
  if deformation.ground then y0,y1=math.min(y0,0),math.max(y1,0)end
  x0,x1=x0-deformation.x,x1+deformation.x
  y0,y1=y0-deformation.y,y1+deformation.y
  z0,z1=z0-deformation.z,z1+deformation.z
 end
 if mirror then y0,y1=-y1,-y0 end
 -- Keep two output pixels around each edge for vertex snap and filtering.
 for axis=0,1 do
  local row=axis*4;local margin=1+4/math.max(1,axis==0 and width or height)
  for sign=-1,1,2 do
   local a,c,d,e=margin*m[13]+sign*m[row+1],margin*m[14]+sign*m[row+2],margin*m[15]+sign*m[row+3],margin*m[16]+sign*m[row+4]
   local furthest=a*(a>=0 and x1 or x0)+c*(c>=0 and y1 or y0)+d*(d>=0 and z1 or z0)+e
   if furthest<0 then return false end
  end
 end
 return true
end
function S.select(entries,out,m,mirror,wind,width,height,unbounded,deformation)
 local n,vertices=0,0
 for _,entry in ipairs(entries)do
  if unbounded or S.visible(entry.stats and entry.stats.frustumBounds,m,mirror,wind,width,height,deformation)then
   n=n+1;out[n]=entry
  else vertices=vertices+(entry.stats and entry.stats.vertices or 0)end
 end
 for i=#out,n+1,-1 do out[i]=nil end
 return out,#entries-n,vertices
end
return S
