-- Authored alpha silhouettes; UVs stay in the original atlas (no image slicing).
local function builder(texture,iw,ih)
 local out={}
 local function card(rect,width,x,z,begin,extra)
  local x0,y0,x1,y1=unpack(rect)
  local d={texture=texture,imageWidth=iw or 1254,imageHeight=ih or 1254,cutout=true,
   points={{x0,y0},{x1,y0},{x1,y1},{x0,y1}},width=width,x=x,y=-1.35,z=z,
   begin=begin,duration=.8,direction=z>1 and -1 or 1}
  for k,v in pairs(extra or{})do d[k]=v end
  out[#out+1]=d
  return d
 end
 return out,card
end
local layouts={}
-- Preserve the authored placement while giving each disconnected hanging
-- object its own card, hinge and real thread instead of a painted hanger.
local function pendants(add,whole,width,x,y,z,begin,parts,extra)
 local unit=width*30/(whole[3]-whole[1]);local made={}
 for i,r in ipairs(parts)do
  local d={mount='lid',floatY=.12,floatPhase=i*.9,eventIndex=i,pivot=(r[4]-r[2])*unit*.96}
  for k,v in pairs(extra or{})do d[k]=v end
  made[#made+1]=add(r,(r[3]-r[1])*unit/30,x+((r[1]+r[3]-whole[1]-whole[3])/2)*unit/30,
   y+(whole[4]-r[4])*unit,z,begin+(i-1)*.018,d)
 end
 return made
end
do
 local out,c=builder('gym-electric-atlas.png');layouts.electric=out
 -- This is a real paper assembly: no finished facade is painted behind it.
 -- Open roof, suspended lamps, pillars, gate and badge unfold separately.
 local function layer(rect,width,x,y,z,begin,extra)
  local d={texture='gym-electric-layers.png',imageWidth=1536,imageHeight=1024,y=y,foldOffset=(begin-3.12)*.18}
  for k,v in pairs(extra or{})do d[k]=v end
  c(rect,width,x,z,begin,d)
 end
 layer({516,116,1019,445},5.70,0,28,-2.56,3.28,{curve=8})
 pendants(layer,{1029,196,1505,383},4.70,0,79,-1.72,3.64,
  {{1070,300,1170,370},{1214,304,1321,383},{1364,300,1468,366}},{warm=true})
 layer({101,517,380,944},1.72,-1.91,-1.35,-1.93,3.42)
 layer({101,517,380,944},1.72,1.91,-1.35,-1.86,3.49,{mirror=true})
 layer({972,744,1515,944},4.63,0,-1.35,-1.65,3.57)
 layer({574,559,943,927},1.59,0,29,-1.44,3.78,{mount='lid'})
 c({1015,552,1240,936},.86,-1.85,-1.30,3.40)
 c({1015,552,1240,936},.86,1.85,-1.30,3.48)
 c({645,729,1013,918},1.12,-2.1,.64,4.05)
 c({645,729,1013,918},1.12,2.12,.20,4.15)
 c({649,990,944,1173},1.10,-1.9,1.80,4.28,{signal=true})
 c({649,990,944,1173},1.10,1.9,1.80,4.34,{signal=true})
 c({961,973,1243,1204},.73,0,2.88,4.44,{signal=true})
end
do
 local out,c=builder('gym-steam-atlas.png');layouts.steam=out
 c({959,558,1235,765},1.04,-1.38,-1.26,3.38,{flowing=true})
 c({959,558,1235,765},1.04,1.38,-1.26,3.44,{flowing=true})
 c({630,581,961,747},1.12,-2.1,.64,4.05)
 c({630,581,961,747},1.12,2.12,.20,4.15)
 c({665,778,920,1171},.85,-2.70,-.48,3.62,{sway=true})
 c({665,778,920,1171},.85,2.70,-.48,3.70,{sway=true})
 c({938,834,1234,1171},.95,-1.94,1.97,4.26,{sway=true})
 c({938,834,1234,1171},.88,1.99,1.93,4.36,{sway=true})
 c({959,558,1235,765},.77,0,2.83,4.44,{flowing=true})
end
do
 local out,c=builder('gym-psychic-atlas.png');layouts.psychic=out
 c({976,527,1220,853},.91,1.62,-1.27,3.40,{oscillate=.10,pivot=15})
 c({950,853,1228,1165},.99,-1.75,-1.24,3.44,{sway=true})
 c({646,663,966,825},1.12,-2.1,.64,4.05)
 c({646,663,966,825},1.12,2.12,.20,4.15)
 c({648,849,945,1173},.99,-2.62,-.32,3.62,{signal=true})
 c({648,849,945,1173},.99,2.62,-.32,3.70,{signal=true})
 c({950,853,1228,1165},.70,-1.84,1.90,4.32,{sway=true})
 c({648,849,945,1173},.70,1.90,1.93,4.38,{signal=true})
end
do
 local out,c=builder('gym-fighting-atlas.png',1536,1024);layouts.fighting=out
 c({1305,511,1508,759},.98,-1.64,-1.12,3.40,{sway=true})
 c({1305,511,1508,759},.98,1.64,-1.12,3.48,{sway=true})
 c({981,631,1298,751},1.12,-2.1,.64,4.05)
 c({981,631,1298,751},1.12,2.12,.20,4.15)
 c({1307,765,1525,980},.80,-2.65,-.15,3.68,{warm=true})
 c({1307,765,1525,980},.80,2.65,-.15,3.74,{warm=true})
 c({990,773,1281,979},.92,-1.94,1.95,4.32)
 c({990,773,1281,979},.83,2.03,1.85,4.38)
end
do
 local out,c=builder('gym-normal-atlas.png',1536,1024);layouts.normal=out
 c({1293,512,1513,753},1.02,-1.61,-1.08,3.40,{sway=true})
 c({1293,512,1513,753},1.02,1.61,-1.08,3.48,{sway=true})
 c({993,571,1286,704},1.12,-2.1,.64,4.05)
 c({993,571,1286,704},1.12,2.12,.20,4.15)
 c({1007,713,1223,983},.80,-2.64,-.15,3.70,{sway=true})
 c({1007,713,1223,983},.80,2.64,-.15,3.76,{sway=true})
 c({1241,768,1513,990},.89,-1.92,1.92,4.34)
 c({1241,768,1513,990},.82,2.01,1.85,4.40)
end
do
 local out,c=builder('gym-sky-atlas.png',1536,1024);layouts.sky=out
 c({1262,518,1525,727},1.16,-1.55,-1.10,3.42,{turn=.18})
 c({1262,518,1525,727},1.16,1.55,-1.10,3.48,{turn=.18})
 c({972,582,1268,724},1.12,-2.1,.64,4.05)
 c({972,582,1268,724},1.12,2.12,.20,4.15)
 c({985,750,1280,1003},1.05,-2.61,-.08,3.68,{sway=true})
 c({985,750,1280,1003},1.05,2.61,-.08,3.74,{sway=true})
 c({985,750,1280,1003},1.01,-1.84,2.04,4.32,{sway=true})
 c({985,750,1280,1003},.92,1.94,1.96,4.40,{sway=true})
end
do
 local out,c=builder('gym-water-atlas.png',1536,1024);layouts.water=out
 c({1260,515,1515,730},1.30,-1.58,-1.08,3.40,{flowing=true})
 c({1260,515,1515,730},1.30,1.58,-1.08,3.48,{flowing=true})
 c({958,554,1249,711},1.12,-2.1,.64,4.05)
 c({958,554,1249,711},1.12,2.12,.20,4.15)
 c({969,758,1230,982},.98,-2.64,-.18,3.70,{sway=true})
 c({969,758,1230,982},.98,2.64,-.18,3.76,{sway=true})
 c({1238,801,1510,969},.92,-1.87,2.01,4.32,{signal=true})
 c({1238,801,1510,969},.92,1.98,1.94,4.40,{signal=true})
end
-- Assemble independently authored background silhouettes around the foreground
-- props above. Open frames reveal the mirror lid between individual silhouettes;
-- hanging accents connect to that lid rather than to an opaque backing sheet.
local function assembly(kind)
 local old=layouts[kind]
 local out,c=builder('gym-'..kind..'-layers.png',1536,1024)
 local function layer(rect,width,x,y,z,begin,extra)
  local d={y=y,foldOffset=(begin-3.12)*.18}
  for k,v in pairs(extra or{})do d[k]=v end
  if d.height then d.heightScale=d.height/((rect[4]-rect[2])*width*30/(rect[3]-rect[1]));d.height=nil end
  return c(rect,width,x,z,begin,d)
 end
 local function finish()for _,d in ipairs(old)do out[#out+1]=d end;layouts[kind]=out end
 return layer,finish
end
do
 local l,finish=assembly('steam')
 l({458,7,1005,512},5.70,0,-1.35,-2.54,3.29,{height=143,curve=8})
 l({68,516,435,1015},1.58,-1.95,-1.35,-1.94,3.40)
 l({68,516,435,1015},1.58,1.95,-1.35,-1.91,3.48,{mirror=true})
 l({960,660,1522,976},4.60,0,-1.35,-1.55,3.58,{flowing=true})
 l({1002,123,1525,511},3.15,0,76,-1.70,3.70,{mount='lid',warm=true})
 l({533,558,916,935},1.43,0,48,-1.38,3.82,{mount='lid'})
 finish()
end
do
 local l,finish=assembly('psychic')
 l({513,0,1025,499},5.72,0,-1.35,-2.54,3.28,{height=145,curve=8,signal=true})
 l({65,500,452,992},1.55,-1.94,-1.35,-1.93,3.40,{signal=true})
 l({65,500,452,992},1.55,1.94,-1.35,-1.88,3.48,{signal=true,mirror=true})
 l({1016,590,1535,925},4.63,0,-1.35,-1.58,3.57,{signal=true})
 pendants(l,{1078,0,1488,426},2.58,0,68,-1.71,3.70,
  {{1085,257,1150,333},{1144,340,1226,424},{1226,255,1329,388},{1340,338,1420,421},{1424,254,1488,342}},
  {eventMotion='psychicPendant',gymDetail=true,gymHabitat='gym:psychic'})
 l({531,497,1010,977},1.54,0,34,-1.32,3.82,{mount='lid',oscillate=.10,pivot=46,eventMotion='psychicMedallion',gymDetail=true,gymHabitat='gym:psychic'})
 finish()
end
do
 local l,finish=assembly('fighting')
 l({507,5,1030,507},5.72,0,-1.35,-2.54,3.28,{height=145,curve=8})
 l({65,528,448,988},1.58,-1.94,-1.35,-1.93,3.40)
 l({65,528,448,988},1.58,1.94,-1.35,-1.88,3.48,{mirror=true})
 l({1005,690,1518,930},4.50,0,-1.35,-1.56,3.58)
 l({1038,158,1519,432},4.27,0,63,-1.73,3.68,{mount='lid',warm=true})
 l({550,565,950,972},1.55,0,28,-1.31,3.82,{mount='lid',pivot=46,eventMotion='dojoTarget'})
 finish()
end
do
 local l,finish=assembly('normal')
 l({502,15,1008,511},5.2,0,-1.35,-2.4,3.27,{height=145,curve=9})
 -- Seven doors, each its own piece, stepped into three actual paper tiers.
 local function door(x,y,z,begin)
  local whole={150,529,359,993};local unit=.65*30/(whole[3]-whole[1])
  local function piece(r,extra)
   l(r,(r[3]-r[1])*unit/30,x+((r[1]+r[3]-whole[1]-whole[3])/2)*unit/30,
    y+(whole[4]-r[4])*unit,z,begin,extra)
  end
  -- A recessed dark paper backing remains behind the hinged leaf.
  l({179,854,330,963},154*unit/30,x,y+29*unit,z-.006,begin,{height=405*unit,paperTint={.22,.22,.22,1}})
  piece({150,529,359,559});piece({150,559,178,964})
  piece({332,559,359,964});piece({150,964,359,993})
  piece({178,559,332,964},{eventMotion='normalDoor',z=z+.006})
 end
 for row=0,1 do
  for col=-1,1 do
   local x,y,z,begin=col*1.03,4+row*43,-1.94-row*.18,3.37+row*.12+(col+1)*.045
   if row==0 and col==-1 then door(x,y,z,begin)
   else l({150,529,359,993},.65,x,y,z,begin)end
  end
  l({932,700,1523,905},4.16,0,-1.35+row*43,-1.67-row*.18,3.59+row*.12)
 end
 l({150,529,359,993},.59,0,82,-2.18,3.68)
 l({932,700,1523,905},1.16,0,78,-1.96,3.74,{height=11})
 l({1020,115,1513,513},1.02,-2.04,65,-1.38,3.77,{mount='lid'})
 l({1020,115,1513,513},1.02,2.04,65,-1.36,3.83,{mount='lid'})
 finish()
end
do
 local l,finish=assembly('sky')
 l({467,20,1065,493},5.74,0,6,-2.05,3.26,{height=136,curve=8,sway=true})
 l({24,498,473,995},1.82,-1.87,-1.35,-1.95,3.40)
 l({24,498,473,995},1.82,1.87,-1.35,-1.90,3.49,{mirror=true})
 l({1002,684,1533,928},4.62,0,9,-1.56,3.58)
 l({1002,684,1533,928},3.64,0,63,-1.87,3.66)
 pendants(l,{1094,26,1510,436},2.35,0,72,-1.54,3.75,
  {{1100,178,1267,292},{1234,348,1355,435},{1309,231,1507,359}},{eventMotion='skyFeather'})
 l({510,543,1008,963},1.53,0,29,-1.35,3.82,{turn=.22})
 finish()
end
do
 local l,finish=assembly('water')
 l({522,0,1013,521},5.74,0,-1.35,-2.54,3.28,{height=143,curve=8})
 l({30,532,475,980},1.60,-1.94,-1.35,-1.94,3.40)
 l({30,532,475,980},1.60,1.94,-1.35,-1.89,3.48,{mirror=true})
 l({987,680,1535,953},4.64,0,-1.35,-1.56,3.57,{flowing=true})
 local icicles=pendants(l,{1040,102,1525,455},3.60,0,75,-1.73,3.70,
  {{1060,170,1121,338},{1146,183,1220,378},{1241,205,1325,447},
   {1346,181,1416,375},{1446,169,1508,327}},
  {eventMotion='waterIcicle',gymDetail=true,gymHabitat='gym:water'})
 -- Separate thin droplet silhouettes reuse the badge's authored paper, with
 -- no bitmap edits. All four land in the rear basin behind the battle plane.
 for n,i in ipairs({1,5,2,4})do
  local tip=icicles[i]
  l({696,619,854,870},.20,tip.x,tip.y-9,-1.52,3.62+n*.02,
   {points={{765,619},{800,677},{845,751},{854,795},{841,833},{812,858},
     {777,870},{740,861},{711,837},{696,801},{701,767},{727,711}},
    height=9,ambientCard='waterPaperDrop',eventIndex=n,gymDetail=true,
    gymHabitat='gym:water',landingY=10,foldBaseY=-1.35})
 end
 l({585,588,942,945},1.52,0,38,-1.31,3.82,{mount='lid'})
 finish()
end
return layouts
