-- Project native screen-OAM healing art onto its measured room surfaces.
-- The engine owns frames, palettes, timing and party changes.
local V=...
local H={rooms=setmetatable({},{__mode='k'})}
function H.bind(def,objects)
 local L=def and def.midLayout;if not L then return end
 H.rooms[L]=nil
 local id=def.id or def.name or''
 if not(id:match('_POKEMON_CENTER_1F$')or id=='EM_EVER_GRANDE_CITY_POKEMON_LEAGUE_1F'
  or id=='SEVII_ONE_ISLAND_POKECENTER')then return end
 local emerald=id:match('^EM_')~=nil
 if not emerald and not V.require('IndoorSurfaces').profile(def)then return end
 H.rooms[L]={objects=objects,emerald=emerald}
end
function H.surface(def,x,y,w,h,kind)
 local room=def and H.rooms[def.midLayout];if not room then return end
 local cfg=V.require('DioramaConfig');local scale=room.emerald and cfg.emeraldInteriors.heightScale or cfg.interiors.heightScale
 local cx,cy=x+w/2,y+h/2
 local function quad(point)return{point(x,y),point(x+w,y),point(x+w,y+h),point(x,y+h)}end
 for _,o in ipairs(room.objects)do
  local left,top=o.x*16,o.y*16
  local width=room.emerald and o.w or(o.w or 1)*16
  if cx>=left and cx<left+width then
   if room.emerald and o.kind=='card'and o.opaque and cy>=top+o.cap and cy<top+o.last and kind=='ball'then
    return quad(function(s,t)return{s,((o.base or 0)+(o.last-(t-top))*(o.height or o.last-o.cap)/(o.last-o.cap))*scale,top+o.front+.05}end)
   elseif not room.emerald and o.kind=='panel'and o.contour and cy>=top and cy<top+o.last and kind=='ball'then
    return quad(function(s,t)return{s,((o.base or 0)+o.last-(t-top))*scale,top+(o.front or o.last)+.05}end)
   elseif kind=='monitor'and o.kind=='receptionMonitor'and cy>=top and cy<top+32 then
    return quad(function(s,t)return{s,(32-(t-top))*scale,top+o.front+.05}end)
   elseif kind=='monitor'and o.kind=='wall'and cy>=top and cy<top+32 then
    local hh=o.wallHeight or 32
    return quad(function(s,t)return{s,(hh-(t-top))*scale,top+hh+.05}end)
   end
  end
 end
end
return H
