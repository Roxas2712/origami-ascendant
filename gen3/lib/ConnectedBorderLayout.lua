local V=...
local B={}
function B.forEntries(def,entries)
 if V.data('Emerald').map(def)or not V.data('Shapes').outdoors(def)
   or V.data('Shapes').forest(def)or #entries<2 then return def.midLayout end
 local base=def.midLayout;local rows={};local banks={}
 for _,e in ipairs(entries)do
  if e.def.midLayout and V.data('Shapes').outdoors(e.def)and not V.data('Shapes').forest(e.def)then
   banks[#banks+1]=e
  end
 end
 local function owner(x,z)
  local row=rows[z];if not row then row={};rows[z]=row end
  if row[x]then return row[x]end
  local best,distance
  for _,e in ipairs(banks)do
   local l=e.def.midLayout
   local dx=math.max(e.ox-x,0,x-(e.ox+l.width-1))
   local dz=math.max(e.oy-z,0,z-(e.oy+l.height-1))
   local d=dx*dx+dz*dz
   if not distance or d<distance or d==distance and e.id<best.id then best,distance=e,d end
  end
  row[x]=best;return best
 end
 local proxy=setmetatable({},{__index=base})
 function proxy:cellAt(x,z)
  local e=owner(x,z)
  if e then
   local cell=e.def.midLayout:cellAt(x-e.ox,z-e.oy)
   -- Kanto primary art is shared; secondary art requires the same atlas.
   if cell and(cell.mid<0x200 or e.def.pair==def.pair)then return cell end
  end
  return base:cellAt(x,z)
 end
 function proxy:midAt(x,z)local c=self:cellAt(x,z);return c and c.mid or 0 end
 return proxy
end
return B
