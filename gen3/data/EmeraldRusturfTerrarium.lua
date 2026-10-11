-- Rusturf's interrupted hand-dug passage: individual overlapping strata,
-- hanging roots/rock teeth, rough boulders and a small rolling rubble event.
local out={}
local rects={
 left={30,5,366,442},right={414,5,734,444},back={760,50,1182,440},timber={1190,70,1523,444},
 tooth={86,445,270,787},root={406,446,660,815},bank={690,520,1186,770},boulders={1190,503,1530,775},
 rubble={35,795,375,990},pebble={480,840,641,986},dust={800,800,1050,991},podium={1180,815,1525,1000},
}
local function card(name,w,x,y,z,h,extra)
 local r=rects[name];local begin=3.12+#out*.022
 local d={texture='rusturf-layered-v1.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
  heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
  direction=z>1 and -1 or 1,foldOffset=math.min(.10,(begin-3.12)*.15)}
 for k,v in pairs(extra or{})do d[k]=v end
 out[#out+1]=d
end
-- Keep the silhouette irregular; each fin occupies its own depth plane.
card('back',2.75,-.70,0,-3.07,117)
card('back',2.58,.92,0,-2.96,110,{mirror=true})
card('left',1.95,-1.89,-1.35,-2.49,125)
card('right',1.75,1.99,-1.35,-2.28,118)
card('right',1.42,-2.48,-1.35,-1.68,88,{mirror=true})
card('left',1.47,2.50,-1.35,-1.55,91,{mirror=true})
for i,x in ipairs({-1.93,-1.13,-.31,.55,1.36,2.03})do
 local h=({29,20,26,19,28,22})[i]
 card('tooth',.37+(i%2)*.10,x,114+(i%3)*3,-3.36,h,{mount='lid',pivot=h-1,oscillate=.003,floatPhase=i,mirror=i%2==0})
end
card('root',.63,-2.15,100,-2.95,40,{mount='lid',pivot=39,oscillate=.009})
card('root',.49,2.14,104,-2.95,34,{mount='lid',pivot=33,oscillate=.007,mirror=true})
card('bank',1.54,-1.57,-1.35,-1.38,34)
card('bank',1.32,1.55,-1.35,-1.25,30,{mirror=true})
card('timber',.67,2.38,-1.35,-.77,41)
card('boulders',.96,-2.56,-1.35,-.64,30)
for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do card('podium',1.15,p[1],-1.35,p[2],18)end
for i,p in ipairs({{-2.77,1.0,.69,18},{2.77,1.0,.69,18},{-2.04,2.07,.79,22},{2.04,2.07,.79,22},{-1.05,2.78,.60,17},{1.05,2.78,.60,17}})do
 card('rubble',p[3],p[1],-1.35,p[2],p[4],{mirror=i%2==0})
end
-- Along the apron outside the arena. They never cross a battler or Dig hole.
for i=1,3 do card('pebble',.11+i*.012,-1.82+i*.04,.5,2.37-i*.025,2.8+i*.3,{ambientCard='rusturfPebble'..i,pivot=1.5})end
card('dust',.35,-1.30,.5,2.33,8,{ambientCard='rusturfDust'})
return {rusturf=out}
