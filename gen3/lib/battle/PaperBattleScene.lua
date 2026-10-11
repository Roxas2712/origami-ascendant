local V=...
local Scene={}
local function battleAngle()return V.require('GraphicsOverlay').battleAngle()end
local Adapter=V.require('WorldAdapter')
local Mat4=V.require('Mat4')
local Config=V.require('DioramaConfig')
local angles={0,math.pi/6,-math.pi/6,math.pi/3,-math.pi/3}
local footprintOffsets={{0,0},{-1,0},{1,0},{0,-1},{0,1}}
local search,searchTiles,searchScales
local function searchOrder(cfg)
  local same=search and searchTiles==cfg.searchTiles and #searchScales==#cfg.layoutScales
  if same then for i,scale in ipairs(cfg.layoutScales)do
    if searchScales[i]~=scale then same=false;break end
  end end
  if same then return search end
  local candidates={}
  for _,scale in ipairs(cfg.layoutScales)do
   for _,angle in ipairs(angles)do
    for dz=-cfg.searchTiles,cfg.searchTiles do for dx=-cfg.searchTiles,cfg.searchTiles do
     candidates[#candidates+1]={scale=scale,angle=angle,dx=dx,dz=dz,
       score=dx*dx+dz*dz+math.abs(angle)*2+(1-scale)*50,ordinal=#candidates+1}
    end end
   end
  end
  table.sort(candidates,function(a,b)return a.score<b.score or a.score==b.score and a.ordinal<b.ordinal end)
  search,searchTiles,searchScales=candidates,cfg.searchTiles,{unpack(cfg.layoutScales)}
  return search
end
-- The ranked offsets depend only on configuration, never on the map or party.
-- Prepare the default once during mod loading; map edits still get fresh
-- collision, height, fitting and occlusion checks on every create().
searchOrder(Config.battle)

function Scene.create(game,battle,actorScale)
  -- Adapter creation runs before the ordinary end-of-update options hook.
  -- Select the battle angle before placement, height and occlusion tests.
  V.require('GraphicsOverlay').apply()
  V.require('Renderer').selectGeometry()
  local id,def=Adapter.current(game)
  if not id then return nil,'no native map' end
  local p=Adapter.Player
  local Collision=require('src.core.game3.collision')
  local cfg=Config.battle
  local bodies=V.require('battle/BattleFootprints').forBattle(battle,cfg)
  -- Map battles share the scenery's world units. The old readability
  -- multiplier enlarged every cutout by 65% independently of the map.
  actorScale=actorScale or 1
  local Renderer=V.require('Renderer')
  -- Placement and the first battle frame need every visible connection.
  -- An active-map-only cache hit can still return the retained field image
  -- while a neighbor builds, then composite battle actors onto that old camera.
  local neighbors=V.mod.options:get('gen3Neighbors')~=false
  local function mapReady()
    local entries=Adapter.maps(game,neighbors,240,160)
    if #entries==0 then return false end
    for _,entry in ipairs(entries)do
      local preserve=Config.trees.preserveViewRows[id]and entry.id~=id
      local key=entry.id..':'..tostring(entry.ox)..':'..tostring(entry.oy)..':'..tostring(preserve)
      local cached=Renderer.cache[key]
      if not cached or cached.layout~=entry.def.midLayout
        or cached.stamp~=V.require('WorldGeometry').layoutStamp(entry.def.midLayout)then return false end
    end
    return true
  end
  if not mapReady()then
    love.graphics.push('all')
    local pw,ph=love.graphics.getPixelDimensions()
    local ok,err=pcall(Renderer.draw,game,240,160,'paper',neighbors,pw,ph,{prepareOnly=true})
    love.graphics.pop();if not ok then error(err)end
    if not mapReady()or Renderer.buildPending then
      return {pendingMap=id,kind='map-loading',cinematic=true,nativeIntroVisible=false,feet={}}
    end
  end
  -- Map geometry and collision are stable for this synchronous placement.
  -- Cache cell queries only for this call so later scripted map edits remain live.
  local heightMaps={}
  for _,cached in pairs(Renderer.cache)do
    if cached.layout==def.midLayout then heightMaps[#heightMaps+1]=cached.heights end
  end
  local heightCells,walkCells={},{}
  local Sky=V.require('EmeraldSkyPillar')
  local Furniture=V.require('Furniture')
  local elevation=p.currentElevation~=0 and p.currentElevation or p.elevation
  local groundCells={}
  local function ground(x,z)
    -- WorldAdapter uses top-left native sprite coordinates; battle feet use
    -- the middle of their bottom edge. Ask the same floor provider as the field.
    local cx,cz=math.floor(x/8),math.floor(z/8)
    local row=groundCells[cz];if not row then row={};groundCells[cz]=row end
    if row[cx]==nil then row[cx]=Furniture.actorOffset(def,cx*8+4-8,cz*8+4-16,nil,elevation)or 0 end
    return row[cx]
  end
  local encounterGround=Furniture.actorOffset(def,p.px,p.py,nil,elevation)or 0
  local function height(x,z)
    local cx,cz=math.floor(x/8),math.floor(z/8)
    local row=heightCells[cz]
    if not row then row={};heightCells[cz]=row end
    if row[cx]~=nil then return row[cx] end
    local h=0
    for _,heights in ipairs(heightMaps)do
      local hr=heights[cz];h=math.max(h,hr and hr[cx]or 0)
    end
    row[cx]=h;return h
  end
  local function walkable(cx,cy)
    local row=walkCells[cy]
    if not row then row={};walkCells[cy]=row end
    if row[cx]==nil then row[cx]=not not Collision.isWalkable(cx,cy)end
    return row[cx]
  end
  local function clear(x,z,scale,level)
    for _,off in ipairs(footprintOffsets)do
      local ox,oz=off[1]*cfg.footprint*scale,off[2]*cfg.footprint*scale
      local cx,cy=math.floor((x+ox)/16),math.floor((z+oz)/16)
      if not Sky.floorCell(def,cx,cy)or cx<0 or cy<0 or cx>=def.midLayout.width or cy>=def.midLayout.height or not walkable(cx,cy)or math.abs(ground(x+ox,z+oz)-level)>.1 or height(x+ox,z+oz)>level+2 then return false end
    end
    return true
  end
  -- Evaluate the same candidates in ascending score order. The first valid
  -- layout is the old search's final minimum; ordinal preserves ties exactly.
  local candidates=searchOrder(cfg)
  local pick
  local fitted={}
  for _,choice in ipairs(candidates)do
    local scale,angle,dx,dz=choice.scale,choice.angle,choice.dx,choice.dz
    local x,z=p.px+8+dx*16,p.py+16+dz*16
    local spacing=math.max(cfg.spacing,(bodies.player.right+bodies.enemy.left+4)*actorScale)
    local playerGap=math.max(cfg.trainerOffset,(bodies.playerTrainer.right+bodies.player.left+4)*actorScale)
    local enemyGap=math.max(cfg.trainerOffset,(bodies.enemy.right+bodies.enemyTrainer.left+4)*actorScale)
    local feet={player={x-spacing/2,z+cfg.depth/2},enemy={x+spacing/2,z-cfg.depth/2}}
    feet.playerTrainer={feet.player[1]-playerGap,feet.player[2]+cfg.trainerDepth}
    if not battle or not battle.wild then feet.enemyTrainer={feet.enemy[1]+enemyGap,feet.enemy[2]-cfg.trainerDepth}end
    if angle~=0 then
      for _,foot in pairs(feet)do local a,b=foot[1]-x,foot[2]-z;foot[1]=x+a*math.cos(angle)-b*math.sin(angle);foot[2]=z+a*math.sin(angle)+b*math.cos(angle)end
    end
    for _,foot in pairs(feet)do foot[1]=x+(foot[1]-x)*scale;foot[2]=z+(foot[2]-z)*scale end
      local candidate={map=id,elevationDegrees=battleAngle(),scale=scale*actorScale,feet=feet,bodies=bodies,level=encounterGround,ground={},focus={px=x-8,py=z-8},
        compactRoom=tonumber(def.mapType)==8 and def.midLayout.width<=24 and def.midLayout.height<=24}
      for side in pairs(feet)do candidate.ground[side]=encounterGround end
      local valid=true
      for _,foot in pairs(feet)do if not clear(foot[1],foot[2],scale,encounterGround)then valid=false;break end end
      if valid then
        -- Every candidate shares the encounter floor height. Translating its
        -- footprint translates the camera too, so angle/scale fitting is reusable.
        local key=tostring(scale)..':'..tostring(angle)
        local fit=fitted[key]
        if fit then
          candidate.distance=fit.distance
          candidate.focus.px=candidate.focus.px+fit.dx
          candidate.focus.py=candidate.focus.py+fit.dz
          candidate.frame={unpack(fit.frame)}
        else
          local px,pz=candidate.focus.px,candidate.focus.py
          Scene.fit(candidate)
          fitted[key]={distance=candidate.distance,
            dx=candidate.focus.px-px,dz=candidate.focus.py-pz,frame=candidate.frame}
        end
      end
      if valid and not Scene.separated(candidate)then valid=false end
      if valid then
      local _,eye=Scene.matrix(nil,candidate.focus.px,candidate.focus.py,nil,240,160,candidate)
      for side,foot in pairs(feet)do
        if not clear(foot[1],foot[2],scale,encounterGround)then valid=false;break end
        -- Check the body width as well as its feet. A walkable anchor alone
        -- can leave half a sprite behind a pillar or a leaning canopy.
        local correction=Config.billboards.preservePixelAspect and 1/math.cos(math.rad(candidate.elevationDegrees))or 1
        local half=math.max(bodies[side].left,bodies[side].right)*candidate.scale*correction
        -- Sample the whole card width and nearby ray at sub-cell intervals;
        -- three rays can straddle a narrow statue without hitting it.
        local samples=math.max(2,math.ceil(half*2/4))
        for column=0,samples do
         local offset=-half+half*2*column/samples
         for step=0,96 do
          local t=step/256;local start=foot[1]+offset
          local rx=start+(eye[1]-start)*t
          local rz=foot[2]+(eye[3]-foot[2])*t
          local startY=encounterGround+4
          local ry=startY+(eye[2]-startY)*t
          local h=height(rx,rz)
          if h>2 and ry<h then valid=false;break end
         end
         if not valid then break end
        end
        if not valid then break end
      end
      end
      if valid then pick=candidate;break end
  end
  -- Tight native rooms/tunnels may need smaller cards to keep every actor
  -- clear. Reduce only presentation scale; never relax the occlusion check.
  if not pick and actorScale>1 then return Scene.create(game,battle,math.max(1,actorScale*.8))end
  if not pick then return nil,'no clear battle footprints/sightlines nearby' end
  return pick
end

function Scene.project(scene,x,y,z)
  local vp=Scene.matrix(nil,scene.focus.px,scene.focus.py,nil,240,160,scene)
  local u,v=V.require('Camera').project(vp,x,y,z)
  return u and u*240,v and v*160
end

function Scene.foot(scene,side)
  local p=scene.feet[side]
  return Scene.project(scene,p[1],scene.ground and scene.ground[side] or 0,p[2])
end

function Scene.spriteHeight(scene,side,height)
  local p=scene.feet[side]
  local _,foot=Scene.foot(scene,side)
  -- Upright scenery preserves native pixel aspect about its fixed foot.
  -- Battle cutouts need the same projection correction, not a size preset.
  local correction=Config.billboards.preservePixelAspect and 1/math.cos(math.rad(scene.elevationDegrees or battleAngle()))or 1
  local _,top=Scene.project(scene,p[1],(scene.ground and scene.ground[side]or 0)+(height or Config.battle.spriteHeight)*(scene.scale or 1)*correction,p[2])
  return foot-top
end

function Scene.actorBounds(scene,side)
 local cfg=Config.battle
 local h=side:find('Trainer')and cfg.trainerHeight or cfg.spriteHeight*1.5
 local b=scene.bodies and scene.bodies[side]or{left=h*.55,right=h*.55,height=h}
 local x,y=Scene.foot(scene,side);local scale=Scene.spriteHeight(scene,side,b.height)/b.height
 return {x-b.left*scale,y-b.height*scale,x+b.right*scale,y}
end
function Scene.separated(scene)
 local rects={}
 for side in pairs(scene.feet)do rects[#rects+1]=Scene.actorBounds(scene,side)end
 for i=1,#rects do for j=i+1,#rects do local a,b=rects[i],rects[j]
  if math.min(a[3],b[3])+1>math.max(a[1],b[1])and math.min(a[4],b[4])+1>math.max(a[2],b[2])then return false end
 end end
 return true
end

function Scene.matrix(_,px,py,_,width,height,scene)
  if scene and scene.vp then return scene.vp,scene.eye,scene.target end
  local c=Config.battle
  local pitch=math.rad(math.max(20,math.min(60,scene and scene.elevationDegrees or battleAngle())))
  local distance=math.max(120,scene and scene.distance or c.distance)
  local target={px+8+c.focusOffsetX,scene and scene.level or 0,py+8+c.focusOffsetZ}
  local eye={target[1],target[2]+distance*math.sin(pitch),target[3]+distance*math.cos(pitch)}
  local projection=Mat4.perspective(math.rad(math.max(8,math.min(35,c.fovDegrees))),width/height,1,3000)
  local vp=Mat4.mul(Mat4.scale(1,-1,1),Mat4.mul(projection,Mat4.lookAt(eye,target,{0,1,0})))
  vp[14]=0
  return vp,eye,target
end

-- Fit actual actor feet/tops between the original HP skins and command box.
-- This is presentation-only: native map, player position and field camera stay put.
function Scene.fit(scene,frame)
 scene.elevationDegrees=battleAngle()
 local c=Config.battle;local f=frame or c.safeFrame
 local function bounds()
  local vp=Scene.matrix(nil,scene.focus.px,scene.focus.py,nil,240,160,scene)
  local camera=V.require('Camera')
  local left,top,right,bottom=math.huge,math.huge,-math.huge,-math.huge
  for side in pairs(scene.feet)do
   local b=Scene.actorBounds(scene,side)
   left,right=math.min(left,b[1]),math.max(right,b[3]);top,bottom=math.min(top,b[2]),math.max(bottom,b[4])
  end
  return left,top,right,bottom
 end
 -- Start closer in small rooms; the same actor bounds still enforce HUD clearance.
 scene.distance=c.distance*(scene.scale or 1)*(scene.compactRoom and .72 or 1)
 for _=1,8 do
  local l,t,r,b=bounds()
  local ratio=math.max((r-l)/(f.right-f.left),(b-t)/(f.bottom-f.top))
  if ratio>1 then scene.distance=scene.distance*ratio*1.01;l,t,r,b=bounds()end
  local cx,cy=(l+r)/2,(t+b)/2
  scene.focus.px=scene.focus.px+1;local l2,_,r2=bounds();scene.focus.px=scene.focus.px-1
  scene.focus.py=scene.focus.py+1;local _,t2,_,b2=bounds();scene.focus.py=scene.focus.py-1
  scene.focus.px=scene.focus.px+((f.left+f.right)/2-cx)/((l2+r2)/2-cx)
  scene.focus.py=scene.focus.py+((f.top+f.bottom)/2-cy)/((t2+b2)/2-cy)
 end
 scene.frame={bounds()}
end

function Scene.render(game,scene,width,height,presentation,record)
  if not scene.pendingMap and scene.elevationDegrees~=battleAngle()then
    -- A camera edit never respawns or rescales the battle formation. Refit
    -- projection around the same feet, physical sizes and encounter floor.
    local Renderer=V.require('Renderer');local ready=true
    local neighbors=V.mod.options:get('gen3Neighbors')~=false
    for _,entry in ipairs(Adapter.maps(game,neighbors,width,height))do
      local preserve=Config.trees.preserveViewRows[scene.map]and entry.id~=scene.map
      local key=entry.id..':'..tostring(entry.ox)..':'..tostring(entry.oy)..':'..tostring(preserve)
      local cached=Renderer.cache[key]
      if not cached or cached.layout~=entry.def.midLayout then ready=false;break end
    end
    -- Keep the captured pose and camera together while the new angle's
    -- geometry loads; the last complete frame stays at display resolution.
    if ready then scene.mapViewportKey=nil;Scene.fit(scene)end
  end
  if scene.pendingMap then
    if Adapter.current(game)~=scene.pendingMap then return nil,'map changed during battle'end
    -- Cold entry has no previous battle view. Keep it covered while the
    -- adapter prepares geometry; never return the retained overworld image.
    if not Scene.loadingCanvas then
      Scene.loadingCanvas=love.graphics.newCanvas(240,160,{dpiscale=1})
      love.graphics.push('all');love.graphics.setCanvas(Scene.loadingCanvas)
      love.graphics.clear(0,0,0,1);love.graphics.pop()
    end
    return Scene.loadingCanvas
  end
  local id=Adapter.current(game)
  if id~=scene.map then return nil,'map changed during battle' end
  local viewport=V.require('battle/MapBattleViewport')
  if viewport.active(scene)then
    local layout=viewport.layout(game);local f=layout.actorFrame
    local key=table.concat({f.left,f.top,f.right,f.bottom},':')
    if scene.mapViewportKey~=key then Scene.fit(scene,f);scene.mapViewportKey=key end
  elseif scene.mapViewportKey then
    Scene.fit(scene);scene.mapViewportKey=nil
  end
  local scale=viewport.active(scene)and viewport.resolution(game)or math.max(1,math.min(6,math.max(Config.battle.renderScale*V.require('RenderResolution').scale(),math.ceil(require('src.render.Renderer'):fitScale()))))
  -- MAP fitting can request a 2880 x 1920 intermediate on a wide phone.
  -- Preserve its projection/crop, but use the same bounded mobile raster as
  -- the field and terrarium; native HP/text/touch remain full resolution.
  if V.require('MobileRenderBudget').active()then
    scale=math.min(scale,V.require('battle/BattleResolution').scenery(require('src.render.Renderer'):fitScale()))
  end
  -- The native compositor retains the entire battle animation stack. Render
  -- at display resolution, retaining nearest-filtered native texture detail.
  presentation:prepare(record)
  return V.require('Renderer').draw(game,width,height,'paper',V.mod.options:get('gen3Neighbors')~=false,
    math.floor(width*scale),math.floor(height*scale),
    {readableDepth=Config.battle.spriteScreenResolution~=false,focus=scene.focus,matrix=function(mode,x,z,facing,w,h)return Scene.matrix(mode,x,z,facing,w,h,scene)end,hideActors=true,
      lights=function(atmosphere)presentation:lights(record,atmosphere)end,
      shadowCasters=function(vp)presentation:shadowCasters(record,function(mesh,texture)mesh:setTexture(texture);love.graphics.draw(mesh)end,vp)end,
      drawLayers=function(...)presentation:drawLayers(record,...)end})
end
return Scene
