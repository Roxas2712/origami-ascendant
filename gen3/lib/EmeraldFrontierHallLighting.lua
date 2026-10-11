-- The three ranking wings and the reception runner have fixed room lights.
-- Shadow bodies follow visible furniture, not native collision cells.
local V=...;local H={}
function H.profile(d)
 local key
 if V.require('EmeraldFrontierRanking').profile(d)then key='ranking'
 elseif V.require('EmeraldFrontierReception').profile(d)then key='reception'end
 if not key then return end
 local c=V.require('DioramaConfig').emeraldInteriors.frontierHallLighting
 return c.enabled and c[key]or nil
end
function H.capture(list,o,x,z)
 local cfg=V.require('DioramaConfig').emeraldInteriors
 local c,gate,lc=cfg.frontierRanking,cfg.frontierReception,cfg.frontierHallLighting
 local function box(a,b,u,v,low,high)
  list[#list+1]={lo={x+a,low*cfg.heightScale,z+u},hi={x+b,high*cfg.heightScale,z+v},wall=false}
 end
 local half=lc.blockerThickness/2
 local function thin(a,b,at,low,high)box(a,b,at-half,at+half,low,high)end
 if o.kind=='rankReturn'then box(-half,half,0,o.h,0,c.wallHeight)
 elseif o.kind=='rankWall'or o.kind=='rankBrick'then thin(0,o.w,48,0,c.wallHeight)
 elseif o.kind=='rankPillar'then
  -- Wide cap stops above the narrow lower moulding; no floor-backed rectangle.
  thin(0,32,48,c.wallHeight*9/47,c.wallHeight)
  thin(8,24,48,0,c.wallHeight*9/47)
 elseif o.kind=='rankTerminal'then box(0,16,32-c.terminalDepth,32,0,c.terminalHeight)
 elseif o.kind=='rankMachine'then box(8,40,40-c.machineDepth,40,0,c.machineHeight)
 elseif o.kind=='rankSeat'then
  box(1,15,20,29,math.max(0,c.seatHeight-lc.slabThickness),c.seatHeight)
  if not o.stool then thin(1,15,20,c.seatHeight,c.backHeight)end
 elseif o.kind=='gateCounter'then
  -- Mirrored C shapes retain each attendant's open recess.
  box(0,32,12,20,0,gate.counterHeight)
  box(o.right and 0 or 16,o.right and 16 or 32,20,44,0,gate.counterHeight)
  box(0,32,44,54,0,gate.counterHeight)
 elseif o.kind=='gateColumn'then thin(3,13,32,0,gate.columnHeight)
 elseif o.kind=='gatePlant'and o.w==16 and o.h==32 then
  -- Native foliage has only its alpha-masked contact shadow.
 else return false end
 return true
end
return H
