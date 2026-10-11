-- Trainer Hill public entrance: measured native silhouettes and open counters.
local V=...
local E={}
function E.profile(d)
 if not d then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.hillEntrance.enabled and(d.id or d.name)=='EM_TRAINER_HILL_ENTRANCE'and d.mapType==8
  and d.pair=='building__trainer_hill'and L and L.width==20 and L.height==18 and L:midAt(9,0)==0x33b then return c.homeRooms.hillEntrance end
end
function E.doorPose(d,a)
 if E.profile(d)and a and a.x==17 and a.y==8 then
  local c=V.require('DioramaConfig').emeraldInteriors
  return{height=c.hillEntrance.wallHeight*c.heightScale,base=0,top=0}
 end
end
function E.lighting(d)if E.profile(d)then return V.require('DioramaConfig').emeraldInteriors.hillEntrance.light end end
local function rect(s,t,x,y,w,h)return s>=x and s<x+w and t>=y and t<y+h end
-- Coordinates in the original full-room image; holes remain open.
local counterParts={{112,60,32,12},{128,60,16,88},{112,124,16,44},{16,132,16,36},{16,156,96,12},
 {160,60,32,12},{160,60,16,92},{176,124,16,44},{192,156,80,12},{288,156,16,12}}
function E.counter(s,t)
 for _,r in ipairs(counterParts)do if rect(s,t,r[1],r[2],r[3],r[4])then return true end end
 return false
end
function E.capture(list,o,x,z)
 if o.kind~='hillEntryCounter'then return false end
 local cfg=V.require('DioramaConfig').emeraldInteriors
 for _,r in ipairs(counterParts)do list[#list+1]={lo={x+r[1],0,z+r[2]},hi={x+r[1]+r[3],cfg.hillEntrance.counterHeight*cfg.heightScale,z+r[2]+r[4]},wall=false}end
 return true
end
local cases={
 {case='pc',x=0,y=10,w=16,h=32,cap=0,split=7,last=32,front=32},
 {case='healer',x=2,y=8,w=32,h=32,cap=0,split=6,last=28,front=28},
 {case='monitor',x=4,y=7,w=32,h=32,cap=6,split=10,last=24,front=32.25},
 {case='medical',x=6,y=8,w=16,h=32,cap=8,split=10,last=28,front=28},
 {case='terminal',x=8,y=9,w=16,h=32,cap=4,split=7,last=32,front=32},
 {case='divider',x=15,y=8,w=16,h=48,cap=4,split=7,last=40,front=40}}
function E.caseInside(o,s,t)
 if t<o.cap or t>=o.last then return false end
 if o.case=='healer'then local a=t==0 and 8 or t==1 and 4 or t==2 and 2 or t==3 and 1 or 0;return s>=a and s<32-a
 elseif o.case=='monitor'then local a=t<8 and 5 or t<10 and 3 or t>=22 and 5 or 2;return s>=a and s<28-a
 elseif o.case=='medical'then return s>=3 and s<16
 elseif o.case=='divider'then return s>=5 and s<12
 elseif o.case=='pc'then local a=t==0 and 3 or t==1 and 2 or t==31 and 2 or 0;return s>=a and s<16-a
 elseif o.case=='terminal'then local a=t==4 and 2 or t>=29 and 2 or 0;return s>=a and s<16-a end
end
function E.plan(d)
 if not E.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{};local c=V.require('DioramaConfig').emeraldInteriors.hillEntrance
 local function add(o,x,y,w,h)o.x=x;o.y=y;o.w=w;o.h=h;o.noContact=true;objects[#objects+1]=o end
 add({kind='hillEntryFloor'},0,0,320,288);add({kind='hillEntryCounter'},0,0,320,288)
 for k=1,L.width*L.height do mask[k]={mid=0x208,void=true}end
 for x=7,11 do add({kind='wall',wallBase=32,wallLast=32,wallHeight=c.wallHeight},x,0,16,32)end
 for _,range in ipairs({{0,6},{12,18}})do for x=range[1],range[2]do
  add({kind='wall',wallBase=32,wallLast=32,wallHeight=c.wallHeight,clean=(x>=1 and x<=6 or x>=12 and x<=15)and {0x321,0x329}or nil},x,7,16,32)
 end end
 for _,x in ipairs({6,12})do add({kind='hillEntrySide'},x,0,16,144)end
 for _,o in ipairs(cases)do local q={};for k,v in pairs(o)do q[k]=v end;q.kind='hillEntryCase';q.noContact=true;for k,v in pairs(c.devices[q.case])do q[k]=v end;objects[#objects+1]=q end
 for _,x in ipairs({1,2,3,15,16,17})do add({kind='hillColumn'},x,14,16,32)end
 return objects,mask
end
local function wall(s,t)
 local x=math.floor(s/16)
 return t<32 and x>=7 and x<=11 or t<144 and(x==6 or x==12)
  or t>=112 and t<144 and(x<=6 or x>=12)
end
local function front(s,t)
 if t>=168 and t<176 then return s>=16 and s<128 or s>=176 and s<272 or s>=288 and s<304 end
 if t>=72 and t<80 then return s>=112 and s<128 or s>=176 and s<192 end
 return t>=152 and t<160 and s>=160 and s<176
end
function E.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.hillEntrance;local G=V.require('WorldGeometry')
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,point,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and inside(s,t)end,0,o.h,1,nil,point,.5)
  for _,v in ipairs(vv)do v[2]=v[2]*cfg.heightScale;out[#out+1]=v end
 end
 if o.kind=='hillEntryFloor'then
  local erase={}
  for _,q in ipairs(cases)do for t=q.cap,q.last-1 do for s=0,q.w-1 do if E.caseInside(q,s,t)then erase[(q.y*16+t)*320+q.x*16+s]=true end end end end
  for _,xx in ipairs({1,2,3,15,16,17})do for t=237,255 do for s=xx*16,xx*16+15 do erase[t*320+s]=true end end end
  draw(0,288,function(s,t)return not wall(s,t)and L:midAt(math.floor(s/16),math.floor(t/16))~=0x208 end,function(s,t)return{x+s,0,z+t}end,function(s,t)
   if E.counter(s,t)or front(s,t)or erase[t*320+s]then local xx,yy=math.floor(s/16),math.floor(t/16);return (xx+yy)%2==1 and 0x330 or 0x331,s%16,t%16 end
   return source(s,t)
  end)
 elseif o.kind=='hillEntryCounter'then
  draw(0,176,E.counter,function(s,t)return{x+s,c.counterHeight,z+t}end,function(s,t)
   if rect(s,t,245,132,7,36)then return 0x305,8,4 end
   return source(s,t)
  end)
  for _,row in ipairs({{72,80},{152,160},{168,176}})do draw(row[1],row[2],front,function(s,t)return{x+s,c.counterHeight*(row[2]-t)/(row[2]-row[1]),z+row[1]}end)end
  for t=60,167 do for s=0,303 do if E.counter(s,t)then
   local function edge(a,b)local uv=G.uv(ts,0x305,8,9,9,10,.5);G.quad(out,{x+a[1],c.counterHeight*cfg.heightScale,z+a[2]},{x+b[1],c.counterHeight*cfg.heightScale,z+b[2]},{x+b[1],0,z+b[2]},{x+a[1],0,z+a[2]},uv,c.sideShade)end
   if not E.counter(s-1,t)then edge({s,t},{s,t+1})end
   if not E.counter(s+1,t)then edge({s+1,t+1},{s+1,t})end
   if not E.counter(s,t-1)then edge({s+1,t},{s,t})end
  end end end
 elseif o.kind=='hillEntrySide'then
  local lo,hi=o.x==6 and 8 or 0,o.x==6 and 16 or 8
  G.quad(out,{x+lo,c.wallHeight*cfg.heightScale,z+32},{x+hi,c.wallHeight*cfg.heightScale,z+32},{x+hi,c.wallHeight*cfg.heightScale,z+144},{x+lo,c.wallHeight*cfg.heightScale,z+144},G.uv(ts,0x321,8,2,9,3,.5),1)
  for _,edge in ipairs({x+lo,x+hi})do
   local vv=V.require('PaperSprite').build(ts,112,32,function(s,t)return t<16 and 0x321 or 0x329,s%16,t%16 end,function()return true end,0,32,1,nil,function(s,t)return{edge,c.wallHeight*cfg.heightScale*(32-t)/32,z+32+s}end,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
  end
 elseif o.kind=='hillEntryCase'then
  local h=o.height;local base=o.base or 0
  draw(o.cap,o.split,function(s,t)return E.caseInside(o,s,t)end,function(s,t)return{x+s,h+base,z+o.front-o.depth+(t-o.cap)*o.depth/(o.split-o.cap)}end)
  draw(o.split,o.last,function(s,t)return E.caseInside(o,s,t)end,function(s,t)return{x+s,base+h*(o.last-t)/(o.last-o.split),z+o.front}end)
  if contacts then contacts[#contacts+1]={x+o.w/2,z+o.front,o.w*.4,2,c.contactStrength}end
 end
end
return E
