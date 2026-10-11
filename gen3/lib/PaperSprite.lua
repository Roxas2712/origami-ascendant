-- Flat cutouts made from native atlas texels. Runs stay inside their source
-- metatile so animated textures still update without copying GPU images.
local V=...
local P={}
function P.build(ts,W,H,source,inside,originX,base,scale,surfaceShade,transform,uvInset,emissiveEligibility)
  local G=V.require("WorldGeometry")
  local uy,uz=V.require("Billboard").up()
  local out={};scale=scale or 1
  local function point(x,y)
    if transform then return transform(x,y)end
    local h=(base-y)*scale*V.require('Billboard').heightScale()
    local enabled=V.require('DioramaConfig').billboards.enabled and V.require('Camera').projection()=="perspective"
    return {x+originX,h*uy,h*uz,originX+W/2,0,enabled and 1 or 0}
  end
  for y=0,H-1 do
    local x=0
    while x<W do
      local mid,sx,sy=source(x,y)
      if mid and inside(x,y,mid,sx,sy) then
        local start=x
        local shade=surfaceShade and surfaceShade(x,y) or 1
        local emissive=emissiveEligibility and emissiveEligibility(x,y)
        repeat x=x+1
          if x>=W then break end
          local m,xx,yy=source(x,y)
          if m~=mid or xx~=sx+x-start or yy~=sy or not inside(x,y,m,xx,yy)
            or (surfaceShade and surfaceShade(x,y) or 1)~=shade
            or (emissiveEligibility and emissiveEligibility(x,y))~=emissive then break end
        until false
        G.quad(out,point(start,y),point(x,y),point(x,y+1),point(start,y+1),
          G.uv(ts,mid,sx,sy,sx+x-start,sy+1,uvInset),shade)
        if emissive~=nil then for i=#out-5,#out do out[i][9]=emissive end end
      else x=x+1 end
    end
  end
  return out
end
return P
