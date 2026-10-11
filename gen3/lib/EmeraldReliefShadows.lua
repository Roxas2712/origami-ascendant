-- Derived only from rendered Secret Base relief; floor colours/holes stay empty.
local V=...;local R={}
function R.pack(field,scale)
 local w,h=field.width,field.heightPixels;local maximum=0;local values,dist,q={},{},{}
 for z=0,h-1 do for x=0,w-1 do local i=z*w+x+1;local a={0,0,0,0}
  if field.rock(x,z)then
   a={field.height(x,z)*scale,field.height(x+1,z)*scale,field.height(x+1,z+1)*scale,field.height(x,z+1)*scale}
   dist[i]=0;q[#q+1]=i
  end
  for _,v in ipairs(a)do maximum=math.max(maximum,v)end;values[i]=a
 end end
 local at=1
 while q[at]do local i=q[at];at=at+1;local x,z=(i-1)%w,math.floor((i-1)/w)
  for dz=-1,1 do for dx=-1,1 do local xx,zz=x+dx,z+dz
   if xx>=0 and xx<w and zz>=0 and zz<h then local j=zz*w+xx+1
    if dist[j]==nil then dist[j]=dist[i]+1;q[#q+1]=j end
   end
  end end
 end
 maximum=math.max(1,maximum)
 local heights=love.image.newImageData(w,h);local distances=love.image.newImageData(w,h)
 for z=0,h-1 do for x=0,w-1 do local i=z*w+x+1;local a=values[i]
  heights:setPixel(x,z,a[1]/maximum,a[2]/maximum,a[3]/maximum,a[4]/maximum)
  distances:setPixel(x,z,math.min(255,dist[i]or 255)/255,0,0,1)
 end end
 return heights,distances,maximum
end
function R.prepare(d)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.secretBases.reliefShadows
 if not(c.enabled and V.require('EmeraldSecretBases').profile(d))then return end
 local field=V.require('EmeraldSecretBases').cache[d.midLayout];if not field then return end
 local old=R.cached;local base=cfg.secretBases
 if not old or old.field.ts~=field.ts or old.field.geometryKey~=field.geometryKey or old.field.width~=field.width or old.field.heightPixels~=field.heightPixels or old.scale~=cfg.heightScale or old.wallHeight~=base.wallHeight or old.wallSlope~=base.wallSlope then
  R.release();local a,b,maximum=R.pack(field,cfg.heightScale)
  local heights=love.graphics.newImage(a);local distances=love.graphics.newImage(b);a:release();b:release()
  heights:setFilter('nearest','nearest');distances:setFilter('nearest','nearest')
  heights:setWrap('clamp','clamp');distances:setWrap('clamp','clamp')
  R.cached={field=field,scale=cfg.heightScale,wallHeight=base.wallHeight,wallSlope=base.wallSlope,heights=heights,distances=distances,maximum=maximum}
 end
 return R.cached
end
function R.send(shader,state)
 if not V.require('UniformState').has(shader,'roomReliefControl')then return end
 local c=V.require('DioramaConfig').emeraldInteriors.secretBases.reliefShadows
 shader:send('roomReliefControl',{state and 1 or 0,c.bias,math.min(96,c.steps),0})
 if state then
  if shader:hasUniform('roomReliefHeights')then shader:send('roomReliefHeights',state.heights);shader:send('roomReliefDistances',state.distances)end
  shader:send('roomReliefMeta',{state.field.width,state.field.heightPixels,state.maximum,0})
 end
end
function R.release()
 V.require('EmeraldReliefAtlas').release()
 if R.cached then R.cached.heights:release();R.cached.distances:release();R.cached=nil end
end
return R
