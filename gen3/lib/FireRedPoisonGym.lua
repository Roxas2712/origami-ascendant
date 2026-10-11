-- Fuchsia dojo: native invisible maze texels/collision remain engine-owned.
-- Only the rear shell, pillars, statues and leader's dais gain volume.
local V=...;local R={}
local function cfg()return V.require('DioramaConfig').interiors.fireredPoisonGym end
function R.profile(d)
 local L=d and d.midLayout
 return cfg().enabled and d and d.id=='FR_FUCHSIA_CITY_GYM'and (d.renderPair or d.pair)=='building__rom_082d4ca4'and d.mapType==8 and L and L.width==16 and L.height==24 and L:midAt(7,0)==0x29f and L:midAt(7,13)==0x28c or nil
end
function R.plan(d)
 if not R.profile(d)then return end
 local objects,mask={},{}
 for i=1,384 do mask[i]={mid=8,void=true,separateSurface=true}end
 local function add(kind,x,y,w,h)objects[#objects+1]={kind=kind,x=x,y=y,w=w,h=h}end
 add('poisonFloor',0,32,240,336);add('poisonWall',0,0,240,32)
 for _,x in ipairs{0,48,176,224}do add('poisonPillar',x,5,16,31)end
 for _,x in ipairs{64,160}do add('poisonStatue',x,288,16,32)end
 add('poisonDais',96,192,48,48)
 return{objects=objects,mask=mask,owners={}}
end
function R.pillarInside(s,t)
 local y=t+5;local a,b
 if y<=8 then a,b=3,14 elseif y<=26 then a,b=4,12 elseif y<=33 then a,b=3,13 elseif y==34 then a,b=5,11 elseif y==35 then a,b=7,9 end
 return a and s>=a and s<b or false
end
-- Pixel contour of the native rounded 48 px dais, excluding floor/shadow.
function R.daisInside(s,t)
 if s<0 or s>=48 or t<0 or t>=48 then return false end
 local inset
 if t==3 or t==45 then inset=7 elseif t==4 or t==44 then inset=6 elseif t==5 or t==43 then inset=5 elseif t==6 or t==42 then inset=4 elseif t==7 or t==41 then inset=3 elseif t>=8 and t<=40 then inset=2 end
 return inset and s>=inset and s<48-inset or false
end
function R.actorOffset(d,x,z)
 if R.profile(d)and R.daisInside(math.floor(x+8-96),math.floor(z+16-192))then return cfg().daisHeight,0 end
end
function R.build(out,objects,L,ts,ox,oz,contacts)
 local c=cfg();local G,P=V.require('WorldGeometry'),V.require('PaperSprite');local hs=V.require('Billboard').heightScale()
 local function src(x,z)return L:midAt(math.floor(x/16),math.floor(z/16)),x%16,z%16 end
 local function draw(w,h,source,inside,project,shade)
  local vv=P.build(ts,w,h,source,inside or function()return true end,0,h,1,shade and function()return shade end or nil,project,.5)
  for _,v in ipairs(vv)do v[1]=v[1]+ox*16;v[3]=v[3]+oz*16;out[#out+1]=v end
 end
 local function pillarColumn(x)for _,left in ipairs{0,48,176,224}do if x>=left and x<left+16 then return true end end;return false end
 local function floorSource(x,z)
  if z<48 and pillarColumn(x)then return 0x289,x%16,z%16 end
  if z>=288 and z<320 and(x>=64 and x<80 or x>=160 and x<176)then return 0x281,x%16,z%16 end
  if R.daisInside(x-96,z-192)then return 0x281,x%16,z%16 end
  return src(x,z)
 end
 for _,o in ipairs(objects)do local first=#out+1
  local function source(s,t)return src(o.x+s,o.y+t)end
  if o.kind=='poisonFloor'then
   draw(o.w,o.h,function(s,t)return floorSource(o.x+s,o.y+t)end,function(s,t)
    local x,z=o.x+s,o.y+t
    if L:midAt(math.floor(x/16),math.floor(z/16))==8 then return false end
    -- The exit tiles include native black void around the small stair lip;
    -- it must stay transparent rather than become a black rectangular pad.
    if z>=352 then local r,g,b=V.require('BuildingMesh').pixel(ts,src(x,z));return r+g+b>0 end
    return true
   end,function(s,t)return{o.x+s,0,o.y+t}end)
  elseif o.kind=='poisonWall'then
   local height=c.wallHeight*hs
   local function wall(s,t)if t>=5 and pillarColumn(s)then return src(64,t)end;return source(s,t)end
   draw(240,32,wall,nil,function(s,t)return{s,height*(32-t)/32,32}end)
   draw(240,c.wallDepth,function(s)return wall(s,0)end,nil,function(s,t)return{s,height,32-c.wallDepth+t}end)
   for _,edge in ipairs{0,240}do draw(c.wallDepth,32,function(_,t)return wall(math.min(239,edge),t)end,nil,function(s,t)return{edge,height*(32-t)/32,32-c.wallDepth+s}end,c.sideShade)end
  elseif o.kind=='poisonDais'then
   draw(48,48,source,R.daisInside,function(s,t)return{o.x+s,c.daisHeight,o.y+t}end)
   -- Close every exposed edge with its native grey border, never a black box.
   for t=0,47 do for s=0,47 do if R.daisInside(s,t)then
    local m,u,v=source(s,t);local uv=G.uv(ts,m,u,v,u+1,v+1,.5)
    for _,a in ipairs{{-1,0,0,0,0,1},{1,0,1,0,1,1},{0,-1,0,0,1,0},{0,1,0,1,1,1}}do if not R.daisInside(s+a[1],t+a[2])then
     local x,z=o.x+s+ox*16,o.y+t+oz*16
     G.quad(out,{x+a[3],c.daisHeight,z+a[4]},{x+a[5],c.daisHeight,z+a[6]},{x+a[5],0,z+a[6]},{x+a[3],0,z+a[4]},uv,c.sideShade)
    end end
   end end end
   contacts[#contacts+1]={o.x+24+ox*16,o.y+41+oz*16,20,3,c.contactStrength}
  else
   local pillar=o.kind=='poisonPillar';local height=(pillar and c.pillarHeight or c.statueHeight)*hs;local base=o.y+o.h
   draw(o.w,o.h,source,pillar and R.pillarInside or function(s,t)return V.require('FireRedGymRooms').inside({kind='gymStatue',w=16,h=32},s,t)end,function(s,t)return{o.x+s,height*(o.h-t)/o.h,base}end)
   contacts[#contacts+1]={o.x+8+ox*16,base+oz*16,6,c.contactRadius,c.contactStrength}
  end
  V.require('RoomLightRig').capture(L,{kind=o.kind=='poisonWall'and 'wall'or 'plant'},out,first,#out)
 end
end
function R.lighting(d)if R.profile(d)then return cfg().light end end
return R
