-- Independent paper silhouettes, sampled from original alpha atlases.
-- The quiet backing never carries trees, clouds or other moving scenery.
local kits={
 desert={back={12,40,426,423},ridge={432,221,872,422},tree={872,98,1248,424},rail={9,604,467,758},cloud={481,535,879,754},grass={885,438,1240,789},podium={441,982,917,1187},front={907,971,1243,1175}},
 pond={back={27,32,413,435},ridge={429,244,878,433},tree={879,19,1240,440},rail={22,623,505,791},cloud={531,550,917,768},grass={967,445,1220,823},podium={451,1009,926,1192},front={932,857,1248,1222}},
 meadow={back={15,53,413,429},ridge={426,266,900,425},tree={900,30,1246,438},rail={13,530,418,747},cloud={431,503,877,748},grass={888,492,1246,747},podium={420,945,895,1150},front={905,867,1245,1165}},
 coast={back={13,49,437,480},ridge={438,310,937,485},tree={900,30,1248,486},rail={8,620,475,792},cloud={475,552,859,790},grass={892,553,1250,811},podium={433,1011,894,1198},front={894,918,1248,1236}},
 ash={back={27,52,429,441},smoke={624,72,862,277},ridge={452,263,882,444},tree={886,76,1245,444},rail={23,528,467,815},cloud={485,524,879,775},grass={938,536,1237,821},podium={457,979,901,1183},front={938,988,1236,1205}},
}
local layouts={}
for kind,r in pairs(kits)do
 for variant=1,(kind=='meadow'and 2 or 1)do
 local out={};layouts[variant==2 and'long_grass'or kind]=out
 local function card(part,width,x,y,z,begin,extra)
  local a=r[part]
  local d={texture='route-'..kind..'-kit.png',imageWidth=1254,imageHeight=1254,cutout=true,
   points={{a[1],a[2]},{a[3],a[2]},{a[3],a[4]},{a[1],a[4]}},width=width,x=x,y=y,z=z,
   begin=begin,duration=.8,direction=z>1 and-1 or 1,foldOffset=begin<4 and(begin-3.12)*.18 or 0}
  -- The palm crown extends left of its trunk. Avoid sampling the adjacent
  -- sea strip in the lower-left corner of this atlas cell.
  if kind=='coast'and part=='tree'then d.points={{900,30},{1248,30},{1248,486},{940,486},{940,308},{900,308}}end
  for k,v in pairs(extra or{})do d[k]=v end
  if d.height then d.heightScale=d.height/((a[4]-a[2])*width*30/(a[3]-a[1]));d.height=nil end
  out[#out+1]=d
 end
 -- Open-air silhouettes: the distant terrain itself defines the skyline.
 -- No generic backdrop plate. Independent clouds hang above trees and hills.
 if kind=='ash'then
  card('smoke',2.0,.55,74,-2.54,3.12,{height=58,floatY=.55,sway=true})
 else
  card('ridge',4.65,-.12,11,-2.70,3.12,{height=93,mirror=true,paperTint={.80,.89,.94,1}})
 end
 card('ridge',5.15,0,-1.35,-2.30,3.28,{height=kind=='ash'and 80 or 72})
 if kind=='desert'then
  card('cloud',1.20,1.32,4,-2.0,3.41,{driftX=5.4,floatY=.4})
 else
  card('cloud',1.68,-1.03,92,-2.03,3.41,{mount='lid',driftX=2.2,floatY=.3})
  card('cloud',1.02,1.72,107,-2.10,3.48,{mount='lid',driftX=1.4,floatY=.2,mirror=true})
 end
 card('tree',kind=='ash'and 2.15 or 2.58,-1.91,-1.35,-1.84,3.53,{sway=kind~='desert'})
 if kind~='desert'then card('tree',kind=='ash'and 1.80 or 2.24,2.06,-1.35,-1.88,3.59,{sway=true,mirror=true})else card('grass',1.74,1.90,-1.35,-1.83,3.59,{sway=true})end
 if kind=='coast'or kind=='pond'then
  card('rail',4.60,0,-1.35,-1.56,3.66,{height=23,wave=.7,flowing=true})
  card('rail',2.43,-1.05,-1.35,-1.28,3.72,{height=16,wave=2.4,flowing=true})
 else
  card('rail',2.43,-.92,-1.35,-1.42,3.67)
 end
 card('grass',1.00,-2.45,-1.35,-.27,3.77,{sway=true})
 card('grass',.90,2.49,-1.35,-.31,3.83,{sway=true,mirror=true})
 card('podium',1.12,-2.10,-1.35,.64,4.05)
 card('podium',1.12,2.12,-1.35,.20,4.15)
 if kind=='pond'then
  card('podium',1.08,-.82,-1.35,.98,4.18)
  card('podium',1.08,.84,-1.35,.88,4.23)
 end
 card('front',.88,-1.89,-1.35,2.04,4.27,{sway=true})
 card('front',.80,1.99,-1.35,1.92,4.34,{sway=true,mirror=true})
 card('grass',.63,-.69,-1.35,2.76,4.40,{sway=true})
 if variant==2 then
  card('grass',1.55,-1.27,-1.35,-1.05,3.73,{sway=true})
  card('grass',1.43,1.32,-1.35,-1.12,3.79,{sway=true,mirror=true})
 end
 end
end
return layouts
