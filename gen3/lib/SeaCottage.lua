-- Native Bill laboratory surfaces. Source UVs remain in the live atlas so
-- door/light animation never changes the geometry or collision ownership.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local podEdges={16,14,12,11,10,9,8,8,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,7,8,8,7,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,8,9,10,11,12}
local function cfg()return V.require('DioramaConfig').interiors.seaCottage end
function R.profile(d)
 local L=d and d.midLayout
 if cfg().enabled and d and d.id=='FR_ROUTE_25_SEA_COTTAGE'and (d.renderPair or d.pair)=='building__rom_082d4eb4'and d.mapType==8 and L and L.width==16 and L.height==12 and L:midAt(0,0)==0x299 and L:midAt(14,9)==0x2a3 then return cfg()end
end
function R.plan(d,objects,mask)
 local L=d.midLayout;if L then R.rooms[L]=nil end;if not R.profile(d)then return end
 local own={};R.rooms[L]=own
 local function add(k,x,y,w,h,p)
  p=p or{};p.kind=k;p.x=x;p.y=y;p.w=w;p.h=h;objects[#objects+1]=p;own[#own+1]=p
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*16+xx+1]={mid=8,void=true,separateSurface=true}end end
 end
 add('cottageWall',0,0,15,2);add('cottageFloor',0,2,15,8);add('cottageExit',6,10,3,1)
 for _,x in ipairs{2,9}do add('cottagePod',x,1,3,3,{cap=0,last=48,split=26,height=cfg().podHeight})end
 add('cottagePipe',4,1,6,2,{cap=0,last=32})
 for _,x in ipairs{1,12}do add('cottageControl',x,0,1,3,{cap=13,last=39,height=cfg().controlHeight})end
 add('cottageDesk',4,4,2,3,{cap=14,last=41,height=cfg().deskHeight})
 for _,pos in ipairs{{0,2},{1,3},{5,3},{6,3},{14,4}}do add('cottageCrate',pos[1],pos[2],1,1,{cap=0,last=16,height=cfg().crateHeight})end
 for _,pos in ipairs{{0,3},{7,3},{13,3},{14,5},{0,7}}do add('cottageDevice',pos[1],pos[2],1,1,{cap=1,last=15,height=cfg().deviceHeight})end
 for _,pos in ipairs{{14,2},{14,3},{8,3},{14,6},{14,7},{0,8},{0,9}}do add('cottageCabinet',pos[1],pos[2],1,1,{cap=0,last=16,height=cfg().cabinetHeight})end
 for _,x in ipairs{1,2,13,14}do add('cottagePlant',x,8,1,2,{cap=4,last=32,height=cfg().plantHeight})end
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local own=R.rooms[L];local c=cfg();if not c.enabled or not own then return end
 local P,G,B=V.require('PaperSprite'),V.require('WorldGeometry'),V.require('BuildingMesh');local hs=V.require('Billboard').heightScale()
 local function source(x,y)return L:midAt(math.floor(x/16),math.floor(y/16)),x%16,y%16 end
 local bg={};for y=0,15 do for x=0,15 do bg[rgb(B.pixel(ts,0x288,x,y))]=true end end
 local wallbg=rgb(B.pixel(ts,source(33,20)))
 local pipebg={};for y=0,8 do pipebg[rgb(B.pixel(ts,0x285,8,y))]=true end
 for y=5,15 do pipebg[rgb(B.pixel(ts,0x2b4,8,y))]=true end
 local masks={}
 for _,o in ipairs(own)do if o.cap then
  local W,H=o.w*16,o.h*16;local clear,empty,q={},{},{}
  for t=0,H-1 do for s=0,W-1 do local r,g,b,a=B.pixel(ts,source(o.x*16+s,o.y*16+t));local col=rgb(r,g,b)
   clear[t*W+s]=t<o.cap or t>=o.last or a<.5 or bg[col]or(o.kind=='cottagePod'and t<16 and col==wallbg)or(o.kind=='cottagePipe'and pipebg[col])
  end end
  local function seed(s,t)local k=t*W+s;if clear[k]and not empty[k]then empty[k]=true;q[#q+1]=k end end
  for s=0,W-1 do seed(s,0);seed(s,H-1)end;for t=0,H-1 do seed(0,t);seed(W-1,t)end
  local n=1;while q[n]do local k=q[n];n=n+1;local s,t=k%W,math.floor(k/W);if s>0 then seed(s-1,t)end;if s<W-1 then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t<H-1 then seed(s,t+1)end end
  masks[o]=empty
 end end
 local function inside(o,s,t)
  if s<0 or s>=o.w*16 then return false end
  if o.kind=='cottagePod'then
   local edge=podEdges[t+1]
   return edge and s>=edge and s<48-edge or false
  end
  if t<o.cap or t>=o.last then return false end
  if o.kind=='cottagePipe'then return s>=12 and s<88 and not masks[o][t*o.w*16+s]end
  if o.kind=='cottageControl'then return s<16 end
  return not masks[o][t*o.w*16+s]
 end
 local clear={};for _,o in ipairs(own)do if o.cap then for t=o.cap,o.last-1 do for s=0,o.w*16-1 do if inside(o,s,t)then clear[(o.y*16+t)*256+o.x*16+s]=true end end end end end
 local function draw(w,h,src,mask,project)
  local vv=P.build(ts,w,h,src,mask,0,h,1,nil,project,.5);for _,v in ipairs(vv)do out[#out+1]=v end
 end
 for _,o in ipairs(own)do local x,z=(o.x+ox)*16,(o.y+oz)*16;local first=#out+1
  local function src(s,t)return source(o.x*16+s,o.y*16+t)end
  local function band(a,b,project,extra)
   draw(o.w*16,o.h*16,src,function(s,t)return t>=a and t<b and inside(o,s,t)and(not extra or extra(s,t))end,project)
  end
  if o.kind=='cottageWall'then
   draw(240,32,function(s,t)
    if s>=16 and s<208 then return source(33,t)end
    return source(s,t)
   end,function()return true end,function(s,t)return{x+s,c.wallHeight*hs*(32-t)/32,z+32}end)
  elseif o.kind=='cottageFloor'then
   draw(240,128,function(s,t)local xx,yy=s,t+32
    if yy<64 or clear[yy*256+xx]then return 0x288,xx%16,yy%16 end
    return source(xx,yy)
   end,function()return true end,function(s,t)return{x+s,0,z+t}end)
  elseif o.kind=='cottageExit'then
   -- Native black filler matches the surrounding map void; omitting it
   -- exposes the renderer's lighter clear colour as a rectangular gap.
   draw(48,16,src,function()return true end,function(s,t)return{x+s,0,z+t}end)
  elseif o.kind=='cottagePod'then
   local h=c.podHeight*hs;local front=z+48
   band(0,26,function(s,t)return{x+s,h,z+48-c.podDepth+t*c.podDepth/26}end)
   band(26,48,function(s,t)return{x+s,h*(48-t)/22,front}end)
   -- Cylindrical shell follows the roof perimeter. A rectangular extrusion
   -- of each facade row would protrude above the curved lid as stray lines.
   local function side(a,b,sx)
    local m,u,v=src(sx,31);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
    G.quad(out,{a[1],h,a[2]},{b[1],h,b[2]},{b[1],0,b[2]},{a[1],0,a[2]},uv,c.sideShade)
   end
   for t=0,25 do local e,n=podEdges[t+1],podEdges[t+2];local zz=front-c.podDepth+t*c.podDepth/26;local nz=zz+c.podDepth/26
    side({x+e,zz},{x+n,nz},7);side({x+48-n,nz},{x+48-e,zz},40)
   end
   side({x+32,front-c.podDepth},{x+16,front-c.podDepth},7)
  elseif o.kind=='cottagePipe'then
   band(0,32,function(s,t)return{x+s,(c.pipeHeight+20-t)*hs,z+26}end)
  elseif o.kind=='cottageDesk'then
   -- Native checkerboard worktop; computer and tower remain on it.
   draw(32,11,function(s,t)return source(88+s%7,86+t)end,function()return true end,function(s,t)return{x+s,c.deskHeight,z+27+t}end)
   band(14,32,function(s,t)return{x+s,c.deskHeight+(32-t)*hs,z+31}end,function(s,t)return s<23 end)
   band(33,41,function(s,t)return{x+s,c.deskHeight*(41-t)/8,z+38}end)
  elseif o.kind=='cottageCrate'or o.kind=='cottageCabinet'then
   local depth=c.storageDepth;local front=z+16
   band(0,6,function(s,t)return{x+s,o.height,front-depth+t*depth/6}end)
   band(6,16,function(s,t)return{x+s,o.height*(16-t)/10,front}end)
   for _,sx in ipairs{0,15}do local m,u,v=src(sx,10);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local xx=x+(sx==15 and 16 or 0);G.quad(out,{xx,o.height,front-depth},{xx,o.height,front},{xx,0,front},{xx,0,front-depth},uv,c.sideShade)end
  else
   band(o.cap,o.last,function(s,t)return{x+s,o.height*hs*(o.last-t)/(o.last-o.cap),z+o.last}end)
  end
  if o.cap and o.kind~='cottagePipe'then contacts[#contacts+1]={x+o.w*8,z+(o.kind=='cottageDesk'and 38 or o.last),o.w*6,c.contactRadius,c.contactStrength}end
  local kind=o.kind=='cottageWall'and 'wall'or(o.kind=='cottageFloor'or o.kind=='cottageExit')and 'card'or o.kind=='cottagePlant'and 'plant'or o.kind
  V.require('RoomLightRig').capture(L,{kind=kind},out,first,#out)
 end
end
function R.lighting(d)
 local c=R.profile(d);if not c then return end;local sources={}
 for _,a in ipairs(c.sources)do sources[#sources+1]={at={a[1]*16,c.lightHeight,a[2]*16},radius=a[4],power=a[3],nightPower=a[3],color=a[5]and c.machineColor or c.lampColor,spread=c.spread}end
 return{localSelection=c.shadowContours,ambient=c.ambient,night=c.nightAmbient,sources=sources}
end
return R
