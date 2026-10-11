-- Audited room blockers and actor anchors; ramps and relief must remain empty.
-- Live planning and native gate state are always initialized before restore.
local V=...;local R={}
local function eligible(def)
 -- These native lab/center surfaces only register blockers and healing
 -- projection in F.build. Planning still initializes owners and live objects.
 local pair=def and def.pair
 local measured=def and (def.id or ''):match('^FR_')
  and (pair=='oak_lab' or pair=='network') and V.require('IndoorSurfaces').profile(def)
 return def and (measured or V.require('FireRedFireGym').profile(def)
  or V.require('FireRedLeagueRooms').profile(def)or V.require('TanobyChambers').profile(def)or V.require('PowerPlantRoom').profile(def)or V.require('MansionShell').profile(def))
end
local function clone(v)
 if type(v)~='table'then return v end
 local t={};for k,x in pairs(v)do t[k]=clone(x)end;return t
end
local function valid(boxes)
 if type(boxes)~='table'or #boxes>4096 then return false end
 for k,b in pairs(boxes)do
  if type(k)~='number'or k<1 or k>#boxes or k%1~=0 or type(b)~='table'then return false end
  for field in pairs(b)do if field~='lo'and field~='hi'and field~='wall'then return false end end
  if type(b.wall)~='boolean'then return false end
  for _,name in ipairs{'lo','hi'}do
   local v=b[name];if type(v)~='table'or #v~=3 then return false end
   for i,n in pairs(v)do if type(i)~='number'or i<1 or i>3 or i%1~=0 or type(n)~='number'or n~=n or math.abs(n)>=10000000 then return false end end
  end
  for i=1,3 do if b.hi[i]<b.lo[i]then return false end end
 end
 return true
end
local function validAnchors(anchors,L)
 if type(anchors)~='table'then return false end
 for cell,front in pairs(anchors)do
  if type(cell)~='number'or cell%1~=0 or cell<1 or cell>L.width*L.height
   or type(front)~='number'or front%16~=0 or front<=0 or front>L.height*16 then return false end
 end
 return true
end
function R.capture(L)
 local F=V.require('Furniture');local def=L and F.defs[L]
 if not eligible(def)then return end
 local rig=V.require('RoomLightRig')
 if not validAnchors(F.anchors[L]or{},L)then return end
 for _,t in ipairs{F.ramps[L]or{},rig.reliefStones and rig.reliefStones[L]or{},rig.reliefFurniture and rig.reliefFurniture[L]or{}}do
  if next(t)then return end
 end
 local boxes=rig.geometry[L]
 if not valid(boxes)then return end
 return{version=1,id=def.id,boxes=clone(boxes),anchors=clone(F.anchors[L]or{})}
end
function R.restore(state,def,objects)
 if state==nil then return false end
 assert(eligible(def)and type(state)=='table'and state.version==1 and state.id==def.id and valid(state.boxes),'invalid furniture registration')
 local F=V.require('Furniture');local L=def.midLayout
 local anchors=state.anchors
 if anchors==nil and not V.require('MansionShell').profile(def)then anchors={}end
 assert(validAnchors(anchors,L),'invalid furniture anchors')
 -- F.plan ran immediately before this call: family registries and quiz gates
 -- reflect the same native layout/configuration guarded by the cache key.
 assert(F.ramps[L]and not next(F.ramps[L]),'unexpected restored ramps')
 V.require('CenterHealingSurface').bind(def,objects)
 local rig=V.require('RoomLightRig');rig.begin(L,def)
 assert(rig.geometry[L],'room profile missing')
 rig.geometry[L]=clone(state.boxes);F.anchors[L]=clone(anchors)
 return true
end
return R
