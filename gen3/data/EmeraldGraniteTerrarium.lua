-- Granite Cave: open irregular paper rims reveal separate darker strata.
local out={}
local function card(r,w,x,y,z,h,extra)
 local begin=3.12+#out*.024
 local d={texture='granite-layered-v2.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},
  width=w,x=x,y=y,z=z,heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),
  begin=begin,duration=.8,direction=z>1 and -1 or 1,foldOffset=math.min(.10,(begin-3.12)*.15)}
 for k,v in pairs(extra or{})do d[k]=v end
 out[#out+1]=d;return d
end
local wall={27,10,410,438};local ladder={442,21,702,439};local rim={712,12,1181,443}
local inner={1199,60,1528,440};local dark={20,464,390,725};local teeth={768,485,1143,724}
local slabs={1163,538,1531,727};local boulders={17,762,375,998};local fern={396,784,613,998}
local mineral={1152,792,1531,991}
-- Five separate hanging teeth: no connecting ceiling strip.
for i,r in ipairs({{393,478,478,692},{481,489,538,655},{541,492,594,634},{596,479,666,685},{673,477,741,650}})do
 local h=({34,25,21,32,26})[i]
 card(r,.38+(i%2)*.10,-1.76+(i-1)*.87,112+(i%2)*5,-3.36,h,{mount='lid',oscillate=.004,pivot=h-1,floatPhase=i})
end
card(dark,3.88,.05,4,-3.20,123)
card(inner,3.91,.05,2,-2.94,123)
card(rim,4.60,-.19,-1.35,-2.57,132)
card(wall,1.87,-2.01,-1.35,-2.01,108)
card(ladder,1.44,2.13,-1.35,-1.79,105)
card(teeth,1.68,-1.01,-1.35,-1.50,47)
card(slabs,1.22,1.25,-1.35,-1.42,26)
card(boulders,.77,-2.70,-1.35,-.62,29)
card(mineral,.82,2.72,-1.35,-.70,27)
for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
 card({16,750,550,998},1.15,p[1],-1.35,p[2],18,{texture='deepcave-granite-kit.png'})
end
card(fern,.59,-2.79,-1.35,1.06,21,{sway=true})
card(slabs,.78,2.74,-1.35,1.10,16)
card(boulders,.90,-2.03,-1.35,2.10,24)
card(mineral,.85,2.03,-1.35,2.12,21)
card(fern,.53,-1.07,-1.35,2.77,19,{sway=true})
card(boulders,.67,1.05,-1.35,2.80,17)
card({615,854,657,982},.21,-.14,-1.35,2.97,12,{sway=true})
for i,r in ipairs({{848,783,979,888},{997,793,1095,882},{847,890,965,987}})do
 card(r,.12+(i-1)*.015,-1.97+i*.043,8,.8-i*.033,2.8+i*.35,{ambientCard='granitePebble'..i,pivot=1.5})
end
return {granite=out}
