-- Shadow volumes follow the room's already separated native surfaces.
local V=...;local S={}
function S.capture(list,o,vertices,first,last)
 local c=V.require('DioramaConfig').interiors.seaCottage
 local k=o.kind
 if not c.shadowContours or not(k=='cottagePod'or k=='cottagePipe'or k=='cottageDesk'
  or k=='cottageCrate'or k=='cottageCabinet'or k=='cottageControl'or k=='cottageDevice')then return false end
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
  local upright=hi[3]==lo[3]and hi[1]>lo[1]and hi[2]>lo[2]
  if horizontal then
   lo[2]=k=='cottageDesk'and math.max(0,hi[2]-c.shadowTableThickness)or 0
   add(lo,hi)
  elseif upright and(k=='cottageDesk'or k=='cottagePipe'or k=='cottageControl'or k=='cottageDevice')then
   lo[3]=lo[3]-c.shadowFaceThickness/2;hi[3]=hi[3]+c.shadowFaceThickness/2
   add(lo,hi)
  end
 end
 for _,b in ipairs(pieces)do list[#list+1]=b end
 return true
end
return S
