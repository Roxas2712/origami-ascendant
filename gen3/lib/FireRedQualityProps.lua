-- Explicit native truck/cargo, open canopy, statues and bollards. No gameplay
-- cells or collisions change. Per-pixel floors retain unclaimed native art.
local V=...
local P={}
local function owns(p,x,y)return p.mask[y+1]:sub(x+1,x+1)=='X'end
function P.plan(def)
 local result={items={},mask={}};local L=def.midLayout
 local id=def.id or def.name
 for _,p in ipairs(V.data('FireRedQualityProps'))do
  if id==p.map then
   for z=0,L.height-p.h do for x=0,L.width-p.w do
    if L:midAt(x,z)==p.mids[1]then
     local match=true
     for dz=0,p.h-1 do for dx=0,p.w-1 do if L:midAt(x+dx,z+dz)~=p.mids[dz*p.w+dx+1]then match=false end end end
     if match then
      local item={p=p,x=x,z=z};result.items[#result.items+1]=item
      for dz=0,p.h-1 do for dx=0,p.w-1 do result.mask[(z+dz)*L.width+x+dx+1]=item end end
     end
    end
   end end
  end
 end
 return result
end
function P.floor(out,def,ts,x,z,ox,oz,item)
 local p=item.p;local G=V.require('WorldGeometry');local mid=def.midLayout:midAt(x,z)
 local localX,localY=(x-item.x)*16,(z-item.z)*16
 local xx,zz=(x+ox)*16,(z+oz)*16
 for sy=0,15 do local sx=0
  while sx<16 do
   local first=sx;local masked=owns(p,localX+sx,localY+sy)
   repeat sx=sx+1 until sx>=16 or owns(p,localX+sx,localY+sy)~=masked
   local donor=masked and p.ground or mid
   if masked and p.kind=='canopy'then donor=def.midLayout:midAt(x,item.z+2)end
   G.quad(out,{xx+first,0,zz+sy},{xx+sx,0,zz+sy},{xx+sx,0,zz+sy+1},{xx+first,0,zz+sy+1},G.uv(ts,donor,first,sy,sx,sy+1,.5),1)
  end
 end
end
function P.build(out,def,ts,ox,oz,contacts,plan)
 local G=V.require('WorldGeometry');local S=V.require('PaperSprite');local B=V.require('Billboard')
 for _,item in ipairs(plan.items)do
  local p=item.p;local w,h=p.w*16,p.h*16;local xx,zz=(item.x+ox)*16,(item.z+oz)*16
  local scale=p.kind=='truck'and .75 or p.kind=='crate'and .7 or p.kind=='stone'and .60 or 1
  local function source(x,y)return p.mids[math.floor(y/16)*p.w+math.floor(x/16)+1],x%16,y%16 end
  local function transform(x,y)
   if p.kind=='canopy'then
    if y<12 then return{x,40,(y/12)*24}end
    if y<16 then return{x,40-(y-12),24}end
    return{x,(32-y)*36/16,24}
   end
   return{x,(h-y)*scale*B.heightScale(),h-2}
  end
  local vertices=S.build(ts,w,h,source,function(x,y)return owns(p,x,y)end,0,h,1,function()return 5 end,transform,.5)
  for _,v in ipairs(vertices)do out[#out+1]=G.place(v,xx,zz)end
  if p.kind=='canopy'then
   -- Rear posts close the shelter's support footprint while leaving the
   -- central passage clear. Reuse the actual native front-leg texels.
   local rear=S.build(ts,w,h,source,function(x,y)return y>=16 and owns(p,x,y)end,0,h,1,function()return 5 end,
    function(x,y)return{x,(32-y)*36/16,0}end,.5)
   for _,v in ipairs(rear)do out[#out+1]=G.place(v,xx,zz)end
  else contacts[#contacts+1]={xx+w*.5,zz+h-2,w*.38,2,.14}end
 end
end
return P
