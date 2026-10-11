-- FireRed mapping onto the measured shared Gen3 cable-room surfaces.
-- Native palette/layout ownership stays distinct from Emerald and multiplayer.
local V=...;local R={}
local rooms={
 FR_BATTLE_COLOSSEUM_2P={w=14,h=10,left=8,right=216,top=8,anchor=0x2e8,style='colosseum'},
 FR_BATTLE_COLOSSEUM_4P={w=14,h=10,left=8,right=216,top=8,anchor=0x2e8,style='colosseum'},
 FR_RECORD_CORNER={w=20,h=10,left=56,right=264,top=0,anchor=0x281,style='record'},
 FR_TRADE_CENTER={w=12,h=10,left=8,right=184,top=8,anchor=0x2b0,style='trade'},
 FR_UNION_ROOM={w=16,h=12,left=0,right=240,top=0,anchor=0x2c8,style='union'},
 FR_UNION_ROOM_PLAZA={w=25,h=25,left=0,right=400,top=0,anchor=0x2c8,style='plaza'}}
local function cfg()return V.require('DioramaConfig').interiors.fireredCableRooms end
function R.profile(d)
 local p=d and rooms[d.id];local L=d and d.midLayout
 if cfg().enabled and p and L and d.mapType==8 and L.width==p.w and L.height==p.h and L:midAt(0,0)==p.anchor
  and (d.renderPair or d.pair)==((p.style=='union'or p.style=='plaza')and 'building__rom_082d50dc'or 'building__rom_082d4c44')then return p end
end
function R.plan(d)
 local p=R.profile(d);if not p then return end;local c=cfg();local obj,mask={},{};local void=(p.style=='union'or p.style=='plaza')and 8 or 0x281
 for i=1,p.w*p.h do mask[i]={mid=void,void=true,separateSurface=true}end
 local function add(kind,x,y,w,h,data)
  local o=data or{};o.kind=kind;o.x=x/16;o.y=y/16;o.w=w;o.h=h;o.room=p;o.noContact=true
  o.presentation={config=c,heightScale=c.heightScale,paletteShift=0x80,voidMid=void};obj[#obj+1]=o
 end
 add('cableFloor',0,0,p.w*16,p.h*16);add('cableWall',0,0,p.w*16,48)
 if p.style=='trade'then
  add('cableTrade',76,64,40,40);add('cableChair',64,80,16,24,{right=false});add('cableChair',112,80,16,24,{right=true})
 elseif p.style=='record'then
  add('cableConsole',128,64,64,48);add('cableScreen',174,86,18,17)
  for _,x in ipairs{112,192}do for _,y in ipairs{48,80}do add('cableTerminal',x,y,16,32)end end
 end
 return{objects=obj,mask=mask}
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local shared=V.require('EmeraldCableRooms');local G=V.require('WorldGeometry');local c=cfg()
 for _,o in ipairs(objects)do local first=#out+1;local x,z=(o.x+ox)*16,(o.y+oz)*16
  shared.build(out,L,ts,o,x,z,contacts)
  if o.kind=='cableWall'then
   local p=o.room;local h=c.wallHeight*c.heightScale
   local function off(s)return math.max(0,(p.left+15-s)/2,(s-(p.right-16))/2)end
   for s=p.left,p.right-1 do
    local y=p.top+math.floor(off(s));local m=L:midAt(math.floor(s/16),math.floor(y/16));local uv=G.uv(ts,m,s%16,y%16,s%16+1,y%16+1,.5)
    local a,b=p.top+32+off(s)+z,p.top+32+off(s+1)+z
    G.quad(out,{x+s,h,a-c.wallDepth},{x+s+1,h,b-c.wallDepth},{x+s+1,h,b},{x+s,h,a},uv)
   end
  end
  V.require('RoomLightRig').capture(L,o,out,first,#out,x,z)
 end
end
function R.lighting(d)
 local p=R.profile(d);if not p then return end;local c=cfg();local locations=c.lights[p.style];local sources={}
 for _,a in ipairs(locations)do sources[#sources+1]={at={a[1],c.lightHeight,a[2]},radius=p.style=='plaza'and c.plazaRadius or c.lightRadius,power=c.lightPower,color=c.lightColor,spread=c.lightSpread,cone=-.1}end
 return{fixed=true,localSelection=true,ambient=c.ambient,sources=sources}
end
return R
