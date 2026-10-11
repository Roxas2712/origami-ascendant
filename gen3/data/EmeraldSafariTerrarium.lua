-- Safari wetlands: many separate leaf silhouettes around a clear capture stage.
local out={}
local function card(r,w,x,y,z,h,extra)
 local begin=3.12+#out*.024
 local d={texture='safari-layered-v2.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},
  width=w,x=x,y=y,z=z,heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),
  begin=begin,duration=.8,direction=z>1 and -1 or 1,foldOffset=math.min(.10,(begin-3.12)*.15)}
 for k,v in pairs(extra or{})do d[k]=v end
 out[#out+1]=d;return d
end
local tree={9,18,386,429};local tree2={394,99,774,429};local stand={778,90,1096,432}
local distant={1125,124,1530,418};local canopy={8,439,380,725};local pool={747,489,1130,710}
local fence={1153,445,1530,709};local grass={6,731,382,1008};local berries={395,759,752,1008}
local log={773,772,1129,1008};local reeds={1143,720,1301,1007};local seeds={1279,829,1408,1007}
card({407,459,733,627},1.76,-.90,119,-3.28,32,{mount='lid',driftX=.7,floatY=.25})
card({589,627,731,701},.99,1.48,128,-3.34,17,{mount='lid',driftX=.6,floatY=.18,floatPhase=2})
card(canopy,1.64,-1.89,111,-3.40,39,{mount='lid',oscillate=.019,eventSway=.028,pivot=38})
card(canopy,1.03,1.97,119,-3.43,27,{mount='lid',oscillate=.015,eventSway=.023,pivot=26,mirror=true})
card(distant,4.91,.04,-1.35,-3.09,105)
card(tree,2.14,-1.84,-1.35,-2.45,122,{sway=true})
card(tree2,2.35,1.78,-1.35,-2.20,106,{sway=true})
card(stand,1.93,.40,-1.35,-1.93,98)
card(pool,2.55,-.54,-1.35,-1.49,33,{flowing=true})
card(fence,1.59,-1.64,-1.35,-1.19,33)
card(reeds,.48,1.59,-1.35,-1.24,35,{sway=true})
card(berries,.76,-2.69,-1.35,-.43,28,{sway=true})
card(grass,.87,2.68,-1.35,-.55,31,{sway=true})
for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
 card({17,733,513,972},1.12,p[1],-1.35,p[2],18,{texture='wildplace-safari-kit.png'})
end
card(seeds,.37,-2.83,-1.35,1.11,24,{sway=true})
card(berries,.64,2.80,-1.35,1.04,19,{sway=true})
card(log,1.09,-2.04,-1.35,2.11,23)
card(grass,.99,2.03,-1.35,2.08,27,{sway=true})
card(berries,.65,-1.06,-1.35,2.78,18,{sway=true})
card(seeds,.33,1.05,-1.35,2.79,21,{sway=true})
card(grass,.39,-.04,-1.35,3.0,12,{sway=true})
card({1421,856,1509,939},.24,-2.04,22,2.10,6.1,{ambientCard='safariButterfly',pivot=3})
return {safari=out}
