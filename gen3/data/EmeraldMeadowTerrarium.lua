-- Dense countryside is built from separate botanical paper pieces. Keep the
-- two combat footprints clear while varied vegetation follows the ball rim.
local layouts={}
for _,kind in ipairs({'meadow','long_grass'})do
 local out={};layouts[kind]=out
 local function card(texture,rect,width,x,y,z,begin,extra)
  local a=rect
  local d={texture=texture,imageWidth=1536,imageHeight=1024,cutout=true,
   points={{a[1],a[2]},{a[3],a[2]},{a[3],a[4]},{a[1],a[4]}},width=width,x=x,y=y,z=z,
   begin=begin,duration=.8,direction=z>1 and-1 or 1,foldOffset=begin<4 and math.min(.11,(begin-3.12)*.18)or 0}
  for k,v in pairs(extra or{})do d[k]=v end
  if d.height then d.heightScale=d.height/((a[4]-a[2])*width*30/(a[3]-a[1]));d.height=nil end
  out[#out+1]=d
 end
 local function land(...)card('meadow-landscape-v2.png',...)end
 local function detail(...)card('meadow-details-v2.png',...)end
 local fern={0,58,518,525};local flowers={524,142,1021,524}
 local log={1027,250,1534,541};local rock={8,672,534,958}
 local berry={540,576,1025,964};local bank={1026,653,1533,967}
 land({907,242,1527,610},5.35,0,-1.35,-2.59,3.12,{height=119,
  points={{907,366},{922,339},{934,310},{948,299},{961,281},{982,258},{997,242},{1527,242},{1527,610},{907,610}}})
 card('route-meadow-kit.png',{431,503,877,748},1.39,1.39,107,-2.82,3.18,{imageWidth=1254,imageHeight=1254,mount='lid',driftX=1.3,floatY=.24})
 land({9,675,534,993},3.40,-1.07,-1.35,-2.11,3.24)
 land({539,650,1040,990},2.88,1.21,-1.35,-1.94,3.35)
 -- Different tree silhouettes; do not duplicate a single rounded crown.
 land({2,5,538,616},2.53,-1.88,-1.35,-1.82,3.43,{sway=true,
  points={{2,5},{492,5},{498,165},{506,339},{538,403},{506,616},{2,616}}})
 land({504,7,968,616},2.14,1.91,-1.35,-1.74,3.52,{sway=true,
  points={{580,7},{968,7},{968,284},{904,326},{900,616},{553,616},{553,379},{504,333},{504,158},{580,112}}})
 land({1039,674,1534,996},2.23,.48,-1.35,-1.39,3.62,{sway=true})
 detail(berry,1.15,-1.26,-1.35,-1.06,3.71,{sway=true})
 detail(flowers,1.31,1.60,-1.35,-.92,3.78,{sway=true})
 detail(fern,1.17,-2.45,-1.35,-.12,3.86,{sway=true})
 detail(berry,.97,2.53,-1.35,-.35,3.91,{sway=true,mirror=true})
 detail(rock,1.12,-2.10,-1.35,.64,4.05)
 detail(rock,1.12,2.12,-1.35,.20,4.15)
 detail(bank,1.28,-2.35,-1.35,1.37,4.21)
 detail(bank,1.19,2.36,-1.35,1.29,4.25,{mirror=true})
 detail(fern,1.06,-1.93,-1.35,2.12,4.29,{sway=true})
 detail(log,1.15,1.73,-1.35,2.16,4.33)
 detail(flowers,.82,.91,-1.35,2.77,4.37,{sway=true})
 detail(bank,.98,-.53,-1.35,2.93,4.41)
 detail(flowers,.78,-2.70,-1.35,.65,4.23,{sway=true})
 detail(fern,.80,2.64,-1.35,.69,4.27,{mirror=true,sway=true})
 if kind=='long_grass'then
  detail(flowers,1.69,-.91,-1.35,-.65,3.82,{sway=true})
  detail(flowers,1.48,.89,-1.35,-.70,3.87,{sway=true,mirror=true})
 end
end
return layouts
