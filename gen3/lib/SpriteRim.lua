-- Cached exterior-only sprite normals; never infer a rim from interior holes.
local V=...
local R={cache=setmetatable({},{__mode='k'}),features=setmetatable({},{__mode='k'}),
 rowX={1,0,0},rowY={0,1,0},size={1,1},light={0,0,0},params={0,0}}
R.uniforms=[[
#ifdef SPRITE_RIM
uniform Image actorRimMask;
uniform vec3 actorRimX;
uniform vec3 actorRimY;
uniform vec2 actorRimSize;
uniform vec3 actorRimLight; // projected direction xy, strength
uniform float actorRimActive;
#endif
]]
R.functions=[[
#if defined(PIXEL) && defined(SPRITE_RIM)
float spriteRimAt(vec2 uv){
 vec2 p=vec2(dot(actorRimX,vec3(uv,1.0)),dot(actorRimY,vec3(uv,1.0)));
 // Differentiate before the bounds branch, including folded/flipped cards.
 vec2 dx=dFdx(p)*actorRimSize,dy=dFdy(p)*actorRimSize;
 if(p.x<0.0 || p.y<0.0 || p.x>=1.0 || p.y>=1.0)return 0.0;
 vec4 mask=Texel(actorRimMask,p);
 vec2 normal=mask.rg*2.0-1.0;
 vec2 projected=vec2(dot(normal,dx),dot(normal,dy));
 return mask.a*max(0.0,dot(projected/max(length(projected),.00001),actorRimLight.xy));
}
#endif
]]
R.fragment=[[
#ifdef SPRITE_RIM
 if(actorRimActive>.5 && actorFace>.5 && cutTreeFoliage<.5 && caveMode<.5){
  float night=moonFill.a;
  vec3 rimColor=mix(sunColor,moonFill.rgb,night);
  float energy=mix(sunStrength*daylightDirect,night*.28,night);
  lit+=rimColor*spriteRimAt(uv)*actorRimLight.z*energy*
    (1.0-shadow*min(1.0,shadowStrength*1.35))*cloudDirectTransmission;
 }
#endif
]]
-- Four-connected transparent pixels reached from the frame boundary are the
-- exterior. Atlas frames are flooded separately, so neighbouring poses cannot
-- contaminate the contour. Width is in native source pixels, not canvas pixels.
function R.normals(data,frames,width)
 local w,h=data:getDimensions();local out=love.image.newImageData(w,h)
 width=math.max(1,math.min(2,math.floor((width or 1)+.5)))
 local function frame(ox,oy,fw,fh)
  -- Two exterior sentinel pixels cover both supported rim widths. Flat
  -- neighbor indices preserve four-connected flooding without per-neighbor
  -- coordinate checks, division, modulo or helper calls in the hot loops.
  local stride=fw+4
  local solid,outer,queue={},{},{}
  for i=1,stride*2 do outer[i]=true;outer[(fh+2)*stride+i]=true end
  for y=0,fh-1 do
   local row=(y+2)*stride
   outer[row+1],outer[row+2],outer[row+fw+3],outer[row+fw+4]=true,true,true,true
   for x=0,fw-1 do local _,_,_,a=data:getPixel(ox+x,oy+y);solid[row+x+3]=a>.5 end
  end
  local function seed(i)
   if not solid[i]and not outer[i]then outer[i]=true;queue[#queue+1]=i end
  end
  for x=0,fw-1 do seed(2*stride+x+3);seed((fh+1)*stride+x+3)end
  for y=0,fh-1 do seed((y+2)*stride+3);seed((y+2)*stride+fw+2)end
  local head=1
  while head<=#queue do
   local i=queue[head];head=head+1
   local n=i-1;if not solid[n]and not outer[n]then outer[n]=true;queue[#queue+1]=n end
   n=i+1;if not solid[n]and not outer[n]then outer[n]=true;queue[#queue+1]=n end
   n=i-stride;if not solid[n]and not outer[n]then outer[n]=true;queue[#queue+1]=n end
   n=i+stride;if not solid[n]and not outer[n]then outer[n]=true;queue[#queue+1]=n end
  end
  for y=0,fh-1 do for x=0,fw-1 do
   local i=(y+2)*stride+x+3
   if solid[i]then
    local nx=(outer[i+1]and 1 or 0)-(outer[i-1]and 1 or 0)
    local ny=(outer[i+stride]and 1 or 0)-(outer[i-stride]and 1 or 0)
    if width==2 then
     nx=nx+((outer[i+2]and 1 or 0)-(outer[i-2]and 1 or 0))*.5
     ny=ny+((outer[i+2*stride]and 1 or 0)-(outer[i-2*stride]and 1 or 0))*.5
    end
    if nx~=0 or ny~=0 then
     local length=math.sqrt(nx*nx+ny*ny)
     out:setPixel(ox+x,oy+y,nx/length*.5+.5,ny/length*.5+.5,0,1)
    end
   end
  end end
 end
 if frames then for _,q in pairs(frames)do frame(q:getViewport())end else frame(0,0,w,h)end
 return out
end
function R.mask(image,data,frames)
 if not image then return end
 local width=math.max(1,math.min(2,math.floor((V.require('DioramaConfig').billboards.rim.width or 1)+.5)))
 local prior=R.cache[image]
 if prior and prior.width==width and (not data or prior.data==data)then return prior.image end
 local owned
 if not data then
  -- Compatibility with the fixed RC1 engine: at most one small source readback
  -- per newly encountered portrait/frame; never read the animated scene canvas.
  local w,h=image:getDimensions();local canvas=love.graphics.newCanvas(w,h,{dpiscale=1})
  love.graphics.push('all')
  local ok,err=pcall(function()
   love.graphics.setCanvas(canvas);love.graphics.origin();love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setScissor()
   love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('replace','premultiplied');love.graphics.clear(0,0,0,0);love.graphics.draw(image)
   love.graphics.setCanvas();data=canvas:newImageData();owned=true
  end)
  love.graphics.pop();canvas:release();if not ok then error(err,0)end
 end
 local normals=R.normals(data,frames,width);local mask=love.graphics.newImage(normals);normals:release()
 mask:setFilter('nearest','nearest');mask:setWrap('clamp','clamp')
 if prior then prior.image:release()end
 R.cache[image]={image=mask,width=width,data=not owned and data or nil}
 if owned then data:release()end
 return mask
end
function R.supports(shader)
 if not shader then return false end
 local v=R.features[shader];if v==nil then v=shader:hasUniform('actorRimActive');R.features[shader]=v end
 return v
end
-- Before publishing a newly entered map, prepare its actor contours in the
-- existing cooperative queue. Cached masks remain valid across cancelled
-- map entries; late-spawned actors retain the normal synchronous fallback.
function R.prepareActors(actors,sprites,mapId,frame,outdoors)
 if outdoors==false then return true end
 local c=V.require('DioramaConfig').billboards.rim
 if not c.enabled then return true end
 local width=math.max(1,math.min(2,math.floor((c.width or 1)+.5)))
 local pending=false
 for _,actor in ipairs(actors)do
  local sprite=sprites.get(actor.gid)
  if sprite then
   local row=R.cache[sprite.image]
   if not row or row.width~=width or (sprite.imageData and row.data~=sprite.imageData)then pending=true;break end
  end
 end
 if not pending then return true end
 return V.require('NativeBuildQueue').get('actor contours:'..mapId..':'..width,frame,function()
  local budget=V.require('BuildBudget')
  for _,actor in ipairs(actors)do
   budget.phase('actor contours');budget.check()
   local sprite=sprites.get(actor.gid)
   if sprite then R.mask(sprite.image,sprite.imageData,sprite.quads)end
  end
  return true
 end)==true
end
function R.prepare(atmosphere,outdoors,vp,point,viewportWidth,viewportHeight)
 local c=V.require('DioramaConfig').billboards.rim
 local direction=atmosphere.direction
 local x,y,z=point[1],point[2],point[3];local project=V.require('Camera').project
 local ax,ay=project(vp,x,y,z);local bx,by=project(vp,x+direction[1],y+direction[2],z+direction[3])
 local dx,dy=((bx or 0)-(ax or 0))*(viewportWidth or 1),((by or 0)-(ay or 0))*(viewportHeight or 1);local len=math.sqrt(dx*dx+dy*dy)
 R.light[1],R.light[2]=dx/math.max(len,.00001),dy/math.max(len,.00001)
 R.light[3]=c.enabled and outdoors and ax and bx and len>.00001 and c.strength or 0
 R.enabled=R.light[3]>0
end
function R.begin(shader)
 if not R.supports(shader)then return end
 local U=V.require('UniformState');U.send(shader,'actorRimLight',R.light);U.send(shader,'actorRimActive',0)
end
function R.bind(shader,image,data,frames,transform)
 if not R.supports(shader)then return end
 local U=V.require('UniformState')
 if not R.enabled or not image then U.send(shader,'actorRimActive',0);return end
 local mask=R.mask(image,data,frames);local w,h=image:getDimensions()
 if transform then
  local t=transform;local c,s=math.cos(t.rot or 0),math.sin(t.rot or 0)
  local sx,sy=t.sx or 1,t.sy or 1
  if math.abs(sx)<.0001 or math.abs(sy)<.0001 then U.send(shader,'actorRimActive',0);return end
  R.rowX[1],R.rowX[2],R.rowX[3]=c*240/sx/w,s*160/sx/w,((t.ox or 32)-(c*t.x+s*t.y)/sx)/w
  R.rowY[1],R.rowY[2],R.rowY[3]=-s*240/sy/h,c*160/sy/h,((t.oy or 32)+(s*t.x-c*t.y)/sy)/h
 else R.rowX[1],R.rowX[2],R.rowX[3]=1,0,0;R.rowY[1],R.rowY[2],R.rowY[3]=0,1,0 end
 R.size[1],R.size[2]=w,h
 U.send(shader,'actorRimMask',mask);U.send(shader,'actorRimSize',R.size)
 U.send(shader,'actorRimX',R.rowX);U.send(shader,'actorRimY',R.rowY);U.send(shader,'actorRimActive',1)
end
function R.compile(source)
 source=V.require('SurfaceDerivatives').prepare(source)
 -- Normalize derivatives at compilation, before discard or material branches.
 -- Evaluating dFdx/dFdy inside spriteRimAt after alpha discard reads undefined
 -- helper lanes on silhouette edges, even with a completely frozen clock.
 -- Keep exported RC4 shader snippets unchanged (RenderSeams' empty-source
 -- contract); this compiler preparation also applies when no Card is present.
 source=source:gsub('float spriteRimAt%(vec2 uv%){','float spriteRimAt(vec2 uv,vec2 uvDx,vec2 uvDy){')
 source=source:gsub('vec2 dx=dFdx%(p%)%*actorRimSize,dy=dFdy%(p%)%*actorRimSize;',
  'vec2 dx=vec2(dot(actorRimX.xy,uvDx),dot(actorRimY.xy,uvDx))*actorRimSize,dy=vec2(dot(actorRimX.xy,uvDy),dot(actorRimY.xy,uvDy))*actorRimSize;')
 source=source:gsub('spriteRimAt%(uv%)','spriteRimAt(uv,oascRimUvDx,oascRimUvDy)')
 local prefix='\n#ifdef SPRITE_RIM\n vec2 oascRimUvDx=dFdx(uv),oascRimUvDy=dFdy(uv);\n#endif\n'
 source=V.require('SurfaceDerivatives').prefixEntry(source,prefix)
 local ok,shader,vertex=pcall(V.require('ActorLighting').compile,'#define SPRITE_RIM\n'..source)
 if ok then return shader,vertex,true end
 V.mod.log:info('Sprite rim unavailable; retaining established actor shading: '..tostring(shader))
 local legacy,foot=V.require('ActorLighting').compile(source)
 return legacy,foot,false
end
return R
