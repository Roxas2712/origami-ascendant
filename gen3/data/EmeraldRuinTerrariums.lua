-- Separate paper flats sit inside the existing hinged ball and mirror lid.
local layouts={}
local bounds={
 memorial={{49,12,466,621},{522,13,1055,621},{1094,13,1515,617},{22,730,636,959},{686,654,1180,967},{1227,650,1450,996}},
 pillar={{44,24,479,649},{523,74,1061,660},{1148,47,1490,674},{26,774,516,959},{549,755,1059,982},{1077,758,1509,989}},
 mirage={{20,19,495,613},{575,38,1087,615},{1144,28,1512,617},{19,738,570,955},{616,722,1199,966},{1262,638,1436,1009}},
 sealed={{80,31,394,636},{510,61,1039,630},{1129,42,1478,633},{36,762,529,960},{573,709,1054,977},{1093,749,1500,968}},
 victory={{29,14,431,663},{499,238,1046,654},{1131,13,1518,662},{15,792,529,989},{567,801,1009,983},{1049,775,1509,984}},
 fossil={{31,48,478,655},{503,132,1049,624},{1085,94,1505,657},{25,772,554,945},{580,741,1024,945},{1032,775,1513,945}},
}
for _,kind in ipairs({'memorial','pillar','mirage','sealed','victory','fossil'})do
 local list={};layouts[kind]=list
 local warm=kind=='memorial';local wet=kind=='sealed'or kind=='victory'
 local function card(part,w,x,y,z,h,extra)
  local b=bounds[kind][part];local start=3.12+#list*.032
  local d={texture='ruin-'..kind..'-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=start,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=math.min(.06,(start-3.12)*.10)}
  for k,v in pairs(extra or{})do d[k]=v end
  list[#list+1]=d
 end
 if kind=='victory'then
  card(1,2.40,-1.59,-1.35,-2.88,135)
  card(3,2.22,1.75,-1.35,-2.62,128)
  card(2,3.83,.01,-1.35,-2.14,82,{mutedWater=true})
 elseif kind=='sealed'then
  card(2,3.32,.14,-1.35,-2.95,132)
  card(1,1.84,-1.92,-1.35,-2.35,119)
  card(3,1.92,1.91,-1.35,-2.20,119,{mutedWater=true})
 elseif kind=='mirage'then
  card(2,3.29,.23,-1.35,-2.90,120)
  card(1,2.41,-1.68,-1.35,-2.47,133)
  card(3,1.92,1.91,-1.35,-2.26,110)
 else
  card(2,3.57,.06,-1.35,-2.93,121,{warm=warm})
  card(1,2.25,-1.80,-1.35,-2.45,130,{warm=warm})
  card(3,2.08,1.85,-1.35,-2.24,122,{warm=warm})
 end
 if kind=='memorial'then
  card(6,.69,-1.47,98,-3.17,45,{mount='lid',oscillate=.018,pivot=45})
  card(6,.65,1.50,103,-3.15,42,{mount='lid',oscillate=.014,pivot=42,mirror=true})
 elseif kind=='mirage'then
  card(6,.49,-1.23,66,-2.31,53,{wave=.6})
  card(6,.39,1.72,73,-2.18,39,{wave=.45,mirror=true})
 elseif kind=='fossil'then
  card(6,2.73,-.73,36,-1.92,15,{driftX=2.1,floatY=.5,paperTint={1,1,1,.30}})
  card(6,1.68,1.28,20,-1.60,10,{driftX=1.5,floatY=.3,paperTint={1,1,1,.22},mirror=true})
 else
  card(6,3.25,-.69,125,-3.40,31,{mount='lid'})
  card(6,1.46,1.66,131,-3.43,23,{mount='lid',mirror=true})
 end
 card(1,.74,-2.74,-1.35,-1.11,46,{warm=warm})
 card(3,.71,2.73,-1.35,-1.05,43,{warm=warm,mutedWater=wet})
 card(5,1.48,-1.29,-1.35,-1.49,26,{warm=warm,mutedWater=wet})
 card(5,1.34,1.44,-1.35,-1.47,23,{warm=warm,mutedWater=wet,mirror=true})
 card(4,1.13,-2.37,-1.35,.54,18)
 card(4,1.13,2.37,-1.35,-.10,18)
 for _,p in ipairs({{-2.80,.95,.74,16},{2.77,.97,.73,16},{-2.04,2.07,.91,22},{2.04,2.08,.91,22},{-1.04,2.78,.68,15},{1.04,2.78,.68,15}})do
  card(5,p[3],p[1],-1.35,p[2],p[4],{warm=warm,mutedWater=wet,mirror=p[1]>0})
 end
end
return layouts
