-- VASC's continuous, axis-separated collision walk adapted to Gen3. Native
-- Player.tick remains the sole arrival pipeline (warps/scripts/steps/battles).
local V=...
local W={radius=5.5}
local F=V.require('FieldCamera')
local P=require('src.core.game3.player')
local Collision=require('src.core.game3.collision')
local pos,lastX,lastZ,mapId
local function busy(game)
 local field=require('src.core.game3.field')
 local space=require('src.core.game3.scripting.space')
 return not F.interactive(game)or field.locked or require('src.ui.game3.fade').lockInput
  or require('src.core.game3.warp').isBusy()or require('src.core.game3.runtime').uiBusy()
  or require('src.core.game3.step_events').busy()or space._pendingOnFrame
  or P.action or P.boulderPush or P.fieldMoveAnim and P.fieldMoveAnim>0
end
function W.drop(snap)
 if snap and pos and not P.moving then P.px,P.py=P.cellX*16,P.cellY*16;P.syncSavePosition(F.game)end
 pos,lastX,lastZ,mapId=nil,nil,nil,nil;F.bodyYaw=nil
end
local function facing(dx,dz)
 if math.abs(dx)>math.abs(dz)then return dx>0 and 'right'or'left'end
 return dz>0 and'down'or'up'
end
local function blocked(game,x,z,dir)
 if x==P.cellX and z==P.cellY then return false end
 return not Collision.canEnter(game,x,z,{fromX=P.cellX,fromY=P.cellY,dir=dir,elevation=P.currentElevation,surfing=P.surfing or P.underwater})
end
local function specials(game,dir,run)
 -- Only called at an actual blocked face. The engine validates ledges,
 -- strength, connections and door/escalator/sign triggers itself.
 P.walkInPlace=false;P.turnArmed=false;P.turnTimer=0
 local result=P.tryMove(dir,game,run)
 if result~='blocked'and result~=nil then W.drop();return true end
 return false
end
local function axis(game,delta,horizontal,run)
 if delta==0 then return false end
 local a=horizontal and'x'or'z';local other=horizontal and'z'or'x'
 local r=W.radius;local nextPos=pos[a]+delta
 local edge=math.floor((nextPos+(delta>0 and r or-r))/16)
 local lo,hi=math.floor((pos[other]-r+.01)/16),math.floor((pos[other]+r-.01)/16)
 local dir=horizontal and(delta>0 and'right'or'left')or(delta>0 and'down'or'up')
 for n=lo,hi do
  if blocked(game,horizontal and edge or n,horizontal and n or edge,dir)then
   -- Do not send grazing an adjacent wall into the grid walker.
   if n==(horizontal and P.cellY or P.cellX)and specials(game,dir,run)then return true end
   nextPos=delta>0 and math.min(nextPos,edge*16-r-.01)or math.max(nextPos,(edge+1)*16+r+.01);break
  end
 end
 local oldCell=horizontal and P.cellX or P.cellY;local newCell=math.floor(nextPos/16)
 if newCell~=oldCell then
  -- Read authored doors/stairs before arrival, exactly as tryMove does.
  P.facing=dir
  if P.fieldTriggers(game,dir)then W.drop();return true end
  local x,z=pos.x,pos.z;pos[a]=nextPos
  assert(math.abs(newCell-oldCell)==1,'free walk crossed more than one cell')
  -- Complete one native step at the boundary; restore the continuous point
  -- only if the arrival did not give control to a warp/script/forced move.
  P.forcedStep(dir,1);P.tick(game)
  if busy(game)or P.moving or require('src.core.game3.map').current~=mapId then W.drop();return true end
  P.px,P.py=pos.x-8,pos.z-8
  return false
 end
 pos[a]=nextPos
 return false
end
function W.tick(game,input)
 local id=require('src.core.game3.map').current
 if not pos or P.px~=lastX or P.py~=lastZ or id~=mapId then pos={x=P.px+8,z=P.py+8};mapId=id end
 local mx,mz=F.moveVector(input);local yaw=F.yaw
 local dx,dz=math.cos(yaw)*mx-math.sin(yaw)*mz,-math.sin(yaw)*mx-math.cos(yaw)*mz
 if dx==0 and dz==0 then F.bodyYaw=yaw;P.walkInPlace=false;P.facing=facing(-math.sin(yaw),-math.cos(yaw));lastX,lastZ=P.px,P.py;return end
 local run=input:isDown('b')and P.canDash()and not P.runningDisallowed(P.cellX,P.cellY)
 local speed=run and 2 or 1
 if axis(game,dx*speed,true,run)then return end
 if axis(game,dz*speed,false,run)then return end
 P.px,P.py=pos.x-8,pos.z-8;lastX,lastZ=P.px,P.py
 F.bodyYaw=math.atan2(-dx,-dz);P.facing=facing(dx,dz);P.walkInPlace=true;P.walkInPlaceFast=run;P.running=run
end
function W.install()
 if W.installed then return end;W.installed=true
 local original=P.update
 local proxies=setmetatable({},{__mode='k'})
 P.update=function(game,input)
  if not F.enabled(game)then if pos then P.walkInPlace=false end;W.drop(true);return original(game,input)end
  -- Authored motion, bikes and forced tiles keep the engine's full controller.
  local forced=require('src.core.game3.forced_movement').isForcedMovementTile(Collision.behavior(P.cellX,P.cellY))
  if P.moving or P.biking or forced or busy(game)then W.drop();return original(game,input)end
  local proxy=proxies[input]
  if not proxy then
   proxy=setmetatable({},{__index=input});proxy.isDown=function(_,button,...)
    if button=='up'or button=='down'or button=='left'or button=='right'then return false end
    return input:isDown(button,...)
   end;proxies[input]=proxy
  end
  original(game,proxy) -- native animation, locks and idle trainer sight
  if P.moving or busy(game)then W.drop();return end
  return W.tick(game,input)
 end
end
return W
