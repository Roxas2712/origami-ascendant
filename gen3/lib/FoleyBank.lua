-- Authored ambience plus the user-selected original Boo laugh.
-- Sources are prepared during mod loading; play never synthesizes samples.
local V=...
local B={sources={}}
B.keys={'thunder-0','thunder-1','thunder-2','wet-1','wet-2','wet-3','wet-4','snow-1','snow-2','snow-3','snow-4','paper-impact','ghost-boo'}
function B.get(key)
 local source=B.sources[key];if source then return source end
 if not(love.audio and love.sound)then return end
 local raw=V.mod:read('gen3/data/foley/'..key..'.wav');if not raw then return end
 local fd=love.filesystem.newFileData(raw,key..'.wav')
 local data=love.sound.newSoundData(fd);fd:release()
 source=love.audio.newSource(data,'static');data:release();B.sources[key]=source
 return source
end
function B.prepare()for _,key in ipairs(B.keys)do B.get(key)end end
-- Voices remain bank-owned, allowing weather reset/re-enable without reload.
function B.release()
 for _,source in pairs(B.sources)do source:stop();source:release()end
 B.sources={}
end
return B
