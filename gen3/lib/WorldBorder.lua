-- Continue the active ROM border outside visible connected maps. Never lay
-- a repeated border over a real neighbour's ground or change native movement.
local V=...
-- The provider may be physically removed along with all of its consumers.
-- Resolve once; a missing optional seam must retain the native ROM border.
local seamsOK,Seams=pcall(V.require,'core/RenderSeams')
if not seamsOK then Seams=nil end
local Budget=V.require('BuildBudget')
local Queue=V.require('NativeBuildQueue')
local B={cache={},serial=0}
local function cancelPending(except)
 local job=Queue.job
 if job and job.key:sub(1,7)=='border:' and job.key~=except then Queue.cancel()end
end
local rockNeighbors={{0,0},{0,1},{0,-1},{1,0},{-1,0}}
local function dispose(s)
 if s.mesh then s.mesh:release()end
 if s.entry then
  for _,k in ipairs{'contacts','caveSection'}do if s.entry[k]then s.entry[k]:release()end end
  for _,batch in ipairs(s.entry.instances)do batch.mesh:release();batch.placements:release()end
 end
end
function B.get(def,ts,entries,px,pz,instancing,viewWidth,viewHeight,frame)
 -- Native connections are stable across camera movement. Exclude their real
 -- footprints even before their renderer entries enter the visible set, so
 -- revealing a neighbour cannot rebuild the same border cell mid-step.
 -- Explicit/offline callers without the matching native world keep their
 -- supplied coverage. Emerald's selective coverage remains unchanged.
 local Map=require('src.core.game3.map')
 local id=def.id or def.name
 if not V.data('Emerald').active() and Map._worldRoot==id and Map.world then
  local context=B.context
  if not context or context.world~=Map.world or context.def~=def then
   local coverage={{id=id,def=def,ox=0,oy=0}}
   for _,e in ipairs(Map.world)do coverage[#coverage+1]=e end
   context={world=Map.world,def=def,entries=coverage};B.context=context
  end
  entries=context.entries
 end
 local cx,cz=math.floor(px/128)*8,math.floor(pz/128)*8
 local Camera=V.require('Camera')
 local ex,ez=Camera.groundExtents(viewWidth or 240,viewHeight or 160)
 local rx=math.max(28,math.ceil(ex/16)+8)
 local rz=math.max(28,math.ceil(ez/16)+10)
 local G=V.require('WorldGeometry');local L=def.midLayout
 local keys={def.id or def.name,cx,cz,rx,rz,tostring(instancing),tostring(ts),G.layoutStamp(L)}
 for _,e in ipairs(entries)do keys[#keys+1]=e.id..':'..e.ox..':'..e.oy end
 -- Optional presentation boundary applies only to synthetic continuation.
 -- Real connected maps above remain covered by their own native geometry.
 B.boundsContext=B.boundsContext or{}
 local context=B.boundsContext;context.def,context.entries=def,entries
 -- The default play view must see continuous native surroundings, not the
 -- edge of a four-tile tabletop. Keep the scenery boundary beyond the local
 -- camera footprint; mesh generation remains limited to rx/rz around player.
 context.continuationMargin=math.max(rx,rz)+2
 local clip=Seams and Seams.chain('borderBounds',false,context)
 B.clipBounds=clip or nil
 local coverage=B.coverageBounds or{};B.coverageBounds=coverage
 coverage[1],coverage[2],coverage[3],coverage[4]=cx-rx,cz-rz,cx+rx+1,cz+rz+1
 if clip then
  coverage[1],coverage[2]=math.max(coverage[1],clip[1]),math.max(coverage[2],clip[2])
  coverage[3],coverage[4]=math.min(coverage[3],clip[3]),math.min(coverage[4],clip[4])
 end
 if clip then for i=1,4 do keys[#keys+1]=clip[i]end end
 local key=table.concat(keys,'|')
 local jobKey='border:'..key
 if B.key==key then return B.mesh,B.entry,true end
 -- Keep the last three exact border cells. Walking back across a 128px
 -- boundary must not destroy and rebuild all their meshes every time.
 B.serial=B.serial+1
 local hit=B.cache[key]
 if hit then
  hit.used=B.serial;B.key=key;B.mesh,B.entry,B.count,B.trees=hit.mesh,hit.entry,hit.count,hit.trees
  return B.mesh,B.entry,true
 end
 cancelPending(frame and jobKey or nil)
 local function build()
 local sourceLayout=V.require('ConnectedBorderLayout').forEntries(def,entries)
 local L=sourceLayout
 local def=setmetatable({midLayout=L},{__index=def})
 local state={count=0,trees=0}
 Budget.phase('border geometry');Budget.check()
 local function newMesh(...)
  Budget.phase('border upload');Budget.check()
  local mesh=Queue.own(love.graphics.newMesh(...))
  Budget.check();return mesh
 end
 local out,placements,claimed={},{},{}
 local rainforest=V.require('EmeraldRainforest');local rainPlacements={}
 local ash=V.require('EmeraldAshRoute');local ashPlacements={}
 local fallarbor=V.require('EmeraldFallarborTrees');local fallarborPlacements={}
 local compact=V.require('EmeraldCompactForest');local compactPlacements={}
 local safari=V.require('FireRedSafari');local safariPlacements={}
 local Shapes=V.data('Shapes');local Trees=V.require('Trees')
 local upright=V.require('DioramaConfig').billboards.enabled
 local outdoor=Shapes.outdoors(def)and upright
 local terrain=V.require('Terrain')
 local rainforestActive=outdoor and rainforest.applies(def)
 local fallarborActive=outdoor and fallarbor.applies(def)
 local ashActive=outdoor and ash.applies(def)
 local compactActive=outdoor and compact.applies(def)
 local safariActive=outdoor and safari.applies(def)
 local wreck=V.require('EmeraldWreckDeck');local wreckActive=wreck.profile(def)
 -- FireRed's terrain classifiers depend on mid/collision and the fixed map
 -- profile, not cell position. Keep this memo local to one build:
 -- native edits, settings and projection changes can never reuse old kinds.
 local fireRed=not V.data('Emerald').map(def)
 local kinds,treeMids={},{}
 local function terrainKind(c)
  if not fireRed then return terrain.kind(def,c)end
  local row=kinds[c.mid];if not row then row={};kinds[c.mid]=row end
  local kind=row[c.coll]
  if kind==nil then kind=terrain.kind(def,c)or false;row[c.coll]=kind end
  return kind or nil
 end
 local function tree(mid)
  local yes=treeMids[mid]
  if yes==nil then yes=not not Shapes.tree(mid,def);treeMids[mid]=yes end
  return yes
 end
 local terracedWriter,terracedKey
 local groundGroups,groundOrder,instancedVertices={},{},0
 local borderWater
 local function waterBounds(xx,zz)
  if not borderWater then borderWater={xx,zz,xx+16,zz+16,-.02,-.02}
  else borderWater[1]=math.min(borderWater[1],xx);borderWater[2]=math.min(borderWater[2],zz)
   borderWater[3]=math.max(borderWater[3],xx+16);borderWater[4]=math.max(borderWater[4],zz+16)end
 end
 local function repeated(key,x,z,stamp)
  if not instancing or #out==0 then stamp(out);return end
  local group=groundGroups[key]
  if not group then
   local vertices={};stamp(vertices)
   -- These templates contain only rigid ground faces, never billboards.
   for _,v in ipairs(vertices)do v[1]=v[1]-x;v[3]=v[3]-z end
   group={vertices=vertices,placements={}};groundGroups[key]=group;groundOrder[#groundOrder+1]=group
  end
  group.placements[#group.placements+1]={x,z,1};instancedVertices=instancedVertices+#group.vertices
  return group
 end
 local forest=Shapes.forest(def);local ground=G.ground(def,ts)
 local waterMids={}
 for _,c in ipairs(L.cells)do Budget.tick();if Shapes.water(c)then waterMids[c.mid]=true end end
 -- A decorative sea border can use a pure water tile absent from all
 -- surfable cells (Six Island). Material ownership comes from the native
 -- FireRed water donors; collision still belongs to the original map.
 if not V.data('Emerald').map(def) and tostring(def.pair):match('^general__')then
  waterMids[0x12b]=true;waterMids[0x1d9]=true
 end
 local width=forest and 3 or 2
 local route=V.require("DioramaConfig").trees.routeRows[def.id or def.name]
 local stride=route and route.stride or V.require("DioramaConfig").trees.rowStride
 -- A border build revisits each row for tree grouping, ground and eaves.
 -- Resolve the real-map rectangles once per row; keep this local so map,
 -- connection and clipping changes cannot retain stale coverage.
 local coverageRows={}
 local function covered(x,z)
  if clip and(x<clip[1]or z<clip[2]or x>=clip[3]or z>=clip[4])then return true end
  local row=coverageRows[z]
  if not row then
   row={};coverageRows[z]=row
   for _,e in ipairs(entries)do
    local l=e.def.midLayout
    if z>=e.oy and z<e.oy+l.height then
     row[#row+1]=e.ox;row[#row+1]=e.ox+l.width
    end
   end
  end
  for i=1,#row,2 do if x>=row[i]and x<row[i+1]then return true end end
 end
 local function isTree(x,z)
  return outdoor and not covered(x,z) and tree(L:midAt(x,z))
 end
 -- Reject incomplete patches at the first covered/non-tree cell. Native
 -- lookups are read-only; the remaining samples cannot change the result.
 local function wholeTree(x,z)
  for dz=0,1 do for dx=0,width-1 do
   if not isTree(x+dx,z+dz)then return false end
  end end
  return true
 end
 local function claim(x,z)
  claimed[z]=claimed[z]or{};claimed[z][x]=true
 end
 -- Anchor to world coordinates, not the moving capture square. Whole native
 -- tree patches become shared standing cards; edge fragments stay small.
 if outdoor then for z=math.floor((cz-rz-2)/2)*2,cz+rz+2,2 do
  for x=math.floor((cx-rx-2)/width)*width,cx+rx+2,width do
   Budget.tick()
   local whole=x<=cx+rx and x+width-1>=cx-rx and z<=cz+rz and z+1>=cz-rz
   if whole and wholeTree(x,z)then
    local nextWhole=wholeTree(x,z+2)
    if (z/2)%math.max(1,stride)==0 or not nextWhole then
      local shift=route and (math.floor(z/2/stride)%2==0 and -1 or 1)*route.stagger/2 or 0
      placements[#placements+1]={x*16+width*8+shift,z*16+16,1}
    end
    for dz=0,1 do for dx=0,width-1 do claim(x+dx,z+dz)end end
   end
  end
 end end
 for z=cz-rz,cz+rz do for x=cx-rx,cx+rx do
  Budget.tick()
  if not covered(x,z) then
   local mid=Shapes.borderMid(def,x,z)
   if ts.midToSlot[mid]then
    local xx,zz=x*16,z*16
    if safariActive and safari.tile(def,mid)then
     local p=safari.anchor(def,x,z)
     if p then safariPlacements[#safariPlacements+1]={xx+8,p.foot,1}end
     mid=ground
    end
    if fallarborActive and fallarbor.tree(mid)then
     if fallarbor.anchor(def,x,z)and not covered(x+1,z)then fallarborPlacements[#fallarborPlacements+1]={xx+16,zz+12,1}end
     mid=fallarbor.ground
    end
    if ashActive and ash.tree(mid)then
     if(mid==0x20c or mid==0x275)and ash.tree(L:midAt(x+1,z))and not covered(x+1,z)then ashPlacements[#ashPlacements+1]={xx+16,zz+12,1}end
     mid=ground
    end
    local cr=compactActive and compact.role(def,mid)
    if cr then
     local below=compact.role(def,L:midAt(x,z+1))
     if cr[4]or not(below and below[4])then
      local group=compactPlacements[cr[1]]or{};compactPlacements[cr[1]]=group
      group[#group+1]={xx+8,zz+(cr[4]and 14 or 16),1}
     end
     mid=cr[3]
    end
    if rainforestActive and rainforest.tile(def,mid)then
     local below=L:midAt(x,z+1)
     if mid==0x16 or mid==0x17 or(below~=0x16 and below~=0x17)then
      local variant=rainforest.variant(mid);local group=rainPlacements[variant]or{};rainPlacements[variant]=group
      group[#group+1]={xx+8,zz+((mid==0x16 or mid==0x17)and 14 or 16),1}
     end
     mid=ground
    end
    if outdoor and tree(mid)then
     mid=ground
     if not (claimed[z]and claimed[z][x])then placements[#placements+1]={xx+8,zz+8,.5}end
    end
    local kind=terrainKind(L:cellAt(x,z))
    if wreckActive and wreck.border(out,def,ts,x,z)then
     -- Preserve deck level/ocean beyond the edge; never repeat flat funnels.
    elseif upright and (kind=='cliff'or kind=='entrance'or kind=='emMagmaWall'or kind=='emRusturfWall'or kind=='emRusturfStep'or kind=='wall'or kind=='frBrownRock'or kind=='frTanobyWall'or kind=='frDiglettWall'or kind=='frLostWall'or kind and kind:match('^frRuin'))then
     local function neighbor(dx,dz)
      local k=terrainKind(L:cellAt(x+dx,z+dz));return k and terrain.height(k)or 0
     end
     if kind=='frBrownRock'then
      if terracedWriter==nil then
       terracedWriter,terracedKey=V.require('FireRedTerracedCaves').borderWriter(def,ts)
       terracedWriter=terracedWriter or false
      end
      local repeatKey=instancing and #out>0 and terracedKey and terracedKey(x,z)
      if repeatKey then
       local group=repeated(repeatKey,xx,zz,function(target)terracedWriter(target,x,z)end)
       group.caveRock=true
      elseif terracedWriter then terracedWriter(out,x,z)
      else terrain.stamp(out,def,ts,x,z,0,0,{},kind,neighbor)end
     elseif (kind=='cliff'or kind=='entrance'or kind=='frDiglettWall'or kind=='frLostWall') and instancing and #out>0 then
      -- Native rock stamps depend on the center and four neighbors.
      -- Group only identical neighborhoods within this one border build.
      local parts={kind}
      for _,dir in ipairs(rockNeighbors)do
       local c=L:cellAt(x+dir[1],z+dir[2]);parts[#parts+1]=c.mid;parts[#parts+1]=c.coll
      end
      local group=repeated(table.concat(parts,':'),xx,zz,function(target)
       terrain.stamp(target,def,ts,x,z,0,0,{},kind,neighbor)
      end)
      group.caveRock=true
     else terrain.stamp(out,def,ts,x,z,0,0,{},kind,neighbor)end
    else
     if waterMids[mid]then waterBounds(xx,zz)end
     local group=instancing and #out>0 and groundGroups[mid]
     if group then
      group.placements[#group.placements+1]={xx,zz,1};instancedVertices=instancedVertices+#group.vertices
     else
      repeated(mid,xx,zz,function(target)
       G.quad(target,{xx,-.02,zz},{xx+16,-.02,zz},{xx+16,-.02,zz+16},{xx,-.02,zz+16},G.uv(ts,mid),waterMids[mid] and G.WATER or 1)
      end)
     end
    end
   end
  end
 end end
 state.count=(#out+instancedVertices)/6
 state.trees=#placements
 local instances={};local treeVertices=0
 for _,group in ipairs(groundOrder)do
  local batch={mesh=newMesh(G.FORMAT,group.vertices,'triangles','static'),
   placements=newMesh({{'WorldPlacement','float',3}},group.placements,'points','static'),count=#group.placements,borderSurface=true}
  batch.mesh:attachAttribute('WorldPlacement',batch.placements,'perinstance');instances[#instances+1]=batch
 end
 if #placements>0 then
  local template=Trees.template(ts,forest)
  treeVertices=#template*#placements
  if instancing then
   local batch={mesh=newMesh(G.FORMAT,template,'triangles','static'),
    placements=newMesh({{'WorldPlacement','float',3}},placements,'points','static'),count=#placements}
   batch.mesh:attachAttribute('WorldPlacement',batch.placements,'perinstance');instances[#instances+1]=batch
  else
   for _,p in ipairs(placements)do for _,v in ipairs(template)do
    out[#out+1]=G.place(v,p[1],p[2],p[3])
   end end
  end
 end
 if #ashPlacements>0 then
  local template=V.require('Props').template(ts,0x204,'ashTree',ground)
  treeVertices=treeVertices+#template*#ashPlacements;state.trees=state.trees+#ashPlacements
  if instancing then
   local batch={mesh=newMesh(G.FORMAT,template,'triangles','static'),placements=newMesh({{'WorldPlacement','float',3}},ashPlacements,'points','static'),count=#ashPlacements}
   batch.mesh:attachAttribute('WorldPlacement',batch.placements,'perinstance');instances[#instances+1]=batch
  else for _,p in ipairs(ashPlacements)do for _,v in ipairs(template)do out[#out+1]=G.place(v,p[1],p[2],p[3])end end end
 end
 if #safariPlacements>0 then
  local template=V.require('Props').template(ts,0x31e,'safariTree',ground)
  treeVertices=treeVertices+#template*#safariPlacements;state.trees=state.trees+#safariPlacements
  if instancing then
   local batch={mesh=newMesh(G.FORMAT,template,'triangles','static'),placements=newMesh({{'WorldPlacement','float',3}},safariPlacements,'points','static'),count=#safariPlacements}
   batch.mesh:attachAttribute('WorldPlacement',batch.placements,'perinstance');instances[#instances+1]=batch
  else for _,p in ipairs(safariPlacements)do for _,v in ipairs(template)do out[#out+1]=G.place(v,p[1],p[2],p[3])end end end
 end
 if #fallarborPlacements>0 then
  local template=V.require('Props').template(ts,0x206,'fallarborTree',fallarbor.ground)
  treeVertices=treeVertices+#template*#fallarborPlacements;state.trees=state.trees+#fallarborPlacements
  if instancing then
   local batch={mesh=newMesh(G.FORMAT,template,'triangles','static'),placements=newMesh({{'WorldPlacement','float',3}},fallarborPlacements,'points','static'),count=#fallarborPlacements}
   batch.mesh:attachAttribute('WorldPlacement',batch.placements,'perinstance');instances[#instances+1]=batch
  else for _,p in ipairs(fallarborPlacements)do for _,v in ipairs(template)do out[#out+1]=G.place(v,p[1],p[2],p[3])end end end
 end
 for _,set in ipairs({{rainPlacements,'rainforest'},{compactPlacements,'compactForest'}})do
 for variant,group in pairs(set[1])do
  local template=V.require('Props').template(ts,variant,set[2],ground)
  treeVertices=treeVertices+#template*#group;state.trees=state.trees+#group
  if instancing then
   local batch={mesh=newMesh(G.FORMAT,template,'triangles','static'),
    placements=newMesh({{'WorldPlacement','float',3}},group,'points','static'),count=#group}
   batch.mesh:attachAttribute('WorldPlacement',batch.placements,'perinstance');instances[#instances+1]=batch
  else for _,p in ipairs(group)do for _,v in ipairs(template)do out[#out+1]=G.place(v,p[1],p[2],p[3])end end end
 end
 end
 if #out>0 then
  state.mesh=newMesh(G.FORMAT,out,'triangles','static')
  local stored=#out
  for _,batch in ipairs(instances)do stored=stored+batch.mesh:getVertexCount()+batch.count end
  local contacts={};local cfg=V.require('DioramaConfig').contact
  for _,p in ipairs(placements)do contacts[#contacts+1]={p[1],p[2],cfg.treeRadius[1]*p[3],cfg.treeRadius[2]*p[3],cfg.treeStrength}end
  for _,p in ipairs(ashPlacements)do contacts[#contacts+1]={p[1],p[2],cfg.treeRadius[1],cfg.treeRadius[2],cfg.treeStrength}end
  for _,p in ipairs(fallarborPlacements)do contacts[#contacts+1]={p[1],p[2],cfg.treeRadius[1],cfg.treeRadius[2],cfg.treeStrength}end
  for _,p in ipairs(safariPlacements)do contacts[#contacts+1]={p[1],p[2],cfg.treeRadius[1]*1.35,cfg.treeRadius[2],cfg.treeStrength}end
  for _,set in ipairs({rainPlacements,compactPlacements})do
  for _,group in pairs(set)do for _,p in ipairs(group)do
   contacts[#contacts+1]={p[1],p[2],cfg.treeRadius[1]*.5,cfg.treeRadius[2]*.5,cfg.treeStrength}
  end end
  end
  Budget.phase('border metadata');Budget.check()
  state.entry={mesh=state.mesh,contacts=Queue.own(V.require('ContactShadows').mesh(contacts)),instances=instances,atlas=ts,
   stats={lights={},vertices=state.count*6+treeVertices,storedVertices=stored,waterReflectionBounds=V.require('WaterReflectionBounds').vertices(out)},heights={}}
  if borderWater then
   local b=state.entry.stats.waterReflectionBounds
   if not b then state.entry.stats.waterReflectionBounds=borderWater
   else for _,i in ipairs{1,2,5}do b[i]=math.min(b[i],borderWater[i])end;for _,i in ipairs{3,4,6}do b[i]=math.max(b[i],borderWater[i])end end
  end
  if V.require('EmeraldMagmaHideout').profile(def)or V.require('EmeraldRusturf').profile(def)or V.require('CaveTerrain').applies(def)or V.require('FireRedTerracedCaves').profile(def)or V.require('TanobyKey').profile(def)or V.require('FireRedDiglettCave').profile(def)or V.require('FireRedLostCave').profile(def)or V.require('FireRedRuinCaves').profile(def)then state.entry.caveCaps=V.require('CaveSectionMesh').collect(out,def,ts)end
 end
  -- Keep the same solid cap triangles for camera cutaways and neighbor
  -- continuity, even when their complete rock mesh is drawn with instances.
  if state.entry and state.entry.caveCaps then
   local target=state.entry.caveCaps;local section=V.require('CaveSectionMesh')
   for _,group in ipairs(groundOrder)do if group.caveRock then
    local caps=section.collect(group.vertices,def,ts)
    for _,p in ipairs(group.placements)do for _,c in ipairs(caps)do
     Budget.tick()
     local cap={x0=c.x0+p[1],x1=c.x1+p[1],z0=c.z0+p[2],z1=c.z1+p[2],uv=c.uv}
     for i=1,3 do local v=c[i];cap[i]={v[1]+p[1],v[2],v[3]+p[2],v[4],v[5],v[6],v[7],v[8],v[9]}end
     target[#target+1]=cap
     for z=math.floor(cap.z0/16),math.ceil(cap.z1/16)-1 do for x=math.floor(cap.x0/16),math.ceil(cap.x1/16)-1 do
      local k=x..':'..z;local bucket=target.grid[k]or{};target.grid[k]=bucket;bucket[#bucket+1]=cap
     end end
    end end
   end end
  end
 return state
 end
 -- Only publish complete meshes and metadata. While a job is suspended the
 -- renderer retains its last complete frame; abandoned GPU objects belong
 -- to NativeBuildQueue until the completed result transfers to this cache.
 local state=frame and Queue.get(jobKey,frame,build)or nil
 if not frame then state=build()end
 if not state then return nil,nil,false end
 B.key=key;B.mesh,B.entry,B.count,B.trees=state.mesh,state.entry,state.count,state.trees
 B.cache[key]={mesh=B.mesh,entry=B.entry,count=B.count,trees=B.trees,used=B.serial}
 local count,oldest,age=0,nil,math.huge
 for k,v in pairs(B.cache)do count=count+1;if k~=B.pinnedKey and v.used<age then oldest,age=k,v.used end end
 if count>3 then dispose(B.cache[oldest]);B.cache[oldest]=nil end
 return B.mesh,B.entry,true
end
-- Speculative borders share the bounded LRU without replacing the active
-- field's public bounds or mesh, even while their cooperative build yields.
function B.prepare(...)
 local fields={'key','mesh','entry','count','trees','context','boundsContext','clipBounds','coverageBounds','pinnedKey'}
 local saved={};for _,k in ipairs(fields)do saved[k]=B[k]end
 B.pinnedKey=B.key;B.boundsContext=nil;B.coverageBounds=nil
 local ok,mesh,entry,ready=pcall(B.get,...)
 for _,k in ipairs(fields)do B[k]=saved[k]end
 if not ok then error(mesh,0)end
 return ready
end
function B.release()
 cancelPending()
 for _,s in pairs(B.cache)do dispose(s)end
 B.cache={};B.serial=0;B.context=nil;B.boundsContext=nil
 B.clipBounds,B.coverageBounds=nil,nil
 B.mesh,B.key,B.count,B.entry,B.trees=nil,nil,0,nil,0
end
return B
