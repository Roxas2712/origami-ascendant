-- Mossdeep has two native round crown sizes, not the primary conifers.
-- Preserve coast/water/rock texels outside each object's exact palette roles.
local V=...
local F={}
local donors={
 [0x2f0]=0x19e,[0x2f1]=0x19e,[0x2f8]=0x19e,[0x2f9]=0x19e,
 [0x2f2]=0x170,[0x2f3]=0x170,[0x2f4]=0x170,[0x301]=2,[0x305]=2,
 [0x2fa]=0xd3,[0x2fb]=2,[0x302]=1,[0x303]=1,[0x304]=1,
 [0x30a]=1,[0x30b]=1,[0x30c]=1,[0x312]=1,[0x313]=1,[0x314]=1,
 [0x308]=0x124,[0x309]=0x124,[0x310]=0x124,[0x311]=0x124,
 [0x31a]=1,[0x31b]=1,[0x31c]=0x7c,[0x31d]=0x7c,[0x31e]=2,[0x31f]=2,
 [0x322]=1,[0x323]=1,[0x324]=1,[0x325]=1,[0x355]=1,[0x356]=1,
}
local small={[0x2f0]=true,[0x308]=true,[0x31a]=true,[0x31c]=true,[0x31e]=true,[0x325]=true,[0x356]=true}
local large={[0x2f2]=true,[0x2fa]=true,[0x302]=true}
local leaves={[0x3a8c31]=true,[0x84c563]=true,[0x3a5200]=true,[0xb5ff84]=true}
local trunk={[0x423a31]=true,[0x6b5a5a]=true,[0x738c8c]=true,[0x948c8c]=true}
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
function F.applies(d)return d and(d.id or d.name)=='EM_MOSSDEEP_CITY'and d.pair=='general__mossdeep'end
function F.ink(ts,m,x,y,leafOnly)
 local r,g,b,a=V.require('BuildingMesh').pixel(ts,m,x,y);if a<=.5 then return false end
 local c=rgb(r,g,b)
 if leafOnly then return leaves[c]or false end
 return leaves[c]or trunk[c]or(c==0xa5635a and m>=0x312 and m<=0x314)or false
end
function F.plan(d)
 local p={mask={},trees={}};if not F.applies(d)then return p end
 local L=d.midLayout
 for y=0,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  if donors[m]then p.mask[y*L.width+x+1]=donors[m]
   if small[m]or large[m]then
    local n=large[m]and 3 or 2;local rows=math.min(n,L.height-y);local complete=true
    for dy=0,rows-1 do for dx=0,n-1 do if not donors[L:midAt(x+dx,y+dy)]then complete=false end end end
    if complete then p.trees[#p.trees+1]={tileX=x,tileY=y,width=n,height=rows,x=x*16+n*8,z=(y+rows)*16-2,kind=rows<n and'mossdeepEdge'or n==3 and'mossdeepLarge'or'mossdeepSmall'}end
   end
  end
 end end
 return p
end
function F.floor(out,d,ts,x,y,ox,oz,donor)
 local G=V.require('WorldGeometry');local m=d.midLayout:midAt(x,y);local xx,zz=(x+ox)*16,(y+oz)*16
 -- Runs keep every visible native background pixel. Only removed foliage,
 -- stump and baked shadow receive the source-matched native terrain donor.
 for py=0,15 do local px=0;while px<16 do
  local start=px;local source=F.ink(ts,m,px,py)and donor or m
  repeat px=px+1 until px==16 or(F.ink(ts,m,px,py)and donor or m)~=source
  G.quad(out,{xx+start,0,zz+py},{xx+px,0,zz+py},{xx+px,0,zz+py+1},{xx+start,0,zz+py+1},G.uv(ts,source,start,py+.5,px,py+.5,0),1)
 end end
end
function F.template(ts,kind)
 local big=kind=='mossdeepLarge';local W=big and 48 or 32;local base=kind=='mossdeepEdge'and 16 or big and 39 or 22
 local mids=big and{{0x302,0x303,0x304},{0x30a,0x30b,0x30c},{0x312,0x313,0x314}}or{{0x31a,0x31b},{0x322,0x323}}
 local cfg=V.require('DioramaConfig').trees;local style=cfg.pairStyle[ts.pair]or cfg.defaultStyle or cfg
 local function pick(k)return style[k]~=nil and style[k]or cfg[k]end
 local out=V.require('PaperSprite').build(ts,W,base,function(x,y)return mids[math.floor(y/16)+1][math.floor(x/16)+1],x%16,y%16 end,
  function(x,y,m,s,t)return F.ink(ts,m,s,t,true)end,-W/2,base,1,function(x,y)
   local lower=math.max(0,math.min(1,(y-base*cfg.lowerShadeStart)/(base*(1-cfg.lowerShadeStart))))
   return pick('crownShade')*(1-lower)+pick('trunkShade')*lower
  end,nil,.5)
 local perspective=V.require('Camera').projection()=='perspective';local a=perspective and math.rad(cfg.tiltDegrees)or 0
 local compensation=pick('preserveScreenHeight')and perspective and 1/math.max(.25,math.cos(a)-math.tan(V.require('Camera').elevation())*math.sin(a))or 1
 for _,v in ipairs(out)do v[1]=v[1]*pick('widthScale');local h=v[2]*pick('heightScale')*compensation;v[2]=h*math.cos(a);if perspective then v[3]=h*math.sin(a)end;if v[9]>0 then v[9]=1+V.require('DioramaConfig').dynamicTexture.treeWeight end end
 return out
end
function F.build(out,d,ts,ox,oz,instances,contacts)
 if not F.applies(d)then return end
 for _,p in ipairs(F.plan(d).trees)do
  local x,z=p.x+ox*16,p.z+oz*16
  if instances then local g=instances.props[p.kind];if not g then g={mid=p.kind=='mossdeepLarge'and 0x302 or 0x31a,kind=p.kind,ground=1,placements={}};instances.props[p.kind]=g end;g.placements[#g.placements+1]={x,z,1}
  else V.require('Props').stamp(out,ts,0x31a,p.kind,x,z,1)end
  local c=V.require('DioramaConfig').contact;local n=p.kind=='mossdeepLarge'and 1.3 or 1
  contacts[#contacts+1]={x,z,c.treeRadius[1]*n,c.treeRadius[2]*n,c.treeStrength}
 end
end
return F
