-- Native cave edges are rock, not outdoor grass ledges. Render-only geometry;
-- the engine's jump direction, elevation, cells and warp data stay authoritative.
local V=...
local C={}
function C.applies(d)
 return d and V.data('Emerald').map(d) and tonumber(d.mapType)==4
  and (d.pair=='general__cave' or d.pair=='general__meteor_falls')
end
function C.ledge(out,d,ts,x,z,ox,oz)
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').terrain.caveLedges
 local cell=d.midLayout:cellAt(x,z);local mid=cell.mid
 local xx,zz=(x+ox)*16,(z+oz)*16;local h,w=cfg.height,cfg.depth
 local function face(a,b,c,e,x0,y0,x1,y1,shade)
  G.quad(out,a,b,c,e,G.uv(ts,mid,x0,y0,x1,y1,.5),shade)
 end
 -- Complete native floor coverage: the previous outdoor routine left the
 -- unused half of indoor ledge tiles empty and sampled primary grass for caps.
 face({xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},0,0,16,16,1)
 local x0,z0,x1,z1=0,0,16,16
 if cell.coll==0xa0 then x0=16-w
 elseif cell.coll==0xa1 then x1=w
 elseif cell.coll==0xa2 then z1=w
 elseif cell.coll==0xa3 then z0=16-w
 else return end
 local a,b,c,e={xx+x0,h,zz+z0},{xx+x1,h,zz+z0},{xx+x1,h,zz+z1},{xx+x0,h,zz+z1}
 face(a,b,c,e,x0,z0,x1,z1,cfg.topShade)
 -- Four short sides keep the low rock lip a closed volume. Source axes stay
 -- aligned even on east/west edges; no rotated grass strip or black filler.
 face({a[1],0,a[3]},a,e,{e[1],0,e[3]},x0,z0,x1,z1,cfg.sideShade)
 face(b,{b[1],0,b[3]},{c[1],0,c[3]},c,x0,z0,x1,z1,cfg.sideShade)
 face(e,c,{c[1],0,c[3]},{e[1],0,e[3]},x0,z0,x1,z1,cfg.sideShade)
 face({a[1],0,a[3]},{b[1],0,b[3]},b,a,x0,z0,x1,z1,cfg.sideShade)
end
return C
