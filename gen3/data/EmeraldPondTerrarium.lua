-- Freshwater banks and foliage are independent paper silhouettes. Keep the
-- native dry-cap rectangles unchanged so feet, catch balls and Dig stay aligned.
local out={}
local function card(tex,r,width,x,y,z,begin,extra)
 local d={texture=tex,imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},
  width=width,x=x,y=y,z=z,begin=begin,duration=.8,direction=z>1 and-1 or 1,
  foldOffset=begin<4 and math.min(.11,(begin-3.12)*.18)or 0}
 for k,v in pairs(extra or{})do d[k]=v end
 if y>0 and d.mount~='lid'then d.support=true end
 if d.height then d.heightScale=d.height/((r[4]-r[2])*width*30/(r[3]-r[1]));d.height=nil end
 out[#out+1]=d
end
local function leaf(...)card('pond-botanical-v2.png',...)end
local tree={8,17,546,565};local young={546,50,1010,568}
local ridge={970,307,1534,551};local reed={8,565,518,1006}
local lily={514,637,992,965};local bank={993,671,1528,987}
local ridgePoints={{1012,307},{1534,307},{1534,551},{970,551},{970,516},{991,490},{998,461},{1012,442}}
local youngPoints={{546,50},{1010,50},{1010,445},{990,485},{955,520},{904,568},{546,568}}
-- The gaps between the two tree silhouettes expose the layered far bank.
leaf(ridge,5.30,.05,-1.35,-2.73,3.12,{height=71,points=ridgePoints,paperTint={.81,.91,.89,1}})
card('route-pond-kit.png',{531,550,917,768},1.38,-1.30,113,-3.30,3.16,{imageWidth=1254,imageHeight=1254,mount='lid',floatY=.24,driftX=1.1})
card('route-pond-kit.png',{531,550,917,768},.94,1.58,125,-3.33,3.20,{imageWidth=1254,imageHeight=1254,mount='lid',floatY=.16,driftX=.8,mirror=true})
leaf(ridge,3.35,.82,-1.35,-2.18,3.29,{height=36,points=ridgePoints,mirror=true})
leaf(tree,2.60,-1.84,-1.35,-1.98,3.42,{height=103,sway=true})
leaf(young,2.35,1.98,-1.35,-1.95,3.51,{height=97,sway=true,points=youngPoints,mirror=true})
leaf(bank,1.68,-1.45,-1.35,-1.43,3.61,{height=13})
leaf(bank,1.55,1.63,-1.35,-1.48,3.64,{height=12,mirror=true})
leaf(reed,.89,-.83,-1.35,-1.49,3.68,{height=29,sway=true})
leaf(reed,.78,1.32,-1.35,-1.23,3.72,{height=26,sway=true,mirror=true})
leaf(lily,1.05,.14,-1.35,-1.04,3.76,{height=11,wave=.7,floatY=.12})
leaf(reed,.90,-2.49,-1.35,-.43,3.81,{height=30,sway=true})
leaf(reed,.82,2.47,-1.35,-.34,3.86,{height=28,sway=true,mirror=true})
local function cap(width,x,z,begin)
 card('route-pond-kit.png',{451,1009,926,1192},width,x,-1.35,z,begin,{imageWidth=1254,imageHeight=1254})
end
cap(1.12,-2.10,.64,4.05);cap(1.12,2.12,.20,4.15)
cap(1.08,-.82,.98,4.18);cap(1.08,.84,.88,4.23)
leaf(bank,.98,-2.37,-1.35,1.39,4.25,{height=8})
leaf(bank,1.08,2.28,-1.35,1.49,4.29,{height=8,mirror=true})
leaf(lily,.77,-1.82,-1.35,2.11,4.31,{height=10,wave=2.1,floatY=.16})
leaf(lily,.69,1.89,-1.35,2.06,4.35,{height=9,wave=3.4,floatY=.15,mirror=true})
leaf(reed,.61,-1.02,-1.35,2.73,4.39,{height=18,sway=true,multi={x=-1.60}})
leaf(lily,.54,.67,-1.35,2.87,4.43,{height=7,wave=4.2,floatY=.12})
return {pond=out}
