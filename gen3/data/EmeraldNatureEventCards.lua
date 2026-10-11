-- Individual quiet-event silhouettes, authored in front of their source plants.
-- Keys match the resolved art registry, while habitat binding remains exact.
local layouts={}
local rects={leaf={69,44,488,504},white={612,62,941,472},pink={1090,71,1464,482},
 frond={65,524,508,967},ash={601,546,947,922},butterfly={1021,546,1507,946}}
local function add(key,habitat,part,motion,i,w,x,y,z,h)
 local list=layouts[key]or{};layouts[key]=list;local r=rects[part]
 list[#list+1]={texture='nature-events-v1.png',imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},
  width=w,x=x,y=y,z=z,heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),
  begin=3.80+i*.02,duration=.8,direction=z>1 and -1 or 1,foldOffset=0,
  ambientCard='nature_'..motion..i,natureEvent=motion,natureHabitat=habitat,eventIndex=i}
end
for i=1,3 do
 add('forest','forest:','leaf','forestLeaf',i,.23,-2.06-(i-1)*.12,59+i*3,-.98,7.7)
 add('meadow','meadow:',i%2==0 and 'pink'or 'white','meadowPetal',i,.21,1.99+(i-1)*.10,25+i*2,-1.03,6.9)
 add('forest:ancient','forest:ancient','frond','ancientFrond',i,.25,-2.08-(i-1)*.12,70+i*3,-1.03,7.8)
 add('forest:island','forest:island','pink','islandPetal',i,.22,2.07+(i-1)*.10,49+i*2,-1.02,7.0)
 add('ash','ash:','ash','routeAsh',i,.30,-1.82+(i-1)*.08,18+i*3,2.40,8.7)
end
for i=1,2 do
 add('meadow:long_grass','meadow:long_grass','butterfly','grassButterfly',i,.32,i==1 and -2.08 or 2.08,30,-1.03,8.0)
end
return layouts
