-- Quiet shore wildlife uses the existing hand-cut art, never a backdrop copy.
local layouts={coast={},pond={}}
local function add(key,texture,r,w,h,x,y,z,name,index)
 layouts[key][#layouts[key]+1]={texture=texture,imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,
  heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),x=x,y=y,z=z,
  begin=3.44,duration=.8,foldOffset=.04,direction=-1,ambientCard=name,
  shoreHabitat=key..':',eventIndex=index,doubleSidedArt=true}
end
add('coast','coastal-details-v1.png',{1180,716,1519,1000},.28,6.8,-1.66,-1.1,2.40,'shoreCrab',1)
for i,x in ipairs({-1.82,1.89})do
 add('pond','nature-events-v1.png',{1021,546,1507,946},.31,7.6,x,10,2.16,'pondButterfly',i)
end
return layouts
