-- Fixed work lights for the native Factory rooms; no rental/script state.
local V=...;local F={}
function F.profile(d)
 local factory=V.require('EmeraldBattleFactory');local _,kind=factory.kind(d)
 if not(kind and factory.profile(d))then return end
 local c=V.require('DioramaConfig').emeraldInteriors.battleFactory.lighting
 return c.enabled and c[kind]or nil
end
function F.capture(list,o,x,z)
 if not o.kind:match('^factory')then return false end
 if o.kind=='factoryWall'then return false end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battleFactory
 local function box(a,b,back,front,low,high,wall)
  list[#list+1]={lo={x+a,low*cfg.heightScale,z+back},hi={x+b,high*cfg.heightScale,z+front},wall=wall or false}
 end
 if o.kind=='factoryCounter'then
  box(0,16,16,64,0,c.counterHeight);box(o.w-16,o.w,16,64,0,c.counterHeight)
  box(16,o.gap,52,64,0,c.counterHeight);box(o.gap+16,o.w-16,52,64,0,c.counterHeight)
 elseif o.kind=='factoryDevice'then box(1,15,27.75,28.25,c.counterHeight,c.counterHeight+c.deviceHeight)
 elseif o.kind=='factoryPC'then box(0,16,39.75,40.25,0,c.pcHeight)
 elseif o.kind=='factoryMonitor'then box(9,39,23.75,24.25,0,c.monitorHeight)
 elseif o.kind=='factoryMachineA'then
  local last=o.last or 32;box(0,o.w,last-.25,last+.25,0,c.machineHeight)
 elseif o.kind=='factoryMachineB'then
  -- The thin probes above the body are not a solid rectangular cabinet.
  box(0,39,38.75,39.25,0,c.machineHeight*22/31)
 elseif o.kind=='factoryMachineRow'then
  box(0,39,31.75,32.25,0,c.machineHeight*23/32)
  box(40,72,31.75,32.25,0,c.machineHeight)
 elseif o.kind=='factoryRack'then
  local last=o.h-8;box(0,32,last-c.rackDepth,last,2*c.rackHeightScale,(last-4)*c.rackHeightScale)
 elseif o.kind=='factoryTable'then box(0,o.w,0,18,c.tableHeight-c.lighting.slabThickness,c.tableHeight)
 elseif o.kind=='factoryBin'then box(2,14,30.75,31.25,0,c.binHeight*23/27)
 elseif o.kind=='factorySeat'then
  box(1,11,4,44,c.seatHeight-c.lighting.slabThickness,c.seatHeight)
  box(11,14,1,44,0,c.backHeight)
 elseif o.kind=='factoryBattleShell'then
  -- Ground and wall share the native source image, never one shadow box.
  box(16,192,39.75,40.25,0,c.battleWallHeight,true)
  -- Keep the conservative corner casters BEHIND the diagonal surface. A
  -- staircase of enclosing AABBs crosses that surface and self-shadows it
  -- into vertical stripes even though its native texture is continuous.
  for a=0,12,4 do
   box(a,a+4,51.5-a,52-a,0,c.battleWallHeight,true)
   box(192+a,196+a,39.5+a,40+a,0,c.battleWallHeight,true)
  end
 end
 -- Plants keep alpha-masked native silhouettes plus their contact shadows.
 return true
end
return F
