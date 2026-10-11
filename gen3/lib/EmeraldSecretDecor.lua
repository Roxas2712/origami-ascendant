-- Read-only presentation of native, currently placed Secret Base decorations.
-- Match complete metatile patterns, not save slots or guessed collision rectangles.
local V=...;local D={plans=setmetatable({},{__mode='k'})}
local catalog
function D.catalog()
 if catalog then return catalog end
 local Native=require('src.core.game3.rse.decoration');local rows={};D.spriteGraphics={}
 for id=1,120 do local d=Native.info(id)
  if d and d.permission==Native.PERM.SPRITE then D.spriteGraphics[d.tiles[1]]=true end
  if d and(d.category<=2 or d.category==5 or(d.category==3 and (V.require('EmeraldSecretOrnaments').styles[id]or V.require('EmeraldSecretStructures').styles[id])))and d.permission~=Native.PERM.SPRITE then
   local w,h=Native.dims(id);local tiles={};for i,m in ipairs(d.tiles)do tiles[i]=m+0x200 end
   rows[#rows+1]={id=id,w=w,h=h,tiles=tiles,category=d.category,permission=d.permission}
  end
 end
 table.sort(rows,function(a,b)if a.w*a.h~=b.w*b.h then return a.w*a.h>b.w*b.h end;return a.id<b.id end)
 catalog=rows;return rows
end
local function active(d)
 local c=V.require('DioramaConfig').emeraldInteriors
 return c.enabled and c.secretBases.enabled and c.secretBases.furniture.enabled and V.require('EmeraldSecretBases').kind(d)
end
function D.plan(d,rows)
 local objects,under={},{};if not active(d)then return objects,under end
 local L=d.midLayout;local claimed={}
 local function add(o)
  objects[#objects+1]=o
  for yy=0,o.h/16-1 do for xx=0,o.w/16-1 do local i=(o.y+yy)*L.width+o.x+xx+1
   claimed[i]=true
   local actual=L:midAt(o.x+xx,o.y+yy);local expected=o.spec and o.spec.tiles[yy*o.spec.w+xx+1]
   under[i]=(o.style=='poster'or(expected and actual==expected+1))and 0x202 or 0x20a
   local native=L.cells[i]and L.cells[i].mid
   if o.style=='board'and(native==0x222 or native==0x223)then under[i]=native end
  end end
 end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x220 or m==0x221 or m==0x224 then add({kind='secretDecor',style='pc',x=x,y=y,w=16,h=16,mid=m,noContact=true})end
 end end
 V.require('EmeraldSecretReactive').plan(d,add)
 for _,s in ipairs(rows or D.catalog())do
  local furniture=V.require('DioramaConfig').emeraldInteriors.secretBases.furniture
  if s.category~=3 or(V.require('EmeraldSecretStructures').styles[s.id]and furniture.structures.enabled)or(V.require('EmeraldSecretOrnaments').styles[s.id]and furniture.ornaments.enabled)then
  for y=0,L.height-s.h do for x=0,L.width-s.w do local match=true
   for yy=0,s.h-1 do for xx=0,s.w-1 do
    local i=(y+yy)*L.width+x+xx+1;local m=L:midAt(x+xx,y+yy);local want=s.tiles[yy*s.w+xx+1]
    if claimed[i]or not(m==want or(s.permission==2 and yy==0 and m==want+1))then match=false;break end
   end;if not match then break end end
   if match then add({kind='secretDecor',style=({[0]='desk',[1]='chair',[2]='plant',[5]='poster'})[s.category]or V.require('EmeraldSecretOrnaments').styles[s.id]or V.require('EmeraldSecretStructures').styles[s.id],x=x,y=y,w=s.w*16,h=s.h*16,spec=s,noContact=true})end
  end end
 end end
 D.plans[L]={objects=objects,under=under};return objects,under
end
function D.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.secretBases.furniture;local PS=V.require('PaperSprite')
 local src,inside=V.require('EmeraldCableRooms').cutout(L,ts,o.x*16,o.y*16,o.w,o.h,o.spec and o.spec.permission==2 and{0x20a,0x202}or{0x20a})
 inside=V.require('EmeraldSecretOrnaments').mask(o,L,ts,src,inside)
 inside=V.require('EmeraldSecretReactive').mask(o,L,ts,src,inside)
 local function draw(y0,y1,point,mask)
  local vv=PS.build(ts,o.w,o.h,src,function(s,t)return t>=y0 and t<y1 and (mask or inside)(s,t)end,0,o.h,1,nil,function(s,t)
   local p=point(s,t);p[2]=p[2]*cfg.heightScale;return p
  end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 if V.require('EmeraldSecretReactive').build(o,draw,x,z,cfg)then
 elseif V.require('EmeraldSecretStructures').build(o,draw,x,z,cfg,inside)then
 elseif V.require('EmeraldSecretOrnaments').build(o,draw,x,z,cfg,src,inside,ts,out)then
 elseif o.style=='poster'then
  -- Hang the intact native poster in front of the restored wall. Draping
  -- its pixels over a rock relief distorts the art and hides it in crevices.
  draw(0,o.h,function(s,t)return{x+s,c.posterBase+c.posterHeight*(o.h-t)/o.h,z+o.h+c.posterOffset}end,function()return true end)
 elseif o.style=='desk'then
  local split=o.h==16 and 12 or o.h==32 and 26 or 42;local height=c.deskHeight;local front=o.h
  draw(0,split,function(s,t)return{x+s,height,z+front-split+t}end)
  draw(split,o.h,function(s,t)return{x+s,height*(o.h-t)/(o.h-split),z+front}end)
 elseif o.style=='chair'then
  draw(0,7,function(s,t)return{x+s,c.chairSeat+(c.chairHeight-c.chairSeat)*(7-t)/7,z+6}end)
  draw(7,10,function(s,t)return{x+s,c.chairSeat,z+6+(t-7)*2}end)
  draw(10,14,function(s,t)return{x+s,c.chairSeat*(14-t)/4,z+12}end)
 elseif o.style=='pc'then
  draw(0,2,function(s,t)return{x+s,c.pcHeight,z+10+t*2}end)
  draw(2,16,function(s,t)return{x+s,c.pcHeight*(16-t)/14,z+14}end)
 elseif o.style=='plant'then
  draw(0,o.h,function(s,t)return{x+s,(o.h-t)*c.plantScale*V.require('Billboard').heightScale(),z+o.h}end)
 end
 if contacts and not o.skipContact and o.style~='poster'then contacts[#contacts+1]={x+o.w/2,z+o.h-1,math.max(4,o.w*.38),2,c.contactStrength}end
end
function D.actorOffset(d,x,z,gid)
 if not active(d)then return end
 -- Native sprite decorations store graphics ids, not metatile ids. Never
 -- duplicate dolls/cushions as map geometry or lift trainers by position.
 D.catalog();if not D.spriteGraphics[gid]then return end
 local p=D.plans[d.midLayout];if not p then D.plan(d);p=D.plans[d.midLayout]end
 for _,o in ipairs(p.objects)do
  local support=o.style=='desk'and V.require('DioramaConfig').emeraldInteriors.secretBases.furniture.deskHeight or V.require('EmeraldSecretOrnaments').support(o,V.require('DioramaConfig').emeraldInteriors.secretBases.furniture.ornaments)
  if support and x+8>=o.x*16 and x+8<(o.x*16+o.w)and z+16>o.y*16 and z+16<=o.y*16+o.h then
   local cx,cy=math.floor(x/16),math.floor(z/16);local expected=o.spec.tiles[(cy-o.y)*o.spec.w+cx-o.x+1]
   if expected and d.midLayout:midAt(cx,cy)==expected then return support*V.require('DioramaConfig').emeraldInteriors.heightScale,0 end
  end
 end
end
return D
