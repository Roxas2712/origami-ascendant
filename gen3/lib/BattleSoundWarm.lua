-- Schedule the engine's own SE and intro/faint-cry warmers; read animation scripts only.
-- Never execute scripts, play sounds, or alter moves / battle state here.
local V=...
local S={stats={requests=0,moves=0,sounds=0,cries=0},elapsed=0}
local soundOps={playse=true,playsewithpan=true,loopsewithpan=true,waitplaysewithpan=true,
 panse=true,panse_adjustnone=true,panse_adjustall=true}
local links={'label','target','label1','label2'}
function S.collect(pack,script,enemy)
 local sounds,seen,pans={},{},{}
 local function pan(v)
  v=tonumber(v)or((v=='SOUND_PAN_TARGET'or v=='TARGET')and 63)or((v=='SOUND_PAN_ATTACKER'or v=='ATTACKER')and -64)or 0
  if enemy then v=-v end;return math.max(-64,math.min(63,v))
 end
 local function add(id,p)
  if type(id)=='number'or type(id)=='string'then
   sounds[id]=true;pans[id]=pans[id]or {};pans[id][p or 0]=true
  end
 end
 local function visit(ops)
  if type(ops)~='table'or seen[ops]then return end;seen[ops]=true
  for _,op in ipairs(ops)do if type(op)=='table'then
   if soundOps[op.op]then add(op.song or op.se or op.id or op[1],op.op=='playse'and 0 or pan(op.pan))end
   if op.op=='createsoundtask'then
    local task,args=op.task or op.name,op.args or {}
    if task=='SoundTask_FireBlast'then
     local p,target=pan(-64),pan(63);local step=p<target and 2 or -2
     for frame=1,111 do
      if (frame-1)%11==0 then add(args[1],p)end
      p=math.max(-64,math.min(63,p+step))
     end
     add(args[2],target)
    elseif task=='SoundTask_LoopSEAdjustPanning'then
     local p,target=pan(args[2]),pan(args[3]);local step=math.abs(tonumber(args[4])or 0)
     if p>target then step=-step elseif p==target then step=0 end
     local plays=(tonumber(args[5])or 0)%256
     local panWait=(tonumber(args[6])or 0)%256;local soundWait=(tonumber(args[7])or 0)%256
     local pc,sc=0,soundWait
     add(args[1],p)
     -- Bounded prediction of this native task, not execution of the VM.
     for _=1,math.min(4096,plays*(soundWait+1))do
      local old=sc;sc=sc+1
      if old==soundWait then sc=0;add(args[1],p);plays=plays-1;if plays==0 then break end end
      old=pc;pc=pc+1;if old==panWait then pc=0;p=math.max(-64,math.min(63,p+step))end
     end
    elseif task=='SoundTask_PlaySE1WithPanning'or task=='SoundTask_PlaySE2WithPanning'then add(args[1],pan(args[2]))end
   end
   for _,key in ipairs(links)do visit(pack.labels and pack.labels[op[key]])end
  end end
 end
 visit(script);return sounds,pans
end
local function moveId(value)
 if type(value)=='table'then value=value.id or value.moveId or value.move end
 if type(value)=='number'then return value end
 if type(value)=='string'then
  return tonumber(value)or require('src.core.game3.battle.moves').numForName(value)
 end
end
function S.request(parties)
 if require('src.core.GameVersion').get()~='firered'then return end
 local Anim=require('src.core.game3.battle.anim');local pack=Anim._pack
 local Audio=require('src.core.game3.audio')
 if not(Anim._packLoaded and pack and pack.moves and Audio.isReady()and type(Audio.prewarmSe)=='function')then return end
 local moves,cries,cryIds={},{},{}
 for side,party in ipairs(parties)do for slot,mon in ipairs(party)do
  if type(mon)=='table'and not(mon.egg or mon.isEgg)then
   for _,move in ipairs(mon.moves or {})do local id=moveId(move);if id and id>0 then moves[side..':'..id]={id=id,enemy=side>1}end end
   -- Prepare the native send-out and faint variants ahead of playback.
   -- Native synthesis yields through Warm; only two legal parties are queued.
   -- Keep the engine's 24-entry cry cache and playback unchanged.
   local species=tonumber(mon.species)
   if side<=2 and slot<=6 and species and species>0 and type(Audio.prewarmCry)=='function'then
    local intro=require('src.core.game3.battle.intro_seq')
    local release=side==1 and intro.releaseCryMode and intro.releaseCryMode(mon)or 0
    local key=side..':'..species..':'..release
    if not cries[key]then cries[key]={species=species,pan=side==1 and -25 or 25,release=release};cryIds[#cryIds+1]=key end
   end
  end
 end end
 local ids={};for id in pairs(moves)do ids[#ids+1]=id end;table.sort(ids)
 table.sort(cryIds)
 local signature=table.concat(ids,',')..'/cries:'..table.concat(cryIds,',')..'/'..tostring(Audio._sfxVolume or 1)..'/'..tostring(Audio._mono)
 if S.pack==pack and S.audioPack==Audio._pack and S.signature==signature then return end
 local audioPack=Audio._pack
 S.pack,S.audioPack,S.signature=pack,audioPack,signature
 S.stats.requests=S.stats.requests+1
 local Warm=require('src.core.game3.warm')
 local request=S.stats.requests
 Warm.add('oasc:battle-sounds:'..request,function()
  if require('src.core.GameVersion').get()~='firered'or Anim._pack~=pack or Audio._pack~=audioPack then return end
  for _,key in ipairs(cryIds)do
   local cry=cries[key]
   for _,mode in ipairs{cry.release,5}do
    if Audio.prewarmCry(cry.species,mode,cry.pan,4)then S.stats.cries=S.stats.cries+1 end
   end
  end
  local queued,variants={},{};local variantCount=0
  local function queuePan(se,p,common)
   local vk=tostring(se)..':'..p
   if variants[vk]or(not common and variantCount>=16)or p==0 or type(Audio._seSourceFor)~='function'then return end
   variants[vk]=true;if not common then variantCount=variantCount+1 end
   local soundId=require('src.core.game3.se_ids').resolve(se)
   if soundId then Warm.add('oasc:se-pan:'..soundId..':'..p,function()
    if require('src.core.GameVersion').get()~='firered'or Audio._pack~=audioPack then return end
    local raw=Audio._seRaw and Audio._seRaw[soundId]
    if raw and not raw.loop then
     -- Native cache key includes gain, pan, mono and PCM identity; no play().
     Audio._seSourceFor(soundId,raw.rawL,raw.rawR,Audio._sfxVolume or 1,p,Audio._mono,false)
    end
   end,5)end
  end
  -- Native AnimSeq pans the three hit-strength sounds to the damaged side.
  local SE=require('src.core.game3.se_ids')
  for _,name in ipairs{'SE_BALL_OPEN','SE_NOT_EFFECTIVE','SE_EFFECTIVE','SE_SUPER_EFFECTIVE'}do
   local se=SE[name]
   if se then Audio.prewarmSe(se,4);if name~='SE_BALL_OPEN'then queuePan(se,-64,true);queuePan(se,63,true)end end
  end
  for _,key in ipairs(ids)do
   if require('src.core.GameVersion').get()~='firered'or Anim._pack~=pack then return end
   local move=moves[key];local script=pack.moves[move.id]or pack.moves[tostring(move.id)]
   local sounds,pans=S.collect(pack,script,move.enemy)
   local ordered={};for se in pairs(sounds)do ordered[#ordered+1]=se end;table.sort(ordered,function(a,b)return tostring(a)<tostring(b)end)
   for _,se in ipairs(ordered)do if not queued[se]then
    queued[se]=true;if Audio.prewarmSe(se,4)then S.stats.sounds=S.stats.sounds+1 end
   end
    local ps={};for p in pairs(pans[se])do ps[#ps+1]=p end;table.sort(ps)
    for _,p in ipairs(ps)do queuePan(se,p,false)end
   end
   S.stats.moves=S.stats.moves+1;Warm.yield()
  end
 end,3)
end
function S.update(game,dt)
 S.elapsed=S.elapsed+(tonumber(dt)or 0)
 if S.elapsed<.25 then return end;S.elapsed=0
 local B=require('src.core.game3.battle');local state=B.isActive()and B.getState()
 if state then
  S.request{state.playerParty or {},state.foeParty or {state.enemy and state.enemy.mon}}
 elseif game and game.session then S.request{game.session.party or {}}end
end
function S.install()
 if S.installed then return end;S.installed=true
 S.offUpdate=V.mod.hooks:wrap('core.update',function(nextFn,game,dt)S.update(game,dt);return nextFn(game,dt)end)
 S.offStart=V.mod.events:on('battle.started',function(event)
  local state=event and event.battle
  if state then S.request{state.playerParty or {},state.foeParty or {state.enemy and state.enemy.mon}}end
 end)
end
return S
