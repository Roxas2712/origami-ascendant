-- Exact native Slateport footprints and measured glass; roofs/signs never emit.
local V=...
local M={}
local specs={
 -- Two native museum warps share one facade. The white sea wall behind its
 -- roof is background art in the same metatiles and must remain on the map.
 {name='museum',x0=28,x1=33,y0=23,y1=27,doorX=30,doorY=26,facadeBaseY=27,eaveRow=56,slateportMuseum=true,
  panes={{35,56,36,56},{34,57,37,60},{43,56,44,56},{42,57,45,60},{51,56,52,56},{50,57,53,60},{59,56,60,56},{58,57,61,60},{19,64,20,64},{18,65,21,68},{75,64,76,64},{74,65,77,68}}},
 {name='annex',x0=24,x1=29,y0=42,y1=44,doorX=26,doorY=44,eaveRow=38,renderOnly=true,panes={{18,44,22,44},{25,44,29,44},{50,44,54,44},{57,44,61,44},{18,46,22,46},{25,46,29,46},{50,46,54,46},{57,46,61,46},{18,47,22,47},{25,47,29,47},{50,47,54,47},{57,47,61,47},{18,48,22,48},{25,48,29,48},{50,48,54,48},{57,48,61,48},{18,50,22,50},{25,50,29,50},{50,50,54,50},{57,50,61,50},{18,51,22,51},{25,51,29,51},{50,51,54,51},{57,51,61,51},{18,52,22,52},{25,52,29,52},{50,52,54,52},{57,52,61,52}}},
 {name='tent',x0=8,x1=12,y0=9,y1=12,doorX=10,doorY=12,eaveRow=0,panes={{32,65,38,65},{41,65,47,65},{37,66,38,66},{41,66,42,66},{38,67,38,67},{41,67,41,67},{38,68,38,68},{41,68,41,68},{37,69,38,69},{41,69,42,69},{32,70,38,70},{41,70,47,70},{32,71,38,71},{41,71,47,71},{32,72,38,72},{41,72,47,72},{32,73,38,73},{41,73,47,73},{32,74,38,74},{41,74,47,74},{32,75,38,75},{41,75,47,75}}},
 {name='harbor',x0=25,x1=31,y0=8,y1=12,doorX=28,doorY=12,eaveRow=62,panes={{30,66,33,66},{78,66,81,66},{28,67,35,67},{76,67,83,67},{28,68,35,68},{76,68,83,68},{27,69,36,69},{75,69,84,69},{27,70,36,70},{75,70,84,70},{27,71,36,71},{75,71,84,71},{27,72,36,72},{75,72,84,72},{29,73,34,73},{77,73,82,73},{30,74,33,74},{78,74,81,74},{30,75,33,75},{78,75,81,75}}},
 {name='rater',x0=4,x1=7,y0=17,y1=19,doorX=5,doorY=19,eaveRow=38,panes={{34,44,38,44},{41,44,45,44},{34,46,38,46},{41,46,45,46},{34,47,38,47},{41,47,45,47},{20,48,27,48},{34,48,38,48},{41,48,45,48},{20,49,27,49},{20,50,27,50},{34,50,38,50},{41,50,45,50},{20,51,27,51},{34,51,38,51},{41,51,45,51},{34,52,38,52},{41,52,45,52}}},
 {name='fan',x0=2,x1=6,y0=23,y1=26,doorX=4,doorY=26,eaveRow=54,panes={{5,56,5,56},{74,56,74,56},{5,57,5,57},{74,57,74,57},{5,58,5,58},{7,58,7,58},{72,58,72,58},{74,58,74,58},{5,59,5,59},{7,59,7,59},{18,59,20,59},{22,59,25,59},{27,59,27,59},{52,59,52,59},{54,59,57,59},{59,59,61,59},{72,59,72,59},{74,59,74,59},{5,60,5,60},{7,60,7,60},{18,60,20,60},{22,60,25,60},{27,60,27,60},{52,60,52,60},{54,60,57,60},{59,60,61,60},{72,60,72,60},{74,60,74,60},{7,61,7,61},{18,61,20,61},{22,61,25,61},{27,61,27,61},{52,61,52,61},{54,61,57,61},{59,61,61,61},{72,61,72,61},{7,62,7,62},{18,62,20,62},{22,62,25,62},{27,62,27,62},{52,62,52,62},{54,62,57,62},{59,62,61,62},{72,62,72,62}}},
 {name='shipyard',x0=24,x1=31,y0=33,y1=38,doorX=26,doorY=38,eaveRow=70,panes={}},
 {name='house',x0=20,x1=23,y0=42,y1=44,doorX=21,doorY=44,eaveRow=38,panes={{34,44,38,44},{41,44,45,44},{34,46,38,46},{41,46,45,46},{34,47,38,47},{41,47,45,47},{20,48,27,48},{34,48,38,48},{41,48,45,48},{20,49,27,49},{20,50,27,50},{34,50,38,50},{41,50,45,50},{20,51,27,51},{34,51,38,51},{41,51,45,51},{34,52,38,52},{41,52,45,52}}},
}
function M.buildings(d)
 local c=V.require('DioramaConfig').slateportArchitecture
 if not c.enabled or d.id~='EM_SLATEPORT_CITY'or d.pair~='general__slateport'then return{}end
 local out={};for _,s in ipairs(specs)do local b={};for k,v in pairs(s)do b[k]=v end
  b.hoennLandmark=true;b.slateportArchitecture=true;b.ground=1;b.lightScale=c.lightScale
  if b.slateportMuseum then b.lightScale=c.museumLightScale end
  b.paperValues={wallScale=b.name=='tent'and c.tentScale or c.wallScale,roofScale=c.roofScale};out[#out+1]=b
 end;return out
end
local grass=setmetatable({},{__mode='k'})
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function M.museumInside(b,L,ts,x,y)
 if y<8 or y>=88 then return false end
 local lo=y<=9 and 8 or y==10 and 3 or y==11 and 2 or y==12 and 1 or 0
 if x<lo or x>95-lo then return false end
 if y<=51 then return true end
 local BM=V.require('BuildingMesh');local colors=grass[ts]
 if not colors then
  colors={};for py=0,15 do for px=0,15 do colors[rgb(BM.pixel(ts,b.ground,px,py))]=true end end;grass[ts]=colors
 end
 local mid=L:midAt(b.x0+math.floor(x/16),b.y0-1+math.floor(y/16))
 return not colors[rgb(BM.pixel(ts,mid,x%16,y%16))]
end
function M.museumFloor(out,b,L,ts,x,y,ox,oz)
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 local mid=L:midAt(x,y);local rx,ry=(x-b.x0)*16,(y-b.y0+1)*16
 local vv=V.require('PaperSprite').build(ts,16,16,function(px,py)
  return M.museumInside(b,L,ts,rx+px,ry+py)and b.ground or mid,px,py
 end,function()return true end,0,0,1,nil,function(px,py)return{xx+px,0,zz+py}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
end
return M
