-- Read-only light samples from native, visible animation sprites. The caller
-- supplies the same fitted particle coordinates used for drawing the effect.
local V=...
local M={}
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
function M.unproject(m,sx,sy,z)
 local u,v=sx/240*2-1,sy/160*2-1
 local a,b=m[1]-u*m[13],m[2]-u*m[14]
 local c,d=m[5]-v*m[13],m[6]-v*m[14]
 local p=-(m[3]-u*m[15])*z-m[4]+u*m[16]
 local q=-(m[7]-v*m[15])*z-m[8]+v*m[16]
 local det=a*d-b*c;if math.abs(det)<1e-9 then return end
 return (p*d-b*q)/det,(a*q-p*c)/det,z
end
-- Native black/white background flashes are capped only for the substituted
-- Paper scenery. The native palette state and particle/actor flashes stay intact.
function M.backgroundDim(blend,active)
 local c=V.require('DioramaConfig').battle.moveLights
 if not(active and c and c.backgroundBlackLimit and type(blend)=='table')then return end
 local color=blend.color
 local black=color==nil or color==0 or type(color)=='table'and(color[1]or 0)==0 and(color[2]or 0)==0 and(color[3]or 0)==0
 if black and (tonumber(blend.coeff)or 0)>c.backgroundBlackLimit then return c.backgroundBlackLimit,0,0,0 end
 local white=color==32767 or type(color)=='table'and color[1]==1 and color[2]==1 and color[3]==1
 if white and c.backgroundWhiteLimit and(tonumber(blend.coeff)or 0)>c.backgroundWhiteLimit then return c.backgroundWhiteLimit,31,31,31 end
end
-- Resolve the current native script, including its called sub-script. No
-- launch/update wrapper or guessed animation duration is needed.
local profiles=setmetatable({},{__mode='k'})
function M.profile(vm)
 if not(vm and vm.active and vm.script)then return end
 local c=V.require('DioramaConfig').battle.moveLights
 local A=require('src.core.game3.battle.anim')
 if not profiles[vm.script]then
  for id,p in pairs(c.moves or{})do
   local script=A.scriptForMove(id);profiles[script]=p
   -- Two-turn moves jump to a branch instead of calling with a return script.
   for _,op in ipairs(script)do if op.op=='choosetwoturnanim'then
    for _,label in ipairs{op.label1,op.label2}do
     local sub=vm._pack and vm._pack.labels and vm._pack.labels[label]
     if sub then profiles[sub]=p end
    end
   end end
  end
 end
 return profiles[vm.script]or profiles[vm._retScript]
end
function M.kind(s,profile)
 local c=V.require('DioramaConfig').battle.moveLights
 local kind=profile and profile.templates and profile.templates[s.template]
 kind=kind or c.templates and c.templates[s.template]or c.tags[s.tag]
 if s.tag=='ORBS'and not c.energyTemplates[s.template]and not(profile and profile.templates and profile.templates[s.template])then kind=nil end
 return kind
end
function M.collect(pool,scene,atmosphere,vm,fit)
 local config=V.require('DioramaConfig');local c=config.battle.moveLights
 if not(c and c.enabled and config.battle.lightsEnabled)or config.settings.maxLights<=0
  or V.mod and V.mod.options and V.mod.options:get('gen3Lights')==false then return 0 end
 local Scene=V.require('battle/PaperBattleScene')
 local vp=Scene.matrix(nil,scene.focus.px,scene.focus.py,nil,240,160,scene)
 local ax,ay=Scene.foot(scene,'player');local bx,by=Scene.foot(scene,'enemy')
 local af,bf=scene.feet.player,scene.feet.enemy
 local scale=scene.scale or 1;local groups={}
 local profile=M.profile(vm)
 local samples=pool or{}
 if profile and profile.palette then
  samples={};for _,s in ipairs(pool or{})do samples[#samples+1]=s end
  local A=require('src.core.game3.battle.anim')
  for _,side in ipairs{'player','enemy'}do
   local pose=A.present(side)or{};local alpha=pose.blendCoeff or 0
   if alpha>0 and pose.visible~=false and not(pose.invisible or pose.battlerInvisible or pose.blinkHidden)then
    local x,y=Scene.foot(scene,side)
    samples[#samples+1]={active=true,visible=true,image=true,x=x,y=y-10*scale,
     alpha=alpha,lightKind=profile.palette,alreadyFitted=true}
   end
  end
 end
 local night=atmosphere.solar and atmosphere.solar.night or 1
 local gain=c.dayScale+(1-c.dayScale)*night
 for _,s in ipairs(samples)do
  local kind=s.lightKind or M.kind(s,profile)
  local look=kind and c[kind]
  if kind=='aurora'then
   local index=math.floor((s._tile or s.frame or 0)/2)%#c.auroraColors+1
   look={power=look.power,radius=look.radius,color=c.auroraColors[index]};kind=kind..index
  end
  local alpha=s.alpha or 1
  if s.objBlend and vm and vm.bldAlpha then local b=vm.bldAlpha;alpha=(s.g2 and 1 or alpha)*clamp(tonumber(b.eva or b[1])or 16,0,16)/16 end
  if s._g1 and s._alphaOverride~=nil then alpha=s._alphaOverride end
  if s.g2 and s.alphaOverride~=nil then alpha=s.alphaOverride end
  local collapsed=s._g1 and (s.affineMode or 0)%2==1 and(s._matX==0 or s._matY==0)
  if s.g2 and(s.affineMode or 0)%2==1 then
   collapsed=math.abs((s.matA or 256)*(s.matD or 256)-(s.matB or 0)*(s.matC or 0))<.065536
  end
  if look and not collapsed and s.active and s.visible~=false and not s.invisible and (not s.customDraw or s._g1 or s.g2 or kind=='heat')
   and s.image and finite(alpha)and alpha>.01 and(s.scaleX or 1)~=0 and(s.scaleY or 1)~=0 then
   local sx,sy=s.x+(s.g2 and s.x2 or s.ox or 0),s.y+(s.g2 and s.y2 or s.oy or 0)
   if finite(sx)and finite(sy)and sx>=-8 and sx<=248 and sy>=0 and sy<=120 then
    local round=s._g1 and 0 or .5
    sx,sy=math.floor(sx+round),math.floor(sy+round) -- native raster centre
    if s.customDraw and fit then
     local E=V.require('battle/EffectFit');local p,e=fit.player,fit.enemy
     local host=p.all and p.all[s.hostId];if host and host~=p and host~=e then p,e=host,host end
     local x,y=E.position(s.x,s.y,p,e);local scale=E.scale(s,fit.player,fit.enemy)
     sx,sy=x+(sx-s.x)*scale,y+(sy-s.y)*scale
    end
    local dx,dy=bx-ax,by-ay
    local t=clamp(((sx-ax)*dx+(sy-ay)*dy)/math.max(.001,dx*dx+dy*dy),0,1)
    local x,y,z=M.unproject(vp,sx,sy,af[2]+(bf[2]-af[2])*t)
    if x and finite(y)then
     local g
     for _,candidate in ipairs(groups)do
      if candidate.kind==kind and(x-candidate.x)^2+(y-candidate.y)^2+(z-candidate.z)^2<(c.mergeRadius*scale)^2 then g=candidate;break end
     end
     alpha=clamp(alpha,0,1)
     if g then
      local sum=g.weight+alpha;g.x=(g.x*g.weight+x*alpha)/sum;g.y=(g.y*g.weight+y*alpha)/sum;g.z=(g.z*g.weight+z*alpha)/sum
      g.weight=sum;g.alpha=math.max(g.alpha,alpha)
     else groups[#groups+1]={kind=kind,x=x,y=y,z=z,weight=alpha,alpha=alpha,look=look}end
    end
   end
  end
 end
 -- A dense fire plume cannot multiply its energy by its particle count.
 table.sort(groups,function(a,b)return a.weight>b.weight end)
 local budget=math.min(c.maxSources,math.max(1,math.floor(config.settings.maxLights/4)))
 local count=math.min(#groups,budget)
 for i=1,count do local g=groups[i];local l=g.look
  atmosphere.lights[#atmosphere.lights+1]={kind='battle',moveLight=true,x=g.x,y=g.y,z=g.z,
   radius=-l.radius*scale,power=l.power*g.alpha*gain/math.sqrt(count),color=l.color,falloff=2}
 end
 return count
end
return M
