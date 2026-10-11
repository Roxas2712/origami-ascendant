-- Native memorial furniture only. The tower's haunting, scripts, floor layout
-- and encounter rules remain engine-owned; shell/stairs are a separate pass.
local V=...;local R={}
local donors={[0x289]=0x282,[0x291]=0x282,[0x293]=0x285,[0x2d8]=0x284,[0x2d9]=0x292,[0x2dc]=0x285,[0x2dd]=0x292,[0x2e3]=0x282,[0x2e4]=0x282}
local inset={5,4,3,2,2,2,2,1,0,0,0,0,0,0,0,1}
local function cfg()return V.require('DioramaConfig').interiors.pokemonTowerFurniture end
function R.profile(d)
 local L=d and d.midLayout;local floor=d and tonumber((d.id or''):match('^FR_POKEMON_TOWER_([1-7])F$'))
 return cfg().enabled and floor and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4efc'and L and L.width==24 and L.height==20 and L:midAt(9,0)==0x298 and floor or nil
end
function R.plan(d)
 local floor=R.profile(d);if not floor then return end
 local L=d.midLayout;local objects,mask={},{}
 local shell=V.require('PokemonTowerShell').plan(d)
 local function add(kind,x,y,w,h,donor)
  objects[#objects+1]={kind=kind,x=x,y=y,w=w,h=h,donor=donor}
  for z=y,y+h/16-1 do for s=x,x+w/16-1 do mask[z*L.width+s+1]={mid=donor,void=true,separateSurface=true}end end
 end
 for y=0,19 do for x=0,23 do local m=L:midAt(x,y)
  if donors[m]then add('towerMemorial',x,y,16,16,donors[m]);if shell and (m==0x2e3 or m==0x2e4)then objects[#objects].sourceMid=0x291 end
  elseif shell and (m==0x2bf or m==0x2be or m==0x2d6 or m==0x2da)then
   add('towerMemorial',x,y,16,16,m==0x2be and 0x285 or 0x282);objects[#objects].sourceMid=0x291
  end
 end end
 if floor==1 and L:midAt(15,11)==0x2c9 and L:midAt(15,16)==0x2d0 then add('towerReception',15,11,96,96,0x282)end
 if floor==7 then for _,x in ipairs{9,13}do
  if L:midAt(x,3)==0x2cf and L:midAt(x,4)==0x2d7 then add('towerStatue',x,2,16,64,0x282)end
 end end
 return{objects=objects,mask=mask}
end
function R.inside(L,ts,o,s,t)
 if s<0 or s>=o.w or t<0 or t>=o.h then return false end
 if o.kind=='towerMemorial'then local a=inset[t+1];return s>=a and s<16-a end
 local x,z=o.x*16+s,o.y*16+t
 local r,g,b=V.require('BuildingMesh').pixel(ts,L:midAt(math.floor(x/16),math.floor(z/16)),s%16,t%16)
 -- Every floor/shadow color in this measured atlas is green with R==B.
 -- Body greys and pale green statue highlights have a different palette.
 return r+g+b>0 and not(g>r and r==b)
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local G,P,B=V.require('WorldGeometry'),V.require('PaperSprite'),V.require('BuildingMesh');local hs=V.require('Billboard').heightScale()
 for _,o in ipairs(objects)do if o.kind=='towerMemorial'or o.kind=='towerReception'or o.kind=='towerStatue'then
  local x,z=(o.x+ox)*16,(o.y+oz)*16
  local function src(s,t)return o.sourceMid or L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local function inside(s,t)return R.inside(L,ts,o,s,t)end
  local function draw(source,mask,project,shade)
   local vv=P.build(ts,o.w,o.h,source,mask,0,o.h,1,shade and function()return shade end or nil,project,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
  end
  -- Preserve the exact native background outside the object silhouette.
  -- Under the body use the corresponding plain / wall-shadow floor variant.
  draw(function(s,t)
   if o.sourceMid or inside(s,t)then
    if o.kind=='towerStatue'and t<16 then return 0x284,s%16,t%16 end
    return o.donor,s%16,t%16
   end
   return src(s,t)
  end,function(s,t)local r,g,b=B.pixel(ts,src(s,t));return r+g+b>0 end,function(s,t)return{x+s,0,z+t}end)
  local counter=o.kind=='towerReception';local statue=o.kind=='towerStatue'
  local height=(counter and c.counterHeight or statue and c.statueHeight or c.memorialHeight)*hs
  local base=statue and 48 or o.h;local top=statue and 8 or 0
  local depth=statue and c.statueDepth or c.memorialDepth
  local function point(s,t,d,left)
   if counter then
    local arm=left==nil and s<16 or left;local split=arm and 89 or 25;local front=arm and 96 or 32
    if t>=split then return{x+s,height*(front-t)/(front-split),z+front}end
    return{x+s,height-d,z+(t<=25 and 12+(t-12)*20/13 or t+7)}
   end
   return{x+s,height*(base-t)/(base-top),z+base-d}
  end
  if counter then
   for _,part in ipairs{{0,16,true},{16,80,false}}do
    local vv=P.build(ts,part[2],o.h,function(s,t)return src(s+part[1],t)end,function(s,t)return inside(s+part[1],t)end,0,o.h,1,nil,function(s,t)return point(s+part[1],t,0,part[3])end,.5)
    for _,v in ipairs(vv)do out[#out+1]=v end
   end
  else draw(src,inside,function(s,t)return point(s,t,0)end)end
  -- Closed native silhouettes: real top/side faces, no rectangular cards.
  for t=0,o.h-1 do for s=0,o.w-1 do if inside(s,t)then
   local m,u,v=src(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
   for _,e in ipairs{{-1,0,s,t,s,t+1},{1,0,s+1,t+1,s+1,t},{0,-1,s+1,t,s,t},{0,1,s,t+1,s+1,t+1}}do
    if not inside(s+e[1],t+e[2])then
     if counter and t<(s<16 and 89 or 25)then
      -- The original seven-row grey fascia folds down the front; side
      -- closures reuse that course rather than stretching its bottom pixels.
      local a,b=point(e[3],e[4],0,s<16),point(e[5],e[6],0,s<16)
      for row=0,6 do
       local edgeUV=G.uv(ts,0x2d2,8,9+row,9,10+row,.5)
       G.quad(out,{a[1],height*(7-row)/7,a[3]},{b[1],height*(7-row)/7,b[3]},{b[1],height*(6-row)/7,b[3]},{a[1],height*(6-row)/7,a[3]},edgeUV,c.sideShade)
      end
     elseif not counter then
     G.quad(out,point(e[3],e[4],0),point(e[5],e[6],0),point(e[5],e[6],counter and height or depth),point(e[3],e[4],counter and height or depth),uv,c.sideShade)
     end
    end
   end
  end end end
  if counter then
   contacts[#contacts+1]={x+55,z+32,40,c.contactRadius,c.contactStrength}
   contacts[#contacts+1]={x+8,z+65,6,28,c.contactStrength}
  else contacts[#contacts+1]={x+o.w/2,z+base,o.w*.40,c.contactRadius,c.contactStrength}end
 end end
end
return R
