-- Native multi-metatile rock columns are one object, not a stack of caps.
local V=...
local P={cache=setmetatable({},{__mode='k'})}
local types={
 {top={0x24b},shaft={0x253},foot={0x25b}},
 {top={0x24c},shaft={0x254},foot={0x25c}},
 {top={0x264,0x265},shaft={0x26c,0x26d},foot={0x274,0x275}},
 {top={0x266,0x267},shaft={0x26e,0x26f},foot={0x276,0x277}},
}
function P.applies(d)
 return d and tostring(d.id or''):match('^EM_METEOR_FALLS_')and d.pair=='general__meteor_falls'
  and V.require('DioramaConfig').meteorColumns.enabled
end
function P.plan(d)
 if not P.applies(d)then return{objects={},mask={}}end
 local L=d.midLayout;local stamp=V.require('WorldGeometry').layoutStamp(L)
 local old=P.cache[L];if old and old.stamp==stamp then return old end
 local result={stamp=stamp,objects={},mask={}}
 local function row(x,y,pattern)
  if y>=L.height or x+#pattern>L.width then return false end
  for i,mid in ipairs(pattern)do if L:midAt(x+i-1,y)~=mid then return false end end;return true
 end
 for y=0,L.height-1 do for x=0,L.width-1 do for _,t in ipairs(types)do
  if row(x,y,t.top)then
   local bottom=y+1;while row(x,bottom,t.shaft)do bottom=bottom+1 end
   if bottom>y+1 and row(x,bottom,t.foot)then
    local o={x=x,y=y,w=#t.top,h=bottom-y+1,mids={}}
    for sy=y,bottom do for sx=x,x+o.w-1 do
     o.mids[#o.mids+1]=L:midAt(sx,sy)
     result.mask[sy*L.width+sx+1]={object=o,donor=sy==bottom and 0x229 or 0x244}
    end end
    result.objects[#result.objects+1]=o
   end
  end
 end end end
 P.cache[L]=result;return result
end
function P.donor(d,x,y)
 if not P.applies(d)then return end
 local p=P.plan(d).mask[y*d.midLayout.width+x+1];return p and p.donor
end
function P.cutout(o,ts)
 local W,H=o.w*16,o.h*16;local pixel=V.require('BuildingMesh').pixel
 local function source(x,y)return o.mids[math.floor(y/16)*o.w+math.floor(x/16)+1],x%16,y%16 end
 local rows={};local foot=0
 for y=0,H-1 do
  local lo,hi
  for x=0,W-1 do local m,sx,sy=source(x,y);local r,g,b,a=pixel(ts,m,sx,sy)
   -- Gold rock palette is disjoint from the violet wall/floor. Retain its
   -- native one-pixel dark outline along both silhouette sides.
   if a>.5 and r>b+.09 and g>b+.09 then lo=lo or x;hi=x end
  end
  if lo then rows[y]={math.max(0,lo-1),math.min(W-1,hi+1)};foot=y+1 end
 end
 return source,rows,foot
end
function P.floor(out,d,ts,x,y,ox,oz)
 if not P.applies(d)then return false end
 local p=P.plan(d).mask[y*d.midLayout.width+x+1]
 if not p or p.donor~=0x229 then return false end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 G.quad(out,{xx,0,zz},{xx+16,0,zz},{xx+16,0,zz+16},{xx,0,zz+16},G.uv(ts,p.donor),1)
 return true
end
function P.build(out,d,ts,ox,oz,contacts)
 if not P.applies(d)or not V.require('DioramaConfig').billboards.enabled or V.require('Camera').projection()~='perspective'then return end
 local G=V.require('WorldGeometry');local cfg=V.require('DioramaConfig').meteorColumns
 for _,o in ipairs(P.plan(d).objects)do
  local source,rows,foot=P.cutout(o,ts)
  local sprite=V.require('PaperSprite').build(ts,o.w*16,o.h*16,source,
   function(x,y)return rows[y]and x>=rows[y][1]and x<=rows[y][2]end,0,foot,cfg.heightScale,nil,nil,.5)
  local xx,zz=(o.x+ox)*16,(o.y+oz)*16
  for _,v in ipairs(sprite)do v[3]=v[3]+foot;v[8]=v[8]+foot;out[#out+1]=G.place(v,xx,zz)end
  contacts[#contacts+1]={xx+o.w*8,zz+foot,o.w*cfg.contactWidth,cfg.contactDepth,cfg.contactStrength}
 end
end
return P
