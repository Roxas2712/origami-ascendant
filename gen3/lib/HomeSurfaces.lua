-- Furniture folded from the native house drawings. The rug is supplied by
-- Furniture's source-aware floor mask; none of these surfaces repaint it.
local V=...
local H={}
function H.table(api,out,L,ts,o,x,z)
 local cfg=V.require('DioramaConfig').interiors.homeSurfaces
 local source,inside=api.nativeMask(L,ts,o,32,32,{o.ground or 0x44})
 local function strip(lo,hi,project)
  local vertices=V.require('PaperSprite').build(ts,32,32,source,
   function(sx,sy)return sy>=lo and sy<hi and inside(sx,sy)end,0,32,1,nil,project,.5)
  for _,v in ipairs(vertices)do out[#out+1]=v end
 end
 local h,d,rim=cfg.tableHeight,cfg.tableDepth,cfg.tableRim
 strip(0,27,function(sx,sy)return {x+sx,h,z+sy*d/27}end)
 strip(27,30,function(sx,sy)return {x+sx,h-(sy-27)*rim/3,z+d}end)
 strip(30,32,function(sx,sy)return {x+sx,(32-sy)*(h-rim)/2,z+d}end)
 o.contactFront=d;o.contactWidth=32
end
function H.chair(api,out,L,ts,o,x,z)
 local cfg=V.require('DioramaConfig').interiors.homeSurfaces
 local source,inside=api.nativeMask(L,ts,o,16,16,{o.ground or 0x44})
 -- The chairs face sideways in the native art. Keep that complete silhouette
 -- rather than turning its narrow blue backrest into a broad grey box.
 local vertices=V.require('PaperSprite').build(ts,16,16,source,inside,0,16,1,nil,
  function(sx,sy)return {x+sx,(16-sy)*cfg.chairBackHeight/16*V.require('Billboard').heightScale(),z+14}end,.5)
 for _,v in ipairs(vertices)do out[#out+1]=v end
 o.contactFront=14;o.contactWidth=16
end

H.seat=H.chair
H.glass=H.table
function H.stairsUp(api,out,L,ts,o,x,z)
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').interiors.homeSurfaces
 local first=L:midAt(o.x,o.y);local last=L:midAt(o.x+1,o.y)
 local tread=G.uv(ts,last,13,2,14,3,.5)
 local riser=G.uv(ts,last,13,4,14,5,.5)
 local rail=G.uv(ts,last,13,2,14,3,.5)
 local side=G.uv(ts,L:midAt(o.x+1,o.y+1),13,7,14,8,.5)
 local post=G.uv(ts,last,13,1,14,2,.5)
 local step=cfg.stairHeight/8
 for n=0,7 do
  local top=(n+1)*step
  api.prism(out,ts,first,x+n*4,z+13,4,23,0,top,tread,side,riser)
  G.quad(out,{x+n*4,top,z+36.02},{x+(n+1)*4,top,z+36.02},
   {x+(n+1)*4,top-1,z+36.02},{x+n*4,top-1,z+36.02},post,1)
 end
 -- Closed handrails follow the step pitch. The old cap compressed its rise
 -- into 32 pixels while posts used 28, leaving posts above the handrail.
 -- Place each post at its tread's high end and meet the sloping underside.
 local function railY(s)return cfg.stairRailHeight+s*step/4 end
 local thickness=1
 local function beam(a,b,zz,depth,bottom,drop)
  local ya,yb=railY(a)-(drop or 0),railY(b)-(drop or 0)
  local ba,bb=bottom or ya-thickness,bottom or yb-thickness
  G.quad(out,{x+a,ya,zz},{x+b,yb,zz},{x+b,yb,zz+depth},{x+a,ya,zz+depth},rail,1)
  G.quad(out,{x+a,ya,zz+depth},{x+b,yb,zz+depth},{x+b,bb,zz+depth},{x+a,ba,zz+depth},rail,.78)
  G.quad(out,{x+b,yb,zz},{x+a,ya,zz},{x+a,ba,zz},{x+b,bb,zz},post,.7)
  G.quad(out,{x+a,ya,zz},{x+a,ya,zz+depth},{x+a,ba,zz+depth},{x+a,ba,zz},post,.78)
  G.quad(out,{x+b,yb,zz+depth},{x+b,yb,zz},{x+b,bb,zz},{x+b,bb,zz+depth},post,.9)
  G.quad(out,{x+a,ba,zz+depth},{x+b,bb,zz+depth},{x+b,bb,zz},{x+a,ba,zz},post,.7)
 end
 for _,zz in ipairs({z+13,z+34})do
  beam(0,32,zz,2)
  for n=0,7 do
   -- The post's sloping cap meets the underside without a protruding tip.
   beam(n*4+3,n*4+4,zz,2,(n+1)*step,thickness)
  end
 end
 o.contactFront=36;o.contactWidth=32
end
return H
