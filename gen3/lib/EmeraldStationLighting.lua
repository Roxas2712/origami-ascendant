-- The two cable-car stations share native architecture, not travel state.
local V=...;local S={}
function S.profile(d)
 if not(d and d.mapType==8)then return end
 local p=V.require('EmeraldStations').profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors.stationLighting
 if not(p and not p.harbor and c.enabled)then return end
 local L=d.midLayout
 if L:midAt(6,5)~=0x2f0 or L:midAt(12,7)~=0x2fa then return end
 return c
end
function S.capture(list,o,x,z)
 -- Harbor objects deliberately retain their separate lighting plan.
 if o.kind~='stationPit'and o.kind~='stationBench'and o.kind~='stationSign'
  and o.kind~='stationMachine'and o.kind~='stationBin'then return false end
 local cfg=V.require('DioramaConfig').emeraldInteriors
 local c,lc=cfg.stations,cfg.stationLighting
 local function box(a,b,u,v,low,high)
  list[#list+1]={lo={x+a,low*cfg.heightScale,z+u},hi={x+b,high*cfg.heightScale,z+v},wall=false}
 end
 if o.kind=='stationBench'then
  box(4,14,14,35,c.benchSeatHeight-lc.slabThickness,c.benchSeatHeight)
  box(1,4,14,35,c.benchSeatHeight,c.benchBackHeight)
 elseif o.kind=='stationSign'then
  local half=lc.blockerThickness/2
  box(1,31,8-half,8+half,c.railHeight,c.railHeight+c.signHeight)
 elseif o.kind=='stationMachine'then box(0,16,32-c.machineDepth,32,0,c.machineHeight)
 end
 -- Sunken pits do not occlude the air above them. The open rail and curved
 -- bin keep their existing contact art instead of becoming opaque cuboids.
 return true
end
return S
