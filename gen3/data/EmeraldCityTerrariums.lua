-- Location silhouettes are separate theatre flats, with their own bridges,
-- railings and foreground details. No finished facade is hidden behind them.
local layouts={treecity={},floating={},crater={}}
local function builder(kind)
 return function(sheet,r,width,x,y,z,begin,extra)
  local d={texture=kind..'-'..sheet..'.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=width,x=x,y=y,z=z,
   begin=begin,duration=.8,direction=z>1 and-1 or 1,foldOffset=begin<4 and math.min(.06,(begin-3.12)*.12)or 0}
  for k,v in pairs(extra or{})do d[k]=v end
  if d.height then d.heightScale=d.height/((r[4]-r[2])*width*30/(r[3]-r[1]));d.height=nil end
  if y>0 and d.mount~='lid'and not d.flowing and d.support~=false then d.support=true end
  layouts[kind][#layouts[kind]+1]=d
 end
end
do
 local card=builder('treecity')
 local houseL={11,21,542,641};local houseR={549,38,1022,641};local distant={1000,181,1519,578}
 local bridge={9,711,537,955};local canopy={546,687,1001,986};local walk={1028,744,1525,987}
 local podium={1,116,621,527};local rail={616,117,1195,543};local chime={1267,18,1454,592}
 local fern={3,550,545,988};local nest={546,630,1081,983};local berry={1084,584,1526,992}
 card('landscape',distant,4.54,.08,21,-2.72,3.12,{height=105,support=true,
  points={{1073,181},{1519,181},{1519,578},{1000,578},{1000,390},{1073,335}}})
 card('landscape',canopy,2.27,-1.34,118,-3.53,3.12,{height=38,mount='lid',oscillate=.016,pivot=38})
 card('landscape',canopy,1.75,1.46,124,-3.48,3.13,{height=31,mount='lid',mirror=true,oscillate=.013,pivot=31})
 card('landscape',houseL,2.76,-1.37,-1.35,-2.12,3.24,{height=116})
 card('landscape',houseR,2.50,1.46,-1.35,-2.07,3.32,{height=112,
  points={{549,38},{1022,38},{1022,277},{976,318},{969,641},{549,641}}})
 card('landscape',bridge,3.07,.01,37,-1.92,3.40,{height=25,support=true,wave=.4})
 card('details',chime,.42,.90,63,-1.75,3.44,{height=37,oscillate=.035,eventSway=.20,pivot=37,support=false})
 card('landscape',walk,2.87,-.02,-1.35,-1.39,3.54,{height=32})
 card('details',rail,1.56,-1.73,-1.35,-.98,3.61,{height=25})
 card('details',berry,1.17,1.86,-1.35,-.99,3.66,{sway=true,height=31})
 card('details',fern,1.13,-2.50,-1.35,-.19,3.72,{sway=true,height=31})
 card('details',fern,.93,2.55,-1.35,-.50,3.77,{sway=true,height=29,mirror=true})
 card('details',podium,1.10,-2.37,-1.35,.54,4.02,{height=19})
 card('details',podium,1.10,2.37,-1.35,-.10,4.06,{height=19})
 card('details',rail,1.25,-2.30,-1.35,1.37,4.12,{height=20})
 card('details',rail,1.23,2.30,-1.35,1.27,4.16,{height=19,mirror=true})
 card('details',fern,1.09,-1.97,-1.35,2.17,4.21,{sway=true,height=25})
 card('details',nest,1.08,1.86,-1.35,2.22,4.25,{height=19})
 card('details',berry,.60,-.73,-1.35,2.88,4.30,{sway=true,height=16})
 card('details',fern,.58,.65,-1.35,2.91,4.34,{sway=true,height=14})
end
do
 local card=builder('floating')
 local houseL={17,112,457,541};local houseR={478,139,1014,541};local distant={1030,307,1525,509}
 local walk={7,671,518,851};local wave={526,687,1021,845};local jetty={1029,639,1532,873}
 local podium={15,216,607,512};local rope={620,227,1079,506};local flag={1120,23,1470,515}
 local net={38,621,432,960};local foam={456,771,1036,950};local coral={1040,744,1522,964}
 card('landscape',distant,5.18,.01,32,-2.81,3.12,{height=59,flowing=true})
 -- The mirrored lid retains a separate suspended sky layer above the town.
 for i,p in ipairs({{-1.42,122,1.29,25},{1.53,132,.96,19}})do
  card('landscape',{475,552,859,790},p[3],p[1],p[2],-3.40,3.13+i*.018,
   {texture='route-coast-kit.png',imageWidth=1254,imageHeight=1254,height=p[4],mount='lid',driftX=.75,floatY=.18,floatPhase=i})
 end
 for i,p in ipairs({{875,846,1096,1035,-.62,106,.48,14},{866,1036,1080,1194,.82,102,.40,12}})do
  card('landscape',{p[1],p[2],p[3],p[4]},p[7],p[5],p[6],-2.98,3.19+i*.025,
   {texture='coast-botanical-v2.png',imageWidth=1254,imageHeight=1254,height=p[8],mount='lid',floatY=.4,floatPhase=i,
    eventMotion='harborBird',eventIndex=i,shoreHabitat='floating:'})
 end
 card('landscape',wave,4.95,-.05,0,-2.54,3.20,{height=46,wave=.9,flowing=true})
 card('landscape',houseL,2.66,-1.31,-1.35,-2.04,3.29,{height=76,floatY=.16})
 card('landscape',houseR,2.75,1.36,-1.35,-1.96,3.36,{height=70,floatY=.14})
 card('landscape',walk,3.43,0,-1.35,-1.45,3.44,{height=24,floatY=.12})
 card('details',flag,.67,-1.29,59,-2.01,3.48,{height=29,oscillate=.04,pivot=29,support=false})
 card('details',flag,.51,1.43,55,-1.92,3.51,{height=25,oscillate=.035,pivot=25,mirror=true,support=false})
 card('landscape',jetty,1.19,-2.47,-1.35,-.41,3.61,{height=20})
 card('landscape',jetty,1.21,2.47,-1.35,-.52,3.66,{height=20,mirror=true})
 card('details',podium,1.16,-2.37,-1.35,.54,4.02,{height=17})
 card('details',podium,1.16,2.37,-1.35,-.10,4.06,{height=17})
 card('details',foam,1.62,-2.35,-1.35,1.26,4.11,{height=14,wave=1.7,flowing=true})
 card('details',foam,1.56,2.32,-1.35,1.26,4.15,{height=13,wave=2.7,flowing=true,mirror=true})
 card('details',net,.85,-1.97,-1.35,2.12,4.20,{height=23})
 card('details',rope,.99,1.91,-1.35,2.14,4.24,{height=16})
 card('details',coral,1.13,-1.17,-1.35,2.68,4.29,{height=14})
 card('details',coral,.94,1.12,-1.35,2.69,4.33,{height=12,mirror=true})
 card('details',foam,.69,-.17,-1.35,3.05,4.36,{height=9,wave=3.1,flowing=true})
end
do
 local card=builder('crater')
 local houseL={5,82,541,514};local houseR={551,82,950,521}
 local terraceL={14,536,512,980};local terraceR={539,594,977,973};local lake={987,631,1526,974}
 local podium={6,324,560,564};local palm={623,61,997,563};local pots={1057,185,1527,564}
 local wall={13,637,569,951};local stairs={578,611,1090,952};local stream={1080,673,1525,964}
 -- Three independently hinged, overlapping contour cards retain the town's
 -- authored silhouette. The seam follows the cliff steps, not a straight slice.
 local function rimPart(r,points,z,begin)
  local width=(r[3]-r[1])*5.40/(1531-956)
  local x=.02+((r[1]+r[3])/2-(956+1531)/2)*5.40/(1531-956)
  card('landscape',r,width,x,-1.35,z,begin,{height=(r[4]-r[2])*128/(509-120),points=points})
 end
 rimPart({1179,120,1290,509},{{1179,120},{1290,120},{1290,331},{1283,349},{1290,460},{1290,509},{1179,509},{1194,430},{1195,350},{1179,300}},-2.91,3.12)
 rimPart({956,120,1218,509},{{956,120},{1218,120},{1218,286},{1192,310},{1210,360},{1218,509},{956,509}},-2.78,3.18)
 rimPart({1250,120,1531,509},{{1250,120},{1531,120},{1531,509},{1250,509},{1271,445},{1250,365},{1264,311}},-2.70,3.22)
 -- Reuse the existing hand-cut sky pieces in both land and lake variants.
 for i,p in ipairs({{-1.67,121,1.23,25},{1.61,128,.97,20},{-.12,137,.72,15}})do
  card('landscape',{475,552,859,790},p[3],p[1],p[2],-3.40,3.13+i*.018,
   {texture='route-coast-kit.png',imageWidth=1254,imageHeight=1254,height=p[4],mount='lid',driftX=.7,floatY=.22,floatPhase=i})
 end
 card('landscape',{875,846,1096,1035},.40,-.53,109,-3.08,3.21,
  {texture='coast-botanical-v2.png',imageWidth=1254,imageHeight=1254,height=11,mount='lid',driftX=1.4,floatY=.45,oscillate=.035})
 card('landscape',{866,1036,1080,1194},.34,.73,115,-3.01,3.25,
  {texture='coast-botanical-v2.png',imageWidth=1254,imageHeight=1254,height=10,mount='lid',driftX=1.1,floatY=.35,floatPhase=2,oscillate=.025})
 card('landscape',terraceL,2.44,-1.43,-1.35,-2.33,3.23,{height=77})
 card('landscape',terraceR,2.40,1.45,-1.35,-2.27,3.28,{height=68})
 card('landscape',houseL,2.24,-1.37,39,-2.22,3.34,{height=62,support=false})
 card('landscape',houseR,1.77,1.54,40,-2.19,3.39,{height=62,support=false})
 card('landscape',lake,2.90,.07,-1.35,-1.45,3.48,{height=29,flowing=true})
 card('details',stairs,1.38,-1.63,-1.35,-1.18,3.54,{height=23})
 card('details',stairs,1.22,1.68,-1.35,-1.18,3.59,{height=22,mirror=true})
 card('details',palm,1.03,-2.34,-1.35,-.99,3.65,{height=49,sway=true})
 card('details',palm,.89,2.40,-1.35,-1.10,3.70,{height=45,sway=true,mirror=true})
 card('details',pots,.70,-2.69,-1.35,-.08,3.76,{height=18,waterRole='trainerPot'})
 card('details',pots,.69,2.73,-1.35,-.21,3.81,{height=18,mirror=true,waterRole='trainerPot'})
 card('details',podium,1.16,-2.37,-1.35,.54,4.02,{height=14})
 card('details',podium,1.16,2.37,-1.35,-.10,4.06,{height=14})
 card('details',wall,1.16,-2.28,-1.35,1.53,4.12,{height=20,waterRole='rail'})
 card('details',wall,1.12,2.30,-1.35,1.43,4.16,{height=19,mirror=true,waterRole='rail'})
 card('details',pots,.64,-1.43,-1.35,2.54,4.22,{height=18,waterRole='frontPot'})
 card('details',pots,.63,1.53,-1.35,2.46,4.26,{height=17,mirror=true,waterRole='frontPot'})
 card('details',stream,1.35,.08,-1.35,2.72,4.31,{height=13,flowing=true})
end
-- Lake battles keep solid decorations on dry stone instead of floating vases
-- and walls on the water texture. Land keeps its wider promenade arrangement.
layouts.crater_water={}
for _,source in ipairs(layouts.crater)do
 local d={};for k,v in pairs(source)do d[k]=v end
 local side=d.x<0 and -1 or 1;local height
 if d.waterRole=='trainerPot'then
  d.x=side*2.72;d.y=8.5;d.z=side<0 and .54 or -.10;d.width=.34;height=9
 elseif d.waterRole=='frontPot'then
  d.x=side*.85;d.y=7.5;d.z=2.04;d.width=.42;height=10
 elseif d.waterRole=='rail'then
  d.x=side*1.0;d.y=7.5;d.z=-.80;d.width=.90;height=17
 end
 if height then
  local r=d.points;d.heightScale=height/((r[3][2]-r[1][2])*d.width*30/(r[3][1]-r[1][1]))
 end
 layouts.crater_water[#layouts.crater_water+1]=d
end
return layouts
