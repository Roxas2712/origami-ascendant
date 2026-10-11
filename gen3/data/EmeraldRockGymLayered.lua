-- A geology hall made of separate strata, specimen boards and hanging minerals.
local out={}
local rects={ochre={79,0,368,454},slate={437,0,724,454},board={807,13,1128,433},beam={1154,23,1520,412},
 shelf={8,466,458,738},podium={462,518,820,713},rubble={822,515,1228,721},mineral={1250,409,1483,742},
 pebble={119,802,314,972},dust={413,783,754,1007},lantern={846,703,1029,1010},badge={1226,741,1488,1012}}
local function card(name,w,x,y,z,h,extra)
 local r=rects[name];local begin=3.12+#out*.023
 local d={texture='rock-gym-layered-v3.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
  heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
  direction=z>1 and -1 or 1,foldOffset=math.min(.1,(begin-3.12)*.15)}
 for k,v in pairs(extra or{})do d[k]=v end
 out[#out+1]=d
end
card('beam',2.32,-1.52,-1.35,-3.02,132)
card('beam',2.32,1.52,-1.35,-3.01,132)
card('board',1.70,.02,-1.35,-2.66,105)
card('ochre',1.46,-1.75,-1.35,-2.42,116)
card('slate',1.51,1.78,-1.35,-2.34,112)
card('slate',1.11,-2.49,-1.35,-1.62,76,{mirror=true})
card('ochre',1.16,2.48,-1.35,-1.56,80,{mirror=true})
card('badge',1.05,0,126,-3.35,31,{mount='lid',pivot=30,oscillate=.009,metal=true})
for i,p in ipairs({{-1.77,117,25},{-.88,131,21},{1.65,120,27}})do
 card('mineral',.45+(i%2)*.08,p[1],p[2],-3.34,p[3],{mount='lid',pivot=p[3]-1,oscillate=.006,floatPhase=i,mirror=i%2==0})
end
for i,x in ipairs({-2.27,2.27})do card('lantern',.35,x,112,-2.98,28,{mount='lid',pivot=27,oscillate=.008,floatPhase=i,lamps=true})end
card('shelf',1.43,-1.56,-1.35,-1.17,31)
card('shelf',1.42,1.55,-1.35,-1.23,30,{mirror=true})
card('rubble',.95,-2.59,-1.35,-.58,20)
for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do card('podium',1.15,p[1],-1.35,p[2],18)end
for i,p in ipairs({{-2.77,1.0,.62,14},{2.77,1.0,.62,14},{-2.02,2.08,.78,18},{2.02,2.08,.78,18},{-.96,2.82,.60,13},{.96,2.82,.60,13}})do
 card('rubble',p[3],p[1],-1.35,p[2],p[4],{mirror=i%2==0})
end
for i=1,3 do card('pebble',.13+i*.012,-1.82+i*.04,.5,2.37-i*.025,3.2+i*.3,{ambientCard='roxannePebble'..i,pivot=1.6})end
card('dust',.38,-1.3,.5,2.42,8,{ambientCard='roxanneDust'})
return out
