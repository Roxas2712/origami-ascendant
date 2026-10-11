-- Original native elevations folded at the roofline: every floor, sign and
-- facade ornament survives intact instead of becoming repeated roof material.
local V=...
local cfg=V.require('DioramaConfig').lighting
local P={cache=setmetatable({},{__mode='k'})}
function P.build(out,b,L,ts,ox,oz)
 local BM=V.require('BuildingMesh');local spec=V.data('BuildingProfiles').get(b,L)
 local variation=V.require('WindowVariation');local lampKey=variation.buildingKey(b)
 local frDetailed=(tostring(b.mapId):match('^FR_')or tostring(b.mapId):match('^SEVII_ONE_ISLAND')) and b.mapId~='FR_PALLET_TOWN'
 local isLab=b.pair=='pallet_outdoor' and spec.shape~='pitched'
 local y0=math.max(0,b.y0-1);local key={b.x1-b.x0,spec.wallRows}
 for y=y0,b.y1 do for x=b.x0,b.x1 do key[#key+1]=L:midAt(x,y)end end
 key=table.concat(key,',')..':'..tostring(b.ground)..':'..tostring(spec.wallScaleKey)..':'..tostring(spec.landmark)..':'..tostring(b.mapId)
 local cache=P.cache[ts]or{};P.cache[ts]=cache
 local item=cache[key]
 if not item then
  local sp,profile=BM.sprite(b,L,ts,true)
  local base=sp.H
  for y=sp.H-1,0,-1 do
   local any=false;for x=0,sp.W-1 do if sp.inside[y*sp.W+x]then any=true;break end end
   if any then base=y+1;break end
  end
  local line=math.min(profile.roofRows,base-8)
  local landmark=spec.landmark and V.require('DioramaConfig').buildings[spec.landmark]
  local wallScale=landmark and landmark.wallScale or spec.wallScaleKey and V.require('DioramaConfig').buildings[spec.wallScaleKey]
    or spec.paper and spec.paper.wallScale or spec.foldWallScale
  wallScale=wallScale*V.require('Billboard').heightScale()
  local wall=(base-line)*wallScale
  local rise=math.min(7,line*.16)
  local elevation=V.require("Camera").elevation()
  local uy,uz=math.cos(elevation),-math.sin(elevation)
  local roofScale=spec.paper and spec.paper.roofScale or .60
  local depth=math.max(4,(line*roofScale-rise*uy)/-uz)
  -- Roof and facade use distinct transforms, sharing one exact eave line.
  -- The old per-vertex bevel switched z at y==line, folding the final roof
  -- strip diagonally and producing triangular corner notches/slivers.
  local windowRows=landmark and landmark.litWindowRows
  local function windowEligible(y)return not windowRows or y>=windowRows[1] and y<=windowRows[2]end
  local function facadePoint(x,y)
   local height=(base-y)*wallScale
   if landmark and landmark.baseRows then
    local lower=math.min(base-y,landmark.baseRows)
    height=height+lower*(landmark.baseWallScale-landmark.wallScale)*V.require('Billboard').heightScale()
   end
   return {x,height,0,0,landmark and y or 0,windowEligible(y) and 0 or -1}
  end
  local function roofPoint(x,y)
   local t=(line-y)/math.max(1,line)
   return {x,wall+t*rise,-t*depth}
  end
  local lights,glass,owners=V.require('LocalLights').windows(sp,profile)
  local roofLights,roofGlass,roofOwners=V.require('LocalLights').windows(sp,profile,true)
  for i in pairs(roofGlass)do glass[i]=true end
  for index,l in ipairs(roofLights)do l.roof=true;l.variationCode=lampKey and variation.code(lampKey,index+32,false)end
  for index,l in ipairs(lights)do l.variationCode=lampKey and variation.code(lampKey,index,frDetailed) end
  -- Repeated tower metatiles share atlas pixels across floors. Keep an
  -- independent vertex eligibility flag and omit lights on the dark floors.
  if windowRows then
   for i=#lights,1,-1 do if not windowEligible(base-lights[i].y)then table.remove(lights,i)end end
  end
  if landmark and landmark.castsLight==false then lights={} end
  local ghost
  if spec.landmark=='lavenderTower' then
   ghost={}
   for y=0,math.min(45,sp.H-1)do for x=0,sp.W-1 do
    local i=y*sp.W+x
    if sp.inside[i] then
     local m=L:midAt(b.x0+math.floor(x/16),y0+math.floor(y/16))
     if V.require('GhostWindows').sidePane(x,y,BM.pixel(ts,m,x%16,y%16))then ghost[i]=true end
    end
   end end
  end
  V.require('LocalLights').registerGlass(ts,sp,glass,ghost)
  local source=BM.source(b,L)
  local sprite=V.require('PaperSprite')
  local G=V.require('WorldGeometry')
  -- Integer source rows/columns; half-texel UVs sample only each native run.
  -- A one-pixel row uses its texel center, preventing adjacent atlas bleed.
  local vertices=sprite.build(ts,sp.W,line,source,
   function(x,y)return sp.inside[y*sp.W+x]end,0,base,1,
   function()return G.BUILDING_ROOF end,roofPoint,.5,next(roofGlass) and function(x,y)
    local owner=roofOwners[y*sp.W+x]
    return owner and (lampKey and variation.code(lampKey,owner+32,false)or .25)or -1
   end or nil)
  local facade=sprite.build(ts,sp.W,sp.H,source,
   function(x,y)return y>=line and sp.inside[y*sp.W+x]end,0,base,1,
   function(x,y)
    local edge=math.max(0,1-math.min(x,sp.W-1-x)/4)
    local eave=math.max(0,1-(y-line)/4)
    return (isLab and 2 or 3)+math.min(.40,edge*.28+eave*.20+cfg.facadeRoofShade/.65*(base-y)/(base-line))
   end,facadePoint,.5,(spec.authoredGlass or spec.glassRects or frDetailed or lampKey) and function(x,y)
    if not windowEligible(y) or not glass[y*sp.W+x]then return -1 end
    local owner=owners[y*sp.W+x]
    return lampKey and owner and variation.code(lampKey,owner,frDetailed) or (frDetailed and 1 or 0)
   end or nil)
  for _,v in ipairs(facade)do vertices[#vertices+1]=v end
  -- The native bottom eave row belongs to the roof. Continue it by one source
  -- pixel on the roof plane over the facade, hiding subpixel raster cracks.
  -- This is original roof-edge artwork, not an untextured/black side wall.
  if line>0 then
  local apron=sprite.build(ts,sp.W,1,function(x)return source(x,line-1)end,
   function(x)return sp.inside[(line-1)*sp.W+x]end,0,1,1,
   function()return G.BUILDING_ROOF end,
   function(x,y)return roofPoint(x,line+y)end,.5)
  for _,v in ipairs(apron)do vertices[#vertices+1]=v end
  end
  for _,l in ipairs(lights)do
   local p=facadePoint(l.x,base-l.y);l.x,l.y,l.z=p[1],p[2],p[3]+.2
   l.radius=math.min(112,72+l.y*.60);l.power=l.power*.35
  end
  -- Small roof-local sources illuminate the rim without shining through the
  -- building into the street. Their true roof height also reflects in water.
  for _,l in ipairs(roofLights)do
   local p=roofPoint(l.x,base-l.y);l.x,l.y,l.z=p[1],p[2]+1,p[3]
   l.radius=-12;l.power=l.power*.09;l.point=true
   lights[#lights+1]=l
  end
  if spec.backgroundColors or spec.backgroundRows then
   local background=sprite.build(ts,sp.W,sp.H,source,
    function(x,y)return sp.background[y*sp.W+x]end,0,0,1,function()return 1 end,
    function(x,y)return {x,.03,y-sp.H}end,.5)
   for _,v in ipairs(background)do vertices[#vertices+1]=v end
  end
  item={vertices=vertices,lights=lights,lampKey=lampKey};cache[key]=item
 end
 local canopy=V.require('SeasonalFoliage').canopyBuilding(b,L)
 local xx,zz=(b.x0+ox)*16,((b.facadeBaseY or b.y1+1)+oz)*16
 local base=V.require("EmeraldFortreeArchitecture").buildingBase(b)+V.require("EmeraldPacifidlog").buildingBase(b)
 -- Identical native facades share geometry, but each placed house owns its
 -- lamp schedule. Codes reserve 1/1024 per house, so rebasing is exact and
 -- keeps pane identity, glass style, UVs and the cached template unchanged.
 local lampShift=lampKey and item.lampKey and (lampKey-item.lampKey)/1024 or 0
 for _,v in ipairs(item.vertices)do
  local p=V.require("WorldGeometry").place(v,xx,zz);p[2]=p[2]+base
  local code=p[9]
  if lampShift~=0 and(code>=.125 and code<.25 or code>=.625 and code<.75)then p[9]=code+lampShift end
  if canopy then p[9]=-4 end -- stationary native foliage; no billboard rotation/wind
  out[#out+1]=p
 end
 local lights={}
 local cfg=V.require('DioramaConfig').lighting
 local lightScale=(b.lightScaleKey or spec.lightScaleKey) and V.require('DioramaConfig').buildings[b.lightScaleKey or spec.lightScaleKey] or b.lightScale
 local strength=(isLab and cfg.labStrength or 1)*(lightScale or spec.lightScale or 1)
 local bounce=isLab and cfg.labBounce or cfg.houseBounce
 for _,l in ipairs(item.lights)do lights[#lights+1]={x=l.x+xx,y=l.y+base,z=l.z+zz,radius=l.radius,power=l.power*strength,point=l.point,facadeBounce=l.roof and 0 or bounce,variationCode=l.variationCode and l.variationCode+lampShift}end
 if isLab and b.doorX then
  lights[#lights+1]={x=(b.doorX+ox+.5)*16,y=cfg.labHotspotHeight*V.require('Billboard').heightScale(),z=zz+.2,
    radius=cfg.labHotspotRadius,power=cfg.labHotspotStrength,facadeBounce=1,wallOnly=true}
 end
 return lights
end
function P.release()P.cache=setmetatable({},{__mode='k'})end
return P
