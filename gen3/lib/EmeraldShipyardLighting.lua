-- Light the real two-level workshop, preserving the doorway and gallery void.
local V=...;local S={}
function S.profile(d)
 if not(d and d.mapType==8)then return end
 local p=V.require('EmeraldShipyard').profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors.shipyard.lighting
 if not(p and c.enabled)then return end
 local L=d.midLayout
 if p.upper then
  if L:midAt(8,5)~=0x250 or L:midAt(15,12)~=0x26a then return end
 else
  if L:midAt(6,7)~=0x210 or L:midAt(11,4)~=0x2d0 then return end
 end
 return p.upper and c.upper or c.ground
end
function S.capture(list,o,x,z)
 if not o.kind:match('^yard')then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.shipyard
 local scale=all.heightScale;local base=o.base or 0
 local function box(a,b,back,front,low,high,wall)
  list[#list+1]={lo={x+a,low*scale,z+back},hi={x+b,high*scale,z+front},wall=wall or false}
 end
 if o.kind=='yardDivider'then
  box(2,14,32,144,0,c.wallHeight,true);box(2,14,184,240,0,c.wallHeight,true)
 elseif o.kind=='yardBay'then
  box(0,128,32,48,0,c.bayHeight,true);box(128,144,16,64,0,c.bayHeight,true)
 elseif o.kind=='yardGallery'then
  -- Only the pit lining blocks light. Never enclose the air above the hole.
  for _,b in ipairs({{7,8,8,120},{120,121,8,120},{8,120,7,8},{8,120,120,121}})do
   box(b[1],b[2],b[3],b[4],-c.galleryDepth,0,true)
  end
 elseif o.kind=='yardDesk'then
  box(1,31,15,29,c.deskHeight-c.lighting.slabThickness,c.deskHeight)
  if o.pc then box(3,16,20.75,21.25,c.deskHeight,c.deskHeight+c.pcHeight)end
 elseif o.kind=='yardDraft'then
  box(1,31,6,26,c.deskHeight-c.lighting.slabThickness,c.deskHeight)
 elseif o.kind=='yardCabinet'then box(1,15,22,28,0,c.cabinetHeight)
 elseif o.kind=='yardBoat'then
  box(16,48,40,64,base,base+c.hullHeight)
  box(22,42,64,84,base,base+c.noseHeight)
 elseif o.kind=='yardRig'then
  local h=o.upper and c.upperRigHeight or c.rigHeight
  box(17,47,55.75,56.25,base,base+h*34/46)
  box(27,42,55.75,56.25,base+h*34/46,base+h)
 end
 -- Open lattice girders, thin stock, stools and the model remain alpha-cut
 -- artwork, not opaque rectangular shadow casters. Their contact art stays.
 return true
end
return S
