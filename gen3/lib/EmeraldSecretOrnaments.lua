-- Static native ornaments. Interactive tents/slides/traps have separate state requirements.
local V=...;local O={styles={[25]='brick',[26]='brick',[27]='brick',[35]='fenceLength',[36]='fenceWidth',[37]='tire',[42]='award',[43]='award',[44]='glass',[45]='tv',[46]='tv',[47]='tv'}}
function O.support(o,c)
 if o.style=='brick'then return c.brickHeight elseif o.style=='tire'then return c.tireHeight end
end
function O.mask(o,L,ts,src,inside)
 if o.style~='fenceLength'and o.style~='fenceWidth'then return inside end
 local pixel=V.require('BuildingMesh').pixel;local bg={}
 local function key(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 for t=0,15 do for s=0,15 do bg[key(pixel(ts,0x20a,s,t))]=true end end
 return function(s,t)return inside(s,t)and not bg[key(pixel(ts,src(s,t)))]end
end
function O.build(o,draw,x,z,cfg,src,inside,ts,out)
 local c=cfg.secretBases.furniture.ornaments;local k=o.style
 if k=='brick'or k=='tire'then
  local split=k=='brick'and c.brickSplit or c.tireSplit;local height=O.support(o,c)
  draw(0,split,function(s,t)return{x+s,height,z+o.h-split+t}end)
  draw(split,o.h,function(s,t)return{x+s,height*(o.h-t)/(o.h-split),z+o.h}end)
 elseif k=='fenceLength'then
  -- Long rail follows the map's north/south axis, standing above its footprint.
  draw(0,o.h,function(s,t)return{x+s,c.fenceHeight,z+t}end)
  local G=V.require('WorldGeometry');local height=c.fenceHeight*cfg.heightScale
  for t=0,o.h-1 do for s=0,o.w-1 do if inside(s,t)then
   for _,e in ipairs{{0,0,0,1,-1,0},{1,1,1,0,1,0},{1,0,0,0,0,-1},{0,1,1,1,0,1}}do
    if not inside(s+e[5],t+e[6])then
     -- Use the adjacent native wood, not the near-black silhouette outline,
     -- as the side material. The cap keeps every original outline pixel.
     local ss,tt=s,t
     for n=1,c.sideSampleInset do if inside(s-e[5]*n,t-e[6]*n)then ss,tt=s-e[5]*n,t-e[6]*n else break end end
     local m,u,v=src(ss,tt)
     local a,b={x+s+e[1],height,z+t+e[2]},{x+s+e[3],height,z+t+e[4]}
     G.quad(out,a,b,{b[1],0,b[3]},{a[1],0,a[3]},G.uv(ts,m,u,v,u+1,v+1,.5),c.sideShade)
    end
   end
  end end end
 elseif k=='fenceWidth'then
  -- Ignore the empty floor rows above/below the native rail when lifting it.
  local first,last=o.h,0
  for t=0,o.h-1 do for s=0,o.w-1 do if inside(s,t)then first=math.min(first,t);last=math.max(last,t+1)end end end
  if last>first then draw(first,last,function(s,t)return{x+s,(last-t)*c.fenceHeight/(last-first),z+o.h}end)end
 elseif k=='tv'then
  -- Antennas/ears are part of the upright silhouette, never a folded lid.
  draw(0,o.h,function(s,t)return{x+s,c.tvHeight*(o.h-t)/o.h*V.require('Billboard').heightScale(),z+o.h}end)
 elseif k=='award'or k=='glass'then
  draw(0,o.h,function(s,t)return{x+s,(o.h-t)*c.sculptureScale*V.require('Billboard').heightScale(),z+o.h}end)
 else return false end
 return true
end
return O
