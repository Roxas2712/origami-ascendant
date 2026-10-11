-- Marine/Terra: separate stone contours, fluid ribbons and hanging paper teeth.
local layouts={}
local function builder(kind)
 local out={};layouts[kind]=out
 return function(r,w,x,y,z,h,extra)
  local begin=3.12+#out*.022
  local d={texture=kind..'-layered-v2.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
   direction=z>1 and -1 or 1,foldOffset=math.min(.10,(begin-3.12)*.15)}
  for k,v in pairs(extra or{})do d[k]=v end
  -- UV mirroring also needs a mirrored asymmetric cut contour; otherwise
  -- the reflected atlas can leak a neighbouring cutout through the polygon.
  if d.mirror and #d.points>4 then
   local points={};local lo,hi=math.huge,-math.huge
   for _,p in ipairs(d.points)do lo=math.min(lo,p[1]);hi=math.max(hi,p[1])end
   for i=#d.points,1,-1 do local p=d.points[i];points[#points+1]={lo+hi-p[1],p[2]}end
   d.points=points
  end
  if y>0 and d.mount~='lid'and not d.ambientCard then d.support=true end
  out[#out+1]=d;return d
 end
end
do
 local card=builder('marine')
 local left={19,8,286,347};local right={420,9,704,350}
 local rear={774,73,1145,348};local teeth={1151,83,1525,325}
 local fall={49,357,254,683};local pool={351,443,762,622}
 local surf={772,499,1152,624};local ledge={1151,448,1526,624}
 local kelp={26,686,293,1007};local shells={384,747,754,964}
 local rock={802,684,1139,1006}
 card(rear,2.52,-1.19,-1.35,-3.16,105)
 card(rear,2.44,1.07,-1.35,-3.02,110,{mirror=true})
 card(left,2.03,-1.72,-1.35,-2.49,127)
 card(right,1.93,1.72,-1.35,-2.40,121)
 card(rock,1.18,-.83,-1.35,-2.68,67)
 card(rock,1.19,.82,-1.35,-2.53,61,{mirror=true})
 for i,p in ipairs({{-1.63,117,.94,27},{.02,124,.91,31},{1.56,118,.91,28}})do
  card(teeth,p[3],p[1],p[2],-3.43,p[4],{mount='lid',mirror=i==2,oscillate=.009})
 end
 -- Dry side shelves and separate ribbons keep each fall attached to rock.
 card(ledge,.75,-2.02,75,-2.27,17)
 card(ledge,.76,1.23,63,-2.18,17)
 card(fall,.51,-2.01,-1.35,-2.20,90,{flowing=true,fluidCard='fall-left'})
 card(fall,.51,1.24,-1.35,-2.10,77,{flowing=true,fluidCard='fall-right'})
 card(pool,3.41,.02,-1.35,-1.94,31,{mutedWater=true,fluidCard='deep-pool'})
 card(surf,1.68,-.99,-1.35,-1.52,18,{mutedWater=true,wave=.5,fluidCard='surf-left'})
 card(surf,1.59,1.00,-1.35,-1.50,19,{mutedWater=true,wave=2.4,mirror=true,fluidCard='surf-right'})
 card(rock,.65,-2.71,-1.35,-.78,38)
 card(rock,.63,2.72,-1.35,-.81,36,{mirror=true})
 for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
  card({21,739,508,994},1.15,p[1],-1.35,p[2],18,{texture='deepcave-marine-kit.png'})
 end
 card(kelp,.64,-2.73,-1.35,1.12,26,{sway=true})
 card(shells,.71,2.74,-1.35,1.14,17)
 card(surf,.83,-2.02,-1.35,2.08,16,{mutedWater=true,wave=1.1,fluidCard='surf-front-left'})
 card(kelp,.87,2.02,-1.35,2.08,23,{sway=true,mirror=true})
 card(shells,.73,-1.03,-1.35,2.78,13)
 card(surf,.76,1.03,-1.35,2.78,14,{mutedWater=true,wave=2.7,fluidCard='surf-front-right'})
 card(kelp,.38,-.56,-1.35,2.80,14,{sway=true})
 for i,p in ipairs({{-.63,5,-1.37},{.05,4,-1.37},{.70,5,-1.37}})do
  card({1244,685,1392,832},.12,p[1],p[2],p[3],4.6,{ambientCard='marineBubble'..i})
 end
end
do
 local card=builder('terra')
 local left={32,12,341,399};local right={423,7,745,406}
 local rear={761,68,1210,407};local teeth={1174,122,1519,366}
 local fall={46,399,279,751};local flow={310,499,772,748}
 local ledge={780,591,1252,727};local smoke={1284,385,1517,738}
 local rock={19,783,388,996};local vents={396,842,836,993}
 local rearPoints={{761,68},{1145,68},{1145,365},{1210,407},{761,407}}
 card(rear,2.57,-1.13,-1.35,-3.14,105,{points=rearPoints})
 card(rear,2.40,1.08,-1.35,-3.00,112,{points=rearPoints,mirror=true})
 card(rock,1.36,.02,-1.35,-2.88,78)
 card(left,1.66,-1.92,-1.35,-2.40,126)
 card(right,1.62,1.91,-1.35,-2.28,120)
 for i,p in ipairs({{-1.59,120,.93,29},{.04,125,.83,26},{1.60,118,.87,28}})do
  card(teeth,p[3],p[1],p[2],-3.43,p[4],{mount='lid',mirror=i==2,
   points={{1174,122},{1519,122},{1519,366},{1250,366},{1215,251}}})
 end
 card(ledge,1.03,-1.50,53,-2.19,23)
 card(ledge,1.04,1.53,37,-2.06,22)
 card(fall,.63,-1.50,-1.35,-2.12,70,{lava=true,fluidCard='lava-fall-left'})
 card(fall,.64,1.53,-1.35,-1.99,54,{lava=true,fluidCard='lava-fall-right',mirror=true})
 card(flow,2.77,0,-1.35,-1.67,27,{lava=true,fluidCard='lava-channel'})
 card(rock,1.28,-.70,-1.35,-2.29,60)
 card(rock,1.17,.77,-1.35,-2.17,51,{mirror=true})
 card(vents,.78,-1.54,-1.35,-1.36,24)
 card(vents,.71,1.48,-1.35,-1.32,20,{mirror=true})
 card(smoke,.31,-1.57,18,-1.39,23,{sway=true,oscillate=.013})
 card(smoke,.27,1.43,15,-1.36,20,{sway=true,oscillate=.016,mirror=true})
 card(rock,.76,-2.73,-1.35,-.73,30)
 card(rock,.72,2.73,-1.35,-.77,29,{mirror=true})
 for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
  card({17,744,514,1001},1.15,p[1],-1.35,p[2],18,{texture='deepcave-terra-kit.png'})
 end
 for i,p in ipairs({{-2.76,1.12,.69,23},{2.76,1.12,.69,22},{-2.01,2.08,.91,22},{2.01,2.08,.91,22},{-1.02,2.77,.70,15},{1.02,2.77,.70,15}})do
  card((i==3 or i==6)and flow or rock,p[3],p[1],-1.35,p[2],p[4],{mirror=p[1]>0,lava=i==3 or i==6,fluidCard=(i==3 or i==6)and'front-lava-'..i or nil})
 end
 for i,p in ipairs({{-1.39,20,-1.26},{-1.23,20,-1.27},{1.29,17,-1.24}})do
  card({837,755,948,992},.076,p[1],p[2],p[3],4.2,{ambientCard='terraEmber'..i})
 end
end
return layouts
