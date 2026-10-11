-- Irregular paper contours leave gaps between the distant terrain cards.
-- Small foreground botany and fossils never fill the native battle footprints.
local layouts={}
for _,kind in ipairs({'desert','ash'})do
 local out={};layouts[kind]=out
 local function card(tex,r,width,x,y,z,begin,extra)
  local d={texture=tex,imageWidth=1254,imageHeight=1254,cutout=true,
   points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=width,x=x,y=y,z=z,
   begin=begin,duration=.8,direction=z>1 and-1 or 1,foldOffset=begin<4 and math.min(.11,(begin-3.12)*.18)or 0}
  for k,v in pairs(extra or{})do d[k]=v end
  if d.height then d.heightScale=d.height/((r[4]-r[2])*width*30/(r[3]-r[1]));d.height=nil end
  out[#out+1]=d
 end
 local function piece(...)card(kind..'-layered-v2.png',...)end
 if kind=='desert'then
  local mesa={0,20,430,430};local dune={433,168,841,425};local ridge={841,185,1253,425}
  local ruin={0,436,431,805};local cactus={438,435,835,810}
  local grass={10,864,435,1202};local fossil={441,879,838,1202}
  piece(mesa,3.45,-1.01,-1.35,-2.80,3.12,{height=118,paperTint={.93,.89,.81,1}})
  card('route-desert-kit.png',{481,535,879,754},1.31,1.22,120,-3.02,3.16,{height=22,mount='lid',floatY=.25,floatPhase=.6,driftX=1.8})
  card('route-desert-kit.png',{481,535,879,754},.93,-1.50,134,-3.17,3.20,{height=15,mount='lid',floatY=.18,floatPhase=2.1,driftX=1.1,mirror=true})
  piece(ridge,3.93,.68,-1.35,-2.59,3.19,{height=71})
  piece(dune,4.75,.15,-1.35,-2.27,3.28,{height=48})
  piece(ruin,2.38,-1.88,-1.35,-1.86,3.40,{height=77})
  piece(cactus,1.95,1.96,-1.35,-1.91,3.49,{height=70,sway=true})
  piece(ridge,2.60,.07,-1.35,-1.49,3.57,{height=17})
  piece(grass,1.03,-1.35,-1.35,-1.10,3.68,{height=23,sway=true})
  piece(fossil,.97,1.34,-1.35,-1.07,3.75,{height=19})
  piece(cactus,.90,-2.51,-1.35,-.24,3.82,{height=29,sway=true})
  piece(grass,.87,2.51,-1.35,-.31,3.88,{height=24,sway=true,mirror=true})
  card('route-desert-kit.png',{441,982,917,1187},1.12,-2.10,-1.35,.64,4.05)
  card('route-desert-kit.png',{441,982,917,1187},1.12,2.12,-1.35,.20,4.15)
  piece(grass,1.10,-2.24,-1.35,1.57,4.23,{height=23,sway=true})
  piece(fossil,1.03,2.18,-1.35,1.57,4.29,{height=22})
  piece(fossil,.88,-1.49,-1.35,2.35,4.33,{height=17,mirror=true})
  piece(grass,.74,.89,-1.35,2.75,4.39,{height=16,sway=true})
  piece({867,850,1236,1222},.60,0,-1.35,-.84,3.95,{height=16,pivot=8,ambientCard='tumbleweed'})
 else
  local volcano={0,78,464,399};local ridge={474,174,889,395}
  local tree={0,421,459,869};local bare={456,421,844,868}
  local grass={0,900,424,1220};local log={429,952,850,1220}
  piece(volcano,4.54,.20,-1.35,-2.83,3.12,{height=128})
  piece(ridge,3.64,-.94,-1.35,-2.33,3.24,{height=54})
  piece(ridge,2.90,1.32,-1.35,-2.10,3.32,{height=41,mirror=true})
  piece(tree,2.53,-1.97,-1.35,-1.85,3.42,{height=98,sway=true})
  piece(bare,2.12,2.05,-1.35,-1.88,3.50,{height=91,sway=true,
   points={{456,421},{844,421},{844,655},{813,713},{796,868},{456,868}}})
  piece({820,510,1253,870},1.62,.36,-1.35,-1.68,3.59,{height=51,warm=true,
   points={{873,510},{1253,510},{1253,870},{820,870},{820,710},{873,640}}})
  -- Individually hung smoke wisps follow the lid rather than a painted sheet.
  piece({891,72,1055,379},.72,-.25,112,-2.94,3.16,{height=34,mount='lid',floatY=.42,floatPhase=.4,driftX=1.2,
   points={{891,72},{1042,72},{1042,260},{1020,280},{1020,350},{975,375},{891,379}}})
  piece({1053,35,1215,282},.67,.59,130,-3.10,3.19,{height=25,mount='lid',floatY=.34,floatPhase=1.7,driftX=1.4})
  piece({980,284,1240,432},.92,1.47,115,-2.91,3.22,{height=18,mount='lid',floatY=.28,floatPhase=2.6,driftX=1.0,
   points={{1045,284},{1240,284},{1240,432},{980,432},{999,402},{1019,380},{1024,352}}})
  piece(grass,1.17,-1.20,-1.35,-1.13,3.70,{height=26,sway=true})
  piece(log,1.06,1.39,-1.35,-1.11,3.77,{height=20})
  piece(grass,.96,-2.48,-1.35,-.23,3.83,{height=25,sway=true,mirror=true})
  piece(grass,.87,2.53,-1.35,-.29,3.90,{height=24,sway=true})
  card('route-ash-kit.png',{457,979,901,1183},1.12,-2.10,-1.35,.64,4.05)
  card('route-ash-kit.png',{457,979,901,1183},1.12,2.12,-1.35,.20,4.15)
  piece(log,1.18,-2.14,-1.35,1.68,4.23,{height=23})
  piece(grass,1.03,2.20,-1.35,1.64,4.28,{height=25,sway=true})
  piece(grass,.76,-1.20,-1.35,2.53,4.34,{height=17,sway=true,multi={x=-1.6}})
  piece(log,.85,1.09,-1.35,2.58,4.40,{height=13,mirror=true})
 end
end
return layouts
