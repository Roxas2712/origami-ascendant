-- Recompose independent paper cards. Original atlases/layouts remain immutable.
local V=...
local K={}
local function copy(value)
 if type(value)~='table'then return value end
 local out={};for k,v in pairs(value)do out[k]=copy(v)end;return out
end
function K.registry(shared)
 local out={};for key,art in pairs(shared)do out[key]=art end
 for key,spec in pairs(V.data('KantoTerrariumCatalog'))do
  local base=assert(shared[spec.base]or shared[spec.base..':'],'missing Kanto material '..tostring(spec.base))
  local art=copy(base);art.kanto=spec;art.kantoKey='kanto:'..key
  art.layout='KantoTerrariumCatalog';art.layoutKey=key
  art.sourceLayout=base.layout;art.sourceLayoutKey=base.layoutKey
  art.camera={eye={0,208,447},target={0,52,-12}}
  art.ambientPlan={kind='kantoPaper',delay=8+(#key%7),duration=5.2,interval=24+(#key%13)}
  if not art.platform then
   art.platform={x=0,z=15,radius=61,height=7.5,texture=art.floor,rect=copy(art.floorRect or {0,0,1253,1253}),sideTint={.65,.62,.54,1}}
  end
  local podium=V.data('KantoTrainerPodium')
  art.anchors={player={-35,8,27},enemy={35,8,4},playerTrainer={-71.1,podium.contactY,.54*30+podium.contactZ},enemyTrainer={71.1,podium.contactY,-3+podium.contactZ}}
  if spec.mode=='town'and spec.townVariant>=2 and spec.townVariant<=11 then
   art.floor='city-floor.png';art.floorRect={24,24,1228,1228};art.platform.texture=art.floor;art.platform.rect={90,90,1164,1164}
  end
  if key=='cerulean_gym'then
   art.floor='deepcave-water-floor.png';art.floorRect={24,24,1228,1228};art.floorFlow=true;art.basin=true
   art.platform.bottom=-43;art.platform.texture='gym-water-atlas.png';art.platform.rect={1006,57,1436,447}
  end
  if spec.mode=='indigo'then
   art.floor='kanto-indigo-floor-v2.png';art.floorRect={0,0,1254,1254}
   art.platform.texture=art.floor;art.platform.rect={0,0,1254,1254}
   art.platform.sideTint={.48,.38,.32,1}
  end
  art.paperCaps=false;art.trainerGround=nil
  V.require('battle/terrarium/KantoReferenceArt').configure(art,key)
  V.require('battle/terrarium/KantoLayeredArt').configure(art,key)
  out[art.kantoKey]=art
 end
 return out
end
local textureNames={'kanto-signatures.png','kanto-towns.png','kanto-relics.png','kanto-details.png','kanto-structure.png','kanto-interiors.png','kanto-indigo-parts-v2.png'}
local detailParts={leaf=1,wheel=2,ghost=3,paper=4,water=5,ember=6,ice=7,banner=8,mist=9,pebble=10,spark=11,electric=12,psychic=11,scan=12,drop=5}
function K.layout(art)
 if art.referenceKey then return V.require('battle/terrarium/KantoLayeredArt').layout(art,V.require('battle/terrarium/KantoReferenceArt').layout(art))end
 local spec=art.kanto;local original=V.data(art.sourceLayout)
 if art.sourceLayoutKey then original=original[art.sourceLayoutKey]end
 local out={}
 for _,item in ipairs(original)do
  local d=copy(item);d.texture=d.texture or art.landscape;local keep=not d.ambientCard
  if spec.mode=='indigo'then keep=false end
  -- Do not carry Hoenn badges, mobiles, oversized facade arches or machinery
  -- identities into Kanto. Smaller structural parts remain separate cards.
  if spec.mode=='gym'or spec.mode=='league'then
   if d.mount=='lid'or(d.width or 0)>3.8 or(math.abs(d.x or 0)<.7 and(d.z or 0)<-1 and(d.y or 0)>20)then keep=false end
  elseif spec.mode=='town'then
   if(d.z or 0)<-1.3 and(d.width or 0)>1 then keep=false end
  elseif spec.mode=='industrial'or spec.mode=='warehouse'or spec.mode=='ruined'or spec.mode=='tunnel'then
   if math.abs(d.x or 0)<1 and(d.z or 0)<-1.4 then keep=false end
  end
  if art.kantoKey=='kanto:cerulean_gym'then keep=false end
  if (spec.mode=='tunnel'or spec.mode=='gate'or spec.mode=='casino')and(d.z or 0)<-.6 then keep=false end
  if spec.mode=='deck'and(d.z or 0)<-1 then keep=false end
  if (spec.mode=='cabin'or spec.mode=='galley')and math.abs(d.x or 0)<1 and(d.z or 0)<-1.4 then keep=false end
  if keep then
   d.eventMotion=nil;d.detailMotion=nil
   if d.mount=='lid'then d.oscillate=d.oscillate or .012 end
   -- Existing source podiums are repositioned to the shared battle anchors.
   if math.abs((d.width or 0)-1.12)<.03 and math.abs(d.x or 0)>2 and math.abs(d.x or 0)<2.4 and(d.z or 0)>-.2 and(d.z or 0)<.7 then
    d.x=d.x<0 and-2.37 or 2.37;d.z=d.x<0 and .54 or-.1
   end
   out[#out+1]=d
  end
 end
 local bounds=V.data('KantoPaperAtlasBounds')
 local function add(kit,part,w,x,y,z,h,extra)
  local b=kit==5 and part==11 and V.data('KantoTrainerPodium').rect or assert(bounds[kit][part]);local start=3.12+#out*.009
  local d={texture=textureNames[kit],imageWidth=1536,imageHeight=1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=start,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=math.min(.10,(start-3.12)*.15)}
  for k,v in pairs(extra or{})do d[k]=v end
  out[#out+1]=d;return d
 end
 if spec.mode=='indigo'then
  for _,d in ipairs(V.data('KantoIndigoTerrarium'))do
   add(7,d.part,d.width,d.x,d.y or-1.35,d.z,d.height,d.extra)
  end
  for _,p in ipairs({{-2.37,.54,'playerTrainer'},{2.37,-.10,'enemyTrainer'}})do
   add(5,11,1.15,p[1],-1.35,p[2],18,{trainerSlot=p[3],anchorOffsetX=0})
  end
 end
 if spec.kit then
  if spec.mode=='town'then
   local v=spec.townVariant or 1
   add(2,spec.prop,2.15,0,-1.35,-2.74,110)
   add(2,spec.prop,1.36,-1.9,-1.35,-2.05,76,{mirror=true})
   -- A distinct secondary frontage, never a mirrored copy of the whole street.
   add(2,v>11 and 12 or 2,1.43,1.95,-1.35,-1.91,69)
  else
   add(spec.kit,spec.prop,2.25,0,-1.35,-2.38,90)
   if spec.mode=='garden'or spec.mode=='memorial'or spec.mode=='warehouse'then
    add(spec.kit,spec.prop,1.30,-2.08,-1.35,-1.72,64)
    add(spec.kit,spec.prop,1.22,2.10,-1.35,-1.61,60,{mirror=true})
   end
  end
 end
 -- Additional architectural wings are separate flats at staggered depths.
 -- They frame the battle without a single painted background arch.
 local key=art.kantoKey:sub(7)
 local structures={pewter_gym=8,cerulean_gym=1,vermilion_gym=5,celadon_gym=3,
  fuchsia_gym=6,saffron_gym=6,cinnabar_gym=7,viridian_gym=8,dojo=6,
  lorelei=12,bruno=8,agatha=12,lance=12,champion=12,
  rocket=5,warehouse=5,silph=5,power=5,mansion=10,tower=9}
 local structure=structures[key]
 if structure then
  for i,p in ipairs({{-2.08,-2.25,117},{2.09,-2.24,115},{-2.68,-1.32,73},{2.65,-1.27,71}})do
   add(5,structure,i<3 and 1.20 or .85,p[1],-1.35,p[2],p[3],{mirror=i%2==0,
    lamps=structure==5 or structure==12,warm=structure==7,sway=structure==3})
  end
  if key=='cerulean_gym'then
   for i,p in ipairs({{-1.50,-1.55},{1.50,-1.56},{-2.69,.76},{2.69,.72},{-1.72,2.43},{1.72,2.43}})do
    add(5,2,i<3 and 1.45 or .83,p[1],-1.35,p[2],i<3 and 31 or 17,{mirror=i%2==0,flowing=true})
   end
   for i,p in ipairs({{-2.37,.54},{2.37,-.10}})do add(5,11,1.15,p[1],-1.35,p[2],18)end
  elseif key=='tower'or key=='agatha'then
   for _,x in ipairs({-2.1,2.1})do add(5,9,1.15,x,-1.35,1.60,21)end
  end
 end
 if spec.mode=='town'then
  local urban=spec.townVariant>=7 and spec.townVariant<=8
  for i,p in ipairs({{-2.55,-1.40},{2.56,-1.35},{-2.52,1.24},{2.52,1.24}})do
   add(5,4,i<3 and .97 or .65,p[1],-1.35,p[2],i<3 and(urban and 51 or 70)or 32,{sway=true,mirror=i%2==0})
  end
 end
 if spec.mode=='tunnel'or spec.mode=='gate'then
  for i,x in ipairs({-2.22,-1.23,1.23,2.22})do add(6,7,.88,x,-1.35,-2.40+math.abs(x)*.12,121-math.abs(x)*6,{mirror=x>0,lamps=true})end
 elseif spec.mode=='casino'then
  for _,x in ipairs({-1.95,1.95})do add(6,4,1.56,x,-1.35,-1.95,84,{signal=true})end
 elseif spec.mode=='deck'then
  for _,x in ipairs({-2.18,2.18})do add(6,3,1.30,x,-1.35,-2.18,116)end
  for _,x in ipairs({-1.8,1.8})do add(6,6,1.0,x,-1.35,-1.22,26)end
 elseif spec.mode=='galley'then
  for _,x in ipairs({-1.80,1.80})do add(6,1,1.45,x,-1.35,-1.91,67,{warm=true})end
 elseif spec.mode=='spa'then
  for _,x in ipairs({-1.75,1.75})do add(6,8,1.45,x,-1.35,-1.70,39,{flowing=true})end
 end
 if spec.mode=='warehouse'then
  add(6,12,1.6,-1.74,-1.35,-2.1,100,{signal=true})
  for _,p in ipairs({{-2.45,-1.28},{2.43,-1.23},{-2.50,1.30},{2.5,1.30}})do add(6,6,.83,p[1],-1.35,p[2],26)end
 end
 -- Vary Sevii settlements by their local landmarks rather than one repeated street.
 if spec.mode=='town'and spec.townVariant>11 then
  local part=({[12]=10,[13]=4,[14]=2,[15]=9,[16]=5,[17]=3,[18]=4})[spec.townVariant]
  local kit=(spec.townVariant==14)and 5 or (spec.townVariant==13)and 6 or 3
  if spec.townVariant==12 then kit,part=2,10 end
  if spec.townVariant==15 then kit,part=4,7 end
  if spec.townVariant==16 then kit,part=3,5 end
  if spec.townVariant==17 then kit,part=3,3 end
  if spec.townVariant==18 then kit,part=3,4 end
  add(kit,part,.92,1.90,-1.35,-1.31,42)
 end
 -- Kanto-specific folded details: separate pivots and real lid threads.
 -- Clear of the combat disk and trainer sightlines; foreground remains low.
 for i,place in ipairs({{-1.48,119,-3.18},{1.43,127,-3.20}})do
  local part=detailParts[spec.motion];local h=spec.motion=='banner'and 25 or 17
  add(spec.mode=='indigo'and 7 or 4,spec.mode=='indigo'and 11 or part,spec.mode=='indigo'and 1.05 or spec.motion=='banner'and .46 or .60,place[1],place[2],place[3],h,
   {mount='lid',pivot=h,oscillate=.012,floatPhase=i*.8,
    eventMotion='kantoProp',kantoKey=art.kantoKey,kantoMotion=spec.motion,eventIndex=i})
 end
 for i,place in ipairs({{-2.30,1.6,1.55},{1.61,1.6,2.38},{-.82,1.6,2.94}})do
  local h=(spec.motion=='pebble'and 4 or spec.motion=='banner'and 12 or 7)
  add(4,detailParts[spec.motion],h/30,place[1],place[2],place[3],h,
   {pivot=h*.5,eventMotion='kantoProp',kantoKey=art.kantoKey,kantoMotion=spec.motion,eventIndex=i+2,
    signal=spec.motion=='electric'or spec.motion=='scan',warm=spec.motion=='ember',haunt=spec.motion=='ghost',
    flowing=spec.motion=='water',floatY=(spec.motion=='ghost'or spec.motion=='leaf')and .25 or nil})
 end
 return out
end
return K
