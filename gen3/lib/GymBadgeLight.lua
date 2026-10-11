-- Gym badge light, ported from VASC's GymSkylights: the badge is painted as
-- stained glass in a ceiling skylight and projected onto the arena floor as
-- coloured light. By day the sun drives it (drifting slightly with the sun
-- bearing), at night a warm roof lamp keeps it glowing more softly.
-- Artwork only; no gameplay state, items or badge flags are read or changed.
local V=...
local M={textures={},unavailable={}}
local badges={FR_PEWTER_CITY_GYM='boulder',FR_CERULEAN_CITY_GYM='cascade',FR_VERMILION_CITY_GYM='thunder',
 FR_CELADON_CITY_GYM='rainbow',FR_FUCHSIA_CITY_GYM='soul',FR_SAFFRON_CITY_GYM='marsh',
 FR_CINNABAR_ISLAND_GYM='volcano',FR_VIRIDIAN_CITY_GYM='earth',FR_SAFFRON_CITY_DOJO='dojo'}
local hoennBadges={EM_RUSTBORO_CITY_GYM=1,EM_DEWFORD_TOWN_GYM=2,EM_MAUVILLE_CITY_GYM=3,
 EM_LAVARIDGE_TOWN_GYM_1F=4,EM_PETALBURG_CITY_GYM=5,
 EM_FORTREE_CITY_GYM=6,EM_MOSSDEEP_CITY_GYM=7,EM_SOOTOPOLIS_CITY_GYM_1F=8}
for id,index in pairs(hoennBadges)do badges[id]='hoenn'..index end
M.badges=badges
-- Mean glass colour per badge for the light column.
local tint={boulder={.78,.76,.70},cascade={.45,.75,1},thunder={1,.84,.35},rainbow={1,.72,.80},
 soul={1,.55,.80},marsh={1,.80,.35},volcano={1,.52,.30},earth={.55,.90,.50},dojo={1,.70,.40}}
for _,badge in pairs(badges)do if badge:match('^hoenn')then tint[badge]={.88,.88,1}end end
local lead={.025,.032,.045}
function M.badge(def)return def and badges[def.id or def.name]end
function M.paint(g,badge,W,H)
 g.push();g.scale(W/256,H/256);g.clear(lead[1],lead[2],lead[3],1)
 local function poly(c,p)
  g.setColor(c[1],c[2],c[3],1)
  for _,tri in ipairs(love.math.triangulate(p))do g.polygon('fill',tri)end
  g.setColor(lead[1],lead[2],lead[3],1);g.setLineWidth(2.5);g.polygon('line',p)
 end
 local function circle(c,x,y,r)
  g.setColor(c[1],c[2],c[3],1);g.circle('fill',x,y,r,48)
  g.setColor(lead[1],lead[2],lead[3],1);g.setLineWidth(3);g.circle('line',x,y,r,48)
 end
 local function line(x,y,xx,yy)g.setColor(lead[1],lead[2],lead[3],1);g.setLineWidth(2);g.line(x,y,xx,yy)end
 local glass=badge=='dojo'and {{.68,.38,.14},{.90,.67,.32},{.97,.84,.54},{.74,.51,.25}}
  or {{.28,.49,.67},{.49,.67,.73},{.65,.75,.77},{.39,.59,.70}}
 for i=0,23 do
  local a,b=i*math.pi/12,(i+1)*math.pi/12
  local ra=129/math.max(math.abs(math.cos(a)),math.abs(math.sin(a)))
  local rb=129/math.max(math.abs(math.cos(b)),math.abs(math.sin(b)))
  poly(glass[i%4+1],{128,128,128+ra*math.cos(a),128+ra*math.sin(a),128+rb*math.cos(b),128+rb*math.sin(b)})
 end
 circle({.13,.23,.33},128,128,86)
 if badge=='dojo'then
  poly({.78,.24,.13},{91,188,91,152,72,130,66,109,78,98,90,106,90,81,99,72,113,75,120,66,135,69,142,77,157,76,168,85,168,119,159,145,151,156,151,188})
  poly({.96,.64,.30},{91,152,115,142,157,145,151,160,151,177,91,177})
  line(113,76,113,110);line(140,78,140,110);line(90,109,113,119);line(113,119,156,119);line(91,177,151,177)
 elseif badge=='boulder'then
  local p={94,61,161,64,193,105,181,167,136,193,77,167,63,107}
  poly({.67,.64,.57},p)
  for i=1,#p,2 do local j=i+2;if j>#p then j=1 end
   poly(i%4==1 and {.82,.79,.68}or {.49,.51,.54},{128,126,p[i],p[i+1],p[j],p[j+1]})
  end
 elseif badge=='cascade'then
  poly({.12,.63,.98},{128,53,171,113,186,145,180,172,157,191,127,198,96,191,77,172,71,146,84,115})
  poly({.37,.85,1},{128,68,132,140,86,164,87,136})
  poly({.06,.34,.73},{132,140,174,148,166,179,127,188})
 elseif badge=='thunder'then
  local p={};for i=0,15 do local a=-math.pi/2+i*math.pi/8;local r=i%2==0 and 79 or 42;p[#p+1]=128+math.cos(a)*r;p[#p+1]=128+math.sin(a)*r end
  poly({1,.73,.08},p);circle({1,.92,.39},128,128,29)
  for i=1,#p,4 do line(128,128,p[i],p[i+1])end
 elseif badge=='rainbow'then
  local cols={{1,.28,.27},{1,.57,.13},{1,.89,.2},{.36,.79,.32},{.16,.70,.91},{.30,.39,.84},{.65,.37,.87},{.94,.39,.69}}
  for i=0,7 do local a=i*math.pi/4;local p={128,128}
   for j=-2,2 do local t=a+j*.15;p[#p+1]=128+math.cos(t)*(j==0 and 79 or 68);p[#p+1]=128+math.sin(t)*(j==0 and 79 or 68)end
   poly(cols[i+1],p)
  end;circle({1,.93,.62},128,128,25)
 elseif badge=='soul'then
  poly({.95,.35,.65},{128,94,151,69,177,72,194,94,191,121,176,145,128,194,80,145,65,120,63,94,79,73,103,68})
  line(128,94,128,192);line(69,104,128,141);line(188,104,128,141)
 elseif badge=='marsh'then
  circle({.90,.51,.08},128,128,76);circle({1,.84,.18},128,128,58);circle({1,.95,.49},128,128,31)
  for i=0,7 do local a=i*math.pi/4;line(128+31*math.cos(a),128+31*math.sin(a),128+76*math.cos(a),128+76*math.sin(a))end
 elseif badge=='volcano'then
  poly({.96,.26,.13},{128,54,144,87,166,70,163,106,192,105,177,133,192,153,163,173,128,196,90,177,65,153,82,128,65,106,95,108,93,71,113,87})
  poly({1,.70,.15},{128,93,157,131,147,161,128,178,107,160,99,132})
  poly({1,.93,.45},{128,119,141,147,128,164,116,149})
 elseif badge=='earth'then
  poly({.23,.69,.30},{169,57,177,102,167,148,137,182,89,192,70,157,77,112,112,79})
  poly({.53,.88,.33},{169,57,128,124,89,192,70,157,77,112,112,79})
  line(85,202,169,57);line(111,151,76,124);line(133,113,119,78);line(111,151,161,145)
 end
 g.pop()
end
local function hoennTexture(badge)
 local raw=require('src.core.game3.dataset').cache():read('data/generated/gba/rse/trainer_card/badges.png')
 if not raw then return nil end
 local file=love.filesystem.newFileData(raw,'hoenn-badges.png')
 local data=love.image.newImageData(file);file:release()
 if data:getWidth()~=128 or data:getHeight()~=16 then data:release();return nil end
 local image=love.graphics.newImage(data);data:release();image:setFilter('nearest','nearest')
 local quad=love.graphics.newQuad((tonumber(badge:match('%d+'))-1)*16,0,16,16,128,16)
 local canvas=love.graphics.newCanvas(256,256,{dpiscale=1,msaa=0})
 local g=love.graphics;g.push('all');g.origin();g.setCanvas(canvas);g.setShader();g.setDepthMode();g.clear(.025,.032,.045,1)
 g.setColor(1,1,1,1);g.setBlendMode('alpha');g.draw(image,quad,40,40,0,11,11);g.pop()
 image:release();quad:release();canvas:setFilter('linear','linear');return canvas
end
function M.texture(badge)
 if M.unavailable[badge]then return nil end
 if M.textures[badge]then return M.textures[badge]end
 if badge:match("^hoenn")then local texture=hoennTexture(badge);M.textures[badge]=texture;M.unavailable[badge]=not texture;return texture end
 local c=love.graphics.newCanvas(256,256,{dpiscale=1,msaa=0})
 love.graphics.push('all');love.graphics.origin();love.graphics.setCanvas(c);love.graphics.setShader();love.graphics.setDepthMode()
 love.graphics.setBlendMode('alpha');M.paint(love.graphics,badge,256,256);love.graphics.pop()
 c:setFilter('linear','linear');M.textures[badge]=c;return c
end
-- Returns the projection for this frame, or nil outside gyms.
function M.prepare(def)
 local cfg=V.require('DioramaConfig').gymBadges
 local badge=cfg and cfg.enabled and M.badge(def);if not badge then return nil end
 local L=def.midLayout;if not L then return nil end
 if def.id=='EM_PETALBURG_CITY_GYM'and require('src.core.game3.player').py>=128 then return nil end
 local DN=V.require('DayNight');local t=DN.time()
 local bearing,elevation,moon=DN.bodyAt(t)
 local sun=math.max(0,math.min(1,DN.strengthAt(t)))*(moon and 0 or 1)
 local w,d=L.width*16,L.height*16
 local room=cfg.rooms and cfg.rooms[def.id or def.name]
 local size=room and room.size or math.min(cfg.maxSize,math.min(w,d)*cfg.roomFraction)
 local a=math.rad(bearing);local drift=size*.14*(1-math.sin(math.rad(math.max(0,elevation)))*.65)*sun
 local strength=cfg.dayStrength*sun+cfg.nightStrength*(1-sun)
 local cx,cz=w/2+cfg.offset[1],d*.53+cfg.offset[2]
 if def.id=='EM_PETALBURG_CITY_GYM'then cx,cz=80,80 end
 if def.id=='EM_MOSSDEEP_CITY_GYM'then cx,cz=384,176 end
 if room and room.at then cx,cz=room.at[1],room.at[2]end
 local texture=M.texture(badge);if not texture then return nil end
 return {texture=texture,area={cx-math.cos(a)*drift,cz-math.sin(a)*drift,size,strength},
  tint=tint[badge],column={x=cx,z=cz,size=size},badge=badge,sun=sun}
end
-- Light column falling from the skylight (drawn with the forest beam mesh).
function M.shafts(state,out)
 local cfg=V.require('DioramaConfig').gymBadges
 if not state or not cfg.column then return end
 local c=state.tint;local k=cfg.columnAlpha*(.35+.65*state.sun)
 out[#out+1]={x=state.column.x,z=state.column.z+state.column.size*.25,color={c[1],c[2],c[3]},fade=1,
  width=state.column.size*.9,height=cfg.columnHeight,alpha=k,slant=0,spread=1.1}
end
function M.release()for k,t in pairs(M.textures)do t:release();M.textures[k]=nil end;M.unavailable={}end
return M
