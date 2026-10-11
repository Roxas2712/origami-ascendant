-- Composition depends on the safe window's aspect, never its pixel density.
local R={}
local function smooth(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
-- Deliberate composition stops: ordinary 16:9 already gets most of the
-- extra room. A single interpolation from 3:2 to 21:9 barely moved it.
local profiles={
 {aspect=.75,actors=.84,scenery=.96,camera=.95},
 {aspect=1.5,actors=1,scenery=1,camera=1},
 {aspect=16/9,actors=1.12,scenery=1.025,camera=1.01},
 {aspect=21/9,actors=1.18,scenery=1.035,camera=1.015},
}
function R.sample(width,height)
 local aspect=math.max(.1,(tonumber(width)or 240)/math.max(1,tonumber(height)or 160))
 local low,high=profiles[1],profiles[#profiles]
 if aspect<=low.aspect then high=low
 elseif aspect>=high.aspect then low=high
 else
  for i=2,#profiles do
   if aspect<=profiles[i].aspect then low,high=profiles[i-1],profiles[i];break end
  end
 end
 local t=low==high and 0 or smooth((aspect-low.aspect)/(high.aspect-low.aspect))
 local layout={aspect=aspect}
 for _,key in ipairs({'actors','scenery','camera'})do layout[key]=low[key]+(high[key]-low[key])*t end
 return layout
end
function R.panelX(scene,def)
 if def.trainerSlot and scene.rest[def.trainerSlot]then
  return scene.rest[def.trainerSlot][1]+(def.anchorOffsetX or 0)*(scene.responsive and scene.responsive.scenery or 1)
 end
 if def.battlerSlot and scene.rest[def.battlerSlot]then
  return scene.rest[def.battlerSlot][1]
 end
 -- Parts attached to a single paper prop retain their local spacing when
 -- the whole prop shifts for a wider screen (rotors, globes, record windows).
 if def.assemblyX~=nil then
  return def.assemblyX*30*(scene.responsive and scene.responsive.scenery or 1)+(def.x-def.assemblyX)*30
 end
 return def.x*30*(scene.responsive and scene.responsive.scenery or 1)
end
function R.apply(scene,width,height)
 local layout=R.sample(width,height);scene.responsive=layout
 scene.authoredRest=scene.authoredRest or{}
 for side,p in pairs(scene.rest or{})do
  if not scene.authoredRest[side]then scene.authoredRest[side]={p[1],p[2],p[3]}end
  local origin=scene.authoredRest[side];local trainer=side:find('Trainer',1,true)
  local platform=scene.battleFootprint or(scene.stage and scene.stage.platform and scene.stage.platform.def)
  local scale=trainer and layout.scenery or platform and layout.actors or layout.scenery
  local x=origin[1]*scale
  if platform and not trainer then
   -- Reserve the entire largest Dig hole, not only the actor's centre.
   local radius=platform.radius-18;local dz=origin[3]-platform.z
   local limit=math.sqrt(math.max(0,radius*radius-dz*dz))
   x=platform.x+math.max(-limit,math.min(limit,x-platform.x))
  end
  p[1],p[2],p[3]=x,origin[2],origin[3]
  if scene.feet and scene.feet[side]then scene.feet[side][1]=x;scene.feet[side][2]=p[3]end
 end
 return layout
end
return R
