-- Warm fixed room lights; native palace water, rugs and scripts are untouched.
local V=...;local P={}
function P.profile(d)
 local palace=V.require('EmeraldBattlePalace');local _,kind=palace.kind(d)
 if not(kind and palace.profile(d))then return end
 local c=V.require('DioramaConfig').emeraldInteriors.battlePalace.lighting
 return c.enabled and c[kind]or nil
end
function P.capture(list,o,x,z)
 if not o.kind:match('^palace')then return false end
 if o.kind=='palaceWall'then return false end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battlePalace
 local function box(a,b,back,front,low,high,rail)
  local lo={x+a,low*cfg.heightScale,z+back};local hi={x+b,high*cfg.heightScale,z+front}
  if rail then
   -- Merge only collinear low stone runs, never fill the planting/water bed.
   for _,v in ipairs(list)do if v.palaceRail then
    if v.lo[1]==lo[1]and v.hi[1]==hi[1]and lo[3]<=v.hi[3]and hi[3]>=v.lo[3]then
     v.lo[3]=math.min(v.lo[3],lo[3]);v.hi[3]=math.max(v.hi[3],hi[3]);return
    elseif v.lo[3]==lo[3]and v.hi[3]==hi[3]and lo[1]<=v.hi[1]and hi[1]>=v.lo[1]then
     v.lo[1]=math.min(v.lo[1],lo[1]);v.hi[1]=math.max(v.hi[1],hi[1]);return
    end
   end end
  end
  list[#list+1]={lo=lo,hi=hi,wall=false,palaceRail=rail}
 end
 if o.kind=='palaceCounter'then
  local low=c.counterHeight-c.lighting.slabThickness
  box(0,24,8,24,low,c.counterHeight);box(88,112,8,24,low,c.counterHeight)
  box(0,48,24,40,low,c.counterHeight);box(64,112,24,40,low,c.counterHeight)
  box(40,72,39.75,40.25,0,c.counterHeight)
  box(1,15,55.75,56.25,0,c.deviceHeight)
 elseif o.kind=='palaceMonitor'then box(9,39,39.75,40.25,0,c.monitorHeight)
 elseif o.kind=='palacePC'then box(8,40,55.75,56.25,0,c.pcHeight)
 elseif o.kind=='palaceStage'then box(0,o.w,0,76,0,c.stageHeight)
 elseif o.kind=='palaceRail'then
  local m=o.mid
  if m==0x239 then box(0,16,8,16,0,c.railHeight,true)
  elseif m==0x23c then box(0,16,0,8,0,c.railHeight,true)
  elseif m==0x235 then box(0,8,0,16,0,c.railHeight,true)
  elseif m==0x233 then box(8,16,0,16,0,c.railHeight,true)
  elseif m==0x23d then box(0,16,0,8,0,c.railHeight,true);box(0,8,8,16,0,c.railHeight,true)
  elseif m==0x23b then box(0,16,0,8,0,c.railHeight,true);box(8,16,8,16,0,c.railHeight,true)end
 end
 -- Do not enclose the alpha-masked leaves in a full rectangular caster.
 return true
end
return P
