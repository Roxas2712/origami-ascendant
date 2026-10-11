-- Render-only rock volumes. Never modify native cells, elevation or collision.
local V=...
local Budget=V.require('BuildBudget')
local T={}
local cliffTemplates=setmetatable({},{__mode="k"})
local function cliffPlace(v,x,z)
 return {v[1]+x,v[2],v[3]+z,v[4],v[5],v[6],v[7],v[8],v[9]}
end
local outdoorRock={ [0x68]=true,[0x69]=true,[0x6a]=true,[0x6b]=true,[0x6c]=true,[0x6d]=true,
 [0x70]=true,[0x71]=true,[0x72]=true,[0x73]=true,[0x75]=true,
 [0x78]=true,[0x79]=true,[0x7a]=true,[0x7b]=true,[0x7c]=true,[0x7d]=true }
-- Shared FireRed concave joins. These native rock-only tiles bridge the
-- straight cliff family; leaving them at ground height cut square notches.
-- Keep them separate from the Emerald family and mixed tree/stair tiles.
local fireRedCliffJoins={[0xb2]=true,[0xb3]=true,[0xba]=true,[0xbb]=true}
-- These rocky underground atlases share the original cap/wall family.
-- Ice, indoor tunnels and unrelated secondary artwork are deliberately excluded.
local cavePairs={general__rom_082d4e0c=true,general__rom_082d4bfc=true,general__rom_082d4df4=true,general__rom_082d4e54=true}
local caveRock={ [0x28f]=true,[0x289]=true,[0x28a]=true,[0x290]=true,[0x291]=true,[0x292]=true,
 [0x298]=true,[0x299]=true,[0x29b]=true,[0x29c]=true,[0x2a3]=true,[0x2a4]=true,
 [0x2cf]=true,[0x2d0]=true,[0x2d1]=true,[0x2d2]=true,[0x2d8]=true,[0x2da]=true,
 [0x2e0]=true,[0x2e1]=true,[0x2e2]=true }
function T.kind(def,c)
 if not c or not V.require('DioramaConfig').terrain.enabled then return nil end
 if V.data('Emerald').map(def)then
  if V.require('EmeraldNavelSanctums').profile(def)then return V.require('EmeraldNavelSanctums').kind(def,c)end
  if V.require('EmeraldNavelPassages').profile(def)then return V.require('EmeraldNavelPassages').kind(def,c)end
  if V.require('EmeraldMirageTower').profile(def)then return V.require('EmeraldMirageTower').kind(def,c)end
  if V.require('EmeraldSeafloorCurrents').profile(def)then return V.require('EmeraldSeafloorCurrents').kind(def,c)end
  if V.require('EmeraldMagmaHideout').profile(def)then return V.require('EmeraldMagmaHideout').kind(def,c)end
  if V.require('EmeraldRusturf').profile(def)then return V.require('EmeraldRusturf').kind(def,c)end
  if V.require('EmeraldFieryPath').profile(def)then return V.require('EmeraldFieryPath').kind(def,c)end
  local coast=V.require('EmeraldCoastCliffs').kind(def,c);if coast then return coast end
  if c.coll>=0xa0 and c.coll<=0xa7 then
   return V.require('CaveTerrain').applies(def) and 'caveLedge' or 'ledge'
  end
  if c.coll~=7 then return nil end
  local m,p=c.mid,(def.renderPair or def.pair)
  if tonumber(def.mapType)==4 and (p=='general__cave' or p=='general__meteor_falls') and m>=0x201 then return 'wall' end
  if p=='general__underwater' and m>=0x202 and m~=0x228 then
   if V.require('EmeraldUnderwater').active(def)and m>=0x2e0 and m<=0x2e7 then return nil end
   if V.require('EmeraldUnderwaterTerrain').active(def)then return 'emUnderwaterWall'end
   return 'wall'
  end
  if p=='general__lavaridge' and (m>=0x268 and m<=0x27f or m>=0x300 and m<=0x30f)then return 'wall' end
  if V.data('EmeraldLandscapes')[def.id or def.name] and (outdoorRock[m]or m==0x89 or m==0x91 or m==0xa9)then return 'wall' end
  return nil
 end
 if V.require('FireRedTerracedCaves').profile(def)then return V.require('FireRedTerracedCaves').kind(def,c)end
 if V.require('TanobyKey').profile(def)then return V.require('TanobyKey').kind(def,c)end
 if V.require('FireRedDiglettCave').profile(def)then return V.require('FireRedDiglettCave').kind(def,c)end
 if V.require('FireRedLostCave').profile(def)then return V.require('FireRedLostCave').kind(def,c)end
 local ruin=V.require('FireRedRuinCaves').kind(def,c);if ruin then return ruin end
 local ember=V.require('FireRedEmber').kind(def,c);if ember then return ember end
 local S=V.data('Shapes');local mid=S.surfaceMid(def,c.mid)
 -- 0x71 is the solid rock cap, including decorative collision-0 filler
 -- on Route 22. Its native walkability does not flatten its artwork.
 if S.outdoors(def)then
  if (outdoorRock[mid]or fireRedCliffJoins[mid]or V.require("FireRedCliffContours").variant(def,mid)) and(S.solid(c)or mid==0x71 and(def.id or def.name)=='FR_ROUTE_22')then return 'cliff' end
  if mid==0xa9 and c.coll==0x71 then return 'entrance' end
  if S.prop(def,c)=='ledge' or c.coll>=0x38 and c.coll<=0x3b then return 'ledge' end
 elseif tonumber(def.mapType)==4 and cavePairs[(def.renderPair or def.pair)] and caveRock[mid]then return 'wall' end
end
function T.height(kind)
 if kind=='emUnderwaterWall'then return V.require('DioramaConfig').underwater.terrain.height end
 if kind=='emNavelSanctumWall'then return V.require('DioramaConfig').terrain.emNavelSanctums.wallHeight end
 if kind=='emNavelWall'then return V.require('EmeraldNavelPassages').height()end
 if kind=='emMirageWall'then return V.require('EmeraldMirageTower').height()end
 if kind=='emSeafloorWall'then return V.require('EmeraldSeafloorCurrents').height()end
 if kind=='emMagmaWall'then return V.require('EmeraldMagmaHideout').height()end
 if kind=='emRusturfWall'or kind=='emRusturfStep'then return V.require('EmeraldRusturf').height(kind)end
 if kind=='emFieryWall'then return V.require('EmeraldFieryPath').height()end
 if kind and kind:match('^frBrown')then return V.require('FireRedTerracedCaves').height(kind)end
 if kind and kind:match('^frTanoby')then return V.require('TanobyKey').height(kind)end
 if kind=='frDiglettWall'then return V.require('FireRedDiglettCave').height()end
 if kind=='frLostWall'then return V.require('FireRedLostCave').height()end
 if kind and kind:match('^frRuin')then return V.require('FireRedRuinCaves').height(kind)end
 if kind=='caveLedge'then return V.require('DioramaConfig').terrain.caveLedges.height end
 if kind=='emeraldCoast'then return V.require('EmeraldCoastCliffs').height()end
 if kind and kind:match('^ember')then return V.require('FireRedEmber').height(kind)end
 local c=V.require('DioramaConfig').terrain
 return kind=='ledge' and c.ledgeHeight or kind=='wall' and c.caveWallHeight or c.cliffHeight
end
function T.plan(def,excluded)
 local L=def.midLayout;local cells={}
 local columns=V.require('EmeraldMeteorColumns').plan(def).mask
 local stalagmites=V.require('EmeraldCaveStalagmites').plan(def).mask
 for y=0,L.height-1 do for x=0,L.width-1 do
  Budget.tick()
  local k=y*L.width+x+1
  local rock=V.require('EmeraldMeteorEdges').applies(def)and V.require('EmeraldMeteorEdges').isRock(L:midAt(x,y))
  if not excluded[k]and not(stalagmites[k]and stalagmites[k].base==0)and not rock and not V.require('EmeraldCaveObjects').isRock(def,L:midAt(x,y))and not V.require('EmeraldOriginObjects').isRock(def,L:midAt(x,y))and not(columns[k]and columns[k].donor==0x229)then local kind=V.require('DioramaConfig').terrain.enabled and V.require('EmeraldCavePortals').wall(def,x,y)and 'wall'or T.kind(def,L:cellAt(x,y));if kind then cells[k]=kind end end
 end end
 return cells
end
function T.stamp(out,def,ts,x,z,ox,oz,cells,borderKind,borderNeighbor)
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').terrain
 local L=def.midLayout;local kind=borderKind or cells[z*L.width+x+1];local h=T.height(kind)
 if kind=='emUnderwaterWall'then return V.require('EmeraldUnderwaterTerrain').stamp(out,def,ts,x,z,ox,oz,cells)end
 if kind=='emNavelSanctumWall'then return V.require('EmeraldNavelSanctums').stamp(out,def,ts,x,z,ox,oz)end
 if kind=='emNavelWall'then return V.require('EmeraldNavelPassages').stamp(out,def,ts,x,z,ox,oz)end
 if kind=='emMirageWall'then return V.require('EmeraldMirageTower').stamp(out,def,ts,x,z,ox,oz)end
 if kind=='emSeafloorWall'then return V.require('EmeraldSeafloorCurrents').stamp(out,def,ts,x,z,ox,oz)end
 if kind and kind:match('^frBrown')then return V.require('FireRedTerracedCaves').stamp(out,def,ts,x,z,ox,oz)end
 if kind and kind:match('^frTanoby')then return V.require('TanobyKey').stamp(out,def,ts,x,z,ox,oz)end
 if kind=='frDiglettWall'then return V.require('FireRedDiglettCave').stamp(out,def,ts,x,z,ox,oz)end
 if kind=='frLostWall'then return V.require('FireRedLostCave').stamp(out,def,ts,x,z,ox,oz)end
 if kind and kind:match('^frRuin')then return V.require('FireRedRuinCaves').stamp(out,def,ts,x,z,ox,oz)end
 if kind=='emMagmaWall'then return V.require('EmeraldMagmaHideout').floor(out,def,ts,x,z,ox,oz)end
 if kind=='emRusturfWall'or kind=='emRusturfStep'then return V.require('EmeraldRusturf').stamp(out,def,ts,x,z,ox,oz)end
 if kind=='emFieryWall'then return V.require('EmeraldFieryPath').stamp(out,def,ts,x,z,ox,oz)end
 if kind=='caveLedge'then return V.require('CaveTerrain').ledge(out,def,ts,x,z,ox,oz)end
 if kind=='ledge'and V.require('EmeraldAshRoute').ledge(out,def,ts,x,z,ox,oz,cells)then return end
 if kind=='emeraldCoast'then return V.require('EmeraldCoastCliffs').stamp(out,def,ts,x,z,ox,oz,cells)end
 if kind and kind:match('^ember')then return V.require('FireRedEmber').stamp(out,def,ts,x,z,ox,oz,cells,kind)end
 if kind=='wall'and V.require('EmeraldMeteorEdges').stamp(out,def,ts,x,z,ox,oz,cells)then return end
 if kind=='wall'and V.require('EmeraldCaveContours').stamp(out,def,ts,x,z,ox,oz,cells)then return end
 local mid=V.require('EmeraldCaveObjects').donor(def,x,z)or V.require('EmeraldOriginObjects').donor(def,x,z)or V.require('EmeraldMeteorColumns').donor(def,x,z)or V.data('Shapes').surfaceMid(def,L:midAt(x,z))
 local portal=kind=='wall'and V.require('EmeraldCavePortals').at(def,x,z)or nil
 local wallMaterial=portal and portal.wall or kind=='wall' and V.require('EmeraldCaveMaterials').side(def,mid)or nil
 local first=#out+1
 local xx,zz=(x+ox)*16,(z+oz)*16
 local back=kind=='ledge' and 8 or 0
 local sideShade=kind=='ledge' and cfg.ledgeSideShade or cfg.sideShade
 local function neighbor(dx,dz)
  if borderNeighbor then return borderNeighbor(dx,dz)end
  local nx,nz=x+dx,z+dz
  if nx<0 or nz<0 or nx>=L.width or nz>=L.height then
   local c=L:cellAt(nx,nz);local k=T.kind(def,c)
   return k and k~='caveLedge' and T.height(k)or 0
  end
  local k=cells[nz*L.width+nx+1]
  -- A cave lip occupies only its narrow edge. It cannot hide the complete
  -- lower side of the neighbouring wall (that left black rectangular holes).
  return k and k~='caveLedge' and T.height(k)or 0
 end
 local function face(a,b,c,d,u0,v0,u1,v1,shade,donor)
  G.quad(out,a,b,c,d,G.uv(ts,donor or mid,u0,v0,u1,v1,.5),shade)
 end
 if kind=='ledge' then
  -- The source corners include opaque grass. Extruding the entire tile
  -- raised that grass into thin green fins at the ends of the step.
  local pixel=V.require('BuildingMesh').pixel
  local columns={}
  for sx=0,15 do
   local first,last
   for sy=8,15 do
    local r,g,b,a=pixel(ts,mid,sx,sy)
    if a>.5 and r>g+.02 and r>b+.005 then first=first or sy;last=sy end
   end
   if first then columns[sx]={first,last}end
  end
  -- The native upper half already carries the local path/grass transition.
  -- A map-wide grass donor cuts sandy paths with a green strip at every jump.
  local surface=mid
  local lip=math.min(h,cfg.ledgeLipHeight)
  for sx=0,15 do local edge=columns[sx]
   if edge then
    local lo,hi=edge[1],edge[2]+1
    face({xx+sx,h,zz+back},{xx+sx+1,h,zz+back},{xx+sx+1,h,zz+16},{xx+sx,h,zz+16},sx,0,sx+1,8,cfg.topShade,surface)
    local front=neighbor(0,1)
    if front<h then
     face({xx+sx,h,zz+16},{xx+sx+1,h,zz+16},{xx+sx+1,h-lip,zz+16},{xx+sx,h-lip,zz+16},sx,0,sx+1,2,cfg.ledgeLipShade,surface)
     if front<h-lip then face({xx+sx,h-lip,zz+16},{xx+sx+1,h-lip,zz+16},{xx+sx+1,front,zz+16},{xx+sx,front,zz+16},sx,lo,sx+1,hi,sideShade)end
    end
    if not columns[sx-1]and (sx>0 or neighbor(-1,0)<h)then
     face({xx+sx,h,zz+back},{xx+sx,h,zz+16},{xx+sx,0,zz+16},{xx+sx,0,zz+back},sx,lo,sx+1,hi,sideShade)
    end
    if not columns[sx+1]and (sx<15 or neighbor(1,0)<h)then
     face({xx+sx+1,h,zz+16},{xx+sx+1,h,zz+back},{xx+sx+1,0,zz+back},{xx+sx+1,0,zz+16},sx,lo,sx+1,hi,sideShade)
    end
    face({xx+sx+1,h,zz+back},{xx+sx,h,zz+back},{xx+sx,0,zz+back},{xx+sx+1,0,zz+back},sx,lo,sx+1,hi,sideShade)
   end
  end
  return
 end
 if kind=='cliff' then
  local contour=V.require('FireRedCliffContours')
  local tileMasks,signature={},{}
  local S=V.data('Shapes')
  for dz=-1,1 do for dx=-1,1 do
   if dx==0 or dz==0 then
    local tx,tz=x+dx,z+dz;local k
    if borderKind then k=T.kind(def,L:cellAt(tx,tz))
    elseif tx>=0 and tz>=0 and tx<L.width and tz<L.height then k=cells[tz*L.width+tx+1]
    else k=T.kind(def,L:cellAt(tx,tz))end
    local source=S.surfaceMid(def,L:midAt(tx,tz))
    signature[#signature+1]=tostring(k)..':'..tostring(source)
    tileMasks[(dz+1)*3+dx+2]=k=='entrance'and true or k=='cliff'and contour.mask(ts,source,contour.variant(def,source))or false
   end
  end end
  local key=table.concat(signature,'|')..':'..h..':'..cfg.topShade..':'..sideShade
  local bank=cliffTemplates[ts];if not bank then bank={};cliffTemplates[ts]=bank end
  local template=bank[key]
  if template then for _,v in ipairs(template)do out[#out+1]=cliffPlace(v,xx,zz)end;return end
  local first=#out+1
  local function occupied(px,pz)
   local tx,tz=math.floor(px/16)-x,math.floor(pz/16)-z
   local mask=tileMasks[(tz+1)*3+tx+2]
   return mask==true or type(mask)=='table'and mask[(pz%16)*16+px%16+1]or false
  end
  for sy=0,15 do
   local sx=0
   while sx<16 do
    if occupied(x*16+sx,z*16+sy)then
     local start=sx
     repeat sx=sx+1 until sx==16 or not occupied(x*16+sx,z*16+sy)
     face({xx+start,h,zz+sy},{xx+sx,h,zz+sy},{xx+sx,h,zz+sy+1},{xx+start,h,zz+sy+1},start,sy,sx,sy+1,cfg.topShade)
    elseif contour.variant(def,mid)then
     -- Keep the native sand/grass margin on the floor, above the generic
     -- underlay. Only rock pixels belong to the raised cap and side faces.
     local start=sx
     repeat sx=sx+1 until sx==16 or occupied(x*16+sx,z*16+sy)
     face({xx+start,.02,zz+sy},{xx+sx,.02,zz+sy},{xx+sx,.02,zz+sy+1},{xx+start,.02,zz+sy+1},start,sy,sx,sy+1,1)
    else sx=sx+1 end
   end
  end
  local donor=ts.midToSlot[0x79]and 0x79 or mid
  -- Merge contiguous one-pixel boundary segments into planar wall strips.
  for _,d in ipairs({{0,1},{0,-1},{1,0},{-1,0}})do
   for row=0,15 do
    local col=0
    local function edge(c)
     local sx,sy=d[1]==0 and c or row,d[1]==0 and row or c
     return occupied(x*16+sx,z*16+sy)and not occupied(x*16+sx+d[1],z*16+sy+d[2])
    end
    while col<16 do
     if edge(col)then
      local start=col;repeat col=col+1 until col==16 or not edge(col)
      if d[1]==0 then
       local fz=zz+row+(d[2]>0 and 1 or 0)
       face({xx+start,h,fz},{xx+col,h,fz},{xx+col,0,fz},{xx+start,0,fz},start,0,col,16,sideShade,donor)
      else
       local fx=xx+row+(d[1]>0 and 1 or 0)
       face({fx,h,zz+start},{fx,h,zz+col},{fx,0,zz+col},{fx,0,zz+start},start,0,col,16,sideShade,donor)
      end
     else col=col+1 end
    end
   end
  end
  template={};for i=first,#out do template[#template+1]=cliffPlace(out[i],-xx,-zz)end
  bank[key]=template
  return
 end
 local cap=portal and portal.cap or kind=='entrance' and (ts.midToSlot[0x79]and 0x79 or mid)or mid
 face({xx,h,zz+back},{xx+16,h,zz+back},{xx+16,h,zz+16},{xx,h,zz+16},0,0,16,kind=='ledge' and 8 or 16,cfg.topShade,cap)
 -- Shared interior faces are culled; only the outer contour is extruded.
 local front=neighbor(0,1)
 if front<h then
  if kind=='entrance' then
   -- Native black door pixels are an opening, not a black solid side wall.
   -- Its frame rises with the rock; the original warp foot remains at y=0.
   local pixel=V.require('BuildingMesh').pixel
   for sy=0,15 do local sx=0
    while sx<16 do
     local r,g,b,a=pixel(ts,mid,sx,sy)
     if a>.5 and math.max(r,g,b)>.12 then
      local first=sx
      repeat sx=sx+1;r,g,b,a=pixel(ts,mid,math.min(15,sx),sy)until sx==16 or a<=.5 or math.max(r,g,b)<=.12
      face({xx+first,h*(1-sy/16),zz+16},{xx+sx,h*(1-sy/16),zz+16},
       {xx+sx,h*(1-(sy+1)/16),zz+16},{xx+first,h*(1-(sy+1)/16),zz+16},first,sy,sx,sy+1,sideShade)
     else sx=sx+1 end
    end
   end
   -- Recessed dark native opening gives the doorway depth without a front cap.
   face({xx+2,h*.8,zz+1},{xx+14,h*.8,zz+1},{xx+14,0,zz+1},{xx+2,0,zz+1},7,9,9,11,sideShade)
  else
   face({xx,h,zz+16},{xx+16,h,zz+16},{xx+16,front,zz+16},{xx,front,zz+16},0,wallMaterial and 0 or 8,16,16,sideShade,portal and portal.upper or wallMaterial)
  end
 end
 local left,right,north=neighbor(-1,0),neighbor(1,0),neighbor(0,-1)
 if left<h then face({xx,h,zz+back},{xx,h,zz+16},{xx,left,zz+16},{xx,left,zz+back},0,wallMaterial and 0 or 8,16,16,sideShade,wallMaterial)end
 if right<h then face({xx+16,h,zz+16},{xx+16,h,zz+back},{xx+16,right,zz+back},{xx+16,right,zz+16},0,wallMaterial and 0 or 8,16,16,sideShade,wallMaterial)end
 if north<h or kind=='ledge' then face({xx+16,h,zz+back},{xx,h,zz+back},{xx,kind=='ledge' and 0 or north,zz+back},{xx+16,kind=='ledge' and 0 or north,zz+back},0,wallMaterial and 0 or 8,16,16,sideShade,wallMaterial)end
 if kind=='wall' and V.require('CaveTerrain').applies(def)then
  V.require('EmeraldCaveContours').closeJoins(out,def,ts,x,z,ox,oz,cells)
  for i=first,#out do out[i][9]=-2 end
 end
end
return T
