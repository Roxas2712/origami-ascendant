-- Native north-facing cave openings bend at the wall/ground seam: the upper
-- graphic is the vertical arch, the lower graphic is the dark floor fade.
-- Never paint the arch onto the horizontal rock cap or stretch only its black
-- lower half down the front. South exits, ladders and unopened walls stay native.
local V=...
local P={}
local pairs={
 [0x20c]={upper=0x20c,lower=0x214,cap=0x219,wall=0x219},
 [0x22b]={upper=0x22b,lower=0x233,cap=0x22c,wall=0x22c},
 [0x2fe]={upper=0x2fe,lower=0x306,cap=0x2f9,wall=0x2f9},
 [0x32e]={upper=0x32e,lower=0x336,cap=0x329,wall=0x334},
}
function P.at(d,x,y)
 if not d or d.pair~='general__cave'or tonumber(d.mapType)~=4 or not V.data('Emerald').map(d)
  or not V.require('DioramaConfig').terrain.cavePortals.enabled then return end
 local L=d.midLayout
 if x<0 or y<0 or x>=L.width or y+1>=L.height then return end
 local p=pairs[L:midAt(x,y)]
 if p and L:midAt(x,y+1)==p.lower then return p end
end
-- The native Dig event marks the whole upper row passable. Its rock arch is
-- still vertical artwork; do not infer its render plane from collision alone.
function P.wall(d,x,y)
 if P.at(d,x,y)then return true end
 local p=P.at(d,x+1,y)
 if p and p.upper==0x22b and d.midLayout:midAt(x,y)==0x22a and d.midLayout:midAt(x,y+1)==0x232 then return true end
 p=P.at(d,x-1,y)
 return p and p.upper==0x22b and d.midLayout:midAt(x,y)==0x22c and d.midLayout:midAt(x,y+1)==0x234 or false
end
return P
