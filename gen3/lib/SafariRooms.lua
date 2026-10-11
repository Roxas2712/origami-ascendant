-- Native Safari/Lorelei room family. Each surface owns only its source art;
-- rugs, door mats and native event/collision data stay on their original grid.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.safariRooms end
local specs={FR_FUCHSIA_CITY_SAFARI_ZONE_ENTRANCE={10,10,'entrance',0x282},FR_FUCHSIA_CITY_SAFARI_ZONE_OFFICE={20,12,'office',0x2a8},FR_FOUR_ISLAND_LORELEIS_HOUSE={12,10,'lorelei',0x108},FR_SAFARI_SECRET={14,12,'secret',0x281},FR_SAFARI_REST={14,12,'rest',0x281}}
function R.profile(d)
 local L=d and d.midLayout;if not(cfg().enabled and d and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4f14'and L)then return end
 local p=specs[d.id]
 if d.id=='FR_SAFARI_ZONE_SECRET_HOUSE'then p=specs.FR_SAFARI_SECRET
 elseif d.id=='FR_SAFARI_ZONE_CENTER_REST_HOUSE'or d.id=='FR_SAFARI_ZONE_EAST_REST_HOUSE'or d.id=='FR_SAFARI_ZONE_NORTH_REST_HOUSE'or d.id=='FR_SAFARI_ZONE_WEST_REST_HOUSE'then p=specs.FR_SAFARI_REST end
 if p and L.width==p[1]and L.height==p[2]and L:midAt(0,0)==p[4]then return p end
end
function R.plan(d,objects,mask)
 local L=d.midLayout;if L then R.rooms[L]=nil end;local p=R.profile(d);if not p then return end
 local c=cfg();local family=p[3];local floor=family=='lorelei'and 0x286 or family=='entrance'and 0x2a2 or 0x290
 local own={};R.rooms[L]=own
 local function add(kind,x,y,w,h,extra,donor)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w;o.h=h;o.floor=donor or floor;o.family=family;objects[#objects+1]=o;own[#own+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=o.floor,separateSurface=true}end end;return o
 end
 local width=family=='office'and 20 or L.width-1
 add('safariWall',0,0,width,2,{height=c.wallHeight,door=family=='entrance'})
 if family=='office'then add('safariWall',0,6,3,2,{height=c.wallHeight,partition=true});add('safariWall',6,6,14,2,{height=c.wallHeight,partition=true})end
 -- Complete source furniture drawings and floor-only shadows.
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==8 then mask[y*L.width+x+1]={mid=8,void=true,separateSurface=true}
  elseif m==0x298 or m==0x2b5 or m==0x287 or m==0x2d8 then mask[y*L.width+x+1]={mid=floor,separateSurface=true}
  elseif(m==0x28e or m==0x28f or m==0x2b2)and y+1<L.height then
   local below=L:midAt(x,y+1)
   if below==0x296 or below==0x297 or below==0x2bf then add('safariPlant',x,y,1,2,{height=c.plantHeight})end
  elseif m==0x2a8 and L:midAt(x+1,y)==0x2a9 and L:midAt(x,y+2)==0x2b8 then add('safariShelf',x,y,2,3,{start=8,last=39,height=c.shelfHeight,depth=6})
  elseif m==0x291 or m==0x2a0 or m==0x2c2 then add('safariStool',x,y,1,1,{height=c.seatHeight},m==0x2a0 and 0x2a2 or m==0x2c2 and 0x286 or floor)
  elseif m==0x2cc and L:midAt(x+1,y)==0x2cd and L:midAt(x,y+1)==0x2ce then add('safariTable',x,y,2,2,{height=c.tableHeight,split=26,last=31})
  elseif m==0x2c0 and L:midAt(x+1,y)==0x2c1 and L:midAt(x,y+1)==0x2c4 then add('safariDesk',x,y,2,2,{height=c.tableHeight},0x286)
  end
 end end
 if family=='entrance'then
  for _,x in ipairs{2,6}do add('safariCounter',x,1,1,7,{start=8,split=104,last=112,height=c.counterHeight})end
 elseif family=='rest'then
  add('safariCounter',8,5,5,2,{start=14,split=24,last=32,height=c.counterHeight})
  add('safariCounter',8,6,1,4,{start=0,split=56,last=64,height=c.counterHeight})
 elseif family=='lorelei'then
  add('safariCabinet',3,0,2,3,{shape='cabinet',start=12,last=39,height=c.shelfHeight,depth=7})
  add('safariCabinet',4,0,1,3,{shape='bin',start=25,last=39,height=c.binHeight,depth=0})
  add('safariCabinet',9,0,2,3,{shape='greenShelf',start=11,last=40,height=c.shelfHeight,depth=6})
  add('safariBackChair',8,0,1,3,{height=c.backHeight})
  add('safariBed',0,2,3,2,{height=c.bedHeight})
  add('safariTable',5,4,2,2,{height=c.tableHeight,split=26,last=31},0x2e5)
  add('safariDisplay',9,3,2,3,{height=c.tableHeight,split=39,last=46})
  add('safariChair',4,4,1,1,{right=false,height=c.seatHeight},0x2e5)
  add('safariChair',7,4,1,1,{right=true,height=c.seatHeight},0x2e5)
 end
 -- Crates keep their native arrangement; a shallow contour volume separates
 -- their contact edge from the floor without turning the pile into a wall.
 local crates={[0x29e]=true,[0x29f]=true,[0x2a3]=true,[0x2a6]=true,[0x2a7]=true,[0x2af]=true,[0x2ba]=true,[0x2bb]=true,[0x2c6]=true}
 for y=0,L.height-1 do for x=0,L.width-1 do if crates[L:midAt(x,y)]then add('safariCrate',x,y,1,1,{height=c.crateHeight})end end end
 -- Rear walls retain native void; their floor margins are independently filled.
 for _,o in ipairs(own)do if o.kind=='safariWall'then
  for y=o.y,o.y+1 do for x=o.x,o.x+o.w-1 do mask[y*L.width+x+1]={mid=8,void=true,separateSurface=true}end end
 end end
end
function R.actorOffset(d,x,z,gid)
 local p=R.profile(d);if not p or p[3]~='lorelei'or not gid or gid<100 or gid>133 then return end
 local xx,yy=math.floor((x+8)/16),math.floor(z/16);local c=cfg()
 if xx>=9 and xx<=10 and yy>=3 and yy<=4 or(xx==6 and yy==4)then return c.tableHeight,0 end
 if xx>=9 and xx<=10 and yy==0 then return c.shelfHeight*V.require('Billboard').heightScale(),24 end
end
function R.lighting(d)
 local p=R.profile(d);if not p then return end
 local c=cfg();local f=p[3];local sources={}
 for _,a in ipairs(c.sources[f]or c.sources.rest)do
  local daylight=a[5]=='window';sources[#sources+1]={at={a[1]*16,c.lightHeight,a[2]*16},power=a[3],
   nightPower=daylight and a[3]*c.windowNightScale or a[3],radius=a[4],
   color=daylight and c.windowColor or c.lampColor,spread=c.lightSpread}
 end
 return{ambient=c.ambient,night=c.nightAmbient,sources=sources}
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local own=R.rooms[L];if not cfg().enabled or not own then return end
 local c=cfg();local hs=V.require('Billboard').heightScale();local G,B,P=V.require('WorldGeometry'),V.require('BuildingMesh'),V.require('PaperSprite')
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local function draw(w,h,src,inside,project,shade)
  local vv=P.build(ts,w,h,src,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5);for _,v in ipairs(vv)do out[#out+1]=v end
 end
 for _,o in ipairs(own)do local x,z=(o.x+ox)*16,(o.y+oz)*16;local w,h=o.w*16,o.h*16;local first=#out+1
  local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  if o.kind=='safariWall'then
   local function src(s,t)
    local col=o.x+math.floor(s/16);local m,u,v=source(s,t)
    if o.family=='lorelei'then
     if col==3 or col==4 or col>=8 then m=t<16 and 0x108 or 0x110 end
    elseif o.family=='entrance'then
     if col<3 or col>5 then m=t<16 and 0x282 or 0x28f;if t>=16 then u=15 end end
    else
     local a=L:midAt(col,o.y)
     if a~=0x2c8 and a~=0x2c9 then m=t<16 and 0x281 or 0x289 end
    end
    return m,u,v
   end
   draw(w,32,src,nil,function(s,t)return{x+s,c.wallHeight*hs*(32-t)/32,z+32}end)
  else
   -- Native background palettes are removed only through edge-connected pixels.
   local bg={};for _,mid in ipairs{o.floor,0x290,0x298,0x286,0x287,0x2a2}do if ts.midToSlot[mid]then for t=0,15 do for s=0,15 do bg[rgb(B.pixel(ts,mid,s,t))]=true end end end end
   local clear,empty,q={},{},{}
   for t=0,h-1 do for s=0,w-1 do local m,u,v=source(s,t);local rr,gg,bb,a=B.pixel(ts,m,u,v);clear[t*w+s]=a<.5 or bg[rgb(rr,gg,bb)]end end
   local function seed(s,t)local k=t*w+s;if clear[k]and not empty[k]then empty[k]=true;q[#q+1]=k end end
   for s=0,w-1 do seed(s,0);seed(s,h-1)end;for t=0,h-1 do seed(0,t);seed(w-1,t)end
   local n=1;while q[n]do local k=q[n];n=n+1;local s,t=k%w,math.floor(k/w);if s>0 then seed(s-1,t)end;if s+1<w then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t+1<h then seed(s,t+1)end end
   local function inside(s,t)return s>=0 and s<w and t>=0 and t<h and not empty[t*w+s]end
   local function surface(start,finish,height)
    draw(w,h,source,function(s,t)return t>=start and t<finish and inside(s,t)end,function(s,t)return{x+s,height,z+t}end)
   end
   local function face(start,finish,height,baseY,zz)
    draw(w,h,source,function(s,t)return t>=start and t<finish and inside(s,t)end,function(s,t)return{x+s,height+(baseY-height)*(t-start)/(finish-start),zz}end)
   end
   if o.kind=='safariPlant'then
    -- The first source tile contains original wall behind the crown.
    local greens={};for t=0,31 do for s=0,15 do local m,u,v=source(s,t);local rr,gg,bb=B.pixel(ts,m,u,v)
     greens[t*16+s]=(gg>rr*1.06 and gg>bb*1.15)or t>=16 and inside(s,t)
    end end
    draw(16,32,source,function(s,t)return greens[t*16+s]end,function(s,t)return{x+s,c.plantHeight*hs*(32-t)/32,z+32}end)
   elseif o.kind=='safariShelf'or o.kind=='safariCabinet'then
    local shape=o.shape;local function cut(s,t)
     return t>=o.start and t<o.last and (not shape or V.require('InteriorHouseVariants').sourceInside({shape=shape,w=o.w,cap=o.start,last=o.last,y=o.y},s,t))
    end
    draw(w,h,source,cut,function(s,t)return{x+s,o.height*hs*(o.last-t)/(o.last-o.start),z+o.last}end)
   elseif o.kind=='safariCounter'then
    surface(o.start,o.split,o.height);face(o.split,o.last,o.height,0,z+o.split)
    for _,edge in ipairs{0,w}do
     for t=o.start,o.split-1 do local m,u,v=source(edge==0 and 0 or w-1,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
      G.quad(out,{x+edge,o.height,z+t},{x+edge,o.height,z+t+1},{x+edge,0,z+t+1},{x+edge,0,z+t},uv,c.sideShade)
     end
    end
   elseif o.kind=='safariTable'or o.kind=='safariDisplay'then
    surface(0,o.split,o.height);face(o.split,o.split+2,o.height,o.height-2,z+o.split)
    face(o.split+2,o.last,o.height-2,0,z+o.split)
   elseif o.kind=='safariStool'then surface(2,12,o.height);face(12,16,o.height,0,z+12)
   elseif o.kind=='safariCrate'then
    surface(0,h,o.height)
    for t=0,h-1 do for s=0,w-1 do if inside(s,t)and not inside(s,t+1)then local m,u,v=source(s,t);G.quad(out,{x+s,o.height,z+t+1},{x+s+1,o.height,z+t+1},{x+s+1,0,z+t+1},{x+s,0,z+t+1},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)end end end
   elseif o.kind=='safariDesk'then
    surface(15,26,o.height);face(26,31,o.height,0,z+26)
    draw(w,24,source,function(s,t)return t<20 and inside(s,t)end,function(s,t)return{x+s,o.height+(20-t)*hs,z+20}end)
   elseif o.kind=='safariBed'then
    local function bed(s,t)return s>=12 and s<36 and inside(s,t)end
    draw(w,h,source,bed,function(s,t)
     if t<4 then return{x+s,o.height+(4-t),z+4}end
     if t<27 then return{x+s,o.height,z+t}end
     return{x+s,o.height*(32-t)/5,z+27}
    end)
   elseif o.kind=='safariChair'then
    -- Native side-facing chair: back, seat, apron and feet are separate.
    -- Never collapse all 16 source rows onto the same vertical plane.
    local function src(s,t)return source(o.right and 15-s or s,t)end
    local function xx(s)return x+(o.right and 16-s or s)end
    local function part(s0,t0,ww,hh,project)
     draw(ww,hh,function(s,t)return src(s+s0,t+t0)end,
      function(s,t)return inside(o.right and 15-(s+s0)or s+s0,t+t0)end,
      function(s,t)return project(s+s0,t+t0)end)
    end
    part(0,1,4,11,function(s,t)return{xx(s),o.height+(12-t)*hs,z+12}end)
    part(4,5,9,7,function(s,t)return{xx(s),o.height,z+t}end)
    part(4,12,9,2,function(s,t)return{xx(s),o.height*(16-t)/4,z+12}end)
    part(0,14,16,2,function(s,t)return{xx(s),o.height*(16-t)/4,z+12}end)
   elseif o.kind=='safariBackChair'then
    draw(16,40,source,function(s,t)return t>=11 and s<15 end,function(s,t)
     if t<27 then return{x+s,c.backHeight*hs+(c.seatHeight-c.backHeight*hs)*(t-11)/16,z+30}end
     if t<34 then return{x+s,c.seatHeight,z+30+t-27}end
     return{x+s,c.seatHeight*(40-t)/6,z+37}
    end)
   end
   contacts[#contacts+1]={x+w/2,z+h,w*.4,c.contactRadius,c.contactStrength}
  end
  local kind=o.kind=='safariTable'or o.kind=='safariDisplay'or o.kind=='safariDesk'
  local lightKind=kind and 'table'or(o.kind=='safariPlant'and 'plant')or(o.kind=='safariStool'and 'seat')or(o.kind=='safariChair'and 'chair')or(o.kind=='safariBed'and 'bed')or o.kind
  V.require('RoomLightRig').capture(L,{kind=lightKind},out,first,#out)
 end
end
return R
