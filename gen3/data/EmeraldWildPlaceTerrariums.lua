-- Overlapping vegetation, landmarks and sky pieces; ball and mirrors stay shared.
local layouts={}
local details={rainforest={14,24,529,569},ancient={528,69,1046,573},island={1051,50,1526,569},safari={14,582,521,1002},mountain={514,622,1024,997},memorial={1034,585,1519,1001}}
local bounds={
 rainforest={{16,17,516,733},{516,157,1028,691},{1034,15,1518,731},{23,790,518,994},{546,717,1013,1000},{1038,760,1515,1004}},
 safari={{18,19,583,646},{568,99,976,653},{1008,150,1517,664},{17,733,513,972},{553,697,1000,970},{1045,729,1512,961}},
 mountain={{17,13,476,713},{499,320,1090,697},{1117,14,1524,728},{12,779,550,992},{573,754,1027,995},{1053,792,1524,973}},
 ash={{40,44,464,668},{492,147,1037,667},{1058,80,1499,674},{27,771,521,967},{547,771,1036,965},{1062,774,1499,935}},
 memorial={{47,40,476,712},{508,386,1032,714},{1062,43,1498,716},{33,805,516,972},{548,775,1016,969},{1056,761,1502,982}},
 ancient={{20,12,521,669},{543,41,1021,661},{1056,12,1517,666},{14,751,519,962},{532,679,1037,989},{1054,700,1517,994}},
 island={{16,23,517,675},{548,184,1022,667},{1059,27,1524,678},{15,789,509,960},{540,738,1033,982},{1070,752,1519,975}},
}
for _,kind in ipairs({'rainforest','safari','mountain','ash','memorial','ancient','island'})do
 local list={};layouts[kind]=list
 local high=kind=='mountain'or kind=='ash';local tropical=kind=='rainforest'or kind=='ancient'or kind=='island'
 local function card(part,w,x,y,z,h,extra)
  local b=type(part)=='table'and part or bounds[kind][part];local start=3.12+#list*.032
  local d={texture='wildplace-'..kind..'-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=start,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=math.min(.06,(start-3.12)*.10)}
  for k,v in pairs(extra or{})do d[k]=v end
  list[#list+1]=d;return d
 end
 if high then
  card(2,5.57,.06,-1.35,-2.95,122.35)
  card(1,2.50,-1.55,-1.35,-2.39,110)
  card(3,2.30,1.68,-1.35,-2.24,105)
  card(6,2.21,-1.12,126,-3.38,25,{mount='lid',driftX=.9,oscillate=.008,pivot=24})
  card(6,1.23,1.56,131,-3.41,16,{mount='lid',driftX=.7,mirror=true})
 elseif kind=='memorial'then
  card(1,2.31,-1.55,-1.35,-2.86,133)
  card(3,2.21,1.70,-1.35,-2.67,126)
  card(2,3.07,.06,-1.35,-2.12,54)
  card({1092,761,1500,825},2.43,-1.02,33,-1.84,12,{driftX=2.4,floatY=.7,paperTint={1,1,1,.42}})
  card({1056,894,1502,982},1.69,1.46,17,-1.51,10,{driftX=1.5,floatY=.4,paperTint={1,1,1,.34}})
 else
  if kind=='ancient'then card(2,3.56,0,-1.35,-2.95,135)
  elseif kind=='safari'then
   local d=card(2,2.18,.61,-1.35,-2.76,122)
   d.points={{633,94},{922,94},{983,491},{983,661},{560,661},{560,491},{626,305}}
  elseif kind=='island'then card(2,2.23,.22,-1.35,-2.63,83)
  else card(2,3.26,.06,-1.35,-2.45,83,{flowing=true})end
  local d=card(1,2.47,-1.74,-1.35,-2.42,131)
  if kind=='safari'then d.points={{18,10},{590,10},{590,400},{519,436},{519,655},{18,655}}end
  card(3,2.39,1.80,-1.35,-2.23,126,{flowing=tropical})
  card(6,2.26,-1.43,123,-3.46,29,{mount='lid',oscillate=.014,pivot=28})
  card(6,1.60,1.63,129,-3.45,25,{mount='lid',oscillate=.010,pivot=24,mirror=true})
 end
 -- Independent middle foliage and foreground layers leave the actors clear.
 card(5,1.59,-1.19,-1.35,-1.53,32,{sway=not high,flowing=kind=='rainforest'})
 card(5,1.43,1.44,-1.35,-1.55,28,{sway=not high,mirror=true,flowing=kind=='rainforest'})
 card(4,1.12,-2.37,-1.35,.54,18)
 card(4,1.12,2.37,-1.35,-.10,18)
 if tropical then
  card(details[kind],.99,-2.62,-1.35,-.73,33,{texture='wildplace-details.png',sway=true})
  card(details[kind],.89,2.62,-1.35,-.86,29,{texture='wildplace-details.png',sway=true,mirror=true})
 end
 for i,p in ipairs({{-2.80,.95,.77,17},{2.77,.97,.75,17},{-2.07,2.04,.98,26},{2.05,2.07,.97,25},{-1.02,2.80,.70,18},{1.03,2.78,.70,18}})do
  local d=card(5,p[3],p[1],-1.35,p[2],p[4],{mirror=p[1]>0,sway=not high and kind~='memorial',flowing=kind=='rainforest'})
  if (i==2 or i==3 or i==6)and details[kind]then
   local b=details[kind];d.texture='wildplace-details.png';d.points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}};d.heightScale=p[4]/((b[4]-b[2])*p[3]*30/(b[3]-b[1]));d.sway=false
  end
 end
 if tropical or kind=='safari'then
  for i,p in ipairs({{-2.45,1.50},{2.39,1.54},{-.45,2.99},{.49,2.97}})do
   card(details[kind],.46,p[1],-1.35,p[2],12,{texture='wildplace-details.png',sway=true,mirror=i%2==0})
  end
 end
end
return layouts
