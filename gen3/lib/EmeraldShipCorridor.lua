-- S.S. Tidal corridor: an open cutaway around the original cabin block.
local V=...
local C={}
function C.profile(d)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if cfg.enabled and cfg.ship.enabled and(d.id or d.name)=='EM_SS_TIDAL_CORRIDOR'
  and d.pair=='general__inside_ship'and L and L.width==18 and L.height==14
  and L:midAt(1,0)==0x2b9 and L:midAt(16,2)==0x2b4 then return cfg.homeRooms.shipCorridor end
end
function C.plan(d)
 local c=V.require('DioramaConfig').emeraldInteriors.ship;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for y=0,13 do for x=0,17 do
  local hole=x>=3 and x<=14 and y>=4 and y<=9
  local door=y==9 and(x==4 or x==7 or x==10 or x==13)
  mask[y*18+x+1]=(x==0 or y<2 or y>=12 or hole and not door)and{mid=0x201,void=true}or 0x2ba
 end end
 for x=1,17 do add('wall',x,0,1,2,{wallHeight=c.wallHeight,wallBase=32,wallLast=32})end
 add('tidalCorridorFront',3,8,12,2)
 add('tidalCorridorBlock',3,3,12,7)
 add('tidalCorridorDown',16,2,2,1)
 mask[2*18+17]={mid=0x201,void=true};mask[2*18+18]={mid=0x201,void=true}
 mask[11*18+2]={mid=0x201,void=true}
 add('tidalCorridorDown',0,11,2,1,{reverse=true})
 return objects,mask
end
function C.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.ship;local G=V.require('WorldGeometry');local start=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(w,h,src,inside,project)
  local vv=V.require('PaperSprite').build(ts,w,h,src,inside,0,h,1,nil,project,.5);for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(m,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)end
 local function wood(s,t)return t<16 and 0x222 or 0x22a,s%16,t%16 end
 local function face(ax,az,bx,bz,h)
  local length=math.sqrt((bx-ax)^2+(bz-az)^2)
  draw(length,32,wood,function()return true end,function(s,t)return{x+ax+(bx-ax)*s/length,h*(32-t)/32,z+az+(bz-az)*s/length}end)
 end
 local function contact(ax,bx,zz)if contacts then for sx=ax+4,bx-3,8 do contacts[#contacts+1]={x+sx,z+zz,5,2,cfg.contactStrength}end end end
 if o.kind=='tidalCorridorFront'then
  -- The thin white eave belongs to the wall cap, not a huge solid ceiling.
  draw(o.w,32,source,function(_,t)return t>=4 end,function(s,t)return{x+s,c.cabinWallHeight*(32-t)/28,z+32}end)
  draw(o.w,4,source,function()return true end,function(s,t)return{x+s,c.cabinWallHeight,z+28+t}end)
  contact(0,o.w,32)
 elseif o.kind=='tidalCorridorBlock'then
  local back=12;local front=112;local h=c.cabinWallHeight
  for _,r in ipairs({{0,4},{o.w-4,o.w}})do
   face(r[1],back,r[1],front,h);face(r[2],front,r[2],back,h)
   patch(0x231,8,8,{x+r[1],h,z+back},{x+r[2],h,z+back},{x+r[2],h,z+front},{x+r[1],h,z+front})
   face(r[1],back,r[2],back,h)
  end
  -- Low north cutaway leaves the upper corridor and all four entrances visible.
  for col=0,11 do if col~=1 and col~=4 and col~=7 and col~=10 then
   local a,b=col*16,(col+1)*16;local ch=c.cabinCutawayHeight
   face(a,16,b,16,ch);face(b,12,a,12,ch)
   patch(0x231,8,8,{x+a,ch,z+12},{x+b,ch,z+12},{x+b,ch,z+16},{x+a,ch,z+16})
   for _,edge in ipairs({a,b})do face(edge,12,edge,16,ch)end
  end end
 elseif o.kind=='tidalCorridorDown'then
  -- Open stairwell; only native metal colors on the treads, no opaque floor
  -- across the hole. Negative surfaces use the existing hanging-face material.
  local drop=o.stairDrop or c.stairDrop;local rail=o.railHeight or c.railHeight
  local dark=G.HANGING_FACADE;local function xx(v)return x+(o.reverse and 32-v or v)end
  for i=0,5 do local a=8+i*4;local b=a+4;local h=-i*drop/5;local bottom=-drop-2
   patch(0x20e,14,10,{xx(a),h,z},{xx(b),h,z},{xx(b),h,z+16},{xx(a),h,z+16},dark)
   patch(0x20e,8,9,{xx(a),h,z+16},{xx(b),h,z+16},{xx(b),bottom,z+16},{xx(a),bottom,z+16},dark)
   patch(0x20e,8,9,{xx(a),h,z},{xx(a),h,z+16},{xx(a),bottom,z+16},{xx(a),bottom,z},dark)
   if o.edgeLine then patch(0x20e,8,9,{xx(a),h+.02,z},{xx(a+1),h+.02,z},{xx(a+1),h+.02,z+16},{xx(a),h+.02,z+16},dark)end
  end
  -- Level rails frame a descending flight and do not drag wall pixels with them.
  for _,zz in ipairs(o.noRear and{16}or{0,16})do
   for s=8,28,5 do
    patch(0x20e,7,9,{xx(s),rail,z+zz},{xx(s+2),rail,z+zz},{xx(s+2),0,z+zz},{xx(s),0,z+zz})
   end
   patch(0x20e,14,10,{xx(8),rail,z+zz},{xx(32),rail,z+zz},{xx(32),rail-2,z+zz},{xx(8),rail-2,z+zz})
  end
  -- Native carpet on the eight-pixel landing, still at the original floor level.
  draw(8,16,function(s,t)return o.floor or 0x2ba,s,t end,function()return true end,function(s,t)return{xx(s),0,z+t}end)
 end
 for i=start,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return C
