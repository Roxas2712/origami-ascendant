-- Measured FR home windows and dining areas; never infer emitters from collision
-- cells or palette brightness. All source art, furniture and native events stay.
local V=...;local R={cache=setmetatable({},{__mode='k'})}
local function stamp(t)
 local keys={};for k in pairs(t)do keys[#keys+1]=k end;table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 local out={};for _,k in ipairs(keys)do local v=t[k];out[#out+1]=tostring(k)..'='..(type(v)=='table'and stamp(v)or tostring(v))end
 return table.concat(out,';')
end
function R.profile(d)
 local c=V.require('DioramaConfig').interiors.homeLighting;local L=d and d.midLayout
 local key=c and c.rooms[d and d.id];local p=key and c.layouts[key]
 if not(c and c.enabled and p and d.mapType==8 and d.pair==p.pair and L and L.midAt and L.width==p.width and L.height==p.height)then return end
 local i=0;for value in p.rows:gmatch('%x+')do
  if L:midAt(i%L.width,math.floor(i/L.width))~=tonumber(value,16)then return end;i=i+1
 end
 local tables=p.tables or {p.table}
 for _,a in ipairs(tables)do if L:midAt(a[1],a[2])~=a[3]then return end end
 if p.work and L:midAt(p.work[1],p.work[2])~=p.work[3]then return end
 -- A stable profile avoids regenerating emission textures each draw. Tuning
 -- values are included so live config changes cannot leave a stale light rig.
 local tuning={};for k,v in pairs(c)do if k~='rooms'and k~='layouts'then tuning[k]=v end end
 local signature=key..stamp(tuning);local hit=R.cache[L]
 if hit and hit.signature==signature then return hit.profile end
 local sources,regions={},{}
 for _,w in ipairs(p.windows)do
  sources[#sources+1]={at={(w[1]+w[2]/2)*16,c.windowHeight,34},radius=c.windowRadius,
   power=c.windowPower*(w[2]==1 and c.windowNarrowScale or 1),nightPower=c.windowNightPower,
   color=c.windowColor,nightColor=c.windowNightColor,spread=c.windowSpread,direction=c.windowDirection,cone=c.windowCone}
  regions[#regions+1]={at={w[1],0},rect={0,0,w[2]*16,32},palette=c.glassPalette}
 end
 local scale=#tables>1 and c.multipleTableScale or 1
 for _,a in ipairs(tables)do
  sources[#sources+1]={at={(a[1]+1)*16,c.ceilingHeight,(a[2]+1)*16},radius=c.ceilingRadius,
   power=(#p.windows==0 and c.windowlessCeilingPower or c.ceilingPower)*scale,
   nightPower=c.ceilingNightPower*scale,color=c.ceilingColor,spread=c.ceilingSpread,direction={0,-1,0},cone=-.1}
 end
 if p.work then local a=p.work;local w=c.work
  sources[#sources+1]={at={(a[1]+1)*16,w.height,a[2]*16+w.forward},radius=w.radius,
   power=w.power,nightPower=w.nightPower,color=c.ceilingColor,spread=w.spread,direction={0,-1,0},cone=-.1}
 end
 local profile={ambient=c.ambient,night=c.nightAmbient,sources=sources}
 if #regions>0 then profile.emission={enabled=true,day=c.emissionDay,night=c.emissionNight,bloom=c.emissionBloom,regions=regions}end
 R.cache[L]={signature=signature,profile=profile};return profile
end
return R
