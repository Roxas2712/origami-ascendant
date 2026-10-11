-- Frontier gate: the native runner connects both exits. All objects are
-- separate surfaces; no edits to maps, event positions or collision.
local V=...
local R={}
function R.profile(d)
 if not d then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.frontierReception.enabled and(d.id or d.name)=='EM_BATTLE_FRONTIER_RECEPTION_GATE'and d.pair=='general__battle_frontier'
  and L and L.width==10 and L.height==14 and L:midAt(4,1)==0x255 and L:midAt(4,13)==0x3b1 then return c.homeRooms.frontierReception end
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.frontierReception;local objects,mask={},{}
 for y=0,13 do for x=0,9 do local k=y*10+x+1
  if x==9 or y<2 then mask[k]={mid=0x23,void=true}
  elseif x<3 or x>5 then mask[k]=0x5e end
 end end
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for x=0,8 do add('wall',x,0,1,2,{wallHeight=c.wallHeight,wallBase=32,wallLast=32})end
 for _,y in ipairs({2,9})do
  add('gateCounter',0,y,2,4)
  add('gateCounter',7,y,2,4,{right=true})
  for _,x in ipairs({2,6})do for _,yy in ipairs({y,y+2})do add('gateColumn',x,yy,1,2)end end
 end
 for _,p in ipairs({{6,6},{7,6},{8,6},{1,7},{2,7}})do add('gatePlant',p[1],p[2],1,2)end
 for y=6,8 do add('frontLoungeSeat',0,y,1,1)end
 add('frontLoungeSeat',8,8,1,1,{right=true})
 return objects,mask
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local px,pz=x+8,z+16
 if px>=5 and px<15 and pz>=100 and pz<=144 or px>=129 and px<139 and pz>=132 and pz<=144 then
  local c=V.require('DioramaConfig').emeraldInteriors;return c.frontierLounges.seatHeight*c.heightScale
 end
end
-- Native leaf gaps are retained; pale pot colors are never color-keyed away.
local plant={
 '................','................','................','......##........','......###.......','.###..####..###.',
 '.##############.','.##############.','..############..','...##########...','..############..','.##############.',
 '.##############.','################','################','################','..############..','...##########...',
 '.....######.....','....########....','...##########...','..############..','..############..','..############..',
 '...##########...','...##########...','...##########...','...##########...','...##########...','....########....',
 '.....######.....','................'}
function R.plantInside(s,t)return plant[t+1]and plant[t+1]:sub(s+1,s+1)=='#'or false end
function R.columnInside(s,t)
 if t<8 or t>=32 then return false end
 local a=t==8 and 5 or t==9 and 4 or t==10 and 3 or t==17 and 3 or t==29 and 3 or t==30 and 4 or t==31 and 5 or 2
 local b=t<24 and 16-a or t<29 and 15 or t==29 and 14 or t==30 and 13 or 12
 return s>=a and s<b
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.frontierReception;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and inside(s,t)end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(s,t,a,b,d,e,shade)local m,u,v=source(s,t);G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,c.contactStrength}end end end
 if o.kind=='gateCounter'then
  local function q(s)return o.right and 31-s or s end
  -- C-shaped top, open middle, with the native upper and lower front faces.
  draw(12,54,function(s,t)return t<20 or t>=44 or q(s)>=16 end,function(s,t)return{x+s,c.counterHeight,z+t}end)
  draw(20,28,function(s)return q(s)<16 end,function(s,t)return{x+s,c.counterHeight*(28-t)/8,z+20}end)
  draw(54,64,function()return true end,function(s,t)return{x+s,c.counterHeight*(64-t)/10,z+54}end)
  local outer=o.right and 0 or 32
  patch(o.right and 1 or 30,58,{x+outer,c.counterHeight,z+12},{x+outer,c.counterHeight,z+54},{x+outer,0,z+54},{x+outer,0,z+12},.96)
  patch(16,58,{x+16,c.counterHeight,z+20},{x+16,c.counterHeight,z+44},{x+16,0,z+44},{x+16,0,z+20},.96)
  patch(10,58,{x,c.counterHeight,z+12},{x+32,c.counterHeight,z+12},{x+32,0,z+12},{x,0,z+12},.96)
  patch(10,58,{x+(o.right and 16 or 0),c.counterHeight,z+44},{x+(o.right and 32 or 16),c.counterHeight,z+44},{x+(o.right and 32 or 16),0,z+44},{x+(o.right and 16 or 0),0,z+44},.96)
  -- End caps at the open edge of both short arms.
  local open=o.right and 32 or 0
  for _,a in ipairs({{12,20},{44,54}})do patch(10,58,{x+open,c.counterHeight,z+a[1]},{x+open,c.counterHeight,z+a[2]},{x+open,0,z+a[2]},{x+open,0,z+a[1]},.96)end
  contact(0,32,54)
 elseif o.kind=='gatePlant'then
  draw(3,31,R.plantInside,function(s,t)return{x+s,c.plantHeight*(31-t)/28,z+31}end);contact(2,14,31)
 elseif o.kind=='gateColumn'then
  draw(8,32,R.columnInside,function(s,t)return{x+s,c.columnHeight*(32-t)/24,z+32}end);contact(2,14,32)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
