-- Native chimney mouths only; no world scan and no gameplay RNG. All positions
-- use PaperBuildings' folded roof coordinates, rebuilt only with the local map.
local V=...
local S={PERIOD=48}
local mouths={
 pallet_outdoor={[0x2bd]={{11,19}}},
 viridian_outdoor={[0x2ab]={{8,16}},[0x283]={{8,8}}},
 general__rom_082d4af4={[0x2cb]={{16,8}}}, -- Bill's cottage
 general__rom_082d4b3c={[0x2df]={{12,10}},[0x31d]={{12,18}}},
 general__rustboro={[0x222]={{18,8}}},
 general__fallarbor={[0x320]={{4,3},{19,3},{11,15}}},
}
local function hash(s)
 local h=17;for i=1,#s do h=(h*131+s:byte(i))%2147483647 end;return h
end
function S.new(id,groups)
 return {groups=groups or{},seed=hash(id or ''),order={},epoch=nil,rolls=0,visible=0,active=0}
end
-- An independent, reproducible map-local draw every 48 seconds. Camera motion
-- cannot change the result; a frozen render clock also freezes selection.
function S.select(state,time)
 local epoch=math.floor(time/S.PERIOD)
 if state.epoch==epoch then return end
 state.epoch=epoch;state.rolls=state.rolls+1
 local seed=(state.seed+epoch*104729)%2147483646+1
 local function random(n)seed=seed*16807%2147483647;return math.floor(seed/2147483647*n)+1 end
 local groups,order=state.groups,state.order;local n=#groups
 for i=1,n do order[i]=i;groups[i].selected=false end
 local count=random(n+1)-1
 for i=n,2,-1 do local j=random(i);order[i],order[j]=order[j],order[i]end
 for i=1,count do local g=groups[order[i]];g.selected=true;g.start=random(8)-1;g.duration=18+random(14)end
end
function S.opacity(group,time,winter)
 if winter then return 1 end
 if not group.selected then return 0 end
 local age=time%S.PERIOD-group.start
 return math.max(0,math.min(1,age/3,(group.duration-age)/6))
end
function S.winter(ctx)
 if ctx.weatherMode=='snow'or ctx.weatherMood and ctx.weatherMood.precipMode=='snow'then return true end
 local W=V.require('Weather')
 return W.setting:get()=='auto'and W.seasonAt(W.clock)=='snow'
end
function S.build(def)
 local groups={};local state=S.new(def.id,groups)
 local patterns=mouths[def.renderPair or def.pair]
 if not patterns then return state end
 local ts=V.require('WorldAdapter').Native._pairs[def.pair]
 if not ts then return state end
 local L=def.midLayout;local C=V.require('DioramaConfig')
 for _,b in ipairs(V.require('WorldGeometry').buildings(def))do
  local found={};local y0=math.max(0,b.y0-1)
  for y=y0,b.y1 do for x=b.x0,b.x1 do
   local points=patterns[L:midAt(x,y)]
   if points then found[#found+1]={x=x,y=y,points=points}end
  end end
  if #found>0 then
   local spec=V.data('BuildingProfiles').get(b,L)
   -- Only the bottom silhouette row and roof split are needed. Building a
   -- complete sprite here would repeat tens of thousands of atlas reads on
   -- a tall/terraced house. These surveyed profiles have no detached masks.
   local pixel=V.require('BuildingMesh').pixel
   local function color(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
   local background={}
   for y=0,15 do for x=0,15 do background[color(pixel(ts,b.ground or 1,x,y))]=true end end
   local width,height=(b.x1-b.x0+1)*16,(b.y1-y0+1)*16
   local base=height
   for y=height-1,0,-1 do
    local any=false
    for x=0,width-1 do
     local r,g,blue,alpha=pixel(ts,L:midAt(b.x0+math.floor(x/16),y0+math.floor(y/16)),x%16,y%16)
     local rgb=color(r,g,blue)
     if alpha>=.5 and not background[rgb]and not(spec.backgroundColors and spec.backgroundColors[rgb])
      and y>=(spec.backgroundRows or 0)and not(g>r*1.2 and blue>r*1.1 and g>blue*1.06 and g>.45)then any=true;break end
    end
    if any then base=y+1;break end
   end
   local line=math.min(height-spec.wallRows*16,base-8)
   local landmark=spec.landmark and C.buildings[spec.landmark]
   local scale=landmark and landmark.wallScale or spec.wallScaleKey and C.buildings[spec.wallScaleKey]
    or spec.paper and spec.paper.wallScale or spec.foldWallScale
   local wall=(base-line)*scale*V.require('Billboard').heightScale()
   local rise=math.min(7,line*.16);local elevation=V.require('Camera').elevation()
   local depth=math.max(4,(line*(spec.paper and spec.paper.roofScale or .60)-rise*math.cos(elevation))/math.sin(elevation))
   for _,mouth in ipairs(found)do
    -- Repeated terraced houses are one geometry record but separate heaters;
    -- multiple openings of a single stack (Fallarbor) share one heating cycle.
    local g={points={},selected=false};groups[#groups+1]=g
    for _,p in ipairs(mouth.points)do
     local sy=(mouth.y-y0)*16+p[2];local t=(line-sy)/math.max(1,line)
     local x,y,z=mouth.x*16+p[1],wall+t*rise+1,(b.facadeBaseY or b.y1+1)*16-t*depth
     g.points[#g.points+1]={x=x,y=y,z=z,seed=hash((def.id or '')..':'..mouth.x..':'..mouth.y..':'..#g.points),
      bounds={x-18,y-10,z-15,x+18,y+44,z+15,0},source={building=b,x=mouth.x*16+p[1]-b.x0*16,y=sy,base=base,line=line}}
    end
   end
  end
 end
 return state
end
function S.emit(state,ctx,pool,Pool,emission,limit,wind,brightness)
 state.visible=0;state.active=0
 if #state.groups==0 or emission<=0 then return end
 local time=ctx.time or 0;S.select(state,time)
 local winter=S.winter(ctx);local visibility=V.require('SceneVisibility')
 for _,g in ipairs(state.groups)do
  local opacity -- evaluate the heating envelope only after visibility passes
  for _,p in ipairs(g.points)do
   if not ctx.vp or visibility.visible(p.bounds,ctx.vp,false,0,ctx.pixelWidth or 1,ctx.pixelHeight or 1)then
    state.visible=state.visible+1
    opacity=opacity or S.opacity(g,time,winter)
    if opacity>0 then
     state.active=state.active+1
     Pool.emit(pool,'steam',12*emission,p.x,p.y,p.z,.7,30,time,wind,brightness,opacity*2.5,p.seed,limit)
    end
   end
  end
 end
end
return S
