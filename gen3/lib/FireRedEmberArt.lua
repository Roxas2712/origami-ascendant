-- Red volcanic rock uses its own native palette. Keep the Ruby puzzle floor,
-- tablets, holes and event objects intact; only lift walls and loose stones.
local V=...;local A={cache=setmetatable({},{__mode='k'})}
local names={FR_MT_EMBER_RUBY_PATH_1F=true,FR_MT_EMBER_RUBY_PATH_B1F=true,FR_MT_EMBER_RUBY_PATH_B1F_STAIRS=true,FR_MT_EMBER_RUBY_PATH_B2F=true,FR_MT_EMBER_RUBY_PATH_B2F_STAIRS=true,FR_MT_EMBER_RUBY_PATH_B3F=true,FR_MT_EMBER_RUBY_PATH_B4F=true,FR_MT_EMBER_RUBY_PATH_B5F=true,FR_MT_EMBER_SUMMIT_PATH_1F=true,FR_MT_EMBER_SUMMIT_PATH_2F=true,FR_MT_EMBER_SUMMIT_PATH_3F=true}
function A.profile(d)return d and (d.renderPair or d.pair)=='general__rom_082d4fec'and names[d.id]end
function A.rock(m)return m==0x282 or m==0x283 or m==0x29f or m==0x2a7 end
function A.ladderUpper(m)return m==0x28e or m==0x28f end
function A.floorMid(m)return(A.rock(m)or A.ladderUpper(m)or m==0x2b7)and 0x281 or m end
local function color(ts,m,x,y)local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y);return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function A.mask(ts,m)
 local c=A.cache[ts];if not c then c={floor={}};A.cache[ts]=c;for y=0,15 do for x=0,15 do c.floor[color(ts,0x281,x,y)]=true end end end
 if not c[m]then local a={count=0};for y=0,15 do for x=0,15 do local yes=not c.floor[color(ts,m,x,y)];a[y*16+x+1]=yes;if yes then a.count=a.count+1 end end end;c[m]=a end
 return c[m]
end
function A.shore()return false end
function A.ladderPixel(ts,x,y,source)
 return V.require('CaveObjectArt').ladderPixel(ts,x,y,source,{0xffefa5,0xcead7b,0x4a4a3a,0x525242},{0,15,0,31})
end
function A.objects(out,d,ts,ox,oz,contacts,height)
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local L=d.midLayout;local C=V.require('DioramaConfig').terrain.frTerracedCaves
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if A.rock(m)and m~=0x2a7 then
   local rows=16;if m==0x29f then while y+rows/16<L.height and L:midAt(x,y+rows/16)==0x2a7 do rows=rows+16 end end
   local base=y+rows/16
   local function source(s,t)return t<16 and m or 0x2a7,s,t%16 end
   local v=P.build(ts,16,rows,source,function(s,t)local mid,u,w=source(s,t);return A.mask(ts,mid)[w*16+u+1]end,0,rows,C.rockScale,function()return 1 end,nil,.5)
   local h=height(d,x*16,(base-1)*16)
   for _,p in ipairs(v)do local q=G.place(p,(x+ox)*16,(base+oz)*16);q[2]=q[2]+h;out[#out+1]=q end
   contacts[#contacts+1]={(x+ox)*16+8,(base+oz)*16,5,C.contactDepth,C.contactStrength,h}
  end
 end end
end
return A
