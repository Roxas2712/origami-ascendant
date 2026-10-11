-- Separate cave/tree/shrub bases, Navel Rock and submerged ship paper layers.
-- Reuses the original hinged ball shell; no shell geometry is part of these atlases.
local layouts={}
local bounds={
 base_cave={{17,12,493,633},{524,18,1046,638},{1079,19,1517,632},{16,798,525,982},{557,700,1078,983},{1155,644,1455,982}},
 base_wood={{18,26,509,681},{535,80,1017,678},{1042,80,1518,681},{26,803,565,959},{609,715,1092,935},{1130,712,1505,962}},
 base_garden={{11,22,486,656},{505,24,1025,676},{1036,23,1525,662},{13,746,521,993},{557,708,1021,998},{1049,665,1515,994}},
 navel_sky={{20,33,464,694},{516,128,1109,692},{1153,92,1514,694},{25,787,624,983},{666,780,1038,978},{1066,783,1513,934}},
 navel_tide={{24,17,482,703},{516,16,1021,703},{1064,16,1521,703},{32,766,506,982},{549,771,1012,990},{1050,749,1508,988}},
 submerged_wreck={{28,31,483,688},{528,34,1037,678},{1086,20,1510,688},{44,800,638,977},{684,706,1055,999},{1189,688,1420,1003}},
}
for _,kind in ipairs({'base_cave','base_wood','base_garden','navel_sky','navel_tide','submerged_wreck'})do
 local list={};layouts[kind]=list;local ordinal=0
 local wet=kind=='navel_tide'or kind=='submerged_wreck'
 local function card(part,w,x,y,z,h,extra)
  local b=bounds[kind][part];local start=3.12+ordinal*.032;ordinal=ordinal+1
  local d={texture='baseevent-'..kind..'-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=start,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=math.min(.06,(start-3.12)*.10)}
  for k,v in pairs(extra or{})do d[k]=v end
  list[#list+1]=d;return d
 end
 -- Partition the original hanging artwork, including its fixed crossbar.
 -- UV scale and assembly hinge remain shared; no painted copy sits behind a
 -- moving piece. Only the lower paper strips swing at their own top joint.
 local function hanger(w,x,y,z,h,mirror)
  local parent=card(6,w,x,y,z,h,{mount='lid',mirror=mirror})
  table.remove(list)
  local b=bounds[kind][6];local sx=w*30/(b[3]-b[1]);local sy=h/(b[4]-b[2])
  local joint=kind=='base_cave'and 724 or kind=='base_wood'and 776 or 782
  local cuts=kind=='base_cave'and{b[1],1223,1390,b[3]}or
   kind=='base_wood'and{b[1],1265,1361,b[3]}or
   {b[1],1145,1190,1247,1324,1375,1431,b[3]}
  local key=kind=='base_cave'and'cave:base'or kind=='base_wood'and'interior:wood'or'interior:garden'
  local function piece(x0,y0,x1,y1,moving,index)
   local d={};for k,v in pairs(parent)do d[k]=v end
   d.points={{x0,y0},{x1,y0},{x1,y1},{x0,y1}}
   d.width=(x1-x0)*sx/30;d.heightScale=sy/sx
   d.x=x+((x0+x1-b[1]-b[3])/2)*sx/30*(mirror and -1 or 1)
   d.y=y+(b[4]-y1)*sy;d.foldBaseY=y;d.assemblyX=x
   d.rigidHanging=true;d.preservePaperPiece=true;d.baseDetail=true
   d.hanging=not moving and y0==b[2]
   if moving then
    d.eventMotion='basePaperFringe';d.baseHabitat=key;d.eventIndex=index+(mirror and 3 or 0)
    d.pivot=(y1-y0)*sy;d.doubleSidedArt=true
   end
   list[#list+1]=d
  end
  piece(b[1],b[2],b[3],joint,false,0)
  for i=1,#cuts-1 do
   local moving=kind~='base_cave'or(i>1 and i<#cuts-1)
   piece(cuts[i],joint,cuts[i+1],b[4],moving,i)
  end
 end
 card(2,3.30,.03,-1.35,-2.97,kind=='navel_sky'and 113 or 127,{mutedWater=wet,lamps=kind=='base_wood'})
 card(1,2.32,-1.80,-1.35,-2.56,123,{mutedWater=kind=='navel_tide'})
 card(3,2.22,1.86,-1.35,-2.27,118,{mutedWater=kind=='navel_tide',warm=kind=='base_cave'})
 if kind=='submerged_wreck'then
  card(6,.66,-2.47,-1.35,-1.35,53,{sway=.025})
  card(6,.59,2.42,-1.35,-1.14,46,{sway=.020,mirror=true})
 elseif kind=='navel_sky'then
  card(6,2.03,-1.10,132,-3.38,22,{mount='lid',driftX=1.3,eventMotion='navelCloud',eventIndex=1,navelHabitat='cave:sky'})
  card(6,1.33,1.49,140,-3.39,16,{mount='lid',driftX=.8,mirror=true,eventMotion='navelCloud',eventIndex=2,navelHabitat='cave:sky'})
 elseif kind=='navel_tide'then
  card(6,1.55,-1.21,110,-3.37,29,{mount='lid'})
  card(6,1.35,1.43,116,-3.36,27,{mount='lid',mirror=true})
 else
  hanger(kind=='base_cave'and .72 or 1.40,-1.19,111,-3.37,32,false)
  hanger(kind=='base_cave'and .59 or 1.17,1.46,117,-3.36,27,true)
 end
 card(5,1.16,-2.52,-1.35,-1.02,25,{mutedWater=wet})
 card(5,.94,2.55,-1.35,-1.04,23,{mirror=true,mutedWater=wet})
 card(5,.78,-1.36,-1.35,-1.56,17,{mutedWater=wet})
 card(5,.67,1.30,-1.35,-1.55,15,{mirror=true,mutedWater=wet})
 card(4,1.14,-2.37,-1.35,.54,18)
 card(4,1.14,2.37,-1.35,-.10,18)
 for _,p in ipairs({{-2.83,.91,.60,16},{2.77,1.06,.65,17},{-2.04,2.03,.86,24},{2.04,2.02,.75,21},{-1.05,2.77,.55,14},{1.06,2.77,.62,16}})do
  card(5,p[3],p[1],-1.35,p[2],p[4],{mirror=p[1]>0,mutedWater=wet,sway=kind=='base_garden'and .006 or nil})
 end
 if kind=='navel_sky' then
  for i,p in ipairs({{-1.66,8,2.39},{1.61,12,2.35}})do
   local d=card(5,.42,p[1],p[2],p[3],7.6,{ambientCard='navelFeather',eventIndex=i,navelHabitat='cave:sky',doubleSidedArt=true})
   -- Trace only the golden feather, excluding its painted rock and shadow.
   d.points={{839,877},{855,860},{874,848},{900,838},{945,824},{937,842},{923,855},{900,868},{872,878},{848,881}}
   d.heightScale=7.6/((881-824)*d.width*30/(945-839))
  end
 elseif kind=='navel_tide'then
  for i,p in ipairs({{-1.42,18,2.55},{1.43,20,2.55},{-1.50,17,2.59},{1.50,18,2.59}})do
   local d=card(5,.13,p[1],p[2],p[3],5.8,{texture='gym-water-layers.png',ambientCard='navelDrop',eventIndex=i,navelHabitat='cave:tide',doubleSidedArt=true,landingY=-1.95})
   d.points={{765,619},{800,677},{845,751},{854,795},{841,833},{812,858},{777,870},{740,861},{711,837},{696,801},{701,767},{727,711}}
   d.heightScale=5.8/((870-619)*d.width*30/(854-696))
  end
 end
end
return layouts
