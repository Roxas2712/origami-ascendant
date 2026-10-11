-- Low gate partitions follow their native cap contour, including L corners.
-- Mixed rug/cap tiles retain the rug at ground level. No collision changes.
local V=...;local S={}
local capStart={
 [0x2eb]=12,[0x2ec]=12,[0x2ed]=12,[0x28c]=12,[0x28e]=12,[0x29d]=12,[0x29f]=12,
 [0x32a]=12,[0x326]=12,[0x32b]=12,[0x297]=8,
 [0x2a4]=0,[0x2a5]=0,[0x2a6]=0,[0x296]=0,[0x28d]=0,[0x295]=0,[0x29c]=0,
}
local function cfg()return V.require('DioramaConfig').interiors.gatePartitions end
local function one(m,... )for i=1,select('#',...)do if m==select(i,...)then return true end end;return false end
local function complete(L,x,y,m)
 local up,dn,le,ri=L:midAt(x,y-1),L:midAt(x,y+1),L:midAt(x-1,y),L:midAt(x+1,y)
 if m==0x297 then return one(dn,0x28d,0x295)end
 if m==0x28d then return one(up,0x297,0x28d,0x296)and one(dn,0x28d,0x295,0x29c)end
 if m==0x295 then return one(up,0x28d,0x296,0x297)end
 if m==0x296 then return up==0x28e and one(dn,0x28d,0x295)end
 if m==0x2a4 then return one(up,0x2eb,0x28c,0x29c)end
 if m==0x2a5 then return one(up,0x2ec,0x29d,0x29f,0x32a,0x326,0x32b)end
 if m==0x2a6 then return one(up,0x2ed,0x28e)end
 if m==0x29c then return up==0x28d and dn==0x2a4 and capStart[ri]~=nil end
 if m==0x2eb or m==0x28c then return dn==0x2a4 and capStart[ri]~=nil end
 if m==0x2ed or m==0x28e then return one(dn,0x2a6,0x296)and capStart[le]~=nil end
 return dn==0x2a5 and capStart[le]~=nil and capStart[ri]~=nil
end
function S.plan(d,objects,mask)
 local L=d.midLayout
 if not cfg().enabled or not L or d.mapType~=8 or d.pair~='house'or not(d.id or d.name or''):match('^FR_ROUTE_')then return end
 local seen={}
 for y=0,L.height-1 do for x=0,L.width-1 do local k=y*L.width+x+1
  if capStart[L:midAt(x,y)]and not seen[k]then
   local queue={{x,y}};seen[k]=true;local i=1;local valid=true;local cells={}
   while queue[i]do local p=queue[i];i=i+1;local xx,yy=p[1],p[2];local m=L:midAt(xx,yy)
    cells[yy*L.width+xx+1]=true;valid=complete(L,xx,yy,m)and valid
    for _,v in ipairs({{-1,0},{1,0},{0,-1},{0,1}})do local a,b=xx+v[1],yy+v[2];local j=b*L.width+a+1
     if a>=0 and a<L.width and b>=0 and b<L.height and not seen[j]and capStart[L:midAt(a,b)]then seen[j]=true;queue[#queue+1]={a,b}end
    end
   end
   if valid then
    objects[#objects+1]={kind='gatePartition',x=x,y=y,cells=cells}
    for j in pairs(cells)do
     local xx,yy=(j-1)%L.width,math.floor((j-1)/L.width)
     mask[j]={mid=0,void=true,separateSurface=true}
     if yy==1 and L:midAt(xx,yy)==0x297 then
      -- Its upper half is wall background; the partition begins below it.
      for _,o in ipairs(objects)do if o.kind=='gateWall'and o.x==xx then o.bottom=0x28f end end
     end
     for _,v in ipairs({{1,0},{0,1}})do local a,b=xx+v[1],yy+v[2];local m=L:midAt(a,b)
      if a<L.width and b<L.height and one(m,0x283,0x284,0x285,0x286)then mask[b*L.width+a+1]={mid=0x281,separateSurface=true}end
     end
    end
   end
  end
 end end
end
function S.build(out,objects,L,ts,ox,oz,contacts)
 if not cfg().enabled then return end
 local G=V.require('WorldGeometry');local B=V.require('BuildingMesh');local c=cfg()
 local function rgb(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 for _,o in ipairs(objects)do if o.kind=='gatePartition'then
  local core,top={},{};local width=L.width*16
  local function key(x,y)return y*width+x end
  local function owned(x,y)
   return x>=0 and y>=0 and x<width and y<L.height*16 and o.cells[math.floor(y/16)*L.width+math.floor(x/16)+1]
  end
  local function source(x,y)return L:midAt(math.floor(x/16),math.floor(y/16)),x%16,y%16 end
  for j in pairs(o.cells)do local x,y=(j-1)%L.width*16,math.floor((j-1)/L.width)*16;local m=L:midAt(x/16,y/16)
   for sy=capStart[m],15 do for sx=0,15 do local col=rgb(B.pixel(ts,m,sx,sy))
    if col==0xf7efbd or col==0xffffff then core[key(x+sx,y+sy)]=true;top[key(x+sx,y+sy)]=true end
   end end
  end
  -- One native grey outline pixel belongs to the cap, not the floor.
  for k in pairs(core)do local x,y=k%width,math.floor(k/width)
   for _,v in ipairs({{-1,0},{1,0},{0,-1},{0,1}})do local a,b=x+v[1],y+v[2]
    if owned(a,b)then local m,u,t=source(a,b);local col=rgb(B.pixel(ts,m,u,t))
     if t>=capStart[m]and(col==0x848484 or col==0xb5b5a5)then top[key(a,b)]=true end
    end
   end
  end
  local function has(x,y)return owned(x,y)and top[key(x,y)]end
  local h=c.height
  for j in pairs(o.cells)do local tx,ty=(j-1)%L.width,math.floor((j-1)/L.width);local m=L:midAt(tx,ty)
   for sy=0,15 do
    -- Ground runs preserve mixed native carpet pixels above the cap. Erase
    -- only the partition bands and their own baked floor shadow palette.
    if ty>1 then
     local sx=0
     while sx<16 do
      local function donor(u)
       if sy>=capStart[m]then return 0x281 end
       local col=rgb(B.pixel(ts,m,u,sy));if col==0xbda552 or col==0xdec56b then return 0x281 end
       return m
      end
      local start=sx;local mid=donor(sx);repeat sx=sx+1 until sx==16 or donor(sx)~=mid
      local x,z=(tx+ox)*16,(ty+oz)*16
      G.quad(out,{x+start,0,z+sy},{x+sx,0,z+sy},{x+sx,0,z+sy+1},{x+start,0,z+sy+1},G.uv(ts,mid,start,sy,sx,sy+1,.5),1)
     end
    end
    local sx=0
    while sx<16 do
     if has(tx*16+sx,ty*16+sy)then
      local start=sx;repeat sx=sx+1 until sx==16 or not has(tx*16+sx,ty*16+sy)
      local x,z=(tx+ox)*16,(ty+oz)*16
      G.quad(out,{x+start,h,z+sy},{x+sx,h,z+sy},{x+sx,h,z+sy+1},{x+start,h,z+sy+1},G.uv(ts,m,start,sy,sx,sy+1,.5),1)
      V.require('GateLighting').box(L,x+start,0,z+sy,sx-start,h,1,false)
     else sx=sx+1 end
    end
   end
  end
  -- Only the exterior contour gets vertical faces. Shared corners have no
  -- internal faces and no raised rectangular floor patches.
  for k in pairs(top)do local px,pz=k%width,math.floor(k/width);local x,z=px+ox*16,pz+oz*16
   local uv=G.uv(ts,0x2a5,px%16,8,px%16+1,16,.5)
   if not has(px,pz+1)then G.quad(out,{x,h,z+1},{x+1,h,z+1},{x+1,0,z+1},{x,0,z+1},uv,c.sideShade)end
   if not has(px,pz-1)then G.quad(out,{x+1,h,z},{x,h,z},{x,0,z},{x+1,0,z},uv,c.sideShade)end
   if not has(px-1,pz)then G.quad(out,{x,h,z},{x,h,z+1},{x,0,z+1},{x,0,z},uv,c.sideShade)end
   if not has(px+1,pz)then G.quad(out,{x+1,h,z+1},{x+1,h,z},{x+1,0,z},{x+1,0,z+1},uv,c.sideShade)end
  end
  -- Short soft contact shadows per native cap row, with no filled L interior.
  for j in pairs(o.cells)do local tx,ty=(j-1)%L.width,math.floor((j-1)/L.width)
   for sy=0,15 do local lo,hi
    for sx=0,15 do if has(tx*16+sx,ty*16+sy)and not has(tx*16+sx,ty*16+sy+1)then lo=lo or sx;hi=sx+1 end end
    if lo and hi-lo>=4 then contacts[#contacts+1]={(tx+ox)*16+(lo+hi)/2,(ty+oz)*16+sy+1,(hi-lo)/2,c.contactRadius,c.contactStrength}end
   end
  end
 end end
end
return S
