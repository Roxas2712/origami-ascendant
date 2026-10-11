-- Three native public entrance halls. Furniture shadows follow the rendered
-- silhouettes, never the collision grid or the transparent plant billboards.
local V=...;local T={}
function T.profile(d)
 if not(d and d.mapType==8)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.transitLighting
 if not c.enabled then return end
 if V.require('EmeraldTransit').profile(d)then return c.cycle end
 if V.require('EmeraldSafariEntrance').profile(d)then return c.safari end
end
function T.capture(list,o,x,z,L)
 -- FireRed also uses transitCounter/Plant; never steal its geometry handler.
 local cycle=L.width==16 and L.height==6 and L:midAt(5,2)==0x2a8
 local safari=L.width==18 and L.height==14 and L:midAt(6,2)==0x2a8 and L:midAt(16,8)==0x2d0
 if not(cycle or safari)then return false end
 local c=V.require('DioramaConfig').emeraldInteriors
 local function box(a,b,u,v,h)
  list[#list+1]={lo={x+a,0,z+u},hi={x+b,h*c.heightScale,z+v},wall=false}
 end
 if o.kind=='transitCounter'then
  -- U-shaped counter: open attendant recess, no full bounding rectangle.
  box(0,16,16,40,c.transit.counterHeight)
  box(80,96,16,40,c.transit.counterHeight)
  box(16,80,31,40,c.transit.counterHeight)
 elseif o.kind=='transitPlanter'then
  box(0,31,17,30,c.transit.planterHeight)
 elseif o.kind=='safariSideCounter'then
  box(0,16,14,92,c.safariEntrance.counterHeight)
  box(16,32,14,28,c.safariEntrance.counterHeight)
  box(16,32,78,92,c.safariEntrance.counterHeight)
 elseif o.kind=='safariTerminal'or o.kind=='safariChair'then
  local terminal=o.kind=='safariTerminal'
  local depth=c.transitLighting.blockerThickness/2
  local at=terminal and 43 or 14
  box(0,16,at-depth,at+depth,terminal and c.safariEntrance.terminalHeight or c.safariEntrance.chairHeight)
 elseif o.kind~='transitPlant'and o.kind~='safariPlant'then return false end
 return true
end
return T
