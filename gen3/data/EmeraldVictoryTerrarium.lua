-- Victory Road: layered cave recess, separate stairs/ladder and a rope bridge.
local out={}
local function card(r,w,x,y,z,h,extra)
 local begin=3.12+#out*.024
 local d={texture='victory-layered-v2.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},
  width=w,x=x,y=y,z=z,heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),
  begin=begin,duration=.8,direction=z>1 and -1 or 1,foldOffset=math.min(.10,(begin-3.12)*.15)}
 for k,v in pairs(extra or{})do d[k]=v end
 out[#out+1]=d;return d
end
local rim={12,14,453,490};local stairs={468,8,810,493};local ladder={829,13,1150,494}
local recess={1160,23,1524,489};local bridge={18,545,433,730};local stream={453,563,902,752}
local teeth={918,517,1147,755};local fern={1181,528,1525,750};local rocks={30,796,377,1007}
local mushrooms={440,775,737,1001};local roots={1238,767,1446,1009}
-- The lid raises individual suspended cards, with clear gaps between them.
for i,p in ipairs({{-1.72,119,.79,35},{-.14,114,.68,32},{1.51,123,.72,30}})do
 card(teeth,p[3],p[1],p[2],-3.38,p[4],{mount='lid',mirror=i==2,floatPhase=i})
end
card(roots,.38,-2.36,101,-3.13,32,{mount='lid',oscillate=.008,pivot=31})
card(roots,.42,2.34,105,-3.10,35,{mount='lid',oscillate=.006,pivot=34,mirror=true})
card(recess,4.20,.05,-1.35,-3.16,126)
card(rim,4.77,-.11,-1.35,-2.80,139)
card(stream,2.46,.04,-1.35,-2.39,52,{mutedWater=true})
card(stairs,1.99,-1.89,-1.35,-2.14,113)
card(ladder,1.87,1.90,-1.35,-1.99,111)
card(bridge,3.02,.02,44,-1.76,29,{oscillate=.006,pivot=26})
card(rocks,1.08,-1.40,-1.35,-1.31,24)
card(fern,.79,1.39,-1.35,-1.38,23,{sway=true})
card(rocks,.66,-2.75,-1.35,-.71,24)
card(fern,.67,2.76,-1.35,-.78,23,{sway=true})
for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
 card({15,792,529,989},1.13,p[1],-1.35,p[2],18,{texture='ruin-victory-kit.png'})
end
card(fern,.63,-2.81,-1.35,1.08,22,{sway=true})
card(mushrooms,.70,2.76,-1.35,1.09,19)
card(rocks,.97,-2.02,-1.35,2.09,24)
card(fern,.91,2.04,-1.35,2.10,22,{sway=true})
card(mushrooms,.67,-1.08,-1.35,2.77,17)
card(rocks,.66,1.05,-1.35,2.79,17)
card(fern,.47,.06,-1.35,2.98,13,{sway=true})
for i=1,3 do
 card({929,877,1056,985},.12+(i-1)*.015,-1.97+i*.043,8,.8-i*.033,2.8+i*.35,
  {ambientCard='victoryPebble'..i,pivot=1.5,mirror=i==2})
end
return {victory=out}
