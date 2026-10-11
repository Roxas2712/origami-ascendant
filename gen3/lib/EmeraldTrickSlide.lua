-- Native slide puzzle: separate the three floor variants from the same pot art.
local V=...
local S={}
local donors={[0x214]=0x208,[0x215]=0x210,[0x26c]=0x26b}
-- Measured opaque contour, including grey pixels shared with the tatami border.
local left={6,5,4,3,3,2,2,1,1,1,1,2,2,3,4,5}
function S.inside(s,t)return t>=0 and t<16 and s>=left[t+1]and s<16-left[t+1]end
function S.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.trickSlide.enabled and(d.id or d.name)=='EM_ROUTE110_TRICK_HOUSE_PUZZLE8'
  and d.mapType==8 and d.pair=='building__trick_house_puzzle'and L and L.width==16 and L.height==22
  and L:midAt(0,0)==0x201 and L:midAt(0,3)==0x26b and L:midAt(2,3)==0x26c then return c.homeRooms.trickSlide end
end
function S.lighting(d)if S.profile(d)then return V.require('EmeraldTrickSteps').roomLighting(d)end end
function S.plan(d)
 if not S.profile(d)then return end
 local L=d.midLayout;local objects,mask=V.require('EmeraldTrickSteps').rearPlan(L)
 for y=2,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y);local donor=donors[m]
  if donor then
   objects[#objects+1]={kind='trickSlidePot',x=x,y=y,w=16,h=16,noContact=true}
   mask[y*L.width+x+1]=donor
  elseif m==1 then mask[y*L.width+x+1]={mid=1,void=true}end
 end end
 return objects,mask
end
function S.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.trickSlide
 local G=V.require('WorldGeometry');local m=L:midAt(o.x,o.y)
 local h=c.potHeight*cfg.heightScale;local front=z+c.front;local back=front-c.depth
 for t=0,15 do for s=0,15 do if S.inside(s,t)then
  local uv=G.uv(ts,m,s,t,s+1,t+1,.5);local u,v=x+s,h*(16-t)/16;local low=h*(15-t)/16
  G.quad(out,{u,v,front},{u+1,v,front},{u+1,low,front},{u,low,front},uv,1)
  if not S.inside(s-1,t)then G.quad(out,{u,v,back},{u,v,front},{u,low,front},{u,low,back},uv,c.sideShade)end
  if not S.inside(s+1,t)then G.quad(out,{u+1,v,front},{u+1,v,back},{u+1,low,back},{u+1,low,front},uv,c.sideShade)end
  if not S.inside(s,t-1)then G.quad(out,{u,v,back},{u+1,v,back},{u+1,v,front},{u,v,front},uv,1)end
  if not S.inside(s,t+1)then G.quad(out,{u,low,front},{u+1,low,front},{u+1,low,back},{u,low,back},uv,c.sideShade)end
 end end end
 if contacts then contacts[#contacts+1]={x+8,front-c.depth/2,c.contactRadius,2,c.contactStrength}end
end
return S
