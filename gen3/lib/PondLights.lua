-- Submerged perimeter lights for enclosed FireRed town and route ponds. Complete
-- components are classified before sampling: a sea cannot become small ponds
-- by stopping a flood fill at the size limit. No native water data is changed.
local V=...
local P={cache=setmetatable({},{__mode='k'})}
-- Collision water also includes ocean below docks and stone sea barriers.
-- Native MB_POND_WATER is the authoritative fresh-water discriminator.
function P.freshWater(def,x,z)
 local behavior=V.require('NativeTilesetIdentity').behavior(def,x,z)
 if behavior==nil then behavior=require('src.core.game3.collision').behaviorOn(def,x,z)end
 return behavior==0x10
end
function P.isFireRed(def)
 local id=tostring(def.id or def.name or'')
 return id:match('^EM_')or id:match('^FR_')or id:match('^SEVII_ONE_ISLAND')
end
function P.applies(def)
 local c=V.require('DioramaConfig').pondLights.townRim
 return c and c.enabled and P.isFireRed(def)
  and (tonumber(def.mapType)==1 or tonumber(def.mapType)==2 or tonumber(def.mapType)==3)
end
function P.sites(def)
 local L=def.midLayout;if not L or not P.applies(def)then return {}end
 if P.cache[L]then return P.cache[L]end
 local c=V.require('DioramaConfig').pondLights.townRim
 local S=V.data('Shapes');local seen,sites={},{}
 local function wet(x,z)
  return x>=0 and z>=0 and x<L.width and z<L.height and S.water(L:cellAt(x,z))
 end
 local dirs={{0,-1},{1,0},{0,1},{-1,0}}
 for z=0,L.height-1 do for x=0,L.width-1 do local key=z*L.width+x
  if not seen[key]and wet(x,z)then
   local q={key};seen[key]=true;local i=1;local border=false;local fresh=true
   while q[i]do
    local k=q[i];i=i+1;local xx,zz=k%L.width,math.floor(k/L.width)
    fresh=fresh and P.freshWater(def,xx,zz)
    border=border or xx==0 or zz==0 or xx==L.width-1 or zz==L.height-1
    for _,d in ipairs(dirs)do local nx,nz=xx+d[1],zz+d[2];local n=nz*L.width+nx
     if wet(nx,nz)and not seen[n]then seen[n]=true;q[#q+1]=n end
    end
   end
   if fresh and not border and #q>=c.minCells and #q<=c.maxCells then
    table.sort(q);local rim={}
    for _,k in ipairs(q)do local xx,zz=k%L.width,math.floor(k/L.width)
     for side,d in ipairs(dirs)do if not wet(xx+d[1],zz+d[2])then
      local px,pz=xx*16+8+d[1]*(8-c.inset),zz*16+8+d[2]*(8-c.inset)
      rim[#rim+1]={x=px,z=pz,side=side,seed=(key*17+xx*7+zz*13)%97,pond=key,cells=#q}
     end end
    end
    -- Deterministic spacing per whole pond, independent of camera/player.
    local chosen={}
    for _,p in ipairs(rim)do local free=true
     for _,b in ipairs(chosen)do if p.side==b.side and (p.x-b.x)^2+(p.z-b.z)^2<c.spacing^2 then free=false;break end end
     if free then chosen[#chosen+1]=p;sites[#sites+1]=p end
    end
   end
  end
 end end
 P.cache[L]=sites;return sites
end
function P.color(time,seed)
 local c=V.require('DioramaConfig').pondLights.townRim
 if not c.colorCycle then return c.colors[1]end
 local phase=(time/c.cycleSeconds+(seed or 0)*c.phaseSpread)%1*#c.colors
 local k=math.floor(phase);local t=phase-k;t=t*t*(3-2*t)
 local a,b=c.colors[k+1],c.colors[(k+1)%#c.colors+1]
 return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t}
end
function P.apply(def,result,px,pz,time,night)
 if not P.applies(def)then return false end
 local c=V.require('DioramaConfig').pondLights.townRim
 if night<=0 or V.mod.options:get('gen3Lights')==false then return true end
 for _,p in ipairs(P.sites(def))do
   local l={x=p.x,y=c.height,z=p.z,radius=-c.radius,power=c.power*night,spatial=true,
    color=P.color(time,p.seed),kind='pond',size=c.size,stretch=c.stretch,squash=c.squash,alpha=c.alpha*night}
   result.lights[#result.lights+1]=l;result.sprites[#result.sprites+1]=l
 end
 return true
end
function P.release()P.cache=setmetatable({},{__mode='k'})end
return P
