-- Presentation-only paper-packet folds in the original sprite sheet. Every point
-- returns exactly to its native plane; no battle state or texture is replaced.
local V=...
local Popup=V.require('battle/PopupActors')
local O={COLUMNS=8,ROWS=12}
function O.enabled()
 return V.mod.options:get('gen3OrigamiSpawn')~=false
end
local function smooth(p)
 p=math.max(0,math.min(1,p));return p*p*(3-2*p)
end
-- Fold a half-sheet around a crease, preserving a shared edge. The large
-- diagonal corners and closing flap follow a paper packet, not an accordion.
local creases={{-1,1,.60,.36,.50},{1,1,.60,.27,.50},{-1,0,.16,.16,.45},{1,0,.16,.10,.42},{0,1,.28,0,.38}}
function O.active(progress,direction)
 return progress<1 and O.enabled()
end
function O.transform(foot,progress,lean,direction,scene,span)
 if not O.active(progress,direction)then return function(p)return Popup.foldPoint(p,foot,progress,lean,direction)end end
 local u=math.max(0,math.min(1,progress));local h=math.max(.01,span and span.height or 48*(scene and scene.scale or 1))
 local folds={}
 for i,c in ipairs(creases)do
  local inv=1/math.sqrt(c[1]*c[1]+c[2]*c[2]);local angle=(1-smooth((u-c[4])/c[5]))*math.pi*.94
  folds[i]={c[1]*inv,c[2]*inv,c[3]*inv,math.cos(angle),math.sin(angle)}
 end
 local t=math.max(0,(u-.86)/.14)
 local settle=direction==-1 and 0 or -.055*math.sin(t*3*math.pi)*(1-t)^2
 local rise=(1-smooth(u/.48))*math.pi*.42+settle
 local cr,sr,cl,sl=math.cos(rise),math.sin(rise),math.cos(lean or 0),math.sin(lean or 0)
 -- Trigonometry belongs to the actor pose, not every individual mesh vertex.
 return function(p)
  local x,y,z=(p[1]-foot[1])/h,(p[2]-foot[2])/h,(p[3]-foot[3])/h
  for _,f in ipairs(folds)do
   local distance=x*f[1]+y*f[2]-f[3]
   if distance>0 then
    local projected=distance*f[4]-z*f[5]
    x,y,z=x+f[1]*(projected-distance),y+f[2]*(projected-distance),distance*f[5]+z*f[4]
   end
  end
  y,z=y*cr-z*sr,y*sr+z*cr
  x,y=x*cl-y*sl,x*sl+y*cl
  return {foot[1]+x*h,foot[2]+y*h,foot[3]+z*h}
 end
end
function O.point(p,foot,progress,lean,direction,scene,span)
 return O.transform(foot,progress,lean,direction,scene,span)(p)
end
function O.quads(out,G,point,x,y,w,h,shade,active)
 local cols,rows=active and O.COLUMNS or 1,active and O.ROWS or 1
 local grid={}
 for j=0,rows do
  local row={};grid[j+1]=row
  for i=0,cols do row[i+1]=point(x+w*i/cols,y+h*j/rows)end
 end
 for j=0,rows-1 do for i=0,cols-1 do
  local l,r=x+w*i/cols,x+w*(i+1)/cols
  local t,b=y+h*j/rows,y+h*(j+1)/rows
  local a,c,d,e=grid[j+1][i+1],grid[j+1][i+2],grid[j+2][i+2],grid[j+2][i+1]
  local gain=1
  if active then
   local ux,uy,uz=c[1]-a[1],c[2]-a[2],c[3]-a[3]
   local vx,vy,vz=e[1]-a[1],e[2]-a[2],e[3]-a[3]
   local nx,ny,nz=uy*vz-uz*vy,uz*vx-ux*vz,ux*vy-uy*vx
   local len=math.sqrt(nx*nx+ny*ny+nz*nz)
   gain=.62+.38*(len>1e-9 and math.abs(nz)/len or 1)
  end
  G.quad(out,a,c,d,e,{l/240,t/160,r/240,b/160},shade*gain)
 end end
end
return O
