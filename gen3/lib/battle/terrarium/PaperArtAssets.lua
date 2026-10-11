-- Release artwork keeps the exact source dimensions and alpha bytes. Color
-- files are optimized independently; source checkouts still read the originals.
local V=...
local A={}
local manifest,loaded
local folder='gen3/data/emerald-terrarium/'
local hasFfi,ffi=pcall(require,'ffi')
local function decode(name)
 local bytes=assert(V.mod:read(folder..name),'missing terrarium art: '..name)
 local file=love.filesystem.newFileData(bytes,name)
 local ok,result=pcall(love.image.newImageData,file);file:release();assert(ok,result)
 return result
end
function A.load(name)
 if not loaded then
  loaded=true;local raw=V.mod:read(folder..'runtime-assets.json')
  if raw then manifest=require('src.link.Json').decode(raw);assert(manifest.version==1,'unsupported paper asset manifest')end
 end
 local row=manifest and manifest.files[name]
 if not row then return decode(name)end
 local image,alpha
 local ok,err=pcall(function()
  image=decode(row.color)
  assert(image:getWidth()==row.width and image:getHeight()==row.height,'paper color dimensions')
  if row.alpha then
   alpha=decode(row.alpha)
   assert(alpha:getWidth()==row.width and alpha:getHeight()==row.height,'paper alpha dimensions')
   local format=alpha:getFormat()
   if hasFfi and image.getFFIPointer and image:getFormat()=='rgba8'and(format=='rgba8'or format=='r8')then
    local pixels=ffi.cast('uint8_t*',image:getFFIPointer());local mask=ffi.cast('const uint8_t*',alpha:getFFIPointer())
    local stride=format=='rgba8'and 4 or 1
    for i=0,row.width*row.height-1 do pixels[i*4+3]=mask[i*stride]end
   else image:mapPixel(function(x,y,red,green,blue)local a=alpha:getPixel(x,y);return red,green,blue,a end)end
  end
 end)
 if alpha then alpha:release()end
 if not ok then if image then image:release()end;error(err,0)end
 return image
end
return A
