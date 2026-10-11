-- The summit is an open ruined rooftop, with cloud bands at separate depths.
local out={}
local function card(r,w,x,y,z,begin,extra)
 local d={texture='sky-pillar-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
  begin=begin,duration=.8,direction=z>1 and -1 or 1,foldOffset=begin<4 and(begin-3.12)*.18 or 0}
 for k,v in pairs(extra or{})do d[k]=v end
 if d.height then d.heightScale=d.height/((r[4]-r[2])*w*30/(r[3]-r[1]));d.height=nil end
 out[#out+1]=d
end
local sky={40,57,495,612};local left={536,40,1008,612};local right={1045,58,1515,616}
local cloud={15,735,495,936};local podium={518,705,1010,930};local rubble={1037,735,1520,945}
card(sky,5.05,0,-1.35,-2.47,3.12,{height=135,curve=9})
card(cloud,2.25,-1.12,99,-2.08,3.27,{driftX=2.4,floatY=.35})
card(cloud,1.52,1.51,108,-2.02,3.36,{mirror=true,driftX=1.8,floatY=.45})
card(left,2.32,-1.28,-1.35,-1.90,3.44,{runes=true})
card(right,2.83,1.02,-1.35,-1.74,3.56,{runes=true})
card(cloud,4.70,0,3,-1.36,3.70,{height=17,driftX=1.2,floatY=.40})
card(podium,1.12,-2.10,-1.35,.64,4.05,{runes=true})
card(podium,1.12,2.12,-1.35,.20,4.15,{runes=true})
card(rubble,.97,-2.55,-1.35,-.02,4.22,{sway=true})
card(rubble,.88,2.60,-1.35,-.05,4.29,{mirror=true,sway=true})
card(rubble,.87,-1.95,-1.35,1.97,4.35,{sway=true})
card(rubble,.78,2.03,-1.35,1.91,4.40,{mirror=true,sway=true})
card(cloud,1.22,0,-.95,2.95,4.45,{height=7,driftX=1.1,floatY=.25})
return out
