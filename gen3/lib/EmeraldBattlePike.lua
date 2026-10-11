-- Original Battle Pike curtains, columns and terminals on separate surfaces.
-- Native events, random-room selection and collisions remain engine-owned.
local V=...
local R={}
local defs={LOBBY={12,14,5,12,0x319,'pikeLobby'},CORRIDOR={14,8,6,7,0x2e8,'pikeHall'},THREE_PATH_ROOM={14,12,6,10,0x2e1,'pikePaths'},ROOM_NORMAL={10,8,4,7,0x2e8,'pikeSmall'},ROOM_FINAL={6,8,2,7,0x359,'pikeFinal'},ROOM_WILD_MONS={10,20,4,19,0x2e8,'pikeWild'}}
local tops={[0x204]=true,[0x205]=true,[0x206]=true,[0x214]=true,[0x216]=true,[0x224]=true,[0x225]=true,[0x234]=true,[0x235]=true,[0x237]=true,[0x2db]=true,[0x30d]=true,[0x314]=true,[0x31b]=true}
local bases={[0x20c]=true,[0x20d]=true,[0x21c]=true,[0x21e]=true,[0x22c]=true,[0x22d]=true,[0x23c]=true,[0x23d]=true,[0x23e]=true,[0x2dc]=true,[0x2f9]=true,[0x31c]=true}
function R.kind(d)local k=d and(d.id or d.name or''):match('^EM_BATTLE_FRONTIER_BATTLE_PIKE_(.+)$');return defs[k],k end
function R.profile(d)
 local p=R.kind(d);if not p then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.battlePike.enabled and d.pair=='building__battle_pike'and L and L.width==p[1]and L.height==p[2]and L:midAt(p[3],p[4])==p[5]then return c.homeRooms[p[6]]end
end
function R.pillarInside(s,t)
 local inset=t==0 and 16 or t==1 and 6 or t<16 and 1 or t<19 and 3 or t<21 and 2 or t<29 and 1 or t==29 and 2 or t==30 and 3 or 5
 return s>=inset and s<16-inset
end
function R.plan(d)
 if not R.profile(d)then return end
 local _,k=R.kind(d);local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,e)local o=e or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=1,void=true}end end;return o
 end
 for y=0,L.height-1 do for x=0,L.width-1 do if L:midAt(x,y)==1 then mask[y*L.width+x+1]={mid=1,void=true}end end end
 local w=k=='CORRIDOR'and L.width or L.width-1
 add('pikeWall',0,0,w,4,{lobby=k=='LOBBY'})
 for y=3,L.height-2 do for x=0,w-1 do
  if tops[L:midAt(x,y)]and bases[L:midAt(x,y+1)]then add('pikePillar',x,y,1,2,{floor=k=='LOBBY'and(x==0 and 0x2c4 or 0x2c2)or(x==0 and 0x2c3 or 0x2c1)})end
 end end
 if k=='LOBBY'then
  add('pikeDevice',0,2,3,3,{shape='display',first=17,last=40})
  add('pikeDevice',8,2,1,3,{shape='monitor',first=12,last=40})
  add('pikeDevice',10,2,1,3,{shape='pc',first=8,last=40})
 end
 return objects,mask
end
local masks={
display={
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '....................########....................',
 '..........############################..........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '.........##############################.........',
 '..........############################..........',
 '..................############..................',
 '..................############..................',
 '...................##########...................',
 '....................########....................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
 '................................................',
},
monitor={
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '...##########...',
 '.##############.',
 '.##############.',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '..############..',
 '.....######.....',
 '......####......',
 '......####......',
 '.....######.....',
 '....########....',
 '....########....',
 '....########....',
 '.....######.....',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
},
pc={
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '...##########...',
 '..############..',
 '.##############.',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '################',
 '.##############.',
 '..############..',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
 '................',
},
}
function R.deviceInside(shape,s,t)return masks[shape]and masks[shape][t+1]and masks[shape][t+1]:sub(s+1,s+1)=='#'end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.battlePike;local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function contact(a,b,zz)if contacts then for xx=a+3,b-2,6 do contacts[#contacts+1]={x+xx,z+zz,4,2,c.contactStrength}end end end
 if o.kind=='pikeWall'then
  draw(0,64,nil,function(s,t)return{x+s,c.wallHeight*(64-t)/64,z+64}end,function(s,t)
   local m,u,v=source(s,t);local xx=math.floor(s/16)
   -- Clean donor curtain tiles behind the explicitly extracted fixtures.
   if t>=48 and tops[m]then m=0x2b9 end
   if o.lobby and t>=32 then
    if xx<=2 then m=t<48 and(0x2b6+(xx%2))or(0x2be+(xx%2))
    elseif xx==8 then m=t<48 and 0x2b6 or 0x2be
    elseif xx==10 then m=t<48 and 0x2b0 or 0x2b8 end
   end
   return m,u,v
  end)
 elseif o.kind=='pikePillar'then
  draw(math.max(0,64-z),32,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)return o.floor,s,t%16 end)
  draw(0,32,R.pillarInside,function(s,t)return{x+s,c.pillarHeight*(32-t)/32,z+32}end);contact(1,15,32)
 elseif o.kind=='pikeDevice'then
  draw(32,48,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)
   if R.deviceInside(o.shape,s,t)then return o.x==0 and math.floor(s/16)==0 and 0x2c4 or 0x2c2,s%16,t%16 end
   return source(s,t)
  end)
  local height=c[o.shape..'Height']
  draw(o.first,o.last,function(s,t)return R.deviceInside(o.shape,s,t)end,function(s,t)return{x+s,height*(o.last-t)/(o.last-o.first),z+o.last}end);contact(o.shape=='display'and 12 or 2,o.shape=='display'and 36 or 14,o.last)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
