-- Native submerged objects. Keep dive tiles, floor shadows and event data intact.
local V=...;local U={art=setmetatable({},{__mode='k'}),floorArt=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').underwater end
function U.profile(d)
 return d and cfg().enabled and d.pair=='general__underwater'and tonumber(d.mapType)==5
  and d.id and d.id:match('^EM_UNDERWATER_')and cfg()or nil
end
function U.active(d)return U.profile(d)and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
function U.plan(d)
 local p={mask={},objects={}};if not U.active(d)then return p end
 local L=d.midLayout
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x201 or m==0x281 then
   local o={x=x,y=y,w=1,h=1,kind='coral'};p.objects[#p.objects+1]=o;p.mask[y*L.width+x+1]=o
  elseif d.id=='EM_UNDERWATER_SEAFLOOR_CAVERN'and m==0x2e4 and L:midAt(x+3,y)==0x2e7 and L:midAt(x,y+1)==0x2e0 then
   local o={x=x,y=y,w=4,h=2,kind='submarine'};p.objects[#p.objects+1]=o
   for dy=0,1 do for dx=0,3 do p.mask[(y+dy)*L.width+x+dx+1]=o end end
  end
 end end
 return p
end
local function coral(ts,m,s,t)
 local r,g,b,a=V.require('BuildingMesh').pixel(ts,m,s,t)
 -- The blue-grey leaf inks have green > red; 29315a is their flat
 -- seabed background, not opaque foliage. Both purple sand
 -- variants have red > green; never key out an enclosed object highlight.
 return a>.5 and g>r and not(math.abs(r-41/255)<.002 and math.abs(g-49/255)<.002 and math.abs(b-90/255)<.002)
end
local function coralGround(ts,m)
 local bank=U.art[ts];if not bank then bank={};U.art[ts]=bank end
 if bank[m]then return bank[m]end
 local map={}
 for t=0,15 do for s=0,15 do local best,bx,by=math.huge,s,t
  if coral(ts,m,s,t)then
   for y=0,15 do for x=0,15 do if not coral(ts,m,x,y)then
    local dist=(x-s)^2+(y-t)^2
    if dist<best then best,bx,by=dist,x,y end
   end end end
  end
  map[t*16+s+1]={bx,by}
 end end
 bank[m]=map;return map
end
local function floorMesh(ts,m)
 local bank=U.floorArt[ts];if not bank then bank={};U.floorArt[ts]=bank end
 if bank[m]then return bank[m]end
 local donor=coralGround(ts,m)
 local original=V.require('PaperSprite').build(ts,16,16,function(s,t)local q=donor[t*16+s+1];return m,q[1],q[2]end,function()return true end,0,0,1,nil,function(s,t)return{s,0,t}end,.5)
 -- Keep the original triangles and UVs: native seaweed animation can change
 -- equal-looking texels, and merging faces changes rasterized seam pixels.
 bank[m]=original;return original
end
function U.floor(out,d,ts,x,y,ox,oz,p)
 local o=p.mask[y*d.midLayout.width+x+1];if not o then return false end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16;local m=d.midLayout:midAt(x,y)
 if o.kind=='coral'then
  for _,q in ipairs(floorMesh(ts,m))do out[#out+1]={xx+q[1],q[2],zz+q[3],q[4],q[5],q[6],q[7],q[8],q[9]}end
 else G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,0x228),1)end
 return true
end
local function submarineMask(ts,L,o)
 local pixel=V.require('BuildingMesh').pixel;local W,H=64,32;local background={}
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 for y=0,15 do for x=0,15 do background[rgb(pixel(ts,0x228,x,y))]=true end end
 local function source(x,y)return L:midAt(o.x+math.floor(x/16),o.y+math.floor(y/16)),x%16,y%16 end
 local outside,queue={},{}
 local function visit(x,y)
  if x<0 or y<0 or x>=W or y>=H then return end
  local k=y*W+x;if outside[k]then return end
  local m,s,t=source(x,y)
  if background[rgb(pixel(ts,m,s,t))]then outside[k]=true;queue[#queue+1]={x,y}end
 end
 for x=0,W-1 do visit(x,0);visit(x,H-1)end;for y=0,H-1 do visit(0,y);visit(W-1,y)end
 local i=1;while queue[i]do local q=queue[i];i=i+1;visit(q[1]-1,q[2]);visit(q[1]+1,q[2]);visit(q[1],q[2]-1);visit(q[1],q[2]+1)end
 return function(x,y)return not outside[y*W+x]end,source
end
function U.objects(out,d,ts,ox,oz,p,contacts)
 if not U.active(d)then return end
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local c=cfg();local L=d.midLayout
 for _,o in ipairs(p.objects)do local xx,zz=(o.x+ox)*16,(o.y+oz)*16
  if o.kind=='coral'then
   local m=L:midAt(o.x,o.y)
   local vv=P.build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return coral(ts,m,s,t)end,0,16,c.coralHeight/16,nil,nil,.5)
   for _,q in ipairs(vv)do out[#out+1]=G.place(q,xx,zz+16)end
   contacts[#contacts+1]={xx+8,zz+16,c.contactWidth,c.contactDepth,c.contactStrength}
  else
   local inside,source=submarineMask(ts,L,o)
   -- Native turret and curved hull stay one opaque cutout. Its painted
   -- lower shadow row remains on the sea floor instead of becoming a box.
   local vv=P.build(ts,64,32,source,inside,0,32,c.submarineHeight/32,nil,nil,.5)
   for _,q in ipairs(vv)do out[#out+1]=G.place(q,xx,zz+32)end
   contacts[#contacts+1]={xx+32,zz+32,c.submarineContactWidth,c.contactDepth,c.contactStrength}
  end
 end
end
return U
