-- Measured ceiling fixtures and furniture occlusion for the four Dome rooms.
local V=...;local D={}
function D.profile(d)
 local dome=V.require('EmeraldBattleDome');local _,kind=dome.kind(d)
 if not(kind and dome.profile(d))then return end
 local c=V.require('DioramaConfig').emeraldInteriors.battleDome.lighting
 return c.enabled and c[kind]or nil
end
function D.capture(list,o,x,z)
 if not o.kind:match('^dome')then return false end
 if o.kind=='domeWall'and not o.stands then return false end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battleDome
 local function box(a,b,back,front,low,high)
  list[#list+1]={lo={x+a,low*cfg.heightScale,z+back},hi={x+b,high*cfg.heightScale,z+front},wall=false}
 end
 if o.kind=='domeCounter'then
  -- Each L-shaped desk is two solid runs, leaving the staff opening clear.
  local left=o.mask=='left'
  box(left and 0 or 24,left and 24 or 48,18,56,0,c.counterHeight)
  box(0,48,56,64,0,c.counterHeight)
 elseif o.kind=='domeShortCounter'then box(0,48,16,32,0,c.counterHeight)
 elseif o.kind=='domeDevice'then box(1,15,27.75,28.25,c.counterHeight,c.counterHeight+c.deviceHeight)
 elseif o.kind=='domeMonitor'then box(9,39,27.75,28.25,c.counterHeight,c.counterHeight+c.deviceHeight)
 elseif o.kind=='domePC'then box(0,16,39.75,40.25,0,c.pcHeight)
 elseif o.kind=='domeTable'then box(8,32,2,42,c.tableHeight-c.lighting.slabThickness,c.tableHeight)
 elseif o.kind=='domeBoard'then
  box(0,4,0,40,0,c.pcHeight);box(4,12,0,36,0,c.tableHeight)
 elseif o.kind=='domeStage'then
  box(64,160,8,72,0,c.stageHeight)
  box(16,64,26,56,0,c.stageHeight);box(160,208,26,56,0,c.stageHeight)
 elseif o.kind=='domeWall'then
  -- Conservative interior of the sloping grandstand, never a full-height
  -- rectangle across its front or the spectators standing on the steps.
  for back=0,33,11 do
   local front=back+11;box(0,o.w,back+20,front+20,0,16+(44-front)/44*(o.height-16))
  end
 end
 -- Alpha-masked plants/ropes and thin chairs keep contact shading. Their
 -- enclosing sprite rectangles must never become opaque shadow casters.
 return true
end
return D
