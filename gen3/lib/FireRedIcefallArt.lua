-- Icefall's native ice, floor transitions and waterfall. Map scripts own
-- cracked floors, falls, sliding, field moves and all collision data.
local V=...;local A={cache=setmetatable({},{__mode='k'})}
local names={FR_FOUR_ISLAND_ICEFALL_CAVE_ENTRANCE=true,FR_FOUR_ISLAND_ICEFALL_CAVE_1F=true,FR_FOUR_ISLAND_ICEFALL_CAVE_B1F=true,FR_FOUR_ISLAND_ICEFALL_CAVE_BACK=true}
local aliases={[0x282]=0x282,[0x283]=0x283,[0x29f]=0x29f,[0x2a7]=0x2a7,[0x2b6]=0x283,
 [0x33f]=0x283,[0x342]=0x282,[0x344]=0x282,[0x347]=0x283,[0x34f]=0x283,
 [0x352]=0x282,[0x354]=0x282,[0x35c]=0x282,[0x35e]=0x282,[0x35f]=0x282,
 [0x362]=0x282,[0x363]=0x282,[0x370]=0x283,[0x371]=0x283,[0x372]=0x283,[0x373]=0x282}
local floors={0x281,0x291,0x2fc,0x2d0,0x2d1,0x2d2,0x2d3,0x2d4,0x2d5,0x2d6,0x2d8,0x2d9,0x2da,0x2db,0x2dc,0x2dd,0x2de,
 0x2e0,0x2e1,0x2e2,0x2e3,0x2e4,0x2e5,0x2f3,0x2f4,0x2f5,0x2f6,0x2f7,0x2f8,0x2f9,0x2fb,0x2fd,0x300,0x301,0x303,0x304,0x305,
 0x343,0x34a,0x34b,0x34c,0x353,0x360,0x361,0x364,0x368,0x369,0x36a,0x36b,0x36c}
local function base()return V.require('FireRedIceArt')end
function A.profile(d)return d and (d.renderPair or d.pair)=='general__rom_082d4e24'and names[d.id]end
function A.rock(m)return aliases[m]~=nil end
function A.ladderUpper(m)return m==0x28e or m==0x28f or m==0x2b5 end
function A.mask(ts,m)return base().mask(ts,m)end
function A.shore(ts,m)return base().shore(ts,m)end
function A.ladderPixel(...)return base().ladderPixel(...)end
function A.rockPixel(ts,m,x,y)return base().rockPixel(ts,aliases[m]or m,x,y)end
local function color(ts,m,x,y)local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y);return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function A.floorMid(m,ts)
 if A.ladderUpper(m)then return 0x281 end
 if not A.rock(m)then return m end
 local c=A.cache[ts];if not c then c={};A.cache[ts]=c end;if c[m]then return c[m]end
 local best,score=0x281,-1
 for _,mid in ipairs(floors)do if ts.midToSlot[mid]then local matches=0
  for y=0,15 do for x=0,15 do
   if not A.rockPixel(ts,m,x,y)and color(ts,m,x,y)==color(ts,mid,x,y)then matches=matches+1 end
  end end
  if matches>score then best,score=mid,matches end
 end end
 c[m]=best;return best
end
function A.objects(out,d,ts,ox,oz,contacts,height)
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local L=d.midLayout;local C=V.require('DioramaConfig').terrain.frTerracedCaves
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if A.rock(m)and m~=0x2a7 then
   local count=1;if m==0x29f then while L:midAt(x,y+count)==0x2a7 do count=count+1 end end
   local rows=count*16;local function source(s,t)return t<16 and m or 0x2a7,s,t%16 end
   local vertices=P.build(ts,16,rows,source,function(s,t)local mid,u,w=source(s,t);return A.rockPixel(ts,mid,u,w)end,0,rows,C.rockScale,function()return 1 end,nil,.5)
   local h=height(d,x*16,(y+count-1)*16)
   for _,p in ipairs(vertices)do local q=G.place(p,(x+ox)*16,(y+count+oz)*16);q[2]=q[2]+h;out[#out+1]=q end
   contacts[#contacts+1]={(x+ox)*16+8,(y+count+oz)*16,5,C.contactDepth,C.contactStrength,h}
  end
 end end
 if d.id=='FR_FOUR_ISLAND_ICEFALL_CAVE_BACK'and V.require('DioramaConfig').seaRocks.enabled then
  for y=0,L.height-1 do for x=0,L.width-1 do local gx,gy=A.seaGroup(L,x,y)
   if gx==x and gy==y then
    for _,p in ipairs(V.require('FireRedSeaRocks').template(ts,0x110))do out[#out+1]=G.place(p,(x+ox)*16,(y+oz)*16)end
   end
  end end
 end
end
function A.seaGroup(L,x,y)
 local offsets={[0x110]={0,0},[0x111]={1,0},[0x118]={0,1},[0x119]={1,1}}
 local o=offsets[L:midAt(x,y)];if not o then return end
 local gx,gy=x-o[1],y-o[2]
 if L:midAt(gx,gy)==0x110 and L:midAt(gx+1,gy)==0x111 and L:midAt(gx,gy+1)==0x118 and L:midAt(gx+1,gy+1)==0x119 then return gx,gy end
end
function A.entrance(d)return d.id=='FR_FOUR_ISLAND_ICEFALL_CAVE_ENTRANCE'end
function A.floorHeight(d,x,z)
 if not A.entrance(d)then return end
 local c=V.require('DioramaConfig').terrain.frTerracedCaves
 return math.max(0,math.min(1,(c.icefallWaterfallBottomRow*16-z)/((c.icefallWaterfallBottomRow-c.icefallWaterfallTopRow)*16)))*c.icefallWaterfallHeight
end
function A.plan(d,p)
 if not A.entrance(d)then return end
 local L=d.midLayout;local c=V.require('DioramaConfig').terrain.frTerracedCaves
 p.borderTop=function(x,y)return A.floorHeight(d,x*16,y*16)+c.wallHeight end
 for y=0,L.height-1 do for x=0,L.width-1 do local k=y*L.width+x+1;local h=A.floorHeight(d,x*16,y*16)
  p.level[k]=h/c.platformHeight;p.base[k]=h;p.top[k]=h+c.wallHeight;p.upper[k]=h>0 or nil
 end end
end
function A.floor(out,d,ts,x,y,ox,oz)
 if d.id=='FR_FOUR_ISLAND_ICEFALL_CAVE_BACK'and V.require('DioramaConfig').seaRocks.enabled then
  local gx,gy=A.seaGroup(d.midLayout,x,y)
  if gx then
   local G=V.require('WorldGeometry');local sx,sy=(x-gx)*16,(y-gy)*16
   local floor=V.require('FireRedSeaRocks').floor(ts,0x110)
   for i=1,#floor,6 do local v=floor[i]
    if v[1]>=sx and v[1]<sx+16 and v[3]>=sy and v[3]<sy+16 then
     for j=i,i+5 do out[#out+1]=G.place(floor[j],(gx+ox)*16,(gy+oz)*16)end
    end
   end
   return true
  end
 end
 if not A.entrance(d)then return false end
 local G=V.require('WorldGeometry');local m=d.midLayout:midAt(x,y);local xx,zz=(x+ox)*16,(y+oz)*16
 local h=A.floorHeight(d,x*16,y*16);local low=A.floorHeight(d,x*16,(y+1)*16)
 G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,low,zz+16},{xx,low,zz+16},G.uv(ts,m,0,0,16,16,.5),V.data('Shapes').water(d.midLayout:cellAt(x,y))and G.WATER or 1)
 return true
end
return A
