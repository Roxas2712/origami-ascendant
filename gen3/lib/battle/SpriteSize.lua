-- Battle readability takes priority over literal dex proportions. Compress
-- decimetre heights: Charmander reaches roughly the 34-unit trainer's waist,
-- while big species still read as big. Preserve each sprite's aspect ratio.
local Size={}
function Size.height(decimetres, reference)
 reference=reference or 28
 local h=tonumber(decimetres)
 if not h or h<=0 or h~=h then return reference end
 return math.max(reference*.6,math.min(reference*1.5,reference*math.sqrt(h/12)))
end
return Size
