-- Measured native city fences, separated from their baked ground.
-- X marks the exact blue/grey fence or baked-shadow texels in the native atlas.
-- Only rows 0..12 stand up; the native shadow below is replaced by clean floor.
local V=...
local F={}
local masks={
 [0x252]={'XXXXXXXXXXXXXX..','XXXXXXXXXXXXXX..','X..X..X....XXX..','X..X..X....XXX..','X..XXXX....XXX..','X..X..X....XXX..','X..X..X....XXX..','X..X..X....XXX..','X..X..X....XXX..','X..X..X....XXX..','X..X..X....XXX..','XXXXXXXXXXXXXX..','XXXXXXXXXXXXXX..','X..........XXX..','XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX'},
 [0x258]={'..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........'},
 [0x25a]={'...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..'},
 [0x2fc]={'XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX','XX...XX....XX...','XX..XXXX..XXXX..','XX..X..X..X..X..','XX..X..X..X..X..','XX..X..X..X..X..','XX..X..X..X..X..','XX..XXXX..XXXX..','XX...XX....XX...','XX...XX....XX...','XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX','XX..............','XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX'},
 [0x320]={'..........XXXXXX','..........XXXXXX','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXXXXX','..........XXXXXX','..........XXX...','..........XXXXXX','..........XXXXXX'},
 [0x2bf]={'XXXXXXXXXXXXX...','XXXXXXXXXXXXXX..','XX...XX....XXX..','XX..XXXX...XXX..','XX..X..X...XXX..','XX..X..X...XXX..','XX..X..X...XXX..','XX..X..X...XXX..','XX..XXXX...XXX..','XX...XX....XXX..','XX...XX....XXX..','XXXXXXXXXXXXXX..','XXXXXXXXXXXXXX..','XX.........XXX..','XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX'},
 [0x2be]={'...XXXXXXXXXXXXX','..XXXXXXXXXXXXXX','..XXX......XX...','..XXX.....XXXX..','..XXX.....X..X..','..XXX.....X..X..','..XXX.....X..X..','..XXX.....X..X..','..XXX.....XXXX..','..XXX......XX...','..XXX......XX...','..XXXXXXXXXXXXXX','..XXXXXXXXXXXXXX','..XXX...........','..XXXXXXXXXXXXXX','..XXXXXXXXXXXXXX'},
 [0x32c]={'XXXXX...........','XXXXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','XXXXX...........','XXXXX...........','..XXX...........','XXXXXXX.........','XXXXXXX.........'},
 [0x321]={'XXXXXX..........','XXXXXX..........','...XXX..........','...XXX..........','...XXX..........','...XXX..........','...XXX..........','...XXX..........','...XXX..........','...XXX..........','...XXX..........','XXXXXX..........','XXXXXX..........','...XXX..........','XXXXXXXX........','XXXXXXXX........'},
 [0x318]={'..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...','..........XXX...'},
 [0x31d]={'...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..'},
 [0x315]={'..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........'},
 [0x2df]={'...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..','...........XXX..'},
 [0x2de]={'..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........','..XXX...........'},
 [0x2e7]={'XXXXXXXXXXXXXX..','XXXXXXXXXXXXXX..','XX...XX....XXX..','XX..XXXX...XXX..','XX..X..X...XXX..','XX..X..X...XXX..','XX..X..X...XXX..','XX..X..X...XXX..','XX..XXXX...XXX..','XX...XX....XXX..','XX...XX....XXX..','XXXXXXXXXXXXXX..','XXXXXXXXXXXXXX..','XX.........XXX..','XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX'},
 [0x2e6]={'..XXXXXXXXXXXXXX','..XXXXXXXXXXXXXX','..XXX......XX...','..XXX.....XXXX..','..XXX.....X..X..','..XXX.....X..X..','..XXX.....X..X..','..XXX.....X..X..','..XXX.....XXXX..','..XXX......XX...','..XXX......XX...','..XXXXXXXXXXXXXX','..XXXXXXXXXXXXXX','..XXX...........','..XXXXXXXXXXXXXX','..XXXXXXXXXXXXXX'},
 [0x2b7]={'XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX','XX...XX....XX...','XX..XXXX..XXXX..','XX..X..X..X..X..','XX..X..X..X..X..','XX..X..X..X..X..','XX..X..X..X..X..','XX..XXXX..XXXX..','XX...XX....XX...','XX...XX....XX...','XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX','XX..............','XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX'},
 [0x2d7]={'XXXXXXXXXXXXX...','XXXXXXXXXXXXXX..','XX...XX....XXX..','XX..XXXX...XXX..','XX..X..X...XXX..','XX..X..X...XXX..','XX..X..X...XXX..','XX..X..X...XXX..','XX..XXXX...XXX..','XX...XX....XXX..','XX...XX....XXX..','XXXXXXXXXXXXXX..','XXXXXXXXXXXXXX..','XX.........XXX..','XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX'},
 [0x337]={'..XXXXXXXXXXXXXX','..XXXXXXXXXXXXXX','..XXX......XX...','..XXX.....XXXX..','..XXX.....X..X..','..XXX.....X..X..','..XXX.....X..X..','..XXX.....X..X..','..XXX.....XXXX..','..XXX......XX...','..XXX......XX...','..XXXXXXXXXXXXXX','..XXXXXXXXXX...X','..XXX...........','..XXXXXXX.......','..XXXXXX........'},
 [0x33e]={'XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX','XX...XX....XX...','XX..XXXX..XXXX..','XX..X..X..X..X..','XX..X..X..X..X..','XX..X..X..X..X..','XX..X..X..X..X..','XX..XXXX..XXXX..','XX...XX....XX...','XX...XX....XX...','XXXXXXXXXXXXXXXX','XXXXXXXXXXXX...X','XX..............','XXXXXXXXX.......','XXXXXXXX........'},
 [0x33f]={'XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX','XX...XX....XX...','XX..XXXX..XXXX..','XX..X..X..X..X..','XX..X..X..X..X..','XX..X..X..X..X..','XX..X..X..X..X..','XX..XXXX..XXXX..','XX...XX....XX...','XX...XX....XX...','XXXXXXXXXXXXXXXX','X...XXXXXXXXXXXX','................','.......XXXXXXXXX','........XXXXXXXX'},
 [0x250]={'..XXXXXXXXXXXXXX','..XXXXXXXXXXXXXX','..XXX....X..X..X','..XXX....X..X..X','..XXX....XXXX..X','..XXX....X..X..X','..XXX....X..X..X','..XXX....X..X..X','..XXX....X..X..X','..XXX....X..X..X','..XXX....X..X..X','..XXXXXXXXXXXXXX','..XXXXXXXXXXXXXX','..XXX..........X','..XXXXXXXXXXXXXX','..XXXXXXXXXXXXXX'},
 [0x251]={'XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX','X..X..X..X..X..X','X..X..X..X..X..X','X..XXXX..XXXX..X','X..X..X..X..X..X','X..X..X..X..X..X','X..X..X..X..X..X','X..X..X..X..X..X','X..X..X..X..X..X','X..X..X..X..X..X','XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX','X..............X','XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX'},
}
local rustboro={
 [0x2fc]={0,16,0,0,0,699},
 [0x320]={12,16,12,0,13,699},
 [0x2bf]={0,13,12,13,16,699},
 [0x2be]={3,16,3,13,16,699},
 [0x32c]={0,4,3,0,13,699},
 [0x321]={0,4,3,0,13,699},
 [0x318]={0,0,11,0,16,699},
 [0x31d]={0,0,12,0,16,699},
 [0x315]={0,0,3,0,16,699},
 [0x2df]={0,0,12,0,16,1},
 [0x2de]={0,0,3,0,16,1},
 [0x2e7]={0,13,12,0,13,1},
 [0x2e6]={3,16,3,0,13,1},
 [0x2b7]={0,16,0,0,0,1},
 [0x2d7]={0,13,12,13,16,1},
 [0x337]={3,16,3,13,16,1},
 [0x33e]={0,16,0,0,0,1},
 [0x33f]={0,16,0,0,0,1},
}
function F.at(def,x,y)
 local id=def.id or def.name;local mid
 if id=='EM_LILYCOVE_CITY'and def.pair=='general__lilycove'then
  mid=def.midLayout:midAt(x,y)
  if mid==0x250 or mid==0x251 or mid==0x252 or mid==0x258 or mid==0x25a then return mid end
 elseif id=='EM_RUSTBORO_CITY'and def.pair=='general__rustboro' then
  mid=def.midLayout:midAt(x,y);if rustboro[mid]then return mid end
 end
end
function F.mask(mid,x,y)return masks[mid]and masks[mid][y+1]:sub(x+1,x+1)=='X'end
function F.ground(def,mid)return def.pair=='general__lilycove'and 1 or rustboro[mid][6]end
function F.floorRuns(def,mid)
 local donor=F.ground(def,mid);local runs={}
 for y=0,15 do
  local x=0
  while x<16 do
   local start=x;local source=F.mask(mid,x,y)and donor or mid
   repeat x=x+1 until x==16 or (F.mask(mid,x,y)and donor or mid)~=source
   runs[#runs+1]={x0=start,x1=x,y=y,mid=source}
  end
 end
 return runs
end
function F.build(out,def,ts,x,y,ox,oz,contacts)
 local mid=F.at(def,x,y);if not mid then return false end
 if not V.require('DioramaConfig').billboards.enabled or V.require('Camera').projection()~='perspective'then return false end
 local G=V.require('WorldGeometry');local B=V.require('Billboard')
 local xx,zz=(x+ox)*16,(y+oz)*16
 local lily=def.pair=='general__lilycove'
 local p=rustboro[mid];local rail=lily and 0x251 or 0x2fc
 if lily then
  if mid==0x258 then p={0,0,3,0,16,1}
  elseif mid==0x25a then p={0,0,12,0,16,1}
  elseif mid==0x250 then p={2,16,3,0,def.midLayout:midAt(x,y-1)==0x258 and 13 or 0,1}
  elseif mid==0x252 then p={0,14,12,0,def.midLayout:midAt(x,y-1)==0x25a and 13 or 0,1}
  else p={0,16,0,0,0,1}end
 end
 -- Preserve all visible native ground/edge/leaf pixels. Only replace metal
 -- and baked shadow; donors are the native lawn or the city's stone paving.
 for _,r in ipairs(F.floorRuns(def,mid))do
  G.quad(out,{xx+r.x0,0,zz+r.y},{xx+r.x1,0,zz+r.y},{xx+r.x1,0,zz+r.y+1},{xx+r.x0,0,zz+r.y+1},G.uv(ts,r.mid,r.x0,r.y+.5,r.x1,r.y+.5,0),1)
 end
 if p[2]>p[1]then
  local fence=V.require('PaperSprite').build(ts,16,13,function(sx,sy)return mid,sx,sy end,
   function(sx,sy)return sx>=p[1]and sx<p[2]and F.mask(mid,sx,sy)end,0,13,1,function()return 5 end,nil,.5)
  for _,v in ipairs(fence)do v[3]=v[3]+13;v[8]=v[8]+13;out[#out+1]=G.place(v,xx,zz)end
  local c=V.require('DioramaConfig').contact
  contacts[#contacts+1]={xx+(p[1]+p[2])/2,zz+13,(p[2]-p[1])/2,c.propRadius,c.strength}
 end
 if p[5]>p[4]then
  -- Native N/S rails are drawn edge-on. Continue the same railing as a real
  -- side plane along Z, with its foot at the native edge (not a yawed card).
  local function point(sx,sy)
   return {p[3],(13-sy)*B.heightScale(),p[4]+sx/16*(p[5]-p[4]),0,0,0}
  end
  local side=V.require('PaperSprite').build(ts,16,13,function(sx,sy)return rail,sx,sy end,
   function(sx,sy)return F.mask(rail,sx,sy)end,0,13,1,function()return 5 end,point,.5)
  for _,v in ipairs(side)do out[#out+1]=G.place(v,xx,zz)end
  -- A plane viewed along Z becomes subpixel-thin. The native three-pixel
  -- edge has real thickness: cap its top/bottom rails and supporting posts,
  -- sampling only the original steel/outline colours (no dark filler wall).
  local h=13*B.heightScale();local cx=xx+p[3]
  local function bar(y0,y1,z0,z1)
   local a,b=cx-.6,cx+.6
   local light=G.uv(ts,rail,0,0,1,1,.5)
   local dark=G.uv(ts,rail,0,1,1,2,.5)
   G.quad(out,{a,y1,z0},{b,y1,z0},{b,y1,z1},{a,y1,z1},light,5)
   G.quad(out,{a,y0,z0},{a,y1,z0},{a,y1,z1},{a,y0,z1},dark,5)
   G.quad(out,{b,y0,z1},{b,y1,z1},{b,y1,z0},{b,y0,z0},dark,5)
  end
  bar(h-1.3,h,zz+p[4],zz+p[5])
  bar(0,1.3,zz+p[4],zz+p[5])
  for z=p[4],p[5]-.01,4 do bar(0,h,zz+z,zz+math.min(p[5],z+.8))end
 end
 return true
end
return F
