-- Pure planning in native map coordinates. Never touches native layouts.
local P={}
local depths,rates,tops,heights={256,192,128,64},{.15,.3,.5,.5},{170,85,55,25},{160,180,150,100}
function P.bounds(entries,margin,out)
 out=out or{};local x0,z0,x1,z1=math.huge,math.huge,-math.huge,-math.huge
 for _,e in ipairs(entries)do
  local l=e.def and e.def.midLayout
  if l then local x,z=e.ox or 0,e.oy or 0
   x0,z0,x1,z1=math.min(x0,x),math.min(z0,z),math.max(x1,x+l.width),math.max(z1,z+l.height)
  end
 end
 if x0==math.huge then return end
 out[1],out[2],out[3],out[4]=x0-margin,z0-margin,x1+margin,z1+margin
 return out
end
-- Below the extended map edge: at the normal downward camera angle these
-- cards read as distant land beyond the tabletop, not giant walls on the map.
function P.layer(bounds,index,focusX,elevation,parallax,out)
 out=out or{};local depth=depths[index]
 local rate=rates[index]
 local center=(bounds[1]+bounds[3])*8
 out.x=center+(parallax and(focusX-center)*(1-rate)or 0)
 out.z=bounds[2]*16-depth
 out.top=-depth*math.tan(elevation)+tops[index]
 out.bottom=out.top-900
 out.width=math.max(2048,(bounds[3]-bounds[1])*16+1024)
 out.height=heights[index]
 out.rate=rate
 return out
end
-- Intersect a screen corner with the distant world plane. Unlike a giant
-- quad crossing behind the eye, every vertex retains a valid clip divisor.
function P.floor(vp,u,v,y)
 local a,b=vp[1]-u*vp[13],vp[3]-u*vp[15]
 local d,e=vp[5]-v*vp[13],vp[7]-v*vp[15]
 local c=u*(vp[14]*y+vp[16])-vp[2]*y-vp[4]
 local f=v*(vp[14]*y+vp[16])-vp[6]*y-vp[8]
 local det=a*e-b*d
 assert(math.abs(det)>1e-9,'singular horizon plane')
 return (c*e-b*f)/det,y,(a*f-c*d)/det
end
function P.floorDepth(vp,depthY)
 local y=-1200
 for attempt=1,16 do
  local valid=true
  for u=-1,1,2 do for v=-1,1,2 do
   local x,_,z=P.floor(vp,u*1.01,v*1.01,y)
   local w=vp[13]*x+vp[14]*y+vp[15]*z+vp[16]
   local depth=vp[9]*x+vp[10]*y+vp[11]*z+vp[12]
   local divisor=w+depthY*y
   if w<=0 or divisor<=0 or depth/divisor<=-1 or depth/divisor>=.99999 then valid=false end
  end end
  if valid then return y end
  y=y*.5
 end
 return y
end
function P.region(id,sets)
 local explicit=sets and sets[id];if explicit then return explicit end
 local hoennRoute=tonumber(id:match('^EM_ROUTE(%d+)$'))
 local coast=(hoennRoute and(hoennRoute==105 or hoennRoute==106 or hoennRoute==107 or hoennRoute==108 or hoennRoute==109 or hoennRoute>=124 and hoennRoute<=134))or id:match('^EM_DEWFORD')or id:match('^EM_SLATEPORT')or id:match('^EM_LILYCOVE')or id:match('^EM_MOSSDEEP')or id:match('^EM_PACIFIDLOG')or id:match('^FR_ROUTE_1[789]$')or id:match('^FR_ROUTE_2[01]')or id:find('CINNABAR',1,true)
  or id:find('SEAFOAM',1,true)or id:find('ISLAND',1,true)or id:find('HARBOR',1,true)
 return coast and(sets and sets.coast or'sea')or(sets and sets.default or'kanto-hills')
end
return P
