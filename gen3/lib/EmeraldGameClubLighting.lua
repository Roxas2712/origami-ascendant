-- Native Emerald game rooms: fixture lighting and open furniture shadows.
local V=...;local M={}
local mauKinds={mauCounter=true,mauRoulette=true,mauBench=true,mauVending=true,mauSlots=true,mauStool=true,mauPlant=true,mauBin=true}
local mossKinds={mossCounter=true,mossTable=true,mossPC=true,mossDoor=true,mossStairs=true,mossPlant=true,mossStool=true}
function M.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors.gameClubLighting
 if not(c.enabled and d and d.mapType==8)then return end
 if V.require('EmeraldMauvilleCorner').profile(d)then return c.mauville end
 local p=V.require('EmeraldMossdeepClub').profile(d)
 if p then return p.basement and c.basement or c.club end
end
function M.capture(list,o,x,z,vertices,first,last)
 local mau=mauKinds[o.kind];local moss=mossKinds[o.kind]
 if not(mau or moss)then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=mau and all.mauvilleCorner or all.mossdeepClub
 local box=V.require('RoomShadowContours').writer(list,x,z,all.heightScale)
 local function tops(height,thickness)
  -- The renderer already removed native background pixels. Reuse only the
  -- horizontal opaque runs; tables/counters remain open underneath.
  local world=V.require('RoomShadowContours').writer(list,0,0,1)
  local h=height*all.heightScale
  for i=first,last,6 do
   local a,b,u,v=math.huge,-math.huge,math.huge,-math.huge;local top=true
   for j=i,math.min(i+5,last)do local q=vertices[j]
    if math.abs(q[2]-h)>.001 then top=false end
    a=math.min(a,q[1]);b=math.max(b,q[1]);u=math.min(u,q[3]);v=math.max(v,q[3])
   end
   if top and b>a and v>u then world(a,b,u,v,h-thickness*all.heightScale,h,true)end
  end
 end
 if o.kind=='mauCounter'or o.kind=='mossCounter'then tops(c.counterHeight,2)
 elseif o.kind=='mauRoulette'or o.kind=='mossTable'then tops(c.tableHeight,2)
 elseif o.kind=='mauBench'then tops(c.benchHeight,2)
 elseif o.kind=='mauVending'then box(1,15,32-c.vendingDepth,32,0,c.vendingHeight)
 elseif o.kind=='mossPC'then box(1,15,40-c.terminalDepth,40,0,c.terminalHeight)
 elseif o.kind=='mauSlots'then
  -- Match the two sloping machine faces, including the low end cap. Do
  -- not replace the peaked row by a full-height enclosing rectangle.
  for _,s in ipairs({{1,4,.31},{4,8,.75},{8,24,1},{24,28,.75},{28,31,.31}})do
   box(s[1],s[2],0,72,0,c.machineHeight*s[3],true)
   box(s[1],s[2],72,75,0,c.machineHeight*s[3]*.5,true)
  end
 elseif o.kind=='mossDoor'then box(0,o.w,34.75,35.25,0,c.wallHeight)
 elseif o.kind=='mossStairs'then
  -- Recess remains open in the middle; no box in front of the steps.
  box(0,16,31.75,32.25,0,c.wallHeight);box(32,48,31.75,32.25,0,c.wallHeight)
 elseif o.kind=='mauPlant'or o.kind=='mossPlant'then
  local f=mau and 31 or 32;box(5,11,f-.25,f+.25,0,12)
 end
 -- Small stools/bins retain their existing contact shadow; their atlas
 -- rectangle must never become a solid full-height shadow volume.
 return true
end
return M
