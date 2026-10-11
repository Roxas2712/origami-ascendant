-- A timed thank-you between the Ascendant intro and native map/music boot.
local V=...
local T={duration=1.5}
function T.new()
 local bytes=assert(V.mod:read('gen3/integrated/ascendant_startup/assets/support-omegadias.png'))
 local data=love.filesystem.newFileData(bytes,'support-omegadias.png')
 local logo=love.graphics.newImage(data);data:release();logo:setFilter('linear','linear')
 local zeroData=love.filesystem.newFileData(assert(V.mod:read('gen3/integrated/ascendant_startup/assets/support-zerostig.png')),'support-zerostig.png')
 local zero=love.graphics.newImage(zeroData);zeroData:release();zero:setFilter('linear','linear')
 return {logo=logo,zero=zero,font=love.graphics.newFont(28),age=0}
end
function T.draw(t,w,h)
 local g=love.graphics;g.push('all');g.origin();g.setShader();g.setScissor();g.setDepthMode()
 g.setColor(0,0,0,1);g.rectangle('fill',0,0,w,h)
 local scale=math.min(w/680,h/400,1.5);g.translate(w/2,h/2);g.scale(scale);g.setFont(t.font)
 g.setColor(.92,.95,1,1);g.printf('Thanks to',-300,-180,600,'center')
 g.setColor(1,1,1,1);local os=340/t.logo:getWidth();g.draw(t.logo,-170,-145,0,os,os)
 g.setColor(.92,.95,1,1);g.printf('and',-300,-26,600,'center')
 local zs=430/t.zero:getWidth();g.setColor(1,1,1,1);g.draw(t.zero,-215,20,0,zs,zs);g.pop()
end
function T.release(t)if not t then return end;for _,k in ipairs{'logo','zero','font'}do if t[k]then t[k]:release();t[k]=nil end end end
return T
