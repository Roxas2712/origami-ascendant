-- Independent paper flats, mounted inside the existing mirrored ball.
local layouts={}
local bounds={
 arena={{19,68,540,558},{511,48,1029,552},{996,68,1508,558},{33,666,613,943},{670,634,1115,925},{1209,588,1482,950}},
 dome={{17,110,495,605},{498,73,1040,626},{1041,104,1520,605},{18,696,510,927},{534,710,1006,921},{1045,724,1519,900}},
 factory={{27,53,512,606},{546,55,1003,599},{1033,42,1515,606},{28,692,602,969},{639,653,1072,970},{1143,617,1486,968}},
 palace={{16,36,486,537},{499,14,1053,535},{1064,82,1518,541},{21,706,520,959},{547,638,1070,953},{1075,600,1519,960}},
 pike={{31,79,587,523},{611,19,1056,519},{1086,78,1505,523},{33,654,717,962},{736,540,1047,973},{1160,542,1419,1002}},
 tower={{51,27,524,600},{562,54,981,602},{1022,35,1495,601},{43,714,666,951},{707,658,1140,950},{1197,623,1465,990}},
 pyramid={{18,13,533,563},{569,14,1063,562},{1102,21,1512,564},{18,712,663,963},{690,640,1133,978},{1172,585,1499,997}},
}
for _,kind in ipairs({'arena','dome','factory','palace','pike','tower','pyramid'})do
 local list={};layouts[kind]=list
 local function card(part,w,x,y,z,h,extra)
  local b=type(part)=='table'and part or bounds[kind][part];local start=3.12+#list*.035
  local d={texture='frontier-'..kind..'-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=start,duration=.80,
   direction=z>1 and-1 or 1,foldOffset=math.min(.06,(start-3.12)*.10)}
  if kind=='arena'then
   if part==1 then d.points={{19,68},{505,68},{505,190},{525,190},{525,403},{540,414},{540,558},{19,558}}
   elseif part==2 then d.points={{553,48},{986,48},{986,110},{1029,110},{1000,153},{940,198},{962,552},{577,552},{590,198},{534,153},{511,114},{553,114}}
   elseif part==3 then d.points={{1508,68},{1508,558},{996,558},{996,414},{1013,400},{1013,190},{1040,190},{1040,170}}end
  end
  if kind=='arena'and type(part)=='table'then
   if b[1]==670 then d.points={{670,634},{800,634},{800,776},{767,776},{767,925},{670,925}}
   elseif b[1]==997 then d.points={{1014,634},{1115,634},{1115,925},{1017,925},{1017,788},{997,788},{997,718}}end
  end
  for k,v in pairs(extra or{})do d[k]=v end
  list[#list+1]=d;return d
 end
 local electronic=kind=='dome'or kind=='factory'or kind=='tower'
 local palace=kind=='palace';local pyramid=kind=='pyramid'
 local centralHeight=kind=='pike'and 132 or palace and 132 or 118
 local center=card(2,3.0,0,-1.35,-2.80,centralHeight,{signal=electronic})
 if kind=='tower'then
  -- The door leaves are independent paper pieces. Cut their opening out of
  -- the facade, preserving the original artwork/UV scale around the frame.
  local unit=3*30/(981-562);local vertical=centralHeight/(602-54)
  local function slice(rect,z,extra)
   extra=extra or{};extra.begin=center.begin;extra.foldOffset=center.foldOffset;extra.foldBaseY=-1.35
   return card(rect,(rect[3]-rect[1])*unit/30,((rect[1]+rect[3])/2-771.5)*unit/30,
    -1.35+(602-rect[4])*vertical,z,(rect[4]-rect[2])*vertical,extra)
  end
  table.remove(list)
  slice({562,54,981,352},-2.80,{signal=true})
  slice({562,352,688,602},-2.80,{signal=true})
  slice({858,352,981,602},-2.80,{signal=true})
  -- Dark paper backing, sampled from the existing Pike doorway. It stays
  -- behind both moving leaves and does not paint over the doorway frame.
  slice({688,352,858,602},-2.81,{texture='frontier-pike-kit.png',
   points={{789,330},{875,330},{875,495},{789,495}},width=170*unit/30,
   heightScale=250*vertical/(165*170*unit/86),frontierDetail='towerRecess'})
  for i,rect in ipairs({{688,352,773,602},{773,352,858,602}})do
   slice(rect,-2.79,{eventMotion='frontierTowerDoor',eventIndex=i,frontierDetail='towerDoor'})
  end
 end
 card(1,2.45,-1.76,-1.35,-2.34,102,{signal=electronic})
 card(3,2.43,1.77,-1.35,-2.27,100,{signal=electronic,flowing=palace})
 -- Separate side details, sized as fixtures rather than miniature duplicate rooms.
 if palace then
  card({16,36,279,370},1.01,-2.57,10,-1.35,48,{sway=true})
  card({1287,84,1518,421},.99,2.61,9,-1.23,47,{sway=true})
 elseif pyramid then
  card(6,.57,-2.60,-1.35,-1.34,48,{signal=true})
  card(6,.56,2.61,-1.35,-1.24,47,{signal=true})
 elseif kind=='factory'then
  card({29,58,137,605},.51,-2.63,-1.35,-1.35,48)
  card({1438,141,1515,606},.40,2.63,-1.35,-1.25,47)
 elseif kind=='dome'then
  card({97,105,208,257},.56,-2.63,12,-1.35,33,{signal=true})
  card({1339,100,1450,265},.56,2.63,12,-1.25,33,{signal=true})
 else
  card(5,.95,-2.61,-1.35,-1.35,41,{signal=electronic,warm=kind=='pike'})
  card(5,.94,2.63,-1.35,-1.25,40,{signal=electronic,warm=kind=='pike',mirror=true})
 end
 if kind=='factory'then
  -- Rotor pivot is its centre; dimensions match the opening in the right bank.
  card(6,1.09,1.79,42,-2.235,33.3,{spin=.48,pivot=16.65})
  card(5,1.14,-1.45,-1.35,-1.69,31,{signal=true})
  card(5,.89,1.61,-1.35,-1.57,27,{signal=true,mirror=true})
 elseif kind=='dome'then
  card(6,2.96,0,116,-3.30,30,{mount='lid',sway=true})
  card(5,2.85,0,-1.35,-1.59,28,{signal=true})
 elseif palace then
  card(6,2.13,-1.02,114,-3.36,40,{mount='lid',sway=true,eventSway=.018,pivot=39})
  card(6,1.51,1.34,126,-3.39,32,{mount='lid',sway=true,mirror=true})
  card(5,1.38,-1.24,-1.35,-1.65,28,{sway=true})
  card(5,1.28,1.37,-1.35,-1.52,26,{sway=true,mirror=true})
 elseif pyramid then
  card(6,.62,-1.31,-1.35,-1.70,50,{signal=true})
  card(6,.58,1.38,-1.35,-1.60,44,{signal=true,mirror=true})
  card(5,1.22,-.2,-1.35,-1.53,27)
 else
  local width=kind=='arena'and .73 or .61
  card(6,width,-1.09,100,-3.31,43,{mount='lid',oscillate=.023,pivot=43,
   eventMotion=kind=='arena'and'frontierArenaBanner'or nil,eventIndex=1,frontierDetail=kind=='arena'and'arenaBanner'or nil})
  card(6,width,1.09,100,-3.32,43,{mount='lid',oscillate=.019,pivot=43,
   eventMotion=kind=='arena'and'frontierArenaBanner'or nil,eventIndex=2,frontierDetail=kind=='arena'and'arenaBanner'or nil})
  if kind~='pike'then card(5,2.23,0,-1.35,-1.54,35,{signal=electronic,sway=kind=='arena'})end
 end
 -- Side trainer positions are authored independently of the battle platform.
 card(4,1.15,-2.37,-1.35,.54,18)
 card(4,1.15,2.37,-1.35,-.10,18)
 for _,p in ipairs({{-2.49,-.69,.78,26},{2.48,-.67,.77,26},{-2.43,1.39,.82,25},{2.43,1.37,.82,25},{-1.48,2.43,.91,18},{1.48,2.43,.91,18}})do
  local part,h=5,p[4]
  -- Foreground uses small constituent props, not shrunken copies of the entire fixture.
  if p[2]>1 then
   if kind=='factory'then part={639,784,814,946};h=11
   elseif kind=='arena'then part=p[1]<0 and{670,634,800,925}or{997,634,1115,925};h=21
   elseif palace then part={547,655,784,953};h=23
   elseif kind=='tower'then part=p[1]<0 and{707,658,803,950}or{1064,696,1140,950};h=24
   elseif pyramid then part={866,810,1051,978};h=15
   end
  end
  local width=p[3]
  if kind=='tower'and p[2]>1 then width=h*(part[3]-part[1])/(part[4]-part[2])/30 end
  if pyramid and p[2]>1 then width=h*185/168/30 end
  local d=card(part,width,p[1],-1.35,p[2],h,{signal=electronic,warm=kind=='pike',sway=palace or kind=='arena',mirror=p[1]>0})
  if pyramid and p[2]>1 then
   -- Trace one complete fallen stone, excluding the sliced column above it.
   d.points={{927,849},{993,810},{1028,831},{1048,858},{1051,886},{1010,916},{989,956},{958,978},{866,978},{893,918}}
   if d.mirror then for _,point in ipairs(d.points)do point[1]=866+1051-point[1]end end
   d.frontierDetail='pyramidFallenStone'
  end
 end
 if palace or pyramid then
  card(5,.48,-.67,-1.35,2.99,11,{sway=palace})
  card(5,.47,.66,-1.35,3.01,11,{sway=palace,mirror=true})
 end
 local function accent(texture,rect,w,x,y,z,h,motion,i)
  return card(rect,w,x,y,z,h,{texture=texture,ambientCard=motion,eventIndex=i,frontierDetail=motion})
 end
 if kind=='dome'then
  for i=1,6 do
   accent('pavilion-details-v1.png',{841,683,1034,990},.16,(i%2==0 and 1 or -1)*(1.55+math.floor((i-1)/2)*.12),
    70+math.floor((i-1)/2)*5,-1.42,7,'frontierDomeRibbon',i)
  end
 elseif kind=='factory'then
  -- Steam starts at the two grilles in the central monitor facade.
  for i=1,3 do
   accent('volcanic-town-details-v1.png',{1233,26,1478,396},.40,i%2==1 and -.49 or .42,
    96,-2.77,18,'frontierFactorySteam',i)
  end
 elseif kind=='pyramid'then
  -- Small rolling flats follow the clear sand strip in front of the rubble.
  for i=1,3 do
   local d=accent('rock-gym-layered-v3.png',{119,802,314,972},.18,-1.60+(i-1)*.09,
    -2.0,2.64+(i-1)*.08,4.8,'frontierPyramidPebble',i)
   d.pivot=2.4
  end
 elseif kind=='pike'then
  for i,p in ipairs({{-2.61,-1.34,28},{2.63,-1.24,27},{-2.43,1.40,16},{2.43,1.38,16}})do
   accent('civic-details-v1.png',{1261,762,1444,957},.30,p[1],p[3],p[2],8.2,'frontierPikeLamp',i)
  end
 end
end
return layouts
