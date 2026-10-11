-- Native primary Center/Mart emblems, measured in source pixels. These masks
-- select the ball, never the surrounding sign plate, roof or facade lettering.
-- A draw-only atlas resource: cached geometry and native artwork stay intact.
local V=...
local B={}
local frRows={{5,10},{3,12},{2,13},{1,14},{0,15},{0,15},{0,15},{1,14},{2,13},{3,12},{4,11},{5,10},{5,10}}
local martRows={{13,18},{12,19},{11,20},{10,21},{10,21},{9,22},{9,22},{9,22},{9,22},{9,22},{10,21},{10,21},{11,20},{12,19},{13,18},{14,17}}
local hoennRows={{14,17},{12,19},{10,21},{9,22},{9,22},{8,23},{9,22},{9,22},{9,22},{10,21},{11,20},{12,19},{13,18},{14,17}}
function B.regions(edition)
 if edition=='firered'or edition=='leafgreen'then
  return {{mids={{0x5a}},rows=frRows,y=2},{mids={{0x39,0x3a}},rows=martRows,y=0}}
 elseif edition=='emerald'then
  return {{mids={{0x51,0x52},{0x59,0x5a}},rows=hoennRows,y=9},
   {mids={{0x31,0x32},{0x39,0x3a}},rows=hoennRows,y=9}}
 end
 return {}
end
-- Alpha in the existing glass atlas is reserved for badge ink. Glass/ghost
-- ownership and floor water exclusion keep their original RGB channels.
function B.write(ts,data)
 local count=0
 for _,r in ipairs(B.regions(require('src.core.GameVersion').get()))do
  for row,span in ipairs(r.rows)do
   local y=r.y+row-1;local cells=r.mids[math.floor(y/16)+1]
   if cells then for x=span[1],span[2]do
    local mid=cells[math.floor(x/16)+1];local slot=mid and ts.midToSlot[mid]
    if slot then
     local ax,ay=slot%ts.cols*16+x%16,math.floor(slot/ts.cols)*16+y%16
     local red,green,blue=data:getPixel(ax,ay);data:setPixel(ax,ay,red,green,blue,1);count=count+1
    end
   end end
  end
 end
 return count
end
return B
