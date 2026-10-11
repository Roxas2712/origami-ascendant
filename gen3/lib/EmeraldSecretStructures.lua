-- Traversable native decorations: original art, shared mesh/actor height functions.
local V=...;local S={styles={[31]='tent',[32]='tent',[33]='board',[34]='slide',[38]='stand'}}
local function clamp(x)return math.max(0,math.min(1,x))end
function S.height(style,x,z,c)
 if style=='board'then return c.boardHeight*math.min(clamp(z/c.boardRamp),clamp((32-z)/c.boardRamp))
 elseif style=='stand'then
  if z<=16 then return c.standHeight end
  if x<16 or x>=48 then return c.standHeight*clamp((32-z)/16)end
 elseif style=='slide'then
  if z<=16 then return c.slideHeight end
  if x<16 then return c.slideHeight*clamp((48-z)/16)end
  return c.slideHeight*clamp((48-z)/32)
 end
 return 0
end
function S.actorOffset(d,x,z)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.secretBases.furniture.structures
 if not(cfg.enabled and cfg.secretBases.enabled and cfg.secretBases.furniture.enabled and c.enabled and V.require('EmeraldSecretBases').kind(d))then return end
 local D=V.require('EmeraldSecretDecor');local p=D.plans[d.midLayout]
 if not p then D.plan(d);p=D.plans[d.midLayout]end
 for _,o in ipairs(p.objects)do if o.style=='board'or o.style=='stand'or o.style=='slide'then
  local s,t=x+8-o.x*16,z+16-o.y*16
  if s>=0 and s<o.w and t>=0 and t<=o.h then
   -- Plans can outlive a removal until the next draw. Validate the full pattern.
   local valid=true
   for yy=0,o.spec.h-1 do for xx=0,o.spec.w-1 do
    if d.midLayout:midAt(o.x+xx,o.y+yy)~=o.spec.tiles[yy*o.spec.w+xx+1]then valid=false end
   end end
   if valid then return (S.height(o.style,s,t,c)+c.groundBias)*cfg.heightScale,0 end
  end
 end end
end
function S.build(o,draw,x,z,cfg,inside)
 local c=cfg.secretBases.furniture.structures;local k=o.style
 if not S.styles[o.spec and o.spec.id]then return false end
 local function part(left,right,top,bottom,point)
  draw(top,bottom,function(s,t)local p=point(s,t);p[2]=p[2]+c.groundBias;return p end,function(s,t)return s>=left and s<right and inside(s,t)end)
 end
 local function surface(s,t)return{x+s,S.height(k,s,t,c),z+t}end
 if k=='board'then
  part(0,16,0,32,surface)
 elseif k=='stand'then
  part(0,64,0,16,surface)
  local function stair(s,t)return{x+s,c.standHeight*clamp((32-t)/16),z+t}end
  part(0,16,16,32,stair);part(48,64,16,32,stair)
  part(16,48,16,28,function(s,t)return{x+s,c.standHeight*(28-t)/12,z+16}end)
  part(16,48,28,32,function(s,t)return{x+s,0,z+t}end)
 elseif k=='slide'then
  part(0,32,0,16,surface)
  part(0,16,16,48,function(s,t)return{x+s,c.slideHeight*clamp((48-t)/16),z+t}end)
  part(16,32,16,48,function(s,t)return{x+s,c.slideHeight*clamp((48-t)/32),z+t}end)
  part(0,32,48,64,surface)
 elseif k=='tent'then
  local function roof(s)return c.tentHeight*math.min(clamp(s/8),clamp((48-s)/8))end
  -- Keep the native emblem on one roof panel; bend only the outer fabric.
  for _,a in ipairs{{0,8},{8,40},{40,48}}do
   part(a[1],a[2],0,32,function(s,t)return{x+s,roof(s),z+t*1.5}end)
  end
  -- Native flaps already have diagonal silhouettes. Their first opaque
  -- texel must meet the roof, rather than leaving a second triangular gap.
  for s=0,47 do if s<16 or s>=32 then
   local first=32;while first<48 and not inside(s,first)do first=first+1 end
   if first<48 then part(s,s+1,first,48,function(ss,t)return{x+ss,roof(ss)*(48-t)/(48-first),z+48}end)end
  end end
  -- Native doorway pixels remain on the floor: no opaque billboard across it.
  part(16,32,32,48,function(s,t)return{x+s,.03,z+t}end)
 end
 return true
end
return S
