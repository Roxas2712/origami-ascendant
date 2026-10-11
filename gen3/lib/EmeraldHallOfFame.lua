-- Hall of Fame: original display wall, low side returns and a separate console.
local V=...
local R={}
function R.profile(d)
 if not d then return end
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.hallOfFame.enabled and(d.id or d.name)=='EM_EVER_GRANDE_CITY_HALL_OF_FAME'and d.pair=='building__cable_club'and L and L.width==16 and L.height==18 and L:midAt(7,7)==0x2f6 and L:midAt(7,4)==0x2f2 then return c.homeRooms.hallOfFame end
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind='fame'..kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o end
 for y=0,17 do for x=0,15 do local m=L:midAt(x,y)
  if m==1 or m==0x201 then mask[y*16+x+1]={mid=m,void=true}
  else mask[y*16+x+1]={mid=1,void=true}end
 end end
 add('Floor',0,0,15,16)
 add('Rear',0,0,15,4)
 for _,x in ipairs({0,13})do add('Side',x,3,2,13,{right=x==13})end
 add('Console',6,3,3,3)
 add('Entry',5,16,5,1)
 return objects,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.hallOfFame;local B=V.require('BuildingMesh');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local floor=rgb(B.pixel(ts,0x2f6,0,0))
 local function native(s,t)local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v);return a>=.5 and math.max(r,g,b)>.02 and rgb(r,g,b)~=floor end
 local function draw(a,b,project,inside,src)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function foot(s)
  if s<16 then return 48-s/2 elseif s<80 then return 40 elseif s<88 then return 40+(s-80)*2.5 elseif s<152 then return 60 elseif s<160 then return 60-(s-152)*2.5 elseif s<224 then return 40 else return 40+(s-224)/2 end
 end
 if o.kind=='fameFloor'then
  draw(0,o.h,function(s,t)return{x+s,0,z+t}end,function(s,t)return s>=12 and s<228 and t>=40 end,function(s,t)return 0x2f6,s%16,t%16 end)
 elseif o.kind=='fameRear'then
  -- The projecting central screen has its own native plinth, not a flat decal.
  local function src(s,t)if s>=96 and s<144 and t>=56 then return source(92,t)end;return source(s,t)end
  for _,r in ipairs({{0,16,0,40},{16,80,0,40},{80,88,16,60},{88,152,16,60},{152,160,16,60},{160,224,0,40},{224,240,0,40}})do
   draw(r[3],r[4],function(s,t)return{x+s,(r[4]-t)/(r[4]-r[3])*c.wallHeight,z+foot(s)}end,function(s,t)
    if s<r[1]or s>=r[2]then return false end
    local m,u,v=src(s,t);local rr,g,b,a=B.pixel(ts,m,u,v);return a>=.5 and math.max(rr,g,b)>.02
   end,src)
  end
 elseif o.kind=='fameSide'then
  local function height(t)return c.sideHeight-(c.sideHeight-c.frontHeight)*math.max(0,(t-160)/48)end
  draw(0,o.h,function(s,t)
   local u=o.right and 31-s or s;local h=height(t)
   if u<5 then return{x+s,h,z+t}end
   return{x+(o.right and 20 or 12),h*math.max(0,(12-u)/7),z+t}
  end,function(s,t)local u=o.right and 31-s or s;return u<12 and native(s,t)end)
 elseif o.kind=='fameConsole'then
  -- Interior screen pixels can equal floor purple; keep closed row spans.
  local spans={}
  for t=8,40 do local a,b=48,-1;for s=0,47 do if native(s,t)then a=math.min(a,s);b=math.max(b,s)end end;if b>=a then spans[t]={a,b+1}end end
  local function inside(s,t)local q=spans[t];return q and s>=q[1]and s<q[2]end
  draw(8,32,function(s,t)return{x+s,c.consoleFrontHeight+(32-t)*(c.consoleHeight-c.consoleFrontHeight)/24,z+16+(t-8)}end,inside)
  draw(32,41,function(s,t)return{x+s,c.consoleFrontHeight*(41-t)/9,z+40}end,inside)
  if contacts then contacts[#contacts+1]={x+24,z+40,20,2,c.contactStrength}end
 elseif o.kind=='fameEntry'then
  draw(0,16,function(s,t)return{x+s,.05,z+t}end,function(s,t)local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v);return a>=.5 and math.max(r,g,b)>.02 end)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
-- Read native animation state only. Project its existing glow sprites onto the
-- sloping machine face; lifecycle, sound and party recording remain native.
function R.recordSprites(d,fx)
 if not R.profile(d)then return{}end
 if not fx then local ok,m=pcall(require,'src.core.game3.field_effects_rse');if ok then fx=m end end
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.hallOfFame
 local out={}
 for _,e in ipairs(fx and fx._list or{})do
  if e.name=='pokeball_glow'and not e.hidden and(not e.delay or e.delay<=0)then
   local sheet,a=e.sheet,e.a;local q=sheet and a and sheet.quads[a.frame or 0]
   if q and e.x>=96 and e.x<=144 and e.y>=56 and e.y<=80 then
    local function point(xx,yy)return{xx,(c.consoleFrontHeight+(80-yy)*(c.consoleHeight-c.consoleFrontHeight)/24)*cfg.heightScale+.2,yy+8}end
    local left,right=e.x-sheet.fw/2,e.x+sheet.fw/2;local top,bottom=e.y-sheet.fh/2,e.y+sheet.fh/2
    out[#out+1]={image=sheet.image,quad=q,flip=a.hflip,vflip=a.vflip,surface={point(left,top),point(right,top),point(right,bottom),point(left,bottom)}}
   end
  end
 end
 return out
end
return R
