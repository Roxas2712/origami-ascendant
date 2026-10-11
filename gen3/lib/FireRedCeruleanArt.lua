-- Native Cerulean Cave material/object policy for the shared closed shell.
-- Unlike brown caves, its floor and boulders share highlight palette entries.
local V=...;local A={cache=setmetatable({},{__mode='k'})}
local names={FR_CERULEAN_CAVE_1F=true,FR_CERULEAN_CAVE_2F=true,FR_CERULEAN_CAVE_B1F=true}
function A.profile(d)return d and (d.renderPair or d.pair)=='general__rom_082d4e54'and names[d.id]end
function A.rock(m)return m==0x282 or m==0x283 or m==0x29f or m==0x2a7 or m==0x2b6 end
function A.stair(m)return m==0x91 end
function A.ladderUpper(m)return m==0x28e or m==0x2b5 end
function A.floorMid(m)return (m==0x2b6 or m==0x2b5)and 0x2d1 or (A.rock(m)or m==0x28e)and 0x281 or m end
local function color(ts,m,x,y)local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y);return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local function cache(ts)
 local c=A.cache[ts];if c then return c end
 c={floor={},water={},masks={},rows={},shores={}};A.cache[ts]=c
 for y=0,15 do for x=0,15 do c.floor[color(ts,0x281,x,y)]=true;c.water[color(ts,0x12b,x,y)]=true end end
 return c
end
function A.mask(ts,m)
 local c=cache(ts);if c.masks[m]then return c.masks[m]end
 local a={count=0};for y=0,15 do for x=0,15 do local v=color(ts,m,x,y);local yes=not c.floor[v]and not c.water[v];a[y*16+x+1]=yes;if yes then a.count=a.count+1 end end end
 c.masks[m]=a;return a
end
function A.shore(ts,m)
 local c=cache(ts);if c.shores[m]~=nil then return c.shores[m]end
 local found=false;for y=0,15 do for x=0,15 do if c.water[color(ts,m,x,y)]then found=true end end end
 c.shores[m]=found;return found
end
function A.rockPixel(ts,m,x,y)
 -- Preserve every pixel enclosed by the native dark boulder outline,
 -- including pale highlights shared with floor speckles. 2b6 overlays the
 -- 283 boulder on a moss lip, so its object silhouette comes from 283.
 if m==0x2b6 then m=0x283 end
 local c=cache(ts);local rows=c.rows[m]
 if not rows then
  rows={};for t=0,15 do local lo,hi=16,-1;for s=0,15 do if color(ts,m,s,t)==0x42424a then lo=math.min(lo,s);hi=math.max(hi,s)end end;rows[t+1]={lo,hi}end
  c.rows[m]=rows
 end
 return x>=rows[y+1][1]and x<=rows[y+1][2]
end
local rails={[0xcece6b]=true,[0x7b844a]=true,[0xefefa5]=true,[0xadad5a]=true}
function A.ladderPixel(ts,x,y,source)
 local function read(s,t)if s<0 or s>=16 or t<0 or t>=32 then return end;local m,u,v=source(s,t);return color(ts,m,u,v)end
 local c=read(x,y);if rails[c]then return true end
 return(c==0x101019 or c==0x42424a)and(rails[read(x-1,y)]or rails[read(x+1,y)]or rails[read(x,y-1)]or rails[read(x,y+1)])and true or false
end
function A.objects(out,d,ts,ox,oz,contacts,height)
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local L=d.midLayout;local C=V.require('DioramaConfig').terrain.frTerracedCaves
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if A.rock(m)and m~=0x2a7 then
   local tall=m==0x29f and L:midAt(x,y+1)==0x2a7;local rows=tall and 32 or 16;local base=y+rows/16
   local function source(s,t)return t<16 and m or 0x2a7,s,t%16 end
   local v=P.build(ts,16,rows,source,function(s,t)local mid,u,w=source(s,t);return A.rockPixel(ts,mid,u,w)end,0,rows,C.rockScale,function()return 1 end,nil,.5)
   local h=height(d,x*16,(base-1)*16)
   for _,p in ipairs(v)do local q=G.place(p,(x+ox)*16,(base+oz)*16);q[2]=q[2]+h;out[#out+1]=q end
   contacts[#contacts+1]={(x+ox)*16+8,(base+oz)*16,5,C.contactDepth,C.contactStrength,h}
  end
 end end
end
return A
