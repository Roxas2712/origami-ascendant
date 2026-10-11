-- Native Rustboro two-metatile street lamps, separated from baked pavement.
local V=...
local P={}
local masks={
 [0x212]={'........X.......','......XXXXX.....','.....XXXXXXX....','....XXXXXXXXX...','...XXXXXXXXXXX..','...XXXXXXXXXXX..','....XXXXXXXXX...','....XXXXXXXXX...','.....XXXXXXX....','.....XXXXXXX....','......XXXXX.....','.......XXX......','......XXXXX.....','.....XXXXXXX....','......XXXXX.....','.......XXX......'},
 [0x21a]={'.......XXX......','.......XXX......','.......XXX......','.......XXX......','.......XXX......','.......XXX......','.......XXX......','.......XXX......','......XXXXX.....','......XXXXX.....','......XXXXX.....','......XXXXXX....','......XXXXXXX...','.......XXXXXXX..','.........XXXXX..','..........XXX...'},
}
function P.at(def,x,y)
 if (def.id or def.name)~='EM_RUSTBORO_CITY'or def.pair~='general__rustboro'then return end
 local L=def.midLayout;local mid=L:midAt(x,y)
 if mid==0x212 and y+1<L.height and L:midAt(x,y+1)==0x21a then return mid end
 if mid==0x21a and y>0 and L:midAt(x,y-1)==0x212 then return mid end
end
function P.mask(mid,x,y)return masks[mid]and masks[mid][y+1]:sub(x+1,x+1)=='X'end
function P.glass(mid,x,y)
 return mid==0x212 and ((y==8 or y==9)and x>=6 and x<=10 or y==10 and x>=7 and x<=9)
end
function P.registerGlass(ts)
 local slot=ts.midToSlot[0x212];local ax,ay=slot%ts.cols*16,math.floor(slot/ts.cols)*16
 local sp={ax={},ay={}};local mask={}
 for y=8,10 do for x=6,10 do if P.glass(0x212,x,y)then
  local i=y*16+x;sp.ax[i]=ax+x;sp.ay[i]=ay+y;mask[i]=true
 end end end
 V.require('LocalLights').registerGlass(ts,sp,mask)
end
function P.silhouette(mid,x,y)
 if not P.mask(mid,x,y)then return false end
 -- Bottom-tile grey pixels spreading right/down are the ROM's ground
 -- shadow, not the lamp base. Keep the native shaft and its rounded foot.
 return mid==0x212 or y<8 or(y<13 and x>=6 and x<=10)or(y==13 and x>=7 and x<=9)
end
function P.floorRuns(mid)
 local runs={}
 for y=0,15 do local x=0
  while x<16 do
   local start=x;local source=P.mask(mid,x,y)and 0x2bb or mid
   repeat x=x+1 until x==16 or(P.mask(mid,x,y)and 0x2bb or mid)~=source
   runs[#runs+1]={x0=start,x1=x,y=y,mid=source}
  end
 end
 return runs
end
function P.build(out,def,ts,x,y,ox,oz,contacts)
 local mid=P.at(def,x,y);if not mid then return false end
 if not V.require('DioramaConfig').billboards.enabled or V.require('Camera').projection()~='perspective'then return false end
 local G=V.require('WorldGeometry');local xx,zz=(x+ox)*16,(y+oz)*16
 for _,r in ipairs(P.floorRuns(mid))do
  G.quad(out,{xx+r.x0,0,zz+r.y},{xx+r.x1,0,zz+r.y},{xx+r.x1,0,zz+r.y+1},{xx+r.x0,0,zz+r.y+1},G.uv(ts,r.mid,r.x0,r.y+.5,r.x1,r.y+.5,0),1)
 end
 if mid==0x212 then
  local luminous=V.require('DioramaConfig').streetLamps.enabled
  if luminous then P.registerGlass(ts)end
  local sprite=V.require('PaperSprite').build(ts,16,32,function(sx,sy)return sy<16 and 0x212 or 0x21a,sx,sy%16 end,
   function(sx,sy,m,px,py)return P.silhouette(m,px,py)end,0,30,1,
   function(sx,sy)return luminous and P.glass(0x212,sx,sy)and 3 or 5 end,nil,.5)
  for _,v in ipairs(sprite)do v[3]=v[3]+30;v[8]=v[8]+30;out[#out+1]=G.place(v,xx,zz)end
  local c=V.require('DioramaConfig').contact
  contacts[#contacts+1]={xx+8,zz+30,3,c.propRadius,c.strength}
 end
 return true
end
local sites=setmetatable({},{__mode='k'})
function P.lights(def,result,px,pz,outdoors)
 local C=V.require('DioramaConfig');local cfg=C.streetLamps
 if not outdoors or not cfg.enabled or not C.lighting.enabled or V.mod.options:get('gen3Lights')==false
  or not C.billboards.enabled or V.require('Camera').projection()~='perspective'
  or(def.id or def.name)~='EM_RUSTBORO_CITY'or def.pair~='general__rustboro'then return end
 local amount=V.require('DayNight').windowLight();if amount<=0 then return end
 local stamp=V.require('WorldGeometry').layoutStamp(def.midLayout)
 local cached=sites[def]
 if not cached or cached.stamp~=stamp then
  cached={stamp=stamp,list={}};sites[def]=cached;local L=def.midLayout
  for y=0,L.height-2 do for x=0,L.width-1 do if P.at(def,x,y)==0x212 then
   cached.list[#cached.list+1]={x=x*16+8,z=y*16+30}
  end end end
 end
 local near={}
 for _,p in ipairs(cached.list)do local d=(p.x-px)^2+(p.z-pz)^2
  if d<cfg.reach^2 then near[#near+1]={p=p,d=d}end
 end
 table.sort(near,function(a,b)if a.d~=b.d then return a.d<b.d end;return a.p.z<b.p.z end)
 for i=1,math.min(cfg.maxVisible,#near)do local p=near[i].p
  result.lights[#result.lights+1]={x=p.x,y=cfg.headHeight*V.require('Billboard').heightScale(),z=p.z,
   radius=-cfg.radius,power=cfg.power*amount,falloff=cfg.falloff,color=cfg.color,kind='streetLamp'}
 end
end
return P
