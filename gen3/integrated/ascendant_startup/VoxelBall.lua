-- Solid voxel geometry, rotated by travelled distance. No flat ball image.
local M={};local faces={};local radius=4.25
local dirs={{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1}}
local function inside(x,y,z)return x*x+y*y+z*z<=radius*radius end
for x=-4,4 do for y=-4,4 do for z=-4,4 do if inside(x,y,z)then
 local r,g,b=.93,.94,.98
 if y>0 then r,g,b=.94,.10,.16 elseif y==0 then r,g,b=.065,.08,.13 end
 if z<=-3 and math.abs(x)<=1 and math.abs(y)<=1 then r,g,b=.065,.08,.13 end
 if z<=-3 and x==0 and y==0 then r,g,b=.98,.99,1 end
 for _,n in ipairs(dirs)do if not inside(x+n[1],y+n[2],z+n[3])then
  local corners={}
  local u=n[1]~=0 and {0,1,0}or{1,0,0};local v=n[3]~=0 and {0,1,0}or{0,0,1}
  for _,pair in ipairs{{-1,-1},{1,-1},{1,1},{-1,1}}do
   corners[#corners+1]={x+n[1]*.5+u[1]*pair[1]*.5+v[1]*pair[2]*.5,y+n[2]*.5+u[2]*pair[1]*.5+v[2]*pair[2]*.5,z+n[3]*.5+u[3]*pair[1]*.5+v[3]*pair[2]*.5}
  end
  faces[#faces+1]={corners=corners,normal=n,color={r,g,b}}
 end end
end end end end
local function transform(x,y,z,c,s)
 local X,Y=x*c-y*s,x*s+y*c
 -- Slightly above and to the side, matching the Cobble character view.
 local a=-.16;local xx=X*math.cos(a)+z*math.sin(a);local zz=-X*math.sin(a)+z*math.cos(a)
 return xx,Y*.98+zz*.2,zz*.98-Y*.2
end
function M.draw(g,x,y,r,turn,alpha)
 local cs,sn=math.cos(turn),math.sin(turn);local k=r/4.5;local queue={};local top=0
 for _,f in ipairs(faces)do
  local nx,ny,nz=transform(f.normal[1],f.normal[2],f.normal[3],cs,sn)
  if nz<-.001 then
   local vertices={};local depth=0
   for _,p in ipairs(f.corners)do
    local px,py,pz=transform(p[1],p[2],p[3],cs,sn)
    vertices[#vertices+1]=x+px*k;vertices[#vertices+1]=y-py*k;depth=depth+pz;top=math.max(top,py*k)
   end
   queue[#queue+1]={points=vertices,depth=depth,light=math.min(1.08,.67-.16*nx+.22*ny-.2*nz),color=f.color}
  end
 end
 table.sort(queue,function(a,b)return a.depth>b.depth end)
 g.setColor(.04,.085,.16,.5*alpha);g.ellipse('fill',x,y+r+5,r*.92,7)
 for _,f in ipairs(queue)do local c=f.color;g.setColor(c[1]*f.light,c[2]*f.light,c[3]*f.light,alpha);g.polygon('fill',f.points)end
 return y-top
end
return M
