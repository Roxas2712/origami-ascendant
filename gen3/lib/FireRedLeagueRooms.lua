-- Measured FR Elite Four chambers. Native art, separate walls and objects.
-- Edition-specific object kinds keep Emerald's tile-local shadow writers
-- from interpreting these already projected world-space objects.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.fireredLeague end
local specs={LORELEIS={floor=0x2a8,shadow={0x2b1,0x2b2},cap=0x34a},BRUNOS={floor=0x2d0,shadow={0x2d7,0x2d8},cap=0x359},AGATHAS={floor=0x2f0,shadow={0x2f7,0x2f8},cap=0x354},LANCES={floor=0x310,shadow={0x317,0x318,0x319,0x33f},cap=0x370}}
function R.profile(d)
 local name=d and(d.id or''):match('^FR_POKEMON_LEAGUE_(%u+)_ROOM$');local p=specs[name];local L=d and d.midLayout
 if not(cfg().enabled and p and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d50c4'and L)then return end
 local large=name=='LANCES';local y=large and 3 or 0
 if L.width~=(large and 28 or 14)or L.height~=(large and 24 or 14)or L:midAt(0,y)~=0x283 or L:midAt(2,y+5)~=p.cap then return end
 return p,name
end
function R.lighting(d)
 local _,name=R.profile(d);if not name then return end
 local c=cfg();local p=c.lights[name];local sources={}
 for _,a in ipairs(p.at)do sources[#sources+1]={at={a[1],c.lightHeight,a[2]},radius=c.lightRadius,power=c.lightPower,color=p.color,spread=c.lightSpread}end
 return{fixed=true,ambient=p.ambient,localSelection=true,sources=sources}
end
function R.doorPose(d,a)
 local _,name=R.profile(d);if not name or not a then return end
 local y=name=='LANCES'and 5 or 2
 if a.x==6 and a.y==y then return{height=cfg().wallHeight*32/43*V.require('Billboard').heightScale(),base=0,top=0}end
end
function R.plan(d)
 local L=d and d.midLayout;if L then R.rooms[L]=nil end
 local p,name=R.profile(d);if not p then return end
 local own,mask={},{};local c=cfg();R.rooms[L]={p=p,name=name,objects=own}
 for i=1,L.width*L.height do mask[i]={mid=8,void=true,separateSurface=true}end
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w;o.h=h;own[#own+1]=o;return o end
 local dy=name=='LANCES'and 48 or 0
 add('frLeagueWall',0,dy,208,48,{height=c.wallHeight,rear=true})
 add('frLeagueWall',0,160+dy,name=='LANCES'and 240 or 208,48,{height=name=='LANCES'and c.partitionHeight or c.cutawayHeight,opening=true})
 if name=='LANCES'then
  add('frLeagueWall',240,96,192,48,{height=c.wallHeight,rear=true})
  add('frLeagueWall',0,336,320,48,{height=c.cutawayHeight})
 end
 for _,x in ipairs{32,160}do for _,y in ipairs{32,72,120}do add('frLeaguePillar',x,y+dy,16,40)end end
 if name=='LANCES'then
  for _,p in ipairs{{336,192},{400,192},{16,256},{64,256},{128,256},{176,256},{16,320},{64,320},{128,320},{176,320}}do add('frLeagueStatue',p[1],p[2],16,32)end
 end
 return{objects=own,mask=mask,owners={}}
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local state=R.rooms[L];if not state then return end
 local c,p=cfg(),state.p;local G,B=V.require('WorldGeometry'),V.require('BuildingMesh')
 local function src(s,t)return L:midAt(math.floor(s/16),math.floor(t/16)),s%16,t%16 end
 local function draw(w,h,source,inside,project,shade)
  local vv=V.require('PaperSprite').build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 local function floorAt(s,t)
  if s<0 or t<0 or s>=L.width*16 or t>=L.height*16 or L:midAt(math.floor(s/16),math.floor(t/16))==8 then return end
  local donor=false
  for _,o in ipairs(objects)do
   if o.kind=='frLeagueWall'and s>=o.x and s<o.x+o.w and t>=o.y and t<o.y+o.h then
    if o.rear then return end
    donor=true
   elseif o.kind~='frLeagueWall'and s>=o.x and s<o.x+32 and t>=o.y and t<o.y+o.h+8 then donor=true end
  end
  return donor
 end
 draw(L.width*16,L.height*16,function(s,t)if floorAt(s,t)then return p.floor,s%16,t%16 end;return src(s,t)end,
  function(s,t)return floorAt(s,t)~=nil end,function(s,t)return{s,0,t}end)
 local bg={};for _,m in ipairs{p.floor,unpack(p.shadow)}do for y=0,15 do for x=0,15 do bg[rgb(B.pixel(ts,m,x,y))]=true end end end
 for _,o in ipairs(objects)do local first=#out+1
  if o.kind=='frLeagueWall'then
   local height=o.height*V.require('Billboard').heightScale()
   local function source(s,t)
    local xx,yy=o.x+s,o.y+5+t
    -- Upper pillar caps overlap these original wall cells. Recover the
    -- native alternating wall panel behind them, without lifting the cap.
    if o.rear and o.x==0 and yy>=o.y+32 and(xx>=32 and xx<48 or xx>=160 and xx<176)then
     local top=L:midAt(math.floor(xx/16),o.y/16+1);return top==0x284 and 0x285 or 0x287,xx%16,yy%16
    end
    return src(xx,yy)
   end
   local function visible(s)return not(o.opening and s>=92 and s<116)end
   draw(o.w,43,source,function(s)return visible(s)end,function(s,t)return{o.x+s,height*(43-t)/43,o.y+48}end)
   draw(o.w,c.wallDepth,function(s,t)return 0x283,s%16,5 end,function(s)return visible(s)end,
    function(s,t)return{o.x+s,height,o.y+48-c.wallDepth+t}end)
   -- Ends close each strip; doorway returns leave its native corridor open.
   for _,s in ipairs(o.opening and{0,92,116,o.w}or{0,o.w})do
    draw(c.wallDepth,43,function(_,t)return source(math.min(o.w-1,s),t)end,nil,
     function(t,v)return{o.x+s,height*(43-v)/43,o.y+48-c.wallDepth+t}end,c.sideShade)
   end
  else
   local statue=o.kind=='frLeagueStatue';local w,h=o.w,o.h
   local function source(s,t)
    if statue and t>=16 then return 0x249,s,t-16 end
    return src(o.x+s,o.y+t)
   end
   -- Derive the contour from an unobscured copy of the same native pillar.
   -- A row span keeps original enclosed pale/green centres fully opaque.
   local rows={};for t=0,h-1 do local a,b=w,-1
    for s=0,w-1 do
     local m,u,v
     if statue then m,u,v=source(s,t)else m,u,v=src(o.x+s,(state.name=='LANCES'and 168 or 120)+t)end
     local r,g,bl,alpha=B.pixel(ts,m,u,v)
     if alpha>.5 and not bg[rgb(r,g,bl)]then a=math.min(a,s);b=math.max(b,s)end
    end
    rows[t]={a,b}
   end
   local last=statue and 32 or 38
   local function inside(s,t)local a=rows[t];return t<last and a and s>=a[1]and s<=a[2]end
   local height=(statue and c.statueScale or c.pillarScale)*V.require('Billboard').heightScale()
   local front=o.y+last;local depth=c.objectDepth
   draw(w,h,source,inside,function(s,t)return{o.x+s,(last-t)*height,front}end)
   for t=0,last-1 do local a=rows[t];if a and a[1]<=a[2]then
    for _,s in ipairs{a[1],a[2]+1}do
     local m,u,v=source(math.min(w-1,s),t)
     G.quad(out,{o.x+s+ox*16,(last-t)*height,front-depth+oz*16},{o.x+s+ox*16,(last-t)*height,front+oz*16},
      {o.x+s+ox*16,(last-t-1)*height,front+oz*16},{o.x+s+ox*16,(last-t-1)*height,front-depth+oz*16},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)
    end
   end end
   contacts[#contacts+1]={o.x+8+ox*16,front+oz*16,7,c.contactRadius,c.contactStrength}
  end
  local rig=V.require('RoomLightRig')
  if o.kind=='frLeagueWall'and o.opening then
   local boxes=rig.geometry[L]
   if boxes then for _,span in ipairs{{0,92},{116,o.w}}do
    boxes[#boxes+1]={lo={o.x+span[1]+ox*16,0,o.y+48-c.wallDepth+oz*16},
     hi={o.x+span[2]+ox*16,o.height*V.require('Billboard').heightScale(),o.y+48+oz*16},wall=true}
   end end
  else rig.capture(L,o,out,first,#out)end
 end
end
return R
