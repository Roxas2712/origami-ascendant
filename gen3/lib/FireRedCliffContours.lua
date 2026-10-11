-- Shared Kanto primary-atlas variants: sandy rock margins and ledge joins.
-- Native pixel ownership keeps sand/grass at ground level. Collision and
-- traversal stay entirely in the ROM map; stair centres are not cliff tiles.
local V=...
local C={}
local mids={}
for _,mid in ipairs{0x80,0x81,0x82,0x88,0x8a,0x8d,0x8e,0x90,0x92,
 0x98,0x99,0x9a,0x9e,0xa0,0xa1,0xa2,0xa8,0xaa,0x1f1,0x1f2}do mids[mid]=true end
-- Original primary-atlas rock palette, including its grey contact edge.
-- Read before lighting/tints. The sand palettes deliberately do not overlap.
local palette={}
for _,rgb in ipairs{{90,58,66},{123,74,74},{123,123,132},{148,107,107},
 {189,148,140},{222,197,165},{239,214,197}}do
 palette[rgb[1]*65536+rgb[2]*256+rgb[3]]=true
end
function C.applies(def)
 return not V.data('Emerald').map(def)and V.data('Shapes').outdoors(def)
end
function C.variant(def,mid)return C.applies(def)and mids[mid]or false end
function C.pixel(ts,mid,x,y)
 local r,g,b,a=V.require('BuildingMesh').pixel(ts,mid,x,y)
 return a>.5 and palette[math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)]or false
end
-- Atlas pixels are immutable. Read each rock mask once instead of once
-- per boundary query for every cliff tile in a city and its neighbours.
local masks=setmetatable({},{__mode='k'})
function C.mask(ts,mid,variant)
 local bank=masks[ts];if not bank then bank={};masks[ts]=bank end
 local key=mid*2+(variant and 1 or 0);if bank[key]then return bank[key]end
 local out={};local pixel=V.require('BuildingMesh').pixel
 for y=0,15 do for x=0,15 do
  local r,g,b,a=pixel(ts,mid,x,y)
  out[y*16+x+1]=variant and(a>.5 and palette[math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)]or false)
   or not variant and a>.5 and not(g>r+.04 and g>b+.04)
 end end
 bank[key]=out;return out
end
return C
