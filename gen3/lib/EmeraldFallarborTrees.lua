-- Native Fallarbor round, lobed trees on brown town soil (not Route113 ash).
local V=...
local F={ground=0x279}
local mids={[0x206]=true,[0x207]=true,[0x20e]=true,[0x20f]=true,[0x26b]=true,[0x26c]=true,[0x273]=true,[0x274]=true}
function F.applies(d)return d and((d.id or d.name)=='EM_FALLARBOR_TOWN'or(d.id or d.name)=='EM_ROUTE114')and d.pair=='general__fallarbor'end
function F.tree(m)return mids[m]or false end
function F.anchor(d,x,y)
 local L=d.midLayout;local m=L:midAt(x,y)
 return(m==0x20e or m==0x273)and F.tree(L:midAt(x+1,y))
end
function F.plan(d)
 local p={};if not F.applies(d)then return p end
 local L=d.midLayout
 for y=0,L.height-1 do for x=0,L.width-1 do if F.tree(L:midAt(x,y))then
  local entry={};if F.anchor(d,x,y)then entry.kind='fallarborTree';entry.x=x*16+16;entry.z=y*16+12 end
  p[y*L.width+x+1]=entry
 end end end
 return p
end
function F.template(ts)return V.require('EmeraldAshRoute').template(ts,'ashTree',{0x206,0x207,0x20e,0x20f})end
function F.place(out,ts,p,ox,oz,instances,contacts)
 if not p.kind then return end
 local x,z=p.x+ox*16,p.z+oz*16
 if instances then
  local g=instances.props.fallarborTree;if not g then g={mid=0x206,kind='fallarborTree',ground=F.ground,placements={}};instances.props.fallarborTree=g end
  g.placements[#g.placements+1]={x,z,1}
 else V.require('Props').stamp(out,ts,0x206,'fallarborTree',x,z,F.ground)end
 local c=V.require('DioramaConfig').contact;contacts[#contacts+1]={x,z,c.treeRadius[1],c.treeRadius[2],c.treeStrength}
end
return F
