-- Native harbor props: separate the object from its baked pavement/shadow.
-- The sea wall is a connected solid on its original footprint, not a card.
local V=...
local P={}
local lawns=setmetatable({},{__mode='k'})
local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
local borders={
 [0x245]='north',[0x25d]='south',[0x234]='west',[0x2c7]='west',
 [0x23c]='east',[0x2cf]='east',[0x255]='nw',[0x24d]='ne',
 [0x2fe]='sw',[0x2ff]='se',
 [0x308]='north',[0x309]='north',[0x30a]='north',[0x30b]='north',[0x30c]='north',
}
function P.applies(d)
 return d.id=='EM_SLATEPORT_CITY'and d.pair=='general__slateport'
end
local function enabled(d)
 return P.applies(d)and V.require('DioramaConfig').slateportProps.enabled
  and V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=='perspective'
end
function P.border(mid,x,y)
 local k=borders[mid]
 return k and ((k=='north'or k=='nw'or k=='ne')and y<8
  or(k=='south'or k=='sw'or k=='se')and y>=8
  or(k=='west'or k=='nw'or k=='sw')and x<8
  or(k=='east'or k=='ne'or k=='se')and x>=8)or false
end
function P.silhouette(ts,mid,x,y)
 if mid==0x243 then
  local pixel=V.require('BuildingMesh').pixel;local bg=lawns[ts]
  if not bg then bg={};for sy=0,15 do for sx=0,15 do bg[rgb(pixel(ts,1,sx,sy))]=true end end;lawns[ts]=bg end
  local r,g,b,a=pixel(ts,mid,x,y)
  return a>.5 and not bg[rgb(r,g,b)]
 elseif mid==0x32d then
  -- Native stem ends at row 13. Blue pixels spreading beyond it are a
  -- painted floor shadow, which must not become upright geometry.
  local rows={
   '......XXXXXX....','....XXXXXXXXXX..','...XXXXXXXXXXXX.','...XXXXXXXXXXXX.',
   '..XXXXXXXXXXXXX.','..XXXXXXXXXXXXX.','..XXXXXXXXXXXX..','..XXXXXXXXXXX...',
   '..XXXXXXXXX.....','..XXXXXXXXX.....','..XXXXXXXXX.....','..XXXXXXXXX.....',
   '...XXXXXXX......','.....XXXX.......',
  }
  return rows[y+1]and rows[y+1]:sub(x+1,x+1)=='X'or false
 end
 return false
end
function P.build(out,d,ts,x,y,ox,oz,contacts)
 if not enabled(d)then return false end
 local mid=d.midLayout:midAt(x,y);if mid~=0x243 and mid~=0x32d then return false end
 local G=V.require('WorldGeometry');local S=V.require('PaperSprite')
 local cfg=V.require('DioramaConfig').slateportProps
 local xx,zz=(x+ox)*16,(y+oz)*16
 local bush=mid==0x243;local donor=bush and 1 or 0x202
 G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,donor),1)
 local foot=bush and 15 or 14;local h=bush and cfg.bushHeight or cfg.bollardHeight
 local sprite=S.build(ts,16,16,function(sx,sy)return mid,sx,sy end,
  function(sx,sy)return P.silhouette(ts,mid,sx,sy)end,0,foot,h/foot,function()return 5 end,nil,.5)
 for _,v in ipairs(sprite)do v[3]=v[3]+foot;v[8]=v[8]+foot;out[#out+1]=G.place(v,xx,zz)end
 local c=V.require('DioramaConfig').contact
 contacts[#contacts+1]={xx+8,zz+foot,bush and 6 or 4,c.propRadius,c.strength}
 return true
end
function P.walls(out,d,ts,ox,oz)
 if not enabled(d)then return end
 local L=d.midLayout;local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').slateportProps
 local h=cfg.wallHeight
 local function occupied(x,y)
  if x<0 or y<0 or x>=L.width*16 or y>=L.height*16 then return false end
  return P.border(L:midAt(math.floor(x/16),math.floor(y/16)),x%16,y%16)
 end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local mid=L:midAt(x,y)
  if borders[mid]then
   local xx,zz=(x+ox)*16,(y+oz)*16
   -- Native cap texture, including its mortar joints. Row runs cannot
   -- reach a neighboring atlas cell and all connecting caps share height.
   for sy=0,15 do local sx=0
    while sx<16 do
     if P.border(mid,sx,sy)then
      local start=sx;repeat sx=sx+1 until sx==16 or not P.border(mid,sx,sy)
      G.quad(out,{xx+start,h,zz+sy},{xx+sx,h,zz+sy},{xx+sx,h,zz+sy+1},{xx+start,h,zz+sy+1},G.uv(ts,mid,start,sy+.5,sx,sy+.5,0),1)
     else sx=sx+1 end
    end
   end
   -- Only exposed edges get sides; shared tile/corner boundaries are not
   -- duplicated. Sample the native grey masonry, never black filler.
   local uv=G.uv(ts,0x245,0,0,1,1,.5)
   for sy=0,15 do for sx=0,15 do if P.border(mid,sx,sy)then
    local a,b=xx+sx,zz+sy;local wx,wz=x*16+sx,y*16+sy
    if not occupied(wx,wz-1)then G.quad(out,{a,0,b},{a+1,0,b},{a+1,h,b},{a,h,b},uv,cfg.wallSideShade)end
    if not occupied(wx,wz+1)then G.quad(out,{a,h,b+1},{a+1,h,b+1},{a+1,0,b+1},{a,0,b+1},uv,cfg.wallSideShade)end
    if not occupied(wx-1,wz)then G.quad(out,{a,0,b+1},{a,0,b},{a,h,b},{a,h,b+1},uv,cfg.wallSideShade)end
    if not occupied(wx+1,wz)then G.quad(out,{a+1,0,b},{a+1,0,b+1},{a+1,h,b+1},{a+1,h,b},uv,cfg.wallSideShade)end
   end end end
  end
 end end
end
return P
