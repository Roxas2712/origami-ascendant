-- Native pixel contours -> closed rectangular shadow volumes. The union is
-- exact: only complete shared rectangle edges merge, never concave gaps.
local V=...;local C={}
function C.writer(list,x,z,scale,base)
 base=base or 0
 local function box(a,b,u,v,low,high,merge)
  if high<=low then return end
  local q={lo={x+a,(base+low)*scale,z+u},hi={x+b,(base+high)*scale,z+v},wall=false,contourVolume=merge}
  if merge then local again=true
   while again do again=false
    for i=#list,1,-1 do local old=list[i]
     if old.contourVolume and old.lo[2]==q.lo[2]and old.hi[2]==q.hi[2]then
      local axis
      if old.lo[3]==q.lo[3]and old.hi[3]==q.hi[3]and(old.hi[1]==q.lo[1]or q.hi[1]==old.lo[1])then axis=1
      elseif old.lo[1]==q.lo[1]and old.hi[1]==q.hi[1]and(old.hi[3]==q.lo[3]or q.hi[3]==old.lo[3])then axis=3 end
      if axis then q.lo[axis]=math.min(q.lo[axis],old.lo[axis]);q.hi[axis]=math.max(q.hi[axis],old.hi[axis]);table.remove(list,i);again=true end
     end
    end
   end
  end
  list[#list+1]=q
 end
 local function contour(w,h,low,high,inside)
  for t=0,h-1 do local s=0
   while s<w do
    if inside(s,t)then local first=s;repeat s=s+1 until s==w or not inside(s,t);box(first,s,t,t+1,low,high,true)
    else s=s+1 end
   end
  end
 end
 return box,contour
end
return C
