-- Native GBA artwork adapter for folded Paperworld buildings.
local V=...
local B={cache=setmetatable({},{__mode="k"})}
local function pixel(ts,mid,x,y)
  local slot=ts.midToSlot[mid] or (V.require("WorldGeometry").lenient and ts.midToSlot[0])
  if not slot then error(string.format("Missing native source pixel %03x in %s",mid,tostring(ts.pair))) end
  local ax,ay=slot%ts.cols*16+x,math.floor(slot/ts.cols)*16+y
  local r,g,b,a=ts.imageData:getPixel(ax,ay)
  if ts.overImageData then
    local rr,gg,bb,aa=ts.overImageData:getPixel(ax,ay)
    if aa>.5 then r,g,b,a=rr,gg,bb,aa end
  end
  return r,g,b,a,ax,ay
end
B.pixel=pixel
local function color(r,g,b)
  return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)
end
-- Snapshot tile IDs for one synchronous building build. Native script edits
-- are read afresh on the next build; never retain a second map-state cache.
function B.source(b,L)
 local y0=math.max(0,b.y0-1);local cols=b.x1-b.x0+1;local mids={}
 for y=y0,b.y1 do for x=b.x0,b.x1 do mids[#mids+1]=L:midAt(x,y)end end
 return function(x,y)
  return mids[math.floor(y/16)*cols+math.floor(x/16)+1],x%16,y%16
 end
end
function B.sprite(b,L,ts,originalArt)
  local spec=V.data("BuildingProfiles").get(b,L)
  local y0=math.max(0,b.y0-1)
  local W,H=(b.x1-b.x0+1)*16,(b.y1-y0+1)*16
  local source=B.source(b,L)
  local sea=V.require('FireRedSeaRocks');local coastalRoof=sea.roof(b,L)
  local sp={W=W,H=H,col={},ax={},ay={},inside={},faceDepth={},darkGlass={},roofGlass={}}
  local grass={}
  sp.background={}
  for y=0,15 do for x=0,15 do
    local r,g,blue=pixel(ts,spec.nativeCanopy and 1 or b.ground or 1,x,y)
    grass[color(r,g,blue)]=true
  end end
  local clear,seen,queue={},{},{}
  local function rowOrigin(mid,sy)
    local slot=ts.midToSlot[mid] or (V.require('WorldGeometry').lenient and ts.midToSlot[0])
    if not slot then error(string.format('Missing native source pixel %03x in %s',mid,tostring(ts.pair)))end
    return slot%ts.cols*16,math.floor(slot/ts.cols)*16+sy
  end
  -- Native artwork is made of 16-pixel cells. Resolve source cells and atlas
  -- row offsets once per run, instead of dividing/modulo-querying every pixel.
  -- Read the live ImageData as before; no second artwork cache is retained.
  for y=0,H-1 do for tileX=0,W-1,16 do
    local original=source(tileX,y);local mid=original
    -- A chimney belongs to a single roof object, never to the repeatable
    -- roof course. Substitute its clean sibling metatile before composition.
    if not originalArt then
      mid=spec.scrub[mid] or mid
    end
    local ax0,ay0=rowOrigin(mid,y%16)
    local edgeX,edgeY=ax0,ay0
    if not originalArt and spec.scrubEdge and spec.scrubEdge[original]then
      edgeX,edgeY=rowOrigin(spec.scrubEdge[original],y%16)
    end
    for sx=0,15 do
    local x=tileX+sx
    local ax,ay=(sx<4 and edgeX or ax0)+sx,sx<4 and edgeY or ay0
    local r,g,blue,a=ts.imageData:getPixel(ax,ay)
    if ts.overImageData then
      local rr,gg,bb,aa=ts.overImageData:getPixel(ax,ay)
      if aa>.5 then r,g,blue,a=rr,gg,bb,aa end
    end
    local i=y*W+x
    sp.ax[i],sp.ay[i]=ax,ay
    if y<H-spec.wallRows*16 and spec.roofGlassColors then
      sp.roofGlass[i]=spec.roofGlassColors[color(r,g,blue)] or false
    end
    if (spec.backgroundColors and spec.backgroundColors[color(r,g,blue)]) or y<(spec.backgroundRows or 0)then sp.background[i]=true end
    -- Original glass and door colours identify recessed facade surfaces.
    -- Keep the existing pixels; move their physical front behind the frame.
    if y>=H-spec.wallRows*16 then
      if spec.glassOverrides and spec.glassOverrides[original]then
        for _,rect in ipairs(spec.glassOverrides[original])do
          if x%16>=rect[1]and x%16<=rect[3]and y%16>=rect[2]and y%16<=rect[4]then sp.faceDepth[i]=2;break end
        end
      elseif spec.glassRegions then
        local bluePane=blue>r*1.25 and blue>g*1.02 and g>r*1.1 and g>.4
        if bluePane then for _,rect in ipairs(spec.glassRegions)do
          if x>=rect[1] and x<=rect[3] and y>=rect[2] and y<=rect[4]then sp.faceDepth[i]=2;break end
        end end
      elseif spec.authoredGlass and b.panes then
        -- Author masks in whole-building coordinates. Repeated native
        -- metatiles may hold different panes in each facade position.
        for _,rect in ipairs(b.panes)do
          if x>=rect[1] and x<=rect[3] and y>=rect[2] and y<=rect[4] then
            sp.faceDepth[i]=2;break
          end
        end
      elseif spec.glassRects then
        for _,rect in ipairs(spec.glassRects[original]or{})do
          if x%16>=rect[1] and x%16<=rect[3] and y%16>=rect[2] and y%16<=rect[4] then
            sp.faceDepth[i]=2;break
          end
        end
      else
      local brightGlass=blue>r*1.25 and blue>g*1.02 and g>r*1.1 and g>.4
      -- Lavender uses dark blue panes (66/74/107), not the usual bright
      -- cyan. Keep these candidates separate from geometry recesses and
      -- bright panes: the same dark colour also outlines ordinary windows.
      local darkGlass=spec.darkGlass and r<.35 and g>.15 and g<.42 and blue>g*1.3 and blue>r*1.4 and g>r*1.08
      sp.darkGlass[i]=darkGlass
      if brightGlass then sp.faceDepth[i]=2
      elseif r>g*1.25 and g>.2 and blue<r*.8 then sp.faceDepth[i]=1 end
      end
    end
    local lum=.2126*r+.7152*g+.0722*blue
    sp.col[i]=lum<.28 and 3 or lum<.52 and 2 or lum<.82 and 1 or 0
    clear[i]=a<.5 or grass[color(r,g,blue)] or (not spec.nativeCanopy and g>r*1.2 and blue>r*1.1 and g>blue*1.06 and g>.45)
  end end end
  local function seed(x,y)
    local i=y*W+x
    if not seen[i] and clear[i] then seen[i]=true;queue[#queue+1]=i end
  end
  for x=0,W-1 do seed(x,0);seed(x,H-1) end
  for y=0,H-1 do seed(0,y);seed(W-1,y) end
  local k=1
  while queue[k] do
    local i=queue[k];k=k+1
    local x,y=i%W,math.floor(i/W)
    if x>0 then seed(x-1,y) end;if x<W-1 then seed(x+1,y) end
    if y>0 then seed(x,y-1) end;if y<H-1 then seed(x,y+1) end
  end
  for i=0,W*H-1 do
    local cell=(y0+math.floor(math.floor(i/W)/16))*L.width+b.x0+math.floor((i%W)/16)+1
    if b.detachedProps and b.detachedProps[cell]then sp.inside[i]=false;sp.background[i]=false
    elseif coastalRoof and sea.roofBackdrop(coastalRoof,i%W,math.floor(i/W))then sp.inside[i]=false
    elseif sp.background[i] then sp.inside[i]=false
    elseif b.slateportMuseum then sp.inside[i]=V.require('EmeraldSlateportExterior').museumInside(b,L,ts,i%W,math.floor(i/W))
    elseif spec.nativeSilhouette then sp.inside[i]=V.require('EmeraldSootopolisHouses').inside(spec.nativeSilhouette,i%W,math.floor(i/W))
    elseif spec.cutAllBackdrop then sp.inside[i]=not clear[i]
    else sp.inside[i]=not seen[i]end
  end
  local roofRows=H-spec.wallRows*16
  local donor={x=math.min(16,W-16),y=math.min(16,math.max(0,roofRows-16)),width=16,height=16}
  if spec.roofMid then
    for cy=y0,b.y1 do for cx=b.x0,b.x1 do
      if L:midAt(cx,cy)==spec.roofMid then
        donor.x,donor.y=(cx-b.x0)*16,(cy-y0)*16
      end
    end end
  end
  return sp,{roofShape=spec.shape,roofDonor=donor,authoredGlass=spec.authoredGlass,
    roofRows=roofRows,slab=3,rise=spec.rise,roofBack=4,roofFront=4,
    hip=spec.paper and spec.paper.hip,roofTextureDepth=spec.paper and spec.paper.roofTextureDepth,
    roofCycle={math.min(16,roofRows-5),roofRows-5},frontEave=1,
    depthPx=(b.y1-b.y0+1)*16}
end
function B.build(out,b,L,ts,ox,oz)
  if b.forestRearGate then return V.require("ForestGateRoof").build(out,b,L,ts,ox,oz)end
  if V.require("FireRedTowerExterior").kind(b)then return V.require("FireRedTowerExterior").build(out,b,L,ts,ox,oz)end
  if b.lilycoveMuseum then return V.require('EmeraldLilycoveMuseum').build(out,b,L,ts,ox,oz)end
  return V.require("PaperBuildings").build(out,b,L,ts,ox,oz)
end
return B
