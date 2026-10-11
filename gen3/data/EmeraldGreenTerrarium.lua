-- Four depth groups around a raised arena. Lid pieces use open-pose world
-- coordinates; EmeraldScene moves them with the single existing rear hinge.
local out={}
local function card(tex,r,width,x,y,z,begin,extra)
 local d={texture=tex,imageWidth=1536,imageHeight=1024,cutout=true,
  points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},
  width=width,x=x,y=y,z=z,begin=begin,duration=.8,direction=z>1 and-1 or 1,
  foldOffset=begin<4 and math.min(.06,math.max(0,(begin-3.12)*.12))or 0}
 for k,v in pairs(extra or{})do d[k]=v end
 if y>0 and d.mount~='lid'and not d.flowing then d.support=true end
 if d.height then d.heightScale=d.height/((r[4]-r[2])*width*30/(r[3]-r[1]));d.height=nil end
 out[#out+1]=d
end
local function stone(...)card('green-structure-v3.png',...)end
local function leaf(...)card('green-foliage-v3.png',...)end
local function detail(...)card('green-details-v3.png',...)end
local pool={4,273,600,496};local ledge={612,263,1165,492}
local stump={1181,223,1530,507};local thicket={6,612,670,896}
local rocks={674,599,1147,914};local flowers={1148,611,1528,893}
local terraceL={26,82,537,528};local terraceR={563,108,981,531}
local mountains={1006,149,1517,505};local falls={175,561,330,942}
local bank={458,686,984,943};local podium={1002,730,1518,944}
local treeL={11,13,548,655};local treeR={580,34,961,656}
local hanging={978,144,1527,562};local cloud={21,680,507,1003}
local fern={522,696,1057,1005};local berry={1070,699,1521,1005}
-- Lid and distant silhouettes retain open gaps revealing the silver mirrors.
leaf(hanging,2.20,-1.40,122,-3.60,3.12,{mount='lid',height=34,oscillate=.014,pivot=34})
leaf(hanging,1.63,1.61,128,-3.57,3.12,{mount='lid',height=29,mirror=true,oscillate=.012,pivot=29})
leaf(cloud,1.58,-1.24,104,-3.25,3.16,{mount='lid',height=36,oscillate=.018,pivot=36})
leaf(cloud,1.13,1.33,112,-3.30,3.18,{mount='lid',height=28,oscillate=.014,pivot=28})
stone(mountains,4.62,.05,43,-2.78,3.20,{height=80})
-- The small upper waterfall terminates behind the lower terrace, where its
-- paper foam conceals the join. Each cascading strip owns its flow shader.
stone(terraceL,2.58,-1.11,18,-2.46,3.28,{height=65})
stone(terraceR,2.35,1.25,16,-2.41,3.31,{height=68})
stone(falls,.53,.06,37,-2.30,3.34,{height=37,flowing=true})
detail(pool,2.02,.10,30,-2.20,3.36,{height=14,flowing=true})
detail(ledge,1.83,.06,16,-2.17,3.37,{height=21})
leaf(treeR,1.01,-1.97,57,-2.29,3.39,{sway=true,height=49})
leaf(treeL,1.20,1.94,52,-2.28,3.43,{sway=true,height=53})
stone(terraceL,2.04,-1.53,-1.35,-1.69,3.49,{height=48})
stone(terraceR,1.99,1.57,-1.35,-1.73,3.53,{height=49})
stone(falls,.70,.10,-1.35,-1.49,3.57,{height=44,flowing=true})
detail(pool,1.82,.11,-1.35,-1.38,3.60,{height=12,flowing=true})
leaf(treeL,1.62,-2.23,-1.35,-1.32,3.63,{height=71,sway=true})
leaf(treeR,1.32,2.27,-1.35,-1.43,3.67,{height=70,sway=true})
leaf(fern,1.00,-.97,1,-1.08,3.71,{sway=true})
leaf(berry,.94,1.04,0,-1.11,3.74,{sway=true})
-- Trainer rocks are beside the raised floor, not in the Pokemon footprints.
stone(podium,1.10,-2.37,-1.35,.54,4.05,{height=14.3})
stone(podium,1.10,2.37,-1.35,-.10,4.09,{height=14.3})
stone(bank,1.24,-2.39,-1.35,1.23,4.13,{height=18})
stone(bank,1.15,2.46,-1.35,1.04,4.17,{height=17,mirror=true})
leaf(fern,.79,-2.20,-1.35,1.84,4.21,{sway=true})
leaf(berry,.75,2.16,-1.35,1.90,4.24,{sway=true})
stone(bank,1.18,-1.33,-1.35,2.49,4.28,{height=14})
stone(bank,1.02,1.40,-1.35,2.45,4.31,{height=12,mirror=true})
leaf(fern,.62,-.48,-1.35,2.86,4.35,{sway=true})
leaf(berry,.56,.70,-1.35,2.88,4.38,{sway=true})
detail(rocks,.94,-2.55,-1.35,.10,3.80,{height=25})
detail(stump,.65,2.77,-1.35,-.72,3.84,{height=22})
detail(thicket,1.76,-1.78,-1.35,2.14,4.30,{height=23,sway=true})
detail(thicket,1.48,1.80,-1.35,2.21,4.32,{height=21,sway=true,mirror=true})
detail(flowers,.58,-.76,-1.35,2.86,4.36,{height=15,sway=true})
detail(flowers,.54,.71,-1.35,2.89,4.40,{height=13,sway=true,mirror=true})
return out
