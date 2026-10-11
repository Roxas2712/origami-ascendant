-- Question-doll room: retain the native tatami path over its blue recess.
local V=...
local Q={}
function Q.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.trickQuiz.enabled and(d.id or d.name)=='EM_ROUTE110_TRICK_HOUSE_PUZZLE5'
  and d.mapType==8 and d.pair=='building__trick_house_puzzle'and L and L.width==16 and L.height==22
  and L:midAt(0,0)==0x201 and L:midAt(0,2)==0x268 and L:midAt(1,20)==0x208 then return c.homeRooms.trickQuiz end
end
function Q.lighting(d)
 if not Q.profile(d)then return end
 local p=V.require('EmeraldTrickSteps').roomLighting(d)
 local c=V.require('DioramaConfig').emeraldInteriors.trickQuiz
 for i,a in ipairs(c.ceilingPositions)do p.sources[i].at[1]=a[1];p.sources[i].at[3]=a[2]end
 return p
end
function Q.plan(d)
 if not Q.profile(d)then return end
 local L=d.midLayout;local objects,mask=V.require('EmeraldTrickSteps').rearPlan(L)
 for y=2,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if m==0x268 then
   objects[#objects+1]={kind='trickQuizRecess',x=x,y=y,w=16,h=16,noContact=true}
   mask[y*L.width+x+1]={mid=1,void=true}
  elseif m==1 then mask[y*L.width+x+1]={mid=1,void=true}end
 end end
 return objects,mask
end
function Q.build(out,L,ts,o,x,z)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.trickQuiz
 local G=V.require('WorldGeometry');local h=c.recessDepth*cfg.heightScale
 G.quad(out,{x,-h,z},{x+16,-h,z},{x+16,-h,z+16},{x,-h,z+16},G.uv(ts,0x268,0,0,16,16,.5),1)
 local function edge(dx,dy,a,b,u0,v0,u1,v1)
  local nx,ny=o.x+dx,o.y+dy
  if nx<0 or ny<1 or nx>=15 or ny>=L.height then return end
  local m=L:midAt(nx,ny);if m==1 or m==0x268 then return end
  -- Sample only the touching native border. No replacement floor or colour key.
  G.quad(out,{x+a[1],0,z+a[2]},{x+b[1],0,z+b[2]},
   {x+b[1],-h,z+b[2]},{x+a[1],-h,z+a[2]},G.uv(ts,m,u0,v0,u1,v1,.5),c.sideShade)
 end
 edge(-1,0,{0,16},{0,0},15,0,16,16)
 edge(1,0,{16,0},{16,16},0,0,1,16)
 edge(0,-1,{0,0},{16,0},0,15,16,16)
 edge(0,1,{16,16},{0,16},0,0,16,1)
end
return Q
