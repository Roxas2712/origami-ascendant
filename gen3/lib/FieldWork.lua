-- Presentation scheduling only: never consumes input or changes simulation.
local V=...
local W={available=true}
local busyUntil=0
function W.update(game,presentation)
 local now=(V.clock or love.timer.getTime)()
 local p=V.require('WorldAdapter').Player
 local input=game and game.input
 local busy=not presentation and(p.moving or input and input.isDown and
  (input:isDown('up')or input:isDown('down')or input:isDown('left')or input:isDown('right')))
 if busy then busyUntil=now+.25 end
 W.available=not presentation and not busy and now>=busyUntil
 return W.available
end
function W.reset()busyUntil=0;W.available=true end
return W
