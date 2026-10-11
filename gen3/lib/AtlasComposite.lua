-- Native animation and scripted palette writes advance renderRevision. Old
-- engines without that contract deliberately retain per-frame composition.
local V=...
local A={hits=0,builds=0,cache=setmetatable({},{__mode='k'})}
function A.get(ts,generation)
 local g=love.graphics
 local row=A.cache[ts]
 local revision=ts.renderRevision
 local uploads=V and V.require('AnimatedAtlasUpload')
 local nativeGeneration=uploads and uploads.nativeRevisions and uploads.nativeGeneration or nil
 if nativeGeneration then revision=ts._oascRenderRevision or 0 end
 local w,h=ts.image:getDimensions();local pw,ph=g.getPixelDimensions()
 local slot=ts.midToSlot[4]
 if row and revision~=nil and row.revision==revision
  and row.nativeGeneration==nativeGeneration
  and row.image==ts.image and row.over==ts.overImage and row.flower==ts._vascGen3FlowerImage
  and row.generation==generation and row.pw==pw and row.ph==ph
  and row.w==w and row.h==h and row.slot==slot and row.cols==ts.cols then
  A.hits=A.hits+1;return row.canvas
 end
 if not row then row={};A.cache[ts]=row end
 if row.canvas and(row.w~=w or row.h~=h)then row.canvas:release();row.canvas=nil end
 row.canvas=row.canvas or g.newCanvas(w,h,{dpiscale=1});row.canvas:setFilter('nearest','nearest')
 g.setCanvas(row.canvas);g.origin();g.setShader();g.setDepthMode()
 g.setBlendMode('alpha','alphamultiply');g.setColor(1,1,1,1);g.clear(0,0,0,0)
 g.draw(ts.image);if ts.overImage then g.draw(ts.overImage)end
 if ts._vascGen3FlowerImage and slot then g.draw(ts._vascGen3FlowerImage,slot%ts.cols*16,math.floor(slot/ts.cols)*16)end
 row.revision=revision;row.image=ts.image;row.over=ts.overImage;row.flower=ts._vascGen3FlowerImage
 row.nativeGeneration=nativeGeneration
 row.generation=generation;row.pw=pw;row.ph=ph;row.w=w;row.h=h;row.slot=slot;row.cols=ts.cols
 row.version=(row.version or 0)+1
 A.builds=A.builds+1;return row.canvas
end
function A.release()
 for _,row in pairs(A.cache)do row.canvas:release()end
 A.cache=setmetatable({},{__mode='k'})
end
return A
