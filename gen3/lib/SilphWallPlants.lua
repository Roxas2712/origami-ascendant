-- Native Silph wall courses and the pots which overlap their lower course.
-- Separate source ownership prevents the pot's feet from lowering the wall.
local V=...
local S={}
local pairsByTop={[0x330]={[0x338]=true,[0x34f]=true},[0x35d]={[0x365]=true},
 [0x35e]={[0x366]=true},[0x35f]={[0x367]=true},[0x37f]={[0x387]=true},
 [0x340]={[0x348]=true},[0x341]={[0x349]=true},[0x342]={[0x2e2]=true}}
local function cfg()return V.require('DioramaConfig').interiors.silphWallPlants end
function S.profile(def)
 return cfg().enabled and def.mapType==8 and (def.renderPair or def.pair)=='building__rom_082d4ecc'
  and (def.id or def.name or ''):match('^FR_SILPH_CO_%d+F$') and def.midLayout
end
function S.plan(def,objects,mask)
 if not S.profile(def)then return end
 local L=def.midLayout
 -- Row zero belongs to the stair alcove and needs its own complete surface
 -- profile (including rails and the level sign); leave that group intact.
 for y=1,L.height-2 do for x=0,L.width-1 do
  local top,bottom=L:midAt(x,y),L:midAt(x,y+1)
  if pairsByTop[top] and pairsByTop[top][bottom]then
   local plant=bottom==0x34f
   -- Never erase an unexpected or script-modified lower pot tile.
   if not plant or y+2<L.height and L:midAt(x,y+2)==0x356 then
    objects[#objects+1]={kind='silphWallCourse',x=x,y=y,top=top,bottom=plant and 0x338 or bottom}
    for dy=0,1 do mask[(y+dy)*L.width+x+1]={mid=dy==0 and 0 or 0x335,void=dy==0,separateSurface=true}end
    if plant then
     objects[#objects+1]={kind='silphWallPlant',x=x,y=y+1}
     mask[(y+2)*L.width+x+1]={mid=0x335,separateSurface=true}
    end
   end
  end
 end end
end
function S.build(out,objects,L,ts,ox,oz,contacts)
 local G=V.require('WorldGeometry');local c=cfg();local cut=V.require('DioramaConfig').interiors.silphCutaway
 V.require('SilphCutaway').register(L,objects,ox,oz)
 for _,o in ipairs(objects)do
  local x,z=(o.x+ox)*16,(o.y+oz)*16
  if o.kind=='silphWallCourse'then
   local vv=V.require('PaperSprite').build(ts,16,32,function(sx,sy)
    return sy<16 and o.top or o.bottom,sx,sy%16
   end,function()return true end,0,32,c.wallHeight/32,function()return 10 end,nil,.5)
   for _,v in ipairs(vv)do out[#out+1]=G.place(v,x,z+32)end
   -- The cutaway retains a thin wall cap. The newly visible footprint
   -- uses the room's original floor, never a stretched decoration texel.
   for sx=0,15 do
    G.quad(out,{x+sx,0,z+32-cut.wallThickness,x+8,z+32,0},{x+sx+1,0,z+32-cut.wallThickness,x+8,z+32,0},
     {x+sx+1,0,z+32,x+8,z+32,0},{x+sx,0,z+32,x+8,z+32,0},G.uv(ts,0x330,sx,0,sx+1,1,.5),11)
   end
   for t=-cut.revealBack,31-cut.wallThickness do
    G.quad(out,{x,cut.revealLift,z+t,x+8,z+32,0},{x+16,cut.revealLift,z+t,x+8,z+32,0},
     {x+16,cut.revealLift,z+t+1,x+8,z+32,0},{x,cut.revealLift,z+t+1,x+8,z+32,0},G.uv(ts,0x334,0,t%16,16,t%16+1,.5),12)
   end
  elseif o.kind=='silphWallPlant'then
   local B=V.require('BuildingMesh');local bg={}
   local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
   for _,m in ipairs({0x338,0x335})do for sy=0,15 do for sx=0,15 do bg[rgb(B.pixel(ts,m,sx,sy))]=true end end end
   local function source(sx,sy)return sy<16 and 0x34f or 0x356,sx,sy%16 end
   local clear,empty,queue={},{},{}
   for sy=0,31 do for sx=0,15 do
    local m,u,v=source(sx,sy);local r,g,b,a=B.pixel(ts,m,u,v)
    clear[sy*16+sx]=a<.5 or bg[rgb(r,g,b)]
   end end
   local function seed(sx,sy)local k=sy*16+sx;if clear[k]and not empty[k]then empty[k]=true;queue[#queue+1]=k end end
   for sx=0,15 do seed(sx,0);seed(sx,31)end
   for sy=0,31 do seed(0,sy);seed(15,sy)end
   local n=1;while queue[n]do
    local k=queue[n];n=n+1;local sx,sy=k%16,math.floor(k/16)
    if sx>0 then seed(sx-1,sy)end;if sx<15 then seed(sx+1,sy)end
    if sy>0 then seed(sx,sy-1)end;if sy<31 then seed(sx,sy+1)end
   end
   local function inside(sx,sy)return not empty[sy*16+sx]end
   local vv=V.require('PaperSprite').build(ts,16,32,source,inside,0,32,c.plantHeight/32,nil,nil,.5)
   for _,v in ipairs(vv)do out[#out+1]=G.place(v,x,z+32)end
   contacts[#contacts+1]={x+8,z+31,7,c.contactRadius,c.contactStrength}
  end
 end
end
return S
