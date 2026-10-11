-- Placed furniture casts shadows only from its native opaque surface runs.
-- Open table legs and plant silhouettes must never become filled AABBs.
local V=...;local S={}
function S.capture(list,o,vertices,first,last)
 local c=V.require('DioramaConfig').emeraldInteriors.secretBases.furniture
 if o.kind~='secretDecor'then return false end
 if o.style=='poster'then return true end
 local k=o.style
 local pieces={}
 local function add(lo,hi)
  -- Only complete shared faces merge. Open legs, pipe gaps and curved lid
  -- corners cannot disappear into a bounding box during coalescing.
  local again=true
  while again do again=false
   for i=#pieces,1,-1 do local b=pieces[i]
    for axis=1,3 do
     local a2=axis%3+1;local a3=a2%3+1
     if b.lo[a2]==lo[a2]and b.hi[a2]==hi[a2]and b.lo[a3]==lo[a3]and b.hi[a3]==hi[a3]
      and(b.hi[axis]==lo[axis]or hi[axis]==b.lo[axis])then
      lo[axis]=math.min(lo[axis],b.lo[axis]);hi[axis]=math.max(hi[axis],b.hi[axis])
      table.remove(pieces,i);again=true;break
     end
    end
    if again then break end
   end
  end
  pieces[#pieces+1]={lo=lo,hi=hi,wall=false}
 end
 for i=first,last,6 do
  local lo={math.huge,math.huge,math.huge};local hi={-math.huge,-math.huge,-math.huge}
  for j=i,i+5 do for a=1,3 do lo[a]=math.min(lo[a],vertices[j][a]);hi[a]=math.max(hi[a],vertices[j][a])end end
  local horizontal=hi[2]==lo[2]and hi[2]>.05 and hi[1]>lo[1]and hi[3]>lo[3]
  local axis=hi[3]==lo[3]and 3 or hi[1]==lo[1]and 1
  local upright=axis and hi[2]>lo[2]
  if horizontal then
   lo[2]=math.max(0,hi[2]-c.shadowTableThickness)
   add(lo,hi)
  elseif upright then
   lo[axis]=lo[axis]-c.shadowFaceThickness/2;hi[axis]=hi[axis]+c.shadowFaceThickness/2
   add(lo,hi)
  end
 end
 for _,b in ipairs(pieces)do list[#list+1]=b end
 return true
end
return S
