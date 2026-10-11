-- Seafloor Cavern: independent slate flats around a visible paper-water channel.
local out={}
local function card(r,w,x,y,z,h,extra)
 local begin=3.12+#out*.022
 local d={texture='seafloor-layered-v2.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
  heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
  direction=z>1 and -1 or 1,foldOffset=math.min(.10,(begin-3.12)*.15)}
 for k,v in pairs(extra or{})do d[k]=v end
 if y>0 and d.mount~='lid'and not d.ambientCard then d.support=true end
 out[#out+1]=d;return d
end
local distant={14,50,402,398};local left={436,25,740,399}
local right={830,18,1104,416};local teeth={1165,96,1518,330}
local ledge={14,445,385,666};local boulders={399,443,770,664}
local water={790,518,1130,657};local crest={1144,475,1521,650}
local kelp={414,681,760,993};local shells={800,809,1122,978}
-- Offset silhouettes provide real openings and depth, not one closed rear arch.
card(distant,2.64,-.70,-1.35,-3.10,126)
card(distant,2.37,1.02,-1.35,-2.91,116,{mirror=true})
card(left,1.81,-1.91,-1.35,-2.38,117)
card(right,1.73,1.93,-1.35,-2.31,119)
card(ledge,1.12,-1.10,-1.35,-2.59,69)
card(ledge,1.17,1.16,-1.35,-2.42,60,{mirror=true})
for i,p in ipairs({{-1.67,116,.94,29},{.02,122,.86,27},{1.55,118,.87,30}})do
 card(teeth,p[3],p[1],p[2],-3.43,p[4],{mount='lid',mirror=i==2,oscillate=.007+i*.002})
end
-- Three separate receding water ribbons; foam and small waves fold independently.
for i,p in ipairs({{-.10,-1.35,-2.75,1.79,14},{.08,-1.35,-2.20,2.02,17},{0,-1.35,-1.65,2.80,20}})do
 card(water,p[4],p[1],p[2],p[3],p[5],{mutedWater=true,poolTier=i})
 card(crest,p[4]*.72,p[1]+.15,p[2]+1,p[3]+.075,p[5]*1.30,
  {mutedWater=true,wave=i*.9,crestTier=i})
end
card(boulders,.92,-1.43,-1.35,-1.37,32)
card(boulders,.90,1.49,-1.35,-1.43,31,{mirror=true})
card(kelp,.59,-1.35,-1.35,-1.30,29,{sway=true})
card(kelp,.57,1.43,-1.35,-1.30,26,{sway=true,mirror=true})
card(left,.57,-2.72,-1.35,-.75,39)
card(right,.59,2.72,-1.35,-.75,38)
-- Retain the proven flat top and native trainer foot heights.
for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
 card({25,762,548,1001},1.15,p[1],-1.35,p[2],18,{texture='deepcave-seafloor-kit.png'})
end
for i,p in ipairs({{-2.75,1.11,.65,24},{2.75,1.11,.65,23},{-2.02,2.08,.90,21},{2.02,2.08,.90,21},{-1.03,2.78,.69,16},{1.03,2.78,.69,16}})do
 card(i%2==0 and kelp or i==3 and boulders or shells,p[3],p[1],-1.35,p[2],p[4],{sway=i%2==0,mirror=p[1]>0})
end
-- Tiny paper droplets occasionally rise from the foremost breaking crest.
for i,p in ipairs({{-.52,15,-1.51},{.05,13,-1.51},{.50,14,-1.51}})do
 card({1257,674,1364,827},.093,p[1],p[2],p[3],4.5,{ambientCard='seafloorSpray'..i})
end
return {seafloor=out}
