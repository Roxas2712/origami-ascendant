-- Twelve distinct paper components per atlas, composed individually.
local layouts={}
local bounds={
 devon={{107, 7, 298, 352}, {425, 7, 726, 352}, {791, 79, 1146, 346}, {1227, 13, 1458, 348}, {21, 435, 374, 652}, {411, 411, 770, 676}, {829, 381, 1094, 666}, {1225, 365, 1486, 684}, {23, 821, 398, 974}, {455, 731, 784, 974}, {865, 723, 1086, 990}, {1169, 691, 1510, 942}},
 lab={{75, 15, 346, 356}, {417, 57, 726, 350}, {783, 41, 1158, 352}, {1259, 25, 1476, 366}, {27, 449, 394, 684}, {433, 365, 742, 694}, {797, 365, 1096, 690}, {1131, 403, 1506, 682}, {47, 717, 354, 970}, {417, 741, 768, 968}, {819, 757, 1120, 958}, {1199, 689, 1496, 972}},
 hall={{121, 9, 274, 364}, {375, 35, 866, 358}, {903, 9, 1060, 364}, {1145, 9, 1512, 376}, {25, 433, 392, 672}, {417, 435, 826, 670}, {845, 389, 1172, 710}, {1215, 375, 1490, 674}, {29, 779, 454, 974}, {553, 707, 666, 1000}, {841, 747, 1150, 990}, {1307, 687, 1422, 1014}},
}
for _,kind in ipairs({'devon','lab','hall'})do
 local list={};layouts[kind]=list
 local function card(part,w,x,y,z,h,extra)
  local b=bounds[kind][part];local start=3.12+#list*.032
  local d={texture='research-'..kind..'-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=start,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=math.min(.06,(start-3.12)*.10)}
  for k,v in pairs(extra or{})do d[k]=v end
  list[#list+1]=d
  return d
 end
 -- Separate moving paper discs from their static housings. Source pixels
 -- stay untouched; these meshes use the same atlas scale and fold hinge.
 local function disc(parent,cx,cy,radius,name)
  local b=parent.points;local x0,y0,x1,y1=b[1][1],b[1][2],b[3][1],b[3][2]
  local sx=parent.width*30/(x1-x0);local sy=sx*parent.heightScale
  local d={};for k,v in pairs(parent)do d[k]=v end
  d.points={};for i=0,47 do local a=i*math.pi/24;d.points[#d.points+1]={cx+radius*math.cos(a),cy+radius*math.sin(a)}end
  d.width=radius*2*sx/30;d.x=parent.x+(cx-(x0+x1)/2)*sx/30
  d.y=parent.y+(y1-cy-radius)*sy;d.z=parent.z+.022
  d.pivot=radius*sy;d.foldBaseY=parent.y;d.hanging=false;d.assemblyX=parent.x
  d.signal=nil;d.lamps=nil;d.spin=nil;d.oscillate=nil
  d.eventMotion=name;d.researchDetail=true;d.researchHabitat=kind=='hall'and'league:hall'or'industrial:'..kind
  list[#list+1]=d;return d
 end
 if kind=='devon'then
  card(1,1.10,-2.31,-1.35,-2.65,126,{signal=true})
  card(2,1.95,-.85,-1.35,-2.82,105,{lamps=true})
  card(3,2.05,.86,-1.35,-2.46,74,{signal=true})
  card(4,1.35,2.29,-1.35,-2.09,96)
  local fan=card(7,1.03,-.02,122,-3.34,32,{mount='lid',rigidHanging=true})
  disc(fan,962,526,106,'devonFanRotor')
  card(12,1.55,.93,104,-3.25,32,{mount='lid',signal=true})
  card(8,1.03,2.63,-1.35,-1.24,59)
  card(5,1.72,-1.62,-1.35,-1.26,34,{signal=true})
  card(6,1.52,.65,-1.35,-1.53,38)
  card(10,.90,-2.66,-1.35,1.27,23)
  card(11,.62,2.68,-1.35,1.11,26)
  card(10,.78,-1.38,-1.35,2.67,20)
  card(11,.55,1.55,-1.35,2.49,23)
 elseif kind=='lab'then
  card(1,1.83,-1.87,-1.35,-2.47,100)
  card(4,1.13,2.06,-1.35,-2.73,112)
  card(7,1.76,.11,91,-3.31,60,{mount='lid',oscillate=.008,pivot=60})
  card(2,1.92,-.23,-1.35,-2.69,65,{signal=true})
  card(3,1.70,1.22,-1.35,-1.92,55)
  card(6,1.05,-2.58,-1.35,-1.38,61,{sway=.009})
  local shelf=card(8,1.88,-1.22,-1.35,-1.42,43)
  disc(shelf,1439,468,46,'labGlobeDisc')
  card(5,1.14,2.50,-1.35,-.98,32)
  card(12,.63,2.55,-1.35,1.21,32,{signal=true})
  card(10,.84,-2.72,-1.35,1.24,17)
  card(11,.68,-1.33,-1.35,2.68,15)
  card(10,.72,1.46,-1.35,2.55,15)
  card(6,.66,2.20,-1.35,1.97,34,{sway=.012})
 else
  card(1,.81,-2.03,-1.35,-2.52,135,{signal=true})
  card(3,.85,2.04,-1.35,-2.49,135,{signal=true})
  card(4,4.28,0,48,-3.30,99,{mount='lid',oscillate=.004,pivot=99})
  card(7,1.36,0,103,-3.15,43,{mount='lid',warm=true})
  card(8,.58,0,83,-3.12,18,{mount='lid',oscillate=.025,pivot=9,signal=true})
  local recorder=card(2,3.16,0,-1.35,-2.68,74,{signal=true})
  -- Six team-record windows receive individual paper stars in sequence.
  for i,cx in ipairs({470,530,590,650,710,770})do
   local x=(cx-(375+866)/2)*3.16/(866-375)
   local y=-1.35+(358-249)*74/(358-35)-4.7
   card(8,.285,x,y,-2.65,9.4,{ambientCard='hallRecordStar',eventIndex=i,
    researchDetail=true,researchHabitat='league:hall',assemblyX=recorder.x,begin=recorder.begin,
    foldBaseY=-1.35,foldOffset=recorder.foldOffset,pivot=4.7})
  end
  card(5,1.44,-1.94,-1.35,-1.44,32)
  card(6,1.48,1.91,-1.35,-1.29,32,{signal=true})
  card(12,.29,-2.56,98,-3.19,43,{mount='lid',oscillate=.012,pivot=43})
  card(12,.29,2.56,98,-3.19,43,{mount='lid',oscillate=.010,pivot=43})
  card(10,.31,-2.86,-1.35,.83,25,{signal=true})
  card(10,.31,2.86,-1.35,.78,25,{signal=true})
  card(11,.60,-1.84,-1.35,2.32,23)
  card(11,.60,1.84,-1.35,2.32,23)
  card(10,.26,-.95,-1.35,2.92,21,{signal=true})
  card(10,.26,.95,-1.35,2.92,21,{signal=true})
 end
 -- Trainer bases share their authored anchors and responsive scenery scale.
 card(9,1.14,-2.37,-1.35,.54,18)
 card(9,1.14,2.37,-1.35,-.10,18)
end
return layouts
