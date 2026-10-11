-- Read-only bridge for the two native S.S. Anne implementations used by
-- supported engines. The script owns the animation clock and boat movement.
local S={}
local ok,current=pcall(require,'src.core.game3.ss_anne_cutscene')
local oldOk,legacy=pcall(require,'src.core.game3.ss_anne')
local Objects=require('src.core.game3.objects')
function S.snapshot(def)
 if not def or(def.id or def.name)~='FR_SSANNE_EXTERIOR'then return{}end
 if ok and current._active then
  local boat=Objects.find(1)
  if not boat then return{}end
  local x=boat.px or boat.cellX*16;local y=boat.py or boat.cellY*16
  local base=y+16;local out={};local w=current._wake
  local q=w and current._wakeQuads and current._wakeQuads[w.frame or 0]
  if q and current._wakeImage then
   out[#out+1]={kind='wake',image=current._wakeImage,quad=q,
    x=x-(current._boatOffset or 0)+50+(w.x2 or 0),y=y-24,base=base,ground=true}
  end
  for _,p in ipairs(current._smokes or{})do
   q=current._smokeQuads and current._smokeQuads[p.frame or 0]
   if q and current._smokeImage then
    -- Mount above the 64-pixel boat card; the native screen-space offset
    -- would put the puff inside the raised hull. Keep native texture/timing.
    out[#out+1]={kind='smoke',image=current._smokeImage,quad=q,
     x=x-(p.boatOffsetAtSpawn or 0)+22+(p.x2 or 0),y=base-80,base=base,height=64}
   end
  end
  return out
 end
 if oldOk and legacy.spriteSnapshot then return legacy.spriteSnapshot()end
 return{}
end
return S
