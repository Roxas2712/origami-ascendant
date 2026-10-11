-- Native indoor families without authored furniture profiles. Keep walkable
-- floor/warp tiles flat; lift bounded solid drawings and rear wall strips.
local V=...
local I={}
function I.plan(def)
 local objects,mask={},{}
 if V.data('Shapes').outdoors(def) or tonumber(def.mapType)~=8 then return objects,mask end
 local L=def.midLayout
 if V.require('SeaCottage').profile(def)then V.require('SeaCottage').plan(def,objects,mask);return objects,mask end
 if V.require('VolunteerHouse').profile(def)then V.require('VolunteerHouse').plan(def,objects,mask);return objects,mask end
 if V.require('InteriorTrashedHouse').profile(def)then V.require('InteriorTrashedHouse').plan(def,objects,mask);return objects,mask end
 if V.require('InteriorDisplayHouses').profile(def)then V.require('InteriorDisplayHouses').plan(def,objects,mask);return objects,mask end
 if V.require('SafariRooms').profile(def)then V.require('SafariRooms').plan(def,objects,mask);return objects,mask end
 if V.require('PowerPlantRoom').profile(def)then V.require('PowerPlantRoom').plan(def,objects,mask);return objects,mask end
 -- Mansion 3F uses native walkable collision 0x2b throughout. Its
 -- measured shell must not be skipped merely because no floor uses 0x00.
 local nativeOpenFloor=V.require("MansionShell").profile(def)or V.data("Emerald").map(def)
 local counts,ground,best={},nil,0
 for _,c in ipairs(L.cells)do
  if (c.coll==0 or nativeOpenFloor and c.coll==0x2b) and c.mid~=0 and c.mid~=8 then
   counts[c.mid]=(counts[c.mid]or 0)+1
   if counts[c.mid]>best then ground,best=c.mid,counts[c.mid]end
  end
 end
 if not ground then return objects,mask end
 local function key(x,y)return y*L.width+x+1 end
 local function solid(x,y)
  if x<0 or y<0 or x>=L.width or y>=L.height then return false end
  local c=L:cellAt(x,y)
  return c.mid~=0 and c.mid~=8 and V.data('Shapes').solid(c)
 end
 local function floor(x,y)
  if x<0 or y<0 or x>=L.width or y>=L.height then return false end
  local c=L:cellAt(x,y)
  return c.mid~=0 and c.mid~=8 and (c.coll==0 or nativeOpenFloor and c.coll==0x2b)
 end
 local seen={}
 for y=0,L.height-1 do for x=0,L.width-1 do
  local k=key(x,y)
  if not seen[k] and solid(x,y)then
   local queue={{x,y}};seen[k]=true
   local n,x0,x1,y0,y1=1,x,x,y,y
   while queue[n]do
    local p=queue[n];n=n+1
    x0,x1,y0,y1=math.min(x0,p[1]),math.max(x1,p[1]),math.min(y0,p[2]),math.max(y1,p[2])
    for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}})do
     local xx,yy=p[1]+d[1],p[2]+d[2];local j=key(xx,yy)
     if not seen[j] and solid(xx,yy)then seen[j]=true;queue[#queue+1]={xx,yy}end
    end
   end
   local w,h=x1-x0+1,y1-y0+1
   -- Large room partitions are handled as rear strips below, never folded
   -- into a single card spanning a whole gym or multi-room building.
   if w<=10 and h<=3 and #queue<=24 then
    for _,p in ipairs(queue)do mask[key(p[1],p[2])]=ground end
   end
  end
 end end
 for y=0,L.height-2 do
  local x=0
  while x<L.width do
   if solid(x,y) and floor(x,y+1) and not mask[key(x,y)]then
    local x0=x
    repeat x=x+1 until x>=L.width or not solid(x,y) or not floor(x,y+1) or mask[key(x,y)]
    if x-x0>=2 then
     for xx=x0,x-1 do
      mask[key(xx,y)]={mid=ground,opaque=true}
      if y<=3 then
       -- Upper wall decorations can have water/walkable behavior bytes.
       -- Their complete native drawing belongs to this rear wall panel.
       for yy=math.max(0,y-2),y-1 do
        local mid=L:midAt(xx,yy)
        if mid~=0 and mid~=8 then mask[key(xx,yy)]={mid=ground,opaque=true}end
       end
      elseif solid(xx,y-1)then mask[key(xx,y-1)]={mid=ground,opaque=true} end
     end
    end
   else x=x+1 end
  end
 end
 -- The Sea Cottage machinery is one connected rear drawing. Its dormant
 -- light tiles have different native collision from their animated variants;
 -- using collision to partition it made the housings change size mid-scene.
 if (def.renderPair or def.pair)=="building__rom_082d4eb4" then
  for y=0,math.min(3,L.height-1)do for x=0,L.width-1 do
   local mid=L:midAt(x,y)
   if mid~=0 and mid~=8 then mask[key(x,y)]={mid=ground,opaque=true}end
  end end
 end
 local authored=V.data('EmeraldInteriors')[def.id or def.name]
 if authored then
  for group,box in ipairs(authored.groups)do
   for y=box[2],box[2]+box[4]-1 do for x=box[1],box[1]+box[3]-1 do
    local c=L:cellAt(x,y)
    if c and c.coll~=0xff and c.coll~=0x72 and not (box.skip and box.skip[c.mid]) then
     mask[key(x,y)]={mid=authored.floor,group=group,opaque=box.opaque==true,opaqueRows=box.opaqueRows,background=box.background,keepPixels=box.keepPixels}
    end
   end end
  end
 end
 V.require('MansionShell').plan(def,objects,mask)
 V.require('MansionFurniture').plan(def,objects,mask)
 V.require("SilphWallPlants").plan(def,objects,mask)
 V.require("SilphStairs").plan(def,objects,mask)
 V.require("SilphCounters").plan(def,objects,mask)
 V.require("SilphEquipment").plan(def,objects,mask)
 V.require("SilphFurniture").plan(def,objects,mask)
 V.require("SilphStorage").plan(def,objects,mask)
 V.require('RocketRoomShell').plan(def,objects,mask)
 V.require('RocketFurniture').plan(def,objects,mask)
 V.require('RocketWarehouse').plan(def,objects,mask)
 V.require('TrainerTowerRooms').plan(def,objects,mask)
 V.require('TrainerTowerLobby').plan(def,objects,mask)
 return objects,mask
end
return I
