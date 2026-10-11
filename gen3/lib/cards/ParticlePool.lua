-- Bounded deterministic trajectories. No random generator or per-tick tables.
local P={MAX=300}
local sin,cos,floor,pi,min,max,abs=math.sin,math.cos,math.floor,math.pi,math.min,math.max,math.abs
local styles={ -- atlas, size, lifetime, rise, radius, r,g,b,opacity
 pollen={0,1.5,18,16,18,1,.89,.56,.65},dust={1,1,14,22,5,1,.91,.7,.42},
 embers={2,1.8,5,36,7,3.2,.9,.15,.85},leaves={3,3.5,12,-44,14,.77,.59,.22,.9},
 snowdrift={4,1.8,9,-22,10,.8,.91,1,.75},steam={5,7,6,25,3,.8,.84,.9,.28},
 sparks={6,1.5,1.2,9,3,2.8,2.2,.6,.9},lint={7,1.5,16,12,6,.85,.8,.7,.45},
}
P.styles=styles
function P.new()
 local p={rows={},count=0}
 for i=1,P.MAX do p.rows[i]={0,0,0,0,0,0,0,0,0,0}end
 return p
end
function P.begin(p)p.count=0 end
function P.emit(p,kind,count,x,y,z,radius,height,time,wind,brightness,opacity,seed,limit,slant,sites,sizeScale)
 local s=styles[kind];if not s then return end
 limit=min(P.MAX,limit or P.MAX);count=min(max(0,floor(count)),limit-p.count)
 if count<=0 then return end
 -- Per-emitter constants stay outside the bounded particle loop. Keep the
 -- trajectory arithmetic/order identical so reload and rollback captures match.
 local rows,first=p.rows,p.count
 local phase=time/s[3];local fall=s[4]<0;local travel=height or abs(s[4])
 local spread=radius or s[5];local driftTime,orbitTime=time*.35,time*.21
 local steam,leaves=kind=='steam',kind=='leaves'
 local spin=time*.8;local size,atlas=s[2],s[1]
 size=size*min(3,max(.25,sizeScale or 1))
 local b=(kind=='embers'or kind=='sparks')and 1 or brightness
 local red,green,blue=s[6]*b,s[7]*b,s[8]*b
 local alpha=s[9];local slope=slant or 0;local siteCount=sites and #sites
 local emitterSeed=(seed or 1)*7919
 -- Map setup supplies complete sites (x/y/z/h/c/s). Traverse that prepared
 -- array directly instead of repeating optional-origin branches and modulo
 -- for every particle. Keep arithmetic order identical to the reference.
 if sites then
  local siteIndex=1
  for i=1,count do
   local site=sites[siteIndex];siteIndex=siteIndex+1
   if siteIndex>siteCount then siteIndex=1 end
   local h=site.h;local ph=phase+h;local age=ph-floor(ph)
   local rise=travel*(fall and 1-age or age)
   local drift=sin(driftTime+h*24)*spread
   local fade=min(1,age*8,(1-age)*5)
   local r=rows[first+i]
   r[1]=site.x+site.c*spread+drift*.3+wind*sin(age*pi)*3-rise*slope
   r[2]=site.y+rise;r[3]=site.z+site.s*spread+cos(orbitTime+h*17)*2
   r[4]=size*(steam and(.5+age)or 1)
   r[5]=leaves and spin+h*20 or h*12;r[6]=atlas
   r[7],r[8],r[9]=red,green,blue
   r[10]=alpha*fade*opacity
  end
 else
 for i=1,count do
  -- Per-emitter seed/ordinal, never camera position or frame number.
  local site=sites and sites[(i-1)%siteCount+1]
  local h=site and site.h or (emitterSeed+i*104729)%65521/65521
  local px,py,pz=site and site.x or x,site and site.y or y,site and site.z or z
  local ph=phase+h;local age=ph-floor(ph);local angle=h*2*pi
  local rise=travel*(fall and 1-age or age)
  local drift=sin(driftTime+h*24)*spread
  local fade=min(1,age*8,(1-age)*5)
  local r=rows[first+i]
  r[1]=px+(site and site.c or cos(angle))*spread+drift*.3+wind*sin(age*pi)*3-rise*slope
  r[2]=py+rise;r[3]=pz+(site and site.s or sin(angle))*spread+cos(orbitTime+h*17)*2
  r[4]=size*(steam and(.5+age)or 1)
  r[5]=leaves and spin+h*20 or h*12;r[6]=atlas
  r[7],r[8],r[9]=red,green,blue
  r[10]=alpha*fade*opacity
 end
 end
 p.count=first+count
end
return P
