-- Read-only bridge for native ash puffs/launches in the two measured gym floors.
local V=...
local A={}
function A.sprites(def,fx)
 local room=V.require('EmeraldLavaridgeGym')
 if not room.profile(def)or not V.require('DioramaConfig').emeraldInteriors.lavaridgeGym.nativeAsh then return{}end
 if not fx then local ok,m=pcall(require,'src.core.game3.field_effects_rse');if ok then fx=m end end
 local out={}
 for _,e in ipairs(fx and fx._list or{})do
  if(e.name=='ash_puff'or e.name=='ash_launch')and not e.hidden and(not e.delay or e.delay<=0)then
   local sheet,a=e.sheet,e.a;local q=sheet and a and sheet.quads[a.frame or 0]
   if q then
    local cy=math.floor(e.y/16);local cx=math.floor(e.x/16)
    out[#out+1]={image=sheet.image,quad=q,x=e.x-sheet.fw/2,z=e.y-sheet.fh/2,
     base=e.y+sheet.fh/2,lift=room.actorHeight(def,cx*16,cy*16)or 0,
     flip=a.hflip,vflip=a.vflip}
   end
  end
 end
 return out
end
return A
