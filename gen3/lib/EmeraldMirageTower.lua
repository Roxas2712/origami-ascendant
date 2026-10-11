-- Exact native Mirage Tower family. Cracked floors, warps and fossils stay native.
local V=...;local M={}
local function cfg()return V.require('DioramaConfig').terrain.emMirageTower end
function M.profile(d)return d and cfg().enabled and d.pair=='general__mirage_tower'and tonumber(d.mapType)==4 and d.id:match('^EM_MIRAGE_TOWER_[1-4]F$')and true or nil end
function M.active(d)return M.profile(d)and V.require('DioramaConfig').terrain.enabled and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'end
local function rock(m)return m==0x202 or m==0x203 end
function M.kind(d,c)
 if not M.active(d)or not c or c.coll~=7 then return end
 if rock(c.mid)or c.mid==0x245 or c.mid==0x258 or c.mid==0x259 then return end
 return'emMirageWall'
end
function M.height()return cfg().wallHeight end
local function level(d,c)return d.id=='EM_MIRAGE_TOWER_4F'and c and c.elev==4 and cfg().platformHeight or 0 end
function M.actorHeight(d,x,z)
 if not M.active(d)then return end
 local c=d.midLayout:cellAt(math.floor((x+8)/16),math.floor((z+15.99)/16))
 if c and c.mid==0x204 then return cfg().platformHeight*(1-math.floor(((z+15.99)%16)/16*cfg().steps)/cfg().steps)end
 return level(d,c)
end
function M.stamp(out,d,ts,x,y,ox,oz)
 local L=d.midLayout;local c=L:cellAt(x,y);if not M.kind(d,c)then return false end
 local G=V.require('WorldGeometry');local h=cfg().wallHeight;local xx,zz=(x+ox)*16,(y+oz)*16;local mid=c.mid==0x20f and 0x20b or c.mid==0x20e and 0x20b or c.mid
 local first=#out+1
 G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,mid),1)
 local function side(dx,dy,a,b)
  local n=L:cellAt(x+dx,y+dy);if M.kind(d,n)then return end
  local low=level(d,n);G.quad(out,{a[1],h,a[2]},{b[1],h,b[2]},{b[1],low,b[2]},{a[1],low,a[2]},G.uv(ts,0x219),cfg().sideShade)
 end
 side(0,-1,{xx+16,zz},{xx,zz});side(0,1,{xx,zz+16},{xx+16,zz+16});side(-1,0,{xx,zz},{xx,zz+16});side(1,0,{xx+16,zz+16},{xx+16,zz})
 for i=first,#out do out[i][9]=-2 end;return true
end
function M.floor(out,d,ts,x,y,ox,oz)
 if not M.active(d)then return false end
 local G=V.require('WorldGeometry');local L=d.midLayout;local c=L:cellAt(x,y);local m=c.mid;local xx,zz=(x+ox)*16,(y+oz)*16;local h=level(d,c)
 if M.kind(d,c)then return false end
 if m==0x245 then return true end
 if m==0x204 then
  for i=0,cfg().steps-1 do local a,b=i*16/cfg().steps,(i+1)*16/cfg().steps;local hi=cfg().platformHeight*(1-i/cfg().steps);local lo=cfg().platformHeight*(1-(i+1)/cfg().steps)
   G.quad(out,{xx,hi,zz+a},{xx+16,hi,zz+a},{xx+16,hi,zz+b},{xx,hi,zz+b},G.uv(ts,m,0,a,16,b,.5),1)
   G.quad(out,{xx,hi,zz+b},{xx+16,hi,zz+b},{xx+16,lo,zz+b},{xx,lo,zz+b},G.uv(ts,0x219,0,12,16,16,.5),cfg().sideShade)
  end;return true
 end
 if rock(m)or m==0x216 or m==0x217 then m=0x211 end
 G.quad(out,{xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},G.uv(ts,m),1)
 if h>0 then for _,p in ipairs{{0,-1,16,0,0,0},{0,1,0,16,16,16},{-1,0,0,0,0,16},{1,0,16,16,16,0}}do
  local n=L:cellAt(x+p[1],y+p[2]);if level(d,n)<h and not M.kind(d,n)and not(n and n.mid==0x204)then
   G.quad(out,{xx+p[3],h,zz+p[4]},{xx+p[5],h,zz+p[6]},{xx+p[5],0,zz+p[6]},{xx+p[3],0,zz+p[4]},G.uv(ts,0x219),cfg().sideShade)
  end
 end end;return true
end
function M.objects(out,d,ts,ox,oz,contacts)
 if not M.active(d)then return end
 local L=d.midLayout;local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local A=V.require('CaveObjectArt')
 local function place(vv,x,y)for _,v in ipairs(vv)do out[#out+1]=G.place(v,(x+ox)*16,(y+oz)*16)end end
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if rock(m)then local vv=P.build(ts,16,16,function(s,t)return m,s,t end,function(s,t)return A.rockPixel(m,s,t)end,0,16,cfg().rockScale,nil,nil,.5);place(vv,x,y+1);contacts[#contacts+1]={(x+ox)*16+8,(y+oz+1)*16,5,2,cfg().contactStrength}end
 end end
 for _,w in ipairs(d.warps or{})do local lower,upper=L:midAt(w.x,w.y),L:midAt(w.x,w.y-1)
  if(lower==0x216 or lower==0x217)and(upper==0x20e or upper==0x20f)then
   local function src(s,t)return t<16 and upper or lower,s,t%16 end
   local vv=P.build(ts,16,32,src,function(s,t)return A.ladderPixel(ts,s,t,src,{0xffffbd,0xded67b,0x524a42,0x7b734a},{3,12,2,29})end,0,32,cfg().ladderScale,nil,nil,.5);place(vv,w.x,w.y+1)
  end
 end
end
function M.light(d,result)
 if not M.active(d)then return end
 local c=cfg().lighting;result.ambient={unpack(c.ambient)};result.shafts={};result.sprites={};local kept={}
 for _,l in ipairs(result.lights)do if l.kind=='flash'or l.kind=='player'then kept[#kept+1]=l end end;result.lights=kept
 for _,p in ipairs(c.positions[d.id])do result.lights[#result.lights+1]={x=p[1]*16+8,z=p[2]*16+8,y=c.height,radius=-c.radius,power=c.power,color=c.color,point=true,falloff=2,kind='mirageCeiling'}end
end
return M
