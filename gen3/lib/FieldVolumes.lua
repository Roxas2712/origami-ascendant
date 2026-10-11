-- Lightweight side/back closures for the optional field cameras. The native
-- front/roof artwork, collision and warp footprint remain authoritative.
-- Prepared once per retained map mesh; never rebuilt on camera rotation.
local V=...
local F={cache=setmetatable({},{__mode='k'})}
function F.get(cached,def,ts,ox,oz)
 if not V.data('Shapes').outdoors(def)then return nil end
 local old=F.cache[cached];F.pending=false;if old~=nil then return old or nil end
 local function build()
 local Budget=V.require('BuildBudget');local Queue=V.require('NativeBuildQueue');Budget.phase('field closures')
 local G=V.require('WorldGeometry');local out={}
 local canopy=false
 local BM=V.require('BuildingMesh');local buildings=G.buildings(def)
 local function donor(b,roof)
  -- A single native palette texel closes unillustrated sides. Pick a common
  -- opaque wall/roof colour, excluding windows and dark ink outlines.
  local counts,points={},{}
  local first,last=roof and math.max(0,b.y0-1) or math.max(b.y0,b.y1-1),roof and b.y0 or b.y1
  for y=first,last do for x=b.x0,b.x1 do
   local mid=def.midLayout:midAt(x,y)
   Budget.check();for sy=2,13,2 do for sx=2,13,2 do
    local r,g,blue,a=BM.pixel(ts,mid,sx,sy)
    if a>.9 and math.min(r,g,blue)>.18 and math.max(r,g,blue)-math.min(r,g,blue)<.2 then
     local key=math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(blue*255+.5)
     counts[key]=(counts[key]or 0)+1;points[key]={mid,sx,sy}
    end
   end end
  end end
  local best,n=nil,0;for k,c in pairs(counts)do if c>n then best,n=points[k],c end end
  if not best then
   -- Saturated Hoenn walls still require a closed body. Fall back to an
   -- opaque native texel rather than silently omitting the rear.
   for y=first,last do for x=b.x0,b.x1 do for sy=2,13,2 do for sx=2,13,2 do
    local mid=def.midLayout:midAt(x,y);local r,g,blue,a=BM.pixel(ts,mid,sx,sy)
    if a>.9 and math.max(r,g,blue)>.2 then best={mid,sx,sy};break end
   end end end end
  end
  if not best then return nil end
  return G.uv(ts,best[1],best[2],best[3],best[2]+1,best[3]+1,.5)
 end
 for _,b in ipairs(buildings)do Budget.check()
  if V.require('SeasonalFoliage').canopyBuilding(b,def.midLayout)then canopy=true else
   local spec=V.data('BuildingProfiles').get(b,def.midLayout)
   local sp,profile=BM.sprite(b,def.midLayout,ts,true);local baseRow=sp.H
   for y=sp.H-1,0,-1 do local any=false;for x=0,sp.W-1 do if sp.inside[y*sp.W+x]then any=true;break end end;if any then baseRow=y+1;break end end
   local line=math.min(profile.roofRows,baseRow-8)
   local landmark=spec.landmark and V.require('DioramaConfig').buildings[spec.landmark]
   local scale=landmark and landmark.wallScale or spec.wallScaleKey and V.require('DioramaConfig').buildings[spec.wallScaleKey]or spec.paper and spec.paper.wallScale or spec.foldWallScale
   local h=(baseRow-line)*scale*V.require('Billboard').heightScale()
   if landmark and landmark.baseRows then h=h+math.min(baseRow-line,landmark.baseRows)*(landmark.baseWallScale-landmark.wallScale)*V.require('Billboard').heightScale()end
   local rise=math.min(7,line*.16);local e=V.require('Camera').geometryElevation()
   local depth=math.max(4,(line*(spec.paper and spec.paper.roofScale or .60)-rise*math.cos(e))/math.sin(e))
   local x0,x1=(b.x0+ox)*16+1,(b.x1+1+ox)*16-1
   local z1=((b.facadeBaseY or b.y1+1)+oz)*16-.1;local z0=z1-depth
   local base=V.require('EmeraldFortreeArchitecture').buildingBase(b)+V.require('EmeraldPacifidlog').buildingBase(b)
   local uv=donor(b,false)
   if uv then
    local function quad(a,b,c,d)G.quad(out,a,b,c,d,uv,6);for i=#out-5,#out do out[i][9]=-1 end end
    quad({x0,base,z0},{x0,base,z1},{x0,base+h,z1},{x0,base+h+rise,z0})
    quad({x1,base,z1},{x1,base,z0},{x1,base+h+rise,z0},{x1,base+h,z1})
    quad({x1,base,z0},{x0,base,z0},{x0,base+h+rise,z0},{x1,base+h+rise,z0})
    quad({x0,base,z1-.08},{x1,base,z1-.08},{x1,base+h,z1-.08},{x0,base+h,z1-.08})
    local roofUV=donor(b,true)or uv;local wallUV=uv;uv=roofUV
    quad({x0,base+h-.08,z1},{x1,base+h-.08,z1},{x1,base+h+rise-.08,z0},{x0,base+h+rise-.08,z0});uv=wallUV
   end
  end
 end
 local scene
 -- Packed geometry may retain isolated native crown-tip tiles (the green
 -- triangles in the report). Only their floor quads get a local ground
 -- donor; the upright tree artwork and collision remain untouched.
 local tipFix=V.require('Trees').standaloneFor(def.renderPair or def.pair,ts.midToSlot)
 if canopy or tipFix then
  local vertices,groups={},{};local changed=false;local fixedTips=0
  local w,h=ts.image:getDimensions();local ground=G.uv(ts,G.ground(def,ts))
  for i=1,cached.mesh:getVertexCount()do Budget.tick()
   local v={cached.mesh:getVertex(i)};vertices[i]=v
   if tipFix and v[2]>=-.001 and v[2]<.10 and v[9]==0 and v[6]==1 then
    local slot=math.floor(v[5]*h/16)*ts.cols+math.floor(v[4]*w/16)
    if slot==ts.midToSlot[0xe]or slot==ts.midToSlot[0xf]then
     local u=(v[4]*w)%16/16;local z=(v[5]*h)%16/16
     v[4]=ground[1]+u*(ground[3]-ground[1]);v[5]=ground[2]+z*(ground[4]-ground[2]);changed=true;fixedTips=fixedTips+1
    end
   end
   if v[9]==-4 then
    local k=v[7]..':'..v[8];local bounds=groups[k]
    if bounds then bounds[1],bounds[2]=math.min(bounds[1],v[1]),math.max(bounds[2],v[1])else groups[k]={v[1],v[1]}end
   end
  end
  for _,v in ipairs(vertices)do if v[9]==-4 then
   local bounds=groups[v[7]..':'..v[8]];v[7]=(bounds[1]+bounds[2])*.5;v[9]=1;changed=true
  end end
  if changed then
  local mesh=Queue.own(love.graphics.newMesh(G.FORMAT,vertices,'triangles','static'))
  scene=setmetatable({mesh=mesh,stats=setmetatable({frustumBounds=V.require('SceneVisibility').merge(V.require('SceneVisibility').vertices(vertices),cached.stats.frustumBounds)},{__index=cached.stats})},{__index=cached})
  end
 end
 if #out==0 and not scene then F.cache[cached]=false;return nil end
 local mesh=#out>0 and Queue.own(love.graphics.newMesh(G.FORMAT,out,'triangles','static'))or nil
 local item={mesh=mesh,instances={},stats={vertices=#out,storedVertices=#out,buildings=0,lights={},contacts={},frustumBounds=V.require('SceneVisibility').vertices(out)},
  heights={},atlas=ts,def=def,foliageOrigin=cached.foliageOrigin}
 item.scene=scene;F.cache[cached]=item;return item
 end
 local R=V.require('Renderer')
 if R.cooperative then
  local result=V.require('NativeBuildQueue').get('field-volume:'..tostring(cached),R.tick,build)
  F.pending=F.cache[cached]==nil;return result
 end
 return build()
end
function F.release(cached)
 local item=F.cache[cached];if item then if item.mesh then item.mesh:release()end;if item.scene then item.scene.mesh:release()end end;F.cache[cached]=nil
end
return F
