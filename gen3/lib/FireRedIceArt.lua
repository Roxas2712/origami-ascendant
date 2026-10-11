-- Native Seafoam material/object policy. Icefall has separate waterfall and
-- breakable-floor semantics and is intentionally not opted in by this profile.
local V=...;local A={cache=setmetatable({},{__mode='k'})}
local names={FR_SEAFOAM_ISLANDS_1F=true,FR_SEAFOAM_ISLANDS_B1F=true,FR_SEAFOAM_ISLANDS_B2F=true,FR_SEAFOAM_ISLANDS_B3F=true,FR_SEAFOAM_ISLANDS_B4F=true}
function A.profile(d)return d and (d.renderPair or d.pair)=='general__rom_082d4e24'and names[d.id]end
local rocks={[0x282]=0x282,[0x283]=0x283,[0x29f]=0x29f,[0x2a7]=0x2a7,[0x2b6]=0x283,[0x370]=0x283,[0x371]=0x283,[0x377]=0x283}
function A.rock(m)return rocks[m]~=nil end
function A.ladderUpper(m)return m==0x28e or m==0x2b5 end
function A.floorMid(m,ts)
 if m==0x2b6 or m==0x2b5 then return 0x2d1 end
 if A.rock(m)or m==0x2b7 then return ts and A.floorDonor(ts,m)or 0x281 end
 if m==0x28e or m==0x2cd then return 0x281 end
 return m
end
local function color(ts,m,x,y)local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y);return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local function cache(ts)
 local c=A.cache[ts];if c then return c end
 c={floor={},water={},masks={},shores={}};A.cache[ts]=c
 for y=0,15 do for x=0,15 do c.floor[color(ts,0x281,x,y)]=true;c.water[color(ts,0x30c,x,y)]=true end end
 return c
end
function A.mask(ts,m)
 local c=cache(ts);if c.masks[m]then return c.masks[m]end
 local ink={count=0};for y=0,15 do for x=0,15 do local v=color(ts,m,x,y);local yes=not c.floor[v]and not c.water[v];ink[y*16+x+1]=yes;if yes then ink.count=ink.count+1 end end end
 c.masks[m]=ink;return ink
end
function A.shore(ts,m)
 local c=cache(ts);if c.shores[m]~=nil then return c.shores[m]end
 local yes=false;for y=0,15 do for x=0,15 do if c.water[color(ts,m,x,y)]then yes=true end end end
 c.shores[m]=yes;return yes
end
function A.rockPixel(ts,m,x,y)return not cache(ts).floor[color(ts,rocks[m]or m,x,y)]end
-- The round stones have several snow/earth transition variants. Match a
-- native floor-only tile against their exposed background instead of painting
-- a generic grey square beneath every variant. No new texture is generated.
function A.floorDonor(ts,m)
 local c=cache(ts);c.donors=c.donors or{};if c.donors[m]then return c.donors[m]end
 if not c.floors then
  c.floors={};local allowed={};for v in pairs(c.floor)do allowed[v]=true end
  for _,mid in ipairs{0x291,0x2fc}do for y=0,15 do for x=0,15 do allowed[color(ts,mid,x,y)]=true end end end
  for mid in pairs(ts.midToSlot)do if mid>=0x281 then local yes=true
   for y=0,15 do for x=0,15 do if not allowed[color(ts,mid,x,y)]then yes=false end end end
   if yes then c.floors[#c.floors+1]=mid end
  end end
  table.sort(c.floors)
 end
 local function object(x,y)
  if m==0x2b7 then return A.ladderPixel(ts,x,y+16,function(s,t)return t<16 and 0x28e or m,s,t%16 end)end
  return A.rockPixel(ts,m,x,y)
 end
 local best,score=0x281,-1
 for _,mid in ipairs(c.floors)do local matches=0
  for y=0,15 do for x=0,15 do if not object(x,y)and color(ts,m,x,y)==color(ts,mid,x,y)then matches=matches+1 end end end
  if matches>score then best,score=mid,matches end
 end
 c.donors[m]=best;return best
end
function A.ladderPixel(ts,x,y,source)
 return V.require('CaveObjectArt').ladderPixel(ts,x,y,source,{0xffefa5,0xe6ce5a,0x423a4a,0x423a4a},{0,15,0,31})
end
function A.objects(out,d,ts,ox,oz,contacts,height)
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local L=d.midLayout;local C=V.require('DioramaConfig').terrain.frTerracedCaves
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if (A.rock(m)and m~=0x2a7)or m==0x2cd then
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
