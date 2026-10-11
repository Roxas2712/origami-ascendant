-- Diglett tunnel shell from its native earth/rock contours. Tanoby Key shares
-- this atlas but has a separate carved-wall/Strength layout and is excluded.
local V=...;local R={masks=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').terrain.frDiglettCave end
function R.profile(d)return d and cfg().enabled and (d.renderPair or d.pair)=='general__rom_082d4e0c'and tonumber(d.mapType)==4 and(d.id or''):match('^FR_DIGLETTS_CAVE_')and true or nil end
local function active(d)return R.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
function R.kind(d,c)
 if not active(d)or not c or(c.coll~=7 and c.coll~=255)or c.mid<0x280 or c.mid==0x282 or c.mid==0x283 or(c.mid>=0x2c8 and c.mid<=0x2ca)then return end
 return'frDiglettWall'
end
function R.height()return cfg().wallHeight end
function R.skylights(d,candidates,settings)
 if not R.profile(d)or d.id~='FR_DIGLETTS_CAVE_B1F' then return end
 -- This long, narrow tunnel needs coverage along its north-west/south-east
 -- route. Random dart placement left its northern stretch without a shaft.
 -- Candidates have already passed the floor and entrance clearance checks.
 local ordered={};for i,p in ipairs(candidates)do ordered[i]=p end
 table.sort(ordered,function(a,b)if a.x+a.z==b.x+b.z then return a.x<b.x end;return a.x+a.z<b.x+b.z end)
 local count=math.min(settings.max,math.max(settings.min,math.floor(V.require('PlaceEffects').floorCount(d)/80+.5)),#ordered)
 local out={}
 for i=1,count do
  local u=count==1 and .5 or .04+.92*(i-1)/(count-1)
  local p=ordered[math.floor(u*(#ordered-1))+1]
  if p then out[#out+1]=p end
 end
 return out
end
function R.lighting(d,result)
 -- Diglett's tunnel has no FLASH requirement. Keep its native earth and
 -- rock readable throughout the tunnel, also where no ceiling gap lands.
 -- Both field and battle use this same ambient; local beams stay additive.
 if not R.profile(d)or not result.cave or result.darkCave then return end
 local a=result.ambient
 result.ambient={math.max(a[1],.34),math.max(a[2],.33),math.max(a[3],.29)}
end
local floors={[0x946b42]=true,[0x736b5a]=true,[0x94946b]=true,[0xbdbd7b]=true}
local function color(ts,m,x,y)local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y);return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local function donor(m)
 if m==0x28f then return 0x299 end
 return m
end
function R.mask(ts,m)
 local cache=R.masks[ts];if not cache then cache={};R.masks[ts]=cache end
 if cache[m]then return cache[m]end
 -- Brown earth is unique, but its stipples also occur in rock highlights.
 -- Only floor-colored pixels connected to actual brown earth are removed.
 local outside,queue={},{}
 for y=0,15 do for x=0,15 do if color(ts,m,x,y)==0x946b42 then local k=y*16+x+1;outside[k]=true;queue[#queue+1]={x,y}end end end
 for _,p in ipairs(queue)do for _,v in ipairs{{1,0},{-1,0},{0,1},{0,-1}}do local x,y=p[1]+v[1],p[2]+v[2];local k=y*16+x+1
  if x>=0 and x<16 and y>=0 and y<16 and not outside[k]and floors[color(ts,m,x,y)]then outside[k]=true;queue[#queue+1]={x,y}end
 end end
 local mask={count=0,bottom=0};for i=1,256 do mask[i]=not outside[i];if mask[i]then mask.count=mask.count+1;mask.bottom=math.floor((i-1)/16)+1 end end
 cache[m]=mask;return mask
end
local stamps=setmetatable({},{__mode='k'})
function R.stamp(out,d,ts,x,y,ox,oz)
 local L=d.midLayout;local c=L:cellAt(x,y);if not R.kind(d,c)then return false end
 local G=V.require('WorldGeometry');local h=R.height();local m=donor(c.mid);local mask=R.mask(ts,m);local xx,zz=(x+ox)*16,(y+oz)*16
 -- Repeating cave borders reuse exactly the same native cutout. Its
 -- geometry depends on this tile, its four edge neighbours and the current
 -- height/shade, not on its absolute position. Keep atlas-local templates
 -- bounded; native script changes select a different neighbourhood key.
 local neighbours={};local key={m,h,cfg().sideShade}
 for _,dir in ipairs{{0,1},{0,-1},{1,0},{-1,0}}do
  local other=L:cellAt(x+dir[1],y+dir[2]);local n=R.kind(d,other)and donor(other.mid)or -1
  key[#key+1]=n;neighbours[#neighbours+1]=n>=0 and R.mask(ts,n)or false
 end
 key=table.concat(key,':');local cache=stamps[ts]
 if not cache then cache={count=0};stamps[ts]=cache end
 local template=cache[key]
 if template then
  for _,v in ipairs(template)do out[#out+1]={v[1]+xx,v[2],v[3]+zz,v[4],v[5],v[6],v[7],v[8],v[9]}end
  return true
 end
 local start=#out+1
 G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,0x281),1)
 local first=#out+1
 local function occupied(wx,wz)
  local sx,sy=wx-x*16,wz-y*16
  if sx>=0 and sx<16 and sy>=0 and sy<16 then return mask[sy*16+sx+1]end
  local n
  if sy>=16 then n=neighbours[1]elseif sy<0 then n=neighbours[2]elseif sx>=16 then n=neighbours[3]else n=neighbours[4]end
  return n and n[(sy%16)*16+sx%16+1]
 end
 if mask.count==256 then G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m,0,0,16,16,.5),1)
 else for sy=0,15 do local sx=0;while sx<16 do if mask[sy*16+sx+1]then local a=sx;repeat sx=sx+1 until sx==16 or not mask[sy*16+sx+1]
  G.quad(out,{xx+a,h,zz+sy},{xx+sx,h,zz+sy},{xx+sx,h,zz+sy+1},{xx+a,h,zz+sy+1},G.uv(ts,m,a,sy,sx,sy+1,.5),1)
 else sx=sx+1 end end end end
 for sy=0,15 do for sx=0,15 do if mask[sy*16+sx+1]then
  for _,dir in ipairs{{0,1},{0,-1},{1,0},{-1,0}}do
   if not occupied(x*16+sx+dir[1],y*16+sy+dir[2])then
    local a,b,u;if dir[1]==0 then local z=zz+sy+(dir[2]>0 and 1 or 0);a={xx+sx,z};b={xx+sx+1,z};u=sx
    else local xp=xx+sx+(dir[1]>0 and 1 or 0);a={xp,zz+sy};b={xp,zz+sy+1};u=sy end
    G.quad(out,{a[1],h,a[2]},{b[1],h,b[2]},{b[1],0,b[2]},{a[1],0,a[2]},G.uv(ts,0x299,u,0,u+1,16,.5),cfg().sideShade)
   end
  end
 end end end
 for i=first,#out do out[i][9]=-2 end
 if cache.count<256 then
  template={};for i=start,#out do local v=out[i];template[#template+1]={v[1]-xx,v[2],v[3]-zz,v[4],v[5],v[6],v[7],v[8],v[9]}end
  cache[key]=template;cache.count=cache.count+1
 end
 return true
end
function R.floor(out,d,ts,x,y,ox,oz)
 if not active(d)then return false end
 local m=d.midLayout:midAt(x,y)
 if m~=0x282 and m~=0x283 and m~=0x297 then return false end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,0x281),1);return true
end
function R.objects(out,d,ts,ox,oz,contacts)
 if not active(d)then return end
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local L=d.midLayout;local C=cfg()
 local function place(v,x,z)for _,p in ipairs(v)do out[#out+1]=G.place(p,(x+ox)*16,(z+oz)*16)end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x282 or m==0x283 then
   -- The native tile has earth below the stone. Anchor the visible cutout
   -- itself to the contact plane instead of raising that empty margin.
   local ink=R.mask(ts,m)
   place(P.build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return ink[t*16+s+1]end,0,ink.bottom,C.rockScale,function()return 1 end,nil,.5),x,y+1)
   contacts[#contacts+1]={(x+ox)*16+8,(y+oz+1)*16,C.rockContactWidth,C.contactDepth,C.contactStrength}
  end
 end end
 for _,w in ipairs(d.warps or{})do local lower=L:midAt(w.x,w.y);local upper=L:midAt(w.x,w.y-1)
  if upper==0x28f and lower==0x297 then
   local function source(s,t)return t<16 and upper or lower,s,t%16 end
   local A=V.require('CaveObjectArt');local colors={0x8c9cde,0x636b8c,0xa5b5e6,0x42424a}
   local function inside(s,t)return A.ladderPixel(ts,s,t,source,colors,{0,15,0,31})end
   local lo,hi=32,0;for t=0,31 do for s=0,15 do if inside(s,t)then lo=math.min(lo,t);hi=math.max(hi,t+1)end end end
   assert(hi>lo,'missing native ladder')
   place(P.build(ts,16,32,source,inside,0,32,1,function()return 1 end,function(s,t)local f=(t-lo)/(hi-lo);return{s,C.wallHeight*(1-f),-16*(1-f)+C.ladderOffset}end,.5),w.x,w.y+1)
  end
 end
end
return R
