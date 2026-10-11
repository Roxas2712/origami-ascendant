-- Native FireRed Power Plant: structural courses and machinery have separate
-- surface ownership. No cell, collision, event, warp or script is modified.
local V=...;local R={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.powerPlant end
R.sectionUniforms=[[
uniform vec4 powerFrontSection; // player x, full height/enabled, section height, inner width
uniform float powerFrontWidth;
]]
R.sectionVertex=[[
 if(BillboardAnchor.z< -29.5 && BillboardAnchor.z> -35.5 && powerFrontSection.y>0.0){
  float amount=1.0-smoothstep(powerFrontSection.w,powerFrontWidth,abs(vertex_position.x-powerFrontSection.x));
  vertex_position.y=min(vertex_position.y,mix(powerFrontSection.y,powerFrontSection.z,amount));
 }
]]
function R.bindSection(shader,d,px,pz)
 local c=cfg();local s=c.frontSection;local active=R.profile(d)and s.enabled
 if active then
  local row=d.midLayout.height-1;local front=row*16;local mid=d.midLayout:midAt(math.floor(px/16),row)
  -- The native entrance gap already provides sight; keep its jambs upright.
  local portal=mid==0x2c9 or mid==0x2ca or mid==0x2cb
  active=not portal and pz<front and pz>front-s.distance
 end
 local hs=V.require('Billboard').heightScale()
 shader:send('powerFrontSection',{px,active and c.wallHeight*hs or 0,s.height*hs,s.innerWidth})
 shader:send('powerFrontWidth',s.outerWidth)
end
function R.profile(d)
 local L=d and d.midLayout
 return cfg().enabled and d and d.id=='FR_POWER_PLANT'and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4e9c'and L and L.width==50 and L.height==40 and L:midAt(2,0)==0x285 and L:midAt(7,9)==0x2e8
end
local wall={};for _,m in ipairs{0x28c,0x28d,0x28e,0x291,0x292,0x2b9,0x2d2,0x2d3,0x2d4,0x2d5,0x2d6,0x2d7,0x2e6,0x2e7,0x308}do wall[m]=true end
local trim={};for _,m in ipairs{0x281,0x282,0x283,0x287,0x289,0x28a,0x28b,0x28f,0x290,0x293,0x297,0x298,0x2a0,0x2a1,0x2a2,0x2a3,0x2a4,0x2a5,0x2a6,0x2a7,0x2a8,0x2a9,0x2aa,0x2ab,0x2ac,0x2ad,0x2ae,0x2b0,0x2b1,0x2b4,0x2b8,0x2bc,0x2bf,0x2c0,0x2c7,0x2c8,0x2cf}do trim[m]=true end
function R.plan(d,objects,mask)
 local L=d.midLayout;if L then R.rooms[L]=nil end;if not R.profile(d)then return end
 local owned={};R.rooms[L]=owned
 local function add(kind,x,y,w,h,extra)
  local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w;o.h=h;objects[#objects+1]=o;owned[#owned+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*L.width+xx+1]={mid=o.floor or 0x29f,separateSurface=true}end end;return o
 end
 for y=1,L.height-1 do for x=0,L.width-1 do
  if wall[L:midAt(x,y)]then add('powerWall',x,y-1,1,3)end
 end end
 -- The west doorway contains a cropped native three-row facade, not three
 -- pieces of horizontal rim. Keep its eight-pixel footprint and full height.
 if L:midAt(0,7)==0x2b8 and L:midAt(0,8)==0x2c0 and L:midAt(0,9)==0x2c8 then add('powerWall',0,7,1,3,{sourceLeft=8,floor=8})end
 for y=0,L.height-3 do for x=0,L.width-1 do
  if L:midAt(x,y)==0x2a0 and L:midAt(x,y+1)==0x2a8 and L:midAt(x,y+2)==0x2b0 then add('powerPillar',x,y,1,3)end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y);local k=y*L.width+x+1
  if m==8 then mask[k]={mid=8,void=true,separateSurface=true}
  elseif trim[m]and not(type(mask[k])=='table'and mask[k].separateSurface)then add('powerTrim',x,y,1,1,{floor=8})end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if (m==0x2e8 or m==0x2eb)and x+2<L.width and y+3<L.height then
   local ok=true;for dy=0,3 do for dx=0,2 do if L:midAt(x+dx,y+dy)~=m+dy*8+dx then ok=false end end end
   if ok then add('powerGenerator',x,y,3,4,{floor=m==0x2e8 and 0x2c4 or 0x29f})end
  elseif(m==0x2ee and L:midAt(x,y+1)==0x2f6)or(m==0x2ef and L:midAt(x,y+1)==0x2f7)then
   add('powerConsole',x,y,1,2)
  elseif m==0x308 and L:midAt(x,y+1)==0x310 and L:midAt(x,y+2)==0x318 then
   add('powerTerminal',x,y,1,3)
  elseif m==0x2d8 or m==0x2d9 then
   local a=L:midAt(x,y-1)
   if a==0x2d0 or a==0x2d1 or a==0x2e0 or a==0x2d8 then
    add('powerCylinder',x,y,1,1);mask[(y-1)*L.width+x+1]={mid=0x29f,separateSurface=true}
   end
  elseif m==0x2b5 or m==0x2b6 or m==0x2e2 then add('powerRubble',x,y,1,1)end
 end end
end
function R.actorOffset(d,px,pz,gid)
 if gid~=92 or not R.profile(d)then return end
 local x,y=math.floor((px+8)/16),math.floor(pz/16)
 local m=d.midLayout:midAt(x,y)
 if(m==0x2d0 or m==0x2d1)and d.midLayout:midAt(x,y+1)==0x2d9 then
  return cfg().cylinderHeight*V.require('Billboard').heightScale(),16
 end
end
function R.lighting(d)
 if not R.profile(d)then return end
 local c,L=cfg(),d.midLayout;local sources={}
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x2b9 then sources[#sources+1]={at={x*16+8,c.wallHeight+10,y*16+36},radius=c.lampRadius,power=c.lampPower,color=c.lampColor,spread={10,7}}
  elseif m==0x2ee or m==0x2ef or m==0x310 then sources[#sources+1]={at={x*16+8,24,y*16+26},radius=c.consoleRadius,power=c.consolePower,color=c.consoleColor,spread={5,4}}end
 end end
 return{fixed=true,ambient=c.ambient,night=c.ambient,localSelection=true,sources=sources}
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local own=R.rooms[L];if not(cfg().enabled and own)then return end
 local c=cfg();local hs=V.require('Billboard').heightScale();local P,B,G=V.require('PaperSprite'),V.require('BuildingMesh'),V.require('WorldGeometry')
 local shell=V.require('ClosedShell');local section=false
 local function closed(normal,a,b,c,d,uv,shade)
  local first=#out+1;G.quad(out,a,b,c,d,uv,shade);shell.tag(out,first,normal,section)
 end
 local function draw(w,h,source,inside,project,shade)
  local vv=P.build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local crowns={}
 for _,o in ipairs(own)do if o.kind=='powerTrim'then crowns[o.y*L.width+o.x]=true end end
 for _,o in ipairs(own)do local x,z=(o.x+ox)*16,(o.y+oz)*16;local first=#out+1
  section=o.kind=='powerTrim'and o.y==L.height-1
  local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  if o.kind=='powerWall'or o.kind=='powerPillar'then
   -- Keep the whole wall just behind the native actor foot plane. Equal-depth
   -- triangles otherwise expose alternating strips of a sprite at the wall.
   z=z-c.wallSurfaceInset
   local function face(s,t)
    local m,u,v=src(s,t+16)
    if t<16 and m==0x308 then m=0x28d end
    if t>=16 and(m==0x2ee or m==0x2ef or m==0x310 or(m>=0x2e8 and m<=0x2ed))then m=0x295 end
    return m,u,v
   end
   local left=o.sourceLeft or 0;local function inFace(s)return s>=left end
   -- End pillars and the cropped west corner continue a longitudinal wall.
   -- Their native three-row footprint needs a solid bridge to the next crown.
   local depth=(o.kind=='powerPillar'or o.sourceLeft)and o.h*16 or c.wallDepth
   draw(16,32,face,inFace,function(s,t)return{x+s,c.wallHeight*hs*(32-t)/32,z+48}end)
   draw(16,16,src,inFace,function(s,t)return{x+s,c.wallHeight*hs,z+48-depth+depth*t/16}end)
   for _,side in ipairs{left,16}do
    for at=0,depth-1,16 do local last=math.min(at+16,depth)
     for course=0,1 do
      closed(side==left and 'left'or'right',{x+side,c.wallHeight*hs*(1-course/2),z+48-depth+at},{x+side,c.wallHeight*hs*(1-course/2),z+48-depth+last},
       {x+side,c.wallHeight*hs*(.5-course/2),z+48-depth+last},{x+side,c.wallHeight*hs*(.5-course/2),z+48-depth+at},G.uv(ts,course==0 and 0x28d or 0x295,0,0,last-at,16,.02),c.sideShade)
     end
    end
   end
   local uv=G.uv(ts,0x295,8,8,9,9,.5)
   closed('back',{x+16,c.wallHeight*hs,z+48-depth},{x+left,c.wallHeight*hs,z+48-depth},{x+left,0,z+48-depth},{x+16,0,z+48-depth},uv,c.sideShade)
   closed('bottom',{x+left,0,z+48-depth},{x+left,0,z+48},{x+16,0,z+48},{x+16,0,z+48-depth},uv,c.sideShade)
  elseif o.kind=='powerTrim'then
   -- These tiles are wall crowns. Their broad gray fill shares a palette
   -- entry with floor speckles, so a floor-color subtraction erases the wall.
   local function inside(s,t)local m,u,v=src(s,t);local r,g,b,a=B.pixel(ts,m,u,v);return a>.5 and r+g+b>.01 end
   local height=c.wallHeight*hs
   local colors={}
   for t=0,15 do for s=0,15 do if inside(s,t)then colors[t*16+s]=rgb(B.pixel(ts,L:midAt(o.x,o.y),s,t))end end end
   local function color(s,t)if s>=0 and s<16 and t>=0 and t<16 then return colors[t*16+s]end end
   local function occupied(s,t)
    if s>=0 and s<16 and t>=0 and t<16 then return color(s,t)~=nil end
    local cx,cy=o.x+math.floor(s/16),o.y+math.floor(t/16)
    if cx<0 or cy<0 or cx>=L.width or cy>=L.height or not crowns[cy*L.width+cx]then return false end
    local r,g,b,a=B.pixel(ts,L:midAt(cx,cy),s%16,t%16);return a>.5 and r+g+b>.01
   end
   local capFirst=#out+1
   draw(16,16,src,inside,function(s,t)return{x+s,height,z+t}end)
   if section then shell.tag(out,capFirst,'top',true)end
   -- Use native vertical wall courses on every exposed side. The top keeps
   -- its exact footprint, including corners and the original doorway gaps.
   for direction=1,4 do for line=0,15 do local at=0
    local function edge(n)
     local s,t=direction<=2 and n or line,direction<=2 and line or n
     return color(s,t) and not occupied(s+(direction==3 and -1 or direction==4 and 1 or 0),t+(direction==1 and -1 or direction==2 and 1 or 0))
    end
    while at<16 do
     if edge(at)then local last=at+1;while last<16 and edge(last)do last=last+1 end
      local normal=({'back','front','left','right'})[direction]
      local function point(n,h)
       if direction<=2 then return{x+n,h,z+line+(direction==2 and 1 or 0)}end
       return{x+line+(direction==4 and 1 or 0),h,z+n}
      end
      for course=0,1 do
       closed(normal,point(at,height*(1-course/2)),point(last,height*(1-course/2)),point(last,height*(.5-course/2)),point(at,height*(.5-course/2)),
        G.uv(ts,course==0 and 0x28d or 0x295,at,0,last,16,.02),c.sideShade)
      end
      at=last
     else at=at+1 end
    end
   end end
   local used={}
   for t=0,15 do for s=0,15 do local value=color(s,t)
    if value and not used[t*16+s]then
     local right=s+1;while right<16 and color(right,t)==value and not used[t*16+right]do right=right+1 end
     local bottom=t+1
     while bottom<16 do local full=true;for u=s,right-1 do if color(u,bottom)~=value or used[bottom*16+u]then full=false;break end end;if not full then break end;bottom=bottom+1 end
     for v=t,bottom-1 do for u=s,right-1 do used[v*16+u]=true end end
     closed('bottom',{x+s,0,z+t},{x+right,0,z+t},{x+right,0,z+bottom},{x+s,0,z+bottom},G.uv(ts,L:midAt(o.x,o.y),s,t,s+1,t+1,.5),c.sideShade)
    end
   end end
  else
   local sy,h,height,base,w=0,o.h*16,24,z+o.h*16,o.w*16
   if o.kind=='powerPillar'then h,height,base=48,c.wallHeight,z+48
   elseif o.kind=='powerGenerator'then sy,h,height,base=8,48,c.generatorHeight,z+56
   elseif o.kind=='powerConsole'then h,height,base=26,c.consoleHeight,z+28
   elseif o.kind=='powerTerminal'then h,height,base=40,c.terminalHeight,z+42
   elseif o.kind=='powerCylinder'then sy,h,height,base=-5,21,c.cylinderHeight,z+16
   elseif o.kind=='powerRubble'then h,height,base=16,c.rubbleHeight,z+16 end
   local function source(s,t)
    if o.kind=='powerCylinder'then
     -- Stacked source tiles contain the next cylinder's cap. Use the native
     -- standalone end tile so each separate barrel keeps its complete foot.
     local yy=t+sy;return yy<0 and 0x2d0 or 0x2d9,s,yy%16
    end
    return src(s,t+sy)
   end
   -- Remove only edge-connected pixels equal to the original background
   -- at this texel. A shared gray/cream palette is not an alpha mask: applying
   -- that globally would erase the generator housing and the rubble itself.
   local clear,empty,queue={},{},{}
   for t=0,h-1 do for s=0,w-1 do
    local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v);local donor=0x29f
    if o.kind=='powerGenerator'then donor=t+sy<16 and 0x295 or o.floor
    elseif o.kind=='powerConsole'then donor=t<16 and 0x295 or 0x29f
    elseif o.kind=='powerTerminal'then donor=t<16 and 0x28d or t<32 and 0x295 or 0x29f
    elseif o.kind=='powerCylinder'then donor=m==0x2d1 and 0x29d or m==0x2e0 and 0x295 or 0x29f
    elseif o.kind=='powerRubble'then donor=m==0x2b5 and 0x29d or m==0x2e2 and 0x29b or 0x29f end
    local rr,gg,bb=B.pixel(ts,donor,u,v)
    clear[t*w+s]=a<.5 or r+g+b<.01 or (o.kind~='powerPillar'and rgb(r,g,b)==rgb(rr,gg,bb))
   end end
   local function seed(s,t)local k=t*w+s;if clear[k]and not empty[k]then empty[k]=true;queue[#queue+1]=k end end
   for s=0,w-1 do seed(s,0);seed(s,h-1)end;for t=0,h-1 do seed(0,t);seed(w-1,t)end
   local n=1;while queue[n]do local k=queue[n];n=n+1;local s,t=k%w,math.floor(k/w)
    if s>0 then seed(s-1,t)end;if s+1<w then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t+1<h then seed(s,t+1)end
   end
   local function inside(s,t)return not empty[t*w+s]end
   draw(w,h,source,inside,function(s,t)return{x+s,height*hs*(h-t)/h,base}end)
   contacts[#contacts+1]={x+w/2,base,w*.4,c.contactRadius,c.contactStrength}
  end
  if o.kind~='powerRubble'and o.kind~='powerCylinder'then V.require('RoomLightRig').capture(L,o,out,first,#out)end
 end
end
return R
