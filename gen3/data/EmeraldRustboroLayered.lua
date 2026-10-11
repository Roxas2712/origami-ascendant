-- Individual city facades, garden layers and suspended paper sky details.
local out={}
local rects={tower={16,8,403,410},house={420,60,760,407},gym={780,60,1190,409},ridge={1200,24,1534,420},
 wall={8,424,462,691},tree={470,405,758,716},podium={780,489,1163,692},hedge={1165,474,1535,695},
 cloud={30,730,483,1004},smoke={538,719,751,1012},lamp={907,696,1018,1011},banner={1190,724,1515,997}}
local function card(name,w,x,y,z,h,extra)
 local r=rects[name];local begin=3.12+#out*.024
 local d={texture='rustboro-layered-v3.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
  heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
  direction=z>1 and -1 or 1,foldOffset=math.min(.1,(begin-3.12)*.15)}
 for k,v in pairs(extra or{})do d[k]=v end
 out[#out+1]=d
end
card('ridge',2.22,-1.90,0,-3.10,108)
card('ridge',2.05,1.98,0,-3.06,104,{mirror=true})
card('tower',2.15,.02,-1.35,-2.81,133)
card('house',1.91,-1.67,-1.35,-2.30,89)
card('gym',2.02,1.72,-1.35,-2.18,85)
card('house',1.10,-2.47,-1.35,-1.60,57,{mirror=true})
for i,p in ipairs({{-1.86,129,.98,18},{-.61,137,.78,15},{.86,132,.95,18},{2.0,119,.82,16}})do
 card('cloud',p[3],p[1],p[2],-3.32,p[4],{mount='lid',pivot=p[4]-1,oscillate=.007,floatPhase=i,mirror=i%2==0})
end
for i,x in ipairs({-2.25,2.27})do card('banner',.68,x,100,-2.73,30,{mount='lid',pivot=29,oscillate=.012,floatPhase=i})end
card('tree',.94,-2.47,-1.35,-.72,47,{sway=true})
card('tree',1.02,2.46,-1.35,-.85,51,{sway=true,mirror=true})
card('wall',1.41,-1.41,-1.35,-1.17,26)
card('wall',1.25,1.40,-1.35,-1.10,24,{mirror=true})
card('lamp',.17,-2.50,-1.35,-.55,34,{lamps=true})
card('lamp',.17,2.50,-1.35,-.55,34,{lamps=true})
for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do card('podium',1.15,p[1],-1.35,p[2],18)end
for i,p in ipairs({{-2.75,1.10,.62,14},{2.75,1.10,.62,14},{-2.00,2.06,.82,17},{2.00,2.06,.82,17},{-.95,2.83,.59,13},{.95,2.83,.59,13}})do
 card('hedge',p[3],p[1],-1.35,p[2],p[4],{sway=true,mirror=i%2==0})
end
-- Emitted at the left townhouse chimney, in front of its roof plane.
for i=1,3 do card('smoke',.24,-2.22,85,-2.285,10,{ambientCard='rustboroSmoke'..i})end
return out
