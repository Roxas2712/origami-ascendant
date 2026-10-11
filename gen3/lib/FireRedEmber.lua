-- Mt. Ember's own grey rock atlas. Rendering only; native routes stay at y=0.
local V=...
local E={}
local maps={FR_MT_EMBER_EXTERIOR=true,FR_MT_EMBER_SUMMIT=true}
local mids={0x334,0x335,0x336,0x337,0x33c,0x33d,0x33e,0x33f,0x345,0x347,
 0x34b,0x34c,0x34d,0x34e,0x34f,0x351,0x353,0x354,0x355,0x356,0x357,0x359,0x35b,0x35c,0x35d,
 0x35e,0x35f,0x360,0x361,0x362,0x363,0x364,0x365,0x366,0x367,0x368,0x369,0x36a,0x36f}
local rock={};for _,m in ipairs(mids)do rock[m]=true end
function E.applies(d)return d and maps[d.id or d.name]==true and d.pair=='sevii_outdoor' end
function E.kind(d,c)
 if not E.applies(d)or not c then return end
 if c.mid==0x346 then return 'emberEntrance' end
 if rock[c.mid]then
  if c.coll>=0xa0 and c.coll<=0xa7 or c.coll>=0x38 and c.coll<=0x3b then return 'emberLedge' end
  if c.coll==7 or c.coll==255 then return (c.mid==0x356 or c.mid==0x357)and 'emberBoulder'or 'emberCliff' end
 end
end
function E.height(kind)
 local cfg=V.require('DioramaConfig').terrain
 return kind=='emberLedge'and cfg.ledgeHeight or kind=='emberBoulder'and math.min(10,cfg.cliffHeight)or cfg.cliffHeight
end
local masks=setmetatable({},{__mode='k'})
local function mask(ts,mid)
 local byMid=masks[ts];if not byMid then byMid={};masks[ts]=byMid end
 if byMid[mid]then return byMid[mid]end
 local q={n=0};local pixel=V.require('BuildingMesh').pixel
 for y=0,15 do for x=0,15 do local r,g,b,a=pixel(ts,mid,x,y)
  -- Measured rock palette R=G; yellow sand and green grass do not match.
  local yes=a>.5 and math.abs(r-g)<.001;q[y*16+x+1]=yes
  if yes then q.n=q.n+1 end
 end end
 byMid[mid]=q;return q
end
function E.pixel(ts,mid,x,y)return mask(ts,mid)[y*16+x+1]end
function E.stamp(out,d,ts,x,z,ox,oz,cells,kind)
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').terrain
 local L=d.midLayout;local h=E.height(kind);local mid=L:midAt(x,z)
 local xx,zz=(x+ox)*16,(z+oz)*16
 local function face(a,b,c,e,u0,v0,u1,v1,shade,donor)
  G.quad(out,a,b,c,e,G.uv(ts,donor or mid,u0,v0,u1,v1,.5),shade)
 end
 if kind=='emberEntrance'then
  -- Native aperture is a recess, never a solid black rectangle in front.
  face({xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},0,0,16,16,cfg.topShade,0x351)
  for sy=0,15 do local sx=0
   while sx<16 do
    if E.pixel(ts,mid,sx,sy)then local start=sx
     repeat sx=sx+1 until sx==16 or not E.pixel(ts,mid,sx,sy)
     face({xx+start,h*(1-sy/16),zz+16},{xx+sx,h*(1-sy/16),zz+16},
      {xx+sx,h*(1-(sy+1)/16),zz+16},{xx+start,h*(1-(sy+1)/16),zz+16},start,sy,sx,sy+1,cfg.sideShade)
    else sx=sx+1 end
   end
  end
  face({xx,h,zz+1},{xx+16,h,zz+1},{xx+16,0,zz+1},{xx,0,zz+1},7,9,9,11,cfg.sideShade)
  return
 end
 local sampled={}
 local function occupied(px,pz)
  local tx,tz=math.floor(px/16),math.floor(pz/16);local key=tz*65536+tx
  local q=sampled[key]
  if q==nil then
   local c=L:cellAt(tx,tz)
   local k=(tx>=0 and tz>=0 and tx<L.width and tz<L.height)and cells[tz*L.width+tx+1]or E.kind(d,c)
   if k=='emberEntrance'then q=true
   elseif (k=='emberCliff'or k=='emberLedge'or k=='emberBoulder')and E.height(k)>=h then q=mask(ts,c.mid)
   else q=false end
   sampled[key]=q
  end
  return q==true or type(q)=='table'and q[(pz%16)*16+px%16+1]

 end
 -- Preserve native mixed grass/sand pixels on the floor; raise only rock.
 local full=mask(ts,mid).n==256
 if full then
  face({xx,h,zz},{xx+16,h,zz},{xx+16,h,zz+16},{xx,h,zz+16},0,0,16,16,cfg.topShade)
 else
 for sy=0,15 do local sx=0
  while sx<16 do
   local solid=occupied(x*16+sx,z*16+sy);local start=sx
   repeat sx=sx+1 until sx==16 or occupied(x*16+sx,z*16+sy)~=solid
   local y=solid and h or .01
   face({xx+start,y,zz+sy},{xx+sx,y,zz+sy},{xx+sx,y,zz+sy+1},{xx+start,y,zz+sy+1},start,sy,sx,sy+1,solid and cfg.topShade or 1)
  end
 end
 end
 -- Contiguous silhouette edges share wall strips; interior faces are culled.
 for _,dir in ipairs{{0,1},{0,-1},{1,0},{-1,0}}do
  local first,last=0,15
  if full then first=(dir[1]+dir[2]>0)and 15 or 0;last=first end
  for row=first,last do local col=0
   local function edge(c)
    local sx,sy=dir[1]==0 and c or row,dir[1]==0 and row or c
    return occupied(x*16+sx,z*16+sy)and not occupied(x*16+sx+dir[1],z*16+sy+dir[2])
   end
   while col<16 do
    if edge(col)then local start=col;repeat col=col+1 until col==16 or not edge(col)
     if dir[1]==0 then local fz=zz+row+(dir[2]>0 and 1 or 0)
      face({xx+start,h,fz},{xx+col,h,fz},{xx+col,0,fz},{xx+start,0,fz},start,0,col,16,cfg.sideShade,0x35c)
     else local fx=xx+row+(dir[1]>0 and 1 or 0)
      face({fx,h,zz+start},{fx,h,zz+col},{fx,0,zz+col},{fx,0,zz+start},start,0,col,16,cfg.sideShade,0x35c)
     end
    else col=col+1 end
   end
  end
 end
end
return E
