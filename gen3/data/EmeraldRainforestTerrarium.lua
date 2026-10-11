-- Route 119: individual flat botanical cards with a separately folded bridge.
local out={}
local function card(r,w,x,y,z,h,extra)
 local begin=3.12+#out*.024
 local d={texture='rainforest-layered-v2.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},
  width=w,x=x,y=y,z=z,heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),
  begin=begin,duration=.8,direction=z>1 and -1 or 1,foldOffset=math.min(.10,(begin-3.12)*.15)}
 for k,v in pairs(extra or{})do d[k]=v end
 out[#out+1]=d;return d
end
local tree={10,8,404,449};local palm={413,9,777,448};local tree2={786,21,1163,451}
local falls={1171,26,1527,451};local bridge={8,511,409,710}
local vines={422,464,778,730};local cloud={804,476,1160,707};local raincloud={1221,476,1481,630}
local fern={14,730,407,1015};local flowers={420,726,774,1010}
local log={784,782,1166,1013};local leaves={1190,735,1521,1010}
-- Rain clouds and canopy fringe are attached to the actual moving lid.
card(cloud,1.75,-1.1,116,-3.14,31,{mount='lid',driftX=.8,floatY=.2})
card(raincloud,1.22,1.37,127,-3.18,22,{mount='lid',driftX=.7,floatY=.15,floatPhase=2})
for _,p in ipairs({{-1.88,123,1.64,31},{1.96,127,1.24,25}})do
 local d=card(vines,p[3],p[1],p[2],-3.35,p[4],{mount='lid',oscillate=.018,pivot=p[4]-1,mirror=p[1]>0})
 -- Preserve the dangling leaf at x704; exclude the neighbouring flower tip.
 d.points={{422,464},{778,464},{778,730},{680,730},{680,710},{422,710}}
end
for i,r in ipairs({{1290,632,1327,690},{1335,674,1378,728},{1388,631,1427,684}})do
 card(r,.18,1.17+(i-1)*.22,119,-3.10,8,{ambientCard='rainDrop'..i})
end
card(tree2,2.08,.72,-1.35,-2.98,116,{sway=true,paperTint={.81,.94,.89,1}})
card(falls,2.27,.18,-1.35,-2.54,93,{flowing=true})
card(tree,2.37,-1.92,-1.35,-2.27,129,{sway=true})
card(palm,1.91,2.02,-1.35,-2.15,112,{sway=true})
card(bridge,3.00,-.02,34,-1.87,38,{sway=true})
card(fern,1.28,-1.68,-1.35,-1.53,28,{sway=true})
card(leaves,1.07,1.61,-1.35,-1.47,29,{sway=true})
card(flowers,.83,-2.72,-1.35,-.57,33,{sway=true})
card(fern,.99,2.69,-1.35,-.60,31,{sway=true,mirror=true})
-- Preserve the native measured trainer ledges and their UV material.
for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
 card({23,790,518,994},1.12,p[1],-1.35,p[2],18,{texture='wildplace-rainforest-kit.png'})
end
card(leaves,.78,-2.79,-1.35,1.12,20,{sway=true})
card(flowers,.74,2.76,-1.35,1.0,23,{sway=true})
card(log,1.19,-1.97,-1.35,2.13,21)
card(fern,1.02,2.04,-1.35,2.06,25,{sway=true})
card(leaves,.64,-.97,-1.35,2.79,17,{sway=true})
card(flowers,.59,1.05,-1.35,2.75,18,{sway=true})
card(fern,.43,-.25,-1.35,2.98,11,{sway=true})
return {rainforest=out}
