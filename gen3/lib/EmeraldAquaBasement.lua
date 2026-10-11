-- Aqua B2: measured native silhouettes, with separate wall/floor donors.
local V=...;local R={}
function R.kind(d)return d and(d.id or d.name)=='EM_AQUA_HIDEOUT_B2F'end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d and d.midLayout
 if R.kind(d)and c.enabled and c.aquaBasement.enabled and d.pair=='general__facility'and L and L.width==34 and L.height==24 and L:midAt(21,0)==0x22c and L:midAt(11,5)==0x241 then return c.homeRooms.aquaBasement end
end
local tankInset={[8]=25,[9]=22,[10]=22,[11]=17,[12]=16,[13]=15,[14]=14,[15]=13,[16]=12,[17]=11,[18]=11,[19]=10,[20]=10,[21]=9,[22]=9,[23]=9}
function R.tankInside(s,t)
 if s<0 or s>=64 or t<8 or t>=96 then return false end
 local inset=t<24 and tankInset[t]or t<72 and 0 or t<95 and 16 or 17
 return s>=inset and s<64-inset
end
function R.deskInside(s,t)
 if t>=11 and t<=27 then return s>=(t==11 and 1 or 0)and s<(t==11 and 31 or 32)end
 if t>=28 and t<32 then return s>=1 and s<=(t==28 and 5 or 4)or s>=27 and s<=30 end
 return false
end
function R.monitorInside(s,t)return t>=8 and t<24 and s>=(t==8 and 3 or 2)and s<=(t==8 and 14 or 15)end
function R.stoolInside(s,t)
 local inset=({[1]=5,4,3,2,2,2,2,3,4,3,3,4,5,6})[t]
 return inset~=nil and s>=inset and s<16-inset
end
local binInset={5,4,3,2,2,2,2,2,2,2,2,2,2,3,4,6}
function R.binInside(s,t)return t>=0 and t<16 and s>=binInset[t+1]and s<16-binInset[t+1]end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,e)
  local o=e or{};o.kind='a2'..kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=0x228,void=true}end end
 end
 add('Wall',1,2,5,3)
 add('Wall',7,0,7,3,{clean={{0,32}}})
 add('Wall',15,0,18,3,{clean={{80,144},{176,240}}})
 add('Wall',1,10,13,3)
 add('Wall',25,14,8,3)
 add('Wall',25,22,8,2)
 add('Machine',7,0,2,4,{start=8,base=56,wall=true})
 for _,p in ipairs{{17,6},{21,7},{25,7},{28,7}}do add('Machine',p[1],p[2],2,3,{start=0,base=48})end
 for _,x in ipairs{20,26}do add('Tank',x,0,4,6)end
 add('Console',20,8,1,2);add('Console',27,8,1,2)
 add('Desk',11,5,2,2);add('Stool',11,7,1,1);add('Bin',13,6,1,1)
 local common=V.require('EmeraldAquaHideout')
 local rim={[0x209]=true,[0x20a]=true,[0x20b]=true,[0x210]=true,[0x211]=true,[0x213]=true,[0x259]=true,[0x220]=true}
 local rail={[0x28e]=true,[0x2a6]=true,[0x262]=true,[0x26a]=true}
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if not mask[y*L.width+x+1]then
   if m==0x201 then mask[y*L.width+x+1]={mid=m,void=true}
   elseif common.isRail(m)or rail[m]then add('Rail',x,y,1,1,{mid=m,water=true})
   elseif rim[m]then add('Rim',x,y,1,1)
   elseif m==0x21f or m==0x227 or m==0x22f or m==0x237 then add('Pipe',x,y,1,1)end
  end
 end end
 return objects,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.aquaBasement;local first=#out+1
 local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project,source)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source or src,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function donor(mid,a,b)draw(a,b,nil,function(s,t)return{x+s,0,z+t}end,function(s,t)return mid,s%16,t%16 end)end
 local function contact(w,base,offset)if contacts then for xx=4,w-3,8 do contacts[#contacts+1]={x+xx+(offset or 0),z+base,5,2,c.contactStrength}end end end
 if o.kind=='a2Wall'then
  local bottom=math.min(40,o.h)
  local function clean(s,t)
   local m,u,v=src(s,t)
   for _,r in ipairs(o.clean or{})do if s>=r[1]and s<r[2]then m=t<16 and 0x219 or t<32 and 0x221 or 0x229 end end
   return m,u,v
  end
  draw(0,bottom,nil,function(s,t)return{x+s,c.wallHeight*(bottom-t)/40,z+bottom}end,clean)
  draw(bottom,o.h,nil,function(s,t)return{x+s,0,z+t}end,clean)
 elseif o.kind=='a2Tank'then
  donor(0x228,40,96)
  draw(8,96,R.tankInside,function(s,t)return{x+s,c.tankHeight*(96-t)/88,z+96}end)
  contact(32,96,16)
 elseif o.kind=='a2Console'then
  donor(0x228,0,32)
  draw(0,24,nil,function(s,t)return{x+s,c.consoleHeight*(24-t)/24,z+24}end)
  contact(16,24)
 elseif o.kind=='a2Desk'then
  donor(0x202,0,32)
  draw(11,25,function(s,t)return R.deskInside(s,t)and not R.monitorInside(s,t)end,function(s,t)return{x+s,c.deskHeight,z+11+(t-11)}end)
  draw(25,32,R.deskInside,function(s,t)return{x+s,c.deskHeight*(32-t)/7,z+25}end)
  draw(8,24,R.monitorInside,function(s,t)return{x+s,c.deskHeight+c.monitorHeight*(24-t)/16,z+23}end)
  contact(32,25)
 elseif o.kind=='a2Stool'or o.kind=='a2Bin'then
  donor(0x202,0,16)
  local stool=o.kind=='a2Stool';local inside=stool and R.stoolInside or R.binInside
  local split=stool and 8 or 4;local height=stool and c.stoolHeight or c.binHeight
  draw(0,split,inside,function(s,t)return{x+s,height,z+t}end)
  draw(split,16,inside,function(s,t)return{x+s,height*(16-t)/(16-split),z+split}end)
  contact(16,split)
 else
  local a={};for k,v in pairs(o)do a[k]=v end;a.kind='aqua'..o.kind:sub(3)
  V.require('EmeraldAquaHideout').build(out,L,ts,a,x,z,contacts);return
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
