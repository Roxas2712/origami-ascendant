-- Source-guarded light volumes for Fortree and Pacifidlog houses.
local V=...;local H={cache=setmetatable({},{__mode='k'})}
local layouts={
 tree1={width=8,height=6,rows='3c8 3c9 3c9 3be 3bf 3c9 3c9 3ca 3d0 3e0 3d1 3be 3bf 3d1 3d1 3d2 3d8 3e8 3dc 3be 3bf 3db 3d9 3da'},
 tree2={width=8,height=6,rows='3c8 3c9 3c9 3be 3bf 3c9 3cb 3ca 3d0 3e3 3e4 3be 3bf 3d1 21e 3d2 3d8 3eb 3ec 3be 3bf 3db 3d3 3da'},
 raft1={width=10,height=10,rows='390 391 3b4 3b5 391 391 391 391 397 392 398 3a8 3bc 3bd 399 399 3b8 3b9 39f 39a 3a0 3b0 3c4 3c5 3a1 3b7 3c0 3c1 3a7 3a2'},
 raft2={width=10,height=10,rows='390 3ba 3bb 3b4 3b5 391 391 393 391 392 398 2c6 2c7 3bc 3bd 399 399 21e 3a9 39a 3a0 3c2 3c3 3c4 3c5 3a1 3a1 39b 3b1 3a2'},
}
local owned={}
for i=1,5 do owned['EM_FORTREE_CITY_HOUSE'..i]='tree'..(i%2==1 and 1 or 2);owned['EM_PACIFIDLOG_TOWN_HOUSE'..i]='raft'..(i%2==1 and 1 or 2)end
local function stamp(t)
 local keys={};for k in pairs(t)do keys[#keys+1]=k end;table.sort(keys)
 local out={};for _,k in ipairs(keys)do local v=t[k];out[#out+1]=k..'='..(type(v)=='table'and stamp(v)or tostring(v))end;return table.concat(out,';')
end
function H.profile(d)
 local key=d and owned[d.id];if not key then return end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.timberLighting;local L=d.midLayout;local room=layouts[key]
 if not(all.enabled and c.enabled and d.mapType==8 and d.pair=='building__generic_building'and L and L.width==room.width and L.height==room.height)then return end
 local i=0;for m in room.rows:gmatch('%x+')do if L:midAt(i%L.width,math.floor(i/L.width))~=tonumber(m,16)then return end;i=i+1 end
 local tree=key:sub(1,4)=='tree'
 if not tree and(L:midAt(4,4)~=0x3aa or L:midAt(5,4)~=0x3ab)then return end
 local signature=key..stamp(c);local hit=H.cache[L];if hit and hit.signature==signature then return hit.profile end
 local sources={};local family=tree and c.tree or c.raft
 local function add(at,radius,power,nightPower,color,direction,spread,cone)
  sources[#sources+1]={at=at,radius=radius,power=power,nightPower=nightPower,color=color,direction=direction,spread=spread,cone=cone}
 end
 add(family.entrance,c.entranceRadius,c.entrancePower,c.entranceNightPower,c.dayColor,{0,-.3,-1},c.entranceSpread,.1)
 for _,at in ipairs(family.ceiling)do add(at,family.radius,family.power,family.nightPower,c.ceilingColor,{0,-1,0},c.ceilingSpread,-.1)end
 if key=='raft1'then add(c.workPosition,c.workRadius,c.workPower,c.workNightPower,c.ceilingColor,{0,-1,0},c.workSpread,-.1)end
 local p={ambient=c.ambient,night=c.nightAmbient,sources=sources}
 H.cache[L]={signature=signature,profile=p};return p
end
function H.capture(list,o,x,z)
 if not o.timberHome then return false end
 local c=V.require('DioramaConfig').emeraldInteriors;local scale=c.heightScale
 local function box(a,b,back,front,low,high)list[#list+1]={lo={x+a,low*scale,z+back},hi={x+b,high*scale,z+front},wall=false}end
 if o.kind=='treeTrunk'then
  -- Inscribed strips follow the curved trunk, unlike its old bounding box.
  local slices=math.max(3,math.floor(c.timberLighting.trunkShadowSlices));local step=28/slices
  local center=o.front-o.depth*.5
  local function arc(a)return o.depth*.5*math.sqrt(math.max(0,1-((a-16)/14)^2))end
  for i=0,slices-1 do local a,b=2+i*step,2+(i+1)*step;local depth=math.min(arc(a),arc(b))
   if depth>.1 then box(a,b,center-depth,center+depth,0,o.height)end
  end
 elseif o.kind~='fold'then return false
 elseif o.faucet then
  box(1,o.w-1,o.front-o.depth,o.front,0,o.height)
  box(6,13,o.front-14-.25,o.front-14+.25,o.height,o.height+9)
 elseif o.timberTable then
  box(0,o.w,o.front-o.depth,o.front,o.height-c.timberLighting.tableThickness,o.height)
 else return false end
 return true
end
return H
