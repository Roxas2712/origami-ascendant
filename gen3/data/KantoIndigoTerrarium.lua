-- Layout derived from the native FR_INDIGO_PLATEAU_EXTERIOR reference.
-- Separate facade, portal, roof, conifers, guardian statues and stepped cliffs.
local cards={}
local function add(part,width,x,y,z,height,extra)
 cards[#cards+1]={part=part,width=width,x=x,y=y,z=z,height=height,extra=extra}
end
-- Dense tree banks behind and beside the broad, low League reception building.
for _,p in ipairs({{-2.58,-2.33,83},{2.58,-2.33,83},{-2.94,-1.40,65},{2.94,-1.40,65},
 {-3.00,-.51,43},{3.00,-.51,43},{-3.00,.42,35},{3.00,.42,35}})do
 add(5,p[2]>-.7 and .60 or .88,p[1],-1.35,p[2],p[3],{sway=true})
end
add(1,2.28,-1.10,-1.35,-2.52,54)
add(2,2.28,1.10,-1.35,-2.52,54)
add(4,4.82,0,50,-2.62,34)
add(3,1.12,0,-1.35,-2.29,52)
for _,x in ipairs({-1.45,1.45})do add(10,.92,x,-1.35,-2.16,22)end
-- A ceremonial approach: statues and white bollards, not a generic town street.
for _,p in ipairs({{-1.32,-1.52},{1.32,-1.52},{-1.70,-.77},{1.70,-.77}})do
 add(6,.44,p[1],-1.35,p[2],27)
end
for _,x in ipairs({-2.13,2.13})do
 for _,z in ipairs({-1.30,-.69,-.06,.60})do add(7,.28,x,-1.35,z,12)end
end
-- Low foreground terraces retain the stair approach without obscuring combatants.
add(9,2.14,-1.91,-1.35,1.91,17)
add(9,2.14,1.91,-1.35,1.91,17)
add(8,1.42,0,-1.35,2.19,17)
return cards
