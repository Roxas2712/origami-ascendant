-- Measured Seafloor current rooms; never apply Pacifidlog town roles here.
local V=...;local F={cache=setmetatable({},{__mode='k'})}
local full={{0,0},{16,0},{16,16},{0,16}}
local mixed={[0x275]=true,[0x277]=true,[0x27d]=true,[0x27f]=true,[0x285]=true,[0x286]=true,[0x287]=true,[0x2c3]=true,[0x2c5]=true}
local names={EM_SEAFLOOR_CAVERN_ROOM6=true,EM_SEAFLOOR_CAVERN_ROOM7=true}
local function cfg()return V.require('DioramaConfig').terrain.emSeafloorCurrents end
function F.profile(d)return d and cfg().enabled and names[d.id]and d.pair=='general__pacifidlog'and tonumber(d.mapType)==4 end
function F.active(d)return F.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
function F.kind(d,c)
 if not F.active(d)or not c or(c.coll~=7 and c.coll~=255)then return end
 if c.mid==0x273 or c.mid==0x274 or c.mid==0x299 then return end
 return'emSeafloorWall'
end
function F.height()return cfg().height end
local function cross(a,b,c)return(b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])end
function F.polygon(ts,m)
 if not mixed[m]then return full end
 local pad=cfg().edgePadding;local cache=F.cache[ts]
 if not cache or cache.pad~=pad then cache={pad=pad};F.cache[ts]=cache end
 if cache[m]then return cache[m]end
 local pts,seen={},{}
 local function add(x,y)x=math.max(0,math.min(16,x));y=math.max(0,math.min(16,y));local k=x..':'..y;if not seen[k]then seen[k]=true;pts[#pts+1]={x,y}end end
 for y=0,15 do for x=0,15 do local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y)
  -- Only this measured shore family contains blue water inside solid tiles.
  if not(b>r+.08 and b>g+.03)then add(x-pad,y-pad);add(x+1+pad,y-pad);add(x+1+pad,y+1+pad);add(x-pad,y+1+pad)end
 end end
 table.sort(pts,function(a,b)return a[1]==b[1]and a[2]<b[2]or a[1]<b[1]end)
 local lo,hi={},{};for _,p in ipairs(pts)do while #lo>=2 and cross(lo[#lo-1],lo[#lo],p)<=0 do lo[#lo]=nil end;lo[#lo+1]=p end
 for i=#pts,1,-1 do local p=pts[i];while #hi>=2 and cross(hi[#hi-1],hi[#hi],p)<=0 do hi[#hi]=nil end;hi[#hi+1]=p end
 local poly={};for i=1,#lo-1 do poly[#poly+1]=lo[i]end;for i=1,#hi-1 do poly[#poly+1]=hi[i]end
 assert(#poly>=3,'missing Seafloor rock contour');cache[m]=poly;return poly
end
local function contains(poly,x,y)for i,a in ipairs(poly)do if cross(a,poly[i%#poly+1],{x,y})<-.001 then return false end end;return true end
function F.stamp(out,d,ts,x,y,ox,oz)
 local L=d.midLayout;local c=L:cellAt(x,y);if not F.kind(d,c)then return false end
 local G=V.require('WorldGeometry');local C=cfg();local h=C.height;local xx,zz=(x+ox)*16,(y+oz)*16;local m=c.mid;local poly=F.polygon(ts,m)
 local function emit(a,b,c,e,uv,shade)local start=#out+1;G.quad(out,a,b,c,e,uv,shade);for i=start,#out do out[i][9]=-2 end end
 -- The original mixed tile supplies the floor outside its raised contour.
 if poly~=full then emit({xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,m),G.WATER)end
 local portal=m==0x289
 local cap=portal and 0x281 or m
 if poly==full then emit({xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,cap),1)
 else
  local slot=ts.midToSlot[m];local tw,th=ts.image:getDimensions();local ax,ay=slot%ts.cols*16,math.floor(slot/ts.cols)*16
  local function vert(p)return{xx+p[1],h,zz+p[2],(ax+math.max(.5,math.min(15.5,p[1])))/tw,(ay+math.max(.5,math.min(15.5,p[2])))/th,1,0,0,-2}end
  for i=2,#poly-1 do for _,p in ipairs{poly[1],poly[i],poly[i+1],poly[1],poly[i+1],poly[i+1]}do out[#out+1]=vert(p)end end
 end
 local function occupied(wx,wz)
  local cx,cy=math.floor(wx/16),math.floor(wz/16);if cx<0 or cy<0 or cx>=L.width or cy>=L.height then return false end;local other=L:cellAt(cx,cy)
  return F.kind(d,other)and contains(F.polygon(ts,other.mid),wx%16,wz%16)
 end
 for i,a in ipairs(poly)do local b=poly[i%#poly+1];local dx,dz=b[1]-a[1],b[2]-a[2];local length=math.sqrt(dx*dx+dz*dz);local n=math.max(1,math.ceil(length));local t=0
  local function exposed(k)local f=(k+.5)/n;return not occupied(x*16+a[1]+dx*f+dz/length*.05,y*16+a[2]+dz*f-dx/length*.05)end
  while t<n do if exposed(t)then
   local lo=t;repeat t=t+1 until t==n or not exposed(t)
   local p={xx+a[1]+dx*lo/n,zz+a[2]+dz*lo/n};local q={xx+a[1]+dx*t/n,zz+a[2]+dz*t/n}
   local uv=G.uv(ts,0x281,0,0,math.max(1,math.min(16,length*(t-lo)/n)),16,.5)
   if portal and a[2]==16 and b[2]==16 then uv=G.uv(ts,m,q[1]-xx,0,p[1]-xx,16,.5);uv[1],uv[3]=uv[3],uv[1]end
   emit({p[1],h,p[2]},{q[1],h,q[2]},{q[1],0,q[2]},{p[1],0,p[2]},uv,C.sideShade)
  else t=t+1 end end
 end
 return true
end
function F.floor(out,d,ts,x,y,ox,oz)
 if not F.active(d)then return false end
 local G=V.require('WorldGeometry');local m=d.midLayout:midAt(x,y);local xx,zz=(x+ox)*16,(y+oz)*16
 if m==0x273 or m==0x274 then
  G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,0x279),1);return true
 end
 if (m==0x295 or m==0x296)and d.midLayout:midAt(x,y+1)==0x299 then
  local a,b=cfg().exitThresholdOffset,cfg().exitThresholdOffset+cfg().exitThresholdDepth
  G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+a},{xx,0,zz+a},G.uv(ts,m,0,0,16,a,.5),1)
  G.quad(out,{xx,0,zz+a},{xx+16,0,zz+a},{xx+16,0,zz+b},{xx,0,zz+b},G.uv(ts,0x299,0,0,16,cfg().exitThresholdDepth,.5),1)
  G.quad(out,{xx,0,zz+b},{xx+16,0,zz+b},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,m,0,b,16,16,.5),1);return true
 end
 return false
end
function F.objects(out,d,ts,ox,oz,contacts)
 if not F.active(d)then return end
 local G=V.require('WorldGeometry');local C=cfg();local L=d.midLayout
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if m==0x273 or m==0x274 then
   local vertices=V.require('PaperSprite').build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return V.require('CaveObjectArt').rockPixel(m==0x273 and 0x203 or 0x202,s,t)end,0,16,C.rockScale,function()return 1 end,nil,.5)
   for _,v in ipairs(vertices)do out[#out+1]=G.place(v,(x+ox)*16,(y+oz+1)*16)end
   contacts[#contacts+1]={(x+ox)*16+8,(y+oz+1)*16,C.rockContactWidth,C.contactDepth,C.contactStrength}
  end
 end end
end
function F.light(d,result)
 if not F.active(d)then return end
 local c=cfg().lighting;result.ambient={unpack(c.ambient)};result.shafts={};result.sprites={}
 local kept={};for _,l in ipairs(result.lights)do if l.kind=='flash'or l.kind=='player'then kept[#kept+1]=l end end;result.lights=kept
 for _,p in ipairs(c.positions[d.id])do result.lights[#result.lights+1]={x=p[1]*16+8,z=p[2]*16+8,y=c.height,radius=-c.radius,power=c.power,color=c.color,falloff=2,kind='seafloorCeiling',point=true}end
end
return F
