-- Shared native FR home palm contour; background palettes must never
-- erase pot highlights. Left-wall and rear-wall variants contain identical
-- object texels, shifted eight rows in the rear-wall composite.
local V=...;local H={}
function H.matches(L,o)
 local m=L:midAt(o.x,o.y)
 local above=L:midAt(o.x,o.y-1)
 return o.ground==0xa9 and (m==0xfd or m==0xfe or m==0xd2 and above==0xca)
  or o.ground==0x109 and ((m==0x15e or m==0x15d)and(above==0x156 or above==0x155)or m==0x132 and above==0xca)
  or o.ground==1 and ((m==0x5f and above==0x57)or(m==0x4f and above==0x47))
end
-- Measured contour of the shared 16x28 palm artwork, starting at source row 4.
-- Old house atlases do not all contain the player-house f5/fd donor pair.
-- A palette-derived mask can therefore erase the entire plant or cut stripes
-- through the pot. Keep its exact silhouette and sample each instance's own art.
local runs={{7,9},{6,10},{2,14},{2,14},{2,14},{2,14},{1,15},{0,16},{0,16},{2,14},{2,14},{1,15},{1,15},{1,15},{4,12},{5,11},{4,12},{3,13},{3,13},{3,13},{3,13},{3,13},{3,13},{3,13},{3,13},{3,13},{4,12},{5,11}}
function H.mask(ts)
 return function(x,y)local r=runs[y-3];return r~=nil and x>=r[1]and x<r[2]end
end

function H.build(out,L,ts,o,x,z)
 local rear=L:midAt(o.x,o.y)==0xd2 or L:midAt(o.x,o.y)==0x132
 local offset=rear and 8 or 0;local sy=(o.y-1)*16-offset
 local inside=H.mask(ts);local c=V.require('DioramaConfig').interiors.homePlants
 local vertices=V.require('PaperSprite').build(ts,16,32,function(s,t)
  local yy=sy+t;return L:midAt(o.x,math.floor(yy/16)),s,yy%16
 end,inside,0,32,1,nil,function(s,t)return{x+s,(32-t)*c.height/28,z+16-offset}end,.5)
 for _,v in ipairs(vertices)do out[#out+1]=v end
 o.contactFront=16-offset;o.contactWidth=12;o.contactOffset=2
end
return H
