-- Measured S.S. Tidal surfaces. Only render geometry changes, never travel data.
local V=...
local S={}
function S.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.ship.enabled and(d.id or d.name)=='EM_SS_TIDAL_LOWER_DECK'
  and d.pair=='general__inside_ship'and L and L.width==18 and L.height==14
  and L:midAt(0,0)==0x2a9 and L:midAt(16,2)==0x216 then return c.homeRooms.shipCargo end
end
local crates={{2,1,2,3},{6,1,2,3},{10,1,3,3},{1,5,3,3},{4,5,3,3},{8,5,2,3},{11,5,3,3},{1,10,3,3},{4,10,3,3},{8,10,2,2},{11,10,2,2},{15,9,2,4}}
function S.plan(d)
 local c=V.require('DioramaConfig').emeraldInteriors.ship;local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,extra)local o=extra or{};o.kind=kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o;return o end
 for y=0,13 do for x=0,17 do
  mask[y*18+x+1]=(x==17 or y==13 or y<2)and{mid=0x201,void=true}or 0x20d
 end end
 for x=0,16 do add('wall',x,0,1,2,{wallHeight=c.wallHeight,wallBase=32,wallLast=32,clean={0x2a9,0x2b1},nativeUpper=true})end
 -- Clear the stair railing from its source wall; the metal railing is separate.
 objects[17].nativeUpper=nil
 for _,r in ipairs(crates)do add('tidalCrate',r[1],r[2],r[3],r[4])end
 for _,r in ipairs({{0,2},{9,2},{0,12}})do add('tidalBin',r[1],r[2],1,1)end
 add('tidalStairs',15,0,2,3)
 return objects,mask
end
function S.binInside(s,t)
 local widths={4,6,8,10,12,12,12,12,12,12,12,12,10,8,6}
 local w=widths[t+1];return w and s>=(16-w)/2 and s<(16+w)/2 or false
end
function S.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.ship;local G=V.require('WorldGeometry');local first=#out+1
 local function src(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function band(a,b,project,inside,source)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,source or src,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,nil,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function patch(mid,u,v,a,b,d,e,shade)G.quad(out,a,b,d,e,G.uv(ts,mid,u,v,u+1,v+1,.5),shade or 1)end
 local function contact(w,zz)if contacts then for s=4,w-3,8 do contacts[#contacts+1]={x+s,z+zz,5,2,cfg.contactStrength}end end end
 if o.kind=='tidalCrate'then
  local split=o.h-16;local front=o.h-1;local back=front-split;local h=c.crateHeight
  band(0,split,function(s,t)return{x+s,h,z+back+t}end)
  band(split,o.h-1,function(s,t)return{x+s,h*(o.h-1-t)/15,z+front}end)
  -- The native front boards also texture the sides, row for row. No stretched
  -- floor/shadow strips and no black filler walls around the boxes.
  for t=0,14 do local yy=h*(15-t)/15;local low=h*(14-t)/15
   for _,s in ipairs({0,o.w})do local m,u,v=src(s==0 and 1 or o.w-2,split+t)
    patch(m,u,v,{x+s,yy,z+back},{x+s,yy,z+front},{x+s,low,z+front},{x+s,low,z+back},.96)
   end
   local m,u,v=src(2,split+t)
   patch(m,u,v,{x,yy,z+back},{x+o.w,yy,z+back},{x+o.w,low,z+back},{x,low,z+back},.96)
  end
  contact(o.w,front)
 elseif o.kind=='tidalBin'then
  band(0,15,function(s,t)return{x+s,c.binHeight*(15-t)/15,z+15}end,S.binInside);contact(16,15)
 elseif o.kind=='tidalStairs'then
  -- Sideways flight: original grey treads and navy rail pixels; walk/warp
  -- coordinates stay native. Each tread is closed down to the deck.
  for i=0,3 do
   local a=11+i*5;local b=math.min(32,a+5);local h=(i+1)*c.stepHeight;local m,u,v=src(25,32)
   patch(m,u,v,{x+a,h,z+32},{x+b,h,z+32},{x+b,h,z+48},{x+a,h,z+48})
   local rm,ru,rv=src(23,36)
   patch(rm,ru,rv,{x+a,h,z+48},{x+b,h,z+48},{x+b,0,z+48},{x+a,0,z+48},.96)
   patch(rm,ru,rv,{x+a,h,z+32},{x+a,h,z+48},{x+a,0,z+48},{x+a,0,z+32},.96)
  end
  -- Rebuild the narrow metal rail from its own native grey/navy texels.
  -- The original inter-post pixels contain wall plaster and floor shadows;
  -- none of those background pixels belong on this freestanding railing.
  local grey,gu,gv=src(12,33);local navy,nu,nv=src(23,36)
  for _,zz in ipairs({32,48})do
   for i=0,3 do local a=12+i*6;local h=(i+1)*c.stepHeight
    patch(navy,nu,nv,{x+a-1,h+c.railHeight,z+zz},{x+a+3,h+c.railHeight,z+zz},{x+a+3,h,z+zz},{x+a-1,h,z+zz})
    patch(grey,gu,gv,{x+a,h+c.railHeight-1,z+zz+.02},{x+a+2,h+c.railHeight-1,z+zz+.02},{x+a+2,h+1,z+zz+.02},{x+a,h+1,z+zz+.02})
   end
   local left=c.stepHeight+c.railHeight;local right=4*c.stepHeight+c.railHeight
   patch(navy,nu,nv,{x+11,left+1,z+zz+.04},{x+33,right+1,z+zz+.04},{x+33,right-2,z+zz+.04},{x+11,left-2,z+zz+.04})
   patch(grey,gu,gv,{x+11,left,z+zz+.05},{x+33,right,z+zz+.05},{x+33,right-1,z+zz+.05},{x+11,left-1,z+zz+.05})
  end
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return S
