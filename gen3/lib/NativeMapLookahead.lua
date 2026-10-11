-- Hint the host's bounded asset worker about the nearest door/stair/seam.
-- No map load, active tileset switch or synchronous atlas upload is allowed.
local V=...
local N={queued=0}
local map,lastTime
function N.update(game,id,def)
 if V.require('DioramaConfig').renderCache.prefetch==false then N.target=nil;return end
 local now=(V.clock or love.timer.getTime)()
 if map==id and lastTime and now-lastTime<.25 then return end
 map,lastTime=id,now
 local A=V.require('WorldAdapter');local native=A.Native
 if type(native.prefetch)~='function'then return end
 local maps=game and game.data and game.data.maps
 if not maps then return end
 local x,y=(A.Player.px or 0)/16,(A.Player.py or 0)/16
 local best,distance
 local function add(dest,score)
  if dest and dest~=id and maps[dest]and score<=12
   and(not distance or score<distance or score==distance and dest<best)then best,distance=dest,score end
 end
 for _,w in ipairs(def.warps or{})do
  add(w.destMap or w.toMap or w.map or w.target,math.abs(x-(tonumber(w.x)or x))+math.abs(y-(tonumber(w.y)or y)))
 end
 local connections=require('src.core.game3.connections');local w,h=connections.sizeOf(def)
 for _,c in ipairs(connections.each(def))do
  add(c.map,math.max(0,c.dir=='north'and y or c.dir=='south'and h-y or c.dir=='west'and x or w-x))
 end
 N.target=best
 local d=best and maps[best];local pair=d and(d.pair or d.midLayout and d.midLayout.pair)
 if pair and not(native._pairs and native._pairs[pair])then native.prefetch(pair,1);N.queued=N.queued+1 end
end
function N.release()map,lastTime=nil,nil;N.target=nil end
return N
