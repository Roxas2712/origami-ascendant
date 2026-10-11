-- Measured Safari outdoor canopy. Original atlas pixels, no collision edits.
local V=...
local S={}
local mids={0x2f5,0x2f6,0x2f7,0x2fc,0x2fd,0x2fe,0x2ff,
 0x304,0x305,0x306,0x307,0x30b,0x30c,0x30d,0x30e,0x30f,
 0x310,0x311,0x312,0x313,0x314,0x315,0x316,0x317,0x318,0x319,0x31a,
 0x31d,0x31e,0x31f,0x320,0x321,0x322,0x323,0x325,0x326,0x327}
local maps={FR_SAFARI_ZONE_CENTER=true,FR_SAFARI_ZONE_EAST=true,FR_SAFARI_ZONE_NORTH=true,FR_SAFARI_ZONE_WEST=true}
local tiles={};for _,m in ipairs(mids)do tiles[m]=true end
function S.applies(d)
 return d and maps[d.id or d.name]==true and (d.renderPair or d.pair)=='general__rom_082d4b54'
  and V.require('DioramaConfig').safariForest.enabled
end
function S.tile(d,m)return S.applies(d)and tiles[m]==true end
function S.anchor(d,x,y)
 if not S.applies(d)then return end
 local L=d.midLayout;local m=L:midAt(x,y)
 if (m==0x2fe or m==0x31e or m==0x319)and tiles[L:midAt(x-1,y)]and tiles[L:midAt(x+1,y)]then
  return {x=x,y=y,foot=(y-1)*16+61}
 end
end
function S.plan(d)
 local mask={};if not S.applies(d)then return mask end
 local L=d.midLayout
 for y=0,L.height-1 do for x=0,L.width-1 do
  if tiles[L:midAt(x,y)]then mask[y*L.width+x+1]=S.anchor(d,x,y)or true end
 end end
 return mask
end
function S.template(ts)
 local cfg=V.require('DioramaConfig').safariForest
 local rows={{0x315,0x316,0x317},{0x31d,0x31e,0x31f},{0x305,0x306,0x307}}
 local pixel=V.require('BuildingMesh').pixel
 -- Measured native canopy ends at row40. Row41+ includes trunk/ground art.
 local base=41
 local function source(x,y)return rows[math.floor(y/16)+1][math.floor(x/16)+1],x%16,y%16 end
 local leaves={}
 for y=0,base-1 do for x=0,47 do
  local r,g,b,a=pixel(ts,source(x,y))
  if a>.5 and g>r*1.08 and b<g*.60 then leaves[y*48+x+1]=true end
 end end
 -- The source also contains disconnected decorative leaf tips. Standing
 -- those separately looks like floating confetti; retain the main crown.
 local seen,inside={},{};local largest=0
 for k in pairs(leaves)do if not seen[k]then
  local q={k};seen[k]=true;local i=1
  while q[i]do local at=q[i];i=i+1;local x,y=(at-1)%48,math.floor((at-1)/48)
   for _,d in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do local xx,yy=x+d[1],y+d[2];local n=yy*48+xx+1
    if xx>=0 and xx<48 and yy>=0 and yy<base and leaves[n]and not seen[n]then seen[n]=true;q[#q+1]=n end
   end
  end
  if #q>largest then largest=#q;inside={};for _,n in ipairs(q)do inside[n]=true end end
 end end
 local out=V.require('PaperSprite').build(ts,48,base,
  source,function(x,y)return inside[y*48+x+1]==true end,
  -24,base,1,function(x,y)
   local t=math.max(0,(y/base-.70)/.30)
   return cfg.crownShade*(1-t)+cfg.lowerShade*t
  end,nil,.5)
 local Camera=V.require('Camera');local perspective=Camera.projection()=='perspective'
 local angle=perspective and math.rad(V.require('DioramaConfig').trees.tiltDegrees)or 0
 local compensation=perspective and 1/math.max(.25,math.cos(angle)-math.tan(Camera.elevation())*math.sin(angle))or 1
 for _,v in ipairs(out)do
  v[1]=v[1]*cfg.widthScale;local h=v[2]*cfg.heightScale*compensation
  v[2]=h*math.cos(angle);v[3]=h*math.sin(angle)
  if (v[9]or 0)>0 then v[9]=1+V.require('DioramaConfig').dynamicTexture.treeWeight end
 end
 return out
end
function S.place(out,ts,p,ox,oz,instances,contacts)
 local x,z=(p.x+ox)*16+8,p.foot+oz*16
 if instances then
  local g=instances.props.safariTree
  if not g then g={mid=0x31e,kind='safariTree',ground=1,placements={}};instances.props.safariTree=g end
  g.placements[#g.placements+1]={x,z,1}
 else V.require('Props').stamp(out,ts,0x31e,'safariTree',x,z,1)end
 local c=V.require('DioramaConfig').contact
 contacts[#contacts+1]={x,z,c.treeRadius[1]*1.35,c.treeRadius[2],c.treeStrength}
end
return S
