-- Native Mauville bike display: two independent 24px bikes per 3-tile strip.
local V=...
local F={}
local grass={[0x73c5a5]=true,[0xa5d6c5]=true,[0x42b584]=true}
local function color(ts,m,x,y)
 local r,g,b=V.require('BuildingMesh').pixel(ts,m,x,y)
 return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)
end
function F.at(d,x,y)
 if(d.id or d.name)~='EM_MAUVILLE_CITY'or d.pair~='general__mauville'then return end
 local L=d.midLayout;local m=L:midAt(x,y);if m<0x298 or m>0x29a then return end
 local left=x-(m-0x298)
 if left>=0 and left+2<L.width and L:midAt(left,y)==0x298 and L:midAt(left+1,y)==0x299 and L:midAt(left+2,y)==0x29a then return m,left end
end
function F.object(ts,m,x,y)return not grass[color(ts,m,x,y)]end
function F.silhouette(ts,m,x,y)
 -- Native grey row15/rightward row14 pixels are the baked ground shadow;
 -- row14 dark pixels are the actual bottom edge of both tyres.
 return y<15 and(y~=14 or color(ts,m,x,y)==0x424a6b)and F.object(ts,m,x,y)
end
function F.template(ts,part)
 return V.require('PaperSprite').build(ts,24,15,function(x,y)
  local sx=x+part*24;return 0x298+math.floor(sx/16),sx%16,y
 end,function(x,y,m,s,t)return F.silhouette(ts,m,s,t)end,0,15,1,function()return 5 end,nil,.5)
end
function F.build(out,d,ts,x,y,ox,oz,contacts)
 local m=F.at(d,x,y);if not m then return false end
 if not V.require('DioramaConfig').billboards.enabled or V.require('Camera').projection()~='perspective'then return false end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 for py=0,15 do local px=0;while px<16 do
  local first=px;local source=F.object(ts,m,px,py)and 1 or m
  repeat px=px+1 until px==16 or(F.object(ts,m,px,py)and 1 or m)~=source
  G.quad(out,{xx+first,0,zz+py},{xx+px,0,zz+py},{xx+px,0,zz+py+1},{xx+first,0,zz+py+1},G.uv(ts,source,first,py+.5,px,py+.5,0),1)
 end end
 if m==0x298 then for part=0,1 do
  local bx=xx+part*24
  for _,v in ipairs(F.template(ts,part))do v[3]=v[3]+15;v[8]=v[8]+15;out[#out+1]=G.place(v,bx,zz)end
  local c=V.require('DioramaConfig').contact;contacts[#contacts+1]={bx+12,zz+15,10,c.propRadius,c.strength}
 end end
 return true
end
return F
