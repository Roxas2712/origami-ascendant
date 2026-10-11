-- Whole-map facade lights indexed in world space, independent of player distance.
-- Each fragment reads only overlapping sources; moving the camera never changes a lamp.
local V=...;local M={CELL=32,SLOTS=24,cache={},serial=0}
local function release(s)for _,k in ipairs{'index','data','spareData','indexData','lightData'}do if s[k]then s[k]:release()end end end
function M.release()for _,s in pairs(M.cache)do release(s)end;M.cache={};M.serial=0;if M.blank then M.blank:release();M.blank=nil end end
function M.prepare(entries,amount,spatial)
 local cfg=V.require('DioramaConfig').lighting
 local keys,lights={},{}
 for _,e in ipairs(entries)do
  if e.stats and e.stats.lights and #e.stats.lights>0 then
   keys[#keys+1]=tostring(e.stats)
   for _,l in ipairs(e.stats.lights)do lights[#lights+1]=l end
  end
 end
 table.sort(keys)
 local environmentalStart=#lights
 for _,l in ipairs(spatial or{})do
  keys[#keys+1]=table.concat({l.kind or 'spatial',l.x,l.y,l.z,l.radius},',')
  lights[#lights+1]=l
 end
 local key=table.concat(keys,':')..':'..(cfg.windowRadiusScale or 1);local s=M.cache[key]
 M.serial=M.serial+1;local serial=M.serial
 if s then s.used=serial end
 if not s then
  if not next(lights)then return nil end
  local x0,z0,x1,z1=math.huge,math.huge,-math.huge,-math.huge
  local radii,reaches,support2,backZ={},{},{},{}
  for id,l in ipairs(lights)do local r=math.abs(l.radius)*(l.radius>0 and(cfg.windowRadiusScale or 1)or 1)
   x0=math.min(x0,l.x-r);x1=math.max(x1,l.x+r);z0=math.min(z0,l.z-r);z1=math.max(z1,l.z+r)
   radii[id]=r;reaches[id]=r+M.CELL*.71
   local support=r+1;support2[id]=support*support
   backZ[id]=l.radius<0 and -math.huge or l.z-6
  end
  x0=math.floor(x0/M.CELL)*M.CELL;z0=math.floor(z0/M.CELL)*M.CELL
  local w,h=math.ceil((x1-x0)/M.CELL),math.ceil((z1-z0)/M.CELL)
  local cells={}
  for id,l in ipairs(lights)do
   local r,reach=radii[id],reaches[id]
   for z=math.max(0,math.floor((l.z-r-z0)/M.CELL)),math.min(h-1,math.floor((l.z+r-z0)/M.CELL))do
    for x=math.max(0,math.floor((l.x-r-x0)/M.CELL)),math.min(w-1,math.floor((l.x+r-x0)/M.CELL))do
     local dx,dz=x0+(x+.5)*M.CELL-l.x,z0+(z+.5)*M.CELL-l.z
     if dx*dx+dz*dz<reach*reach then
      local k=z*w+x;local cell=cells[k]
      if not cell then cell={ids={},scores={}};cells[k]=cell end
      cell.ids[#cell.ids+1]=id
      cell.scores[id]=(l.power or 1)*math.max(0,1-math.sqrt(dx*dx+dz*dz)/reach)^2
     end
    end
   end
  end
  -- Preserve the original 32-pixel cell's selected24 sources and order.
  -- Subdivide only to omit sources provably zero throughout a smaller cell.
  local scale=2;local fine=M.CELL/scale
  local index=love.image.newImageData(w*scale*6,h*scale,'rgba32f');local overflow=0
  for k,cell in pairs(cells)do
   local list,scores=cell.ids,cell.scores
   table.sort(list,function(a,b)return scores[a]>scores[b]end)
   if #list>M.SLOTS then overflow=overflow+1 end
   local parentX,parentZ=k%w,math.floor(k/w)
   for sz=0,scale-1 do for sx=0,scale-1 do
    local cx,cz=parentX*scale+sx,parentZ*scale+sz
    local loX,loZ=x0+cx*fine,z0+cz*fine
    local pack,count,a,b,c,d=0,0,0,0,0,0
    for slot=1,math.min(M.SLOTS,#list)do
     local id=list[slot];local l=lights[id]
     local dx=math.max(loX-l.x,0,l.x-(loX+fine))
     local dz=math.max(loZ-l.z,0,l.z-(loZ+fine))
     -- Positive-radius sources have zero outward term behind their facade;
     -- retain an extra pixel beyond the five-pixel facade bounce support.
     if dx*dx+dz*dz<=support2[id]and loZ+fine>=backZ[id]then
      if count==0 then a=id elseif count==1 then b=id elseif count==2 then c=id else d=id end
      count=count+1
      if count==4 then
       index:setPixel(cx*6+pack,cz,a,b,c,d)
       pack=pack+1;count=0;a,b,c,d=0,0,0,0
      end
     end
    end
    -- New ImageData is zero-filled. Leave unused source packs untouched;
    -- sparse city cells usually need only one of their six RGBA texels.
    if count>0 then index:setPixel(cx*6+pack,cz,a,b,c,d)end
   end end
  end
  local sourceRefs={}
  for _,e in ipairs(entries)do if e.stats and e.stats.lights and #e.stats.lights>0 then sourceRefs[#sourceRefs+1]=e.stats end end
  -- Keep the tables whose identities form the key alive until eviction;
  -- their addresses must not be recycled for a different facade catalogue.
  s={lights=lights,sourceRefs=sourceRefs,indexData=index,index=love.graphics.newImage(index),lightData=love.image.newImageData(3,#lights,'rgba32f'),area={x0,z0,w*scale,h*scale},overflow=overflow,used=serial}
  s.index:setFilter('nearest','nearest');M.cache[key]=s
  local n=0;for _ in pairs(M.cache)do n=n+1 end
  if n>4 then
   -- A camera oscillating across a neighbour boundary repeatedly alternates
   -- two grids. Evict the oldest use, never an arbitrary hash-table entry
   -- that may be one of those two hot grids.
   local oldest,age=nil,math.huge
   for k,v in pairs(M.cache)do if k~=key and v.used<age then oldest,age=k,v.used end end
   if oldest then release(M.cache[oldest]);M.cache[oldest]=nil end
  end
 end
 -- These sites stay fixed, but their time-driven colour/power may change.
 for i,l in ipairs(spatial or{})do s.lights[environmentalStart+i]=l end
 local bucket=math.floor((V.clock or love.timer.getTime)()*4)
 if s.bucket~=bucket or math.abs((s.amount or -1)-amount)>.002 then
  s.bucket=bucket;s.amount=amount
  for i,l in ipairs(s.lights)do
   local c=l.color or cfg.windowColor;local lamp=l.spatial and {1,1,1,1}or V.require('WindowVariation').sample(l.variationCode)
   local r=l.radius*(l.radius>0 and(cfg.windowRadiusScale or 1)or 1)
   s.lightData:setPixel(0,i-1,l.x,l.y,l.z,r)
   s.lightData:setPixel(1,i-1,c[1]*lamp[1],c[2]*lamp[2],c[3]*lamp[3],l.power*lamp[4]*(l.spatial and 1 or amount*cfg.windowStrength))
   s.lightData:setPixel(2,i-1,l.facadeBounce or 0,l.falloff or 2,l.wallOnly and 1 or 0,l.point and 1 or 0)
  end
  -- The current texture may still be read by queued world/actor draws. Upload
  -- into the previous update's texture instead of waiting for those draws.
  local uploadData=M.dataFilter and M.dataFilter(s.lightData,s.lights,s)or s.lightData
  local upload=s.spareData
  if upload then upload:replacePixels(uploadData)else upload=love.graphics.newImage(uploadData);upload:setFilter('nearest','nearest')end
  s.spareData,s.data=s.data,upload
 end
 return s
end
function M.send(shader,s)
 if not M.blank then local d=love.image.newImageData(1,1);M.blank=love.graphics.newImage(d);d:release()end
 shader:send('staticLightGrid',s and s.index or M.blank);shader:send('staticLightData',s and s.data or M.blank)
 shader:send('staticLightArea',s and s.area or {0,0,1,1});shader:send('staticLightRows',s and #s.lights or 0)
end
M.uniforms=[[
uniform Image staticLightGrid;
uniform Image staticLightData;
uniform vec4 staticLightArea;
uniform float staticLightRows;
float staticLightId(int slot,vec2 world){
 vec2 cell=floor((world-staticLightArea.xy)/16.0);
 if(staticLightRows<.5 || cell.x<0.0 || cell.y<0.0 || cell.x>=staticLightArea.z || cell.y>=staticLightArea.w)return 0.0;
 float pack=floor(float(slot)/4.0);
 vec4 ids=Texel(staticLightGrid,vec2((cell.x*6.0+pack+.5)/(staticLightArea.z*6.0),(cell.y+.5)/staticLightArea.w));
 int channel=slot-(slot/4)*4;
 if(channel==0)return ids.r;if(channel==1)return ids.g;if(channel==2)return ids.b;return ids.a;
}
]]
return M
