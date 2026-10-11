-- Fixed Tanoby Key rock shell only. Movable Strength boulders, socket tiles,
-- scripts and jump/exit behavior remain owned by the native game engine.
local V=...;local R={masks=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').terrain.frTanobyKey end
function R.profile(d)
 return d and cfg().enabled and (d.renderPair or d.pair)=='general__rom_082d4e0c'
  and tonumber(d.mapType)==4 and d.id=='FR_SEVEN_ISLAND_SEVAULT_CANYON_TANOBY_KEY' and true or nil
end
local function active(d)return R.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
function R.kind(d,c)
 if not active(d)or not c then return end
 if c.coll>=0xa0 and c.coll<=0xa7 then return 'frTanobyLedge'end
 if(c.coll~=7 and c.coll~=255)or c.mid<0x280 or c.mid==0x2b7 or(c.mid>=0x318 and c.mid<=0x31a)then return end
 return 'frTanobyWall'
end
function R.height(kind)return kind=='frTanobyLedge'and cfg().ledgeHeight or cfg().wallHeight end
local floors={[0xd6c584]=true,[0xe6dea5]=true,[0xad944a]=true,[0xc5ad6b]=true}
local function color(ts,m,x,y)local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y);return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local function donor(m)
 return m
end
function R.mask(ts,m)
 local cache=R.masks[ts];if not cache then cache={};R.masks[ts]=cache end
 if cache[m]then return cache[m]end
 -- This secondary palette separates pale sand from ochre rock highlights.
 local mask={count=0};for y=0,15 do for x=0,15 do local yes=not floors[color(ts,m,x,y)];mask[y*16+x+1]=yes;if yes then mask.count=mask.count+1 end end end
 cache[m]=mask;return mask
end
function R.stamp(out,d,ts,x,y,ox,oz)
 local L=d.midLayout;local c=L:cellAt(x,y);local kind=R.kind(d,c);if not kind then return false end
 local G=V.require('WorldGeometry');local h=R.height(kind);local m=donor(c.mid);local mask=R.mask(ts,m);local xx,zz=(x+ox)*16,(y+oz)*16
 G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,0x2fc),1)
 local first=#out+1
 local dirs={{0,1},{0,-1},{1,0},{-1,0}}
 local neighbors={[0]={[0]=mask}};local enclosed=mask.count==256
 for _,dir in ipairs(dirs)do
  local dx,dy=dir[1],dir[2];local other=L:cellAt(x+dx,y+dy);local k=R.kind(d,other)
  local ink=k and R.height(k)>=h and R.mask(ts,donor(other.mid))or false
  neighbors[dy]=neighbors[dy]or{};neighbors[dy][dx]=ink
  if not ink or ink.count~=256 then enclosed=false end
 end
 local function occupied(sx,sy)
  local ink=neighbors[math.floor(sy/16)][math.floor(sx/16)]
  return ink and ink[(sy%16)*16+sx%16+1]
 end
 if mask.count==256 then G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m,0,0,16,16,.5),1)
 else for sy=0,15 do local sx=0;while sx<16 do if mask[sy*16+sx+1]then local a=sx;repeat sx=sx+1 until sx==16 or not mask[sy*16+sx+1]
  G.quad(out,{xx+a,h,zz+sy},{xx+sx,h,zz+sy},{xx+sx,h,zz+sy+1},{xx+a,h,zz+sy+1},G.uv(ts,m,a,sy,sx,sy+1,.5),1)
 else sx=sx+1 end end end end
 -- Full neighbouring caps hide every side. Otherwise only a full cap's
 -- perimeter can expose a face; preserve the original emitted face order.
 if not enclosed then
 for sy=0,15 do local step=mask.count==256 and sy>0 and sy<15 and 15 or 1
 for sx=0,15,step do if mask[sy*16+sx+1]then
  for _,dir in ipairs(dirs)do
   if not occupied(sx+dir[1],sy+dir[2])then
    local a,b,u;if dir[1]==0 then local z=zz+sy+(dir[2]>0 and 1 or 0);a={xx+sx,z};b={xx+sx+1,z};u=sx
    else local xp=xx+sx+(dir[1]>0 and 1 or 0);a={xp,zz+sy};b={xp,zz+sy+1};u=sy end
    G.quad(out,{a[1],h,a[2]},{b[1],h,b[2]},{b[1],0,b[2]},{a[1],0,a[2]},G.uv(ts,0x30e,u,0,u+1,16,.5),cfg().sideShade)
   end
  end
 end end end
 end
 for i=first,#out do out[i][9]=-2 end
 return true
end
function R.floor(out,d,ts,x,y,ox,oz)
 if not active(d)then return false end
 local m=d.midLayout:midAt(x,y)
 if m~=0x2b7 then return false end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,0x2fc),1);return true
end
function R.objects(out,d,ts,ox,oz,contacts)
 if not active(d)then return end
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local L=d.midLayout;local C=cfg()
 local function place(v,x,z)for _,p in ipairs(v)do out[#out+1]=G.place(p,(x+ox)*16,(z+oz)*16)end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x2b7 then
   place(P.build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return R.mask(ts,m)[t*16+s+1]end,0,16,C.rockScale,function()return 1 end,nil,.5),x,y+1)
   contacts[#contacts+1]={(x+ox)*16+8,(y+oz+1)*16,C.rockContactWidth,C.contactDepth,C.contactStrength}
  end
 end end
end
return R
