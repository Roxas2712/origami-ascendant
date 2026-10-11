-- Viridian's native maze is a continuous low wall volume. Spin tiles and
-- collision/forced movement belong exclusively to the original engine.
local V=...;local R={}
local function cfg()return V.require('DioramaConfig').interiors.fireredEarthGym end
function R.profile(d)
 local L=d and d.midLayout
 return cfg().enabled and d and d.id=='FR_VIRIDIAN_CITY_GYM'and (d.renderPair or d.pair)=='building__rom_082d4cbc'and d.mapType==8 and L and L.width==20 and L.height==24 and L:midAt(2,2)==0x2be and L:midAt(7,6)==0x2d0 or nil
end
function R.plan(d)
 if not R.profile(d)then return end;local mask={};for i=1,480 do mask[i]={mid=8,void=true,separateSurface=true}end
 return{mask=mask,owners={},objects={{kind='earthFloor'},{kind='earthRear'},{kind='earthWalls'},{kind='earthMat',x=16,y=28,w=48,h=28},{kind='earthStatue',x=240,y=304,w=16,h=32},{kind='earthStatue',x=304,y=304,w=16,h=32}}}
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local colors={[0xb5b5a5]=true,[0x7b7b7b]=true,[0x52526b]=true,[0xd6d6d6]=true,[0xd69c7b]=true,[0xb57352]=true,[0xe6e6e6]=true}
function R.wallMask(L,ts)
 local B=V.require('BuildingMesh');local mask={}
 for z=32,367 do for x=0,319 do local m=L:midAt(math.floor(x/16),math.floor(z/16))
  local eligible=m and m>=0x290 and m~=0x2a1 and m~=0x2a9 and not(m>=0x2aa and m<=0x2ac)and not(m>=0x2b2 and m<=0x2b7)and not(m>=0x2bd and m<=0x2bf)and not(m>=0x2cd and m<=0x2cf)
  if eligible and colors[rgb(B.pixel(ts,m,x%16,z%16))]then mask[z*320+x]=true end
 end end
 -- Dark outline colors also occur in mixed arrow/wall tiles. Retain only
 -- components containing the native grey cap, never a detached arrow border.
 local visited={}
 for seed in pairs(mask)do if not visited[seed]then
  local q={seed};visited[seed]=true;local i,cap=1,false
  while q[i]do local k=q[i];i=i+1;local x,z=k%320,math.floor(k/320)
   if rgb(B.pixel(ts,L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16))==0xb5b5a5 then cap=true end
   for _,a in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do local xx,zz=x+a[1],z+a[2];local n=zz*320+xx
    if xx>=0 and xx<320 and mask[n]and not visited[n]then visited[n]=true;q[#q+1]=n end
   end
  end
  if not cap then for _,k in ipairs(q)do mask[k]=nil end end
 end end
 return mask
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local P,B,G=V.require('PaperSprite'),V.require('BuildingMesh'),V.require('WorldGeometry');local hs=V.require('Billboard').heightScale();local walls=R.wallMask(L,ts)
 local function src(x,z)return L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16 end
 local function draw(w,h,source,inside,project,shade)
  local vv=P.build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 local function clean(x,z)
  if z>=304 and z<336 and(x>=240 and x<256 or x>=304 and x<320)then return 0x281,x%16,z%16 end
  return src(x,z)
 end
 for _,o in ipairs(objects)do local first=#out+1
  if o.kind=='earthFloor'then
   draw(320,352,function(s,t)return clean(s,t+32)end,function(s,t)local z=t+32
    if walls[z*320+s]or(s>=16 and s<64 and z<56)then return false end
    local r,g,b=B.pixel(ts,clean(s,z));return r+g+b>0
   end,function(s,t)return{s,0,t+32}end)
  elseif o.kind=='earthMat'then
   draw(48,28,function(s,t)return src(16+s,28+t)end,nil,function(s,t)return{16+s,0,28+t}end)
  elseif o.kind=='earthRear'then
   local height=c.wallHeight*hs
   local function source(s,t)
    -- Fill the original pillar/plinth overlap with its exact rear-wall
    -- course. The independent maze and mat own those foreground pixels.
    if s<80 and not(s>=32 and s<48 and t<16)then return t<16 and 0x291 or 0x299,s%16,t%16 end
    return src(s,t)
   end
   draw(320,32,source,nil,function(s,t)return{s,height*(32-t)/32,32}end)
   draw(320,1,function(s)return source(s,0)end,nil,function(s,t)return{s,height,32-c.wallDepth+t*c.wallDepth}end)
   for _,x in ipairs{0,320}do draw(1,32,function(_,t)return source(math.min(319,x),t)end,nil,function(s,t)return{x,height*(32-t)/32,32-c.wallDepth+s*c.wallDepth}end,c.sideShade)end
  elseif o.kind=='earthWalls'then
   local height=c.partitionHeight*hs
   -- The original cap's southern outline cannot be stretched per column:
   -- that creates floating notches at L-junctions. Reconstruct its continuous
   -- edge from the native cap palette over the exact original footprint.
   local palette={}
   for k in pairs(walls)do local x,z=k%320,math.floor(k/320);local m,u,v=src(x,z);local color=rgb(B.pixel(ts,m,u,v));palette[color]=palette[color]or{m,u,v}end
   local function capSource(x,z)
    local edge=false;local near=false
    for _,a in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do
     if not walls[(z+a[2])*320+x+a[1]]then edge=true end
     if not walls[(z+2*a[2])*320+x+2*a[1]]then near=true end
    end
    return edge and 0x7b7b7b or near and 0xd6d6d6 or 0xb5b5a5
   end
   for z=32,367 do local x=0
    while x<320 do if walls[z*320+x]then
     local start=x;local col=capSource(x,z);repeat x=x+1 until x>=320 or not walls[z*320+x]or capSource(x,z)~=col
     local a=assert(palette[col]);local uv=G.uv(ts,a[1],a[2],a[3],a[2]+1,a[3]+1,.5);local xx,zz=start+ox*16,z+oz*16
     G.quad(out,{xx,height,zz},{x+ox*16,height,zz},{x+ox*16,height,zz+1},{xx,height,zz+1},uv)
    else x=x+1 end end
   end
   local fronts={}
   -- Trace each native column. The final orange course folds onto the
   -- front face; the cap spans its complete footprint to avoid void strips.
   for x=0,319 do local z=32
    while z<368 do if walls[z*320+x]then
     local start=z;repeat z=z+1 until z>=368 or not walls[z*320+x];local stop=z;local split=stop
     for zz=stop-1,start,-1 do local col=rgb(B.pixel(ts,src(x,zz)))
      if col==0xd69c7b or col==0xb57352 then split=zz-3 end
     end
     split=math.max(start+1,math.min(stop,split))
     if split<stop then fronts[#fronts+1]={x=x,split=split,stop=stop}
     else draw(1,1,function()return src(x,stop-1)end,nil,function(s,t)return{x+s,height*(1-t),stop}end,c.sideShade)end
     draw(1,1,function()return src(x,start)end,nil,function(s,t)return{x+s,height*(1-t),start}end,c.sideShade)
     for zz=start,stop-1 do for _,a in ipairs{{-1,0},{1,1}}do if not walls[zz*320+x+a[1]]then
      local m,u,v=src(x,zz);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local xx,yy=x+a[2]+ox*16,zz+oz*16
      G.quad(out,{xx,height,yy},{xx,height,yy+1},{xx,0,yy+1},{xx,0,yy},uv,c.sideShade)
     end end end
    else z=z+1 end end
   end
   table.sort(fronts,function(a,b)if a.stop~=b.stop then return a.stop<b.stop elseif a.split~=b.split then return a.split<b.split else return a.x<b.x end end)
   local i=1
   while fronts[i]do local a=fronts[i];local w=1
    while fronts[i+w]and fronts[i+w].stop==a.stop and fronts[i+w].split==a.split and fronts[i+w].x==a.x+w do w=w+1 end
    draw(w,a.stop-a.split,function(s,t)return src(a.x+s,a.split+t)end,nil,function(s,t)return{a.x+s,height*(a.stop-a.split-t)/(a.stop-a.split),a.stop}end)
    i=i+w
   end
  elseif o.kind=='earthStatue'then
   draw(16,32,function(s,t)return src(o.x+s,o.y+t)end,function(s,t)return V.require('FireRedGymRooms').inside({kind='gymStatue',w=16,h=32},s,t)end,function(s,t)return{o.x+s,c.statueHeight*hs*(32-t)/32,o.y+32}end)
   contacts[#contacts+1]={o.x+8+ox*16,o.y+32+oz*16,7,c.contactRadius,c.contactStrength}
  end
  V.require('RoomLightRig').capture(L,{kind=o.kind=='earthRear'and 'wall'or 'plant'},out,first,#out)
 end
end
function R.lighting(d)
 if not R.profile(d)then return end;local c=cfg();local sources={}
 for _,p in ipairs(c.lights)do sources[#sources+1]={at={p[1],c.lightHeight,p[2]},power=c.lightPower,radius=c.lightRadius,color=c.lightColor,spread=c.lightSpread}end
 return{fixed=true,ambient=c.ambient,sources=sources}
end
return R
