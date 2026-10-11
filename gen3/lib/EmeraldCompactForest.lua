-- Compact Hoenn crowns with map-native sand/grass/rock below them.
local V=...
local F={}
local maps={EM_DEWFORD_TOWN='general__dewford',EM_ROUTE106='general__dewford',EM_ROUTE107='general__dewford',EM_MAUVILLE_CITY='general__mauville',EM_SLATEPORT_CITY='general__slateport',EM_LAVARIDGE_TOWN='general__lavaridge'}
local primary={ [0xe]={0xe,0x16,1,false},[0x16]={0xe,0x16,1,true},[0xc6]={0xe,0x16,1,false},
 [0xf]={0xf,0x17,1,false},[0x17]={0xf,0x17,1,true},[0xc7]={0xf,0x17,1,false}}
function F.applies(d)return d and maps[d.id or d.name]==d.pair end
function F.role(d,m)
 if not F.applies(d)then return end
 if d.pair=='general__dewford'then
  if m==0x239 or m==0x243 then return{0x239,0x23a,0x124,false}end
  if m==0x23a then return{0x239,0x23a,0x124,true}end
 elseif d.pair=='general__lavaridge'and(m==0x211 or m==0x218)then return{0x211,0x218,0x271,m==0x218}
 else return primary[m]end
end
function F.plan(d)
 local mask={};if not F.applies(d)then return mask end
 local L=d.midLayout;local function k(x,y)return y*L.width+x+1 end
 for y=1,L.height-1 do for x=0,L.width-1 do
  local r=F.role(d,L:midAt(x,y));local a=F.role(d,L:midAt(x,y-1))
  if r and r[4]and a and not a[4]then
   local p={x=x,y=y,foot=(y+1)*16-2,variant=r[1],lower=r[2],ground=r[3]}
   mask[k(x,y-1)]=p;mask[k(x,y)]=p
  end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local r=F.role(d,L:midAt(x,y))
  if r and not mask[k(x,y)]then mask[k(x,y)]={x=x,y=y,foot=(y+1)*16,variant=r[1],lower=r[2],ground=r[3]}end
 end end
 return mask
end
function F.template(ts,variant)
 local lower=variant==0x239 and 0x23a or variant==0x211 and 0x218 or variant+8
 return V.require('EmeraldRainforest').template(ts,variant,lower)
end
function F.place(out,ts,p,ox,oz,instances,contacts)
 local x,z=(p.x+ox)*16+8,p.foot+oz*16
 if instances then
  local key=p.variant..':compactForest';local g=instances.props[key]
  if not g then g={mid=p.variant,kind='compactForest',ground=p.ground,placements={}};instances.props[key]=g end
  g.placements[#g.placements+1]={x,z,1}
 else V.require('Props').stamp(out,ts,p.variant,'compactForest',x,z,p.ground)end
 local c=V.require('DioramaConfig').contact;contacts[#contacts+1]={x,z,c.treeRadius[1]*.5,c.treeRadius[2]*.5,c.treeStrength}
end
return F
