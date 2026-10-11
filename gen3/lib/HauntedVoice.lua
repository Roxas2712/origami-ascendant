-- One accepted apparition owns both its voice and visual transformation.
local V=...
local S={lastPlayed=-math.huge}
function S.start(time,x,z,px,pz,contact)
 local distance=math.sqrt((x-px)^2+(z-pz)^2)
 if not contact and(distance>96 or time>=S.lastPlayed and time-S.lastPlayed<80)then return false end
 local volume=require('src.core.game3.audio')._sfxVolume or 1
 -- Respect mute while keeping the visual event; unmuting never replays it.
 if volume<=0 then S.lastPlayed=time;return true end
 local voice=V.require('FoleyBank').get('ghost-boo');if not voice then return false end
 voice:stop();voice:setVolume(volume*.95*(1-.20*math.min(distance,96)/96));voice:play()
 S.lastPlayed=time;return true
end
function S.reset()
 local voice=V.require('FoleyBank').sources['ghost-boo'];if voice then voice:stop()end
end
return S
