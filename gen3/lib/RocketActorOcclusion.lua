-- Rocket boundary BG2 contains opaque void pixels which cover native actors.
-- The room mesh correctly omits void, so retain its original actor mask only.
local V=...;local R={borders=setmetatable({},{__mode='k'}),pixels=setmetatable({},{__mode='k'})}
function R.rectangles(def,ts,x,z,w,h)
 local shell=V.require('RocketRoomShell')
 if not shell.profile(def)or not ts or not ts.overImageData then return end
 local L=def.midLayout;local objects=shell.rooms[L];if not objects then return end
 local borders=R.borders[objects]
 if not borders then
  borders={};for _,o in ipairs(objects)do if o.kind=='rocketBorder'then borders[o.y*L.width+o.x]=true end end
  R.borders[objects]=borders
 end
 local masks=R.pixels[ts.overImageData]
 if not masks then masks={};R.pixels[ts.overImageData]=masks end
 local function mask(cx,cy)
  if cx<0 or cy<0 or cx>=L.width or cy>=L.height or not borders[cy*L.width+cx]then return end
  local mid=L:midAt(cx,cy);local p=masks[mid]
  if p==nil then
   p={};local slot=ts.midToSlot[mid]
   if slot then for v=0,15 do for u=0,15 do
    local r,g,b,a=ts.overImageData:getPixel(slot%ts.cols*16+u,math.floor(slot/ts.cols)*16+v)
    if a>.5 and r+g+b<.01 then p[v*16+u]=true end
   end end end
   if not next(p)then p=false end;masks[mid]=p
  end
  return p
 end
 -- Most actors do not touch a boundary: preserve their single-quad fast path.
 local hit=false
 for cy=math.floor(z/16),math.floor((z+h-1)/16)do for cx=math.floor(x/16),math.floor((x+w-1)/16)do
  if mask(cx,cy)then hit=true end
 end end
 if not hit then return end
 local out,removed,previous={},false,{}
 for t=0,h-1 do
  local start;local current={}
  for s=0,w do
   local visible=s<w
   if visible then
    local wx,wz=math.floor(x+s),math.floor(z+t);local p=mask(math.floor(wx/16),math.floor(wz/16))
    if p and p[(wz%16)*16+wx%16]then visible=false;removed=true end
   end
   if visible and not start then start=s
   elseif not visible and start then
    local key=start..':'..s;local rect=previous[key]
    if rect then rect[4]=t+1 else rect={start,t,s,t+1};out[#out+1]=rect end
    current[key]=rect;start=nil
   end
  end
  previous=current
 end
 return removed and out or nil
end
return R
