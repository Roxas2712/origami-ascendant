-- Individually hinged paper flats. Landmarks share materials, not whole scenes.
local layouts={}
local rects={
 volcanic={left={18,10,503,540},right={524,56,1008,541},back={1022,279,1523,546},cascade={17,594,523,975},ceiling={534,605,993,971},shelf={1021,702,1519,992},
  podium={8,201,580,491},feature={589,78,1210,496},instrument={1223,61,1528,498},rock={12,563,509,962},ribbon={514,686,1270,973},vent={1274,522,1521,973}},
 tidal={left={11,12,513,605},right={558,21,1006,613},back={1023,114,1532,581},cascade={9,643,518,1000},ceiling={527,663,1010,987},shelf={1024,710,1530,985},
  podium={24,151,502,494},salt={556,213,984,493},kelp={1048,86,1506,504},rock={11,545,519,939},ribbon={533,729,999,903},dry={1025,608,1522,939}},
 frost={left={28,20,502,641},right={526,19,968,641},back={995,113,1525,645},cascade={22,684,503,975},ceiling={526,732,981,937},shelf={991,833,1517,990},
  podium={22,204,533,486},crystal={602,104,940,486},drift={990,213,1523,487},rock={19,555,519,935},fringe={525,612,1004,915},pool={1000,691,1528,940}},
}
local function builder(key,kind)
 local list={};layouts[key]=list;local r=rects[kind]
 return function(sheet,part,width,x,y,z,height,extra)
  local b=r[part];local start=3.12+#list*.045
  local d={texture=kind..'-'..sheet..'.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=width,x=x,y=y,z=z,
   heightScale=height/((b[4]-b[2])*width*30/(b[3]-b[1])),begin=start,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=start<4 and math.min(.06,(start-3.12)*.12)or 0}
  for k,v in pairs(extra or{})do d[k]=v end
  if kind=='tidal'and part=='ribbon'then
   d.points={{533,881},{603,778},{743,733},{923,741},{999,879},{911,902},{738,898},{598,892}}
  end
  list[#list+1]=d
 end
end
for _,key in ipairs({'path','magma','volcano'})do
 local card=builder(key,'volcanic');local outside=key=='volcano'
 if outside then
  card('structure','back',5.52,0,-1.35,-2.77,109,{lava=true})
  card('structure','left',2.13,-1.90,-1.35,-2.33,64,{lava=true})
  card('structure','right',2.14,1.90,-1.35,-2.29,66,{lava=true})
  card('details','instrument',.88,.89,-1.35,-1.98,46,{lamps=true})
 else
  card('structure','right',3.17,.09,-1.35,-2.96,91,{lava=true,mirror=true})
  card('structure','left',3.35,-1.04,-1.35,-2.80,122,{lava=true})
  card('structure','right',3.09,1.22,-1.35,-2.69,115,{lava=true})
  card('structure','ceiling',3.54,-.57,110,-3.38,41,{mount='lid',lava=true})
  card('structure','ceiling',1.77,1.42,121,-3.43,28,{mount='lid',mirror=true,lava=true})
 end
 if key=='magma'then
  card('details','feature',3.73,.25,0,-2.09,69,{lamps=true})
  card('details','instrument',.56,-2.25,8,-1.58,36,{lamps=true})
  card('structure','cascade',1.64,-1.57,-1.35,-1.90,55,{lava=true})
 elseif outside then
  card('structure','cascade',2.35,-.42,-1.35,-1.90,53,{lava=true})
  card('details','vent',.76,-1.13,29,-2.55,43,{sway=true})
 else
  card('structure','shelf',2.76,.13,-1.35,-1.88,31,{lava=true})
  card('details','vent',.77,.64,26,-2.13,42,{sway=true})
 end
 card('details','ribbon',2.94,.02,-1.35,-1.43,24,{lava=true})
 card('details','rock',1.14,-2.36,-1.35,-.91,31,{lava=true})
 card('details','rock',1.03,2.48,-1.35,-1.02,30,{mirror=true,lava=true})
 card('details','podium',1.15,-2.37,-1.35,.54,18,{lava=true})
 card('details','podium',1.15,2.37,-1.35,-.10,18,{lava=true})
 card('details','rock',.86,-2.42,-1.35,1.46,24,{lava=true})
 card('details','rock',.84,2.47,-1.35,1.33,24,{mirror=true,lava=true})
 card('details','ribbon',1.29,-1.46,-1.35,2.43,13,{lava=true})
 card('details','ribbon',1.20,1.53,-1.35,2.38,12,{mirror=true,lava=true})
 card('details','rock',.62,-.68,-1.35,2.99,13,{lava=true})
 card('details','rock',.54,.66,-1.35,3.01,12,{mirror=true,lava=true})
end
for _,key in ipairs({'tide','salt'})do
 local card=builder(key,'tidal');local wet=key=='tide'
 card('structure','back',4.65,0,-1.35,-2.91,108)
 card('structure','left',2.53,-1.52,-1.35,-2.39,104)
 card('structure','right',2.31,1.65,-1.35,-2.27,97)
 card('structure','ceiling',3.10,-.61,115,-3.34,37,{mount='lid'})
 card('structure','ceiling',1.79,1.49,120,-3.39,26,{mount='lid',mirror=true})
 if wet then
  card('structure','cascade',2.73,-.10,-1.35,-1.88,50,{flowing=true})
  card('details','ribbon',3.12,0,-1.35,-1.43,18,{flowing=true,wave=.6})
 else
  card('details','dry',2.91,-.09,-1.35,-1.84,48)
  card('details','salt',.90,-.33,35,-1.85,22)
  card('details','salt',1.11,.72,-1.35,-1.40,20)
 end
 card('details','rock',1.14,-2.35,-1.35,-.98,28)
 card('details',wet and'kelp'or'salt',.91,2.42,-1.35,-.87,27,{sway=wet})
 card('details','podium',1.11,-2.37,-1.35,.54,18)
 card('details','podium',1.11,2.37,-1.35,-.10,18)
 card('details',wet and'kelp'or'salt',.76,-2.51,-1.35,1.44,25,{sway=wet})
 card('details','rock',.84,2.47,-1.35,1.35,23,{mirror=true})
 card('details',wet and'ribbon'or'salt',1.06,-1.51,-1.35,2.36,15,{flowing=wet,wave=wet and 1.4 or nil})
 card('details',wet and'kelp'or'dry',.84,1.63,-1.35,2.31,20,{sway=wet,mirror=true})
 card('details','salt',.59,-.69,-1.35,2.96,12)
 card('details',wet and'kelp'or'salt',.50,.65,-1.35,3.01,13,{sway=wet})
end
do
 local card=builder('ice','frost')
 card('structure','back',4.73,0,-1.35,-2.90,114,{frost=true})
 card('structure','left',2.41,-1.61,-1.35,-2.39,111,{frost=true})
 card('structure','right',2.32,1.66,-1.35,-2.26,106,{frost=true})
 card('structure','ceiling',3.14,-.54,121,-3.38,29,{mount='lid',frost=true})
 card('details','fringe',1.90,1.44,126,-3.41,24,{mount='lid',frost=true})
 card('structure','cascade',2.37,-.33,-1.35,-1.89,47,{frost=true})
 card('details','crystal',.90,1.29,-1.35,-1.71,37,{frost=true})
 card('details','pool',2.56,-.06,-1.35,-1.44,22,{frost=true})
 card('details','rock',1.14,-2.39,-1.35,-1.02,32,{frost=true})
 card('details','drift',1.13,2.47,-1.35,-.91,26)
 card('details','podium',1.15,-2.37,-1.35,.54,18,{frost=true})
 card('details','podium',1.15,2.37,-1.35,-.10,18,{frost=true})
 card('details','drift',1.03,-2.35,-1.35,1.42,22)
 card('details','rock',.82,2.47,-1.35,1.33,25,{frost=true,mirror=true})
 card('details','crystal',.59,-1.44,-1.35,2.43,23,{frost=true})
 card('details','drift',.89,1.48,-1.35,2.43,17)
 card('details','rock',.53,-.71,-1.35,2.93,12,{frost=true})
 card('details','crystal',.39,.66,-1.35,3.01,15,{frost=true})
end
return layouts
