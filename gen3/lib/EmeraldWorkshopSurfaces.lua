-- Exact native workshop layouts, keeping the glassware and treehouse artwork.
local V=...
local W={}
local specs={EM_FORTREE_CITY_DECORATION_SHOP={8,6,0x3c8},EM_ROUTE113_GLASS_WORKSHOP={10,10,0x2e3}}
function W.profile(def)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local id=def.id or def.name
 local s=specs[id];local L=def.midLayout
 if cfg.enabled and cfg.workshops.enabled and s and def.pair=='building__generic_building'
  and L and L.width==s[1]and L.height==s[2]and L:midAt(0,0)==s[3]then
  return cfg.homeRooms[V.data('Emerald').homeRooms[id]]
 end
end
function W.counterInside(o,x,y)
 if o.right then x=47-x end
 if y<11 or y>=31 then return false end
 if y<=26 then return x>=10 and x<46 end
 if y==27 then return x>=11 and x<45 end
 return x>=12 and x<15 or x>=41 and x<44
end
function W.plan(def,p)
 if p.style=='tatami'then return V.require('EmeraldGuestSurfaces').plan(def,p)end
 local L=def.midLayout;local objects,mask=V.require('EmeraldTimberSurfaces').plan(def,p)
 for _,o in ipairs(objects)do
  if o.kind=='corner'then
   -- Native display tops replace the original lower corner tile. They are
   -- separate furniture now, so the wall return uses its clean native donor.
   o.sourceRows=o.right and{0x3ca,0x3d2,0x3da}or{0x3c8,0x3d0,0x3d8}
  end
 end
 for _,x in ipairs({0,5})do
  objects[#objects+1]={kind='workshopCounter',x=x,y=2,w=48,h=32,front=31,right=x>0,noContact=true}
  for yy=2,3 do for xx=x,x+2 do
   local k=yy*L.width+xx+1
   if not(type(mask[k])=='table'and mask[k].void)then mask[k]=p.floor end
  end end
 end
 return objects,mask
end
function W.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.workshops
 local function draw(a,b,project)
  local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local vertices=V.require('PaperSprite').build(ts,o.w,o.h,source,
   function(s,t)return t>=a and t<b and W.counterInside(o,s,t)end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vertices)do v[2]=v[2]*cfg.heightScale;out[#out+1]=v end
 end
 draw(11,25,function(s,t)return{x+s,c.counterHeight,z+o.front-c.counterDepth+(t-11)*c.counterDepth/14}end)
 draw(25,31,function(s,t)return{x+s,c.counterHeight*(31-t)/6,z+o.front}end)
 if contacts then
  local a,b=o.right and 2 or 10,o.right and 38 or 46
  for xx=x+a+4,x+b-3,8 do contacts[#contacts+1]={xx,z+o.front,6,2,cfg.contactStrength}end
 end
end
return W
