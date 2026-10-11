-- Authored sprite contours shared by native cave palettes. Palette flood-fill
-- is unsuitable: the pale rock highlights share the floor colors.
local V=...
local A={}
-- Native 202 and 2d5 have identical pixel topology, including pale highlights.
local rockRows={{6,9},{4,10},{2,11},{1,12},{1,13},{1,13},{1,13},{0,13},
 {0,12},{2,14},{2,14},{1,14},{0,14},{0,7,9,14},{1,7,9,13},{2,6}}
local clusterRows={{4,7},{3,7,10,12},{3,7,9,13},{2,14},{1,15},{0,15},{0,15},{0,15},
 {0,15},{1,14},{1,13},{1,14},{1,14},{2,14},{3,5,9,13},{10,12}}
-- Shoal's icy rocks have different outlines, not merely a blue palette.
local iceRows={{7,9},{6,10},{5,11},{4,12},{3,12},{2,12},{1,12},{1,13},
 {1,14},{2,14},{2,15},{1,15},{0,15},{0,14},{1,13},{2,5,8,12}}
local iceClusterRows={{11,12},{5,5,10,13},{4,6,9,14},{3,15},{2,15},{2,15},{2,14},{2,15},
 {1,15},{0,15},{0,14},{0,13},{1,13},{3,13},{5,12},{7,10}}
function A.rockPixel(mid,x,y)
 local rows=mid==0x37d and iceRows or mid==0x37e and iceClusterRows or mid==0x203 and clusterRows or rockRows
 local r=rows[y+1];if not r then return false end
 for i=1,#r,2 do if x>=r[i]and x<=r[i+1]then return true end end
 return false
end
function A.ladderPixel(ts,x,y,source,colors,bounds)
 local x0,x1,y0,y1=unpack(bounds)
 if x<x0 or x>x1 or y<y0 or y>y1 then return false end
 local pixel=V.require('BuildingMesh').pixel
 local function color(s,t)
  if s<x0 or s>x1 or t<y0 or t>y1 then return end
  local m,u,v=source(s,t);local r,g,b=pixel(ts,m,u,v)
  return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)
 end
 local function rail(s,t)local c=color(s,t);return c==colors[1]or c==colors[2]end
 if rail(x,y)then return true end
 local c=color(x,y)
 return(c==colors[3]or c==colors[4])and(rail(x-1,y)or rail(x+1,y)or rail(x,y-1)or rail(x,y+1))
end
return A
