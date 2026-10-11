-- Native FR lift cabin: one connected wall and the unchanged tile floor.
local V=...
local E={}
function E.profile(def)
 local c=V.require('DioramaConfig').interiors.elevatorSurfaces
 local L=def and def.midLayout
 if not(L and def.mapType==8 and (def.renderPair or def.pair)=='building__rom_082d4ecc'
  and c.rooms[def.id or def.name] and L.width==6 and L.height==8)then return end
 -- Structural anchors exclude other facility layouts while allowing the
 -- three scrolling indicator tiles to change during a native lift ride.
 for _,a in ipairs({{0,0,0x2eb},{4,0,0x2ec},{0,2,0x2fb},{4,2,0x2fc},{2,6,0x1b}})do
  if L:midAt(a[1],a[2])~=a[3]then return end
 end
 return c
end
function E.lighting(def)
 local c=E.profile(def)
 if c and c.rooms[def.id or def.name]=='fixed'then return c.closedLight end
end
function E.cameraOffset(def)
 if not E.profile(def)then return 0,0 end
 -- Native elevator tasks own timing and reset. Compensate the camera pitch
 -- as in the moving-van room so one native vertical pixel stays visible.
 local f=require('src.core.game3.field_view')
 return f.cameraPanX or 0,(f.cameraPanY or 0)/math.sin(V.require('Camera').elevation())
end
function E.plan(def)
 if V.require('IndoorSurfaces').profile(def)~=V.require('DioramaConfig').interiors.elevatorSurfaces then return end
 local L=def.midLayout;local wall={kind='elevatorWall',x=0,y=0,w=5,front=48}
 local mask,owners={},{}
 for y=0,2 do for x=0,4 do local k=y*L.width+x+1;mask[k]={mid=0,void=true};owners[k]=wall end end
 -- Native black padding is empty space, not a raised wall or floor plate.
 for y=0,L.height-1 do for x=0,L.width-1 do
  local mid=L:midAt(x,y)
  if mid==0 or mid==8 then mask[y*L.width+x+1]={mid=0,void=true}end
 end end
 local doorway={kind='elevatorDoorway',x=1,y=6,w=3}
 for x=1,3 do mask[6*L.width+x+1]={mid=0,void=true}end
 return {objects={wall,doorway},mask=mask,owners=owners}
end
function E.doorway(api,out,L,ts,o,x,z)
 local BM,G=V.require('BuildingMesh'),V.require('WorldGeometry')
 local function inside(mid,u,v)
  local r,g,b,a=BM.pixel(ts,mid,u,v)
  return a>.5 and (r>0 or g>0 or b>0)
 end
 for tile=0,2 do local mid=L:midAt(o.x+tile,o.y)
  for sy=0,15 do local sx=0
   while sx<16 do
    if inside(mid,sx,sy)then
     local first=sx;repeat sx=sx+1 until sx==16 or not inside(mid,sx,sy)
     local a,b=x+tile*16+first,x+tile*16+sx
     G.quad(out,{a,0,z+sy},{b,0,z+sy},{b,0,z+sy+1},{a,0,z+sy+1},G.uv(ts,mid,first,sy,sx,sy+1,.5),1)
    else sx=sx+1 end
   end
  end
 end
end
function E.wall(api,out,L,ts,o,x,z)
 local c=V.require('DioramaConfig').interiors.elevatorSurfaces
 local h,d=c.wallHeight,c.wallDepth
 -- Rows 0..7 are native void. All art from trim through baseboard is
 -- retained exactly once; none of the moving-light/handrail pixels are cut.
 api.patch(out,L,ts,o,0,8,80,40,{x,h,z+48},{x+80,h,z+48},{x+80,0,z+48},{x,0,z+48})
 api.patch(out,L,ts,o,0,8,80,2,{x,h,z+48-d},{x+80,h,z+48-d},{x+80,h,z+48},{x,h,z+48})
 api.patch(out,L,ts,o,0,8,1,40,{x,h,z+48-d},{x,h,z+48},{x,0,z+48},{x,0,z+48-d},.9)
 api.patch(out,L,ts,o,79,8,1,40,{x+80,h,z+48},{x+80,h,z+48-d},{x+80,0,z+48-d},{x+80,0,z+48},.9)
end
return E
