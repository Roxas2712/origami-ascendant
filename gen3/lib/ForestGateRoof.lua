-- The south forest exit is the back of the same broad native gatehouse.
-- Raise its own roof in place; reuse native brickwork below its side eaves.
-- The leaf tunnel and warp row north of the roof remain entirely untouched.
local V=...
local F={}
function F.build(out,b,L,ts,ox,oz)
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite')
 local BM=V.require('BuildingMesh')
 local x0,z0=(b.x0+ox)*16,(b.y0-1+oz)*16
 local width,depth=(b.x1-b.x0+1)*16,(b.y1-b.y0+2)*16
 local wall=48*1.18*V.require('Billboard').heightScale();local rise=7
 local function append(vertices)for _,v in ipairs(vertices)do out[#out+1]=v end end
 local source=BM.source(b,L)
 append(P.build(ts,width,depth,source,function()return true end,0,0,1,
  function()return G.BUILDING_ROOF end,
  function(x,y)return {x0+x,wall+rise*(1-y/depth),z0+y}end,.5))
 local function brick(x,y)return 0x05d,x%16,y%16 end
 -- Close the near wall too: omitting it exposes the donor grass beneath a
 -- floating roof. This cropped side has no traversable/native entrance.
 append(P.build(ts,width,48,function(x,y)return y<16 and 0x1b5 or 0x05d,x%16,y%16 end,
  function()return true end,0,0,1,function()return 3.2 end,
  function(x,y)return {x0+x,wall*(1-y/48),z0+depth,0,0,-1}end,.5))
 -- Side walls use opaque native masonry, never the roof/window palette.
 for _,side in ipairs{0,width}do
  append(P.build(ts,depth,48,brick,function()return true end,0,0,1,function()return 3.2 end,
   function(x,y)return {x0+side,(wall+rise*(1-x/depth))*(1-y/48),z0+x,0,0,-1}end,.5))
 end
 -- The rear opening is centred on the original three-cell entrance. Reuse
 -- the north gate's matching original arch and brick frontage, at this eave.
 append(P.build(ts,width,48,function(x,y)return L:midAt(math.floor(x/16),7+math.floor(y/16)),x%16,y%16 end,
  function()return true end,0,0,1,function()return 3.2 end,
  function(x,y)return {x0+x,(wall+rise)*(1-y/48),z0,0,0,-1}end,.5))
 return {}
end
return F
