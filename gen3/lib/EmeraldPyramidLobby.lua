-- Native Pyramid reception: separate fixtures, stepped podium and rear wall.
local V=...
local R={}
function R.kind(d)return d and(d.id or d.name)=='EM_BATTLE_FRONTIER_BATTLE_PYRAMID_LOBBY'end
function R.profile(d)
 local c=V.require('DioramaConfig').emeraldInteriors;local L=d and d.midLayout
 if R.kind(d)and c.enabled and c.pyramidLobby.enabled and d.pair=='building__battle_pyramid'and L and L.width==16 and L.height==18 and L:midAt(7,17)==0x2c4 and L:midAt(7,8)==0x224 then return c.homeRooms.pyramidLobby end
end
function R.surfaceHeight(x,z)
 local c=V.require('DioramaConfig').emeraldInteriors.pyramidLobby
 if z<=128 or (x<48 or x>=192)and z<=160 then return c.platformHeight end
 if x>=96 and x<144 and z<208 then return math.max(0,math.ceil((208-z)/c.treadDepth))*c.platformHeight*c.treadDepth/80 end
 return 0
end
function R.actorHeight(d,x,z)
 if R.profile(d)then return R.surfaceHeight(x+8,z+16)*V.require('DioramaConfig').emeraldInteriors.heightScale end
end
function R.statueInside(s,t)
 if t<1 or t>=46 then return false end
 if t==1 then return s==5 or s==10 end
 if t==2 then return s>=4 and s<=6 or s>=9 and s<=11 end
 local inset=t<4 and 4 or t<22 and 3 or t==22 and 4 or t<25 and 5 or (t==26 or t==28 or t==45)and 1 or 2
 return s>=inset and s<16-inset
end
function R.wallSource(L,s,t)
 local xx,yy=math.floor(s/16),math.floor(t/16);local m=L:midAt(xx,yy)
 if xx==2 or xx==12 or (xx==3 or xx==5 or xx==9 or xx==11)and yy>=2 then m=({0x203,0x204,0x205,0x206,0x201})[yy+1]end
 -- Keep the native blue entrance and its two white jambs intact.
 if yy==4 and(xx<6 or xx>8)then m=0x201 end
 return m,s%16,t%16
end
function R.plan(d)
 if not R.profile(d)then return end
 local L=d.midLayout;local objects,mask={},{}
 local function add(kind,x,y,w,h,e)local o=e or{};o.kind='pyl'..kind;o.x=x;o.y=y;o.w=w*16;o.h=h*16;o.noContact=true;objects[#objects+1]=o
  for yy=y,y+h-1 do for xx=x,x+w-1 do mask[yy*16+xx+1]={mid=1,void=true}end end
 end
 for y=0,17 do mask[y*16+16]={mid=1,void=true}end
 add('Wall',0,0,15,5)
 add('Platform',0,5,15,3);add('Platform',0,8,3,2);add('Platform',12,8,3,2)
 for _,a in ipairs({{3,8,3,5},{9,8,3,5},{0,10,3,3},{12,10,3,3}})do add('Face',unpack(a))end
 add('Stairs',6,8,3,5)
 for _,x in ipairs({2,12})do add('Column',x,0,1,7)end
 for _,x in ipairs({3,5,9,11})do add('Statue',x,2,1,3)end
 for _,x in ipairs({4,10})do add('Torch',x,4,1,2)end
 add('Device',0,11,3,3,{shape='display',first=17,last=40})
 add('Device',5,11,1,3,{shape='monitor',first=12,last=40})
 add('Device',13,11,1,3,{shape='pc',first=8,last=40})
 return objects,mask
end
function R.build(out,L,ts,o,x,z,contacts)
 local cfg=V.require('DioramaConfig').emeraldInteriors;local c=cfg.pyramidLobby;local G=V.require('WorldGeometry');local first=#out+1
 local function source(s,t)return L:midAt(o.x+math.floor(s/16),o.y+math.floor(t/16)),s%16,t%16 end
 local function draw(a,b,inside,project,src,shade)
  local vv=V.require('PaperSprite').build(ts,o.w,o.h,src or source,function(s,t)return t>=a and t<b and(not inside or inside(s,t))end,0,o.h,1,shade and function()return shade end,project,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 local function contact(a,b,zz)if contacts then for xx=a+4,b-3,8 do contacts[#contacts+1]={x+xx,z+zz,5,2,c.contactStrength}end end end
 local function fixtureAt(xx,yy)
  if xx<48 and yy>=176 then return 'display',xx,yy-176 end
  if xx>=80 and xx<96 and yy>=176 then return 'monitor',xx-80,yy-176 end
  if xx>=208 and xx<224 and yy>=176 then return 'pc',xx-208,yy-176 end
 end
 local function clean(s,t)
  local xx,yy=x+s,z+t;local shape,u,v=fixtureAt(xx,yy)
  if shape and V.require('EmeraldBattlePike').deviceInside(shape,u,v)then
   if yy>=208 then return 0x20b,s%16,t%16 end
   if xx>=48 and xx<192 then return yy>=192 and 0x21b or 0x201,s%16,t%16 end
   return math.floor(yy/16)%2==0 and 0x205 or 0x206,s%16,t%16
  end
  return source(s,t)
 end
 if o.kind=='pylWall'then
  draw(0,80,nil,function(s,t)return{x+s,c.platformHeight+c.wallHeight*(80-t)/80,79.5}end,function(s,t)
   return R.wallSource(L,s,t)
  end)
 elseif o.kind=='pylPlatform'then
  draw(0,o.h,nil,function(s,t)return{x+s,c.platformHeight,z+t}end,function(s,t)
   local m,u,v=source(s,t)
   if m==0x216 or m==0x219 or m==0x231 or m==0x21a then m=0x20b end
   return m,u,v
  end)
 elseif o.kind=='pylFace'then
  -- The decorative native cap is one lip at the front, not repeated rows
  -- across the entire upper surface. Stone behind it continues the landing.
  local lip=c.faceLipDepth
  draw(0,o.h-lip,nil,function(s,t)return{x+s,c.platformHeight,z+t}end,function(s,t)return 0x20b,s%16,t%16 end)
  draw(0,16,nil,function(s,t)return{x+s,c.platformHeight,z+o.h-lip+t*lip/16}end)
  draw(16,o.h,nil,function(s,t)return{x+s,c.platformHeight*(o.h-t)/(o.h-16),z+o.h}end,clean);contact(0,o.w,o.h)
  -- Close the exposed sides along the descending staircase. Each wall strip
  -- meets the actual tread height; no shadow mesh is used to plug the gap.
  if o.x==3 or o.x==9 then
   local xx=o.x==3 and x+o.w or x
   for start=0,80-c.treadDepth,c.treadDepth do
    local bottom=c.platformHeight*(80-start)/80
    if bottom<c.platformHeight then
     G.quad(out,{xx,c.platformHeight,z+start},{xx,c.platformHeight,z+start+c.treadDepth},
      {xx,bottom,z+start+c.treadDepth},{xx,bottom,z+start},G.uv(ts,0x201,8,8,9,9,.5),c.sideShade)
    end
   end
  end
 elseif o.kind=='pylStairs'then
  local step=c.treadDepth
  for start=0,80-step,step do
   local h=c.platformHeight*(80-start)/80;local nextH=c.platformHeight*(80-step-start)/80
   draw(start,start+step,nil,function(s,t)return{x+s,h,z+t}end)
   draw(start+step-1,start+step,nil,function(s,t)return{x+s,h+(nextH-h)*(t-start-step+1),z+start+step}end,nil,c.treadShade)
  end
 elseif o.kind=='pylColumn'then
  draw(0,112,nil,function(s,t)return{x+s,c.platformHeight+c.columnHeight*(112-t)/112,z+112}end)
 elseif o.kind=='pylStatue'then
  draw(0,48,R.statueInside,function(s,t)return{x+s,c.platformHeight+c.statueHeight*(46-t)/46,z+48}end)
 elseif o.kind=='pylTorch'then
  draw(12,32,function(s,t)
   local m,u,v=source(s,t);local r,g,b=V.require('BuildingMesh').pixel(ts,m,u,v)
   if t>=16 then return not(math.abs(r-49/255)<.002 and math.abs(g-49/255)<.002 and math.abs(b-132/255)<.002)end
   return r>.95 and g<.9
  end,function(s,t)return{x+s,c.platformHeight+c.torchHeight*(32-t)/20,z+32}end)
 elseif o.kind=='pylDevice'then
  draw(32,48,nil,function(s,t)return{x+s,0,z+t}end,clean)
  draw(o.first,o.last,function(s,t)return V.require('EmeraldBattlePike').deviceInside(o.shape,s,t)end,function(s,t)return{x+s,c[o.shape..'Height']*(o.last-t)/(o.last-o.first),z+o.last}end);contact(4,o.w-4,o.last)
 end
 for i=first,#out do out[i][2]=out[i][2]*cfg.heightScale end
end
return R
