-- Native artwork bounds measured on BPEE layouts, in 16px metatile cells.
-- Include painted object tops/feet even where the cartridge marks them walkable.
-- Only the first two rear rows are wall artwork; floor-colored pixels below
-- them are cut away, including the lab's shadowed floor palette.
-- Rugs, exit warps and ordinary floor remain native ground surfaces.
local kitchenFronts={
 -- Drawer wood shares the exact floor palette but belongs to the cabinet.
 [0x239]={{1,9,15,7}},[0x23a]={{0,9,14,7}},
}
return {
 EM_LITTLEROOT_TOWN_BRENDANS_HOUSE_1F={floor=0x201,groups={
  {0,0,7,3,opaqueRows=2,keepPixels=kitchenFronts},{2,4,3,2},
 }},
 EM_LITTLEROOT_TOWN_MAYS_HOUSE_1F={floor=0x201,groups={
  {4,0,7,3,opaqueRows=2,keepPixels=kitchenFronts},{6,4,3,2},
 }},
 EM_LITTLEROOT_TOWN_BRENDANS_HOUSE_2F={floor=0x201,groups={{0,0,6,3,opaqueRows=2},{1,3,3,3}}},
 EM_LITTLEROOT_TOWN_MAYS_HOUSE_2F={floor=0x201,groups={{3,0,6,3,opaqueRows=2},{6,3,3,3}}},
 EM_LITTLEROOT_TOWN_PROFESSOR_BIRCHS_LAB={floor=0x202,groups={
  {0,0,13,3,opaqueRows=2,background={0x23e}}, -- Rear instruments, notices, desk and shelves.
  {0,5,4,3}, -- Both bookcases, including their walkable top artwork.
  {10,6,3,3}, -- Healing/research machine, including painted feet.
  {0,9,3,3,skip={[0x204]=true}},{10,9,3,4}, -- Front workstations.
 }},
}
