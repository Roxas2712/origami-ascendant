-- Quiet details are attached to actual paper props. Work on copies so cached
-- layouts never accumulate changes when switching views or battle formats.
local E={}
local targets={['interior:puzzle']=true,['tower:memorial']=true,['mountain:memorial']=true,
 ['mountain:ash']=true,['cave:fossil']=true,['ruins:sand']=true,['ruins:braille']=true,
 ['ruins:regirock']=true,ruins=true,cave=true,['island:triangle']=true,
 ['industrial:electric']=true,['lava:ancient']=true,['facility:pike']=true,
 crater=true,['sea:sootopolis']=true}
function E.apply(key,source)
 if not targets[key]then return source end
 local list={};local n=0
 local function animate(d,kind)
  n=n+1;d.eventMotion='paperDetail';d.detailMotion=kind;d.detailKey=key;d.eventIndex=n
  d.doubleSidedArt=true
 end
 for index,src in ipairs(source)do
  local d={};for k,v in pairs(src)do d[k]=v end
  if key=='interior:puzzle'and d.spin then animate(d,'gear')
  elseif key=='industrial:electric'and d.spin then animate(d,'rotor')
  elseif key=='tower:memorial'and d.mount=='lid'then animate(d,'banner')
  elseif key=='mountain:ash'and d.mount=='lid'then animate(d,'cloud')
  elseif (key=='mountain:memorial'or key=='cave:fossil')and d.paperTint then animate(d,'mist')
  elseif (key=='crater'or key=='sea:sootopolis')and d.texture=='coast-botanical-v2.png'then animate(d,'bird')

  elseif key=='lava:ancient'and d.ambientCard and d.ambientCard:match('terraEmber')then
   -- Rise from the visible front lava, rather than behind the battle plinth.
   local i=tonumber(d.ambientCard:match('%d+'));d.x=i==3 and 1.78 or -1.91+(i-1)*.17
   d.z=2.13;d.y=5;d.width=.19;d.heightScale=d.heightScale*8/(4.2*.19/.076)
  elseif key=='facility:pike'and d.ambientCard=='frontierPikeLamp'then
   -- Printed light cutouts face the viewer in front of their lamp housings.
   d.z=d.z+.20;d.width=.44;d.heightScale=d.heightScale*11/(8.2*.44/.30)
  end
  list[#list+1]=d
 end
 local function accent(texture,r,w,x,y,z,h,kind,i)
  local d={texture=texture,imageWidth=1536,imageHeight=1024,cutout=true,
   points={{r[1],r[2]},{r[3],r[2]},{r[3],r[4]},{r[1],r[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((r[4]-r[2])*w*30/(r[3]-r[1])),begin=3.8,duration=.7,direction=-1,
   ambientCard='paperDetail',detailMotion=kind,detailKey=key,eventIndex=i,doubleSidedArt=true}
  list[#list+1]=d;return d
 end
 if key=='island:triangle'then
  -- The stone's foot is also painted into the island flat. Moving it would
  -- expose a duplicate stump; animate separate cut-paper stars instead.
  for i=1,3 do
   local d=accent('birth-island-paper.png',{906,158,933,188},.24,(i-2)*.78,100+i*8,-2.78,8,'star',i)
   d.imageWidth=1448;d.imageHeight=1086
   d.points={{919,158},{922,167},{933,172},{923,175},{919,188},{915,178},{906,172},{915,169}}
  end
 elseif key=='cave'or key=='ruins'or key=='ruins:sand'or key=='ruins:regirock'then
  for i=1,3 do
   local d=accent('rock-gym-layered-v3.png',{119,802,314,972},.21,-1.64+(i-1)*.11,-1.6,2.50+(i-1)*.11,5.2,'pebble',i)
   d.pivot=2.6
   if key~='cave'then d.paperTint={1,.87,.65,1}end
  end
 elseif key=='ruins:braille'then
  for i,p in ipairs({{-2.42,20,1.42},{2.43,23,1.39},{-1.78,17,2.38}})do
   local d=accent('gym-water-layers.png',{696,619,854,870},.14,p[1],p[2],p[3],6.2,'drop',i)
   d.points={{765,619},{800,677},{845,751},{854,795},{841,833},{812,858},{777,870},{740,861},{711,837},{696,801},{701,767},{727,711}}
  end
 end
 return list
end
return E
