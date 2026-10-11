-- Native L/U work surfaces: preserve holes and split devices from their donors.
local V=...;local S={}
local function cfg()return V.require('DioramaConfig').interiors.silphCounters end
function S.profile(d)return cfg().enabled and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4ecc'and(d.id or d.name or''):match('^FR_SILPH_CO_%d+F$')and d.midLayout end
function S.plan(d,objects,mask)
 if not S.profile(d)then return end;local L=d.midLayout
 local function claim(o,dx,dy)
  local x,y=o.x+dx,o.y+dy;o.cells[dy*(o.w/16)+dx]=true
  mask[y*L.width+x+1]={mid=0x334,separateSurface=true,silphCounter=true}
 end
 local function shadow(x,y)
  if x>=0 and y>=0 and x<L.width and y<L.height then
   local m=L:midAt(x,y)
   if m==0x336 or m==0x357 or m==0x33b or m==0x33c then mask[y*L.width+x+1]={mid=0x334,separateSurface=true}end
  end
 end
 for y=1,L.height-1 do for x=0,L.width-1 do
  if L:midAt(x,y)==0x364 and L:midAt(x,y-1)==0x330 then
   local bottom=y+1;while bottom<L.height and (L:midAt(x,bottom)==0x36c or L:midAt(x,bottom)==0x374)do bottom=bottom+1 end
   if bottom+1<L.height and L:midAt(x,bottom)==0x373 and L:midAt(x,bottom+1)==0x372 then
    local left=x-1;while left>=0 and L:midAt(left,bottom)==0x369 and L:midAt(left,bottom+1)==0x371 do left=left-1 end
    if left>=0 and L:midAt(left,bottom)==0x368 and L:midAt(left,bottom+1)==0x370 then
     local o={kind='silphLCounter',x=left,y=y,w=(x-left+1)*16,h=(bottom-y+2)*16,cells={}};objects[#objects+1]=o
     for yy=0,bottom-y-1 do claim(o,x-left,yy);shadow(x+1,y+yy)end
     for xx=0,x-left do for yy=bottom-y,bottom-y+1 do claim(o,xx,yy)end;shadow(left+xx,bottom+2)end
     shadow(x+1,bottom);shadow(x+1,bottom+1);shadow(x+1,bottom+2)
     -- The original top cell contains a strip of wall behind the counter.
     objects[#objects+1]={kind='silphWallCourse',x=x,y=y-1,top=0x330,bottom=0x338}
     mask[(y-1)*L.width+x+1]={mid=0,void=true,separateSurface=true}
    end
   end
  end
  if L:midAt(x,y)==0x378 and x+5<L.width and y+6<L.height then
   local rows={{0x378,0x379,0x37a,0x396,0x379,0x37a},{0x2b8,0x2b9,0x2ba,0x397,0x2b9,0x2ba},
    {0x380,0x381,0x382,0x2bb,0x2b9,0x2ba},{false,false,false,0x2c3,0x2b9,0x398},
    {0x396,0x379,0x37a,0x2b8,0x2b9,0x2c4},{0x397,0x2b9,0x2ba,0x2b8,0x2b9,0x2ba},
    {0x380,0x381,0x382,0x380,0x381,0x382}}
   local valid=true
   for yy,row in ipairs(rows)do for xx,m in ipairs(row)do if m and L:midAt(x+xx-1,y+yy-1)~=m then valid=false end end end
   if valid then
    local o={kind='silphUCounter',x=x,y=y,w=96,h=112,cells={}};objects[#objects+1]=o
    for yy,row in ipairs(rows)do for xx,m in ipairs(row)do if m then claim(o,xx-1,yy-1)end end end
    for yy=0,6 do shadow(x+6,y+yy)end
   end
  end
 end end
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local function flood(w,h,clear)
 local empty,queue={},{};local function seed(x,y)local k=y*w+x;if clear[k]and not empty[k]then empty[k]=true;queue[#queue+1]=k end end
 for x=0,w-1 do seed(x,0);seed(x,h-1)end;for y=0,h-1 do seed(0,y);seed(w-1,y)end
 local i=1;while queue[i]do local k=queue[i];i=i+1;local x,y=k%w,math.floor(k/w)
  if x>0 then seed(x-1,y)end;if x<w-1 then seed(x+1,y)end;if y>0 then seed(x,y-1)end;if y<h-1 then seed(x,y+1)end
 end
 return function(x,y)return x>=0 and y>=0 and x<w and y<h and not empty[y*w+x]end
end
function S.build(out,objects,L,ts,ox,oz,contacts)
 if not cfg().enabled then return end
 local B=V.require('BuildingMesh');local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local c=cfg()
 for _,o in ipairs(objects)do if o.kind=='silphLCounter'or o.kind=='silphUCounter'then
  local x,z=(o.x+ox)*16,(o.y+oz)*16;local H=o.kind=='silphLCounter'and c.receptionHeight or c.workHeight
  local function owned(s,t)return s>=0 and t>=0 and s<o.w and t<o.h and o.cells[math.floor(t/16)*(o.w/16)+math.floor(s/16)]end
  local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local donors={[0x374]=0x36c,[0x2bb]=0x2b8,[0x2c3]=0x2b8,[0x2c4]=0x2ba,[0x396]=0x378,[0x397]=0x2b8,[0x398]=0x2ba}
  local function plain(s,t)local m,u,v=source(s,t);return donors[m]or m,u,v end
  local bg={};for _,m in ipairs({0x334,0x335,0x336})do for v=0,15 do for u=0,15 do bg[rgb(B.pixel(ts,m,u,v))]=true end end end
  local clear={};for t=0,o.h-1 do for s=0,o.w-1 do local m,u,v=plain(s,t);local r,g,b,a=B.pixel(ts,m,u,v);clear[t*o.w+s]=not owned(s,t)or a<.5 or bg[rgb(r,g,b)]end end
  local inside=flood(o.w,o.h,clear)
  local function front(s,t)
   if not owned(s,t)then return end;local m,_,v=source(s,t)
   if m==0x370 or m==0x371 or m==0x372 then return 16,v end
   if m==0x380 or m==0x381 or m==0x382 then if v<8 then return 8,v end end
  end
  local function top(s,t)
   if not owned(s,t)or not inside(s,t)or front(s,t)then return false end
   local m,_,v=source(s,t)
   if m==0x364 and v<8 then return false end
   if (m==0x380 or m==0x381 or m==0x382)and v>=8 then return false end
   return true
  end
  local vv=P.build(ts,o.w,o.h,plain,top,0,o.h,1,nil,function(s,t)return{x+s,H,z+t}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
  -- Close only the actual contour. Empty space inside either counter stays open.
  for t=0,o.h-1 do for s=0,o.w-1 do
   if top(s,t)then
    local m,u,v=plain(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5);local a,b=x+s,z+t
    if not top(s-1,t)then G.quad(out,{a,H,b},{a,H,b+1},{a,0,b+1},{a,0,b},uv,c.sideShade)end
    if not top(s+1,t)then G.quad(out,{a+1,H,b+1},{a+1,H,b},{a+1,0,b},{a+1,0,b+1},uv,c.sideShade)end
    if not top(s,t-1)then G.quad(out,{a+1,H,b},{a,H,b},{a,0,b},{a+1,0,b},uv,c.sideShade)end
    if not top(s,t+1)and not front(s,t+1)then G.quad(out,{a,H,b+1},{a+1,H,b+1},{a+1,0,b+1},{a,0,b+1},uv,c.sideShade)end
    if (s%8==4)and not top(s,t+1)then contacts[#contacts+1]={a,b+1,4,c.contactRadius,c.contactStrength}end
   elseif owned(s,t)and inside(s,t)then
    local span,v=front(s,t)
    if span then
     local m,u,sy=source(s,t);local a,b=x+s,z+t-v;local h0,h1=H*(span-v)/span,H*(span-v-1)/span
     G.quad(out,{a,h0,b},{a+1,h0,b},{a+1,h1,b},{a,h1,b},G.uv(ts,m,u,sy,u+1,sy+1,.5),1)
    end
   end
  end end
  -- Devices/clipboards retain native pixels; subtract only matching donor pixels.
  for dy=0,o.h/16-1 do for dx=0,o.w/16-1 do if o.cells[dy*(o.w/16)+dx]then
   local m=L:midAt(o.x+dx,o.y+dy)
   if m==0x374 or m==0x2bb or m==0x2c4 or m==0x396 or m==0x398 then
    local dh=(m==0x2bb or m==0x396)and 32 or 16;local base=m==0x2bb and 29 or m==0x396 and 23 or 16
    local function src(s,t)return source(dx*16+s,dy*16+t)end
    local clear={};for t=0,dh-1 do for s=0,15 do local sm,u,v=src(s,t);local r,g,b,a=B.pixel(ts,sm,u,v);clear[t*16+s]=a<.5 or rgb(r,g,b)==rgb(B.pixel(ts,donors[sm]or sm,u,v))end end
    local cut=flood(16,dh,clear)
    local vv=P.build(ts,16,dh,src,function(s,t)return t<base and cut(s,t)end,0,dh,1,nil,function(s,t)return{x+dx*16+s,H+(base-t)*c.deviceScale,z+dy*16+base}end,.5)
    for _,v in ipairs(vv)do out[#out+1]=v end
   end
  end end end
 end end
end
return S
