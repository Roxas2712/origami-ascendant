-- Match the already-rendered research furniture: desk slabs and upright
-- screens are separate volumes. Small seats/plants retain contact shadows.
local V=...;local M={}
function M.capture(list,o,x,z)
 if not(x and z)then return false end
 local k=o.kind;local c=V.require('DioramaConfig');local e=c.emeraldInteriors
 local scale=e.heightScale;local rig=c.roomLightRig
 local function box(a,b,back,front,low,high)
  list[#list+1]={lo={x+a,low*scale,z+back},hi={x+b,high*scale,z+front},wall=false}
 end
 local function slab(w,back,front,h)
  box(0,w,back,front,math.max(0,h-rig.researchTableThickness),h)
 end
 local function screen(a,b,depth,h,rise)
  local d=rig.researchDeviceDepth/2
  box(a,b,depth-d,depth+d,h,h+rise)
 end
 if k=='weatherCabinet'then
  -- These cabinets touch exactly along a continuous row. Merge only that
  -- matching solid footprint, never bridge an aisle or monitor gap.
  local low,high=z+20,z+31;local height=e.weatherInstitute.cabinetHeight*scale
  for _,b in ipairs(list)do
   if b.researchCabinet and b.lo[3]==low and b.hi[3]==high and b.hi[2]==height
    and x<=b.hi[1] and x+o.w>=b.lo[1]then
    b.lo[1]=math.min(b.lo[1],x);b.hi[1]=math.max(b.hi[1],x+o.w);return true
   end
  end
  box(0,o.w,20,31,0,e.weatherInstitute.cabinetHeight);list[#list].researchCabinet=true
 elseif k=='devonDesk' or k=='spaceDesk'then
  local cfg=k=='devonDesk'and e.devon or e.spaceCenter
  slab(o.w,15,29,cfg.deskHeight)
  if k=='devonDesk'or o.pc then screen(2,16,21,cfg.deskHeight,cfg.pcHeight)end
 elseif k=='devonDrawing' or k=='spaceDrawing'then
  local cfg=k=='devonDrawing'and e.devon or e.spaceCenter
  slab(o.w,k=='devonDrawing'and 8 or 7,k=='devonDrawing'and 28 or 27,cfg.deskHeight)
 elseif k=='devonTable'then
  slab(o.w,20,66,e.devon.executiveTableHeight)
 elseif k=='devonCounter'then
  slab(o.w,20,28,e.devon.counterHeight)
 elseif k=='weatherDesk'then
  local cfg=e.weatherInstitute;slab(o.w,14,40,cfg.deskHeight)
  for dx=0,o.w-1,16 do screen(dx+1,dx+15,23,cfg.deskHeight,cfg.pcHeight)end
 elseif k=='weatherTerminal'then
  local cfg=e.weatherInstitute;slab(o.w,32,44,cfg.deskHeight)
  screen(1,24,40,cfg.deskHeight,cfg.terminalHeight)
 elseif k~='devonStool'and k~='spaceStool'and k~='weatherChair'and k~='weatherPlant'then
  return false
 end
 return true
end
return M
