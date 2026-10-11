-- Native exterior sign ink. Each rendered map owns its badge colour, including
-- connected-map and mirror passes; indoor glass lighting remains independent.
local V=...
local M={}
local colours={
 FR_PEWTER_CITY={.78,.76,.70},FR_CERULEAN_CITY={.45,.75,1},
 FR_VERMILION_CITY={1,.84,.35},FR_CELADON_CITY={1,.72,.80},
 FR_FUCHSIA_CITY={1,.55,.80},FR_SAFFRON_CITY={1,.80,.35},
 FR_CINNABAR_ISLAND={1,.52,.30},FR_VIRIDIAN_CITY={.55,.90,.50},
 EM_RUSTBORO_CITY={.74,.72,.66},EM_DEWFORD_TOWN={1,.64,.35},
 EM_MAUVILLE_CITY={1,.85,.35},EM_LAVARIDGE_TOWN={1,.42,.30},
 EM_PETALBURG_CITY={.93,.92,.84},EM_FORTREE_CITY={.55,.80,1},
 EM_MOSSDEEP_CITY={1,.57,.75},EM_SOOTOPOLIS_CITY={.40,.70,1},
}
local off={0,0,0}
function M.color(def)return def and colours[def.id or def.name]or off end
-- Rectangles contain only letter ink, selected from native red pixels. The
-- pale plate, stone surrounds, doors and roof never enter the emission mask.
local fr={{0x151,6,14,15,15},{0x152,0,14,0,15},{0x159,6,0,15,0},
 {0x15a,0,0,0,0},{0x311,6,0,15,0},{0x312,0,0,0,0}}
local em={{0x1c1,3,11,13,13},{0x234,3,11,13,13},{0x2a7,3,7,13,9}}
function M.write(ts,data)
 local edition=require('src.core.GameVersion').get()
 local rects=edition=='emerald'and em or fr;local count=0
 local pixel=V.require('BuildingMesh').pixel
 local function mark(mid,x,y)
  local slot=ts.midToSlot[mid];if not slot then return end
  local ax,ay=slot%ts.cols*16+x,math.floor(slot/ts.cols)*16+y
  local r,g,b=data:getPixel(ax,ay);data:setPixel(ax,ay,r,g,b,.25);count=count+1
 end
 for _,r in ipairs(rects)do if ts.midToSlot[r[1]]then
  for y=r[3],r[5]do for x=r[2],r[4]do
   local red,green,blue=pixel(ts,r[1],x,y)
   if red>.58 and green<.44 and blue<.44 then mark(r[1],x,y)end
  end end
 end end
 -- Kanto also has the native pale ball on the central golden fascia. Its
 -- silhouette is measured separately, excluding the golden plate itself.
 if edition~='emerald'and ts.midToSlot[0x153]then
  for y=2,13 do for x=2,13 do
   local red,green,blue=pixel(ts,0x153,x,y)
   if red>.84 and green>.84 and blue>.65 and math.abs(red-green)<.08 then mark(0x153,x,y)end
  end end
 end
 return count
end
return M
