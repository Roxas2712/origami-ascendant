local V=...
local R={}
local function recipes()return V.data('KantoReferenceTerrariums')end
local function part(kit,n)
 if kit=='podium'then local p=V.data('KantoTrainerPodium');return{texture=p.texture,width=1536,height=1024},p.rect end
 local all=V.data('KantoReferenceParts');local a=all[kit]
 if a then return a,a.parts[n]end
 local old=V.data('KantoPaperAtlasBounds')
 local index=kit=='cloud'and 7 or kit=='podium'and 5 or 4
 return {texture=kit=='cloud'and'kanto-indigo-parts-v2.png'or kit=='podium'and'kanto-structure.png'or'kanto-details.png',width=1536,height=1024},old[index][n]
end
function R.configure(art,key)
 local spec=recipes()[key];if not spec then return false end
 art.referenceKey=key;art.kanto.mode='reference';art.kanto.motion=spec.motion
 local floors=V.data('KantoReferenceParts').floors
 art.floor=floors.texture;art.floorRect=floors.parts[spec.floor]
 art.landscape=select(1,part(spec.cards[1].kit,spec.cards[1].part)).texture
 -- These floors are atlas swatches. The legacy bowl mesh uses full-image UVs.
 art.water=false;art.sea=false;art.basin=false
 art.floorFlow=spec.water or false;art.floorFrost=false;art.floorLava=false
 if spec.floorKit then
  local atlas,rect=part(spec.floorKit,spec.floorPart)
  art.floor=atlas.texture;art.floorRect=rect
 end
 art.platform={x=0,z=15,radius=61,height=7.5,texture=floors.texture,
  rect=floors.parts[spec.topFloor or spec.floor],sideTint=spec.environment=='cave'and{.51,.45,.40,1}or{.71,.67,.58,1}}
 if spec.floorKit then art.platform.texture=art.floor;art.platform.rect=art.floorRect end
 art.paperCaps=false;art.trainerGround=nil;art.battlerGround=nil
 return true
end
function R.layout(art)
 local spec=assert(recipes()[art.referenceKey]);local out={}
 local function card(kit,n,w,x,z,h,y,extra)
  local a,b=part(kit,n);assert(b,'Missing reference part '..kit..':'..n)
  if extra and extra.cropU then
   local u=extra.cropU;local width=b[3]-b[1]
   b={b[1]+width*u[1],b[2],b[1]+width*u[2],b[4]}
  end
  local d={texture=a.texture,imageWidth=a.width,imageHeight=a.height,cutout=true,
   points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}},width=w,x=x,z=z,y=y or-1.35,
   heightScale=h/((b[4]-b[2])*w*30/(b[3]-b[1])),begin=3.12+#out*.009,duration=.8,
   direction=z>1 and-1 or 1,foldOffset=math.min(.10,#out*.002)}
  for k,v in pairs(extra or{})do d[k]=v end
  out[#out+1]=d;return d
 end
 for _,p in ipairs(spec.cards)do card(p.kit,p.part,p.width,p.x,p.z,p.height,p.y,p.extra)end
 -- Fixed support heights match the battler/trainer anchors and their shadows.
 for _,p in ipairs({{-2.37,.54,'playerTrainer'},{2.37,-.10,'enemyTrainer'}})do
  card('podium',11,1.15,p[1],p[2],18,nil,{trainerSlot=p[3],anchorOffsetX=0})
 end
 for i,x in ipairs({-1.47,1.45})do
  local kit,n,w,h='cloud',11,1.05,18
  if spec.environment=='room'then kit,n,w,h='league',11,.46,30
  elseif spec.environment=='cave'then kit,n,w,h='finishing',10,1.19,25 end
  card(kit,n,w,x,-3.20,h,120+i*5,{mount='lid',pivot=h,oscillate=.008,
   eventMotion='kantoProp',kantoKey=art.kantoKey,kantoMotion='banner',eventIndex=i})
 end
 local m=spec.motion;local kit,n,h='detail',({wheel=2,ember=6,banner=8})[spec.motion]or 4,6
 if m=='leaf'then kit,n,h='nature',12,6
 elseif m=='pebble'then kit,n,h='terrain',6,5
 elseif m=='water'then kit,n,h='nature',7,7
 elseif m=='mist'then kit,n,h='nature',8,12
 elseif m=='ghost'then kit,n,h='detail',3,7
 elseif m=='electric'or m=='scan'then kit,n,h='detail',12,5
 elseif m=='spark'or m=='psychic'then kit,n,h='detail',11,5
 elseif m=='ice'then kit,n,h='detail',7,5
 elseif m=='drop'then kit,n,h='detail',5,6 end
 for i,p in ipairs({{-2.63,1.45},{2.10,2.15},{-.91,2.98}})do
  local extra={eventMotion='kantoProp',kantoKey=art.kantoKey,kantoMotion=m,eventIndex=i+2,pivot=h*.5,
   flowing=m=='water',warmSignal=m=='electric'or m=='scan'or m=='spark',psychic=m=='psychic',haunt=m=='ghost',lava=m=='ember'}
  if m=='water'then extra.restPitch=-math.pi/2 end
  card(kit,n,m=='mist'and .35 or .26,p[1],p[2],h,m=='water'and-1.0 or 1.1,extra)
 end
 return out
end
return R
