-- Warm native torch positions and neutral ceiling fill for the reception only.
-- Pyramid challenge floors retain their own native darkness/visibility rules.
local V=...;local P={}
function P.profile(d)
 if not V.require('EmeraldPyramidLobby').profile(d)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.pyramidLobbyLighting
 return c.enabled and c or nil
end
function P.capture(list,o,x,z)
 if not o.kind:match('^pyl')then return false end
 local cfg=V.require('DioramaConfig').emeraldInteriors
 local c,lc=cfg.pyramidLobby,cfg.pyramidLobbyLighting
 local function box(a,b,u,v,low,high,platform)
  local lo,hi={x+a,low*cfg.heightScale,z+u},{x+b,high*cfg.heightScale,z+v}
  if platform then
   -- Join only complete shared edges. The stair channel must never be filled.
   local again=true
   while again do
    again=false
    for i=#list,1,-1 do local q=list[i]
     if q.pyramidPlatform and q.lo[2]==lo[2]and q.hi[2]==hi[2]then
      if q.lo[1]==lo[1]and q.hi[1]==hi[1]and lo[3]<=q.hi[3]and hi[3]>=q.lo[3]then
       lo[3]=math.min(lo[3],q.lo[3]);hi[3]=math.max(hi[3],q.hi[3]);table.remove(list,i);again=true
      elseif q.lo[3]==lo[3]and q.hi[3]==hi[3]and lo[1]<=q.hi[1]and hi[1]>=q.lo[1]then
       lo[1]=math.min(lo[1],q.lo[1]);hi[1]=math.max(hi[1],q.hi[1]);table.remove(list,i);again=true
      end
     end
    end
   end
  end
  list[#list+1]={lo=lo,hi=hi,wall=false,pyramidPlatform=platform}
 end
 local half=lc.blockerThickness/2
 local function thin(a,b,at,low,high)box(a,b,at-half,at+half,low,high)end
 if o.kind=='pylWall'then thin(0,o.w,79.5,c.platformHeight,c.platformHeight+c.wallHeight)
 elseif o.kind=='pylPlatform'or o.kind=='pylFace'then box(0,o.w,0,o.h,0,c.platformHeight,true)
 elseif o.kind=='pylStairs'then
  for start=0,80-c.treadDepth,c.treadDepth do
   box(0,o.w,start,start+c.treadDepth,0,c.platformHeight*(80-start)/80)
  end
 elseif o.kind=='pylColumn'then thin(0,16,112,c.platformHeight,c.platformHeight+c.columnHeight)
 elseif o.kind=='pylStatue'then thin(3,13,48,c.platformHeight,c.platformHeight+c.statueHeight)
 elseif o.kind=='pylDevice'then
  local a,b=o.shape=='display'and 2 or 1,o.shape=='display'and 46 or 15
  thin(a,b,o.last,0,c[o.shape..'Height'])
 end
 -- Torch flame sprites emit light; they must not shadow their own source.
 return true
end
return P
