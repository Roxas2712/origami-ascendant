-- A paper actor rotates about its planted feet; it never travels sideways.
local A={RELEASE=6.65,LAND=7.45,READY=8.45}
function A.progress(side,time,entry,active)
 if not active then return 1 end
 local start,duration
 if entry=='switch'then
  -- Both rock pedestals finish unfolding at 5.15 seconds.
  start,duration=5.17,.38
 elseif side=='playerTrainer'then start,duration=5.25,.65
 elseif side=='enemyTrainer'then start,duration=5.38,.65
 elseif side=='player'then start,duration=A.LAND,.8
 else start,duration=5.55,.7 end
 local t=math.max(0,math.min(1,(time-start)/duration))
 return t*t*(3-2*t)
end
function A.lean(side,time,entry,active)
 if not active or entry~='battle'or side~='playerTrainer'then return 0 end
 if time<6.25 or time>A.RELEASE+.2 then return 0 end
 if time<A.RELEASE then return -.12*math.sin((time-6.25)/(A.RELEASE-6.25)*math.pi)end
 return .05*math.sin((time-A.RELEASE)/.2*math.pi)
end
-- Finite settling motion: stand upright, overshoot gently, then stop exactly.
-- Fainting retains the plain hinge so this bounce cannot resurrect a card.
function A.angle(progress,direction)
 if direction==-1 then return -(1-progress)*math.pi/2 end
 local p=math.max(0,math.min(1,progress))
 if p==1 then return 0 end
 if p<.68 then return (1-p/.68)^2*math.pi/2 end
 local t=(p-.68)/.32
 return -.20*math.sin(t*3*math.pi)*math.sin(t*math.pi)*(1-t)^2
end
function A.foldPoint(p,foot,progress,lean,direction)
 local angle=A.angle(progress,direction)
 local x,y,z=p[1]-foot[1],p[2]-foot[2],p[3]-foot[3]
 local c,s=math.cos(lean or 0),math.sin(lean or 0)
 x,y=x*c-y*s,x*s+y*c
 return {foot[1]+x,foot[2]+y*math.cos(angle)-z*math.sin(angle),foot[3]+y*math.sin(angle)+z*math.cos(angle)}
end
function A.faintFold(progress)
 local t=math.max(0,math.min(1,progress))
 return 1-t*t*(3-2*t)
end
function A.throw(time,entry,active,hand,target)
 if not active or entry~='battle'or not hand or time<A.RELEASE or time>A.LAND+.22 then return nil end
 local u=math.max(0,math.min(1,(time-A.RELEASE)/(A.LAND-A.RELEASE)))
 return {x=hand[1]+(target[1]-hand[1])*u,y=hand[2]+(target[2]-hand[2])*u-36*u*(1-u),
  scale=math.max(.3,math.min(.65,hand[3]*.8)),rot=u*math.pi*3,landed=time>=A.LAND,
  flash=time>=A.LAND and math.max(0,1-(time-A.LAND)/.22)or 0}
end
function A.replacesNativeIntro(scene,phase)
 return scene and (scene.paperPopup or scene.edition=='emerald') and scene.popupOwnsIntro==true and phase=='intro'
end
return A
