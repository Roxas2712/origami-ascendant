-- Independently bounded native machines, with a complete wall behind each.
local V=...;local S={}
local patterns={{0x37d,0x385,0x37e},{0x330,0x37b,0x383},{0x330,0x37c,0x384},{0x3ef,0x62,0x3f7}}
local function cfg()return V.require('DioramaConfig').interiors.silphEquipment end
function S.profile(d)return cfg().enabled and d.mapType==8 and (d.renderPair or d.pair)=='building__rom_082d4ecc'and(d.id or d.name or''):match('^FR_SILPH_CO_%d+F$')and d.midLayout end
function S.plan(d,objects,mask)
 if not S.profile(d)then return end;local L=d.midLayout
 for y=1,L.height-3 do for x=0,L.width-1 do for variant,p in ipairs(patterns)do
  if L:midAt(x,y)==p[1]and L:midAt(x,y+1)==p[2]and L:midAt(x,y+2)==p[3]then
   objects[#objects+1]={kind='silphMachine',x=x,y=y,variant=variant}
   objects[#objects+1]={kind='silphWallCourse',x=x,y=y,top=0x330,bottom=0x338}
   for dy=0,2 do mask[(y+dy)*L.width+x+1]={mid=dy==0 and 0 or 0x335,void=dy==0,separateSurface=true}end
  end
 end end end
 if cfg().cabinets then
  for y=1,L.height-3 do for x=0,L.width-2 do
   local rows={{0x38a,0x38b},{0x38c,0x38d},{0x38e,0x38f}};local ok=true
   for dy,row in ipairs(rows)do for dx,m in ipairs(row)do if L:midAt(x+dx-1,y+dy-1)~=m then ok=false end end end
   if ok then
    objects[#objects+1]={kind='silphMachine',x=x,y=y,width=32,cabinet=true}
    for dx=0,1 do
     objects[#objects+1]={kind='silphWallCourse',x=x+dx,y=y,top=0x330,bottom=0x338}
     for dy=0,2 do mask[(y+dy)*L.width+x+dx+1]={mid=dy==0 and 0 or 0x335,void=dy==0,separateSurface=true}end
    end
   end
  end end
 end
end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function S.build(out,objects,L,ts,ox,oz,contacts)
 if not cfg().enabled then return end
 local B=V.require('BuildingMesh');local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local c=cfg()
 for _,o in ipairs(objects)do if o.kind=='silphMachine'then
  local x,z=(o.x+ox)*16,(o.y+oz)*16;local base=40;local width=o.width or 16;local scale=c.heightScale*V.require('Billboard').heightScale()
  local clear,empty,queue={},{},{}
  local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  for t=0,47 do for s=0,width-1 do
   local m,u,v=source(s,t);local r,g,b,a=B.pixel(ts,m,u,v);local donor=t<16 and 0x330 or t<32 and 0x338 or 0x335
   clear[t*width+s]=t>=base or a<.5 or rgb(r,g,b)==rgb(B.pixel(ts,donor,u,v))
  end end
  local function seed(s,t)local k=t*width+s;if clear[k]and not empty[k]then empty[k]=true;queue[#queue+1]=k end end
  for s=0,width-1 do seed(s,0);seed(s,47)end;for t=0,47 do seed(0,t);seed(width-1,t)end
  local i=1;while queue[i]do local k=queue[i];i=i+1;local s,t=k%width,math.floor(k/width)
   if s>0 then seed(s-1,t)end;if s<width-1 then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t<47 then seed(s,t+1)end
  end
  local function inside(s,t)return s>=0 and s<width and t>=0 and t<base and not empty[t*width+s]end
  local vv=P.build(ts,width,48,source,inside,0,base,1,nil,function(s,t)return{x+s,(base-t)*scale,z+base}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
  -- Use the machine's edge texel for its thickness. No rectangular donor
  -- card and no black wedge fill around the front silhouette.
  for t=0,base-1 do for s=0,width-1 do if inside(s,t)then
   local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
   local a,b=x+s,z+base;local h0,h1=(base-t)*scale,(base-t-1)*scale
   if not inside(s-1,t)then G.quad(out,{a,h0,b-c.depth},{a,h0,b},{a,h1,b},{a,h1,b-c.depth},uv,c.sideShade)end
   if not inside(s+1,t)then G.quad(out,{a+1,h0,b},{a+1,h0,b-c.depth},{a+1,h1,b-c.depth},{a+1,h1,b},uv,c.sideShade)end
   if not inside(s,t-1)then G.quad(out,{a,h0,b-c.depth},{a+1,h0,b-c.depth},{a+1,h0,b},{a,h0,b},uv,c.capShade)end
   if not inside(s,t+1)then G.quad(out,{a,h1,b},{a+1,h1,b},{a+1,h1,b-c.depth},{a,h1,b-c.depth},uv,c.sideShade)end
  end end end
  contacts[#contacts+1]={x+width/2,z+base,width/2-1,c.contactRadius,c.contactStrength}
 end end
end
return S
