-- Read the public host's native drawing without advancing the healing state.
-- Older hosts expose drawBalls/drawMonitor but no spriteSnapshot API.
local N={}
function N.snapshot(heal)
 if heal.spriteSnapshot then return heal.spriteSnapshot()end
 if not heal._fx then return {}end
 local g=love.graphics;local draw,claimed=g.draw,heal._claimed
 local sprites={};local kind
 g.push('all')
 g.draw=function(image,a,b,c)
  if type(a)=='number'then sprites[#sprites+1]={image=image,x=a,y=b,kind=kind}
  else sprites[#sprites+1]={image=image,quad=a,x=b,y=c,kind=kind}end
 end
 local ok,err=pcall(function()
  kind='ball';if heal.drawBalls then heal.drawBalls()end
  kind='monitor';if heal.drawMonitor then heal.drawMonitor()end
 end)
 g.draw=draw;heal._claimed=claimed;g.pop()
 if not ok then error(err,0)end
 return sprites
end
return N
