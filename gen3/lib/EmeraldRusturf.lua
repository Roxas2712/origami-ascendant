-- Rusturf's moss atlas has its own wall, floor and native boulder roles.
-- Render-only separation; event boulders and all native collisions stay intact.
local V=...;local F={cache=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').terrain.emRusturf end
function F.profile(d)return d and cfg().enabled and d.id=='EM_RUSTURF_TUNNEL'and d.pair=='general__rusturf_tunnel'and tonumber(d.mapType)==4 end
function F.active(d)return F.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
local walls={[0x208]=true,[0x209]=true,[0x20a]=true,[0x210]=true,[0x211]=true,[0x212]=true,[0x218]=true,[0x219]=true,[0x21a]=true,[0x21b]=true,[0x21c]=true,[0x220]=true,[0x221]=true,[0x222]=true,[0x233]=true,[0x234]=true,[0x240]=true,[0x241]=true,[0x250]=true,[0x252]=true}
function F.kind(d,c)
 if not F.active(d)or not c then return end
 if walls[c.mid]or c.mid==0x205 or c.mid==0x206 then return'emRusturfWall'end
 if c.mid==0x23c then return'emRusturfStep'end
end
function F.height(kind)return kind=='emRusturfStep'and cfg().stepHeight or cfg().height end
local function cross(a,b,c)return(b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])end
function F.polygon(ts,m)
 return V.require('EmeraldCaveContours').polygon(ts,m,0x31423a,cfg().edgePadding)
end
local function contains(poly,x,y)for i,a in ipairs(poly)do if cross(a,poly[i%#poly+1],{x,y})<-.001 then return false end end;return true end
function F.rockBase(d,x,y)
 for _,p in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do local c=d.midLayout:cellAt(x+p[1],y+p[2]);if c and(c.coll==0x2b or c.coll==0x72)then return 0 end end
 return cfg().height
end
function F.support(d,x,y)
 local c=d.midLayout:cellAt(x,y);if not c then return 0 end
 if c.mid==0x205 or c.mid==0x206 then return F.rockBase(d,x,y)end
 local kind=F.kind(d,c);return kind and F.height(kind)or 0
end
function F.stamp(out,d,ts,x,y,ox,oz)
 local L=d.midLayout;local c=L:cellAt(x,y);if not F.kind(d,c)then return false end
 local G=V.require('WorldGeometry');local C=cfg();local h=F.support(d,x,y);local xx,zz=(x+ox)*16,(y+oz)*16;local m=c.mid;local poly=F.polygon(ts,m);local whole=#poly==4 and poly[1][1]==0 and poly[1][2]==0 and poly[2][1]==16 and poly[2][2]==0 and poly[3][1]==16 and poly[3][2]==16 and poly[4][1]==0 and poly[4][2]==16
 local function emit(a,b,c,e,uv,shade)local start=#out+1;G.quad(out,a,b,c,e,uv,shade);for i=start,#out do out[i][9]=-2 end end
 -- The original mixed tile supplies the floor outside its raised contour.
 if not whole then emit({xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,m),1)end
 local portal=(m==0x250 or m==0x252)
 local cap=(portal or m==0x23c or m==0x205 or m==0x206)and 0x211 or m
 if whole then emit({xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,cap),1)
 else
  local slot=ts.midToSlot[m];local tw,th=ts.image:getDimensions();local ax,ay=slot%ts.cols*16,math.floor(slot/ts.cols)*16
  local function vert(p)return{xx+p[1],h,zz+p[2],(ax+math.max(.5,math.min(15.5,p[1])))/tw,(ay+math.max(.5,math.min(15.5,p[2])))/th,1,0,0,-2}end
  for i=2,#poly-1 do for _,p in ipairs{poly[1],poly[i],poly[i+1],poly[1],poly[i+1],poly[i+1]}do out[#out+1]=vert(p)end end
 end
 local function occupied(wx,wz)
  local cx,cy=math.floor(wx/16),math.floor(wz/16);local other=L:cellAt(cx,cy)
  return F.kind(d,other)and F.support(d,cx,cy)>=h and contains(F.polygon(ts,other.mid),wx%16,wz%16)
 end
 for i,a in ipairs(poly)do local b=poly[i%#poly+1];local dx,dz=b[1]-a[1],b[2]-a[2];local length=math.sqrt(dx*dx+dz*dz);local n=math.max(1,math.ceil(length));local t=0
  local function exposed(k)local f=(k+.5)/n;return not occupied(x*16+a[1]+dx*f+dz/length*.05,y*16+a[2]+dz*f-dx/length*.05)end
  while t<n do if exposed(t)then
   local lo=t;repeat t=t+1 until t==n or not exposed(t)
   local p={xx+a[1]+dx*lo/n,zz+a[2]+dz*lo/n};local q={xx+a[1]+dx*t/n,zz+a[2]+dz*t/n}
   local uv=G.uv(ts,0x219,0,0,math.max(1,math.min(16,length*(t-lo)/n)),16,.5)
   if portal and a[2]==0 and b[2]==0 then uv=G.uv(ts,m,p[1]-xx,0,q[1]-xx,16,.5)end
   emit({p[1],h,p[2]},{q[1],h,q[2]},{q[1],0,q[2]},{p[1],0,p[2]},uv,C.sideShade)
  else t=t+1 end end
 end
 return true
end
-- Each object mask is a perimeter flood of the authored background palette.
-- Interior highlight pixels are retained, even when they share floor colors.
function F.rockMask(ts,m)
 local cache=F.cache[ts];if not cache then cache={};F.cache[ts]=cache end
 if cache[m]then return cache[m]end
 local brown=m==0x203 or m==0x204
 local barrier=brown and {[0x526308]=true,[0x3a4a00]=true,[0x6b7b21]=true}or {[0x52635a]=true,[0x31423a]=true,[0x5a845a]=true}
 local clear,seen,queue={},{},{}
 for y=0,15 do for x=0,15 do local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y)
  local key=math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)
  clear[y*16+x]=not barrier[key]
 end end
 local function seed(x,y)local k=y*16+x;if clear[k]and not seen[k]then seen[k]=true;queue[#queue+1]=k end end
 for n=0,15 do seed(n,0);seed(n,15);seed(0,n);seed(15,n)end
 local i=1;while queue[i]do local k=queue[i];i=i+1;local x,y=k%16,math.floor(k/16)
  if x>0 then seed(x-1,y)end;if x<15 then seed(x+1,y)end;if y>0 then seed(x,y-1)end;if y<15 then seed(x,y+1)end
 end
 local mask={};for k=0,255 do mask[k]=not seen[k]end;cache[m]=mask;return mask
end
function F.rock(d,m)return F.active(d)and m>=0x203 and m<=0x206 end
function F.floor(out,d,ts,x,y,ox,oz)
 if not F.active(d)then return false end
 local m=d.midLayout:midAt(x,y);local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 if m==0x207 and d.midLayout:midAt(x,y+1)==0x251 then
  local a,b=cfg().exitThresholdOffset,cfg().exitThresholdOffset+cfg().exitThresholdDepth
  G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+a},{xx,0,zz+a},G.uv(ts,m,0,0,16,a,.5),1)
  G.quad(out,{xx,0,zz+a},{xx+16,0,zz+a},{xx+16,0,zz+b},{xx,0,zz+b},G.uv(ts,0x251,0,0,16,cfg().exitThresholdDepth,.5),1)
  G.quad(out,{xx,0,zz+b},{xx+16,0,zz+b},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,m,0,b,16,16,.5),1)
  return true
 end
 if not F.rock(d,m)then return false end
 local mask=F.rockMask(ts,m);local donor=m<=0x204 and 0x201 or 0x211
 if m>=0x205 and F.rockBase(d,x,y)>0 then return F.stamp(out,d,ts,x,y,ox,oz)end
 -- Keep the native background outside the rock contour pixel for pixel.
 for sy=0,15 do local sx=0;while sx<16 do local first=sx;local source=mask[sy*16+sx]and donor or m
  repeat sx=sx+1 until sx==16 or (mask[sy*16+sx]and donor or m)~=source
  G.quad(out,{xx+first,0,zz+sy},{xx+sx,0,zz+sy},{xx+sx,0,zz+sy+1},{xx+first,0,zz+sy+1},G.uv(ts,source,first,sy,sx,sy+1,.02),1)
 end end
 return true
end
function F.objects(out,d,ts,ox,oz,contacts)
 if not F.active(d)then return end
 local L=d.midLayout;local G=V.require('WorldGeometry');local C=cfg()
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if F.rock(d,m)then local mask=F.rockMask(ts,m)
   local vertices=V.require('PaperSprite').build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return mask[t*16+s]end,0,16,C.rockScale,function()return 1 end,nil,.02)
   local base=m>=0x205 and F.rockBase(d,x,y)or 0
   for _,v in ipairs(vertices)do v[2]=v[2]+base;if base>0 then v[9]=-2 end;out[#out+1]=G.place(v,(x+ox)*16,(y+oz)*16+16)end
   if base==0 then contacts[#contacts+1]={(x+ox)*16+8,(y+oz)*16+16,C.rockContactWidth,C.contactDepth,C.contactStrength}end
  end
 end end
end
function F.light(d,result)
 if not F.active(d)then return end
 local c=cfg().lighting;result.ambient={unpack(c.ambient)};result.shafts={};result.sprites={}
 local kept={};for _,l in ipairs(result.lights)do if l.kind=='flash'then kept[#kept+1]=l end end;result.lights=kept
 for _,p in ipairs(c.positions)do result.lights[#result.lights+1]={x=p[1]*16+8,z=p[2]*16+8,y=c.height,radius=-c.radius,power=c.power,color=c.color,falloff=2,kind='rusturfCeiling',point=true}end
end
return F
