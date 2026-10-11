-- Fit the native catch ball without modifying its trajectory, counters,
-- shakes, sprite visibility or result. Simulation always stays in GBA space.
local F={}
function F.anchor(base,foot,scale)
 return {x=foot[1],y=foot[2]-8*scale,scale=scale,nx=base.x,ny=base.y+24}
end
function F.particle(x,y,a)
 return a.x+(x-a.nx)*a.scale,a.y+(y-a.ny)*a.scale
end
function F.ball(ball,hand,a)
 local x=(ball.x or 0)+(ball.ox or 0);local y=(ball.y or 0)+(ball.oy or 0)
 -- During the 34 native flight frames the x coordinate advances from 32
 -- to the enemy. Afterwards only the native bounce and shake remain.
 local u=math.max(0,math.min(1,(x-32)/(a.nx-32)))
 local endY=a.y-40*a.scale
 local baseline=80+(a.ny-40-80)*u
 local px=hand[1]+(a.x-hand[1])*u+(x-(32+(a.nx-32)*u))*a.scale
 local py=hand[2]+(endY-hand[2])*u+(y-baseline)*a.scale
 return px,py,a.scale
end
return F
