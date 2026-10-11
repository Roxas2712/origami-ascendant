-- Separate, alpha-bounded coastal cards. No rectangular ocean backdrop.
-- The central sand and native trainer ledges remain unobstructed.
local out={}
local function card(tex,r,width,x,y,z,begin,extra)
 local d={texture=tex,imageWidth=1254,imageHeight=1254,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},
  width=width,x=x,y=y,z=z,begin=begin,duration=.8,direction=z>1 and-1 or 1,
  foldOffset=begin<4 and math.min(.11,(begin-3.12)*.18)or 0}
 for k,v in pairs(extra or{})do d[k]=v end
 if d.height then d.heightScale=d.height/((r[4]-r[2])*width*30/(r[3]-r[1]));d.height=nil end
 out[#out+1]=d
end
local function coast(...)card('coast-botanical-v2.png',...)end
local arch={0,150,440,470};local palm={450,50,840,505};local cliff={850,65,1254,515}
local waveA={0,570,438,815};local waveB={440,575,848,818}
local driftwood={12,868,433,1230};local dune={440,841,842,1230}
coast(arch,4.40,-.48,-1.35,-2.78,3.12,{height=91,paperTint={.88,.94,.95,1}})
card('route-coast-kit.png',{475,552,859,790},1.28,-1.41,114,-3.04,3.16,{mount='lid',floatY=.2,driftX=.9})
card('route-coast-kit.png',{475,552,859,790},.91,1.33,130,-3.15,3.20,{mount='lid',floatY=.17,driftX=.7})
coast(palm,2.25,-2.02,-1.35,-1.92,3.32,{height=112,sway=true})
coast(cliff,2.49,1.84,-1.35,-2.02,3.42,{height=82})
-- Each breaker has its own hinge, phase and soft horizontal surge.
coast(waveB,4.30,.12,-1.35,-2.23,3.26,{height=33,wave=.3,floatY=.7,floatPhase=.3,driftX=1.8,flowing=true})
coast(waveA,3.36,-.64,-1.35,-1.86,3.48,{height=26,wave=2.2,floatY=.6,floatPhase=2.2,driftX=2.4,flowing=true})
coast(waveB,2.43,.65,-1.35,-1.53,3.56,{height=17,wave=4.3,floatY=.4,floatPhase=4.3,driftX=1.5,flowing=true,mirror=true})
coast(dune,1.13,-1.47,-1.35,-1.22,3.65,{height=28,sway=true})
coast(driftwood,1.21,1.53,-1.35,-1.05,3.72,{height=22})
coast(dune,.92,-2.57,-1.35,-.33,3.80,{height=26,sway=true,mirror=true})
coast(dune,.84,2.57,-1.35,-.42,3.86,{height=24,sway=true})
-- Retain the measured dry-top ledges used by native trainer feet and throws.
card('route-coast-kit.png',{433,1011,894,1198},1.12,-2.10,-1.35,.64,4.05)
card('route-coast-kit.png',{433,1011,894,1198},1.12,2.12,-1.35,.20,4.15)
coast(driftwood,1.23,-1.85,-1.35,2.12,4.28,{height=23})
coast(dune,1.06,1.99,-1.35,1.95,4.32,{height=26,sway=true})
coast(dune,.69,-.89,-1.35,2.75,4.37,{height=15,sway=true,multi={x=-1.6}})
coast(driftwood,.77,1.03,-1.35,2.67,4.40,{height=13,mirror=true})
coast({1090,1080,1245,1217},.26,.22,-1.35,2.70,4.42,{height=5})
-- Two individually suspended seabirds; the strings move with the actual lid.
coast({875,846,1096,1035},.52,-.63,104,-2.83,3.22,{height=15,mount='lid',floatY=.6,floatPhase=1.4,driftX=2.6,oscillate=.05,eventMotion='coastBird',eventIndex=1,shoreHabitat='coast:'})
coast({866,1036,1080,1194},.43,.83,97,-2.65,3.25,{height=13,mount='lid',floatY=.45,floatPhase=3.1,driftX=1.9,oscillate=.035,eventMotion='coastBird',eventIndex=2,shoreHabitat='coast:'})
return {coast=out}
