-- Gate wall art and freestanding fixtures share native metatiles. Separate
-- their ownership without altering rugs, exits, stairs or event positions.
local V=...;local S={}
local function cfg()return V.require('DioramaConfig').interiors.gateFixtures end
function S.profile(d)
 local L=d and d.midLayout;local c=cfg()
 local id=d and(d.id or d.name or'')or''
 if not(c.enabled and L and d.mapType==8 and d.pair=='house'and id:match('^FR_ROUTE_')
  and(id:match('_ENTRANCE')or id=='FR_ROUTE_2_EAST_BUILDING'))then return false end
 local tops={[8]=true,[0x287]=true,[0x288]=true,[0x289]=true,[0x28a]=true,[0x298]=true,[0x299]=true,[0x2a8]=true,[0x2a9]=true,[0x2fe]=true,[0x2ff]=true}
 for x=0,L.width-1 do if not tops[L:midAt(x,0)]then return false end end
 return true
end
function S.plan(d,objects,mask)
 if not S.profile(d)then return end;local L=d.midLayout
 local function claim(x,y,mid,void)mask[y*L.width+x+1]={mid=mid,void=void,separateSurface=true}end
 for x=0,L.width-1 do
  local top=L:midAt(x,0)
  if top~=0 and top~=8 then
   local bottom=L:midAt(x,1);if bottom==0x2ea and L:midAt(x,2)==0x2f1 then bottom=0x28f elseif bottom==0x2c0 and L:midAt(x,2)==0x2c8 then bottom=0x2b0 elseif bottom==0x2c1 and L:midAt(x,2)==0x2c9 then bottom=0x2b1 end
   objects[#objects+1]={kind='gateWall',x=x,y=0,top=top,bottom=bottom}
   claim(x,0,0,true);claim(x,1,0,true)
  end
 end
 for y=1,L.height-1 do for x=0,L.width-1 do local m=L:midAt(x,y)
  local bottom=L:midAt(x,y+1)
  local small=(m==0x2e8 or m==0x2e9)and bottom==0x2f0
  local tall=(m==0x2e9 or m==0x2ea)and bottom==0x2f1
  if y+1<L.height and(small or tall)then
   objects[#objects+1]={kind='gatePlant',x=x,y=y,small=small}
   -- Rear-wall pixels were just reconstructed independently above.
   if y~=1 then claim(x,y,0x281)end;claim(x,y+1,0x281)
  elseif (m==0x2c0 or m==0x2c1)and y==1 and L:midAt(x,2)==(m==0x2c0 and 0x2c8 or 0x2c9)then
   objects[#objects+1]={kind='gateTelescope',x=x,y=1,left=m==0x2c0}
   claim(x,2,m==0x2c0 and 0x2b8 or 0x2b9)
  end
 end end
end
function S.build(out,objects,L,ts,ox,oz,contacts)
 if not cfg().enabled then return end
 local G=V.require('WorldGeometry');local P=V.require('PaperSprite');local B=V.require('BuildingMesh');local c=cfg()
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 for _,o in ipairs(objects)do if o.kind=='gateWall'or o.kind=='gatePlant'or o.kind=='gateTelescope'then
  local first=#out+1;local x,z=(o.x+ox)*16,(o.y+oz)*16
  if o.kind=='gateWall'then
   for row=0,1 do local a=c.wallHeight*(1-row/2);local b=a-c.wallHeight/2
    G.quad(out,{x,a,z+32},{x+16,a,z+32},{x+16,b,z+32},{x,b,z+32},G.uv(ts,row==0 and o.top or o.bottom,0,0,16,16,.5),1)
   end
   if o.top==0x2a8 or o.top==0x2a9 then
    local top=c.wallHeight;local bottom=top-c.lintelRows
    G.quad(out,{x,top,z+32.01},{x+16,top,z+32.01},{x+16,bottom,z+32.01},{x,bottom,z+32.01},G.uv(ts,0x287,0,0,16,c.lintelRows,.5),1)
   end
   if o.top~=0x288 and o.top~=0x289 and o.top~=0x28a then
    local thick=V.require('DioramaConfig').gateLighting.wallThickness
    V.require('GateLighting').box(L,x,0,z+32-thick,16,c.wallHeight*V.require('Billboard').heightScale(),thick,true)
   end
  elseif o.kind=='gatePlant'and not o.small then
   V.require('InteriorTransit').transitPlant(nil,out,L,ts,o,x,z)
   contacts[#contacts+1]={x+8,z+30,6,c.contactRadius,c.contactStrength}
  else
   local function src(s,t)return L:midAt(o.x,o.y+math.floor(t/16)),s,t%16 end
   local clear,empty,q={},{},{}
   local colors={};if o.small then for _,m in ipairs({0x281,0x282})do for t=0,15 do for s=0,15 do colors[rgb(B.pixel(ts,m,s,t))]=true end end end end
   for t=0,31 do for s=0,15 do
    local m,u,v=src(s,t);local r,g,b,a=B.pixel(ts,m,u,v);local donor=o.left and(t<16 and 0x2b0 or 0x2b8)or(t<16 and 0x2b1 or 0x2b9)
    clear[t*16+s]=a<.5 or (o.small and colors[rgb(r,g,b)]or not o.small and rgb(r,g,b)==rgb(B.pixel(ts,donor,u,v)))
   end end
   local function seed(s,t)local k=t*16+s;if clear[k]and not empty[k]then empty[k]=true;q[#q+1]=k end end
   for t=0,31 do seed(0,t);seed(15,t)end;for s=0,15 do seed(s,0);seed(s,31)end
   local j=1;while q[j]do local k=q[j];j=j+1;local s,t=k%16,math.floor(k/16)
    if s>0 then seed(s-1,t)end;if s<15 then seed(s+1,t)end;if t>0 then seed(s,t-1)end;if t<31 then seed(s,t+1)end
   end
   local front=o.small and c.smallPlantBase or c.telescopeBase
   local vv=P.build(ts,16,32,src,function(s,t)return t<front and not empty[t*16+s]end,0,32,1,nil,
    function(s,t)return{x+s,front-t,z+front}end,.5)
   for _,v in ipairs(vv)do out[#out+1]=v end
   contacts[#contacts+1]={x+8,z+front,5,c.contactRadius,c.contactStrength}
  end
  local scale=V.require('Billboard').heightScale();for i=first,#out do out[i][2]=out[i][2]*scale end
 end end
end
return S
