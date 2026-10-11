-- Meteor Falls: three independent falls/pools between thin limestone flats.
local out={}
local function card(r,w,x,y,z,h,extra)
 local begin=3.12+#out*.022
 local d={texture='meteor-layered-v2.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},
  width=w,x=x,y=y,z=z,heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),
  begin=begin,duration=.8,direction=z>1 and -1 or 1,foldOffset=math.min(.10,(begin-3.12)*.15)}
 for k,v in pairs(extra or{})do d[k]=v end
 -- Raised pieces ride folding rear cardstock supports from the floor; they
 -- must not hover at their final height while the rest of the cave unfolds.
 if y>0 and d.mount~='lid'and not d.ambientCard then d.support=true end
 out[#out+1]=d;return d
end
local left={18,11,371,383};local right={397,9,758,383}
local rim={777,10,1139,383};local recess={1146,13,1529,383}
local pool={15,546,396,707};local fall={464,389,710,721}
local teeth={777,399,1138,691};local fern={1147,403,1529,714}
local scree={1115,814,1526,992};local meteor={462,752,756,988}
local ledge={20,806,418,990}
-- Three hanging groups, with visible thread attachments and gaps to the lid.
for i,p in ipairs({{-1.78,120,.90,33},{-.17,122,.74,30},{1.57,119,.84,34}})do
 card(teeth,p[3],p[1],p[2],-3.40,p[4],{mount='lid',mirror=i==2})
end
card(recess,4.26,.06,-1.35,-3.17,126)
-- The opening's crown and two cheeks are separate overlapping hinged flats.
local function rimPart(r,points,z)
 local w=4.78*(r[3]-r[1])/(rim[3]-rim[1])
 local h=138*(r[4]-r[2])/(rim[4]-rim[2])
 local x=.02+((r[1]+r[3])/2-(rim[1]+rim[3])/2)*4.78/(rim[3]-rim[1])
 local y=-1.35+(rim[4]-r[4])*138/(rim[4]-rim[2])
 card(r,w,x,y,z,h,{points=points})
end
rimPart({777,10,1139,185},{{777,10},{1139,10},{1139,161},{1100,169},{1033,153},{962,185},{887,158},{832,171},{777,156}},-2.86)
rimPart({777,142,943,383},{{777,142},{865,142},{902,160},{943,183},{926,225},{884,237},{890,278},{931,335},{943,383},{777,383}},-2.80)
rimPart({996,136,1139,383},{{996,150},{1044,136},{1097,145},{1139,142},{1139,383},{996,383},{1028,320},{1036,243}},-2.75)
card(left,1.96,-1.91,-1.35,-2.28,113)
card(right,1.98,1.91,-1.35,-2.10,112)
card(left,2.12,-.24,-1.35,-2.64,115)
-- Terraces support every pool; water is mounted in front of their dry top lip.
card(ledge,1.52,-.35,94,-2.61,22)
card(ledge,2.35,-.25,55,-2.53,28)
card(ledge,2.78,.10,17,-2.19,30)
card(pool,1.13,-.35,104,-2.59,9,{mutedWater=true,poolTier=0})
-- Falling ribbons overlap the following pool. Each has its own mesh and flow.
card(fall,.68,-.35,79,-2.56,32,{flowing=true,waterfallTier=1})
card(pool,1.60,-.25,70,-2.47,11,{mutedWater=true,poolTier=1})
card(fall,.86,.05,43,-2.27,33,{flowing=true,waterfallTier=2})
card(pool,1.90,.10,34,-2.13,12,{mutedWater=true,poolTier=2})
card(fall,1.02,-.12,13,-1.96,30,{flowing=true,waterfallTier=3})
card(pool,2.53,0,-1.35,-1.69,20,{mutedWater=true,poolTier=3})
card(scree,.97,-1.32,-1.35,-1.42,27)
card(fern,.71,1.35,-1.35,-1.40,25,{sway=true})
card(left,.68,-2.73,-1.35,-.73,37)
card(right,.65,2.75,-1.35,-.78,34)
-- Keep the authored dry ledges/foot heights for the battle anchors.
for _,p in ipairs({{-2.37,.54},{2.37,-.10}})do
 card({29,792,514,987},1.15,p[1],-1.35,p[2],18,{texture='deepcave-meteor-kit.png'})
end
card(fern,.70,-2.80,-1.35,1.08,22,{sway=true})
card(scree,.73,2.78,-1.35,1.12,22)
card(scree,.96,-2.03,-1.35,2.08,23)
card(fern,.90,2.04,-1.35,2.09,23,{sway=true})
card(meteor,.62,-1.06,-1.35,2.76,17)
card(scree,.69,1.08,-1.35,2.77,17)
card(fern,.46,.03,-1.35,2.98,13,{sway=true})
-- Quiet drips fall beside the cascade and disappear at the lower pool.
for i,p in ipairs({{-.79,68,-1.77},{.72,56,-1.76},{.37,63,-1.78}})do
 card({890,694,1019,999},.083,p[1],p[2],p[3],4.2,
  {ambientCard='meteorDrop'..i,pivot=3})
end
return {meteor=out}
