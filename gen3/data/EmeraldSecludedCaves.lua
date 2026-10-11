-- Separate card constructions for the two quiet optional caves. No full
-- backdrop sheet: silhouettes overlap at different authored depths.
local layouts={}
local atlas={
 artisan={left={20,5,332,441},right={359,5,646,441},back={654,42,1066,439},bank={1065,205,1530,439},
  tooth={75,448,257,754},root={439,440,586,780},boulders={673,485,1067,735},podium={1120,503,1532,720},
  rubble={22,803,333,1004},pebble={473,850,650,996},drop={885,820,991,988},tail={1210,726,1405,1004}},
 altering={left={4,3,372,375},right={426,0,725,378},back={746,124,1139,370},bank={1150,172,1535,373},
  tooth={125,383,260,710},root={411,380,692,730},boulders={717,451,1129,710},podium={1145,504,1532,712},
  rubble={0,733,400,1000},pebble={509,845,630,940},bat0={775,724,1072,997},bat1={1116,786,1535,995}},
}
for _,kind in ipairs({'artisan','altering'})do
 local out={};layouts[kind]=out
 local function card(name,w,x,y,z,h,extra)
  local r=atlas[kind][name];local begin=3.12+#out*.023
  local d={texture=kind..'-layered-v1.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
   direction=z>1 and -1 or 1,foldOffset=math.min(.10,(begin-3.12)*.15)}
  for k,v in pairs(extra or{})do d[k]=v end
  out[#out+1]=d
 end
 if kind=='artisan'then
  card('back',3.27,-.12,-1.35,-3.0,124)
  card('left',1.61,-1.81,-1.35,-2.63,127)
  card('right',1.62,1.79,-1.35,-2.36,120)
  card('left',1.26,2.43,-1.35,-1.96,94,{mirror=true})
  card('right',1.28,-2.45,-1.35,-1.81,97,{mirror=true})
  card('bank',1.36,-1.37,-1.35,-1.38,27)
  card('bank',1.45,1.40,-1.35,-1.33,29,{mirror=true})
  card('boulders',.96,-2.64,-1.35,-.83,27)
  card('boulders',.84,2.63,-1.35,-.91,23,{mirror=true})
  -- The brush tip rises from behind the right-hand shelf, then settles back.
  card('tail',.29,1.21,4,-1.59,17,{ambientCard='artisanTail'})
  for i=1,3 do card('drop',.083+i*.008,1.10+i*.06,30,-1.25+i*.015,3.3+i*.25,{ambientCard='artisanPaint'..i})end
 else
  card('back',3.05,-.94,-1.35,-3.02,114)
  card('back',2.69,1.02,-1.35,-2.94,121,{mirror=true})
  card('left',1.76,-2.03,-1.35,-2.35,113)
  card('right',1.59,2.04,-1.35,-2.08,119)
  card('right',1.10,-2.66,-1.35,-1.56,73,{mirror=true})
  card('left',1.05,2.69,-1.35,-1.44,72,{mirror=true})
  card('bank',1.46,-1.59,-1.35,-1.47,28)
  card('boulders',1.15,1.69,-1.35,-1.39,31)
  card('bank',.97,2.66,-1.35,-.60,21)
  card('boulders',.83,-2.67,-1.35,-.66,25)
  -- Two whole silhouettes alternate as animation frames, never simultaneously.
  card('bat0',.46,-1.50,77,-2.75,12.7,{ambientCard='alteringBat0'})
  card('bat1',.65,-1.50,77,-2.75,9.7,{ambientCard='alteringBat1'})
 end
 for i,x in ipairs({-1.85,-.96,-.10,.81,1.72})do
  local h=({29,23,32,21,27})[i]
  card('tooth',.34+(i%2)*.09,x,113+(i%2)*4,-3.36,h,{mount='lid',pivot=h-1,oscillate=.003,mirror=i%2==0,floatPhase=i})
 end
 for i,x in ipairs({-2.04,2.11})do card('root',.48,x,110,-3.02,37,{mount='lid',pivot=36,oscillate=.009,mirror=i==2})end
 for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do card('podium',1.15,p[1],-1.35,p[2],18)end
 for i,p in ipairs({{-2.77,1.0,.63,18},{2.77,1.0,.65,18},{-2.04,2.07,.77,22},{2.04,2.07,.75,21},{-1.05,2.78,.59,16},{1.05,2.78,.59,17}})do
  card('rubble',p[3],p[1],-1.35,p[2],p[4],{mirror=i%2==0})
 end
end
return layouts
