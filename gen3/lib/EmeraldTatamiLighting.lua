-- Fixed sources in seven measured native tatami homes; no invented windows.
local V=...;local H={cache=setmetatable({},{__mode='k'})}
local rooms={
 EM_DEWFORD_TOWN_HOUSE1={width=10,height=8,rows='2e3 2be 2bf 217 215 216 2a6 2a7 215 2e4 2eb 2c6 2c7 21f 21d 21e 2ae 2af 2a1 2ec 2f3 2ce 2cf 221 221 240 2b6 2b7 2a9 2f4',windows={3},tables={{4,3}}},
 EM_DEWFORD_TOWN_HOUSE2={width=10,height=10,rows='2e3 2be 2bf 215 217 217 215 215 215 2e4 2eb 2c6 2c7 21d 21f 21f 21d 21d 2a0 2ec 2f3 2ce 2cf 2b3 2b3 221 221 221 2a8 2f4',windows={4,5},tables={{7,4,0x25f}}},
 EM_LAVARIDGE_TOWN_HOUSE={width=10,height=8,rows='2e3 2be 2bf 217 215 216 2a6 2a7 215 2e4 2eb 2c6 2c7 21f 21d 21e 2ae 2af 2a1 2ec 2f3 2ce 2cf 221 221 240 2b6 2b7 2a9 2f4',windows={3},tables={{4,3}}},
 EM_LILYCOVE_CITY_HOUSE2={width=8,height=8,rows='2e3 2b1 2b2 217 217 2be 2bf 2e4 2eb 2b9 2ba 21f 21f 2c6 2c7 2ec 2f3 2c1 2c2 221 221 2ce 2cf 2f4',windows={3,4},tables={{1,3}}},
 EM_ROUTE104_MR_BRINEYS_HOUSE={width=12,height=10,rows='2e3 2b1 2b2 215 2e3 217 217 2e4 215 2be 2bf 2e4 2eb 2b9 2ba 21d 2eb 21f 21f 2ec 2a0 2c6 2c7 2ec 2f3 2c1 2c2 221 2f3 221 221 2f4 2a8 2ce 2cf 2f4',windows={5,6},tables={{7,4}}},
 EM_ROUTE114_FOSSIL_MANIACS_HOUSE={width=10,height=8,rows='2b1 2b2 215 2ed 2ee 2ef 215 215 215 216 2b9 2ba 21d 2f5 2f6 2f7 21d 316 317 21e 2c1 2c2 221 2fd 2fe 306 307 2ae 2af 240',windows={},tables={{1,4}}},
 EM_ROUTE116_TUNNELERS_REST_HOUSE={width=10,height=10,rows='2e3 2b1 2b2 217 215 217 215 2be 2bf 2e4 2eb 2b9 2ba 21f 21d 21f 21d 2c6 2c7 2ec 2f3 2c1 2c2 221 221 221 221 2ce 2cf 2f4',windows={3,5},tables={{1,4},{7,4}}},
}
local function stamp(t)
 local keys={};for k in pairs(t)do keys[#keys+1]=k end;table.sort(keys)
 local out={};for _,k in ipairs(keys)do local v=t[k];out[#out+1]=k..'='..(type(v)=='table'and stamp(v)or tostring(v))end;return table.concat(out,';')
end
function H.profile(d)
 local room=d and rooms[d.id];if not room then return end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.tatamiLighting;local L=d.midLayout
 if not(all.enabled and c.enabled and d.mapType==8 and d.pair=='building__generic_building'and L and L.width==room.width and L.height==room.height)then return end
 local i=0;for m in room.rows:gmatch('%x+')do if L:midAt(i%L.width,math.floor(i/L.width))~=tonumber(m,16)then return end;i=i+1 end
 for _,t in ipairs(room.tables)do if L:midAt(t[1],t[2])~=0x24e or L:midAt(t[1]+1,t[2])~=(t[3]or 0x24f)then return end end
 local signature=d.id..stamp(c);local hit=H.cache[L];if hit and hit.signature==signature then return hit.profile end
 local sources,regions={},{}
 for _,x in ipairs(room.windows)do
  sources[#sources+1]={at={x*16+8,c.windowHeight,34},radius=c.windowRadius,power=c.windowPower/math.sqrt(#room.windows),nightPower=c.windowNightPower,color=c.windowColor,nightColor=c.windowNightColor,spread=c.windowSpread,direction={0,-.45,1},cone=.1}
  regions[#regions+1]={at={x,0},rect={0,0,16,32},palette=c.glassPalette}
 end
 for _,t in ipairs(room.tables)do
  sources[#sources+1]={at={(t[1]+1)*16,c.ceilingHeight,(t[2]+1)*16},radius=c.ceilingRadius,power=c.ceilingPower,nightPower=c.ceilingNightPower,color=c.ceilingColor,spread=c.ceilingSpread,direction={0,-1,0},cone=-.1}
 end
 if #room.windows==0 then
  sources[#sources+1]={at=c.rearPosition,radius=c.rearRadius,power=c.rearPower,nightPower=c.rearNightPower,color=c.ceilingColor,spread=c.ceilingSpread,direction={0,-1,0},cone=-.1}
 end
 local p={ambient=c.ambient,night=c.nightAmbient,sources=sources}
 if #regions>0 then p.emission={enabled=true,day=c.emissionDay,night=c.emissionNight,bloom=c.emissionBloom,regions=regions}end
 H.cache[L]={signature=signature,profile=p};return p
end
function H.capture(list,o,x,z)
 if not(o.tatamiHome and o.kind=='fold'and o.tatamiTable)then return false end
 local c=V.require('DioramaConfig').emeraldInteriors;local scale=c.heightScale
 local function box(a,b,back,front,low,high)list[#list+1]={lo={x+a,low*scale,z+back},hi={x+b,high*scale,z+front},wall=false}end
 box(0,o.w,o.front-o.depth,o.front,o.height-c.tatamiLighting.tableThickness,o.height)
 if o.tatamiGlass then box(16,22,o.front-12-.25,o.front-12+.25,o.height,o.height+8)end
 return true
end
return H
