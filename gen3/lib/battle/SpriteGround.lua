-- Opaque source-pixel support under the actual native affine animation.
-- No pose/state mutation: lift only the drawn center if it penetrates the floor.
local Ground={}
function Ground.outline(data)
 local points={};local w,h=data:getDimensions()
 for y=0,h-1 do
  local left,right=w,-1
  for x=0,w-1 do local _,_,_,a=data:getPixel(x,y)
   if a>.01 then left=math.min(left,x);right=x end
  end
  if right>=left then
   for _,yy in ipairs({y,y+1})do
    points[#points+1]={left-32,yy-32};points[#points+1]={right+1-32,yy-32}
   end
  end
 end
 return points
end
function Ground.center(points,cx,cy,rot,sx,sy,fx,fy,slope,pad)
 slope=slope or 0
 local c,s=math.cos(rot),math.sin(rot);local support=-math.huge
 for _,p in ipairs(points)do
  local x,y=p[1]*sx,p[2]*sy
  local dx,dy=c*x-s*y,s*x+c*y
  support=math.max(support,dy-slope*dx)
 end
 if support==-math.huge then return cx,cy,0 end
 local penetration=cy+support-(fy+slope*(cx-fx))+(pad or 0)
 local lift=math.max(0,penetration)
 return cx,cy-lift,lift
end
-- Native GBA bounces/attack offsets can point below their resting baseline.
-- In a grounded scene play the same excursion above that baseline instead of
-- cancelling every positive sample. Then enforce the actual opaque contour.
function Ground.animatedCenter(points,cx,cy,rot,sx,sy,fx,fy,slope,pad,oy,bounce)
 oy=oy or 0;bounce=math.max(0,bounce or 0)
 -- Long native downward exits (e.g. Dig) must not become giant skyward hops.
 local down=math.max(0,oy)
 local x,y,lift=Ground.center(points,cx,cy-down-math.min(6,down)-2*bounce,rot,sx,sy,fx,fy,slope,pad)
 return x,y,lift
end
return Ground
