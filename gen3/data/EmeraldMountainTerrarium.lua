-- Route 114: distant ridge cards, staggered trails and suspended sky pieces.
local out={}
local function card(r,w,x,y,z,h,extra)
 local begin=3.12+#out*.024
 local d={texture='mountain-layered-v2.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},
  width=w,x=x,y=y,z=z,heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),
  begin=begin,duration=.8,direction=z>1 and -1 or 1,foldOffset=math.min(.10,(begin-3.12)*.15)}
 for k,v in pairs(extra or{})do d[k]=v end
 out[#out+1]=d;return d
end
local cliff={5,8,384,500};local stairs={394,26,734,495};local tree={744,69,1124,480}
local peak={1093,149,1534,459};local ridge={5,548,386,730};local hill={388,538,780,733}
local boulder={5,774,372,1003};local grass={379,764,736,1009};local scree={738,806,1032,1002}
local log={1152,780,1535,999}
card({780,535,1047,701},1.92,-1.16,123,-3.38,33,{mount='lid',driftX=1.1,floatY=.3})
card({1053,593,1209,697},1.01,1.56,139,-3.43,18,{mount='lid',driftX=.8,floatY=.2,floatPhase=2})
card({1218,524,1375,678},.54,-.41,136,-3.25,14,{mount='lid',driftX=1.3,floatY=.4,eventSway=.16,pivot=13})
card({1376,572,1509,696},.42,1.07,118,-3.17,10,{mount='lid',driftX=.8,floatY=.35,floatPhase=1.7,eventSway=.12,pivot=9})
local peaks=card(peak,4.82,.12,18,-3.13,108)
-- The adjacent tree spreads into the unused top-left of this atlas cell.
peaks.points={{1200,149},{1534,149},{1534,459},{1093,459},{1093,260},{1200,260}}
card(ridge,4.58,-.25,6,-2.76,65)
card(hill,3.74,.35,-1.35,-2.41,52)
card(cliff,1.91,-1.98,-1.35,-2.04,110)
card(stairs,1.59,2.03,-1.35,-1.86,90)
local windtree=card(tree,1.66,-2.27,-1.35,-1.28,67,{sway=true,eventSway=.035})
windtree.points={{744,69},{1124,69},{1124,210},{1060,300},{1060,480},{744,480}}
card(scree,1.10,1.44,-1.35,-1.44,26)
card(grass,.71,2.78,-1.35,-.88,25,{sway=true})
for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
 card({12,779,550,992},1.12,p[1],-1.35,p[2],18,{texture='wildplace-mountain-kit.png'})
end
card(grass,.62,-2.79,-1.35,1.02,20,{sway=true})
card(boulder,.72,2.77,-1.35,.98,23)
card(log,1.02,-2.01,-1.35,2.09,20)
card(grass,.91,2.05,-1.35,2.04,26,{sway=true})
card(scree,.68,-1.03,-1.35,2.78,17)
card(boulder,.68,1.06,-1.35,2.76,20)
card(grass,.48,.05,-1.35,2.99,14,{sway=true})
return {mountain=out}
