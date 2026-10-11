-- VASC Terarrium.idleSample timing and alternating roll, shared without its
-- voxel geometry. Any input or menu change restarts the nine-second delay.
local C={}
function C.activity(scene,ready,cursor,dt)
 if not ready or cursor~=scene.idleCursor then scene.idleAge=0
 else scene.idleAge=(scene.idleAge or 0)+dt end
 scene.idleCursor=cursor
end
function C.sample(age)
 if age<9 then return 0,0 end
 local t=(age-9)/.56;local beat=math.floor(t)
 local pulse=math.sin(math.pi*(t-beat))^2
 return (beat%2==0 and 1 or -1)*.075*pulse,pulse
end
function C.impact(scene)
 local age=scene.idleAge or 0
 if age<9 then scene.idleBeat=nil;return false end
 local t=(age-9)/.56;local beat=math.floor(t)
 if t-beat>=.42 and scene.idleBeat~=beat then scene.idleBeat=beat;return true end
 return false
end
function C.zoom(current,dy)
 return math.max(.65,math.min(2.5,current*math.exp(dy*.10)))
end
return C
