-- Draw-only sprite fitting. VM coordinates, callbacks and affine state are
-- restored even if a renderer errors, so switching views never mutates combat.
local E={}
function E.scale(sprite,player,enemy)
 local host=sprite.hostId
 if player.all and player.all[host]then return player.all[host][3]end
 if host==0 or host=='player'then return player[3]end
 if host==1 or host=='enemy'then return enemy[3]end
 local px,py=player[4]or player[1],player[5]or player[2]
 local ex,ey=enemy[4]or enemy[1],enemy[5]or enemy[2]
 local dx,dy=ex-px,ey-py
 local t=((sprite.x-px)*dx+(sprite.y-py)*dy)/math.max(.001,dx*dx+dy*dy)
 t=math.max(0,math.min(1,t))
 return player[3]+(enemy[3]-player[3])*t
end
function E.position(x,y,player,enemy)
 if not player[4]then return x,y end
 if math.abs(enemy[4]-player[4])<.001 then
  local dy=enemy[5]-player[5]
  return player[1]+(x-player[4])*player[3],
   math.abs(dy)>.001 and player[2]+(y-player[5])*(enemy[2]-player[2])/dy or player[2]+(y-player[5])*player[3]
 end
 local u=(x-player[4])/(enemy[4]-player[4])
 local scale=player[3]+(enemy[3]-player[3])*math.max(0,math.min(1,u))
 local baseline=player[5]+(enemy[5]-player[5])*u
 return player[1]+(enemy[1]-player[1])*u,player[2]+(enemy[2]-player[2])*u+(y-baseline)*scale
end
-- The two native dirt tiles are one mound attached to one battler. They
-- must share a baseline and their spacing must scale with that sprite, not
-- with the distance/slope between both combatants.
local function groundAnchor(s,player,enemy)
 if s.tag~='DIRT_MOUND'or not player.ground then return end
 if player.all then
  if player.all[s.hostId]then return player.all[s.hostId]end
  local nearest,distance
  for id=0,3 do local a=player.all[id]
   if a then local d=(s.x-a[4])^2+(s.y-a[5])^2
    if not distance or d<distance then nearest,distance=a,d end
   end
  end
  if nearest then return nearest end
 end
 local a=math.abs(s.x-player[4])<math.abs(s.x-enemy[4])and player or enemy
 return a
end
function E.draw(pool,player,enemy,draw,...)
 local saved={};local count=0
 for _,s in ipairs(pool or{})do if s.active then
  count=count+1
  local ground=groundAnchor(s,player,enemy)
  local scale=ground and ground[3]or E.scale(s,player,enemy)
  saved[#saved+1]={s=s,x=s.x,y=s.y,sx=s.scaleX,sy=s.scaleY,ox=s.ox,oy=s.oy,custom=s.customDraw}
  local projectile=player.projectiles and player.projectiles[s.tag]
  local p,e=projectile and projectile[1]or player,projectile and projectile[2]or enemy
  local host=player.all and player.all[s.hostId]
  if not projectile and host and host~=player and host~=enemy then p,e=host,host end
  local x,y=E.position(s.x,s.y,p,e)
  if ground then x=ground.ground[1]+(s.x-ground[4])*scale;y=ground.ground[2]-2*scale end
  if s.customDraw then
   local custom=s.customDraw
   s.customDraw=function(sprite,...)
    love.graphics.push('all')
    love.graphics.translate(x,y);love.graphics.scale(scale,scale);love.graphics.translate(-sprite.x,-sprite.y)
    local result={pcall(custom,sprite,...)};love.graphics.pop()
    if not result[1]then error(result[2],0)end
    return unpack(result,2)
   end
  else
   local ox,oy=E.position(s.x+(s.ox or 0),s.y+(s.oy or 0),p,e)
   if ground then ox=x+(s.ox or 0)*scale;oy=y+(s.oy or 0)*scale end
   s.x,s.y=x,y
   s.scaleX=(s.scaleX or 1)*scale;s.scaleY=(s.scaleY or 1)*scale
   s.ox=player[4]and ox-x or(s.ox or 0)*scale;s.oy=player[4]and oy-y or(s.oy or 0)*scale
  end
 end end
 local result={pcall(draw,...)}
 for _,v in ipairs(saved)do local s=v.s;s.x=v.x;s.y=v.y;s.scaleX=v.sx;s.scaleY=v.sy;s.ox=v.ox;s.oy=v.oy;s.customDraw=v.custom end
 if not result[1]then error(result[2],0)end
 return count,unpack(result,2)
end
return E
