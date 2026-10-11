-- Measured fixed ceiling light and panel accents, independent of player/time.
local V=...;local R={}
local function cfg()return V.require('DioramaConfig').interiors.rocketLighting end
function R.profile(d)
 if not(cfg().enabled and V.require('RocketRoomShell').profile(d))then return end
 local c=cfg();local L=d.midLayout;local room=c.rooms[d.id or d.name];if not room then return end
 local sources={}
 for _,p in ipairs(room)do
  local m=L:midAt(math.floor(p[1]),math.floor(p[2]));if not m or m==0 or m==8 then return end
  sources[#sources+1]={at={p[1]*16,c.height,p[2]*16},radius=c.radius,power=c.power,
   color=c.color,spread=c.spread,direction={0,-1,0},cone=c.cone}
 end
 -- Light belongs to an actual native panel, not to an invisible lamp carried
 -- by the player. Small warm panel accents do not tint the ambient fill.
 for y=0,L.height-1 do for x=0,L.width-1 do if L:midAt(x,y)==0x28b then
  sources[#sources+1]={at={x*16+8,c.panelHeight,(y+2)*16+2},radius=c.panelRadius,power=c.panelPower,
   color=c.panelColor,spread={2,2},direction={0,0,1},cone=-.15}
 end end end
 return {fixed=true,ambient=c.ambient,sources=sources,localSelection=true,rocket=true}
end
function R.capture(L,objects,ox,oz)
 local rig=V.require('RoomLightRig');local list=rig.geometry[L];if not list then return end
 local c=cfg();local function box(x0,z0,x1,z1,h,wall,y0)
  rig.capture(L,{kind=wall and'wall'or'rocketBlocker'},{{x0,y0 or .051,z0},{x1,h,z1},{x0,h,z0},{x1,y0 or .051,z1}},1,4)
 end
 -- Inter-room voids block light as structural spaces. Merge vertical runs.
 local previous={}
 for y=0,L.height-1 do
  local row={};local x=0
  while x<L.width do
   local m=L:midAt(x,y)
   if m==0 or m==8 then
    local first=x;repeat x=x+1 until x==L.width or(L:midAt(x,y)~=0 and L:midAt(x,y)~=8)
    local key=first..':'..x;local b=previous[key]
    if b then b.hi[3]=(y+oz+1)*16 else b={lo={(first+ox)*16,0,(y+oz)*16},hi={(x+ox)*16,c.blockerHeight,(y+oz+1)*16},wall=true};list[#list+1]=b end
    row[key]=b
   else x=x+1 end
  end
  previous=row
 end
 for _,o in ipairs(objects)do
  local x,z=(o.x+ox)*16,(o.y+oz)*16
  if o.kind=='rocketWall'then
   -- Door panels occupy their own source columns; leave their opening in
   -- the structural light blockers so the threshold stays readable.
   if o.top<0x2a2 or o.top>0x2a4 then box(x,z+29,x+16,z+32,c.blockerHeight,true)end
  elseif o.kind=='rocketBorder'then
   local m=L:midAt(o.x,o.y)
   if m==0x288 or m==0x290 then box(x+8,z,x+16,z+16,c.blockerHeight,true)
   elseif m==0x28c or m==0x294 then box(x,z,x+8,z+16,c.blockerHeight,true)
   elseif m==0x29a then box(x,z+8,x+16,z+11,c.blockerHeight,true)end
  elseif o.kind=='rocketWorkDesk'or o.kind=='rocketDrawingDesk'then
   local h=V.require('DioramaConfig').interiors.rocketFurniture.deskHeight
   local top=o.kind=='rocketDrawingDesk'and 3 or 12
   box(x+2,z+top,x+o.w-2,z+o.h-16,h,false,h-c.tableThickness)
  elseif o.kind=='warehouseBoxes'or o.kind=='warehousePallet'then
   local w=V.require('DioramaConfig').interiors.rocketWarehouse
   box(x,z+o.back,x+o.w*16,z+o.depth,o.kind=='warehouseBoxes'and w.boxHeight or w.palletHeight,false)
  elseif o.kind=='rocketCupboard'then
   local f=V.require('DioramaConfig').interiors.rocketFurniture
   box(x+2,z+o.h-8-f.cupboardDepth,x+o.w-2,z+o.h-8,f.cupboardHeight,false)
  end
 end
end
return R
