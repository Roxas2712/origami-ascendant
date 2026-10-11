-- Route gate statues share floor decoration, pedestal and figure in one
-- native drawing. Keep all three surfaces separate without replacing the art.
local V=...;local S={}
local variants={{0x30e,0x331,0x30f,0x333,0x32f,0x334,0x335,0x336,0x337},
 {0x330,0x32e,0x332,0x333,0x32f,0x334,0x335,0x336,0x337}}
local function cfg()return V.require('DioramaConfig').interiors.gateStatues end
function S.plan(d,objects,mask)
 local L=d.midLayout
 if not cfg().enabled or not L or d.mapType~=8 or d.pair~='house'or not(d.id or d.name or''):match('^FR_ROUTE_')then return end
 for y=0,L.height-3 do for x=0,L.width-3 do for _,p in ipairs(variants)do
  local complete=true;for i,m in ipairs(p)do if L:midAt(x+(i-1)%3,y+math.floor((i-1)/3))~=m then complete=false;break end end
  if complete then
   objects[#objects+1]={kind='gateStatue',x=x,y=y}
   for yy=y,y+2 do for xx=x,x+2 do mask[yy*L.width+xx+1]={mid=0,void=true,separateSurface=true}end end
  end
 end end end
end
function S.build(out,objects,L,ts,ox,oz,contacts)
 if not cfg().enabled then return end
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local B=V.require('BuildingMesh');local c=cfg()
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local fg={[0x7b7b7b]=true,[0x52526b]=true,[0xb5b5a5]=true,[0xdee6e6]=true,[0xffffff]=true}
 for _,o in ipairs(objects)do if o.kind=='gateStatue'then
  local x,z=(o.x+ox)*16,(o.y+oz)*16
  local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
  local function uv(s,t)local m,u,v=src(s,t);return G.uv(ts,m,u,v,u+1,v+1,.5)end
  local function body(s,t)
   if s<16 or s>=32 or t>=32 then return false end
   local m,u,v=src(s,t);return fg[rgb(B.pixel(ts,m,u,v))]or false
  end
  -- Recover the covered centre from the exposed row at native x=14. It
  -- contains the same blue/cream horizontal mat bands, including the rim.
  local function ground(s,t)
   if s>=16 and s<32 and t<32 then
    if t<8 then return 0x281,s%16,t%16 end
    return src(14,t)
   end
   return src(s,t)
  end
  local floor=P.build(ts,48,48,ground,function()return true end,0,48,1,nil,function(s,t)return{x+s,0,z+t}end,.5)
  for _,v in ipairs(floor)do out[#out+1]=v end
  local function band(lo,hi,project)
   local vv=P.build(ts,48,48,src,function(s,t)return t>=lo and t<hi and body(s,t)end,0,48,1,nil,project,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
  end
  local h,front,depth=c.pedestalHeight,c.front,c.pedestalDepth
  band(17,20,function(s,t)return{x+s,h,z+front-depth+(t-17)*depth/3}end)
  band(20,32,function(s,t)return{x+s,h*(32-t)/12,z+front}end)
  V.require('GateLighting').box(L,x+16,0,z+front-depth,16,h,depth,false)
  local edge=uv(18,23)
  for _,s in ipairs({16,32})do G.quad(out,{x+s,h,z+front-depth},{x+s,h,z+front},{x+s,0,z+front},{x+s,0,z+front-depth},edge,c.sideShade)end
  G.quad(out,{x+32,h,z+front-depth},{x+16,h,z+front-depth},{x+16,0,z+front-depth},{x+32,0,z+front-depth},edge,c.sideShade)
  local scale=c.figureScale*V.require('Billboard').heightScale()
  band(0,17,function(s,t)return{x+s,h+(17-t)*scale,z+front-c.figureInset}end)
  contacts[#contacts+1]={x+24,z+front,8,c.contactRadius,c.contactStrength}
 end end
end
return S
