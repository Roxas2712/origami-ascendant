-- Native Route 113 ash vegetation. No map, collision or encounter edits.
local V=...
local A={ground=0x218}
local treeMids={[0x204]=true,[0x205]=true,[0x20c]=true,[0x20d]=true,[0x26d]=true,[0x26e]=true,[0x275]=true,[0x276]=true}
function A.applies(d)return d and(d.id or d.name)=='EM_ROUTE113'and d.pair=='general__fallarbor'end
function A.tree(m)return treeMids[m]or false end
-- Exact native ash-tree palette roles, scoped to this atlas and artwork.
-- 845A5A/634252 are baked ground shadows, not part of the standing trunk.
local treeInk={[0x4a5221]=true,[0x9cbd63]=true,[0xc5ff9c]=true,[0x738431]=true,[0x3a2108]=true,[0x9c6b42]=true}
local grassInk={[0xe6e6ce]=true,[0x73734a]=true,[0x5a5a3a]=true,[0x948c73]=true,[0xc5b573]=true}
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function A.ink(ts,mid,x,y,kind)
 local r,g,b,a=V.require('BuildingMesh').pixel(ts,mid,x,y)
 if a<=.5 then return false end
 local c=rgb(r,g,b)
 if kind=='ashTree'then return treeInk[c]or false end
 if grassInk[c]then return true end
 -- Cream leaf tips share a colour with ground specks: retain only tips
 -- adjacent to the actual ash-grass stems, never an opaque tile rectangle.
 if c==0xcecea5 then for dy=-1,1 do for dx=-1,1 do
  local xx,yy=x+dx,y+dy
  if xx>=0 and xx<16 and yy>=0 and yy<16 then local rr,gg,bb=V.require('BuildingMesh').pixel(ts,mid,xx,yy);if grassInk[rgb(rr,gg,bb)]then return true end end
 end end end
 return false
end
function A.plan(d)
 local mask={};if not A.applies(d)then return mask end
 local L=d.midLayout
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if A.tree(m)then
   local p={};mask[y*L.width+x+1]=p
   -- The native lower-left trunk tile is the stable foot even where
   -- neighbouring canopy courses overlap in the dense variants.
   if(m==0x20c or m==0x275)and A.tree(L:midAt(x+1,y))then p.kind='ashTree';p.x=x*16+16;p.z=y*16+12 end
  elseif m==0x20a then mask[y*L.width+x+1]={kind='ashGrass',x=x*16+8+((x+y)%2==0 and -1 or 1),z=y*16+13}end
 end end
 return mask
end
function A.template(ts,kind,sourceMids)
 local tree=kind=='ashTree';local W,H=tree and 32 or 16,tree and 32 or 16
 local mids=sourceMids or{0x204,0x205,0x20c,0x20d};local base=tree and 28 or 15
 local cfg=V.require('DioramaConfig').trees;local style=cfg.defaultStyle or cfg
 local function pick(k)return style[k]~=nil and style[k]or cfg[k]end
 local verts=V.require('PaperSprite').build(ts,W,H,function(x,y)return tree and mids[math.floor(y/16)*2+math.floor(x/16)+1]or 0x20a,x%16,y%16 end,
  function(x,y,m,sx,sy)return y<base and A.ink(ts,m,sx,sy,kind)end,-W/2,base,tree and 1 or V.require('DioramaConfig').ashRoute.grassHeight/base,tree and function(x,y)
   local t=math.max(0,math.min(1,(y-base*cfg.lowerShadeStart)/(base*(1-cfg.lowerShadeStart))))
   return pick('crownShade')*(1-t)+pick('trunkShade')*t
  end or nil,nil,.5)
 if not tree then
  for _,v in ipairs(verts)do v[1]=v[1]*V.require('DioramaConfig').ashRoute.grassWidth/16;if v[9]>0 then v[9]=1+V.require('DioramaConfig').dynamicTexture.grassWeight end end
 end
 if tree then
  local perspective=V.require('Camera').projection()=='perspective';local angle=perspective and math.rad(cfg.tiltDegrees)or 0
  local compensation=pick('preserveScreenHeight')and perspective and 1/math.max(.25,math.cos(angle)-math.tan(V.require('Camera').elevation())*math.sin(angle))or 1
  for _,v in ipairs(verts)do v[1]=v[1]*pick('widthScale');local h=v[2]*pick('heightScale')*compensation;v[2]=h*math.cos(angle);if perspective then v[3]=h*math.sin(angle)end;if v[9]>0 then v[9]=1+V.require('DioramaConfig').dynamicTexture.treeWeight end end
 end
 return verts
end
function A.place(out,ts,p,ox,oz,instances,contacts)
 if not p.kind then return end
 local x,z=p.x+ox*16,p.z+oz*16
 if instances then local key=p.kind;local group=instances.props[key]
  if not group then group={mid=p.kind=='ashTree'and 0x204 or 0x20a,kind=p.kind,ground=A.ground,placements={}};instances.props[key]=group end
  group.placements[#group.placements+1]={x,z,1}
 else V.require('Props').stamp(out,ts,p.kind=='ashTree'and 0x204 or 0x20a,p.kind,x,z,A.ground)end
 if p.kind=='ashTree'then local c=V.require('DioramaConfig').contact;contacts[#contacts+1]={x,z,c.treeRadius[1],c.treeRadius[2],c.treeStrength}end
end
function A.ledge(out,d,ts,x,z,ox,oz,cells)
 if not A.applies(d)then return false end
 local cell=d.midLayout:cellAt(x,z);local dir=cell.coll
 if dir<0xa0 or dir>0xa3 then return false end
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').terrain;local h=cfg.ledgeHeight
 local x0,x1,z0,z1=0,16,0,16
 if dir==0xa0 then x0=8 elseif dir==0xa1 then x1=8 elseif dir==0xa2 then z1=8 else z0=8 end
 local xx,zz=(x+ox)*16,(z+oz)*16
 local function point(a,y,b)return {xx+a,y,zz+b}end
 local function face(a,b,c,e,uv,shade)G.quad(out,a,b,c,e,uv,shade)end
 face(point(x0,h,z0),point(x1,h,z0),point(x1,h,z1),point(x0,h,z1),G.uv(ts,A.ground,x0,z0,x1,z1,.5),cfg.topShade)
 local edges={
  {x0,z0,x0,z1,-1,0,0,0,8,16},{x1,z1,x1,z0,1,0,8,0,16,16},
  {x1,z0,x0,z0,0,-1,0,0,16,8},{x0,z1,x1,z1,0,1,0,8,16,16}}
 for _,e in ipairs(edges)do
  local nx,nz=x+e[5],z+e[6];local neighbour=d.midLayout:cellAt(nx,nz)
  local internal=(e[5]~=0 and x0==0 and x1==16 or e[6]~=0 and z0==0 and z1==16)and neighbour and neighbour.coll==dir
  if not internal then
   face(point(e[1],h,e[2]),point(e[3],h,e[4]),point(e[3],0,e[4]),point(e[1],0,e[2]),G.uv(ts,cell.mid,e[7],e[8],e[9],e[10],.5),cfg.ledgeSideShade)
  end
 end
 return true
end
return A
