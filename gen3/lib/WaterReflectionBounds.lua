-- Conservative screen bounds of the rendered water receivers. The reflection
-- remains full resolution within these bounds, including its wave/filter margin.
local V=...
local Budget=V and V.require('BuildBudget')
local B={}
-- Capture the actual rendered water, including raised pools, submerged gym
-- floors and the water pixels underneath sea rocks. Packed with scene stats,
-- so restoring a scene does not scan GPU vertices or rebuild native geometry.
function B.vertices(vertices)
 local box
 for i,v in ipairs(vertices)do
  if Budget and i%512==0 then Budget.check()end
  if v[6]>=3.5 and v[6]<4.5 then
  local x,y,z=v[1],v[2],v[3]
  if not box then box={x,z,x,z,y,y}
  else
   box[1]=math.min(box[1],x);box[2]=math.min(box[2],z)
   box[3]=math.max(box[3],x);box[4]=math.max(box[4],z)
   box[5]=math.min(box[5],y);box[6]=math.max(box[6],y)
  end
 end end
 return box or false
end
function B.rect(runs,m,w,h,extra)
 if not m then return 0,0,w,h end
 -- Maximum normalized wave offset plus roughness taps, bilinear filtering,
 -- and raster rounding. Bounds include the sampling footprint, not just water.
 local padx,pady=math.ceil(w*.013)+4,math.ceil(h*.010)+4
 local left,top,right,bottom=w,h,0,0
 for n=1,#runs+(extra and #extra or 0)do
  local r=n<=#runs and runs[n]or extra[n-#runs]
  local x0,y0,x1,y1=math.huge,math.huge,-math.huge,-math.huge
  local front,back=0,0
  for corner=1,(r[6]and r[6]~=r[5]and 8 or 4)do
   local i=(corner-1)%4+1
   local x=(i==1 or i==4)and r[1]or r[3]
   local z=i<=2 and r[2]or r[4]
   local y=(corner>4 and r[6]or r[5])or 0
   local d=m[13]*x+m[14]*y+m[15]*z+m[16]
   if d<=.0001 then back=back+1 else
    front=front+1
    local u=((m[1]*x+m[2]*y+m[3]*z+m[4])/d*.5+.5)*w
    local v=((m[5]*x+m[6]*y+m[7]*z+m[8])/d*.5+.5)*h
    x0=math.min(x0,u);x1=math.max(x1,u);y0=math.min(y0,v);y1=math.max(y1,v)
   end
  end
  if front>0 and back>0 then return 0,0,w,h end
  if front>0 and x1>=-1 and y1>=-1 and x0<=w+1 and y0<=h+1 then
   left=math.min(left,math.max(0,math.floor(x0)-padx));right=math.max(right,math.min(w,math.ceil(x1)+padx))
   top=math.min(top,math.max(0,math.floor(y0)-pady));bottom=math.max(bottom,math.min(h,math.ceil(y1)+pady))
  end
 end
 if right<=left or bottom<=top then return 0,0,0,0 end
 return left,top,right-left,bottom-top
end
return B
