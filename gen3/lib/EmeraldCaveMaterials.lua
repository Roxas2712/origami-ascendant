-- Native rock materials for cave volume sides.
-- The lower half of a boundary/cap metatile often contains FLOOR. Stretching
-- that half down a wall repeats the diagonal floor pattern as horizontal bands.
-- 334 is the complete native rock face in the same palette; caps stay native.
local V=...
local M={}
function M.family(mid)
 if mid==0x237 then return 0x2f9 end
 if mid==0x30f or mid>=0x317 and mid<=0x33a then return 0x334 end
 if mid>=0x208 and mid<=0x23b and mid~=0x20c and mid~=0x214 and mid~=0x22b and mid~=0x233 then return 0x219 end
 if mid>=0x378 and mid<=0x38f and mid~=0x37d and mid~=0x37e and mid~=0x37f and mid~=0x38b then return 0x389 end
end
function M.side(d,mid)
 local cfg=V.require('DioramaConfig').terrain.caveMaterials
 if not cfg.enabled then return nil end
 if not d or d.pair~='general__cave' or tonumber(d.mapType)~=4 or not V.data('Emerald').map(d)then return nil end
 local family=M.family(mid)
 if family==0x334 then return family end
 -- Keep holes/door frames and unrelated art out of the material family.
 if cfg.brown and(family==0x219 or family==0x2f9)or cfg.ice and family==0x389 then return family end
end
return M
