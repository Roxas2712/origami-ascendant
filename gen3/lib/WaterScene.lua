-- A bounded, half-resolution planar reflection of actual scene geometry.
-- No readback, temporal history, or extra simulation step: moving actors use
-- the same pose as the main pass. Keep a few exact native bank fields when
-- adjacent maps repeatedly enter and leave the visible connection set.
local V=...
local Bounds=V.require('WaterReflectionBounds')
local Uniform=V.require('UniformState')
local texel,emptyArea,clipBoxes={1,1},{0,0,1,1},{}
local M={bankStates={},bankSerial=0}
function M.release()
 for _,s in pairs(M.bankStates)do s.banks:release()end
 M.bankStates={};M.bankSerial=0;M.banks=nil;M.area=nil;M.hasWater=nil;M.active=false
 for _,k in ipairs{'color','depth','blank'}do if M[k]then M[k]:release();M[k]=nil end end
 M.key=nil;M.native=nil;M.clipMatrix=nil;M.clipRect=nil;M.clipBoxes=nil
end
function M.prepare(entries,width,height,enabled,format)
 if not M.blank then local d=love.image.newImageData(1,1);M.blank=love.graphics.newImage(d);d:release()end
 M.active=false
 if not enabled then return false end
 local keys={};local native=true;local geometry=V.require('WorldGeometry')
 for _,e in ipairs(entries)do
  local l=e.def.midLayout
  keys[#keys+1]=e.id..':'..e.ox..':'..e.oy..':'..tostring(l)..':'..l.width..':'..l.height..':'..geometry.layoutStamp(l)
  if not tostring(e.id):match('^FR_')then native=false end
 end
 local key=table.concat(keys,'|')
 M.bankSerial=M.bankSerial+1
 local state=M.bankStates[key]
 if state then state.used=M.bankSerial end
 if M.key~=key then
  if not state then
  local minx,minz,maxx,maxz=math.huge,math.huge,-math.huge,-math.huge
  for _,e in ipairs(entries)do local l=e.def.midLayout
   minx=math.min(minx,e.ox);minz=math.min(minz,e.oy);maxx=math.max(maxx,e.ox+l.width);maxz=math.max(maxz,e.oy+l.height)
  end
  local w,h=maxx-minx,maxz-minz
  -- Malformed/oversized connection sets fall back to analytic highlights.
  if w<=0 or h<=0 or w>1024 or h>1024 then return false end
  local wet={};local count=0;local shapes=V.data('Shapes')
  for _,e in ipairs(entries)do local l=e.def.midLayout
   for z=0,l.height-1 do for x=0,l.width-1 do
    local i=(z+e.oy-minz)*w+x+e.ox-minx+1
    wet[i]=shapes.water(l:cellAt(x,z))and true or false
   end end
  end
  local dist={};for i=1,w*h do dist[i]=wet[i]and 8 or 0;if wet[i]then count=count+1 end end
  -- Two-pass distance field. Unknown map edges stay deep, never invent surf
  -- at the boundary of the streamed scene. Native bank texels stay masked.
  for z=0,h-1 do for x=0,w-1 do local i=z*w+x+1
   if x>0 then dist[i]=math.min(dist[i],dist[i-1]+1)end
   if z>0 then dist[i]=math.min(dist[i],dist[i-w]+1)end
  end end
  for z=h-1,0,-1 do for x=w-1,0,-1 do local i=z*w+x+1
   if x<w-1 then dist[i]=math.min(dist[i],dist[i+1]+1)end
   if z<h-1 then dist[i]=math.min(dist[i],dist[i+w]+1)end
  end end
  local d=love.image.newImageData(w,h)
  for z=0,h-1 do for x=0,w-1 do d:setPixel(x,z,dist[z*w+x+1]/8,0,0,1)end end
  local banks=love.graphics.newImage(d);d:release();banks:setFilter('linear','linear')
  local refs={};for _,e in ipairs(entries)do refs[#refs+1]=e.def.midLayout end
  state={banks=banks,area={minx*16,minz*16,w*16,h*16},hasWater=count>0,used=M.bankSerial,layouts=refs}
  M.bankStates[key]=state
  end
  local count=0;for _ in pairs(M.bankStates)do count=count+1 end
  -- Keep connected banks warm in all three editions. Owners stay alive
  -- until eviction so a layout address cannot identify unrelated data.
  local limit=4
  while count>limit do
   local oldest,age=nil,math.huge
   for k,s in pairs(M.bankStates)do if k~=key and s.used<age then oldest,age=k,s.used end end
   M.bankStates[oldest].banks:release();M.bankStates[oldest]=nil;count=count-1
  end
  M.banks=state.banks;M.area=state.area;M.hasWater=state.hasWater;M.key=key
  -- Missing receiver metadata still falls back to the complete reflection.
  M.native=native
  M.clipMatrix=nil
 end
 if not M.hasWater then return false end
 local w,h=math.max(1,math.ceil(width*.5)),math.max(1,math.ceil(height*.5))
 format=format or 'rgba8'
 if not M.color or M.color:getWidth()~=w or M.color:getHeight()~=h or M.color:getFormat()~=format then
  if M.color then M.color:release();M.depth:release()end
  M.color=love.graphics.newCanvas(w,h,{format=format,dpiscale=1});M.color:setFilter('linear','linear')
  M.depth=love.graphics.newCanvas(w,h,{format='depth24',dpiscale=1})
 end
 M.active=true;return true
end
-- Reuse screen bounds while the camera is stationary. A changed map set,
-- camera matrix or render size invalidates them; no temporal approximation.
function M.clip(vp,drawList)
 if not M.active or not vp or not drawList then return nil end
 local boxes=clipBoxes;for i=#boxes,1,-1 do boxes[i]=nil end
 for _,e in ipairs(drawList)do
  local box=e.stats and e.stats.waterReflectionBounds
  -- Older cached records have no receiver metadata. Render them in full.
  if box==nil then return nil end
  if box then boxes[#boxes+1]=box end
 end
 local w,h=M.color:getDimensions()
 local same=M.clipMatrix and M.clipWidth==w and M.clipHeight==h and #M.clipBoxes==#boxes
 if same then for i,box in ipairs(boxes)do if M.clipBoxes[i]~=box then same=false;break end end end
 if same then for i=1,16 do if M.clipMatrix[i]~=vp[i]then same=false;break end end end
 if not same then
  M.clipRect={Bounds.rect(boxes,vp,w,h)};M.clipMatrix={unpack(vp)};M.clipWidth,M.clipHeight=w,h;M.clipBoxes=M.clipBoxes or{}
  for i=#M.clipBoxes,1,-1 do M.clipBoxes[i]=nil end;for i,box in ipairs(boxes)do M.clipBoxes[i]=box end
 end
 local r=M.clipRect
 if r[1]==0 and r[2]==0 and r[3]==w and r[4]==h then return nil end
 return r
end
function M.bind(shader,pass)
 texel[1],texel[2]=M.color and 1/M.color:getWidth()or 1,M.color and 1/M.color:getHeight()or 1
 Uniform.send(shader,'waterSceneTexel',texel)
 Uniform.send(shader,'waterMirrorPass',pass and 1 or 0)
 Uniform.send(shader,'waterSceneEnabled',M.active and not pass and 1 or 0)
 -- Never bind a render target as its own input, even with sampling disabled.
 Uniform.send(shader,'waterScene',not pass and M.active and M.color or M.blank)
 Uniform.send(shader,'waterBanks',M.banks or M.blank)
 Uniform.send(shader,'waterBankArea',M.area or emptyArea)
end
return M
