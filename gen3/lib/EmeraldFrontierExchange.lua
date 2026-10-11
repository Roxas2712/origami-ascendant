-- Measured BP exchange room. Original shelves, open U-counter and terminal;
-- graphics-only replacement, with native NPCs, collision and shop scripts.
local V=...
local R={}
function R.profile(d)
 if not d then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.frontierExchange.enabled and(d.id or d.name)=='EM_BATTLE_FRONTIER_EXCHANGE_SERVICE_CORNER'and d.pair=='building__battle_frontier'
  and L and L.width==16 and L.height==12 and L:midAt(7,1)==0x309 and L:midAt(3,6)==0x3f8 then return c.homeRooms.frontierExchange end
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.frontierExchange;local objects,mask={},{}
 local rugs={[0x36d]=true,[0x36e]=true,[0x36f]=true,[0x375]=true,[0x376]=true,[0x377]=true}
 for y=0,11 do for x=0,15 do local m=L:midAt(x,y);local k=y*16+x+1
  if m==1 or y<2 then mask[k]={mid=1,void=true}
  elseif not rugs[m]then mask[k]=(x+y)%2==0 and 0x3b9 or 0x3b8 end
 end end
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for x=0,14 do add('wall',x,0,1,2,{clean={0x2e0+x%3,0x2e8+x%3},wallHeight=c.wallHeight,wallLast=32,wallBase=32})end
 add('exchangeShelves',4,0,7,4)
 add('exchangeCounter',3,1,9,6)
 add('exchangeTerminal',14,0,1,3)
 -- The two benches share the measured native Frontier seat contour.
 add('frontLoungeSeat',0,3,1,3)
 add('frontLoungeSeat',0,7,1,2)
 return objects,mask
end
function R.actorHeight(d,x,z)
 if not R.profile(d)then return end
 local foot=z+16
 if x+8>=5 and x+8<15 and(foot>=52 and foot<=96 or foot>=116 and foot<=144)then
  local c=V.require('DioramaConfig').emeraldInteriors;return c.frontierLounges.seatHeight*c.heightScale
 end
end
function R.counterInside(s,t)
 if s<0 or s>=144 or t<8 or t>=96 then return false end
 if t<76 then return s<16 or s>=128 end
 return t<95 or s>=1 and s<143
end
function R.shelfInside(s,t)return s>=0 and s<112 and t>=16 and t<64 and(t<48 or s<32 or s>=80)end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.frontierExchange;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source,function(s,t)return t>=a and t<b and inside(s,t)end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(s,t,a,b,d,e,shade)local m,u,v=source(s,t);G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,c.contactStrength}end end end
 if o.kind=='exchangeCounter'then
  draw(8,86,R.counterInside,function(s,t)return{x+s,c.counterHeight,z+10+t}end)
  draw(86,96,R.counterInside,function(s,t)return{x+s,c.counterHeight*(96-t)/10,z+96}end)
  for _,ss in ipairs({0,16,128,144})do local endZ=(ss==0 or ss==144)and 96 or 86;patch(1,88,{x+ss,c.counterHeight,z+18},{x+ss,c.counterHeight,z+endZ},{x+ss,0,z+endZ},{x+ss,0,z+18},.96)end
  patch(32,88,{x+16,c.counterHeight,z+86},{x+128,c.counterHeight,z+86},{x+128,0,z+86},{x+16,0,z+86},.96)
  for _,a in ipairs({0,128})do patch(1,88,{x+a,c.counterHeight,z+18},{x+a+16,c.counterHeight,z+18},{x+a+16,0,z+18},{x+a,0,z+18},.96)end
  contact(0,144,96)
 elseif o.kind=='exchangeShelves'then
  -- All three top caps share their seam. The middle cabinet is shorter and
  -- hangs between the full-height sides; its native empty underside stays open.
  draw(16,22,R.shelfInside,function(s,t)return{x+s,c.shelfHeight,z+64-c.shelfDepth+(t-16)*c.shelfDepth/6}end)
  draw(22,64,R.shelfInside,function(s,t)return{x+s,c.shelfHeight*(64-t)/42,z+64}end)
  local midBase=c.shelfHeight*16/42
  for _,ss in ipairs({0,112})do patch(ss==0 and 0 or 111,32,{x+ss,c.shelfHeight,z+64-c.shelfDepth},{x+ss,c.shelfHeight,z+64},{x+ss,0,z+64},{x+ss,0,z+64-c.shelfDepth},.96)end
  for _,ss in ipairs({32,80})do patch(ss==32 and 31 or 80,54,{x+ss,midBase,z+64-c.shelfDepth},{x+ss,midBase,z+64},{x+ss,0,z+64},{x+ss,0,z+64-c.shelfDepth},.96)end
  patch(40,44,{x+32,midBase,z+64-c.shelfDepth},{x+80,midBase,z+64-c.shelfDepth},{x+80,midBase,z+64},{x+32,midBase,z+64},.96)
  contact(0,32,64);contact(80,112,64)
 elseif o.kind=='exchangeTerminal'then
  local function inside(s,t)local inset=t==8 and 3 or t==9 and 2 or t==10 and 1 or t==39 and 1 or 0;return s>=inset and s<16-inset end
  draw(8,14,inside,function(s,t)return{x+s,c.terminalHeight,z+40-c.terminalDepth+(t-8)*c.terminalDepth/6}end)
  draw(14,40,inside,function(s,t)return{x+s,c.terminalHeight*(40-t)/26,z+40}end)
  for _,ss in ipairs({0,16})do patch(1,16,{x+ss,c.terminalHeight,z+40-c.terminalDepth},{x+ss,c.terminalHeight,z+40},{x+ss,0,z+40},{x+ss,0,z+40-c.terminalDepth},.96)end
  contact(0,16,40)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
