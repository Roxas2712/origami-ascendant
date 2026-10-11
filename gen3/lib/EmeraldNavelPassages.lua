-- Measured Navel Rock passages. Summit and deepest chamber have distinct art
-- and remain outside this profile until their own terraces are implemented.
local V=...;local N={}
local function cfg()return V.require('DioramaConfig').terrain.emNavelPassages end
local rooms={EM_NAVEL_ROCK_ENTRANCE={22,32},EM_NAVEL_ROCK_B1F={24,12},EM_NAVEL_ROCK_FORK={28,86}}
for i=1,4 do rooms['EM_NAVEL_ROCK_UP'..i]={10,8}end
for i=1,11 do rooms[string.format('EM_NAVEL_ROCK_DOWN%02d',i)]={10,8}end
function N.profile(d)
 local dim=d and rooms[d.id];local L=d and d.midLayout
 return cfg().enabled and dim and d.pair=='general__navel_rock'and tonumber(d.mapType)==4 and L and L.width==dim[1]and L.height==dim[2]and true or nil
end
function N.active(d)return N.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
local clusterRows={{7,9},{6,10},{5,11},{4,12},{3,12},{2,12},{1,12},{1,13},{1,14},{2,14},{2,14},{1,14},{1,14},{1,14},{1,13},{2,5,8,12}}
local function clusterPixel(x,y)local row=clusterRows[y+1];for i=1,#row,2 do if x>=row[i]and x<=row[i+1]then return true end end;return false end
local function rock(m)return m==0x203 or m==0x2d5 or m==0x356 end
function N.kind(d,c)
 if not N.active(d)or not c then return end
 if c.mid==0x211 and c.elev==0 then return'emNavelWall'end
 if c.coll~=7 or rock(c.mid)or c.mid==0x35e or c.mid>=0x258 and c.mid<=0x25a then return end
 return'emNavelWall'
end
function N.height()return cfg().wallHeight end
function N.floorHeight(d,z)
 if d.id~='EM_NAVEL_ROCK_FORK'then return 0 end
 local c=cfg();return c.platformHeight*(1-math.max(0,math.min(c.steps,math.floor((z-c.forkStairRow*16)/(16/c.steps))))/c.steps)
end
function N.actorHeight(d,x,z)if N.active(d)then return N.floorHeight(d,z+15.99)end end
local function donor(m)return m>=0x2d0 and 0x2e1 or 0x219 end
local function mid(d,x,y)local m=d.midLayout:midAt(x,y);return m==0x20f and 0x219 or m end
function N.stamp(out,d,ts,x,y,ox,oz)
 local L=d.midLayout;if not N.kind(d,L:cellAt(x,y))then return false end
 local G=V.require('WorldGeometry');local C=V.require('EmeraldCaveContours');local m=mid(d,x,y);local h=N.height();local xx,zz=(x+ox)*16,(y+oz)*16
 local function poly(m)return C.polygon(ts,m,0x847b3a,cfg().edgePadding)end
 local p=poly(m)
 -- Preserve the floor beneath clipped native side contours.
 local ground=N.floorHeight(d,y*16);G.quad(out,{xx,ground,zz},{xx+16,ground,zz},{xx+16,ground,zz+16},{xx,ground,zz+16},G.uv(ts,0x201),1)
 local first=#out+1;local slot=ts.midToSlot[m];local tw,th=ts.image:getDimensions();local ax,ay=slot%ts.cols*16,math.floor(slot/ts.cols)*16
 local function vertex(q)return{xx+q[1],h,zz+q[2],(ax+math.max(.5,math.min(15.5,q[1])))/tw,(ay+math.max(.5,math.min(15.5,q[2])))/th,1,0,0,-2}end
 for i=2,#p-1 do for _,q in ipairs{p[1],p[i],p[i+1],p[1],p[i+1],p[i+1]}do out[#out+1]=vertex(q)end end
 local function occupied(wx,wz)
  local a,b=math.floor(wx/16),math.floor(wz/16)
  return a>=0 and b>=0 and a<L.width and b<L.height and N.kind(d,L:cellAt(a,b))and C.contains(poly(mid(d,a,b)),wx%16,wz%16)
 end
 for i,a in ipairs(p)do local b=p[i%#p+1];local dx,dz=b[1]-a[1],b[2]-a[2];local length=math.sqrt(dx*dx+dz*dz);local count=math.ceil(length)
  for j=0,count-1 do local t=(j+.5)/count
   if not occupied(x*16+a[1]+dx*t+dz/length*.05,y*16+a[2]+dz*t-dx/length*.05)then
    local u,v=j/count,(j+1)/count;local ax,az=xx+a[1]+dx*u,zz+a[2]+dz*u;local bx,bz=xx+a[1]+dx*v,zz+a[2]+dz*v
    local low=N.floorHeight(d,(az+bz)*.5-oz*16);G.quad(out,{ax,h,az},{bx,h,bz},{bx,low,bz},{ax,low,az},G.uv(ts,donor(m),j%16,0,j%16+1,16,.5),cfg().sideShade)
   end
  end
 end
 for i=first,#out do out[i][9]=-2 end;return true
end
function N.floor(out,d,ts,x,y,ox,oz)
 if not N.active(d)then return false end
 local L=d.midLayout;local m=L:midAt(x,y);if N.kind(d,L:cellAt(x,y))then return false end
 if not rock(m)and m~=0x217 and m~=0x35e and m~=0x366 and d.id~='EM_NAVEL_ROCK_FORK'then return false end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16;local floor=rock(m)or m==0x217 or m==0x35e or m==0x366
 for sy=0,15 do local a=N.floorHeight(d,y*16+sy);local b=N.floorHeight(d,y*16+sy+1)
  G.quad(out,{xx,a,zz+sy},{xx+16,a,zz+sy},{xx+16,a,zz+sy+1},{xx,a,zz+sy+1},G.uv(ts,floor and 0x201 or m,0,sy,16,sy+1,.5),1)
  if a~=b then G.quad(out,{xx,a,zz+sy+1},{xx+16,a,zz+sy+1},{xx+16,b,zz+sy+1},{xx,b,zz+sy+1},G.uv(ts,0x219,0,0,16,4,.5),cfg().sideShade)end
 end;return true
end
function N.objects(out,d,ts,ox,oz,contacts)
 if not N.active(d)then return end
 local L=d.midLayout;local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local A=V.require('CaveObjectArt')
 local function place(vv,x,y)for _,v in ipairs(vv)do v[2]=v[2]+N.floorHeight(d,y*16-.01);out[#out+1]=G.place(v,(x+ox)*16,(y+oz)*16)end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if rock(m)then place(P.build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return m==0x356 and clusterPixel(s,t)or m~=0x356 and A.rockPixel(m,s,t)end,0,16,cfg().rockScale,nil,nil,.5),x,y+1);contacts[#contacts+1]={(x+ox)*16+8,(y+oz+1)*16,5,2,cfg().contactStrength}end
 end end
 for _,w in ipairs(d.warps or{})do local lower,upper=L:midAt(w.x,w.y),L:midAt(w.x,w.y-1)
 if lower==0x217 and upper==0x20f or lower==0x366 and upper==0x35e then
  local function src(s,t)return t<16 and upper or lower,s,t%16 end
  local vv=P.build(ts,16,32,src,function(s,t)return A.ladderPixel(ts,s,t,src,{0xffffff,0xffffc5,0x847b3a,0xadad73},{3,12,2,29})end,0,32,1,nil,function(s,t)return{s,(N.height()-N.floorHeight(d,(w.y+1)*16-.01))*(30-t)/28,(t-30)/28*16+cfg().ladderOffset}end,.5)
  place(vv,w.x,w.y+1)
 end end
end
function N.light(d,result)
 if not N.active(d)then return end
 local c=cfg().lighting;local L=d.midLayout;result.ambient={unpack(c.ambient)};result.shafts={};result.sprites={};result.crystals=0;result.fireflies=0;local kept={}
 for _,l in ipairs(result.lights)do if l.kind=='flash'or l.kind=='player'then kept[#kept+1]=l end end;result.lights=kept
 for y0=0,L.height-1,c.spacing do local best,score
  for y=y0,math.min(L.height-1,y0+c.spacing-1)do for x=0,L.width-1 do local cell=L:cellAt(x,y)
   if cell.mid==0x201 and cell.elev==3 then local s=(x-L.width*.5)^2+(y-y0-math.min(c.spacing,L.height-y0)*.5)^2
    if not score or s<score then best={x,y};score=s end
   end
  end end
  if best then result.lights[#result.lights+1]={x=best[1]*16+8,z=best[2]*16+8,y=c.height,radius=-c.radius,power=c.power,color=c.color,point=true,falloff=2,kind='navelCeiling'}end
 end
end
return N
