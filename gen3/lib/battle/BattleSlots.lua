-- Stable visual identities. Side alone cannot identify a doubles partner.
local S={keys={'player','enemy','playerPartner','enemyPartner'},
 actorKeys={'enemyPartnerTrainer','playerPartnerTrainer','enemyTrainer','playerTrainer','enemyPartner','enemy','player','playerPartner'}}
local ids={player=0,enemy=1,playerPartner=2,enemyPartner=3}
function S.id(key)return type(key)=='number'and key or ids[key]end
function S.key(key)return type(key)=='number'and S.keys[key+1]or key end
function S.player(key)local id=S.id(key);return id~=nil and id%2==0 end
function S.side(key)return S.player(key)and'player'or'enemy'end
function S.mons(st)return st and st.safari and{'enemy'}or st and st.double and S.keys or{'player','enemy'}end
function S.battler(st,key)
 local id=S.id(key)
 if not st or id==nil then return end
 if id==0 then return st.player elseif id==1 then return st.enemy end
 return st.battlers and st.battlers[id]
end
function S.ballId(stage,ball)
 if ball.battler~=nil then return ball.battler end
 for id=0,3 do if stage.balls and stage.balls[id]==ball then return id end end
 return ball.side=='enemy'and 1 or 0
end
function S.trainer(st,id)
 if id==2 and(st.partner or st.multi)then return 'playerPartnerTrainer' end
 if id==3 and(st.trainerB or st.multi)then return 'enemyPartnerTrainer' end
 return S.player(id)and 'playerTrainer'or 'enemyTrainer'
end
local trainerIds={playerTrainer=0,enemyTrainer=1,playerPartnerTrainer=2,enemyPartnerTrainer=3}
function S.trainerGender(st,key)
 local id=trainerIds[key]
 if st.multi and st.linkGenders and id~=nil then return st.linkGenders[id]or 0 end
 return key=='playerTrainer'and st.playerGender or 0
end
return S
