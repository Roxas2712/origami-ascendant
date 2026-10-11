-- Shoal Cave retains its rock landmarks as the tide exposes salt and shells.
local layouts={}
local function builder(key,texture)
 local out={};layouts[key]=out
 return function(r,w,x,y,z,h,extra)
  local begin=3.12+#out*.02
  local d={texture=texture,imageWidth=1536,imageHeight=1024,cutout=true,
   points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
   direction=z>1 and -1 or 1,foldOffset=math.min(.08,(begin-3.12)*.12)}
  for k,v in pairs(extra or{})do d[k]=v end
  out[#out+1]=d;return d
 end
end
local left={38,18,310,362};local right={447,19,675,362}
local ridge={713,169,1187,349};local kelp={31,378,370,721}
local salt={386,543,752,708};local wave={765,536,1288,711}
local trickle={1347,379,1435,709};local ledge={33,809,458,994}
local rock={478,790,875,995};local crab={908,754,1192,985}
local teeth={{1208,42,1299,340},{1327,53,1375,340},{1400,30,1487,322}}
local drops={{1280,767,1321,826},{1286,850,1316,898},{1287,919,1315,961}}
local saltBits={{1398,768,1437,824},{1400,847,1440,896},{1404,918,1446,966}}
for _,key in ipairs({'tide','salt'})do
 local card=builder(key,'tidal-layered-v2.png');local wet=key=='tide'
 card(ridge,3.83,.12,-1.35,-3.08,91)
 card(ridge,2.29,-.81,-1.35,-2.83,77,{mirror=true})
 card(left,2.12,-1.70,-1.35,-2.45,129)
 card(right,1.98,1.78,-1.35,-2.38,123)
 for i=1,6 do local h=({31,24,34,25,28,23})[i]
  card(teeth[(i-1)%3+1],.38+(i%2)*.08,-1.92+(i-1)*.77,112+(i%3)*7,-3.36,h,
   {mount='lid',pivot=h-1,oscillate=.004,floatPhase=i*.7})
 end
 card(left,.93,-1.85,-1.35,-1.96,61)
 card(right,.89,1.87,-1.35,-1.90,76)
 if wet then
  card(trickle,.25,-1.85,-1.35,-1.85,49,{flowing=true,fluidCard='left-seep'})
  card(trickle,.24,1.87,-1.35,-1.80,61,{flowing=true,fluidCard='right-seep'})
  card(wave,1.80,-1.41,-1.35,-1.38,17,{mutedWater=true,wave=.6,fluidCard='back-left-tide'})
  card(wave,1.73,1.43,-1.35,-1.33,16,{mutedWater=true,wave=.8,fluidCard='back-right-tide',mirror=true})
 else
  card(salt,1.30,-1.41,-1.35,-1.40,21)
  card(salt,1.24,1.47,-1.35,-1.34,20,{mirror=true})
 end
 card(rock,.83,-2.65,-1.35,-.72,27)
 card(rock,.79,2.63,-1.35,-.75,25,{mirror=true})
 for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
  card(ledge,1.15,p[1],-1.35,p[2],18)
 end
 card(wet and kelp or salt,.73,-2.63,-1.35,1.08,wet and 29 or 17,{sway=wet})
 card(rock,.75,2.62,-1.35,1.09,24)
 card(wet and wave or salt,.86,-1.98,-1.35,2.05,wet and 10 or 17,
  {mutedWater=wet,wave=wet and 1.2 or nil,fluidCard=wet and'front-tide'or nil})
 card(wet and kelp or salt,.61,2.00,-1.35,2.03,wet and 25 or 15,{sway=wet,mirror=true})
 card(salt,.52,-.97,-1.35,2.73,13)
 card(wet and kelp or salt,.44,.97,-1.35,2.71,wet and 18 or 12,{sway=wet})
 for i=1,3 do
  card(wet and drops[i]or saltBits[i],wet and .10 or .075,
   ({-1.83,1.85,-1.85})[i],wet and({42,54,42})[i]or 38,
   wet and({-1.79,-1.75,-1.77})[i]or -1.76,wet and 4 or 2.5,
   {ambientCard=(wet and'shoalDrop'or'shoalSalt')..i})
 end
 if not wet then card(crab,.28,-1.78,-.8,2.43,5,{ambientCard='shoalCrab'})end
end
do
 local card=builder('ice','ice-layered-v2.png')
 local l={56,19,350,337};local r={431,23,725,339};local rear={770,148,1190,303}
 local frozenFall={65,357,337,726};local crystal={430,377,700,710}
 local pool={751,505,1214,709};local ledge={17,813,401,958}
 local snow={418,758,748,983};local shards={780,826,1205,978}
 card(rear,3.83,.05,-1.35,-3.11,94)
 card(rear,2.49,-.65,-1.35,-2.90,78,{mirror=true})
 card(l,1.92,-1.82,-1.35,-2.49,127)
 card(r,1.94,1.83,-1.35,-2.41,122)
 for i,b in ipairs({{1230,34,1300,342},{1343,38,1396,316},{1438,26,1492,299}})do
  for j=1,2 do local index=(j-1)*3+i;local h=24+(index%3)*5
   card(b,.35+(index%2)*.08,-1.94+(index-1)*.78,116+(index%3)*6,-3.37,h,
    {mount='lid',pivot=h-1,oscillate=.006,floatPhase=index*.75,frost=true})
  end
 end
 -- Each tracing-paper snowflake is separately suspended between the icicles.
 for i,b in ipairs({{1315,341,1435,460},{1313,467,1433,584},{1312,590,1427,720}})do
  card(b,.48,-1.13+(i-1)*1.15,100+(i%2)*4,-3.10,15,
   {mount='lid',pivot=14,oscillate=.015,floatPhase=i*1.1,frost=true})
 end
 card(frozenFall,1.20,-.11,-1.35,-2.21,87,{frost=true})
 card(crystal,.81,-1.72,-1.35,-1.66,47,{frost=true})
 card(crystal,.71,1.78,-1.35,-1.68,42,{frost=true,mirror=true})
 card(pool,2.28,0,-1.35,-1.46,21,{frost=true})
 card(snow,.91,-2.65,-1.35,-.72,29)
 card(shards,.86,2.64,-1.35,-.74,23,{frost=true})
 for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do card(ledge,1.15,p[1],-1.35,p[2],18,{frost=true})end
 card(snow,.74,-2.62,-1.35,1.10,25)
 card(shards,.73,2.64,-1.35,1.10,23,{frost=true})
 card(crystal,.47,-2.00,-1.35,2.04,24,{frost=true})
 card(snow,.64,2.02,-1.35,2.02,19)
 card(shards,.52,-.96,-1.35,2.72,15,{frost=true})
 card(snow,.45,.97,-1.35,2.70,13)
 for i,b in ipairs({{1263,752,1334,823},{1267,833,1334,905},{1271,914,1336,980}})do
  card(b,.18,-1.71+(i-1)*1.72,90,-1.48,5.5,{ambientCard='shoalFrost'..i})
 end
end
return layouts
