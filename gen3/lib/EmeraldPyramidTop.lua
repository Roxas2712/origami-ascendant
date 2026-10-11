-- The native sunset is a distant backdrop, never a floor under the summit.
local V=...
local R={}
-- Native one-pixel chips contain sky, not masonry.
local chips={
 [120]={266,267,276,277,278,282,283,289,290,291},
 [136]={234,235,244,245,246,250,251,308,309,310,314,315,321,322,323},
 [152]={202,203,212,213,214,218,219,340,341,342,346,347,353,354,355},
 [168]={170,171,180,181,182,186,187,372,373,374,378,379,385,386,387},
 [184]={138,139,145,146,147,154,155,401,402,403,410,411,417,418,419},
 [200]={106,107,113,114,115,122,123,433,434,435,442,443,449,450,451},
 [216]={74,75,81,82,83,90,91,465,466,467,474,475,481,482,483},
 [232]={42,43,49,50,51,58,59,497,498,499,506,507,513,514,515},
 [248]={10,11,17,18,19,31,529,530,531},
 [249]={31},
}
for y,xs in pairs(chips)do local set={};for _,x in ipairs(xs)do set[x]=true end;chips[y]=set end
function R.kind(d)return d and(d.id or d.name)=='EM_BATTLE_FRONTIER_BATTLE_PYRAMID_TOP'end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d and d.midLayout
 if R.kind(d)and c.enabled and c.pyramidTop.enabled and d.pair=='building__battle_pyramid'and L and L.width==34 and L.height==24 and L:midAt(17,3)==0x27a and L:midAt(17,10)==0x251 then return c.homeRooms.pyramidTop end
end
-- Exact stone silhouette measured from the native 544x384 picture.
function R.bounds(y)
 if y<120 or y>=368 then return end
 local row=math.floor((y-120)/16);local l,r=math.max(0,256-row*32),math.min(544,304+row*32)
 if row<=8 and(y-120)%16==0 then l=l+1;r=r-1 end
 if row>=3 and row<=8 and(y-120)%16==1 then r=r-1 end
 return l,r
end
function R.inside(x,y)local l,r=R.bounds(y);return l and x>=l and x<r and not(chips[y]and chips[y][x])end
function R.height(x,z)
 local c=V.require('DioramaConfig').emeraldInteriors.pyramidTop
 if x>=272 and x<288 and z>=160 and z<288 then return c.tierHeight*(8-math.floor((z-160)/c.stairTreadDepth)*c.stairTreadDepth/32)end
 return math.max(0,8-math.max(0,math.floor((z-144)/32)))*c.tierHeight
end
function R.actorHeight(d,x,z)
 if R.profile(d)then return R.height(x+8,z+16)*V.require('DioramaConfig').emeraldInteriors.heightScale end
end
function R.plan(d)
 if not R.profile(d)then return end
 local mask={};for i=1,816 do mask[i]={mid=1,void=true}end
 return{{kind='pyramidTopStone',x=0,y=0,w=544,h=368,noContact=true}},mask
end
function R.build(out,L,ts,o,x,z)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.pyramidTop;local G=V.require('WorldGeometry');local first=#out+1
 local function src(s,t)return L:midAt(math.floor(s/16),math.floor(t/16)),s%16,t%16 end
 local vv=V.require('PaperSprite').build(ts,544,368,src,R.inside,0,368,1,nil,function(s,t)return{x+s,R.height(s+.001,math.min(t,367.999)),z+t}end,.5)
 -- Keep each native pixel row horizontal; connect height changes explicitly.
 -- A transform at row boundaries would turn a riser into a diagonal smear.
 for i=1,#vv,6 do
  local h=R.height(vv[i][1]-x+.001,vv[i][3]-z+.001)
  for j=i,i+5 do vv[j][2]=h;out[#out+1]=vv[j]end
 end
 local function edge(s,t,a,b,h1,h2)
  local mid,u,v=src(s,t)
  G.quad(out,{x+a[1],h1,z+a[2]},{x+b[1],h1,z+b[2]},{x+b[1],h2,z+b[2]},{x+a[1],h2,z+a[2]},G.uv(ts,mid,u,v,u+1,v+1,.5),c.sideShade)
 end
 for y=120,367 do
  local l,r=R.bounds(y)
  for xx=l,r-1 do if R.inside(xx,y)then
   local h=R.height(xx+.5,y+.5)
   local nextH=R.inside(xx,y+1)and R.height(xx+.5,y+1.5)or -c.skirtDepth
   if h~=nextH then edge(xx,y,{xx,y+1},{xx+1,y+1},h,nextH)end
   if not R.inside(xx,y-1)then edge(xx,y,{xx+1,y},{xx,y},h,-c.skirtDepth)end
   if not R.inside(xx-1,y)then edge(xx,y,{xx,y},{xx,y+1},h,-c.skirtDepth)end
   if not R.inside(xx+1,y)then edge(xx,y,{xx+1,y+1},{xx+1,y},h,-c.skirtDepth)end
   if (xx==271 or xx==287)and R.inside(xx+1,y)then
    local other=R.height(xx+1.5,y+.5)
    if other~=h then edge(xx,y,{xx+1,y+1},{xx+1,y},h,other)end
   end
  end end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
function R.release()if R.backdrop then R.backdrop:release();R.backdrop=nil end;R.texture=nil;R.layout=nil end
function R.drawBackdrop(d,w,h)
 if not R.profile(d)then return false end
 local ts=V.require('WorldAdapter').Native.get(d.pair);if not ts then return false end
 local L=d.midLayout;local c=V.require('DioramaConfig').emeraldInteriors.pyramidTop
 if not R.backdrop or R.texture~=ts.image or R.layout~=L then
  R.release()
  local function source(s,t)
   if R.inside(s,t)then s=s%16 end
   return L:midAt(math.floor(s/16),math.floor(t/16)),s%16,t%16
  end
  local vv=V.require('PaperSprite').build(ts,544,240,source,function()return true end,0,240,1,nil,function(s,t)return{s,t,0}end,.5)
  R.backdrop=love.graphics.newMesh(V.require('WorldGeometry').FORMAT,vv,'triangles','static');R.backdrop:setTexture(ts.image);R.texture=ts.image;R.layout=L
 end
 love.graphics.push('all');love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setColor(1,1,1,1)
 local r,g,b=V.require('BuildingMesh').pixel(ts,L:midAt(0,14),0,15)
 love.graphics.clear(r,g,b,1,0,1)
 local scale=math.max(w/544,h*c.skyCoverage/240)*c.skyScale
 love.graphics.draw(R.backdrop,(w-544*scale)/2,0,0,scale,scale)
 love.graphics.pop();return true
end
return R
