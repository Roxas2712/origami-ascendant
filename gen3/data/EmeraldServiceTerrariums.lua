-- Twelve illustrated objects per atlas, assembled as separate pop-up cards.
local layouts={}
local bounds={
 center={{78,13,360,378}, {389,54,792,376}, {839,16,1081,379}, {1146,37,1511,367}, {31,423,407,672}, {438,446,824,673}, {873,394,1125,675}, {1192,384,1466,665}, {31,772,423,961}, {474,668,733,976}, {798,787,1135,978}, {1185,688,1498,978}},
 shop={{37,12,367,403}, {398,137,813,403}, {849,55,1143,400}, {1194,54,1495,379}, {29,454,398,708}, {403,442,778,707}, {836,443,1126,686}, {1173,403,1490,701}, {40,820,397,979}, {427,749,771,976}, {802,766,1140,972}, {1184,693,1483,989}},
 harbor={{39,26,340,390}, {398,14,742,371}, {813,17,1103,373}, {1171,14,1512,394}, {21,456,383,685}, {401,459,777,675}, {795,407,1149,716}, {1278,391,1484,714}, {16,774,379,990}, {403,723,737,993}, {777,779,1144,981}, {1165,825,1526,937}},
 truck={{40,8,343,384}, {413,17,764,368}, {836,11,1102,393}, {1239,9,1469,381}, {15,406,389,691}, {429,433,754,689}, {789,408,1155,687}, {1281,399,1448,689}, {10,805,382,960}, {424,767,765,981}, {790,732,1173,989}, {1220,681,1502,1003}},
}
for _,kind in ipairs({'center','shop','harbor','truck'})do
 local list={};layouts[kind]=list;local ordinal=0
 local function card(part,w,x,y,z,h,extra)
  local b=bounds[kind][part];local start=3.12+ordinal*.032;ordinal=ordinal+1
  local d={texture='service-'..kind..'-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=start,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=math.min(.06,(start-3.12)*.10)}
  for k,v in pairs(extra or{})do d[k]=v end
  list[#list+1]=d;return d
 end
 if kind=='center'then
  card(1,1.62,-1.85,-1.35,-2.08,103)
  card(3,1.16,1.96,-1.35,-2.13,103,{signal=true})
  card(4,2.45,.16,83,-3.29,64,{mount='lid'})
  card(7,.80,-1.60,117,-3.20,29,{mount='lid',oscillate=.014,pivot=29})
  card(8,1.05,1.73,103,-3.16,39,{mount='lid',oscillate=.010,pivot=39,warm=true})
  card(2,2.70,0,-1.35,-2.35,80,{signal=true})
  card(5,1.48,-1.58,-1.35,-1.12,33)
  card(6,1.32,1.54,-1.35,-1.15,32)
  card(10,.82,2.63,-1.35,-.72,34,{sway=.012})
  card(12,.90,-2.64,-1.35,-.72,29)
  card(11,.79,-1.26,-1.35,2.68,12)
  card(10,.54,1.65,-1.35,2.45,24,{sway=.010})
 elseif kind=='shop'then
  card(1,1.63,-1.88,-1.35,-2.08,107)
  card(3,1.52,1.88,-1.35,-2.08,103)
  card(4,2.24,0,84,-3.27,64,{mount='lid'})
  card(7,.85,-1.67,109,-3.14,34,{mount='lid',oscillate=.012,pivot=34})
  card(8,.80,1.78,107,-3.14,35,{mount='lid',oscillate=.016,pivot=35})
  card(2,2.64,0,-1.35,-2.15,71,{signal=true})
  card(5,1.24,-1.64,-1.35,-1.15,30)
  card(6,1.04,1.69,-1.35,-1.21,35)
  card(12,.83,2.66,-1.35,-.70,32,{turn=.035,eventSway=.020,pivot=16})
  card(10,.89,-2.70,-1.35,-.72,24)
  card(11,.76,1.46,-1.35,2.52,22)
  card(10,.61,-1.28,-1.35,2.73,17)
 elseif kind=='harbor'then
  card(4,2.04,-1.60,-1.35,-1.88,109)
  local crane=card(3,1.74,1.63,-1.35,-2.03,124);table.remove(list)
  -- Hook and ropes are one thin hanging piece, separated below the pulley.
  -- Top beam, hook column and right frame exactly partition the source card.
  local b=bounds.harbor[3];local sx=1.74*30/(b[3]-b[1]);local sy=124/(b[4]-b[2])
  for i,r in ipairs({{813,17,1103,58},{813,58,861,373},{861,58,1103,373}})do
   local d={};for k,v in pairs(crane)do d[k]=v end
   d.points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}}
   d.width=(r[3]-r[1])*sx/30;d.heightScale=sy/sx
   d.x=crane.x+(r[1]+r[3]-b[1]-b[3])/2*sx/30
   d.y=crane.y+(b[4]-r[4])*sy;d.foldBaseY=crane.y;d.assemblyX=crane.x
   d.preservePaperPiece=true;d.shipCranePart=i
   if i==2 then d.eventMotion='dockHook';d.shipHabitat='ship:harbor';d.pivot=(r[4]-r[2])*sy;d.doubleSidedArt=true end
   list[#list+1]=d
  end
  card(2,2.69,.12,-10,-2.75,90,{oscillate=.007,pivot=40,floatY=.35})
  local gulls=card(7,2.19,-.19,112,-3.30,37,{mount='lid',driftX=3,floatY=.65,eventMotion='dockGull',shipHabitat='ship:harbor'})
  table.remove(list)
  -- Silhouettes cross each other's bounding boxes in the original sheet.
  -- Explicit non-overlapping source regions prevent a loose beak/wing from
  -- riding on a second bird when the hanging cards move independently.
  local regions={
   {{795,407},{1085,407},{1085,453},{1020,486},{1020,539},{795,539}},
   {{795,544},{994,544},{994,605},{1060,662},{1060,716},{795,716}},
   {{1020,468},{1149,468},{1149,657},{1060,628},{1020,608}},
  }
  local gx,gy=2.19*30/(1149-795),37/(716-407)
  for i,points in ipairs(regions)do
   local x0,y0,x1,y1=math.huge,math.huge,-math.huge,-math.huge
   for _,q in ipairs(points)do x0=math.min(x0,q[1]);y0=math.min(y0,q[2]);x1=math.max(x1,q[1]);y1=math.max(y1,q[2])end
   local d={};for k,v in pairs(gulls)do d[k]=v end
   d.points=points;d.width=(x1-x0)*gx/30;d.heightScale=gy/gx
   d.x=gulls.x+(x0+x1-795-1149)/2*gx/30;d.y=gulls.y+(716-y1)*gy
   d.foldBaseY=gulls.y;d.assemblyX=gulls.x;d.eventIndex=i;d.hangingFractions={.5};d.doubleSidedArt=true
   list[#list+1]=d
  end
  card(8,.87,-2.08,91,-3.07,49,{mount='lid',oscillate=.022,pivot=49})
  card(1,1.04,2.61,-17,-1.22,68,{warm=true})
  card(5,1.44,-1.71,-1.35,-1.23,39)
  card(6,1.43,1.07,-1.35,-1.29,38)
  card(12,2.25,.12,-6,-1.24,12,{mutedWater=true,driftX=1.6,floatY=.5})
  card(10,.68,-2.59,-1.35,-.71,27)
  card(11,.89,2.29,-1.35,1.70,20)
  card(12,1.44,-.17,-3,3.03,9,{mutedWater=true,driftX=.7,floatY=.4})
  card(11,.63,-2.24,-1.35,1.84,13)
 elseif kind=='truck'then
  card(1,1.63,-1.87,-1.35,-2.05,112,{eventSway=.008,pivot=0})
  card(4,1.40,1.87,-1.35,-2.03,105,{eventSway=.006,pivot=0})
  card(2,2.31,-.16,-1.35,-3.15,141)
  card(3,1.65,.51,-1.35,-2.47,106)
  card(7,3.38,0,106,-3.18,39,{mount='lid',oscillate=.012,pivot=39})
  card(8,.66,-1.73,79,-3.11,48,{mount='lid',oscillate=.025,pivot=48})
  card(8,.65,1.87,81,-3.13,47,{mount='lid',oscillate=.021,pivot=47})
  card(5,1.50,-1.61,-1.35,-1.23,39,{eventSway=.013,pivot=0})
  card(6,1.46,1.65,-1.35,-1.23,38)
  card(12,.72,2.66,-1.35,-.73,35,{eventSway=.018,pivot=0})
  card(10,.90,-2.61,-1.35,-.68,22)
  card(11,.95,-1.53,-1.35,2.52,23)
  card(10,.76,1.31,-1.35,2.70,18)
 end
 card(9,1.14,-2.37,-1.35,.54,18)
 card(9,1.14,2.37,-1.35,-.10,18)
end
return layouts
