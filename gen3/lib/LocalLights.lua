-- Bounded world-space lights shared by terrain, cutouts and actors.
local V=...
local L={MAX=24}
local payloadKeys={'positions','colors','bounces','wallOnly','falloffs','points','sources'}
function L.windows(sp,profile,roof)
  local out,glass={},{}
  if roof and not next(sp.roofGlass or {})then return out,glass,{} end
  local firstRow,lastRow=roof and 0 or profile.roofRows,roof and profile.roofRows-1 or sp.H-1
  local ground=sp.H
  for y=sp.H-1,0,-1 do
    local found=false;for x=0,sp.W-1 do if sp.inside[y*sp.W+x] then found=true;break end end
    if found then ground=y+1;break end
  end
  -- Dark panes are a separate pass: dark borders touching bright glass
  -- must never enlarge that glass or join it to the rest of the facade.
  for pass=1,roof and 1 or 2 do
    local seen={}
    local function candidate(i)
      if roof then return sp.inside[i] and sp.roofGlass and sp.roofGlass[i] end
      return sp.inside[i] and (pass==1 and sp.faceDepth[i]==2
        or pass==2 and sp.darkGlass and sp.darkGlass[i])
    end
    for y=firstRow,lastRow do for x=0,sp.W-1 do
      local k=y*sp.W+x
      if candidate(k) and not seen[k] then
        local queue={k};seen[k]=true;local n,sx,sy=1,0,0
        local touchesBright=false
        local x0,x1,y0,y1=sp.W,0,sp.H,0
        while queue[n] do
          local i=queue[n];n=n+1;local xx,yy=i%sp.W,math.floor(i/sp.W)
          sx=sx+xx;sy=sy+yy
          x0=math.min(x0,xx);x1=math.max(x1,xx);y0=math.min(y0,yy);y1=math.max(y1,yy)
          for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}})do
            local nx,ny=xx+d[1],yy+d[2];local j=ny*sp.W+nx
            if pass==2 and nx>=0 and nx<sp.W and ny>=firstRow and ny<=lastRow
              and sp.inside[j] and sp.faceDepth[j]==2 then touchesBright=true end
            if nx>=0 and nx<sp.W and ny>=firstRow and ny<=lastRow
              and candidate(j) and not seen[j] then
              seen[j]=true;queue[#queue+1]=j
            end
          end
        end
        -- A blue pavement strip is not glass. Require a bounded pane
        -- above the ground line, rather than colouring every blue facade texel.
        local authored=(roof or profile.authoredGlass) and #queue>=2 and #queue<=4096 and x1-x0<128 and y1-y0<64
        local inferred=#queue>=8 and #queue<=240 and x1-x0>=3 and y1-y0>=2 and x1-x0<24 and y1-y0<24
        if not touchesBright and (authored or inferred) and y1<ground-3 then
          for _,i in ipairs(queue)do glass[i]=true end
          out[#out+1]={x=sx/#queue+.5,y=ground-sy/#queue-.5,z=profile.depthPx,
            radius=42,power=math.min(1,#queue/32),pixels=queue}
        end
      end
    end end
  end
  -- Native glass is split by mullions and highlight stripes. Merge nearby
  -- pieces into one pane light so they do not multiply the emitted energy.
  local changed=true
  while changed do
    changed=false
    for i=#out,2,-1 do
      for j=1,i-1 do
        local a,b=out[i],out[j]
        if math.abs(a.x-b.x)<13 and math.abs(a.y-b.y)<12 then
          local weight=a.power+b.power
          b.x=(a.x*a.power+b.x*b.power)/weight
          b.y=(a.y*a.power+b.y*b.power)/weight
          b.power=weight
          for _,pixel in ipairs(a.pixels)do b.pixels[#b.pixels+1]=pixel end
          table.remove(out,i);changed=true;break
        end
      end
    end
  end
  for _,l in ipairs(out)do l.power=math.min(1,l.power) end
  local owners={}
  for index,l in ipairs(out)do for _,pixel in ipairs(l.pixels)do owners[pixel]=index end end
  return out,glass,owners
end
-- One nearest-filtered mask per atlas: red/green retain exact glass/ghost
-- ownership; blue also excludes native water ink from ground-level snow.
-- Legacy glass records keep their blue bit (glass already rejects snow).
local masks=setmetatable({},{__mode='k'})
local blank
local capture
function L.beginGlassCapture(ts)
 local w,h=ts.image:getDimensions();capture={ts=ts,width=w,height=h,points={}}
end
function L.finishGlassCapture(ts)
 local c=capture;capture=nil
 if not c or c.ts~=ts then return false end
 return {width=c.width,height=c.height,points=c.points}
end
function L.registerGlass(ts,sp,glass,ghost)
  local m=masks[ts]
  if not m then
    local w,h=ts.image:getDimensions()
    m={data=love.image.newImageData(w,h),width=w,height=h,points={}};masks[ts]=m
  end
  for i in pairs(glass)do m.data:setPixel(sp.ax[i],sp.ay[i],1,1,1,0);m.points[sp.ay[i]*m.width+sp.ax[i]]=7 end
  for i in pairs(ghost or {})do
    local r=m.data:getPixel(sp.ax[i],sp.ay[i]);m.data:setPixel(sp.ax[i],sp.ay[i],r,1,0,0)
    m.points[sp.ay[i]*m.width+sp.ax[i]]=r+2
  end
  if capture and capture.ts==ts then
   for i in pairs(glass)do capture.points[sp.ay[i]*m.width+sp.ax[i]]=7 end
   for i in pairs(ghost or{})do local k=sp.ay[i]*m.width+sp.ax[i];capture.points[k]=(capture.points[k]or 0)%2+2 end
  end
  m.dirty=true
end
function L.exportGlass(ts)
 local m=masks[ts];if not m then return false end
 return {width=m.width,height=m.height,points=m.points}
end
function L.importGlass(ts,state)
 if not state then return end
 local w,h=ts.image:getDimensions()
 assert(state.width==w and state.height==h and type(state.points)=='table','invalid glass atlas')
 local m=masks[ts]
 if not m then m={data=love.image.newImageData(w,h),width=w,height=h,points={}};masks[ts]=m end
 for i,code in pairs(state.points)do
  assert(type(i)=='number'and i==math.floor(i)and i>=0 and i<w*h and type(code)=='number'and code==math.floor(code)and code>=0 and code<=7,'invalid glass pixel')
  local prior=m.points[i]or 0
  local r=math.max(prior%2,code%2);local g=math.max(math.floor(prior/2)%2,math.floor(code/2)%2);local b=math.floor(code/4)
  m.points[i]=r+g*2+b*4;m.data:setPixel(i%w,math.floor(i/w),r,g,b,0)
 end
 m.dirty=true
end
function L.bindGlass(shader,ts,def)
  local U=V.require('UniformState')
  if U.has(shader,'gymSignColor')then U.send(shader,'gymSignColor',V.require('GymRoofLight').color(def))end
  local m=ts and masks[ts]
  local water=V.require('SnowWaterMask');local bank=water.bank(ts)
  if bank then
    if not m then local w,h=ts.image:getDimensions();m={data=love.image.newImageData(w,h),width=w,height=h,points={}};masks[ts]=m end
    if m.waterBank~=bank then
      water.write(ts,m.data,bank);m.waterBank=bank;m.dirty=true
    end
  end
  if ts then
    if not m then local w,h=ts.image:getDimensions();m={data=love.image.newImageData(w,h),width=w,height=h,points={}};masks[ts]=m end
    if not m.badgesWritten then V.require('RoofBadgeLight').write(ts,m.data);V.require('GymRoofLight').write(ts,m.data);m.badgesWritten=true;m.dirty=true end
  end
  if m then
    if not m.image then m.image=love.graphics.newImage(m.data);m.image:setFilter('nearest','nearest')
    elseif m.dirty then m.image:replacePixels(m.data) end
    m.dirty=false;shader:send('glassMask',m.image)
  else
    if not blank then
      local d=love.image.newImageData(1,1);blank=love.graphics.newImage(d);d:release()
    end
    shader:send('glassMask',blank)
  end
end
function L.release()
  capture=nil
  V.require('StaticLightGrid').release()
  for _,m in pairs(masks)do if m.image then m.image:release() end;m.data:release() end
  if blank then blank:release();blank=nil end
  masks=setmetatable({},{__mode='k'})
  V.require('PaperBuildings').release()
  V.require('BuildingMesh').cache=setmetatable({},{__mode='k'})
end
-- Optional caller-owned output: reuse only when earlier draws have finished.
-- Callers that retain snapshots can omit it and receive independent tables.
function L.prepare(drawList,px,pz,outdoors,environment,state)
  state=state or{}
  local list=state._candidates or{};state._candidates=list
  local rows=state._rows or{};state._rows=rows
  local count=0
  local cfg=V.require("DioramaConfig").lighting
  local enabled=cfg.enabled and V.mod.options:get("gen3Lights")~=false
  local amount=enabled and outdoors and V.require("DayNight").windowLight() or 0
  local spatial=state._spatial or{};state._spatial=spatial
  local spatialCount=0
  if enabled then
    for _,l in ipairs(environment.lights)do
      if l.spatial then spatialCount=spatialCount+1;spatial[spatialCount]=l
      else
        count=count+1;local row=rows[count]or{};rows[count]=row
        row.light,row.d,row.dynamic=l,(l.x-px)^2+(l.z-pz)^2,true;list[count]=row
      end
    end
  end
  for i=#list,count+1,-1 do list[i]=nil end
  for i=#spatial,spatialCount+1,-1 do spatial[i]=nil end
  -- Drop references to departed light sources while keeping reusable rows.
  for i=count+1,#rows do rows[i].light=nil end
  local staticGrid=(amount>0 or #spatial>0)and V.require('StaticLightGrid').prepare(drawList,amount,spatial)or nil
  table.sort(list,function(a,b)
    if a.light.roomRank and b.light.roomRank and a.light.roomRank~=b.light.roomRank then return a.light.roomRank<b.light.roomRank end
    if a.d~=b.d then return a.d<b.d end
    if a.light.x~=b.light.x then return a.light.x<b.light.x end
    return a.light.z<b.light.z
  end)
  local budget=V.require('DioramaConfig').settings.maxLights
  for i=#list,budget+1,-1 do list[i]=nil end
  for _,key in ipairs(payloadKeys)do state[key]=state[key]or{} end
  local positions,colors,bounces,wallOnly,falloffs,points,sources=state.positions,state.colors,state.bounces,state.wallOnly,state.falloffs,state.points,state.sources
  for i=1,L.MAX do
    local l=list[i] and list[i].light
    sources[i]=l
    points[i]=l and (l.point or l.kind=="battle" or l.kind=="flash" or l.kind=="haunt" or l.kind=="player" and not outdoors and environment.cave and V.require("DioramaConfig").caves.enabled) and 1 or 0
    falloffs[i]=l and (l.falloff or 2)or 2
    wallOnly[i]=l and l.wallOnly and 1 or 0
    bounces[i]=l and (l.facadeBounce or 0)or 0
    local r=l and l.radius or 1
    -- Facade window/door pools reach further into the street (reference night clips).
    if l and not list[i].dynamic and r>0 then r=r*(cfg.windowRadiusScale or 1) end
    local position=positions[i]or{};positions[i]=position
    position[1],position[2],position[3],position[4]=l and l.x or 0,l and l.y or 0,l and l.z or 0,r
    local c=l and l.color or cfg.windowColor
    local lamp=V.require('WindowVariation').sample(l and l.variationCode)
    local color=colors[i]or{};colors[i]=color
    color[1],color[2],color[3]=l and c[1]*lamp[1]or 0,l and c[2]*lamp[2]or 0,l and c[3]*lamp[3]or 0
    color[4]=l and l.power*lamp[4]*(list[i].dynamic and 1 or amount*cfg.windowStrength)or 0
  end
  state.staticGrid,state.roomRig=staticGrid,environment.roomRig
  state.cave=not outdoors and environment.cave and V.require('DioramaConfig').caves.enabled
  state.count,state.amount=math.min(#list,L.MAX),amount
  state._groupBoundsDirty=true
  return state
end
function L.send(shader,state)
  V.require('StaticLightGrid').send(shader,state.staticGrid)
  V.require("WindowVariation").bind(shader)
  V.require("RoomLightRig").send(shader,state.roomRig,state.sources)
  V.require('UniformState').send(shader,"lightCount",state.count)
  if not state.groupBounds or state._groupBoundsDirty then
    local bounds=state.groupBounds or{}
    for group=0,5 do
      local x0,z0,x1,z1=math.huge,math.huge,-math.huge,-math.huge
      for i=group*4+1,math.min(group*4+4,state.count)do
        local p=state.positions[i];local r=math.abs(p[4])+1
        x0=math.min(x0,p[1]-r);z0=math.min(z0,p[3]-r)
        x1=math.max(x1,p[1]+r);z1=math.max(z1,p[3]+r)
      end
      local b=bounds[group+1]or{};bounds[group+1]=b
      if x0==math.huge then b[1],b[2],b[3],b[4]=0,0,0,0
      else b[1],b[2],b[3],b[4]=x0,z0,x1,z1 end
    end
    state.groupBounds=bounds;state._groupBoundsDirty=false
  end
  V.require('UniformState').send(shader,"localGroupBounds",unpack(state.groupBounds))
  V.require('UniformState').send(shader,"labFacadeFill",V.require("DioramaConfig").lighting.labFacadeFill)
  V.require('UniformState').send(shader,"localWallOnly",unpack(state.wallOnly))
  V.require('UniformState').send(shader,"localFalloff",unpack(state.falloffs))
  V.require('UniformState').send(shader,"localPoint",unpack(state.points))
  local cave=V.require('DioramaConfig').caves
  V.require('UniformState').send(shader,'caveMode',state.cave and 1 or 0)
  V.require('UniformState').send(shader,'caveSpillLimit',cave.spillLimit)
  V.require('UniformState').send(shader,'caveMaterialResponse',cave.materialResponse)
  V.require('UniformState').send(shader,'caveAmbientTexture',cave.ambientTexture)
  V.require('UniformState').send(shader,'caveDiffuseFloor',cave.diffuseFloor)
  V.require('UniformState').send(shader,'caveActorLight',cave.actorLight or 1)
  V.require('UniformState').send(shader,"groundLightColor",V.require('DioramaConfig').lighting.groundLightColor)
  V.require('UniformState').send(shader,"fenceLightResponse",V.require('DioramaConfig').props.fenceLightResponse)
  V.require('UniformState').send(shader,"signLightResponse",V.require('DioramaConfig').props.signLightResponse)
  V.require('UniformState').send(shader,"signAlphaCutoff",V.require('DioramaConfig').props.signAlphaCutoff)
  V.require('UniformState').send(shader,"signBloomCeiling",V.require('DioramaConfig').props.signBloomCeiling)
  V.require('UniformState').send(shader,"windowConePower",V.require("DioramaConfig").lighting.windowConePower)
  V.require('UniformState').send(shader,"localBounce",unpack(state.bounces))
  V.require('UniformState').send(shader,"facadeFill",V.require("DioramaConfig").lighting.facadeFill)
  V.require('UniformState').send(shader,"facadeLightColor",V.require("DioramaConfig").lighting.facadeLightColor)
  V.require('UniformState').send(shader,"localPosition",unpack(state.positions))
  V.require('UniformState').send(shader,"localColor",unpack(state.colors))
  V.require('UniformState').send(shader,"windowAmount",state.amount)
  V.require('UniformState').send(shader,"spillLimit",V.require("DioramaConfig").lighting.spillLimit)
  V.require('UniformState').send(shader,"glassTextureStrength",V.require("DioramaConfig").lighting.glassTextureStrength)
  V.require('UniformState').send(shader,"windowEmission",V.require('DioramaConfig').lighting.windowEmission)
end
return L
