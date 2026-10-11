-- Compact native rainforest crowns, not the wider primary city-tree art.
local V=...
local R={}
function R.applies(def)
 return def and ((def.pair=='general__fortree' and
  ((def.id or def.name)=='EM_FORTREE_CITY'or(def.id or def.name)=='EM_ROUTE119'or def.id=='EM_FARAWAY_ISLAND_INTERIOR'))
  or(def.pair=='general__rustboro'and def.id=='EM_FARAWAY_ISLAND_ENTRANCE'))
end
function R.tile(def,mid)
 return R.applies(def)and(mid==0xe or mid==0xf or mid==0x16 or mid==0x17 or mid==0xc6 or mid==0xc7 or ((def.id=='EM_FARAWAY_ISLAND_ENTRANCE'or def.id=='EM_FARAWAY_ISLAND_INTERIOR')and(mid==0x316 or mid==0x317)))
end
function R.variant(mid)return(mid==0xf or mid==0x17 or mid==0xc7 or mid==0x317)and 0xf or 0xe end
function R.plan(def)
 local mask={};if not R.applies(def)then return mask end
 local L=def.midLayout
 local function key(x,y)return y*L.width+x+1 end
 -- Edge trees have a separate lower trunk tile: one full crown owns both
 -- cells and keeps the native foot. Interior canopy courses overlap densely.
 for y=1,L.height-1 do for x=0,L.width-1 do
  local mid=L:midAt(x,y);local above=L:midAt(x,y-1)
  if(mid==0x16 or mid==0x17)and(above==0xe or above==0xf or above==0xc6 or above==0xc7)then
   local p={x=x,y=y,foot=(y+1)*16-2,variant=R.variant(mid)}
   mask[key(x,y-1)]=p;mask[key(x,y)]=p
  end
 end end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local mid=L:midAt(x,y)
  if R.tile(def,mid)and not mask[key(x,y)]then mask[key(x,y)]={x=x,y=y,foot=(y+1)*16,variant=R.variant(mid)}end
 end end
 return mask
end
function R.template(ts,variant,lower)
 local pixel=V.require('BuildingMesh').pixel;local cfg=V.require('DioramaConfig').trees
 local style=cfg.pairStyle[ts.pair]or cfg.defaultStyle or cfg
 local function pick(k)return style[k]~=nil and style[k]or cfg[k]end
 local base=24 -- last canopy course, before the native brown stump
 local out=V.require('PaperSprite').build(ts,16,32,function(x,y)return y<16 and variant or lower or variant+8,x,y%16 end,
  function(x,y,mid,sx,sy)
   local r,g,b,a=pixel(ts,mid,sx,sy)
   return y<base and a>.5 and g>r*1.08 and b<g*.60
  end,-8,base,1,function(x,y)
   local lower=math.max(0,math.min(1,(y-base*cfg.lowerShadeStart)/(base*(1-cfg.lowerShadeStart))))
   return pick('crownShade')*(1-lower)+pick('trunkShade')*lower
  end,nil,.5)
 local perspective=V.require('Camera').projection()=='perspective';local angle=perspective and math.rad(cfg.tiltDegrees)or 0
 local compensation=pick('preserveScreenHeight')and perspective and
  1/math.max(.25,math.cos(angle)-math.tan(V.require('Camera').elevation())*math.sin(angle))or 1
 for _,v in ipairs(out)do
  v[1]=v[1]*pick('widthScale');local h=v[2]*pick('heightScale')*compensation
  v[2]=h*math.cos(angle);if perspective then v[3]=h*math.sin(angle)end
  if v[9]>0 then v[9]=1+V.require('DioramaConfig').dynamicTexture.treeWeight end
 end
 return out
end
function R.place(out,ts,p,ox,oz,instances,contacts)
 local x,z=(p.x+ox)*16+8,p.foot+oz*16
 if instances then
  local key=p.variant..':rainforest';local group=instances.props[key]
  if not group then group={mid=p.variant,kind='rainforest',ground=1,placements={}};instances.props[key]=group end
  group.placements[#group.placements+1]={x,z,1}
 else V.require('Props').stamp(out,ts,p.variant,'rainforest',x,z,1)end
 local c=V.require('DioramaConfig').contact
 contacts[#contacts+1]={x,z,c.treeRadius[1]*.5,c.treeRadius[2]*.5,c.treeStrength}
end
return R
