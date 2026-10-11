-- Native Fortree decks share one render-only elevation with their doors/actors.
-- Collision, elevation metadata, overpass routing and warps remain engine-owned.
local V=...
local R={}
local C=V.require('DioramaConfig').fortreeArchitecture
function R.applies(d)
 return C.enabled and d and(d.id or d.name)=='EM_FORTREE_CITY'and d.pair=='general__fortree'
  and V.require('DioramaConfig').billboards.enabled
end
local function deck(m)return m==0x233 or m==0x237 or m>=0x23b and m<=0x23f or m==0x256 or m==0x257 or m==0x24e or m==0x24f end
function R.plan(d)
 local p={mask={},decks={},fronts={},ladders={}}
 if not R.applies(d)then return p end
 local L=d.midLayout
 for y=0,L.height-1 do for x=0,L.width-1 do
  local c=L:cellAt(x,y);local m=c.mid
  -- Side foliage 233/237 occurs in both the house face and its deck course.
  local side=(m==0x233 and L:midAt(x+1,y)==0x23c)or(m==0x237 and L:midAt(x-1,y)==0x23e)
  if deck(m)and(c.elev==4 or m==0x24e or m==0x24f or side)then
   p.decks[#p.decks+1]={x=x,y=y,mid=m};p.mask[y*L.width+x+1]=1
   local f=L:midAt(x,y+1)
   if f==0x243 or f==0x244 or f==0x246 or f==0x247 then
    p.fronts[#p.fronts+1]={x=x,y=y+1,mid=f};p.mask[(y+1)*L.width+x+1]=1
   end
  elseif m==0x245 and L:midAt(x,y+1)==0x24d then
   p.ladders[#p.ladders+1]={x=x,y=y}
   p.mask[y*L.width+x+1]=1;p.mask[(y+1)*L.width+x+1]=1
  end
 end end
 return p
end
function R.mask(d,mask)for k,v in pairs(R.plan(d).mask)do mask[k]=v end end
function R.build(out,d,ts,ox,oz)
 if not R.applies(d)then return end
 local p=R.plan(d);local G=V.require('WorldGeometry');local BM=V.require('BuildingMesh')
 local xx,zz=(ox or 0)*16,(oz or 0)*16
 local function foliage(m,x,y)local r,g,b,a=BM.pixel(ts,m,x,y);return a>.5 and g>r*1.07 and g>b*1.4 end
 local function art(o,h,inside,transform,shade)
  local vv=V.require('PaperSprite').build(ts,16,h,function(s,t)return d.midLayout:midAt(o.x,o.y+math.floor(t/16)),s,t%16 end,
   inside,0,h,1,shade and function()return shade end or nil,
   function(s,t)local a,b,c=transform(s,t);return{xx+a,b,zz+c}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 for _,o in ipairs(p.decks)do
  art(o,16,function(s,t,m,u,v)return not foliage(m,u,v)end,
   function(s,t)return o.x*16+s,C.deckHeight,o.y*16+t end)
  -- Foliage framing the planks belongs to the hanging crown, not the path.
  art(o,16,function(s,t,m,u,v)return foliage(m,u,v)end,
   function(s,t)return o.x*16+s,C.deckHeight*(16-t)/16,(o.y+1)*16 end)
 end
 for _,o in ipairs(p.fronts)do
  art(o,16,function(s,t,m,u,v)return foliage(m,u,v)end,
   function(s,t)return o.x*16+s,C.deckHeight*(16-t)/16,o.y*16+.08 end,C.canopyShade)
 end
 for _,o in ipairs(p.ladders)do
  art(o,32,function(s,t,m,u,v)return not foliage(m,u,v)end,
   function(s,t)return o.x*16+s,C.deckHeight*(32-t)/32,o.y*16+t end)
 end
end
function R.buildingBase(b)
 if C.enabled and V.require('DioramaConfig').billboards.enabled and b.mapId=='EM_FORTREE_CITY'and b.ground==0xc7 then return C.deckHeight end
 return 0
end
function R.actorHeight(d,x,z,elevation)
 if not R.applies(d)then return end
 local L=d.midLayout;local cx=math.floor((x+8)/16);local foot=z+16
 for y=0,L.height-2 do
  if L:midAt(cx,y)==0x245 and L:midAt(cx,y+1)==0x24d and foot>=y*16 and foot<=(y+2)*16 then
   return C.deckHeight*((y+2)*16-foot)/32
  end
 end
 local cy=math.floor((z+.001)/16);local cell=L:cellAt(cx,cy)
 if not cell then return 0 end
 if cell.mid==0x24e or cell.mid==0x24f then return tonumber(elevation)==4 and C.deckHeight or 0 end
 if cell.elev==4 or cell.mid==0x256 or cell.mid==0x257 or cell.mid==0x235 then return C.deckHeight end
 return 0
end
function R.doorPose(d,a)
 if not R.applies(d)or not a or d.midLayout:midAt(a.x,a.y)~=0x235 then return end
 return{height=32*C.wallScale*V.require('Billboard').heightScale(),base=C.deckHeight,top=0}
end
return R
