-- Native Trainer Tower roof: deck, hanging facade, service block and flight.
local V=...;local R={}
function R.profile(d)
 local c=V.require('DioramaConfig').interiors.trainerTowerRoof;local L=d and d.midLayout
 if not(c.enabled and d and d.id=='FR_TRAINER_TOWER_ROOF'and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d5094'
  and L and L.width==18 and L.height==16 and L:midAt(6,5)==0x34a and L:midAt(13,5)==0x356)then return end
 for i,m in ipairs{0x360,0x361,0x362,0x363,0x364,0x365,0x366,0x367,0x35f}do
  if L:midAt(2+(i-1)%3,5+math.floor((i-1)/3))~=m then return end
 end
 return c
end
function R.plan(d)
 if not R.profile(d)then return end
 local mask={};for i=1,18*16 do mask[i]={mid=0,void=true,separateSurface=true}end
 return{objects={{kind='towerRoof',x=0,y=0}},mask=mask,owners={}}
end
function R.actorOffset(d,px,pz)
 local c=R.profile(d);if not c then return end
 local x,z=px+8-32,pz+16-80
 if x>=0 and x<48 and z>=16 and z<=48 then return-(8-math.min(7,math.floor(x/6)))*c.height/8,0 end
end
function R.doorPose(d,a)
 local c=R.profile(d);if c and a and a.x==13 and a.y==5 then return{height=c.hutHeight,base=0,top=0}end
end
function R.edge(s)return 176-math.max(0,48-s,s-240)end
local function seam(s)return s>=96 and s<192 and 80 or 64 end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=V.require('DioramaConfig').interiors.trainerTowerRoof;local G=V.require('WorldGeometry');local B=V.require('BuildingMesh')
 local function src(s,t)return L:midAt(math.floor(s/16),math.floor(t/16)),s%16,t%16 end
 local br,bg,bb=B.pixel(ts,0x31a,0,0)
 local function ink(s,t)local r,g,b,a=B.pixel(ts,src(s,t));return a>.5 and(math.abs(r-br)+math.abs(g-bg)+math.abs(b-bb)>.01)end
 local function draw(w,h,source,inside,point,shade)
  local vv=V.require('PaperSprite').build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,point,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 -- All native traversable deck cells stay at Y=0. Only drawing surfaces move.
 draw(288,176,src,function(s,t)
  return s>=8 and s<280 and t<R.edge(s)and not(s>=32 and s<256 and t<seam(s)+32)
   and not(s>=32 and s<80 and t>=96 and t<128)and ink(s,t)
 end,function(s,t)return{s,0,t}end)
 -- Each vertical strip starts at the exact same polygonal edge as the deck.
 local expanded=V.require('DioramaConfig').rooftopVista.enabled~=false
 for floor=0,(expanded and 3 or 0)do
  for s=8,279 do local edge=R.edge(s);local delta=R.edge(s+1)-edge
   local start=edge+(floor==0 and 0 or 16)
   local finish=expanded and math.min(256,edge+80)or 256
   local offset=floor==0 and 0 or 80+(floor-1)*64
   local t=start
   while t<finish do
    if ink(s,t)then
     local first=t;local m,u,v=src(s,t);local limit=math.min(finish,(math.floor(t/16)+1)*16)
     repeat t=t+1 until t>=limit or not ink(s,t)
     local a,b=-(first-start+offset)*c.facadeScale,-(t-start+offset)*c.facadeScale
     G.quad(out,{s+ox*16,a,edge+oz*16},{s+1+ox*16,a,edge+delta+oz*16},
      {s+1+ox*16,b,edge+delta+oz*16},{s+ox*16,b,edge+oz*16},
      G.uv(ts,m,u,v,u+1,v+t-first,.5),G.HANGING_FACADE)
    else t=t+1 end
   end
  end
 end
 -- Joined three-bay service enclosure. Central bay projects forward 16px.
 for _,a in ipairs{{32,96,64},{96,192,80},{192,256,64}}do
  local left,right,cut=a[1],a[2],a[3];local base=cut+32
  draw(right-left,cut,function(s,t)
   local x=left+s
   if (x>=96 and x<112 or x>=176 and x<192)and t>=56 then return 0x35b,s%16,t%16 end
   return src(x,t)
  end,nil,function(s,t)return{left+s,c.hutHeight,t*base/cut}end)
  draw(right-left,32,function(s,t)return src(left+s,cut+t)end,nil,
   function(s,t)return{left+s,c.hutHeight*(32-t)/32,base}end)
 end
 for _,x in ipairs{32,256}do
  draw(96,32,function(s,t)return src(128+s%16,80+t)end,nil,
   function(s,t)return{x,c.hutHeight*(32-t)/32,s}end,c.sideShade)
 end
 for _,x in ipairs{96,192}do
  draw(16,32,function(s,t)return src(128+s,80+t)end,nil,function(s,t)return{x,c.hutHeight*(32-t)/32,96+s}end,c.sideShade)
 end
 -- The original two finials sit on the raised roof, with no light rectangle.
 for _,x in ipairs{96,176}do
  draw(16,21,function(s,t)return src(x+s,56+t)end,function(s,t)
   local lo=t==0 and 7 or t<14 and 6 or(t==14 or t==20)and 5 or 4
   return s>=lo and s<16-lo
  end,function(s,t)return{x+s,c.hutHeight+c.postHeight*(21-t)/21,112}end)
 end
 V.require('SilphStairs').build(out,{{kind='silphStairs',x=2,y=5,left=true,down=true,stairConfig=c}},L,ts,ox,oz)
end
return R
