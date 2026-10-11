-- One byte per native tile: four cardinal and four diagonal bank bits.
-- Decoding the local distance analytically keeps a one-tile channel crisp;
-- interpolating one distance per corner would paint the whole channel white.
local M={}
local offsets={{-1,0},{1,0},{0,-1},{0,1},{-1,-1},{1,-1},{-1,1},{1,1}}
function M.water(layout,x,z)
 if x<0 or z<0 or x>=(layout.trueWidth or layout.width)or z>=(layout.trueHeight or layout.height)then return false end
 return layout:collAt(x,z)==0x29
end
-- Clip a rendered water triangle to a native cell. Its clipped centroid is a
-- safe rain origin even for a one-pixel basin strip or a partly covered tile.
local function clip(points,axis,bound,keepGreater)
 local out={};local previous=points[#points]
 for _,current in ipairs(points)do
  local a,b=previous[axis]-bound,current[axis]-bound
  local ain,bin=keepGreater and a>=0 or not keepGreater and a<=0,keepGreater and b>=0 or not keepGreater and b<=0
  if ain~=bin then local t=a/(a-b);out[#out+1]={previous[1]+(current[1]-previous[1])*t,previous[2]+(current[2]-previous[2])*t}end
  if bin then out[#out+1]=current end;previous=current
 end
 return out
end
function M.decorative(layout,mesh,checkpoint)
 local points={};if not mesh then return points end
 local w,h=layout.trueWidth or layout.width,layout.trueHeight or layout.height
 for i=1,mesh:getVertexCount(),3 do
  local ax,ay,az,_,_,ash=mesh:getVertex(i)
  if ash>=3.5 and ash<4.5 then
   local bx,by,bz,_,_,bsh=mesh:getVertex(i+1)
   local cx,cy,cz,_,_,csh=mesh:getVertex(i+2)
   if bsh>=3.5 and bsh<4.5 and csh>=3.5 and csh<4.5 and math.max(ay,by,cy)-math.min(ay,by,cy)<.01 then
    for z=math.max(0,math.floor(math.min(az,bz,cz)/16)),math.min(h-1,math.floor((math.max(az,bz,cz)-1e-6)/16))do
     for x=math.max(0,math.floor(math.min(ax,bx,cx)/16)),math.min(w-1,math.floor((math.max(ax,bx,cx)-1e-6)/16))do
      if not M.water(layout,x,z)then
       local poly={{ax,az},{bx,bz},{cx,cz}}
       for _,edge in ipairs({{1,x*16,true},{1,(x+1)*16,false},{2,z*16,true},{2,(z+1)*16,false}})do
        if #poly==0 then break end;poly=clip(poly,edge[1],edge[2],edge[3])
       end
       if #poly>=3 then
        local area,sx,sz=0,0,0;local prev=poly[#poly]
        for _,p in ipairs(poly)do area=area+prev[1]*p[2]-p[1]*prev[2];sx=sx+p[1];sz=sz+p[2];prev=p end
        if math.abs(area)>1e-6 then
         sx,sz=sx/#poly,sz/#poly
         local key=z*w+x;local old=points[key];local distance=(sx-x*16-8)^2+(sz-z*16-8)^2
         if not old or distance<old.distance then points[key]={x=sx,z=sz,distance=distance}end
        end
       end
      end
     end
    end
   end
  end
  if checkpoint and i%192==1 then checkpoint()end
 end
 return points
end
function M.build(layout,checkpoint,decorative)
 local w,h=layout.trueWidth or layout.width,layout.trueHeight or layout.height
 local function wet(x,z)return M.water(layout,x,z)or decorative and decorative[z*w+x]~=nil end
 local bytes,water={},{}
 for z=0,h-1 do for x=0,w-1 do
  local code=0
  if wet(x,z)then
   water[#water+1]=z*w+x
   for i,d in ipairs(offsets)do
    -- The map boundary alone is not a bank: a neighbouring map may be sea.
    local a,b=x+d[1],z+d[2]
    if a>=0 and b>=0 and a<w and b<h and not wet(a,b)then code=code+2^(i-1)end
   end
  end
  bytes[#bytes+1]=string.char(code)
  if checkpoint and #bytes%128==0 then checkpoint()end
 end end
 return w,h,table.concat(bytes),water
end
return M
