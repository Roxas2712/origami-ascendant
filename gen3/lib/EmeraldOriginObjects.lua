-- Native Cave of Origin objects. Keep ladder warps and rock collision native;
-- separate the authored rock/ladder pixels from their floor/wall backgrounds.
local V=...
local O={}
function O.applies(d)
 return d and tostring(d.id or ''):match('^EM_CAVE_OF_ORIGIN_') and d.pair=='general__cave'
  and V.require('DioramaConfig').originObjects.enabled
  and V.require('DioramaConfig').billboards.enabled and V.require('DioramaConfig').terrain.enabled
  and V.require('Camera').projection()=='perspective'
end
function O.isRock(d,mid)return O.applies(d)and mid==0x330 end
function O.plan(d)
 local p={objects={},mask={}};if not O.applies(d)then return p end
 local L=d.midLayout
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x330 then local o={kind='rock',x=x,y=y};p.objects[#p.objects+1]=o;p.mask[y*L.width+x+1]=o
  elseif m==0x340 and L:midAt(x,y+1)==0x341 then
   for _,w in ipairs(d.warps or{})do if w.x==x and w.y==y+1 then
    local o={kind='ladder',x=x,y=y};p.objects[#p.objects+1]=o
    p.mask[y*L.width+x+1]=o;p.mask[(y+1)*L.width+x+1]=o;break
   end end
  end
 end end
 return p
end
function O.donor(d,x,y)
 if O.applies(d) and d.midLayout:midAt(x,y)==0x340 and d.midLayout:midAt(x,y+1)==0x341 then
  for _,w in ipairs(d.warps or{})do if w.x==x and w.y==y+1 then return 0x329 end end
 end
end
function O.rockPixel(x,y)return V.require('CaveObjectArt').rockPixel(0x330,x,y)end
function O.ladderPixel(ts,x,y)
 return V.require('CaveObjectArt').ladderPixel(ts,x,y,
  function(s,t)return t<16 and 0x340 or 0x341,s,t%16 end,
  {0xffffff,0xe6cece,0x5a423a,0x735a52},{3,12,2,29})
end
function O.floor(out,d,ts,x,y,ox,oz,p)
 local o=p.mask[y*d.midLayout.width+x+1]
 if not o or o.kind=='ladder'and y==o.y then return false end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,0x31b),1)
 return true
end
function O.build(out,d,ts,ox,oz,contacts,p)
 local C=V.require('DioramaConfig').originObjects;local G=V.require('WorldGeometry')
 for _,o in ipairs(p.objects)do local xx,zz=(o.x+ox)*16,(o.y+oz)*16;local vertices
  if o.kind=='rock'then
   vertices=V.require('PaperSprite').build(ts,16,16,function(x,y)return 0x330,x,y end,
    O.rockPixel,0,16,C.rockHeightScale,function()return 5 end,nil,.5)
   zz=zz+16
   contacts[#contacts+1]={xx+8,zz,C.rockContactWidth,C.contactDepth,C.contactStrength}
  else
   local h=V.require('DioramaConfig').terrain.caveWallHeight
   vertices=V.require('PaperSprite').build(ts,16,32,function(x,y)return y<16 and 0x340 or 0x341,x,y%16 end,
    function(x,y)return O.ladderPixel(ts,x,y)end,0,29,1,function()return 5 end,
    function(x,y)local t=(y-2)/27;return{x,h*(1-t),-16+C.ladderFrontOffset+(16-C.ladderFrontOffset)*t}end,.5)
   for _,v in ipairs(vertices)do v[9]=-2 end -- Same opaque foreground cutaway as its supporting rock.
   zz=zz+32;contacts[#contacts+1]={xx+8,zz,4,C.contactDepth,C.contactStrength}
  end
  for _,v in ipairs(vertices)do out[#out+1]=G.place(v,xx,zz)end
 end
end
return O
