-- Presentation only: native orientation/animation, native RGBA, native pivot.
-- In particular, do not call active(), step(), rotate() or setOrientation().
local V=...
local R={count=0,cache={}}
local function config(def)
 local c=V.require('DioramaConfig').emeraldInteriors
 return def and(def.id or def.name)=='EM_ROUTE110_TRICK_HOUSE_PUZZLE6'and c.trickGates or c.fortreeGates
end
function R.snapshot(def,native)
 local cfg=config(def)
 if not cfg.enabled or not def then return{}end
 local trick=(def.id or def.name)=='EM_ROUTE110_TRICK_HOUSE_PUZZLE6'
 if not(trick and V.require('EmeraldTrickSteps').profile(def)or V.require('EmeraldFortreeGym').profile(def))then return{}end
 if not native then local ok,m=pcall(require,'src.core.game3.rotating_gate');if ok then native=m end end
 local p=native and native._p
 if not p or p.map~=def.id then return{}end
 local manifest=native.manifest();local sheets={}
 for _,s in ipairs(manifest and manifest.sheets or{})do sheets[s.shape]=s end
 local out={}
 for i,g in ipairs(p.gates or{})do
  if sheets[g.shape]then out[#out+1]={index=i-1,x=g.x*16,z=g.y*16,
   angle=native.angle(i-1)*math.pi/128,sheet=sheets[g.shape]}end
 end
 return out
end
-- Extrude just the opaque silhouette. Transparent pixels never acquire a
-- side face; their RGB is irrelevant. Edge faces sample one native edge texel.
function R.geometry(data,height,thickness,sideShade)
 local G=V.require('WorldGeometry');local w,h=data:getDimensions();local out={}
 local bottom=math.max(.1,height-thickness)
 G.quad(out,{-w/2,height,-h/2},{w/2,height,-h/2},{w/2,height,h/2},{-w/2,height,h/2},{0,0,1,1},1)
 local function solid(x,y)
  if x<0 or y<0 or x>=w or y>=h then return false end
  local _,_,_,a=data:getPixel(x,y);return a>=.5
 end
 for y=0,h-1 do for x=0,w-1 do if solid(x,y)then
  local u,v=(x+.5)/w,(y+.5)/h;local uv={u,v,u,v};local xx,zz=x-w/2,y-h/2
  for _,e in ipairs({{0,-1,xx,zz,xx+1,zz},{1,0,xx+1,zz,xx+1,zz+1},
   {0,1,xx+1,zz+1,xx,zz+1},{-1,0,xx,zz+1,xx,zz}})do
   if not solid(x+e[1],y+e[2])then
    G.quad(out,{e[3],height,e[4]},{e[5],height,e[6]},
     {e[5],bottom,e[6]},{e[3],bottom,e[4]},uv,sideShade or config().sideShade)
   end
  end
 end end end
 return out
end
function R.transform(vertices,x,z,angle)
 local out={};local c,s=math.cos(angle),math.sin(angle)
 for i,v in ipairs(vertices)do
  out[i]={x+v[1]*c-v[3]*s,v[2],z+v[1]*s+v[3]*c,v[4],v[5],v[6],0,0,0}
 end
 return out
end
-- Keep assets shared between lighting and drawing so the first visible frame
-- already has the same opaque mask, height and orientation in both passes.
function R.asset(sheet,cfg)
 if R.height~=cfg.height or R.thickness~=cfg.thickness or R.sideShade~=cfg.sideShade then
  R.release();R.height=cfg.height;R.thickness=cfg.thickness;R.sideShade=cfg.sideShade
 end
 local cached=R.cache[sheet.file]
 if cached==nil then
  local rgba=require('src.core.game3.dataset').cache():read('data/generated/gba/rotating_gates/'..sheet.file)
  if rgba and #rgba==sheet.w*sheet.h*4 then
   local data=love.image.newImageData(sheet.w,sheet.h,'rgba8',rgba)
   local vertices=R.geometry(data,cfg.height,cfg.thickness,cfg.sideShade)
   local image=love.graphics.newImage(data,{mipmaps=false});image:setFilter('nearest','nearest');image:setWrap('clamp','clamp')
   local mesh=love.graphics.newMesh(V.require('WorldGeometry').FORMAT,#vertices,'triangles','stream');mesh:setTexture(image)
   cached={image=image,mesh=mesh,vertices=vertices,shadows=R.shadowGeometry(data,cfg.height,cfg.thickness)};data:release()
  else cached=false end
  R.cache[sheet.file]=cached
 end
 return cached
end
function R.shadowGeometry(data,height,thickness)
 local w,h=data:getDimensions();local out={}
 local _,contour=V.require('RoomShadowContours').writer(out,-w/2,-h/2,1)
 contour(w,h,math.max(.1,height-thickness),height,function(x,y)local _,_,_,a=data:getPixel(x,y);return a>=.5 end)
 return out
end
function R.shadowTransform(box,g)
 local c,s=math.cos(g.angle),math.sin(g.angle)
 local lo,hi={math.huge,box.lo[2],math.huge},{-math.huge,box.hi[2],-math.huge}
 for _,x in ipairs({box.lo[1],box.hi[1]})do for _,z in ipairs({box.lo[3],box.hi[3]})do
  local xx,zz=g.x+x*c-z*s,g.z+x*s+z*c
  lo[1]=math.min(lo[1],xx);lo[3]=math.min(lo[3],zz);hi[1]=math.max(hi[1],xx);hi[3]=math.max(hi[3],zz)
 end end
 return{lo=box.lo,hi=box.hi,frame={g.x,g.z,c-1,s},worldLow=lo,worldHigh=hi,wall=false,gate=g.index}
end
function R.shadowBoxes(def)
 local out={};local cfg=config(def)
 for _,g in ipairs(R.snapshot(def))do local asset=R.asset(g.sheet,cfg)
  if asset then for _,box in ipairs(asset.shadows)do out[#out+1]=R.shadowTransform(box,g)end end
 end
 return out
end
function R.draw(def)
 R.count=0;local states=R.snapshot(def);local cfg=config(def)
 for _,g in ipairs(states)do local cached=R.asset(g.sheet,cfg)
  if cached then cached.mesh:setVertices(R.transform(cached.vertices,g.x,g.z,g.angle));love.graphics.draw(cached.mesh);R.count=R.count+1 end
 end
end
function R.release()
 for _,c in pairs(R.cache)do if c then c.mesh:release();c.image:release()end end
 R.cache={};R.count=0
end
return R
