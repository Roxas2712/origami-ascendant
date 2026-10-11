-- Independent cliff, water, ceiling and foreground flats in the existing shell.
local layouts={}
local foreground={meteor={19,18,501,504},seafloor={528,78,1028,501},marine={1061,19,1510,510},terra={17,517,508,990},granite={523,507,1022,991},origin={1031,522,1522,997}}
local bounds={
 meteor={{29,19,462,722},{534,59,1051,721},{1095,25,1509,718},{29,792,514,987},{551,753,1039,1000},{1080,758,1512,1004}},
 seafloor={{23,19,452,707},{480,69,1122,703},{1162,27,1516,703},{25,762,548,1001},{578,769,1067,989},{1073,745,1523,983}},
 marine={{19,22,440,658},{463,158,1076,651},{1098,25,1512,659},{21,739,508,994},{554,728,1080,977},{1088,710,1518,983}},
 terra={{15,12,506,668},{512,21,1027,692},{1047,14,1521,682},{17,744,514,1001},{533,752,1036,997},{1053,702,1514,994}},
 granite={{19,18,480,692},{504,17,1083,702},{1104,19,1516,697},{16,750,550,998},{583,729,1053,1000},{1079,750,1516,1001}},
 origin={{33,15,469,721},{502,33,1062,729},{1095,18,1512,731},{29,782,523,996},{552,778,1062,997},{1091,763,1506,997}},
}
for _,kind in ipairs({'meteor','seafloor','marine','terra','granite','origin'})do
 local list={};layouts[kind]=list
 local wet=kind=='marine'or kind=='seafloor';local lava=kind=='terra'
 local function card(part,w,x,y,z,h,extra)
  local b=type(part)=='table'and part or bounds[kind][part];local start=3.12+#list*.032
  local d={texture='deepcave-'..kind..'-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=start,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=math.min(.06,(start-3.12)*.10)}
  for k,v in pairs(extra or{})do d[k]=v end
  list[#list+1]=d
 end
 if kind=='meteor'then
  card(3,2.62,1.43,-1.35,-2.92,127)
  card(2,3.19,-.62,-1.35,-2.57,132,{flowing=true})
  card(1,1.84,-2.15,-1.35,-2.12,96)
 elseif kind=='marine'then
  card(1,2.40,-1.60,-1.35,-2.85,133,{flowing=true})
  card(3,2.30,1.78,-1.35,-2.67,127,{flowing=true})
  card(2,3.58,.06,-1.35,-2.20,79,{flowing=true})
 elseif kind=='terra'then
  card(1,2.34,-1.63,-1.35,-2.88,137,{lava=true})
  card(3,2.25,1.73,-1.35,-2.67,128,{lava=true})
  card(2,3.22,.11,-1.35,-2.20,91,{lava=true})
 else
  card(2,3.66,-.09,-1.35,-2.91,117,{flowing=wet})
  card(1,2.15,-1.91,-1.35,-2.36,116)
  card(3,2.10,1.93,-1.35,-2.20,113,{flowing=kind~='granite'})
 end
 card(6,3.49,-.53,127,-3.41,31,{mount='lid'})
 card(6,1.49,1.64,136,-3.43,22,{mount='lid',mirror=true})
 card(1,.79,-2.71,-1.35,-1.14,53,{lava=lava,flowing=kind=='marine'})
 card(3,.76,2.70,-1.35,-1.06,48,{lava=lava,flowing=kind~='granite'})
 card(5,1.57,-1.28,-1.35,-1.44,28,{lava=lava,flowing=kind~='granite'})
 card(5,1.39,1.45,-1.35,-1.48,24,{lava=lava,flowing=kind~='granite',mirror=true})
 card(4,1.15,-2.37,-1.35,.54,18)
 card(4,1.15,2.37,-1.35,-.10,18)
 for i,p in ipairs({{-2.69,.91,.73,25},{2.64,1.02,.74,24},{-2.04,2.08,.97,24},{2.04,2.08,.97,24},{-1.03,2.78,.73,17},{1.03,2.78,.73,17}})do
  local detail=i==1 or i==4 or i==5
  card(detail and foreground[kind]or 5,p[3],p[1],-1.35,p[2],p[4],{texture=detail and'deepcave-foreground.png'or nil,lava=lava,flowing=not detail and kind~='granite',mirror=p[1]>0,wave=not detail and kind=='marine'and .35 or nil,sway=detail and kind=='marine'})
 end
end
return layouts
