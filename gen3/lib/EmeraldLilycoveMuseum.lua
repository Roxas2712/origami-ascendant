-- Two native roof levels, one recessed entrance, and untouched approach tiles.
-- Pixel coordinates refer to the original 160x112 museum art at map (7,0).
local V=...
local M={}
function M.buildings(d)
 local c=V.require('DioramaConfig').lilycoveMuseum
 if not c.enabled or d.id~='EM_LILYCOVE_CITY'or d.pair~='general__lilycove'then return{}end
 return{{x0=7,x1=16,y0=1,y1=6,doorX=11,doorY=5,facadeBaseY=7,
  ground=1,lilycoveMuseum=true}}
end
function M.role(x,y)
 if x<0 or x>=160 or y<8 or y>=112 then return nil end
 if y<32 and(x<40 or x>=120)then return nil end
 if x>=40 and x<120 and y<64 then return y<48 and'upperRoof'or'upperWall'end
 if y<72 then return'lowerRoof'end
 if x>=64 and x<96 and y>=88 then return y<96 and'entrance'or nil end
 return'lowerWall'
end
function M.glass(x,y)
 for _,a in ipairs({52,57,76,81,100,105})do
  if x>=a and x<a+3 and(y==48 or y==50 or y==51 or y==53 or y==54)then return true end
 end
 for _,a in ipairs({11,18,35,42,114,121,138,145})do
  if x>=a and x<a+4 and(y==81 or y>=83 and y<=87)then return true end
 end
 return false
end
function M.project(role,x,y)
 local c=V.require('DioramaConfig').lilycoveMuseum
 local scale=c.wallScale*V.require('Billboard').heightScale()
 local h=40*scale
 local function lower(y)return h+(72-y)*c.roofRise/40,112-(72-y)*c.roofDepthScale end
 if role=='lowerRoof'then local a,b=lower(y);return{x,a,b}end
 if role=='upperRoof'or role=='upperWall'then
  local a,b=lower(64)
  if role=='upperWall'then return{x,a+(64-y)*scale,b}end
  return{x,a+16*scale+(48-y)*c.upperRoofRise/40,b-(48-y)*c.roofDepthScale}
 end
 if role=='entrance'then return{x,(96-y)*3*scale,96}end
 return{x,(112-y)*scale,112}
end
function M.floor(out,b,L,ts,x,y,ox,oz)
 local G=V.require('WorldGeometry');local sx,sy=(x-7)*16,y*16
 local vv=V.require('PaperSprite').build(ts,16,16,function(px,py)
  return M.role(sx+px,sy+py)and b.ground or L:midAt(x,y),px,py
 end,function()return true end,0,0,1,nil,function(px,py)return{(x+ox)*16+px,0,(y+oz)*16+py}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
end
function M.build(out,b,L,ts,ox,oz)
 local start=#out
 local G=V.require('WorldGeometry');local S=V.require('PaperSprite');local BM=V.require('BuildingMesh')
 local c=V.require('DioramaConfig').lilycoveMuseum
 local function source(x,y)return L:midAt(7+math.floor(x/16),math.floor(y/16)),x%16,y%16 end
 local sp={W=160,H=112,inside={},faceDepth={},ax={},ay={}}
 for y=0,111 do for x=0,159 do local i=y*160+x
  sp.inside[i]=M.role(x,y)~=nil;sp.faceDepth[i]=M.glass(x,y)and 2 or nil
  local _,_,_,_,ax,ay=BM.pixel(ts,source(x,y));sp.ax[i],sp.ay[i]=ax,ay
 end end
 local LL=V.require('LocalLights');local lights,glass=LL.windows(sp,{roofRows=48,authoredGlass=true,depthPx=96})
 LL.registerGlass(ts,sp,glass)
 for _,role in ipairs({'lowerRoof','upperRoof','upperWall','lowerWall','entrance'})do
  local roof=role=='lowerRoof'or role=='upperRoof'
  local vv=S.build(ts,160,112,source,function(x,y)return M.role(x,y)==role end,0,112,1,
   function()return roof and G.BUILDING_ROOF or 3 end,function(x,y)return M.project(role,x,y)end,.5,
   function(x,y)return glass[y*160+x]and 0 or -1 end)
  for _,v in ipairs(vv)do out[#out+1]=G.place(v,(7+ox)*16,oz*16)end
 end
 local sourceVertices=#out-start
 -- Native doorway row 5 is one tile behind the front wings. Close the
 -- lintel and jamb returns with their own native edge texels, never a black
 -- shadow wedge or a false lawn strip across solid building cells.
 local scale=c.wallScale*V.require('Billboard').heightScale()
 local function append(vv)for _,v in ipairs(vv)do out[#out+1]=G.place(v,(7+ox)*16,oz*16)end end
 for _,side in ipairs({{64,63},{96,96}})do
  append(S.build(ts,1,24,function(_,t)return source(side[2],88+t)end,function()return true end,0,0,1,
   function()return 3 end,function(s,t)return{side[1],(24-t)*scale,96+s*16}end,.5,function()return -1 end))
 end
 append(S.build(ts,32,1,function(s)return source(64+s,87)end,function()return true end,0,0,1,
  function()return 3 end,function(s,t)return{64+s,24*scale,96+t*16}end,.5,function()return -1 end))
 local result={}
 for _,l in ipairs(lights)do
  local y=112-l.y;local p=M.project(y<64 and'upperWall'or'lowerWall',l.x,y)
  result[#result+1]={x=(7+ox)*16+p[1],y=p[2],z=oz*16+p[3]+.2,
   radius=c.lightRadius,power=l.power*c.lightStrength,facadeBounce=V.require('DioramaConfig').lighting.houseBounce}
 end
 return result,{sourceVertices=sourceVertices,returnVertices=#out-start-sourceVertices}
end
return M
