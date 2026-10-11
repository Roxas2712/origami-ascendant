-- Bespoke story-location props in the shared mirrored shell.
local layouts={}
local bounds={
 space={{34,28,541,627},{582,6,886,657},{952,43,1507,608},{32,753,594,958},{620,697,1091,972},{1136,624,1480,965}},
 weather={{38,47,518,667},{555,47,1045,670},{1068,34,1519,670},{38,796,524,971},{576,693,1114,974},{1174,701,1470,968}},
 electric={{16,11,447,643},{466,41,1062,635},{1074,39,1522,638},{13,751,590,970},{607,695,1099,976},{1150,636,1492,984}},
 regirock={{18,8,463,593},{509,71,1034,596},{1089,13,1519,596},{19,693,487,928},{503,637,1102,950},{1254,606,1401,1015}},
 regice={{31,17,393,691},{459,20,1078,686},{1136,11,1500,691},{10,734,492,989},{514,718,1086,996},{1107,724,1527,978}},
 registeel={{15,11,430,663},{479,79,1067,658},{1121,8,1521,660},{23,750,573,970},{609,707,1089,975},{1167,690,1473,967}},
}
for _,kind in ipairs({'space','weather','electric','regirock','regice','registeel'})do
 local list={};layouts[kind]=list
 local function card(part,w,x,y,z,h,extra)
  local b=type(part)=='table'and part or bounds[kind][part];local start=3.12+#list*.032
  local d={texture='story-'..kind..'-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=start,duration=.80,
   direction=z>1 and-1 or 1,foldOffset=math.min(.06,(start-3.12)*.10)}
  for k,v in pairs(extra or{})do d[k]=v end
  list[#list+1]=d;return d
 end
 local ruins=kind:sub(1,4)=='regi';local icy=kind=='regice'
 if kind=='space'then
  -- The model and its empty stand must be separate artwork: cutting the
  -- original combined silhouette would carry part of the plinth into the air.
  card({612,168,1471,507},1.90,.07,-1.35,-2.92,13.5,{texture='space-test-model-v1.png',storyDetail='rocketStand'})
  card({81,10,514,995},1.90,.07,9.3,-2.915,131.5,{texture='space-test-model-v1.png',eventMotion='spaceModelLift',storyDetail='rocket',begin=3.12,foldBaseY=-1.35,foldOffset=0})
  for i=1,3 do
   card({606,573,1459,989},.63,.07,10.0,-2.89,9.2,{texture='space-test-model-v1.png',ambientCard='spaceModelSteam',eventIndex=i,storyDetail='rocketSteam'})
  end
  card(1,2.50,-1.68,-1.35,-2.43,116,{signal=true})
  card(3,2.77,1.54,-1.35,-2.25,116)
  card({137,35,157,188},.10,-1.90,101,-2.43,16)
  card(6,.71,-1.90,114,-2.415,21.3,{spin=.22,pivot=10.65})
  card(5,1.43,-1.26,-1.35,-1.51,32,{signal=true})
  card(5,1.36,1.35,-1.35,-1.44,30,{signal=true,mirror=true})
 elseif kind=='weather'then
  card(1,2.47,-1.62,-1.35,-2.71,124,{rain=true})
  card(2,2.71,.29,-1.35,-2.38,99,{signal=true})
  card(3,2.22,1.96,-1.35,-2.19,107)
  card({41,145,77,564},.10,-1.74,114,-2.685,13)
  card(6,.69,-1.74,120,-2.66,20,{spin=.64,pivot=10,eventMotion='weatherGustRotor',storyDetail='windRotor'})
  for i=1,3 do
   card({69,44,488,504},.22,-2.53,79+i*8,-2.69,7.2,{texture='nature-events-v1.png',ambientCard='weatherWindowLeaf',eventIndex=i,storyDetail='windLeaf'})
  end
  -- Separate front mullions occlude the outdoor leaves. Their texture scale
  -- and fold hinge match the rear window exactly throughout unfolding.
  for _,r in ipairs({{38,47,84,667},{472,47,518,667},{196,94,215,600},{339,94,355,600},
   {84,47,472,94},{84,157,472,189},{84,469,472,497},{84,570,472,667}})do
   card(r,2.47*(r[3]-r[1])/480,(-48.6+((r[1]+r[3])/2-278)*74.1/480)/30,
    -1.35+(667-r[4])*124/620,-2.68,(r[4]-r[2])*124/620,
    {storyDetail='windowFrame',begin=3.12,foldBaseY=-1.35,foldOffset=0})
  end
  card(5,1.59,-1.53,-1.35,-1.48,35,{sway=true})
  card(5,.97,1.86,-1.35,-1.43,30,{sway=true,mirror=true})
 elseif kind=='electric'then
  card(2,3.46,.02,-1.35,-2.87,118,{signal=true})
  card(1,2.09,-1.97,-1.35,-2.31,112,{signal=true})
  card(3,2.10,1.99,-1.35,-2.21,110,{signal=true})
  card(6,1.41,.02,35.5,-2.835,45,{spin=.39,pivot=22.5})
  card(5,1.49,-1.56,-1.35,-1.47,30,{signal=true})
  card(5,1.43,1.56,-1.35,-1.41,29,{signal=true,mirror=true})
 else
  card(2,3.58,0,-1.35,-2.89,110,{frost=icy})
  card(1,2.14,-1.75,-1.35,-2.43,126,{frost=icy})
  card(3,2.11,1.78,-1.35,-2.27,121,{flowing=icy})
  card(1,.86,-2.64,-1.35,-1.48,55,{frost=icy})
  card(3,.86,2.64,-1.35,-1.35,51,{flowing=icy})
  card(5,1.45,-1.26,-1.35,-1.68,29,{flowing=icy})
  card(5,1.35,1.43,-1.35,-1.55,27,{flowing=icy,mirror=true})
  if icy then
   card(6,2.31,-.71,127,-3.39,30,{mount='lid',frost=true})
   card(6,1.43,1.32,132,-3.40,22,{mount='lid',frost=true})
  elseif kind=='regirock'then
   card(6,.28,-1.29,58,-2.32,53,{sway=true})
  else
   card(6,1.62,.19,108,-3.39,38,{mount='lid',oscillate=.009,eventSway=.018,pivot=37,metal=true})
  end
 end
 card(4,1.15,-2.37,-1.35,.54,18)
 card(4,1.15,2.37,-1.35,-.10,18)
 for _,p in ipairs({{-2.51,-.72,.76,26},{2.48,-.66,.77,25},{-2.47,1.40,.85,24},{2.47,1.35,.85,24},{-1.51,2.42,.98,18},{1.51,2.42,.98,18}})do
  local part,h=5,p[4];local texture
  if p[2]>1 and kind=='weather'then part=p[1]<0 and{513,60,990,494}or{519,522,1019,955};h=23;texture='story-small-props.png'
  elseif p[2]>1 and kind=='space'then part=p[1]<0 and{17,115,503,467}or{29,630,500,940};h=15;texture='story-small-props.png'
  elseif p[2]>1 and kind=='electric'then part=p[1]<0 and{1022,103,1501,509}or{1050,573,1508,945};h=20;texture='story-small-props.png'
  end
  -- The Space Center has four trainers during the Steven encounter. Put
  -- the side consoles behind their rear podiums and the low equipment in
  -- the gap between the two rows, rather than across either trainer's feet.
  local multi=kind=='space'and p[2]<2 and {z=p[2]<0 and -1.50 or .10}or nil
  card(part,p[3],p[1],-1.35,p[2],h,{texture=texture,flowing=icy,signal=not ruins and kind~='weather',sway=kind=='weather',mirror=p[1]>0,multi=multi})
 end
end
return layouts
