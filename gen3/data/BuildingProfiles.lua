-- Authored surface roles for FireRed. These are coordinates/shape rules only;
-- colour and art always come from the user's native atlas at runtime.
local P={}

-- Source-local roof/facade boundaries measured in the native FireRed art.
-- Match the whole footprint: connected views and different shapes must not
-- inherit a city-wide eave. No atlas, collision or warp data is modified.
local fireRedRoofFolds={
 {map='FR_PEWTER_CITY',x=12,y=0,w=176,h=112,eave=70,backdrop=8},
 {map='FR_PEWTER_CITY',x=23,y=1,w=80,h=80,eave=62},
 {map='FR_PEWTER_CITY',x=32,y=9,w=80,h=64,eave=46},
 {map='FR_PEWTER_CITY',x=8,y=28,w=80,h=64,eave=46},
 {map='FR_CERULEAN_CITY',x=11,y=24,w=80,h=96,eave=54},
 {map='FR_VERMILION_CITY',x=8,y=3,w=80,h=80,eave=58},
 {map='FR_VERMILION_CITY',x=18,y=15,w=64,h=64,eave=42},
 {map='FR_VERMILION_CITY',x=27,y=22,w=64,h=64,eave=42},
 {map='FR_VERMILION_CITY',x=18,y=3,w=64,h=80,eave=58},
 {map='FR_VERMILION_CITY',x=25,y=3,w=80,h=80,eave=58},
 {map='FR_VERMILION_CITY',x=22,y=35,w=48,h=48,eave=30},
 {map='FR_LAVENDER_TOWN',x=8,y=9,w=80,h=64,eave=42},
 {map='FR_LAVENDER_TOWN',x=3,y=14,w=160,h=64,eave=42},
 {map='FR_CELADON_CITY',x=16,y=26,w=64,h=80,eave=42},
 {map='FR_CELADON_CITY',x=20,y=27,w=64,h=64,eave=42},
 {map='FR_CELADON_CITY',x=32,y=26,w=320,h=80,eave=42},
 {map='FR_CELADON_CITY',x=24,y=17,w=96,h=48,eave=30},
 {map='FR_CELADON_CITY',x=44,y=18,w=128,h=80,eave=42},
 {map='FR_CELADON_CITY',x=4,y=25,w=64,h=96,eave=58},
 {map='FR_FUCHSIA_CITY',x=32,y=28,w=160,h=80,eave=56},
 {map='FR_FUCHSIA_CITY',x=26,y=13,w=96,h=80,eave=56},
 {map='FR_FUCHSIA_CITY',x=13,y=28,w=160,h=80,eave=56},
 {map='FR_SAFFRON_CITY',x=17,y=11,w=192,h=80,eave=46},
 {map='FR_SAFFRON_CITY',x=41,y=35,w=144,h=80,eave=46},
 {map='FR_SAFFRON_CITY',x=50,y=8,w=64,h=80,eave=62},
 {map='FR_SAFFRON_CITY',x=18,y=35,w=64,h=80,eave=46},
 {map='FR_SAFFRON_CITY',x=19,y=42,w=192,h=64,eave=46},
 {map='FR_SAFFRON_CITY',x=39,y=42,w=192,h=64,eave=46},
 {map='FR_CINNABAR_ISLAND',x=5,y=0,w=112,h=64,eave=30},
 {map='FR_INDIGO_PLATEAU_EXTERIOR',x=6,y=0,w=176,h=128,eave=64},
}
-- Native Lilycove pane interiors, inclusive pixel bounds inside each 16px
-- metatile. The blue siding, eave teeth, window surrounds/sills and opaque
-- door panels share the generic 'blue glass' palette and must not emit.
-- 243/244 + 24B/24C are the mirrored-position fan-club window; the standard
-- house uses 23F/24D + 247/255. Motel panes cross 2A5/2AD vertically.
local lilycoveGlass={
 [0x243]={{11,13,14,15}},[0x244]={{1,13,4,15}},
 [0x23f]={{11,13,14,15}},[0x24d]={{1,13,4,15}},
 [0x24b]={{11,1,14,4}},[0x24c]={{1,1,4,4}},
 [0x247]={{11,1,14,4}},[0x255]={{1,1,4,4}},
 [0x2a5]={{1,14,6,15}},[0x2ad]={{1,0,6,3}},
}
-- Emerald's shared primary Mart art: only the blue door pane is glass.
-- The roof fascia/logo use similar blue hues but are opaque painted metal.
local emeraldMartGlass={[0x39]={{1,13,14,15}},[0x41]={{1,0,14,7}}}
-- Exact shared gym panes. Pale blue wall paint and entrance lintels are
-- opaque; only the three windows and the two door panes emit at night.
local hoennGymGlass={
 [0x1c0]={{11,2,15,4}},[0x1c1]={{0,2,4,4},{11,2,15,4}},
 [0x1c2]={{0,2,4,4}},[0x1c3]={{11,2,15,4}},[0x1c4]={{0,2,4,4}},
 [0x1c5]={{1,14,6,15},{9,14,14,15}},[0x1cd]={{1,0,6,6},{9,0,14,6}},
}
-- Dewford's sand-coloured gym preserves the same native pane geometry.
for a,b in pairs({[0x233]=0x1c0,[0x234]=0x1c1,[0x235]=0x1c2,[0x236]=0x1c3,[0x237]=0x1c4})do hoennGymGlass[a]=hoennGymGlass[b]end
local function finish(p)
 -- City-specific paper profiles must preserve the shared Mart sign aspect too.
 if p.foldWallScale==1 and p.paper then
  local paper={};for key,value in pairs(p.paper)do paper[key]=value end
  paper.wallScale=1;p.paper=paper
 end
 return p
end
function P.get(b,L)
 local mids={}
 for y=b.y0,b.y1 do for x=b.x0,b.x1 do mids[L:midAt(x,y)]=true end end
 local p={wallRows=math.max(2,b.y1-b.y0),rise=10,shape="profiled",scrub={},fold=true,foldWallScale=1.18}
 if b.mapId=='FR_PEWTER_CITY'and b.x0==12 and b.y0==0 and b.x1==22 and b.y1==6 then
  p.authoredGlass=true
  -- Six museum windows: only the individual 2x2 blue panes, never arches,
  -- stone columns, exhibits, surrounds or the pale entrance ornament.
  p.glassOverrides={[0x2a9]={},[0x2ad]={}}
  for _,y in ipairs{2,5,8}do
   for _,x in ipairs{1,5}do p.glassOverrides[0x2a9][#p.glassOverrides[0x2a9]+1]={x,y,x+1,y+1}end
   for _,x in ipairs{9,13}do p.glassOverrides[0x2ad][#p.glassOverrides[0x2ad]+1]={x,y,x+1,y+1}end
  end
 end
 -- Vermilion house doors: the outer blue panel is painted metal. Only
 -- the inset 8x8 pane inside the dark inner frame transmits light.
 if (b.renderPair or b.pair)=='general__rom_082d4b24'and mids[0x29e]then
  p.glassOverrides={[0x29e]={{4,3,11,10}}}
 end
 if type(b.mapId)=='string' and b.mapId:match('^EM_') and (b.renderPair or b.pair)
  and (b.renderPair or b.pair):match('^general__') and mids[0x30] and mids[0x31] and mids[0x32]
  and mids[0x33] and mids[0x38] and mids[0x39] and mids[0x3a] and mids[0x3b]
  and mids[0x41] and mids[0x42] then p.glassRects=emeraldMartGlass;p.foldWallScale=1 end
 if b.hoennLocalArchitecture or b.hoennLandmark then
  p.authoredGlass=true;p.nativeSilhouette=b.nativeSilhouette;p.cutAllBackdrop=b.cutAllBackdrop
  p.wallRows=((b.y1-b.y0+2)*16-b.eaveRow)/16
  p.paper=b.paperValues or{wallScale=1.18,roofScale=.60};p.glassRects={}
  -- Source-local measured panes become atlas-local rectangles. This avoids
  -- treating blue roof trim, pale siding or sign lettering as emissive glass.
  for _,r in ipairs(b.panes or{})do
   for ty=math.floor(r[2]/16),math.floor(r[4]/16)do for tx=math.floor(r[1]/16),math.floor(r[3]/16)do
    local mid=L:midAt(b.x0+tx,b.y0-1+ty)
    p.glassRects[mid]=p.glassRects[mid]or{}
    p.glassRects[mid][#p.glassRects[mid]+1]={math.max(0,r[1]-tx*16),math.max(0,r[2]-ty*16),math.min(15,r[3]-tx*16),math.min(15,r[4]-ty*16)}
   end end
  end
  return finish(p)
 end
 -- Only the measured city footprints opt in. Do not reinterpret Emerald's
 -- secondary tiles globally: that range also contains cliffs and fences.
 if b.exteriorPaper and ((b.mapId=='EM_RUSTBORO_CITY' and (b.renderPair or b.pair)=='general__rustboro')
  or (b.mapId=='EM_LILYCOVE_CITY' and (b.renderPair or b.pair)=='general__lilycove'))then
  p.wallRows=b.wallRows;p.paper={wallScale=1.18,roofScale=.60}
  -- Measured native pane geometry, not a blue-palette heuristic. In
  -- particular, 286's full-width blue strip is the motel door lintel.
  if b.mapId=='EM_LILYCOVE_CITY'then p.glassRects=lilycoveGlass end
  return finish(p)
 end
 if (b.renderPair or b.pair)=='general__fortree' then
  p.wallRows=b.wallRows or 2;p.paper={wallScale=1.08,roofScale=.60}
  if b.fortreeArchitecture then
   p.wallRows=2;p.paper.wallScale=b.fortreeArchitecture.wallScale;p.nativeCanopy=true
  end
  return finish(p)
 end
 if type(b.mapId)=='string'and b.mapId:match('^EM_')and(mids[0x19]and mids[0x11]or mids[0x1c5]and mids[0x1b3])then
  p.wallRows=2;p.paper={wallScale=1.18,roofScale=.60}
  if mids[0x1c5]and mids[0x1b3]then
   p.glassRects=hoennGymGlass
   if (b.renderPair or b.pair)=='general__sootopolis'then p.glassRects=setmetatable({[0x250]=hoennGymGlass[0x1cd]},{__index=hoennGymGlass})end
   if (b.renderPair or b.pair)=='general__lavaridge'then p.glassRects=setmetatable({[0x29f]=hoennGymGlass[0x1c4]},{__index=hoennGymGlass})end
  end
  return finish(p)
 end
 if (b.renderPair or b.pair)=='general__petalburg' then
  p.wallRows=2
  p.paper={wallScale=1.18,roofScale=.52}
  return finish(p)
 end
 -- Lavender's small house panes use the dark outline palette. Other city
 -- families reuse that colour for roof/foundation trim, so opt in explicitly.
 p.darkGlass=(b.renderPair or b.pair)=="general__rom_082d4b0c"
 local lavender=b.mapId=="FR_LAVENDER_TOWN"
 if lavender then p.wallScaleKey="lavenderHouseWallScale" end
 if (b.renderPair or b.pair)=="pallet_outdoor" then
  p.wallRows=2
  if mids[0x28a] then p.shape="pitched";p.rise=14;p.roofMid=0x28a
  else
   p.rise=0
   p.scrub={[0x2bd]=0x2a9,[0x2b3]=0x2b1,[0x2bb]=0x2b9,[0x2b5]=0x2a9,[0x2b4]=0x2b1,[0x2bc]=0x2b9}
   p.scrubEdge={[0x2b5]=0x2a9,[0x2b4]=0x2b1,[0x2bc]=0x2b9}
   p.chimney={mid=0x2b3,source=0x2b3,base=31,height=16}
  end
 elseif (b.renderPair or b.pair)=="viridian_outdoor" and mids[0x289] then
  p.wallRows=1;p.shape="pitched";p.rise=14;p.roofMid=0x289
  p.scrub={[0x2ab]=0x2aa,[0x283]=0x282,[0x28b]=0x289,[0x293]=0x291}
  p.chimney={mid=0x28b,source=0x28b,base=23,height=14}
 elseif (b.renderPair or b.pair)=="general__rom_082d4af4" and mids[0x2a9] then
  p.wallRows=1;p.shape="pitched";p.rise=12;p.roofMid=0x2a9
 elseif mids[0x48] or mids[0x49] then
  p.wallRows=2;p.rise=3;p.roofMid=0x49
  if lavender then p.wallScaleKey="lavenderCenterWallScale" end
 elseif mids[0x141] then
  p.wallRows=2;p.rise=6
 elseif mids[0x30] then
  p.wallRows=2;p.rise=6
 end
 -- Fit Pallet's projected roof/facade proportions independently of the
 -- fixed camera. Other native building families retain their measured shape.
 if (b.renderPair or b.pair)=="pallet_outdoor" then
  p.paper={wallScale=p.shape=="pitched" and 1.20 or 1.15,
    roofScale=p.shape=="pitched" and .36 or .55,
    depthScale=p.shape=="pitched" and .32 or .50,riseScale=.57,
    hip=p.shape=="pitched" and 6 or nil,roofTextureDepth=32}
 end
 -- The tower touches the north map edge: its first row is another storey,
 -- not the extra roof-trim row assumed for ordinary houses.
 if lavender and b.x0==15 and b.x1==21 and b.y0==0 and b.y1==6 then
  p.wallRows=7;p.landmark="lavenderTower"
 end
 -- FireRed's shared Mart badge is painted blue metal, not a window.
 -- Bounds are measured in the original 64x64 facade, including roof trim.
 local fr=type(b.mapId)=='string' and (b.mapId:match('^FR_')or b.mapId:match('^SEVII_ONE_ISLAND'))
 if fr and mids[0x30] and mids[0x31] and mids[0x32] and mids[0x33]
  and mids[0x38] and mids[0x39] and mids[0x3a] and mids[0x3b] then
  p.foldWallScale=1 -- Preserve the native Mart emblem aspect, without extra facade stretch.
  p.authoredGlass=true;p.glassRegions={{33,49,46,60}}
 end
 if b.mapId=='FR_CELADON_CITY'and b.x0==9 and b.y0==6 and b.x1==17 and b.y1==14 then
  -- The central bay panes exceed the generic small-window component limit.
  -- Author facade-only regions; native blue pixels preserve every mullion.
  p.authoredGlass=true;p.glassRegions={}
  for y=80,144,16 do
   for _,x in ipairs{12,52,116}do p.glassRegions[#p.glassRegions+1]={x,y,x==52 and 91 or x+15,y+12}end
  end
  for _,x in ipairs{33,41,97,105}do p.glassRegions[#p.glassRegions+1]={x,144,x+5,155}end
  p.wallRows=6;p.lightScaleKey='celadonDepartmentLightScale'
 end
 if b.celadonGameCorner then
  -- The yellow skylight field is roof artwork, not a bank of upper storeys.
  -- Grass and the sign in the extra source row stay at native ground level.
  p.backgroundRows=16
  p.roofGlassColors={[0xadd6ff]=true,[0xc5efff]=true}
 end
 if b.mapId=='FR_CERULEAN_CITY' and b.x0==11 and b.y0==24 and b.x1==15 and b.y1==28 then
  p.roofGlassColors={[0xaddeef]=true,[0x8cbdd6]=true,[0x73a5bd]=true}
 end
 -- Match the existing restrained Saffron decorative towers. A bank of
 -- twelve apartment windows must not burn the neighbouring department wall.
 if b.celadonHighRise then
  p.lightScale=.22
  if b.x0==27 and b.y0==4 then p.backgroundRows=24 end
 end
 if b.saffronSilph or b.mapId=='FR_SAFFRON_CITY'and b.x0==29 and b.y0==17 then p.lightScale=.20 end
 if b.mapId=='FR_SEVEN_ISLAND_TRAINER_TOWER'and b.x0==54 and b.y0==0 then
  -- Like Lavender, the top edge is a cropped storey, never a horizontal roof.
  p.wallRows=8;p.lightScale=.22
  -- Exact native rock palette. Keep this surrounding cliff artwork on the
  -- terrain plane instead of hoisting it with the blue tower facade.
  p.backgroundColors={[0xdec5a5]=true,[0x7b4a4a]=true,[0xbd948c]=true,
   [0x5a3a42]=true,[0x946b6b]=true,[0xefd6c5]=true}
 end
 -- The Route 5 day care reuses blue glass colours in its foundation trim.
 -- Keep the four window panes and door glass; never light the wall base.
 if b.mapId=='FR_ROUTE_5'and b.x0==21 and b.y0==22 then
  p.authoredGlass=true;p.glassRegions={{10,49,18,54},{21,49,29,54},{50,49,58,54},{61,49,69,54},{33,65,46,76}}
 end
 if b.forestGate or b.pierGate then
  p.authoredGlass=true;p.glassRects={
   [0x1b6]={{10,3,15,9}},[0x1b5]={{0,3,7,9},{9,3,15,9}},[0x1b7]={{0,3,5,9}},
  };p.lightScale=.18
 end
 if b.saffronGate or b.routeGate then
  -- Five long panes, bounded by their original mullions. Roof metal, pale
  -- side posts and the grey entrance panel are not emissive surfaces.
  local y=b.gatePaneTop or 51
  p.authoredGlass=true;p.glassRegions={{10,y,23,y+6},{25,y,39,y+6},{41,y,55,y+6},{57,y,71,y+6},{73,y,85,y+6}}
  p.lightScale=.35
 end
 if b.wallRows then p.wallRows=b.wallRows end
 local height=(b.y1-math.max(0,b.y0-1)+1)*16
 local width=(b.x1-b.x0+1)*16
 for _,f in ipairs(fireRedRoofFolds)do
  if b.mapId==f.map and b.x0==f.x and b.y0==f.y and width==f.w and height==f.h then
   p.wallRows=(height-f.eave)/16
   p.backgroundRows=f.backdrop or p.backgroundRows
   break
  end
 end
 return finish(p)
end
return P
