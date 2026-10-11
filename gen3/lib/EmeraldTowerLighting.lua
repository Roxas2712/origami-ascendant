-- Fixed Tower lights and measured blockers; native challenge state is read-only.
local V=...;local T={}
function T.profile(d)
 local p=V.require('EmeraldTowerPublic');local key
 if p.profile(d)then key=p.kind(d)
 else local r=V.require('EmeraldTowerChallengeRooms');local spec=r.kind(d)
  if spec and r.profile(d)then key=spec[3]end
 end
 if not key then return end
 local c=V.require('DioramaConfig').emeraldInteriors.towerLighting
 return c.enabled and c[key]or nil
end
function T.capture(list,o,x,z)
 local cfg=V.require('DioramaConfig').emeraldInteriors
 local c,cc=cfg.towerPublic,cfg.towerChallenge;local lc=cfg.towerLighting
 local function box(a,b,u,v,low,high)
  list[#list+1]={lo={x+a,low*cfg.heightScale,z+u},hi={x+b,high*cfg.heightScale,z+v},wall=false}
 end
 local function thin(a,b,at,low,high)
  box(a,b,at-lc.blockerThickness/2,at+lc.blockerThickness/2,low,high)
 end
 if o.kind=='towerCounter'then
  -- Five narrow dividers and two front arms per lane; the central staff
  -- openings remain open. The top art projects t=8..72 onto z=16..80.
  for a=0,256,64 do box(a,a+16,16,80,0,c.counterHeight)end
  for a=0,192,64 do
   box(a+16,a+32,68,80,0,c.counterHeight)
   box(a+48,a+64,68,80,0,c.counterHeight)
  end
 elseif o.kind=='towerDeskDevice'then thin(1,15,28,c.counterHeight,c.counterHeight+c.deviceHeight)
 elseif o.kind=='towerMonitor'then thin(9,39,40,0,c.monitorHeight)
 elseif o.kind=='towerPC'then box(0,16,40-c.pcDepth,40,0,c.pcHeight)
 elseif o.kind=='towerBench'then
  box(1,11,5,44,math.max(0,c.seatHeight-lc.slabThickness),c.seatHeight)
  box(11,13,1,44,0,c.backHeight)
 elseif o.kind=='challengeColumn'then thin(1,15,32,0,cc.columnHeight)
 elseif o.kind=='towerPlant'or o.kind=='challengePlant'then
  -- Alpha-masked plants retain contact shadows, never rectangular casters.
 else return false end
 return true
end
return T
