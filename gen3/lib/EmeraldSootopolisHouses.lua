-- Native Sootopolis house silhouettes. White walls and white paving share
-- palette entries, so colour-keying cannot separate this architecture.
local V=...
local M={}
function M.inside(style,x,y)
 if style=='sootopolis_dome'then
  if y<8 then return false end
  local lo
  if y<=17 then lo=31-y elseif y<=26 then lo=26-y elseif y<=70 then lo=0 elseif y<=78 then lo=y-70 else lo=8 end
  return x>=lo and x<=47-lo
 end
 if style=='sootopolis_flat'then
  local lo=y==0 and 3 or y==1 and 2 or y==63 and 2 or 1
  return y>=0 and y<64 and x>=lo and x<=47-lo
 end
 return false
end
function M.buildings(d)
 local out={};local C=V.require('DioramaConfig').sootopolisArchitecture
 if not C.enabled or d.id~='EM_SOOTOPOLIS_CITY'or d.pair~='general__sootopolis'then return out end
 local L=d.midLayout
 for y=2,L.height-3 do for x=1,L.width-2 do
  local mid=L:midAt(x,y);local dome=mid==0x20a and L:midAt(x-1,y)==0x209 and L:midAt(x+1,y)==0x20b
  if dome or mid==0x20e then
   local b={x0=x-1,x1=x+1,y0=dome and y-1 or y,y1=y+2,doorX=x,doorY=y+2,ground=0x2d9,
    hoennLocalArchitecture=true,nativeSilhouette=dome and'sootopolis_dome'or'sootopolis_flat',
    eaveRow=dome and 54 or 32,paperValues={wallScale=C.wallScale,roofScale=C.roofScale},panes={},renderOnly=true}
   for _,w in ipairs(d.warps or{})do if w.x==x and w.y==y+2 then b.renderOnly=nil;break end end
   out[#out+1]=b
  end
 end end
 return out
end
-- Keep source rock/paving outside the silhouette; replace only lifted art
-- with its real native paving donor. No rectangle of white floor on cliffs.
function M.floor(out,b,L,ts,x,y,ox,oz)
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 local mid=L:midAt(x,y);local rx,ry=(x-b.x0)*16,(y-b.y0+1)*16
 local function isInside(px,py)return M.inside(b.nativeSilhouette,rx+px,ry+py)end
 local n=0;for py=0,15 do for px=0,15 do if isInside(px,py)then n=n+1 end end end
 if n==0 or n==256 then
  G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,n==0 and mid or b.ground),1)
 else
  local vv=V.require('PaperSprite').build(ts,16,16,function(px,py)return isInside(px,py)and b.ground or mid,px,py end,
   function()return true end,0,0,1,nil,function(px,py)return{xx+px,0,zz+py}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
end
return M
