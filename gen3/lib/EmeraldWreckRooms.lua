-- Constructed rooms can have the native CAVE map header. Keep original data;
-- dispatch only measured wreck layouts, never every cave or facility tileset.
local V=...;local W={}
function W.profile(d)
 local water=V.require('EmeraldWreckUnderwater').profile(d);if water then return water end
 local hall=V.require("EmeraldWreckCorridors").profile(d);if hall then return hall end
 local cabin=V.require("EmeraldWreckCabins").profile(d);if cabin then return cabin end
 local a=V.require('DioramaConfig').emeraldInteriors;local c=a.wreck;local L=d and d.midLayout
 if a.enabled and c.enabled and d and (d.id or d.name)=='EM_ABANDONED_SHIP_CAPTAINS_OFFICE'
  and tonumber(d.mapType)==4 and d.pair=='general__facility'and L and L.width==10 and L.height==8
  and L:midAt(0,0)==0x2f8 and L:midAt(3,1)==0x2b8 and L:midAt(7,1)==0x20e
  and L:midAt(3,5)==0x20c and L:midAt(0,3)==0x3b4 then return c.office end
end
function W.plan(d)
 local c=V.require('DioramaConfig').emeraldInteriors.wreck;local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o end
 for y=0,L.height-1 do for x=0,L.width-1 do
  if y<2 or L:midAt(x,y)==0x201 then mask[y*L.width+x+1]={mid=0x201,void=true}end
 end end
 for x=0,8 do
  add('wall',x,0,1,2,{wallHeight=c.wallHeight,wallBase=32,wallLast=32,
   clean=(x==3 or x==4 or x==7 or x==8)and{0x219,0x221}or nil,nativeUpper=true})
 end
 add('wreckCabinet',3,1,2,2);add('wreckTerminal',0,3,1,2)
 -- These drawings are the exact model cabinet and drafting desk already
 -- measured in Stern's shipyard, not new/replacement furniture artwork.
 add('yardModel',7,1,2,2);add('yardDraft',3,5,2,2)
 for _,x in ipairs{3,4,7,8}do mask[2*L.width+x+1]=0x204 end
 for _,y in ipairs{3,4}do mask[y*L.width+1]=0x203 end
 for y=5,6 do for x=3,4 do mask[y*L.width+x+1]=0x202 end end
 return objects,mask
end
function W.build(out,L,ts,o,x,z,contacts)
 if o.kind:match('^wreckUnderwater')then return V.require('EmeraldWreckUnderwater').build(out,L,ts,o,x,z)end
 if o.kind:match("^wreckHall")then return V.require("EmeraldWreckCorridors").build(out,L,ts,o,x,z,contacts)end
 local a=V.require('DioramaConfig').emeraldInteriors;local c=a.wreck
 local h=o.kind=='wreckTerminal'and c.terminalHeight or c.cabinetHeight
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function inside(s,t)
  if o.kind=='wreckTerminal'then return s<15 and t<24 end
  return t<24 and(t>0 or s>=16)and(t~=1 or s%16>0 and s%16<15)
 end
 local vertices=V.require('PaperSprite').build(ts,o.w,o.h,source,inside,0,o.h,1,nil,
  function(s,t)return{x+s,h*(24-t)/24*a.heightScale,z+24}end,.5)
 for _,v in ipairs(vertices)do out[#out+1]=v end
 if contacts then for sx=4,o.w-2,8 do contacts[#contacts+1]={x+sx,z+24,5,2,c.contactStrength}end end
end
function W.lighting(d)
 local water=V.require('EmeraldWreckUnderwater').lighting(d);if water then return water end
 local hall=V.require("EmeraldWreckCorridors").lighting(d);if hall then return hall end
 local cabin=V.require('EmeraldWreckCabins').lighting(d);if cabin then return cabin end
 if W.profile(d)then return V.require('DioramaConfig').emeraldInteriors.wreck.officeLight end
end
function W.capture(list,o,x,z)
 if V.require('EmeraldWreckUnderwater').capture(list,o,x,z)then return true end
 if V.require("EmeraldWreckCorridors").capture(list,o,x,z)then return true end
 if o.kind~='wreckCabinet'and o.kind~='wreckTerminal'then return false end
 local a=V.require('DioramaConfig').emeraldInteriors;local c=a.wreck
 local h=o.kind=='wreckTerminal'and c.terminalHeight or c.cabinetHeight
 list[#list+1]={lo={x,0,z+23.75},hi={x+o.w-(o.kind=='wreckTerminal'and 1 or 0),h*a.heightScale,z+24.25},wall=false}
 return true
end
return W
