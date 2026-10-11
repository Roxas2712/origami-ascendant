-- Exact native FireRed gym surfaces. Visual geometry only; the engine keeps
-- ownership of collisions, battles, tile animation, events and movement.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.fireredGyms end
function R.profile(d)
 local L=d and d.midLayout
 if not cfg().enabled or not L or d.mapType~=8 then return end
 -- Select by native identity before loading a gym's geometry module. The
 -- selected module still validates live dimensions, tiles and configuration.
 if d.id=='FR_VIRIDIAN_CITY_GYM'and V.require('FireRedEarthGym').profile(d)then return 'earth'end
 if d.id=='FR_CINNABAR_ISLAND_GYM'and V.require('FireRedFireGym').profile(d)then return 'fire'end
 if d.id=='FR_SAFFRON_CITY_GYM'and V.require('FireRedPsychicGym').profile(d)then return 'psychic'end
 if d.id=='FR_FUCHSIA_CITY_GYM'and V.require('FireRedPoisonGym').profile(d)then return 'poison'end
 if d.id=='FR_CELADON_CITY_GYM'and V.require('FireRedGardenGym').profile(d)then return 'garden'end
 if d.id=='FR_VERMILION_CITY_GYM'and V.require('FireRedElectricGym').profile(d)then return 'electric'end
 if d.id=='FR_PEWTER_CITY_GYM'and (d.renderPair or d.pair)=='pewter_gym'and L.width==14 and L.height==16 and L:midAt(0,0)==0x280 and L:midAt(6,5)==0x2ad then return 'rock'end
 if d.id=='FR_CERULEAN_CITY_GYM'and (d.renderPair or d.pair)=='building__rom_082d4d1c'and L.width==18 and L.height==20 and L:midAt(0,0)==0x2a6 and L:midAt(8,5)==0x2d3 then return 'water'end
end
function R.plan(d)
 local L=d and d.midLayout;if L then R.rooms[L]=nil end
 local family=R.profile(d);if not family then return end
 if family=='earth'then R.rooms[L]={family=family};return V.require('FireRedEarthGym').plan(d)end
 if family=='fire'then R.rooms[L]={family=family};return V.require('FireRedFireGym').plan(d)end
 if family=='psychic'then R.rooms[L]={family=family};return V.require('FireRedPsychicGym').plan(d)end
 if family=='poison'then R.rooms[L]={family=family};return V.require('FireRedPoisonGym').plan(d)end
 if family=='garden'then R.rooms[L]={family=family};return V.require('FireRedGardenGym').plan(d)end
 if family=='electric'then R.rooms[L]={family=family};return V.require('FireRedElectricGym').plan(d)end
 local own,mask={},{};R.rooms[L]={family=family,objects=own}
 for i=1,L.width*L.height do mask[i]={mid=8,void=true,separateSurface=true}end
 local function add(kind,x,y,w,h,p)p=p or{};p.kind=kind;p.x=x;p.y=y;p.w=w;p.h=h;own[#own+1]=p end
 if family=='water'then
  add('gymWall',8,0,256,48);add('gymPoolFloor',0,48,272,272)
  for _,x in ipairs{8,256}do add('gymSideWall',x,48,8,256)end
  for _,x in ipairs{48,208}do for _,y in ipairs{64,272}do add('gymLadder',x,y,16,32)end end
  for _,x in ipairs{96,160}do add('gymStatue',x,256,16,32)end
  add('gymStartingBlock',128,80,16,48)
  return{objects=own,mask=mask,owners={}}
 end
 add('gymWall',8,0,192,48);add('gymFloor',0,48,208,208)
 for _,x in ipairs{8,192}do add('gymSideWall',x,48,8,192)end
 local donor={[0x29b]=0x29c,[0x2a2]=0x293,[0x2a3]=0x294,[0x2a4]=0x2a5}
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if donor[m]then add('gymRock',x*16,y*16,16,16,{donor=donor[m]})end
 end end
 for _,x in ipairs{64,128}do add('gymStatue',x,176,16,32)end
 add('gymPlinth',80,80,48,24)
 return{objects=own,mask=mask,owners={}}
end
local rockRuns={[2]={5,11},[3]={3,13},[4]={2,14},[5]={2,14},[6]={1,15},[7]={1,15},[8]={1,15},[9]={1,15},[10]={1,15},[11]={2,15},[12]={2,15},[13]={4,14},[14]={9,13}}
local plinthRuns={{16,32},{14,34},{12,36},{11,37},{10,38},{9,39},{9,39},{9,39},{8,40},{8,40},{8,40},{8,40},{8,40},{8,40},{8,40},{8,40},{8,40},{9,39},{9,39},{9,39},{10,38},{11,37},{12,35},{16,33}}
function R.inside(o,s,t)
 if s<0 or s>=o.w or t<0 or t>=o.h then return false end
 local a
 if o.kind=='gymStartingBlock'then return t>=13 and t<40
 elseif o.kind=='gymLadder'then
  if t<8 or t>=26 then return false end
  if t==8 then return s>=1 and s<3 or s>=13 and s<15 end
  if t>=19 and t<23 then return true end
  if t==25 then return s>=1 and s<3 or s>=13 and s<15 end
  return s<4 or s>=12
 elseif o.kind=='gymRock'then a=rockRuns[t]
 elseif o.kind=='gymPlinth'then a=plinthRuns[t+1]
 elseif o.kind=='gymStatue'then
  if t==0 then return s>=3 and s<5 or s>=6 and s<10 or s>=11 and s<13 elseif t==1 then a={2,13}elseif t<5 then a={3,13}elseif t==5 then a={2,14}elseif t==6 or t==30 then a={1,15}elseif t==31 then a={1,14}else a={0,16}end
 end
 return a and s>=a[1]and s<a[2]or false
end
function R.actorOffset(d,x,z)
 local family=R.profile(d);if not family then return end
 if family=='poison'then return V.require('FireRedPoisonGym').actorOffset(d,x,z)end
 if family=='earth'or family=='fire'or family=='psychic'or family=='electric'or family=='garden'then return end
 if family=='water'then
  if x+8>=128 and x+8<144 and z+16>=93 and z+16<=112 then return cfg().startingBlockHeight,0 end
  local state=R.rooms[d.midLayout];local wet=state and state.wet
  if wet and wet[math.floor(z+16)*288+math.floor(x+8)]then return -cfg().poolDepth,0 end
  return
 end
 if R.inside({kind='gymPlinth',w=48,h=24},math.floor(x+8-80),math.floor(z+16-80))then return cfg().plinthHeight,0 end
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local state=R.rooms[L];if not state then return end
 if state.family=='earth'then return V.require('FireRedEarthGym').build(out,objects,L,ts,ox,oz,contacts)end
 if state.family=='fire'then return V.require('FireRedFireGym').build(out,objects,L,ts,ox,oz,contacts)end
 if state.family=='psychic'then return V.require('FireRedPsychicGym').build(out,objects,L,ts,ox,oz,contacts)end
 if state.family=='poison'then return V.require('FireRedPoisonGym').build(out,objects,L,ts,ox,oz,contacts)end
 if state.family=='garden'then return V.require('FireRedGardenGym').build(out,objects,L,ts,ox,oz,contacts)end
 if state.family=='electric'then return V.require('FireRedElectricGym').build(out,objects,L,ts,ox,oz,contacts)end
 local c=cfg();local G,P,B=V.require('WorldGeometry'),V.require('PaperSprite'),V.require('BuildingMesh');local hs=V.require('Billboard').heightScale()
 local function src(x,y)return L:midAt(math.floor(x/16),math.floor(y/16)),x%16,y%16 end
 local function draw(w,h,source,inside,project,shade)
  local vv=P.build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 local clear={}
 for _,o in ipairs(objects)do if o.kind=='gymRock'or o.kind=='gymStatue'or o.kind=='gymPlinth'or o.kind=='gymLadder'or o.kind=='gymStartingBlock'then
  for t=0,o.h-1 do for s=0,o.w-1 do if (o.kind~='gymPlinth'and o.kind~='gymStartingBlock')or R.inside(o,s,t)then clear[(o.y+t)*L.width*16+o.x+s]=o end end end
 end end
 for _,o in ipairs(objects)do local first=#out+1
  local function source(s,t)return src(o.x+s,o.y+t)end
  if o.kind=='gymFloor'then
   draw(o.w,o.h,function(s,t)local x,z=o.x+s,o.y+t;local p=clear[z*L.width*16+x]
    if z>=208 and z<224 and(x>=64 and x<96 or x>=128 and x<160)then return 0x2aa,x%16,z%16 end
    if p then
     if p.kind=='gymPlinth'then return 0x2a5,8,z%16 end
     if p.kind=='gymStatue'then return z<192 and 0x294 or 0x2aa,x%16,z%16 end
     return p.donor,x%16,z%16
    end
    return src(x,z)
   end,function(s,t)return not(t<192 and(s>=8 and s<16 or s>=192 and s<200))end,function(s,t)return{o.x+s,0,o.y+t}end)
  elseif o.kind=='gymPoolFloor'then
   local function floorSource(x,z)
    local p=clear[z*288+x]
    if p then
     if p.kind=='gymStatue'then
      -- These statues overlay the two rounded corners of the entry deck.
      -- Restore the deck underneath them, never a rectangular water hole.
      if z<272 then local u=p.x==96 and x%16 or 15-x%16;local t=z%16
       if t<3 or u<2 then return 0x2a1,u,t end
       return 0x2b9,8,t
      end
      return 0x2c1,8,z%16
     end
     if p.kind=='gymStartingBlock'then if z<96 then return 0x291,x%16,z%16 end;return 0x2b2,8,8 end
     if p.kind=='gymLadder'then
      local mid=z<80 and 0x281 or z<96 and 0x289 or z<288 and 0x299 or 0x281
      return mid,x%16,z%16
     end
    end
    return src(x,z)
   end
   local wet={};state.wet=wet
   local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
   local waterColors={};for _,m in ipairs{0x291,0x293}do for t=0,15 do for x=0,15 do waterColors[key(B.pixel(ts,m,x,t))]=true end end end
   for z=48,303 do for x=16,255 do wet[z*288+x]=waterColors[key(B.pixel(ts,floorSource(x,z)))]or nil end end
   -- Native fastening bolts are drawn below the bridge edge in the ROM.
   -- Fold those texels onto the vertical face instead of extruding floating
   -- islands beside the bridge. The cream deck, unlike the bolts, stays flat.
   local bolts={};local cream=key(B.pixel(ts,0x2b2,8,8))
   local boltColors={[0x63637b]=true,[0xadced6]=true,[0x948c84]=true,[0xcedee6]=true}
   for x=32,239 do local lastCream
    for z=80,287 do local rgb=key(B.pixel(ts,floorSource(x,z)))
     if rgb==cream then lastCream=z
     elseif lastCream and z-lastCream>=2 and z-lastCream<=6 and boltColors[rgb]then bolts[z*288+x]=lastCream+2 end
    end
   end
   for k in pairs(bolts)do wet[k]=true end
   local function inFloor(x,z)return z>=48 and z<320 and x>=0 and x<272 and not(z<304 and(x>=8 and x<16 or x>=256 and x<264))end
   draw(o.w,o.h,function(s,t)return floorSource(s,t+48)end,function(s,t)return inFloor(s,t+48)and not wet[(t+48)*288+s]end,function(s,t)return{s,0,t+48}end)
   draw(o.w,o.h,function(s,t)if bolts[(t+48)*288+s]then return 0x293,0,0 end;return floorSource(s,t+48)end,function(s,t)return wet[(t+48)*288+s]end,function(s,t)return{s,-c.poolDepth,t+48}end,G.WATER)
   -- Vertical faces follow the pixel contour of each native bridge and bank.
   -- Keeping the walking surface at zero preserves all actor/tile positions.
   for z=48,303 do for x=16,255 do if not wet[z*288+x]then
    for _,a in ipairs{{-1,0,0,0,0,1},{1,0,1,0,1,1},{0,-1,0,0,1,0},{0,1,0,1,1,1}}do
     if wet[(z+a[2])*288+x+a[1]]then
      local m,u,v=floorSource(x,z);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local xx,zz=x+ox*16,z+oz*16
      G.quad(out,{xx+a[3],0,zz+a[4]},{xx+a[5],0,zz+a[6]},{xx+a[5],-c.poolDepth,zz+a[6]},{xx+a[3],-c.poolDepth,zz+a[4]},uv,c.poolSideShade)
     end
    end
   end end end
   -- Each bolt column has one fixed bridge-edge anchor, also at its bottom
   -- vertex, so pixel rows cannot accidentally bend back onto the water.
   for x=32,239 do local z=80
    while z<288 do local edge=bolts[z*288+x]
     if edge then local first=z;repeat z=z+1 until z>=288 or bolts[z*288+x]~=edge
      draw(1,z-first,function(_,t)return floorSource(x,first+t)end,nil,function(s,t)return{x+s,-(first+t-edge)*c.poolDepth/5,edge+.02}end)
     else z=z+1 end
    end
   end
  elseif o.kind=='gymWall'then
   local height=c.wallHeight*hs
   draw(o.w,o.h,source,nil,function(s,t)return{o.x+s,height*(o.h-t)/o.h,48}end)
   draw(o.w,c.wallDepth,function(s)return source(s,0)end,nil,function(s,t)return{o.x+s,height,48-c.wallDepth+t}end)
   for _,edge in ipairs{0,o.w}do draw(c.wallDepth,o.h,function(_,t)return source(math.min(o.w-1,edge),t)end,nil,function(s,t)return{o.x+edge,height*(o.h-t)/o.h,48-c.wallDepth+s}end,c.sideShade)end
  elseif o.kind=='gymSideWall'then
   draw(o.w,o.h,source,nil,function(s,t)return{o.x+s,c.cutawayHeight,o.y+t}end)
   for _,edge in ipairs{0,8}do draw(o.h,c.cutawayHeight,function(s)return source(math.min(7,edge),s)end,nil,function(s,t)return{o.x+edge,c.cutawayHeight-t,o.y+s}end,c.sideShade)end
   draw(8,c.cutawayHeight,function(s)return source(s,o.h-1)end,nil,function(s,t)return{o.x+s,c.cutawayHeight-t,o.y+o.h}end,c.sideShade)
  elseif o.kind=='gymStartingBlock'then
   draw(o.w,o.h,source,function(s,t)return t>=13 and t<32 end,function(s,t)return{o.x+s,c.startingBlockHeight,o.y+t}end)
   draw(o.w,o.h,source,function(s,t)return t>=32 and t<40 end,function(s,t)return{o.x+s,c.startingBlockHeight*(40-t)/8,o.y+32}end)
   for _,edge in ipairs{0,16}do draw(19,c.startingBlockHeight,function(s)return source(math.min(15,edge),13+s)end,nil,function(s,t)return{o.x+edge,c.startingBlockHeight-t,o.y+13+s}end,c.sideShade)end
  elseif o.kind=='gymLadder'then
   local rear=o.y<100;local edge=o.y+(rear and 22 or 15)
   draw(o.w,o.h,source,function(s,t)return t<19 and R.inside(o,s,t)end,function(s,t)return{o.x+s,(19-t)*c.ladderHeight/11,edge}end)
   draw(o.w,o.h,source,function(s,t)return t>=19 and R.inside(o,s,t)end,function(s,t)return{o.x+s,-(t-19)*c.poolDepth/7,edge+(rear and .03 or -.03)}end)
  elseif o.kind=='gymPlinth'then
   draw(o.w,o.h,source,function(s,t)return R.inside(o,s,t)end,function(s,t)return{o.x+s,c.plinthHeight,o.y+t}end)
   for t=0,o.h-1 do for s=0,o.w-1 do if R.inside(o,s,t)then
    local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
    for _,a in ipairs{{-1,0,0,0,0,1},{1,0,1,0,1,1},{0,-1,0,0,1,0},{0,1,0,1,1,1}}do if not R.inside(o,s+a[1],t+a[2])then
     local x,z=o.x+s+ox*16,o.y+t+oz*16
     G.quad(out,{x+a[3],c.plinthHeight,z+a[4]},{x+a[5],c.plinthHeight,z+a[6]},{x+a[5],0,z+a[6]},{x+a[3],0,z+a[4]},uv,c.sideShade)
    end end
   end end end
   contacts[#contacts+1]={o.x+24+ox*16,o.y+18+oz*16,17,5,c.contactStrength}
  else
   local statue=o.kind=='gymStatue';local last=statue and 32 or 15;local cap=statue and 0 or 2
   local height=(statue and c.statueHeight or c.rockHeight)*hs;local front=o.y+last
   draw(o.w,o.h,source,function(s,t)return R.inside(o,s,t)end,function(s,t)return{o.x+s,(last-t)*height/(last-cap),front}end)
   contacts[#contacts+1]={o.x+8+ox*16,front+oz*16,statue and 7 or 6,c.contactRadius,c.contactStrength}
  end
  V.require('RoomLightRig').capture(L,{kind=(o.kind=='gymFloor'or o.kind=='gymPoolFloor')and 'card'or(o.kind=='gymRock'or o.kind=='gymStatue'or o.kind=='gymLadder')and 'plant'or o.kind},out,first,#out)
 end
end
function R.lighting(d)
 local family=R.profile(d);if not family then return end
 if family=='earth'then return V.require('FireRedEarthGym').lighting(d)end
 if family=='fire'then return V.require('FireRedFireGym').lighting(d)end
 if family=='psychic'then return V.require('FireRedPsychicGym').lighting(d)end
 if family=='poison'then return V.require('FireRedPoisonGym').lighting(d)end
 if family=='garden'then return V.require('FireRedGardenGym').lighting(d)end
 if family=='electric'then return V.require('FireRedElectricGym').lighting(d)end
 local c=cfg();local p=c.lights[family];local sources={}
 for _,a in ipairs(p.sources)do sources[#sources+1]={at={a[1],c.lightHeight,a[2]},power=a[3],radius=a[4],color=p.color,spread=c.lightSpread}end
 return{fixed=true,ambient=p.ambient,sources=sources}
end
return R
