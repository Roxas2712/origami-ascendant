-- LUTs are authored/generated mod assets, loaded once. Initial named grades
-- intentionally equal neutral; their continuous blend supports later grading.
local V=...
local G={images={},identity={}}
local U=V.require('UniformState')
local names={'neutral','dawn','day','golden','dusk','night'}
function G.release()
 for _,image in pairs(G.images)do image:release()end
 G.images={};G.identity={};G.loaded=nil;G.reason=nil
end
function G.prepare()
 if G.loaded~=nil then return G.loaded end;G.loaded=false
 local neutralIdentity=false
 local ok,err=pcall(function()
  local neutral=assert(V.mod:read('gen3/data/luts/neutral.png'),'missing neutral LUT')
  for _,name in ipairs(names)do
   local raw=assert(V.mod:read('gen3/data/luts/'..name..'.png'),'missing '..name..' LUT')
   local file=love.filesystem.newFileData(raw,name..'.png')
   local data=love.image.newImageData(file);file:release()
   local w,h=data:getDimensions()
   if w~=1024 or h~=32 then data:release();error('LUT must be 1024x32: '..name)end
   if name=='neutral'then
    neutralIdentity=true
    for y=0,31 do for z=0,31 do for x=0,31 do
     local r,g,b=data:getPixel(z*32+x,y)
     if math.abs(r-x/31)>1/65535 or math.abs(g-y/31)>1/65535 or math.abs(b-z/31)>1/65535 then neutralIdentity=false end
    end end end
   end
   local image=love.graphics.newImage(data,{mipmaps=false,linear=true});data:release()
   image:setFilter('linear','linear');image:setWrap('clamp','clamp')
   G.images[name]=image;G.identity[name]=neutralIdentity and raw==neutral
  end
 end)
 if not ok then
  G.release();G.loaded=false;G.reason=tostring(err)
  if V.mod and V.mod.log then V.mod.log:info('LUT grading disabled: '..G.reason)end
  return false
 end
 G.loaded=true;return true
end
function G.send(shader,cfg,rig,fallback,override)
 if override and override.a and override.b then
  local amount=override.identity and 0 or math.max(0,math.min(1,override.amount or 0))
  U.send(shader,'lutA',override.a);U.send(shader,'lutB',override.b)
  U.send(shader,'lutMix',math.max(0,math.min(1,override.mix or 0)));U.send(shader,'lutAmount',amount)
  return override.preserveLegacy and 0 or amount
 end
 local amount=math.min(1,math.max(0,cfg.lutAmount or 0))
 local a,b='neutral','neutral';local mix=0
 if rig then a,b,mix=rig.lutA or a,rig.lutB or b,rig.lutMix or 0 end
 if amount>0 and G.prepare()then
  if not G.images[a]then a='neutral'end;if not G.images[b]then b='neutral'end
  U.send(shader,'lutA',G.images[a]);U.send(shader,'lutB',G.images[b])
  -- Identity should be exact, including colours outside 0..1 before ACES.
  if G.identity[a]and G.identity[b]then amount=0 end
 else amount=0;U.send(shader,'lutA',fallback);U.send(shader,'lutB',fallback)end
 U.send(shader,'lutMix',mix);U.send(shader,'lutAmount',amount)
 return amount
end
return G
