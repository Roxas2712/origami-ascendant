-- Freestanding signs and rails own only their native prop pixels. Side
-- fences follow Z; their joints share a foot line with the front sections.
local V=...
local F={}
function F.profile(def,mid)
 local id=tostring(def.id or def.name)
 if not id:match('^FR_') and not id:match('^SEVII_')then return nil end
 if not V.data('Shapes').outdoors(def)then return nil end
 local data=V.data('FireRedStandingProps')
 return data[tostring((def.renderPair or def.pair))..':'..string.format('%x',mid)]
  or ((def.renderPair or def.pair)=='general__rom_082d4b9c'and data['s'..string.format('%x',mid)])
  or data['p'..string.format('%x',mid)]
end
function F.mask(p,x,y)return x>=0 and x<16 and y>=0 and y<16 and p.mask[y+1]:sub(x+1,x+1)=='X'end
local floors=setmetatable({},{__mode='k'})
function F.floorSources(p,mid)
 local cached=floors[p];if cached then return cached end
 local result={}
 for y=0,15 do for x=0,15 do
  local m,sx,sy=mid,x,y
  if F.mask(p,x,y)then
   local found=false
   -- Use this tile's unoccluded row first: no grass pasted over paving,
   -- and the native curb remains on its original side of the rail.
   for d=1,15 do
    for _,xx in ipairs({x-d,x+d})do
     if xx>=0 and xx<16 and not F.mask(p,xx,y)then sx=xx;found=true;break end
    end
    if found then break end
   end
   if not found then m=p.ground end
  end
  result[y*16+x+1]={m,sx,sy}
 end end
 floors[p]=result;return result
end
function F.build(out,def,ts,x,y,ox,oz,contacts,replacement)
 local mid=replacement and replacement.mid or def.midLayout:midAt(x,y);local p=F.profile(def,mid)
 if not p or not V.require('DioramaConfig').billboards.enabled or V.require('Camera').projection()~='perspective'then return false end
 local G=V.require('WorldGeometry');local B=V.require('Billboard');local S=V.require('PaperSprite')
 local xx,zz=(x+ox)*16,(y+oz)*16;local city=(def.renderPair or def.pair)=='general__rom_082d4b9c'and mid>=0x300
 local foot=p.kind=='sign'and 15 or city and 14 or 13
 -- A raised whole tree has already claimed the composite's leaves. Draw
 -- its local ground once and reconstruct the native rail independently.
 if replacement then
  G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,replacement.ground),1)
 else
  local floor=F.floorSources(p,mid)
  -- Coalesce adjacent original/donor texels; do not turn every paving pixel
  -- into its own quad when a long city boundary uses hundreds of tiles.
  for sy=0,15 do
   local sx=0
   while sx<16 do
    local first=floor[sy*16+sx+1];local last=sx+1
    local nextPixel=last<16 and floor[sy*16+last+1]
    local step=nextPixel and nextPixel[1]==first[1]and nextPixel[3]==first[3]and nextPixel[2]-first[2]or 0
    if step~=0 and step~=1 then step=0 end
    while last<16 do
     local candidate=floor[sy*16+last+1]
     if candidate[1]~=first[1]or candidate[3]~=first[3]or candidate[2]~=first[2]+(last-sx)*step then break end
     last=last+1
    end
    local u0=first[2]+(step==0 and .5 or 0);local u1=step==0 and u0 or first[2]+last-sx
    G.quad(out,{xx+sx,0,zz+sy},{xx+last,0,zz+sy},{xx+last,0,zz+sy+1},{xx+sx,0,zz+sy+1},
     G.uv(ts,first[1],u0,first[3]+.5,u1,first[3]+.5,0),1)
    sx=last
   end
  end
 end
 local function ink(profile,m,sx,sy)
  if not F.mask(profile,sx,sy)then return false end
  -- Neutral bottom-row pixels are baked contact shadow, not sign legs.
  if p.kind=='sign'and sy>=12 then
   local r,g,b=V.require('BuildingMesh').pixel(ts,m,sx,sy)
   if math.abs(r-123/255)<.002 and math.abs(g-123/255)<.002 and math.abs(b-132/255)<.002 then return false end
  end
  return true
 end
 local a=p.axis or {0,16,0,0,0}
 if a[2]>a[1]then
  local front=S.build(ts,16,foot,function(sx,sy)return mid,sx,sy end,
   function(sx,sy)return sx>=a[1]and sx<a[2]and ink(p,mid,sx,sy)end,0,foot,1,
   function()return p.kind=='sign'and 5.25 or 5 end,function(sx,sy)return {sx,(foot-sy)*B.heightScale(),foot}end,.5)
  for _,v in ipairs(front)do out[#out+1]=G.place(v,xx,zz)end
  local c=V.require('DioramaConfig').contact
  contacts[#contacts+1]={xx+(a[1]+a[2])/2,zz+foot,(a[2]-a[1])/2,c.propRadius,c.strength}
 end
 if a[5]>a[4]then
  local rail=a[6];local donor=F.profile(def,rail)
  local side=S.build(ts,16,foot,function(sx,sy)return rail,sx,sy end,
   function(sx,sy)return F.mask(donor,sx,sy)end,0,foot,1,function()return 5 end,
   function(sx,sy)return {a[3],(foot-sy)*B.heightScale(),a[4]+sx/16*(a[5]-a[4])}end,.5)
  for _,v in ipairs(side)do out[#out+1]=G.place(v,xx,zz)end
  -- Give edge-on paper rails their native thickness. Metal posts keep
  -- separate pale caps; a continuous white cap would look like a wire.
  local function bar(y0,y1,z0,z1,sx,sy,width)
   local left,right=xx+a[3]-width/2,xx+a[3]+width/2
   local uv=G.uv(ts,rail,sx,sy,sx+1,sy+1,.5)
   G.quad(out,{left,y1,zz+z0},{right,y1,zz+z0},{right,y1,zz+z1},{left,y1,zz+z1},uv,5)
   G.quad(out,{left,y0,zz+z0},{right,y0,zz+z0},{right,y1,zz+z0},{left,y1,zz+z0},uv,5)
   G.quad(out,{left,y0,zz+z1},{left,y1,zz+z1},{right,y1,zz+z1},{right,y0,zz+z1},uv,5)
   G.quad(out,{left,y0,zz+z0},{left,y1,zz+z0},{left,y1,zz+z1},{left,y0,zz+z1},uv,5)
   G.quad(out,{right,y0,zz+z1},{right,y1,zz+z1},{right,y1,zz+z0},{right,y0,zz+z0},uv,5)
  end
  local h=(foot-3)*B.heightScale()
  if city then
   bar(h-1,h,a[4],a[5],3,4,1.4)
   bar(2,3,a[4],a[5],3,9,1.2)
   for z=a[4],a[5]-.01,8 do bar(0,h,z,math.min(a[5],z+1),0,7,1.6)end
  else
   for z=a[4]+1,a[5]-1,8 do
    local stop=math.min(a[5],z+5)
    bar(0,h-1,z,stop,4,7,2.8)
    bar(h-1,h,z,stop,4,3,2.8)
   end
   if rail==0xe7 then bar(4,5,a[4],a[5],0,9,1.2)end
  end
  local c=V.require('DioramaConfig').contact
  for z=a[4],a[5]-.01,4 do contacts[#contacts+1]={xx+a[3],zz+z,1.2,2,c.strength*.65}end
 end
 return true
end
return F
