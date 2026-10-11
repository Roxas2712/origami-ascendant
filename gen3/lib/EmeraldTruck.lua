-- Native moving-van interior. Moving boxes remain engine-owned actors.
local V=...
local T={}
-- Pixel bounds in the original 80x72 cargo image: x,y,width,height,top rows.
local crates={{1,4,14,10,4},{17,9,14,10,4},{1,25,14,10,4},{1,36,14,10,4},
 {1,49,14,13,4},{33,41,14,10,4},{33,52,14,10,4},{17,57,14,10,4},{49,57,14,10,4}}
function T.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d.midLayout
 if c.enabled and c.truck.enabled and(d.id or d.name)=='EM_INSIDE_OF_TRUCK'and d.mapType==8
  and d.pair=='general__inside_of_truck'and L and L.width==6 and L.height==6
  and L:midAt(0,0)==0x201 then return c.homeRooms.truck end
end
function T.lighting(d)
 if T.profile(d)then local c=V.require('DioramaConfig').emeraldInteriors.truck
  return d.midLayout:midAt(4,2)==0x210 and c.openLight or c.closedLight
 end
end
function T.cameraOffset(d)
 if not T.profile(d)then return 0,0 end
 local f=require('src.core.game3.field_view')
 return f and f.cameraPanX or 0,(f and f.cameraPanY or 0)/math.sin(V.require('Camera').elevation())
end
function T.plan(d)
 if not T.profile(d)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.truck
 local objects={{kind='truckFloor',x=0,y=0,w=80,h=72,noContact=true}};local mask={}
 for k=1,36 do mask[k]={mid=0x206,void=true}end
 local function add(r,height,depth)
  objects[#objects+1]={kind='truckCargo',x=r[1]/16,y=r[2]/16,w=r[3],h=r[4],split=r[5],height=height,depth=depth,noContact=true}
 end
 for _,r in ipairs(crates)do add(r,c.boxHeight,c.boxDepth)end
 add({32,0,32,23,12},c.cabinetHeight,c.cabinetDepth)
 add({16,40,16,16,12},c.lowCaseHeight,c.cabinetDepth)
 return objects,mask
end
function T.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.truck;local G=V.require('WorldGeometry')
 local function src(s,t)return L:midAt(math.floor(s/16),math.floor(t/16)),s%16,t%16 end
 if o.kind=='truckFloor'then
  local occupied={}
  local function erase(a,b,w,h)for yy=b,b+h-1 do for xx=a,a+w-1 do occupied[yy*80+xx]=true end end end
  for _,r in ipairs(crates)do erase(r[1],r[2],r[3],r[4])end;erase(32,0,32,23);erase(16,40,16,16)
  local vv=V.require('PaperSprite').build(ts,80,72,function(s,t)
   if occupied[t*80+s]then return 0x214,s%16,t%16 end
   return src(s,t)
  end,function()return true end,0,72,1,nil,function(s,t)return{x+s,0,z+t}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 else
  local h=o.height*cfg.heightScale;local front=z+o.h;local back=front-o.depth
  local function pixel(s,t,a,b,d,e,shade)
   local m,u,v=src(o.x*16+s,o.y*16+t);G.quad(out,a,b,d,e,G.uv(ts,m,u,v,u+1,v+1,.5),shade or 1)
  end
  for t=0,o.h-1 do for s=0,o.w-1 do
   if t<o.split then
    local a=back+t*o.depth/o.split;local b=back+(t+1)*o.depth/o.split
    pixel(s,t,{x+s,h,a},{x+s+1,h,a},{x+s+1,h,b},{x+s,h,b})
   else
    local hi=h*(o.h-t)/(o.h-o.split);local lo=h*(o.h-t-1)/(o.h-o.split)
    pixel(s,t,{x+s,hi,front},{x+s+1,hi,front},{x+s+1,lo,front},{x+s,lo,front})
    if s==0 then pixel(s,t,{x,hi,back},{x,hi,front},{x,lo,front},{x,lo,back},c.sideShade)end
    if s==o.w-1 then pixel(s,t,{x+o.w,hi,front},{x+o.w,hi,back},{x+o.w,lo,back},{x+o.w,lo,front},c.sideShade)end
   end
  end end
  if contacts then contacts[#contacts+1]={x+o.w/2,front-1,o.w/2,2,c.contactStrength}end
 end
end
return T
