-- Measured winding gym walls; native trainer progress remains engine-owned.
local V=...
local D={}
local contours=V.data('EmeraldDewfordContours')
local frontTop={[0x21c]=true,[0x21d]=true,[0x21e]=true,[0x221]=true,[0x23b]=true,[0x23c]=true}
local frontBottom={[0x224]=true,[0x225]=true,[0x226]=true,[0x229]=true,[0x243]=true,[0x244]=true,[0x22e]=true}
function D.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.dewfordGym.enabled and(d.id or d.name)=='EM_DEWFORD_TOWN_GYM'
  and d.pair=='building__dewford_gym'and L and L.width==18 and L.height==28
  and L:midAt(3,1)==0x23b and L:midAt(4,23)==0x21f then return c.homeRooms.dewfordGym end
end
function D.covered(mid,s,t)
 local c=contours[mid];if not c then return false end
 local row=tonumber(c:sub(t*4+1,t*4+4),16)
 return math.floor(row/2^s)%2==1
end
function D.plan(d)
 if not D.profile(d)then return end
 local L=d.midLayout;local objects,mask,paired={},{},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o end
 for y=0,26 do for x=0,17 do local m=L:midAt(x,y);local below=L:midAt(x,y+1)
  if frontTop[m]and frontBottom[below]then
   add('dewGymFront',x,y,1,2,{cleanPillar=below==0x22e});paired[y*18+x+1]=true;paired[(y+1)*18+x+1]=true
  end
 end end
 for y=0,27 do for x=0,17 do local k=y*18+x+1;local m=L:midAt(x,y)
  if m~=6 and m~=7 then mask[k]=0x210 end
  if not paired[k]and contours[m]then add('dewGymCap',x,y,1,1,{mid=m})end
 end end
 add('dewGymPodium',2,3,4,2)
 for _,x in ipairs({1,6})do add('dewGymPillar',x,2,1,2)end
 for _,x in ipairs({4,7})do add('dewGymStatue',x,23,1,2)end
 for _,o in ipairs(objects)do o.paired=paired end
 return objects,mask
end
function D.actorHeight(d,x,z)
 if not D.profile(d)then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local f=z+16
 if x+8>=32 and x+8<96 and f>=48 and f<80 then return c.dewfordGym.podiumHeight*c.heightScale*math.min(1,(80-f)/8)end
 return 0
end
function D.podiumInside(s,t)
 return t>=0 and t<32 and s>=(t>=8 and t<22 and 2 or 1)and s<63
end
function D.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.dewfordGym;local G=V.require('WorldGeometry');local first=#out+1
 local function heightAt(xx,zz)return xx<112 and zz<48 and c.backWallHeight or c.wallHeight end
 local wallHeight=heightAt(o.x*16,o.y*16)
 local function source(s,t)
  if o.cleanPillar and t>=16 then return 0x224,s%16,t%16 end
  return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16
 end
 local function band(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function side(a,b,bottom)
  G.quad(out,{x+a[1],wallHeight,z+a[2]},{x+b[1],wallHeight,z+b[2]},{x+b[1],bottom,z+b[2]},{x+a[1],bottom,z+a[2]},G.uv(ts,0x224,8,0,9,16,.5))
 end
 local function occupied(s,t)
  local xx=o.x+math.floor(s/16);local yy=o.y+math.floor(t/16)
  if xx<0 or xx>=18 or yy<0 or yy>=28 then return false end
  return o.paired[yy*18+xx+1]or D.covered(L:midAt(xx,yy),s%16,t%16)
 end
 if o.kind=='dewGymCap'or o.kind=='dewGymFront'then
  local h=o.kind=='dewGymFront'and 32 or 16
  local function inside(s,t)return o.kind=='dewGymFront'or D.covered(o.mid,s,t)end
  local function cap(s,t)
   if o.kind=='dewGymFront'and t>=28 then return source(s,t-24)end
   -- Original plan-view rims inside the folded roof are no longer boundaries.
   -- Retain the perimeter rim; fill the covered interior with native roof art.
   local perimeter=false
   for n=1,5 do if not occupied(s-n,t)or not occupied(s+n,t)or not occupied(s,t-n)or not occupied(s,t+n)then perimeter=true;break end end
   if perimeter and(o.kind~='dewGymFront'or t<4)then return source(s,t)end
   return 0x208,s%16,t%16
  end
  band(0,h,function(s,t)return{x+s,wallHeight,z+t}end,inside,cap)
  if o.kind=='dewGymFront'then
   band(8,32,function(s,t)return{x+s,wallHeight*(32-t)/24,z+32}end)
   if contacts then contacts[#contacts+1]={x+8,z+32,8,1.5,c.contactStrength}end
  end
  local function boundary(s,t,a,b)
   local bottom=occupied(s,t)and heightAt(o.x*16+s,o.y*16+t)or 0
   if bottom<wallHeight then side(a,b,bottom)end
  end
  for t=0,h-1 do for s=0,15 do if inside(s,t)then
   boundary(s-1,t,{s,t},{s,t+1});boundary(s+1,t,{s+1,t+1},{s+1,t})
   boundary(s,t-1,{s+1,t},{s,t})
   if not(o.kind=='dewGymFront'and t==31)then boundary(s,t+1,{s,t+1},{s+1,t+1})end
  end end end
 elseif o.kind=='dewGymPillar'then
  band(0,32,function(s,t)return{x+s,c.pillarHeight*(32-t)/32,z+32}end)
 elseif o.kind=='dewGymStatue'then
  band(0,32,function(s,t)return{x+s,c.statueHeight*(32-t)/32,z+28}end,V.require('EmeraldRustboroGym').statueInside)
 elseif o.kind=='dewGymPodium'then
  local function stairs(s)return s>=3 and s<17 or s>=47 and s<61 end
  band(0,24,function(s,t)return{x+s,c.podiumHeight,z+t}end,D.podiumInside)
  band(24,32,function(s,t)return{x+s,c.podiumHeight*(32-t)/8,z+24}end,function(s,t)return D.podiumInside(s,t)and not stairs(s)end)
  for j=0,3 do local a=24+j*2;local h=c.podiumHeight*(4-j)/4
   band(a,a+1,function(s,t)return{x+s,h,z+a+(t-a)*2}end,stairs)
   band(a+1,a+2,function(s,t)return{x+s,h-(t-a-1)*c.podiumHeight/4,z+a+2}end,stairs)
  end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return D
