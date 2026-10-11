-- Thin individual cliff fins and machine flats; never a single cavern arch.
local layouts={}
local left={62,17,341,330};local right={423,19,709,330}
local ridge={772,186,1151,308};local door={73,365,319,664}
local pipe={514,349,682,674};local console={806,433,1116,664}
local fall={1300,360,1420,680};local pool={20,805,383,954}
local rubble={397,727,755,943};local vent={791,779,1149,965}
local steam={1239,700,1348,976}
local embers={{1414,719,1463,790},{1419,820,1459,879},{1420,910,1455,959}}
local teeth={{1194,77,1284,283},{1315,77,1400,284},{1433,60,1510,278}}
for _,key in ipairs({'path','magma','volcano'})do
 local out={};layouts[key]=out
 local function card(r,w,x,y,z,h,extra)
  local begin=3.12+#out*.022
  local d={texture='volcanic-layered-v2.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
   direction=z>1 and -1 or 1,foldOffset=math.min(.08,(begin-3.12)*.12)}
  for k,v in pairs(extra or{})do d[k]=v end
  out[#out+1]=d;return d
 end
 if key=='volcano'then
  card(ridge,4.80,0,-1.35,-3.01,76,{lava=true})
  card(ridge,2.05,-1.60,-1.35,-2.71,57,{lava=true})
  card(ridge,2.01,1.64,-1.35,-2.56,48,{lava=true,mirror=true})
  card(left,1.17,-2.07,-1.35,-2.00,65)
  card(right,1.22,2.06,-1.35,-2.03,67)
  -- The original meteorite apparatus remains a distinct landmark card.
  card({1223,61,1528,498},.68,.58,-1.35,-2.05,42,{texture='volcanic-details.png',lamps=true})
 else
  card(right,1.86,-.82,-1.35,-3.03,117)
  card(left,1.92,.91,-1.35,-2.88,119)
  card(left,1.84,-1.93,-1.35,-2.45,128)
  card(right,1.76,1.91,-1.35,-2.34,122)
  for i=1,6 do
   local h=({30,23,34,25,31,22})[i]
   card(teeth[(i-1)%3+1],.39+(i%2)*.10,-1.92+(i-1)*.77,111+(i%3)*8,-3.36,h,
    {mount='lid',pivot=h-1,oscillate=.004,floatPhase=i*.9})
  end
 end
 if key=='magma'then
  card(door,1.47,.04,-1.35,-2.56,75)
  card(pipe,.66,-1.13,-1.35,-2.19,67)
  card(console,1.36,.95,-1.35,-1.88,36,{lamps=true})
  card(left,.90,-2.03,-1.35,-1.69,57)
  card(fall,.25,-2.02,-1.35,-1.58,47,{lava=true,fluidCard='magma-fall'})
 elseif key=='path'then
  card(rubble,1.26,-1.07,-1.35,-2.03,37)
  card(vent,1.06,.94,-1.35,-1.91,35)
  card(rubble,.91,-2.16,-1.35,-1.51,28)
  card(rubble,.87,2.15,-1.35,-1.48,30,{mirror=true})
 else
  card(left,.89,-.98,-1.35,-2.26,54)
  card(fall,.33,-1.02,-1.35,-2.12,42,{lava=true,fluidCard='volcano-fall'})
  card(vent,.90,1.56,-1.35,-1.51,27)
 end
 if key~='path'then
  card(pool,1.41,-1.75,-1.35,-1.24,15,{lava=true,fluidCard='left-current'})
  card(pool,1.49,1.54,-1.35,-1.30,15,{lava=true,fluidCard='right-current',mirror=true})
 end
 card(rubble,.90,-2.61,-1.35,-.73,27)
 card(rubble,.85,2.64,-1.35,-.77,25,{mirror=true})
 for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
  card({8,201,580,491},1.15,p[1],-1.35,p[2],18,{texture='volcanic-details.png'})
 end
 card(rubble,.78,-2.64,-1.35,1.05,25)
 card(rubble,.72,2.62,-1.35,1.09,22,{mirror=true})
 if key=='path'then
  card(vent,.69,-1.98,-1.35,2.04,18)
  card(rubble,.65,2.00,-1.35,2.00,18)
 else
  card(pool,.90,-1.94,-1.35,2.10,10,{lava=true,fluidCard='front-left-current'})
  card(pool,.87,1.98,-1.35,2.06,10,{lava=true,fluidCard='front-right-current',mirror=true})
 end
 card(rubble,.56,-.97,-1.35,2.73,15)
 card(rubble,.48,.97,-1.35,2.72,13,{mirror=true})
 for i=1,3 do
  local path=key=='path'
  local x=path and(i==2 and -1.98 or .94)or(i==2 and 1.57 or -1.79)
  local y=path and(i==2 and 14 or 29)or 4
  local z=path and(i==2 and 2.03 or -1.90)or -1.18
  card(path and steam or embers[i],path and .24 or .10,x,y,z,path and 15 or 4,
   {ambientCard=key..'Volcanic'..i})
 end
end
return layouts
