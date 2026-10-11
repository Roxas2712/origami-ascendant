-- The native Trainer Tower reception has a continuous L-shaped counter on
-- each side of the corridor. Its devices are not part of that red surface.
local V=...;local T={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.trainerTowerLobby end
function T.profile(d)
 local L=d and d.midLayout
 local match=cfg().enabled and d and d.id=='FR_TRAINER_TOWER_LOBBY'and d.mapType==8
  and (d.renderPair or d.pair)=='building__rom_082d5094'and L and L.width==20 and L.height==18
  and L:midAt(7,4)==0x2a4 and L:midAt(10,4)==0x2a6 and L:midAt(2,8)==0x2bd
  and L:midAt(9,1)==0x2e0 and L:midAt(11,3)==0x2e7
 if not match then return false end
 for i,m in ipairs{0x2e0,0x2e1,0x2e2,0x2e3,0x2e4,0x2e5,0x2df,0x2e6,0x2e7}do
  if L:midAt(9+(i-1)%3,1+math.floor((i-1)/3))~=m then return false end
 end
 return true
end
function T.lighting(d)if T.profile(d)then return cfg().light end end
function T.plan(d,objects,mask)
 local L=d.midLayout;if L then T.rooms[L]=nil end
 if not T.profile(d)then return end
 local own={};T.rooms[L]=own
 local function add(kind,x,y,w,h,extra)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w;o.h=h;own[#own+1]=o;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do local k=yy*L.width+xx+1
   mask[k]={mid=0x281,void=type(mask[k])=='table'and mask[k].void,separateSurface=true}
  end end
 end
 for k,c in ipairs(L.cells)do if c.mid==8 or c.mid==0 then mask[k]={mid=8,void=true,separateSurface=true}end end
 for x=7,11 do add('towerLobbyWall',x,0,1,2,{top=0x289,bottom=0x291})end
 for x=0,18 do if x<=6 or x>=12 then
  local keep=x==4 or x==5 or x>=16
  add('towerLobbyWall',x,7,1,2,{top=keep and L:midAt(x,7)or 0x289,bottom=keep and L:midAt(x,8)or 0x291})
 end end
 for _,x in ipairs{6,12}do add('towerLobbySideWall',x,0,1,7,{left=x==6})end
 for _,o in ipairs(own)do for y=o.y,o.y+o.h-1 do for x=o.x,o.x+o.w-1 do
  mask[y*L.width+x+1]={mid=8,void=true,separateSurface=true}
 end end end
 add('towerLobbyCounter',1,4,8,7)
 add('towerLobbyCounter',10,4,9,7)
 add('towerLobbyHealer',2,8,2,2)
 add('towerLobbyLamp',0,8,1,2,{clip={0,0,16,25}})
 add('towerLobbyDevice',0,9,1,3,{clip={0,9,16,48}})
 add('towerLobbyDevice',8,9,1,3,{clip={0,12,16,40}})
 add('towerLobbyDevice',6,8,1,2,{cabinet=true,clip={0,8,16,29}})
 add('towerLobbyDevice',15,8,1,3,{divider=true,clip={5,3,11,36}})
 for _,x in ipairs{7,10}do add('towerLobbyStatue',x,8,2,2,{clip={8,0,24,20}})end
 add('towerLobbyStairs',9,1,3,3)
 for y=1,3 do for x=9,11 do mask[y*L.width+x+1]={mid=8,void=true,separateSurface=true}end end
 for _,x in ipairs{0,2,4,14,16,18}do add('towerLobbyPlant',x,14,1,2)end
 -- These two original floor rows contain the three complete blue emblems.
 -- Restore them pixel-for-pixel around the separate terminal at (8,9).
 for y=11,13 do for x=0,18 do if not mask[y*L.width+x+1]then
  mask[y*L.width+x+1]={mid=L:midAt(x,y),separateSurface=true}
 end end end
 for y=15,16 do for x=8,10 do mask[y*L.width+x+1]={mid=L:midAt(x,y),separateSurface=true}end end
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local function flood(w,h,clear)
 local empty,queue={},{}
 local function seed(x,y)local k=y*w+x;if clear[k]and not empty[k]then empty[k]=true;queue[#queue+1]=k end end
 for x=0,w-1 do seed(x,0);seed(x,h-1)end;for y=0,h-1 do seed(0,y);seed(w-1,y)end
 local n=1;while queue[n]do local k=queue[n];n=n+1;local x,y=k%w,math.floor(k/w)
  if x>0 then seed(x-1,y)end;if x<w-1 then seed(x+1,y)end;if y>0 then seed(x,y-1)end;if y<h-1 then seed(x,y+1)end
 end
 return function(x,y)return x>=0 and y>=0 and x<w and y<h and not empty[y*w+x]end
end
function T.actorOffset(d,px,pz)
 if not T.profile(d)then return end
 local x,z=px+8-9*16,pz+16-16
 if x>=0 and x<48 and z>=16 and z<=48 then return(math.min(7,math.floor(x/6))+1)*cfg().height/8,0 end
end
function T.build(out,objects,L,ts,ox,oz,contacts)
 if not T.rooms[L]then return end
 local c=cfg();local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local P=V.require('PaperSprite')
 local floor={};for _,m in ipairs{0x281,0x283,0x284,0x285,0x286,0x2b1,0x2d2,0x2d3,0x2d4,0x2da,0x2db,0x2dc}do
  for y=0,15 do for x=0,15 do floor[rgb(B.pixel(ts,m,x,y))]=true end end
 end
 local red=rgb(1,132/255,115/255);local edgeRed=rgb(206/255,82/255,66/255)
 local wall={};for _,p in ipairs{{0x289,8,10},{0x291,8,10},{0x291,0,0}}do wall[rgb(B.pixel(ts,unpack(p)))]=true end
 local function q(a,b,d,e,uv,s)G.quad(out,a,b,d,e,uv,s or 1)end
 for _,o in ipairs(T.rooms[L])do
  local first=#out+1;local x,z=(o.x+ox)*16,(o.y+oz)*16;local W,H=o.w*16,o.h*16
  local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local function draw(w,h,source,inside,project)
   local vv=P.build(ts,w,h,source,inside,0,h,1,nil,project,.5);for _,v in ipairs(vv)do out[#out+1]=v end
  end
  if o.kind=='towerLobbyWall'then
   draw(16,32,function(s,t)return t<16 and o.top or o.bottom,s,t%16 end,function()return true end,
    function(s,t)return{x+s,c.wallHeight*(32-t)/32,z+32}end)
  elseif o.kind=='towerLobbySideWall'then
   local xx=x+(o.left and 16 or 0);local outer=xx+(o.left and -c.wallDepth or c.wallDepth)
   draw(112,32,function(s,t)return t<16 and 0x289 or 0x291,s%16,t%16 end,function()return true end,
    function(s,t)return{xx,c.wallHeight*(32-t)/32,z+32+s}end)
   q({xx,c.wallHeight,z+32},{outer,c.wallHeight,z+32},{outer,c.wallHeight,z+144},{xx,c.wallHeight,z+144},G.uv(ts,0x289,6,1,7,2,.5))
  elseif o.kind=='towerLobbyStairs'then
   V.require('SilphStairs').build(out,{{kind='silphStairs',x=o.x,y=o.y,left=false,down=false,stairConfig=c}},L,ts,ox,oz)
  else
   local counter=o.kind=='towerLobbyCounter';local clear={}
   for t=0,H-1 do for s=0,W-1 do local r,g,b,a=B.pixel(ts,src(s,t));local col=rgb(r,g,b)
    clear[t*W+s]=counter and col~=red and col~=edgeRed or not counter and(a<.5 or floor[col]or wall[col]or col==red or col==edgeRed or r+g+b==0)
   end end
   local nativeInside=flood(W,H,clear)
   local function inside(s,t)
    local b=o.clip
    if b and(s<b[1]or t<b[2]or s>=b[3]or t>=b[4])then return false end
    if o.cabinet and s<5 and t<13 then return false end
    return nativeInside(s,t)
   end
   -- Original floor art outside each silhouette stays flat, including the
   -- left edge of the centre emblem in the terminal's bottom source cell.
   draw(W,H,src,function(s,t)return not inside(s,t)and floor[rgb(B.pixel(ts,src(s,t)))]end,
    function(s,t)return{x+s,.02,z+t}end)
   if counter then
    local function source(s,t)
     local m,u,v=src(s,t);local col=rgb(B.pixel(ts,m,u,v));local gx,gy=o.x*16+s,o.y*16+t
     local plate=(gx>=64 and gx<80 or gx>=224 and gx<240)and gy>=144 and gy<160
      or gx>=160 and gx<176 and gy>=96 and gy<112
     if col==red or col==edgeRed or plate then return m,u,v end
     return 0x29e,8,2 -- hidden surface beneath the separate native device
    end
    draw(W,H,source,inside,function(s,t)return{x+s,c.counterHeight,z+t}end)
    -- Merge identical occupied row spans into exact boxes. The hollow
    -- centre of an L-shaped counter must not become a light blocker.
    local rig=V.require('RoomLightRig').geometry[L];local runs={}
    if rig then for t=0,H-1 do local nextRuns={};local s=0
     while s<W do
      if inside(s,t)then local left=s;repeat s=s+1 until s>=W or not inside(s,t)
       local key=left..':'..s;local box=runs[key]
       if box then box.hi[3]=z+t+1 else
        box={lo={x+left,0,z+t},hi={x+s,c.counterHeight,z+t+1},wall=false}
        rig[#rig+1]=box
       end
       nextRuns[key]=box
      else s=s+1 end
     end
     runs=nextRuns
    end end
    local uv=G.uv(ts,0x29e,5,8,6,15,.5)
    for t=0,H-1 do for s=0,W-1 do if inside(s,t)then
     local a,b=x+s,z+t
     if not inside(s,t+1)then q({a,c.counterHeight,b+1},{a+1,c.counterHeight,b+1},{a+1,0,b+1},{a,0,b+1},uv)
      if s%8==4 then contacts[#contacts+1]={a,b+1,5,c.contactRadius,c.contactStrength}end end
     if not inside(s-1,t)then q({a,c.counterHeight,b},{a,c.counterHeight,b+1},{a,0,b+1},{a,0,b},uv,c.sideShade)end
     if not inside(s+1,t)then q({a+1,c.counterHeight,b+1},{a+1,c.counterHeight,b},{a+1,0,b},{a+1,0,b+1},uv,c.sideShade)end
     if not inside(s,t-1)then q({a+1,c.counterHeight,b},{a,c.counterHeight,b},{a,0,b},{a+1,0,b},uv,c.sideShade)end
    end end end
   elseif o.kind=='towerLobbyLamp'then
    draw(W,H,src,inside,function(s,t)return{x+s,32-t,z+16+.04}end)
   else
    local last=0;for t=0,H-1 do for s=0,W-1 do if inside(s,t)then last=math.max(last,t+1)end end end
    local statue=o.kind=='towerLobbyStatue';local base=(statue or o.divider)and c.counterHeight or 0
    local scale=statue and c.statueScale or o.kind=='towerLobbyPlant'and c.plantHeight/math.max(1,last)or c.deviceScale
    scale=scale*V.require('Billboard').heightScale()
    draw(W,H,src,inside,function(s,t)return{x+s,base+(last-t)*scale,z+last}end)
    for t=0,last-1 do for s=0,W-1 do if inside(s,t)then
     local m,u,v=src(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local a,b=x+s,z+last
     local h0,h1=base+(last-t)*scale,base+(last-t-1)*scale
     if not inside(s-1,t)then q({a,h0,b-3},{a,h0,b},{a,h1,b},{a,h1,b-3},uv,c.sideShade)end
     if not inside(s+1,t)then q({a+1,h0,b},{a+1,h0,b-3},{a+1,h1,b-3},{a+1,h1,b},uv,c.sideShade)end
     if not inside(s,t-1)then q({a,h0,b-3},{a+1,h0,b-3},{a+1,h0,b},{a,h0,b},uv)end
    end end end
    contacts[#contacts+1]={x+W/2,z+last,W/2-1,c.contactRadius,c.contactStrength}
   end
  end
  if o.kind~='towerLobbyCounter'and o.kind~='towerLobbyPlant'then V.require('RoomLightRig').capture(L,o,out,first,#out)end
 end
end
return T
