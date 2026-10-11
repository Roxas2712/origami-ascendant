-- Cave of Origin: staggered limestone flats, individual lid teeth and seep cards.
local out={}
local function card(r,w,x,y,z,h,extra)
 local begin=3.12+#out*.021
 local d={texture='origin-layered-v2.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
  heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
  direction=z>1 and -1 or 1,foldOffset=math.min(.08,(begin-3.12)*.12)}
 for k,v in pairs(extra or{})do d[k]=v end
 if y>1 and not d.mount and not d.ambientCard then d.support=true end
 out[#out+1]=d;return d
end
local left={13,11,323,398};local right={448,11,749,399}
local ridge={786,22,1152,389};local depth={12,410,377,670}
local fall={882,402,1047,698}
local pool={1146,506,1533,663};local fern={8,698,372,1006}
local rock={393,699,766,1005};local chips={798,740,1135,1002}
card(depth,3.0,.08,-1.35,-3.23,103)
card(ridge,1.92,-.66,-1.35,-2.99,116)
card(ridge,1.49,.90,-1.35,-2.80,98,{mirror=true})
card(left,2.05,-1.70,-1.35,-2.49,135)
card(right,2.10,1.73,-1.35,-2.31,129)
for i,r in ipairs({{1160,52,1233,292},{1234,105,1307,351},{1308,113,1373,365},{1382,49,1448,304},{1450,42,1523,292}})do
 local h=({37,29,35,30,34})[i]
 card(r,.34+(i%2)*.08,-1.80+(i-1)*.88,111+(i%2)*9,-3.37,h,
  {mount='lid',pivot=h-1,oscillate=.004,floatPhase=i*.8})
end
card(rock,1.10,-2.04,-1.35,-1.58,59)
card(rock,1.02,2.01,-1.35,-1.62,76,{mirror=true})
card(fall,.27,-2.03,-1.35,-1.48,48,{flowing=true,fluidCard='seep-left'})
card(fall,.25,2.01,-1.35,-1.52,66,{flowing=true,fluidCard='seep-right'})
card(pool,1.27,-1.92,-1.35,-1.13,12,{flowing=true,fluidCard='pool-left'})
card(pool,1.17,1.91,-1.35,-1.09,11,{flowing=true,fluidCard='pool-right'})
card(fern,.69,-2.70,-1.35,-.81,27,{sway=true})
card(fern,.59,2.70,-1.35,-.80,23,{sway=true,mirror=true})
for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
 card({29,782,523,996},1.15,p[1],-1.35,p[2],18,{texture='deepcave-origin-kit.png'})
end
card(chips,.73,-2.71,-1.35,1.04,16)
card(rock,.79,2.68,-1.35,1.09,26)
card(fern,.62,-2.07,-1.35,2.08,23,{sway=true})
card(chips,.79,2.09,-1.35,2.04,16,{mirror=true})
card(rock,.68,-.97,-1.35,2.73,19)
card(fern,.47,.98,-1.35,2.70,17,{sway=true})
card(pool,.73,-2.15,-1.35,1.75,8,{flowing=true,fluidCard='front-pool'})
for i,r in ipairs({{1314,692,1364,762},{1306,777,1372,870},{1297,873,1384,1004}})do
 card(r,.09+(i-1)*.006,({-2.00,1.99,-1.96})[i],({46,64,45})[i],({-1.42,-1.47,-1.35})[i],3.5,
  {ambientCard='originDrop'..i})
end
return {origin=out}
