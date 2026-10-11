-- One native basin, not twelve unrelated facade/roof metatiles.
-- All colours/texels come from the original fountain; native cells stay intact.
local V=...
local F={}
function F.active(def)
 if not def or (def.id or def.name)~='FR_CELADON_CITY' or (def.renderPair or def.pair)~='general__rom_082d4b3c' then return false end
 local L=def.midLayout;if not L then return false end
 for y=0,3 do for x=0,2 do if L:midAt(12+x,18+y)~=0x2cd+y*3+x then return false end end end
 return true
end
function F.source(x,y)return 0x2cd+math.floor(y/16)*3+math.floor(x/16),x%16,y%16 end
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local function color(r,g,b)return r*65536+g*256+b end
local jetColors={[color(173,214,255)]=true,[color(197,239,255)]=true,[color(123,165,222)]=true}
local waterColors={[color(123,165,189)]=true,[color(99,140,189)]=true}
local rimColors={[color(197,181,115)]=true,[color(173,156,90)]=true}
local stoneColors={[color(123,123,132)]=true,[color(82,82,107)]=true}
local cache=setmetatable({},{__mode='k'})
function F.template(ts)
 local scale=V.require('Billboard').heightScale()
 if cache[ts]and cache[ts].scale==scale then return cache[ts]end
 local pixel=V.require('BuildingMesh').pixel;local G=V.require('WorldGeometry')
 local pixels={}
 for y=0,63 do for x=0,47 do
  local mid,sx,sy=F.source(x,y);local c=rgb(pixel(ts,mid,sx,sy))
  local jet=jetColors[c]or false;local water=waterColors[c]or jet
  pixels[y*48+x+1]={mid=mid,sx=sx,sy=sy,color=c,jet=jet,water=water,
   height=rimColors[c]and 4 or stoneColors[c]and 1.5 or water and 2 or 0}
 end end
 -- Remove the jet's flat duplicate using the nearest original basin texel.
 -- This keeps the pool's native palette; the jet is drawn once above it.
 for y=0,63 do for x=0,47 do local p=pixels[y*48+x+1]
  if p.jet then
   local donor
   for radius=1,64 do
    for dy=-radius,radius do for _,dx in ipairs{-(radius-math.abs(dy)),radius-math.abs(dy)}do
     local nx,ny=x+dx,y+dy
     local q=nx>=0 and nx<48 and ny>=0 and ny<64 and pixels[ny*48+nx+1]
     if q and q.water and not q.jet then donor=q;break end
    end;if donor then break end end
    if donor then break end
   end
   assert(donor,'native fountain jet has no basin donor')
   p.mid,p.sx,p.sy,p.color=donor.mid,donor.sx,donor.sy,donor.color
  end
 end end
 local out={}
 local function face(a,b,c,d,p,role)
  G.quad(out,a,b,c,d,G.uv(ts,p.mid,p.sx+.5,p.sy+.5,p.sx+.5,p.sy+.5,0),role)
 end
 -- Constant-colour native pixel runs keep the rounded stone rim continuous.
 for y=0,63 do local x=0
  while x<48 do
   local p=pixels[y*48+x+1];local stop=x+1
   while stop<48 do local q=pixels[y*48+stop+1]
    if q.height~=p.height or q.water~=p.water or q.color~=p.color then break end
    stop=stop+1
   end
   face({x,p.height,y},{stop,p.height,y},{stop,p.height,y+1},{x,p.height,y+1},p,p.water and G.WATER or 1)
   x=stop
  end
 end
 -- Close only exposed height changes; no artificial walls between equal tiles.
 for y=0,63 do for x=0,47 do local p=pixels[y*48+x+1]
  if p.height>0 and not p.water then
   for _,d in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do
    local nx,ny=x+d[1],y+d[2];local q=nx>=0 and nx<48 and ny>=0 and ny<64 and pixels[ny*48+nx+1]
    local low=q and q.height or 0
    if low<p.height then
     if d[1]==-1 then face({x,p.height,y},{x,p.height,y+1},{x,low,y+1},{x,low,y},p,.82)
     elseif d[1]==1 then face({x+1,p.height,y+1},{x+1,p.height,y},{x+1,low,y},{x+1,low,y+1},p,.82)
     elseif d[2]==-1 then face({x+1,p.height,y},{x,p.height,y},{x,low,y},{x+1,low,y},p,.86)
     else face({x,p.height,y+1},{x+1,p.height,y+1},{x+1,low,y+1},{x,low,y+1},p,.86)end
    end
   end
  end
 end end
 local jet=V.require('PaperSprite').build(ts,48,39,F.source,
  function(x,y)return pixels[y*48+x+1].jet end,0,39,1,nil,
  function(x,y)return {24+(x-24)*.8,2+(39-y)*.8*scale,36}end,.5)
 for _,v in ipairs(jet)do out[#out+1]=v end
 cache[ts]={vertices=out,pixels=pixels,jetVertices=#jet,scale=scale};return cache[ts]
end
function F.place(out,ts,ox,oz,contacts)
 local G=V.require('WorldGeometry');local x,z=(12+ox)*16,(18+oz)*16
 for _,v in ipairs(F.template(ts).vertices)do out[#out+1]=G.place(v,x,z)end
 local c=V.require('DioramaConfig').contact
 contacts[#contacts+1]={x+24,z+42,20,6,c.strength*.6}
end
return F
