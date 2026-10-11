-- Additional room families measured from native FireRed drawings. These
-- descriptors reuse the same surface builders; no replacement art is loaded.
local P={}
local families={building__rom_082d4f5c="school",building__rom_082d4e6c="department",pewter_gym="dojo"}
function P.family(def)
 if families[(def.renderPair or def.pair)] then return families[(def.renderPair or def.pair)] end
 if (def.renderPair or def.pair)=="oak_lab" then return "laboratory" end
end
function P.floor(def)
 local f=P.family(def)
 if f=="school" then return 0x29e elseif f=="department" then return 0x2c3 elseif f=="dojo" then return 0x294 elseif f=="laboratory" and def.id~="FR_OAKS_LAB" then return 0x81 end
end
function P.plan(def,api)
 local L=def.midLayout;local family=P.family(def)
 local panel,claim,add,clear=api.panel,api.claim,api.add,api.clear
 local lab=family=="laboratory" and def.id~="FR_OAKS_LAB"
 for y=1,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y)
  if lab then
   if m==0x94 and L:midAt(x,y-1)==0x8c then
    add({kind="plant",x=x,y=y,ground=0x81});claim(x,y-1,0x81);claim(x,y,0x81)
   elseif m==0x6f and L:midAt(x+1,y)==0x8f then
    add({kind="labbench",x=x,y=y})
    for dy=0,3 do for dx=0,1 do claim(x+dx,y+dy)end end
    local upper=panel(x,y,1,0,4,20,8,m,2,8,12);upper.front=13;upper.contour=true
    upper.background={0x81};upper.backgroundPixels={{0x8f,4,8},{0x8f,4,12}}
    local lower=panel(x+1,y+1,1,8,12,28,8,0x300,2,8,12);lower.front=24;lower.contour=true
    lower.background=upper.background;lower.backgroundPixels=upper.backgroundPixels
   elseif m==0x2cb then
    add({kind="labstool",x=x,y=y});claim(x,y,0x81)
   elseif y==1 and m==0x62 then
    panel(x,0,1,12,18,43,10,m,1,7).front=44
   elseif y==1 and m==0x301 and L:midAt(x+1,y)==0x302 then
    panel(x,0,2,12,16,45,12,m,1,6).front=44
   end
  elseif family=="school" then
   if y==1 and m==0x29b then panel(x,0,2,12,20,43,12,m,1,8).front=43
   elseif m==0x291 then
    add({kind="surfaceTable",x=x,y=y,w=2,cap=13,split=26,front=33,depth=20,height=12,frameY=28})
    for dy=0,1 do for dx=0,1 do claim(x+dx,y+dy)end end
   elseif m==0x288 then add({kind="surfaceTable",x=x,y=y,w=1,cap=8,split=15,front=15,depth=11,height=7,frameY=15});claim(x,y)
   elseif m==0x289 or m==0x28a then
    add({kind="plant",x=x,y=y,ground=0x29e});claim(x,y-1);claim(x,y)
   end
  elseif family=="dojo" and def.id=="FR_PEWTER_CITY_GYM" then
   if m==0x29b or m==0x2a2 or m==0x2a3 or m==0x2a4 then
    add({kind="rock",x=x,y=y,ground=0x294});claim(x,y)
   elseif m==0x2af then
    add({kind="standing",x=x,y=y,w=1,pixelH=30,sy=2,depth=10,front=31,ground=0x294})
    claim(x,y);claim(x,y+1)
   end
  elseif family=="department" then
   if m==0x320 and (L:midAt(x,y-1)==0x310 or L:midAt(x,y-1)==0x318) then
    local w=L:midAt(x+1,y)==0x321 and 2 or 1
    add({kind="gondola",x=x,y=y-1,w=w,department=true})
    for dy=-1,2 do for dx=0,w-1 do claim(x+dx,y+dy)end end
   elseif m==0x306 and L:midAt(x+1,y)==0x307 and L:midAt(x,y-1)==0x29b then
    panel(x,y-1,2,8,16,45,12,m,1,6)
   elseif m==0x2f8 and L:midAt(x+1,y)==0x2f9 then
    local w=(L:midAt(x+2,y)==0x2fa or L:midAt(x+2,y)==0x303) and 3 or 2
    panel(x,y, w,0,12,25,14,m,2,14)
   elseif m==0x338 and L:midAt(x+1,y)==0x339 then
    panel(x,y,2,0,19,32,20,m,1,12)
   end
  end
 end end
end
return P
