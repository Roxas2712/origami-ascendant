-- The city's white crater and masonry have their own native atlas family.
-- Solid rock contours are separate from walkable white paving and stairs.
local V=...
local M={cache=setmetatable({},{__mode='k'}),railMasks=setmetatable({},{__mode='k'})}
local rocks={};for _,m in ipairs({0x2cd,0x2ce,0x2d0,0x2d1,0x2d2,0x2d3,0x2d4,0x2d6,0x2d8,0x2d9,
 0x2da,0x2db,0x2dc,0x2e0,0x2e1,0x2e2,0x2eb,0x2ec,0x2ed,0x2f3,0x2fb,0x2fd})do rocks[m]=true end
local caps={[0x2d0]=true,[0x2d1]=true,[0x2d2]=true,[0x2d9]=true,[0x2db]=true,[0x2dc]=true,[0x2ec]=true}
local rails={};for _,m in ipairs({0x240,0x241,0x242,0x243,0x246,0x247,0x24e,0x24f,0x254,0x255,0x256,0x257,
 0x25c,0x25d,0x25e,0x25f,0x262,0x263,0x264,0x265,0x266,0x267,0x26e,0x26f})do rails[m]=true end
local capColors={[0xffffff]=true,[0xefefd6]=true,[0xdedeb5]=true,[0x63637b]=true}
local railColors={[0xffffff]=true,[0xefefd6]=true,[0xdedeb5]=true,[0xb5b594]=true,[0x63637b]=true,[0x424a6b]=true,[0x84848c]=true}
local function rgb(ts,m,x,y)
 local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y)
 return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)
end
function M.applies(d)
 return d.id=='EM_SOOTOPOLIS_CITY'and d.pair=='general__sootopolis'
  and V.require('DioramaConfig').sootopolisCrater.enabled
  and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled
  and V.require('Camera').projection()=='perspective'
end
function M.plan(d,excluded)
 local p={};if not M.applies(d)then return p end
 local L=d.midLayout
 for y=0,L.height-1 do for x=0,L.width-1 do local k=y*L.width+x+1;local c=L:cellAt(x,y)
  if c.coll==7 and not(excluded and excluded[k])then
   if rocks[c.mid]then p[k]='rock'elseif rails[c.mid]then p[k]='rail'elseif c.mid==0x280 then p[k]='marker'end
  end
 end end
 -- The native 229 tiles below the front beam are walkable: this is an
 -- overhead gateway, not a curb to extrude across the approach.
 if L:midAt(31,16)==0x221 and L:midAt(31,15)==0x25b and L:midAt(31,17)==0x229 then
  for y=15,18 do for x=29,33 do if not(excluded and excluded[y*L.width+x+1])then p[y*L.width+x+1]='portal'end end end
 end
 return p
end
local function cross(a,b,c)return(b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])end
function M.polygon(ts,m)
 local cache=M.cache[ts]or{};M.cache[ts]=cache;if cache[m]then return cache[m]end
 if caps[m]then cache[m]={{0,0},{16,0},{16,16},{0,16}};return cache[m]end
 local points,seen={},{}
 for y=0,15 do for x=0,15 do local c=rgb(ts,m,x,y)
  if c==0xadad9c or c==0x94947b then
   -- One native texel of pale rim belongs to the rock contour.
   for _,q in ipairs({{x-1,y-1},{x+2,y-1},{x+2,y+2},{x-1,y+2}})do
    local a,b=math.max(0,math.min(16,q[1])),math.max(0,math.min(16,q[2]));local k=b*17+a
    if not seen[k]then seen[k]=true;points[#points+1]={a,b}end
   end
  end
 end end
 table.sort(points,function(a,b)return a[1]==b[1]and a[2]<b[2]or a[1]<b[1]end)
 local lo,hi={},{}
 for _,p in ipairs(points)do while #lo>=2 and cross(lo[#lo-1],lo[#lo],p)<=0 do lo[#lo]=nil end;lo[#lo+1]=p end
 for i=#points,1,-1 do local p=points[i];while #hi>=2 and cross(hi[#hi-1],hi[#hi],p)<=0 do hi[#hi]=nil end;hi[#hi+1]=p end
 local poly={};for i=1,#lo-1 do poly[#poly+1]=lo[i]end;for i=1,#hi-1 do poly[#poly+1]=hi[i]end
 cache[m]=poly;return poly
end
function M.contains(poly,x,y)
 if #poly<3 then return false end
 for i,a in ipairs(poly)do if cross(a,poly[i%#poly+1],{x,y})<-.001 then return false end end
 return true
end
function M.railCap(ts,m,x,y)
 local all=M.railMasks[ts]or{};M.railMasks[ts]=all
 if not all[m]then local mask={};for py=0,15 do for px=0,15 do mask[py*16+px+1]=capColors[rgb(ts,m,px,py)]or false end end;all[m]=mask end
 return all[m][y*16+x+1]
end
function M.portalRole(ts,L,x,y)
 if y<32 then return'back'end
 local mid=L:midAt(29+math.floor(x/16),15+math.floor(y/16))
 if not railColors[rgb(ts,mid,x%16,y%16)]then return end
 if y<44 then return'beam'end
 if x<16 or x>=64 then return'post'end
end
function M.portalPoint(role,x,y)
 local c=V.require('DioramaConfig').sootopolisCrater;local scale=V.require('Billboard').heightScale()
 if role=='back'then return{x,(32-y)*scale,32}end
 if role=='post'then return{x,(64-y)/20*c.portalPostHeight*scale,64}end
 return{x,(c.portalPostHeight+44-y)*scale,64}
end
function M.marker(ts,m,x,y)
 local c=rgb(ts,m,x,y)
 return c~=0xdeb5a5 and c~=0xbd948c and c~=0xefd6ce and c~=0x9c7373 and c~=0x845a5a and c~=0x634252
end
function M.floor(out,d,ts,x,y,ox,oz,kind)
 local G=V.require('WorldGeometry');local mid=d.midLayout:midAt(x,y)
 if kind=='rock'or kind=='marker'or kind=='portal'and y<17 then
  local a,b=(x+ox)*16,(y+oz)*16
  G.quad(out,{a,0,b},{a+16,0,b},{a+16,0,b+16},{a,0,b+16},G.uv(ts,kind=='rock'and mid or 0x71),1)
  return
 end
 local vv=V.require('PaperSprite').build(ts,16,16,function(px,py)
  if kind=='marker'or kind=='portal'and M.portalRole(ts,d.midLayout,(x-29)*16+px,(y-15)*16+py)then return 0x71,px,py end
  return kind=='rail'and railColors[rgb(ts,mid,px,py)]and 0x2d9 or mid,px,py
 end,function()return true end,0,0,1,nil,function(px,py)return{(x+ox)*16+px,0,(y+oz)*16+py}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
end
function M.build(out,d,ts,ox,oz,plan,contacts)
 local G=V.require('WorldGeometry');local L=d.midLayout;local C=V.require('DioramaConfig').sootopolisCrater
 local function occupied(wx,wz,kind)
  local x,y=math.floor(wx/16),math.floor(wz/16)
  if x<0 or y<0 or x>=L.width or y>=L.height or plan[y*L.width+x+1]~=kind then return false end
  local mid=L:midAt(x,y)
  return kind=='rail'and M.railCap(ts,mid,math.floor(wx%16),math.floor(wz%16))or kind=='rock'and M.contains(M.polygon(ts,mid),wx%16,wz%16)
 end
 for k,kind in pairs(plan)do
  local x,y=(k-1)%L.width,math.floor((k-1)/L.width);local mid=L:midAt(x,y)
  local xx,zz=(x+ox)*16,(y+oz)*16;local h=kind=='rock'and C.rockHeight or C.railHeight
  if kind=='rock'then
   local poly=M.polygon(ts,mid);local slot=ts.midToSlot[mid];local w,ht=ts.image:getDimensions();local ax,ay=slot%ts.cols*16,math.floor(slot/ts.cols)*16
   local function vertex(p)return{xx+p[1],h,zz+p[2],(ax+math.max(.02,math.min(15.98,p[1])))/w,(ay+math.max(.02,math.min(15.98,p[2])))/ht,1,0,0,0}end
   for i=2,#poly-1 do for _,p in ipairs({poly[1],poly[i],poly[i+1],poly[1],poly[i+1],poly[i+1]})do out[#out+1]=vertex(p)end end
   for i,a in ipairs(poly)do local b=poly[i%#poly+1];local dx,dz=b[1]-a[1],b[2]-a[2];local length=math.sqrt(dx*dx+dz*dz);local n=math.max(1,math.ceil(length));local t=0
    local function exposed(j)
     local f=(j+.5)/n;return not occupied(x*16+a[1]+dx*f+dz/length*.05,y*16+a[2]+dz*f-dx/length*.05,kind)
    end
    while t<n do if exposed(t)then local first=t;repeat t=t+1 until t==n or not exposed(t)
     local p,q={xx+a[1]+dx*first/n,zz+a[2]+dz*first/n},{xx+a[1]+dx*t/n,zz+a[2]+dz*t/n}
     G.quad(out,{p[1],h,p[2]},{q[1],h,q[2]},{q[1],0,q[2]},{p[1],0,p[2]},G.uv(ts,0x2e1,0,0,math.max(1,math.min(16,length*(t-first)/n)),16,.5),C.rockSideShade)
    else t=t+1 end end
   end
  elseif kind=='rail'then
   local uv=G.uv(ts,0x241,4,8,5,9,.5)
   for py=0,15 do local px=0;while px<16 do
    if M.railCap(ts,mid,px,py)then local first=px;repeat px=px+1 until px==16 or not M.railCap(ts,mid,px,py)
     G.quad(out,{xx+first,h,zz+py},{xx+px,h,zz+py},{xx+px,h,zz+py+1},{xx+first,h,zz+py+1},G.uv(ts,mid,first+.5,py+.5,px-.5,py+.5,0),1)
    else px=px+1 end
   end end
   for py=0,15 do for px=0,15 do if M.railCap(ts,mid,px,py)then
    local a,b=xx+px,zz+py
    for _,dir in ipairs({{0,-1},{0,1},{-1,0},{1,0}})do
     if not occupied(x*16+px+dir[1],y*16+py+dir[2],kind)then
      if dir[1]==0 then local z=b+(dir[2]>0 and 1 or 0);G.quad(out,{a,h,z},{a+1,h,z},{a+1,0,z},{a,0,z},uv,C.railSideShade)
      else local q=a+(dir[1]>0 and 1 or 0);G.quad(out,{q,h,b},{q,h,b+1},{q,0,b+1},{q,0,b},uv,C.railSideShade)end
     end
    end
   end end end
  elseif kind=='marker'then
   local vv=V.require('PaperSprite').build(ts,16,16,function(px,py)return mid,px,py end,
    function(px,py)return M.marker(ts,mid,px,py)end,0,16,C.markerScale,function()return 5 end,nil,.5)
   for _,v in ipairs(vv)do v[3]=v[3]+16;v[8]=v[8]+16;out[#out+1]=G.place(v,xx,zz)end
   if contacts then contacts[#contacts+1]={xx+8,zz+16,6,C.contactDepth,C.contactStrength}end
  elseif kind=='portal'and x==29 and y==15 then
   for _,role in ipairs({'back','beam','post'})do
    local vv=V.require('PaperSprite').build(ts,80,64,function(px,py)return L:midAt(29+math.floor(px/16),15+math.floor(py/16)),px%16,py%16 end,
     function(px,py)return M.portalRole(ts,L,px,py)==role end,0,0,1,function()return 3 end,
     function(px,py)return M.portalPoint(role,px,py)end,.5,function()return -1 end)
    for _,v in ipairs(vv)do out[#out+1]=G.place(v,(29+ox)*16,(15+oz)*16)end
   end
  end
 end
end
return M
