-- Measured public-room lighting; native NPCs, BP menus and room art stay owned
-- by the engine. A hanging cabinet must not shadow the empty space beneath it.
local V=...;local S={}
function S.profile(d)
 local p=V.require('EmeraldFrontierLounges').profile(d);local key
 if p then key=d.midLayout.width==14 and 'wide'or'lounge'
 elseif V.require('EmeraldFrontierExchange').profile(d)then key='exchange'end
 if not key then return end
 local c=V.require('DioramaConfig').emeraldInteriors.frontierSocialLighting
 return c.enabled and c[key]or nil
end
function S.capture(list,o,x,z)
 local cfg=V.require('DioramaConfig').emeraldInteriors
 local c,ec,lc=cfg.frontierLounges,cfg.frontierExchange,cfg.frontierSocialLighting
 local function box(a,b,u,v,low,high)
  list[#list+1]={lo={x+a,low*cfg.heightScale,z+u},hi={x+b,high*cfg.heightScale,z+v},wall=false}
 end
 if o.kind=='frontLoungePlant'then
  -- Retain the native alpha-masked contact, not the rectangular sprite quad.
 elseif o.kind=='frontLoungeDevice'then box(0,16,40-c.deviceDepth,40,0,c.deviceHeight)
 elseif o.kind=='frontLoungeSeat'then
  box(o.right and 1 or 5,o.right and 11 or 15,4,o.h-3,math.max(0,c.seatHeight-lc.slabThickness),c.seatHeight)
  box(o.right and 11 or 3,o.right and 13 or 5,1,o.h-3,0,c.backHeight)
 elseif o.kind=='exchangeCounter'then
  box(0,16,18,96,0,ec.counterHeight);box(128,144,18,96,0,ec.counterHeight)
  box(16,128,86,96,0,ec.counterHeight)
 elseif o.kind=='exchangeShelves'then
  box(0,32,64-ec.shelfDepth,64,0,ec.shelfHeight)
  box(80,112,64-ec.shelfDepth,64,0,ec.shelfHeight)
  box(32,80,64-ec.shelfDepth,64,ec.shelfHeight*16/42,ec.shelfHeight)
 elseif o.kind=='exchangeTerminal'then box(0,16,40-ec.terminalDepth,40,0,ec.terminalHeight)
 else return false end
 return true
end
return S
