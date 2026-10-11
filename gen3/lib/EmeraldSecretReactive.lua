-- Live native metatile states; animation clocks, triggers and inventory stay in the engine.
local V=...;local R={}
local function active(d)
 local c=V.require('DioramaConfig').emeraldInteriors
 return c.enabled and c.secretBases.enabled and c.secretBases.furniture.enabled and c.secretBases.furniture.reactive.enabled and V.require('EmeraldSecretBases').kind(d)
end
local function effects(fx)
 if fx then return fx._list or{}end
 local ok,m=pcall(require,'src.core.game3.field_effects_rse');return ok and m._list or{}
end
local function visible(e)
 return e.name=='sand_pillar'and not e.hidden and(not e.delay or e.delay<=0)
end
function R.effectStamp(d,fx)
 if not active(d)then return ''end
 local keys={};for _,e in ipairs(effects(fx))do if visible(e)then keys[#keys+1]=e.x..':'..e.y end end
 table.sort(keys);return table.concat(keys,',')
end
function R.mask(o,L,ts,src,inside)
 if o.style~='breakDoor'or o.stage~=1 then return inside end
 -- The open frame encloses native floor pixels. They must be holes, including
 -- regions that a perimeter flood fill cannot reach.
 return V.require('EmeraldSecretOrnaments').mask({style='fenceWidth'},L,ts,src,inside)
end
function R.plan(d,add)
 if not active(d)then return end
 local L=d.midLayout;local animating={}
 for _,e in ipairs(effects())do if visible(e)then animating[math.floor((e.x-8)/16)..':'..math.floor((e.y-16)/16)]=true end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y);local style,stage
  for _,base in ipairs{0x338,0x33c,0x340,0x228}do
   if m>=base and m<base+3 then style=base==0x228 and 'mudBall'or 'balloon';stage=m-base;break end
  end
  if style then add({kind='secretDecor',style=style,x=x,y=y,w=16,h=16,stage=stage,noContact=true,skipContact=stage>0})
  elseif y+1<L.height then local lower=L:midAt(x,y+1)
   if(m==0x237 and lower==0x23f)or(m==0x26e and lower==0x276)then
    add({kind='secretDecor',style='breakDoor',x=x,y=y,w=16,h=32,stage=m==0x26e and 1 or 0,noContact=true})
   elseif(m==0x285 or m==0x286)and(lower==0x28d or lower==0x28e)then
    add({kind='secretDecor',style='sandFigure',x=x,y=y,w=16,h=32,noContact=true,animated=animating[x..':'..y],spec={w=1,h=2,permission=2,tiles={0x285,lower}}})
   end
  end
 end end
 -- Final burst tiles and broken sand remain native ground debris, not upright cards.
end
function R.build(o,draw,x,z,cfg)
 local c=cfg.secretBases.furniture.reactive;local k=o.style
 if k=='sandFigure'and o.animated then return true end
 if k=='balloon'or k=='mudBall'then
  local scale=k=='balloon'and c.balloonScale or c.mudScale
  draw(0,o.h,function(s,t)return{x+s,(o.h-t)*scale*V.require('Billboard').heightScale(),z+o.h}end)
 elseif k=='breakDoor'or k=='sandFigure'then
  local scale=k=='breakDoor'and c.doorScale or c.sandScale
  draw(0,o.h,function(s,t)return{x+s,(o.h-t)*scale*V.require('Billboard').heightScale(),z+o.h}end)
 else return false end
 return true
end
function R.sprites(d,fx)
 if not active(d)then return{}end
 local out={}
 for _,e in ipairs(effects(fx))do
  if visible(e)then
   local sheet,a=e.sheet,e.a;local q=sheet and a and sheet.quads[a.frame or 0]
   if q then
    local x,z=math.floor(e.x-sheet.fw/2),math.floor(e.y-sheet.fh/2);local base=z+sheet.fh
    local c=V.require('DioramaConfig').emeraldInteriors
    local height=sheet.fh*c.secretBases.furniture.reactive.sandScale*V.require('Billboard').heightScale()*c.heightScale
    out[#out+1]={image=sheet.image,quad=q,x=x,z=z,base=base,flip=a.hflip,vflip=a.vflip,
     surface={{x,height,base+.05},{x+sheet.fw,height,base+.05},{x+sheet.fw,0,base+.05},{x,0,base+.05}}}
   end
  end
 end
 return out
end
return R
