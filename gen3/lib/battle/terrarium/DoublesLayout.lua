-- Four stage-local anchors, ordered for the native 3,1,0,2 sprite bands.
local D={feet={player={-37,21},playerPartner={-17,47},enemy={37,14},enemyPartner={17,-18}}}
function D.panels(layout,art)
 local result,templates={},{}
 for _,p in ipairs(layout)do
  local cap=art.sea and p.texture=='sea-rock-columns-v2.png'
   or art.layoutKey=='pond'and p.width==1.08 and math.abs(p.x)<1
  if cap then templates[#templates+1]=p
  elseif art.layoutKey=='pond'and p.z>2.6 and math.abs(p.x)<1 then
   -- The front reeds framed two actors, but covered the new front partner's
   -- feet and Dig aperture. Keep the cutouts inside the rim, beside the lane.
   local leaf={};for key,value in pairs(p)do leaf[key]=value end
   leaf.x=p.x<0 and -1.25 or 1.25
   result[#result+1]=leaf
  else result[#result+1]=p end
 end
 if #templates==0 then return layout end
 for i,side in ipairs({'player','enemy','playerPartner','enemyPartner'})do
  local source=templates[(i-1)%#templates+1];local p={}
  for key,value in pairs(source)do p[key]=value end
  local foot=D.feet[side]
  p.width=art.sea and 1.48 or 1.35
  p.heightScale=(source.heightScale or 1)*source.width/p.width
  p.x=foot[1]/30;p.z=(foot[2]-(art.sea and 1.8 or 1.2))/30
  p.begin=3.70+(i-1)*.06;p.battlerSlot=side
  result[#result+1]=p
 end
 return result
end
function D.trainers(layout,feet,ground,battle)
 local replacements,added,anchors={},{},{}
 for _,side in ipairs({'player','enemy'})do
  if battle.multi or side=='player'and battle.partner or side=='enemy'and battle.trainerB then
   local key=side..'Trainer';local foot=feet[key]
   local found,score
   for _,p in ipairs(layout)do
    local distance=(p.x*30-foot[1])^2+(p.z*30-foot[2])^2
    if distance<16 and (not score or distance<score)then found,score=p,distance end
   end
   if not found then return nil,'no authored trainer podium for '..side end
   for i,name in ipairs({key,side..'PartnerTrainer'})do
    local p={};for k,v in pairs(found)do p[k]=v end
    local z=i==1 and 38 or -24
    p.z=found.z+(z-foot[2])/30;p.trainerSlot=name
    p.anchorOffsetX=found.x*30-foot[1]
    p.begin=4.00+(i-1)*.08
    anchors[name]={foot[1],ground[key],z}
    if i==1 then replacements[found]=p else added[#added+1]=p end
   end
  end
 end
 local out={};for _,p in ipairs(layout)do
  local replacement=replacements[p]
  if not replacement and p.multi then
   replacement={};for k,v in pairs(p)do replacement[k]=v end
   for k,v in pairs(p.multi)do replacement[k]=v end
  end
  out[#out+1]=replacement or p
 end
 for _,p in ipairs(added)do out[#out+1]=p end
 return out,anchors
end
return D
