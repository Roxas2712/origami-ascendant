-- Flat room partitions, independent hanging details and foreground props.
-- The shared Pokeball shell and mirrored hinged lid remain behind them.
local layouts={}
local bounds={
 wreck={{44,7,496,669},{536,24,1016,667},{1076,7,1506,686},{11,723,559,1010},{580,716,1095,999},{1073,705,1517,1009}},
 liner={{33,71,451,584},{517,110,1021,584},{1083,71,1501,584},{28,764,490,940},{543,663,1039,934},{1102,665,1509,958}},
 hill={{14,28,528,638},{571,14,1014,634},{1072,58,1521,634},{33,769,544,988},{593,712,1072,976},{1161,668,1488,999}},
 puzzle={{28,25,484,615},{541,25,997,616},{1054,25,1504,615},{22,770,590,974},{614,667,1033,981},{1123,641,1483,995}},
}
for _,kind in ipairs({'wreck','liner','hill','puzzle'})do
 local list={};layouts[kind]=list;local ordinal=0
 local function card(part,w,x,y,z,h,extra)
  local b=bounds[kind][part];local start=3.12+ordinal*.032;ordinal=ordinal+1
  local d={texture='room-'..kind..'-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=start,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=math.min(.06,(start-3.12)*.10)}
  if kind=='wreck'and part==5 then d.points={{580,716},{1059,716},{1059,856},{1095,946},{1095,999},{580,999}}end
  if kind=='wreck'and part==6 then d.points={{1073,705},{1517,705},{1517,1009},{1150,1009},{1150,766},{1073,766}}end
  for k,v in pairs(extra or{})do d[k]=v end
  -- The atlas gutter is asymmetric here. Mirror the clipping polygon along
  -- with the renderer's UVs, otherwise neighboring waves leak into the sail.
  if kind=='wreck'and d.mirror and(part==5 or part==6)then
   local reflected={}
   for i=#d.points,1,-1 do local q=d.points[i];reflected[#reflected+1]={b[1]+b[3]-q[1],q[2]}end
   d.points=reflected
  end
  list[#list+1]=d;return d
 end
 -- Original cloth is partitioned once. The bar stays fixed and every lower
 -- strip pivots along its full upper edge; all parts share the opening hinge.
 local function cloth(w,x,y,z,h,mirror)
  local parent=card(6,w,x,y,z,h,{mount='lid',mirror=mirror});table.remove(list)
  local b=bounds[kind][6];local sx=w*30/(b[3]-b[1]);local sy=h/(b[4]-b[2])
  local joint=kind=='wreck'and 766 or 795
  local cuts=kind=='wreck'and{1150,1238,1335,1417,b[3]}or{b[1],1190,1255,1345,1418,b[3]}
  local function piece(x0,y0,x1,y1,moving,index)
   local d={};for k,v in pairs(parent)do d[k]=v end
   d.points={{x0,y0},{x1,y0},{x1,y1},{x0,y1}}
   d.width=(x1-x0)*sx/30;d.heightScale=sy/sx
   d.x=x+(x0+x1-b[1]-b[3])/2*sx/30*(mirror and -1 or 1)
   d.y=y+(b[4]-y1)*sy;d.foldBaseY=y;d.assemblyX=x
   d.rigidHanging=true;d.preservePaperPiece=true;d.hanging=not moving
   if moving then
    d.eventMotion='shipCloth';d.shipHabitat='ship:'..kind;d.eventIndex=index+(mirror and 5 or 0)
    d.pivot=(y1-y0)*sy;d.doubleSidedArt=true
   end
   list[#list+1]=d
  end
  piece(b[1],b[2],b[3],joint,false,0)
  for i=1,#cuts-1 do piece(cuts[i],joint,cuts[i+1],b[4],true,i)end
 end
 card(2,3.12,.04,-1.35,-2.95,123,{signal=kind=='hill',mutedWater=kind=='wreck',warm=kind=='liner'})
 card(1,2.34,-1.75,-1.35,-2.57,124,{flowing=kind=='liner'})
 card(3,2.26,1.82,-1.35,-2.31,120,{flowing=kind=='liner'})
 if kind=='puzzle'then
  card(6,.87,-1.30,106,-2.46,26,{spin=.11,pivot=13})
  card(6,.59,1.32,106,-2.22,18,{spin=-.16,pivot=9,mirror=true})
 elseif kind=='liner'or kind=='wreck'then
  cloth(1.52,-1.20,109,-3.37,31,false)
  cloth(1.31,1.35,113,-3.36,28,true)
 else
  card(6,1.52,-1.20,109,-3.37,31,{mount='lid',oscillate=.013,pivot=31,eventMotion=kind=='hill'and'hillBanner'or nil,eventIndex=1})
  card(6,1.31,1.35,113,-3.36,28,{mount='lid',oscillate=.010,pivot=28,mirror=true,eventMotion=kind=='hill'and'hillBanner'or nil,eventIndex=2})
 end
 card(5,1.10,-2.53,-1.35,-1.08,27,{mutedWater=kind=='wreck'})
 card(5,.98,2.57,-1.35,-1.09,25,{mirror=true,mutedWater=kind=='wreck'})
 card(5,1.17,-1.22,-1.35,-1.53,24,{mutedWater=kind=='wreck'})
 card(5,.89,1.46,-1.35,-1.56,19,{mirror=true,mutedWater=kind=='wreck'})
 card(4,1.14,-2.37,-1.35,.54,18)
 card(4,1.14,2.37,-1.35,-.10,18)
 for _,p in ipairs({{-2.80,.95,.66,15},{2.77,.97,.66,15},{-2.04,2.07,.78,20},{2.04,2.08,.78,20},{-1.04,2.78,.59,14},{1.04,2.78,.59,14}})do
  card(5,p[3],p[1],-1.35,p[2],p[4],{mutedWater=kind=='wreck',mirror=p[1]>0})
 end
end
return layouts
