-- Indoor profiles describe surfaces: shelf fronts stand, tabletops lie,
-- chair backs stand above seats, and floor/rug drawings stay at ground level.
local V=...
local F={rooms=setmetatable({},{__mode="k"}),anchors=setmetatable({},{__mode="k"}),owners=setmetatable({},{__mode="k"}),defs=setmetatable({},{__mode="k"}),ramps=setmetatable({},{__mode='k'})}
local Budget=V.require('BuildBudget')
-- Provider initialization may load many independent room modules. Yield only
-- inside the geometry queue; direct tools and runtime lookups stay synchronous.
local function provider(name)
 local module=V.require(name);Budget.check();return module
end
function F.plan(def)
 local L=def.midLayout;local pair=(def.renderPair or def.pair)
 F.rooms[L]=nil
 if provider('EmeraldRoomSurfaces').profile(def)then
  F.rooms[L]=def;return provider('EmeraldRoomSurfaces').plan(def)
 end
 local objects,mask,wallClear={},{},{}
 local owners,owner={},nil;F.owners[L]=owners;F.defs[L]=def
 F.ramps[L]={}
 local memorial=provider('PokemonTowerFurniture').plan(def);local shell=provider('PokemonTowerShell').plan(def)
 if memorial or shell then
  local p=memorial or{objects={},mask={}}
  if shell then for _,o in ipairs(shell.objects)do p.objects[#p.objects+1]=o end;for k,m in pairs(shell.mask)do p.mask[k]=m end end
  return p.objects,p.mask
 end
 local tanoby=provider('TanobyChambers').plan(def);if tanoby then return tanoby.objects,tanoby.mask end
 local dojo=provider('FireRedDojo').plan(def);if dojo then return dojo.objects,dojo.mask end
 local cable=provider('FireRedCableRooms').plan(def);if cable then return cable.objects,cable.mask end
 local islandHarbor=provider('EmeraldIslandHarbors').plan(def);if islandHarbor then return islandHarbor.objects,islandHarbor.mask end
 local harbor=provider('FireRedHarbors').plan(def);if harbor then return harbor.objects,harbor.mask end
 local tunnel=provider('FireRedTunnels').plan(def);if tunnel then return tunnel.objects,tunnel.mask end
 local gym=provider('FireRedGymRooms').plan(def);if gym then return gym.objects,gym.mask end
 local seven=provider('SevenIslandRooms').plan(def);if seven then return seven.objects,seven.mask end
 local copycat=provider('CopycatRoom').plan(def);if copycat then return copycat.objects,copycat.mask end
 local special=provider('FireRedFinalRooms').plan(def)or provider('FireRedLeagueRooms').plan(def)or provider('TrainerTowerRoof').plan(def)or provider('InteriorCommunity').plan(def)or provider('InteriorIndigoReception').plan(def) or provider('InteriorCasino').plan(def) or provider('InteriorCelio').plan(def) or provider('InteriorShipCorridors').plan(def) or provider('InteriorShipPublic').plan(def) or provider('InteriorShipCabins').plan(def) or provider('InteriorHouseVariants').plan(def) or provider('FireRedDepartmentRoof').plan(def) or provider('InteriorLab').plan(def) or provider('InteriorNetwork').plan(def) or provider('InteriorSchool').plan(def)
  or provider('InteriorTransit').plan(def) or provider('InteriorHotel').plan(def) or provider('InteriorRestaurant').plan(def) or provider('InteriorMuseum').plan(def) or provider('InteriorCondo').plan(def) or provider('InteriorClub').plan(def) or provider('InteriorBikeShop').plan(def) or provider('InteriorDepartment').plan(def) or provider('InteriorElevator').plan(def)
 if special then F.owners[L]=special.owners;F.ramps[L]=special.ramps or {};return special.objects,special.mask end
 local home=pair=="player_house" or pair=="house"
 local network=pair=="network"
 local mart=pair=="building__rom_082d4bcc"
 local extras=V.require("IndoorProfiles")
 if pair~="oak_lab" and not home and not network and not mart and not extras.family(def) then
  local oo,mm=provider('IndoorCutouts').plan(def)
  for _,o in ipairs(oo)do if o.kind=='silphStairs'then F.ramps[L][#F.ramps[L]+1]=o end end
  return oo,mm
 end
 local floor=pair=="oak_lab" and 0x289 or (network or mart) and 0x281 or 1
 if home then
  local counts={}
  for _,c in ipairs(L.cells)do counts[c.mid]=(counts[c.mid] or 0)+1 end
  for _,m in ipairs({0xa9,0x109,0x281})do if (counts[m] or 0)>(counts[floor] or 0) then floor=m end end
 end
 floor=extras.floor(def) or floor
 -- The compact house atlas may omit unused interior tile 0x45. The lower
 -- eight rows of the present top-border tile repeat to exactly that pattern.
 local rugInterior={mid=0x44,x0=0,y0=8,x1=16,y1=16,repeatY=2}
 local northBorder,westBorder=false,false
 if home and floor==1 then
  for x=1,L.width-1 do if L:midAt(x,2)==0x009 then northBorder=true;break end end
  for x=0,1 do
   for y=2,L.height-1 do if L:midAt(x,y)==0x009 then westBorder=x;break end end
   if westBorder~=false then break end
  end
 end
 local function claim(x,y,ground)
  -- Native parquet rooms shade the north/west border with
  -- 0x009. Removing furniture must continue that border, not insert bright
  -- 0x001 rectangles beside the bed or beneath the desk. Explicit rug and
  -- void donors still take precedence. Require a native border witness.
  if ground==nil and x>=0 and y>=2
   and (x==westBorder or y==2 and northBorder) then ground=0x009 end
  if x>=0 and x<L.width and y>=0 and y<L.height then local k=y*L.width+x+1;mask[k]=ground or floor;owners[k]=owner or objects[#objects] end
 end
 local function panel(x,y,w,cap,split,last,depth,sideMid,sideX,sideY,base)
  local o={kind="panel",x=x,y=y,w=w,cap=cap,split=split,last=last,depth=depth,
   sideMid=sideMid,sideX=sideX,sideY=sideY,base=base or 0}
  objects[#objects+1]=o
  for dy=0,math.ceil(last/16)-1 do for dx=0,w-1 do claim(x+dx,y+dy) end end
  if y==0 then for dx=0,w-1 do wallClear[x+dx]=true end end
  return o
 end
 -- A back wall is one upright composite of its two drawn rows. Its art is
 -- never wrapped onto the top and never repeated down the room.
 for x=0,L.width-1 do
  if L:midAt(x,0)~=0 and L:midAt(x,0)~=8 then
   objects[#objects+1]={kind="wall",x=x,y=0,clear=pair=="oak_lab" and (L:midAt(x,1)==0x73 or L:midAt(x,1)==0x74)}
   claim(x,0,0);claim(x,1,0)
  end
 end
 for y=1,L.height-1 do for x=0,L.width-1 do
  local mid=L:midAt(x,y)
  if network and y==1 and mid==0x348 then
   local o=panel(x,1,6,0,46,77,48,0x358,0,8);o.contour=true;o.background={};o.backgroundPixels={{0x348,0,0},{0x2a9,8,0}};o.front=77
   -- The upper rim is part of the machine, not another wall decoration.
   for dx=0,5 do wallClear[x+dx]=true end
  elseif network and mid==0x300 and L:midAt(x,y+1)==0x301 then
   objects[#objects+1]={kind="plant",x=x,y=y+1,ground=floor}
   claim(x,y);claim(x,y+1)
  elseif network and mid==0x2db and L:midAt(x+1,y)==0x2dc then
   objects[#objects+1]={kind="escalator",x=x,y=y,reverse=true}
   for dy=0,2 do for dx=0,1 do claim(x+dx,y+dy)end end
  elseif network and mid==0x2a7 and L:midAt(x,y+1)==0x2af then
   panel(x,y,1,0,5,32,12,0x2af,2,5)
  elseif network and y==2 and mid==0x326 then
   panel(x,y,1,10,18,40,12,0x326,1,12).front=40
  elseif network and y==1 and mid==0x2fe then
   local o=panel(x,y,1,29,33,51,12,0x365,1,8);o.front=49
   objects[#objects+1]={kind="standing",x=x,y=y,w=1,pixelH=26,sy=3,depth=5,front=45,base=18,
    backgroundPixels={{0x2fe,0,0},{0x2fe,0,5},{0x2fe,0,7}}}
   wallClear[x]=true
  elseif network and y==2 and (mid==0x2da or mid==0x328 or mid==0x327 or mid==0x376 or mid==0x302 or mid==0x363) then
   local o=panel(x,y,1,12,25,32,15,0x2e9,6,4);o.height=10;o.front=28
  -- 0x2b7 / 0x2c6 are shaded floor beneath the wall picture, not furniture.
  elseif network and y==1 and mid==0x2aa then
   local o=panel(x,1,2,0,7,28,16,0x2aa,2,11);o.front=28;o.contour=true;o.background={};o.backgroundPixels={{0x2aa,0,0},{0x2aa,0,5}}
   wallClear[x]=true;wallClear[x+1]=true
  elseif network and y==1 and mid==0x2ac then
   local o=panel(x,y,2,0,10,25,12,0x2ad,2,9,11);o.front=30
   wallClear[x]=true;wallClear[x+1]=true
  elseif network and y==1 and mid==0x62 then
   panel(x,0,1,12,18,39,9,0x62,1,6).front=43
  elseif network and y==1 and mid==0x2cb then
   panel(x,0,2,11,16,39,12,0x2cb,1,6).front=42
  elseif network and mid==0x2b1 then
   objects[#objects+1]={kind="counter",x=x,y=y,w=7}
   if provider('IndoorSurfaces').profile(def)then wallClear[x]=true;wallClear[x+6]=true end
   for dx=0,6 do claim(x+dx,y+1);claim(x+dx,y) end
  elseif network and (mid==0x2f5 or mid==0x2fd) then
   objects[#objects+1]={kind="stool",x=x,y=y};claim(x,y)
  elseif network and mid==0x29c and L:midAt(x+1,y)==0x29d then
   objects[#objects+1]={kind="roundtable",x=x,y=y}
   for dy=0,1 do for dx=0,1 do claim(x+dx,y+dy)end end
  elseif network and mid==0x2d0 and L:midAt(x+1,y)==0x2d1 then
   objects[#objects+1]={kind="escalator",x=x,y=y}
   for dy=0,2 do for dx=0,1 do claim(x+dx,y+dy)end end
  elseif network and mid==0x294 and L:midAt(x,y-1)==0x28d then
   objects[#objects+1]={kind="plant",x=x,y=y,ground=floor,rows=3,trim=8,bg={0x284,0x2a9}}
   for dy=-2,0 do claim(x,y+dy)end;wallClear[x]=true
  elseif mart and mid==0x2b6 and L:midAt(x,y-1)==0x2b5 then
   objects[#objects+1]={kind="plant",x=x,y=y,ground=floor};claim(x,y-1);claim(x,y)
  elseif mart and mid==0x2b0 then
   panel(x,y,3,0,6,16,14,0x2b1,6,12)
  elseif mart and mid==0x2b7 and L:midAt(x+1,y)==0x2bc then
   panel(x,y,2,12,24,32,16,0x2c1,1,15)
  elseif mart and mid==0x29d then
   local o=panel(x,y,1,16,32,44,24,0x2ad,2,10);o.height=10
   panel(x,y-1,1,12,16,32,8,0x29d,1,8,10).front=40;wallClear[x]=true
  elseif mart and y==1 and mid==0x29a then
   panel(x,0,3,12,16,36,12,0x29a,1,9).front=41
  elseif mart and mid==0x29e and L:midAt(x,y-1)==0x296 then
   local width=L:midAt(x+1,y)==0x29f and 2 or 1
   objects[#objects+1]={kind="gondola",x=x,y=y-1,w=width}
   for dy=-1,2 do for dx=0,width-1 do claim(x+dx,y+dy)end end
  elseif home and y==1 and mid==0xe0 then
   panel(x,0,2,16,30,44,16,0xe8,6,4)
  elseif home and y==1 and mid==0xb4 then
   panel(x,0,2,14,19,44,13,0xb4,3,12)
  elseif home and y==1 and mid==0xb7 then
   panel(x,0,1,13,18,44,10,0xb7,3,10)
  elseif home and y==1 and mid==0x35 and L:midAt(x,0)==0xaa then
   panel(x,0,1,13,16,42,12,0x35,0,7)
  elseif home and ((mid==0x128 and L:midAt(x+1,y)==0x129) or (mid==0xc8 and L:midAt(x+1,y)==0xc9)) then
   local rug=mid==0x128 and 0x134 or 0xd4
   objects[#objects+1]={kind="glass",x=x,y=y,ground=rug}
   for dy=0,1 do for dx=0,1 do claim(x+dx,y+dy,{mid=rug,x0=8,y0=2,x1=9,y1=3})end end
  elseif home and (mid==0x126 or mid==0x127 or mid==0xc6 or mid==0xc7) then
   local rug=mid>=0x126 and 0x134 or 0xd4
   objects[#objects+1]={kind="seat",x=x,y=y,right=mid==0x127 or mid==0xc7,ground=rug}
   claim(x,y,{mid=rug,x0=8,y0=2,x1=9,y1=3})
  elseif home and (mid==0x15e or mid==0x15d) then
   objects[#objects+1]={kind="plant",x=x,y=y,ground=floor,bg={0xa3,0x9b,0x109},trim=0}
   claim(x,y-1);claim(x,y)
  elseif home and (mid==0xfe or mid==0xfd or mid==0xd2 and L:midAt(x,y-1)==0xca) then
   objects[#objects+1]={kind='plant',x=x,y=y,ground=floor,bg={0xb1,0xb0,0xa8}}
   claim(x,y-1);claim(x,y)
   if y==2 then wallClear[x]=true;claim(x,y-2)end
  elseif pair=="house" and mid==0x2ea and L:midAt(x,y+1)==0x2f1 then
   objects[#objects+1]={kind="plant",x=x,y=y+1,ground=floor,bg={0x282},bgPixels={{0x28f,0,0},{0x28f,0,8},{0x28f,0,9}}}
   claim(x,y);claim(x,y+1);wallClear[x]=true
  elseif pair=="house" and mid==0x2e9 and L:midAt(x,y+1)==0x2f1 then
   objects[#objects+1]={kind="plant",x=x,y=y+1,ground=floor,bg={0x282}}
   claim(x,y);claim(x,y+1)
  elseif pair=="house" and mid==0x2d6 and L:midAt(x+1,y)==0x2d7 then
   objects[#objects+1]={kind="roundtable",x=x,y=y,ground=floor}
   for dy=0,1 do for dx=0,1 do claim(x+dx,y+dy)end end
  elseif pair=="house" and (mid==0x2e6 or mid==0x2e7) then
   objects[#objects+1]={kind="seat",x=x,y=y,right=mid==0x2e7,ground=floor};claim(x,y)
  elseif pair=="house" and (mid==0x2c1 or mid==0x2c0) then
   objects[#objects+1]={kind="standing",x=x,y=y,w=1,h=2,depth=5,ground=floor,background={floor,0x282},
    backgroundPixels={{0x2b0,1,0},{0x2b0,15,9},{0x2b0,1,10},{0x2b0,1,14}},base=0,front=30}
   claim(x,y);claim(x,y+1);wallClear[x]={L:midAt(x,0),mid==0x2c1 and 0x2b1 or 0x2b0}
  elseif pair=="house" and mid==0x2aa and L:midAt(x+1,y)==0x2ab then
   objects[#objects+1]={kind="gatestairs",x=x,y=y}
   for dy=0,2 do for dx=0,2 do claim(x+dx,y+dy)end end
  elseif home and y==1 and mid==0x31 and L:midAt(x+1,y)==0x32 then
   panel(x,0,2,16,32,44,16,0x39,7,6)
  elseif home and y==1 and mid==0x36 then
   panel(x,0,2,13,16,43,12,0x36,2,5)
  elseif home and y==1 and mid==0x35 then
   panel(x,0,1,12,16,42,12,0x35,0,7)
  elseif home and y==1 and mid==0x33 then
   panel(x,0,2,11,14,40,12,0x33,1,4).front=44
  elseif pair=="player_house" and y==1 and mid==0x28f then
   panel(x,0,1,14,20,37,10,0x28f,2,8,14).front=44
   objects[#objects+1]={kind="desk",x=x,y=1,w=2,home=true}
   claim(x+1,1);claim(x+1,2);wallClear[x+1]=true
  elseif pair=="oak_lab" and y==1 and mid==0x2ad then
   panel(x,0,2,10,16,44,14,0x2ad,0,7)
  elseif pair=="oak_lab" and mid==0x29f then
   panel(x,y,1,0,6,16,10,0x29f,2,8)
  elseif pair=="oak_lab" and y==1 and (mid==0x75 or mid==0x85) then
   objects[#objects+1]={kind="desk",x=x,y=y,w=2}
   for dx=0,1 do claim(x+dx,y);claim(x+dx,y+1);wallClear[x+dx]=true end
   if mid==0x75 then panel(x,0,2,16,20,32,9,0x75,1,6,14).front=42 end
  elseif pair=="player_house" and mid==0x28c then
   objects[#objects+1]={kind="bed",x=x-1,y=y-1}
   for dz=-1,1 do for dx=-1,1 do claim(x+dx,y+dz) end end
  elseif pair=="player_house" and mid==0x35 and L:midAt(x,y-1)==0x286 then
   objects[#objects+1]={kind="console",x=x,y=y-1}
   for dz=-1,1 do
    local donor=provider('IndoorSurfaces').profile(def) and L:midAt(x-1,y+dz) or nil
    claim(x,y+dz,donor)
   end
  elseif home and ((mid==5 and L:midAt(x+1,y)==6) or (mid==0x16 and L:midAt(x+1,y)==0x17) or (mid==0xeb and L:midAt(x+1,y)==0xec)) then
   local up=mid~=5
   objects[#objects+1]={kind=up and 'stairsUp' or 'stairs',x=x,y=y,w=2}
   for dz=0,(provider('IndoorSurfaces').profile(def) and not up and 1 or 2) do for dx=0,1 do claim(x+dx,y+dz) end end
   if y==1 then wallClear[x]=true;wallClear[x+1]=true end
  elseif pair=="oak_lab" and (mid==0x73 or mid==0x74) then
   objects[#objects+1]={kind="shelf",x=x,y=y}
   claim(x,y-1);claim(x,y);claim(x,y+1)
  elseif pair=="oak_lab" and mid==0x2ab then
   objects[#objects+1]={kind="machine",x=x,y=y}
   for dz=-1,1 do for dx=0,1 do claim(x+dx,y+dz) end end
  elseif pair=="oak_lab" and mid==0x2a8 then
   objects[#objects+1]={kind="table",x=x,y=y,w=3,d=1,height=14,lab=true}
   for dx=0,2 do claim(x+dx,y);claim(x+dx,y+1) end
  elseif home and mid==0x4c then
   objects[#objects+1]={kind="table",x=x,y=y,w=2,d=2,ground=0x44}
   -- 0x44 is the TOP rug border; furniture sits on the dotted interior.
   -- Keep its full palette for the furniture cutout, but never repeat the
   -- border as replacement ground underneath the table/chairs.
   for dz=0,1 do for dx=0,1 do claim(x+dx,y+dz,rugInterior) end end
  elseif home and (mid==0x4b or mid==0x4e) then
   objects[#objects+1]={kind="chair",x=x,y=y,right=mid==0x4e}
   claim(x,y,rugInterior)
  elseif (home and (mid==0x5f or mid==0x4f))
      or (pair=="oak_lab" and (mid==0x29b or mid==0x29c)) then
   objects[#objects+1]={kind="plant",x=x,y=y,ground=floor}
   claim(x,y-1);claim(x,y)
  end
 end end
 extras.plan(def,{panel=panel,claim=claim,add=function(o)objects[#objects+1]=o end,clear=function(x)wallClear[x]=true end})
 if provider('IndoorSurfaces').profile(def) and (def.id or def.name)=='FR_PLAYERS_HOUSE_2F' then
  -- Native narrow shelf between desk and bookcase: its lower row is furniture,
  -- not floor. Keep the complete elevation independent from the back wall.
  panel(3,1,1,2,4,24,8,L:midAt(3,1),1,10).front=24;wallClear[3]=true
 end
 for _,o in ipairs(objects)do
  owner=o
  if o.kind=="wall" then claim(o.x,0,0);claim(o.x,1,0) end
  if o.kind=="wall" and wallClear[o.x] then o.clear=true;o.home=home;o.network=network;o.mart=mart;o.floor=floor;o.school=extras.family(def)=="school" end
  if o.kind=="wall" and o.clear and home then
   o.wallSource=floor==0xa9 and {0xa8,0xb0} or floor==0x109 and {0x9b,0xa3} or {0x20,0x28}
  end
  if o.kind=="wall" and type(wallClear[o.x])=="table" then o.wallSource=wallClear[o.x] end
 end
 if provider('IndoorSurfaces').profile(def)then
  -- The old wooden-floor shadow strip cannot meet the unshaded donor under
  -- lifted furniture: it leaves bright tile rectangles below the cabinets.
  -- Use the matching native floor throughout; room lighting supplies shadows.
  -- This is a render mask only, never a metatile/collision edit.
  if home and floor==0x109 then
   for k,cell in ipairs(L.cells)do
    if cell.mid==0x111 and mask[k]==nil then mask[k]=0x109 end
   end
  end
  for _,o in ipairs(objects)do
   if o.kind=='stairs' then
    for dy=0,1 do for dx=0,1 do mask[(o.y+dy)*L.width+o.x+dx+1]={mid=0,void=true} end end
   elseif o.kind=='stairsUp' then F.ramps[L][#F.ramps[L]+1]=o end
  end
 end
 provider('GateFixtures').plan(def,objects,mask)
 provider('GateDivider').plan(def,objects,mask)
 provider('GatePartitions').plan(def,objects,mask)
 provider('GateStairs').plan(def,objects,mask,F.ramps[L])
 provider('GateFurniture').plan(def,objects,mask)
 provider('GateStatues').plan(def,objects,mask)
 return objects,mask
end
-- Connected original drawings become flat cutouts; the old prism/voxel
-- furniture builders are deliberately absent from the paper runtime.
function F.cutouts(out,objects,L,ts,ox,oz,mask)
 local pixel=V.require("BuildingMesh").pixel
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 local seen={}
 local anchors={};F.anchors[L]=anchors
 for start in pairs(mask or {})do if not seen[start] and not(type(mask[start])=="table" and mask[start].separateSurface)then
  local first=mask[start];local group=type(first)=='table'and first.group or false
  local queue={start};seen[start]=true;local n=1
  local x0,z0,x1,z1=L.width,L.height,0,0;local cells,bg={},{};local opaque=false;local opaqueRows=0
  while queue[n]do
   local k=queue[n];n=n+1;cells[k]=true
   local x,z=(k-1)%L.width,math.floor((k-1)/L.width)
   x0=math.min(x0,x);x1=math.max(x1,x);z0=math.min(z0,z);z1=math.max(z1,z)
   local donor=mask[k];opaque=opaque or type(donor)=="table" and donor.opaque==true
   if type(donor)=="table" then opaqueRows=math.max(opaqueRows,donor.opaqueRows or 0)end
   local mid=type(donor)=="table" and donor.mid or donor
   local function background(m)
    if ts.midToSlot[m]then for yy=0,15 do for xx=0,15 do local r,g,b=pixel(ts,m,xx,yy);bg[rgb(r,g,b)]=true end end end
   end
   background(mid)
   if type(donor)=="table"then for _,m in ipairs(donor.background or{})do background(m)end end
   for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}})do
    local xx,zz=x+d[1],z+d[2];local j=zz*L.width+xx+1
    local other=mask[j];local otherGroup=type(other)=='table'and other.group or false
    if xx>=0 and xx<L.width and zz>=0 and zz<L.height and other and not(type(other)=="table" and other.separateSurface) and not seen[j] and otherGroup==group then seen[j]=true;queue[#queue+1]=j end
   end
  end
  for k in pairs(cells)do anchors[k]=(z1+1)*16 end
  local W,H=(x1-x0+1)*16,(z1-z0+1)*16
  local clear,empty,edge={},{},{}
  local function source(x,y)return L:midAt(x0+math.floor(x/16),z0+math.floor(y/16)),x%16,y%16 end
  for y=0,H-1 do for x=0,W-1 do
   local mid,sx,sy=source(x,y);local r,g,b,a=pixel(ts,mid,sx,sy)
   local k=(z0+math.floor(y/16))*L.width+x0+math.floor(x/16)+1
   local donor=mask[k];local keep=opaque or y<opaqueRows*16
   if type(donor)=="table" and donor.keepPixels then
    for _,rect in ipairs(donor.keepPixels[mid]or{})do
     if sx>=rect[1] and sx<rect[1]+rect[3] and sy>=rect[2] and sy<rect[2]+rect[4]then keep=true end
    end
   end
   clear[y*W+x]=not cells[k] or a<.5 or not keep and bg[rgb(r,g,b)]
  end end
  local function seed(x,y)local k=y*W+x;if clear[k] and not empty[k]then empty[k]=true;edge[#edge+1]=k end end
  for x=0,W-1 do seed(x,0);seed(x,H-1)end
  for y=0,H-1 do seed(0,y);seed(W-1,y)end
  n=1
  while edge[n]do
   local k=edge[n];n=n+1;local x,y=k%W,math.floor(k/W)
   if x>0 then seed(x-1,y)end;if x<W-1 then seed(x+1,y)end
   if y>0 then seed(x,y-1)end;if y<H-1 then seed(x,y+1)end
  end
  local vertices=provider('PaperSprite').build(ts,W,H,source,function(x,y)return not empty[y*W+x]end,0,H)
  for _,v in ipairs(vertices)do out[#out+1]=V.require("WorldGeometry").place(v,(x0+ox)*16,(z1+oz+1)*16)end
 end end
end
function F.build(out,objects,L,ts,ox,oz,mask,contacts)
 provider('CenterHealingSurface').bind(F.rooms[L]or F.defs[L],objects)
 provider('RoomLightRig').begin(L,F.rooms[L]or F.defs[L])
 if F.rooms[L]then
  F.anchors[L]={};return provider('EmeraldRoomSurfaces').build(out,objects,L,ts,ox,oz,contacts)
 end
 local I=V.require('IndoorSurfaces');local def=F.defs[L]
 if def and provider('FireRedFinalRooms').profile(def)then
  F.anchors[L]={};return provider('FireRedFinalRooms').build(out,def,ts,ox,oz,contacts or {})
 end
 if def and provider('FireRedLeagueRooms').profile(def)then
  F.anchors[L]={};return provider('FireRedLeagueRooms').build(out,objects,L,ts,ox,oz,contacts or {})
 end
 if def and provider('TrainerTowerRoof').profile(def)then
  F.anchors[L]={};return provider('TrainerTowerRoof').build(out,objects,L,ts,ox,oz,contacts or {})
 end
 if def and provider('FireRedDepartmentRoof').profile(def)then
  F.anchors[L]={};return provider('FireRedDepartmentRoof').build(out,objects,L,ts,ox,oz,contacts or {})
 end
 if def and (provider('PokemonTowerFurniture').profile(def)or provider('PokemonTowerShell').profile(def))then
  F.anchors[L]={};provider('PokemonTowerShell').build(out,objects,L,ts,ox,oz,contacts or {})
  return provider('PokemonTowerFurniture').build(out,objects,L,ts,ox,oz,contacts or {})
 end
 if def and provider('TanobyChambers').profile(def)then F.anchors[L]={};return provider('TanobyChambers').build(out,def,ts,ox,oz,contacts or{})end
 if def and provider('FireRedDojo').profile(def)then F.anchors[L]={};return provider('FireRedDojo').build(out,objects,L,ts,ox,oz,contacts or {})end
 if def and provider('FireRedCableRooms').profile(def)then F.anchors[L]={};return provider('FireRedCableRooms').build(out,objects,L,ts,ox,oz,contacts or {})end
 if def and provider('EmeraldIslandHarbors').profile(def)then F.anchors[L]={};return provider('EmeraldIslandHarbors').build(out,def,ts,ox,oz,contacts or {})end
 if def and provider('FireRedHarbors').profile(def)then F.anchors[L]={};return provider('FireRedHarbors').build(out,def,ts,ox,oz,contacts or {})end
 if def and provider('FireRedTunnels').profile(def)then F.anchors[L]={};return provider('FireRedTunnels').build(out,def,ts,ox,oz,contacts or {})end
 if def and provider('FireRedGymRooms').profile(def)then
  F.anchors[L]={};return provider('FireRedGymRooms').build(out,objects,L,ts,ox,oz,contacts or {})
 end
 if def and provider('SevenIslandRooms').profile(def)then
  F.anchors[L]={};return provider('SevenIslandRooms').build(out,objects,L,ts,ox,oz,contacts or {})
 end
 if def and provider('CopycatRoom').profile(def)then
  F.anchors[L]={};return provider('CopycatRoom').build(out,objects,L,ts,ox,oz,contacts or {})
 end
 if def and I.profile(def)then
  I.build(out,objects,L,ts,ox,oz,mask,F.owners[L],function(own)
   F.cutouts(out,{},L,ts,ox,oz,own)
  end,contacts or {})
  -- New surfaces retain native actor feet. In particular clerks no longer
  -- inherit the height of a connected counter/wall cutout.
  F.anchors[L]={}
 else
  provider('SeaCottage').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('VolunteerHouse').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('InteriorTrashedHouse').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('InteriorDisplayHouses').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('SafariRooms').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('PowerPlantRoom').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('MansionShell').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('MansionFurniture').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('TrainerTowerLobby').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('TrainerTowerRooms').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('RocketWarehouse').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('RocketFurniture').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('RocketRoomShell').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('SilphWallPlants').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('SilphStairs').build(out,objects,L,ts,ox,oz)
  provider('SilphCounters').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('SilphEquipment').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('SilphFurniture').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('SilphStorage').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('GateFixtures').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('GateDivider').build(out,objects,L,ts,ox,oz)
  provider('GatePartitions').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('GateStairs').build(out,objects,L,ts,ox,oz)
  provider('GateFurniture').build(out,objects,L,ts,ox,oz,contacts or {})
  provider('GateStatues').build(out,objects,L,ts,ox,oz,contacts or {})
  F.cutouts(out,objects,L,ts,ox,oz,mask)
  V.require("GateLighting").compact(L)
  if def and provider('RocketLighting').profile(def)then V.require('RocketLighting').capture(L,objects,ox,oz)end
  if def and provider('SilphLighting').profile(def)then V.require("SilphLighting").capture(L,objects,ox,oz)end
 end
end
-- Native effect art must follow the same connected cutout as the furniture.
function F.paperAnchor(def,x,y)
 local L=def and def.midLayout;local row=L and F.anchors[L]
 if not row then return nil end
 local cx,cy=math.floor(x/16),math.floor(y/16)
 if cx<0 or cy<0 or cx>=L.width or cy>=L.height then return nil end
 local base=row[cy*L.width+cx+1]
 -- The Mart clerk stands in the gap behind the L-shaped counter. That
 -- floor cell is deliberately not furniture, but its actor belongs to the
 -- counter's paper plane. Otherwise the raised front hides the entire clerk.
 -- Match the native counter tiles rather than moving every nearby actor.
 if not base and (def.renderPair or def.pair)=="building__rom_082d4bcc" then
  local mid,front=L:midAt(cx,cy),L:midAt(cx,cy+1)
  if (mid==0x2a9 or mid==0x2aa) and (front==0x2b1 or front==0x2b2) then
   base=row[(cy+1)*L.width+cx+1]
  end
 end
 return base
end
function F.actorOffset(def,x,z,gid,elevation)
 if def then local h=V.require('EmeraldMagmaHideout').actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require('EmeraldCaveTerraces').actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require('FireRedTerracedCaves').actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require('FireRedRuinCaves').actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldPacifidlog").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldFortreeArchitecture").actorHeight(def,x,z,elevation);if h then return h,0 end end
 if def then local h,dz=V.require("EmeraldSecretStructures").actorOffset(def,x,z);if h then return h,dz end end
 if def then local h,dz=V.require('EmeraldSecretDecor').actorOffset(def,x,z,gid);if h then return h,dz end end
 if def then local h=V.require('PokemonTowerShell').actorHeight(def,x+8,z+16);if h then return h,0 end end
 if def then local h,dz=V.require('FireRedGymRooms').actorOffset(def,x,z);if h then return h,dz end end
 if def then local h,dz=V.require('SevenIslandRooms').actorOffset(def,x,z,gid);if h then return h,dz end end
 if def then local h,dz=V.require('CopycatRoom').actorOffset(def,x,z);if h then return h,dz end end
 if def then local h,dz=V.require('InteriorDisplayHouses').actorOffset(def,x,z,gid);if h then return h,dz end end
 if def then local h,dz=V.require('SafariRooms').actorOffset(def,x,z,gid);if h then return h,dz end end
 if def then local h,dz=V.require('PowerPlantRoom').actorOffset(def,x,z,gid);if h then return h,dz end end
 if def then local h,dz=V.require('TrainerTowerRoof').actorOffset(def,x,z);if h then return h,dz end end
 if def then local h,dz=V.require("TrainerTowerLobby").actorOffset(def,x,z);if h then return h,dz end end
 if def then local h,dz=V.require("TrainerTowerRooms").actorOffset(def,x,z);if h then return h,dz end end
 if def then local h,dz=V.require("RocketWarehouse").actorOffset(def,x,z,gid);if h then return h,dz end end
 if def then local h,dz=V.require("RocketFurniture").actorOffset(def,x,z,gid);if h then return h,dz end end
 if def then local h,dz=V.require("MansionFurniture").actorOffset(def,x,z,gid);if h then return h,dz end end
 if def then local h,dz=V.require("MansionShell").actorOffset(def,x,z);if h then return h,dz end end
 if def then local h,dz=V.require("RocketRoomShell").actorOffset(def,x,z,gid);if h then return h,dz end end
 if def then local h=V.require("InteriorCasino").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("InteriorCelio").actorHeight(def,x,z);if h then return h,0 end end
 local gh,gz=V.require("GateFurniture").actorOffset(def,x+8,z+16)
 if gh then return gh,gz end
 if def then local h,dz=V.require("SilphStorage").actorOffset(def,x+8,z+16,gid);if h then return h,dz end end
 if def then local h,dz=V.require("SilphFurniture").actorOffset(def,x+8,z+16,gid);if h then return h,dz end end
 if def then local h=V.require('EmeraldIslandHarbors').actorHeight(def,x,z,gid);if h then return h,0 end end
 if def then local h=V.require('EmeraldWreckDeck').actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require('EmeraldSkyPillar').actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldPyramidTop").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldPyramidLobby").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldBattlePalace").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h,dz=V.require("EmeraldBattleDome").actorHeight(def,x,z);if h then return h,dz or 0 end end
 if def then local h=V.require("EmeraldBattleArena").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldTowerPublic").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldFrontierRanking").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldFrontierReception").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldFrontierExchange").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldFrontierLounges").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("FireRedFinalRooms").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldChampionRoom").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldLeagueRooms").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldContestRooms").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldSootopolisGym").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldMossdeepGym").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldFortreeGym").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldPetalburgGym").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldLavaridgeGym").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldMauvilleGym").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldDewfordGym").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldRustboroGym").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldPyre").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldNavelSanctums").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldNavelPassages").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldMirageTower").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldPowerHall").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldWreckCabins").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldShipCabins").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldDevon").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldWeatherInstitute").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldSpaceCenter").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldShipyard").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldDayCare").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h,dz=V.require('InteriorShipPublic').actorHeight(def,x,z);if h then return h,dz or 0 end end
 if def then local h=V.require("InteriorShipCabins").actorHeight(def,x,z);if h then return h,0 end end
 if def then local h=V.require("EmeraldMauvilleCorner").actorHeight(def,x,z);if h then return h,0 end end
 if def then
  local h=V.require("EmeraldFanClub").actorHeight(def,x,z)
  if h then return h,0 end
 end
 if def then
  local h=V.require('EmeraldGuestSurfaces').actorHeight(def,x,z)
  if h then return h,0 end
 end
 if def then
  local h=V.require('InteriorHouseVariants').actorHeight(def,x,z)
  if h then return h,0 end
 end
 if def and (def.id or def.name)=='FR_PEWTER_CITY_MUSEUM_1F'
  and V.require('IndoorSurfaces').profile(def)==V.require('DioramaConfig').interiors.museumSurfaces.rooms.FR_PEWTER_CITY_MUSEUM_1F then
  local cx,cy=math.floor((x+8)/16),math.floor((z+15.99)/16)
  if cx==22 and cy==3 and def.midLayout:midAt(cx,cy)==0x2b0 then
   local cfg=V.require('DioramaConfig').interiors
   return cfg.museumSurfaces.deskHeight*cfg.heightScale,0
  end
 end
 if def and (def.id or def.name)=='FR_CELADON_CITY_CONDOMINIUMS_ROOF_ROOM'
  and V.require('IndoorSurfaces').profile(def)==V.require('DioramaConfig').interiors.schoolSurfaces then
  local cx,cy=math.floor((x+8)/16),math.floor((z+15.99)/16)
  if cx==7 and cy==3 and def.midLayout:midAt(cx,cy)==0x2ac then
   local cfg=V.require('DioramaConfig').interiors
   return cfg.schoolSurfaces.deskHeight*cfg.heightScale,0
  end
 end
 if def and (def.id or def.name)=='FR_OAKS_LAB' and V.require('IndoorSurfaces').profile(def) then
  -- Native starter-ball and Pokedex events occupy their table cells.
  -- Only their render height changes; player and professor remain on the floor.
  local cx,cy=math.floor((x+8)/16),math.floor((z+15.99)/16)
  if cy==4 and cx>=8 and cx<=10 or cy==1 and cx>=4 and cx<=5 then
   -- The desk is in front of the folded rear wall (z=32). Keep
   -- its paper props inside the tabletop, not coplanar with that wall.
   return V.require('DioramaConfig').interiors.labSurfaces.starterHeight*V.require('DioramaConfig').interiors.heightScale,cy==1 and 6 or 0
  end
 end
 for _,o in ipairs(F.ramps[def and def.midLayout] or {})do
  if o.kind=='silphStairs'then
   local h=V.require('SilphStairs').height(o,x+8,z+16)
   if h then return h,0 end
  elseif o.kind=='gateStairs'then
   local h=V.require('GateStairs').height(o,x+8,z+16)
   if h then return h,0 end
  elseif o.kind=='shipCorridorStairs'then
   local h=V.require('InteriorShipCorridors').stairHeight(o,x+8,z+16)
   if h then return h*V.require('DioramaConfig').interiors.heightScale,0 end
  elseif o.kind=='shipPublicStairs'then
   local h=V.require('InteriorShipPublic').stairHeight(o,x+8,z+16)
   if h then return h*V.require('DioramaConfig').interiors.heightScale,0 end
  elseif o.kind=='deptStairs'then
   local height=V.require('InteriorDepartment').stairHeight(o,x+8,z+16)
   if height then return height*V.require('DioramaConfig').interiors.heightScale,0 end
  elseif o.kind=='condoStairs'then
   local height=V.require('InteriorCondo').stairHeight(o,x+8,z+16)
   if height then return height*V.require('DioramaConfig').interiors.heightScale,0 end
  else
  local dx,dz=x+8-o.x*16,z+16-o.y*16
  if dx>=0 and dx<32 and dz>=13 and dz<=36 then
   local cfg=V.require('DioramaConfig').interiors
   return (math.floor(dx/4)+1)*cfg.homeSurfaces.stairHeight/8*cfg.heightScale,0
  end
  end
 end
 local base=F.paperAnchor(def,x+8,z+15.99)
 if not base then return 0,0 end
 local h=math.max(0,base-z-16)
 local uy,uz=V.require('Camera').cardUp()
 -- Even the last row shares the cutout's plane (h == 0). Keep actors
 -- slightly in front there too, otherwise the starter table hides their
 -- heads when they stand on its native interaction row.
 return h*uy,h*(1+uz)+.3
end
function F.surfaceHeight(def,x,y)
 return F.actorOffset(def,x*16,y*16)
end
return F
