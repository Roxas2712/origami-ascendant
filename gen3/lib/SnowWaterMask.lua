-- Render-only water ink in mixed coastal metatiles. Collision marks many
-- sea rocks/ship edges solid; it cannot identify their visible water pixels.
local V=...
local M={}
local function rgb(r,g,b)return r*65536+g*256+b end
function M.bank(ts)
 local entry=ts and require('src.core.game3.tileset_anim')._pairs[ts.pair]
 return entry and not entry.rse and entry.banks and entry.banks.water or nil
end
function M.write(ts,data,bank)
 if not bank or not bank.rgba then return 0 end
 local colors={};local n=#bank.mids
 -- Native FireRed's two complete water donors use the coast and sea palettes.
 -- Read all native frames, never infer water from arbitrary blue artwork.
 for i,mid in ipairs(bank.mids)do if mid==0x12b or mid==0x1d9 then
  for frame=0,bank.frames-1 do for pixel=0,255 do
   local at=(frame*n+i-1)*1024+pixel*4+1
   local r,g,b=bank.rgba:byte(at,at+2);colors[rgb(r,g,b)]=true
  end end
 end end
 if not next(colors)then return 0 end
 local count=0;local marked={};local w,h=data:getDimensions()
 local function mark(x,y)
  local k=y*w+x;if marked[k]then return end;marked[k]=true
  local r,g,b,a=data:getPixel(x,y);data:setPixel(x,y,r,g,1,a);count=count+1
 end
 -- Static portions of ship/shore tiles can retain the same water ink without
 -- belonging to the animation bank themselves.
 local pixels=ts.imageData:getString()
 for at=1,#pixels,4 do
  local r,g,b,a=pixels:byte(at,at+3)
  if a>127 and colors[rgb(r,g,b)]then
   local k=(at-1)/4;mark(k%w,math.floor(k/w))
  end
 end
 -- A foam pixel may be blue water in the next frame. Keep the union stable
 -- for the whole animation, so snowfall cannot flicker with the native waves.
 for i,mid in ipairs(bank.mids)do local slot=ts.midToSlot[mid]
  if slot then for pixel=0,255 do
   for frame=0,bank.frames-1 do
    local at=(frame*n+i-1)*1024+pixel*4+1;local r,g,b,a=bank.rgba:byte(at,at+3)
    if a>127 and colors[rgb(r,g,b)]then mark(slot%ts.cols*16+pixel%16,math.floor(slot/ts.cols)*16+math.floor(pixel/16));break end
   end
  end end
 end
 return count
end
return M
