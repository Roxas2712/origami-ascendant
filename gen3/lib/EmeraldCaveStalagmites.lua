-- Native brown stalagmites: 21f, optionally continued by 227 below.
-- Adjacent rounded rock-cap tiles are terrain, not independent objects.
local V=...
local S={}
local rows={{},{9,11},{8,12},{4,13},{3,13},{2,14},{2,14},{2,14},
 {2,15},{1,15},{1,15},{1,15},{1,15},{1,15},{2,15},{2,15},
 {1,15},{0,14},{0,13},{0,13},{0,13},{0,13},{0,14},{0,15},
 {1,15},{0,15},{0,15},{0,15},{0,14},{0,14},{1,13},{3,7,9,12}}
function S.applies(d)
 return V.require('EmeraldCaveObjects').applies(d)
  and V.require('DioramaConfig').caveObjects.stalagmites.enabled
end
function S.inside(x,y)
 local r=rows[y+1];if not r then return false end
 for i=1,#r,2 do if x>=r[i]and x<=r[i+1]then return true end end
 return false
end
function S.plan(d)
 local p={objects={},mask={}};if not S.applies(d)then return p end
 local L=d.midLayout
 for y=0,L.height-1 do for x=0,L.width-1 do if L:midAt(x,y)==0x21f then
  local h=y+1<L.height and L:midAt(x,y+1)==0x227 and 2 or 1
  local ground=false;local floors={};local best,floor=0,0x211
  for yy=y-1,y+h do for xx=x-1,x+1 do
   if xx~=x or yy<y or yy>=y+h then local c=L:cellAt(xx,yy)
    if c then
     if c.coll~=7 and c.coll~=255 then ground=true end
     if c.mid==0x201 or c.mid==0x211 then floors[c.mid]=(floors[c.mid]or 0)+1
      if floors[c.mid]>best then best=floors[c.mid];floor=c.mid end
     end
    end
   end
  end end
  local o={kind='rock',x=x,y=y,h=h,floor=floor,wall=0x219,
   base=ground and 0 or V.require('DioramaConfig').terrain.caveWallHeight}
  p.objects[#p.objects+1]=o
  for yy=y,y+h-1 do p.mask[yy*L.width+x+1]=o end
 end end end
 return p
end
function S.floor(out,d,ts,x,y,ox,oz,p)
 -- Reuse the closed supporting-cap/side implementation for raised objects.
 return V.require('EmeraldCaveObjects').floor(out,d,ts,x,y,ox,oz,p)
end
function S.build(out,d,ts,ox,oz,contacts,p)
 local c=V.require('DioramaConfig').caveObjects;local G=V.require('WorldGeometry')
 for _,o in ipairs(p.objects)do
  local vv=V.require('PaperSprite').build(ts,16,o.h*16,
   function(x,y)return y<16 and 0x21f or 0x227,x,y%16 end,S.inside,
   0,o.h*16,c.stalagmites.heightScale,function()return 1 end,nil,.5)
  for _,v in ipairs(vv)do
   v[2]=v[2]+o.base;if o.base>0 then v[9]=-2 end
   out[#out+1]=G.place(v,(o.x+ox)*16,(o.y+oz+o.h)*16)
  end
  if o.base==0 then contacts[#contacts+1]={(o.x+ox)*16+8,(o.y+oz+o.h)*16,
   c.stalagmites.contactWidth,c.contactDepth,c.contactStrength}end
 end
end
return S
