-- Closed, overlapping rock strata made from separately cut paper sectors.
-- The arena top and battle height stay fixed; cutout cliffs frame its edge.
local P={}
function P.build(def,edgeRadius)
 local sides,ledges,seams={},{},{}
 local function v(r,t,y,u,w,shade)return{math.cos(t)*r,y,math.sin(t)*r,u,w,shade or 1}end
 local function quad(out,a,b,c,d)
  for _,p in ipairs({a,b,c,a,c,d})do out[#out+1]=p end
 end
 local levels={def.bottom or -12,-9,-4,.3,3.8,def.height}
 -- Lower shelves stagger beneath the cut arena edge. Unlike the
 -- previous vertical cylinder, every shelf has a real horizontal paper lip.
 local offsets={2.8,3.6,2.3,1.6,.65,0}
 local function radius(layer,t)
  if layer==#levels then return edgeRadius(t)end
  local amount=offsets[layer]
  return edgeRadius(t)-4+amount*(.70+.20*math.sin(t*7+layer*.7)+.10*math.cos(t*11-layer))
 end
 for layer=1,#levels-1 do
  local low,high=levels[layer],levels[layer+1]
  for i=0,95 do
   local a,b=i*math.pi/48,(i+1)*math.pi/48
   local ra,rb=radius(layer,a),radius(layer,b)
   local na,nb=radius(layer+1,a),radius(layer+1,b)
   local sector=math.floor(i/8)
   local shade=.73+layer*.035+(sector%3)*.024
   -- Each eight-segment face uses its own paper grain interval.
   local ua,ub=(i%8)/8,(i%8+1)/8
   quad(sides,v(ra,a,low,ua,0,shade),v(rb,b,low,ub,0,shade),v(rb,b,high,ub,1,shade),v(ra,a,high,ua,1,shade))
   local lipY=layer==#levels-1 and high-.06 or high
   quad(ledges,v(ra,a,lipY,ua,0,.95),v(rb,b,lipY,ub,0,.95),v(nb,b,lipY,ub,1,.95),v(na,a,lipY,ua,1,.95))
   -- A thin exposed cardboard edge under every shelf, not a painted stripe.
   quad(seams,v(ra+.035,a,high-.22,ua,0,.90),v(rb+.035,b,high-.22,ub,0,.90),v(rb+.035,b,high,ub,1,.90),v(ra+.035,a,high,ua,1,.90))
   if i%8==0 then
    local t=a+.003
    quad(seams,v(ra+.05,a,low,0,0,.55),v(radius(layer,t)+.05,t,low,1,0,.55),v(radius(layer,t)+.05,t,high-.25,1,1,.55),v(ra+.05,a,high-.25,0,1,.55))
   end
  end
 end
 return{sides=sides,ledges=ledges,seams=seams,levels=levels}
end
function P.cards(def)
 local result={};local art=def.rockArt;if not art then return result end
 local b=art.rect;local h=34
 for i=0,6 do
  local a=.22+i*(math.pi-.44)/6
  local r=def.radius+(def.edge or 0)*(.55+.25*math.sin(a*5)+.20*math.sin(a*9+.7))+.6
  local w=1.05+(i%3)*.09
  result[#result+1]={texture=art.texture,imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,
   x=(def.x+math.cos(a)*r)/30,y=def.height-h+6.5,z=(def.z+math.sin(a)*r)/30,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),fixedYaw=math.pi/2-a,
   begin=3.36+i*.01,duration=.7,foldOffset=.024+i*.001,direction=-1,
   platformRock=true,rockIndex=i+1,assemblyX=0,mirror=i%2==1}
 end
 return result
end
return P
