-- Aqua dock: independent paper cave ribbons, machinery, submarine and water.
local out={}
local function card(r,w,x,y,z,h,extra)
 local begin=3.12+#out*.021
 local d={texture='aqua-layered-v2.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
  heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=begin,duration=.8,
  direction=z>1 and -1 or 1,foldOffset=math.min(.08,(begin-3.12)*.12)}
 for k,v in pairs(extra or{})do d[k]=v end
 out[#out+1]=d;return d
end
local left={23,12,276,346};local right={459,14,741,350};local ridge={766,144,1147,335}
local console={22,365,355,684};local pad={372,517,763,676};local door={789,422,1069,665}
local sub={1116,365,1527,668};local water={24,800,402,974};local rock={432,733,790,982}
local cargo={826,726,1145,983};local scope={1270,700,1383,983}
card(ridge,3.58,-.24,-1.35,-3.16,92)
card(ridge,2.27,.93,-1.35,-2.98,73,{mirror=true})
card(left,1.80,-2.00,-1.35,-2.58,125)
card(right,1.81,2.02,-1.35,-2.49,120)
card(door,1.27,1.22,-1.35,-2.29,59,{lamps=true})
card(console,1.56,-1.40,-1.35,-2.20,71,{lamps=true,glow={108,446,329,537}})
for i,r in ipairs({{1137,19,1257,298},{1290,45,1359,327},{1407,19,1513,312}})do
 local h=({43,37,41})[i]
 card(r,.49,-1.61+(i-1)*1.57,111+(i%2)*6,-3.39,h,
  {mount='lid',lamps=true,pivot=h-1,oscillate=.009,floatPhase=i*.9,
   points=i==1 and{{1137,19},{1257,19},{1257,298},{1151,298},{1151,185},{1137,185}}or nil})
end
-- Periscope rises behind the hull, then withdraws into it during quiet moments.
card(scope,.17,-.03,5,-2.84,30,{ambientCard='aquaPeriscope'})
card(sub,2.19,-.03,3,-2.73,42)
card(water,2.46,-.14,-1.35,-2.52,17,{mutedWater=true,wave=.4,fluidCard='dock-back'})
card(water,2.54,.08,-1.35,-2.26,14,{mutedWater=true,wave=2.0,fluidCard='dock-front'})
card(pad,1.29,-1.52,-1.35,-1.41,20,{lamps=true,glow={463,543,676,590}})
card(pad,1.19,1.51,-1.35,-1.43,19,{lamps=true,glow={463,543,676,590}})
card(rock,.93,-2.65,-1.35,-.78,30)
card(cargo,.71,2.66,-1.35,-.83,30)
local podiums={
 {points={{288,693},{304,651},{335,636},{386,633},{444,641},{460,657},{480,705},{449,724},{391,729},{335,716}},width=1.12,x=-2.1,z=.64,begin=4.05,duration=.6,direction=1},
 {points={{992,693},{1008,650},{1037,636},{1086,633},{1140,644},{1155,660},{1178,710},{1138,729},{1079,730},{1027,716}},width=1.12,x=2.12,z=.2,begin=4.15,duration=.6,direction=1},
}
for _,d in ipairs(podiums)do
 d.texture='aqua-paper.png';d.imageWidth=1448;d.imageHeight=1086
 d.begin=3.12+#out*.021;d.duration=.8;out[#out+1]=d
end
card(cargo,.72,-2.64,-1.35,1.18,24)
card(rock,.79,2.65,-1.35,1.21,24,{mirror=true})
card(rock,.79,-1.93,-1.35,2.25,22)
card(cargo,.61,1.95,-1.35,2.17,21)
card(rock,.49,-.94,-1.35,2.85,14)
card(rock,.44,1.02,-1.35,2.82,12,{mirror=true})
return out
