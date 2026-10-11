-- Small round paper cutouts from the original cavern atlas. Their ascent stays
-- behind the combat platform; no duplicated front-floor particle substitute.
local layouts={}
for _,key in ipairs({'underwater:cavern','underwater:wreck'})do
 local list={};layouts[key]=list
 for i=1,6 do
  local cx,cy,r=1300,444,12
  local points={}
  for j=0,15 do local a=j*math.pi/8;points[#points+1]={cx+math.cos(a)*r,cy+math.sin(a)*r}end
  list[#list+1]={texture='undersea-cavern-kit.png',imageWidth=1536,imageHeight=1024,cutout=true,
   points=points,width=.13+(i%3)*.035,heightScale=1,x=(i%2==0 and .45 or -.36),
   y=36,z=-2.20,begin=3.36,duration=.8,direction=1,foldOffset=.024,
   ambientCard='underseaBubble',eventIndex=i,underseaHabitat=key,underseaDetail=true}
 end
end
return layouts
