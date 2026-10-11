-- Neutral stage lighting preserves each native contest category's artwork.
local V=...;local C={}
function C.profile(d)
 if not(d and d.mapType==8)then return end
 local p=V.require('EmeraldContestRooms').profile(d)
 local cfg=V.require('DioramaConfig').emeraldInteriors
 if not(p and cfg.contestLighting.enabled)then return end
 local key=p==cfg.homeRooms.contestLobby and 'lobby'or p==cfg.homeRooms.contestHall and 'hall'or 'stage'
 return cfg.contestLighting[key]
end
function C.capture(list,o,x,z)
 if not o.kind:match('^contest')then return false end
 -- Generic wall handling merges collinear runs without bridging wall returns.
 if o.kind=='contestWall'then return false end
 local cfg=V.require('DioramaConfig').emeraldInteriors
 local c,lc=cfg.contestRooms,cfg.contestLighting
 local function box(a,b,u,v,low,high)
  list[#list+1]={lo={x+a,low*cfg.heightScale,z+u},hi={x+b,high*cfg.heightScale,z+v},wall=false}
 end
 local half=lc.blockerThickness/2
 if o.kind=='contestReturn'then
  local edge=o.right and 0 or 16
  box(edge-half,edge+half,64,96,0,c.hallWallHeight)
  box(0,16,96-half,96+half,0,c.hallWallHeight)
 elseif o.kind=='contestCounter'then
  box(0,16,20,48,0,c.counterHeight);box(112,128,20,48,0,c.counterHeight)
  box(16,112,39,48,0,c.counterHeight)
 elseif o.kind=='contestPC'then box(1,15,48-half,48+half,0,c.pcHeight)
 elseif o.kind=='contestBlender'then
  box(2,14,8,16,0,c.blenderHeight)
 elseif o.kind=='contestSeat'then
  -- A thin upright back, no floor-sized rectangle behind the sprite.
  box(2,14,30-half,30+half,4,c.seatHeight)
 elseif o.kind=='contestStage'then
  box(0,96,0,160,0,c.stageHeight);box(144,240,0,160,0,c.stageHeight)
  box(96,144,0,112,0,c.stageHeight)
  for a=112,152,8 do
   local top,low=c.stageHeight*(160-a)/48,c.stageHeight*(152-a)/48
   box(96,144,a,a+4,0,top)
   if low>0 then box(96,144,a+4,a+8,0,low)end
  end
 end
 -- Plants keep alpha-masked native contact shadows, not full quad occluders.
 return true
end
return C
