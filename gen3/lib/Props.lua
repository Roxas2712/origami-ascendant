-- Native prop silhouettes on flat cards; no per-pixel extrusion.
local V=...

-- Reference-style tall grass: a hand-drawn fern (one per tile) whose four
-- tones are sampled from the map's own tall-grass metatile, so every region
-- keeps its native palette. o=outline d=dark m=mid l=light.
local FERN=[[
.......omo.......
.......omo.......
..o....omo...oo..
.oloo.olmo..olmo.
..olmoolmo.olmo..
..olmoolmmoolmo..
...olmolmmolmo...
...olmolmmolmo...
o...olmlmmlmo...o
lo..olmlmmlmo..ol
olo..ollmlmo..olo
omlooollmmmooolmo
.omlloolmooollmo.
.odmmlolmoolmmdo.
.omddmlodolmddmo.
.odmmomodomdmmdo.
..oddmmddommddo..
...ooddddoddoo...
.....oooo.oo.....
]]
local fernRows={};for line in FERN:gmatch('[^\n]+')do fernRows[#fernRows+1]=line end
local function fernTones(ts,mid,lawn,pixel)
  local list={}
  for y=0,15 do for x=0,15 do
    local r,g,b,a=pixel(ts,mid,x,y)
    if a>.5 and not lawn[string.format('%.3f,%.3f,%.3f',r,g,b)] then list[#list+1]={x=x,y=y,l=.2126*r+.7152*g+.0722*b} end
  end end
  if #list<4 then return nil end
  table.sort(list,function(a,b)return a.l<b.l end)
  -- Tones by distinct colour, not pixel count: darkest outline, brightest
  -- highlight, and the two in between as leaf shadow and leaf body.
  local uniq,seen={},{}
  for _,e in ipairs(list)do local k=string.format('%.3f',e.l);if not seen[k]then seen[k]=true;uniq[#uniq+1]=e end end
  local n=#uniq
  local function at(i)return uniq[math.max(1,math.min(n,i))]end
  return {o=at(1),d=at(math.max(2,math.floor(n*.4))),m=at(math.max(2,math.floor(n*.75))),l=at(n)}
end
local function fernTuft(ts,mid,tones,height,width)
  local G=V.require("WorldGeometry");local uy,uz=V.require("Billboard").up()
  local enabled=V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=="perspective"
  local H=#fernRows;local W=#fernRows[1]
  local sy=height/H;local sx=width/W;local out={}
  local function point(x,y)
    local h=(H-y)*sy*V.require('Billboard').heightScale()
    return {(x-W/2)*sx,h*uy,h*uz,0,0,enabled and 1 or 0}
  end
  for y=1,H do
    local row=fernRows[y];local x=1
    while x<=W do
      local ch=row:sub(x,x)
      if ch~='.' then
        local start=x
        while x<=W and row:sub(x,x)==ch do x=x+1 end
        local t=tones[ch]
        G.quad(out,point(start-1,y-1),point(x-1,y-1),point(x-1,y),point(start-1,y),G.uv(ts,mid,t.x,t.y,t.x+1,t.y+1,.5),1)
      else x=x+1 end
    end
  end
  return out
end
local P={cache=setmetatable({},{__mode="k"})}
local function template(ts,mid,kind,ground)
  local key=mid..":"..kind..":"..tostring(ground or 1)
  local cache=P.cache[ts] or {};P.cache[ts]=cache
  if cache[key] then return cache[key] end
  if kind=='fallarborTree'then cache[key]=V.require('EmeraldFallarborTrees').template(ts);return cache[key]end
  if kind=='ashTree'or kind=='ashGrass'then
    cache[key]=V.require('EmeraldAshRoute').template(ts,kind);return cache[key]
  end
  if kind=='mossdeepSmall'or kind=='mossdeepLarge'or kind=='mossdeepEdge'then
    cache[key]=V.require('EmeraldMossdeepTrees').template(ts,kind);return cache[key]
  end
  if kind=='compactForest'then
    cache[key]=V.require('EmeraldCompactForest').template(ts,mid);return cache[key]
  end
  if kind=='seaRock'then
    cache[key]=V.require('FireRedSeaRocks').template(ts,mid);return cache[key]
  end
  if kind=='safariTree'then
    cache[key]=V.require('FireRedSafari').template(ts);return cache[key]
  end
  if kind=='rainforest'then
    cache[key]=V.require('EmeraldRainforest').template(ts,mid);return cache[key]
  end
  local pixel=V.require("BuildingMesh").pixel
  local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
  local cfg=V.require("DioramaConfig").props
  local bg={}
  for y=0,15 do for x=0,15 do local r,g,b=pixel(ts,ground or 1,x,y);bg[rgb(r,g,b)]=true end end
  -- Native sign tiles carry an opaque baked ground shadow. Identify its
  -- neutral palette on the bottom row; do not raise it with the sign/post.
  local signShadow={}
  if kind=="sign" then
    for x=0,15 do
      local r,g,b,a=pixel(ts,mid,x,15)
      if a>.5 and math.abs(r-g)<.02 and math.abs(g-b)<.05 then signShadow[rgb(r,g,b)]=true end
    end
  end
  local function inside(x,y,m,sx,sy)
    local r,g,b,a=pixel(ts,m,sx,sy)
    if a<=.5 or (kind=="rock" and a<cfg.objectAlphaCutoff) or (kind=="sign" and a<cfg.signAlphaCutoff) or bg[rgb(r,g,b)]then return false end
    if kind=="sign" and sy>=12 and signShadow[rgb(r,g,b)]then return false end
    if kind=="fence" or kind=="mailbox" or kind=="sign" or kind=="post" then
      -- Native opaque tiles include several green ground palettes, not just
      -- the donor grass. Remove those texels before making an upright card.
      if g>r+.06 and g>b+.045 then return false end
      if kind=="fence" and sy>=13 then return false end
      -- Grey cast-shadow pixels are not part of the mailbox post.
      if kind=="mailbox" and m==mid and sy>=12 and (sx<6 or sx>9 or math.abs(r-g)<.025)then return false end
    end
    return true
  end
  local sprite=V.require("PaperSprite")
  local out={}
  if kind=="post" then
    -- Native wooden boundaries pack several independent posts into one tile.
    -- Keep their feet/spacing; never stand the whole N/S strip on one card.
    for row=0,1 do for col=0,1 do
      local x0,y0=col*8,row*8
      local low=-1
      for y=0,7 do for x=0,7 do
        local r,g,b,a=pixel(ts,mid,x+x0,y+y0)
        if a>=cfg.objectAlphaCutoff and r>g+.025 and r>b+.08 then low=math.max(low,y)end
      end end
      -- E6/E8/E9 horizontal posts span both source rows; F0/F2/F3
      -- contain two short posts arranged north/south.
      local vertical=mid==0xf0 or mid==0xf2 or mid==0xf3
      if low>=0 and (vertical or row==0)then
        local H=vertical and 8 or 16
        local base=vertical and 8 or 13
        local post=sprite.build(ts,8,H,function(x,y)return mid,x+x0,y+(vertical and y0 or 0)end,
          function(x,y,m,sx,sy)
            local r,g,b,a=pixel(ts,m,sx,sy)
            return a>=cfg.objectAlphaCutoff and r>g+.025 and r>b+.08 and (vertical or sy<13)
          end,0,base,cfg.woodPostHeight/base,nil,nil,.5)
        local foot=vertical and y0+7 or 14
        for _,v in ipairs(post)do v[1]=v[1]+x0;v[3]=v[3]+foot;v[7]=v[7]+x0;v[8]=v[8]+foot;out[#out+1]=v end
      end
    end end
  elseif kind=="rock" then
    out=sprite.build(ts,16,16,function(x,y)return mid,x,y end,inside,0,15,cfg.rockHeight/15,nil,nil,.5)
    for _,v in ipairs(out)do v[3]=v[3]+14;v[8]=v[8]+14 end
  elseif kind=="grass" then
    local grass=V.require('DioramaConfig').grass
    if grass.enabled then
      -- Each complete native leaf silhouette is a small standing tuft, not
      -- a chopped horizontal atlas strip. Reject opaque mint ground pixels.
      -- Lawn colours come from the plain ground metatile (0x001), as the
      -- building cutouts do. Everything else in the tall-grass tile is the
      -- plant: dark outline, leaf body and highlights all stay.
      local lawn={}
      local okGround=ts.midToSlot[1]~=nil
      if okGround then for yy=0,15 do for xx=0,15 do
        local r,g,b=pixel(ts,1,xx,yy);lawn[string.format('%.3f,%.3f,%.3f',r,g,b)]=true
      end end end
      -- Background = lawn-coloured texels reachable from the tile border.
      -- Lawn-coloured leaf bodies enclosed by the dark outline stay, so the
      -- whole native plant stands up (as in the reference footage).
      local outside={}
      if grass.floodLeaf and okGround then
        local queue={}
        local function key(x,y)return y*16+x end
        local function isLawn(x,y)local r,g,b=pixel(ts,mid,x,y);return lawn[string.format('%.3f,%.3f,%.3f',r,g,b)]end
        for i=0,15 do for _,p in ipairs({{i,0},{i,15},{0,i},{15,i}})do
          if isLawn(p[1],p[2])and not outside[key(p[1],p[2])]then outside[key(p[1],p[2])]=true;queue[#queue+1]=p end
        end end
        local h=1
        while h<=#queue do local p=queue[h];h=h+1
          for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}})do
            local x,y=p[1]+d[1],p[2]+d[2]
            if x>=0 and x<16 and y>=0 and y<16 and not outside[key(x,y)] and isLawn(x,y)then outside[key(x,y)]=true;queue[#queue+1]={x,y}end
          end
        end
      end
      local function leaves(x,y,m,sx,sy)
        local r,g,b,a=pixel(ts,m,sx,sy)
        if a<grass.alphaCutoff then return false end
        if grass.floodLeaf and okGround then return not outside[sy*16+sx] end
        if grass.fullLeaf and okGround then
          return not lawn[string.format('%.3f,%.3f,%.3f',r,g,b)]
        end
        return g>r*1.05 and b<g*(grass.leafBlueRatio or .60)
      end
      local tones=grass.fern and okGround and fernTones(ts,mid,lawn,pixel)
      if tones then
        local tuft=fernTuft(ts,mid,tones,grass.fernHeight,grass.fernWidth)
        for _,v in ipairs(tuft)do
          v[1]=v[1]+8;v[3]=v[3]+grass.singleFoot;v[7]=8;v[8]=(v[8]or 0)+grass.singleFoot
          if v[9]>0 then v[9]=1+V.require('DioramaConfig').dynamicTexture.grassWeight end
          out[#out+1]=v
        end
      end
      for row=(grass.rows==1 and 1 or 0),(tones and 0 or 1) do
        local scale=grass.tuftHeight/16*(row==0 and grass.backHeightScale or 1)
        local tuft=sprite.build(ts,16,16,function(x,y)return mid,x,y end,leaves,0,16,scale,nil,nil,.5)
        local center=8+(grass.rows==1 and 0 or (row==0 and -grass.stagger or grass.stagger))
        local foot=grass.rows==1 and (grass.singleFoot or 12) or 6+(row-.5)*grass.rowSpacing+4
        for _,v in ipairs(tuft)do
          v[1]=(v[1]-8)*grass.tuftWidth/16+center
          v[3]=v[3]+foot;v[7]=center;v[8]=v[8]+foot
          if v[9]>0 then v[9]=1+V.require('DioramaConfig').dynamicTexture.grassWeight end
          out[#out+1]=v
        end
      end
    else
      -- Retain the prior two-strip rendering behind the grass-only flag.
      for row=0,8,8 do
        local strip=sprite.build(ts,16,8,function(x,y)return mid,x,y+row end,inside,0,8,.85)
        for _,v in ipairs(strip)do v[3]=v[3]+row+6;v[8]=v[8]+row+6;out[#out+1]=v end
      end
    end
  else
    if kind=="mailbox" then
      local post=V.require('DioramaConfig').props.mailboxPostHeight
      local head=ts.midToSlot[0x2a5]and 6 or 0
      local height=head+12+post
      out=sprite.build(ts,16,height,function(x,y)
        if y<head then return 0x2a5,x,y+10 end
        y=y-head
        return mid,x,y<12 and y or 12+math.min(2,math.floor((y-12)*3/post))
      end,inside,0,height)
    else
      out=sprite.build(ts,16,16,function(x,y)return mid,x,y end,inside,0,kind=="fence" and 13 or 16,1,nil,nil,kind=="sign" and .5 or nil)
      if kind=="fence" or kind=="sign" then
        for _,v in ipairs(out)do v[6]=kind=="sign" and 5.25 or 5 end
      end
    end
    for _,v in ipairs(out)do v[3]=v[3]+14;v[8]=v[8]+14 end
  end
  -- Snow must also reach stationary shrubs and flower leaves. A tiny explicit
  -- tag distinguishes foliage from signs/rocks without adding wind or changing
  -- its daylight lift, spring/autumn palette, silhouette or placement.
  if (kind=='shrub'or kind=='flower')and not V.data('Emerald').active()then
    for _,v in ipairs(out)do if(v[9]or 0)>.5 then v[9]=1.001 end end
  end
  cache[key]=out;return out
end
-- The Pallet mailbox starts six pixels above its solid base cell. Remove
-- exactly those head pixels from the native lawn when the complete pair exists.
function P.mailboxHeadFloor(out,def,ts,x,y,ox,oz,ground)
 local L=def.midLayout
 if (def.renderPair or def.pair)~='pallet_outdoor'or L:midAt(x,y)~=0x2a5
  or y+1>=L.height or L:midAt(x,y+1)~=0x2ad then return false end
 local G=V.require('WorldGeometry');local pixel=V.require('BuildingMesh').pixel
 local xx,zz=(x+ox)*16,(y+oz)*16
 local function source(sx,sy)
  if sy>=10 then local r,g,b,a=pixel(ts,0x2a5,sx,sy)
   if a>.5 and not(g>r+.06 and g>b+.045)then return ground end
  end
  return 0x2a5
 end
 for sy=0,15 do local sx=0
  while sx<16 do
   local donor=source(sx,sy);local stop=sx+1
   while stop<16 and source(stop,sy)==donor do stop=stop+1 end
   G.quad(out,{xx+sx,0,zz+sy},{xx+stop,0,zz+sy},{xx+stop,0,zz+sy+1},{xx+sx,0,zz+sy+1},G.uv(ts,donor,sx,sy,stop,sy+1),1)
   sx=stop
  end
 end
 return true
end
function P.release()P.cache=setmetatable({},{__mode="k"})end
P.template=template
function P.stamp(out,ts,mid,kind,x,z,ground)
  for _,v in ipairs(template(ts,mid,kind,ground))do out[#out+1]=V.require("WorldGeometry").place(v,x,z) end
end
return P
