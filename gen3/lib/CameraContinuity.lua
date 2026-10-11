-- Connected maps remap world coordinates; carry the previous camera into that
-- coordinate system before easing differences in map framing. Doors retain
-- their native fade and independent interior framing.
local V=...
local M={origin={0,0}}
function M.install()
 if M.installed then return end;M.installed=true
 local C=require('src.core.game3.collision');local P=require('src.core.game3.player')
 local Audio=require('src.core.game3.audio')
 local playSong=Audio.playSong
 Audio.playSong=function(id,opts)
  -- Only music requested by a native seamless crossing. Battles, fanfares,
  -- doors and scripted songs retain their own timing and ownership.
  local song=Audio.resolveSong(id)
  if M.crossing and song and song~=0 and song~=0xFFFF and Audio._currentSong
    and Audio._bgmSource and not(opts and opts.restart)then
    if Audio.currentMapMusic()==song then return true end
    -- Reversing direction must not restart an already running fade at full
    -- volume. Retarget that fade, or start from the current fade-in gain.
    if Audio._fadeOut and not Audio._fanfareActive then
      Audio._fadeOut.nextSong=song;Audio._fadeOut.fadeIn=5
      return true
    end
    local fadeIn=Audio._fadeIn
    local result=Audio.fadeOutAndPlay(song,3,5)
    if fadeIn and Audio._fadeOut and not Audio._fanfareActive then
      Audio._fadeOut.start=(Audio._bgmVolume or 1)*math.min(1,fadeIn.t/math.max(.01,fadeIn.dur))
      Audio._fadeIn=nil
    end
    return result
  end
  return playSong(id,opts)
 end
 local original=C.tryConnection
 C.tryConnection=function(game,...)
  local x,z=P.px,P.py
  M.crossing=true
  local result={pcall(original,game,...)};M.crossing=false
  if not result[1]then error(result[2],0)end
  if result[2]then
   local dx,dz=P.px-x,P.py-z
   M.origin[1],M.origin[2]=M.origin[1]-dx,M.origin[2]-dz
   V.require('Camera').connect(dx,dz,P.px,P.py)
  end
  return unpack(result,2)
 end
end
return M
