-- The map supplies identity; the stage is a layered paper world, not a map wall.
local V=...
local L={}
local selection={
 pewter_gym='rock',cerulean_gym='pool',vermilion_gym='electric',celadon_gym='garden',
 fuchsia_gym='dojo',saffron_gym='psychic',cinnabar_gym='quiz',viridian_gym='earth',dojo='dojo',
 town_one='coast',town_two='coast',town_three='island',town_four='coast',
 town_five='coast',town_six='island',town_seven='coast',
 seafoam='ice',icefall='ice',berry='forest',pattern='forest',ruin_valley='ruin',
 memorial='coast',tanoby_exterior='coast',navel_exterior='coast',kindle_road='coast',
 canyon='mountain',ember='mountain',trainer_tower_exterior='coast',pier_route='coast',harbor='coast',
}
local function copy(x)if type(x)~='table'then return x end;local r={};for k,v in pairs(x)do r[k]=copy(v)end;return r end
function L.configure(art,key)
 local kind=selection[key];if not kind then return end
 art.layeredKey=key;art.layeredKind=kind
 if kind=='coast'or kind=='island'then
  art.floor='pond-water-floor.png';art.floorRect={24,24,1228,1228};art.floorFlow=true
  art.platform.texture='route-coast-kit.png';art.platform.rect={46,839,400,1184};art.platform.sideTint={.66,.60,.41,1}
 elseif kind=='ice'then
  art.floor='pond-water-floor.png';art.floorRect={24,24,1228,1228};art.floorFlow=true
  art.platform.texture='frost-floor.png';art.platform.rect={90,90,1164,1164};art.platform.frost=true
  art.floorFrost=false -- Only the raised ice is frozen; the surrounding pool flows.
 elseif kind=='pool'then
  art.floor='pond-water-floor.png';art.floorRect={24,24,1228,1228};art.floorFlow=true
 elseif kind=='garden'or kind=='forest'or kind=='ruin'then
  art.floor='floor.jpg';art.floorRect={30,30,738,738};art.platform.texture='floor.jpg';art.platform.rect={30,30,738,738}
 end
end
function L.layout(art,native)
 if not art.layeredKey then return native end
 local key,kind=art.layeredKey,art.layeredKind;local out={}
 local function raw(tex,b,w,x,y,z,h,extra,iw,ih)
  local d={texture=tex,imageWidth=iw or 1536,imageHeight=ih or 1024,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,y=y,z=z,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=3.12+#out*.009,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=math.min(.1,#out*.002)}
  for k,v in pairs(extra or{})do d[k]=v end;out[#out+1]=d;return d
 end
 local names={'kanto-signatures.png','kanto-towns.png','kanto-relics.png','kanto-details.png','kanto-structure.png','kanto-interiors.png'}
 local function old(kit,part,w,x,y,z,h,extra)
  return raw(names[kit],V.data('KantoPaperAtlasBounds')[kit][part],w,x,y,z,h,extra)
 end
 local function ref(kit,part,w,x,y,z,h,extra)
  local a=V.data('KantoReferenceParts')[kit];return raw(a.texture,a.parts[part],w,x,y,z,h,extra)
 end
 local coastRects={palm={450,50,840,505},cliff={850,65,1254,515},wave={0,570,438,815},
  drift={12,868,433,1230},dune={440,841,842,1230},bird={875,846,1096,1035}}
 local function coast(p,w,x,y,z,h,extra)return raw('coast-botanical-v2.png',coastRects[p],w,x,y,z,h,extra,1254,1254)end
 local function source(name,sub,filter)
  local t=V.data(name);if sub then t=t[sub]end
  for _,item in ipairs(t)do
   local podium=math.abs((item.width or 0)-1.135)<.035 and math.abs(item.x or 0)>2 and(item.z or 0)>-.3 and(item.z or 0)<.8
   if not podium and not item.ambientCard and(not filter or filter(item))then
    local d=copy(item);d.eventMotion=nil;d.gymDetail=nil;d.eventSway=nil
    out[#out+1]=d
   end
  end
 end
 local function garden()
  source('EmeraldRainforestTerrarium','rainforest',function(d)
   return d.sway or d.mount=='lid'
  end)
  -- Trellis leaves, frame and flowers remain distinct overlapping cards.
  for i,p in ipairs({{-1.90,-2.55,103},{-.55,-2.84,117},{1.22,-2.69,107},{2.05,-2.00,76}})do
   old(5,3,1.28,p[1],-1.35,p[2],p[3],{sway=true})
  end
  old(1,4,1.67,0,-1.35,-1.98,65)
 end
 if kind=='coast'or kind=='island'then
  source('EmeraldCoastTerrarium','coast',function(d)
   -- Open a view onto the actual settlement; no universal central rock arch.
   return d.width<4 and not(d.width==2.49) and not(d.width==2.25)
  end)
  local variant=({town_one=1,town_two=2,town_three=3,town_four=4,town_five=5,town_six=6,town_seven=7})[key]or 3
  -- Shore shelves and separate tree silhouettes form staggered wings.
  coast('cliff',1.55,-2.13,-1.35,-2.52,69+variant%3*8)
  coast('cliff',1.27,2.18,-1.35,-1.89,57,{mirror=true})
  coast('palm',1.40,-2.38,15,-2.13,91,{sway=true})
  coast('palm',1.12,2.39,8,-1.72,78,{sway=true,mirror=true})
  local recipe=V.data('KantoReferenceTerrariums')[key]
  for i,p in ipairs(recipe.cards)do
   if p.kit=='towns'or p.kit=='landmarks'or p.kit=='corrections'then
    local by=27+(i%2)*7;local z=-2.63+(i%3)*.22
    raw('green-structure-v3.png',{460,700,975,950},p.width*.84,p.x*.74,-1.35,z+.025,by+5)
    local d=ref(p.kit,p.part,p.width*.66,p.x*.74,by-8,z,p.height*.75)
    d.foldBaseY=-1.35
   end
  end
  if kind=='island'then
   raw('rainforest-layered-v2.png',{10,8,404,449},1.64,-1.57,-1.35,-2.65,121,{sway=true})
   raw('rainforest-layered-v2.png',{786,21,1163,451},1.54,1.64,-1.35,-2.48,110,{sway=true})
   if not key:match('town_')then
    raw('rainforest-layered-v2.png',{8,511,409,710},2.34,.12,25,-2.05,30)
   end
  end
  if key=='town_one'or key=='kindle_road'then
   raw('volcanic-layered-v2.png',{772,186,1151,308},3.6,.45,-1.35,-3.03,117,{lava=true})
  elseif key=='town_four'then
   raw('ice-layered-v2.png',{770,148,1190,303},1.95,1.3,-1.35,-2.91,105,{frost=true})
  elseif key=='town_seven'or key=='tanoby_exterior'then
   for i,x in ipairs({-1.4,0,1.42})do ref('landmarks',11,.88,x,8,-2.39+i*.05,43)end
  elseif key=='navel_exterior'then
   raw('tidal-layered-v2.png',{38,18,310,362},1.44,-.60,-1.35,-2.65,131)
   raw('tidal-layered-v2.png',{447,19,675,362},1.24,.65,-1.35,-2.51,119)
  end
  -- Water gets separate white-edged paper curls around the dry battle disk.
  for i,p in ipairs({{-2.64,.93},{2.62,.93},{-1.86,2.18},{1.82,2.18},{-.67,2.96},{.68,2.94}})do
   coast('wave',.64,p[1],-.8,p[2],8,{wave=i*.9,flowing=true,driftX=.5,mirror=i%2==0})
  end
 elseif kind=='forest'or kind=='ruin'then
  source('EmeraldWildPlaceTerrariums','island',function(d)return not(d.width==2.23)end)
  if key=='berry'then
   for i,p in ipairs({{-1.63,-2.17},{.05,-2.55},{1.56,-2.07},{-2.62,1.30},{2.60,1.26}})do ref('nature',2,.72,p[1],-1.35,p[2],24,{sway=true})end
   ref('nature',7,1.02,1.40,-.9,-1.60,25,{restPitch=-math.pi/2,flowing=true})
  elseif key=='pattern'then
   for i,x in ipairs({-1.96,-1.01,0,.98,1.94})do ref('nature',3,.73,x,-1.35,-1.70,28,{sway=true})end
   raw('rainforest-layered-v2.png',{786,21,1163,451},1.50,0,-1.35,-2.95,117,{sway=true})
  else
   raw('green-structure-v3.png',{0,70,550,530},1.97,-1.34,-1.35,-2.28,83)
   raw('green-structure-v3.png',{550,100,975,530},1.72,1.40,-1.35,-2.25,77)
   ref('terrain',5,1.42,0,-1.35,-2.70,68)
   ref('terrain',10,.75,.48,-1.35,-1.74,35)
  end
 elseif kind=='ice'then
  source('EmeraldShoalTerrariums','ice')
  if key=='icefall'then
   -- Reuse the one existing waterfall instead of placing a second one over it.
   for _,d in ipairs(out)do
    if d.points[1][1]==65 or d.points[1][1]==751 then
     d.frost=nil;d.flowing=true;d.fluidCard='icefall-water'
    end
   end
  end
  for i,x in ipairs({-1.58,0,1.50})do
   coast('wave',.84,x,1,-1.38,12,{wave=i,flowing=true})
  end
  if key~='icefall'then
   ref('terrain',6,.57,-1.52,5,-1.51,24);ref('terrain',6,.48,1.61,2,-1.63,20)
  end
 elseif kind=='mountain'then
  source('EmeraldWildPlaceTerrariums','mountain')
  for i,x in ipairs({-1.6,0,1.6})do raw('green-structure-v3.png',{460,700,975,950},1.26,x,-1.35,-1.55,25+i*3)end
  if key=='ember'then
   raw('volcanic-layered-v2.png',{772,186,1151,308},3.6,0,35,-2.90,91,{lava=true})
  end
 elseif kind=='garden'then garden()
 elseif kind=='rock'or kind=='earth'then
  source('EmeraldRockGymLayered',nil,function(d)
   local x=d.points[1][1]
   return x~=807 and x~=1154 and x~=1226 and x~=846
  end)
  -- Original gym puzzle/stonework punctuates the layered geology.
  for _,x in ipairs({-1.17,0,1.17})do ref('terrain',6,.58,x,1,-2.04,28)end
  if kind=='earth'then
   for _,x in ipairs({-1.7,1.7})do
    old(5,8,1.08,x,-1.35,-2.34,97)
    ref('gyms',11,.47,x,8,-1.42,15,{restPitch=-math.pi/2,signal=true})
   end
   coast('dune',.63,-2.55,-1.35,1.35,19,{sway=true});coast('dune',.67,2.50,-1.35,1.4,22,{sway=true})
  end
 elseif kind=='pool'then
  local parts=V.data('KantoMistyPopupParts')
  local function pool(n,w,x,y,z,h,extra)return raw('kanto-misty-popup-v4.png',parts[n],w,x,y,z,h,extra)end
  -- Tall wings, three successive water planes and low foreground planting.
  pool(1,2.50,-1.64,-1.35,-2.56,129)
  pool(3,2.44,1.71,-1.35,-2.45,108)
  pool(2,2.49,.19,-1.35,-2.91,137,{flowing=true})
  pool(2,1.42,-.21,-1.35,-1.93,62,{flowing=true,mirror=true})
  pool(4,1.65,-1.57,-1.35,-1.52,30)
  pool(4,1.56,1.64,-1.35,-1.45,27,{mirror=true})
  pool(5,1.03,-2.61,-1.35,-.91,42,{sway=true})
  pool(5,.96,2.60,-1.35,-.88,39,{sway=true,mirror=true})
  pool(8,.94,-1.24,12,-1.71,43,{flowing=true})
  pool(8,.80,1.36,10,-1.65,37,{flowing=true})
  for i,p in ipairs({{-2.72,1.10,.84,13},{2.70,1.06,.84,13},{-1.86,2.17,1.14,18},{1.88,2.13,1.10,17},{-.76,2.96,.73,10},{.76,2.92,.73,10}})do
   pool(6,p[3],p[1],-.5,p[2],p[4],{wave=i*.8,flowing=true,driftX=.5,mirror=i%2==0})
  end
  pool(7,1.06,-2.11,-1.35,1.54,22);pool(7,1.02,2.12,-1.35,1.50,21,{mirror=true})
  pool(5,.63,-1.34,-1.35,2.52,19,{sway=true});pool(5,.59,1.40,-1.35,2.49,18,{sway=true,mirror=true})
  for i,x in ipairs({-1.65,-.79,.09,.96,1.79})do
   pool(9,.28,x,118+(i%2)*10,-3.15,17,{mount='lid',pivot=16,oscillate=.022,floatY=.25,floatPhase=i})
  end
 elseif kind=='electric'or kind=='psychic'or kind=='dojo'or kind=='quiz'then
  local family=({electric='electric',psychic='psychic',dojo='fighting',quiz='steam'})[kind]
  source('EmeraldGymAtlasLayouts',family,function(d)
   -- Keep separated framing/foreground material; discard Hoenn's emblems,
   -- oversized arch backdrops, source podiums and whole hanging assemblies.
   if d.width>3.8 or(d.mount=='lid'and d.width>1.3)then return false end
   return true
  end)
  local column=kind=='electric'and 5 or kind=='quiz'and 7 or 6
  for i,p in ipairs({{-2.01,-2.64,118},{2.01,-2.52,111},{-2.61,-1.45,72},{2.60,-1.38,76}})do
   old(5,column,.49,p[1],-1.35,p[2],p[3])
  end
  if kind=='electric'then
   for _,z in ipairs({-2.07,-1.46})do for _,x in ipairs({-1.39,-.47,.47,1.39})do ref('gyms',3,.36,x,0,z,19)end end
   ref('gyms',4,2.05,0,20,-2.45,32,{signal=true})
  elseif kind=='psychic'then
   for i,p in ipairs({{-1.73,-1.72},{1.68,-1.66},{-2.57,1.53},{2.53,1.50}})do
    ref('gyms',8,.63,p[1],2,p[2],18,{restPitch=-math.pi/2,signal=true})
   end
  elseif kind=='quiz'then
   for i,x in ipairs({-1.35,0,1.35})do ref('gyms',9,.86,x,10+(i%2)*8,-2.07,60)end
  else
   old(1,5,2.11,0,20,-2.58,71)
   for _,x in ipairs({-1.51,1.51})do ref('gyms',12,1.05,x,2,-1.77,27,{restPitch=-math.pi/2})end
  end
  for i,x in ipairs({-1.55,-.50,.56,1.55})do
   old(4,kind=='electric'and 12 or kind=='psychic'and 11 or 8,.33,x,106+(i%2)*13,-3.13,17,
    {mount='lid',pivot=16,oscillate=.019,floatPhase=i,signal=kind=='electric'})
  end
 end
 -- Bespoke complementary wings replace the sparse pillar-only gym draft.
 local theme={rock={'A',1},electric={'A',5},dojo={'A',9},psychic={'B',1},quiz={'B',5},earth={'B',9}}
 if theme[kind]then
  out={};local t=theme[kind];local b=V.data('KantoGymPopupParts'..t[1]);local tex='kanto-gym-popup-'..t[1]:lower()..'-v4.png'
  local function piece(n,w,x,y,z,h,extra)return raw(tex,b[t[2]+n-1],w,x,y,z,h,extra)end
  piece(1,2.17,-1.65,-1.35,-2.63,126)
  piece(2,2.11,1.69,-1.35,-2.51,119)
  piece(3,3.64,0,-1.35,-2.96,kind=='dojo'and 105 or 77)
  piece(1,1.08,-2.52,-1.35,-1.44,64)
  piece(2,1.04,2.52,-1.35,-1.37,61,{mirror=true})
  piece(3,1.28,-1.40,-1.35,-1.59,33)
  piece(3,1.20,1.42,-1.35,-1.57,31,{mirror=true})
  for i,p in ipairs({{-2.73,.96,.70,21},{2.74,.96,.66,20},{-1.96,2.05,.92,25},{1.96,2.02,.86,23},{-.99,2.78,.57,16},{1.01,2.77,.59,17}})do
   piece(4,p[3],p[1],-1.35,p[2],p[4],{warmSignal=kind=='electric',psychic=kind=='psychic',mirror=i%2==0})
  end
  for i,x in ipairs({-1.76,-.60,.61,1.77})do
   old(4,kind=='electric'and 12 or kind=='psychic'and 11 or kind=='quiz'and 6 or kind=='dojo'and 8 or 10,.30,x,116+(i%2)*10,-3.17,14,
    {mount='lid',pivot=13,oscillate=.014,floatPhase=i})
  end
  if kind=='electric'then
   for _,x in ipairs({-1.68,-.55,.55,1.68})do ref('gyms',3,.36,x,2,-1.84,20)end
   ref('gyms',4,1.90,0,22,-2.53,32,{signal=true})
  elseif kind=='psychic'or kind=='earth'then
   for _,x in ipairs({-1.78,1.78})do for _,z in ipairs({-1.63,1.79})do
    ref('gyms',kind=='psychic'and 8 or 11,.47,x,3,z,14,{restPitch=-math.pi/2,signal=kind=='psychic'})
   end end
  elseif kind=='quiz'then
   ref('gyms',9,.74,-.71,4,-1.93,49);ref('gyms',9,.74,.71,4,-1.91,49)
   -- Separate paper steam rises from the boilers; the machine stays planted.
   for i,p in ipairs({{1.69,111,-2.48},{2.52,56,-1.34},{-1.96,21,2.08},{1.96,19,2.05}})do
    old(4,9,i<3 and .24 or .16,p[1],p[2],p[3],i<3 and 16 or 9,
     {ambientCard='kantoSteam',kantoKey=art.kantoKey,eventIndex=i})
   end
  end
 end
 -- Keep the measured, fixed trainer support and the scene's own ambient props.
 for _,d in ipairs(native)do
  if d.trainerSlot or d.eventMotion=='kantoProp'and d.mount~='lid'then out[#out+1]=copy(d)end
 end
 -- Reference puzzle details can remain small front accents, never repeated walls.
 if key:find('_gym',1,true)then
  for _,x in ipairs({-2.50,2.50})do ref('finishing',8,.34,x,-1.35,1.53,22)end
 end
 -- The folds share the normal intro duration despite the increased piece count.
 for i,d in ipairs(out)do d.begin=3.12+(i-1)*.008;d.foldOffset=math.min(.10,(i-1)*.002)end
 return out
end
return L
