-- Native New Mauville machinery and structural surfaces, separate from its cave entrance.
local V=...;local H={background=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').emeraldInteriors.newMauville.hall end
function H.profile(d)
 local L=d and d.midLayout;local c=cfg();local a=V.require('DioramaConfig').emeraldInteriors
 if a.enabled and a.newMauville.enabled and c.enabled and d and d.id=='EM_NEW_MAUVILLE_INSIDE'and d.pair=='general__bike_shop'and L and L.width==42 and L.height==42 and L:midAt(3,0)==0x268 then return c.profile end
end
local tops={[0x21f]=true,[0x268]=true,[0x26a]=true}
local rims={};for _,m in ipairs{0x227,0x25c,0x25d,0x260,0x261,0x26e,0x270,0x272,0x277,0x278,0x27a,0x280,0x282,0x287,0x288,0x289,0x28a,0x28b,0x28c,0x290,0x291,0x293,0x294,0x295,0x296,0x298,0x29d,0x29e,0x29f,0x2a0,0x2a5,0x2a6,0x2a7}do rims[m]=true end
local gates={{21,2},{28,22},{10,24},{37,33},{10,0},{10,16},{23,34}}
function H.plan(d)
 if not H.profile(d)then return end
 local L=d.midLayout;local c=cfg();local objects,mask,bg={},{},{}
 H.background[L]=bg
 local function add(kind,x,y,w,h,e)
  local o=e or{};o.kind='newMauvilleHall'..kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o
 end
 local function object(kind,x,y,w,h,height,start,last,wallRows)
  local o=add(kind,x,y,w,h,{height=height,start=start or 0,last=last or h*16})
  for yy=0,h-1 do for xx=0,w-1 do local k=(y+yy)*L.width+x+xx+1
   local donor=wallRows==2 and yy==0 and 0x21f or wallRows and yy<(wallRows or 0)and 0x227 or 0x210
   bg[k]=donor;mask[k]=donor
  end end;return o
 end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if bg[y*L.width+x+1]then -- An already extracted multi-tile object owns this cell.
  elseif m==0x276 then add('Stair',x,y,1,1,{height=c.stairHeight,mid=m});mask[y*L.width+x+1]=0x210
  elseif m==0x299 and L:midAt(x,y+1)==0x2a1 then
   -- The central shelf ends at a native partition: only its left half exists.
   object('Shelf',x,y,L:midAt(x+1,y)==0x29a and 2 or 1,3,c.shelfHeight,8,40,2)
  elseif m==0x2a8 then object('Desk',x,y,2,3,c.deskHeight,6,40,2)
  elseif m==0x2d4 and L:midAt(x+1,y)==0x2d5 then object('Machine',x,y,2,3,c.machineHeight,0,48,1)
  elseif m==0x2d0 and L:midAt(x+3,y)==0x2d3 then object('Generator',x,y,4,4,c.generatorHeight,0,56,1)
  elseif m==0x2d6 or m==0x2d7 then object('Console',x,y,1,2,c.consoleHeight,0,28,1)
  elseif m==0x2a3 and L:midAt(x+1,y)==0x2a4 then object('Bench',x,y,2,2,c.benchHeight,0,32)
  elseif m==0x2c8 then object('Bin',x,y,1,1,c.binHeight,0,16)
  elseif m==0x2c0 or m==0x2c1 or m==0x2c2 or m==0x2c3 then object('Crate',x,y,1,1,c.crateHeight,0,16)
  elseif m==0x2b2 or m==0x2b3 or m==0x2b4 then object('Crate',x,y,1,2,c.crateHeight,0,24,1)
  end
 end end
 for _,p in ipairs(gates)do local x,y=p[1],p[2];local m=L:midAt(x,y)
  if m==0x2b6 or m==0x2b7 then
   add('Gate',x,y,1,4,{height=c.gateHeight,start=0,last=64})
   for yy=0,3 do local k=(y+yy)*L.width+x+1;mask[k]=0x210;bg[k]=0x210 end
  end
 end
 for y=0,L.height-2 do for x=0,L.width-1 do local k=y*L.width+x+1;local m=bg[k]or L:midAt(x,y)
  if tops[m]then
   add('Wall',x,y,1,2,{height=c.wallHeight,start=5,last=32})
   for yy=y,y+1 do mask[yy*L.width+x+1]={mid=0x208,void=true}end
  end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do local k=y*L.width+x+1;local m=bg[k]or L:midAt(x,y)
  if m==0x208 then mask[k]={mid=0x208,void=true}
  elseif rims[m]and not(type(mask[k])=='table'and mask[k].void)then
   add('Rim',x,y,1,1,{height=c.rimHeight,mid=m});mask[k]={mid=0x208,void=true}
  end
 end end
 return objects,mask
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function H.build(out,L,ts,o,x,z,contacts)
 local c=cfg();local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local P=V.require('PaperSprite');local hs=V.require('DioramaConfig').emeraldInteriors.heightScale
 local bg=H.background[L]or{};local kind=o.kind:sub(#'newMauvilleHall'+1)
 local function source(s,t)local xx,yy=o.x+math.floor(s/16),o.y+math.floor(t/16);return L:midAt(xx,yy),s%16,t%16 end
 local function back(s,t)local xx,yy=o.x+math.floor(s/16),o.y+math.floor(t/16);return bg[yy*L.width+xx+1]or L:midAt(xx,yy),s%16,t%16 end
 local function draw(src,inside,project,shade)
  local vv=P.build(ts,o.w,o.h,src,inside,0,o.h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do v[2]=v[2]*hs;out[#out+1]=v end
 end
 if kind=='Stair'then
  for i=0,c.stairSteps-1 do local a,b=i*16/c.stairSteps,(i+1)*16/c.stairSteps;local h=o.height*(1-i/c.stairSteps)*hs;local low=o.height*(1-(i+1)/c.stairSteps)*hs
   G.quad(out,{x,h,z+a},{x+16,h,z+a},{x+16,h,z+b},{x,h,z+b},G.uv(ts,o.mid,0,a,16,b,.5),1)
   G.quad(out,{x,h,z+b},{x+16,h,z+b},{x+16,low,z+b},{x,low,z+b},G.uv(ts,o.mid,0,b-1,16,b,.5),c.sideShade)
   for _,xx in ipairs{0,16}do G.quad(out,{x+xx,h,z+a},{x+xx,h,z+b},{x+xx,0,z+b},{x+xx,0,z+a},G.uv(ts,0x227,8,8,9,9,.5),c.sideShade)end
  end
 elseif kind=='Wall'then
  draw(back,function(s,t)local m,u,v=back(s,t);local r,g,b,a=B.pixel(ts,m,u,v);return t>=o.start and a>.5 and r+g+b>.03 end,function(s,t)return{x+s,o.height*(o.last-t)/(o.last-o.start),z+o.last}end)
  draw(back,function(s,t)return t>=5 and t<7 end,function(s,t)return{x+s,o.height,z+o.last-c.wallDepth+(t-5)*c.wallDepth/2}end)
  G.quad(out,{x+16,o.height*hs,z+32-c.wallDepth},{x,o.height*hs,z+32-c.wallDepth},{x,0,z+32-c.wallDepth},{x+16,0,z+32-c.wallDepth},G.uv(ts,0x227,8,8,9,9,.5),c.sideShade)
  for _,s in ipairs{0,16}do G.quad(out,{x+s,o.height*hs,z+32-c.wallDepth},{x+s,o.height*hs,z+32},{x+s,0,z+32},{x+s,0,z+32-c.wallDepth},G.uv(ts,0x227,8,8,9,9,.5),c.sideShade)end
 elseif kind=='Rim'then
  local function src(s,t)return o.mid,s,t end
  local function inside(s,t)local r,g,b,a=B.pixel(ts,o.mid,s,t);return a>.5 and r+g+b>.03 end
  draw(src,inside,function(s,t)return{x+s,o.height,z+t}end)
  for t=0,15 do for s=0,15 do if inside(s,t)then local uv=G.uv(ts,0x227,8,8,9,9,.5)
   if t==0 or not inside(s,t-1)then G.quad(out,{x+s+1,o.height*hs,z+t},{x+s,o.height*hs,z+t},{x+s,0,z+t},{x+s+1,0,z+t},uv,c.sideShade)end
   if t==15 or not inside(s,t+1)then G.quad(out,{x+s,o.height*hs,z+t+1},{x+s+1,o.height*hs,z+t+1},{x+s+1,0,z+t+1},{x+s,0,z+t+1},uv,c.sideShade)end
   if s==0 or not inside(s-1,t)then G.quad(out,{x+s,o.height*hs,z+t},{x+s,o.height*hs,z+t+1},{x+s,0,z+t+1},{x+s,0,z+t},uv,c.sideShade)end
   if s==15 or not inside(s+1,t)then G.quad(out,{x+s+1,o.height*hs,z+t+1},{x+s+1,o.height*hs,z+t},{x+s+1,0,z+t},{x+s+1,0,z+t+1},uv,c.sideShade)end
  end end end
 else
  local clear,empty,q={},{},{}
  for t=0,o.h-1 do for s=0,o.w-1 do local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v);local donor=bg[(o.y+math.floor(t/16))*L.width+o.x+math.floor(s/16)+1]or 0x210;local rr,gg,bb=B.pixel(ts,donor,u,v)
   clear[t*o.w+s]=t<o.start or (t>=o.last and kind~='Generator')or a<.5 or r+g+b<.03 or rgb(r,g,b)==rgb(rr,gg,bb)
  end end
  local function seed(s,t)local k=t*o.w+s;if clear[k]and not empty[k]then empty[k]=true;q[#q+1]=k end end
  for s=0,o.w-1 do seed(s,0);seed(s,o.h-1)end;for t=0,o.h-1 do seed(0,t);seed(o.w-1,t)end
  local i=1;while q[i]do local k=q[i];i=i+1;local s,t=k%o.w,math.floor(k/o.w);if s>0 then seed(s-1,t)end;if s+1<o.w then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t+1<o.h then seed(s,t+1)end end
  if kind=='Generator'then
   -- The pale mounting plate surrounds the orange housing in the source.
   -- Keep that plate horizontal, including its corner bolts. Only the housing
   -- rises; edge-connected neutral plate pixels cannot become a white backdrop.
   local plateEmpty=empty;clear={};empty={};q={}
   for t=0,o.h-1 do for s=0,o.w-1 do local m,u,v=source(s,t);local r,g,b=B.pixel(ts,m,u,v)
    clear[t*o.w+s]=plateEmpty[t*o.w+s]or(math.abs(r-g)<.12 and math.abs(g-b)<.17 and(r+g+b>1.7 or s<6 or s>=58 or t>=56 or t<14 and(s<16 or s>48)))
   end end
   for s=0,o.w-1 do seed(s,0);seed(s,o.h-1)end;for t=0,o.h-1 do seed(0,t);seed(o.w-1,t)end
   local i=1;while q[i]do local k=q[i];i=i+1;local s,t=k%o.w,math.floor(k/o.w);if s>0 then seed(s-1,t)end;if s+1<o.w then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t+1<o.h then seed(s,t+1)end end
   local function plate(s,t)if not empty[t*o.w+s]then return 0x2d8,2,2 end;return source(s,t)end
   draw(plate,function(s,t)return not plateEmpty[t*o.w+s]end,function(s,t)return{x+s,.1,z+32+t*.5}end)
  end
  draw(source,function(s,t)return t>=o.start and t<o.last and not empty[t*o.w+s]end,function(s,t)return{x+s,o.height*(o.last-t)/(o.last-o.start),z+o.last}end)
  if contacts then contacts[#contacts+1]={x+o.w/2,z+o.last,o.w*.38,2,c.contactStrength}end
 end
end
function H.actorHeight(d,x,z)
 if not H.profile(d)then return end
 local xx,zz=x+8,z+15.99;local tx,ty=math.floor(xx/16),math.floor(zz/16)
 if d.midLayout:midAt(tx,ty)==0x276 then return cfg().stairHeight*(1-math.floor((zz%16)/16*cfg().stairSteps)/cfg().stairSteps)*V.require('DioramaConfig').emeraldInteriors.heightScale end
end
function H.lighting(d)
 if not H.profile(d)then return end
 local c=cfg();local sources={}
 for _,p in ipairs(c.ceiling)do sources[#sources+1]={at={p[1]*16+8,c.lightHeight,p[2]*16+8},radius=c.radius,power=c.power,color=c.color,spread={16,12}}end
 for _,p in ipairs(c.devices)do sources[#sources+1]={at={p[1]*16,c.deviceHeight,p[2]*16+12},radius=c.deviceRadius,power=c.devicePower,color=c.deviceColor,spread={4,3}}end
 if d.midLayout:midAt(32,2)==0x2d8 then sources[#sources+1]={at={34*16,c.generatorHeight+8,4*16},radius=c.generatorRadius,power=c.generatorPower,color=c.generatorColor,spread={12,8}}end
 return{fixed=true,ambient=c.ambient,night=c.ambient,localSelection=true,sources=sources}
end
function H.capture(list,o,x,z)
 if not o.kind:match('^newMauvilleHall')then return false end
 local h=o.height*V.require('DioramaConfig').emeraldInteriors.heightScale
 if o.kind=='newMauvilleHallWall'then list[#list+1]={lo={x,0,z+32-cfg().wallDepth},hi={x+o.w,h,z+32},wall=true}
 elseif o.kind~='newMauvilleHallRim'and o.kind~='newMauvilleHallStair'then list[#list+1]={lo={x+2,0,z+o.last-.5},hi={x+o.w-2,h,z+o.last},wall=false}end
 return true
end
return H
