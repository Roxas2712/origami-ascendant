-- Measured native Fuchsia display homes and Resort Gorgeous. Background pixels
-- belong to wall/floor surfaces; cases, palms and furniture own separate meshes.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.displayHouses end
local specs={FR_FUCHSIA_CITY_HOUSE2={10,10,'house',0xac},FR_FUCHSIA_CITY_WARDENS_HOUSE={14,12,'warden',0xdd},FR_FIVE_ISLAND_RESORT_GORGEOUS_HOUSE={12,10,'resort',0x2bd}}
function R.profile(d)
 local p=d and specs[d.id];local L=d and d.midLayout
 if cfg().enabled and p and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4c2c'and L and L.width==p[1]and L.height==p[2]and L:midAt(0,0)==p[4]then return p end
end
function R.plan(d,objects,mask)
 local L=d.midLayout;if L then R.rooms[L]=nil end;local p=R.profile(d);if not p then return end
 local c=cfg();local f=p[3];local own={};R.rooms[L]=own
 local function add(kind,x,y,w,h,extra,donor)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w;o.h=h;o.family=f;objects[#objects+1]=o;own[#own+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=donor or 0x109,separateSurface=true}end end;return o
 end
 local width=f=='house'and 10 or L.width-1
 add('displayWall',0,0,width,2)
 local function panel(x,w,shape,start,last,height,depth)
  add('displayPanel',x,0,w,3,{shape=shape,cap=start,last=last,height=height,depth=depth})
 end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==8 then mask[y*L.width+x+1]={mid=8,void=true,separateSurface=true}
  elseif m==0x111 or m==0x112 then mask[y*L.width+x+1]={mid=0x109,separateSurface=true}
  elseif m==0xc2 and L:midAt(x,y+2)==0x132 then add('displayPlant',x,y,1,3,{shape='palm',cap=12,last=39,front=39,height=c.plantHeight})
  elseif m==0x155 or m==0x156 then add('displayPlant',x,y,1,2,{shape='palm',cap=4,last=31,front=31,height=c.plantHeight})
  elseif(m==0x102 or m==0x12e)and(L:midAt(x,y+1)==0x103 or L:midAt(x,y+1)==0x136)then add('displayPlant',x,y,1,2,{shape='broadPlant',cap=4,last=31,front=31,height=c.plantHeight})
  elseif m==0x126 or m==0x127 or m==0x173 then add('displayChair',x,y,1,1,{right=m==0x127,height=c.seatHeight},m==0x173 and 0x109 or 0x12c)
  end
 end end
 if f=='house'then
  panel(0,2,'cabinet',12,39,c.shelfHeight,c.shelfDepth);panel(1,1,'bin',25,39,c.binHeight,0)
  add('displayTable',7,5,2,2,{cap=1,split=24,last=31,height=c.tableHeight},0x12c)
 elseif f=='warden'then
  panel(0,2,'greenShelf',11,40,c.shelfHeight,c.shelfDepth);panel(2,2,'greenShelf',11,40,c.shelfHeight,c.shelfDepth)
  panel(4,1,'blueShelf',14,40,c.deviceHeight,c.shelfDepth)
  add('displayTable',0,4,2,2,{cap=1,split=24,last=31,height=c.tableHeight})
  for _,x in ipairs{4,6}do
   add('displayCase',x,3,2,3,{height=c.caseHeight})
   -- Native case bases cover a blue runner. Restore its middle and lower
   -- border independently; a wood donor would cut rectangular holes in it.
   for xx=x,x+1 do mask[4*L.width+xx+1]={mid=0x12c,separateSurface=true};mask[5*L.width+xx+1]={mid=0x134,separateSurface=true}end
  end
  add('displayCounter',10,3,3,3,{height=c.counterHeight})
 else
  panel(8,2,'greenShelf',11,40,c.shelfHeight,c.shelfDepth)
  add('displayTable',5,4,2,2,{cap=1,split=26,last=31,height=c.tableHeight},0x12c)
  for _,x in ipairs{0,10}do
   add('displayColumn',x,0,1,3,{height=c.columnHeight})
  end
 end
 -- Wall source lives upright; the third native row is its floor margin.
 for y=0,1 do for x=0,width-1 do mask[y*L.width+x+1]={mid=8,void=true,separateSurface=true}end end
end
function R.actorOffset(d,px,pz,gid)
 local p=R.profile(d);if not p then return end
 local x,y=math.floor((px+8)/16),math.floor(pz/16)
 if p[3]=='house'and gid==57 and x==6 and y==5 or p[3]=='resort'and gid==28 and x==4 and y==4 then return cfg().seatHeight,0 end
end
function R.lighting(d)
 local p=R.profile(d);if not p then return end
 local c=cfg();local sources={}
 for _,a in ipairs(c.sources[p[3]])do local kind=a[5]or 'lamp'
  sources[#sources+1]={at={a[1]*16,kind=='case'and c.caseLightHeight or c.lightHeight,a[2]*16},radius=a[4],power=a[3],nightPower=kind=='window'and a[3]*c.windowNightScale or a[3],color=c.colors[kind],spread=c.spread}
 end
 return{ambient=c.ambient,night=c.nightAmbient,sources=sources}
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local own=R.rooms[L];if not c.enabled or not own then return end
 local P,G,B=V.require('PaperSprite'),V.require('WorldGeometry'),V.require('BuildingMesh');local hs=V.require('Billboard').heightScale()
 local function draw(w,h,src,inside,project,shade)
  local vv=P.build(ts,w,h,src,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 for _,o in ipairs(own)do local x,z=(o.x+ox)*16,(o.y+oz)*16;local w,h=o.w*16,o.h*16;local first=#out+1
  local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  if o.kind=='displayWall'then
   local function wall(s,t)
    local col=math.floor(s/16);local mid,u,v=src(s,t)
    if o.family=='house'and(col<=1 or col>=8)or o.family=='warden'and col<=4 then mid=t<16 and 0xa8 or 0xb0
    elseif o.family=='resort'and(col==8 or col==9)then mid=t<16 and 0x287 or 0x28f end
    return mid,u,v
   end
   draw(w,32,wall,function(s)return o.family~='resort'or s>=16 and s<160 end,function(s,t)return{x+s,c.wallHeight*hs*(32-t)/32,z+32}end)
  elseif o.kind=='displayColumn'then
   draw(16,40,src,nil,function(s,t)return{x+s,c.columnHeight*hs*(40-t)/40,z+40}end)
  elseif o.kind=='displayPlant'or o.kind=='displayPanel'then
   local function inside(s,t)
    if o.shape=='greenShelf'and t>=11 and t<=12 then
     -- Native upper corners include wall and baked-shadow texels between
     -- the white posts. Those do not become a floating shelf/header line.
     return t==11 and(s==1 or s==30)or t==12 and(s>=1 and s<=4 or s>=28 and s<=30)
    end
    return V.require('InteriorHouseVariants').sourceInside(o,s,t)
   end
   local front=o.front or o.last
   if o.kind=='displayPlant'then
    draw(w,h,src,inside,function(s,t)return{x+s,o.height*hs*(o.last-t)/(o.last-o.cap),z+front}end)
   else
    draw(w,h,src,inside,function(s,t)return{x+s,o.height*hs*(o.last-t)/(o.last-o.cap),z+front}end)
    -- Thin textured side return gives rear furniture real depth. The front
    -- retains its complete source contour, including its native white trim.
    if o.depth>0 then
     for t=o.cap+2,o.last-1 do local a,b
      for s=0,w-1 do if inside(s,t)then a=a or s;b=s end end
      if a then for _,edge in ipairs{a,b+1}do local m,u,v=src(edge==a and a or b,t)
       G.quad(out,{x+edge,o.height*hs*(o.last-t)/(o.last-o.cap),z+front-o.depth},{x+edge,o.height*hs*(o.last-t)/(o.last-o.cap),z+front},
        {x+edge,o.height*hs*(o.last-t-1)/(o.last-o.cap),z+front},{x+edge,o.height*hs*(o.last-t-1)/(o.last-o.cap),z+front-o.depth},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)
      end end
     end
    end
   end
  elseif o.kind=='displayCase'then
   -- The native glass/specimen area slopes toward its front plaque. The
   -- plinth stays upright; native runner rows (40 onward) stay on the floor.
   draw(32,40,src,function(s,t)return t>=8 and t<26 and(t~=8 or s>0 and s<31)end,
    function(s,t)return{x+s,(o.height+c.caseRearRise*(26-t)/18)*hs,z+40-c.caseDepth*(26-t)/18}end)
   draw(32,40,src,function(s,t)return t>=26 end,function(s,t)return{x+s,o.height*hs*(40-t)/14,z+40}end)
   for _,edge in ipairs{0,32}do local m,u,v=src(edge==0 and 1 or 30,28)
    G.quad(out,{x+edge,(o.height+c.caseRearRise)*hs,z+40-c.caseDepth},{x+edge,o.height*hs,z+40},
     {x+edge,0,z+40},{x+edge,0,z+40-c.caseDepth},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)
   end
  else
   local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
   local bg={[rgb(123/255,123/255,123/255)]=true}
   local floors=o.kind=='displayChair'and(o.family=='warden'and{0x109,0x111}or{0x12c})or(o.family=='house'or o.family=='resort')and{0x12c}or{0x109,0x111}
   for _,f in ipairs(floors)do for yy=0,15 do for xx=0,15 do bg[rgb(B.pixel(ts,f,xx,yy))]=true end end end
   local function isFloor(s,t)local m,u,v=src(s,t);return bg[rgb(B.pixel(ts,m,u,v))]end
   local mask={};for t=0,h-1 do for s=0,w-1 do mask[t*w+s]=not isFloor(s,t)end end
   local function inside(s,t)return s>=0 and s<w and t>=0 and t<h and not(o.kind=='displayTable'and(s==0 or s==w-1))and mask[t*w+s]end
   local function band(a,b,project,cut)draw(w,h,src,function(s,t)return t>=a and t<b and inside(s,t)and(not cut or cut(s,t))end,project)end
   if o.kind=='displayTable'then
    band(o.cap,o.split,function(s,t)return{x+s,o.height,z+t}end)
    band(o.split,o.split+2,function(s,t)return{x+s,o.height-c.tableRim*(t-o.split)/2,z+o.split}end)
    band(o.split+2,o.last,function(s,t)return{x+s,(o.height-c.tableRim)*(o.last-t)/(o.last-o.split-2),z+o.split}end)
   elseif o.kind=='displayChair'then
    local function srcChair(s,t)return src(o.right and 15-s or s,t)end
    local function xx(s)return x+(o.right and 16-s or s)end
    local function part(a,b,ww,hh,project)
     draw(ww,hh,function(s,t)return srcChair(s+a,t+b)end,function(s,t)return inside(o.right and 15-s-a or s+a,t+b)end,function(s,t)return project(s+a,t+b)end)
    end
    part(0,1,4,11,function(s,t)return{xx(s),o.height+(12-t)*hs,z+12}end)
    part(4,5,9,7,function(s,t)return{xx(s),o.height,z+t}end)
    part(4,12,9,2,function(s,t)return{xx(s),o.height-c.tableRim*(t-12)/2,z+12}end)
    part(0,14,16,2,function(s,t)return{xx(s),(o.height-c.tableRim)*(16-t)/2,z+12}end)
   elseif o.kind=='displayCounter'then
    band(12,40,function(s,t)return{x+s,o.height,z+t}end,function(s,t)return t<25 or s<16 or s>=32 end)
    band(40,48,function(s,t)return{x+s,o.height*(48-t)/8,z+40}end,function(s)return s<16 or s>=32 end)
    band(25,32,function(s,t)return{x+s,o.height*(32-t)/7,z+25}end,function(s)return s>=16 and s<32 end)
    for _,edge in ipairs{0,16,32,48}do local start=(edge==0 or edge==48)and 14 or 25
     for t=start,39 do local m,u,v=src(edge==48 and 47 or edge,t)
      G.quad(out,{x+edge,o.height,z+t},{x+edge,o.height,z+t+1},{x+edge,0,z+t+1},{x+edge,0,z+t},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)
     end
    end
   end
  end
  local kind=o.kind=='displayPlant'and 'plant'or o.kind=='displayChair'and 'chair'or o.kind=='displayTable'and 'table'or o.kind
  V.require('RoomLightRig').capture(L,{kind=kind},out,first,#out)
  if o.kind~='displayWall'then contacts[#contacts+1]={x+w/2,z+(o.front or o.last or h),w*.4,c.contactRadius,c.contactStrength}end
 end
end
return R
