-- Native opaque sprite bounds, reserved for the whole party before placement.
-- Measuring each image once keeps switches from moving an established arena.
local V=...
local F={}
local measured=setmetatable({},{__mode='k'})
function F.image(image,height)
 if not image then return {left=height*.55,right=height*.55,height=height}end
 local m=measured[image]
 if not m then
  local canvas=love.graphics.newCanvas(64,64,{dpiscale=1})
  love.graphics.push('all')
  love.graphics.setCanvas(canvas);love.graphics.origin();love.graphics.setShader()
  love.graphics.setScissor();love.graphics.setDepthMode();love.graphics.setColor(1,1,1,1)
  love.graphics.setBlendMode('replace','premultiplied');love.graphics.clear(0,0,0,0)
  love.graphics.draw(image);love.graphics.pop()
  local data=canvas:newImageData();local l,t,r,b=64,64,-1,-1
  for y=0,63 do for x=0,63 do local _,_,_,a=data:getPixel(x,y)
   if a>.5 then l=math.min(l,x);r=math.max(r,x);t=math.min(t,y);b=math.max(b,y)end
  end end
  data:release();canvas:release()
  m=b>=t and {left=math.max(0,32-l)/(b-t+1),right=math.max(0,r+1-32)/(b-t+1)}or{left=.55,right=.55}
  measured[image]=m
 end
 return {left=m.left*height,right=m.right*height,height=height}
end
local function merge(a,b)
 a.left=math.max(a.left,b.left);a.right=math.max(a.right,b.right);a.height=math.max(a.height,b.height)
end
function F.party(party,active,cfg)
 local Pokemon=require('src.core.game3.pokemon')
 local result={left=0,right=0,height=0}
 local function include(mon)
  if not mon then return end
  mon=mon.mon or mon
  local species=mon.species or mon.speciesId
  if not species then return end
  local pic=Pokemon.frontPic(species,mon.form)
  local height=V.require('battle/SpriteSize').height((Pokemon.dexEntry(species)or{}).height,cfg.spriteHeight)
  merge(result,F.image(pic and pic.image,height))
 end
 for _,mon in ipairs(party or{})do include(mon)end;include(active)
 if result.height==0 then return F.image(nil,cfg.spriteHeight*1.5)end
 return result
end
function F.forBattle(battle,cfg)
 battle=battle or{}
 local pic
 if require('src.core.GameVersion').get()=='emerald'then
  local ids=require('src.core.game3.constants').of('emerald').trainer_classes.byName
  pic=battle.playerGender==1 and ids.TRAINER_PIC_MAY or ids.TRAINER_PIC_BRENDAN
 else
  local ids=require('src.import.gba.versions')
  pic=battle.playerGender==1 and ids.TRAINER_PIC_LEAF or ids.TRAINER_PIC_RED
 end
 local Trainer=require('src.core.game3.trainer_pic')
 local player=pic and Trainer.front(pic)
 local enemy=battle.trainerPicId and Trainer.front(battle.trainerPicId)
 return {player=F.party(battle.playerParty,battle.player,cfg),enemy=F.party(battle.foeParty,battle.enemy,cfg),
  playerTrainer=F.image(player and player.image,cfg.trainerHeight),
  enemyTrainer=F.image(enemy and enemy.image,cfg.trainerHeight)}
end
return F
