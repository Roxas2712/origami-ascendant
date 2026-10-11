-- Town landmarks and small tournament pavilions, built from individual flats.
local layouts={}
local bounds={
 dewford={{11,58,492,655},{513,91,1040,633},{1073,97,1523,660},{8,751,551,952},{583,712,1038,971},{1088,770,1522,954}},
 lavaridge={{6,3,514,612},{533,75,1031,612},{1045,60,1533,625},{21,789,598,991},{611,655,1057,992},{1089,683,1511,991}},
 mossdeep={{22,115,505,660},{526,81,1011,658},{1030,127,1519,659},{16,719,514,960},{530,735,1012,989},{1056,775,1502,929}},
 frontier={{24,35,498,609},{515,113,1022,612},{1038,141,1521,609},{54,768,575,972},{638,712,1108,962},{1212,654,1391,927}},
 ever_grande={{25,20,483,736},{500,36,1044,731},{1056,158,1527,741},{20,761,490,967},{547,764,1006,994},{1066,804,1503,978}},
 petalburg={{10,72,526,572},{536,74,1024,560},{1036,108,1524,587},{34,720,518,931},{543,665,1043,942},{1070,723,1517,936}},
 littleroot={{8,84,479,627},{505,98,1027,623},{1058,77,1532,626},{34,727,498,937},{526,673,1047,935},{1116,686,1494,935}},
 oldale={{10,32,503,657},{527,59,1007,658},{1036,30,1527,674},{24,726,564,981},{621,732,991,978},{1057,740,1501,966}},
 verdanturf={{26,86,496,593},{521,99,1014,594},{1036,89,1514,593},{35,739,485,936},{524,651,1013,935},{1068,701,1497,930}},
 fallarbor={{17,78,503,648},{519,131,1009,638},{1025,127,1518,649},{31,741,507,932},{544,727,1010,930},{1039,753,1519,905}},

 mauville={{13,96,529,600},{534,131,1016,599},{1023,89,1526,602},{13,705,546,906},{573,697,1093,908},{1136,732,1494,872}},
 lilycove={{23,48,510,644},{548,49,994,661},{1027,158,1512,690},{24,775,538,959},{576,743,1023,975},{1130,730,1457,928}},
 slateport={{19,153,529,637},{543,75,1001,638},{1021,24,1522,644},{20,731,574,966},{616,680,1104,969},{1226,711,1504,961}},
 museum={{87,36,482,656},{556,49,979,659},{1058,52,1491,662},{57,746,517,965},{546,675,1060,969},{1128,667,1452,982}},
 tent_slateport={{18,34,479,670},{501,15,1034,670},{1057,34,1516,671},{38,808,476,974},{530,701,1006,985},{1158,687,1417,1005}},
 tent_verdanturf={{13,8,443,636},{457,3,1081,637},{1097,8,1521,643},{26,751,592,990},{629,706,1092,980},{1152,671,1457,985}},
 tent_fallarbor={{10,11,468,658},{529,9,1009,656},{1070,10,1526,657},{17,765,635,980},{688,718,1164,988},{1209,692,1508,1015}},
}
for _,kind in ipairs({'mauville','lilycove','slateport','museum','tent_slateport','tent_verdanturf','tent_fallarbor','dewford','lavaridge','mossdeep','frontier','ever_grande','petalburg','littleroot','oldale','verdanturf','fallarbor'})do
 local list={};layouts[kind]=list;local tent=kind:find('tent_',1,true)~=nil
 local function card(part,w,x,y,z,h,extra)
  local b=bounds[kind][part];local start=3.12+#list*.032
  local d={texture='town-'..kind..'-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=start,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=math.min(.06,(start-3.12)*.10)}
  for k,v in pairs(extra or{})do d[k]=v end
  list[#list+1]=d
 end
 if kind=='mauville'then
  card(2,3.10,.10,-1.35,-2.98,108)
  card(1,2.64,-1.60,-1.35,-2.43,101,{warm=true})
  card(3,2.50,1.73,-1.35,-2.25,104,{lamps=true})
 elseif kind=='slateport'then
  card(2,3.12,.07,-1.35,-2.95,126)
  card(1,2.47,-1.75,-1.35,-2.47,106)
  card(3,2.35,1.79,-1.35,-2.24,120,{flowing=true})
 else
  card(2,3.36,.03,-1.35,-2.94,125)
  card(1,2.31,-1.79,-1.35,-2.52,120,{flowing=kind=='museum'or kind=='ever_grande'or kind=='lavaridge'})
  card(3,2.23,1.83,-1.35,-2.29,117,{flowing=kind=='lilycove'or kind=='museum'or kind=='petalburg'or kind=='dewford'or kind=='mossdeep'or kind=='ever_grande'or kind=='lavaridge'})
 end
 if kind=='dewford'then
  card(6,1.48,-1.55,-1.35,-1.46,25,{wave=.7,flowing=true})
  card(6,1.17,1.47,-1.35,-1.48,21,{wave=2.1,flowing=true})
 elseif kind=='lavaridge'then
  card(6,.87,-1.93,86,-2.37,28,{floatY=2.1,sway=.01})
  card(6,.75,1.97,74,-2.15,25,{floatY=1.6,sway=.01,mirror=true})
 elseif kind=='museum'then
  card(6,.83,1.98,65,-2.19,25,{spin=.18,pivot=12.5})
  card(6,.61,-1.74,72,-2.43,18,{spin=-.12,pivot=9})
 elseif kind=='mauville'or kind=='lilycove'or kind=='mossdeep' or kind=='ever_grande' or kind=='petalburg' or kind=='littleroot' or kind=='oldale' or kind=='verdanturf' or kind=='fallarbor'then
  card(6,1.78,-1.39,127,-3.39,kind=='mauville'and 20 or 27,{mount='lid',driftX=.9})
  card(6,1.15,1.56,132,-3.40,kind=='mauville'and 15 or 20,{mount='lid',driftX=.65,mirror=true})
 elseif kind~='frontier'then
  card(6,.76,-1.34,109,-3.37,32,{mount='lid',oscillate=.016,pivot=32})
  card(6,.65,1.49,115,-3.36,27,{mount='lid',oscillate=.012,pivot=27,mirror=true})
 end
 local coastal=kind=='mossdeep'or kind=='slateport'or kind=='dewford'or kind=='lilycove'
 if coastal then
  -- Trainer podiums retain their original anchored geometry.
  card(4,1.14,-2.37,-1.35,.54,18)
  card(4,1.14,2.37,-1.35,-.10,18)
  local rects={palm={38,6,384,394},rocks={379,138,775,396},hibiscus={775,48,1160,395},
   telescope={1208,18,1499,395},wall={16,430,375,688},crates={392,432,787,691},
   bollard={836,432,1147,690},buoy={1222,398,1437,699},grass={18,696,369,997},
   bench={382,736,773,984},net={779,728,1159,1005},crab={1180,716,1519,1000}}
  local function prop(name,w,x,z,h,extra)
   local r=rects[name];local begin=3.32+#list*.016
   local d={texture='coastal-details-v1.png',imageWidth=1536,imageHeight=1024,cutout=true,
    points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=-1.35,z=z,
    heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
    direction=z>1 and -1 or 1,foldOffset=.035,coastalDetail=name}
   for k,v in pairs(extra or{})do d[k]=v end
   list[#list+1]=d
  end
  if kind=='mossdeep'then
   prop('palm',1.18,-2.52,-1.33,55,{sway=true})
   prop('wall',1.15,1.68,-1.41,20)
   prop('telescope',.58,2.45,-1.07,30)
   prop('bench',.91,-1.44,-1.47,15)
   prop('hibiscus',.75,-2.54,-.86,22,{sway=true})
   prop('hibiscus',.61,1.74,-1.22,18,{sway=true,mirror=true})
   prop('rocks',.88,-2.66,1.01,15)
   prop('grass',.51,-2.47,1.20,14,{sway=true})
   prop('hibiscus',.69,2.66,1.07,18,{sway=true,mirror=true})
   prop('rocks',1.05,1.96,2.04,20)
   prop('grass',.65,1.68,2.22,16,{sway=true})
   prop('wall',1.07,-1.98,2.02,18)
   prop('grass',.58,-1.02,2.80,14,{sway=true})
   prop('rocks',.74,1.04,2.80,11,{mirror=true})
  elseif kind=='slateport'then
   prop('crates',1.01,-2.45,-1.29,27)
   prop('wall',1.26,1.58,-1.46,23)
   prop('bollard',.56,2.48,-1.09,19)
   prop('hibiscus',.56,-1.48,-1.38,17,{sway=true})
   prop('net',.63,-2.25,-1.05,13)
   prop('crates',.87,2.64,1.03,20,{mirror=true})
   prop('buoy',.33,2.40,1.24,18)
   prop('bollard',.55,-2.75,1.02,15)
   prop('wall',1.09,-1.97,2.05,18)
   prop('net',.69,-1.69,2.25,14)
   prop('rocks',.85,2.02,2.04,14)
   prop('grass',.54,1.76,2.25,13,{sway=true})
   prop('buoy',.29,-1.02,2.80,15)
   prop('net',.67,1.05,2.79,11,{mirror=true})
  elseif kind=='dewford'then
   prop('palm',1.27,-2.38,-1.50,57,{sway=true})
   prop('palm',1.03,2.52,-1.43,48,{sway=true,mirror=true})
   prop('rocks',1.29,-1.47,-1.40,21)
   prop('hibiscus',.74,1.55,-1.45,22,{sway=true})
   prop('net',.66,2.38,-1.05,16)
   prop('buoy',.31,-2.72,1.03,16)
   prop('rocks',.90,2.65,1.00,17)
   prop('grass',.51,2.43,1.22,13,{sway=true})
   prop('rocks',1.00,-2.06,2.08,17)
   prop('crab',.21,-2.15,2.31,5.1,{ambientCard='dewfordCrab'})
   prop('grass',.72,1.98,2.08,17,{sway=true,mirror=true})
   prop('grass',.54,-1.05,2.80,13,{sway=true})
   prop('rocks',.78,1.02,2.80,12)
  else
   prop('wall',1.35,-1.56,-1.45,25)
   prop('palm',1.05,2.53,-1.43,49,{sway=true,mirror=true})
   prop('bench',1.00,1.38,-1.40,17)
   prop('hibiscus',.66,-2.48,-1.10,21,{sway=true})
   prop('hibiscus',.57,2.32,-.94,17,{sway=true})
   prop('rocks',.91,-2.60,1.02,17)
   prop('grass',.49,-2.45,1.20,13,{sway=true})
   prop('bollard',.55,2.73,1.02,17)
   prop('wall',1.00,-1.99,2.04,18)
   prop('hibiscus',.62,-1.74,2.23,16,{sway=true})
   prop('net',.88,2.02,2.06,18)
   prop('crab',.20,1.88,2.36,4.9,{ambientCard='lilycoveCrab',mirror=true})
   prop('grass',.61,-1.06,2.79,15,{sway=true})
   prop('buoy',.31,1.04,2.79,15)
  end
 elseif kind=='littleroot'or kind=='oldale'or kind=='verdanturf'or kind=='petalburg'then
  card(4,1.14,-2.37,-1.35,.54,18)
  card(4,1.14,2.37,-1.35,-.10,18)
  local rects={tree={16,20,359,371},hedge={392,128,761,343},fern={796,26,1137,345},
   fence={1170,114,1517,333},flowers={20,392,369,665},planter={402,438,753,659},
   sign={892,370,1119,667},mailbox={1276,388,1433,667},
   rotor={108,689,269,852},stick={170,845,195,998},butterfly={436,754,715,943},
   leaf={832,690,1097,999},log={1158,768,1517,965}}
  local function prop(name,w,x,z,h,extra)
   local r=rects[name];local begin=3.32+#list*.016
   local d={texture='garden-details-v1.png',imageWidth=1536,imageHeight=1024,cutout=true,
    points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=-1.35,z=z,
    heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
    direction=z>1 and -1 or 1,foldOffset=.035,gardenDetail=name}
   for k,v in pairs(extra or{})do d[k]=v end
   list[#list+1]=d;return d
  end
  if kind=='littleroot'then
   prop('tree',1.17,-2.49,-1.35,54,{sway=true})
   prop('fern',.93,2.40,-1.39,35,{sway=true})
   prop('fence',1.17,-1.51,-1.46,23)
   prop('planter',.89,1.36,-1.43,19)
   prop('mailbox',.34,-2.33,-.88,27)
   -- Rotor contour excludes the stick; a full rotation cannot turn the pole.
   local unit=.13
   local stick=prop('stick',25*unit/30,2.48,-1.04,153*unit)
   local rotor=prop('rotor',161*unit/30,2.48+6*unit/30,-1.038,163*unit,
    {y=-1.35+146*unit,pivot=78*unit,eventMotion='littlerootRotor',hingeX=-1.5*unit,
     points={{135,689},{196,709},{230,746},{269,714},{261,778},{237,813},{244,852},{195,842},{163,809},{108,835},{117,784},{159,745}}})
   rotor.begin=stick.begin;rotor.foldBaseY=-1.35
   prop('hedge',.90,-2.61,1.02,15,{sway=true})
   prop('flowers',.68,2.66,1.04,18,{sway=true})
   prop('log',1.01,-1.99,2.04,16)
   prop('fern',.57,-1.72,2.22,16,{sway=true})
   prop('fence',.96,2.00,2.06,19)
   prop('flowers',.59,1.72,2.23,15,{sway=true})
   prop('hedge',.63,-1.03,2.78,12,{sway=true})
   prop('planter',.68,1.03,2.78,12)
  elseif kind=='oldale'then
   prop('tree',1.09,-2.49,-1.35,50,{sway=true})
   prop('hedge',1.18,-1.37,-1.45,24,{sway=true})
   prop('planter',.92,1.42,-1.40,20)
   prop('fern',.77,2.37,-1.13,26,{sway=true})
   local sign=prop('sign',.89,2.30,-1.41,38)
   local u=sign.width*30/(1119-892);local v=38/(667-370)
   -- Fixed post and a single hinged arrow; original RGBA remains unchanged.
   sign.points={{892,370},{936,370},{936,667},{892,667}};sign.width=44*u/30
   sign.x=2.30+(914-1005.5)*u/30
   prop('sign',183*u/30,2.30+(1027.5-1005.5)*u/30,-1.408,100*v,
    {points={{936,388},{1119,388},{1119,488},{936,488}},heightScale=v/u,
     y=-1.35+(667-488)*v,eventMotion='oldaleSign',foldBaseY=-1.35,begin=sign.begin})
   prop('flowers',.71,-2.66,1.02,18,{sway=true})
   prop('fence',.86,2.63,1.02,16)
   prop('hedge',.58,2.44,1.23,13,{sway=true})
   prop('log',1.00,-1.97,2.05,16)
   prop('flowers',.59,-1.69,2.24,15,{sway=true})
   prop('planter',.95,1.97,2.04,17)
   prop('fern',.56,-1.04,2.79,14,{sway=true})
   prop('hedge',.72,1.03,2.78,13,{sway=true})
  elseif kind=='verdanturf'then
   prop('tree',1.00,-2.46,-1.36,49,{sway=true})
   prop('tree',.89,2.47,-1.38,44,{sway=true,mirror=true})
   card(5,1.08,-1.40,-1.35,-1.44,24)
   prop('flowers',1.02,1.37,-1.44,26,{sway=true})
   prop('fern',.64,-2.30,-.94,24,{sway=true})
   prop('planter',.83,-2.63,1.01,17)
   prop('hedge',.85,2.62,1.02,16,{sway=true})
   prop('fence',1.00,-1.99,2.03,20)
   prop('flowers',.72,-1.74,2.23,18,{sway=true})
   prop('flowers',.89,1.98,2.04,23,{sway=true,mirror=true})
   prop('fern',.55,1.72,2.24,16,{sway=true})
   prop('hedge',.70,-1.02,2.78,13,{sway=true})
   prop('planter',.70,1.03,2.78,14)
   for i,x in ipairs({-1.81,1.90})do prop('butterfly',.23,x,2.29,5.4,{y=14,ambientCard='verdanturfButterfly'..i})end
  else
   prop('tree',1.20,-2.47,-1.36,55,{sway=true})
   prop('fern',.98,2.43,-1.35,36,{sway=true})
   prop('fence',1.15,-1.41,-1.44,23)
   prop('hedge',1.14,1.34,-1.44,24,{sway=true})
   prop('flowers',.72,-2.34,-.97,22,{sway=true})
   prop('hedge',.88,-2.61,1.02,16,{sway=true})
   prop('fern',.67,2.66,1.03,20,{sway=true})
   prop('log',1.00,-1.99,2.04,17)
   prop('flowers',.57,-1.72,2.24,14,{sway=true})
   prop('fence',1.00,1.97,2.04,20)
   prop('hedge',.65,1.70,2.24,14,{sway=true})
   prop('fern',.57,-1.03,2.79,15,{sway=true})
   prop('flowers',.65,1.02,2.79,15,{sway=true})
   for i=1,3 do prop('leaf',.16,-2.14+(i-1)*.14,-.94,5.6,{y=39+i*1.4,ambientCard='petalburgLeaf'..i})end
  end
 elseif kind=='museum'or tent then
  card(4,1.14,-2.37,-1.35,.54,18)
  card(4,1.14,2.37,-1.35,-.10,18)
  local rects={anchor={18,6,343,360},fossil={408,24,716,357},ship={754,20,1136,355},
   lectern={1170,49,1518,353},trophy={67,364,325,676},rope={378,390,771,661},
   planter={779,386,1143,671},cushions={1175,391,1518,657},desk={19,693,395,991},
   beam={427,694,733,761},bell={484,761,695,987},ribbon={841,683,1034,990},fan={1108,695,1526,977}}
  local function prop(name,w,x,z,h,extra)
   local r=rects[name];local begin=3.32+#list*.016
   local d={texture='pavilion-details-v1.png',imageWidth=1536,imageHeight=1024,cutout=true,
    points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=-1.35,z=z,
    heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
    direction=z>1 and -1 or 1,foldOffset=.035,pavilionDetail=name}
   for k,v in pairs(extra or{})do d[k]=v end
   list[#list+1]=d;return d
  end
  if kind=='museum'then
   prop('ship',1.03,-1.52,-1.46,35)
   prop('anchor',.70,1.49,-1.45,36)
   prop('lectern',.66,-2.48,-1.07,24)
   prop('fossil',.62,2.46,-1.06,26)
   prop('rope',.87,-2.63,1.02,19)
   prop('fossil',.48,-2.39,1.22,20)
   prop('lectern',.68,2.64,1.04,22)
   prop('anchor',.58,-1.99,2.05,24)
   prop('rope',.59,-1.71,2.25,15)
   prop('ship',.95,1.98,2.06,23)
   prop('planter',.51,1.71,2.25,13)
   prop('lectern',.60,-1.03,2.79,17)
   prop('fossil',.46,1.03,2.79,18)
   local unit=28/226
   local beam=prop('beam',306*unit/30,2.16-9.5*unit/30,-1.74,67*unit,{y=71,foldBaseY=-1.35})
   local bell=prop('bell',211*unit/30,2.16,-1.735,28,
    {y=43,pivot=28,foldBaseY=-1.35,eventMotion='museumBell',hingeX=-5.5*unit})
   bell.begin=beam.begin
  else
   -- One differently arranged set per tent; no tenfold copied decoration island.
   local verdant=kind=='tent_verdanturf';local fall=kind=='tent_fallarbor'
   prop('desk',1.13,verdant and 1.47 or -1.47,-1.46,30)
   prop('trophy',.54,verdant and -1.50 or 1.50,-1.45,31)
   prop('planter',.70,-2.45,-1.05,22)
   prop('cushions',.68,2.46,-1.04,20)
   prop(fall and 'cushions'or 'rope',.81,-2.64,1.03,18)
   prop('planter',.50,-2.41,1.23,14)
   prop(verdant and 'planter'or 'rope',.76,2.65,1.04,18)
   prop('cushions',.91,-1.98,2.05,20)
   prop('planter',.55,-1.71,2.24,14)
   prop('rope',.95,1.98,2.05,19)
   prop('planter',.55,1.71,2.24,14)
   prop(fall and 'rope'or 'planter',.63,-1.03,2.79,14)
   prop(verdant and 'planter'or 'cushions',.65,1.03,2.79,14)
   if kind=='tent_slateport'then
    for i=1,2 do prop('ribbon',.24,i==1 and -2.16 or 2.16,-.97,12,
     {y=45,ambientCard='slateportRibbon'..i})end
   elseif verdant then
    prop('fan',.67,1.47,-1.43,16,{y=22,foldBaseY=-1.35,eventMotion='verdanturfFan',pivot=0})
   else
    -- Reuse the refined four-point paper highlight already used by Mauville.
    prop('trophy',.42,1.39,-1.38,13,{y=25,ambientCard='fallarborTrophySpark',
     texture='civic-details-v1.png',points={{1261,762},{1444,762},{1444,957},{1261,957}},
     heightScale=13/(195*.42*30/183)})
   end
  end
 elseif kind=='mauville'or kind=='ever_grande'or kind=='frontier'then
  card(4,1.14,-2.37,-1.35,.54,18)
  card(4,1.14,2.37,-1.35,-.10,18)
  local rects={bike={20,57,420,353},bench={431,89,820,355},lamp={914,14,1019,393},
   hedge={1107,99,1519,360},wall={29,449,412,681},tree={428,353,815,719},
   flowers={814,449,1198,695},urn={1202,381,1515,713},
   pennant={75,697,309,999},rope={420,733,816,990},petal={936,765,1129,959},spark={1261,762,1444,957}}
  local function prop(name,w,x,z,h,extra)
   local r=rects[name];local begin=3.32+#list*.016
   local d={texture='civic-details-v1.png',imageWidth=1536,imageHeight=1024,cutout=true,
    points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=-1.35,z=z,
    heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
    direction=z>1 and -1 or 1,foldOffset=.035,civicDetail=name}
   for k,v in pairs(extra or{})do d[k]=v end
   list[#list+1]=d
  end
  if kind=='mauville'then
   prop('hedge',1.06,-1.52,-1.47,22)
   prop('bench',1.00,1.47,-1.45,22)
   prop('bike',.78,-2.21,-1.05,24)
   prop('lamp',.29,-2.49,-1.36,42,{lamps=true})
   prop('lamp',.29,2.48,-1.34,42,{lamps=true})
   prop('hedge',.76,-2.66,1.02,17)
   prop('flowers',.53,-2.44,1.21,14,{sway=true})
   prop('rope',.78,2.65,1.04,18)
   prop('bench',1.00,-1.98,2.04,21)
   prop('flowers',.53,-1.71,2.23,14,{sway=true})
   prop('hedge',.99,1.98,2.05,20)
   prop('flowers',.58,1.72,2.24,14,{sway=true})
   prop('rope',.63,-1.04,2.78,14)
   prop('hedge',.66,1.03,2.79,13)
   for i=1,2 do prop('spark',.40,i==1 and -2.49 or 2.48,i==1 and -1.27 or -1.25,13,
    {y=32,ambientCard='mauvilleSpark'..i})end
  elseif kind=='ever_grande'then
   prop('tree',1.16,-2.44,-1.42,54,{sway=true})
   prop('tree',1.02,2.47,-1.39,49,{sway=true,mirror=true})
   prop('wall',1.12,-1.40,-1.47,26)
   prop('urn',.52,1.59,-1.40,29)
   prop('flowers',.61,-2.34,-.95,18,{sway=true})
   prop('wall',.91,-2.61,1.02,20)
   prop('flowers',.51,-2.41,1.24,14,{sway=true})
   prop('urn',.53,2.70,1.01,22)
   prop('wall',1.00,-1.99,2.05,22)
   prop('flowers',.60,-1.71,2.24,15,{sway=true})
   prop('bench',.98,1.98,2.06,21)
   prop('flowers',.60,1.72,2.24,15,{sway=true})
   prop('flowers',.63,-1.03,2.79,14,{sway=true})
   prop('urn',.42,1.03,2.79,18)
   for i=1,3 do prop('petal',.13,-2.16+(i-1)*.09,-.96,4.1,
    {y=37+i*2,ambientCard='everGrandePetal'..i})end
  else
   prop('hedge',1.08,-1.43,-1.45,23)
   prop('bench',1.02,1.39,-1.44,22)
   prop('urn',.49,-2.43,-1.06,28)
   prop('urn',.49,2.43,-1.06,28)
   prop('rope',.94,-2.56,1.02,19)
   prop('flowers',.52,-2.38,1.23,14,{sway=true})
   prop('hedge',.82,2.64,1.03,18)
   prop('rope',.99,-1.98,2.05,19)
   prop('flowers',.54,-1.71,2.24,14,{sway=true})
   prop('wall',.99,1.98,2.05,22)
   prop('flowers',.54,1.71,2.24,14,{sway=true})
   prop('urn',.42,-1.03,2.79,18)
   prop('hedge',.65,1.03,2.79,14)
   -- No floor stand hanging in midair: these pennants consist only of rod
   -- and paper, suspended on the renderer's lid threads.
   prop('pennant',.76,-1.34,-3.37,32,{y=109,mount='lid',pivot=32,
    eventMotion='frontierPennant',floatPhase=.9})
   prop('pennant',.65,1.49,-3.36,27,{y=115,mount='lid',pivot=27,
    eventMotion='frontierPennant',floatPhase=1.8,mirror=true})
  end
 elseif kind=='lavaridge'or kind=='fallarbor'then
  card(4,1.14,-2.37,-1.35,.54,18)
  card(4,1.14,2.37,-1.35,-.10,18)
  local rects={rocks={22,40,411,363},spout={461,62,737,350},basin={779,58,1183,365},
   steam={1233,26,1478,396},maple={22,384,379,686},screen={429,424,741,670},
   fern={788,402,1169,688},shrub={1197,425,1510,687},pots={75,698,331,998},
   planter={399,712,766,975},leaf={853,744,1075,966},ash={1223,746,1464,975}}
  local function prop(name,w,x,z,h,extra)
   local r=rects[name];local begin=3.32+#list*.016
   local d={texture='volcanic-town-details-v1.png',imageWidth=1536,imageHeight=1024,cutout=true,
    points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=-1.35,z=z,
    heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
    direction=z>1 and -1 or 1,foldOffset=.035,volcanicTownDetail=name}
   for k,v in pairs(extra or{})do d[k]=v end
   list[#list+1]=d
  end
  if kind=='lavaridge'then
   prop('maple',1.10,-2.45,-1.38,51,{sway=true})
   prop('screen',1.23,1.72,-1.46,32)
   prop('basin',1.16,-1.34,-1.48,24,{flowing=true})
   prop('spout',.59,-1.70,-1.46,31,{y=9,foldBaseY=-1.35,flowing=true})
   prop('pots',.44,2.45,-1.08,23)
   prop('shrub',.59,-2.42,-.93,17,{sway=true})
   prop('rocks',.90,-2.60,1.02,18)
   prop('fern',.52,-2.40,1.23,13,{sway=true})
   prop('planter',.75,2.66,1.04,17)
   prop('screen',.96,-1.99,2.04,20)
   prop('shrub',.59,-1.70,2.24,15,{sway=true})
   prop('rocks',.96,2.00,2.05,19)
   prop('pots',.40,1.73,2.22,17)
   prop('fern',.58,-1.03,2.79,15,{sway=true})
   prop('planter',.65,1.03,2.79,13)
   for i=1,3 do prop('steam',.36,-1.52+(i-1)*.17,-1.47,17,
    {y=17,ambientCard='lavaridgeSteam'..i})end
  else
   prop('maple',1.17,2.45,-1.40,52,{sway=true,mirror=true})
   prop('screen',1.15,-1.65,-1.45,28)
   prop('rocks',.95,-2.42,-1.09,29)
   prop('planter',.79,1.40,-1.36,19)
   prop('fern',.65,2.40,-.92,21,{sway=true})
   prop('pots',.43,-1.44,-1.09,22)
   prop('shrub',.77,-2.65,1.03,19,{sway=true})
   prop('rocks',.91,2.62,1.02,18)
   prop('fern',.51,2.42,1.22,14,{sway=true})
   prop('screen',.95,-1.98,2.05,19)
   prop('fern',.55,-1.70,2.24,15,{sway=true})
   prop('shrub',.88,1.99,2.06,19,{sway=true})
   prop('pots',.39,1.73,2.25,17)
   prop('rocks',.63,-1.02,2.79,13)
   prop('planter',.66,1.02,2.79,14)
   for i=1,3 do prop('ash',.22,-1.86+(i-1)*.12,2.35,6.8,
    {y=4+i*1.5,ambientCard='fallarborAsh'..i})end
  end
 else
 card(5,1.19,-2.49,-1.35,-1.12,24)
 card(5,1.06,2.52,-1.35,-1.07,22,{mirror=true})
 card(5,1.06,-1.18,-1.35,-1.53,21)
 card(5,.93,1.45,-1.35,-1.51,19,{mirror=true})
 card(4,1.14,-2.37,-1.35,.54,18)
 card(4,1.14,2.37,-1.35,-.10,18)
 for _,p in ipairs({{-2.80,.95,.67,15},{2.77,.97,.67,15},{-2.05,2.07,.83,20},{2.04,2.07,.83,20},{-1.03,2.78,.62,14},{1.04,2.78,.62,14}})do
  card(5,p[3],p[1],-1.35,p[2],p[4],{mirror=p[1]>0})
 end
 end
 -- Split machinery from its facade using the original atlas pixels. All
 -- pieces share the facade's floor hinge during the opening animation.
 local function split(index,rects)
  local source=table.remove(list,index)
  local b0,b1=source.points[1],source.points[3]
  local unit=source.width*30/(b1[1]-b0[1])
  for _,r in ipairs(rects)do
   local d={};for k,v in pairs(source)do d[k]=v end
   d.points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}}
   d.width=(r[3]-r[1])*unit/30
   d.x=source.x+((r[1]+r[3]-b0[1]-b1[1])/2)*unit/30
   d.y=source.y+(b1[2]-r[4])*unit*source.heightScale
   d.foldBaseY=source.y
   for k,v in pairs(r[5]or{})do d[k]=v end
   list[#list+1]=d
  end
 end
 if kind=='mossdeep'then
  local unit=3.36*30/(1011-526)
  split(1,{{526,203,1011,658},{526,81,638,203},{790,81,1011,203},
   {638,81,790,203,{eventMotion='mossdeepDish',hingeX=(697-714)*unit}}})
 elseif kind=='slateport'then
  split(1,{{543,75,1001,237},{543,237,832,303},{864,237,1001,303},{543,303,1001,638},
   {832,237,864,303,{eventMotion='slateportHook',pivot=66*126/(638-75)}}})
  for i,d in ipairs(list)do
   if d.mount=='lid'then d.eventMotion='slateportPennant';d.floatPhase=i*.7 end
  end
 end
end
return layouts
