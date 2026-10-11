-- Source-scoped lighting for the two measured BPEE wooden home layouts.
local V=...;local H={cache=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').emeraldInteriors.homeLighting end
local rows={
 kitchenHome='286 287 230 205 205 206 205 205 205 205 278 001 28e 28f 21e 20d 20d 20e 20d 268 26c 26d 280 001 296 297 238 224 224 224 224 270 274 275 288 001',
 rugHome='286 287 279 27a 205 207 205 205 205 205 28e 28f 281 282 20d 20f 20d 20d 290 290 296 297 289 28a 224 224 224 224 298 298',
}
local function stamp(t)
 local keys={};for k in pairs(t)do keys[#keys+1]=k end;table.sort(keys)
 local a={};for _,k in ipairs(keys)do local v=t[k];a[#a+1]=k..'='..(type(v)=='table'and stamp(v)or tostring(v))end;return table.concat(a,';')
end
function H.profile(d)
 if not(d and d.pair=='building__generic_building'and(d.id or''):match('^EM_'))then return end
 local c=cfg();local L=d and d.midLayout;local family=d and V.data('Emerald').homeRooms[d.id]
 local source=rows[family]
 if not(c.enabled and V.require('DioramaConfig').emeraldInteriors.enabled and source and d.mapType==8 and d.pair=='building__generic_building'and L)then return end
 local kitchen=family=='kitchenHome';local width,height=kitchen and 12 or 10,kitchen and 8 or 10
 if L.width~=width or L.height~=height then return end
 local i=0;for m in source:gmatch('%x+')do if L:midAt(i%width,math.floor(i/width))~=tonumber(m,16)then return end;i=i+1 end
 local tx=kitchen and 5 or 2
 if L:midAt(tx,4)~=(kitchen and 0x24a or 0x248)or L:midAt(tx+1,4)~=(kitchen and 0x24b or 0x249)then return end
 local signature=family..stamp(c);local hit=H.cache[L];if hit and hit.signature==signature then return hit.profile end
 local sources={
  {at={88,c.windowHeight,34},radius=c.windowRadius,power=c.windowPower,nightPower=c.windowNightPower,color=c.windowColor,nightColor=c.windowNightColor,spread=c.windowSpread,direction={-.15,-.45,1},cone=.1},
  {at={(tx+1)*16,c.ceilingHeight,88},radius=c.ceilingRadius,power=c.ceilingPower,nightPower=c.ceilingNightPower,color=c.ceilingColor,spread=c.ceilingSpread,direction={0,-1,0},cone=-.1},
 }
 if kitchen then sources[#sources+1]={at={144,c.workHeight,48},radius=c.workRadius,power=c.workPower,nightPower=c.workNightPower,color=c.ceilingColor,spread={12,6},direction={0,-1,0},cone=-.1}end
 local p={ambient=c.ambient,night=c.nightAmbient,sources=sources,emission={enabled=true,day=c.emissionDay,night=c.emissionNight,bloom=c.emissionBloom,regions={{at={5,0},rect={0,0,16,32},palette=c.glassPalette}}}}
 H.cache[L]={signature=signature,profile=p};return p
end
function H.capture(list,o,x,z)
 if not o.woodHome or o.kind~='fold'then return false end
 local c=cfg();local scale=V.require('DioramaConfig').emeraldInteriors.heightScale
 local function box(a,b,back,front,low,high)list[#list+1]={lo={x+a,low*scale,z+back},hi={x+b,high*scale,z+front},wall=false}end
 if o.faucet then
  box(1,o.w-1,o.front-o.depth,o.front,0,o.height)
  box(6,13,o.front-14-.25,o.front-14+.25,o.height,o.height+9)
 elseif o.y==4 then
  box(0,o.w,o.front-o.depth,o.front,o.height-c.tableThickness,o.height)
  if o.cup then box(17,27,o.front-12-.25,o.front-12+.25,o.height,o.height+9)end
 else return false end
 return true
end
return H
