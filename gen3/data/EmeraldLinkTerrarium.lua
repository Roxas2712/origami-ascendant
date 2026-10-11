-- Individually mounted communication stations, cable racks and lid pennants.
local out={}
local bounds={{40,49,504,555},{570,16,1047,571},{1077,51,1511,556},{14,672,564,918},{568,682,1182,902},{1240,594,1468,960}}
local function card(part,w,x,y,z,h,extra)
 local b=type(part)=='table'and part or bounds[part]
 local d={texture='link-colosseum-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
  heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=3.12+#out*.04,duration=.80,
  direction=z>1 and-1 or 1,foldOffset=math.min(.06,#out*.004)}
 for k,v in pairs(extra or{})do d[k]=v end
 out[#out+1]=d
end
card(2,2.28,0,-1.35,-2.8,113,{signal=true})
card(1,2.26,-1.91,-1.35,-2.19,87,{signal=true})
card(3,2.22,1.95,-1.35,-2.07,85,{signal=true})
card(6,.63,-1.18,118,-3.32,40,{mount='lid',oscillate=.021,pivot=40})
card(6,.63,1.19,119,-3.33,40,{mount='lid',oscillate=.018,pivot=40,mirror=true})
card(5,1.98,0,-1.35,-1.51,25,{signal=true})
card(4,1.15,-2.37,-1.35,.54,18)
card(4,1.15,2.37,-1.35,-.10,18)
-- Low cable racks surround, rather than cross, the attack lanes.
for _,p in ipairs({{-2.63,-.85,1.0,23},{2.63,-.78,1.0,23},{-2.53,1.31,.76,16},{2.53,1.31,.76,16},{-1.45,2.49,.93,13},{1.45,2.49,.93,13}})do
 card(5,p[3],p[1],-1.35,p[2],p[4],{signal=true,mirror=p[1]>0})
end
return {link=out}
