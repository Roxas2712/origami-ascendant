-- Ranking Hall: three connected marble wings, original terminals and seating.
-- Measured presentation surfaces only; the native records/events stay owned by
-- the engine. No shared tileset-wide object guesses.
local V=...
local R={}
local walls={{5,2,7},{23,0,7},{41,2,7},{14,6,5},{34,6,5}}
local bricks={{3,4},{12,4},{21,1},{30,1},{39,4},{48,4}}
local pillars={{19,4},{32,4}}
local terminals={{26,4},{8,6},{44,6},{23,7},{29,7},{6,8},{10,8},{42,8},{46,8}}
local seats={{21,4},{31,4},{3,7},{3,9},{5,12},{6,12,true},{10,12,true},{11,12},{42,12,true},{44,12,true},{46,12,true}}
-- Return walls connect the front planes at each step of the native outline.
local returns={{5,5,7},{12,5,7},{14,7,9},{19,7,9},{21,4,7},{23,3,4},{30,3,4},{32,4,7},{34,7,9},{39,7,9},{41,5,7},{48,5,7}}
function R.profile(d)
 if not d then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.frontierRanking.enabled and(d.id or d.name)=='EM_BATTLE_FRONTIER_RANKING_HALL'
  and d.pair=='building__battle_frontier_ranking_hall'and L and L.width==54 and L.height==16
  and L:midAt(26,4)==0x207 and L:midAt(26,14)==6 then return c.homeRooms.frontierRanking end
end
function R.floor(x,y)return y%2==0 and(x%2==0 and 0x20b or 0x20a)or(x%2==0 and 0x203 or 0x202)end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 for y=0,15 do for x=0,53 do local m=L:midAt(x,y)
  if m==1 then mask[y*54+x+1]={mid=1,void=true}
  elseif m==0x204 or m==0x205 or m==0x20c or m==0x20d then mask[y*54+x+1]=R.floor(x,y)end
 end end
 local function add(kind,x,y,w,h,extra,wall)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*54+xx+1]=wall and{mid=1,void=true}or R.floor(xx,yy)end end
 end
 for _,p in ipairs(walls)do add('rankWall',p[1],p[2],p[3],3,nil,true)end
 for _,p in ipairs(bricks)do add('rankBrick',p[1],p[2],2,3,nil,true)end
 for _,p in ipairs(pillars)do add('rankPillar',p[1],p[2],2,3,nil,true);for x=p[1],p[1]+1 do mask[(p[2]+2)*54+x+1]=R.floor(x,p[2]+2)end end
 for _,p in ipairs(returns)do objects[#objects+1]={kind='rankReturn',x=p[1],y=p[2],w=0,h=(p[3]-p[2])*16,noContact=true}end
 for _,p in ipairs(terminals)do add('rankTerminal',p[1],p[2],1,2)end
 add('rankMachine',25,8,3,3)
 for _,p in ipairs(seats)do add('rankSeat',p[1],p[2],1,2,{stool=p[3]})end
 return objects,mask
end
function R.seatInside(s,t,stool)
 local start=stool and 14 or 6
 if t<start or t>=31 then return false end
 if t==start then return s>=2 and s<14 end
 if t==start+1 or t==27 or t==28 then return s>=1 and s<15 end
 if t>=29 then return s>=1 and s<5 or s>=11 and s<15 end
 return s>=0 and s<16
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 for _,p in ipairs(seats)do if x+8>=p[1]*16+1 and x+8<p[1]*16+15 and z+16>=p[2]*16+20 and z+16<=p[2]*16+32 then
  local c=V.require('DioramaConfig').emeraldInteriors;return c.frontierRanking.seatHeight*c.heightScale
 end end
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.frontierRanking;local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and inside(s,t)end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function solid()return true end
 local function patch(mid,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,mid,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,c.contactStrength}end end end
 if o.kind=='rankReturn'then
  patch(0x230,8,8,{x,c.wallHeight,z},{x,c.wallHeight,z+o.h},{x,0,z+o.h},{x,0,z},.97)
 elseif o.kind=='rankWall'or o.kind=='rankBrick'then
  draw(0,48,function(s,t)local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v);return a>=.5 and r+g+b>.02 end,
   function(s,t)return{x+s,c.wallHeight*(48-t)/48,z+48}end)
  contact(0,o.w,48)
 elseif o.kind=='rankPillar'then
  -- The projecting central moulding reaches lower than its side strips.
  draw(0,47,function(s,t)return t<38 or t==38 and s>=1 and s<31 or t<46 and s>=8 and s<24 or t==46 and s>=9 and s<23 end,
   function(s,t)return{x+s,c.wallHeight*(47-t)/47,z+48}end)
  contact(8,24,48)
 elseif o.kind=='rankTerminal'or o.kind=='rankMachine'then
  local big=o.kind=='rankMachine';local a,b=big and 8 or 0,big and 40 or 16
  local last,split=big and 40 or 32,big and 16 or 8
  local height,depth=big and c.machineHeight or c.terminalHeight,big and c.machineDepth or c.terminalDepth
  local inside=function(s)return s>=a and s<b end
  draw(0,split,inside,function(s,t)return{x+s,height,z+last-depth+t*depth/split}end)
  draw(split,last,inside,function(s,t)return{x+s,height*(last-t)/(last-split),z+last}end)
  for _,ss in ipairs({a,b})do local m,u,v=source(ss==a and a or b-1,split+2)
   patch(m,u,v,{x+ss,height,z+last-depth},{x+ss,height,z+last},{x+ss,0,z+last},{x+ss,0,z+last-depth},.97)
  end
  contact(a,b,last)
 elseif o.kind=='rankSeat'then
  local function inside(s,t)return R.seatInside(s,t,o.stool)end
  if not o.stool then draw(6,16,inside,function(s,t)return{x+s,c.backHeight-(t-6)*(c.backHeight-c.seatHeight)/10,z+20}end)end
  local start=o.stool and 14 or 16
  draw(start,27,inside,function(s,t)return{x+s,c.seatHeight,z+20+(t-start)*9/(27-start)}end)
  draw(27,31,inside,function(s,t)return{x+s,c.seatHeight*(31-t)/4,z+29}end)
  for _,ss in ipairs({1,15})do patch(0x249,2,12,{x+ss,c.seatHeight,z+20},{x+ss,c.seatHeight,z+29},{x+ss,0,z+29},{x+ss,0,z+20},.97)end
  contact(0,16,29)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
