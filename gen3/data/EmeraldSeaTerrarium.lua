-- Separate alpha-cut paper props. All three wave ribbons curve around the
-- island and overlap in depth; the matching continuous rear scene seals gaps.
local panels={}
local function cut(texture,iw,ih,rect,width,x,y,z,begin,extra)
 local x0,y0,x1,y1=unpack(rect)
 local d={texture=texture,imageWidth=iw,imageHeight=ih,cutout=true,
  points={{x0,y0},{x1,y0},{x1,y1},{x0,y1}},width=width,x=x,y=y,z=z,
  begin=begin,duration=.9,direction=1}
 for k,v in pairs(extra or{})do d[k]=v end
 panels[#panels+1]=d
end
-- All lid layers come from the same composed illustration. Matched UV
-- proportions keep the foam and shoreline continuous across their overlaps.
local function lid(points,width,x,y,z,begin,wave)
 panels[#panels+1]={texture='sea-composition-v3.png',points=points,width=width,
  heightScale=1.20,x=x,y=y,z=z,begin=begin,duration=.95,direction=1,wave=wave}
end
lid({{400,287},{414,248},{440,208},{481,165},{520,135},{574,112},{626,99},{680,93},{724,91},{782,99},{835,115},{883,141},{927,169},{966,207},{997,248},{1024,286},{1025,320},{1045,345},{1030,377},{1021,413},{1006,441},{958,446},{887,442},{801,445},{711,443},{628,447},{544,442},{465,443},{415,433},{398,404},{384,369},{377,337},{390,322}},5.40,0,-8,-3.25,3.12)
lid({{407,284},{430,292},{454,311},{480,317},{508,317},{541,320},{578,330},{613,323},{651,336},{688,340},{716,344},{752,338},{790,334},{824,332},{858,330},{892,328},{918,314},{943,310},{970,292},{1000,280},{1021,284},{1016,319},{997,351},{969,369},{924,375},{876,382},{811,377},{750,382},{692,378},{630,382},{572,375},{521,376},{465,368},{429,352},{410,332}},4.96,.09,10.9,-3.19,3.30,1)
lid({{377,333},{397,321},{418,326},{439,344},{460,354},{484,362},{510,368},{540,367},{566,358},{595,359},{628,373},{660,384},{694,392},{727,396},{758,391},{792,386},{824,383},{855,379},{882,376},{912,369},{942,361},{970,350},{1002,335},{1026,338},{1048,350},{1040,376},{1024,412},{1007,441},{950,447},{875,442},{794,445},{711,443},{628,447},{546,442},{465,443},{416,434},{399,405},{388,372}},5.40,.01,-8,-3.12,3.45,2)
local props={
 {18,8,528,525},{546,72,1006,521},{1022,24,1522,521},
 {22,545,535,1008},{550,520,1018,1008},{1028,547,1520,1009},
}
local function coral(n,width,x,y,z,begin)
 cut('sea-coral-v2.png',1536,1024,props[n],width,x,y,z,begin,{sway=true,curve=1.4,direction=z>1 and -1 or 1})
end
-- Taller back kelp, varied side fans, and two stepped rows at the front rim.
coral(1,.78,-1.67,-33,-1.98,3.55)
coral(5,.78,1.67,-33,-1.98,3.62)
coral(2,.83,-2.61,-15,.20,3.80)
-- Clear the trainer tower by a full layer, including the coral's sway arc.
-- Equal z positions made the tower cut a vertical strip through its shelves.
coral(3,.75,2.67,-15,.75,3.86)
coral(4,.86,-2.35,-15,1.30,4.02)
coral(5,.81,2.36,-15,1.30,4.08)
coral(3,.88,-1.62,-23,1.98,4.22)
coral(6,.88,1.64,-23,1.98,4.28)
coral(2,.68,-.72,-22,2.48,4.38)
coral(4,.68,.75,-22,2.48,4.44)
local stonePanels={
 -- Trainer towers: tops above the single water surface, bases on the seabed.
 {points={{359,732},{360,670},{364,624},{376,604},{396,595},{423,602},{447,607},{458,629},{452,667},{463,704},{453,754},{440,789},{407,795},{377,776}},width=.88,x=-2.23,y=-47,z=.50,begin=4.05,duration=.6,direction=1},
 {points={{969,764},{968,706},{971,654},{980,618},{997,600},{1020,589},{1042,596},{1060,614},{1071,641},{1068,685},{1060,722},{1052,758},{1035,783},{1000,788}},width=.88,x=2.23,y=-46,z=.20,begin=4.15,duration=.6,direction=1},
 }
for _,p in ipairs(stonePanels)do panels[#panels+1]=p end
-- New authored continuous silhouettes, with natural proportions and dry tops.
cut('sea-rock-columns-v2.png',1536,1024,{0,80,768,960},1.84,-.97,-46,-.66,3.70)
cut('sea-rock-columns-v2.png',1536,1024,{768,80,1536,960},1.84,.97,-46,-.93,3.76)
return panels
