-- Trick House living rooms only. Puzzle tiles/events remain engine-owned.
local V=...
local T={}
function T.profile(d)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 local id=d.id or d.name
 if not(cfg.enabled and cfg.trickHouse.enabled and d.mapType==8 and L
  and d.pair=='building__generic_building'and L.width==12 and L.height==8)then return end
 if id=='EM_ROUTE110_TRICK_HOUSE_ENTRANCE'and L:midAt(5,3)==0x24e
  or id=='EM_ROUTE110_TRICK_HOUSE_END'and L:midAt(5,4)==0x24e then
  return cfg.homeRooms.trickHome
 end
end
function T.lighting(d)
 if not T.profile(d)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.trickHouse.lighting
 local z=(d.id or d.name)=='EM_ROUTE110_TRICK_HOUSE_END'and 88 or 72
 local sources={{at={96,c.height,z},radius=c.radius,power=c.power,nightPower=c.nightPower,color=c.color,spread=c.spread,cone=-.1}}
 for x=0,11 do if d.midLayout:midAt(x,0)==0x217 then
  sources[#sources+1]={at={x*16+8,c.windowHeight,33},radius=c.windowRadius,power=c.windowPower,nightPower=c.windowNightPower,
   color=c.windowColor,spread=c.windowSpread,direction={0,-.35,1},cone=.15}
 end end
 return{ambient=c.ambient,night=c.night,sources=sources}
end
function T.plan(d)
 local p=T.profile(d);if not p then return end
 local c=V.require('DioramaConfig').emeraldInteriors.trickHouse
 local objects,mask=V.require('EmeraldGuestSurfaces').plan(d,p)
 local L=d.midLayout
 for _,o in ipairs(objects)do
  if o.kind=='wall'then o.wallHeight=c.wallHeight end
  -- The columns meet the rear wall, rather than floating a tile in front.
  if o.kind=='card'and o.opaque then o.front=32.25;o.height=c.pillarHeight end
 end
 for y=2,L.height-2 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if(m==0x319 and L:midAt(x,y+1)==0x327)or(m==0x31a and L:midAt(x,y+1)==0x322)then
   objects[#objects+1]={kind='trickPlant',x=x,y=y,w=16,h=32,cap=0,last=32,front=32,height=c.plantHeight,
    background={{mid=p.floor},{mid=p.edgeFloor}},positionMask=false}
   for yy=y,y+1 do mask[yy*L.width+x+1]=x==0 and p.edgeFloor or p.floor end
  end
 end end
 return objects,mask
end
-- Measured native outline, not a palette key: leaves share the tatami greens.
local spans={{7,9},{6,10},{3,13},{3,13},{2,14},{1,15},{0,16},{0,16},
 {1,15},{0,16},{0,16},{1,15},{2,14},{2,14},{5,11},{7,9},{6,10},
 {6,10},{4,12},{3,13},{2,14},{2,14},{2,14},{2,14},{2,14},{2,14},
 {2,14},{2,14},{2,14},{3,13},{4,12}}
function T.plantInside(s,t)local r=spans[t];return r and s>=r[1]and s<r[2]end
function T.build(out,L,ts,o,x,z)
 local cfg=V.require('DioramaConfig').emeraldInteriors
 local vv=V.require('PaperSprite').build(ts,16,32,function(s,t)
  return L:midAt(o.x,o.y+math.floor(t/16)),s,t%16
 end,T.plantInside,0,32,1,nil,function(s,t)
  return{x+s,cfg.trickHouse.plantHeight*(32-t)/32*cfg.heightScale,z+32}
 end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
end
return T
