-- Rendered from the existing Cobblemon models; no live 3D loading at startup.
local M={duration=11.6,logoAt=6.16}
local function clamp(t)return math.max(0,math.min(1,t))end
local function smooth(t)t=clamp(t);return t*t*(3-2*t)end
local function mix(a,b,t)return a+(b-a)*t end
function M.new(read)
 local self={images={},quads={},duration=M.duration};local Ball=assert((loadstring or load)(assert(read('VoxelBall.lua'))))()
 local ok,err=pcall(function()
  for _,name in ipairs{'ascendant-start','pikachu-atlas','eevee-atlas','mew-atlas'}do
   local fd=love.filesystem.newFileData(assert(read('assets/'..name..'.png')),name..'.png')
   local yes,img=pcall(love.graphics.newImage,fd);fd:release();assert(yes,img)
   self.images[name]=img;img:setFilter('linear','linear')
  end
  for i=0,63 do self.quads[i]=love.graphics.newQuad((i%8)*256,math.floor(i/8)*256,256,256,2048,2048)end
 end)
 function self:release()
  if self.sound then self.sound:stop();self.sound:release();self.sound=nil end
  for _,img in pairs(self.images)do img:release()end;self.images={}
  for _,q in pairs(self.quads)do q:release()end;self.quads={}
 end
 if not ok then self:release();error(err)end
 -- Audio is optional: a device without an audio backend still gets the intro.
 pcall(function()
  local fd=love.filesystem.newFileData(assert(read('assets/ascendant-chime.wav')),'ascendant-chime.wav')
  local yes,s=pcall(love.audio.newSource,fd,'static');fd:release();assert(yes,s);self.sound=s
 end)
 function self:play(volume)if self.sound and volume>0 then self.sound:setVolume(volume);self.sound:play()end end
 function self:draw(t,w,h,animationTime)
  animationTime=animationTime or t
  local g=love.graphics;g.push('all');g.setCanvas();g.origin();g.setShader();g.setScissor();g.setDepthMode();if g.setStencilMode then g.setStencilMode()else g.setStencilTest()end;g.setBlendMode('alpha')
  g.setColor(0,0,0,1);g.rectangle('fill',0,0,w,h)
  local scale=math.min(w/1280,h/720);g.translate((w-1280*scale)/2,(h-720*scale)/2);g.scale(scale)
  local appear=smooth(t/.35);local fade=1-smooth((t-11)/.6);local alpha=appear*fade
  local roll=smooth((t-.2)/4.6);local turn=smooth((t-4.85)/.9);local reveal=smooth((t-M.logoAt)/.48)
  -- Quiet pool of light anchors the two balls without a loading bar or UI.
  for i=18,1,-1 do
   g.setColor(.055,.13,.30,.008*alpha);g.ellipse('fill',640,mix(595,671,reveal),230+i*20,6+i*1.8)
  end
  for index,name in ipairs{'pikachu','eevee'}do
   local side=index==1 and -1 or 1
   local x=640+side*mix(570,130,roll);x=mix(x,640+side*130,reveal)
   local y=mix(541,627,reveal)
   local size=mix(name=='pikachu'and 1.14 or 1.02,name=='pikachu'and .91 or .83,reveal)
   local radius=mix(66,49,reveal)
   local travelled=x-(640+side*570)
   local spin=-travelled/(440/(math.pi*2))
   local ballTop=Ball.draw(g,x,y,radius,spin,alpha)
   local frame
   if t<4.85 then frame=math.floor(math.abs(travelled)/112*24)%24
   elseif t<5.75 then frame=24+math.min(19,math.floor((t-4.85)/.9*20))
   else frame=44+math.floor((animationTime-5.75)*24)%20 end
   local bob=0
   local lean=side*.055*math.sin(roll*math.pi)*(1-turn)
   g.push();g.translate(x,ballTop+3+bob);g.rotate(lean)
   g.setBlendMode('alpha','premultiplied');g.setColor(alpha,alpha,alpha,alpha)
   g.draw(self.images[name..'-atlas'],self.quads[frame],-128*size,-241*size,0,size,size)
   g.setBlendMode('alpha');g.pop()
  end
  if t>=M.logoAt then
   local img=self.images['ascendant-start'];local iw,ih=img:getDimensions()
   local grow=mix(.84,1,reveal);local s=960/iw*grow
   g.setColor(1,1,1,reveal*fade);g.draw(img,640,310,0,s,s,iw/2,ih/2)
   local burst=clamp((t-M.logoAt)/.72)
   if burst<1 then
    for i=1,12 do
     local a=i*math.pi/6;local r=130+burst*360
     local xx,yy=640+math.cos(a)*r,270+math.sin(a)*r*.42
     g.setColor(1,.84,.32,(1-burst)*.75*fade);g.setLineWidth(2*(1-burst)+1)
     g.line(xx,yy,xx+math.cos(a)*13*(1-burst),yy+math.sin(a)*13*(1-burst))
    end
   end
   local flash=(1-smooth((t-M.logoAt)/.20))*.18
   g.setColor(1,.94,.74,flash);g.rectangle('fill',0,0,1280,720)
  end
  -- Mew flies above the pair, then lowers its paws onto the tall d in the logo.
  if t>=3.7 then
   local flight=smooth((t-3.7)/2.8);local landing=smooth((t-7.7)/.7)
   local x=mix(-95,850,flight);x=mix(x,806,landing)
   local feet=mix(255,210,flight)-math.sin(flight*math.pi)*30
   feet=mix(feet,146,landing)
   local f
   if t<7.7 then f=math.floor(t*24)%24
   elseif t<8.4 then f=24+math.min(19,math.floor((t-7.7)/.7*20))
   else f=44+math.floor((animationTime-8.4)*24)%20 end
   local k=.8;local a=smooth((t-3.7)/.3)*fade
   g.setBlendMode('alpha','premultiplied');g.setColor(a,a,a,a)
   g.draw(self.images['mew-atlas'],self.quads[f],x-128*k,feet-241*k,0,k,k)
   g.setBlendMode('alpha')
  end
  g.pop()
 end
 function self:drawStatus(label,seconds,alpha)
  local g=love.graphics;g.push('all');g.setCanvas();g.origin();g.setShader();g.setScissor();g.setDepthMode()
  if g.setStencilMode then g.setStencilMode()else g.setStencilTest()end
  g.setBlendMode('alpha');g.setColor(.8,.88,.98,alpha)
  local w,h=g.getDimensions();local scale=math.max(1,math.min(w/900,h/600))
  -- Screen-space placement stays legible below the letterboxed portrait logo.
  g.scale(scale);w=w/scale;h=h/scale
  g.printf(tostring(label)..'  '..string.format('%.0f s',seconds),12,h-38,w-24,'center')
  g.pop()
 end
 return self
end
return M
